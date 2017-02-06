/*********
 * 
 * Write the assembly function:
 *     printn ( char * , ... ) ;
 * Use the following C functions:
 *     printHex ( int ) ;
 *     printOct ( int ) ;
 *     printDec ( int ) ;
 * 
 * Note that 'a' is a valid integer, so movi r2, 'a' is valid, and you don't need to look up ASCII values.
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
  addi sp, sp, -20
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw r18, 8(sp)
  stw r19, 12(sp) # unused
  stw r20, 16(sp)

  # init local variables
  # character lookup table
  movia r16, 'O'
  movia r17, 'D'
  movia r18, 'H'
  # char array index
  mov r20, r4

LOOP:
  ldw r4, 0(r20) # load each char in string
  beq r4, r16, Octal # if(char == 'O')
  beq r4, r17, Decimal # if(char == 'D')
  beq r4, r18, Hex # if(char == 'H')
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
	ldw r19, 12(sp) # unused
	ldw r20, 16(sp)
  addi sp, sp, 20

  # restore ra
  ldw ra, 0(sp)
  addi sp, sp, 4

  # shrink stack
  addi sp, sp, 16
  ret


