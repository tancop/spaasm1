; Zadanie 1
; Teodor Potančok

; 1. Vypísať počty číslic, malých písmen, veľkých písmen a ostatných znakov pre
; každý riadok aj pre celý vstup.

; 7. Plus 1 bod: Ak budú korektne spracované vstupné súbory s veľkosťou nad 64 kB.
; 9. Plus 2 body: Ak bude možné zadať viacero vstupných súborov.
; 10. Plus 2 body: Je možné získať ak pridelená úloha bude realizovaná ako externá
; procedúra (kompilovaná samostatne a prilinkovaná k výslednému programu).
; 12. Plus 1 bod: Je možné získať za (dobré) komentáre, resp. dokumentáciu, v
; anglickom jazyku.

; 22. 3. 2026
; 2. ročník, LS 2025/26, informatika

%include "macros.inc"

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
    mov rdi, [rbp]     ; pointer to file name
    mov rsi, rbx       ; function checks if argument is 1 to print totals
                       ; rbx is 1 at the last file
    call count_file

    dec rbx
    jz  end            ; exit if no arguments left

    add rbp, 8         ; move to next file
    jmp handle_file

no_args:
    print no_input_msg, no_input_len
    fail 3

end:
    exit

; Zhodnotenie:

; Program je navrhnutý pre prostredie s jadrom Linux a architektúrou x86-64. Pre
; jeho skompilovanie potrebujeme assembler NASM a linker s podporou ELF, napr. GNU
; ld alebo gold. Funguje pre všetky súbory ktoré majú obsah a konečnú dĺžku. Ak je
; vstupný súbor adresár, neexistuje alebo používateľ nemá prístup na čítanie, program
; vráti chybu. V prípade že súbor nemá koniec (ako /dev/zero), proces nekončí a je
; treba ho manuálne zastaviť.
;
; Skompilovaný program používame ako: "count FILE1 FILE2..." kde FILEn je cesta na súbor.
; Keď je prvý argument "-h" namiesto normálneho výstupu ukáže informácie o programe. Keď
; nedostane argumenty vypíše chybu ktorá ukazuje na funkciu "-h".
;
; Výstup programu je ako prvé N riadkov kde na každom z nich sú 4 čísla - číslice, malé
; písmená, veľké písmená a iné znaky na vstupnom riadku. Potom nasleduje riadok s označením
; ("Total: ") a súčty pre každú kategóriu znakov. Ak je na príkazovom riadku viac argumentov,
; program ich berie ako jeden vstup a zobrazí len jeden súčet. Keď niektorý zo súborov
; nevie otvoriť vypíše chybu a skončí.
;
; Hlavná procedúra count_file je v súbore count.asm. Ako argumenty berie pointer na
; meno súboru a logickú hodnotu, v C by vyzerala ako `void count_file(char *path, int print_totals)`.
; Argumenty sú uložené v registroch rdi a rsi, čo je štandard pre 64-bitové systémy
; založené na Unixe. Procedúra otvorí súbor cez systémové volanie open, postupne číta
; jeho obsah do buffera cez volanie read a na konci zatvorí súbor cez close.
;
; Pre výpis údajov je v rovnakom súbore procedúra printn ktorá berie ako jediný argument
; číslo a vypíše ho na štandardný výstup. Hlavný cyklus postupne delí vstup 10 pomocou
; inštrukcie div a zapisuje číslice na buffer od konca. Tak dosiahneme že pre správny
; výsledok nie je treba v druhom cykle obrátiť buffer.

; Použité zdroje:

; Systémové volania Linux - https://filippo.io/linux-syscall-table/
; CPU inštrukcie - https://www.felixcloutier.com/x86/
; Dokumentácia assemblera - https://www.nasm.us/docs/3.01/
; Použitie registrov pri volaní procedúry - https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI
