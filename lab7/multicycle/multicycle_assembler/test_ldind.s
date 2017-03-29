  sub k1, k1
  ori 3         ; k1 = 3
  sub k2, k2
  add k2, k1    ; k2 = 3
  shiftl k2, 1  ; k2 = 6
  store k2, (k1)                ; MEM[3] = 6
  shiftl k1, 2                  ; k1 = 12
  store k1, (k2)                ; MEM[6] = 12
  sub k1, k1
  ori 3        ; k1 = 3
  db %10011110  ; ldind k2,((k1)), k2 = Mem[Mem[k1]] = Mem[Mem[3]] = Mem[6] = 12

  ;; db %00000100  ; read first by ldind above
  ;; db %00001111  ; read second by ldind above
