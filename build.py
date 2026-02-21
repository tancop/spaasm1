import glob
import os
import sys


def main():
    try:
        os.mkdir("out")
    except FileExistsError:
        pass

    asm_files = [f.removesuffix(".asm") for f in glob.glob("*.asm")]

    argv = []
    debug = False

    for arg in sys.argv[1:]:
        if arg == "-d":
            debug = True
        else:
            argv.append(arg)

    for file in asm_files:
        os.system(
            f"nasm {file}.asm -f elf64 {'-F dwarf' if debug else ''} -o out/{file}.o"
        )

    os.system(f"gold {' '.join([f'out/{f}.o' for f in asm_files])} -o out/count")
    if not debug:
        os.system("strip out/count")

    code = os.waitstatus_to_exitcode(os.system(f"out/count {' '.join(argv)}"))
    sys.exit(code)


if __name__ == "__main__":
    main()
