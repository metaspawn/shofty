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
call vga_menu

    cmp byte [menu_choice], 0
    je enter_vga
    jmp $                   ; "no" -> parked for now

enter_vga:
    mov ah, 0x00
    mov al, 0x13
    int 0x10

    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov al, 0x36
    mov cx, 320*200
    rep stosb

    jmp $
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

times 8192-($-$$) db 0
