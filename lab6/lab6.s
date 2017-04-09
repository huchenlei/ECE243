/*
    This program controls the car on screen
    */
  .text
  .equ UART_TERM, 0xFF201000
  .equ UART_CAR, 0x10001020
  .equ TIMER, 0xFF202000

  .equ LEFT_STEER, 64
  .equ RIGHT_STEER, -64
  .equ S_LEFT_STEER, 127
  .equ S_RIGHT_STEER, -127
  .equ STRAIGHT_SPEED_MAX, 48
  .equ STRAIGHT_SPEED_MIN, 47
  .equ LEFT_SPEED_MAX, 40
  .equ LEFT_SPEED_MIN, 40
  .equ RIGHT_SPEED_MAX, 40
  .equ RIGHT_SPEED_MIN, 40
  .equ S_RIGHT_SPEED_MAX, 40
  .equ S_RIGHT_SPEED_MIN, 40
  .equ S_LEFT_SPEED_MAX, 40
  .equ S_LEFT_SPEED_MIN, 40

  .equ DISPLAY_SENSOR, 1
  .equ DISPLAY_SPEED, 0

  #.equ INITIAL_STACK, 2000
  .equ INITIAL_STACK, 0x00400000

  .section .data
display_option: # 1 for sensor / 0 for speed
  .word 0
sensor:
  .word 0
speed:
  .word 0

  .align 2

  .section .exceptions, "ax"
ihandler:
  # prologue
  addi sp, sp, -32
  stw ea, 0(sp)
  stw et, 4(sp)
  rdctl et, ctl1
  stw et, 8(sp)
  stw r2, 12(sp)
  stw r4, 16(sp)
  stw r8, 20(sp)
  stw r9, 24(sp)
  stw r16, 28(sp)
  stw ra, 32(sp)


  rdctl r8, ctl4  # read ipending
  andi r8, r8, 0x0100 # check if UART_TERM
  bne r8, r0, term_ihandler
  rdctl r8, ctl4  # read ipending
  andi r8, r8, 0x0001 # check if timer
  bne r8, r0, timer_ihandler
  br exit_ihandler

  /*handles terminal interrupt*/
term_ihandler:
  movia r8, UART_TERM
  ldwio r9, 0(r8)
  andi r9, r9, 0x00FF
  movi r8, 's'
  beq r8, r9, display_sensor
  movi r8, 'r'
  beq r8, r9, display_speed
  br exit_ihandler

display_sensor:
  movi r8, display_option
  movia r9, DISPLAY_SENSOR
  stw r9, 0(r8)
  br exit_ihandler

display_speed:
  movi r8, display_option
  movia r9, DISPLAY_SPEED
  stw r9, 0(r8)
  br exit_ihandler

 /* handles timer interrupt */
timer_ihandler:
  # clear screen
  movi	r4, 0x1b
  call	write_term
  movi	r4, '['
  call	write_term
  movi	r4, '2'
  call	write_term
  movi	r4, 'J'
  call	write_term

  movia r8, display_option
  ldw r9, 0(r8)
  movi r8, DISPLAY_SENSOR
  beq r8, r9, timer_display_sensor
  br timer_display_speed

  #display speed on terminal
timer_display_speed:
  movia r16, speed
  ldw r16, 0(r16)
  # display higher 4 bit
  srli r4, r16, 4
  call to_ascii
  mov r4, r2
  call write_term
  # display lower 4 bit
  mov r4, r16
  call to_ascii
  mov r4, r2
  call write_term
  br timer_ihandler_exit

  #display sensors on terminal
timer_display_sensor:
  movia r16, sensor
  ldw r16, 0(r16)
  # display higher 4 bit
  srli r4, r16, 4
  call to_ascii
  mov r4, r2
  call write_term
  # display lower 4 bit
  mov r4, r16
  call to_ascii
  mov r4, r2
  call write_term
timer_ihandler_exit:
  # notify timer
  movia r16, TIMER
  stwio r0, 0(r16)

exit_ihandler:
  # epilogue
  ldw ea, 0(sp)
  ldw et, 8(sp)
  wrctl ctl1, et
  ldw et, 4(sp)
  ldw r2, 12(sp)
  ldw r4, 16(sp)
  ldw r8, 20(sp)
  ldw r9, 24(sp)
  ldw r16, 28(sp)
  ldw ra, 32(sp)
  addi sp, sp, 32
  addi ea, ea, -4
  eret


  .global _start
  .global main

  /* write a byte to URAT TERM r4 = byte char */
write_term:
  # wait until ready to write
  movia r8, UART_TERM
write_term_wait:
  ldwio r9, 4(r8)
  srli r9, r9, 16
  beq r9, r0, write_term_wait

  # write byte to UART_TERM
  stwio r4, 0(r8)
  ret

  /* read a byte from URAT TERM return value in r2 */
read_term:
  movia r8, UART_TERM
read_term_wait:
  ldwio r2, 0(r8)
  srli r8, r2, 15
  andi r8, r8, 0x0001
  beq r8, r0, read_term_wait

  andi r2, r2, 0x00FF
  ret

  /* convert number&char to ascii char r4=num */
to_ascii:
  andi r2, r4, 0xF #only care about lowest 4 bit
  movi r8, 9
  bgt r2, r8, is_char
  br is_num
is_num:
  addi r2, r2, '0'
  ret
is_char:
  addi r2, r2, 55
  ret

  /* read sensor value and speed value return them in r2 and r3 */
read_sensor_and_speed:
  # prologue
  addi sp, sp, -12
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw ra, 8(sp)

  # request data
  movi r16, 2 # packet type = 2
  movia r17, UART_CAR
  call poll_write
  stwio r16, 0(r17)

wait_byte_0:
  # wait until first byte (0x00)
  call read_packet
  bne r2, r0, wait_byte_0

  # read sensor value
  call read_packet
  mov r3, r2 # r3 = sensor value

  call read_packet # r2 = speed value

  # save speed&sensor value on stack
  movia r16, speed
  stw r2, 0(r16)

  movia r16, sensor
  stw r3, 0(r16)

  #epilogue
  ldw r16, 0(sp)
  ldw r17, 4(sp)
  ldw ra, 8(sp)
  addi sp, sp, 12
  ret

  /* change acceleration r4 = a (-127 ~ 128)*/
change_a:
  # prologue
  addi sp, sp, -12
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw ra, 8(sp)
  movi r16, 4 # packet type 4
  movia r17, UART_CAR
  call poll_write
  stwio r16, 0(r17) # send first byte
  call poll_write
  stwio r4, 0(r17) # send second byte
  # epilogue
  ldw r16, 0(sp)
  ldw r17, 4(sp)
  ldw ra, 8(sp)
  addi sp, sp, 12
  ret

  /* change steering r4 = steeling (-127 ~ 128)*/
change_steering:
  # prologue
  addi sp, sp, -12
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw ra, 8(sp)
  movi r16, 5 # packet type 5
  movia r17, UART_CAR
  call poll_write
  stwio r16, 0(r17) # send first byte
  call poll_write
  stwio r4, 0(r17) # send second byte
  # epilogue
  ldw r16, 0(sp)
  ldw r17, 4(sp)
  ldw ra, 8(sp)
  addi sp, sp, 12
  ret

  /* request a space for writing */
poll_write:
  # poll UART_CAR for writing
  movia r9, UART_CAR

wait_write_space:
  # wait until there is space for writing
  ldwio r8, 4(r17)
  srli r8, r8, 16
  beq r8, r0, wait_write_space
  ret

  /* read a packet from UART return value in r2 */
read_packet:
  movia r9, UART_CAR
wait_read_valid:
  ldwio r2, 0(r9)
  srli r8, r2, 15
  andi r8, r8, 0x1
  beq r8, r0, wait_read_valid

  andi r2, r2, 0xFF
  ret


_start:
main:
  movia sp, INITIAL_STACK #initialize stack pointer
  movia r4, 100000000
  call set_up_timer
  call set_up_UART
  # set up interrupt globally
  movi r16, 0x0101
  wrctl ctl3, r16 # set bit 0 and bit 8 to active
  movi r16, 0x0001
  wrctl ctl0, r16 # set PIE bit

check_sensor_speed:
  call read_sensor_and_speed
  mov r16, r2 # r16 = speed
  andi r17, r3, 0b11111 # r17 = sensors

  # switch different situations
  movi r18, 0b11111
  beq r17, r18, go_straight
  movi r18, 0b01111
  beq r17, r18, turn_right
  movi r18, 0b00111
  beq r17, r18, turn_sheer_right
  movi r18, 0b11110
  beq r17, r18, turn_left
  movi r18, 0b11100
  beq r17, r18, turn_sheer_left
  br check_sensor_speed

go_straight:
  movi r4, 0
  call change_steering
  mov r4, r16
  movi r5, STRAIGHT_SPEED_MIN
  movi r6, STRAIGHT_SPEED_MAX
  call set_speed
  br check_sensor_speed
turn_left:
  movi r4, LEFT_STEER
  call change_steering
  mov r4, r16
  movi r5, LEFT_SPEED_MIN
  movi r6, LEFT_SPEED_MAX
  call set_speed
  br check_sensor_speed
turn_sheer_left:
  movi r4, S_LEFT_STEER
  call change_steering
  mov r4, r16
  movi r5, S_LEFT_SPEED_MIN
  movi r6, S_LEFT_SPEED_MAX
  call set_speed
  br check_sensor_speed
turn_right:
  movi r4, RIGHT_STEER
  call change_steering
  mov r4, r16
  movi r5, RIGHT_SPEED_MIN
  movi r6, RIGHT_SPEED_MAX
  call set_speed
  br check_sensor_speed
turn_sheer_right:
  movi r4, S_RIGHT_STEER
  call change_steering
  mov r4, r16
  movi r5, S_RIGHT_SPEED_MIN
  movi r6, S_RIGHT_SPEED_MAX
  call set_speed
  br check_sensor_speed



  /* set_speed(current, min, max) */
  /* acceleration would be set to get current speed in range specified by min&max*/
set_speed:
  addi sp, sp, -4
  stw ra, 0(sp)

  bge r4, r6, slower
  ble r4, r5, faster

slower:
  movi r4, -127
  call change_a
  br return

faster:
  movi r4, 127
  call change_a
  br return

return:
  ldw ra, 0(sp)
  addi sp, sp, 4
  ret

  /* set up timer and enable interrupt r4=cycle number */
set_up_timer:
  movia r8, TIMER # base address
  # clear timer
  movi r9, 0b1000
  stwio r9, 4(r8)
  stwio r0, 0(r8)

  # set period
  andi r9, r4, 0xFFFF
  stwio r9, 8(r8)
  srli r9, r4, 16
  stwio r9, 12(r8)

  # start timer & enable interrupt
  movi r9, 0b0111
  stwio r9, 4(r8)
  ret

  /* set up UART interrupts */
set_up_UART:
  movia r8, UART_TERM
  ldwio r9, 4(r8)
  ori r9, r9, 0x0001 # enable read interrupt
  stwio r9, 4(r8)
  ret
