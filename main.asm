global    _start

section   .data

start_msg  db "slovakia #1", 10
start_len  equ $ - start_msg

args_msg  db "arguments found", 10
args_len  equ $ - args_msg

help_msg  db "count digits, small letters, capital letters and other characters in a file", 10
          db "usage - count FILE1 [FILE2...]", 10
help_len  equ $ - help_msg

section   .text

; print ptr, len
; prints len characters starting at ptr to stdout
%macro print 2
    mov rax, 1      ; write(2)
    mov rdi, 1      ; stdout
    mov rsi, %1     ; set string pointer to %1
    mov rdx, %2     ; set output length to %2
    syscall
%endmacro

; exits with code 0, no arguments
%macro exit 0
    mov rax, 60     ; exit(2)
    xor rdi, rdi    ; code 0
    syscall
%endmacro

; check_byte off, pat, dst
; checks if byte at [rax+off] is equal to pat, jump to dst if not
; clobbers rsi
%macro check_byte 3
    mov sil, [rax + %1]
    cmp sil, %2
    jne %3
%endmacro

_start:
    print start_msg, start_len

    mov rcx, [rsp]                ; check number of arguments
    cmp rcx, 1
    je no_args                    ; print message if argc > 1

    mov rax, [rsp+16]             ; argv[1]

    check_byte 0, '-', not_help   ; check if the argument is '-h'
    check_byte 1, 'h', not_help
    check_byte 2, 0, not_help

    print help_msg, help_len
    exit

not_help:
    print args_msg, args_len

no_args:
    exit
