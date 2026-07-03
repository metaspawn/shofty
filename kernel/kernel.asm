; ============================================
; SHOFTY - Kernel v0.1
; MetaSpawn Project - GPL-3.0
; ============================================

[org 0x1000]
[bits 16]

kernel_start:
    mov ax, 0x0003
    int 0x10

    call catdes_show
jmp echo_loop
print:
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .loop
.done:
    ret
%include "kernel/menu.asm"
%include "kernel/catdes.asm"
%include "kernel/kernel_util.asm"

times 1024-($-$$) db 0
