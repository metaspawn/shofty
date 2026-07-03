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
