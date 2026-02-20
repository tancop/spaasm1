global    _start

section   .data

start_msg  db "slovakia #1", 10
start_len  equ $ - start_msg

fail_msg  db "failed to open file", 10
fail_len  equ $ - fail_msg

help_msg  db "count digits, small letters, capital letters and other characters in a file", 10
          db "usage - count FILE1 [FILE2...]", 10
help_len  equ $ - help_msg

total_msg  db "Total:", 10
total_len  equ $ - total_msg

out_buf    times 20 db 0     ; output buffer for printn
           db ' '            ; 2^64 is 20 characters long

section   .bss

buf        resb 256
buf_offset dq ?
read_ctr   dq ?

digits     dq ?
big        dq ?
small      dq ?
other      dq ?

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

; exits with user provided code
%macro fail 1
    mov rax, 60     ; exit(2)
    mov rdi, %1     ; set exit code
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

; print number in rdi to stdout
printn:
    mov rax, rdi                  ; number to print
    mov rdx, 0                    ; clear out for division
    mov rsi, out_buf + 19         ; pointer to current character
    mov r8, 10                    ; constant 10
    mov r9, 0                     ; chars written

printn_loop:
    cmp rax, 10                   ; check if on first digit (last processed)
    jl  printn_end

    div r8                        ; divide rax by 10
    mov byte [rsi], dl
    add byte [rsi], 48  ; convert to ascii digit
    mov rdx, 0                    ; clear out remainder

    dec rsi
    inc r9
    jmp printn_loop
printn_end:
    mov byte [rsi], al            ; print last digit
    add byte [rsi], 48
    inc r9

    mov r8, r9                    ; max length, 20 digits + space
    add r8, 2
    print rsi, r8

    ret

%define r_line_digits r12 ; digits on line
%define r_line_big r13    ; capital letters on line
%define r_line_small r14  ; small letters on line
%define r_line_other r15  ; other chars on line

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

    bt  rax, 0    ; check if return value is positive -> success
    jc  open_ok
    print fail_msg, fail_len
    fail 1

open_ok:
    mov rbx, rax

read_buf:
    read rbx, buf, 256 ; read bytes to buffer

    mov rdi, rax       ; store read length
    cmp rax, 0
    je end             ; no more bytes to read

    mov rsi, 0         ; offset into buf

read_char:
    cmp byte [buf + rsi], 10   ; is newline?
    jne same_line

    ; print line counts and add to totals
    mov [buf_offset], rsi
    mov [read_ctr], rdi

    add [digits], r_line_digits
    add [big], r_line_big
    add [small], r_line_small
    add [other], r_line_other

    mov rbp, rsp            ; save stack pointer for argc/argv

    mov rdi, r_line_digits
    call printn
    mov rdi, r_line_big
    call printn
    mov rdi, r_line_small
    call printn
    mov rdi, r_line_other
    call printn

    mov rsp, rbp            ; restore stack pointer

    ; clear line registers
    xor r_line_digits, r_line_digits
    xor r_line_big, r_line_big
    xor r_line_small, r_line_small
    xor r_line_other, r_line_other

    mov byte [out_buf], 10 ; new line
    print out_buf, 1

    mov rsi, [buf_offset]
    mov rdi, [read_ctr]

    jmp loop_end

same_line:
    cmp byte [buf + rsi], 47 ; control chars
    jle is_other
    cmp byte [buf + rsi], 57 ; digits
    jle is_digit
    cmp byte [buf + rsi], 64 ; special chars
    jle is_other
    cmp byte [buf + rsi], 90 ; capital letters
    jle is_big
    cmp byte [buf + rsi], 96 ; more special chars
    jle is_other
    cmp byte [buf + rsi], 122 ; small letters
    jle is_small
    jmp is_other

is_digit:
    inc r_line_digits
    jmp loop_end

is_big:
    inc r_line_big
    jmp loop_end

is_small:
    inc r_line_small
    jmp loop_end

is_other:
    inc r_line_other

loop_end:
    inc rsi               ; add to offset
    dec rdi               ; take from read length
    jz read_buf           ; reached end of buffer
    jmp read_char

end:
    print total_msg, total_len

    mov rdi, [digits]
    call printn
    mov rdi, [big]
    call printn
    mov rdi, [small]
    call printn
    mov rdi, [other]
    call printn

    mov byte [out_buf], 10 ; new line
    print out_buf, 1

    close rbx

no_args:
    exit
