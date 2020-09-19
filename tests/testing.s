.align 3
.doublew 123
.word 2147483648

.align 1
.constant 0b010a 5
.halfword 132

.ascii "this is a message LUL"
.zero 4

auipc t0 123
# in
# a0 something
# a1 another thing
# out
# a0 some return value
.align 2
.label my_function
addi sp sp -32
sd ra sp 0
sd s0 sp 8
sd s1 sp 16
sd s2 sp 24

slli t0 t0 4

# amoswap.w t0 t1 t2
# t0 = rd = register to swap to
# t1 = rs1 = address of target memory
# t2 = rs2 = register to swap from

addi a0 zero 31
ld t0 my_variable
beq t0 a0 my_function_return
sub t0 t0 a0
sd t0 my_variable t1

.label my_function_return
ld s2 sp 24
ld s1 sp 16
ld s0 sp 8
ld ra sp 0
addi sp sp 32
jalr zero ra 0


.align 2
.constant KKE 69

.label _start # this is a comment
addi sp sp -16
sd ra sp 0
sd s0 sp 8

add sp sp t0
andi t0 t0 KKE
beq sp t0 2f. # symbol name, not relative numeric reference
fence r rwio

jal zero 123124535625
jal ra my_function

amoadd.w.aq t0 t1 t2
lr.w.aqrl       t0   t1

# return
ld s0 sp 8
ld ra sp 0
addi sp sp 16
jalr zero ra 0

# to do how to implement lo and hi???
# %hi(symbol)
# %lo(symbol)

# andi t0 t0 KKE
# lui t0 KKE
# lui t0 %hi(KKE)
# lui t0 hi(KKE)
# lui t0 KKE:hi
# lui t0 hi:KKE
# lui t0 KKE
add t0 a4 zero

.label my_func.ion
addi a0 a0 1
