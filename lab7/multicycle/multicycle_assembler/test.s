0 db %01001100                  ; JAL 0100 R1 = 2
1 ori 4                         ; R1 = 4
2 store r2,(r1)                 ;
3 load r0,(r1)                  ; R0 = R2
4 bnz -1                        ;
5 add r3,r1                     ;
6 sub r1,r1                     ; R1 = 0
7 ori 10                        ; R1 = 10
8 db %10010001                  ; LDIND R2, ((R1))
9 db %11001110                  ; JR R3
10 db %00001011                 ; SHIFT R0 Right 1
11 db %10101000                 ; NAND R2, R2
