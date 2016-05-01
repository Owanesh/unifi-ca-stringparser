i.data   ## Definisco la parte generale delle variabili

## ============= VARIABILI PER OUTPUT =============== ##
str_insertname: .asciiz "Insert your name \n here: "     ## Carica stringa in memoria, con carattere terminale
str_welcome: .asciiz "\nBenvenuto "

 ## ============= VARIABILI PER INPUT =============== ##
input_name_21: .space 21 ## Considerare il ventunesimo comme carattere di finestringa
.text                    ## Serve a far capire all'assemblatore che da questo punto in poi, ci sono istruzioni e non piu' dati
## ======== DEFINIZIONE FUNZIONI GLOBALI  ========== ##
.globl main   ## funzione pubblica main, ti permette di usarla in tutta la classe

main:
  la $a0 str_insertname    # Nell'indirizzo a0 ci carico la stringa0
  li $v0,4                 # Caricare in un registro, un valore costante, lo stesso valore che corrisponde ad una funzione che verrà poi eseguita con la chiamata successiva
  syscall                  # Esegue la funzione correlata al registro

  li $v0, 8               # Valore per aspettarsi un input da tastiera
  la $a0, input_name_21   # Memorizzo l'input da tastiera nella variabile "nomeinserito"
  li $a1,21               # La lunghezza massima consentita durante l'input da tastiera, memorizzato nel registro $a1, che viene poi visto dalla syscall
  syscall

  li $v0, 4         # 4 = print_string
  la $a0, str_welcome
  syscall

  li $v0, 4
  la $a0, input_name_21
  syscall

  li $v0, 10          # 10 = uscita dal programma
  syscall



###############################################
#==== 14 Marzo 2016   =====      Elaboratori  #
###############################################
