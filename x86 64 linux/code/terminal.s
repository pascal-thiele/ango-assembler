.section .text


terminal_out:
# send the current buffer
movl $1, %eax
movl $1, %edi
leaq terminal_buffer, %rsi
movzwq terminal_buffer_size, %rdx
syscall
# reset the buffer size
movw $0, terminal_buffer_size
ret


# in
# al character to append
terminal_append_character:
leaq terminal_buffer, %rbx
movzwq terminal_buffer_size, %rcx
addq %rcx, %rbx
movb %al, (%rbx)
# increment size
addw $1, %cx
movw %cx, terminal_buffer_size
ret


# in
# rax string address
# bx string size
terminal_append_string:
leaq terminal_buffer, %rcx
movw terminal_buffer_size, %dx
movzwq %dx, %rsi
addq %rsi, %rcx
addw %bx, %dx
movw %dx, terminal_buffer_size
movb (%rax), %dl
movb %dl, (%rcx)
addw $-1, %bx
testw %bx, %bx
jz terminal_append_string_return
terminal_append_string_copy:
addq $1, %rax
movb (%rax), %dl
addq $1, %rcx
movb %dl, (%rcx)
addw $-1, %bx
testw %bx, %bx
jnz terminal_append_string_copy
terminal_append_string_return:
ret


# in
# rax signed integer
terminal_append_integer:
leaq terminal_buffer, %rbx
movzwq terminal_buffer_size, %rcx
addq %rcx, %rbx

# check for negative
testq %rax, %rax
jns terminal_append_integer_negative_end
negq %rax
movb $45, (%rbx)
addq $1, %rbx
addq $1, %rcx
terminal_append_integer_negative_end:

# extract digits
xorl %esi, %esi # digit count
movq $10, %rdi
terminal_append_integer_extract_digit:
xorl %edx, %edx
divq %rdi
addq $48, %rdx
pushq %rdx
addq $1, %rsi
test %rax, %rax
jnz terminal_append_integer_extract_digit

# increment the buffer size
addq %rsi, %rcx
movw %cx, terminal_buffer_size
terminal_append_integer_digit:
popq %rax
movb %al, (%rbx)
addq $1, %rbx
addq $-1, %rsi
test %rsi, %rsi
jnz terminal_append_integer_digit
ret


.align 2
terminal_buffer_size: .word 0
.align 8
terminal_buffer: .zero 1024
