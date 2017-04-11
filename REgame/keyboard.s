/*
  this module provide interrupt handling routines for keyboard input from
  ps2 keybaord and input from mouse.

  */

  .equ INITIAL_STACK, 0x00020000
  #equ INITIAL_STACK, 0x00400000
  .equ KEYBOARD, 0xFF200100
  .equ MOUSE, 0xFF200108

  /****************** interrupt section **********************/
  .section .exceptions, "ax" # ax
  br ihandler

  /********************* data section *******************/
  .data

is_f0_flag:
  /* 1: a f0 is read; 0: no f0 before that char */
  .byte 0
shift_on_flag:
  /* 1: shift is on; 0: shift is off */
  .byte 0
need_refresh_flag:
  .byte 0
  .skip 1

keyboard_buffer:
  /* the buffer accepting keyboard strokes; The PS2 queue has only 256 bytes */
  .skip 256

user_input_length:
  /* length of user input */
  .word 0x0000
user_input:
  /* ascii string end with 0 */
  .skip 1000 /* TODO text buffer may be more or less than that value */
  .align 1

make_to_ascii_table:
  /* [main][data initialize] initialize data structure of make code to
    ascii convertion table
    struct {
    char make_code
    char ascii
    } c_table[36]
  */
  # a - z
  .byte 0x1c, 97
  .byte 0x32, 98
  .byte 0x21, 99
  .byte 0x23, 100
  .byte 0x24, 101
  .byte 0x2B, 102
  .byte 0x34, 103
  .byte 0x33, 104
  .byte 0x43, 105
  .byte 0x3B, 106
  .byte 0x42, 107
  .byte 0x4B, 108
  .byte 0x3A, 109
  .byte 0x31, 110
  .byte 0x44, 111
  .byte 0x4D, 112
  .byte 0x15, 113
  .byte 0x2D, 114
  .byte 0x1B, 115
  .byte 0x2C, 116
  .byte 0x3C, 117
  .byte 0x2A, 118
  .byte 0x1D, 119
  .byte 0x22, 120
  .byte 0x35, 121
  .byte 0x1A, 122

  # 0 - 9
  .byte 0x45, 48
  .byte 0x16, 49
  .byte 0x1E, 50
  .byte 0x26, 51
  .byte 0x25, 52
  .byte 0x2E, 53
  .byte 0x36, 54
  .byte 0x3D, 55
  .byte 0x3E, 56
  .byte 0x46, 57

  # space
  .byte 0x29, 32
  
  # \
  .byte 0x5d, 92
  
  # .,
  .byte 0x49, 46
  .byte 0x41, 44
  
  .align 2

make_to_ascii_table_shift:
  /* convertion table with shift pressed */
  # A - Z
  .byte 0x1c, 65
  .byte 0x32, 66
  .byte 0x21, 67
  .byte 0x23, 68
  .byte 0x24, 69
  .byte 0x2B, 70
  .byte 0x34, 71
  .byte 0x33, 72
  .byte 0x43, 73
  .byte 0x3B, 74
  .byte 0x42, 75
  .byte 0x4B, 76
  .byte 0x3A, 77
  .byte 0x31, 78
  .byte 0x44, 79
  .byte 0x4D, 80
  .byte 0x15, 81
  .byte 0x2D, 82
  .byte 0x1B, 83
  .byte 0x2C, 84
  .byte 0x3C, 85
  .byte 0x2A, 86
  .byte 0x1D, 87
  .byte 0x22, 88
  .byte 0x35, 89
  .byte 0x1A, 90

  # )!@#$%^&*(
  .byte 0x45, 41
  .byte 0x16, 33
  .byte 0x1E, 64
  .byte 0x26, 35
  .byte 0x25, 36
  .byte 0x2E, 37
  .byte 0x36, 94
  .byte 0x3D, 38
  .byte 0x3E, 42
  .byte 0x46, 40

  # space
  .byte 0x29, 32

  # |
  .byte 0x5d, 124

  # <>
  .byte 0x49, 60
  .byte 0x41, 62
  .align 2
  /******************** text section ********************/
  .text
  #.global _start
initialize_keyboard:
#_start:
  #movia sp, INITIAL_STACK
  subi sp, sp, 4
  stw ra, 0(sp)

  /* enable keyboard & mouse interrupt TODO timer interrupt*/
  call set_up_keyboard
  call set_up_mouse

  # set up interrupt globally

  # enable mouse & keyboard interrupt
  movia r5, 0x00800080
  # enable mouse(bit 23), keyboard(bit 7) and timer(bit 0) interrupt
  # movia r5, 0x00800081
  wrctl ctl3, r5

  movi r5, 0x0001
  wrctl ctl0, r5 # set PIE bit to 1

  ldw ra, 0(sp)
  addi sp, sp, 4
  ret

wait_loop:
  br wait_loop #infinite loop to hold the program

  /* [interrupt initialize] acknowledge keyboard to accept interrupt */
set_up_keyboard:
  movia r4, KEYBOARD
  ldwio r5, 4(r4)
  ori r5, r5, 0x0001 # enable read interrupt
  stwio r5, 4(r4)
  ret

  /* [interrupt initialize] acknowledge mouse to accept interrupt */
set_up_mouse:
  movia r4, MOUSE
  ldwio r5, 4(r4)
  ori r5, r5, 0x0001 # enabe read interrupt
  stwio r5, 4(r4)
  ret

  /* [MAIN] bool get_input_status() */
get_input_status:
  movia r4, need_refresh_flag
  ldb r2, 0(r4)
  bne r2, r0, refresh_input_status:
  ret
refresh_input_status:
  stb r0, 0(r4)
  ret
  
  /* [MAIN] char* get_input_string()
  returns a char pointer to current input string */
get_input_string:
  # add 0 to the end of buffer string
  movia r2, user_input
  movia r3, user_input_length
  ldw r3, 0(r3)
  add r5, r2, r3
  movi r6, 0
  stb r6, 0(r5)
  ret

  /* [MAIN] void refresh_input_buffer()
  @Deprecated
  refresh the input buffer (set input length to 0) */
refresh_input_buffer:
  movia r4, user_input_length
  movi r5, 0x0000
  stw r5, 0(r4)
  ret

  /* interrupt handling routines */
  ihandler:
  #prologue
  subi sp, sp, 60
  stw r8, 0(sp)
  stw r9, 4(sp)
  stw r10, 8(sp)
  stw r11, 12(sp)
  stw r12, 16(sp)
  stw r13, 20(sp)
  stw ra, 24(sp)

  # calling other functions in ihandler
  # save everything that might be changed: caller save regs and r2 ~ r7
  stw r2, 28(sp)
  stw r3, 32(sp)
  stw r4, 36(sp)
  stw r5, 40(sp)
  stw r6, 44(sp)
  stw r7, 48(sp)
  stw r14, 52(sp)
  stw r15, 56(sp)
  
  rdctl et, ctl4 # read ipending
  andi et, et, 0x0080 # check IRQ line 7 (KEYBOARD)
  bne et, r0, keyboard_handler

  rdctl et, ctl4
  andhi et, et, 0x0080 # check IRQ line 23 (MOUSE)
  bne et, r0, mouse_handler

  br exit_ihandler

exit_ihandler:
  beq r0, r14, exit_ihandler_epilogue
  # set need_refresh_flag to 1 
  movia et, need_refresh_flag
  movi r11, 1
  stb r11, 0(et)
  
exit_ihandler_epilogue:
  #epilogue
  ldw r8, 0(sp)
  ldw r9, 4(sp)
  ldw r10, 8(sp)
  ldw r11, 12(sp)
  ldw r12, 16(sp)
  ldw r13, 20(sp)
  ldw ra, 24(sp)

  ldw r2, 28(sp)
  ldw r3, 32(sp)
  ldw r4, 36(sp)
  ldw r5, 40(sp)
  ldw r6, 44(sp)
  ldw r7, 48(sp)
  ldw r14, 52(sp)
  ldw r15, 56(sp)
  
  addi sp, sp, 60

  # re-execute the command on interrupt
  addi ea, ea, -4
  eret

  /* [ihandler] read input from keyboard
      whenever is called, clear the FIFO queue and process all data in queue

while (!FIFO.empty()) {
  char byte = read_next_byte()
  if (byte == 0xf0) {
    char b = read_next_byte()
    if(b.is_valid()) {
      if (b == 0x12) shift_on_flag = false // disable shift
      continue
    } else {
      is_f0_flag = true
      break
    }
  } else if (byte == 0x12) { // shift
    if(is_f0_flag) {
      shift_on_flag = false
      is_f0_flag = false
    }
    shift_on_flag = true
  } else if (byte == 0x66) {
    if (!is_f0_flag)
      input_length--
    else
        is_f0_flag = false;
  } else {
    if(is_f0_flag) {
      is_f0_flag = false
      continue
    } else {
      save_char_to_buffer
    }
  }
}
keyboard_process_raw_input();
  */
keyboard_handler:
  movi r14, 0 # need_refresh bool
  movia et, KEYBOARD
  movia r10, keyboard_buffer

read_next_byte_raw_input:
  movia et, KEYBOARD
  ldwio r8, 0(et)
  andi r9, r8, 0x8000 # check read valid byte
  beq r9, r0, keyboard_process_raw_input # break if valid byte is not 1

  andi r9, r8, 0x00FF # read data itself

  # the interrupt is caused by key release
  # read the byte after since the two consist as one key event
  # and continue cycle
  movi et, 0x00f0
  beq r9, et, handle_f0
  movi et, 0x0012
  beq r9, et, handle_shift
  movi et, 0x0066
  beq r9, et, handle_delete
  br handle_other_char

  /* handle f0 */
handle_f0:
  # the interrupt is f0
  # read next byte
  movia et, KEYBOARD
  ldwio r8, 0(et)
  andi r9, r8, 0x8000 # check read valid byte
  bne r9, r0, next_byte_valid
  br next_byte_invalid
next_byte_valid:
  # valid -> read next byte (the byte after f0 is already read and discard)
  # and consider whether is shift
  andi r9, r8, 0x00FF
  movi r8, 0x0012
  bne r9, r8, read_next_byte_raw_input
  # is shift, turn off shift flag
  movia r8, shift_on_flag
  movi r9, 0
  stb r9, 0(r8)
  br read_next_byte_raw_input
next_byte_invalid:
  # invalid -> the end of raw input set flag to 1 and process existing raw_input
  movia et, is_f0_flag
  movi r8, 1
  stb r8, 0(et)
  br keyboard_process_raw_input

  /* handle shift */
handle_shift:
  # the interrupt is shift
  # check the is_f0_flag
  movia et, is_f0_flag
  ldb r8, 0(et)
  bne r8, r0, shift_previous_is_f0
  br shift_previous_not_f0
shift_previous_is_f0:
  # previous char is f0 -> shift off & is_f0_flag false
  movia et, shift_on_flag
  movi r8, 0
  stb r8, 0(et)
  movia et, is_f0_flag
  stb r8, 0(et)
  br read_next_byte_raw_input
shift_previous_not_f0:
  # previous char is not f0 -> shift on
  movia et, shift_on_flag
  movi r8, 1
  stb r8, 0(et)
  br read_next_byte_raw_input

/* handle delete */
handle_delete:
  movia et, is_f0_flag
  ldb r8, 0(et)
  movi r9, 1
  beq r8, r9, delete_previous_is_f0 # ignore break code del
  br delete_previous_not_f0
delete_previous_is_f0:
  movia et, is_f0_flag
  movi r8, 0
  stb r8, 0(et)
  br exit_ihandler
delete_previous_not_f0:
  movia et, user_input_length
  ldw r8, 0(et)
  beq r8, r0, exit_ihandler # prevent overflow
  subi r8, r8, 1
  stw r8, 0(et)
  movi r14, 1
  br exit_ihandler

/* handle other chars */
handle_other_char:
  # the data is valid
  # check the is_f0_flag
  movia et, is_f0_flag
  ldb r8, 0(et)
  bne r8, r0, previous_is_f0
  br previous_not_f0
previous_is_f0:
  # previous char is f0 -> discard this byte and read next & set is_f0_flag to 0
  movi r8, 0
  stb r8, 0(et)
  br read_next_byte_raw_input
previous_not_f0:
  # previous char is not f0 -> save to keyboard_buffer
  stb r9, 0(r10) # save data to keyboard_buffer
  addi r10, r10, 1 # increment r10
  movi r14, 1
  br read_next_byte_raw_input

keyboard_process_raw_input:
  # this part analysis the key strokes saved in keyboard_buffer
  # r10 is end pointer previously set
  movia et, user_input_length
  ldw r11, 0(et) # r11 is current length of the string
  movia et, user_input
  add r12, et, r11 # r12 is the current char pointer of user_input string

  movia et, keyboard_buffer

  # outer loop. loop through current raw input buffer
convert_next_raw_input:
  beq et, r10, exit_keyboard_handler # break if reach the end of string
  ldb r8, 0(et) # read the make code char
  movia r9, shift_on_flag
  ldb r13, 0(r9)
  beq r13, r0, use_regular_table
  br use_shift_table
use_regular_table:
  movia r13, make_to_ascii_table
  br make_to_ascii_lookup_loop
use_shift_table:
  movia r13, make_to_ascii_table_shift
  br make_to_ascii_lookup_loop

  # inner loop. loop through make_to_ascii_table
make_to_ascii_lookup_loop:
  ldb r9, 0(r13) # read the loop up code and save in r9
  beq r8, r9, save_ascii_to_user_input
  addi r13, r13, 2 # increment table address
  br make_to_ascii_lookup_loop
save_ascii_to_user_input:
  ldb r9, 1(r13) # r9 is cooresponse ascii code
  stb r9, 0(r12) # append r9 to user_input string
  addi r11, r11, 1 # increment string length counter
  addi r12, r12, 1 # increment user_input pointer

  addi et, et, 1 # increment raw_input pointer
  br convert_next_raw_input

exit_keyboard_handler:
  # save the new string length
  movia et, user_input_length
  stw r11, 0(et)

  
  br exit_ihandler

  /* [ihandler] read input from mouse */
mouse_handler:
  /* TODO */
  br exit_ihandler
