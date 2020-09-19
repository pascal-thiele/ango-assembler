# include byte layout
# 0 identifier address
# 8 identifier size
# 16 data address
# 24 data size
# 32

.section .text


# in
# rax include address
# out
# rax include data address
# rbx include data size
include_table_get:
movq 24(%rax), %rbx
movq 16(%rax), %rax
ret


# in
# rax capacity
# out
# al status
include_table_initialize:
movq %rax, include_table_capacity
addq $1, %rax
movl $32, %ebx
mulq %rbx
# allocate
movq %rax, %rsi
movl $9, %eax
xorl %edi, %edi
movl $7, %edx
movl $-1, %r8d
xorl %r9d, %r9d
movl $34, %r10d
syscall
testq %rax, %rax
js include_table_initialize_failure
movq %rax, include_table_address
xorb %al, %al
ret
include_table_initialize_failure:
movb $1, %al
ret


# in
# rax include identifier address
# rbx include identifier size
# rcx include data address
# rdx include data size
include_table_insert:
movq %rax, %rsi
movq %rdx, %rdi
movq include_table_size, %rax
addq $1, %rax
movq %rax, include_table_size
movl $32, %r8d
mulq %r8
movq include_table_address, %rdx
addq %rdx, %rax
movq %rsi, (%rax)
movq %rbx, 8(%rax)
movq %rcx, 16(%rax)
movq %rdi, 24(%rax)
ret


# in
# rax include identifier address
# rbx include identifier size
# out
# al status
# rbx include address
include_table_seek:
movq include_table_size, %rcx
testq %rcx, %rcx
jz include_table_seek_failure
movq include_table_address, %rdx
include_table_seek_element:
addq $32, %rdx
cmpq 8(%rdx), %rbx
jne include_table_seek_next_element
movq (%rdx), %rsi
movb (%rsi), %dil
cmpb (%rax), %dil
jne include_table_seek_next_element
movq %rax, %rdi
movq %rbx, %r8
include_table_seek_identify:
addq $-1, %r8
testq %r8, %r8
jz include_table_seek_success
addq $1, %rsi
movb (%rsi), %r9b
addq $1, %rdi
cmpb (%rdi), %r9b
je include_table_seek_identify
include_table_seek_next_element:
addq $-1, %rcx
testq %rcx, %rcx
jnz include_table_seek_element
include_table_seek_failure:
movb $1, %al
ret
include_table_seek_success:
movq %rdx, %rbx
xorb %al, %al
ret


.align 8
include_table_address: .quad 0
include_table_capacity: .quad 0
include_table_size: .quad 0
