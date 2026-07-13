# SHOFTY - MetaSpawn Project - GPL-3.0
all: shofty.img

boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o boot.bin

kernel.bin: kernel/kernel.asm kernel/catdes.asm kernel/menu.asm kernel/kernel_util.asm kernel/login.asm kernel/shell.asm kernel/disk.asm kernel/sfm.asm
	nasm -f bin kernel/kernel.asm -o kernel.bin

shofty.img: boot.bin kernel.bin
	cat boot.bin kernel.bin > shofty.img
	truncate -s 16M shofty.img

run: shofty.img
	qemu-system-x86_64 -drive format=raw,file=shofty.img
debug: shofty.img
	qemu-system-x86_64 -drive format=raw,file=shofty.img -monitor stdio

clean:
	rm -f *.bin *.img
