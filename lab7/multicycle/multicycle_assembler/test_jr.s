 sub k1,k1
 ori 4                          ; k1 = 4
 db %01000001                   ;	jr k1: PC = k1 = 3
 sub k1,k1                      ; this line will be skipped
 add k1,k1                      ; k1=8
