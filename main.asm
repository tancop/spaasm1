%include "macros.asl"

global    _start
extern    count_file

section   .data

no_input_msg db "count: missing file", 10
             db "try 'count -h' to get help", 10
no_input_len  equ $ - no_input_msg

help_msg  db "count digits, small letters, capital letters and other characters", 10
          db "usage - count FILE1 [FILE2...]", 10
          db "output - [digits] [small] [capital] [other] for each line and total for all files", 10
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
    add rbp, 16        ; skip argc and file name

    dec rbx            ; count actual args without file name

handle_file:
    mov rdi, [rbp]
    call count_file

    dec rbx
    jz  no_args        ; exit if no arguments left

    add rbp, 8         ; move to next file
    jmp handle_file

no_args:
    print no_input_msg, no_input_len

end:
    exit
