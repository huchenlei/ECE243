.equ Timer, 0xFF202000
.equ LED, 0xFF200000
.equ PERIOD, 100000000

.section .exceptions, "ax"
Interrrupt:
addi sp,sp, -8
rdctl et, ctl1
stw et, 0(sp)
stw ea, 4(sp)
rdctl et, ctl4
andi et, et, 1
beq et, r0, TimerInterrupt

TimerInterrupt:
xori r11, r11, 1
movia et, LED
stwio r11, 0(r10)
movia et, Timer
stwio r0, 0(et) # acknowledge timer
movia et, 0x01
wrctl ctl0, et
br Exit

Exit:
ldw et, 0(sp)
ldw ea, 4(sp)
wrctl ctl1, et
addi sp, sp, 8
subi ea, ea, 4
eret


.section .text
.global _start
_start:
#initilize
movia    r4,100000000
movia r9, Timer
movia r10, LED
movia r11, 0x01
movi r8, %lo(PERIOD)
stwio r8, 8(r9)
movi r8, %hi(PERIOD)
stwio r8, 12(r9)
stwio r0, 0(r9) #clear
movi r8, 0x07
stwio r8, 4(r9) #initialize interrupt, continue and start


movia sp, 0x04000000
movi r8, 0x01
wrctl ctl0, r8
wrctl ctl3, r8

waiting_to_finish:
ldwio r13, 0(r9)
ldwio r14, 4(r9)
ldwio r15, 8(r9)
ldwio r16, 12(r9)
br waiting_to_finish
