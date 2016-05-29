##################################################################
#    Architettura degli elaboratori - Simulatore operazioni      #
##################################################################
#Mauro Matteo - matteo.mauro@stud.unifi.it
#Busiello Salvatore - salvatore.busiello@stud.unifi.it
#Milicia Lorenzo - lorenzo.milicia1@stud.unifi.it

# Data di consegna: 29/05/2016


.data

strReturnSomma: .asciiz "<-- somma-return("
strReturnSottrazione: .asciiz "<-- sottrazione-return("
strReturnProdotto: .asciiz "<-- prodotto-return("
strReturnDivisione: .asciiz "<-- divisione-return("
strTab: .asciiz "	"
fnf:	.ascii  "The file was not found: "
file:	.asciiz	"chiamate.txt"
error_divFor0:	.asciiz  "ERROR: found division for 0"
bufferString: .space 150
puntatore: .word bufferString
contatoreTab: .word 0

.text
.globl main

main:
	addi $sp, $sp, -4	#salvo solo l'indirizzo di ritorno (non ho usato altri registri)
	sw $ra, 0($sp)

	jal readFunction	#procedura per salvare in buffer la stringa che rappresenta la funzione

	lw $ra, 0($sp)		#ripristino l'indirizzo di ritorno
	addi $sp, $sp, 4


	addi $sp, $sp, -4	#salvo solo l'indirizzo di ritorno
	sw $ra, 0($sp)
	la $a0, bufferString	#bufferString = stringa che rappresenta la funzione, viene passato come argomento
				#per la procedura parsing

	jal parsing		#la procedura 'main' richiama 'parsing'
	lw $ra, 0($sp)		#ripristino l'indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack

	jr $ra			#terminazione del programma, ritorno a procedura chiamante di QTSpim

exitForError:
	#ho letto una divisione per 0, esco con un messaggio di errore

	li $v0, 4		#stampa messaggio d'errore
	la $a0, error_divFor0
	syscall
	li $v0, 10
	syscall

#--------------------------- PROCEDURA PARSING   ---------------------------------------------------------------------------------------
#parsing: procedura che si occupa di analizzare la stringa e fornire gli operandi necessari alla procedura chiamante,
#	  questo implica che al suo interno possono essere richiamate ulteriori procedure, nel caso in cui appaiano
# 	  come operandi della procedura chiamante
parsing:

	move $t0, $a0 			#salvo l'indirizzo del carattere iniziale, mi servira' dopo
					#(nella 'callProcedure')

	addi $sp, $sp, -4
	sw $s0, 0($sp)			#salvo il valore di $s0, dato che all'inizio sarà uguale a 0 (non ho ancora
					#raggiunto la virgola ovviamente)

	move $s0, $zero			#inizializzo la variabile flag $s0
	move $t8, $zero			#$t8 e $t9 conterranno i 2 operandi, li inizializzo a zero
	move $t9, $zero

loopParsing:

	lb  $t1, 0($a0)			#leggo un carattere
	beq $t1, ' ', ignore		#se trovo uno spazio la ignoro
	beq $t1, '(', ignore		#se trovo una parentesi aperta la ignoro
	beq $t1, ')', execute		#se trovo una parentesi chiusa devo eseguire l'operazione ritornando
					#alla procedura chiamante

	beq $t1, ',', flagVirgola	#se trovo una virgola devo aggiornare $s0 che mi dice se ho già trovato
					#il primo operando

	beq $t1, '-', flagNegativo       #se trovo un trattino il prossimo operando che leggo dovro' moltiplicarlo
					 #per -1

	beq $t1, $zero, exit		#se trovo zero significa che sono arrivato alla fine del file, perciò
					#ho già calcolato il risultato finale

	bge $t1, 'a', callProcedure     #se trovo una lettera allora devo richiamare una procedura, salto a
					#'callProcedure' per capire quale

	#se sono arrivato qui ho trovato un operando per esclusione
	#il primo e secondo operando vanno salvati rispettivamente in $t8 e $t9, $s0 mi dice quale

	beq $s0, 1, insertOperando2	#se $s0 è uguale a 1 salto a modificare il primo operando
	 				#altrimenti metto il primo operando in $t8

	addi $t1, $t1, -48		#trasformo $t1 in un numero
	mul $t8, $t8, 10		#il valore finora letto di $t8 viene moltiplicato per 10 per sommarci
					#la cifra appena letta

	add $t8, $t8, $t1
	addi $a0, $a0, 1		#procedo al prossimo carattere
	j loopParsing

flagNegativo:
	#$t4 è la variabile flag che, quando è uguale a 1, mi dice di moltiplicare per -1 il prossimo operando che leggo

	addi $t4, $t4, 1
	addi $a0, $a0, 1	#procedo a prossimo carattere
	j loopParsing		#rieseguo il ciclo di lettura

negativeMultiplication1:

	mul $t8, $t8, -1	#il primo operando ($t8) viene modificato in un numero negativo
	move $t4, $zero		#$t4 torna a 0
	j loopParsing		#essendo il primo operando non ho ancora terminato la procedura attuale,
				#continuo a leggere

negativeMultiplication2:

	mul $t9, $t9, -1	#il secondo operando ($t9) viene modificato in un numero negativo
	move $t4, $zero		#$t4 torna a 0
	j execute		#essendo il secondo operando ho terminato il parsing di questa procedura,
				#salto a 'execute'


flagVirgola:
	#modifico $s0 con valore 1, così dopo capisco che ho già trovato il primo operando
	#(devo gestire in quali registri inserire i valori di ritorno)

	addi $s0, $zero, 1
	move $t0, $a0				#ripristino l'inizio sottostringa da dopo la virgola
	addi $t0, $t0, 1
	addi $a0, $a0, 1			#procedo al prossimo carattere
	beq $t4, 1, negativeMultiplication1 	#salto a modificare il primo operando appena letto se $t4 è uguale
						#a 1 (significa che avevo letto un meno)
	j loopParsing				#rieseguo il ciclo

ignore:

	addi $a0, $a0, 1			#procedo al prossimo carattere
	j loopParsing

callProcedure:
	#individua l'operazione da svolgere

	move $t2, $t1			#uso $t2 come appoggio per la lettera che ho trovato
	beq $t2, 'd', isDivision	#salto alla procedura 'divisione'
	beq $t2, 'p', isMultiplication	#salto alla procedura 'prodotto'
	lb $t2, 2($t0) 			#mi sposto di 2 byte/caratteri (SOmma e SOttrazione hanno le prime due
					#lettere uguali, la terza mi rivela che operazione devo fare)

	beq $t2, 'm', isSum		#salto alla procedura 'somma'
	beq $t2, 't', isSubtraction 	#per esclusione salto alla procedura 'sottrazione'(eseguo comunque il controllo)

exit:
	#se sono qui la procedura chiamante a cui ritorno dev'essere main e in $ra ho già ripristinato
	#l'indirizzo di ritorno
	#devo togliere lo spazio usato per il registro $s0
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	jr $ra



#isSum, isSubtraction ecc consentono di richiamare la procedura da eseguire. In $v0 verrà salvato il valore di
#ritorno che in base a $s0 sarà salvato in $t8 (primo operando) o $t9 (secondo operando)

isSum:

	addi $a0, $a0, 6	#essendo una somma, il carattere dopo la prima parentesi aperta la trovo tra
				#6 byte/caratteri

	sw $a0, puntatore	#aggiorno variabile globale puntatore
	addi $sp, $sp, -8	#devo salvarmi $ra ed eventualmente $t8, che potrei già avere calcolato
				#oppure no (magari lo sto calcolando con questa chiamata)

	sw $ra,4($sp)	   	#salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)	   	#salvo il primo operando
	jal somma		#salto alla procedura 'somma'
	lw $t8,0($sp) 	 	#ripristina i valori salvati in precedenza nello stack frame: primo operando
	lw $ra,4($sp)	 	#e indirizzo di ritorno
	addi $sp,$sp,8 	 	#ripristina lo stack frame
	beq $s0, 1, L1		#$s0 mi dice se ho superato la virgola dell'attuale operazione, serve per capire
				#se il risultato lo devo mettere in $t8 oppure $t9

	move $t8, $v0		#copio il risultato in $t8 (primo operando)
	j loopParsing   	#rieseguo il ciclo

L1:
	move $t9, $v0		#copio il risultato in $t9 (secondo operando)
	j loopParsing   	#rieseguo il ciclo


isSubtraction:

	addi $a0, $a0, 12	#essendo una sottrazione, il carattere dopo la prima parentesi aperta la trovo
				#tra 12 byte/caratteri

	sw $a0, puntatore	#aggiorno variabile globale puntatore
	addi $sp, $sp, -8	#devo salvarmi $ra ed eventualmente $t8, che potrei già avere calcolato
				#oppure no (magari lo sto calcolando con questa chiamata)

	sw $ra,4($sp)	  	#salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)	   	#salvo il primo operando
	jal sottrazione		#salto alla procedura 'sottrazione'
	lw $t8,0($sp) 		#ripristina i valori salvati in precedenza nello stack frame: operando
	lw $ra,4($sp)		#e indirizzo di ritorno
	addi $sp,$sp,8 		#ripristina lo stack frame
	beq $s0, 1, L2		#$s0 mi dice se ho superato la virgola dell'attuale operazione, serve per
				#capire se il risultato lo devo mettere in $t8 oppure $t9

	move $t8, $v0		#copio il risultato in $t8 (primo operando)
	j loopParsing   	#rieseguo il ciclo
L2:

	move $t9, $v0		#copio il risultato in $t9 (secondo operando)
	j loopParsing  	 	#rieseguo il ciclo

isMultiplication:

	addi $a0, $a0, 9	#essendo una moltiplicazione, il carattere dopo la prima parentesi aperta la
				#trovo tra 9 byte/caratteri

	sw $a0, puntatore	#aggiorno variabile globale puntatore
	addi $sp, $sp, -8	#devo salvarmi $ra ed eventualmente $t8, che potrei già avere calcolato oppure
				#no (magari lo sto calcolando con questa chiamata)
	sw $ra,4($sp)	 	#salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)		#salvo il primo operando
	jal prodotto		#salto alla procedura 'prodotto'
	lw $t8,0($sp) 		#ripristina i valori salvati in precedenza nello stack frame: operando
	lw $ra,4($sp)		#e indirizzo di ritorno
	addi $sp,$sp,8 		#ripristina lo stack frame

	beq $s0, 1, L3		#$s0 mi dice se ho superato la virgola dell'attuale operazione, serve per capire
				#se il risultato lo devo mettere in $t8 oppure $t9

	move $t8, $v0		#copio il risultato in $t8 (primo operando)
	j loopParsing   	#rieseguo il ciclo

L3:

	move $t9, $v0		#copio il risultato in $t9 (secondo operando)
	j loopParsing  		#rieseguo il ciclo

isDivision:

	addi $a0, $a0, 10	#essendo una divisione, il carattere dopo la prima parentesi aperta la trovo
				#tra 10 byte/caratteri

	sw $a0, puntatore	#aggiorno variabile globale puntatore
	addi $sp, $sp, -8	#devo salvarmi $ra ed eventualmente $t8, che potrei già avere calcolato oppure
				#no (magari lo sto calcolando con questa chiamata)
	sw $ra,4($sp)	   	#salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)	  	#salvo il primo operando
	jal divisione		#salto alla procedura 'divisione'
	lw $t8,0($sp) 	 	#ripristina i valori salvati in precedenza nello stack frame: operando
	lw $ra,4($sp)	 	#e indirizzo di ritorno
	addi $sp,$sp,8 	 	#ripristina lo stack frame
	beq $s0, 1, L4		#$s0 mi dice se ho superato la virgola dell'attuale operazione, serve per capire
				#se il risultato lo devo mettere in $t8 oppure $t9

	move $t8, $v0		#copio il risultato in $t8 (primo operando)
	j loopParsing   	#rieseguo il ciclo
L4:

	move $t9, $v0		#copio il risultato in $t9 (secondo operando)
	j loopParsing   	#rieseguo il ciclo

insertOperando2:

	addi $t1, $t1, -48	#trasformo $t1 in un numero
	mul $t9, $t9, 10	#il valore finora letto di $t9 viene moltiplicato per 10 per sommarci la cifra
				#appena letta

	add $t9, $t9, $t1	#effettua la somma tra l'ultima cifra letta e $t9
	addi $a0, $a0, 1	#procedo al prossimo carattere
	j loopParsing		#rieseguo il ciclo


execute:
	#ho trovato una parentesi chiusa, sono qui per tornare alla procedura chiamante.
	#Valori di ritorno -> $v0: primo operando , $v1: secondo operando

	move $v0, $t8				#gli operandi sono nei registri $t8 e $t9, li sposto in $v0 e $v1
	beq $t4, 1, negativeMultiplication2	#il secondo operando potrebbe dover essere modificato,
						#controllo $t4 ed eventualmente salto

	move $v1, $t9				#copia il valore di $t9 in $v1
	lw $s0, 0($sp)				#devo ripristinare il valore di $s0 per il chiamante
	addi $sp, $sp ,4
	addi $a0, $a0, 1    			#se sono qui è perchè ho trovato una parentesi chiusa, mi sposto
						#sul prossimo carattere

	move $t8, $zero				#devo azzerare i valori di $t8 e $t9 per le prossime procedure
	move $t9, $zero				#devo azzerare i valori di $t8 e $t9 per le prossime procedure
	sw $a0, puntatore  			#aggiorno variabile globale puntatore

	#in questo caso $ra è l'indirizzo di ritorno a somma, prodotto, sottrazione o divisione
	jr $ra

#------------------------  FINE PROCEDURA PARSING -------------------------------------------------------------------------------------

#--------------------------  PROCEDURA SOMMA -------------------------------------------------------------------------------------------
somma:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui cominciare a stampare
	addi $a0, $a0, -6	#decremento di 6 byte/caratteri per tornare alla lettera 's'
	jal printOperation	#salto alla procedura 'printOperation'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack

	addi $sp, $sp, -4	#salvo solo l'indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura somma richiama 'parsing'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack

	add $v0, $v0, $v1	#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito
	addi $sp, $sp, -8	#salvo indirizzo di ritorno e risultato della somma
	sw $v0, 4($sp)
	sw $ra, 0($sp)
	move $a0, $v0 		#$a0 = risultato da stampare
	addi $a1, $zero, 1	#$a1 = 1 perche' stampo una somma
	jal printReturnOperation#salto alla procedura 'printReturnOperation'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno e risultato
	lw $v0, 4($sp)
	addi $sp, $sp, 8	#e dealloco lo stack

	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jr $ra

#-------------------------- FINE PROCEDURA SOMMA -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA SOTTRAZIONE -------------------------------------------------------------------------------------------
sottrazione:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui cominciare a stampare
	addi $a0, $a0, -12	#decremento di 12 byte/caratteri per tornare alla lettera 's'
	jal printOperation
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura sottrazione richiama la procedura 'parsing'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack
	sub $v0, $v0, $v1	#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito

	addi $sp, $sp, -8	#salvo indirizzo di ritorno e risultato della somma
	sw $v0, 4($sp)
	sw $ra, 0($sp)
	move $a0, $v0 		#$a0 = risultato da stampare
	addi $a1, $zero, 2	#$a1 = 2 perche' stampo una sottrazione
	jal printReturnOperation#salto alla procedura 'printReturnOperation'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno e risultato
	lw $v0, 4($sp)
	addi $sp, $sp, 8	#e dealloco lo stack

	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jr $ra

#-------------------------- FINE PROCEDURA SOTTRAZIONE -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA PRODOTTO -------------------------------------------------------------------------------------------
prodotto:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui cominciare a stampare
	addi $a0, $a0, -9	#decremento di 9 byte/caratteri per tornare alla lettera 'p'
	jal printOperation
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura prodotto richiama la procedura 'parsing'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack
	mul $v0, $v0, $v1	#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito
	addi $sp, $sp, -8	#salvo indirizzo di ritorno e risultato della somma
	sw $v0, 4($sp)
	sw $ra, 0($sp)
	move $a0, $v0 		#$a0 = risultato da stampare
	addi $a1, $zero, 3	#$a1 = 3 perche' stampo un prodotto
	jal printReturnOperation#salto alla procedura 'printReturnOperation'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno e risultato
	lw $v0, 4($sp)
	addi $sp, $sp, 8	#e dealloco lo stack

	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jr $ra

#-------------------------- FINE PROCEDURA PRODOTTO -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA DIVISIONE -------------------------------------------------------------------------------------------
divisione:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui cominciare a stampare
	addi $a0, $a0, -10	# decremento di 10 byte/caratteri per tornare alla lettera 'd'
	jal printOperation
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura divisione richiama la procedura 'parsing'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4	#e dealloco lo stack
	beq $v1, $zero, exitForError	#se il secondo operando è uguale a 0 devo uscire stampando un messaggio
					#di errore

	div $v0, $v1		#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito
	mflo $v0		#prendiamo il quoziente della divisione e lo mettiamo in $v0

	addi $sp, $sp, -8	#salvo indirizzo di ritorno e risultato della somma
	sw $v0, 4($sp)
	sw $ra, 0($sp)
	move $a0, $v0 		#$a0 = risultato da stampare
	addi $a1, $zero, 4	#$a1 = 4 perche' stampo una divisione
	jal printReturnOperation#salto alla procedura 'printReturnOperation'
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno e risultato
	lw $v0, 4($sp)
	addi $sp, $sp, 8	#e dealloco lo stack

	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jr $ra

#-------------------------- FINE PROCEDURA DIVISIONE -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA PRINT OPERATION -------------------------------------------------------------------------------------------
#printOperation:  $a0 -> contiene l'indirizzo del primo carattere della procedura, non ritorna niente.
#		  Esegue un ciclo che termina quando il contatore torna a 0
printOperation:

	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	move $s2, $zero				#$s2 = contatore di parentesi
	move $s0, $a0				#$s0 = puntatore del prossimo carattere da leggere

	#stampo tante indentazioni quante specificate nella variabile globale contatoreTab

	lw $t0, contatoreTab
	la $a0, strTab				#stringa di indentazione da stampare

loopTab:

	beq $t0, $zero, exitLoopTab
	li $v0, 4			#stampa stringa 'strTab'
	syscall
	addi $t0, $t0, -1       	#decremento contatore
	j loopTab

exitLoopTab:

	lw $t0, contatoreTab		#aumento contatoreTab per la prossima stampa
	addi $t0, $t0, 1
	sw $t0, contatoreTab

	#stampa freccia (--> )

	li $v0, 11			#stampo '-'
	addi $a0, $zero, 45
	syscall
	li $v0, 11			#stampo '-'
	addi $a0, $zero, 45
	syscall
	li $v0, 11			#stampo '>'
	addi $a0, $zero, 62
	syscall
	li $v0, 11			#stampo ' '
	addi $a0, $zero, 32
	syscall

loopPrimoCiclo:		#il primo ciclo stampa la sottostringa esistente fino alla prima parentesi tonda

	lb  $s1, 0($s0)			# $s1 = carattere letto
	li $v0, 11			#stampo il carattere letto
	move $a0, $s1
	syscall
	beq $s1, '(', exitLoop1		#controllo se ho letto una '(' .Se l'ho letta salto a 'exitLoop1'
	addi $s0, $s0, 1
	j loopPrimoCiclo		#rieseguo il ciclo di lettura e stampa

exitLoop1:

	addi $s0, $s0, 1
	addi $s2, $s2, 1 		#incremento il contatore

loopSecondoCiclo:

	ble $s2, 0, exitLoop2		#esci dal ciclo se contatore <= 0
	lb  $s1, 0($s0)			# $s1 = carattere letto
	li $v0, 11			#stampo il carattere letto
	move $a0, $s1
	syscall
	addi $s0, $s0, 1		#incremento il puntatore
	beq $s1, ')', decremento	# se ho letto una ')' devo decrementare il contatore di parentesi
	beq $s1, '(', incremento	# se ho letto una '(' devo incrementare il contatore di parentesi
	beq $s1, $zero, exitLoop2	# se ho letto zero la stringa è terminata, quindi esco dal ciclo
	j loopSecondoCiclo		# rieseguo il ciclo di lettura e stampa

incremento:

	addi $s2, $s2, 1		#incremento il contatore di parentesi
	j loopSecondoCiclo		# rieseguo il ciclo di lettura e stampa

decremento:

	addi $s2, $s2, -1		#decremento il contatore
	j loopSecondoCiclo		# rieseguo il ciclo di lettura e stampa

exitLoop2:

	li $v0, 11			#stampo un ritorno a capo (\n)
	addi $a0, $zero, 10
	syscall
	li $v0, 11
	addi $a0, $zero, 13
	syscall
	lw $s2, 8($sp)			#ripristino i registri modificati dalla procedura
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12
	jr $ra

#-------------------------- FINE PROCEDURA PRINT OPERATION -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA PRINT RETURN OPERATION -------------------------------------------------------------------------------------------
#printReturnOperation:  stampa il valore di ritorno dell'operazione appena eseguita, riceve $a0 = valore da stampare,
# 			$a1 = codice della procedura da stampare 1->somma, 2->sottrazione, 3->prodotto, 4->divisione
printReturnOperation:

	move $t0, $a0		#$t0 = valore da stampare
	move $t1, $a1		#$t1 = carattere della procedura da stampare

	#stampo tante indentazioni quante specificate nella variabile globale contatoreTab

	lw $t2, contatoreTab
	addi $t2, $t2, -1
	la $a0, strTab		#stringa di indentazione da stampare

loopTab2:

	beq $t2, $zero, exitLoopTab2
	li $v0, 4		# stampa stringa 'strTab'
	syscall
	addi $t2, $t2, -1   	#decremento contatore
	j loopTab2

exitLoopTab2:

	lw $t2, contatoreTab	#decremento contatoreTab per la prossima stampa
	addi $t2, $t2, -1
	sw $t2, contatoreTab

	#controllo quale procedura devo stampare

	beq $t1, 1, strSomma
	beq $t1, 2, strSottrazione
	beq $t1, 3, strProdotto

	la $a0, strReturnDivisione	#per esclusione la procedura e' divisione
	j L5

strSomma:

	la $a0, strReturnSomma
	j L5

strSottrazione:

	la $a0, strReturnSottrazione
	j L5

strProdotto:

	la $a0, strReturnProdotto

L5:

	li $v0, 4		# stampa stringa strReturnDivisione
	syscall
	li $v0, 1		# stampa intero
	move $a0, $t0
	syscall
	li $v0, 11		# stampa parentesi
	addi $a0, $zero, 41
	syscall
	li $v0, 11
	addi $a0, $zero, 10
	syscall
	li $v0, 11
	addi $a0, $zero, 13
	syscall
	jr $ra

#-------------------------- FINE PROCEDURA PRINT RETURN OPERATION -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA READ FUNCTION -------------------------------------------------------------------------------------------
#readFuntion: procedura per apertura del file e caricamento della stringa che rappresenta la funzione

readFunction:

	# Open File

	li $v0, 13		#Open File Syscall
	la $a0, file		#Load File Name
	li $a1, 0		#Read-only Flag
	li $a2, 0
	syscall
	move $t0, $v0		#Save File Descriptor
	blt $v0, 0, err		#Goto Error

	# Read Data

	li $v0, 14		#Read File Syscall
	move $a0, $t0		#Load File Descriptor
	la $a1, bufferString    #Load Buffer Address
	li $a2, 150		#Buffer Size
	syscall

	# Close File

	li $v0, 16		#Close File Syscall
	move $a0, $t0		#Load File Descriptor
	syscall
	jr $ra

	# Error

err:

	li $v0, 4		# Print String Syscall
	la $a0, fnf		# Load Error String
	syscall
	li $v0, 10		#termino esecuzione
	syscall

#-------------------------- FINE PROCEDURA READ FUNCTION -------------------------------------------------------------------------------------------
