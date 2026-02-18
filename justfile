run file *args:
    #!/usr/bin/env sh
    name="{{ file_stem(file) }}"
    nasm "{{ file }}" -f elf64 -o "out/$name.o"
    ld "out/$name.o" -o "out/$name"
    out/$name {{ args }}
