# SHOFTY

A hobby operating system written from scratch in x86 real-mode assembly (NASM).

Named after my cat.

**Status:** alpha — bootable, with a working shell and disk I/O. Filesystem in progress.

## Features

- Custom bootloader
- Login screen
- Interactive shell: `help`, `clear`, `cat`, `vga`, `disktest`, `format`
- Disk I/O through BIOS int 0x13 extensions (LBA addressing)
- SFM, a filesystem of my own design (work in progress)

## Build

    nasm -f bin boot/boot.asm -o boot.bin
    nasm -f bin kernel/kernel.asm -o kernel.bin
    cat boot.bin kernel.bin > shofty.img

## Run

    qemu-system-i386 -drive format=raw,file=shofty.img

## Structure

    boot/boot.asm       bootloader
    kernel/kernel.asm   entry point and %include hub
    kernel/shell.asm    command interpreter
    kernel/login.asm    login screen
    kernel/menu.asm     menu system
    kernel/disk.asm     disk I/O via int 0x13
    kernel/sfm.asm      SFM filesystem
    kernel/catdes.asm   cat command
    kernel/kernel_util.asm  shared routines

## Version history

### Alpha — current (the experimental branch is at end alpha)
- SFM superblock written to sector 40 with "SFM1" magic bytes
- Filesystem read/write in progress

### v0.3 — disk access
- LBA disk I/O through int 0x13 extensions
- `disktest` and `format` commands

### v0.2 — shell
- Interactive command interpreter
- `help`, `clear`, `cat`, `vga` commands

### v0.1 — boot
- Bootloader loading a kernel from disk
- Login screen

## Roadmap

- SFM directory and file read/write
- System call interface so external programs can use kernel services
- Loading and executing programs from disk

## License

GPL-3.0
