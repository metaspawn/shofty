; ================= VGA MODE MENU (highlight bar) =================
; Returns: byte [menu_choice] = 0 (yes) or 1 (no)

vga_menu:
    mov byte [menu_choice], 0

.draw:
    ; clear screen
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    mov si, menu_top
    call print_string

    ; --- YES at row 4 ---
    mov dh, 4               ; row
    mov bl, 0x07            ; normal attribute
    cmp byte [menu_choice], 0
    jne .yes_draw
    mov bl, 0x70            ; selected: black on grey
.yes_draw:
    mov si, opt_yes
    call print_at

    ; --- NO at row 6 ---
    mov dh, 6
    mov bl, 0x07
    cmp byte [menu_choice], 1
    jne .no_draw
    mov bl, 0x70
.no_draw:
    mov si, opt_no
    call print_at

    mov si, menu_hint
    mov dh, 9
    mov bl, 0x07
    call print_at

.key:
    mov ah, 0
    int 0x16

    cmp al, 0x0D            ; Enter
    je .confirm
    cmp ah, 0x48            ; up
    je .up
    cmp ah, 0x50            ; down
    je .down
    jmp .key

.up:
    mov byte [menu_choice], 0
    jmp .draw
.down:
    mov byte [menu_choice], 1
    jmp .draw
.confirm:
    ret

; ---------- print_at: prints string SI at row DH with attribute BL ----------
; centers-ish at column 14, prints char by char with color
print_at:
    mov dl, 14              ; column
.char:
    lodsb
    test al, al
    jz .end

    push ax
    ; move cursor to DH,DL
    mov ah, 0x02
    xor bh, bh              ; page 0
    int 0x10
    pop ax

    ; print char with attribute BL
    mov ah, 0x09
    xor bh, bh
    mov cx, 1               ; one copy
    int 0x10

    inc dl                  ; next column
    jmp .char
.end:
    ret

; ---------- menu data ----------
menu_top     db "__________________________", 13, 10, 13, 10
             db " do you wish to enter vga mode?", 13, 10, 0
opt_yes      db "   yes   ", 0
opt_no       db "   no    ", 0
menu_hint    db "use up/down arrows, enter to confirm", 0
menu_choice  db 0

; ================= BOOT MODE MENU (highlight bar) =================
; Asks whether to boot into the terminal (real-mode shell) or
; desktop mode (32-bit protected mode).
; Returns: byte [boot_choice] = 0 (terminal) or 1 (desktop)

boot_menu:
    mov byte [boot_choice], 0

.draw:
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    mov si, boot_top
    call print_string

    ; --- Terminal at row 5 ---
    mov dh, 5
    mov bl, 0x07
    cmp byte [boot_choice], 0
    jne .term_draw
    mov bl, 0x70               ; selected: black on grey
.term_draw:
    mov si, opt_terminal
    call print_at

    ; --- Desktop mode at row 7 ---
    mov dh, 7
    mov bl, 0x07
    cmp byte [boot_choice], 1
    jne .desk_draw
    mov bl, 0x70
.desk_draw:
    mov si, opt_desktop
    call print_at

    mov si, boot_hint
    mov dh, 10
    mov bl, 0x07
    call print_at

.key:
    mov ah, 0
    int 0x16
    cmp al, 0x0D               ; Enter
    je .confirm
    cmp ah, 0x48               ; up
    je .up
    cmp ah, 0x50               ; down
    je .down
    jmp .key

.up:
    mov byte [boot_choice], 0
    jmp .draw
.down:
    mov byte [boot_choice], 1
    jmp .draw
.confirm:
    ret

; ---------- boot menu data ----------
boot_top      db "======================", 13, 10, 13, 10
              db " Select boot mode:", 13, 10, 0
opt_terminal  db "  Terminal      ", 0
opt_desktop   db "  Desktop mode  ", 0
boot_hint     db "up/down + enter", 0
boot_choice   db 0
