; ============================================
; SHOFTY - Boot Sector v0.1
; MetaSpawn Project - GPL-3.0
; Free forever - no telemetry, no greed
; ============================================

[org 0x7C00]
[bits 16]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov si, mensaje

imprimir:
    lodsb
    or al, al
    jz fin
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp imprimir

fin:
    jmp $

mensaje db "SHOFTY OS - MetaSpawn Project", 13, 10
        db "Free forever. No telemetry. No greed.", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
