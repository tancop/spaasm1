import glob
import os
import sys


def main():
    try:
        os.mkdir("out")
    except FileExistsError:
        pass

    asm_files = [f.removesuffix(".asm") for f in glob.glob("*.asm")]

    for file in asm_files:
        os.system(f"nasm {file}.asm -f elf64 -F dwarf -o out/{file}.o")

    os.system(f"gold {' '.join([f'out/{f}.o' for f in asm_files])} -o out/main")
    os.system(f"out/main {' '.join(sys.argv[1:])}")


if __name__ == "__main__":
    main()
