  /*
  This program controls the car on screen
  */

  .equ UART_CAR, 0x10001020
  .equ TIMER, 0x10002000
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

  #.equ INITIAL_STACK, 2000
  .equ INITIAL_STACK, 0x00400000

  .global _start
  .global main

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
  movia sp, INITIAL_STACK
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
