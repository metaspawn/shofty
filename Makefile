# SHOFTY - MetaSpawn Project - GPL-3.0

all: shofty.img

boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o boot.bin

kernel.bin: kernel/kernel.asm kernel/catdes.asm kernel/menu.asm kernel/kernel_util.asm kernel/login.asm
	nasm -f bin kernel/kernel.asm -o kernel.bin

shofty.img: boot.bin kernel.bin
	cat boot.bin kernel.bin > shofty.img

run: shofty.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=shofty.img

clean:
	rm -f *.bin *.img
