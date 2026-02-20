run file *args:
    #!/usr/bin/env sh
    mkdir -p out/
    name="{{ file_stem(file) }}"
    nasm "{{ file }}" -f elf64 -F dwarf -o "out/$name.o"
    ld "out/$name.o" -o "out/$name"
    out/$name {{ args }}
