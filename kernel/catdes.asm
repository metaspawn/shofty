; ============================================
; SHOFTY - catdes (cat design)
; Boot screen: tuxedo cat + loading bar
; MetaSpawn Project - GPL-3.0
; ============================================

catdes_show:
    mov si, cat
    call print

    mov si, loading
    call print

    mov cx, 15
.bar:
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
    ret

cat db 13, 10
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
; --- after the cat splash ---

echo_loop:
    mov ah, 0
    int 0x16            ; wait for keypress; AL = ASCII, AH = scancode

    cmp al, 0x0D        ; Enter?
    je .newline

    cmp al, 0x08        ; Backspace?
    je .backspace

    mov ah, 0x0E        ; BIOS teletype: print AL
    int 0x10
    jmp echo_loop

.newline:
    mov ah, 0x0E
    mov al, 0x0D        ; carriage return
    int 0x10
    mov al, 0x0A        ; line feed
    int 0x10
    jmp echo_loop

.backspace:
    mov ah, 0x0E
    mov al, 0x08        ; move cursor back
    int 0x10
    mov al, ' '         ; erase the character
    int 0x10
    mov al, 0x08        ; move cursor back again
    int 0x10
    jmp echo_loop
