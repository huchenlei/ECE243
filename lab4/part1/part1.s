# Author: Charles Change  
# Copy Right © 2017

######### Physical Setup ########
# Used motor 1
# Used sensor 3
# Used sensor 4

######### Data Section #########
.data
	# Hardware device mapping
	.equ legoControllerAddress_JP1, 0xFF200060
    .equ legoControllerAddress_JP2, 0xFF200070
    #.equ sensor3EnableMask, 0xfffeffff	# -> Well this is confusing since how can we set other bits that are supposed to be read?
    #.equ sensor4EnableMask, 0xfffbffff	# -> Well this is confusing since how can we set other bits that are supposed to be read?
    .equ sensor3EnableMask, 0xfffefffc  # Reserve last two bits
    .equ sensor4EnableMask, 0xfffbfffc	# Reserve last two bits	
    .equ motor1EnableMaskWithDirP, 0xfffffffc
    .equ motor1EnableMaskWithDirN, 0xfffffffe
    .equ motorsDisableMask, 0xffffffff
    .equ timer1Address, 0xFF202000
    .equ timer2Address, 0xFF202020
    .equ slideSwitchAddress, 0xFF200040
    .equ MBRamStartAddress, 0x00000000
    .equ MBRamEndAddress, 0x03FFFFFF
    .equ GBRamStartAddress, 0x40000000
    .equ GBRamEndAddress, 0x7FFFFFFF
    
    # Program parameters
	# .equ rotationValue
    .equ waitTimeLow, 0x0016	# in Cycles
    .equ waitTimeHigh, 0x0000

.global _start
######### Code Section #########
# Reserved registers: 
#	r8 - Controller address
#	r22 - Switch Address
# 	r23 - Current Switch 1 value
#	r24 - Auto rotation direction correction bInitialize status bit
#	All other registers use at will
.text    
### Program Flow Execution Routines
_start:
Main:
	# Peripheral Setup
    call Setup	# Setup Lego Controller (For part 1) and Timer (For part 2)

MainLoop:
	# Read Switch Value
    movia r22,slideSwitchAddress
  	ldwio r23,0(r22)
    andi r23, r23, 0x1

	# Read value of sensors
    call ReadSensorValues
    # If two sensors are equal, stop rotation
    beq r11, r12, StopRotate
    # If two sensors are not equal, rotate in some direction, the actual direction will be adjusted later
    blt r11, r12, RotateDirP	# "Positive" dir
    br RotateDirN	# "Negative" dir
    br MainLoop
    
    # End program
    br End
    
ReadSensorValues:
ReadSensor3Values:
	# Read current motor 1 value
    ldwio r10, 0(r8)
    andi r10, r10, 0x3
	# Enable sensor 3, keep current motor
	movia r9, sensor3EnableMask
    add r9, r9, r10
   	stwio r9, 0(r8)
    
    # Checking for valid data sensor 3
	ldwio r10,  0(r8)          
	srli r11, r10, 17 # bit 17 is valid bit for sensor 3           
	andi r11, r11, 0x1
    # Read sensor value 3 if ready, otherwise wait till ready
	bne	r0, r11, ReadSensor3Values
    # Read actual sensor value
   	srli   r11, r10, 27 # shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits 
   	andi   r11, r11, 0x0f
    # Now r11 holds value of sensor 3
ReadSensor4Values:
	# Read current motor 1 value
    ldwio r10, 0(r8)
    andi r10, r10, 0x3
	# Enable sensor 4, keep current motor
	movia r9, sensor4EnableMask
    add r9, r9, r10
   	stwio r9, 0(r8)
	
    # Checking for valid data sensor 4
	ldwio r10,  0(r8)          
	srli r12, r10, 19 # bit 19 is valid bit for sensor 4       
	andi r12, r12, 0x1
    # Read sensor value 4 if ready, otherwise wait till ready
	bne	r0, r12, ReadSensor4Values
    # Read actual sensor value
   	srli   r12, r10, 27 # shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits 
   	andi   r12, r12, 0x0f
    # Now r12 holds value of sensor 4
    ret
    
RotateDirP:
	# Setup direction and magnitude(on/off)
    beq r0, r23, DirPReverse
	movia r9, motor1EnableMaskWithDirP
    br ContinueRotate
    #(Not used due to complexity)br RotateWithAutoDirCorrection
	DirPReverse:
		movia r9, motor1EnableMaskWithDirN
        br ContinueRotate
RotateDirN:
	# Setup direction and magnitude(on/off)
    beq r0, r23, DirNReverse
	movia r9, motor1EnableMaskWithDirN
    br ContinueRotate
    #(Not used due to complexity)br RotateWithAutoDirCorrection
	DirNReverse:
		movia r9, motor1EnableMaskWithDirP
        br ContinueRotate
RotateDirAutoCorrection:
	# Set up value and let whatever motor rolls
	stwio r9, 0(r8)
    # (Not used due to complexity)If this is our first time rotating after device setup, check rotate result and reset direction variable
    # (Not used due to complexity)beq r24, r0, InitializeRotationDirection
ContinueRotate:
	# (Part 1) Comment below line if we are doing part 2
    # stwio r9, 0(r8)
	# (Part 2) Uncomment below line for part 1
    # Run for a while
    stwio r9, 0(r8)
   	call CarefulRotate
    # Stop For a while
    movia r9, motorsDisableMask
    stwio r9, 0(r8)
    call CarefulRotate
    br MainLoop
CarefulRotate:
	# Set up input for function
    movia r2, waitTimeLow
    movia r3, waitTimeHigh
    # ABI
    addi sp, sp, -28
    stw r8, 0(sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw ra, 24(sp)
	call WaitTime
    # ABI
    ldw r8, 0(sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw ra, 24(sp)
    addi sp, sp, 28
    ret
WaitTime:
	# ABI
    addi sp, sp, -4
    stw ra, 0(sp)	# Even though we didn't call any function
TimerSet:
    # Set the period to be waitTime clock cycles 
    movia r8, timer1Address
	stwio r2, 8(r8) # Set low bits
	stwio r3, 12(r8) # Set high bits
TimerStart:
    # Start the timer without continuing or interrupts
	movui r9, 4
	stwio r9, 4(r8)  
TimerLoop:
	# Wait until time out using polling
    ldwio r10, 0(r8)
    andi r10, r10, 0x1
    beq r0, r10, TimerLoop
TimerEnd:
    # ABI
    ldw ra, 0(sp)	# Even though we didn't call any function
    addi sp, sp, 4
    ret

StopRotate:
	movia r9, motorsDisableMask
    stwio r9, 0(r8)
    br MainLoop
    
# (Not used due to complexity)InitializeRotationDirection:
    # (Not used due to complexity)call ReadSensorValues
    # (Not used due to complexity)blt r10, r11, AdjustLeft
    # (Not used due to complexity)br AdjustRight
    # (Not used due to complexity)movia r24, 1
    
# (Not used due to complexity)AdjustLeft:
	# ..
	# (Not used due to complexity)br RotateRight
# (Not used due to complexity)AdjustRight:
	# ..
	# (Not used due to complexity)br RotateLeft
    
End:
	br End
    
### Helpder Functions
Setup:
	# Initialize Stack Pointer
	movia sp, GBRamEndAddress
    addi sp, sp, 1
	# Setup Controller
    stw ra, -4(sp)
    call SetupController
    ldw ra, -4(sp)
    # (Part 2 Only)
    # stw ra, -4(sp)
    # call SetupTimer
    # ldw ra, 4(sp)
    ret
    
SetupController: # Notice registers used here are not used before entering this function; And we don't clean it up
	movia  r8, legoControllerAddress_JP1
  	movia  r9, 0x07f557ff       # set direction for motors to all output, and other bits all input
  	stwio  r9, 4(r8)
	ret
    # Sensors and motors are ready to go
    
SetupTimer:
	# No need to setup; Adjust parameter when call
	ret