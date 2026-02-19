global    _start

section   .data

start_msg  db "slovakia #1", 10
start_len  equ $ - start_msg

fail_msg  db "failed to open file", 10
fail_len  equ $ - fail_msg

line_msg  db "line end", 10
line_len  equ $ - line_msg

help_msg  db "count digits, small letters, capital letters and other characters in a file", 10
          db "usage - count FILE1 [FILE2...]", 10
help_len  equ $ - help_msg

section   .bss

buf        times 256 db ?
buf_offset dq ?
read_ctr   dq ?

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

%define O_RDONLY	00000000q ; open file read only

; open path, flags
%macro open 2
    mov rax, 2  ; open(2)
    mov rdi, %1 ; pointer to path
    mov rsi, %2 ; flags
    syscall
%endmacro

; close fd
%macro close 1
    mov rax, 3  ; close(2)
    mov rdi, %1 ; fd to close
    syscall
%endmacro

; read fd, ptr, len
%macro read 3
    mov rax, 0
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

_start:
    print start_msg, start_len

    mov rbx, [rsp]                ; check number of arguments
    cmp rbx, 1
    je no_args                    ; print message if argc > 1

    mov rax, [rsp+16]             ; argv[1]

    check_byte 0, '-', not_help   ; check if the argument is '-h'
    check_byte 1, 'h', not_help
    check_byte 2, 0, not_help

    print help_msg, help_len
    exit

not_help:
    open [rsp+16], O_RDONLY
    mov rbx, rax

read_buf:
    read rbx, buf, 256 ; read bytes to buffer

    mov rdi, rax       ; store read length
    cmp rax, 0
    je end             ; no more bytes to read

    mov rsi, 0         ; offset into buf

read_char:
%define r_line_digits r12 ; digits on line
%define r_line_big r13    ; capital letters on line
%define r_line_small r14  ; small letters on line
%define r_line_other r15  ; other chars on line

    cmp byte [buf + rsi], 10   ; is newline?
    jne same_line

    ; print line counts and add to totals
    mov [buf_offset], rsi
    mov [read_ctr], rdi

    print line_msg, line_len

    mov rsi, [buf_offset]
    mov rdi, [read_ctr]

same_line:
    inc rsi               ; add to offset
    dec rdi               ; take from read length
    jz read_buf           ; reached end of buffer
    jmp read_char

end:
    close rbx

no_args:
    exit
