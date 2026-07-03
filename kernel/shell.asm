; ================= SHOFTY SHELL =================
; Interactive shell. Needs: print_string (kernel_util.asm),
; current_user (login.asm), cat (catdes.asm data),
; disk_read/disk_write (disk.asm).

shell_start:
    ; clear screen (set video mode resets it)
    mov ah, 0x00
    mov al, 0x03        ; 80x25 text mode
    int 0x10

    mov si, banner
    call print_string

shell_loop:
    ; prompt: shofty (user)>
    mov si, prompt_open
    call print_string
    mov si, current_user
    call print_string
    mov si, prompt_close
    call print_string

    call read_line      ; fills input_buffer, returns on Enter

    ; empty input? just prompt again
    mov si, input_buffer
    cmp byte [si], 0
    je shell_loop

    ; --- compare against commands ---
    mov si, input_buffer
    mov di, cmd_help
    call str_equals
    jc .do_help

    mov si, input_buffer
    mov di, cmd_clear
    call str_equals
    jc shell_start      ; clear = redraw screen

    mov si, input_buffer
    mov di, cmd_cat
    call str_equals
    jc .do_cat

    mov si, input_buffer
    mov di, cmd_disktest
    call str_equals
    jc .do_disktest

    ; unknown command
    mov si, msg_unknown
    call print_string
    jmp shell_loop

.do_help:
    mov si, msg_help
    call print_string
    jmp shell_loop

.do_cat:
    mov si, cat         ; reuse the splash cat!
    call print_string
    jmp shell_loop

.do_disktest:
    ; write test pattern to sector 20
    mov ax, 20
    mov bx, disk_buf
    call disk_write
    jc .dt_fail

    ; wipe the buffer to prove the read is real
    mov di, disk_buf
    mov cx, 512
    mov al, 0
    rep stosb

    ; read sector 20 back
    mov ax, 20
    mov bx, disk_buf
    call disk_read
    jc .dt_fail

    mov si, disk_buf    ; print what came back
    call print_string
    jmp shell_loop

.dt_fail:
    mov si, msg_dt_fail
    call print_string
    jmp shell_loop

; ---------- read_line: reads keys into input_buffer until Enter ----------
read_line:
    mov di, input_buffer
    xor cx, cx          ; char count

.key:
    mov ah, 0
    int 0x16

    cmp al, 0x0D        ; Enter -> done
    je .done

    cmp al, 0x08        ; Backspace
    je .backspace

    cmp cx, 63          ; buffer full? ignore key
    jae .key

    ; store + echo
    stosb               ; [di] = al, di++
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .key

.backspace:
    test cx, cx         ; nothing to erase?
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
    mov byte [di], 0    ; null-terminate
    mov si, shell_nl
    call print_string
    ret

; ---------- str_equals: compares SI vs DI, carry flag set if equal ----------
str_equals:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .no
    test al, al         ; both hit null -> equal
    jz .yes
    inc si
    inc di
    jmp .loop
.yes:
    stc
    ret
.no:
    clc
    ret

; ---------- shell data ----------
banner       db "SHOFTY shell v0.1", 13, 10
             db "Type 'help' for commands.", 13, 10, 13, 10, 0
prompt_open  db "shofty (", 0
prompt_close db ")> ", 0
shell_nl     db 13, 10, 0
msg_unknown  db "Unknown command. Try 'help'.", 13, 10, 0
msg_help     db "Commands:", 13, 10
             db "  help     - show this list", 13, 10
             db "  clear    - clear the screen", 13, 10
             db "  cat      - meow", 13, 10
             db "  disktest - test disk read/write", 13, 10, 0
cmd_help     db "help", 0
cmd_clear    db "clear", 0
cmd_cat      db "cat", 0
cmd_disktest db "disktest", 0
msg_dt_fail  db "disk error!", 13, 10, 0
disk_buf     db "SFM disk I/O works!", 13, 10, 0
             times 512-21 db 0
input_buffer times 64 db 0
