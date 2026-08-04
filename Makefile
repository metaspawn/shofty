# SHOFTY - MetaSpawn Project - GPL-3.0

# --- Detect environment: WSL uses the native Windows QEMU (real window),
#     plain Linux uses the native Linux QEMU. ---
IS_WSL := $(shell grep -qi microsoft /proc/version 2>/dev/null && echo yes)

ifeq ($(IS_WSL),yes)
    QEMU     := "/mnt/c/Program Files/qemu/qemu-system-x86_64.exe"
    QEMU_ENV := WSL (Windows QEMU)
else
    QEMU     := qemu-system-x86_64
    QEMU_ENV := Linux (native QEMU)
endif

all: shofty.img

boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o boot.bin

kernel.bin: kernel/kernel.asm kernel/catdes.asm kernel/menu.asm kernel/kernel_util.asm kernel/login.asm kernel/shell.asm kernel/disk.asm kernel/sfm.asm kernel/pmode.asm
	nasm -f bin kernel/kernel.asm -o kernel.bin

shofty.img: boot.bin kernel.bin
	cat boot.bin kernel.bin > shofty.img
	truncate -s 16M shofty.img

# auto-detected window (native window on both WSL and Linux)
run: shofty.img
	@echo "Running on: $(QEMU_ENV)"
	$(QEMU) -drive format=raw,file=shofty.img

# force in-terminal text mode (no window, works everywhere)
run-curses: shofty.img
	qemu-system-x86_64 -drive format=raw,file=shofty.img -display curses

debug: shofty.img
	@echo "Running on: $(QEMU_ENV)"
	$(QEMU) -drive format=raw,file=shofty.img -monitor stdio

clean:
	rm -f *.bin *.img
