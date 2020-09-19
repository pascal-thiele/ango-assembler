.align 3
.constant my_variable 532
.doubleword 123
.word 2147483648

.word -123

.align 1
.constant herro 123
.halfword 0b111


# in
# a0 some argument
# out
# a0 status
.label my_first_function
addi sp sp -16
sd ra sp 0
sd s0 sp 8
addi a0 a0 my_variable
# return
ld s0 sp 8
ld ra sp 0
addi a0 zero 0
jalr zero ra 0

jal ra my_function
jal ra 8
jal ra herro

.zero 32


# in
# a0 something
# a1 another thing
# out
# a0 some return value
.align 8
.label my_function
addi sp sp -32
sd ra sp 0
sd s0 sp 8
sd s1 sp 16
sd s2 sp 24

csrrci t0 time 31
slli t0 t0 4

# amoswap.w t0 t1 t2
# t0 = rd = register to swap to
# t1 = rs1 = address of target memory
# t2 = rs2 = register to swap from

addi a0 zero 31
lb t0 my_function_return
beq t0 a0 my_function_return
sub t0 t0 a0
sd t0 my_function_return t1

.label my_function_return
ld s2 sp 24
ld s1 sp 16
ld s0 sp 8
ld ra sp 0
addi sp sp 32
jalr zero ra 0


.align 16
.constant KKE 69

.label _start # this is a comment
addi sp sp -16
sd ra sp 0
sd s0 sp 8

add sp sp t0
andi t0 t0 KKE
beq sp t0 2f # symbol name, not relative numeric reference
fence r rwio

jal zero 2f
jal ra my_function

.label 2f
amoadd.w.aq t0 t1 t2
lr.w.aqrl       t0   t1

# return
ld s0 sp 8
ld ra sp 0
addi sp sp 16
jalr zero ra 0
