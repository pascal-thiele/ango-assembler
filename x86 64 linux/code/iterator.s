.section .text


iterator_to_terminal:
movq iterator_file_path, %rax
movq iterator_file_path_size, %rbx
call terminal_append_string
movb $58, %al
call terminal_append_character
movq iterator_row_identifier, %rax
call terminal_append_integer
movb $58, %al
call terminal_append_character
movq iterator_column_identifier, %rax
call terminal_append_integer
movb $58, %al
call terminal_append_character
movb $32, %al
call terminal_append_character
ret


# in
# rax current character
# rbx character count
# out
# rax token size
iterator_calculate_token_size:
xorl %ecx, %ecx
cmpq %rcx, %rbx
je iterator_calculate_token_size_end
movb (%rax), %dl
cmpb $10, %dl
je iterator_calculate_token_size_end
cmpb $32, %dl
je iterator_calculate_token_size_end
cmpb $35, %dl
je iterator_calculate_token_size_end
iterator_calculate_token_size_next:
addq $1, %rcx
cmpq %rcx, %rbx
je iterator_calculate_token_size_end
addq $1, %rax
movb (%rax), %dl
cmpb $10, %dl
je iterator_calculate_token_size_end
cmpb $32, %dl
je iterator_calculate_token_size_end
cmpb $35, %dl
jne iterator_calculate_token_size_next
iterator_calculate_token_size_end:
movq %rcx, %rax
ret


# in
# rax file data
# rbx file size
# rcx file path data
# rdx file path size
# out
# al zero if any token was found
iterator_reset:
movl $1, %esi # row identifier
movl $1, %edi # column identifier
# jump separators to find the first token
testq %rbx, %rbx
jz iterator_reset_jump_separators_end
movb (%rax), %r8b
cmpb $10, %r8b
je iterator_reset_jump_separators_line_feed
cmpb $32, %r8b
je iterator_reset_jump_separators_space
cmpb $35, %r8b
je iterator_reset_jump_separators_comment
jmp iterator_reset_jump_separators_end
iterator_reset_jump_separators:
addq $-1, %rbx
testq %rbx, %rbx
jz iterator_reset_jump_separators_end
addq $1, %rax
movb (%rax), %r8b
cmpb $10, %r8b
je iterator_reset_jump_separators_line_feed
cmpb $32, %r8b
je iterator_reset_jump_separators_space
cmpb $35, %r8b
jne iterator_reset_jump_separators_end
iterator_reset_jump_separators_comment:
addq $1, %rdi
addq $-1, %rbx
testq %rbx, %rbx
jz iterator_reset_jump_separators_end
addq $1, %rax
cmpb $10, (%rax)
jne iterator_reset_jump_separators_comment
addq $1, %rsi
movl $1, %edi
jmp iterator_reset_jump_separators
iterator_reset_jump_separators_line_feed:
addq $1, %rsi
movl $1, %edi
jmp iterator_reset_jump_separators
iterator_reset_jump_separators_space:
addq $1, %rdi
jmp iterator_reset_jump_separators
iterator_reset_jump_separators_end:

# update the iterator variables
movq %rax, iterator_current_character
movq %rbx, iterator_character_count
movq %rcx, iterator_file_path
movq %rdx, iterator_file_path_size
movq %rsi, iterator_row_identifier
movq %rdi, iterator_column_identifier
call iterator_calculate_token_size
movq %rax, iterator_token_size

# prepare return value
movq %rax, %rbx
xorb %al, %al
testq %rbx, %rbx
jnz iterator_reset_return
addb $1, %al
iterator_reset_return:
ret


# out
# al zero if any token was found in a following line
iterator_next_line:
# jump the current token
movq iterator_token_size, %rsi
movq iterator_current_character, %rax
addq %rsi, %rax
movq iterator_character_count, %rbx
subq %rsi, %rbx
movq iterator_column_identifier, %rcx
addq %rsi, %rcx
movq iterator_row_identifier, %rdx

# seek the next line feed
testq %rbx, %rbx
jz iterator_next_line_jump_separators_end
cmpb $10, (%rax)
je iterator_next_line_seek_line_feed_end
iterator_next_line_seek_line_feed:
addq $-1, %rbx
testq %rbx, %rbx
jz iterator_next_line_jump_separators_end
addq $1, %rax
addq $1, %rcx
cmpb $10, (%rax)
jne iterator_next_line_seek_line_feed
iterator_next_line_seek_line_feed_end:
movl $1, %ecx
addq $1, %rdx

iterator_next_line_jump_separators:
addq $-1, %rbx
testq %rbx, %rbx
jz iterator_next_line_jump_separators_end
addq $1, %rax
movb (%rax), %sil
cmpb $10, %sil
je iterator_next_line_jump_separators_line_feed
cmpb $32, %sil
je iterator_next_line_jump_separators_space
cmpb $35, %sil
jne iterator_next_line_jump_separators_end
iterator_next_line_jump_separators_comment:
addq $1, %rcx
addq $-1, %rbx
testq %rbx, %rbx
jz iterator_next_line_jump_separators_end
addq $1, %rax
cmpb $10, (%rax)
jne iterator_next_line_jump_separators_comment
movl $1, %ecx
addq $1, %rdx
jmp iterator_next_line_jump_separators
iterator_next_line_jump_separators_line_feed:
movl $1, %ecx
addq $1, %rdx
jmp iterator_next_line_jump_separators
iterator_next_line_jump_separators_space:
addq $1, %rcx
jmp iterator_next_line_jump_separators
iterator_next_line_jump_separators_end:

# update iterator variables
movq %rax, iterator_current_character
movq %rbx, iterator_character_count
movq %rcx, iterator_column_identifier
movq %rdx, iterator_row_identifier
# update the token size
call iterator_calculate_token_size
movq %rax, iterator_token_size

# prepare return value
movq %rax, %rbx
xorb %al, %al
testq %rbx, %rbx
jnz iterator_next_line_return
addb $1, %al
iterator_next_line_return:
ret


# out
# al zero if next operand exists
iterator_next_token:
# jump the current token
movq iterator_token_size, %rsi
movq iterator_current_character, %rax
addq %rsi, %rax
movq iterator_character_count, %rbx
subq %rsi, %rbx
movq iterator_column_identifier, %rcx
addq %rsi, %rcx

# jump following spaces
testq %rbx, %rbx
jz iterator_next_token_jump_spaces_end
cmpb $32, (%rax)
jne iterator_next_token_jump_spaces_end
iterator_next_token_jump_spaces:
addq $-1, %rbx
testq %rbx, %rbx
jz iterator_next_token_jump_spaces_end
addq $1, %rax
addq $1, %rcx
cmpb $32, (%rax)
je iterator_next_token_jump_spaces
iterator_next_token_jump_spaces_end:

# update iterator variables
movq %rax, iterator_current_character
movq %rbx, iterator_character_count
movq %rcx, iterator_column_identifier
# update the token size
call iterator_calculate_token_size
movq %rax, iterator_token_size

# prepare return values
movq %rax, %rbx
xorb %al, %al
testq %rbx, %rbx
jnz iterator_next_token_return
addb $1, %al
iterator_next_token_return:
ret


# out
# al status
# rbx quote address
# rcx quote size
iterator_extract_quote:
movq iterator_current_character, %rax
cmpb $34, (%rax)
jne iterator_extract_quote_failure
movq iterator_character_count, %rdx
addq $-1, %rdx
testq %rdx, %rdx
jz iterator_extract_quote_failure
movq %rax, %rbx
addq $1, %rbx
xorl %ecx, %ecx
iterator_extract_quote_loop:
addq $1, %rax
movb (%rax), %sil
cmpb $34, %sil
je iterator_extract_quote_success
cmpb $10, %sil
je iterator_extract_quote_failure
addq $1, %rcx
addq $-1, %rdx
testq %rdx, %rdx
jnz iterator_extract_quote_loop
iterator_extract_quote_failure:
movb $1, %al
ret
iterator_extract_quote_success:
xorb %al, %al
ret


# out
# al status
# rbx integer
iterator_extract_integer:
movq iterator_current_character, %rsi
movq iterator_token_size, %rdi

movsbq (%rsi), %rbx
cmpq $45, %rbx
je iterator_extract_integer_negative
cmpq $48, %rbx
jl iterator_extract_integer_failure
cmpq $58, %rbx
jge iterator_extract_integer_failure
addq $-48, %rbx
addq $-1, %rdi
testq %rdi, %rdi
jz iterator_extract_integer_positive_success
movq $10, %rcx
xorq %rdx, %rdx
iterator_extract_integer_positive_digit:
addq $1, %rsi
movsbq (%rsi), %r8
cmpq $48, %r8
jl iterator_extract_integer_failure
cmpq $58, %r8
jge iterator_extract_integer_failure
addq $-48, %r8
# prevent integer overflow
movq $18446744073709551615, %rax
subq %r8, %rax
divq %rcx
cmpq %rbx, %rax
jb iterator_extract_integer_failure
# add the digit to the total
movq %rbx, %rax
mulq %rcx
addq %r8, %rax
movq %rax, %rbx
# next
addq $-1, %rdi
testq %rdi, %rdi
jnz iterator_extract_integer_positive_digit
iterator_extract_integer_positive_success:
xorb %al, %al
ret

iterator_extract_integer_negative:
addq $-1, %rdi
testq %rdi, %rdi
jz iterator_extract_integer_failure
xorq %rbx, %rbx
movq $10, %rcx
iterator_extract_integer_negative_digit:
addq $1, %rsi
movsbq (%rsi), %r8
cmpq $48, %r8
jl iterator_extract_integer_failure
cmpq $58, %r8
jge iterator_extract_integer_failure
addq $-48, %r8
# prevent integer overflow
movq $-9223372036854775808, %rax
addq %r8, %rax
movq $-1, %rdx
idivq %rcx
cmpq %rax, %rbx
jl iterator_extract_integer_failure
# add the digit to the total
movq %rbx, %rax
imulq %rcx
subq %r8, %rax
movq %rax, %rbx
# next
addq $-1, %rdi
testq %rdi, %rdi
jnz iterator_extract_integer_negative_digit
xorb %al, %al
ret

# implement???
# hexadecimal 0h 16_ 16'1fae
# binary 0b 2_ 2'10001
# octal 0o 8_ 8'172

iterator_extract_integer_failure:
movb $1, %al
ret


# out
# al status
# rbx signed integer
iterator_extract_signed_integer:
movq iterator_current_character, %rsi
movq iterator_token_size, %rdi

movsbq (%rsi), %rbx
cmpq $45, %rbx
je iterator_extract_signed_integer_negative
cmpq $48, %rbx
jl iterator_extract_signed_integer_failure
cmpq $58, %rbx
jge iterator_extract_signed_integer_failure
addq $-48, %rbx
addq $-1, %rdi
testq %rdi, %rdi
jz iterator_extract_signed_integer_positive_success
movq $10, %rcx
xorq %rdx, %rdx
iterator_extract_signed_integer_positive_digit:
addq $1, %rsi
movsbq (%rsi), %r8
cmpq $48, %r8
jl iterator_extract_signed_integer_failure
cmpq $58, %r8
jge iterator_extract_signed_integer_failure
addq $-48, %r8
# prevent integer overflow
movq $9223372036854775807, %rax
subq %r8, %rax
idivq %rcx
cmpq %rbx, %rax
jl iterator_extract_signed_integer_failure
# add the digit to the total
movq %rbx, %rax
imulq %rcx
addq %r8, %rax
movq %rax, %rbx
# next
addq $-1, %rdi
testq %rdi, %rdi
jnz iterator_extract_signed_integer_positive_digit
iterator_extract_signed_integer_positive_success:
xorb %al, %al
ret

iterator_extract_signed_integer_negative:
addq $-1, %rdi
testq %rdi, %rdi
jz iterator_extract_signed_integer_failure
xorq %rbx, %rbx
movq $10, %rcx
iterator_extract_signed_integer_negative_digit:
addq $1, %rsi
movsbq (%rsi), %r8
cmpq $48, %r8
jl iterator_extract_signed_integer_failure
cmpq $58, %r8
jge iterator_extract_signed_integer_failure
addq $-48, %r8
# prevent integer overflow
movq $-9223372036854775808, %rax
addq %r8, %rax
movq $-1, %rdx
idivq %rcx
cmpq %rax, %rbx
jl iterator_extract_signed_integer_failure
# add the digit to the total
movq %rbx, %rax
imulq %rcx
subq %r8, %rax
movq %rax, %rbx
# next
addq $-1, %rdi
testq %rdi, %rdi
jnz iterator_extract_signed_integer_negative_digit
xorb %al, %al
ret

iterator_extract_signed_integer_failure:
movb $1, %al
ret


# out
# al status
# rbx unsigned integer
iterator_extract_unsigned_integer:
movq iterator_current_character, %rsi
movq iterator_token_size, %rdi
movsbq (%rsi), %rbx
cmpq $48, %rbx
jl iterator_extract_unsigned_integer_failure
cmpq $58, %rbx
jge iterator_extract_unsigned_integer_failure
addq $-48, %rbx
addq $-1, %rdi
testq %rdi, %rdi
jz iterator_extract_unsigned_integer_success
movq $10, %rcx
xorq %rdx, %rdx
iterator_extract_unsigned_integer_digit:
addq $1, %rsi
movsbq (%rsi), %r8
cmpq $48, %r8
jl iterator_extract_unsigned_integer_failure
cmpq $58, %r8
jge iterator_extract_unsigned_integer_failure
addq $-48, %r8
# prevent integer overflow
movq $18446744073709551615, %rax
subq %r8, %rax
divq %rcx
cmpq %rbx, %rax
jb iterator_extract_unsigned_integer_failure
# add the digit to the total
movq %rbx, %rax
mulq %rcx
addq %r8, %rax
movq %rax, %rbx
# next
addq $-1, %rdi
testq %rdi, %rdi
jnz iterator_extract_unsigned_integer_digit
iterator_extract_unsigned_integer_success:
xorb %al, %al
ret
iterator_extract_unsigned_integer_failure:
movb $1, %al
ret


# undefined behaviour when token size is zero
# out
# al status
# bl fence mask
iterator_extract_fence_mask:
movq iterator_current_character, %rax
movq iterator_token_size, %rcx
movb (%rax), %dl
# first character
movb $8, %bl
cmpb $105, %dl
je iterator_extract_fence_mask_first
movb $4, %bl
cmpb $111, %dl
je iterator_extract_fence_mask_first
movb $2, %bl
cmpb $114, %dl
je iterator_extract_fence_mask_first
movb $1, %bl
cmpb $119, %dl
jne iterator_extract_fence_mask_failure
iterator_extract_fence_mask_first:
addq $-1, %rcx
testq %rcx, %rcx
jz iterator_extract_fence_mask_success
iterator_extract_fence_mask_character:
addq $1, %rax
movb (%rax), %dl
movb $8, %sil
cmpb $105, %dl
je iterator_extract_fence_mask_character_end
movb $4, %sil
cmpb $111, %dl
je iterator_extract_fence_mask_character_end
movb $2, %sil
cmpb $114, %dl
je iterator_extract_fence_mask_character_end
movb $1, %sil
cmpb $119, %dl
jne iterator_extract_fence_mask_failure
iterator_extract_fence_mask_character_end:
movb %bl, %dl
andb %sil, %dl
testb %dl, %dl
jnz iterator_extract_fence_mask_failure
orb %sil, %bl
# next
addq $-1, %rcx
testq %rcx, %rcx
jnz iterator_extract_fence_mask_character
iterator_extract_fence_mask_success:
xorb %al, %al
ret
iterator_extract_fence_mask_failure:
movb $1, %al
ret


# out
# al zero if integer register
# bl integer register identifier
iterator_extract_integer_register:
movq iterator_current_character, %rax
movq iterator_token_size, %rbx
# x0
cmpq $2, %rbx
jne iterator_extract_integer_register_zero
cmpb $120, (%rax)
jne iterator_extract_integer_register_zero
cmpb $48, 1(%rax)
jne iterator_extract_integer_register_zero
xorb %al, %al
xorb %bl, %bl
ret
iterator_extract_integer_register_zero:
cmpq $4, %rbx
jne iterator_extract_integer_register_x1
cmpb $122, (%rax)
jne iterator_extract_integer_register_x1
cmpb $101, 1(%rax)
jne iterator_extract_integer_register_x1
cmpb $114, 2(%rax)
jne iterator_extract_integer_register_x1
cmpb $111, 3(%rax)
jne iterator_extract_integer_register_x1
xorb %al, %al
xorb %bl, %bl
ret
iterator_extract_integer_register_x1:
cmpq $2, %rbx
jne iterator_extract_integer_register_ra
cmpb $120, (%rax)
jne iterator_extract_integer_register_ra
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_ra
xorb %al, %al
movb $1, %bl
ret
iterator_extract_integer_register_ra:
cmpq $2, %rbx
jne iterator_extract_integer_register_x2
cmpb $114, (%rax)
jne iterator_extract_integer_register_x2
cmpb $97, 1(%rax)
jne iterator_extract_integer_register_x2
xorb %al, %al
movb $1, %bl
ret
iterator_extract_integer_register_x2:
cmpq $2, %rbx
jne iterator_extract_integer_register_sp
cmpb $120, (%rax)
jne iterator_extract_integer_register_sp
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_sp
xorb %al, %al
movb $2, %bl
ret
iterator_extract_integer_register_sp:
cmpq $2, %rbx
jne iterator_extract_integer_register_x3
cmpb $115, (%rax)
jne iterator_extract_integer_register_x3
cmpb $112, 1(%rax)
jne iterator_extract_integer_register_x3
xorb %al, %al
movb $2, %bl
ret
iterator_extract_integer_register_x3:
cmpq $2, %rbx
jne iterator_extract_integer_register_gp
cmpb $120, (%rax)
jne iterator_extract_integer_register_gp
cmpb $51, 1(%rax)
jne iterator_extract_integer_register_gp
xorb %al, %al
movb $3, %bl
ret
iterator_extract_integer_register_gp:
cmpq $2, %rbx
jne iterator_extract_integer_register_x4
cmpb $103, (%rax)
jne iterator_extract_integer_register_x4
cmpb $112, 1(%rax)
jne iterator_extract_integer_register_x4
xorb %al, %al
movb $3, %bl
ret
iterator_extract_integer_register_x4:
cmpq $2, %rbx
jne iterator_extract_integer_register_tp
cmpb $120, (%rax)
jne iterator_extract_integer_register_tp
cmpb $52, 1(%rax)
jne iterator_extract_integer_register_tp
xorb %al, %al
movb $4, %bl
ret
iterator_extract_integer_register_tp:
cmpq $2, %rbx
jne iterator_extract_integer_register_x5
cmpb $116, (%rax)
jne iterator_extract_integer_register_x5
cmpb $112, 1(%rax)
jne iterator_extract_integer_register_x5
xorb %al, %al
movb $4, %bl
ret
iterator_extract_integer_register_x5:
cmpq $2, %rbx
jne iterator_extract_integer_register_t0
cmpb $120, (%rax)
jne iterator_extract_integer_register_t0
cmpb $53, 1(%rax)
jne iterator_extract_integer_register_t0
xorb %al, %al
movb $5, %bl
ret
iterator_extract_integer_register_t0:
cmpq $2, %rbx
jne iterator_extract_integer_register_x6
cmpb $116, (%rax)
jne iterator_extract_integer_register_x6
cmpb $48, 1(%rax)
jne iterator_extract_integer_register_x6
xorb %al, %al
movb $5, %bl
ret
iterator_extract_integer_register_x6:
cmpq $2, %rbx
jne iterator_extract_integer_register_t1
cmpb $120, (%rax)
jne iterator_extract_integer_register_t1
cmpb $54, 1(%rax)
jne iterator_extract_integer_register_t1
xorb %al, %al
movb $6, %bl
ret
iterator_extract_integer_register_t1:
cmpq $2, %rbx
jne iterator_extract_integer_register_x7
cmpb $116, (%rax)
jne iterator_extract_integer_register_x7
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_x7
xorb %al, %al
movb $6, %bl
ret
iterator_extract_integer_register_x7:
cmpq $2, %rbx
jne iterator_extract_integer_register_t2
cmpb $120, (%rax)
jne iterator_extract_integer_register_t2
cmpb $55, 1(%rax)
jne iterator_extract_integer_register_t2
xorb %al, %al
movb $7, %bl
ret
iterator_extract_integer_register_t2:
cmpq $2, %rbx
jne iterator_extract_integer_register_x8
cmpb $116, (%rax)
jne iterator_extract_integer_register_x8
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_x8
xorb %al, %al
movb $7, %bl
ret
iterator_extract_integer_register_x8:
cmpq $2, %rbx
jne iterator_extract_integer_register_s0
cmpb $120, (%rax)
jne iterator_extract_integer_register_s0
cmpb $56, 1(%rax)
jne iterator_extract_integer_register_s0
xorb %al, %al
movb $8, %bl
ret
iterator_extract_integer_register_s0:
cmpq $2, %rbx
jne iterator_extract_integer_register_fp
cmpb $115, (%rax)
jne iterator_extract_integer_register_fp
cmpb $48, 1(%rax)
jne iterator_extract_integer_register_fp
xorb %al, %al
movb $8, %bl
ret
iterator_extract_integer_register_fp:
cmpq $2, %rbx
jne iterator_extract_integer_register_x9
cmpb $102, (%rax)
jne iterator_extract_integer_register_x9
cmpb $112, 1(%rax)
jne iterator_extract_integer_register_x9
xorb %al, %al
movb $8, %bl
ret
iterator_extract_integer_register_x9:
cmpq $2, %rbx
jne iterator_extract_integer_register_s1
cmpb $120, (%rax)
jne iterator_extract_integer_register_s1
cmpb $57, 1(%rax)
jne iterator_extract_integer_register_s1
xorb %al, %al
movb $9, %bl
ret
iterator_extract_integer_register_s1:
cmpq $2, %rbx
jne iterator_extract_integer_register_x10
cmpb $115, (%rax)
jne iterator_extract_integer_register_x10
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_x10
xorb %al, %al
movb $9, %bl
ret
iterator_extract_integer_register_x10:
cmpq $3, %rbx
jne iterator_extract_integer_register_a0
cmpb $120, (%rax)
jne iterator_extract_integer_register_a0
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a0
cmpb $48, 2(%rax)
jne iterator_extract_integer_register_a0
xorb %al, %al
movb $10, %bl
ret
iterator_extract_integer_register_a0:
cmpq $2, %rbx
jne iterator_extract_integer_register_x11
cmpb $97, (%rax)
jne iterator_extract_integer_register_x11
cmpb $48, 1(%rax)
jne iterator_extract_integer_register_x11
xorb %al, %al
movb $10, %bl
ret
iterator_extract_integer_register_x11:
cmpq $3, %rbx
jne iterator_extract_integer_register_a1
cmpb $120, (%rax)
jne iterator_extract_integer_register_a1
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a1
cmpb $49, 2(%rax)
jne iterator_extract_integer_register_a1
xorb %al, %al
movb $11, %bl
ret
iterator_extract_integer_register_a1:
cmpq $2, %rbx
jne iterator_extract_integer_register_x12
cmpb $97, (%rax)
jne iterator_extract_integer_register_x12
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_x12
xorb %al, %al
movb $11, %bl
ret
iterator_extract_integer_register_x12:
cmpq $3, %rbx
jne iterator_extract_integer_register_a2
cmpb $120, (%rax)
jne iterator_extract_integer_register_a2
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a2
cmpb $50, 2(%rax)
jne iterator_extract_integer_register_a2
xorb %al, %al
movb $12, %bl
ret
iterator_extract_integer_register_a2:
cmpq $2, %rbx
jne iterator_extract_integer_register_x13
cmpb $97, (%rax)
jne iterator_extract_integer_register_x13
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_x13
xorb %al, %al
movb $12, %bl
ret
iterator_extract_integer_register_x13:
cmpq $3, %rbx
jne iterator_extract_integer_register_a3
cmpb $120, (%rax)
jne iterator_extract_integer_register_a3
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a3
cmpb $51, 2(%rax)
jne iterator_extract_integer_register_a3
xorb %al, %al
movb $13, %bl
ret
iterator_extract_integer_register_a3:
cmpq $2, %rbx
jne iterator_extract_integer_register_x14
cmpb $97, (%rax)
jne iterator_extract_integer_register_x14
cmpb $51, 1(%rax)
jne iterator_extract_integer_register_x14
xorb %al, %al
movb $13, %bl
ret
iterator_extract_integer_register_x14:
cmpq $3, %rbx
jne iterator_extract_integer_register_a4
cmpb $120, (%rax)
jne iterator_extract_integer_register_a4
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a4
cmpb $52, 2(%rax)
jne iterator_extract_integer_register_a4
xorb %al, %al
movb $14, %bl
ret
iterator_extract_integer_register_a4:
cmpq $2, %rbx
jne iterator_extract_integer_register_x15
cmpb $97, (%rax)
jne iterator_extract_integer_register_x15
cmpb $52, 1(%rax)
jne iterator_extract_integer_register_x15
xorb %al, %al
movb $14, %bl
ret
iterator_extract_integer_register_x15:
cmpq $3, %rbx
jne iterator_extract_integer_register_a5
cmpb $120, (%rax)
jne iterator_extract_integer_register_a5
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a5
cmpb $53, 2(%rax)
jne iterator_extract_integer_register_a5
xorb %al, %al
movb $15, %bl
ret
iterator_extract_integer_register_a5:
cmpq $2, %rbx
jne iterator_extract_integer_register_x16
cmpb $97, (%rax)
jne iterator_extract_integer_register_x16
cmpb $53, 1(%rax)
jne iterator_extract_integer_register_x16
xorb %al, %al
movb $15, %bl
ret
iterator_extract_integer_register_x16:
cmpq $3, %rbx
jne iterator_extract_integer_register_a6
cmpb $120, (%rax)
jne iterator_extract_integer_register_a6
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a6
cmpb $54, 2(%rax)
jne iterator_extract_integer_register_a6
xorb %al, %al
movb $16, %bl
ret
iterator_extract_integer_register_a6:
cmpq $2, %rbx
jne iterator_extract_integer_register_x17
cmpb $97, (%rax)
jne iterator_extract_integer_register_x17
cmpb $54, 1(%rax)
jne iterator_extract_integer_register_x17
xorb %al, %al
movb $16, %bl
ret
iterator_extract_integer_register_x17:
cmpq $3, %rbx
jne iterator_extract_integer_register_a7
cmpb $120, (%rax)
jne iterator_extract_integer_register_a7
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_a7
cmpb $55, 2(%rax)
jne iterator_extract_integer_register_a7
xorb %al, %al
movb $17, %bl
ret
iterator_extract_integer_register_a7:
cmpq $2, %rbx
jne iterator_extract_integer_register_x18
cmpb $97, (%rax)
jne iterator_extract_integer_register_x18
cmpb $55, 1(%rax)
jne iterator_extract_integer_register_x18
xorb %al, %al
movb $17, %bl
ret
iterator_extract_integer_register_x18:
cmpq $3, %rbx
jne iterator_extract_integer_register_s2
cmpb $120, (%rax)
jne iterator_extract_integer_register_s2
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_s2
cmpb $56, 2(%rax)
jne iterator_extract_integer_register_s2
xorb %al, %al
movb $18, %bl
ret
iterator_extract_integer_register_s2:
cmpq $2, %rbx
jne iterator_extract_integer_register_x19
cmpb $115, (%rax)
jne iterator_extract_integer_register_x19
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_x19
xorb %al, %al
movb $18, %bl
ret
iterator_extract_integer_register_x19:
cmpq $3, %rbx
jne iterator_extract_integer_register_s3
cmpb $120, (%rax)
jne iterator_extract_integer_register_s3
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_s3
cmpb $57, 2(%rax)
jne iterator_extract_integer_register_s3
xorb %al, %al
movb $19, %bl
ret
iterator_extract_integer_register_s3:
cmpq $2, %rbx
jne iterator_extract_integer_register_x20
cmpb $115, (%rax)
jne iterator_extract_integer_register_x20
cmpb $51, 1(%rax)
jne iterator_extract_integer_register_x20
xorb %al, %al
movb $19, %bl
ret
iterator_extract_integer_register_x20:
cmpq $3, %rbx
jne iterator_extract_integer_register_s4
cmpb $120, (%rax)
jne iterator_extract_integer_register_s4
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s4
cmpb $48, 2(%rax)
jne iterator_extract_integer_register_s4
xorb %al, %al
movb $20, %bl
ret
iterator_extract_integer_register_s4:
cmpq $2, %rbx
jne iterator_extract_integer_register_x21
cmpb $115, (%rax)
jne iterator_extract_integer_register_x21
cmpb $52, 1(%rax)
jne iterator_extract_integer_register_x21
xorb %al, %al
movb $20, %bl
ret
iterator_extract_integer_register_x21:
cmpq $3, %rbx
jne iterator_extract_integer_register_s5
cmpb $120, (%rax)
jne iterator_extract_integer_register_s5
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s5
cmpb $49, 2(%rax)
jne iterator_extract_integer_register_s5
xorb %al, %al
movb $21, %bl
ret
iterator_extract_integer_register_s5:
cmpq $2, %rbx
jne iterator_extract_integer_register_x22
cmpb $115, (%rax)
jne iterator_extract_integer_register_x22
cmpb $53, 1(%rax)
jne iterator_extract_integer_register_x22
xorb %al, %al
movb $21, %bl
ret
iterator_extract_integer_register_x22:
cmpq $3, %rbx
jne iterator_extract_integer_register_s6
cmpb $120, (%rax)
jne iterator_extract_integer_register_s6
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s6
cmpb $50, 2(%rax)
jne iterator_extract_integer_register_s6
xorb %al, %al
movb $22, %bl
ret
iterator_extract_integer_register_s6:
cmpq $2, %rbx
jne iterator_extract_integer_register_x23
cmpb $115, (%rax)
jne iterator_extract_integer_register_x23
cmpb $54, 1(%rax)
jne iterator_extract_integer_register_x23
xorb %al, %al
movb $22, %bl
ret
iterator_extract_integer_register_x23:
cmpq $3, %rbx
jne iterator_extract_integer_register_s7
cmpb $120, (%rax)
jne iterator_extract_integer_register_s7
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s7
cmpb $51, 2(%rax)
jne iterator_extract_integer_register_s7
xorb %al, %al
movb $23, %bl
ret
iterator_extract_integer_register_s7:
cmpq $2, %rbx
jne iterator_extract_integer_register_x24
cmpb $115, (%rax)
jne iterator_extract_integer_register_x24
cmpb $55, 1(%rax)
jne iterator_extract_integer_register_x24
xorb %al, %al
movb $23, %bl
ret
iterator_extract_integer_register_x24:
cmpq $3, %rbx
jne iterator_extract_integer_register_s8
cmpb $120, (%rax)
jne iterator_extract_integer_register_s8
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s8
cmpb $52, 2(%rax)
jne iterator_extract_integer_register_s8
xorb %al, %al
movb $24, %bl
ret
iterator_extract_integer_register_s8:
cmpq $2, %rbx
jne iterator_extract_integer_register_x25
cmpb $115, (%rax)
jne iterator_extract_integer_register_x25
cmpb $56, 1(%rax)
jne iterator_extract_integer_register_x25
xorb %al, %al
movb $24, %bl
ret
iterator_extract_integer_register_x25:
cmpq $3, %rbx
jne iterator_extract_integer_register_s9
cmpb $120, (%rax)
jne iterator_extract_integer_register_s9
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s9
cmpb $53, 2(%rax)
jne iterator_extract_integer_register_s9
xorb %al, %al
movb $25, %bl
ret
iterator_extract_integer_register_s9:
cmpq $2, %rbx
jne iterator_extract_integer_register_x26
cmpb $115, (%rax)
jne iterator_extract_integer_register_x26
cmpb $57, 1(%rax)
jne iterator_extract_integer_register_x26
xorb %al, %al
movb $25, %bl
ret
iterator_extract_integer_register_x26:
cmpq $3, %rbx
jne iterator_extract_integer_register_s10
cmpb $120, (%rax)
jne iterator_extract_integer_register_s10
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s10
cmpb $54, 2(%rax)
jne iterator_extract_integer_register_s10
xorb %al, %al
movb $26, %bl
ret
iterator_extract_integer_register_s10:
cmpq $3, %rbx
jne iterator_extract_integer_register_x27
cmpb $115, (%rax)
jne iterator_extract_integer_register_x27
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_x27
cmpb $48, 2(%rax)
jne iterator_extract_integer_register_x27
xorb %al, %al
movb $26, %bl
ret
iterator_extract_integer_register_x27:
cmpq $3, %rbx
jne iterator_extract_integer_register_s11
cmpb $120, (%rax)
jne iterator_extract_integer_register_s11
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_s11
cmpb $55, 2(%rax)
jne iterator_extract_integer_register_s11
xorb %al, %al
movb $27, %bl
ret
iterator_extract_integer_register_s11:
cmpq $3, %rbx
jne iterator_extract_integer_register_x28
cmpb $115, (%rax)
jne iterator_extract_integer_register_x28
cmpb $49, 1(%rax)
jne iterator_extract_integer_register_x28
cmpb $49, 2(%rax)
jne iterator_extract_integer_register_x28
xorb %al, %al
movb $27, %bl
ret
iterator_extract_integer_register_x28:
cmpq $3, %rbx
jne iterator_extract_integer_register_t3
cmpb $120, (%rax)
jne iterator_extract_integer_register_t3
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_t3
cmpb $56, 2(%rax)
jne iterator_extract_integer_register_t3
xorb %al, %al
movb $28, %bl
ret
iterator_extract_integer_register_t3:
cmpq $2, %rbx
jne iterator_extract_integer_register_x29
cmpb $116, (%rax)
jne iterator_extract_integer_register_x29
cmpb $51, 1(%rax)
jne iterator_extract_integer_register_x29
xorb %al, %al
movb $28, %bl
ret
iterator_extract_integer_register_x29:
cmpq $3, %rbx
jne iterator_extract_integer_register_t4
cmpb $120, (%rax)
jne iterator_extract_integer_register_t4
cmpb $50, 1(%rax)
jne iterator_extract_integer_register_t4
cmpb $57, 2(%rax)
jne iterator_extract_integer_register_t4
xorb %al, %al
movb $29, %bl
ret
iterator_extract_integer_register_t4:
cmpq $2, %rbx
jne iterator_extract_integer_register_x30
cmpb $116, (%rax)
jne iterator_extract_integer_register_x30
cmpb $52, 1(%rax)
jne iterator_extract_integer_register_x30
xorb %al, %al
movb $29, %bl
ret
iterator_extract_integer_register_x30:
cmpq $3, %rbx
jne iterator_extract_integer_register_t5
cmpb $120, (%rax)
jne iterator_extract_integer_register_t5
cmpb $51, 1(%rax)
jne iterator_extract_integer_register_t5
cmpb $48, 2(%rax)
jne iterator_extract_integer_register_t5
xorb %al, %al
movb $30, %bl
ret
iterator_extract_integer_register_t5:
cmpq $2, %rbx
jne iterator_extract_integer_register_x31
cmpb $116, (%rax)
jne iterator_extract_integer_register_x31
cmpb $53, 1(%rax)
jne iterator_extract_integer_register_x31
xorb %al, %al
movb $30, %bl
ret
iterator_extract_integer_register_x31:
cmpq $3, %rbx
jne iterator_extract_integer_register_t6
cmpb $120, (%rax)
jne iterator_extract_integer_register_t6
cmpb $51, 1(%rax)
jne iterator_extract_integer_register_t6
cmpb $49, 2(%rax)
jne iterator_extract_integer_register_t6
xorb %al, %al
movb $31, %bl
ret
iterator_extract_integer_register_t6:
cmpq $2, %rbx
jne iterator_extract_integer_register_unknown
cmpb $116, (%rax)
jne iterator_extract_integer_register_unknown
cmpb $54, 1(%rax)
jne iterator_extract_integer_register_unknown
xorb %al, %al
movb $31, %bl
ret
iterator_extract_integer_register_unknown:
movb $1, %al
ret


# out
# al status
# bl floating point register
iterator_extract_floating_point_register:
movq iterator_current_character, %rax
movq iterator_token_size, %rbx
# f0
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft0
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft0
cmpb $48, 1(%rax)
jne iterator_extract_floating_point_register_ft0
xorb %al, %al
xorb %bl, %bl
ret
iterator_extract_floating_point_register_ft0:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f1
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f1
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f1
cmpb $48, 2(%rax)
jne iterator_extract_floating_point_register_f1
xorb %al, %al
xorb %bl, %bl
ret
iterator_extract_floating_point_register_f1:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft1
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft1
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_ft1
xorb %al, %al
movb $1, %bl
ret
iterator_extract_floating_point_register_ft1:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f2
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f2
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f2
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_f2
xorb %al, %al
movb $1, %bl
ret
iterator_extract_floating_point_register_f2:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft2
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft2
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_ft2
xorb %al, %al
movb $2, %bl
ret
iterator_extract_floating_point_register_ft2:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f3
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f3
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f3
cmpb $50, 2(%rax)
jne iterator_extract_floating_point_register_f3
xorb %al, %al
movb $2, %bl
ret
iterator_extract_floating_point_register_f3:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft3
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft3
cmpb $51, 1(%rax)
jne iterator_extract_floating_point_register_ft3
xorb %al, %al
movb $3, %bl
ret
iterator_extract_floating_point_register_ft3:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f4
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f4
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f4
cmpb $51, 2(%rax)
jne iterator_extract_floating_point_register_f4
xorb %al, %al
movb $3, %bl
ret
iterator_extract_floating_point_register_f4:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft4
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft4
cmpb $52, 1(%rax)
jne iterator_extract_floating_point_register_ft4
xorb %al, %al
movb $4, %bl
ret
iterator_extract_floating_point_register_ft4:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f5
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f5
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f5
cmpb $52, 2(%rax)
jne iterator_extract_floating_point_register_f5
xorb %al, %al
movb $4, %bl
ret
iterator_extract_floating_point_register_f5:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft5
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft5
cmpb $53, 1(%rax)
jne iterator_extract_floating_point_register_ft5
xorb %al, %al
movb $5, %bl
ret
iterator_extract_floating_point_register_ft5:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f6
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f6
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f6
cmpb $53, 2(%rax)
jne iterator_extract_floating_point_register_f6
xorb %al, %al
movb $5, %bl
ret
iterator_extract_floating_point_register_f6:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft6
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft6
cmpb $54, 1(%rax)
jne iterator_extract_floating_point_register_ft6
xorb %al, %al
movb $6, %bl
ret
iterator_extract_floating_point_register_ft6:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f7
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f7
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f7
cmpb $54, 2(%rax)
jne iterator_extract_floating_point_register_f7
xorb %al, %al
movb $6, %bl
ret
iterator_extract_floating_point_register_f7:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_ft7
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft7
cmpb $55, 1(%rax)
jne iterator_extract_floating_point_register_ft7
xorb %al, %al
movb $7, %bl
ret
iterator_extract_floating_point_register_ft7:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f8
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f8
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f8
cmpb $55, 2(%rax)
jne iterator_extract_floating_point_register_f8
xorb %al, %al
movb $7, %bl
ret
iterator_extract_floating_point_register_f8:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_fs0
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs0
cmpb $56, 1(%rax)
jne iterator_extract_floating_point_register_fs0
xorb %al, %al
movb $8, %bl
ret
iterator_extract_floating_point_register_fs0:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f9
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f9
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f9
cmpb $48, 2(%rax)
jne iterator_extract_floating_point_register_f9
xorb %al, %al
movb $8, %bl
ret
iterator_extract_floating_point_register_f9:
cmpq $2, %rbx
jne iterator_extract_floating_point_register_fs1
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs1
cmpb $57, 1(%rax)
jne iterator_extract_floating_point_register_fs1
xorb %al, %al
movb $9, %bl
ret
iterator_extract_floating_point_register_fs1:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f10
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f10
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f10
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_f10
xorb %al, %al
movb $9, %bl
ret
iterator_extract_floating_point_register_f10:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa0
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa0
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa0
cmpb $48, 2(%rax)
jne iterator_extract_floating_point_register_fa0
xorb %al, %al
movb $10, %bl
ret
iterator_extract_floating_point_register_fa0:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f11
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f11
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f11
cmpb $48, 2(%rax)
jne iterator_extract_floating_point_register_f11
xorb %al, %al
movb $10, %bl
ret
iterator_extract_floating_point_register_f11:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa1
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa1
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa1
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_fa1
xorb %al, %al
movb $11, %bl
ret
iterator_extract_floating_point_register_fa1:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f12
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f12
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f12
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_f12
xorb %al, %al
movb $11, %bl
ret
iterator_extract_floating_point_register_f12:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa2
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa2
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa2
cmpb $50, 2(%rax)
jne iterator_extract_floating_point_register_fa2
xorb %al, %al
movb $12, %bl
ret
iterator_extract_floating_point_register_fa2:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f13
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f13
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f13
cmpb $50, 2(%rax)
jne iterator_extract_floating_point_register_f13
xorb %al, %al
movb $12, %bl
ret
iterator_extract_floating_point_register_f13:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa3
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa3
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa3
cmpb $51, 2(%rax)
jne iterator_extract_floating_point_register_fa3
xorb %al, %al
movb $13, %bl
ret
iterator_extract_floating_point_register_fa3:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f14
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f14
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f14
cmpb $51, 2(%rax)
jne iterator_extract_floating_point_register_f14
xorb %al, %al
movb $13, %bl
ret
iterator_extract_floating_point_register_f14:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa4
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa4
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa4
cmpb $52, 2(%rax)
jne iterator_extract_floating_point_register_fa4
xorb %al, %al
movb $14, %bl
ret
iterator_extract_floating_point_register_fa4:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f15
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f15
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f15
cmpb $52, 2(%rax)
jne iterator_extract_floating_point_register_f15
xorb %al, %al
movb $14, %bl
ret
iterator_extract_floating_point_register_f15:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa5
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa5
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa5
cmpb $53, 2(%rax)
jne iterator_extract_floating_point_register_fa5
xorb %al, %al
movb $15, %bl
ret
iterator_extract_floating_point_register_fa5:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f16
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f16
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f16
cmpb $53, 2(%rax)
jne iterator_extract_floating_point_register_f16
xorb %al, %al
movb $15, %bl
ret
iterator_extract_floating_point_register_f16:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa6
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa6
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa6
cmpb $54, 2(%rax)
jne iterator_extract_floating_point_register_fa6
xorb %al, %al
movb $16, %bl
ret
iterator_extract_floating_point_register_fa6:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f17
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f17
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f17
cmpb $54, 2(%rax)
jne iterator_extract_floating_point_register_f17
xorb %al, %al
movb $16, %bl
ret
iterator_extract_floating_point_register_f17:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fa7
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fa7
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fa7
cmpb $55, 2(%rax)
jne iterator_extract_floating_point_register_fa7
xorb %al, %al
movb $17, %bl
ret
iterator_extract_floating_point_register_fa7:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f18
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f18
cmpb $97, 1(%rax)
jne iterator_extract_floating_point_register_f18
cmpb $55, 2(%rax)
jne iterator_extract_floating_point_register_f18
xorb %al, %al
movb $17, %bl
ret
iterator_extract_floating_point_register_f18:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs2
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs2
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fs2
cmpb $56, 2(%rax)
jne iterator_extract_floating_point_register_fs2
xorb %al, %al
movb $18, %bl
ret
iterator_extract_floating_point_register_fs2:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f19
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f19
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f19
cmpb $50, 2(%rax)
jne iterator_extract_floating_point_register_f19
xorb %al, %al
movb $18, %bl
ret
iterator_extract_floating_point_register_f19:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs3
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs3
cmpb $49, 1(%rax)
jne iterator_extract_floating_point_register_fs3
cmpb $57, 2(%rax)
jne iterator_extract_floating_point_register_fs3
xorb %al, %al
movb $19, %bl
ret
iterator_extract_floating_point_register_fs3:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f20
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f20
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f20
cmpb $51, 2(%rax)
jne iterator_extract_floating_point_register_f20
xorb %al, %al
movb $19, %bl
ret
iterator_extract_floating_point_register_f20:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs4
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs4
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs4
cmpb $48, 2(%rax)
jne iterator_extract_floating_point_register_fs4
xorb %al, %al
movb $20, %bl
ret
iterator_extract_floating_point_register_fs4:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f21
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f21
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f21
cmpb $52, 2(%rax)
jne iterator_extract_floating_point_register_f21
xorb %al, %al
movb $20, %bl
ret
iterator_extract_floating_point_register_f21:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs5
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs5
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs5
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_fs5
xorb %al, %al
movb $21, %bl
ret
iterator_extract_floating_point_register_fs5:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f22
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f22
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f22
cmpb $53, 2(%rax)
jne iterator_extract_floating_point_register_f22
xorb %al, %al
movb $21, %bl
ret
iterator_extract_floating_point_register_f22:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs6
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs6
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs6
cmpb $50, 2(%rax)
jne iterator_extract_floating_point_register_fs6
xorb %al, %al
movb $22, %bl
ret
iterator_extract_floating_point_register_fs6:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f23
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f23
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f23
cmpb $54, 2(%rax)
jne iterator_extract_floating_point_register_f23
xorb %al, %al
movb $22, %bl
ret
iterator_extract_floating_point_register_f23:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs7
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs7
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs7
cmpb $51, 2(%rax)
jne iterator_extract_floating_point_register_fs7
xorb %al, %al
movb $23, %bl
ret
iterator_extract_floating_point_register_fs7:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f24
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f24
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f24
cmpb $55, 2(%rax)
jne iterator_extract_floating_point_register_f24
xorb %al, %al
movb $23, %bl
ret
iterator_extract_floating_point_register_f24:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs8
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs8
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs8
cmpb $52, 2(%rax)
jne iterator_extract_floating_point_register_fs8
xorb %al, %al
movb $24, %bl
ret
iterator_extract_floating_point_register_fs8:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f25
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f25
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f25
cmpb $56, 2(%rax)
jne iterator_extract_floating_point_register_f25
xorb %al, %al
movb $24, %bl
ret
iterator_extract_floating_point_register_f25:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs9
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs9
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs9
cmpb $53, 2(%rax)
jne iterator_extract_floating_point_register_fs9
xorb %al, %al
movb $25, %bl
ret
iterator_extract_floating_point_register_fs9:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f26
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f26
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f26
cmpb $57, 2(%rax)
jne iterator_extract_floating_point_register_f26
xorb %al, %al
movb $25, %bl
ret
iterator_extract_floating_point_register_f26:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs10
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs10
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs10
cmpb $54, 2(%rax)
jne iterator_extract_floating_point_register_fs10
xorb %al, %al
movb $26, %bl
ret
iterator_extract_floating_point_register_fs10:
cmpq $4, %rbx
jne iterator_extract_floating_point_register_f27
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f27
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f27
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_f27
cmpb $48, 3(%rax)
jne iterator_extract_floating_point_register_f27
xorb %al, %al
movb $26, %bl
ret
iterator_extract_floating_point_register_f27:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_fs11
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_fs11
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_fs11
cmpb $55, 2(%rax)
jne iterator_extract_floating_point_register_fs11
xorb %al, %al
movb $27, %bl
ret
iterator_extract_floating_point_register_fs11:
cmpq $4, %rbx
jne iterator_extract_floating_point_register_f28
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f28
cmpb $115, 1(%rax)
jne iterator_extract_floating_point_register_f28
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_f28
cmpb $49, 3(%rax)
jne iterator_extract_floating_point_register_f28
xorb %al, %al
movb $27, %bl
ret
iterator_extract_floating_point_register_f28:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_ft8
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft8
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_ft8
cmpb $56, 2(%rax)
jne iterator_extract_floating_point_register_ft8
xorb %al, %al
movb $28, %bl
ret
iterator_extract_floating_point_register_ft8:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f29
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f29
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f29
cmpb $56, 2(%rax)
jne iterator_extract_floating_point_register_f29
xorb %al, %al
movb $28, %bl
ret
iterator_extract_floating_point_register_f29:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_ft9
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft9
cmpb $50, 1(%rax)
jne iterator_extract_floating_point_register_ft9
cmpb $57, 2(%rax)
jne iterator_extract_floating_point_register_ft9
xorb %al, %al
movb $29, %bl
ret
iterator_extract_floating_point_register_ft9:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_f30
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f30
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f30
cmpb $57, 2(%rax)
jne iterator_extract_floating_point_register_f30
xorb %al, %al
movb $29, %bl
ret
iterator_extract_floating_point_register_f30:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_ft10
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft10
cmpb $51, 1(%rax)
jne iterator_extract_floating_point_register_ft10
cmpb $48, 2(%rax)
jne iterator_extract_floating_point_register_ft10
xorb %al, %al
movb $30, %bl
ret
iterator_extract_floating_point_register_ft10:
cmpq $4, %rbx
jne iterator_extract_floating_point_register_f31
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_f31
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_f31
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_f31
cmpb $48, 3(%rax)
jne iterator_extract_floating_point_register_f31
xorb %al, %al
movb $30, %bl
ret
iterator_extract_floating_point_register_f31:
cmpq $3, %rbx
jne iterator_extract_floating_point_register_ft11
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_ft11
cmpb $51, 1(%rax)
jne iterator_extract_floating_point_register_ft11
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_ft11
xorb %al, %al
movb $31, %bl
ret
iterator_extract_floating_point_register_ft11:
cmpq $4, %rbx
jne iterator_extract_floating_point_register_unknown
cmpb $102, (%rax)
jne iterator_extract_floating_point_register_unknown
cmpb $116, 1(%rax)
jne iterator_extract_floating_point_register_unknown
cmpb $49, 2(%rax)
jne iterator_extract_floating_point_register_unknown
cmpb $49, 3(%rax)
jne iterator_extract_floating_point_register_unknown
xorb %al, %al
movb $31, %bl
ret
iterator_extract_floating_point_register_unknown:
movb $1, %al
ret


# out
# al status
# bx control and status register
iterator_extract_control_and_status_register:
movq iterator_current_character, %rax
movq iterator_token_size, %rbx
# ustatus
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_fflags
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_fflags
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_fflags
cmpb $116, 2(%rax)
jne iterator_extract_control_and_status_register_fflags
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_fflags
cmpb $116, 4(%rax)
jne iterator_extract_control_and_status_register_fflags
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_fflags
cmpb $115, 6(%rax)
jne iterator_extract_control_and_status_register_fflags
xorb %al, %al
xorw %bx, %bx
ret
iterator_extract_control_and_status_register_fflags:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_frm
cmpb $102, (%rax)
jne iterator_extract_control_and_status_register_frm
cmpb $102, 1(%rax)
jne iterator_extract_control_and_status_register_frm
cmpb $108, 2(%rax)
jne iterator_extract_control_and_status_register_frm
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_frm
cmpb $103, 4(%rax)
jne iterator_extract_control_and_status_register_frm
cmpb $115, 5(%rax)
jne iterator_extract_control_and_status_register_frm
xorb %al, %al
movw $1, %bx
ret
iterator_extract_control_and_status_register_frm:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_fcsr
cmpb $102, (%rax)
jne iterator_extract_control_and_status_register_fcsr
cmpb $114, 1(%rax)
jne iterator_extract_control_and_status_register_fcsr
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_fcsr
xorb %al, %al
movw $2, %bx
ret
iterator_extract_control_and_status_register_fcsr:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_uie
cmpb $102, (%rax)
jne iterator_extract_control_and_status_register_uie
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_uie
cmpb $115, 2(%rax)
jne iterator_extract_control_and_status_register_uie
cmpb $114, 3(%rax)
jne iterator_extract_control_and_status_register_uie
xorb %al, %al
movw $3, %bx
ret
iterator_extract_control_and_status_register_uie:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_utvec
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_utvec
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_utvec
cmpb $101, 2(%rax)
jne iterator_extract_control_and_status_register_utvec
xorb %al, %al
movw $4, %bx
ret
iterator_extract_control_and_status_register_utvec:
cmpq $5, %rbx
jne iterator_extract_control_and_status_register_uscratch
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_uscratch
cmpb $116, 1(%rax)
jne iterator_extract_control_and_status_register_uscratch
cmpb $118, 2(%rax)
jne iterator_extract_control_and_status_register_uscratch
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_uscratch
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_uscratch
xorb %al, %al
movw $5, %bx
ret
iterator_extract_control_and_status_register_uscratch:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_uepc
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_uepc
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_uepc
cmpb $99, 2(%rax)
jne iterator_extract_control_and_status_register_uepc
cmpb $114, 3(%rax)
jne iterator_extract_control_and_status_register_uepc
cmpb $97, 4(%rax)
jne iterator_extract_control_and_status_register_uepc
cmpb $116, 5(%rax)
jne iterator_extract_control_and_status_register_uepc
cmpb $99, 6(%rax)
jne iterator_extract_control_and_status_register_uepc
cmpb $104, 7(%rax)
jne iterator_extract_control_and_status_register_uepc
xorb %al, %al
movw $64, %bx
ret
iterator_extract_control_and_status_register_uepc:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_ucause
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_ucause
cmpb $101, 1(%rax)
jne iterator_extract_control_and_status_register_ucause
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_ucause
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_ucause
xorb %al, %al
movw $65, %bx
ret
iterator_extract_control_and_status_register_ucause:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_utval
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_utval
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_utval
cmpb $97, 2(%rax)
jne iterator_extract_control_and_status_register_utval
cmpb $117, 3(%rax)
jne iterator_extract_control_and_status_register_utval
cmpb $115, 4(%rax)
jne iterator_extract_control_and_status_register_utval
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_utval
xorb %al, %al
movw $66, %bx
ret
iterator_extract_control_and_status_register_utval:
cmpq $5, %rbx
jne iterator_extract_control_and_status_register_uip
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_uip
cmpb $116, 1(%rax)
jne iterator_extract_control_and_status_register_uip
cmpb $118, 2(%rax)
jne iterator_extract_control_and_status_register_uip
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_uip
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_uip
xorb %al, %al
movw $67, %bx
ret
iterator_extract_control_and_status_register_uip:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_sstatus
cmpb $117, (%rax)
jne iterator_extract_control_and_status_register_sstatus
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_sstatus
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_sstatus
xorb %al, %al
movw $68, %bx
ret
iterator_extract_control_and_status_register_sstatus:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_sedeleg
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_sedeleg
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_sedeleg
cmpb $116, 2(%rax)
jne iterator_extract_control_and_status_register_sedeleg
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_sedeleg
cmpb $116, 4(%rax)
jne iterator_extract_control_and_status_register_sedeleg
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_sedeleg
cmpb $115, 6(%rax)
jne iterator_extract_control_and_status_register_sedeleg
xorb %al, %al
movw $256, %bx
ret
iterator_extract_control_and_status_register_sedeleg:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_sideleg
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_sideleg
cmpb $101, 1(%rax)
jne iterator_extract_control_and_status_register_sideleg
cmpb $100, 2(%rax)
jne iterator_extract_control_and_status_register_sideleg
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_sideleg
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_sideleg
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_sideleg
cmpb $103, 6(%rax)
jne iterator_extract_control_and_status_register_sideleg
xorb %al, %al
movw $258, %bx
ret
iterator_extract_control_and_status_register_sideleg:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_sie
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_sie
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_sie
cmpb $100, 2(%rax)
jne iterator_extract_control_and_status_register_sie
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_sie
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_sie
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_sie
cmpb $103, 6(%rax)
jne iterator_extract_control_and_status_register_sie
xorb %al, %al
movw $259, %bx
ret
iterator_extract_control_and_status_register_sie:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_stvec
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_stvec
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_stvec
cmpb $101, 2(%rax)
jne iterator_extract_control_and_status_register_stvec
xorb %al, %al
movw $260, %bx
ret
iterator_extract_control_and_status_register_stvec:
cmpq $5, %rbx
jne iterator_extract_control_and_status_register_scounteren
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_scounteren
cmpb $116, 1(%rax)
jne iterator_extract_control_and_status_register_scounteren
cmpb $118, 2(%rax)
jne iterator_extract_control_and_status_register_scounteren
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_scounteren
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_scounteren
xorb %al, %al
movw $261, %bx
ret
iterator_extract_control_and_status_register_scounteren:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_sscratch
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $111, 2(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $117, 3(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $110, 4(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $116, 5(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $114, 7(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_sscratch
cmpb $110, 9(%rax)
jne iterator_extract_control_and_status_register_sscratch
xorb %al, %al
movw $262, %bx
ret
iterator_extract_control_and_status_register_sscratch:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_sepc
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_sepc
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_sepc
cmpb $99, 2(%rax)
jne iterator_extract_control_and_status_register_sepc
cmpb $114, 3(%rax)
jne iterator_extract_control_and_status_register_sepc
cmpb $97, 4(%rax)
jne iterator_extract_control_and_status_register_sepc
cmpb $116, 5(%rax)
jne iterator_extract_control_and_status_register_sepc
cmpb $99, 6(%rax)
jne iterator_extract_control_and_status_register_sepc
cmpb $104, 7(%rax)
jne iterator_extract_control_and_status_register_sepc
xorb %al, %al
movw $320, %bx
ret
iterator_extract_control_and_status_register_sepc:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_scause
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_scause
cmpb $101, 1(%rax)
jne iterator_extract_control_and_status_register_scause
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_scause
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_scause
xorb %al, %al
movw $321, %bx
ret
iterator_extract_control_and_status_register_scause:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_stval
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_stval
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_stval
cmpb $97, 2(%rax)
jne iterator_extract_control_and_status_register_stval
cmpb $117, 3(%rax)
jne iterator_extract_control_and_status_register_stval
cmpb $115, 4(%rax)
jne iterator_extract_control_and_status_register_stval
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_stval
xorb %al, %al
movw $322, %bx
ret
iterator_extract_control_and_status_register_stval:
cmpq $5, %rbx
jne iterator_extract_control_and_status_register_sip
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_sip
cmpb $116, 1(%rax)
jne iterator_extract_control_and_status_register_sip
cmpb $118, 2(%rax)
jne iterator_extract_control_and_status_register_sip
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_sip
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_sip
xorb %al, %al
movw $323, %bx
ret
iterator_extract_control_and_status_register_sip:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_satp
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_satp
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_satp
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_satp
xorb %al, %al
movw $324, %bx
ret
iterator_extract_control_and_status_register_satp:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_mstatus
cmpb $115, (%rax)
jne iterator_extract_control_and_status_register_mstatus
cmpb $97, 1(%rax)
jne iterator_extract_control_and_status_register_mstatus
cmpb $116, 2(%rax)
jne iterator_extract_control_and_status_register_mstatus
cmpb $112, 3(%rax)
jne iterator_extract_control_and_status_register_mstatus
xorb %al, %al
movw $384, %bx
ret
iterator_extract_control_and_status_register_mstatus:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_misa
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_misa
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_misa
cmpb $116, 2(%rax)
jne iterator_extract_control_and_status_register_misa
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_misa
cmpb $116, 4(%rax)
jne iterator_extract_control_and_status_register_misa
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_misa
cmpb $115, 6(%rax)
jne iterator_extract_control_and_status_register_misa
xorb %al, %al
movw $768, %bx
ret
iterator_extract_control_and_status_register_misa:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_medeleg
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_medeleg
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_medeleg
cmpb $115, 2(%rax)
jne iterator_extract_control_and_status_register_medeleg
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_medeleg
xorb %al, %al
movw $769, %bx
ret
iterator_extract_control_and_status_register_medeleg:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_mideleg
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mideleg
cmpb $101, 1(%rax)
jne iterator_extract_control_and_status_register_mideleg
cmpb $100, 2(%rax)
jne iterator_extract_control_and_status_register_mideleg
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_mideleg
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_mideleg
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_mideleg
cmpb $103, 6(%rax)
jne iterator_extract_control_and_status_register_mideleg
xorb %al, %al
movw $770, %bx
ret
iterator_extract_control_and_status_register_mideleg:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_mie
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mie
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_mie
cmpb $100, 2(%rax)
jne iterator_extract_control_and_status_register_mie
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_mie
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_mie
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_mie
cmpb $103, 6(%rax)
jne iterator_extract_control_and_status_register_mie
xorb %al, %al
movw $771, %bx
ret
iterator_extract_control_and_status_register_mie:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_mtvec
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mtvec
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_mtvec
cmpb $101, 2(%rax)
jne iterator_extract_control_and_status_register_mtvec
xorb %al, %al
movw $772, %bx
ret
iterator_extract_control_and_status_register_mtvec:
cmpq $5, %rbx
jne iterator_extract_control_and_status_register_mcounteren
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mcounteren
cmpb $116, 1(%rax)
jne iterator_extract_control_and_status_register_mcounteren
cmpb $118, 2(%rax)
jne iterator_extract_control_and_status_register_mcounteren
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_mcounteren
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mcounteren
xorb %al, %al
movw $773, %bx
ret
iterator_extract_control_and_status_register_mcounteren:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $111, 2(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $117, 3(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $110, 4(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $116, 5(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $114, 7(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
cmpb $110, 9(%rax)
jne iterator_extract_control_and_status_register_mcountinhibit
xorb %al, %al
movw $774, %bx
ret
iterator_extract_control_and_status_register_mcountinhibit:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $111, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $117, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $110, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $116, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $105, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $104, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $105, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $98, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $105, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
cmpb $116, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmevent3
xorb %al, %al
movw $800, %bx
ret
iterator_extract_control_and_status_register_mhpmevent3:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
cmpb $51, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent4
xorb %al, %al
movw $803, %bx
ret
iterator_extract_control_and_status_register_mhpmevent4:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
cmpb $52, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent5
xorb %al, %al
movw $804, %bx
ret
iterator_extract_control_and_status_register_mhpmevent5:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
cmpb $53, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent6
xorb %al, %al
movw $805, %bx
ret
iterator_extract_control_and_status_register_mhpmevent6:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
cmpb $54, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent7
xorb %al, %al
movw $806, %bx
ret
iterator_extract_control_and_status_register_mhpmevent7:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
cmpb $55, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent8
xorb %al, %al
movw $807, %bx
ret
iterator_extract_control_and_status_register_mhpmevent8:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
cmpb $56, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent9
xorb %al, %al
movw $808, %bx
ret
iterator_extract_control_and_status_register_mhpmevent9:
cmpq $10, %rbx
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
cmpb $57, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent10
xorb %al, %al
movw $809, %bx
ret
iterator_extract_control_and_status_register_mhpmevent10:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
cmpb $48, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent11
xorb %al, %al
movw $810, %bx
ret
iterator_extract_control_and_status_register_mhpmevent11:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent12
xorb %al, %al
movw $811, %bx
ret
iterator_extract_control_and_status_register_mhpmevent12:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent13
xorb %al, %al
movw $812, %bx
ret
iterator_extract_control_and_status_register_mhpmevent13:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
cmpb $51, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent14
xorb %al, %al
movw $813, %bx
ret
iterator_extract_control_and_status_register_mhpmevent14:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
cmpb $52, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent15
xorb %al, %al
movw $814, %bx
ret
iterator_extract_control_and_status_register_mhpmevent15:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
cmpb $53, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent16
xorb %al, %al
movw $815, %bx
ret
iterator_extract_control_and_status_register_mhpmevent16:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
cmpb $54, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent17
xorb %al, %al
movw $816, %bx
ret
iterator_extract_control_and_status_register_mhpmevent17:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
cmpb $55, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent18
xorb %al, %al
movw $817, %bx
ret
iterator_extract_control_and_status_register_mhpmevent18:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
cmpb $56, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent19
xorb %al, %al
movw $818, %bx
ret
iterator_extract_control_and_status_register_mhpmevent19:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $49, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
cmpb $57, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent20
xorb %al, %al
movw $819, %bx
ret
iterator_extract_control_and_status_register_mhpmevent20:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
cmpb $48, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent21
xorb %al, %al
movw $820, %bx
ret
iterator_extract_control_and_status_register_mhpmevent21:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent22
xorb %al, %al
movw $821, %bx
ret
iterator_extract_control_and_status_register_mhpmevent22:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent23
xorb %al, %al
movw $822, %bx
ret
iterator_extract_control_and_status_register_mhpmevent23:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
cmpb $51, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent24
xorb %al, %al
movw $823, %bx
ret
iterator_extract_control_and_status_register_mhpmevent24:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
cmpb $52, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent25
xorb %al, %al
movw $824, %bx
ret
iterator_extract_control_and_status_register_mhpmevent25:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
cmpb $53, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent26
xorb %al, %al
movw $825, %bx
ret
iterator_extract_control_and_status_register_mhpmevent26:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
cmpb $54, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent27
xorb %al, %al
movw $826, %bx
ret
iterator_extract_control_and_status_register_mhpmevent27:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
cmpb $55, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent28
xorb %al, %al
movw $827, %bx
ret
iterator_extract_control_and_status_register_mhpmevent28:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
cmpb $56, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent29
xorb %al, %al
movw $828, %bx
ret
iterator_extract_control_and_status_register_mhpmevent29:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $50, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
cmpb $57, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent30
xorb %al, %al
movw $829, %bx
ret
iterator_extract_control_and_status_register_mhpmevent30:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $51, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
cmpb $48, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmevent31
xorb %al, %al
movw $830, %bx
ret
iterator_extract_control_and_status_register_mhpmevent31:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_mscratch
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $118, 5(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $51, 9(%rax)
jne iterator_extract_control_and_status_register_mscratch
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_mscratch
xorb %al, %al
movw $831, %bx
ret
iterator_extract_control_and_status_register_mscratch:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_mepc
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mepc
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_mepc
cmpb $99, 2(%rax)
jne iterator_extract_control_and_status_register_mepc
cmpb $114, 3(%rax)
jne iterator_extract_control_and_status_register_mepc
cmpb $97, 4(%rax)
jne iterator_extract_control_and_status_register_mepc
cmpb $116, 5(%rax)
jne iterator_extract_control_and_status_register_mepc
cmpb $99, 6(%rax)
jne iterator_extract_control_and_status_register_mepc
cmpb $104, 7(%rax)
jne iterator_extract_control_and_status_register_mepc
xorb %al, %al
movw $832, %bx
ret
iterator_extract_control_and_status_register_mepc:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_mcause
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mcause
cmpb $101, 1(%rax)
jne iterator_extract_control_and_status_register_mcause
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mcause
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_mcause
xorb %al, %al
movw $833, %bx
ret
iterator_extract_control_and_status_register_mcause:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_mtval
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mtval
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_mtval
cmpb $97, 2(%rax)
jne iterator_extract_control_and_status_register_mtval
cmpb $117, 3(%rax)
jne iterator_extract_control_and_status_register_mtval
cmpb $115, 4(%rax)
jne iterator_extract_control_and_status_register_mtval
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_mtval
xorb %al, %al
movw $834, %bx
ret
iterator_extract_control_and_status_register_mtval:
cmpq $5, %rbx
jne iterator_extract_control_and_status_register_mip
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mip
cmpb $116, 1(%rax)
jne iterator_extract_control_and_status_register_mip
cmpb $118, 2(%rax)
jne iterator_extract_control_and_status_register_mip
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_mip
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_mip
xorb %al, %al
movw $835, %bx
ret
iterator_extract_control_and_status_register_mip:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_pmpcfg0
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_pmpcfg0
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_pmpcfg0
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpcfg0
xorb %al, %al
movw $836, %bx
ret
iterator_extract_control_and_status_register_pmpcfg0:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_pmpcfg1
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpcfg1
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpcfg1
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpcfg1
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_pmpcfg1
cmpb $102, 4(%rax)
jne iterator_extract_control_and_status_register_pmpcfg1
cmpb $103, 5(%rax)
jne iterator_extract_control_and_status_register_pmpcfg1
cmpb $48, 6(%rax)
jne iterator_extract_control_and_status_register_pmpcfg1
xorb %al, %al
movw $928, %bx
ret
iterator_extract_control_and_status_register_pmpcfg1:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_pmpcfg2
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpcfg2
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpcfg2
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpcfg2
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_pmpcfg2
cmpb $102, 4(%rax)
jne iterator_extract_control_and_status_register_pmpcfg2
cmpb $103, 5(%rax)
jne iterator_extract_control_and_status_register_pmpcfg2
cmpb $49, 6(%rax)
jne iterator_extract_control_and_status_register_pmpcfg2
xorb %al, %al
movw $929, %bx
ret
iterator_extract_control_and_status_register_pmpcfg2:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_pmpcfg3
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpcfg3
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpcfg3
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpcfg3
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_pmpcfg3
cmpb $102, 4(%rax)
jne iterator_extract_control_and_status_register_pmpcfg3
cmpb $103, 5(%rax)
jne iterator_extract_control_and_status_register_pmpcfg3
cmpb $50, 6(%rax)
jne iterator_extract_control_and_status_register_pmpcfg3
xorb %al, %al
movw $930, %bx
ret
iterator_extract_control_and_status_register_pmpcfg3:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_pmpaddr0
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr0
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr0
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr0
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr0
cmpb $102, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr0
cmpb $103, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr0
cmpb $51, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr0
xorb %al, %al
movw $931, %bx
ret
iterator_extract_control_and_status_register_pmpaddr0:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
cmpb $48, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr1
xorb %al, %al
movw $944, %bx
ret
iterator_extract_control_and_status_register_pmpaddr1:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
cmpb $49, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr2
xorb %al, %al
movw $945, %bx
ret
iterator_extract_control_and_status_register_pmpaddr2:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
cmpb $50, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr3
xorb %al, %al
movw $946, %bx
ret
iterator_extract_control_and_status_register_pmpaddr3:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
cmpb $51, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr4
xorb %al, %al
movw $947, %bx
ret
iterator_extract_control_and_status_register_pmpaddr4:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
cmpb $52, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr5
xorb %al, %al
movw $948, %bx
ret
iterator_extract_control_and_status_register_pmpaddr5:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
cmpb $53, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr6
xorb %al, %al
movw $949, %bx
ret
iterator_extract_control_and_status_register_pmpaddr6:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
cmpb $54, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr7
xorb %al, %al
movw $950, %bx
ret
iterator_extract_control_and_status_register_pmpaddr7:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
cmpb $55, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr8
xorb %al, %al
movw $951, %bx
ret
iterator_extract_control_and_status_register_pmpaddr8:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
cmpb $56, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr9
xorb %al, %al
movw $952, %bx
ret
iterator_extract_control_and_status_register_pmpaddr9:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
cmpb $57, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr10
xorb %al, %al
movw $953, %bx
ret
iterator_extract_control_and_status_register_pmpaddr10:
cmpq $9, %rbx
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $49, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
cmpb $48, 8(%rax)
jne iterator_extract_control_and_status_register_pmpaddr11
xorb %al, %al
movw $954, %bx
ret
iterator_extract_control_and_status_register_pmpaddr11:
cmpq $9, %rbx
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $49, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
cmpb $49, 8(%rax)
jne iterator_extract_control_and_status_register_pmpaddr12
xorb %al, %al
movw $955, %bx
ret
iterator_extract_control_and_status_register_pmpaddr12:
cmpq $9, %rbx
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $49, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
cmpb $50, 8(%rax)
jne iterator_extract_control_and_status_register_pmpaddr13
xorb %al, %al
movw $956, %bx
ret
iterator_extract_control_and_status_register_pmpaddr13:
cmpq $9, %rbx
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $49, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
cmpb $51, 8(%rax)
jne iterator_extract_control_and_status_register_pmpaddr14
xorb %al, %al
movw $957, %bx
ret
iterator_extract_control_and_status_register_pmpaddr14:
cmpq $9, %rbx
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $49, 7(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
cmpb $52, 8(%rax)
jne iterator_extract_control_and_status_register_pmpaddr15
xorb %al, %al
movw $958, %bx
ret
iterator_extract_control_and_status_register_pmpaddr15:
cmpq $9, %rbx
jne iterator_extract_control_and_status_register_tselect
cmpb $112, (%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $109, 1(%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $97, 3(%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $49, 7(%rax)
jne iterator_extract_control_and_status_register_tselect
cmpb $53, 8(%rax)
jne iterator_extract_control_and_status_register_tselect
xorb %al, %al
movw $959, %bx
ret
iterator_extract_control_and_status_register_tselect:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_tdata1
cmpb $116, (%rax)
jne iterator_extract_control_and_status_register_tdata1
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_tdata1
cmpb $101, 2(%rax)
jne iterator_extract_control_and_status_register_tdata1
cmpb $108, 3(%rax)
jne iterator_extract_control_and_status_register_tdata1
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_tdata1
cmpb $99, 5(%rax)
jne iterator_extract_control_and_status_register_tdata1
cmpb $116, 6(%rax)
jne iterator_extract_control_and_status_register_tdata1
xorb %al, %al
movw $1952, %bx
ret
iterator_extract_control_and_status_register_tdata1:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_tdata2
cmpb $116, (%rax)
jne iterator_extract_control_and_status_register_tdata2
cmpb $100, 1(%rax)
jne iterator_extract_control_and_status_register_tdata2
cmpb $97, 2(%rax)
jne iterator_extract_control_and_status_register_tdata2
cmpb $116, 3(%rax)
jne iterator_extract_control_and_status_register_tdata2
cmpb $97, 4(%rax)
jne iterator_extract_control_and_status_register_tdata2
cmpb $49, 5(%rax)
jne iterator_extract_control_and_status_register_tdata2
xorb %al, %al
movw $1953, %bx
ret
iterator_extract_control_and_status_register_tdata2:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_tdata3
cmpb $116, (%rax)
jne iterator_extract_control_and_status_register_tdata3
cmpb $100, 1(%rax)
jne iterator_extract_control_and_status_register_tdata3
cmpb $97, 2(%rax)
jne iterator_extract_control_and_status_register_tdata3
cmpb $116, 3(%rax)
jne iterator_extract_control_and_status_register_tdata3
cmpb $97, 4(%rax)
jne iterator_extract_control_and_status_register_tdata3
cmpb $50, 5(%rax)
jne iterator_extract_control_and_status_register_tdata3
xorb %al, %al
movw $1954, %bx
ret
iterator_extract_control_and_status_register_tdata3:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_dcsr
cmpb $116, (%rax)
jne iterator_extract_control_and_status_register_dcsr
cmpb $100, 1(%rax)
jne iterator_extract_control_and_status_register_dcsr
cmpb $97, 2(%rax)
jne iterator_extract_control_and_status_register_dcsr
cmpb $116, 3(%rax)
jne iterator_extract_control_and_status_register_dcsr
cmpb $97, 4(%rax)
jne iterator_extract_control_and_status_register_dcsr
cmpb $51, 5(%rax)
jne iterator_extract_control_and_status_register_dcsr
xorb %al, %al
movw $1955, %bx
ret
iterator_extract_control_and_status_register_dcsr:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_dpc
cmpb $100, (%rax)
jne iterator_extract_control_and_status_register_dpc
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_dpc
cmpb $115, 2(%rax)
jne iterator_extract_control_and_status_register_dpc
cmpb $114, 3(%rax)
jne iterator_extract_control_and_status_register_dpc
xorb %al, %al
movw $1968, %bx
ret
iterator_extract_control_and_status_register_dpc:
cmpq $3, %rbx
jne iterator_extract_control_and_status_register_dscratch
cmpb $100, (%rax)
jne iterator_extract_control_and_status_register_dscratch
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_dscratch
cmpb $99, 2(%rax)
jne iterator_extract_control_and_status_register_dscratch
xorb %al, %al
movw $1969, %bx
ret
iterator_extract_control_and_status_register_dscratch:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_mcycle
cmpb $100, (%rax)
jne iterator_extract_control_and_status_register_mcycle
cmpb $115, 1(%rax)
jne iterator_extract_control_and_status_register_mcycle
cmpb $99, 2(%rax)
jne iterator_extract_control_and_status_register_mcycle
cmpb $114, 3(%rax)
jne iterator_extract_control_and_status_register_mcycle
cmpb $97, 4(%rax)
jne iterator_extract_control_and_status_register_mcycle
cmpb $116, 5(%rax)
jne iterator_extract_control_and_status_register_mcycle
cmpb $99, 6(%rax)
jne iterator_extract_control_and_status_register_mcycle
cmpb $104, 7(%rax)
jne iterator_extract_control_and_status_register_mcycle
xorb %al, %al
movw $1970, %bx
ret
iterator_extract_control_and_status_register_mcycle:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_minstret
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_minstret
cmpb $99, 1(%rax)
jne iterator_extract_control_and_status_register_minstret
cmpb $121, 2(%rax)
jne iterator_extract_control_and_status_register_minstret
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_minstret
cmpb $108, 4(%rax)
jne iterator_extract_control_and_status_register_minstret
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_minstret
xorb %al, %al
movw $2816, %bx
ret
iterator_extract_control_and_status_register_minstret:
cmpq $8, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $110, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $115, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $116, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $114, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $101, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter3
xorb %al, %al
movw $2818, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter3:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
cmpb $51, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter4
xorb %al, %al
movw $2819, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter4:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
cmpb $52, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter5
xorb %al, %al
movw $2820, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter5:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
cmpb $53, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter6
xorb %al, %al
movw $2821, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter6:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
cmpb $54, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter7
xorb %al, %al
movw $2822, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter7:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
cmpb $55, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter8
xorb %al, %al
movw $2823, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter8:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
cmpb $56, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter9
xorb %al, %al
movw $2824, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter9:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
cmpb $57, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter10
xorb %al, %al
movw $2825, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter10:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
cmpb $48, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter11
xorb %al, %al
movw $2826, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter11:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
cmpb $49, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter12
xorb %al, %al
movw $2827, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter12:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
cmpb $50, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter13
xorb %al, %al
movw $2828, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter13:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
cmpb $51, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter14
xorb %al, %al
movw $2829, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter14:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
cmpb $52, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter15
xorb %al, %al
movw $2830, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter15:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
cmpb $53, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter16
xorb %al, %al
movw $2831, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter16:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
cmpb $54, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter17
xorb %al, %al
movw $2832, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter17:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
cmpb $55, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter18
xorb %al, %al
movw $2833, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter18:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
cmpb $56, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter19
xorb %al, %al
movw $2834, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter19:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
cmpb $57, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter20
xorb %al, %al
movw $2835, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter20:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
cmpb $48, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter21
xorb %al, %al
movw $2836, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter21:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
cmpb $49, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter22
xorb %al, %al
movw $2837, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter22:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
cmpb $50, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter23
xorb %al, %al
movw $2838, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter23:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
cmpb $51, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter24
xorb %al, %al
movw $2839, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter24:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
cmpb $52, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter25
xorb %al, %al
movw $2840, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter25:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
cmpb $53, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter26
xorb %al, %al
movw $2841, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter26:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
cmpb $54, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter27
xorb %al, %al
movw $2842, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter27:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
cmpb $55, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter28
xorb %al, %al
movw $2843, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter28:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
cmpb $56, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter29
xorb %al, %al
movw $2844, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter29:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
cmpb $57, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter30
xorb %al, %al
movw $2845, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter30:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $51, 11(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
cmpb $48, 12(%rax)
jne iterator_extract_control_and_status_register_mhpmcounter31
xorb %al, %al
movw $2846, %bx
ret
iterator_extract_control_and_status_register_mhpmcounter31:
cmpq $13, %rbx
jne iterator_extract_control_and_status_register_cycle
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $112, 2(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $109, 3(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $99, 4(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $117, 6(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $110, 7(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $116, 8(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $101, 9(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $114, 10(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $51, 11(%rax)
jne iterator_extract_control_and_status_register_cycle
cmpb $49, 12(%rax)
jne iterator_extract_control_and_status_register_cycle
xorb %al, %al
movw $2847, %bx
ret
iterator_extract_control_and_status_register_cycle:
cmpq $5, %rbx
jne iterator_extract_control_and_status_register_time
cmpb $99, (%rax)
jne iterator_extract_control_and_status_register_time
cmpb $121, 1(%rax)
jne iterator_extract_control_and_status_register_time
cmpb $99, 2(%rax)
jne iterator_extract_control_and_status_register_time
cmpb $108, 3(%rax)
jne iterator_extract_control_and_status_register_time
cmpb $101, 4(%rax)
jne iterator_extract_control_and_status_register_time
xorb %al, %al
movw $3072, %bx
ret
iterator_extract_control_and_status_register_time:
cmpq $4, %rbx
jne iterator_extract_control_and_status_register_instret
cmpb $116, (%rax)
jne iterator_extract_control_and_status_register_instret
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_instret
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_instret
cmpb $101, 3(%rax)
jne iterator_extract_control_and_status_register_instret
xorb %al, %al
movw $3073, %bx
ret
iterator_extract_control_and_status_register_instret:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_hpmcounter3
cmpb $105, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter3
cmpb $110, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter3
cmpb $115, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter3
cmpb $116, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter3
cmpb $114, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter3
cmpb $101, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter3
cmpb $116, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter3
xorb %al, %al
movw $3074, %bx
ret
iterator_extract_control_and_status_register_hpmcounter3:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
cmpb $51, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter4
xorb %al, %al
movw $3075, %bx
ret
iterator_extract_control_and_status_register_hpmcounter4:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
cmpb $52, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter5
xorb %al, %al
movw $3076, %bx
ret
iterator_extract_control_and_status_register_hpmcounter5:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
cmpb $53, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter6
xorb %al, %al
movw $3077, %bx
ret
iterator_extract_control_and_status_register_hpmcounter6:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
cmpb $54, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter7
xorb %al, %al
movw $3078, %bx
ret
iterator_extract_control_and_status_register_hpmcounter7:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
cmpb $55, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter8
xorb %al, %al
movw $3079, %bx
ret
iterator_extract_control_and_status_register_hpmcounter8:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
cmpb $56, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter9
xorb %al, %al
movw $3080, %bx
ret
iterator_extract_control_and_status_register_hpmcounter9:
cmpq $11, %rbx
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
cmpb $57, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter10
xorb %al, %al
movw $3081, %bx
ret
iterator_extract_control_and_status_register_hpmcounter10:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
cmpb $48, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter11
xorb %al, %al
movw $3082, %bx
ret
iterator_extract_control_and_status_register_hpmcounter11:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter12
xorb %al, %al
movw $3083, %bx
ret
iterator_extract_control_and_status_register_hpmcounter12:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter13
xorb %al, %al
movw $3084, %bx
ret
iterator_extract_control_and_status_register_hpmcounter13:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
cmpb $51, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter14
xorb %al, %al
movw $3085, %bx
ret
iterator_extract_control_and_status_register_hpmcounter14:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
cmpb $52, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter15
xorb %al, %al
movw $3086, %bx
ret
iterator_extract_control_and_status_register_hpmcounter15:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
cmpb $53, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter16
xorb %al, %al
movw $3087, %bx
ret
iterator_extract_control_and_status_register_hpmcounter16:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
cmpb $54, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter17
xorb %al, %al
movw $3088, %bx
ret
iterator_extract_control_and_status_register_hpmcounter17:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
cmpb $55, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter18
xorb %al, %al
movw $3089, %bx
ret
iterator_extract_control_and_status_register_hpmcounter18:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
cmpb $56, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter19
xorb %al, %al
movw $3090, %bx
ret
iterator_extract_control_and_status_register_hpmcounter19:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $49, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
cmpb $57, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter20
xorb %al, %al
movw $3091, %bx
ret
iterator_extract_control_and_status_register_hpmcounter20:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
cmpb $48, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter21
xorb %al, %al
movw $3092, %bx
ret
iterator_extract_control_and_status_register_hpmcounter21:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter22
xorb %al, %al
movw $3093, %bx
ret
iterator_extract_control_and_status_register_hpmcounter22:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
cmpb $50, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter23
xorb %al, %al
movw $3094, %bx
ret
iterator_extract_control_and_status_register_hpmcounter23:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
cmpb $51, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter24
xorb %al, %al
movw $3095, %bx
ret
iterator_extract_control_and_status_register_hpmcounter24:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
cmpb $52, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter25
xorb %al, %al
movw $3096, %bx
ret
iterator_extract_control_and_status_register_hpmcounter25:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
cmpb $53, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter26
xorb %al, %al
movw $3097, %bx
ret
iterator_extract_control_and_status_register_hpmcounter26:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
cmpb $54, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter27
xorb %al, %al
movw $3098, %bx
ret
iterator_extract_control_and_status_register_hpmcounter27:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
cmpb $55, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter28
xorb %al, %al
movw $3099, %bx
ret
iterator_extract_control_and_status_register_hpmcounter28:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
cmpb $56, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter29
xorb %al, %al
movw $3100, %bx
ret
iterator_extract_control_and_status_register_hpmcounter29:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $50, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
cmpb $57, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter30
xorb %al, %al
movw $3101, %bx
ret
iterator_extract_control_and_status_register_hpmcounter30:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $51, 10(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
cmpb $48, 11(%rax)
jne iterator_extract_control_and_status_register_hpmcounter31
xorb %al, %al
movw $3102, %bx
ret
iterator_extract_control_and_status_register_hpmcounter31:
cmpq $12, %rbx
jne iterator_extract_control_and_status_register_mvendorid
cmpb $104, (%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $112, 1(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $111, 4(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $117, 5(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $110, 6(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $116, 7(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $101, 8(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $114, 9(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $51, 10(%rax)
jne iterator_extract_control_and_status_register_mvendorid
cmpb $49, 11(%rax)
jne iterator_extract_control_and_status_register_mvendorid
xorb %al, %al
movw $3103, %bx
ret
iterator_extract_control_and_status_register_mvendorid:
cmpq $9, %rbx
jne iterator_extract_control_and_status_register_marchid
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $118, 1(%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $101, 2(%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $110, 3(%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $100, 4(%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $111, 5(%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $114, 6(%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $105, 7(%rax)
jne iterator_extract_control_and_status_register_marchid
cmpb $100, 8(%rax)
jne iterator_extract_control_and_status_register_marchid
xorb %al, %al
movw $3857, %bx
ret
iterator_extract_control_and_status_register_marchid:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_mimpid
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mimpid
cmpb $97, 1(%rax)
jne iterator_extract_control_and_status_register_mimpid
cmpb $114, 2(%rax)
jne iterator_extract_control_and_status_register_mimpid
cmpb $99, 3(%rax)
jne iterator_extract_control_and_status_register_mimpid
cmpb $104, 4(%rax)
jne iterator_extract_control_and_status_register_mimpid
cmpb $105, 5(%rax)
jne iterator_extract_control_and_status_register_mimpid
cmpb $100, 6(%rax)
jne iterator_extract_control_and_status_register_mimpid
xorb %al, %al
movw $3858, %bx
ret
iterator_extract_control_and_status_register_mimpid:
cmpq $6, %rbx
jne iterator_extract_control_and_status_register_mhartid
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_mhartid
cmpb $105, 1(%rax)
jne iterator_extract_control_and_status_register_mhartid
cmpb $109, 2(%rax)
jne iterator_extract_control_and_status_register_mhartid
cmpb $112, 3(%rax)
jne iterator_extract_control_and_status_register_mhartid
cmpb $105, 4(%rax)
jne iterator_extract_control_and_status_register_mhartid
cmpb $100, 5(%rax)
jne iterator_extract_control_and_status_register_mhartid
xorb %al, %al
movw $3859, %bx
ret
iterator_extract_control_and_status_register_mhartid:
cmpq $7, %rbx
jne iterator_extract_control_and_status_register_unknown
cmpb $109, (%rax)
jne iterator_extract_control_and_status_register_unknown
cmpb $104, 1(%rax)
jne iterator_extract_control_and_status_register_unknown
cmpb $97, 2(%rax)
jne iterator_extract_control_and_status_register_unknown
cmpb $114, 3(%rax)
jne iterator_extract_control_and_status_register_unknown
cmpb $116, 4(%rax)
jne iterator_extract_control_and_status_register_unknown
cmpb $105, 5(%rax)
jne iterator_extract_control_and_status_register_unknown
cmpb $100, 6(%rax)
jne iterator_extract_control_and_status_register_unknown
xorb %al, %al
movw $3860, %bx
ret
iterator_extract_control_and_status_register_unknown:
movb $1, %al
ret


# directives
# following functions return zero in al if the iterator points to a token that matches the comparison


iterator_is__align:
cmpq $6, iterator_token_size
jne iterator_is__align_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__align_false
cmpb $97, 1(%rax)
jne iterator_is__align_false
cmpb $108, 2(%rax)
jne iterator_is__align_false
cmpb $105, 3(%rax)
jne iterator_is__align_false
cmpb $103, 4(%rax)
jne iterator_is__align_false
cmpb $110, 5(%rax)
jne iterator_is__align_false
xorb %al, %al
ret
iterator_is__align_false:
movb $1, %al
ret

iterator_is__byte:
cmpq $5, iterator_token_size
jne iterator_is__byte_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__byte_false
cmpb $98, 1(%rax)
jne iterator_is__byte_false
cmpb $121, 2(%rax)
jne iterator_is__byte_false
cmpb $116, 3(%rax)
jne iterator_is__byte_false
cmpb $101, 4(%rax)
jne iterator_is__byte_false
xorb %al, %al
ret
iterator_is__byte_false:
movb $1, %al
ret

iterator_is__constant:
cmpq $9, iterator_token_size
jne iterator_is__constant_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__constant_false
cmpb $99, 1(%rax)
jne iterator_is__constant_false
cmpb $111, 2(%rax)
jne iterator_is__constant_false
cmpb $110, 3(%rax)
jne iterator_is__constant_false
cmpb $115, 4(%rax)
jne iterator_is__constant_false
cmpb $116, 5(%rax)
jne iterator_is__constant_false
cmpb $97, 6(%rax)
jne iterator_is__constant_false
cmpb $110, 7(%rax)
jne iterator_is__constant_false
cmpb $116, 8(%rax)
jne iterator_is__constant_false
xorb %al, %al
ret
iterator_is__constant_false:
movb $1, %al
ret

iterator_is__doubleword:
cmpq $11, iterator_token_size
jne iterator_is__doubleword_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__doubleword_false
cmpb $100, 1(%rax)
jne iterator_is__doubleword_false
cmpb $111, 2(%rax)
jne iterator_is__doubleword_false
cmpb $117, 3(%rax)
jne iterator_is__doubleword_false
cmpb $98, 4(%rax)
jne iterator_is__doubleword_false
cmpb $108, 5(%rax)
jne iterator_is__doubleword_false
cmpb $101, 6(%rax)
jne iterator_is__doubleword_false
cmpb $119, 7(%rax)
jne iterator_is__doubleword_false
cmpb $111, 8(%rax)
jne iterator_is__doubleword_false
cmpb $114, 9(%rax)
jne iterator_is__doubleword_false
cmpb $100, 10(%rax)
jne iterator_is__doubleword_false
xorb %al, %al
ret
iterator_is__doubleword_false:
movb $1, %al
ret

iterator_is__halfword:
cmpq $9, iterator_token_size
jne iterator_is__halfword_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__halfword_false
cmpb $104, 1(%rax)
jne iterator_is__halfword_false
cmpb $97, 2(%rax)
jne iterator_is__halfword_false
cmpb $108, 3(%rax)
jne iterator_is__halfword_false
cmpb $102, 4(%rax)
jne iterator_is__halfword_false
cmpb $119, 5(%rax)
jne iterator_is__halfword_false
cmpb $111, 6(%rax)
jne iterator_is__halfword_false
cmpb $114, 7(%rax)
jne iterator_is__halfword_false
cmpb $100, 8(%rax)
jne iterator_is__halfword_false
xorb %al, %al
ret
iterator_is__halfword_false:
movb $1, %al
ret

iterator_is__include:
cmpq $8, iterator_token_size
jne iterator_is__include_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__include_false
cmpb $105, 1(%rax)
jne iterator_is__include_false
cmpb $110, 2(%rax)
jne iterator_is__include_false
cmpb $99, 3(%rax)
jne iterator_is__include_false
cmpb $108, 4(%rax)
jne iterator_is__include_false
cmpb $117, 5(%rax)
jne iterator_is__include_false
cmpb $100, 6(%rax)
jne iterator_is__include_false
cmpb $101, 7(%rax)
jne iterator_is__include_false
xorb %al, %al
ret
iterator_is__include_false:
movb $1, %al
ret

iterator_is__label:
cmpq $6, iterator_token_size
jne iterator_is__label_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__label_false
cmpb $108, 1(%rax)
jne iterator_is__label_false
cmpb $97, 2(%rax)
jne iterator_is__label_false
cmpb $98, 3(%rax)
jne iterator_is__label_false
cmpb $101, 4(%rax)
jne iterator_is__label_false
cmpb $108, 5(%rax)
jne iterator_is__label_false
xorb %al, %al
ret
iterator_is__label_false:
movb $1, %al
ret

iterator_is__word:
cmpq $5, iterator_token_size
jne iterator_is__word_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__word_false
cmpb $119, 1(%rax)
jne iterator_is__word_false
cmpb $111, 2(%rax)
jne iterator_is__word_false
cmpb $114, 3(%rax)
jne iterator_is__word_false
cmpb $100, 4(%rax)
jne iterator_is__word_false
xorb %al, %al
ret
iterator_is__word_false:
movb $1, %al
ret

iterator_is__zero:
cmpq $5, iterator_token_size
jne iterator_is__zero_false
movq iterator_current_character, %rax
cmpb $46, (%rax)
jne iterator_is__zero_false
cmpb $122, 1(%rax)
jne iterator_is__zero_false
cmpb $101, 2(%rax)
jne iterator_is__zero_false
cmpb $114, 3(%rax)
jne iterator_is__zero_false
cmpb $111, 4(%rax)
jne iterator_is__zero_false
xorb %al, %al
ret
iterator_is__zero_false:
movb $1, %al
ret


# operations
# following functions return zero in al if the iterator points to a token that matches the comparison


iterator_is_add:
cmpq $3, iterator_token_size
jne iterator_is_add_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_add_false
cmpb $100, 1(%rax)
jne iterator_is_add_false
cmpb $100, 2(%rax)
jne iterator_is_add_false
xorb %al, %al
ret
iterator_is_add_false:
movb $1, %al
ret

iterator_is_addi:
cmpq $4, iterator_token_size
jne iterator_is_addi_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_addi_false
cmpb $100, 1(%rax)
jne iterator_is_addi_false
cmpb $100, 2(%rax)
jne iterator_is_addi_false
cmpb $105, 3(%rax)
jne iterator_is_addi_false
xorb %al, %al
ret
iterator_is_addi_false:
movb $1, %al
ret

iterator_is_addiw:
cmpq $5, iterator_token_size
jne iterator_is_addiw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_addiw_false
cmpb $100, 1(%rax)
jne iterator_is_addiw_false
cmpb $100, 2(%rax)
jne iterator_is_addiw_false
cmpb $105, 3(%rax)
jne iterator_is_addiw_false
cmpb $119, 4(%rax)
jne iterator_is_addiw_false
xorb %al, %al
ret
iterator_is_addiw_false:
movb $1, %al
ret

iterator_is_addw:
cmpq $4, iterator_token_size
jne iterator_is_addw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_addw_false
cmpb $100, 1(%rax)
jne iterator_is_addw_false
cmpb $100, 2(%rax)
jne iterator_is_addw_false
cmpb $119, 3(%rax)
jne iterator_is_addw_false
xorb %al, %al
ret
iterator_is_addw_false:
movb $1, %al
ret

iterator_is_and:
cmpq $3, iterator_token_size
jne iterator_is_and_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_and_false
cmpb $110, 1(%rax)
jne iterator_is_and_false
cmpb $100, 2(%rax)
jne iterator_is_and_false
xorb %al, %al
ret
iterator_is_and_false:
movb $1, %al
ret

iterator_is_andi:
cmpq $4, iterator_token_size
jne iterator_is_andi_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_andi_false
cmpb $110, 1(%rax)
jne iterator_is_andi_false
cmpb $100, 2(%rax)
jne iterator_is_andi_false
cmpb $105, 3(%rax)
jne iterator_is_andi_false
xorb %al, %al
ret
iterator_is_andi_false:
movb $1, %al
ret

iterator_is_amoaddd:
cmpq $7, iterator_token_size
jne iterator_is_amoaddd_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoaddd_false
cmpb $109, 1(%rax)
jne iterator_is_amoaddd_false
cmpb $111, 2(%rax)
jne iterator_is_amoaddd_false
cmpb $97, 3(%rax)
jne iterator_is_amoaddd_false
cmpb $100, 4(%rax)
jne iterator_is_amoaddd_false
cmpb $100, 5(%rax)
jne iterator_is_amoaddd_false
cmpb $100, 6(%rax)
jne iterator_is_amoaddd_false
xorb %al, %al
ret
iterator_is_amoaddd_false:
movb $1, %al
ret

iterator_is_amoadddaq:
cmpq $9, iterator_token_size
jne iterator_is_amoadddaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoadddaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoadddaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoadddaq_false
cmpb $97, 3(%rax)
jne iterator_is_amoadddaq_false
cmpb $100, 4(%rax)
jne iterator_is_amoadddaq_false
cmpb $100, 5(%rax)
jne iterator_is_amoadddaq_false
cmpb $100, 6(%rax)
jne iterator_is_amoadddaq_false
cmpb $97, 7(%rax)
jne iterator_is_amoadddaq_false
cmpb $113, 8(%rax)
jne iterator_is_amoadddaq_false
xorb %al, %al
ret
iterator_is_amoadddaq_false:
movb $1, %al
ret

iterator_is_amoadddaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amoadddaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoadddaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $100, 4(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $100, 6(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amoadddaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amoadddaqrl_false
xorb %al, %al
ret
iterator_is_amoadddaqrl_false:
movb $1, %al
ret

iterator_is_amoadddrl:
cmpq $9, iterator_token_size
jne iterator_is_amoadddrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoadddrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoadddrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoadddrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoadddrl_false
cmpb $100, 4(%rax)
jne iterator_is_amoadddrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoadddrl_false
cmpb $100, 6(%rax)
jne iterator_is_amoadddrl_false
cmpb $114, 7(%rax)
jne iterator_is_amoadddrl_false
cmpb $108, 8(%rax)
jne iterator_is_amoadddrl_false
xorb %al, %al
ret
iterator_is_amoadddrl_false:
movb $1, %al
ret

iterator_is_amoaddw:
cmpq $7, iterator_token_size
jne iterator_is_amoaddw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoaddw_false
cmpb $109, 1(%rax)
jne iterator_is_amoaddw_false
cmpb $111, 2(%rax)
jne iterator_is_amoaddw_false
cmpb $97, 3(%rax)
jne iterator_is_amoaddw_false
cmpb $100, 4(%rax)
jne iterator_is_amoaddw_false
cmpb $100, 5(%rax)
jne iterator_is_amoaddw_false
cmpb $119, 6(%rax)
jne iterator_is_amoaddw_false
xorb %al, %al
ret
iterator_is_amoaddw_false:
movb $1, %al
ret

iterator_is_amoaddwaq:
cmpq $9, iterator_token_size
jne iterator_is_amoaddwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoaddwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoaddwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoaddwaq_false
cmpb $97, 3(%rax)
jne iterator_is_amoaddwaq_false
cmpb $100, 4(%rax)
jne iterator_is_amoaddwaq_false
cmpb $100, 5(%rax)
jne iterator_is_amoaddwaq_false
cmpb $119, 6(%rax)
jne iterator_is_amoaddwaq_false
cmpb $97, 7(%rax)
jne iterator_is_amoaddwaq_false
cmpb $113, 8(%rax)
jne iterator_is_amoaddwaq_false
xorb %al, %al
ret
iterator_is_amoaddwaq_false:
movb $1, %al
ret

iterator_is_amoaddwaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amoaddwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $100, 4(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $119, 6(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amoaddwaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amoaddwaqrl_false
xorb %al, %al
ret
iterator_is_amoaddwaqrl_false:
movb $1, %al
ret

iterator_is_amoaddwrl:
cmpq $9, iterator_token_size
jne iterator_is_amoaddwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoaddwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoaddwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoaddwrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoaddwrl_false
cmpb $100, 4(%rax)
jne iterator_is_amoaddwrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoaddwrl_false
cmpb $119, 6(%rax)
jne iterator_is_amoaddwrl_false
cmpb $114, 7(%rax)
jne iterator_is_amoaddwrl_false
cmpb $108, 8(%rax)
jne iterator_is_amoaddwrl_false
xorb %al, %al
ret
iterator_is_amoaddwrl_false:
movb $1, %al
ret

iterator_is_amoandd:
cmpq $7, iterator_token_size
jne iterator_is_amoandd_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoandd_false
cmpb $109, 1(%rax)
jne iterator_is_amoandd_false
cmpb $111, 2(%rax)
jne iterator_is_amoandd_false
cmpb $97, 3(%rax)
jne iterator_is_amoandd_false
cmpb $110, 4(%rax)
jne iterator_is_amoandd_false
cmpb $100, 5(%rax)
jne iterator_is_amoandd_false
cmpb $100, 6(%rax)
jne iterator_is_amoandd_false
xorb %al, %al
ret
iterator_is_amoandd_false:
movb $1, %al
ret

iterator_is_amoanddaq:
cmpq $9, iterator_token_size
jne iterator_is_amoanddaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoanddaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoanddaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoanddaq_false
cmpb $97, 3(%rax)
jne iterator_is_amoanddaq_false
cmpb $110, 4(%rax)
jne iterator_is_amoanddaq_false
cmpb $100, 5(%rax)
jne iterator_is_amoanddaq_false
cmpb $100, 6(%rax)
jne iterator_is_amoanddaq_false
cmpb $97, 7(%rax)
jne iterator_is_amoanddaq_false
cmpb $113, 8(%rax)
jne iterator_is_amoanddaq_false
xorb %al, %al
ret
iterator_is_amoanddaq_false:
movb $1, %al
ret

iterator_is_amoanddaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amoanddaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoanddaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $110, 4(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $100, 6(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amoanddaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amoanddaqrl_false
xorb %al, %al
ret
iterator_is_amoanddaqrl_false:
movb $1, %al
ret

iterator_is_amoanddrl:
cmpq $9, iterator_token_size
jne iterator_is_amoanddrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoanddrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoanddrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoanddrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoanddrl_false
cmpb $110, 4(%rax)
jne iterator_is_amoanddrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoanddrl_false
cmpb $100, 6(%rax)
jne iterator_is_amoanddrl_false
cmpb $114, 7(%rax)
jne iterator_is_amoanddrl_false
cmpb $108, 8(%rax)
jne iterator_is_amoanddrl_false
xorb %al, %al
ret
iterator_is_amoanddrl_false:
movb $1, %al
ret

iterator_is_amoandw:
cmpq $7, iterator_token_size
jne iterator_is_amoandw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoandw_false
cmpb $109, 1(%rax)
jne iterator_is_amoandw_false
cmpb $111, 2(%rax)
jne iterator_is_amoandw_false
cmpb $97, 3(%rax)
jne iterator_is_amoandw_false
cmpb $110, 4(%rax)
jne iterator_is_amoandw_false
cmpb $100, 5(%rax)
jne iterator_is_amoandw_false
cmpb $119, 6(%rax)
jne iterator_is_amoandw_false
xorb %al, %al
ret
iterator_is_amoandw_false:
movb $1, %al
ret

iterator_is_amoandwaq:
cmpq $9, iterator_token_size
jne iterator_is_amoandwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoandwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoandwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoandwaq_false
cmpb $97, 3(%rax)
jne iterator_is_amoandwaq_false
cmpb $110, 4(%rax)
jne iterator_is_amoandwaq_false
cmpb $100, 5(%rax)
jne iterator_is_amoandwaq_false
cmpb $119, 6(%rax)
jne iterator_is_amoandwaq_false
cmpb $97, 7(%rax)
jne iterator_is_amoandwaq_false
cmpb $113, 8(%rax)
jne iterator_is_amoandwaq_false
xorb %al, %al
ret
iterator_is_amoandwaq_false:
movb $1, %al
ret

iterator_is_amoandwaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amoandwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoandwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $110, 4(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $119, 6(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amoandwaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amoandwaqrl_false
xorb %al, %al
ret
iterator_is_amoandwaqrl_false:
movb $1, %al
ret

iterator_is_amoandwrl:
cmpq $9, iterator_token_size
jne iterator_is_amoandwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoandwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoandwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoandwrl_false
cmpb $97, 3(%rax)
jne iterator_is_amoandwrl_false
cmpb $110, 4(%rax)
jne iterator_is_amoandwrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoandwrl_false
cmpb $119, 6(%rax)
jne iterator_is_amoandwrl_false
cmpb $114, 7(%rax)
jne iterator_is_amoandwrl_false
cmpb $108, 8(%rax)
jne iterator_is_amoandwrl_false
xorb %al, %al
ret
iterator_is_amoandwrl_false:
movb $1, %al
ret

iterator_is_amomaxd:
cmpq $7, iterator_token_size
jne iterator_is_amomaxd_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxd_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxd_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxd_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxd_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxd_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxd_false
cmpb $100, 6(%rax)
jne iterator_is_amomaxd_false
xorb %al, %al
ret
iterator_is_amomaxd_false:
movb $1, %al
ret

iterator_is_amomaxdaq:
cmpq $9, iterator_token_size
jne iterator_is_amomaxdaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxdaq_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxdaq_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxdaq_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxdaq_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxdaq_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxdaq_false
cmpb $100, 6(%rax)
jne iterator_is_amomaxdaq_false
cmpb $97, 7(%rax)
jne iterator_is_amomaxdaq_false
cmpb $113, 8(%rax)
jne iterator_is_amomaxdaq_false
xorb %al, %al
ret
iterator_is_amomaxdaq_false:
movb $1, %al
ret

iterator_is_amomaxdaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amomaxdaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $100, 6(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amomaxdaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amomaxdaqrl_false
xorb %al, %al
ret
iterator_is_amomaxdaqrl_false:
movb $1, %al
ret

iterator_is_amomaxdrl:
cmpq $9, iterator_token_size
jne iterator_is_amomaxdrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxdrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxdrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxdrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxdrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxdrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxdrl_false
cmpb $100, 6(%rax)
jne iterator_is_amomaxdrl_false
cmpb $114, 7(%rax)
jne iterator_is_amomaxdrl_false
cmpb $108, 8(%rax)
jne iterator_is_amomaxdrl_false
xorb %al, %al
ret
iterator_is_amomaxdrl_false:
movb $1, %al
ret

iterator_is_amomaxw:
cmpq $7, iterator_token_size
jne iterator_is_amomaxw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxw_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxw_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxw_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxw_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxw_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxw_false
cmpb $119, 6(%rax)
jne iterator_is_amomaxw_false
xorb %al, %al
ret
iterator_is_amomaxw_false:
movb $1, %al
ret

iterator_is_amomaxwaq:
cmpq $9, iterator_token_size
jne iterator_is_amomaxwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxwaq_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxwaq_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxwaq_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxwaq_false
cmpb $119, 6(%rax)
jne iterator_is_amomaxwaq_false
cmpb $97, 7(%rax)
jne iterator_is_amomaxwaq_false
cmpb $113, 8(%rax)
jne iterator_is_amomaxwaq_false
xorb %al, %al
ret
iterator_is_amomaxwaq_false:
movb $1, %al
ret

iterator_is_amomaxwaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amomaxwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $119, 6(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amomaxwaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amomaxwaqrl_false
xorb %al, %al
ret
iterator_is_amomaxwaqrl_false:
movb $1, %al
ret

iterator_is_amomaxwrl:
cmpq $9, iterator_token_size
jne iterator_is_amomaxwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxwrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxwrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxwrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxwrl_false
cmpb $119, 6(%rax)
jne iterator_is_amomaxwrl_false
cmpb $114, 7(%rax)
jne iterator_is_amomaxwrl_false
cmpb $108, 8(%rax)
jne iterator_is_amomaxwrl_false
xorb %al, %al
ret
iterator_is_amomaxwrl_false:
movb $1, %al
ret

iterator_is_amomaxud:
cmpq $8, iterator_token_size
jne iterator_is_amomaxud_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxud_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxud_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxud_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxud_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxud_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxud_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxud_false
cmpb $100, 7(%rax)
jne iterator_is_amomaxud_false
xorb %al, %al
ret
iterator_is_amomaxud_false:
movb $1, %al
ret

iterator_is_amomaxudaq:
cmpq $10, iterator_token_size
jne iterator_is_amomaxudaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxudaq_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxudaq_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxudaq_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxudaq_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxudaq_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxudaq_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxudaq_false
cmpb $100, 7(%rax)
jne iterator_is_amomaxudaq_false
cmpb $97, 8(%rax)
jne iterator_is_amomaxudaq_false
cmpb $113, 9(%rax)
jne iterator_is_amomaxudaq_false
xorb %al, %al
ret
iterator_is_amomaxudaq_false:
movb $1, %al
ret

iterator_is_amomaxudaqrl:
cmpq $12, iterator_token_size
jne iterator_is_amomaxudaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $100, 7(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $97, 8(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $113, 9(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $114, 10(%rax)
jne iterator_is_amomaxudaqrl_false
cmpb $108, 11(%rax)
jne iterator_is_amomaxudaqrl_false
xorb %al, %al
ret
iterator_is_amomaxudaqrl_false:
movb $1, %al
ret

iterator_is_amomaxudrl:
cmpq $10, iterator_token_size
jne iterator_is_amomaxudrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxudrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxudrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxudrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxudrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxudrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxudrl_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxudrl_false
cmpb $100, 7(%rax)
jne iterator_is_amomaxudrl_false
cmpb $114, 8(%rax)
jne iterator_is_amomaxudrl_false
cmpb $108, 9(%rax)
jne iterator_is_amomaxudrl_false
xorb %al, %al
ret
iterator_is_amomaxudrl_false:
movb $1, %al
ret

iterator_is_amomaxuw:
cmpq $8, iterator_token_size
jne iterator_is_amomaxuw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxuw_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxuw_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxuw_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxuw_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxuw_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxuw_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxuw_false
cmpb $119, 7(%rax)
jne iterator_is_amomaxuw_false
xorb %al, %al
ret
iterator_is_amomaxuw_false:
movb $1, %al
ret

iterator_is_amomaxuwaq:
cmpq $10, iterator_token_size
jne iterator_is_amomaxuwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxuwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $119, 7(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $97, 8(%rax)
jne iterator_is_amomaxuwaq_false
cmpb $113, 9(%rax)
jne iterator_is_amomaxuwaq_false
xorb %al, %al
ret
iterator_is_amomaxuwaq_false:
movb $1, %al
ret

iterator_is_amomaxuwaqrl:
cmpq $12, iterator_token_size
jne iterator_is_amomaxuwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $119, 7(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $97, 8(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $113, 9(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $114, 10(%rax)
jne iterator_is_amomaxuwaqrl_false
cmpb $108, 11(%rax)
jne iterator_is_amomaxuwaqrl_false
xorb %al, %al
ret
iterator_is_amomaxuwaqrl_false:
movb $1, %al
ret

iterator_is_amomaxuwrl:
cmpq $10, iterator_token_size
jne iterator_is_amomaxuwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomaxuwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $97, 4(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $120, 5(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $117, 6(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $119, 7(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $114, 8(%rax)
jne iterator_is_amomaxuwrl_false
cmpb $108, 9(%rax)
jne iterator_is_amomaxuwrl_false
xorb %al, %al
ret
iterator_is_amomaxuwrl_false:
movb $1, %al
ret

iterator_is_amomind:
cmpq $7, iterator_token_size
jne iterator_is_amomind_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomind_false
cmpb $109, 1(%rax)
jne iterator_is_amomind_false
cmpb $111, 2(%rax)
jne iterator_is_amomind_false
cmpb $109, 3(%rax)
jne iterator_is_amomind_false
cmpb $105, 4(%rax)
jne iterator_is_amomind_false
cmpb $110, 5(%rax)
jne iterator_is_amomind_false
cmpb $100, 6(%rax)
jne iterator_is_amomind_false
xorb %al, %al
ret
iterator_is_amomind_false:
movb $1, %al
ret

iterator_is_amomindaq:
cmpq $9, iterator_token_size
jne iterator_is_amomindaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomindaq_false
cmpb $109, 1(%rax)
jne iterator_is_amomindaq_false
cmpb $111, 2(%rax)
jne iterator_is_amomindaq_false
cmpb $109, 3(%rax)
jne iterator_is_amomindaq_false
cmpb $105, 4(%rax)
jne iterator_is_amomindaq_false
cmpb $110, 5(%rax)
jne iterator_is_amomindaq_false
cmpb $100, 6(%rax)
jne iterator_is_amomindaq_false
cmpb $97, 7(%rax)
jne iterator_is_amomindaq_false
cmpb $113, 8(%rax)
jne iterator_is_amomindaq_false
xorb %al, %al
ret
iterator_is_amomindaq_false:
movb $1, %al
ret

iterator_is_amomindaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amomindaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomindaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomindaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomindaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomindaqrl_false
cmpb $105, 4(%rax)
jne iterator_is_amomindaqrl_false
cmpb $110, 5(%rax)
jne iterator_is_amomindaqrl_false
cmpb $100, 6(%rax)
jne iterator_is_amomindaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amomindaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amomindaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amomindaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amomindaqrl_false
xorb %al, %al
ret
iterator_is_amomindaqrl_false:
movb $1, %al
ret

iterator_is_amomindrl:
cmpq $9, iterator_token_size
jne iterator_is_amomindrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amomindrl_false
cmpb $109, 1(%rax)
jne iterator_is_amomindrl_false
cmpb $111, 2(%rax)
jne iterator_is_amomindrl_false
cmpb $109, 3(%rax)
jne iterator_is_amomindrl_false
cmpb $105, 4(%rax)
jne iterator_is_amomindrl_false
cmpb $110, 5(%rax)
jne iterator_is_amomindrl_false
cmpb $100, 6(%rax)
jne iterator_is_amomindrl_false
cmpb $114, 7(%rax)
jne iterator_is_amomindrl_false
cmpb $108, 8(%rax)
jne iterator_is_amomindrl_false
xorb %al, %al
ret
iterator_is_amomindrl_false:
movb $1, %al
ret

iterator_is_amominw:
cmpq $7, iterator_token_size
jne iterator_is_amominw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominw_false
cmpb $109, 1(%rax)
jne iterator_is_amominw_false
cmpb $111, 2(%rax)
jne iterator_is_amominw_false
cmpb $109, 3(%rax)
jne iterator_is_amominw_false
cmpb $105, 4(%rax)
jne iterator_is_amominw_false
cmpb $110, 5(%rax)
jne iterator_is_amominw_false
cmpb $119, 6(%rax)
jne iterator_is_amominw_false
xorb %al, %al
ret
iterator_is_amominw_false:
movb $1, %al
ret

iterator_is_amominwaq:
cmpq $9, iterator_token_size
jne iterator_is_amominwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amominwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amominwaq_false
cmpb $109, 3(%rax)
jne iterator_is_amominwaq_false
cmpb $105, 4(%rax)
jne iterator_is_amominwaq_false
cmpb $110, 5(%rax)
jne iterator_is_amominwaq_false
cmpb $119, 6(%rax)
jne iterator_is_amominwaq_false
cmpb $97, 7(%rax)
jne iterator_is_amominwaq_false
cmpb $113, 8(%rax)
jne iterator_is_amominwaq_false
xorb %al, %al
ret
iterator_is_amominwaq_false:
movb $1, %al
ret

iterator_is_amominwaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amominwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amominwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amominwaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amominwaqrl_false
cmpb $105, 4(%rax)
jne iterator_is_amominwaqrl_false
cmpb $110, 5(%rax)
jne iterator_is_amominwaqrl_false
cmpb $119, 6(%rax)
jne iterator_is_amominwaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amominwaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amominwaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amominwaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amominwaqrl_false
xorb %al, %al
ret
iterator_is_amominwaqrl_false:
movb $1, %al
ret

iterator_is_amominwrl:
cmpq $9, iterator_token_size
jne iterator_is_amominwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amominwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amominwrl_false
cmpb $109, 3(%rax)
jne iterator_is_amominwrl_false
cmpb $105, 4(%rax)
jne iterator_is_amominwrl_false
cmpb $110, 5(%rax)
jne iterator_is_amominwrl_false
cmpb $119, 6(%rax)
jne iterator_is_amominwrl_false
cmpb $114, 7(%rax)
jne iterator_is_amominwrl_false
cmpb $108, 8(%rax)
jne iterator_is_amominwrl_false
xorb %al, %al
ret
iterator_is_amominwrl_false:
movb $1, %al
ret

iterator_is_amominud:
cmpq $8, iterator_token_size
jne iterator_is_amominud_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominud_false
cmpb $109, 1(%rax)
jne iterator_is_amominud_false
cmpb $111, 2(%rax)
jne iterator_is_amominud_false
cmpb $109, 3(%rax)
jne iterator_is_amominud_false
cmpb $105, 4(%rax)
jne iterator_is_amominud_false
cmpb $110, 5(%rax)
jne iterator_is_amominud_false
cmpb $117, 6(%rax)
jne iterator_is_amominud_false
cmpb $100, 7(%rax)
jne iterator_is_amominud_false
xorb %al, %al
ret
iterator_is_amominud_false:
movb $1, %al
ret

iterator_is_amominudaq:
cmpq $10, iterator_token_size
jne iterator_is_amominudaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominudaq_false
cmpb $109, 1(%rax)
jne iterator_is_amominudaq_false
cmpb $111, 2(%rax)
jne iterator_is_amominudaq_false
cmpb $109, 3(%rax)
jne iterator_is_amominudaq_false
cmpb $105, 4(%rax)
jne iterator_is_amominudaq_false
cmpb $110, 5(%rax)
jne iterator_is_amominudaq_false
cmpb $117, 6(%rax)
jne iterator_is_amominudaq_false
cmpb $100, 7(%rax)
jne iterator_is_amominudaq_false
cmpb $97, 8(%rax)
jne iterator_is_amominudaq_false
cmpb $113, 9(%rax)
jne iterator_is_amominudaq_false
xorb %al, %al
ret
iterator_is_amominudaq_false:
movb $1, %al
ret

iterator_is_amominudaqrl:
cmpq $12, iterator_token_size
jne iterator_is_amominudaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominudaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amominudaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amominudaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amominudaqrl_false
cmpb $105, 4(%rax)
jne iterator_is_amominudaqrl_false
cmpb $110, 5(%rax)
jne iterator_is_amominudaqrl_false
cmpb $117, 6(%rax)
jne iterator_is_amominudaqrl_false
cmpb $100, 7(%rax)
jne iterator_is_amominudaqrl_false
cmpb $97, 8(%rax)
jne iterator_is_amominudaqrl_false
cmpb $113, 9(%rax)
jne iterator_is_amominudaqrl_false
cmpb $114, 10(%rax)
jne iterator_is_amominudaqrl_false
cmpb $108, 11(%rax)
jne iterator_is_amominudaqrl_false
xorb %al, %al
ret
iterator_is_amominudaqrl_false:
movb $1, %al
ret

iterator_is_amominudrl:
cmpq $10, iterator_token_size
jne iterator_is_amominudrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominudrl_false
cmpb $109, 1(%rax)
jne iterator_is_amominudrl_false
cmpb $111, 2(%rax)
jne iterator_is_amominudrl_false
cmpb $109, 3(%rax)
jne iterator_is_amominudrl_false
cmpb $105, 4(%rax)
jne iterator_is_amominudrl_false
cmpb $110, 5(%rax)
jne iterator_is_amominudrl_false
cmpb $117, 6(%rax)
jne iterator_is_amominudrl_false
cmpb $100, 7(%rax)
jne iterator_is_amominudrl_false
cmpb $114, 8(%rax)
jne iterator_is_amominudrl_false
cmpb $108, 9(%rax)
jne iterator_is_amominudrl_false
xorb %al, %al
ret
iterator_is_amominudrl_false:
movb $1, %al
ret

iterator_is_amominuw:
cmpq $8, iterator_token_size
jne iterator_is_amominuw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominuw_false
cmpb $109, 1(%rax)
jne iterator_is_amominuw_false
cmpb $111, 2(%rax)
jne iterator_is_amominuw_false
cmpb $109, 3(%rax)
jne iterator_is_amominuw_false
cmpb $105, 4(%rax)
jne iterator_is_amominuw_false
cmpb $110, 5(%rax)
jne iterator_is_amominuw_false
cmpb $117, 6(%rax)
jne iterator_is_amominuw_false
cmpb $119, 7(%rax)
jne iterator_is_amominuw_false
xorb %al, %al
ret
iterator_is_amominuw_false:
movb $1, %al
ret

iterator_is_amominuwaq:
cmpq $10, iterator_token_size
jne iterator_is_amominuwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominuwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amominuwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amominuwaq_false
cmpb $109, 3(%rax)
jne iterator_is_amominuwaq_false
cmpb $105, 4(%rax)
jne iterator_is_amominuwaq_false
cmpb $110, 5(%rax)
jne iterator_is_amominuwaq_false
cmpb $117, 6(%rax)
jne iterator_is_amominuwaq_false
cmpb $119, 7(%rax)
jne iterator_is_amominuwaq_false
cmpb $97, 8(%rax)
jne iterator_is_amominuwaq_false
cmpb $113, 9(%rax)
jne iterator_is_amominuwaq_false
xorb %al, %al
ret
iterator_is_amominuwaq_false:
movb $1, %al
ret

iterator_is_amominuwaqrl:
cmpq $12, iterator_token_size
jne iterator_is_amominuwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominuwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $109, 3(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $105, 4(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $110, 5(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $117, 6(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $119, 7(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $97, 8(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $113, 9(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $114, 10(%rax)
jne iterator_is_amominuwaqrl_false
cmpb $108, 11(%rax)
jne iterator_is_amominuwaqrl_false
xorb %al, %al
ret
iterator_is_amominuwaqrl_false:
movb $1, %al
ret

iterator_is_amominuwrl:
cmpq $10, iterator_token_size
jne iterator_is_amominuwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amominuwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amominuwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amominuwrl_false
cmpb $109, 3(%rax)
jne iterator_is_amominuwrl_false
cmpb $105, 4(%rax)
jne iterator_is_amominuwrl_false
cmpb $110, 5(%rax)
jne iterator_is_amominuwrl_false
cmpb $117, 6(%rax)
jne iterator_is_amominuwrl_false
cmpb $119, 7(%rax)
jne iterator_is_amominuwrl_false
cmpb $114, 8(%rax)
jne iterator_is_amominuwrl_false
cmpb $108, 9(%rax)
jne iterator_is_amominuwrl_false
xorb %al, %al
ret
iterator_is_amominuwrl_false:
movb $1, %al
ret

iterator_is_amoord:
cmpq $6, iterator_token_size
jne iterator_is_amoord_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoord_false
cmpb $109, 1(%rax)
jne iterator_is_amoord_false
cmpb $111, 2(%rax)
jne iterator_is_amoord_false
cmpb $111, 3(%rax)
jne iterator_is_amoord_false
cmpb $114, 4(%rax)
jne iterator_is_amoord_false
cmpb $100, 5(%rax)
jne iterator_is_amoord_false
xorb %al, %al
ret
iterator_is_amoord_false:
movb $1, %al
ret

iterator_is_amoordaq:
cmpq $8, iterator_token_size
jne iterator_is_amoordaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoordaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoordaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoordaq_false
cmpb $111, 3(%rax)
jne iterator_is_amoordaq_false
cmpb $114, 4(%rax)
jne iterator_is_amoordaq_false
cmpb $100, 5(%rax)
jne iterator_is_amoordaq_false
cmpb $97, 6(%rax)
jne iterator_is_amoordaq_false
cmpb $113, 7(%rax)
jne iterator_is_amoordaq_false
xorb %al, %al
ret
iterator_is_amoordaq_false:
movb $1, %al
ret

iterator_is_amoordaqrl:
cmpq $10, iterator_token_size
jne iterator_is_amoordaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoordaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoordaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoordaqrl_false
cmpb $111, 3(%rax)
jne iterator_is_amoordaqrl_false
cmpb $114, 4(%rax)
jne iterator_is_amoordaqrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoordaqrl_false
cmpb $97, 6(%rax)
jne iterator_is_amoordaqrl_false
cmpb $113, 7(%rax)
jne iterator_is_amoordaqrl_false
cmpb $114, 8(%rax)
jne iterator_is_amoordaqrl_false
cmpb $108, 9(%rax)
jne iterator_is_amoordaqrl_false
xorb %al, %al
ret
iterator_is_amoordaqrl_false:
movb $1, %al
ret

iterator_is_amoordrl:
cmpq $8, iterator_token_size
jne iterator_is_amoordrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoordrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoordrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoordrl_false
cmpb $111, 3(%rax)
jne iterator_is_amoordrl_false
cmpb $114, 4(%rax)
jne iterator_is_amoordrl_false
cmpb $100, 5(%rax)
jne iterator_is_amoordrl_false
cmpb $114, 6(%rax)
jne iterator_is_amoordrl_false
cmpb $108, 7(%rax)
jne iterator_is_amoordrl_false
xorb %al, %al
ret
iterator_is_amoordrl_false:
movb $1, %al
ret

iterator_is_amoorw:
cmpq $6, iterator_token_size
jne iterator_is_amoorw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoorw_false
cmpb $109, 1(%rax)
jne iterator_is_amoorw_false
cmpb $111, 2(%rax)
jne iterator_is_amoorw_false
cmpb $111, 3(%rax)
jne iterator_is_amoorw_false
cmpb $114, 4(%rax)
jne iterator_is_amoorw_false
cmpb $119, 5(%rax)
jne iterator_is_amoorw_false
xorb %al, %al
ret
iterator_is_amoorw_false:
movb $1, %al
ret

iterator_is_amoorwaq:
cmpq $8, iterator_token_size
jne iterator_is_amoorwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoorwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoorwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoorwaq_false
cmpb $111, 3(%rax)
jne iterator_is_amoorwaq_false
cmpb $114, 4(%rax)
jne iterator_is_amoorwaq_false
cmpb $119, 5(%rax)
jne iterator_is_amoorwaq_false
cmpb $97, 6(%rax)
jne iterator_is_amoorwaq_false
cmpb $113, 7(%rax)
jne iterator_is_amoorwaq_false
xorb %al, %al
ret
iterator_is_amoorwaq_false:
movb $1, %al
ret

iterator_is_amoorwaqrl:
cmpq $10, iterator_token_size
jne iterator_is_amoorwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoorwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $111, 3(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $114, 4(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $119, 5(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $97, 6(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $113, 7(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $114, 8(%rax)
jne iterator_is_amoorwaqrl_false
cmpb $108, 9(%rax)
jne iterator_is_amoorwaqrl_false
xorb %al, %al
ret
iterator_is_amoorwaqrl_false:
movb $1, %al
ret

iterator_is_amoorwrl:
cmpq $8, iterator_token_size
jne iterator_is_amoorwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoorwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoorwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoorwrl_false
cmpb $111, 3(%rax)
jne iterator_is_amoorwrl_false
cmpb $114, 4(%rax)
jne iterator_is_amoorwrl_false
cmpb $119, 5(%rax)
jne iterator_is_amoorwrl_false
cmpb $114, 6(%rax)
jne iterator_is_amoorwrl_false
cmpb $108, 7(%rax)
jne iterator_is_amoorwrl_false
xorb %al, %al
ret
iterator_is_amoorwrl_false:
movb $1, %al
ret

iterator_is_amoswapd:
cmpq $8, iterator_token_size
jne iterator_is_amoswapd_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapd_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapd_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapd_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapd_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapd_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapd_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapd_false
cmpb $100, 7(%rax)
jne iterator_is_amoswapd_false
xorb %al, %al
ret
iterator_is_amoswapd_false:
movb $1, %al
ret

iterator_is_amoswapdaq:
cmpq $10, iterator_token_size
jne iterator_is_amoswapdaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapdaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapdaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapdaq_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapdaq_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapdaq_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapdaq_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapdaq_false
cmpb $100, 7(%rax)
jne iterator_is_amoswapdaq_false
cmpb $97, 8(%rax)
jne iterator_is_amoswapdaq_false
cmpb $113, 9(%rax)
jne iterator_is_amoswapdaq_false
xorb %al, %al
ret
iterator_is_amoswapdaq_false:
movb $1, %al
ret

iterator_is_amoswapdaqrl:
cmpq $12, iterator_token_size
jne iterator_is_amoswapdaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $100, 7(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $97, 8(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $113, 9(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $114, 10(%rax)
jne iterator_is_amoswapdaqrl_false
cmpb $108, 11(%rax)
jne iterator_is_amoswapdaqrl_false
xorb %al, %al
ret
iterator_is_amoswapdaqrl_false:
movb $1, %al
ret

iterator_is_amoswapdrl:
cmpq $10, iterator_token_size
jne iterator_is_amoswapdrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapdrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapdrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapdrl_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapdrl_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapdrl_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapdrl_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapdrl_false
cmpb $100, 7(%rax)
jne iterator_is_amoswapdrl_false
cmpb $114, 8(%rax)
jne iterator_is_amoswapdrl_false
cmpb $108, 9(%rax)
jne iterator_is_amoswapdrl_false
xorb %al, %al
ret
iterator_is_amoswapdrl_false:
movb $1, %al
ret

iterator_is_amoswapw:
cmpq $8, iterator_token_size
jne iterator_is_amoswapw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapw_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapw_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapw_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapw_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapw_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapw_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapw_false
cmpb $119, 7(%rax)
jne iterator_is_amoswapw_false
xorb %al, %al
ret
iterator_is_amoswapw_false:
movb $1, %al
ret

iterator_is_amoswapwaq:
cmpq $10, iterator_token_size
jne iterator_is_amoswapwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapwaq_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapwaq_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapwaq_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapwaq_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapwaq_false
cmpb $119, 7(%rax)
jne iterator_is_amoswapwaq_false
cmpb $97, 8(%rax)
jne iterator_is_amoswapwaq_false
cmpb $113, 9(%rax)
jne iterator_is_amoswapwaq_false
xorb %al, %al
ret
iterator_is_amoswapwaq_false:
movb $1, %al
ret

iterator_is_amoswapwaqrl:
cmpq $12, iterator_token_size
jne iterator_is_amoswapwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $119, 7(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $97, 8(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $113, 9(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $114, 10(%rax)
jne iterator_is_amoswapwaqrl_false
cmpb $108, 11(%rax)
jne iterator_is_amoswapwaqrl_false
xorb %al, %al
ret
iterator_is_amoswapwaqrl_false:
movb $1, %al
ret

iterator_is_amoswapwrl:
cmpq $10, iterator_token_size
jne iterator_is_amoswapwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoswapwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoswapwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoswapwrl_false
cmpb $115, 3(%rax)
jne iterator_is_amoswapwrl_false
cmpb $119, 4(%rax)
jne iterator_is_amoswapwrl_false
cmpb $97, 5(%rax)
jne iterator_is_amoswapwrl_false
cmpb $112, 6(%rax)
jne iterator_is_amoswapwrl_false
cmpb $119, 7(%rax)
jne iterator_is_amoswapwrl_false
cmpb $114, 8(%rax)
jne iterator_is_amoswapwrl_false
cmpb $108, 9(%rax)
jne iterator_is_amoswapwrl_false
xorb %al, %al
ret
iterator_is_amoswapwrl_false:
movb $1, %al
ret

iterator_is_amoxord:
cmpq $7, iterator_token_size
jne iterator_is_amoxord_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxord_false
cmpb $109, 1(%rax)
jne iterator_is_amoxord_false
cmpb $111, 2(%rax)
jne iterator_is_amoxord_false
cmpb $120, 3(%rax)
jne iterator_is_amoxord_false
cmpb $111, 4(%rax)
jne iterator_is_amoxord_false
cmpb $114, 5(%rax)
jne iterator_is_amoxord_false
cmpb $100, 6(%rax)
jne iterator_is_amoxord_false
xorb %al, %al
ret
iterator_is_amoxord_false:
movb $1, %al
ret

iterator_is_amoxordaq:
cmpq $9, iterator_token_size
jne iterator_is_amoxordaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxordaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoxordaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoxordaq_false
cmpb $120, 3(%rax)
jne iterator_is_amoxordaq_false
cmpb $111, 4(%rax)
jne iterator_is_amoxordaq_false
cmpb $114, 5(%rax)
jne iterator_is_amoxordaq_false
cmpb $100, 6(%rax)
jne iterator_is_amoxordaq_false
cmpb $97, 7(%rax)
jne iterator_is_amoxordaq_false
cmpb $113, 8(%rax)
jne iterator_is_amoxordaq_false
xorb %al, %al
ret
iterator_is_amoxordaq_false:
movb $1, %al
ret

iterator_is_amoxordaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amoxordaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxordaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $120, 3(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $111, 4(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $114, 5(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $100, 6(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amoxordaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amoxordaqrl_false
xorb %al, %al
ret
iterator_is_amoxordaqrl_false:
movb $1, %al
ret

iterator_is_amoxordrl:
cmpq $9, iterator_token_size
jne iterator_is_amoxordrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxordrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoxordrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoxordrl_false
cmpb $120, 3(%rax)
jne iterator_is_amoxordrl_false
cmpb $111, 4(%rax)
jne iterator_is_amoxordrl_false
cmpb $114, 5(%rax)
jne iterator_is_amoxordrl_false
cmpb $100, 6(%rax)
jne iterator_is_amoxordrl_false
cmpb $114, 7(%rax)
jne iterator_is_amoxordrl_false
cmpb $108, 8(%rax)
jne iterator_is_amoxordrl_false
xorb %al, %al
ret
iterator_is_amoxordrl_false:
movb $1, %al
ret

iterator_is_amoxorw:
cmpq $7, iterator_token_size
jne iterator_is_amoxorw_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxorw_false
cmpb $109, 1(%rax)
jne iterator_is_amoxorw_false
cmpb $111, 2(%rax)
jne iterator_is_amoxorw_false
cmpb $120, 3(%rax)
jne iterator_is_amoxorw_false
cmpb $111, 4(%rax)
jne iterator_is_amoxorw_false
cmpb $114, 5(%rax)
jne iterator_is_amoxorw_false
cmpb $119, 6(%rax)
jne iterator_is_amoxorw_false
xorb %al, %al
ret
iterator_is_amoxorw_false:
movb $1, %al
ret

iterator_is_amoxorwaq:
cmpq $9, iterator_token_size
jne iterator_is_amoxorwaq_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxorwaq_false
cmpb $109, 1(%rax)
jne iterator_is_amoxorwaq_false
cmpb $111, 2(%rax)
jne iterator_is_amoxorwaq_false
cmpb $120, 3(%rax)
jne iterator_is_amoxorwaq_false
cmpb $111, 4(%rax)
jne iterator_is_amoxorwaq_false
cmpb $114, 5(%rax)
jne iterator_is_amoxorwaq_false
cmpb $119, 6(%rax)
jne iterator_is_amoxorwaq_false
cmpb $97, 7(%rax)
jne iterator_is_amoxorwaq_false
cmpb $113, 8(%rax)
jne iterator_is_amoxorwaq_false
xorb %al, %al
ret
iterator_is_amoxorwaq_false:
movb $1, %al
ret

iterator_is_amoxorwaqrl:
cmpq $11, iterator_token_size
jne iterator_is_amoxorwaqrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $120, 3(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $111, 4(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $114, 5(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $119, 6(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $97, 7(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $113, 8(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $114, 9(%rax)
jne iterator_is_amoxorwaqrl_false
cmpb $108, 10(%rax)
jne iterator_is_amoxorwaqrl_false
xorb %al, %al
ret
iterator_is_amoxorwaqrl_false:
movb $1, %al
ret

iterator_is_amoxorwrl:
cmpq $9, iterator_token_size
jne iterator_is_amoxorwrl_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_amoxorwrl_false
cmpb $109, 1(%rax)
jne iterator_is_amoxorwrl_false
cmpb $111, 2(%rax)
jne iterator_is_amoxorwrl_false
cmpb $120, 3(%rax)
jne iterator_is_amoxorwrl_false
cmpb $111, 4(%rax)
jne iterator_is_amoxorwrl_false
cmpb $114, 5(%rax)
jne iterator_is_amoxorwrl_false
cmpb $119, 6(%rax)
jne iterator_is_amoxorwrl_false
cmpb $114, 7(%rax)
jne iterator_is_amoxorwrl_false
cmpb $108, 8(%rax)
jne iterator_is_amoxorwrl_false
xorb %al, %al
ret
iterator_is_amoxorwrl_false:
movb $1, %al
ret

iterator_is_auipc:
cmpq $5, iterator_token_size
jne iterator_is_auipc_false
movq iterator_current_character, %rax
cmpb $97, (%rax)
jne iterator_is_auipc_false
cmpb $117, 1(%rax)
jne iterator_is_auipc_false
cmpb $105, 2(%rax)
jne iterator_is_auipc_false
cmpb $112, 3(%rax)
jne iterator_is_auipc_false
cmpb $99, 4(%rax)
jne iterator_is_auipc_false
xorb %al, %al
ret
iterator_is_auipc_false:
movb $1, %al
ret

iterator_is_beq:
cmpq $3, iterator_token_size
jne iterator_is_beq_false
movq iterator_current_character, %rax
cmpb $98, (%rax)
jne iterator_is_beq_false
cmpb $101, 1(%rax)
jne iterator_is_beq_false
cmpb $113, 2(%rax)
jne iterator_is_beq_false
xorb %al, %al
ret
iterator_is_beq_false:
movb $1, %al
ret

iterator_is_bge:
cmpq $3, iterator_token_size
jne iterator_is_bge_false
movq iterator_current_character, %rax
cmpb $98, (%rax)
jne iterator_is_bge_false
cmpb $103, 1(%rax)
jne iterator_is_bge_false
cmpb $101, 2(%rax)
jne iterator_is_bge_false
xorb %al, %al
ret
iterator_is_bge_false:
movb $1, %al
ret

iterator_is_bgeu:
cmpq $4, iterator_token_size
jne iterator_is_bgeu_false
movq iterator_current_character, %rax
cmpb $98, (%rax)
jne iterator_is_bgeu_false
cmpb $103, 1(%rax)
jne iterator_is_bgeu_false
cmpb $101, 2(%rax)
jne iterator_is_bgeu_false
cmpb $117, 3(%rax)
jne iterator_is_bgeu_false
xorb %al, %al
ret
iterator_is_bgeu_false:
movb $1, %al
ret

iterator_is_blt:
cmpq $3, iterator_token_size
jne iterator_is_blt_false
movq iterator_current_character, %rax
cmpb $98, (%rax)
jne iterator_is_blt_false
cmpb $108, 1(%rax)
jne iterator_is_blt_false
cmpb $116, 2(%rax)
jne iterator_is_blt_false
xorb %al, %al
ret
iterator_is_blt_false:
movb $1, %al
ret

iterator_is_bltu:
cmpq $4, iterator_token_size
jne iterator_is_bltu_false
movq iterator_current_character, %rax
cmpb $98, (%rax)
jne iterator_is_bltu_false
cmpb $108, 1(%rax)
jne iterator_is_bltu_false
cmpb $116, 2(%rax)
jne iterator_is_bltu_false
cmpb $117, 3(%rax)
jne iterator_is_bltu_false
xorb %al, %al
ret
iterator_is_bltu_false:
movb $1, %al
ret

iterator_is_bne:
cmpq $3, iterator_token_size
jne iterator_is_bne_false
movq iterator_current_character, %rax
cmpb $98, (%rax)
jne iterator_is_bne_false
cmpb $110, 1(%rax)
jne iterator_is_bne_false
cmpb $101, 2(%rax)
jne iterator_is_bne_false
xorb %al, %al
ret
iterator_is_bne_false:
movb $1, %al
ret

iterator_is_call:
cmpq $4, iterator_token_size
jne iterator_is_call_false
movq iterator_current_character, %rax
cmpb $99, (%rax)
jne iterator_is_call_false
cmpb $97, 1(%rax)
jne iterator_is_call_false
cmpb $108, 2(%rax)
jne iterator_is_call_false
cmpb $108, 3(%rax)
jne iterator_is_call_false
xorb %al, %al
ret
iterator_is_call_false:
movb $1, %al
ret

iterator_is_csrrc:
cmpq $5, iterator_token_size
jne iterator_is_csrrc_false
movq iterator_current_character, %rax
cmpb $99, (%rax)
jne iterator_is_csrrc_false
cmpb $115, 1(%rax)
jne iterator_is_csrrc_false
cmpb $114, 2(%rax)
jne iterator_is_csrrc_false
cmpb $114, 3(%rax)
jne iterator_is_csrrc_false
cmpb $99, 4(%rax)
jne iterator_is_csrrc_false
xorb %al, %al
ret
iterator_is_csrrc_false:
movb $1, %al
ret

iterator_is_csrrci:
cmpq $6, iterator_token_size
jne iterator_is_csrrci_false
movq iterator_current_character, %rax
cmpb $99, (%rax)
jne iterator_is_csrrci_false
cmpb $115, 1(%rax)
jne iterator_is_csrrci_false
cmpb $114, 2(%rax)
jne iterator_is_csrrci_false
cmpb $114, 3(%rax)
jne iterator_is_csrrci_false
cmpb $99, 4(%rax)
jne iterator_is_csrrci_false
cmpb $105, 5(%rax)
jne iterator_is_csrrci_false
xorb %al, %al
ret
iterator_is_csrrci_false:
movb $1, %al
ret

iterator_is_csrrs:
cmpq $5, iterator_token_size
jne iterator_is_csrrs_false
movq iterator_current_character, %rax
cmpb $99, (%rax)
jne iterator_is_csrrs_false
cmpb $115, 1(%rax)
jne iterator_is_csrrs_false
cmpb $114, 2(%rax)
jne iterator_is_csrrs_false
cmpb $114, 3(%rax)
jne iterator_is_csrrs_false
cmpb $115, 4(%rax)
jne iterator_is_csrrs_false
xorb %al, %al
ret
iterator_is_csrrs_false:
movb $1, %al
ret

iterator_is_csrrsi:
cmpq $6, iterator_token_size
jne iterator_is_csrrsi_false
movq iterator_current_character, %rax
cmpb $99, (%rax)
jne iterator_is_csrrsi_false
cmpb $115, 1(%rax)
jne iterator_is_csrrsi_false
cmpb $114, 2(%rax)
jne iterator_is_csrrsi_false
cmpb $114, 3(%rax)
jne iterator_is_csrrsi_false
cmpb $115, 4(%rax)
jne iterator_is_csrrsi_false
cmpb $105, 5(%rax)
jne iterator_is_csrrsi_false
xorb %al, %al
ret
iterator_is_csrrsi_false:
movb $1, %al
ret

iterator_is_csrrw:
cmpq $5, iterator_token_size
jne iterator_is_csrrw_false
movq iterator_current_character, %rax
cmpb $99, (%rax)
jne iterator_is_csrrw_false
cmpb $115, 1(%rax)
jne iterator_is_csrrw_false
cmpb $114, 2(%rax)
jne iterator_is_csrrw_false
cmpb $114, 3(%rax)
jne iterator_is_csrrw_false
cmpb $119, 4(%rax)
jne iterator_is_csrrw_false
xorb %al, %al
ret
iterator_is_csrrw_false:
movb $1, %al
ret

iterator_is_csrrwi:
cmpq $6, iterator_token_size
jne iterator_is_csrrwi_false
movq iterator_current_character, %rax
cmpb $99, (%rax)
jne iterator_is_csrrwi_false
cmpb $115, 1(%rax)
jne iterator_is_csrrwi_false
cmpb $114, 2(%rax)
jne iterator_is_csrrwi_false
cmpb $114, 3(%rax)
jne iterator_is_csrrwi_false
cmpb $119, 4(%rax)
jne iterator_is_csrrwi_false
cmpb $105, 5(%rax)
jne iterator_is_csrrwi_false
xorb %al, %al
ret
iterator_is_csrrwi_false:
movb $1, %al
ret

iterator_is_div:
cmpq $3, iterator_token_size
jne iterator_is_div_false
movq iterator_current_character, %rax
cmpb $100, (%rax)
jne iterator_is_div_false
cmpb $105, 1(%rax)
jne iterator_is_div_false
cmpb $118, 2(%rax)
jne iterator_is_div_false
xorb %al, %al
ret
iterator_is_div_false:
movb $1, %al
ret

iterator_is_divu:
cmpq $4, iterator_token_size
jne iterator_is_divu_false
movq iterator_current_character, %rax
cmpb $100, (%rax)
jne iterator_is_divu_false
cmpb $105, 1(%rax)
jne iterator_is_divu_false
cmpb $118, 2(%rax)
jne iterator_is_divu_false
cmpb $117, 3(%rax)
jne iterator_is_divu_false
xorb %al, %al
ret
iterator_is_divu_false:
movb $1, %al
ret

iterator_is_divuw:
cmpq $5, iterator_token_size
jne iterator_is_divuw_false
movq iterator_current_character, %rax
cmpb $100, (%rax)
jne iterator_is_divuw_false
cmpb $105, 1(%rax)
jne iterator_is_divuw_false
cmpb $118, 2(%rax)
jne iterator_is_divuw_false
cmpb $117, 3(%rax)
jne iterator_is_divuw_false
cmpb $119, 4(%rax)
jne iterator_is_divuw_false
xorb %al, %al
ret
iterator_is_divuw_false:
movb $1, %al
ret

iterator_is_divw:
cmpq $4, iterator_token_size
jne iterator_is_divw_false
movq iterator_current_character, %rax
cmpb $100, (%rax)
jne iterator_is_divw_false
cmpb $105, 1(%rax)
jne iterator_is_divw_false
cmpb $118, 2(%rax)
jne iterator_is_divw_false
cmpb $119, 3(%rax)
jne iterator_is_divw_false
xorb %al, %al
ret
iterator_is_divw_false:
movb $1, %al
ret

iterator_is_ebreak:
cmpq $6, iterator_token_size
jne iterator_is_ebreak_false
movq iterator_current_character, %rax
cmpb $101, (%rax)
jne iterator_is_ebreak_false
cmpb $98, 1(%rax)
jne iterator_is_ebreak_false
cmpb $114, 2(%rax)
jne iterator_is_ebreak_false
cmpb $101, 3(%rax)
jne iterator_is_ebreak_false
cmpb $97, 4(%rax)
jne iterator_is_ebreak_false
cmpb $107, 5(%rax)
jne iterator_is_ebreak_false
xorb %al, %al
ret
iterator_is_ebreak_false:
movb $1, %al
ret

iterator_is_ecall:
cmpq $5, iterator_token_size
jne iterator_is_ecall_false
movq iterator_current_character, %rax
cmpb $101, (%rax)
jne iterator_is_ecall_false
cmpb $99, 1(%rax)
jne iterator_is_ecall_false
cmpb $97, 2(%rax)
jne iterator_is_ecall_false
cmpb $108, 3(%rax)
jne iterator_is_ecall_false
cmpb $108, 4(%rax)
jne iterator_is_ecall_false
xorb %al, %al
ret
iterator_is_ecall_false:
movb $1, %al
ret

iterator_is_faddddyn:
cmpq $8, iterator_token_size
jne iterator_is_faddddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddddyn_false
cmpb $97, 1(%rax)
jne iterator_is_faddddyn_false
cmpb $100, 2(%rax)
jne iterator_is_faddddyn_false
cmpb $100, 3(%rax)
jne iterator_is_faddddyn_false
cmpb $100, 4(%rax)
jne iterator_is_faddddyn_false
cmpb $100, 5(%rax)
jne iterator_is_faddddyn_false
cmpb $121, 6(%rax)
jne iterator_is_faddddyn_false
cmpb $110, 7(%rax)
jne iterator_is_faddddyn_false
xorb %al, %al
ret
iterator_is_faddddyn_false:
movb $1, %al
ret

iterator_is_fadddrdn:
cmpq $8, iterator_token_size
jne iterator_is_fadddrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fadddrdn_false
cmpb $97, 1(%rax)
jne iterator_is_fadddrdn_false
cmpb $100, 2(%rax)
jne iterator_is_fadddrdn_false
cmpb $100, 3(%rax)
jne iterator_is_fadddrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fadddrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fadddrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fadddrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fadddrdn_false
xorb %al, %al
ret
iterator_is_fadddrdn_false:
movb $1, %al
ret

iterator_is_fadddrmm:
cmpq $8, iterator_token_size
jne iterator_is_fadddrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fadddrmm_false
cmpb $97, 1(%rax)
jne iterator_is_fadddrmm_false
cmpb $100, 2(%rax)
jne iterator_is_fadddrmm_false
cmpb $100, 3(%rax)
jne iterator_is_fadddrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fadddrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fadddrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fadddrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fadddrmm_false
xorb %al, %al
ret
iterator_is_fadddrmm_false:
movb $1, %al
ret

iterator_is_fadddrne:
cmpq $8, iterator_token_size
jne iterator_is_fadddrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fadddrne_false
cmpb $97, 1(%rax)
jne iterator_is_fadddrne_false
cmpb $100, 2(%rax)
jne iterator_is_fadddrne_false
cmpb $100, 3(%rax)
jne iterator_is_fadddrne_false
cmpb $100, 4(%rax)
jne iterator_is_fadddrne_false
cmpb $114, 5(%rax)
jne iterator_is_fadddrne_false
cmpb $110, 6(%rax)
jne iterator_is_fadddrne_false
cmpb $101, 7(%rax)
jne iterator_is_fadddrne_false
xorb %al, %al
ret
iterator_is_fadddrne_false:
movb $1, %al
ret

iterator_is_fadddrtz:
cmpq $8, iterator_token_size
jne iterator_is_fadddrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fadddrtz_false
cmpb $97, 1(%rax)
jne iterator_is_fadddrtz_false
cmpb $100, 2(%rax)
jne iterator_is_fadddrtz_false
cmpb $100, 3(%rax)
jne iterator_is_fadddrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fadddrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fadddrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fadddrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fadddrtz_false
xorb %al, %al
ret
iterator_is_fadddrtz_false:
movb $1, %al
ret

iterator_is_fadddrup:
cmpq $8, iterator_token_size
jne iterator_is_fadddrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fadddrup_false
cmpb $97, 1(%rax)
jne iterator_is_fadddrup_false
cmpb $100, 2(%rax)
jne iterator_is_fadddrup_false
cmpb $100, 3(%rax)
jne iterator_is_fadddrup_false
cmpb $100, 4(%rax)
jne iterator_is_fadddrup_false
cmpb $114, 5(%rax)
jne iterator_is_fadddrup_false
cmpb $117, 6(%rax)
jne iterator_is_fadddrup_false
cmpb $112, 7(%rax)
jne iterator_is_fadddrup_false
xorb %al, %al
ret
iterator_is_fadddrup_false:
movb $1, %al
ret

iterator_is_faddqdyn:
cmpq $8, iterator_token_size
jne iterator_is_faddqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddqdyn_false
cmpb $97, 1(%rax)
jne iterator_is_faddqdyn_false
cmpb $100, 2(%rax)
jne iterator_is_faddqdyn_false
cmpb $100, 3(%rax)
jne iterator_is_faddqdyn_false
cmpb $113, 4(%rax)
jne iterator_is_faddqdyn_false
cmpb $100, 5(%rax)
jne iterator_is_faddqdyn_false
cmpb $121, 6(%rax)
jne iterator_is_faddqdyn_false
cmpb $110, 7(%rax)
jne iterator_is_faddqdyn_false
xorb %al, %al
ret
iterator_is_faddqdyn_false:
movb $1, %al
ret

iterator_is_faddqrdn:
cmpq $8, iterator_token_size
jne iterator_is_faddqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddqrdn_false
cmpb $97, 1(%rax)
jne iterator_is_faddqrdn_false
cmpb $100, 2(%rax)
jne iterator_is_faddqrdn_false
cmpb $100, 3(%rax)
jne iterator_is_faddqrdn_false
cmpb $113, 4(%rax)
jne iterator_is_faddqrdn_false
cmpb $114, 5(%rax)
jne iterator_is_faddqrdn_false
cmpb $100, 6(%rax)
jne iterator_is_faddqrdn_false
cmpb $110, 7(%rax)
jne iterator_is_faddqrdn_false
xorb %al, %al
ret
iterator_is_faddqrdn_false:
movb $1, %al
ret

iterator_is_faddqrmm:
cmpq $8, iterator_token_size
jne iterator_is_faddqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddqrmm_false
cmpb $97, 1(%rax)
jne iterator_is_faddqrmm_false
cmpb $100, 2(%rax)
jne iterator_is_faddqrmm_false
cmpb $100, 3(%rax)
jne iterator_is_faddqrmm_false
cmpb $113, 4(%rax)
jne iterator_is_faddqrmm_false
cmpb $114, 5(%rax)
jne iterator_is_faddqrmm_false
cmpb $109, 6(%rax)
jne iterator_is_faddqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_faddqrmm_false
xorb %al, %al
ret
iterator_is_faddqrmm_false:
movb $1, %al
ret

iterator_is_faddqrne:
cmpq $8, iterator_token_size
jne iterator_is_faddqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddqrne_false
cmpb $97, 1(%rax)
jne iterator_is_faddqrne_false
cmpb $100, 2(%rax)
jne iterator_is_faddqrne_false
cmpb $100, 3(%rax)
jne iterator_is_faddqrne_false
cmpb $113, 4(%rax)
jne iterator_is_faddqrne_false
cmpb $114, 5(%rax)
jne iterator_is_faddqrne_false
cmpb $110, 6(%rax)
jne iterator_is_faddqrne_false
cmpb $101, 7(%rax)
jne iterator_is_faddqrne_false
xorb %al, %al
ret
iterator_is_faddqrne_false:
movb $1, %al
ret

iterator_is_faddqrtz:
cmpq $8, iterator_token_size
jne iterator_is_faddqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddqrtz_false
cmpb $97, 1(%rax)
jne iterator_is_faddqrtz_false
cmpb $100, 2(%rax)
jne iterator_is_faddqrtz_false
cmpb $100, 3(%rax)
jne iterator_is_faddqrtz_false
cmpb $113, 4(%rax)
jne iterator_is_faddqrtz_false
cmpb $114, 5(%rax)
jne iterator_is_faddqrtz_false
cmpb $116, 6(%rax)
jne iterator_is_faddqrtz_false
cmpb $122, 7(%rax)
jne iterator_is_faddqrtz_false
xorb %al, %al
ret
iterator_is_faddqrtz_false:
movb $1, %al
ret

iterator_is_faddqrup:
cmpq $8, iterator_token_size
jne iterator_is_faddqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddqrup_false
cmpb $97, 1(%rax)
jne iterator_is_faddqrup_false
cmpb $100, 2(%rax)
jne iterator_is_faddqrup_false
cmpb $100, 3(%rax)
jne iterator_is_faddqrup_false
cmpb $113, 4(%rax)
jne iterator_is_faddqrup_false
cmpb $114, 5(%rax)
jne iterator_is_faddqrup_false
cmpb $117, 6(%rax)
jne iterator_is_faddqrup_false
cmpb $112, 7(%rax)
jne iterator_is_faddqrup_false
xorb %al, %al
ret
iterator_is_faddqrup_false:
movb $1, %al
ret

iterator_is_faddsdyn:
cmpq $8, iterator_token_size
jne iterator_is_faddsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddsdyn_false
cmpb $97, 1(%rax)
jne iterator_is_faddsdyn_false
cmpb $100, 2(%rax)
jne iterator_is_faddsdyn_false
cmpb $100, 3(%rax)
jne iterator_is_faddsdyn_false
cmpb $115, 4(%rax)
jne iterator_is_faddsdyn_false
cmpb $100, 5(%rax)
jne iterator_is_faddsdyn_false
cmpb $121, 6(%rax)
jne iterator_is_faddsdyn_false
cmpb $110, 7(%rax)
jne iterator_is_faddsdyn_false
xorb %al, %al
ret
iterator_is_faddsdyn_false:
movb $1, %al
ret

iterator_is_faddsrdn:
cmpq $8, iterator_token_size
jne iterator_is_faddsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddsrdn_false
cmpb $97, 1(%rax)
jne iterator_is_faddsrdn_false
cmpb $100, 2(%rax)
jne iterator_is_faddsrdn_false
cmpb $100, 3(%rax)
jne iterator_is_faddsrdn_false
cmpb $115, 4(%rax)
jne iterator_is_faddsrdn_false
cmpb $114, 5(%rax)
jne iterator_is_faddsrdn_false
cmpb $100, 6(%rax)
jne iterator_is_faddsrdn_false
cmpb $110, 7(%rax)
jne iterator_is_faddsrdn_false
xorb %al, %al
ret
iterator_is_faddsrdn_false:
movb $1, %al
ret

iterator_is_faddsrmm:
cmpq $8, iterator_token_size
jne iterator_is_faddsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddsrmm_false
cmpb $97, 1(%rax)
jne iterator_is_faddsrmm_false
cmpb $100, 2(%rax)
jne iterator_is_faddsrmm_false
cmpb $100, 3(%rax)
jne iterator_is_faddsrmm_false
cmpb $115, 4(%rax)
jne iterator_is_faddsrmm_false
cmpb $114, 5(%rax)
jne iterator_is_faddsrmm_false
cmpb $109, 6(%rax)
jne iterator_is_faddsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_faddsrmm_false
xorb %al, %al
ret
iterator_is_faddsrmm_false:
movb $1, %al
ret

iterator_is_faddsrne:
cmpq $8, iterator_token_size
jne iterator_is_faddsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddsrne_false
cmpb $97, 1(%rax)
jne iterator_is_faddsrne_false
cmpb $100, 2(%rax)
jne iterator_is_faddsrne_false
cmpb $100, 3(%rax)
jne iterator_is_faddsrne_false
cmpb $115, 4(%rax)
jne iterator_is_faddsrne_false
cmpb $114, 5(%rax)
jne iterator_is_faddsrne_false
cmpb $110, 6(%rax)
jne iterator_is_faddsrne_false
cmpb $101, 7(%rax)
jne iterator_is_faddsrne_false
xorb %al, %al
ret
iterator_is_faddsrne_false:
movb $1, %al
ret

iterator_is_faddsrtz:
cmpq $8, iterator_token_size
jne iterator_is_faddsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddsrtz_false
cmpb $97, 1(%rax)
jne iterator_is_faddsrtz_false
cmpb $100, 2(%rax)
jne iterator_is_faddsrtz_false
cmpb $100, 3(%rax)
jne iterator_is_faddsrtz_false
cmpb $115, 4(%rax)
jne iterator_is_faddsrtz_false
cmpb $114, 5(%rax)
jne iterator_is_faddsrtz_false
cmpb $116, 6(%rax)
jne iterator_is_faddsrtz_false
cmpb $122, 7(%rax)
jne iterator_is_faddsrtz_false
xorb %al, %al
ret
iterator_is_faddsrtz_false:
movb $1, %al
ret

iterator_is_faddsrup:
cmpq $8, iterator_token_size
jne iterator_is_faddsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_faddsrup_false
cmpb $97, 1(%rax)
jne iterator_is_faddsrup_false
cmpb $100, 2(%rax)
jne iterator_is_faddsrup_false
cmpb $100, 3(%rax)
jne iterator_is_faddsrup_false
cmpb $115, 4(%rax)
jne iterator_is_faddsrup_false
cmpb $114, 5(%rax)
jne iterator_is_faddsrup_false
cmpb $117, 6(%rax)
jne iterator_is_faddsrup_false
cmpb $112, 7(%rax)
jne iterator_is_faddsrup_false
xorb %al, %al
ret
iterator_is_faddsrup_false:
movb $1, %al
ret

iterator_is_fclassd:
cmpq $7, iterator_token_size
jne iterator_is_fclassd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fclassd_false
cmpb $99, 1(%rax)
jne iterator_is_fclassd_false
cmpb $108, 2(%rax)
jne iterator_is_fclassd_false
cmpb $97, 3(%rax)
jne iterator_is_fclassd_false
cmpb $115, 4(%rax)
jne iterator_is_fclassd_false
cmpb $115, 5(%rax)
jne iterator_is_fclassd_false
cmpb $100, 6(%rax)
jne iterator_is_fclassd_false
xorb %al, %al
ret
iterator_is_fclassd_false:
movb $1, %al
ret

iterator_is_fclassq:
cmpq $7, iterator_token_size
jne iterator_is_fclassq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fclassq_false
cmpb $99, 1(%rax)
jne iterator_is_fclassq_false
cmpb $108, 2(%rax)
jne iterator_is_fclassq_false
cmpb $97, 3(%rax)
jne iterator_is_fclassq_false
cmpb $115, 4(%rax)
jne iterator_is_fclassq_false
cmpb $115, 5(%rax)
jne iterator_is_fclassq_false
cmpb $113, 6(%rax)
jne iterator_is_fclassq_false
xorb %al, %al
ret
iterator_is_fclassq_false:
movb $1, %al
ret

iterator_is_fclasss:
cmpq $7, iterator_token_size
jne iterator_is_fclasss_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fclasss_false
cmpb $99, 1(%rax)
jne iterator_is_fclasss_false
cmpb $108, 2(%rax)
jne iterator_is_fclasss_false
cmpb $97, 3(%rax)
jne iterator_is_fclasss_false
cmpb $115, 4(%rax)
jne iterator_is_fclasss_false
cmpb $115, 5(%rax)
jne iterator_is_fclasss_false
cmpb $115, 6(%rax)
jne iterator_is_fclasss_false
xorb %al, %al
ret
iterator_is_fclasss_false:
movb $1, %al
ret

iterator_is_fcvtdldyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdldyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdldyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdldyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdldyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdldyn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdldyn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdldyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtdldyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtdldyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdldyn_false
xorb %al, %al
ret
iterator_is_fcvtdldyn_false:
movb $1, %al
ret

iterator_is_fcvtdlrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdlrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtdlrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdlrdn_false
xorb %al, %al
ret
iterator_is_fcvtdlrdn_false:
movb $1, %al
ret

iterator_is_fcvtdlrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdlrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtdlrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtdlrmm_false
xorb %al, %al
ret
iterator_is_fcvtdlrmm_false:
movb $1, %al
ret

iterator_is_fcvtdlrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdlrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlrne_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlrne_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdlrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtdlrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtdlrne_false
xorb %al, %al
ret
iterator_is_fcvtdlrne_false:
movb $1, %al
ret

iterator_is_fcvtdlrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdlrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtdlrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtdlrtz_false
xorb %al, %al
ret
iterator_is_fcvtdlrtz_false:
movb $1, %al
ret

iterator_is_fcvtdlrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdlrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlrup_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlrup_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdlrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtdlrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtdlrup_false
xorb %al, %al
ret
iterator_is_fcvtdlrup_false:
movb $1, %al
ret

iterator_is_fcvtdludyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdludyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdludyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtdludyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtdludyn_false
xorb %al, %al
ret
iterator_is_fcvtdludyn_false:
movb $1, %al
ret

iterator_is_fcvtdlurdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdlurdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtdlurdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtdlurdn_false
xorb %al, %al
ret
iterator_is_fcvtdlurdn_false:
movb $1, %al
ret

iterator_is_fcvtdlurmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdlurmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtdlurmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtdlurmm_false
xorb %al, %al
ret
iterator_is_fcvtdlurmm_false:
movb $1, %al
ret

iterator_is_fcvtdlurne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdlurne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlurne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdlurne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtdlurne_false
xorb %al, %al
ret
iterator_is_fcvtdlurne_false:
movb $1, %al
ret

iterator_is_fcvtdlurtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdlurtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtdlurtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtdlurtz_false
xorb %al, %al
ret
iterator_is_fcvtdlurtz_false:
movb $1, %al
ret

iterator_is_fcvtdlurup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdlurup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdlurup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtdlurup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtdlurup_false
xorb %al, %al
ret
iterator_is_fcvtdlurup_false:
movb $1, %al
ret

iterator_is_fcvtdqdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtdqdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdqdyn_false
xorb %al, %al
ret
iterator_is_fcvtdqdyn_false:
movb $1, %al
ret

iterator_is_fcvtdqrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtdqrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdqrdn_false
xorb %al, %al
ret
iterator_is_fcvtdqrdn_false:
movb $1, %al
ret

iterator_is_fcvtdqrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtdqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtdqrmm_false
xorb %al, %al
ret
iterator_is_fcvtdqrmm_false:
movb $1, %al
ret

iterator_is_fcvtdqrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdqrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdqrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdqrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdqrne_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdqrne_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtdqrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdqrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtdqrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtdqrne_false
xorb %al, %al
ret
iterator_is_fcvtdqrne_false:
movb $1, %al
ret

iterator_is_fcvtdqrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtdqrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtdqrtz_false
xorb %al, %al
ret
iterator_is_fcvtdqrtz_false:
movb $1, %al
ret

iterator_is_fcvtdqrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdqrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdqrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdqrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdqrup_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdqrup_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtdqrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdqrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtdqrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtdqrup_false
xorb %al, %al
ret
iterator_is_fcvtdqrup_false:
movb $1, %al
ret

iterator_is_fcvtds:
cmpq $6, iterator_token_size
jne iterator_is_fcvtds_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtds_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtds_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtds_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtds_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtds_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtds_false
xorb %al, %al
ret
iterator_is_fcvtds_false:
movb $1, %al
ret

iterator_is_fcvtdwdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdwdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtdwdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdwdyn_false
xorb %al, %al
ret
iterator_is_fcvtdwdyn_false:
movb $1, %al
ret

iterator_is_fcvtdwrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdwrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtdwrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdwrdn_false
xorb %al, %al
ret
iterator_is_fcvtdwrdn_false:
movb $1, %al
ret

iterator_is_fcvtdwrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdwrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtdwrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtdwrmm_false
xorb %al, %al
ret
iterator_is_fcvtdwrmm_false:
movb $1, %al
ret

iterator_is_fcvtdwrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdwrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwrne_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwrne_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdwrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtdwrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtdwrne_false
xorb %al, %al
ret
iterator_is_fcvtdwrne_false:
movb $1, %al
ret

iterator_is_fcvtdwrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdwrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtdwrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtdwrtz_false
xorb %al, %al
ret
iterator_is_fcvtdwrtz_false:
movb $1, %al
ret

iterator_is_fcvtdwrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtdwrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwrup_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwrup_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtdwrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtdwrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtdwrup_false
xorb %al, %al
ret
iterator_is_fcvtdwrup_false:
movb $1, %al
ret

iterator_is_fcvtdwudyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdwudyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtdwudyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtdwudyn_false
xorb %al, %al
ret
iterator_is_fcvtdwudyn_false:
movb $1, %al
ret

iterator_is_fcvtdwurdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdwurdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtdwurdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtdwurdn_false
xorb %al, %al
ret
iterator_is_fcvtdwurdn_false:
movb $1, %al
ret

iterator_is_fcvtdwurmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdwurmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtdwurmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtdwurmm_false
xorb %al, %al
ret
iterator_is_fcvtdwurmm_false:
movb $1, %al
ret

iterator_is_fcvtdwurne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdwurne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwurne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtdwurne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtdwurne_false
xorb %al, %al
ret
iterator_is_fcvtdwurne_false:
movb $1, %al
ret

iterator_is_fcvtdwurtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdwurtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtdwurtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtdwurtz_false
xorb %al, %al
ret
iterator_is_fcvtdwurtz_false:
movb $1, %al
ret

iterator_is_fcvtdwurup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtdwurup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtdwurup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $100, 4(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtdwurup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtdwurup_false
xorb %al, %al
ret
iterator_is_fcvtdwurup_false:
movb $1, %al
ret

iterator_is_fcvtlddyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlddyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlddyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlddyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlddyn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtlddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtlddyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtlddyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtlddyn_false
xorb %al, %al
ret
iterator_is_fcvtlddyn_false:
movb $1, %al
ret

iterator_is_fcvtldrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtldrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtldrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtldrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtldrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtldrdn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtldrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtldrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtldrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtldrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtldrdn_false
xorb %al, %al
ret
iterator_is_fcvtldrdn_false:
movb $1, %al
ret

iterator_is_fcvtldrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtldrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtldrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtldrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtldrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtldrmm_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtldrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtldrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtldrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtldrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtldrmm_false
xorb %al, %al
ret
iterator_is_fcvtldrmm_false:
movb $1, %al
ret

iterator_is_fcvtldrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtldrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtldrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtldrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtldrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtldrne_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtldrne_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtldrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtldrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtldrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtldrne_false
xorb %al, %al
ret
iterator_is_fcvtldrne_false:
movb $1, %al
ret

iterator_is_fcvtldrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtldrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtldrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtldrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtldrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtldrtz_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtldrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtldrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtldrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtldrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtldrtz_false
xorb %al, %al
ret
iterator_is_fcvtldrtz_false:
movb $1, %al
ret

iterator_is_fcvtldrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtldrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtldrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtldrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtldrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtldrup_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtldrup_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtldrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtldrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtldrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtldrup_false
xorb %al, %al
ret
iterator_is_fcvtldrup_false:
movb $1, %al
ret

iterator_is_fcvtlqdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtlqdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtlqdyn_false
xorb %al, %al
ret
iterator_is_fcvtlqdyn_false:
movb $1, %al
ret

iterator_is_fcvtlqrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtlqrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtlqrdn_false
xorb %al, %al
ret
iterator_is_fcvtlqrdn_false:
movb $1, %al
ret

iterator_is_fcvtlqrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtlqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtlqrmm_false
xorb %al, %al
ret
iterator_is_fcvtlqrmm_false:
movb $1, %al
ret

iterator_is_fcvtlqrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlqrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlqrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlqrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlqrne_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlqrne_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtlqrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlqrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtlqrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtlqrne_false
xorb %al, %al
ret
iterator_is_fcvtlqrne_false:
movb $1, %al
ret

iterator_is_fcvtlqrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtlqrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtlqrtz_false
xorb %al, %al
ret
iterator_is_fcvtlqrtz_false:
movb $1, %al
ret

iterator_is_fcvtlqrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlqrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlqrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlqrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlqrup_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlqrup_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtlqrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlqrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtlqrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtlqrup_false
xorb %al, %al
ret
iterator_is_fcvtlqrup_false:
movb $1, %al
ret

iterator_is_fcvtlsdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtlsdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtlsdyn_false
xorb %al, %al
ret
iterator_is_fcvtlsdyn_false:
movb $1, %al
ret

iterator_is_fcvtlsrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtlsrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtlsrdn_false
xorb %al, %al
ret
iterator_is_fcvtlsrdn_false:
movb $1, %al
ret

iterator_is_fcvtlsrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtlsrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtlsrmm_false
xorb %al, %al
ret
iterator_is_fcvtlsrmm_false:
movb $1, %al
ret

iterator_is_fcvtlsrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlsrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlsrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlsrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlsrne_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlsrne_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtlsrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlsrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtlsrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtlsrne_false
xorb %al, %al
ret
iterator_is_fcvtlsrne_false:
movb $1, %al
ret

iterator_is_fcvtlsrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtlsrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtlsrtz_false
xorb %al, %al
ret
iterator_is_fcvtlsrtz_false:
movb $1, %al
ret

iterator_is_fcvtlsrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtlsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlsrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlsrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlsrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlsrup_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlsrup_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtlsrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtlsrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtlsrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtlsrup_false
xorb %al, %al
ret
iterator_is_fcvtlsrup_false:
movb $1, %al
ret

iterator_is_fcvtluddyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtluddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtluddyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtluddyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtluddyn_false
xorb %al, %al
ret
iterator_is_fcvtluddyn_false:
movb $1, %al
ret

iterator_is_fcvtludrdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtludrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtludrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtludrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtludrdn_false
xorb %al, %al
ret
iterator_is_fcvtludrdn_false:
movb $1, %al
ret

iterator_is_fcvtludrmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtludrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtludrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtludrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtludrmm_false
xorb %al, %al
ret
iterator_is_fcvtludrmm_false:
movb $1, %al
ret

iterator_is_fcvtludrne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtludrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtludrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtludrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtludrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtludrne_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtludrne_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtludrne_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtludrne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtludrne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtludrne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtludrne_false
xorb %al, %al
ret
iterator_is_fcvtludrne_false:
movb $1, %al
ret

iterator_is_fcvtludrtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtludrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtludrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtludrtz_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtludrtz_false
xorb %al, %al
ret
iterator_is_fcvtludrtz_false:
movb $1, %al
ret

iterator_is_fcvtludrup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtludrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtludrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtludrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtludrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtludrup_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtludrup_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtludrup_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtludrup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtludrup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtludrup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtludrup_false
xorb %al, %al
ret
iterator_is_fcvtludrup_false:
movb $1, %al
ret

iterator_is_fcvtluqdyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtluqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtluqdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtluqdyn_false
xorb %al, %al
ret
iterator_is_fcvtluqdyn_false:
movb $1, %al
ret

iterator_is_fcvtluqrdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtluqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtluqrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtluqrdn_false
xorb %al, %al
ret
iterator_is_fcvtluqrdn_false:
movb $1, %al
ret

iterator_is_fcvtluqrmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtluqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtluqrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtluqrmm_false
xorb %al, %al
ret
iterator_is_fcvtluqrmm_false:
movb $1, %al
ret

iterator_is_fcvtluqrne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtluqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtluqrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtluqrne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtluqrne_false
xorb %al, %al
ret
iterator_is_fcvtluqrne_false:
movb $1, %al
ret

iterator_is_fcvtluqrtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtluqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtluqrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtluqrtz_false
xorb %al, %al
ret
iterator_is_fcvtluqrtz_false:
movb $1, %al
ret

iterator_is_fcvtluqrup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtluqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtluqrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtluqrup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtluqrup_false
xorb %al, %al
ret
iterator_is_fcvtluqrup_false:
movb $1, %al
ret

iterator_is_fcvtlusdyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtlusdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtlusdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtlusdyn_false
xorb %al, %al
ret
iterator_is_fcvtlusdyn_false:
movb $1, %al
ret

iterator_is_fcvtlusrdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtlusrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtlusrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtlusrdn_false
xorb %al, %al
ret
iterator_is_fcvtlusrdn_false:
movb $1, %al
ret

iterator_is_fcvtlusrmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtlusrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtlusrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtlusrmm_false
xorb %al, %al
ret
iterator_is_fcvtlusrmm_false:
movb $1, %al
ret

iterator_is_fcvtlusrne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtlusrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlusrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtlusrne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtlusrne_false
xorb %al, %al
ret
iterator_is_fcvtlusrne_false:
movb $1, %al
ret

iterator_is_fcvtlusrtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtlusrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtlusrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtlusrtz_false
xorb %al, %al
ret
iterator_is_fcvtlusrtz_false:
movb $1, %al
ret

iterator_is_fcvtlusrup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtlusrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtlusrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $108, 4(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtlusrup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtlusrup_false
xorb %al, %al
ret
iterator_is_fcvtlusrup_false:
movb $1, %al
ret

iterator_is_fcvtqd:
cmpq $6, iterator_token_size
jne iterator_is_fcvtqd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqd_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqd_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqd_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqd_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqd_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtqd_false
xorb %al, %al
ret
iterator_is_fcvtqd_false:
movb $1, %al
ret

iterator_is_fcvtqldyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqldyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqldyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqldyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqldyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqldyn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqldyn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqldyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtqldyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtqldyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtqldyn_false
xorb %al, %al
ret
iterator_is_fcvtqldyn_false:
movb $1, %al
ret

iterator_is_fcvtqlrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqlrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtqlrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtqlrdn_false
xorb %al, %al
ret
iterator_is_fcvtqlrdn_false:
movb $1, %al
ret

iterator_is_fcvtqlrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqlrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtqlrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtqlrmm_false
xorb %al, %al
ret
iterator_is_fcvtqlrmm_false:
movb $1, %al
ret

iterator_is_fcvtqlrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqlrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlrne_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlrne_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqlrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtqlrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtqlrne_false
xorb %al, %al
ret
iterator_is_fcvtqlrne_false:
movb $1, %al
ret

iterator_is_fcvtqlrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqlrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtqlrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtqlrtz_false
xorb %al, %al
ret
iterator_is_fcvtqlrtz_false:
movb $1, %al
ret

iterator_is_fcvtqlrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqlrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlrup_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlrup_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqlrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtqlrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtqlrup_false
xorb %al, %al
ret
iterator_is_fcvtqlrup_false:
movb $1, %al
ret

iterator_is_fcvtqludyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqludyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqludyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtqludyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtqludyn_false
xorb %al, %al
ret
iterator_is_fcvtqludyn_false:
movb $1, %al
ret

iterator_is_fcvtqlurdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqlurdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtqlurdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtqlurdn_false
xorb %al, %al
ret
iterator_is_fcvtqlurdn_false:
movb $1, %al
ret

iterator_is_fcvtqlurmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqlurmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtqlurmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtqlurmm_false
xorb %al, %al
ret
iterator_is_fcvtqlurmm_false:
movb $1, %al
ret

iterator_is_fcvtqlurne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqlurne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlurne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtqlurne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtqlurne_false
xorb %al, %al
ret
iterator_is_fcvtqlurne_false:
movb $1, %al
ret

iterator_is_fcvtqlurtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqlurtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtqlurtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtqlurtz_false
xorb %al, %al
ret
iterator_is_fcvtqlurtz_false:
movb $1, %al
ret

iterator_is_fcvtqlurup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqlurup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqlurup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtqlurup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtqlurup_false
xorb %al, %al
ret
iterator_is_fcvtqlurup_false:
movb $1, %al
ret

iterator_is_fcvtqs:
cmpq $6, iterator_token_size
jne iterator_is_fcvtqs_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqs_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqs_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqs_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqs_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqs_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtqs_false
xorb %al, %al
ret
iterator_is_fcvtqs_false:
movb $1, %al
ret

iterator_is_fcvtqwdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqwdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtqwdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtqwdyn_false
xorb %al, %al
ret
iterator_is_fcvtqwdyn_false:
movb $1, %al
ret

iterator_is_fcvtqwrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqwrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtqwrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtqwrdn_false
xorb %al, %al
ret
iterator_is_fcvtqwrdn_false:
movb $1, %al
ret

iterator_is_fcvtqwrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqwrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtqwrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtqwrmm_false
xorb %al, %al
ret
iterator_is_fcvtqwrmm_false:
movb $1, %al
ret

iterator_is_fcvtqwrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqwrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwrne_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwrne_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqwrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtqwrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtqwrne_false
xorb %al, %al
ret
iterator_is_fcvtqwrne_false:
movb $1, %al
ret

iterator_is_fcvtqwrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqwrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtqwrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtqwrtz_false
xorb %al, %al
ret
iterator_is_fcvtqwrtz_false:
movb $1, %al
ret

iterator_is_fcvtqwrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtqwrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwrup_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwrup_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtqwrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtqwrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtqwrup_false
xorb %al, %al
ret
iterator_is_fcvtqwrup_false:
movb $1, %al
ret

iterator_is_fcvtqwudyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqwudyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtqwudyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtqwudyn_false
xorb %al, %al
ret
iterator_is_fcvtqwudyn_false:
movb $1, %al
ret

iterator_is_fcvtqwurdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqwurdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtqwurdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtqwurdn_false
xorb %al, %al
ret
iterator_is_fcvtqwurdn_false:
movb $1, %al
ret

iterator_is_fcvtqwurmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqwurmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtqwurmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtqwurmm_false
xorb %al, %al
ret
iterator_is_fcvtqwurmm_false:
movb $1, %al
ret

iterator_is_fcvtqwurne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqwurne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwurne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtqwurne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtqwurne_false
xorb %al, %al
ret
iterator_is_fcvtqwurne_false:
movb $1, %al
ret

iterator_is_fcvtqwurtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqwurtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtqwurtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtqwurtz_false
xorb %al, %al
ret
iterator_is_fcvtqwurtz_false:
movb $1, %al
ret

iterator_is_fcvtqwurup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtqwurup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtqwurup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $113, 4(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtqwurup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtqwurup_false
xorb %al, %al
ret
iterator_is_fcvtqwurup_false:
movb $1, %al
ret

iterator_is_fcvtsddyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsddyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsddyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsddyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsddyn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtsddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtsddyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtsddyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtsddyn_false
xorb %al, %al
ret
iterator_is_fcvtsddyn_false:
movb $1, %al
ret

iterator_is_fcvtsdrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsdrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtsdrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtsdrdn_false
xorb %al, %al
ret
iterator_is_fcvtsdrdn_false:
movb $1, %al
ret

iterator_is_fcvtsdrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsdrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtsdrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtsdrmm_false
xorb %al, %al
ret
iterator_is_fcvtsdrmm_false:
movb $1, %al
ret

iterator_is_fcvtsdrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsdrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsdrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsdrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsdrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsdrne_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsdrne_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtsdrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsdrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtsdrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtsdrne_false
xorb %al, %al
ret
iterator_is_fcvtsdrne_false:
movb $1, %al
ret

iterator_is_fcvtsdrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsdrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtsdrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtsdrtz_false
xorb %al, %al
ret
iterator_is_fcvtsdrtz_false:
movb $1, %al
ret

iterator_is_fcvtsdrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsdrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsdrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsdrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsdrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsdrup_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsdrup_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtsdrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsdrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtsdrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtsdrup_false
xorb %al, %al
ret
iterator_is_fcvtsdrup_false:
movb $1, %al
ret

iterator_is_fcvtsldyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsldyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsldyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsldyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsldyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsldyn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsldyn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtsldyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtsldyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtsldyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtsldyn_false
xorb %al, %al
ret
iterator_is_fcvtsldyn_false:
movb $1, %al
ret

iterator_is_fcvtslrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtslrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslrdn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslrdn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtslrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtslrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtslrdn_false
xorb %al, %al
ret
iterator_is_fcvtslrdn_false:
movb $1, %al
ret

iterator_is_fcvtslrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtslrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslrmm_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslrmm_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtslrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtslrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtslrmm_false
xorb %al, %al
ret
iterator_is_fcvtslrmm_false:
movb $1, %al
ret

iterator_is_fcvtslrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtslrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslrne_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslrne_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtslrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtslrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtslrne_false
xorb %al, %al
ret
iterator_is_fcvtslrne_false:
movb $1, %al
ret

iterator_is_fcvtslrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtslrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslrtz_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslrtz_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtslrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtslrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtslrtz_false
xorb %al, %al
ret
iterator_is_fcvtslrtz_false:
movb $1, %al
ret

iterator_is_fcvtslrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtslrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslrup_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslrup_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtslrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtslrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtslrup_false
xorb %al, %al
ret
iterator_is_fcvtslrup_false:
movb $1, %al
ret

iterator_is_fcvtsludyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtsludyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsludyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtsludyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtsludyn_false
xorb %al, %al
ret
iterator_is_fcvtsludyn_false:
movb $1, %al
ret

iterator_is_fcvtslurdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtslurdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslurdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtslurdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtslurdn_false
xorb %al, %al
ret
iterator_is_fcvtslurdn_false:
movb $1, %al
ret

iterator_is_fcvtslurmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtslurmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslurmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtslurmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtslurmm_false
xorb %al, %al
ret
iterator_is_fcvtslurmm_false:
movb $1, %al
ret

iterator_is_fcvtslurne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtslurne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslurne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslurne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslurne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslurne_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslurne_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslurne_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtslurne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtslurne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtslurne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtslurne_false
xorb %al, %al
ret
iterator_is_fcvtslurne_false:
movb $1, %al
ret

iterator_is_fcvtslurtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtslurtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslurtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtslurtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtslurtz_false
xorb %al, %al
ret
iterator_is_fcvtslurtz_false:
movb $1, %al
ret

iterator_is_fcvtslurup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtslurup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtslurup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtslurup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtslurup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtslurup_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtslurup_false
cmpb $108, 5(%rax)
jne iterator_is_fcvtslurup_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtslurup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtslurup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtslurup_false
xorb %al, %al
ret
iterator_is_fcvtslurup_false:
movb $1, %al
ret

iterator_is_fcvtsqdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtsqdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtsqdyn_false
xorb %al, %al
ret
iterator_is_fcvtsqdyn_false:
movb $1, %al
ret

iterator_is_fcvtsqrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtsqrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtsqrdn_false
xorb %al, %al
ret
iterator_is_fcvtsqrdn_false:
movb $1, %al
ret

iterator_is_fcvtsqrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtsqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtsqrmm_false
xorb %al, %al
ret
iterator_is_fcvtsqrmm_false:
movb $1, %al
ret

iterator_is_fcvtsqrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsqrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsqrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsqrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsqrne_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsqrne_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtsqrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsqrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtsqrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtsqrne_false
xorb %al, %al
ret
iterator_is_fcvtsqrne_false:
movb $1, %al
ret

iterator_is_fcvtsqrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtsqrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtsqrtz_false
xorb %al, %al
ret
iterator_is_fcvtsqrtz_false:
movb $1, %al
ret

iterator_is_fcvtsqrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtsqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtsqrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtsqrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtsqrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtsqrup_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtsqrup_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtsqrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtsqrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtsqrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtsqrup_false
xorb %al, %al
ret
iterator_is_fcvtsqrup_false:
movb $1, %al
ret

iterator_is_fcvtswdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtswdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswdyn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswdyn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtswdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtswdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtswdyn_false
xorb %al, %al
ret
iterator_is_fcvtswdyn_false:
movb $1, %al
ret

iterator_is_fcvtswrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtswrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswrdn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswrdn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtswrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtswrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtswrdn_false
xorb %al, %al
ret
iterator_is_fcvtswrdn_false:
movb $1, %al
ret

iterator_is_fcvtswrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtswrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswrmm_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswrmm_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtswrmm_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtswrmm_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtswrmm_false
xorb %al, %al
ret
iterator_is_fcvtswrmm_false:
movb $1, %al
ret

iterator_is_fcvtswrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtswrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswrne_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswrne_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtswrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtswrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtswrne_false
xorb %al, %al
ret
iterator_is_fcvtswrne_false:
movb $1, %al
ret

iterator_is_fcvtswrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtswrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswrtz_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswrtz_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtswrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtswrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtswrtz_false
xorb %al, %al
ret
iterator_is_fcvtswrtz_false:
movb $1, %al
ret

iterator_is_fcvtswrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtswrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswrup_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswrup_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtswrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtswrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtswrup_false
xorb %al, %al
ret
iterator_is_fcvtswrup_false:
movb $1, %al
ret

iterator_is_fcvtswudyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtswudyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswudyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtswudyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtswudyn_false
xorb %al, %al
ret
iterator_is_fcvtswudyn_false:
movb $1, %al
ret

iterator_is_fcvtswurdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtswurdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswurdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtswurdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtswurdn_false
xorb %al, %al
ret
iterator_is_fcvtswurdn_false:
movb $1, %al
ret

iterator_is_fcvtswurmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtswurmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswurmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtswurmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtswurmm_false
xorb %al, %al
ret
iterator_is_fcvtswurmm_false:
movb $1, %al
ret

iterator_is_fcvtswurne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtswurne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswurne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswurne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswurne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswurne_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswurne_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswurne_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtswurne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtswurne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtswurne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtswurne_false
xorb %al, %al
ret
iterator_is_fcvtswurne_false:
movb $1, %al
ret

iterator_is_fcvtswurtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtswurtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswurtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtswurtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtswurtz_false
xorb %al, %al
ret
iterator_is_fcvtswurtz_false:
movb $1, %al
ret

iterator_is_fcvtswurup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtswurup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtswurup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtswurup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtswurup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtswurup_false
cmpb $115, 4(%rax)
jne iterator_is_fcvtswurup_false
cmpb $119, 5(%rax)
jne iterator_is_fcvtswurup_false
cmpb $117, 6(%rax)
jne iterator_is_fcvtswurup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtswurup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtswurup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtswurup_false
xorb %al, %al
ret
iterator_is_fcvtswurup_false:
movb $1, %al
ret

iterator_is_fcvtwddyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwddyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwddyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwddyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwddyn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtwddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwddyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtwddyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwddyn_false
xorb %al, %al
ret
iterator_is_fcvtwddyn_false:
movb $1, %al
ret

iterator_is_fcvtwdrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwdrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtwdrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwdrdn_false
xorb %al, %al
ret
iterator_is_fcvtwdrdn_false:
movb $1, %al
ret

iterator_is_fcvtwdrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwdrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtwdrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtwdrmm_false
xorb %al, %al
ret
iterator_is_fcvtwdrmm_false:
movb $1, %al
ret

iterator_is_fcvtwdrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwdrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwdrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwdrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwdrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwdrne_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwdrne_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtwdrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwdrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtwdrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtwdrne_false
xorb %al, %al
ret
iterator_is_fcvtwdrne_false:
movb $1, %al
ret

iterator_is_fcvtwdrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwdrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtwdrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtwdrtz_false
xorb %al, %al
ret
iterator_is_fcvtwdrtz_false:
movb $1, %al
ret

iterator_is_fcvtwdrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwdrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwdrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwdrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwdrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwdrup_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwdrup_false
cmpb $100, 5(%rax)
jne iterator_is_fcvtwdrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwdrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtwdrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtwdrup_false
xorb %al, %al
ret
iterator_is_fcvtwdrup_false:
movb $1, %al
ret

iterator_is_fcvtwqdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtwqdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwqdyn_false
xorb %al, %al
ret
iterator_is_fcvtwqdyn_false:
movb $1, %al
ret

iterator_is_fcvtwqrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtwqrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwqrdn_false
xorb %al, %al
ret
iterator_is_fcvtwqrdn_false:
movb $1, %al
ret

iterator_is_fcvtwqrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtwqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtwqrmm_false
xorb %al, %al
ret
iterator_is_fcvtwqrmm_false:
movb $1, %al
ret

iterator_is_fcvtwqrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwqrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwqrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwqrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwqrne_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwqrne_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtwqrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwqrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtwqrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtwqrne_false
xorb %al, %al
ret
iterator_is_fcvtwqrne_false:
movb $1, %al
ret

iterator_is_fcvtwqrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtwqrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtwqrtz_false
xorb %al, %al
ret
iterator_is_fcvtwqrtz_false:
movb $1, %al
ret

iterator_is_fcvtwqrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwqrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwqrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwqrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwqrup_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwqrup_false
cmpb $113, 5(%rax)
jne iterator_is_fcvtwqrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwqrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtwqrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtwqrup_false
xorb %al, %al
ret
iterator_is_fcvtwqrup_false:
movb $1, %al
ret

iterator_is_fcvtwsdyn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fcvtwsdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwsdyn_false
xorb %al, %al
ret
iterator_is_fcvtwsdyn_false:
movb $1, %al
ret

iterator_is_fcvtwsrdn:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtwsrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwsrdn_false
xorb %al, %al
ret
iterator_is_fcvtwsrdn_false:
movb $1, %al
ret

iterator_is_fcvtwsrmm:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fcvtwsrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtwsrmm_false
xorb %al, %al
ret
iterator_is_fcvtwsrmm_false:
movb $1, %al
ret

iterator_is_fcvtwsrne:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwsrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwsrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwsrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwsrne_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwsrne_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtwsrne_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwsrne_false
cmpb $110, 7(%rax)
jne iterator_is_fcvtwsrne_false
cmpb $101, 8(%rax)
jne iterator_is_fcvtwsrne_false
xorb %al, %al
ret
iterator_is_fcvtwsrne_false:
movb $1, %al
ret

iterator_is_fcvtwsrtz:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fcvtwsrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fcvtwsrtz_false
xorb %al, %al
ret
iterator_is_fcvtwsrtz_false:
movb $1, %al
ret

iterator_is_fcvtwsrup:
cmpq $9, iterator_token_size
jne iterator_is_fcvtwsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwsrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwsrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwsrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwsrup_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwsrup_false
cmpb $115, 5(%rax)
jne iterator_is_fcvtwsrup_false
cmpb $114, 6(%rax)
jne iterator_is_fcvtwsrup_false
cmpb $117, 7(%rax)
jne iterator_is_fcvtwsrup_false
cmpb $112, 8(%rax)
jne iterator_is_fcvtwsrup_false
xorb %al, %al
ret
iterator_is_fcvtwsrup_false:
movb $1, %al
ret

iterator_is_fcvtwuddyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwuddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtwuddyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtwuddyn_false
xorb %al, %al
ret
iterator_is_fcvtwuddyn_false:
movb $1, %al
ret

iterator_is_fcvtwudrdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwudrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtwudrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtwudrdn_false
xorb %al, %al
ret
iterator_is_fcvtwudrdn_false:
movb $1, %al
ret

iterator_is_fcvtwudrmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwudrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtwudrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtwudrmm_false
xorb %al, %al
ret
iterator_is_fcvtwudrmm_false:
movb $1, %al
ret

iterator_is_fcvtwudrne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwudrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwudrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwudrne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtwudrne_false
xorb %al, %al
ret
iterator_is_fcvtwudrne_false:
movb $1, %al
ret

iterator_is_fcvtwudrtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwudrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtwudrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtwudrtz_false
xorb %al, %al
ret
iterator_is_fcvtwudrtz_false:
movb $1, %al
ret

iterator_is_fcvtwudrup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwudrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwudrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $100, 6(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtwudrup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtwudrup_false
xorb %al, %al
ret
iterator_is_fcvtwudrup_false:
movb $1, %al
ret

iterator_is_fcvtwuqdyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwuqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtwuqdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtwuqdyn_false
xorb %al, %al
ret
iterator_is_fcvtwuqdyn_false:
movb $1, %al
ret

iterator_is_fcvtwuqrdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwuqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtwuqrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtwuqrdn_false
xorb %al, %al
ret
iterator_is_fcvtwuqrdn_false:
movb $1, %al
ret

iterator_is_fcvtwuqrmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwuqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtwuqrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtwuqrmm_false
xorb %al, %al
ret
iterator_is_fcvtwuqrmm_false:
movb $1, %al
ret

iterator_is_fcvtwuqrne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwuqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwuqrne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtwuqrne_false
xorb %al, %al
ret
iterator_is_fcvtwuqrne_false:
movb $1, %al
ret

iterator_is_fcvtwuqrtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwuqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtwuqrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtwuqrtz_false
xorb %al, %al
ret
iterator_is_fcvtwuqrtz_false:
movb $1, %al
ret

iterator_is_fcvtwuqrup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwuqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $113, 6(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtwuqrup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtwuqrup_false
xorb %al, %al
ret
iterator_is_fcvtwuqrup_false:
movb $1, %al
ret

iterator_is_fcvtwusdyn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwusdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fcvtwusdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtwusdyn_false
xorb %al, %al
ret
iterator_is_fcvtwusdyn_false:
movb $1, %al
ret

iterator_is_fcvtwusrdn:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwusrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fcvtwusrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fcvtwusrdn_false
xorb %al, %al
ret
iterator_is_fcvtwusrdn_false:
movb $1, %al
ret

iterator_is_fcvtwusrmm:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwusrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fcvtwusrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fcvtwusrmm_false
xorb %al, %al
ret
iterator_is_fcvtwusrmm_false:
movb $1, %al
ret

iterator_is_fcvtwusrne:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwusrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwusrne_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $110, 8(%rax)
jne iterator_is_fcvtwusrne_false
cmpb $101, 9(%rax)
jne iterator_is_fcvtwusrne_false
xorb %al, %al
ret
iterator_is_fcvtwusrne_false:
movb $1, %al
ret

iterator_is_fcvtwusrtz:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwusrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fcvtwusrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fcvtwusrtz_false
xorb %al, %al
ret
iterator_is_fcvtwusrtz_false:
movb $1, %al
ret

iterator_is_fcvtwusrup:
cmpq $10, iterator_token_size
jne iterator_is_fcvtwusrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fcvtwusrup_false
cmpb $99, 1(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $118, 2(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $116, 3(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $119, 4(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $117, 5(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $115, 6(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $114, 7(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $117, 8(%rax)
jne iterator_is_fcvtwusrup_false
cmpb $112, 9(%rax)
jne iterator_is_fcvtwusrup_false
xorb %al, %al
ret
iterator_is_fcvtwusrup_false:
movb $1, %al
ret

iterator_is_fdivddyn:
cmpq $8, iterator_token_size
jne iterator_is_fdivddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivddyn_false
cmpb $100, 1(%rax)
jne iterator_is_fdivddyn_false
cmpb $105, 2(%rax)
jne iterator_is_fdivddyn_false
cmpb $118, 3(%rax)
jne iterator_is_fdivddyn_false
cmpb $100, 4(%rax)
jne iterator_is_fdivddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fdivddyn_false
cmpb $121, 6(%rax)
jne iterator_is_fdivddyn_false
cmpb $110, 7(%rax)
jne iterator_is_fdivddyn_false
xorb %al, %al
ret
iterator_is_fdivddyn_false:
movb $1, %al
ret

iterator_is_fdivdrdn:
cmpq $8, iterator_token_size
jne iterator_is_fdivdrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivdrdn_false
cmpb $100, 1(%rax)
jne iterator_is_fdivdrdn_false
cmpb $105, 2(%rax)
jne iterator_is_fdivdrdn_false
cmpb $118, 3(%rax)
jne iterator_is_fdivdrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fdivdrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fdivdrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fdivdrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fdivdrdn_false
xorb %al, %al
ret
iterator_is_fdivdrdn_false:
movb $1, %al
ret

iterator_is_fdivdrmm:
cmpq $8, iterator_token_size
jne iterator_is_fdivdrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivdrmm_false
cmpb $100, 1(%rax)
jne iterator_is_fdivdrmm_false
cmpb $105, 2(%rax)
jne iterator_is_fdivdrmm_false
cmpb $118, 3(%rax)
jne iterator_is_fdivdrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fdivdrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fdivdrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fdivdrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fdivdrmm_false
xorb %al, %al
ret
iterator_is_fdivdrmm_false:
movb $1, %al
ret

iterator_is_fdivdrne:
cmpq $8, iterator_token_size
jne iterator_is_fdivdrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivdrne_false
cmpb $100, 1(%rax)
jne iterator_is_fdivdrne_false
cmpb $105, 2(%rax)
jne iterator_is_fdivdrne_false
cmpb $118, 3(%rax)
jne iterator_is_fdivdrne_false
cmpb $100, 4(%rax)
jne iterator_is_fdivdrne_false
cmpb $114, 5(%rax)
jne iterator_is_fdivdrne_false
cmpb $110, 6(%rax)
jne iterator_is_fdivdrne_false
cmpb $101, 7(%rax)
jne iterator_is_fdivdrne_false
xorb %al, %al
ret
iterator_is_fdivdrne_false:
movb $1, %al
ret

iterator_is_fdivdrtz:
cmpq $8, iterator_token_size
jne iterator_is_fdivdrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivdrtz_false
cmpb $100, 1(%rax)
jne iterator_is_fdivdrtz_false
cmpb $105, 2(%rax)
jne iterator_is_fdivdrtz_false
cmpb $118, 3(%rax)
jne iterator_is_fdivdrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fdivdrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fdivdrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fdivdrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fdivdrtz_false
xorb %al, %al
ret
iterator_is_fdivdrtz_false:
movb $1, %al
ret

iterator_is_fdivdrup:
cmpq $8, iterator_token_size
jne iterator_is_fdivdrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivdrup_false
cmpb $100, 1(%rax)
jne iterator_is_fdivdrup_false
cmpb $105, 2(%rax)
jne iterator_is_fdivdrup_false
cmpb $118, 3(%rax)
jne iterator_is_fdivdrup_false
cmpb $100, 4(%rax)
jne iterator_is_fdivdrup_false
cmpb $114, 5(%rax)
jne iterator_is_fdivdrup_false
cmpb $117, 6(%rax)
jne iterator_is_fdivdrup_false
cmpb $112, 7(%rax)
jne iterator_is_fdivdrup_false
xorb %al, %al
ret
iterator_is_fdivdrup_false:
movb $1, %al
ret

iterator_is_fdivqdyn:
cmpq $8, iterator_token_size
jne iterator_is_fdivqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivqdyn_false
cmpb $100, 1(%rax)
jne iterator_is_fdivqdyn_false
cmpb $105, 2(%rax)
jne iterator_is_fdivqdyn_false
cmpb $118, 3(%rax)
jne iterator_is_fdivqdyn_false
cmpb $113, 4(%rax)
jne iterator_is_fdivqdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fdivqdyn_false
cmpb $121, 6(%rax)
jne iterator_is_fdivqdyn_false
cmpb $110, 7(%rax)
jne iterator_is_fdivqdyn_false
xorb %al, %al
ret
iterator_is_fdivqdyn_false:
movb $1, %al
ret

iterator_is_fdivqrdn:
cmpq $8, iterator_token_size
jne iterator_is_fdivqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivqrdn_false
cmpb $100, 1(%rax)
jne iterator_is_fdivqrdn_false
cmpb $105, 2(%rax)
jne iterator_is_fdivqrdn_false
cmpb $118, 3(%rax)
jne iterator_is_fdivqrdn_false
cmpb $113, 4(%rax)
jne iterator_is_fdivqrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fdivqrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fdivqrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fdivqrdn_false
xorb %al, %al
ret
iterator_is_fdivqrdn_false:
movb $1, %al
ret

iterator_is_fdivqrmm:
cmpq $8, iterator_token_size
jne iterator_is_fdivqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivqrmm_false
cmpb $100, 1(%rax)
jne iterator_is_fdivqrmm_false
cmpb $105, 2(%rax)
jne iterator_is_fdivqrmm_false
cmpb $118, 3(%rax)
jne iterator_is_fdivqrmm_false
cmpb $113, 4(%rax)
jne iterator_is_fdivqrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fdivqrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fdivqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fdivqrmm_false
xorb %al, %al
ret
iterator_is_fdivqrmm_false:
movb $1, %al
ret

iterator_is_fdivqrne:
cmpq $8, iterator_token_size
jne iterator_is_fdivqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivqrne_false
cmpb $100, 1(%rax)
jne iterator_is_fdivqrne_false
cmpb $105, 2(%rax)
jne iterator_is_fdivqrne_false
cmpb $118, 3(%rax)
jne iterator_is_fdivqrne_false
cmpb $113, 4(%rax)
jne iterator_is_fdivqrne_false
cmpb $114, 5(%rax)
jne iterator_is_fdivqrne_false
cmpb $110, 6(%rax)
jne iterator_is_fdivqrne_false
cmpb $101, 7(%rax)
jne iterator_is_fdivqrne_false
xorb %al, %al
ret
iterator_is_fdivqrne_false:
movb $1, %al
ret

iterator_is_fdivqrtz:
cmpq $8, iterator_token_size
jne iterator_is_fdivqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivqrtz_false
cmpb $100, 1(%rax)
jne iterator_is_fdivqrtz_false
cmpb $105, 2(%rax)
jne iterator_is_fdivqrtz_false
cmpb $118, 3(%rax)
jne iterator_is_fdivqrtz_false
cmpb $113, 4(%rax)
jne iterator_is_fdivqrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fdivqrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fdivqrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fdivqrtz_false
xorb %al, %al
ret
iterator_is_fdivqrtz_false:
movb $1, %al
ret

iterator_is_fdivqrup:
cmpq $8, iterator_token_size
jne iterator_is_fdivqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivqrup_false
cmpb $100, 1(%rax)
jne iterator_is_fdivqrup_false
cmpb $105, 2(%rax)
jne iterator_is_fdivqrup_false
cmpb $118, 3(%rax)
jne iterator_is_fdivqrup_false
cmpb $113, 4(%rax)
jne iterator_is_fdivqrup_false
cmpb $114, 5(%rax)
jne iterator_is_fdivqrup_false
cmpb $117, 6(%rax)
jne iterator_is_fdivqrup_false
cmpb $112, 7(%rax)
jne iterator_is_fdivqrup_false
xorb %al, %al
ret
iterator_is_fdivqrup_false:
movb $1, %al
ret

iterator_is_fdivsdyn:
cmpq $8, iterator_token_size
jne iterator_is_fdivsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivsdyn_false
cmpb $100, 1(%rax)
jne iterator_is_fdivsdyn_false
cmpb $105, 2(%rax)
jne iterator_is_fdivsdyn_false
cmpb $118, 3(%rax)
jne iterator_is_fdivsdyn_false
cmpb $115, 4(%rax)
jne iterator_is_fdivsdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fdivsdyn_false
cmpb $121, 6(%rax)
jne iterator_is_fdivsdyn_false
cmpb $110, 7(%rax)
jne iterator_is_fdivsdyn_false
xorb %al, %al
ret
iterator_is_fdivsdyn_false:
movb $1, %al
ret

iterator_is_fdivsrdn:
cmpq $8, iterator_token_size
jne iterator_is_fdivsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivsrdn_false
cmpb $100, 1(%rax)
jne iterator_is_fdivsrdn_false
cmpb $105, 2(%rax)
jne iterator_is_fdivsrdn_false
cmpb $118, 3(%rax)
jne iterator_is_fdivsrdn_false
cmpb $115, 4(%rax)
jne iterator_is_fdivsrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fdivsrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fdivsrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fdivsrdn_false
xorb %al, %al
ret
iterator_is_fdivsrdn_false:
movb $1, %al
ret

iterator_is_fdivsrmm:
cmpq $8, iterator_token_size
jne iterator_is_fdivsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivsrmm_false
cmpb $100, 1(%rax)
jne iterator_is_fdivsrmm_false
cmpb $105, 2(%rax)
jne iterator_is_fdivsrmm_false
cmpb $118, 3(%rax)
jne iterator_is_fdivsrmm_false
cmpb $115, 4(%rax)
jne iterator_is_fdivsrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fdivsrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fdivsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fdivsrmm_false
xorb %al, %al
ret
iterator_is_fdivsrmm_false:
movb $1, %al
ret

iterator_is_fdivsrne:
cmpq $8, iterator_token_size
jne iterator_is_fdivsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivsrne_false
cmpb $100, 1(%rax)
jne iterator_is_fdivsrne_false
cmpb $105, 2(%rax)
jne iterator_is_fdivsrne_false
cmpb $118, 3(%rax)
jne iterator_is_fdivsrne_false
cmpb $115, 4(%rax)
jne iterator_is_fdivsrne_false
cmpb $114, 5(%rax)
jne iterator_is_fdivsrne_false
cmpb $110, 6(%rax)
jne iterator_is_fdivsrne_false
cmpb $101, 7(%rax)
jne iterator_is_fdivsrne_false
xorb %al, %al
ret
iterator_is_fdivsrne_false:
movb $1, %al
ret

iterator_is_fdivsrtz:
cmpq $8, iterator_token_size
jne iterator_is_fdivsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivsrtz_false
cmpb $100, 1(%rax)
jne iterator_is_fdivsrtz_false
cmpb $105, 2(%rax)
jne iterator_is_fdivsrtz_false
cmpb $118, 3(%rax)
jne iterator_is_fdivsrtz_false
cmpb $115, 4(%rax)
jne iterator_is_fdivsrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fdivsrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fdivsrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fdivsrtz_false
xorb %al, %al
ret
iterator_is_fdivsrtz_false:
movb $1, %al
ret

iterator_is_fdivsrup:
cmpq $8, iterator_token_size
jne iterator_is_fdivsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fdivsrup_false
cmpb $100, 1(%rax)
jne iterator_is_fdivsrup_false
cmpb $105, 2(%rax)
jne iterator_is_fdivsrup_false
cmpb $118, 3(%rax)
jne iterator_is_fdivsrup_false
cmpb $115, 4(%rax)
jne iterator_is_fdivsrup_false
cmpb $114, 5(%rax)
jne iterator_is_fdivsrup_false
cmpb $117, 6(%rax)
jne iterator_is_fdivsrup_false
cmpb $112, 7(%rax)
jne iterator_is_fdivsrup_false
xorb %al, %al
ret
iterator_is_fdivsrup_false:
movb $1, %al
ret

iterator_is_fence:
cmpq $5, iterator_token_size
jne iterator_is_fence_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fence_false
cmpb $101, 1(%rax)
jne iterator_is_fence_false
cmpb $110, 2(%rax)
jne iterator_is_fence_false
cmpb $99, 3(%rax)
jne iterator_is_fence_false
cmpb $101, 4(%rax)
jne iterator_is_fence_false
xorb %al, %al
ret
iterator_is_fence_false:
movb $1, %al
ret

iterator_is_fencei:
cmpq $6, iterator_token_size
jne iterator_is_fencei_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fencei_false
cmpb $101, 1(%rax)
jne iterator_is_fencei_false
cmpb $110, 2(%rax)
jne iterator_is_fencei_false
cmpb $99, 3(%rax)
jne iterator_is_fencei_false
cmpb $101, 4(%rax)
jne iterator_is_fencei_false
cmpb $105, 5(%rax)
jne iterator_is_fencei_false
xorb %al, %al
ret
iterator_is_fencei_false:
movb $1, %al
ret

iterator_is_feqd:
cmpq $4, iterator_token_size
jne iterator_is_feqd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_feqd_false
cmpb $101, 1(%rax)
jne iterator_is_feqd_false
cmpb $113, 2(%rax)
jne iterator_is_feqd_false
cmpb $100, 3(%rax)
jne iterator_is_feqd_false
xorb %al, %al
ret
iterator_is_feqd_false:
movb $1, %al
ret

iterator_is_feqq:
cmpq $4, iterator_token_size
jne iterator_is_feqq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_feqq_false
cmpb $101, 1(%rax)
jne iterator_is_feqq_false
cmpb $113, 2(%rax)
jne iterator_is_feqq_false
cmpb $113, 3(%rax)
jne iterator_is_feqq_false
xorb %al, %al
ret
iterator_is_feqq_false:
movb $1, %al
ret

iterator_is_feqs:
cmpq $4, iterator_token_size
jne iterator_is_feqs_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_feqs_false
cmpb $101, 1(%rax)
jne iterator_is_feqs_false
cmpb $113, 2(%rax)
jne iterator_is_feqs_false
cmpb $115, 3(%rax)
jne iterator_is_feqs_false
xorb %al, %al
ret
iterator_is_feqs_false:
movb $1, %al
ret

iterator_is_fld:
cmpq $3, iterator_token_size
jne iterator_is_fld_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fld_false
cmpb $108, 1(%rax)
jne iterator_is_fld_false
cmpb $100, 2(%rax)
jne iterator_is_fld_false
xorb %al, %al
ret
iterator_is_fld_false:
movb $1, %al
ret

iterator_is_fled:
cmpq $4, iterator_token_size
jne iterator_is_fled_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fled_false
cmpb $108, 1(%rax)
jne iterator_is_fled_false
cmpb $101, 2(%rax)
jne iterator_is_fled_false
cmpb $100, 3(%rax)
jne iterator_is_fled_false
xorb %al, %al
ret
iterator_is_fled_false:
movb $1, %al
ret

iterator_is_fleq:
cmpq $4, iterator_token_size
jne iterator_is_fleq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fleq_false
cmpb $108, 1(%rax)
jne iterator_is_fleq_false
cmpb $101, 2(%rax)
jne iterator_is_fleq_false
cmpb $113, 3(%rax)
jne iterator_is_fleq_false
xorb %al, %al
ret
iterator_is_fleq_false:
movb $1, %al
ret

iterator_is_fles:
cmpq $4, iterator_token_size
jne iterator_is_fles_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fles_false
cmpb $108, 1(%rax)
jne iterator_is_fles_false
cmpb $101, 2(%rax)
jne iterator_is_fles_false
cmpb $115, 3(%rax)
jne iterator_is_fles_false
xorb %al, %al
ret
iterator_is_fles_false:
movb $1, %al
ret

iterator_is_flq:
cmpq $3, iterator_token_size
jne iterator_is_flq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_flq_false
cmpb $108, 1(%rax)
jne iterator_is_flq_false
cmpb $113, 2(%rax)
jne iterator_is_flq_false
xorb %al, %al
ret
iterator_is_flq_false:
movb $1, %al
ret

iterator_is_fltd:
cmpq $4, iterator_token_size
jne iterator_is_fltd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fltd_false
cmpb $108, 1(%rax)
jne iterator_is_fltd_false
cmpb $116, 2(%rax)
jne iterator_is_fltd_false
cmpb $100, 3(%rax)
jne iterator_is_fltd_false
xorb %al, %al
ret
iterator_is_fltd_false:
movb $1, %al
ret

iterator_is_fltq:
cmpq $4, iterator_token_size
jne iterator_is_fltq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fltq_false
cmpb $108, 1(%rax)
jne iterator_is_fltq_false
cmpb $116, 2(%rax)
jne iterator_is_fltq_false
cmpb $113, 3(%rax)
jne iterator_is_fltq_false
xorb %al, %al
ret
iterator_is_fltq_false:
movb $1, %al
ret

iterator_is_flts:
cmpq $4, iterator_token_size
jne iterator_is_flts_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_flts_false
cmpb $108, 1(%rax)
jne iterator_is_flts_false
cmpb $116, 2(%rax)
jne iterator_is_flts_false
cmpb $115, 3(%rax)
jne iterator_is_flts_false
xorb %al, %al
ret
iterator_is_flts_false:
movb $1, %al
ret

iterator_is_flw:
cmpq $3, iterator_token_size
jne iterator_is_flw_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_flw_false
cmpb $108, 1(%rax)
jne iterator_is_flw_false
cmpb $119, 2(%rax)
jne iterator_is_flw_false
xorb %al, %al
ret
iterator_is_flw_false:
movb $1, %al
ret

iterator_is_fmaddddyn:
cmpq $9, iterator_token_size
jne iterator_is_fmaddddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddddyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddddyn_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddddyn_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddddyn_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fmaddddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fmaddddyn_false
cmpb $121, 7(%rax)
jne iterator_is_fmaddddyn_false
cmpb $110, 8(%rax)
jne iterator_is_fmaddddyn_false
xorb %al, %al
ret
iterator_is_fmaddddyn_false:
movb $1, %al
ret

iterator_is_fmadddrdn:
cmpq $9, iterator_token_size
jne iterator_is_fmadddrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmadddrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmadddrdn_false
cmpb $97, 2(%rax)
jne iterator_is_fmadddrdn_false
cmpb $100, 3(%rax)
jne iterator_is_fmadddrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fmadddrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fmadddrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fmadddrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fmadddrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fmadddrdn_false
xorb %al, %al
ret
iterator_is_fmadddrdn_false:
movb $1, %al
ret

iterator_is_fmadddrmm:
cmpq $9, iterator_token_size
jne iterator_is_fmadddrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmadddrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmadddrmm_false
cmpb $97, 2(%rax)
jne iterator_is_fmadddrmm_false
cmpb $100, 3(%rax)
jne iterator_is_fmadddrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fmadddrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fmadddrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fmadddrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmadddrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fmadddrmm_false
xorb %al, %al
ret
iterator_is_fmadddrmm_false:
movb $1, %al
ret

iterator_is_fmadddrne:
cmpq $9, iterator_token_size
jne iterator_is_fmadddrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmadddrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmadddrne_false
cmpb $97, 2(%rax)
jne iterator_is_fmadddrne_false
cmpb $100, 3(%rax)
jne iterator_is_fmadddrne_false
cmpb $100, 4(%rax)
jne iterator_is_fmadddrne_false
cmpb $100, 5(%rax)
jne iterator_is_fmadddrne_false
cmpb $114, 6(%rax)
jne iterator_is_fmadddrne_false
cmpb $110, 7(%rax)
jne iterator_is_fmadddrne_false
cmpb $101, 8(%rax)
jne iterator_is_fmadddrne_false
xorb %al, %al
ret
iterator_is_fmadddrne_false:
movb $1, %al
ret

iterator_is_fmadddrtz:
cmpq $9, iterator_token_size
jne iterator_is_fmadddrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmadddrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmadddrtz_false
cmpb $97, 2(%rax)
jne iterator_is_fmadddrtz_false
cmpb $100, 3(%rax)
jne iterator_is_fmadddrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fmadddrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fmadddrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fmadddrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fmadddrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fmadddrtz_false
xorb %al, %al
ret
iterator_is_fmadddrtz_false:
movb $1, %al
ret

iterator_is_fmadddrup:
cmpq $9, iterator_token_size
jne iterator_is_fmadddrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmadddrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmadddrup_false
cmpb $97, 2(%rax)
jne iterator_is_fmadddrup_false
cmpb $100, 3(%rax)
jne iterator_is_fmadddrup_false
cmpb $100, 4(%rax)
jne iterator_is_fmadddrup_false
cmpb $100, 5(%rax)
jne iterator_is_fmadddrup_false
cmpb $114, 6(%rax)
jne iterator_is_fmadddrup_false
cmpb $117, 7(%rax)
jne iterator_is_fmadddrup_false
cmpb $112, 8(%rax)
jne iterator_is_fmadddrup_false
xorb %al, %al
ret
iterator_is_fmadddrup_false:
movb $1, %al
ret

iterator_is_fmaddqdyn:
cmpq $9, iterator_token_size
jne iterator_is_fmaddqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddqdyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddqdyn_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddqdyn_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddqdyn_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddqdyn_false
cmpb $113, 5(%rax)
jne iterator_is_fmaddqdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fmaddqdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fmaddqdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fmaddqdyn_false
xorb %al, %al
ret
iterator_is_fmaddqdyn_false:
movb $1, %al
ret

iterator_is_fmaddqrdn:
cmpq $9, iterator_token_size
jne iterator_is_fmaddqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddqrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddqrdn_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddqrdn_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddqrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddqrdn_false
cmpb $113, 5(%rax)
jne iterator_is_fmaddqrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddqrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fmaddqrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fmaddqrdn_false
xorb %al, %al
ret
iterator_is_fmaddqrdn_false:
movb $1, %al
ret

iterator_is_fmaddqrmm:
cmpq $9, iterator_token_size
jne iterator_is_fmaddqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddqrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddqrmm_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddqrmm_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddqrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddqrmm_false
cmpb $113, 5(%rax)
jne iterator_is_fmaddqrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmaddqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fmaddqrmm_false
xorb %al, %al
ret
iterator_is_fmaddqrmm_false:
movb $1, %al
ret

iterator_is_fmaddqrne:
cmpq $9, iterator_token_size
jne iterator_is_fmaddqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddqrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddqrne_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddqrne_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddqrne_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddqrne_false
cmpb $113, 5(%rax)
jne iterator_is_fmaddqrne_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddqrne_false
cmpb $110, 7(%rax)
jne iterator_is_fmaddqrne_false
cmpb $101, 8(%rax)
jne iterator_is_fmaddqrne_false
xorb %al, %al
ret
iterator_is_fmaddqrne_false:
movb $1, %al
ret

iterator_is_fmaddqrtz:
cmpq $9, iterator_token_size
jne iterator_is_fmaddqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddqrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddqrtz_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddqrtz_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddqrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddqrtz_false
cmpb $113, 5(%rax)
jne iterator_is_fmaddqrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddqrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fmaddqrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fmaddqrtz_false
xorb %al, %al
ret
iterator_is_fmaddqrtz_false:
movb $1, %al
ret

iterator_is_fmaddqrup:
cmpq $9, iterator_token_size
jne iterator_is_fmaddqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddqrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddqrup_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddqrup_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddqrup_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddqrup_false
cmpb $113, 5(%rax)
jne iterator_is_fmaddqrup_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddqrup_false
cmpb $117, 7(%rax)
jne iterator_is_fmaddqrup_false
cmpb $112, 8(%rax)
jne iterator_is_fmaddqrup_false
xorb %al, %al
ret
iterator_is_fmaddqrup_false:
movb $1, %al
ret

iterator_is_fmaddsdyn:
cmpq $9, iterator_token_size
jne iterator_is_fmaddsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddsdyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddsdyn_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddsdyn_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddsdyn_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddsdyn_false
cmpb $115, 5(%rax)
jne iterator_is_fmaddsdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fmaddsdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fmaddsdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fmaddsdyn_false
xorb %al, %al
ret
iterator_is_fmaddsdyn_false:
movb $1, %al
ret

iterator_is_fmaddsrdn:
cmpq $9, iterator_token_size
jne iterator_is_fmaddsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddsrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddsrdn_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddsrdn_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddsrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddsrdn_false
cmpb $115, 5(%rax)
jne iterator_is_fmaddsrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddsrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fmaddsrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fmaddsrdn_false
xorb %al, %al
ret
iterator_is_fmaddsrdn_false:
movb $1, %al
ret

iterator_is_fmaddsrmm:
cmpq $9, iterator_token_size
jne iterator_is_fmaddsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddsrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddsrmm_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddsrmm_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddsrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddsrmm_false
cmpb $115, 5(%rax)
jne iterator_is_fmaddsrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmaddsrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fmaddsrmm_false
xorb %al, %al
ret
iterator_is_fmaddsrmm_false:
movb $1, %al
ret

iterator_is_fmaddsrne:
cmpq $9, iterator_token_size
jne iterator_is_fmaddsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddsrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddsrne_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddsrne_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddsrne_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddsrne_false
cmpb $115, 5(%rax)
jne iterator_is_fmaddsrne_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddsrne_false
cmpb $110, 7(%rax)
jne iterator_is_fmaddsrne_false
cmpb $101, 8(%rax)
jne iterator_is_fmaddsrne_false
xorb %al, %al
ret
iterator_is_fmaddsrne_false:
movb $1, %al
ret

iterator_is_fmaddsrtz:
cmpq $9, iterator_token_size
jne iterator_is_fmaddsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddsrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddsrtz_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddsrtz_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddsrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddsrtz_false
cmpb $115, 5(%rax)
jne iterator_is_fmaddsrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddsrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fmaddsrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fmaddsrtz_false
xorb %al, %al
ret
iterator_is_fmaddsrtz_false:
movb $1, %al
ret

iterator_is_fmaddsrup:
cmpq $9, iterator_token_size
jne iterator_is_fmaddsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaddsrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmaddsrup_false
cmpb $97, 2(%rax)
jne iterator_is_fmaddsrup_false
cmpb $100, 3(%rax)
jne iterator_is_fmaddsrup_false
cmpb $100, 4(%rax)
jne iterator_is_fmaddsrup_false
cmpb $115, 5(%rax)
jne iterator_is_fmaddsrup_false
cmpb $114, 6(%rax)
jne iterator_is_fmaddsrup_false
cmpb $117, 7(%rax)
jne iterator_is_fmaddsrup_false
cmpb $112, 8(%rax)
jne iterator_is_fmaddsrup_false
xorb %al, %al
ret
iterator_is_fmaddsrup_false:
movb $1, %al
ret

iterator_is_fmaxd:
cmpq $5, iterator_token_size
jne iterator_is_fmaxd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaxd_false
cmpb $109, 1(%rax)
jne iterator_is_fmaxd_false
cmpb $97, 2(%rax)
jne iterator_is_fmaxd_false
cmpb $120, 3(%rax)
jne iterator_is_fmaxd_false
cmpb $100, 4(%rax)
jne iterator_is_fmaxd_false
xorb %al, %al
ret
iterator_is_fmaxd_false:
movb $1, %al
ret

iterator_is_fmaxq:
cmpq $5, iterator_token_size
jne iterator_is_fmaxq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaxq_false
cmpb $109, 1(%rax)
jne iterator_is_fmaxq_false
cmpb $97, 2(%rax)
jne iterator_is_fmaxq_false
cmpb $120, 3(%rax)
jne iterator_is_fmaxq_false
cmpb $113, 4(%rax)
jne iterator_is_fmaxq_false
xorb %al, %al
ret
iterator_is_fmaxq_false:
movb $1, %al
ret

iterator_is_fmaxs:
cmpq $5, iterator_token_size
jne iterator_is_fmaxs_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmaxs_false
cmpb $109, 1(%rax)
jne iterator_is_fmaxs_false
cmpb $97, 2(%rax)
jne iterator_is_fmaxs_false
cmpb $120, 3(%rax)
jne iterator_is_fmaxs_false
cmpb $115, 4(%rax)
jne iterator_is_fmaxs_false
xorb %al, %al
ret
iterator_is_fmaxs_false:
movb $1, %al
ret

iterator_is_fmind:
cmpq $5, iterator_token_size
jne iterator_is_fmind_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmind_false
cmpb $109, 1(%rax)
jne iterator_is_fmind_false
cmpb $105, 2(%rax)
jne iterator_is_fmind_false
cmpb $110, 3(%rax)
jne iterator_is_fmind_false
cmpb $100, 4(%rax)
jne iterator_is_fmind_false
xorb %al, %al
ret
iterator_is_fmind_false:
movb $1, %al
ret

iterator_is_fminq:
cmpq $5, iterator_token_size
jne iterator_is_fminq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fminq_false
cmpb $109, 1(%rax)
jne iterator_is_fminq_false
cmpb $105, 2(%rax)
jne iterator_is_fminq_false
cmpb $110, 3(%rax)
jne iterator_is_fminq_false
cmpb $113, 4(%rax)
jne iterator_is_fminq_false
xorb %al, %al
ret
iterator_is_fminq_false:
movb $1, %al
ret

iterator_is_fmins:
cmpq $5, iterator_token_size
jne iterator_is_fmins_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmins_false
cmpb $109, 1(%rax)
jne iterator_is_fmins_false
cmpb $105, 2(%rax)
jne iterator_is_fmins_false
cmpb $110, 3(%rax)
jne iterator_is_fmins_false
cmpb $115, 4(%rax)
jne iterator_is_fmins_false
xorb %al, %al
ret
iterator_is_fmins_false:
movb $1, %al
ret

iterator_is_fmsubddyn:
cmpq $9, iterator_token_size
jne iterator_is_fmsubddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubddyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubddyn_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubddyn_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubddyn_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fmsubddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fmsubddyn_false
cmpb $121, 7(%rax)
jne iterator_is_fmsubddyn_false
cmpb $110, 8(%rax)
jne iterator_is_fmsubddyn_false
xorb %al, %al
ret
iterator_is_fmsubddyn_false:
movb $1, %al
ret

iterator_is_fmsubdrdn:
cmpq $9, iterator_token_size
jne iterator_is_fmsubdrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubdrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubdrdn_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubdrdn_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubdrdn_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubdrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fmsubdrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubdrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fmsubdrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fmsubdrdn_false
xorb %al, %al
ret
iterator_is_fmsubdrdn_false:
movb $1, %al
ret

iterator_is_fmsubdrmm:
cmpq $9, iterator_token_size
jne iterator_is_fmsubdrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubdrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubdrmm_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubdrmm_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubdrmm_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubdrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fmsubdrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubdrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmsubdrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fmsubdrmm_false
xorb %al, %al
ret
iterator_is_fmsubdrmm_false:
movb $1, %al
ret

iterator_is_fmsubdrne:
cmpq $9, iterator_token_size
jne iterator_is_fmsubdrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubdrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubdrne_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubdrne_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubdrne_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubdrne_false
cmpb $100, 5(%rax)
jne iterator_is_fmsubdrne_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubdrne_false
cmpb $110, 7(%rax)
jne iterator_is_fmsubdrne_false
cmpb $101, 8(%rax)
jne iterator_is_fmsubdrne_false
xorb %al, %al
ret
iterator_is_fmsubdrne_false:
movb $1, %al
ret

iterator_is_fmsubdrtz:
cmpq $9, iterator_token_size
jne iterator_is_fmsubdrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubdrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubdrtz_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubdrtz_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubdrtz_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubdrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fmsubdrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubdrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fmsubdrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fmsubdrtz_false
xorb %al, %al
ret
iterator_is_fmsubdrtz_false:
movb $1, %al
ret

iterator_is_fmsubdrup:
cmpq $9, iterator_token_size
jne iterator_is_fmsubdrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubdrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubdrup_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubdrup_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubdrup_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubdrup_false
cmpb $100, 5(%rax)
jne iterator_is_fmsubdrup_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubdrup_false
cmpb $117, 7(%rax)
jne iterator_is_fmsubdrup_false
cmpb $112, 8(%rax)
jne iterator_is_fmsubdrup_false
xorb %al, %al
ret
iterator_is_fmsubdrup_false:
movb $1, %al
ret

iterator_is_fmsubqdyn:
cmpq $9, iterator_token_size
jne iterator_is_fmsubqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubqdyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubqdyn_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubqdyn_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubqdyn_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubqdyn_false
cmpb $113, 5(%rax)
jne iterator_is_fmsubqdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fmsubqdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fmsubqdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fmsubqdyn_false
xorb %al, %al
ret
iterator_is_fmsubqdyn_false:
movb $1, %al
ret

iterator_is_fmsubqrdn:
cmpq $9, iterator_token_size
jne iterator_is_fmsubqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubqrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubqrdn_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubqrdn_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubqrdn_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubqrdn_false
cmpb $113, 5(%rax)
jne iterator_is_fmsubqrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubqrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fmsubqrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fmsubqrdn_false
xorb %al, %al
ret
iterator_is_fmsubqrdn_false:
movb $1, %al
ret

iterator_is_fmsubqrmm:
cmpq $9, iterator_token_size
jne iterator_is_fmsubqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubqrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubqrmm_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubqrmm_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubqrmm_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubqrmm_false
cmpb $113, 5(%rax)
jne iterator_is_fmsubqrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmsubqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fmsubqrmm_false
xorb %al, %al
ret
iterator_is_fmsubqrmm_false:
movb $1, %al
ret

iterator_is_fmsubqrne:
cmpq $9, iterator_token_size
jne iterator_is_fmsubqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubqrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubqrne_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubqrne_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubqrne_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubqrne_false
cmpb $113, 5(%rax)
jne iterator_is_fmsubqrne_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubqrne_false
cmpb $110, 7(%rax)
jne iterator_is_fmsubqrne_false
cmpb $101, 8(%rax)
jne iterator_is_fmsubqrne_false
xorb %al, %al
ret
iterator_is_fmsubqrne_false:
movb $1, %al
ret

iterator_is_fmsubqrtz:
cmpq $9, iterator_token_size
jne iterator_is_fmsubqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubqrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubqrtz_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubqrtz_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubqrtz_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubqrtz_false
cmpb $113, 5(%rax)
jne iterator_is_fmsubqrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubqrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fmsubqrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fmsubqrtz_false
xorb %al, %al
ret
iterator_is_fmsubqrtz_false:
movb $1, %al
ret

iterator_is_fmsubqrup:
cmpq $9, iterator_token_size
jne iterator_is_fmsubqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubqrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubqrup_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubqrup_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubqrup_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubqrup_false
cmpb $113, 5(%rax)
jne iterator_is_fmsubqrup_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubqrup_false
cmpb $117, 7(%rax)
jne iterator_is_fmsubqrup_false
cmpb $112, 8(%rax)
jne iterator_is_fmsubqrup_false
xorb %al, %al
ret
iterator_is_fmsubqrup_false:
movb $1, %al
ret

iterator_is_fmsubsdyn:
cmpq $9, iterator_token_size
jne iterator_is_fmsubsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubsdyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubsdyn_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubsdyn_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubsdyn_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubsdyn_false
cmpb $115, 5(%rax)
jne iterator_is_fmsubsdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fmsubsdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fmsubsdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fmsubsdyn_false
xorb %al, %al
ret
iterator_is_fmsubsdyn_false:
movb $1, %al
ret

iterator_is_fmsubsrdn:
cmpq $9, iterator_token_size
jne iterator_is_fmsubsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubsrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubsrdn_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubsrdn_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubsrdn_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubsrdn_false
cmpb $115, 5(%rax)
jne iterator_is_fmsubsrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubsrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fmsubsrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fmsubsrdn_false
xorb %al, %al
ret
iterator_is_fmsubsrdn_false:
movb $1, %al
ret

iterator_is_fmsubsrmm:
cmpq $9, iterator_token_size
jne iterator_is_fmsubsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubsrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubsrmm_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubsrmm_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubsrmm_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubsrmm_false
cmpb $115, 5(%rax)
jne iterator_is_fmsubsrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmsubsrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fmsubsrmm_false
xorb %al, %al
ret
iterator_is_fmsubsrmm_false:
movb $1, %al
ret

iterator_is_fmsubsrne:
cmpq $9, iterator_token_size
jne iterator_is_fmsubsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubsrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubsrne_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubsrne_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubsrne_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubsrne_false
cmpb $115, 5(%rax)
jne iterator_is_fmsubsrne_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubsrne_false
cmpb $110, 7(%rax)
jne iterator_is_fmsubsrne_false
cmpb $101, 8(%rax)
jne iterator_is_fmsubsrne_false
xorb %al, %al
ret
iterator_is_fmsubsrne_false:
movb $1, %al
ret

iterator_is_fmsubsrtz:
cmpq $9, iterator_token_size
jne iterator_is_fmsubsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubsrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubsrtz_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubsrtz_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubsrtz_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubsrtz_false
cmpb $115, 5(%rax)
jne iterator_is_fmsubsrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubsrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fmsubsrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fmsubsrtz_false
xorb %al, %al
ret
iterator_is_fmsubsrtz_false:
movb $1, %al
ret

iterator_is_fmsubsrup:
cmpq $9, iterator_token_size
jne iterator_is_fmsubsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmsubsrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmsubsrup_false
cmpb $115, 2(%rax)
jne iterator_is_fmsubsrup_false
cmpb $117, 3(%rax)
jne iterator_is_fmsubsrup_false
cmpb $98, 4(%rax)
jne iterator_is_fmsubsrup_false
cmpb $115, 5(%rax)
jne iterator_is_fmsubsrup_false
cmpb $114, 6(%rax)
jne iterator_is_fmsubsrup_false
cmpb $117, 7(%rax)
jne iterator_is_fmsubsrup_false
cmpb $112, 8(%rax)
jne iterator_is_fmsubsrup_false
xorb %al, %al
ret
iterator_is_fmsubsrup_false:
movb $1, %al
ret

iterator_is_fmulddyn:
cmpq $8, iterator_token_size
jne iterator_is_fmulddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulddyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmulddyn_false
cmpb $117, 2(%rax)
jne iterator_is_fmulddyn_false
cmpb $108, 3(%rax)
jne iterator_is_fmulddyn_false
cmpb $100, 4(%rax)
jne iterator_is_fmulddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fmulddyn_false
cmpb $121, 6(%rax)
jne iterator_is_fmulddyn_false
cmpb $110, 7(%rax)
jne iterator_is_fmulddyn_false
xorb %al, %al
ret
iterator_is_fmulddyn_false:
movb $1, %al
ret

iterator_is_fmuldrdn:
cmpq $8, iterator_token_size
jne iterator_is_fmuldrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmuldrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmuldrdn_false
cmpb $117, 2(%rax)
jne iterator_is_fmuldrdn_false
cmpb $108, 3(%rax)
jne iterator_is_fmuldrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fmuldrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fmuldrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fmuldrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fmuldrdn_false
xorb %al, %al
ret
iterator_is_fmuldrdn_false:
movb $1, %al
ret

iterator_is_fmuldrmm:
cmpq $8, iterator_token_size
jne iterator_is_fmuldrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmuldrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmuldrmm_false
cmpb $117, 2(%rax)
jne iterator_is_fmuldrmm_false
cmpb $108, 3(%rax)
jne iterator_is_fmuldrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fmuldrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fmuldrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fmuldrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmuldrmm_false
xorb %al, %al
ret
iterator_is_fmuldrmm_false:
movb $1, %al
ret

iterator_is_fmuldrne:
cmpq $8, iterator_token_size
jne iterator_is_fmuldrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmuldrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmuldrne_false
cmpb $117, 2(%rax)
jne iterator_is_fmuldrne_false
cmpb $108, 3(%rax)
jne iterator_is_fmuldrne_false
cmpb $100, 4(%rax)
jne iterator_is_fmuldrne_false
cmpb $114, 5(%rax)
jne iterator_is_fmuldrne_false
cmpb $110, 6(%rax)
jne iterator_is_fmuldrne_false
cmpb $101, 7(%rax)
jne iterator_is_fmuldrne_false
xorb %al, %al
ret
iterator_is_fmuldrne_false:
movb $1, %al
ret

iterator_is_fmuldrtz:
cmpq $8, iterator_token_size
jne iterator_is_fmuldrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmuldrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmuldrtz_false
cmpb $117, 2(%rax)
jne iterator_is_fmuldrtz_false
cmpb $108, 3(%rax)
jne iterator_is_fmuldrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fmuldrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fmuldrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fmuldrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fmuldrtz_false
xorb %al, %al
ret
iterator_is_fmuldrtz_false:
movb $1, %al
ret

iterator_is_fmuldrup:
cmp $8, iterator_token_size
jne iterator_is_fmuldrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmuldrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmuldrup_false
cmpb $117, 2(%rax)
jne iterator_is_fmuldrup_false
cmpb $108, 3(%rax)
jne iterator_is_fmuldrup_false
cmpb $100, 4(%rax)
jne iterator_is_fmuldrup_false
cmpb $114, 5(%rax)
jne iterator_is_fmuldrup_false
cmpb $117, 6(%rax)
jne iterator_is_fmuldrup_false
cmpb $112, 7(%rax)
jne iterator_is_fmuldrup_false
xorb %al, %al
ret
iterator_is_fmuldrup_false:
movb $1, %al
ret

iterator_is_fmulqdyn:
cmpq $8, iterator_token_size
jne iterator_is_fmulqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulqdyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmulqdyn_false
cmpb $117, 2(%rax)
jne iterator_is_fmulqdyn_false
cmpb $108, 3(%rax)
jne iterator_is_fmulqdyn_false
cmpb $113, 4(%rax)
jne iterator_is_fmulqdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fmulqdyn_false
cmpb $121, 6(%rax)
jne iterator_is_fmulqdyn_false
cmpb $110, 7(%rax)
jne iterator_is_fmulqdyn_false
xorb %al, %al
ret
iterator_is_fmulqdyn_false:
movb $1, %al
ret

iterator_is_fmulqrdn:
cmpq $8, iterator_token_size
jne iterator_is_fmulqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulqrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmulqrdn_false
cmpb $117, 2(%rax)
jne iterator_is_fmulqrdn_false
cmpb $108, 3(%rax)
jne iterator_is_fmulqrdn_false
cmpb $113, 4(%rax)
jne iterator_is_fmulqrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fmulqrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fmulqrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fmulqrdn_false
xorb %al, %al
ret
iterator_is_fmulqrdn_false:
movb $1, %al
ret

iterator_is_fmulqrmm:
cmpq $8, iterator_token_size
jne iterator_is_fmulqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulqrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmulqrmm_false
cmpb $117, 2(%rax)
jne iterator_is_fmulqrmm_false
cmpb $108, 3(%rax)
jne iterator_is_fmulqrmm_false
cmpb $113, 4(%rax)
jne iterator_is_fmulqrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fmulqrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fmulqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmulqrmm_false
xorb %al, %al
ret
iterator_is_fmulqrmm_false:
movb $1, %al
ret

iterator_is_fmulqrne:
cmpq $8, iterator_token_size
jne iterator_is_fmulqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulqrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmulqrne_false
cmpb $117, 2(%rax)
jne iterator_is_fmulqrne_false
cmpb $108, 3(%rax)
jne iterator_is_fmulqrne_false
cmpb $113, 4(%rax)
jne iterator_is_fmulqrne_false
cmpb $114, 5(%rax)
jne iterator_is_fmulqrne_false
cmpb $110, 6(%rax)
jne iterator_is_fmulqrne_false
cmpb $101, 7(%rax)
jne iterator_is_fmulqrne_false
xorb %al, %al
ret
iterator_is_fmulqrne_false:
movb $1, %al
ret

iterator_is_fmulqrtz:
cmpq $8, iterator_token_size
jne iterator_is_fmulqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulqrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmulqrtz_false
cmpb $117, 2(%rax)
jne iterator_is_fmulqrtz_false
cmpb $108, 3(%rax)
jne iterator_is_fmulqrtz_false
cmpb $113, 4(%rax)
jne iterator_is_fmulqrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fmulqrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fmulqrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fmulqrtz_false
xorb %al, %al
ret
iterator_is_fmulqrtz_false:
movb $1, %al
ret

iterator_is_fmulqrup:
cmpq $8, iterator_token_size
jne iterator_is_fmulqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulqrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmulqrup_false
cmpb $117, 2(%rax)
jne iterator_is_fmulqrup_false
cmpb $108, 3(%rax)
jne iterator_is_fmulqrup_false
cmpb $113, 4(%rax)
jne iterator_is_fmulqrup_false
cmpb $114, 5(%rax)
jne iterator_is_fmulqrup_false
cmpb $117, 6(%rax)
jne iterator_is_fmulqrup_false
cmpb $112, 7(%rax)
jne iterator_is_fmulqrup_false
xorb %al, %al
ret
iterator_is_fmulqrup_false:
movb $1, %al
ret

iterator_is_fmulsdyn:
cmpq $8, iterator_token_size
jne iterator_is_fmulsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulsdyn_false
cmpb $109, 1(%rax)
jne iterator_is_fmulsdyn_false
cmpb $117, 2(%rax)
jne iterator_is_fmulsdyn_false
cmpb $108, 3(%rax)
jne iterator_is_fmulsdyn_false
cmpb $115, 4(%rax)
jne iterator_is_fmulsdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fmulsdyn_false
cmpb $121, 6(%rax)
jne iterator_is_fmulsdyn_false
cmpb $110, 7(%rax)
jne iterator_is_fmulsdyn_false
xorb %al, %al
ret
iterator_is_fmulsdyn_false:
movb $1, %al
ret

iterator_is_fmulsrdn:
cmpq $8, iterator_token_size
jne iterator_is_fmulsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulsrdn_false
cmpb $109, 1(%rax)
jne iterator_is_fmulsrdn_false
cmpb $117, 2(%rax)
jne iterator_is_fmulsrdn_false
cmpb $108, 3(%rax)
jne iterator_is_fmulsrdn_false
cmpb $115, 4(%rax)
jne iterator_is_fmulsrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fmulsrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fmulsrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fmulsrdn_false
xorb %al, %al
ret
iterator_is_fmulsrdn_false:
movb $1, %al
ret

iterator_is_fmulsrmm:
cmpq $8, iterator_token_size
jne iterator_is_fmulsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulsrmm_false
cmpb $109, 1(%rax)
jne iterator_is_fmulsrmm_false
cmpb $117, 2(%rax)
jne iterator_is_fmulsrmm_false
cmpb $108, 3(%rax)
jne iterator_is_fmulsrmm_false
cmpb $115, 4(%rax)
jne iterator_is_fmulsrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fmulsrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fmulsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fmulsrmm_false
xorb %al, %al
ret
iterator_is_fmulsrmm_false:
movb $1, %al
ret

iterator_is_fmulsrne:
cmpq $8, iterator_token_size
jne iterator_is_fmulsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulsrne_false
cmpb $109, 1(%rax)
jne iterator_is_fmulsrne_false
cmpb $117, 2(%rax)
jne iterator_is_fmulsrne_false
cmpb $108, 3(%rax)
jne iterator_is_fmulsrne_false
cmpb $115, 4(%rax)
jne iterator_is_fmulsrne_false
cmpb $114, 5(%rax)
jne iterator_is_fmulsrne_false
cmpb $110, 6(%rax)
jne iterator_is_fmulsrne_false
cmpb $101, 7(%rax)
jne iterator_is_fmulsrne_false
xorb %al, %al
ret
iterator_is_fmulsrne_false:
movb $1, %al
ret

iterator_is_fmulsrtz:
cmpq $8, iterator_token_size
jne iterator_is_fmulsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulsrtz_false
cmpb $109, 1(%rax)
jne iterator_is_fmulsrtz_false
cmpb $117, 2(%rax)
jne iterator_is_fmulsrtz_false
cmpb $108, 3(%rax)
jne iterator_is_fmulsrtz_false
cmpb $115, 4(%rax)
jne iterator_is_fmulsrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fmulsrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fmulsrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fmulsrtz_false
xorb %al, %al
ret
iterator_is_fmulsrtz_false:
movb $1, %al
ret

iterator_is_fmulsrup:
cmpq $8, iterator_token_size
jne iterator_is_fmulsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmulsrup_false
cmpb $109, 1(%rax)
jne iterator_is_fmulsrup_false
cmpb $117, 2(%rax)
jne iterator_is_fmulsrup_false
cmpb $108, 3(%rax)
jne iterator_is_fmulsrup_false
cmpb $115, 4(%rax)
jne iterator_is_fmulsrup_false
cmpb $114, 5(%rax)
jne iterator_is_fmulsrup_false
cmpb $117, 6(%rax)
jne iterator_is_fmulsrup_false
cmpb $112, 7(%rax)
jne iterator_is_fmulsrup_false
xorb %al, %al
ret
iterator_is_fmulsrup_false:
movb $1, %al
ret

iterator_is_fmvdx:
cmpq $5, iterator_token_size
jne iterator_is_fmvdx_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmvdx_false
cmpb $109, 1(%rax)
jne iterator_is_fmvdx_false
cmpb $118, 2(%rax)
jne iterator_is_fmvdx_false
cmpb $100, 3(%rax)
jne iterator_is_fmvdx_false
cmpb $120, 4(%rax)
jne iterator_is_fmvdx_false
xorb %al, %al
ret
iterator_is_fmvdx_false:
movb $1, %al
ret

iterator_is_fmvwx:
cmpq $5, iterator_token_size
jne iterator_is_fmvwx_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmvwx_false
cmpb $109, 1(%rax)
jne iterator_is_fmvwx_false
cmpb $118, 2(%rax)
jne iterator_is_fmvwx_false
cmpb $119, 3(%rax)
jne iterator_is_fmvwx_false
cmpb $120, 4(%rax)
jne iterator_is_fmvwx_false
xorb %al, %al
ret
iterator_is_fmvwx_false:
movb $1, %al
ret

iterator_is_fmvxd:
cmpq $5, iterator_token_size
jne iterator_is_fmvxd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmvxd_false
cmpb $109, 1(%rax)
jne iterator_is_fmvxd_false
cmpb $118, 2(%rax)
jne iterator_is_fmvxd_false
cmpb $120, 3(%rax)
jne iterator_is_fmvxd_false
cmpb $100, 4(%rax)
jne iterator_is_fmvxd_false
xorb %al, %al
ret
iterator_is_fmvxd_false:
movb $1, %al
ret

iterator_is_fmvxw:
cmpq $5, iterator_token_size
jne iterator_is_fmvxw_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fmvxw_false
cmpb $109, 1(%rax)
jne iterator_is_fmvxw_false
cmpb $118, 2(%rax)
jne iterator_is_fmvxw_false
cmpb $120, 3(%rax)
jne iterator_is_fmvxw_false
cmpb $119, 4(%rax)
jne iterator_is_fmvxw_false
xorb %al, %al
ret
iterator_is_fmvxw_false:
movb $1, %al
ret

iterator_is_fnmaddddyn:
cmpb $10, iterator_token_size
jne iterator_is_fnmaddddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddddyn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $100, 7(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $121, 8(%rax)
jne iterator_is_fnmaddddyn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmaddddyn_false
xorb %al, %al
ret
iterator_is_fnmaddddyn_false:
movb $1, %al
ret

iterator_is_fnmadddrdn:
cmpq $10, iterator_token_size
jne iterator_is_fnmadddrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmadddrdn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $97, 3(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fnmadddrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmadddrdn_false
xorb %al, %al
ret
iterator_is_fnmadddrdn_false:
movb $1, %al
ret

iterator_is_fnmadddrmm:
cmpq $10, iterator_token_size
jne iterator_is_fnmadddrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmadddrmm_false
cmpb $110, 1(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $109, 2(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $97, 3(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $100, 6(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fnmadddrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fnmadddrmm_false
xorb %al, %al
ret
iterator_is_fnmadddrmm_false:
movb $1, %al
ret

iterator_is_fnmadddrne:
cmpq $10, iterator_token_size
jne iterator_is_fnmadddrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmadddrne_false
cmpb $110, 1(%rax)
jne iterator_is_fnmadddrne_false
cmpb $109, 2(%rax)
jne iterator_is_fnmadddrne_false
cmpb $97, 3(%rax)
jne iterator_is_fnmadddrne_false
cmpb $100, 4(%rax)
jne iterator_is_fnmadddrne_false
cmpb $100, 5(%rax)
jne iterator_is_fnmadddrne_false
cmpb $100, 6(%rax)
jne iterator_is_fnmadddrne_false
cmpb $114, 7(%rax)
jne iterator_is_fnmadddrne_false
cmpb $110, 8(%rax)
jne iterator_is_fnmadddrne_false
cmpb $101, 9(%rax)
jne iterator_is_fnmadddrne_false
xorb %al, %al
ret
iterator_is_fnmadddrne_false:
movb $1, %al
ret

iterator_is_fnmadddrtz:
cmpq $10, iterator_token_size
jne iterator_is_fnmadddrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmadddrtz_false
cmpb $110, 1(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $109, 2(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $97, 3(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $100, 6(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fnmadddrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fnmadddrtz_false
xorb %al, %al
ret
iterator_is_fnmadddrtz_false:
movb $1, %al
ret

iterator_is_fnmadddrup:
cmpq $10, iterator_token_size
jne iterator_is_fnmadddrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmadddrup_false
cmpb $110, 1(%rax)
jne iterator_is_fnmadddrup_false
cmpb $109, 2(%rax)
jne iterator_is_fnmadddrup_false
cmpb $97, 3(%rax)
jne iterator_is_fnmadddrup_false
cmpb $100, 4(%rax)
jne iterator_is_fnmadddrup_false
cmpb $100, 5(%rax)
jne iterator_is_fnmadddrup_false
cmpb $100, 6(%rax)
jne iterator_is_fnmadddrup_false
cmpb $114, 7(%rax)
jne iterator_is_fnmadddrup_false
cmpb $117, 8(%rax)
jne iterator_is_fnmadddrup_false
cmpb $112, 9(%rax)
jne iterator_is_fnmadddrup_false
xorb %al, %al
ret
iterator_is_fnmadddrup_false:
movb $1, %al
ret

iterator_is_fnmaddqdyn:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $113, 6(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fnmaddqdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmaddqdyn_false
xorb %al, %al
ret
iterator_is_fnmaddqdyn_false:
movb $1, %al
ret

iterator_is_fnmaddqrdn:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $113, 6(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fnmaddqrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmaddqrdn_false
xorb %al, %al
ret
iterator_is_fnmaddqrdn_false:
movb $1, %al
ret

iterator_is_fnmaddqrmm:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $113, 6(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fnmaddqrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fnmaddqrmm_false
xorb %al, %al
ret
iterator_is_fnmaddqrmm_false:
movb $1, %al
ret

iterator_is_fnmaddqrne:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddqrne_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $113, 6(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $110, 8(%rax)
jne iterator_is_fnmaddqrne_false
cmpb $101, 9(%rax)
jne iterator_is_fnmaddqrne_false
xorb %al, %al
ret
iterator_is_fnmaddqrne_false:
movb $1, %al
ret

iterator_is_fnmaddqrtz:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $113, 6(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fnmaddqrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fnmaddqrtz_false
xorb %al, %al
ret
iterator_is_fnmaddqrtz_false:
movb $1, %al
ret

iterator_is_fnmaddqrup:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddqrup_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $113, 6(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $117, 8(%rax)
jne iterator_is_fnmaddqrup_false
cmpb $112, 9(%rax)
jne iterator_is_fnmaddqrup_false
xorb %al, %al
ret
iterator_is_fnmaddqrup_false:
movb $1, %al
ret

iterator_is_fnmaddsdyn:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $115, 6(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fnmaddsdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmaddsdyn_false
xorb %al, %al
ret
iterator_is_fnmaddsdyn_false:
movb $1, %al
ret

iterator_is_fnmaddsrdn:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $115, 6(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fnmaddsrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmaddsrdn_false
xorb %al, %al
ret
iterator_is_fnmaddsrdn_false:
movb $1, %al
ret

iterator_is_fnmaddsrmm:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $115, 6(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fnmaddsrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fnmaddsrmm_false
xorb %al, %al
ret
iterator_is_fnmaddsrmm_false:
movb $1, %al
ret

iterator_is_fnmaddsrne:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddsrne_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $115, 6(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $110, 8(%rax)
jne iterator_is_fnmaddsrne_false
cmpb $101, 9(%rax)
jne iterator_is_fnmaddsrne_false
xorb %al, %al
ret
iterator_is_fnmaddsrne_false:
movb $1, %al
ret

iterator_is_fnmaddsrtz:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $115, 6(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fnmaddsrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fnmaddsrtz_false
xorb %al, %al
ret
iterator_is_fnmaddsrtz_false:
movb $1, %al
ret

iterator_is_fnmaddsrup:
cmpq $10, iterator_token_size
jne iterator_is_fnmaddsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmaddsrup_false
cmpb $110, 1(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $109, 2(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $97, 3(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $100, 4(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $100, 5(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $115, 6(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $114, 7(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $117, 8(%rax)
jne iterator_is_fnmaddsrup_false
cmpb $112, 9(%rax)
jne iterator_is_fnmaddsrup_false
xorb %al, %al
ret
iterator_is_fnmaddsrup_false:
movb $1, %al
ret

iterator_is_fnmsubddyn:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubddyn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $100, 7(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $121, 8(%rax)
jne iterator_is_fnmsubddyn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmsubddyn_false
xorb %al, %al
ret
iterator_is_fnmsubddyn_false:
movb $1, %al
ret

iterator_is_fnmsubdrdn:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubdrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fnmsubdrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmsubdrdn_false
xorb %al, %al
ret
iterator_is_fnmsubdrdn_false:
movb $1, %al
ret

iterator_is_fnmsubdrmm:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubdrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $100, 6(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fnmsubdrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fnmsubdrmm_false
xorb %al, %al
ret
iterator_is_fnmsubdrmm_false:
movb $1, %al
ret

iterator_is_fnmsubdrne:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubdrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubdrne_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $100, 6(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $110, 8(%rax)
jne iterator_is_fnmsubdrne_false
cmpb $101, 9(%rax)
jne iterator_is_fnmsubdrne_false
xorb %al, %al
ret
iterator_is_fnmsubdrne_false:
movb $1, %al
ret

iterator_is_fnmsubdrtz:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubdrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $100, 6(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fnmsubdrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fnmsubdrtz_false
xorb %al, %al
ret
iterator_is_fnmsubdrtz_false:
movb $1, %al
ret

iterator_is_fnmsubdrup:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubdrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubdrup_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $100, 6(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $117, 8(%rax)
jne iterator_is_fnmsubdrup_false
cmpb $112, 9(%rax)
jne iterator_is_fnmsubdrup_false
xorb %al, %al
ret
iterator_is_fnmsubdrup_false:
movb $1, %al
ret

iterator_is_fnmsubqdyn:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $113, 6(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fnmsubqdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmsubqdyn_false
xorb %al, %al
ret
iterator_is_fnmsubqdyn_false:
movb $1, %al
ret

iterator_is_fnmsubqrdn:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $113, 6(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fnmsubqrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmsubqrdn_false
xorb %al, %al
ret
iterator_is_fnmsubqrdn_false:
movb $1, %al
ret

iterator_is_fnmsubqrmm:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $113, 6(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fnmsubqrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fnmsubqrmm_false
xorb %al, %al
ret
iterator_is_fnmsubqrmm_false:
movb $1, %al
ret

iterator_is_fnmsubqrne:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubqrne_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $113, 6(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $110, 8(%rax)
jne iterator_is_fnmsubqrne_false
cmpb $101, 9(%rax)
jne iterator_is_fnmsubqrne_false
xorb %al, %al
ret
iterator_is_fnmsubqrne_false:
movb $1, %al
ret

iterator_is_fnmsubqrtz:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $113, 6(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fnmsubqrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fnmsubqrtz_false
xorb %al, %al
ret
iterator_is_fnmsubqrtz_false:
movb $1, %al
ret

iterator_is_fnmsubqrup:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubqrup_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $113, 6(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $117, 8(%rax)
jne iterator_is_fnmsubqrup_false
cmpb $112, 9(%rax)
jne iterator_is_fnmsubqrup_false
xorb %al, %al
ret
iterator_is_fnmsubqrup_false:
movb $1, %al
ret

iterator_is_fnmsubsdyn:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $115, 6(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $100, 7(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $121, 8(%rax)
jne iterator_is_fnmsubsdyn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmsubsdyn_false
xorb %al, %al
ret
iterator_is_fnmsubsdyn_false:
movb $1, %al
ret

iterator_is_fnmsubsrdn:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $115, 6(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $100, 8(%rax)
jne iterator_is_fnmsubsrdn_false
cmpb $110, 9(%rax)
jne iterator_is_fnmsubsrdn_false
xorb %al, %al
ret
iterator_is_fnmsubsrdn_false:
movb $1, %al
ret

iterator_is_fnmsubsrmm:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $115, 6(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fnmsubsrmm_false
cmpb $109, 9(%rax)
jne iterator_is_fnmsubsrmm_false
xorb %al, %al
ret
iterator_is_fnmsubsrmm_false:
movb $1, %al
ret

iterator_is_fnmsubsrne:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubsrne_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $115, 6(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $110, 8(%rax)
jne iterator_is_fnmsubsrne_false
cmpb $101, 9(%rax)
jne iterator_is_fnmsubsrne_false
xorb %al, %al
ret
iterator_is_fnmsubsrne_false:
movb $1, %al
ret

iterator_is_fnmsubsrtz:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $115, 6(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $116, 8(%rax)
jne iterator_is_fnmsubsrtz_false
cmpb $122, 9(%rax)
jne iterator_is_fnmsubsrtz_false
xorb %al, %al
ret
iterator_is_fnmsubsrtz_false:
movb $1, %al
ret

iterator_is_fnmsubsrup:
cmpq $10, iterator_token_size
jne iterator_is_fnmsubsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fnmsubsrup_false
cmpb $110, 1(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $109, 2(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $115, 3(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $117, 4(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $98, 5(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $115, 6(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $114, 7(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $117, 8(%rax)
jne iterator_is_fnmsubsrup_false
cmpb $112, 9(%rax)
jne iterator_is_fnmsubsrup_false
xorb %al, %al
ret
iterator_is_fnmsubsrup_false:
movb $1, %al
ret

iterator_is_fsd:
cmpq $3, iterator_token_size
jne iterator_is_fsd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsd_false
cmpb $115, 1(%rax)
jne iterator_is_fsd_false
cmpb $100, 2(%rax)
jne iterator_is_fsd_false
xorb %al, %al
ret
iterator_is_fsd_false:
movb $1, %al
ret

iterator_is_fsgnjd:
cmpq $6, iterator_token_size
jne iterator_is_fsgnjd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjd_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjd_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjd_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjd_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjd_false
cmpb $100, 5(%rax)
jne iterator_is_fsgnjd_false
xorb %al, %al
ret
iterator_is_fsgnjd_false:
movb $1, %al
ret

iterator_is_fsgnjnd:
cmpq $7, iterator_token_size
jne iterator_is_fsgnjnd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjnd_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjnd_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjnd_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjnd_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjnd_false
cmpb $110, 5(%rax)
jne iterator_is_fsgnjnd_false
cmpb $100, 6(%rax)
jne iterator_is_fsgnjnd_false
xorb %al, %al
ret
iterator_is_fsgnjnd_false:
movb $1, %al
ret

iterator_is_fsgnjnq:
cmpq $7, iterator_token_size
jne iterator_is_fsgnjnq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjnq_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjnq_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjnq_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjnq_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjnq_false
cmpb $110, 5(%rax)
jne iterator_is_fsgnjnq_false
cmpb $113, 6(%rax)
jne iterator_is_fsgnjnq_false
xorb %al, %al
ret
iterator_is_fsgnjnq_false:
movb $1, %al
ret

iterator_is_fsgnjns:
cmpq $7, iterator_token_size
jne iterator_is_fsgnjns_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjns_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjns_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjns_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjns_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjns_false
cmpb $110, 5(%rax)
jne iterator_is_fsgnjns_false
cmpb $115, 6(%rax)
jne iterator_is_fsgnjns_false
xorb %al, %al
ret
iterator_is_fsgnjns_false:
movb $1, %al
ret

iterator_is_fsgnjq:
cmpq $6, iterator_token_size
jne iterator_is_fsgnjq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjq_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjq_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjq_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjq_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjq_false
cmpb $113, 5(%rax)
jne iterator_is_fsgnjq_false
xorb %al, %al
ret
iterator_is_fsgnjq_false:
movb $1, %al
ret

iterator_is_fsgnjs:
cmpq $6, iterator_token_size
jne iterator_is_fsgnjs_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjs_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjs_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjs_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjs_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjs_false
cmpb $115, 5(%rax)
jne iterator_is_fsgnjs_false
xorb %al, %al
ret
iterator_is_fsgnjs_false:
movb $1, %al
ret

iterator_is_fsgnjxd:
cmpq $7, iterator_token_size
jne iterator_is_fsgnjxd_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjxd_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjxd_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjxd_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjxd_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjxd_false
cmpb $120, 5(%rax)
jne iterator_is_fsgnjxd_false
cmpb $100, 6(%rax)
jne iterator_is_fsgnjxd_false
xorb %al, %al
ret
iterator_is_fsgnjxd_false:
movb $1, %al
ret

iterator_is_fsgnjxq:
cmpq $7, iterator_token_size
jne iterator_is_fsgnjxq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjxq_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjxq_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjxq_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjxq_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjxq_false
cmpb $120, 5(%rax)
jne iterator_is_fsgnjxq_false
cmpb $113, 6(%rax)
jne iterator_is_fsgnjxq_false
xorb %al, %al
ret
iterator_is_fsgnjxq_false:
movb $1, %al
ret

iterator_is_fsgnjxs:
cmpq $7, iterator_token_size
jne iterator_is_fsgnjxs_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsgnjxs_false
cmpb $115, 1(%rax)
jne iterator_is_fsgnjxs_false
cmpb $103, 2(%rax)
jne iterator_is_fsgnjxs_false
cmpb $110, 3(%rax)
jne iterator_is_fsgnjxs_false
cmpb $106, 4(%rax)
jne iterator_is_fsgnjxs_false
cmpb $120, 5(%rax)
jne iterator_is_fsgnjxs_false
cmpb $115, 6(%rax)
jne iterator_is_fsgnjxs_false
xorb %al, %al
ret
iterator_is_fsgnjxs_false:
movb $1, %al
ret

iterator_is_fsq:
cmpq $3, iterator_token_size
jne iterator_is_fsq_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsq_false
cmpb $115, 1(%rax)
jne iterator_is_fsq_false
cmpb $113, 2(%rax)
jne iterator_is_fsq_false
xorb %al, %al
ret
iterator_is_fsq_false:
movb $1, %al
ret

iterator_is_fsqrtddyn:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtddyn_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtddyn_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtddyn_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtddyn_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fsqrtddyn_false
cmpb $100, 6(%rax)
jne iterator_is_fsqrtddyn_false
cmpb $121, 7(%rax)
jne iterator_is_fsqrtddyn_false
cmpb $110, 8(%rax)
jne iterator_is_fsqrtddyn_false
xorb %al, %al
ret
iterator_is_fsqrtddyn_false:
movb $1, %al
ret

iterator_is_fsqrtdrdn:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtdrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $100, 5(%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fsqrtdrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fsqrtdrdn_false
xorb %al, %al
ret
iterator_is_fsqrtdrdn_false:
movb $1, %al
ret

iterator_is_fsqrtdrmm:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtdrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $100, 5(%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fsqrtdrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fsqrtdrmm_false
xorb %al, %al
ret
iterator_is_fsqrtdrmm_false:
movb $1, %al
ret

iterator_is_fsqrtdrne:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtdrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtdrne_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtdrne_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtdrne_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtdrne_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtdrne_false
cmpb $100, 5(%rax)
jne iterator_is_fsqrtdrne_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtdrne_false
cmpb $110, 7(%rax)
jne iterator_is_fsqrtdrne_false
cmpb $101, 8(%rax)
jne iterator_is_fsqrtdrne_false
xorb %al, %al
ret
iterator_is_fsqrtdrne_false:
movb $1, %al
ret

iterator_is_fsqrtdrtz:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtdrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $100, 5(%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fsqrtdrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fsqrtdrtz_false
xorb %al, %al
ret
iterator_is_fsqrtdrtz_false:
movb $1, %al
ret

iterator_is_fsqrtdrup:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtdrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtdrup_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtdrup_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtdrup_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtdrup_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtdrup_false
cmpb $100, 5(%rax)
jne iterator_is_fsqrtdrup_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtdrup_false
cmpb $117, 7(%rax)
jne iterator_is_fsqrtdrup_false
cmpb $112, 8(%rax)
jne iterator_is_fsqrtdrup_false
xorb %al, %al
ret
iterator_is_fsqrtdrup_false:
movb $1, %al
ret

iterator_is_fsqrtqdyn:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $113, 5(%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fsqrtqdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fsqrtqdyn_false
xorb %al, %al
ret
iterator_is_fsqrtqdyn_false:
movb $1, %al
ret

iterator_is_fsqrtqrdn:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $113, 5(%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fsqrtqrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fsqrtqrdn_false
xorb %al, %al
ret
iterator_is_fsqrtqrdn_false:
movb $1, %al
ret

iterator_is_fsqrtqrmm:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $113, 5(%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fsqrtqrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fsqrtqrmm_false
xorb %al, %al
ret
iterator_is_fsqrtqrmm_false:
movb $1, %al
ret

iterator_is_fsqrtqrne:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtqrne_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtqrne_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtqrne_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtqrne_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtqrne_false
cmpb $113, 5(%rax)
jne iterator_is_fsqrtqrne_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtqrne_false
cmpb $110, 7(%rax)
jne iterator_is_fsqrtqrne_false
cmpb $101, 8(%rax)
jne iterator_is_fsqrtqrne_false
xorb %al, %al
ret
iterator_is_fsqrtqrne_false:
movb $1, %al
ret

iterator_is_fsqrtqrtz:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $113, 5(%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fsqrtqrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fsqrtqrtz_false
xorb %al, %al
ret
iterator_is_fsqrtqrtz_false:
movb $1, %al
ret

iterator_is_fsqrtqrup:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtqrup_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtqrup_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtqrup_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtqrup_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtqrup_false
cmpb $113, 5(%rax)
jne iterator_is_fsqrtqrup_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtqrup_false
cmpb $117, 7(%rax)
jne iterator_is_fsqrtqrup_false
cmpb $112, 8(%rax)
jne iterator_is_fsqrtqrup_false
xorb %al, %al
ret
iterator_is_fsqrtqrup_false:
movb $1, %al
ret

iterator_is_fsqrtsdyn:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $115, 5(%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $100, 6(%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $121, 7(%rax)
jne iterator_is_fsqrtsdyn_false
cmpb $110, 8(%rax)
jne iterator_is_fsqrtsdyn_false
xorb %al, %al
ret
iterator_is_fsqrtsdyn_false:
movb $1, %al
ret

iterator_is_fsqrtsrdn:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $115, 5(%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $100, 7(%rax)
jne iterator_is_fsqrtsrdn_false
cmpb $110, 8(%rax)
jne iterator_is_fsqrtsrdn_false
xorb %al, %al
ret
iterator_is_fsqrtsrdn_false:
movb $1, %al
ret

iterator_is_fsqrtsrmm:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $115, 5(%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fsqrtsrmm_false
cmpb $109, 8(%rax)
jne iterator_is_fsqrtsrmm_false
xorb %al, %al
ret
iterator_is_fsqrtsrmm_false:
movb $1, %al
ret

iterator_is_fsqrtsrne:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtsrne_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtsrne_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtsrne_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtsrne_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtsrne_false
cmpb $115, 5(%rax)
jne iterator_is_fsqrtsrne_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtsrne_false
cmpb $110, 7(%rax)
jne iterator_is_fsqrtsrne_false
cmpb $101, 8(%rax)
jne iterator_is_fsqrtsrne_false
xorb %al, %al
ret
iterator_is_fsqrtsrne_false:
movb $1, %al
ret

iterator_is_fsqrtsrtz:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $115, 5(%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $116, 7(%rax)
jne iterator_is_fsqrtsrtz_false
cmpb $122, 8(%rax)
jne iterator_is_fsqrtsrtz_false
xorb %al, %al
ret
iterator_is_fsqrtsrtz_false:
movb $1, %al
ret

iterator_is_fsqrtsrup:
cmpq $9, iterator_token_size
jne iterator_is_fsqrtsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsqrtsrup_false
cmpb $115, 1(%rax)
jne iterator_is_fsqrtsrup_false
cmpb $113, 2(%rax)
jne iterator_is_fsqrtsrup_false
cmpb $114, 3(%rax)
jne iterator_is_fsqrtsrup_false
cmpb $116, 4(%rax)
jne iterator_is_fsqrtsrup_false
cmpb $115, 5(%rax)
jne iterator_is_fsqrtsrup_false
cmpb $114, 6(%rax)
jne iterator_is_fsqrtsrup_false
cmpb $117, 7(%rax)
jne iterator_is_fsqrtsrup_false
cmpb $112, 8(%rax)
jne iterator_is_fsqrtsrup_false
xorb %al, %al
ret
iterator_is_fsqrtsrup_false:
movb $1, %al
ret

iterator_is_fsubddyn:
cmpq $8, iterator_token_size
jne iterator_is_fsubddyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubddyn_false
cmpb $115, 1(%rax)
jne iterator_is_fsubddyn_false
cmpb $117, 2(%rax)
jne iterator_is_fsubddyn_false
cmpb $98, 3(%rax)
jne iterator_is_fsubddyn_false
cmpb $100, 4(%rax)
jne iterator_is_fsubddyn_false
cmpb $100, 5(%rax)
jne iterator_is_fsubddyn_false
cmpb $121, 6(%rax)
jne iterator_is_fsubddyn_false
cmpb $110, 7(%rax)
jne iterator_is_fsubddyn_false
xorb %al, %al
ret
iterator_is_fsubddyn_false:
movb $1, %al
ret

iterator_is_fsubdrdn:
cmpq $8, iterator_token_size
jne iterator_is_fsubdrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubdrdn_false
cmpb $115, 1(%rax)
jne iterator_is_fsubdrdn_false
cmpb $117, 2(%rax)
jne iterator_is_fsubdrdn_false
cmpb $98, 3(%rax)
jne iterator_is_fsubdrdn_false
cmpb $100, 4(%rax)
jne iterator_is_fsubdrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fsubdrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fsubdrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fsubdrdn_false
xorb %al, %al
ret
iterator_is_fsubdrdn_false:
movb $1, %al
ret

iterator_is_fsubdrmm:
cmpq $8, iterator_token_size
jne iterator_is_fsubdrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubdrmm_false
cmpb $115, 1(%rax)
jne iterator_is_fsubdrmm_false
cmpb $117, 2(%rax)
jne iterator_is_fsubdrmm_false
cmpb $98, 3(%rax)
jne iterator_is_fsubdrmm_false
cmpb $100, 4(%rax)
jne iterator_is_fsubdrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fsubdrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fsubdrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fsubdrmm_false
xorb %al, %al
ret
iterator_is_fsubdrmm_false:
movb $1, %al
ret

iterator_is_fsubdrne:
cmpq $8, iterator_token_size
jne iterator_is_fsubdrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubdrne_false
cmpb $115, 1(%rax)
jne iterator_is_fsubdrne_false
cmpb $117, 2(%rax)
jne iterator_is_fsubdrne_false
cmpb $98, 3(%rax)
jne iterator_is_fsubdrne_false
cmpb $100, 4(%rax)
jne iterator_is_fsubdrne_false
cmpb $114, 5(%rax)
jne iterator_is_fsubdrne_false
cmpb $110, 6(%rax)
jne iterator_is_fsubdrne_false
cmpb $101, 7(%rax)
jne iterator_is_fsubdrne_false
xorb %al, %al
ret
iterator_is_fsubdrne_false:
movb $1, %al
ret

iterator_is_fsubdrtz:
cmpq $8, iterator_token_size
jne iterator_is_fsubdrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubdrtz_false
cmpb $115, 1(%rax)
jne iterator_is_fsubdrtz_false
cmpb $117, 2(%rax)
jne iterator_is_fsubdrtz_false
cmpb $98, 3(%rax)
jne iterator_is_fsubdrtz_false
cmpb $100, 4(%rax)
jne iterator_is_fsubdrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fsubdrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fsubdrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fsubdrtz_false
xorb %al, %al
ret
iterator_is_fsubdrtz_false:
movb $1, %al
ret

iterator_is_fsubdrup:
cmpq $8, iterator_token_size
jne iterator_is_fsubdrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubdrup_false
cmpb $115, 1(%rax)
jne iterator_is_fsubdrup_false
cmpb $117, 2(%rax)
jne iterator_is_fsubdrup_false
cmpb $98, 3(%rax)
jne iterator_is_fsubdrup_false
cmpb $100, 4(%rax)
jne iterator_is_fsubdrup_false
cmpb $114, 5(%rax)
jne iterator_is_fsubdrup_false
cmpb $117, 6(%rax)
jne iterator_is_fsubdrup_false
cmpb $112, 7(%rax)
jne iterator_is_fsubdrup_false
xorb %al, %al
ret
iterator_is_fsubdrup_false:
movb $1, %al
ret

iterator_is_fsubqdyn:
cmpb $8, iterator_token_size
jne iterator_is_fsubqdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubqdyn_false
cmpb $115, 1(%rax)
jne iterator_is_fsubqdyn_false
cmpb $117, 2(%rax)
jne iterator_is_fsubqdyn_false
cmpb $98, 3(%rax)
jne iterator_is_fsubqdyn_false
cmpb $113, 4(%rax)
jne iterator_is_fsubqdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fsubqdyn_false
cmpb $121, 6(%rax)
jne iterator_is_fsubqdyn_false
cmpb $110, 7(%rax)
jne iterator_is_fsubqdyn_false
xorb %al, %al
ret
iterator_is_fsubqdyn_false:
movb $1, %al
ret

iterator_is_fsubqrdn:
cmpq $8, iterator_token_size
jne iterator_is_fsubqrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubqrdn_false
cmpb $115, 1(%rax)
jne iterator_is_fsubqrdn_false
cmpb $117, 2(%rax)
jne iterator_is_fsubqrdn_false
cmpb $98, 3(%rax)
jne iterator_is_fsubqrdn_false
cmpb $113, 4(%rax)
jne iterator_is_fsubqrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fsubqrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fsubqrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fsubqrdn_false
xorb %al, %al
ret
iterator_is_fsubqrdn_false:
movb $1, %al
ret

iterator_is_fsubqrmm:
cmpq $8, iterator_token_size
jne iterator_is_fsubqrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubqrmm_false
cmpb $115, 1(%rax)
jne iterator_is_fsubqrmm_false
cmpb $117, 2(%rax)
jne iterator_is_fsubqrmm_false
cmpb $98, 3(%rax)
jne iterator_is_fsubqrmm_false
cmpb $113, 4(%rax)
jne iterator_is_fsubqrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fsubqrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fsubqrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fsubqrmm_false
xorb %al, %al
ret
iterator_is_fsubqrmm_false:
movb $1, %al
ret

iterator_is_fsubqrne:
cmpq $8, iterator_token_size
jne iterator_is_fsubqrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubqrne_false
cmpb $115, 1(%rax)
jne iterator_is_fsubqrne_false
cmpb $117, 2(%rax)
jne iterator_is_fsubqrne_false
cmpb $98, 3(%rax)
jne iterator_is_fsubqrne_false
cmpb $113, 4(%rax)
jne iterator_is_fsubqrne_false
cmpb $114, 5(%rax)
jne iterator_is_fsubqrne_false
cmpb $110, 6(%rax)
jne iterator_is_fsubqrne_false
cmpb $101, 7(%rax)
jne iterator_is_fsubqrne_false
xorb %al, %al
ret
iterator_is_fsubqrne_false:
movb $1, %al
ret

iterator_is_fsubqrtz:
cmpq $8, iterator_token_size
jne iterator_is_fsubqrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubqrtz_false
cmpb $115, 1(%rax)
jne iterator_is_fsubqrtz_false
cmpb $117, 2(%rax)
jne iterator_is_fsubqrtz_false
cmpb $98, 3(%rax)
jne iterator_is_fsubqrtz_false
cmpb $113, 4(%rax)
jne iterator_is_fsubqrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fsubqrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fsubqrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fsubqrtz_false
xorb %al, %al
ret
iterator_is_fsubqrtz_false:
movb $1, %al
ret

iterator_is_fsubqrup:
cmpq $8, iterator_token_size
jne iterator_is_fsubqrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubqrup_false
cmpb $115, 1(%rax)
jne iterator_is_fsubqrup_false
cmpb $117, 2(%rax)
jne iterator_is_fsubqrup_false
cmpb $98, 3(%rax)
jne iterator_is_fsubqrup_false
cmpb $113, 4(%rax)
jne iterator_is_fsubqrup_false
cmpb $114, 5(%rax)
jne iterator_is_fsubqrup_false
cmpb $117, 6(%rax)
jne iterator_is_fsubqrup_false
cmpb $112, 7(%rax)
jne iterator_is_fsubqrup_false
xorb %al, %al
ret
iterator_is_fsubqrup_false:
movb $1, %al
ret

iterator_is_fsubsdyn:
cmpq $8, iterator_token_size
jne iterator_is_fsubsdyn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubsdyn_false
cmpb $115, 1(%rax)
jne iterator_is_fsubsdyn_false
cmpb $117, 2(%rax)
jne iterator_is_fsubsdyn_false
cmpb $98, 3(%rax)
jne iterator_is_fsubsdyn_false
cmpb $115, 4(%rax)
jne iterator_is_fsubsdyn_false
cmpb $100, 5(%rax)
jne iterator_is_fsubsdyn_false
cmpb $121, 6(%rax)
jne iterator_is_fsubsdyn_false
cmpb $110, 7(%rax)
jne iterator_is_fsubsdyn_false
xorb %al, %al
ret
iterator_is_fsubsdyn_false:
movb $1, %al
ret

iterator_is_fsubsrdn:
cmpq $8, iterator_token_size
jne iterator_is_fsubsrdn_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubsrdn_false
cmpb $115, 1(%rax)
jne iterator_is_fsubsrdn_false
cmpb $117, 2(%rax)
jne iterator_is_fsubsrdn_false
cmpb $98, 3(%rax)
jne iterator_is_fsubsrdn_false
cmpb $115, 4(%rax)
jne iterator_is_fsubsrdn_false
cmpb $114, 5(%rax)
jne iterator_is_fsubsrdn_false
cmpb $100, 6(%rax)
jne iterator_is_fsubsrdn_false
cmpb $110, 7(%rax)
jne iterator_is_fsubsrdn_false
xorb %al, %al
ret
iterator_is_fsubsrdn_false:
movb $1, %al
ret

iterator_is_fsubsrmm:
cmpq $8, iterator_token_size
jne iterator_is_fsubsrmm_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubsrmm_false
cmpb $115, 1(%rax)
jne iterator_is_fsubsrmm_false
cmpb $117, 2(%rax)
jne iterator_is_fsubsrmm_false
cmpb $98, 3(%rax)
jne iterator_is_fsubsrmm_false
cmpb $115, 4(%rax)
jne iterator_is_fsubsrmm_false
cmpb $114, 5(%rax)
jne iterator_is_fsubsrmm_false
cmpb $109, 6(%rax)
jne iterator_is_fsubsrmm_false
cmpb $109, 7(%rax)
jne iterator_is_fsubsrmm_false
xorb %al, %al
ret
iterator_is_fsubsrmm_false:
movb $1, %al
ret

iterator_is_fsubsrne:
cmpq $8, iterator_token_size
jne iterator_is_fsubsrne_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubsrne_false
cmpb $115, 1(%rax)
jne iterator_is_fsubsrne_false
cmpb $117, 2(%rax)
jne iterator_is_fsubsrne_false
cmpb $98, 3(%rax)
jne iterator_is_fsubsrne_false
cmpb $115, 4(%rax)
jne iterator_is_fsubsrne_false
cmpb $114, 5(%rax)
jne iterator_is_fsubsrne_false
cmpb $110, 6(%rax)
jne iterator_is_fsubsrne_false
cmpb $101, 7(%rax)
jne iterator_is_fsubsrne_false
xorb %al, %al
ret
iterator_is_fsubsrne_false:
movb $1, %al
ret

iterator_is_fsubsrtz:
cmpq $8, iterator_token_size
jne iterator_is_fsubsrtz_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubsrtz_false
cmpb $115, 1(%rax)
jne iterator_is_fsubsrtz_false
cmpb $117, 2(%rax)
jne iterator_is_fsubsrtz_false
cmpb $98, 3(%rax)
jne iterator_is_fsubsrtz_false
cmpb $115, 4(%rax)
jne iterator_is_fsubsrtz_false
cmpb $114, 5(%rax)
jne iterator_is_fsubsrtz_false
cmpb $116, 6(%rax)
jne iterator_is_fsubsrtz_false
cmpb $122, 7(%rax)
jne iterator_is_fsubsrtz_false
xorb %al, %al
ret
iterator_is_fsubsrtz_false:
movb $1, %al
ret

iterator_is_fsubsrup:
cmpq $8, iterator_token_size
jne iterator_is_fsubsrup_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsubsrup_false
cmpb $115, 1(%rax)
jne iterator_is_fsubsrup_false
cmpb $117, 2(%rax)
jne iterator_is_fsubsrup_false
cmpb $98, 3(%rax)
jne iterator_is_fsubsrup_false
cmpb $115, 4(%rax)
jne iterator_is_fsubsrup_false
cmpb $114, 5(%rax)
jne iterator_is_fsubsrup_false
cmpb $117, 6(%rax)
jne iterator_is_fsubsrup_false
cmpb $112, 7(%rax)
jne iterator_is_fsubsrup_false
xorb %al, %al
ret
iterator_is_fsubsrup_false:
movb $1, %al
ret

iterator_is_fsw:
cmpq $3, iterator_token_size
jne iterator_is_fsw_false
movq iterator_current_character, %rax
cmpb $102, (%rax)
jne iterator_is_fsw_false
cmpb $115, 1(%rax)
jne iterator_is_fsw_false
cmpb $119, 2(%rax)
jne iterator_is_fsw_false
xorb %al, %al
ret
iterator_is_fsw_false:
movb $1, %al
ret

iterator_is_jal:
cmpq $3, iterator_token_size
jne iterator_is_jal_false
movq iterator_current_character, %rax
cmpb $106, (%rax)
jne iterator_is_jal_false
cmpb $97, 1(%rax)
jne iterator_is_jal_false
cmpb $108, 2(%rax)
jne iterator_is_jal_false
xorb %al, %al
ret
iterator_is_jal_false:
movb $1, %al
ret

iterator_is_jalr:
cmpq $4, iterator_token_size
jne iterator_is_jalr_false
movq iterator_current_character, %rax
cmpb $106, (%rax)
jne iterator_is_jalr_false
cmpb $97, 1(%rax)
jne iterator_is_jalr_false
cmpb $108, 2(%rax)
jne iterator_is_jalr_false
cmpb $114, 3(%rax)
jne iterator_is_jalr_false
xorb %al, %al
ret
iterator_is_jalr_false:
movb $1, %al
ret

iterator_is_lb:
cmpq $2, iterator_token_size
jne iterator_is_lb_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lb_false
cmpb $98, 1(%rax)
jne iterator_is_lb_false
xorb %al, %al
ret
iterator_is_lb_false:
movb $1, %al
ret

iterator_is_lbu:
cmpq $3, iterator_token_size
jne iterator_is_lbu_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lbu_false
cmpb $98, 1(%rax)
jne iterator_is_lbu_false
cmpb $117, 2(%rax)
jne iterator_is_lbu_false
xorb %al, %al
ret
iterator_is_lbu_false:
movb $1, %al
ret

iterator_is_ld:
cmpq $2, iterator_token_size
jne iterator_is_ld_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_ld_false
cmpb $100, 1(%rax)
jne iterator_is_ld_false
xorb %al, %al
ret
iterator_is_ld_false:
movb $1, %al
ret

iterator_is_lh:
cmpq $2, iterator_token_size
jne iterator_is_lh_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lh_false
cmpb $104, 1(%rax)
jne iterator_is_lh_false
xorb %al, %al
ret
iterator_is_lh_false:
movb $1, %al
ret

iterator_is_lhu:
cmpq $3, iterator_token_size
jne iterator_is_lhu_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lhu_false
cmpb $104, 1(%rax)
jne iterator_is_lhu_false
cmpb $117, 2(%rax)
jne iterator_is_lhu_false
xorb %al, %al
ret
iterator_is_lhu_false:
movb $1, %al
ret

iterator_is_li:
cmpq $2, iterator_token_size
jne iterator_is_li_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_li_false
cmpb $105, 1(%rax)
jne iterator_is_li_false
xorb %al, %al
ret
iterator_is_li_false:
movb $1, %al
ret

iterator_is_lrd:
cmpq $3, iterator_token_size
jne iterator_is_lrd_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrd_false
cmpb $114, 1(%rax)
jne iterator_is_lrd_false
cmpb $100, 2(%rax)
jne iterator_is_lrd_false
xorb %al, %al
ret
iterator_is_lrd_false:
movb $1, %al
ret

iterator_is_lrdaq:
cmpq $5, iterator_token_size
jne iterator_is_lrdaq_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrdaq_false
cmpb $114, 1(%rax)
jne iterator_is_lrdaq_false
cmpb $100, 2(%rax)
jne iterator_is_lrdaq_false
cmpb $97, 3(%rax)
jne iterator_is_lrdaq_false
cmpb $113, 4(%rax)
jne iterator_is_lrdaq_false
xorb %al, %al
ret
iterator_is_lrdaq_false:
movb $1, %al
ret

iterator_is_lrdaqrl:
cmpq $7, iterator_token_size
jne iterator_is_lrdaqrl_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrdaqrl_false
cmpb $114, 1(%rax)
jne iterator_is_lrdaqrl_false
cmpb $100, 2(%rax)
jne iterator_is_lrdaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_lrdaqrl_false
cmpb $113, 4(%rax)
jne iterator_is_lrdaqrl_false
cmpb $114, 5(%rax)
jne iterator_is_lrdaqrl_false
cmpb $108, 6(%rax)
jne iterator_is_lrdaqrl_false
xorb %al, %al
ret
iterator_is_lrdaqrl_false:
movb $1, %al
ret

iterator_is_lrdrl:
cmpq $5, iterator_token_size
jne iterator_is_lrdrl_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrdrl_false
cmpb $114, 1(%rax)
jne iterator_is_lrdrl_false
cmpb $100, 2(%rax)
jne iterator_is_lrdrl_false
cmpb $114, 3(%rax)
jne iterator_is_lrdrl_false
cmpb $108, 4(%rax)
jne iterator_is_lrdrl_false
xorb %al, %al
ret
iterator_is_lrdrl_false:
movb $1, %al
ret

iterator_is_lrw:
cmpq $3, iterator_token_size
jne iterator_is_lrw_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrw_false
cmpb $114, 1(%rax)
jne iterator_is_lrw_false
cmpb $119, 2(%rax)
jne iterator_is_lrw_false
xorb %al, %al
ret
iterator_is_lrw_false:
movb $1, %al
ret

iterator_is_lrwaq:
cmpq $5, iterator_token_size
jne iterator_is_lrwaq_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrwaq_false
cmpb $114, 1(%rax)
jne iterator_is_lrwaq_false
cmpb $119, 2(%rax)
jne iterator_is_lrwaq_false
cmpb $97, 3(%rax)
jne iterator_is_lrwaq_false
cmpb $113, 4(%rax)
jne iterator_is_lrwaq_false
xorb %al, %al
ret
iterator_is_lrwaq_false:
movb $1, %al
ret

iterator_is_lrwaqrl:
cmpq $7, iterator_token_size
jne iterator_is_lrwaqrl_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrwaqrl_false
cmpb $114, 1(%rax)
jne iterator_is_lrwaqrl_false
cmpb $119, 2(%rax)
jne iterator_is_lrwaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_lrwaqrl_false
cmpb $113, 4(%rax)
jne iterator_is_lrwaqrl_false
cmpb $114, 5(%rax)
jne iterator_is_lrwaqrl_false
cmpb $108, 6(%rax)
jne iterator_is_lrwaqrl_false
xorb %al, %al
ret
iterator_is_lrwaqrl_false:
movb $1, %al
ret

iterator_is_lrwrl:
cmpq $5, iterator_token_size
jne iterator_is_lrwrl_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lrwrl_false
cmpb $114, 1(%rax)
jne iterator_is_lrwrl_false
cmpb $119, 2(%rax)
jne iterator_is_lrwrl_false
cmpb $114, 3(%rax)
jne iterator_is_lrwrl_false
cmpb $108, 4(%rax)
jne iterator_is_lrwrl_false
xorb %al, %al
ret
iterator_is_lrwrl_false:
movb $1, %al
ret

iterator_is_lui:
cmpq $3, iterator_token_size
jne iterator_is_lui_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lui_false
cmpb $117, 1(%rax)
jne iterator_is_lui_false
cmpb $105, 2(%rax)
jne iterator_is_lui_false
xorb %al, %al
ret
iterator_is_lui_false:
movb $1, %al
ret

iterator_is_lw:
cmpq $2, iterator_token_size
jne iterator_is_lw_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lw_false
cmpb $119, 1(%rax)
jne iterator_is_lw_false
xorb %al, %al
ret
iterator_is_lw_false:
movb $1, %al
ret

iterator_is_lwu:
cmpq $3, iterator_token_size
jne iterator_is_lwu_false
movq iterator_current_character, %rax
cmpb $108, (%rax)
jne iterator_is_lwu_false
cmpb $119, 1(%rax)
jne iterator_is_lwu_false
cmpb $117, 2(%rax)
jne iterator_is_lwu_false
xorb %al, %al
ret
iterator_is_lwu_false:
movb $1, %al
ret

iterator_is_mret:
cmpq $4, iterator_token_size
jne iterator_is_mret_false
movq iterator_current_character, %rax
cmpb $109, (%rax)
jne iterator_is_mret_false
cmpb $114, 1(%rax)
jne iterator_is_mret_false
cmpb $101, 2(%rax)
jne iterator_is_mret_false
cmpb $116, 3(%rax)
jne iterator_is_mret_false
xorb %al, %al
ret
iterator_is_mret_false:
movb $1, %al
ret

iterator_is_mul:
cmpq $3, iterator_token_size
jne iterator_is_mul_false
movq iterator_current_character, %rax
cmpb $109, (%rax)
jne iterator_is_mul_false
cmpb $117, 1(%rax)
jne iterator_is_mul_false
cmpb $108, 2(%rax)
jne iterator_is_mul_false
xorb %al, %al
ret
iterator_is_mul_false:
movb $1, %al
ret

iterator_is_mulh:
cmpq $4, iterator_token_size
jne iterator_is_mulh_false
movq iterator_current_character, %rax
cmpb $109, (%rax)
jne iterator_is_mulh_false
cmpb $117, 1(%rax)
jne iterator_is_mulh_false
cmpb $108, 2(%rax)
jne iterator_is_mulh_false
cmpb $104, 3(%rax)
jne iterator_is_mulh_false
xorb %al, %al
ret
iterator_is_mulh_false:
movb $1, %al
ret

iterator_is_mulhsu:
cmpq $6, iterator_token_size
jne iterator_is_mulhsu_false
movq iterator_current_character, %rax
cmpb $109, (%rax)
jne iterator_is_mulhsu_false
cmpb $117, 1(%rax)
jne iterator_is_mulhsu_false
cmpb $108, 2(%rax)
jne iterator_is_mulhsu_false
cmpb $104, 3(%rax)
jne iterator_is_mulhsu_false
cmpb $115, 4(%rax)
jne iterator_is_mulhsu_false
cmpb $117, 5(%rax)
jne iterator_is_mulhsu_false
xorb %al, %al
ret
iterator_is_mulhsu_false:
movb $1, %al
ret

iterator_is_mulhu:
cmpq $5, iterator_token_size
jne iterator_is_mulhu_false
movq iterator_current_character, %rax
cmpb $109, (%rax)
jne iterator_is_mulhu_false
cmpb $117, 1(%rax)
jne iterator_is_mulhu_false
cmpb $108, 2(%rax)
jne iterator_is_mulhu_false
cmpb $104, 3(%rax)
jne iterator_is_mulhu_false
cmpb $117, 4(%rax)
jne iterator_is_mulhu_false
xorb %al, %al
ret
iterator_is_mulhu_false:
movb $1, %al
ret

iterator_is_mulw:
cmpq $4, iterator_token_size
jne iterator_is_mulw_false
movq iterator_current_character, %rax
cmpb $109, (%rax)
jne iterator_is_mulw_false
cmpb $117, 1(%rax)
jne iterator_is_mulw_false
cmpb $108, 2(%rax)
jne iterator_is_mulw_false
cmpb $119, 3(%rax)
jne iterator_is_mulw_false
xorb %al, %al
ret
iterator_is_mulw_false:
movb $1, %al
ret

iterator_is_or:
cmpq $2, iterator_token_size
jne iterator_is_or_false
movq iterator_current_character, %rax
cmpb $111, (%rax)
jne iterator_is_or_false
cmpb $114, 1(%rax)
jne iterator_is_or_false
xorb %al, %al
ret
iterator_is_or_false:
movb $1, %al
ret

iterator_is_ori:
cmpq $3, iterator_token_size
jne iterator_is_ori_false
movq iterator_current_character, %rax
cmpb $111, (%rax)
jne iterator_is_ori_false
cmpb $114, 1(%rax)
jne iterator_is_ori_false
cmpb $105, 2(%rax)
jne iterator_is_ori_false
xorb %al, %al
ret
iterator_is_ori_false:
movb $1, %al
ret

iterator_is_rem:
cmpq $3, iterator_token_size
jne iterator_is_rem_false
movq iterator_current_character, %rax
cmpb $114, (%rax)
jne iterator_is_rem_false
cmpb $101, 1(%rax)
jne iterator_is_rem_false
cmpb $109, 2(%rax)
jne iterator_is_rem_false
xorb %al, %al
ret
iterator_is_rem_false:
movb $1, %al
ret

iterator_is_remu:
cmpq $4, iterator_token_size
jne iterator_is_remu_false
movq iterator_current_character, %rax
cmpb $114, (%rax)
jne iterator_is_remu_false
cmpb $101, 1(%rax)
jne iterator_is_remu_false
cmpb $109, 2(%rax)
jne iterator_is_remu_false
cmpb $117, 3(%rax)
jne iterator_is_remu_false
xorb %al, %al
ret
iterator_is_remu_false:
movb $1, %al
ret

iterator_is_remuw:
cmpq $5, iterator_token_size
jne iterator_is_remuw_false
movq iterator_current_character, %rax
cmpb $114, (%rax)
jne iterator_is_remuw_false
cmpb $101, 1(%rax)
jne iterator_is_remuw_false
cmpb $109, 2(%rax)
jne iterator_is_remuw_false
cmpb $117, 3(%rax)
jne iterator_is_remuw_false
cmpb $119, 4(%rax)
jne iterator_is_remuw_false
xorb %al, %al
ret
iterator_is_remuw_false:
movb $1, %al
ret

iterator_is_remw:
cmpq $4, iterator_token_size
jne iterator_is_remw_false
movq iterator_current_character, %rax
cmpb $114, (%rax)
jne iterator_is_remw_false
cmpb $101, 1(%rax)
jne iterator_is_remw_false
cmpb $109, 2(%rax)
jne iterator_is_remw_false
cmpb $119, 3(%rax)
jne iterator_is_remw_false
xorb %al, %al
ret
iterator_is_remw_false:
movb $1, %al
ret

iterator_is_sb:
cmpq $2, iterator_token_size
jne iterator_is_sb_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sb_false
cmpb $98, 1(%rax)
jne iterator_is_sb_false
xorb %al, %al
ret
iterator_is_sb_false:
movb $1, %al
ret

iterator_is_scd:
cmpq $3, iterator_token_size
jne iterator_is_scd_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scd_false
cmpb $99, 1(%rax)
jne iterator_is_scd_false
cmpb $100, 2(%rax)
jne iterator_is_scd_false
xorb %al, %al
ret
iterator_is_scd_false:
movb $1, %al
ret

iterator_is_scdaq:
cmpq $5, iterator_token_size
jne iterator_is_scdaq_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scdaq_false
cmpb $99, 1(%rax)
jne iterator_is_scdaq_false
cmpb $100, 2(%rax)
jne iterator_is_scdaq_false
cmpb $97, 3(%rax)
jne iterator_is_scdaq_false
cmpb $113, 4(%rax)
jne iterator_is_scdaq_false
xorb %al, %al
ret
iterator_is_scdaq_false:
movb $1, %al
ret

iterator_is_scdaqrl:
cmpq $7, iterator_token_size
jne iterator_is_scdaqrl_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scdaqrl_false
cmpb $99, 1(%rax)
jne iterator_is_scdaqrl_false
cmpb $100, 2(%rax)
jne iterator_is_scdaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_scdaqrl_false
cmpb $113, 4(%rax)
jne iterator_is_scdaqrl_false
cmpb $114, 5(%rax)
jne iterator_is_scdaqrl_false
cmpb $108, 6(%rax)
jne iterator_is_scdaqrl_false
xorb %al, %al
ret
iterator_is_scdaqrl_false:
movb $1, %al
ret

iterator_is_scdrl:
cmpq $5, iterator_token_size
jne iterator_is_scdrl_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scdrl_false
cmpb $99, 1(%rax)
jne iterator_is_scdrl_false
cmpb $100, 2(%rax)
jne iterator_is_scdrl_false
cmpb $114, 3(%rax)
jne iterator_is_scdrl_false
cmpb $108, 4(%rax)
jne iterator_is_scdrl_false
xorb %al, %al
ret
iterator_is_scdrl_false:
movb $1, %al
ret

iterator_is_scw:
cmpq $3, iterator_token_size
jne iterator_is_scw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scw_false
cmpb $99, 1(%rax)
jne iterator_is_scw_false
cmpb $119, 2(%rax)
jne iterator_is_scw_false
xorb %al, %al
ret
iterator_is_scw_false:
movb $1, %al
ret

iterator_is_scwaq:
cmpq $5, iterator_token_size
jne iterator_is_scwaq_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scwaq_false
cmpb $99, 1(%rax)
jne iterator_is_scwaq_false
cmpb $119, 2(%rax)
jne iterator_is_scwaq_false
cmpb $97, 3(%rax)
jne iterator_is_scwaq_false
cmpb $113, 4(%rax)
jne iterator_is_scwaq_false
xorb %al, %al
ret
iterator_is_scwaq_false:
movb $1, %al
ret

iterator_is_scwaqrl:
cmpq $7, iterator_token_size
jne iterator_is_scwaqrl_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scwaqrl_false
cmpb $99, 1(%rax)
jne iterator_is_scwaqrl_false
cmpb $119, 2(%rax)
jne iterator_is_scwaqrl_false
cmpb $97, 3(%rax)
jne iterator_is_scwaqrl_false
cmpb $113, 4(%rax)
jne iterator_is_scwaqrl_false
cmpb $114, 5(%rax)
jne iterator_is_scwaqrl_false
cmpb $108, 6(%rax)
jne iterator_is_scwaqrl_false
xorb %al, %al
ret
iterator_is_scwaqrl_false:
movb $1, %al
ret

iterator_is_scwrl:
cmpq $5, iterator_token_size
jne iterator_is_scwrl_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_scwrl_false
cmpb $99, 1(%rax)
jne iterator_is_scwrl_false
cmpb $119, 2(%rax)
jne iterator_is_scwrl_false
cmpb $114, 3(%rax)
jne iterator_is_scwrl_false
cmpb $108, 4(%rax)
jne iterator_is_scwrl_false
xorb %al, %al
ret
iterator_is_scwrl_false:
movb $1, %al
ret

iterator_is_sd:
cmpq $2, iterator_token_size
jne iterator_is_sd_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sd_false
cmpb $100, 1(%rax)
jne iterator_is_sd_false
xorb %al, %al
ret
iterator_is_sd_false:
movb $1, %al
ret

iterator_is_sfencevma:
cmpq $9, iterator_token_size
jne iterator_is_sfencevma_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sfencevma_false
cmpb $102, 1(%rax)
jne iterator_is_sfencevma_false
cmpb $101, 2(%rax)
jne iterator_is_sfencevma_false
cmpb $110, 3(%rax)
jne iterator_is_sfencevma_false
cmpb $99, 4(%rax)
jne iterator_is_sfencevma_false
cmpb $101, 5(%rax)
jne iterator_is_sfencevma_false
cmpb $118, 6(%rax)
jne iterator_is_sfencevma_false
cmpb $109, 7(%rax)
jne iterator_is_sfencevma_false
cmpb $97, 8(%rax)
jne iterator_is_sfencevma_false
xorb %al, %al
ret
iterator_is_sfencevma_false:
movb $1, %al
ret

iterator_is_sh:
cmpq $2, iterator_token_size
jne iterator_is_sh_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sh_false
cmpb $104, 1(%rax)
jne iterator_is_sh_false
xorb %al, %al
ret
iterator_is_sh_false:
movb $1, %al
ret

iterator_is_sll:
cmpq $3, iterator_token_size
jne iterator_is_sll_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sll_false
cmpb $108, 1(%rax)
jne iterator_is_sll_false
cmpb $108, 2(%rax)
jne iterator_is_sll_false
xorb %al, %al
ret
iterator_is_sll_false:
movb $1, %al
ret

iterator_is_slli:
cmpq $4, iterator_token_size
jne iterator_is_slli_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_slli_false
cmpb $108, 1(%rax)
jne iterator_is_slli_false
cmpb $108, 2(%rax)
jne iterator_is_slli_false
cmpb $105, 3(%rax)
jne iterator_is_slli_false
xorb %al, %al
ret
iterator_is_slli_false:
movb $1, %al
ret

iterator_is_slliw:
cmpq $5, iterator_token_size
jne iterator_is_slliw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_slliw_false
cmpb $108, 1(%rax)
jne iterator_is_slliw_false
cmpb $108, 2(%rax)
jne iterator_is_slliw_false
cmpb $105, 3(%rax)
jne iterator_is_slliw_false
cmpb $119, 4(%rax)
jne iterator_is_slliw_false
xorb %al, %al
ret
iterator_is_slliw_false:
movb $1, %al
ret

iterator_is_sllw:
cmpq $4, iterator_token_size
jne iterator_is_sllw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sllw_false
cmpb $108, 1(%rax)
jne iterator_is_sllw_false
cmpb $108, 2(%rax)
jne iterator_is_sllw_false
cmpb $119, 3(%rax)
jne iterator_is_sllw_false
xorb %al, %al
ret
iterator_is_sllw_false:
movb $1, %al
ret

iterator_is_slt:
cmpq $3, iterator_token_size
jne iterator_is_slt_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_slt_false
cmpb $108, 1(%rax)
jne iterator_is_slt_false
cmpb $116, 2(%rax)
jne iterator_is_slt_false
xorb %al, %al
ret
iterator_is_slt_false:
movb $1, %al
ret

iterator_is_slti:
cmpq $4, iterator_token_size
jne iterator_is_slti_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_slti_false
cmpb $108, 1(%rax)
jne iterator_is_slti_false
cmpb $116, 2(%rax)
jne iterator_is_slti_false
cmpb $105, 3(%rax)
jne iterator_is_slti_false
xorb %al, %al
ret
iterator_is_slti_false:
movb $1, %al
ret

iterator_is_sltiu:
cmpq $5, iterator_token_size
jne iterator_is_sltiu_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sltiu_false
cmpb $108, 1(%rax)
jne iterator_is_sltiu_false
cmpb $116, 2(%rax)
jne iterator_is_sltiu_false
cmpb $105, 3(%rax)
jne iterator_is_sltiu_false
cmpb $117, 4(%rax)
jne iterator_is_sltiu_false
xorb %al, %al
ret
iterator_is_sltiu_false:
movb $1, %al
ret

iterator_is_sltu:
cmpq $4, iterator_token_size
jne iterator_is_sltu_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sltu_false
cmpb $108, 1(%rax)
jne iterator_is_sltu_false
cmpb $116, 2(%rax)
jne iterator_is_sltu_false
cmpb $117, 3(%rax)
jne iterator_is_sltu_false
xorb %al, %al
ret
iterator_is_sltu_false:
movb $1, %al
ret

iterator_is_sra:
cmpq $3, iterator_token_size
jne iterator_is_sra_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sra_false
cmpb $114, 1(%rax)
jne iterator_is_sra_false
cmpb $97, 2(%rax)
jne iterator_is_sra_false
xorb %al, %al
ret
iterator_is_sra_false:
movb $1, %al
ret

iterator_is_srai:
cmpq $4, iterator_token_size
jne iterator_is_srai_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_srai_false
cmpb $114, 1(%rax)
jne iterator_is_srai_false
cmpb $97, 2(%rax)
jne iterator_is_srai_false
cmpb $105, 3(%rax)
jne iterator_is_srai_false
xorb %al, %al
ret
iterator_is_srai_false:
movb $1, %al
ret

iterator_is_sraiw:
cmpq $5, iterator_token_size
jne iterator_is_sraiw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sraiw_false
cmpb $114, 1(%rax)
jne iterator_is_sraiw_false
cmpb $97, 2(%rax)
jne iterator_is_sraiw_false
cmpb $105, 3(%rax)
jne iterator_is_sraiw_false
cmpb $119, 4(%rax)
jne iterator_is_sraiw_false
xorb %al, %al
ret
iterator_is_sraiw_false:
movb $1, %al
ret

iterator_is_sraw:
cmpq $4, iterator_token_size
jne iterator_is_sraw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sraw_false
cmpb $114, 1(%rax)
jne iterator_is_sraw_false
cmpb $97, 2(%rax)
jne iterator_is_sraw_false
cmpb $119, 3(%rax)
jne iterator_is_sraw_false
xorb %al, %al
ret
iterator_is_sraw_false:
movb $1, %al
ret

iterator_is_sret:
cmpq $4, iterator_token_size
jne iterator_is_sret_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sret_false
cmpb $114, 1(%rax)
jne iterator_is_sret_false
cmpb $101, 2(%rax)
jne iterator_is_sret_false
cmpb $116, 3(%rax)
jne iterator_is_sret_false
xorb %al, %al
ret
iterator_is_sret_false:
movb $1, %al
ret

iterator_is_srl:
cmpq $3, iterator_token_size
jne iterator_is_srl_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_srl_false
cmpb $114, 1(%rax)
jne iterator_is_srl_false
cmpb $108, 2(%rax)
jne iterator_is_srl_false
xorb %al, %al
ret
iterator_is_srl_false:
movb $1, %al
ret

iterator_is_srli:
cmpq $4, iterator_token_size
jne iterator_is_srli_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_srli_false
cmpb $114, 1(%rax)
jne iterator_is_srli_false
cmpb $108, 2(%rax)
jne iterator_is_srli_false
cmpb $105, 3(%rax)
jne iterator_is_srli_false
xorb %al, %al
ret
iterator_is_srli_false:
movb $1, %al
ret

iterator_is_srliw:
cmpq $5, iterator_token_size
jne iterator_is_srliw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_srliw_false
cmpb $114, 1(%rax)
jne iterator_is_srliw_false
cmpb $108, 2(%rax)
jne iterator_is_srliw_false
cmpb $105, 3(%rax)
jne iterator_is_srliw_false
cmpb $119, 4(%rax)
jne iterator_is_srliw_false
xorb %al, %al
ret
iterator_is_srliw_false:
movb $1, %al
ret

iterator_is_srlw:
cmpq $4, iterator_token_size
jne iterator_is_srlw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_srlw_false
cmpb $114, 1(%rax)
jne iterator_is_srlw_false
cmpb $108, 2(%rax)
jne iterator_is_srlw_false
cmpb $119, 3(%rax)
jne iterator_is_srlw_false
xorb %al, %al
ret
iterator_is_srlw_false:
movb $1, %al
ret

iterator_is_sub:
cmpq $3, iterator_token_size
jne iterator_is_sub_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sub_false
cmpb $117, 1(%rax)
jne iterator_is_sub_false
cmpb $98, 2(%rax)
jne iterator_is_sub_false
xorb %al, %al
ret
iterator_is_sub_false:
movb $1, %al
ret

iterator_is_subw:
cmpq $4, iterator_token_size
jne iterator_is_subw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_subw_false
cmpb $117, 1(%rax)
jne iterator_is_subw_false
cmpb $98, 2(%rax)
jne iterator_is_subw_false
cmpb $119, 3(%rax)
jne iterator_is_subw_false
xorb %al, %al
ret
iterator_is_subw_false:
movb $1, %al
ret

iterator_is_sw:
cmpq $2, iterator_token_size
jne iterator_is_sw_false
movq iterator_current_character, %rax
cmpb $115, (%rax)
jne iterator_is_sw_false
cmpb $119, 1(%rax)
jne iterator_is_sw_false
xorb %al, %al
ret
iterator_is_sw_false:
movb $1, %al
ret

iterator_is_uret:
cmpq $4, iterator_token_size
jne iterator_is_uret_false
movq iterator_current_character, %rax
cmpb $117, (%rax)
jne iterator_is_uret_false
cmpb $114, 1(%rax)
jne iterator_is_uret_false
cmpb $101, 2(%rax)
jne iterator_is_uret_false
cmpb $116, 3(%rax)
jne iterator_is_uret_false
xorb %al, %al
ret
iterator_is_uret_false:
movb $1, %al
ret

iterator_is_wfi:
cmpq $3, iterator_token_size
jne iterator_is_wfi_false
movq iterator_current_character, %rax
cmpb $119, (%rax)
jne iterator_is_wfi_false
cmpb $102, 1(%rax)
jne iterator_is_wfi_false
cmpb $105, 2(%rax)
jne iterator_is_wfi_false
xorb %al, %al
ret
iterator_is_wfi_false:
movb $1, %al
ret

iterator_is_xor:
cmpq $3, iterator_token_size
jne iterator_is_xor_false
movq iterator_current_character, %rax
cmpb $120, (%rax)
jne iterator_is_xor_false
cmpb $111, 1(%rax)
jne iterator_is_xor_false
cmpb $114, 2(%rax)
jne iterator_is_xor_false
xorb %al, %al
ret
iterator_is_xor_false:
movb $1, %al
ret

iterator_is_xori:
cmpq $4, iterator_token_size
jne iterator_is_xori_false
movq iterator_current_character, %rax
cmpb $120, (%rax)
jne iterator_is_xori_false
cmpb $111, 1(%rax)
jne iterator_is_xori_false
cmpb $114, 2(%rax)
jne iterator_is_xori_false
cmpb $105, 3(%rax)
jne iterator_is_xori_false
xorb %al, %al
ret
iterator_is_xori_false:
movb $1, %al
ret


.align 8
iterator_current_character: .quad 0
iterator_character_count: .quad 0
iterator_file_path: .quad 0
iterator_file_path_size: .quad 0
iterator_row_identifier: .quad 0
iterator_column_identifier: .quad 0
iterator_token_size: .quad 0
