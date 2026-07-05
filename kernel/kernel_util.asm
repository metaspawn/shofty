; ---------- print_string: prints null-terminated string at SI ----------
print_string:
    mov ah, 0x0E
.next:
    lodsb               ; al = [si], si++
    test al, al
    jz .end
    int 0x10
    jmp .next
.end:
    ret
; ---------- print_hex_byte: prints AL as two hex digits ----------
print_hex_byte:
    push ax
    push bx
    mov bl, al
    shr al, 4
    call .digit
    mov al, bl
    and al, 0x0F
    call .digit
    pop bx
    pop ax
    ret
.digit:
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe .print
    add al, 7           ; 'A'-'9'-1
.print:
    mov ah, 0x0E
    int 0x10
    ret
