.equ RED_LEDS, 0xFF200000

/* List of registers utilized:
r2: pointer in array                 r6: index in the array
r3: value displayed                  r7: temporary register
r4: address of LEDs                  r9: counter in delay loop
r5: length of the array                                        */

array:
.byte 1
.byte 2
.byte 3
.byte 2
.byte 1

.global _start
_start:
movia r4,RED_LEDS  /* Get location of LED device */
movia r2,array     /* Get location of array: char *p = array; */
movi r3,0          /* initialize value displayed */
movi r6,0          /* initialize counter */
movi r5,5          /* set length of the array */

RESET_PTR:
  movi r2, array # reset array pointer
  movi r6, 0 # reset loop counter

LOOP:
  bge r6,r5,RESET_PTR    /* test for end of array */

  ldb r7,0(r2)       /* load digit from array: r7 = *p; */
  or r3,r3,r7        /* insert character in string of digits */
  stwio r3,0(r4)     /* write to the red LEDs */
  addi r2,r2,1       /* increment address: p++ */
  slli r3,r3,2       /* shift string to the left */

  addi r6,r6,1

  movia r9,40000000 /* set starting point for delay counter */

  DELAY:
    subi r9,r9,1       # subtract 1 from delay
  bne r9,r0, DELAY   # continue subtracting if delay has not elapsed
br LOOP            # delay elapsed, redo the LOOP
                   # Make sure there is always a newline at the end of the file.

