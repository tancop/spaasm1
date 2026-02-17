global    _start

section   .data

%define message_text "slovakia #1", 10
%strlen message_len  message_text
message:  db message_text

%define args_text "arguments found", 10
%strlen args_len  args_text
args_msg:  db args_text

section   .text

%macro print 2 ; print ptr, len
    mov rax, 1
    mov rdi, 1
    mov rsi, %1     ; set pointer to string start
    mov rdx, %2 + 1 ; don't skip last character
    syscall
%endmacro

_start:
    print message, message_len

    mov rbx, [rsp]
    cmp rbx, 1
    je no_args
    print args_msg, args_len

no_args:

    mov       rax, 60                 ; system call for exit
    xor       rdi, rdi                ; exit code 0
    syscall                           ; invoke operating system to exit
