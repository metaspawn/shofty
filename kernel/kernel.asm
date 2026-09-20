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

    ; ask which mode to enter
    call boot_menu
    cmp byte [boot_choice], 1
    je .enter_desktop
    jmp shell_start            ; 0 = terminal (real-mode shell)

.enter_desktop:
    jmp switch_to_pmode        ; 1 = desktop mode (32-bit protected mode)

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

; protected-mode switch + 32-bit VGA driver. Must be the LAST include
; because pmode.asm ends in `bits 32` (and pulls in drivers/vga32.asm,
; also 32-bit). Anything after it would assemble as 32-bit code.
%include "kernel/pmode.asm"

times 32768-($-$$) db 0
