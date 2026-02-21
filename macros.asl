%ifndef MACROS_ASL
%define MACROS_ASL

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

; fail code
; exits with user provided code
%macro fail 1
    mov rax, 60     ; exit(2)
    mov rdi, %1     ; set exit code
    syscall
%endmacro

; check_byte off, pat, dst
; checks if byte at [rax+off] is equal to pat, jump to dst if not
%macro check_byte 3
    mov sil, [rax + %1]
    cmp sil, %2
    jne %3
%endmacro

%define O_RDONLY	00000000q ; open file read only

; open path, flags
; opens file at path with flags
%macro open 2
    mov rax, 2  ; open(2)
    mov rdi, %1 ; pointer to path
    mov rsi, %2 ; flags
    syscall
%endmacro

; close fd
; closes file at fd
%macro close 1
    mov rax, 3  ; close(2)
    mov rdi, %1 ; fd to close
    syscall
%endmacro

; read fd, ptr, len
; reads len bytes from fd into ptr
%macro read 3
    mov rax, 0
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

%endif ; MACROS_ASL
