; ============================================
; SHOFTY - Kernel v0.2
; MetaSpawn Project - GPL-3.0
; ============================================
[org 0x1000]
[bits 16]

kernel_start:
    mov [boot_drive_k], dl
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ax, 0x0003
    int 0x10
    call catdes_show
    call login_screen
    jmp shell_start

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
%include "kernel/login.asm"
%include "kernel/shell.asm"
%include "kernel/disk.asm"
%include "kernel/sfm.asm"

times 16384-($-$$) db 0
