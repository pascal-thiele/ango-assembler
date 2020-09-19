# the file paths given to following functions have to be null terminated

.section .text


# in
# rax file path address
# out
# al status
# rbx file data address
# rcx file data size
file_read:
pushq %r12
pushq %r13
pushq %r14
# open the file
movq %rax, %rdi
movl $2, %eax
xorl %esi, %esi # read only
syscall
cmpq $-1, %rax
je file_read_failure
movq %rax, %r12
# seek the end of the file to obtain its size
movl $8, %eax
movq %r12, %rdi
xorl %esi, %esi
movl $2, %edx
syscall
cmpq $1, %rax
jl file_read_failure
movq %rax, %r13
# allocate memory to load the file into
movl $9, %eax
xorl %edi, %edi # address
movq %r13, %rsi # length
movl $7, %edx # protection: read write execute
movl $-1, %r8d # file descriptor
xorl %r9d, %r9d # offset
movl $34, %r10d # flags: private anonymous
syscall
testq %rax, %rax
js file_read_failure
movq %rax, %r14
# seek the start of the file
movl $8, %eax
movq %r12, %rdi
xorl %esi, %esi
xorl %edx, %edx
syscall
testq %rax, %rax
jnz file_read_failure
# read the file
xorl %eax, %eax
movq %r12, %rdi
movq %r14, %rsi
movq %r13, %rdx
syscall
cmpq %r13, %rax
jne file_read_failure
# close the file
movl $3, %eax
movq %r12, %rdi
syscall
cmpq $-1, %rax
je file_read_failure
# success
xorb %al, %al
movq %r14, %rbx
movq %r13, %rcx
jmp file_read_return
file_read_failure:
movb $1, %al
file_read_return:
popq %r14
popq %r13
popq %r12
ret


# in
# rax file data address
# rbx file data size
# rcx file path address
# out
# al status
file_write:
pushq %r12
pushq %r13
movq %rax, %r12
movq %rbx, %r13
# open the file
movl $2, %eax
movq %rcx, %rdi
movl $577, %esi # write only | create | truncate
movl $511, %edx # read write execute permissions for all
syscall
cmpq $-1, %rax
je file_write_failure
# write the data to the file
movq %rax, %rdi
movl $1, %eax
movq %r12, %rsi
movq %r13, %rdx
syscall
cmpq %r13, %rax
jl file_write_failure
# success
xorb %al, %al
jmp file_write_return
file_write_failure:
movb $1, %al
file_write_return:
popq %r13
popq %r12
ret
