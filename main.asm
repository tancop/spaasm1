%include "macros.asl"

global    _start
extern    count_file

section   .data

help_msg  db "count digits, small letters, capital letters and other characters in a file", 10
          db "usage - count FILE1 [FILE2...]", 10
help_len  equ $ - help_msg

section   .text

_start:
    mov rbx, [rsp]                ; check number of arguments
    cmp rbx, 1
    je no_args                    ; exit if argc == 1 (no arguments)

    mov rax, [rsp + 16]           ; load address of argv[1]

    check_byte 0, '-', not_help   ; check if the argument is '-h'
    check_byte 1, 'h', not_help
    check_byte 2, 0, not_help

    print help_msg, help_len      ; user needs help, print it and exit
    exit

not_help:
    mov rbp, rsp       ; save argv pointer (rbx = argc, rbp = argv)

handle_file:
    mov rdi, [rsp + 16]
    call count_file

no_args:
    exit
