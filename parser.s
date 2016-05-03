#Mauro Matteo - Busiello Salvatore - Milicia Lorenzo


# Legenda registri usati
# $t0 = indirizzo del prossimo carattere da cui fa partire il parsing



.data

jump_table: .space 16 # jump table array a 4 word che verra' instanziata dal main con gli indirizzi delle label che chiameranno le corrispondenti procedure
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

	#prepara la jump_table con gli indirizzi delle case actions
	la $t1, jump_table
	la $t0, jumpSum
	sw $t0, 0($t1)
 	la $t0, jumpSubtraction
	sw $t0, 4($t1)
	la $t0, jumpMultiplication
	sw $t0, 8($t1)
	la $t0, jumpDivision
	sw $t0, 12($t1)

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno (non mi interessa che $t0 e $t1 vengano modificati)
	sw $ra, 0($sp)
	la $a0, bufferString	#bufferString = stringa che rappresenta la funzione, viene passato come argomento per la procedura parsing
	jal parsing
	lw $ra, 0($sp)		# ripristino indirizzo di ritorno
	addi $sp, $sp, 4	# e dealloco lo stack

	#$v0 = codice con procedura da eseguire
	#calcolo velocemente a quale procedura saltare con la jump_table, mi evita di
	#riscrivere per tutte le procedure il costrutto if than...else if...
	add $t4, $v0, $v0
	add $t4, $t4, $t4 	
	lw $t5, jump_table($t4) # ho calcolato jump_table[$v0], $t5 contiene indirizzo della case action a cui saltare
	jr $t5
	

# costrutto switch per saltare alla giusta procedura da ogni procedura chiamante
jumpSum:
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	jal somma
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4
	jr $ra
jumpSubtraction:
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	jal sottrazione
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4
	jr $ra
jumpMultiplication:
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	jal prodotto
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4
	jr $ra
jumpDivision:
	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	jal divisione
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4
	jr $ra


endOfString:
	#sout	 finale

#--------------------------- PROCEDURA PARSING   ---------------------------------------------------------------------------------------
#parsing: procedura che si occupa di analizzare la funzione e di invocare la giusta procedura
parsing:
	move $t0, $a0 		#salvo indirizzo del carattere iniziale, mi servira' dopo
loopParsing:
	lb $t1, 0($a0)		#leggo un carattere
	beq $t1, '(', checkOperation	#se trovo una parentesi aperta devo capire che operazione dovro' svolgere
	beq $t1, ')', execute	#se trovo una parentesi chiusa devo caricare gli operandi e tornare all'ultima procedura chiamata
	beq $t1, ',', ignore	#ignora la virgola
	bge $t1, 'a', ignore    #ignora un carattere
	beq $t1, $zero, endOfString	#ignora la virgola

	#se sono arrivato qui ho trovato un operando
	addi $sp, $sp, -4
	sw $t1, 0($sp)		#salvo nello stack l'operando
ignore:
	addi $a0, $a0, 1	# $a0 = offset
	j loopParsing

checkOperation: #individua l'operazione da svolgere
	lb $t2, 0($t0) 		#$t2 = lettera iniziale da controllare per individuare l'operazione
	beq $t2, 'd', isDivision	#salto alla divisione
	beq $t2, 'p', isMultiplication	#salto alla moltiplicazione
	lb $t2, 2($t0) 		#mi sposto di 2 byte/caratteri (SOmma e SOttrazione hanno le prime due lettere uguali, la terza mi rivela che operazione devo fare)
	beq $t2, 'm', isSum	# salto alla somma
	beq $t2, 't', isSubtraction #per esclusione salto a sottrazione (eseguo comunque il controllo)

# isSum, isSubtraction ecc consentono di ritornare alla procedura chiamante con un valore di ritorno ($v0)
# che rappresenta la prossima procedura da chiamare, in particolare
# 0 -> Somma, 1 -> Sottrazione, 2 -> Moltiplicazione, 3 -> Divisione
isSum:
	addiu $v0, $zero, 0
	add $a0,$a0,1	# $a0 incrementato di un byte, perchè punta al prossimo carattere della stringa
	sw $a0, puntatore  # la word puntatore è una variabile globale che conterrà sempre l'indirizzo del carattere da cui ripartire nel prossimo parsing
	jr $ra
isSubtraction:
	addiu $v0, $zero, 1
	add $a0,$a0,1	#ritorno $a0 incrementato di un byte, perchè punta al prossimo carattere della stringa
	sw $a0, puntatore  # la word puntatore è una variabile globale che conterrà sempre l'indirizzo del carattere da cui ripartire nel prossimo parsing
	jr $ra
isMultiplication:
	addiu $v0, $zero, 2
	add $a0,$a0,1	#ritorno $a0 incrementato di un byte, perchè punta al prossimo carattere della stringa
	sw $a0, puntatore  # la word puntatore è una variabile globale che conterrà sempre l'indirizzo del carattere da cui ripartire nel prossimo parsing	
	jr $ra
isDivision:
	addiu $v0, $zero, 3
	add $a0,$a0,1	#ritorno $a0 incrementato di un byte, perchè punta al prossimo carattere della stringa
	sw $a0, puntatore  # la word puntatore è una variabile globale che conterrà sempre l'indirizzo del carattere da cui ripartire nel prossimo parsing	
	jr $ra 
# ho trovato una parentesi chiusa, devo eseguire l'operazione associata alla procedura chiamante
# ritorno -1 perche' non devo chiamare altre procedure
execute:
	addiu $v0, $zero, -1
	sw $a0, puntatore  # la word puntatore è una variabile globale che conterrà sempre l'indirizzo del carattere da cui ripartire nel prossimo parsing
	jr $ra
	

#------------------------  FINE PROCEDURA PARSING -------------------------------------------------------------------------------------



#--------------------------  PROCEDURA SOMMA -------------------------------------------------------------------------------------------
somma:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = word che rappresenta l'indirizzo da cui continuare il parsing, è l'unico argomento della procedura parsing
	jal parsing
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4

	#$v0 = codice con procedura da eseguire
	beq $v0, -1, executionSum    #if( $v0 == -1) salta a executionSum
				     #else devo chiamare una sottoprocedura
	add $t4, $v0, $v0
	add $t4, $t4, $t4
	lw $t5, jump_table($t4) # ho calcolato jump_table[$v0], $t5 contiene indirizzo della case action a cui saltare
	jr $t5
executionSum:
	add $t8, $t8, $t9
	
	
	#e inserisci nello stack più o meno lo schema è questo

	jr $ra
#-------------------------- FINE PROCEDURA SOMMA -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA SOTTRAZIONE -------------------------------------------------------------------------------------------
sottrazione:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = word che rappresenta l'indirizzo da cui continuare il parsing, è l'unico argomento della procedura parsing
	jal parsing
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4

	#$v0 = codice con procedura da eseguire
	beq $v0, -1, executionSub    #if( $v0 == -1) salta a executionSub
				     #else devo chiamare una sottoprocedura
	add $t4, $v0, $v0
	add $t4, $t4, $t4 
	lw $t5, jump_table($t4) # ho calcolato jump_table[$v0], $t5 contiene indirizzo della case action a cui saltare
	jr $t5

executionSub:
	sub $t8, $t8, $t9
	#e inserisci nello stack più o meno lo schema è questo

	jr $ra
#-------------------------- FINE PROCEDURA SOTTRAZIONE -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA PRODOTTO -------------------------------------------------------------------------------------------
prodotto:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = word che rappresenta l'indirizzo da cui continuare il parsing, è l'unico argomento della procedura parsing
	jal parsing
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4

	#$v0 = codice con procedura da eseguire
	beq $v0, -1, executionMul    #if( $v0 == -1) salta a executionMul
				     #else devo chiamare una sottoprocedura
	add $t4, $v0, $v0
	add $t4, $t4, $t4 
	lw $t5, jump_table($t4) # ho calcolato jump_table[$v0], $t5 contiene indirizzo della case action a cui saltare
	jr $t5

executionMul:
	mul $t8, $t8, $t9
	#e inserisci nello stack più o meno lo schema è questo
	jr $ra
#-------------------------- FINE PROCEDURA PRODOTTO -------------------------------------------------------------------------------------------

#--------------------------  PROCEDURA DIVISIONE -------------------------------------------------------------------------------------------
divisione:

	addi $sp, $sp, -4	#salvo solo indirizzo di ritorno
	sw $ra, 0($sp)
	lw $a0, puntatore	#puntatore = word che rappresenta l'indirizzo da cui continuare il parsing, è l'unico argomento della procedura parsing
	jal parsing
	lw $ra, 0($sp)		#ripristino indirizzo di ritorno
	addi $sp, $sp, 4

	#$v0 = codice con procedura da eseguire
	beq $v0, -1, executionDiv    #if( $v0 == -1) salta a executionDiv
				     #else devo chiamare una sottoprocedura
	add $t4, $v0, $v0
	add $t4, $t4, $t4 
	lw $t5, jump_table($t4) # ho calcolato jump_table[$v0], $t5 contiene indirizzo della case action a cui saltare
	jr $t5

executionDiv:
	div $t8, $t8, $t9
	#e inserisci nello stack più o meno lo schema è questo

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
