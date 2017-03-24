# Print ten in octal, hexadecimal, and decimal
# Use the following C functions:
#     printHex ( int ) ;
#     printOct ( int ) ;
#     printDec ( int ) ;

.global main

main:
  movia r4, 10
  call printHex
  movia r4, 10
  call printOct
  movia r4, 10
  call printDec

  ret	# Make sure this returns to main's caller

