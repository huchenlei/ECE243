/*********
 * 
 * Write the assembly function:
 *     printn ( char * , ... ) ;
 * Use the following C functions:
 *     printHex ( int ) ;
 *     printOct ( int ) ;
 *     printDec ( int ) ;
 * 
 * Note that 'a' is a valid integer, so movi r2, 'a' is valid, and you dont  need to look up ASCII values.
 *********/

.global	printn

printn:
  # Callee Prologue
  addi sp, sp, -16 # save param 1~4
  stw r4, 0(sp)
  stw r5, 4(sp)
  stw r6, 8(sp)
  stw r7, 12(sp)
  
  addi sp, sp, -4 # save ra
  stw ra, 0(sp)

  # save callee save regs
  addi sp, sp, -24
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw r18, 8(sp)
  stw r19, 12(sp)
  stw r20, 16(sp)
  stw r21, 20(sp)   # r21 char read

  # init local variables
  # r19 pointer to param list on stack
  addi r19, sp, 4 + 24
  # character lookup table
  movia r16, 'O'
  movia r17, 'D'
  movia r18, 'H'
  # char array index
  mov r20, r4

LOOP:
  ldb r21, 0(r20) # load each char in string
  addi r20, r20, 1 # increment string char pointer
  ldw r4, 4(r19) # read next param start from 2nd param
  addi r19, r19, 4
  
  beq r21, r16, Octal # if(char == 'O')
  beq r21, r17, Decimal # if(char == 'D')
  beq r21, r18, Hex # if(char == 'H')
  br RET # else return

Octal:
  call printOct
  br LOOP

Decimal:
  call printDec
  br LOOP

Hex:
  call printHex
  br LOOP

RET:
  # restore callee save
	ldw r16, 0(sp)
	ldw r17, 4(sp)
	ldw r18, 8(sp)
	ldw r19, 12(sp) 
	ldw r20, 16(sp)
	ldw r21, 20(sp)
  addi sp, sp, 24

  # restore ra
  ldw ra, 0(sp)
  addi sp, sp, 4

  # shrink stack
  addi sp, sp, 16
  ret


