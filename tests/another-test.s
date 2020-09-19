.constant something 2000
addi t0 a0 something
amoadd.d t0 t0 t1
add t0 t0 t2
.align 8
.label my_variable
.doubleword 12
