; vga32.asm - 32-bit protected mode text output
; Writes straight into VGA text memory at 0xB8000. There is no BIOS
; in protected mode, so int 0x10 is not available.
;
; The buffer is 80x25 cells, two bytes each: character, then attribute.

bits 32

VGA_MEM     equ 0xB8000
VGA_COLS    equ 80
VGA_ROWS    equ 25
VGA_ATTR    equ 0x0F            ; white on black

; ---------------------------------------------------------------
; print_char32 - write one character at the cursor
;   al = character
; Clobbers: nothing (all registers preserved)
; ---------------------------------------------------------------
print_char32:
    pusha

    cmp al, 10                  ; '\n'
    je .newline
    cmp al, 13                  ; '\r'
    je .carriage_return
    cmp al, 8                   ; backspace
    je .backspace

    ; offset = (row * VGA_COLS + col) * 2
    movzx eax, byte [cursor_row]
    imul eax, VGA_COLS
    movzx ebx, byte [cursor_col]
    add eax, ebx
    shl eax, 1                  ; two bytes per cell
    add eax, VGA_MEM

    mov bl, [esp + 28]          ; recover al from the pusha frame
    mov [eax], bl
    mov byte [eax + 1], VGA_ATTR

    inc byte [cursor_col]
    cmp byte [cursor_col], VGA_COLS
    jb .done

.newline:
    mov byte [cursor_col], 0
    inc byte [cursor_row]
    cmp byte [cursor_row], VGA_ROWS
    jb .done
    call scroll_up
    mov byte [cursor_row], VGA_ROWS - 1
    jmp .done

.carriage_return:
    mov byte [cursor_col], 0
    jmp .done

.backspace:
    cmp byte [cursor_col], 0
    je .done
    dec byte [cursor_col]

    movzx eax, byte [cursor_row]
    imul eax, VGA_COLS
    movzx ebx, byte [cursor_col]
    add eax, ebx
    shl eax, 1
    add eax, VGA_MEM
    mov byte [eax], ' '
    mov byte [eax + 1], VGA_ATTR

.done:
    call move_cursor
    popa
    ret

; ---------------------------------------------------------------
; print_string32 - write a null-terminated string
;   esi = pointer to string
; ---------------------------------------------------------------
print_string32:
    pusha
.loop:
    mov al, [esi]
    test al, al
    jz .done
    call print_char32
    inc esi
    jmp .loop
.done:
    popa
    ret

; ---------------------------------------------------------------
; print_dec32 - write an unsigned number in decimal
;   eax = value
; ---------------------------------------------------------------
print_dec32:
    pusha
    mov ecx, 0                  ; digit count
    mov ebx, 10

    test eax, eax
    jnz .divide
    mov al, '0'
    call print_char32
    jmp .done

.divide:
    xor edx, edx
    div ebx                     ; eax = eax/10, edx = remainder
    add dl, '0'
    push edx
    inc ecx
    test eax, eax
    jnz .divide

.pop_digits:
    pop eax
    call print_char32
    loop .pop_digits

.done:
    popa
    ret

; ---------------------------------------------------------------
; clear_screen32 - fill the whole buffer with spaces
; ---------------------------------------------------------------
clear_screen32:
    pusha
    mov edi, VGA_MEM
    mov ecx, VGA_COLS * VGA_ROWS
    mov ax, (VGA_ATTR << 8) | ' '
    rep stosw                   ; store ax, ecx times

    mov byte [cursor_row], 0
    mov byte [cursor_col], 0
    call move_cursor
    popa
    ret

; ---------------------------------------------------------------
; scroll_up - move every row up one line, blank the last row
; ---------------------------------------------------------------
scroll_up:
    pusha

    mov esi, VGA_MEM + (VGA_COLS * 2)   ; second row
    mov edi, VGA_MEM                     ; first row
    mov ecx, VGA_COLS * (VGA_ROWS - 1)
    rep movsw

    ; blank the bottom row
    mov edi, VGA_MEM + (VGA_COLS * (VGA_ROWS - 1) * 2)
    mov ecx, VGA_COLS
    mov ax, (VGA_ATTR << 8) | ' '
    rep stosw

    popa
    ret

; ---------------------------------------------------------------
; move_cursor - tell the VGA hardware where the cursor sits
; The position goes out through the CRTC index/data port pair.
; ---------------------------------------------------------------
move_cursor:
    pusha

    movzx eax, byte [cursor_row]
    imul eax, VGA_COLS
    movzx ebx, byte [cursor_col]
    add eax, ebx
    mov ebx, eax                ; ebx = linear cell position

    mov dx, 0x3D4               ; CRTC index port
    mov al, 0x0F                ; cursor location low byte
    out dx, al
    mov dx, 0x3D5               ; CRTC data port
    mov al, bl
    out dx, al

    mov dx, 0x3D4
    mov al, 0x0E                ; cursor location high byte
    out dx, al
    mov dx, 0x3D5
    mov al, bh
    out dx, al

    popa
    ret

; ---------------------------------------------------------------
cursor_row: db 0
cursor_col: db 0
