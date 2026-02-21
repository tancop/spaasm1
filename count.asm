%include "macros.asl"

global    count_file

%define r_line_digits r12 ; digits on line
%define r_line_big r13    ; capital letters on line
%define r_line_small r14  ; small letters on line
%define r_line_other r15  ; other chars on line

section   .data

fail_msg  db "failed to open file", 10
fail_len  equ $ - fail_msg

read_fail_msg  db "failed to read from file", 10
read_fail_len  equ $ - read_fail_msg

total_msg  db "Total:", 10
total_len  equ $ - total_msg

out_buf    times 20 db 0     ; output buffer for printn
           db ' '            ; 2^64 is 20 characters, all we need to print a number

section   .bss

buf        resb 256  ; input buffer for reading from file
buf_offset dq ?      ; saved offset into buffer
read_ctr   dq ?      ; characters left in buffer

digits     dq ?      ; character class counts for whole file
big        dq ?
small      dq ?
other      dq ?

open_fd    dq ?

section   .text

; prints number in rdi to stdout
; output is unsigned decimal followed by 1 space
printn:
    mov rax, rdi                  ; number to print
    mov rdx, 0                    ; clear out for division
    mov rsi, out_buf + 19         ; pointer to current character, start at last digit in buffer
    mov r8, 10                    ; constant 10 for division
    mov r9, 0                     ; number of digits written

printn_loop:
    cmp rax, 10                   ; check if on first digit (last processed)
    jl  printn_end                ; no more divisions, jump to end

    div r8                        ; divide rax by 10
    mov byte [rsi], dl            ; write remainder (always < 10) to buffer
    add byte [rsi], 48            ; convert to ascii digit
    mov rdx, 0                    ; clear out remainder

    dec rsi                       ; move next digit position back 1
    inc r9                        ; increment number of digits
    jmp printn_loop

printn_end:
    mov byte [rsi], al            ; write first digit to buffer
    add byte [rsi], 48            ; stored in rax because we skipped division
    inc r9

    mov r8, r9                    ; get number of digits in output
    inc r8                        ; add 1 for final space
    print rsi, r8                 ; print out result

    ret

; main procedure, rdi is pointer to file path
count_file:
    mov rax, rdi
    open rdi, O_RDONLY ; open input file as read only

    test rax, rax      ; check if return value is negative -> error
    jns open_ok

    print fail_msg, fail_len
    fail 1             ; open returned error, exit with code 1

open_ok:
    mov [open_fd], rax ; save file descriptor

    ; save r12-r15 to stack
    push r_line_digits
    push r_line_big
    push r_line_small
    push r_line_other

read_buf:
    read [open_fd], buf, 256 ; read bytes to buffer
    test rax, rax      ; check if return value is negative -> error
    jns  read_ok

    print read_fail_msg, read_fail_len
    fail 2

read_ok:
    mov rdi, rax       ; store read length
    cmp rax, 0
    je end             ; no more bytes to read

    mov rsi, 0         ; clear offset before loop

read_char:
    cmp byte [buf + rsi], 10   ; is newline?
    jne same_line              ; skip printing counts if same line

    ; save offset and read counter
    mov [buf_offset], rsi
    mov [read_ctr], rdi

    ; add line counts to totals
    add [digits], r_line_digits
    add [big], r_line_big
    add [small], r_line_small
    add [other], r_line_other

    ; print all line counts
    mov rdi, r_line_digits
    call printn
    mov rdi, r_line_big
    call printn
    mov rdi, r_line_small
    call printn
    mov rdi, r_line_other
    call printn

    ; clear line count registers
    xor r_line_digits, r_line_digits
    xor r_line_big, r_line_big
    xor r_line_small, r_line_small
    xor r_line_other, r_line_other

    mov byte [out_buf], 10  ; start new line
    print out_buf, 1

    ; restore offset and read counter
    mov rsi, [buf_offset]
    mov rdi, [read_ctr]

    ; skip adding character to total
    jmp loop_tail

same_line:
    ; find out what category the character is in
    cmp byte [buf + rsi], 47  ; '/', control and special chars
    jle is_other
    cmp byte [buf + rsi], 57  ; '9', digits
    jle is_digit
    cmp byte [buf + rsi], 64  ; '@', special chars
    jle is_other
    cmp byte [buf + rsi], 90  ; 'Z', capital letters
    jle is_big
    cmp byte [buf + rsi], 96  ; '`', more special chars
    jle is_other
    cmp byte [buf + rsi], 122 ; 'z', small letters
    jle is_small
    ; other byte
    jmp is_other

    ; increment line count for category
is_digit:
    inc r_line_digits
    jmp loop_tail

is_big:
    inc r_line_big
    jmp loop_tail

is_small:
    inc r_line_small
    jmp loop_tail

is_other:
    inc r_line_other

loop_tail:
    inc rsi               ; add 1 to offset

    dec rdi               ; take 1 from available chars
    jz read_buf           ; reached end of buffer and need to load more

    jmp read_char

end:
    cmp rbx, 1
    jne no_total  ; skip printing if this is not the last file

    ; print total counts in the end
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

no_total:
    close [open_fd]

    ; restore r12-r15 from stack
    pop r_line_other
    pop r_line_small
    pop r_line_big
    pop r_line_digits

    ret
