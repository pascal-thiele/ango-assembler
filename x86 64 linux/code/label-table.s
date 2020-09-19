# label byte layout
# 0 identifier address
# 8 identifier size
# 16 value
# 24

.section .text


# in
# rax label address
# out
# rax label value
label_table_get:
movq 16(%rax), %rax
ret


# in
# rax label address
# rbx label value
label_table_set:
movq %rbx, 16(%rax)
ret


# in
# rax capacity
# out
# al status
label_table_initialize:
movq %rax, label_table_capacity
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
js label_table_initialize_failure
movq %rax, label_table_address
xorb %al, %al
ret
label_table_initialize_failure:
movb $1, %al
ret


# in
# rax label identifier address
# rbx label identifier size
label_table_insert:
movq %rax, %rcx
movq label_table_size, %rax
addq $1, %rax
movq %rax, label_table_size
movq $24, %rdx
mulq %rdx
movq label_table_address, %rdx
addq %rdx, %rax
movq %rcx, (%rax)
movq %rbx, 8(%rax)
movq $0, 16(%rax)
ret


# in
# rax label identifier address
# rbx label identifier size
# out
# rax label identifier occurrences
label_table_count:
xorq %rcx, %rcx # occurences
movq label_table_size, %rdx
testq %rdx, %rdx
jz label_table_count_return
movq label_table_address, %rsi
label_table_count_element:
addq $24, %rsi
cmpq 8(%rsi), %rbx
jne label_table_count_element_end
movq (%rsi), %rdi
movq %rax, %r8
movq %rbx, %r9
label_table_count_character:
movb (%rdi), %r10b
cmpb (%r8), %r10b
jne label_table_count_element_end
addq $-1, %r9
testq %r9, %r9
jz label_table_count_match
addq $1, %rdi
addq $1, %r8
jmp label_table_count_character
label_table_count_match:
addq $1, %rcx
label_table_count_element_end:
addq $-1, %rdx
testq %rdx, %rdx
jnz label_table_count_element
label_table_count_return:
movq %rcx, %rax
ret


# in
# rax label identifier address
# rbx label identifier size
# out
# al status
# rbx label address
label_table_seek:
movq label_table_size, %rcx
testq %rcx, %rcx
jz label_table_seek_failure
movq label_table_address, %rdx
label_table_seek_element:
addq $24, %rdx
cmpq 8(%rdx), %rbx
jne label_table_seek_element_end
movq (%rdx), %rsi
movb (%rsi), %dil
cmpb (%rax), %dil
jne label_table_seek_element_end
movq %rax, %rdi
movq %rbx, %r8
label_table_seek_identify:
addq $-1, %r8
testq %r8, %r8
jz label_table_seek_success
addq $1, %rsi
movb (%rsi), %r9b
addq $1, %rdi
cmpb (%rdi), %r9b
je label_table_seek_identify
label_table_seek_element_end:
addq $-1, %rcx
testq %rcx, %rcx
jnz label_table_seek_element
label_table_seek_failure:
movb $1, %al
ret
label_table_seek_success:
movq %rdx, %rbx
xorb %al, %al
ret


.align 8
label_table_address: .quad 0
label_table_capacity: .quad 0
label_table_size: .quad 0
