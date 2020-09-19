as --64 -march=generic64 code/ango-riscv64-assembler.s code/file.s code/terminal.s code/constant-table.s code/include-table.s code/label-table.s code/iterator.s -o ango-riscv64-assembler.o
ld -N -s -m elf_x86_64 --entry entrance ango-riscv64-assembler.o -o ango-riscv64-assembler
