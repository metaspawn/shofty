; ================= SHOFTY KERNEL UTILITIES =================
; Shared routines: printing, hex output, panic/warning screens.

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

; ---------- print_hex_word: prints AX as 4 hex digits ----------
print_hex_word:
    push ax
    mov al, ah
    call print_hex_byte ; high byte first
    pop ax
    call print_hex_byte ; then low byte
    ret

; ---------- warning: scary but survivable (returns!) ----------
; Input: SI = warning message
warning:
    push si
    mov si, warn_head
    call print_string
    pop si
    call print_string
    mov si, warn_foot
    call print_string
    ret

; ---------- panic: SHOFTY error screen with F1/F2 menu ----------
; Input: SI = error message (never returns to caller)
panic:
    mov [panic_msg], si     ; remember the error message
    ; capture registers for F2 debug screen
    mov [reg_ax], ax
    mov [reg_bx], bx
    mov [reg_cx], cx
    mov [reg_dx], dx
    mov [reg_si], si
    mov [reg_di], di
    mov [reg_sp], sp

.draw:
    ; text mode reset + red screen
    mov ax, 0x0003
    int 0x10
    mov ah, 0x06        ; scroll-clear with attribute
    mov al, 0
    mov bh, 0x4F        ; white on red
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    mov ah, 0x02        ; cursor to row 1
    xor bh, bh
    mov dx, 0x0100
    int 0x10

    mov si, panic_cat
    call print_string
    mov si, panic_head
    call print_string
    mov si, [panic_msg]
    call print_string
    mov si, panic_menu
    call print_string

.key:
    mov ah, 0
    int 0x16
    cmp ah, 0x3B        ; F1 scancode
    je .power_off
    cmp ah, 0x3C        ; F2 scancode
    je .debug_logs
    jmp .key

.power_off:
    ; APM shutdown via BIOS
    mov ax, 0x5301      ; APM connect
    xor bx, bx
    int 0x15
    mov ax, 0x5308      ; enable power management
    mov bx, 1
    mov cx, 1
    int 0x15
    mov ax, 0x5307      ; set power state: off
    mov bx, 1
    mov cx, 3
    int 0x15
.halt:                  ; fallback if APM failed
    hlt
    jmp .halt

.debug_logs:
    ; forensic screen: blue, dumps captured registers
    mov ax, 0x0003
    int 0x10
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F        ; white on blue
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    xor bh, bh
    mov dx, 0x0100
    int 0x10

    mov si, dbg_head
    call print_string
    mov si, [panic_msg]
    call print_string
    mov si, dbg_regs
    call print_string

    mov si, lbl_ax
    call print_string
    mov ax, [reg_ax]
    call print_hex_word
    mov si, lbl_bx
    call print_string
    mov ax, [reg_bx]
    call print_hex_word
    mov si, lbl_cx
    call print_string
    mov ax, [reg_cx]
    call print_hex_word
    mov si, lbl_dx
    call print_string
    mov ax, [reg_dx]
    call print_hex_word
    mov si, lbl_si
    call print_string
    mov ax, [reg_si]
    call print_hex_word
    mov si, lbl_di
    call print_string
    mov ax, [reg_di]
    call print_hex_word
    mov si, lbl_sp
    call print_string
    mov ax, [reg_sp]
    call print_hex_word

    mov si, dbg_foot
    call print_string

    mov ah, 0           ; any key returns to panic screen
    int 0x16
    jmp .draw

; ---------- error screen data ----------
panic_msg  dw 0
reg_ax     dw 0
reg_bx     dw 0
reg_cx     dw 0
reg_dx     dw 0
reg_si     dw 0
reg_di     dw 0
reg_sp     dw 0
panic_cat  db "        /\_____/\ ", 13, 10
           db "       /  x   x  \ ", 13, 10
           db "      ( ==  ^  == )", 13, 10
           db "       )         ( ", 13, 10
           db "      (           )", 13, 10
           db "     ( (  )   (  ) )", 13, 10
           db "    (__(__)___(__)__)", 13, 10, 13, 10, 0
panic_head db "    SHOFTY PANIC - CRITICAL SYSTEM FAILURE", 13, 10, 13, 10
           db "    The system cannot run a critical kernel file", 13, 10
           db "    or has suffered a fatal error.", 13, 10, 13, 10
           db "    Please power off your machine to avoid", 13, 10
           db "    unwanted failures. The system is damaged", 13, 10
           db "    and will not boot.", 13, 10, 13, 10
           db "    Error: ", 0
panic_menu db 13, 10, 13, 10
           db "    F1 - power off", 13, 10
           db "    F2 - attempt repair (debug recovery)", 13, 10, 0
dbg_head   db "  SHOFTY DEBUG RECOVERY LOGS", 13, 10
           db "  ==========================", 13, 10, 13, 10
           db "  Error: ", 0
dbg_regs   db 13, 10, 13, 10, "  Registers at crash:", 13, 10, 0
lbl_ax     db 13, 10, "  AX = ", 0
lbl_bx     db "   BX = ", 0
lbl_cx     db 13, 10, "  CX = ", 0
lbl_dx     db "   DX = ", 0
lbl_si     db 13, 10, "  SI = ", 0
lbl_di     db "   DI = ", 0
lbl_sp     db 13, 10, "  SP = ", 0
dbg_foot   db 13, 10, 13, 10, "  Press any key to return.", 13, 10, 0
warn_head  db 13, 10, "  !! SHOFTY WARNING !!", 13, 10
           db "  Something is wrong. Not fatal yet - but pay attention.", 13, 10
           db "  ", 0
warn_foot  db 13, 10, "  You have been warned.", 13, 10, 13, 10, 0
