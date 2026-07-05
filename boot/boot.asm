; ============================================
; SHOFTY - Boot Sector v0.2
; MetaSpawn Project - GPL-3.0
; Loads the kernel from disk
; ============================================

[org 0x7C00]
[bits 16]

KERNEL_ADDR equ 0x1000

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    mov si, msg_boot
    call print

    mov bx, KERNEL_ADDR
    mov ah, 0x02
    mov al, 32
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    mov dl, [boot_drive]    ; hand the real boot drive to the kernel
    jmp KERNEL_ADDR

disk_error:
    mov si, msg_error
    call print
    jmp $

print:
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
times 8192-($-$$) db 0
    int 0x10
    jmp .loop
.done:
    ret

boot_drive db 0

msg_boot  db "SHOFTY boot: loading kernel...", 13, 10, 0
msg_error db "Disk read error!", 13, 10, 0

times 510- ($-$$) db 0
dw 0xAA55
