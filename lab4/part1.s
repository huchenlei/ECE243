  /*
    This program adjust LEGO car based on sensor feedback
    Use of devices:
    bit number from 1 ~ 32
  motor0:  bit 1 ~ 2 base address
  sensor0:  bit 11 ~ 12 base address
  sensor1:  bit 13 ~14 base address
  Sensor: bit 28 ~ 31 base address

  Structure:
    while(true) {
      x1 = read_sensor0()
      x2 = read_sensor1()
      dx = x2 - x1
      if(dx > threshold) {// means sensor1 side is more to ground
      turn on motor0
      forward
      } else if(dx < -threshold){ // means sensor0 side is more to ground
        turn on motor0
        reverse
      } else {
        turn off motor0
      }
    }
    */

.equ LEGO, 0xFF200060

.global _start

_start:
  movia r20, LEGO # save address of device to r20
  # set direction regs
  movia r16, 0x07F557FF
  stwio r16, 4(r20)

  # turn off all sensors and motors
  ldwio r16, 0(r20)
  # set bit 11, 13, 15, 17, 19 to 1
  ori r16, r16, 0x57FF
  orhi r16, r16, 0x0005
  stwio r16, 0(r20)

infinite_loop:

  /*r17 = read_sensor0()*/
enable_sensor0:
  ldwio r16, 0(r20)
  # set bit-11 to 0 and set all other sensor to 1
  andi r21, r16, 0xFBFF
  andhi r16, r16, 0xFFFF
  add r16, r16, r21
  stwio r16, 0(r20)

wait_sensor0:
  # check if data in sensor0 is valid
  ldwio r16, 0(r20)
  # read bit-12
  srli r16, r16, 11
  andi r16, r16, 0x0001
  bne r16, r0, wait_sensor0 # wait until valid (r16 == 0)

read_sensor0:
  # read data from sensor 0 to r17
  ldwio r16, 0(r20)
  # read bit 28 ~ 31
  srli r16, r16, 27
  andi r17, r16, 0x000F

disable_sensor0:
  ldwio r16, 0(r20)
  ori r16, r16, 0x0400
  stwio r16, 0(r20)

/*r18 = read_sensor0()*/
enable_sensor1:
  ldwio r16, 0(r20)
  # set bit-13 to 0 and set all other sensor to 1
  andi r21, r16, 0xEFFF
  andhi r16, r16, 0xFFFF
  add r16, r16, r21
  stwio r16, 0(r20)

wait_sensor1:
  # check if data in sensor1 is valid
  ldwio r16, 0(r20)
  # read bit-14
  srli r16, r16, 13
  andi r16, r16, 0x0001
  bne r16, r0, wait_sensor1 # wait until valid (r16 == 0)

read_sensor1:
  # read data from sensor 1 to r18
  ldwio r16, 0(r20)
  # read bit 28 ~ 31
  srli r16, r16, 27
  andi r18, r16, 0x000F

disable_sensor1:
  ldwio r16, 0(r20)
  ori r16, r16, 0x1000
  stwio r16, 0(r20)

  /* decision making */
  sub r19, r18, r17  # r19 = r18 - r17
  movia r21, 2 # threshold = 2
  movia r22, -2
  bgt r19, r21, push_sensor1_side # sensor1 side is more to ground
  blt r19, r22, push_sensor0_side # sensor0 side is more to ground
  br stop_motor # balanced

push_sensor1_side:
  # forward on (10)
  ldwio r16, 0(r20)
  ori r16, r16, 0x0002 # set bit 2 to 1
  andi r16, r16, 0xFFFE # set bit 1 to 0
  stwio r16, 0(r20)
  br infinite_loop

push_sensor0_side:
  # reverse on (00)
  ldwio r16, 0(r20)
  andi r16, r16, 0xFFFC # set bit 1 and 2 to 0
  stwio r16, 0(r20)
  br infinite_loop

stop_motor:
  # off(x1)
  ldwio r16, 0(r20)
  orhi r16, r16, 0x0000
  ori r16, r16, 0x0003
  stwio r16, 0(r20)
  br infinite_loop
