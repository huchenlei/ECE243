 sub k1,k1
 db %00011010                   ;	jal 1: k1 = PC + 1 = 2, PC = PC + 1 + IMM = 3
 sub k1,k1                      ;	this line will be skipped
 add k1,k1                      ; k1 = 4
