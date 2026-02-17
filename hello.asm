global    _start

section   .data

%define message_text "slovakia #1", 10
%strlen message_len  message_text

message:  db message_text      ; note the newline at the end

section   .text

_start:
    mov       rax, 1                  ; system call for write
    mov       rdi, 1                  ; file handle 1 is stdout
    mov       rsi, message            ; address of string to output
    mov       rdx, message_len + 1    ; number of bytes
    syscall                           ; invoke operating system to do the write

    mov       rax, 60                 ; system call for exit
    xor       rdi, rdi                ; exit code 0
    syscall                           ; invoke operating system to exit
