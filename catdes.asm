; ============================================
; SHOFTY - Kernel v0.1 + catdes
; MetaSpawn Project - GPL-3.0
; ============================================

[org 0x1000]
[bits 16]

kernel_start:
    mov ax, 0x0003
    int 0x10

    mov si, catdes
    call print

    mov si, loading
    call print

    mov cx, 15
.bar:/
    mov al, 219
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    push cx
    mov cx, 0x0002
    mov dx, 0x0000
    mov ah, 0x86
    int 0x15
    pop cx
    loop .bar

    mov si, done
    call print

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

catdes db 13, 10
       db "      /\_____/\ ", 13, 10
       db "     /  o   o  \ ", 13, 10
       db "    ( ==  ^  == )", 13, 10
       db "     )         ( ", 13, 10
       db "    (           )", 13, 10
       db "   ( (  )   (  ) )", 13, 10
       db "  (__(__)___(__)__)", 13, 10
       db "      S H O F T Y", 13, 10, 13, 10, 0

loading db "   Loading SHOFTY... ", 13, 10, "   [", 0
done    db "]", 13, 10, 13, 10, "   Welcome.", 13, 10, 0

times 1024-($-$$) db 0
