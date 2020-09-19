# constant byte layout
# 0 identifier address
# 8 identifier size
# 16 value
# 24

.section .text


# in
# rax constant address
# out
# rax constant value
constant_table_get:
movq 16(%rax), %rax
ret


# in
# rax capacity
# out
# al status
constant_table_initialize:
movq %rax, constant_table_capacity
addq $1, %rax
movq $24, %rbx
mulq %rbx
# allocate memory
movq %rax, %rsi
movl $9, %eax
xorl %edi, %edi
movl $7, %edx
movl $-1, %r8d
xorl %r9d, %r9d
movl $34, %r10d
syscall
testq %rax, %rax
js constant_table_initialize_failure
movq %rax, constant_table_address
xorb %al, %al
ret
constant_table_initialize_failure:
movb $1, %al
ret


# in
# rax constant identifier address
# rbx constant identifier size
# rcx constant value
constant_table_insert:
movq %rax, %rsi
movq constant_table_size, %rax
addq $1, %rax
movq %rax, constant_table_size
movq $24, %rdx
mulq %rdx
movq constant_table_address, %rdx
addq %rdx, %rax
movq %rsi, (%rax)
movq %rbx, 8(%rax)
movq %rcx, 16(%rax)
ret


# in
# rax constant identifier address
# rbx constant identifier size
# out
# rax constant identifier occurrences
constant_table_count:
xorq %rcx, %rcx # occurences
movq constant_table_size, %rdx
testq %rdx, %rdx
jz constant_table_count_return
movq constant_table_address, %rsi
constant_table_count_element:
addq $24, %rsi
cmpq 8(%rsi), %rbx
jne constant_table_count_element_end
movq (%rsi), %rdi
movq %rax, %r8
movq %rbx, %r9
constant_table_count_character:
movb (%rdi), %r10b
cmpb (%r8), %r10b
jne constant_table_count_element_end
addq $-1, %r9
testq %r9, %r9
jz constant_table_count_match
addq $1, %rdi
addq $1, %r8
jmp constant_table_count_character
constant_table_count_match:
addq $1, %rcx
constant_table_count_element_end:
addq $-1, %rdx
testq %rdx, %rdx
jnz constant_table_count_element
constant_table_count_return:
movq %rcx, %rax
ret


# in
# rax constant identifier address
# rbx constant identifier size
# out
# al status
# rbx constant address
constant_table_seek:
movq constant_table_size, %rcx
testq %rcx, %rcx
jz constant_table_seek_failure
movq constant_table_address, %rdx
constant_table_seek_element:
addq $24, %rdx
cmpq 8(%rdx), %rbx
jne constant_table_seek_element_end
movq (%rdx), %rsi
movb (%rsi), %dil
cmpb (%rax), %dil
jne constant_table_seek_element_end
movq %rax, %rdi
movq %rbx, %r8
constant_table_seek_identify:
addq $-1, %r8
testq %r8, %r8
jz constant_table_seek_success
addq $1, %rsi
movb (%rsi), %r9b
addq $1, %rdi
cmpb (%rdi), %r9b
je constant_table_seek_identify
constant_table_seek_element_end:
addq $-1, %rcx
testq %rcx, %rcx
jnz constant_table_seek_element
constant_table_seek_failure:
movb $1, %al
ret
constant_table_seek_success:
movq %rdx, %rbx
xorb %al, %al
ret


.align 8
constant_table_address: .quad 0
constant_table_capacity: .quad 0
constant_table_size: .quad 0
