  /*
    This function delays the process N timer cycles
    void delay(int N)
  */
  .equ TIMER, 0xFF202000

  delay:
    # Callee Prologue
    # only one param and not struct, not saving param 1~4 here
    # not making any calls thus does not need to save ra
    # Does not use any callee save regs(r16 ~ r24), not saving any callee save regs
    movia r8, TIMER # set r8 to base address of timer

    andi r9, r4, 0x0FFFF # set r9 to lower 16 bit of N
    srli r10, r4, 16 # set r10 to higher 16 bit of N

    stwio r9, 8(r8)
    stwio r10, 12(r8)

    ldwio r11, 4(r8) # load current data in base + 4 to r11
    ori r11, r11, 0x04 # set bit 2 to 1 to start timer
    stwio r11, 4(r8)

  wait:
    ldwio r11, 0(r8) # load current data in base to r11
    andi r11, r11, 0x02 # take bit 1
    bgt r11, r0, wait # if r11 == 1 (timer is still running) continue waiting

    ret # count is over
