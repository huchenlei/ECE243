.global _start
.equ jtag_uart_base, 0xFF201000

.section .exceptions, "ax"
subi sp, sp, 4
stw r9, 0(sp)

# check what device cause interrupt
rdctl et, ctl4
andi et, et, 0x100
beq et, r0, iEND

# WIP or RIP
ldwio et, 4(r15)
andi et, et, 0x100
beq et, r0, iEND

#ACK interrupt
ldwio et, 0(r15)

# write to uart
WAIT_FOR_WR:
ldwio r9, 4(r15)
srli r9, r9, 16
beq r9, r0, WAIT_FOR_WR
andi et, et, 0xFF
stwio et, 0(r15)

iEND:
ldw r9, 0(sp)
addi sp, sp, 4
subi ea, ea, 4
eret

.text
_start:
movia sp, 0x03FFFFFC
#init uart
movia r15, jtag_uart_base
movi r9, 1
stwio r9, 4(r15)

#init processor interrupt
movi r9, 0x100
wrctl ctl3, r9
movi r9, 1
wrctl ctl0, r9

LOOP:
br LOOP
