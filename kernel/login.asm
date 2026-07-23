; ================= SHOFTY LOGIN =================
; Asks for a username or guest. Stores name in [current_user].

login_screen:
    ; clear screen
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    mov si, login_banner
    call print_string

    mov si, login_prompt
    call print_string

    call login_read_line

    ; empty input -> guest
    mov si, login_buffer
    cmp byte [si], 0
    je .as_guest

    ; copy typed name into current_user
    mov si, login_buffer
    mov di, current_user
.copy:
    lodsb
    mov [di], al
    inc di
    test al, al
    jnz .copy
    jmp .welcome

.as_guest:
    mov si, guest_name
    mov di, current_user
.copyg:
    lodsb
    mov [di], al
    inc di
    test al, al
    jnz .copyg

.welcome:
    mov si, msg_welcome
    call print_string
    mov si, current_user
    call print_string
    mov si, newline2
    call print_string

    ; small pause so the welcome is visible (BIOS wait ~1.5s)
    mov ah, 0x86
    mov cx, 0x0016
    mov dx, 0xE360
    int 0x15
    ret

; ---------- login_read_line: like read_line but into login_buffer ----------
login_read_line:
    mov di, login_buffer
    xor cx, cx
.key:
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .done
    cmp al, 0x08
    je .back
    cmp cx, 15              ; max 15 chars for a username
    jae .key
    stosb
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .key
.back:
    test cx, cx
    jz .key
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .key
.done:
    mov byte [di], 0
    mov si, newline2
    call print_string
    ret

; ---------- login data ----------
login_banner  db "==== SHOFTY LOGIN ====", 13, 10, 13, 10, 0
login_prompt  db "username (empty = guest): ", 0
msg_welcome   db 13, 10, "welcome, ", 0
guest_name    db "guest", 0
newline2      db 13, 10, 0
current_user  times 16 db 0
login_buffer  times 16 db 0
