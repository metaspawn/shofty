; pmtest.asm - minimal boot sector that jumps straight to protected mode
bits 16
org 0x7c00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    jmp switch_to_pmode

%include "kernel/pmode.asm"

times 510-($-$$) db 0
dw 0xaa55
