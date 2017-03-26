	.equ RED_LEDS, 0xFF200000 	   # (From DESL website > NIOS II > devices)

	.data                              # "data" section for input and output lists

	IN_LIST:                  	   # List of 10 signed halfwords starting at address IN_LIST
	    .hword 1
	    .hword -1
	    .hword -2
	    .hword 2
	    .hword 0
	    .hword -3
	    .hword 100
	    .hword 0xff9c
	    .hword 0b1111
	LAST:			 	    # These 2 bytes are the last halfword in IN_LIST
	    .byte  0x01		  	    # address LAST
	    .byte  0x02		  	    # address LAST+1
	    
	IN_LINKED_LIST:                     # Used only in Part 3
	    A: .word 1
	       .word B
	    B: .word -1
	       .word C
	    C: .word -2
	       .word E + 8
	    D: .word 2
	       .word C
	    E: .word 0
	       .word K
	    F: .word -3
	       .word G
	    G: .word 100
	       .word J
	    H: .word 0xffffff9c
	       .word E
	    I: .word 0xff9c
	       .word H
	    J: .word 0b1111
	       .word IN_LINKED_LIST + 0x40
	    K: .byte 0x01		    # address K
	       .byte 0x02		    # address K+1
	       .byte 0x03		    # address K+2
	       .byte 0x04		    # address K+3
	       .word 0

	OUT_NEGATIVE:
	    .skip 40                         # Reserve space for 10 output words

	OUT_POSITIVE:
	    .skip 40                         # Reserve space for 10 output words

	#-----------------------------------------

	.text                  # "text" section for code

	    # Register allocation:
	    #   r0 is zero, and r1 is "assembler temporary". Not used here.
	    #   r2  Holds the number of negative numbers in the list
	    #   r3  Holds the number of positive numbers in the list
	    #   r9  A pointer to array element
	    #   r10 loop counter for LOOP_LIST
      #   r11 list length (10)
	    #   r16, r17 Short-lived temporary values.
	    #   r18, r19 pointer to output array element

	.global _start
	_start:

	# Your program here. Pseudocode and some code done for you:
  movia r2, 0
  movia r3, 0
  movia r9, IN_LIST
  movia r10, 0
  movia r11, 10
  movia r18, OUT_POSITIVE
  movia r19, OUT_NEGATIVE

LOOP_LIST:
  bge r10, r11, DISPLAY_RESULT /* test for end of array */

  ldh r16, 0(r9) /* load list item to r16 */
  addi r9, r9, 2
  addi r10, r10, 1
  bgt r16, r0, POSITIVE # r16 > 0 -> positive
  blt r16, r0, NEGATIVE # r16 < 0 -> negative
  br DISPLAY_RESULT # 0 -> end of list

POSITIVE:
  stw r16, 0(r18) # store to OUTPUT POSITIVE
  addi r18, r18, 4 # increment pointer
  addi r3, r3, 1
  br LOOP_LIST

NEGATIVE:
  stw r16, 0(r19) # store to OUTPUT NEGATIVE
  addi r19, r19, 4
  addi r2, r2, 1
  br LOOP_LIST

	# Begin loop to process each number

	        # Process a number here:
	        #    if (number is negative) { 
	        #        insert number in OUT_NEGATIVE list
	        #        increment count of negative values (r2)
	        #    } else if (number is positive) { 
	        #        insert number in OUT_POSITIVE list
	        #        increment count of positive values (r3)
	        #    }
	        # Done processing.


	# (You'll learn more about I/O in Lab 4.)	DISPLAY_RESULT:
	movia  r16, RED_LEDS          # r16 and r17 are temporary values
	slli r8, r3, 4
	movia r17, 0
	add r17, r2, r8
	stwio  r17, 0(r16)


	# Finished output to LEDs.
	# End loop


	LOOP_FOREVER:
	    br LOOP_FOREVER                   # Loop forever.
