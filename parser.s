#Mauro Matteo - Busiello Salvatore - Milicia Lorenzo



.data

fnf:	.ascii  "The file was not found: "
file:	.asciiz	"chiamate.txt"
bufferString: .space 150
puntatore: .word bufferString


.text
.globl main
main:
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno (non ho usato altri registri)
	sw $ra, 0($sp)

	jal readFunction	#procedura per salvare in buffer la stringa che rappresenta la funzione

	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4


	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	la $a0, bufferString	#bufferString = stringa che rappresenta la funzione, viene passato come argomento per la procedura parsing
	jal parsing		#la procedura main richiama parsing 
	lw $ra, 0($sp)		# ripristino indirizzo di ritorno
	addi $sp, $sp, 4	# e dealloco lo stack
	
	#stampa risultato finale
	move $t5, $v0
	li $v0, 1
	add $a0, $zero, $t5
	syscall
	
	li $v0, 10
	syscall
	
#	jr $ra	#terminazione programma


#--------------------------- PROCEDURA PARSING   ---------------------------------------------------------------------------------------
#parsing: procedura che si occupa di analizzare la stringa e fornire gli operandi necessari alla procedura chiamante,
#	  questo implica che al suo interno possono essere richiamate ulteriori procedure, nel caso in cui appaiano come 
# 	  operandi della procedura chiamante
parsing:
	move $t0, $a0 		#salvo indirizzo del carattere iniziale, mi servira' dopo (nella callProcedure)
	addi $sp, $sp, -4
	sw $s0, 0($sp)		#salvo il valore di $s0, dato che all'inizio $s0 sarà uguale a 0 (non ho ancora raggiunto la virgola ovviamente)
	move $s0, $zero
loopParsing:
	lb $t1, 0($a0)		#leggo un carattere
	beq $t1, ' ', ignore	#se trovo uno spazio la ignoro
	beq $t1, '(', ignore	#se trovo una parentesi aperta la ignoro
	beq $t1, ')', execute	#se trovo una parentesi chiusa devo eseguire l'operazione ritornando alla procedura chiamante
	beq $t1, ',', flag	#se trovo una virgola devo aggiornare $s0 che mi dice se ho già trovato il primo operando
	beq $t1, $zero, exit	#se trovo zero significa che sono arrivato alla fine del file, perciò ho già calcolato il risultato finale
	bge $t1, 'a', callProcedure    #se trovo una lettera allora devo richiamare una procedura, salto a callProcedure per capire quale

	#se sono arrivato qui ho trovato un operando per esclusione
	#il primo e secondo operando vanno salvati rispettivamente in $t8 e $t9, $s0 mi dice quale
	beq $s0, 1, insertOperando2	#altrimenti metto il primo operando in $t8
	addi $t1, $t1, -48
	move $t8, $t1	# $v0 è ovviamente il valore di ritorno dell'operazione appena ritornata
	addi $a0, $a0, 1	# $a0 = offset
	j loopParsing
	
flag:	# modifico $s0 con valore 1, così dopo capisco che ho trovato il primo operando (devo gestire in quali registri inserire i valori di ritorno)
	addi $s0, $zero, 1
	#ripristino inizio sottostringa da dopo la virgola
	move $t0, $a0
	addi $t0, $t0, 1
	#procedo direttamente all'etichetta sotto per incrementare offset e rieseguire il cicl
ignore:
	addi $a0, $a0, 1	# $a0 = offset
	j loopParsing

callProcedure: #individua l'operazione da svolgere
	move $t2, $t1		# uso $t2 come appoggio per la lettera che ho trovato
	beq $t2, 'd', isDivision	#salto alla divisione
	beq $t2, 'p', isMultiplication	#salto alla moltiplicazione
	lb $t2, 2($t0) 		#mi sposto di 2 byte/caratteri (SOmma e SOttrazione hanno le prime due lettere uguali, la terza mi rivela che operazione devo fare)
	beq $t2, 'm', isSum	# salto alla somma
	beq $t2, 't', isSubtraction #per esclusione salto a sottrazione (eseguo comunque il controllo)
	
exit:
	addi $sp, $sp ,4
	addi $a0, $a0, 1    # se sono qui è perchè ho trovato una parentesi chiusa, mi sposto sul prossimo carattere
	jr $ra



# isSum, isSubtraction ecc consentono di richiamare la procedura da eseguire e ritornano al ciclo, il valore di ritorno delle procedure è salvato
# in $v0 se non ho ancora raggiunto la virgola, altrimenti in $v1 (in sostanza simulano un costrutto if...else if...)
isSum:
	addi $a0, $a0, 6	#essendo una somma, il carattere dopo la prima parentesi aperta la trovo tra 6 byte/caratteri
	sw $a0, puntatore
	addi $sp, $sp, -8	#devo salvarmi ra ed eventualmente $t8, che potrei già avere calcolato oppure no (magari lo sto calcolando con questa chiamata)
	sw $ra,4($sp)	   # salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)	   # salva il parametro d'invocazione
	jal somma
	lw $t8,0($sp) 	 # ripristina i valori salvati in precedenza nello stack frame: operando
	lw $ra,4($sp)	 # e indirizzo di ritorno
	addi $sp,$sp,8 	 # ripristina lo stack frame
	add $t1, $zero, $v0	 #inserisco in $t1 il valore di ritorno ($t1 conteneva al massimo l'ultimo carattere della stringa letto, non mi interessa)
	beq $s0, 1, L1	# $s0 mi dice se ho superato la virgola dell'attuale operazione, serve per capire se il risultato
					# lo devo mettere in $t8 oppure $t9
	move $t8, $t1	# $v0 è ovviamente il valore di ritorno dell'operazione appena ritornata
	addi $a0, $a0, 1	# $a0 = offset
	j loopParsing   # rieseguo il ciclo 
L1:
	move $t9, $t1	# $v0 è ovviamente il valore di ritorno dell'operazione appena ritornata
	addi $a0, $a0, 1	# $a0 = offset
	j loopParsing   # rieseguo il ciclo 
	
	
	
isSubtraction:
	addi $a0, $a0, 12	#essendo una sottrazione, il carattere dopo la prima parentesi aperta la trovo tra 12 byte/caratteri
	addi $sp, $sp, -8	#devo salvarmi ra ed eventualmente $t8, che potrei già avere calcolato oppure no (magari lo sto calcolando con questa chiamata)
	sw $ra,4($sp)	   # salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)	   # salva il parametro d'invocazione
	jal sottrazione
	lw $t8,0($sp) 	 # ripristina i valori salvati in precedenza nello stack frame: operando
	lw $ra,4($sp)	 # e indirizzo di ritorno
	addi $sp,$sp,8 	 # ripristina lo stack frame
	add $t1, $zero, $v0	 #inserisco in $t1 il valore di ritorno ($t1 conteneva al massimo l'ultimo carattere della stringa letto, non mi interessa)
	beq $s0, 1, insertOperando2	# $s0 mi dice se ho superato la virgola dell'attuale operazione, serve per capire se il risultato
					# lo devo mettere in $t8 oppure $t9
	move $t8, $v0	# $v0 è ovviamente il valore di ritorno dell'operazione appena ritornata
	j loopParsing   # rieseguo il ciclo 


	
isMultiplication:
	addi $a0, $a0, 9	#essendo un prodotto, il carattere dopo la prima parentesi aperta la trovo tra 9 byte/caratteri
	addi $sp, $sp, -8	#devo salvarmi ra ed eventualmente $t8, che potrei già avere calcolato oppure no (magari lo sto calcolando con questa chiamata)
	sw $ra,4($sp)	   # salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)	   # salva il parametro d'invocazione
	jal prodotto
	lw $t8,0($sp) 	 # ripristina i valori salvati in precedenza nello stack frame: operando
	lw $ra,4($sp)	 # e indirizzo di ritorno
	addi $sp,$sp,8 	 # ripristina lo stack frame
	add $t1, $zero, $v0	 #inserisco in $t1 il valore di ritorno ($t1 conteneva al massimo l'ultimo carattere della stringa letto, non mi interessa)
	beq $s0, 1, insertOperando2	# $s0 mi dice se ho superato la virgola dell'attuale operazione, serve per capire se il risultato
					# lo devo mettere in $t8 oppure $t9
	move $t8, $v0	# $v0 è ovviamente il valore di ritorno dell'operazione appena ritornata
	j loopParsing   # rieseguo il ciclo 

	 
	   
isDivision:
	addi $a0, $a0, 10	#essendo una divisione, il carattere dopo la prima parentesi aperta la trovo tra 10 byte/caratteri
	addi $sp, $sp, -8	#devo salvarmi ra ed eventualmente $t8, che potrei già avere calcolato oppure no (magari lo sto calcolando con questa chiamata)
	sw $ra,4($sp)	   # salva l'indirizzo di ritorno al chiamante
	sw $t8,0($sp)	   # salva il parametro d'invocazione
	jal divisione
	lw $t8,0($sp) 	 # ripristina i valori salvati in precedenza nello stack frame: operando
	lw $ra,4($sp)	 # e indirizzo di ritorno
	addi $sp,$sp,8 	 # ripristina lo stack frame
	add $t1, $zero, $v0	 #inserisco in $t1 il valore di ritorno ($t1 conteneva al massimo l'ultimo carattere della stringa letto, non mi interessa)
	beq $s0, 1, insertOperando2	# $s0 mi dice se ho superato la virgola dell'attuale operazione, serve per capire se il risultato
					# lo devo mettere in $t8 oppure $t9
	move $t8, $v0	# $v0 è ovviamente il valore di ritorno dell'operazione appena ritornata
	j loopParsing   # rieseguo il ciclo 


	
insertOperando2:
	addi $t1, $t1, -48
	move $t9, $t1	# $v0 è ovviamente il valore di ritorno dell'operazione appena ritornata
	addi $a0, $a0, 1	# $a0 = offset
	j loopParsing	# rieseguo il ciclo 
	
	
execute:	# ho trovato una parentesi chiusa, sono qui per tornare alla procedura chiamante con $v0: primo operando e $v1: secondo operando
	move $v0, $t8	# gli operandi sono nei registri $t8 e $t9, li sposto in $v0 e $v1
	move $v1, $t9	
	lw $s0, 0($sp)	#devo ripristinare il valore di $s0 per il chiamante
	addi $sp, $sp ,4
	addi $a0, $a0, 1    # se sono qui è perchè ho trovato una parentesi chiusa, mi sposto sul prossimo carattere
	sw $a0, puntatore  # la word puntatore è una variabile globale che conterrà sempre l'indirizzo del carattere da cui ripartire nel prossimo parsing
	jr $ra

#------------------------  FINE PROCEDURA PARSING -------------------------------------------------------------------------------------



#--------------------------  PROCEDURA SOMMA -------------------------------------------------------------------------------------------
somma:
	
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura main richiama parsing 
	lw $ra, 0($sp)		# ripristino indirizzo di ritorno
	addi $sp, $sp, 4	# e dealloco lo stack
	add $v0, $v0, $v1	#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito
	jr $ra
#-------------------------- FINE PROCEDURA SOMMA -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA SOTTRAZIONE -------------------------------------------------------------------------------------------
sottrazione:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	la $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura main richiama parsing 
	lw $ra, 0($sp)		# ripristino indirizzo di ritorno
	addi $sp, $sp, 4	# e dealloco lo stack
	sub $v0, $v0, $v1	#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito
	jr $ra
#-------------------------- FINE PROCEDURA SOTTRAZIONE -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA PRODOTTO -------------------------------------------------------------------------------------------
prodotto:
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	la $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura main richiama parsing 
	lw $ra, 0($sp)		# ripristino indirizzo di ritorno
	addi $sp, $sp, 4	# e dealloco lo stack
	mul $v0, $v0, $v1	#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito
	jr $ra
#-------------------------- FINE PROCEDURA PRODOTTO -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA DIVISIONE -------------------------------------------------------------------------------------------
divisione:
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	la $a0, puntatore	#puntatore = indirizzo del carattere da cui ripartire per il parsing
	jal parsing		#la procedura main richiama parsing 
	lw $ra, 0($sp)		# ripristino indirizzo di ritorno
	addi $sp, $sp, 4	# e dealloco lo stack
	div $v0, $v0, $v1	#calcolo direttamente in $v0 la somma degli operandi che parsing mi ha fornito
	jr $ra
#-------------------------- FINE PROCEDURA DIVISIONE -------------------------------------------------------------------------------------------



#--------------------------  PROCEDURA PRINT OPERATION -------------------------------------------------------------------------------------------

printOperation:

#-------------------------- FINE PROCEDURA PRINT OPERATION -------------------------------------------------------------------------------------------





#--------------------------  PROCEDURA READ FUNCTION -------------------------------------------------------------------------------------------

#readFuntion: procedura per apertura del file e caricamento della stringa che rappresenta la funzione
readFunction:
	# Open File
	li	$v0, 13		# Open File Syscall
	la	$a0, file	# Load File Name
	li	$a1, 0		# Read-only Flag
	li	$a2, 0		# (ignored)
	syscall
	move	$t0, $v0	# Save File Descriptor
	blt	$v0, 0, err	# Goto Error

	# Read Data
	li	$v0, 14		# Read File Syscall
	move	$a0, $t0	# Load File Descriptor
	la	$a1, bufferString  # Load Buffer Address
	li	$a2, 150	# Buffer Size
	syscall

	# Close File
	li	$v0, 16		# Close File Syscall
	move	$a0, $t0	# Load File Descriptor
	syscall
	jr $ra

	# Error
err:
	li	$v0, 4		# Print String Syscall
	la	$a0, fnf	# Load Error String
	syscall
	li      $v0, 10		#termino esecuzione
	syscall
#-------------------------- FINE PROCEDURA READ FUNCTION -------------------------------------------------------------------------------------------
