; ================= SHOFTY SHELL =================
; Interactive shell. Needs: kernel_util.asm, login.asm,
; catdes.asm, disk.asm, sfm.asm.

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

    ; --- integrity guard: is the filesystem still alive? ---
    call sfm_guard

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
    mov di, cmd_vga
    call str_equals
    jc .do_vga

    mov si, input_buffer
    mov di, cmd_disktest
    call str_equals
    jc .do_disktest

    mov si, input_buffer
    mov di, cmd_format
    call str_equals
    jc .do_format

    mov si, input_buffer
    mov di, cmd_chkdsk
    call str_equals
    jc .do_chkdsk

    ; dev tool: injects corruption to test the integrity guard
    mov si, input_buffer
    mov di, cmd_corrupt
    call str_equals
    jc .do_corrupt

    mov si, input_buffer
    mov di, cmd_pmode
    call str_equals
    jc .do_pmode

    mov si, input_buffer
    mov di, cmd_echo
    call str_prefix          ; prefix match: "echo ..."
    jc .do_echo

    mov si, input_buffer
    mov di, cmd_about
    call str_equals
    jc .do_about

    mov si, input_buffer
    mov di, cmd_ver
    call str_equals
    jc .do_about             ; ver = alias of about

    mov si, input_buffer
    mov di, cmd_mem
    call str_equals
    jc .do_mem

    mov si, input_buffer
    mov di, cmd_time
    call str_equals
    jc .do_time

    mov si, input_buffer
    mov di, cmd_reboot
    call str_equals
    jc .do_reboot

    mov si, input_buffer
    mov di, cmd_ls
    call str_equals
    jc .do_ls

    mov si, input_buffer
    mov di, cmd_sh
    call str_equals
    jc .do_sh

    mov si, input_buffer
    mov di, cmd_cs
    call str_prefix
    jc .do_cs

    mov si, input_buffer
    mov di, cmd_pstcon
    call str_prefix
    jc .do_pstcon

    mov si, input_buffer
    mov di, cmd_remfil
    call str_prefix
    jc .do_remfil

    mov si, input_buffer
    mov di, cmd_readfil
    call str_prefix
    jc .do_readfil

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

.do_vga:
    mov ah, 0x00
    mov al, 0x13        ; VGA 320x200, 256 colors
    int 0x10

    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov al, 0x36
    mov cx, 320*200
    rep stosb

    mov ah, 0           ; wait for key, return to text shell
    int 0x16
    jmp shell_start

.do_disktest:
    xor ax, ax
    mov es, ax

    mov ax, 0           ; read test: boot sector
    mov bx, disk_buf
    call disk_read
    jc .dt_fail

    mov si, msg_read_ok
    call print_string

    mov ax, 20          ; write test: sector 20 round trip
    mov bx, disk_buf2
    call disk_write
    jc .dt_fail

    mov di, disk_buf2
    mov cx, 512
    mov al, 0
    rep stosb

    mov ax, 20
    mov bx, disk_buf2
    call disk_read
    jc .dt_fail

    mov si, disk_buf2
    call print_string
    jmp shell_loop

.dt_fail:
    mov si, msg_dt_fail
    call print_string
    mov al, [disk_err]
    call print_hex_byte
    mov si, shell_nl
    call print_string
    jmp shell_loop

.do_format:
    xor ax, ax
    mov es, ax
    call sfm_format
    jmp shell_loop

.do_chkdsk:
    xor ax, ax
    mov es, ax
    call sfm_diskcheck
    jmp shell_loop

.do_corrupt:
    xor ax, ax
    mov es, ax
    call sfm_corrupt
    jmp shell_loop

.do_pmode:
    ; one-way trip: real mode -> 32-bit protected mode.
    ; The BIOS is gone after this, so the shell does not return.
    mov si, msg_pmode
    call print_string
    jmp switch_to_pmode

.do_echo:
    ; SI already points past "echo " (str_prefix advanced it)
    call print_string
    mov si, shell_nl
    call print_string
    jmp shell_loop

.do_about:
    mov si, msg_about
    call print_string
    jmp shell_loop

.do_mem:
    int 0x12                 ; AX = KB of conventional memory
    push ax
    mov si, msg_mem
    call print_string
    pop ax
    call print_dec_word
    mov si, msg_kb
    call print_string
    jmp shell_loop

.do_time:
    mov ah, 0x02
    int 0x1A                 ; CH=hours CL=min DH=sec (all BCD)
    push dx
    push cx
    mov si, msg_time
    call print_string
    pop cx
    mov al, ch
    call print_bcd
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    mov al, cl
    call print_bcd
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    pop dx
    mov al, dh
    call print_bcd
    mov si, shell_nl
    call print_string
    jmp shell_loop

.do_reboot:
    mov si, msg_reboot
    call print_string
    mov al, 0xFE             ; pulse the keyboard controller reset line
    out 0x64, al
    jmp $                    ; if it didn't reset, just hang

.do_ls:
    xor ax, ax
    mov es, ax
    mov dl, 0                ; hide dotfiles
    call sfm_list
    jmp shell_loop

.do_sh:
    xor ax, ax
    mov es, ax
    mov dl, 1                ; show hidden too
    call sfm_list
    jmp shell_loop

.do_cs:
    ; SI points past "cs ". Split into name + content.
    call split_arg           ; -> name_buf (0-term), DX = content ptr
    mov si, name_buf
    call sfm_create
    jmp shell_loop

.do_pstcon:
    call split_arg
    mov si, name_buf
    call sfm_write
    jmp shell_loop

.do_remfil:
    ; SI points past "remfil ". Whole remainder is the name.
    call copy_name           ; -> name_buf (0-term)
    mov si, name_buf
    call sfm_delete
    jmp shell_loop

.do_readfil:
    ; SI points past "readfil ". Remainder is the name.
    call copy_name           ; -> name_buf (0-term)
    mov si, name_buf
    call sfm_read
    jmp shell_loop

; ---------- read_line: reads keys into input_buffer until Enter ----------
read_line:
    mov di, input_buffer
    xor cx, cx

.key:
    mov ah, 0
    int 0x16

    cmp al, 0x0D        ; Enter
    je .done

    cmp al, 0x08        ; Backspace
    je .backspace

    cmp cx, 63
    jae .key

    stosb
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .key

.backspace:
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
    mov si, shell_nl
    call print_string
    ret

; ---------- str_equals: compares SI vs DI, carry set if equal ----------
str_equals:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .no
    test al, al
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

; ---------- str_prefix: does SI start with prefix DI? ----------
; if yes: CF=1 and SI is advanced past the prefix; else CF=0
str_prefix:
.loop:
    mov al, [di]
    test al, al
    jz .match                ; end of prefix reached -> it matched
    mov bl, [si]
    cmp al, bl
    jne .no
    inc si
    inc di
    jmp .loop
.match:
    stc
    ret
.no:
    clc
    ret

; ---------- split_arg: split "name content" at first space ----------
; Input:  SI -> "name content"
; Output: name_buf holds the name (0-terminated, max 15),
;         DX -> content (first char after the space; "" if none)
split_arg:
    push di
    mov di, name_buf
    xor cx, cx
.name:
    mov al, [si]
    test al, al
    jz .no_content
    cmp al, ' '
    je .space
    cmp cx, 15
    jae .skipname
    mov [di], al
    inc di
    inc cx
.skipname:
    inc si
    jmp .name
.space:
    mov byte [di], 0         ; terminate name
    inc si                   ; skip the space
    mov dx, si               ; content starts here
    pop di
    ret
.no_content:
    mov byte [di], 0
    mov dx, si               ; DX -> the terminating 0 (empty content)
    pop di
    ret

; ---------- copy_name: copy SI into name_buf (0-term, max 15) ----------
copy_name:
    push di
    mov di, name_buf
    xor cx, cx
.cp:
    mov al, [si]
    test al, al
    jz .done
    cmp cx, 15
    jae .adv
    mov [di], al
    inc di
    inc cx
.adv:
    inc si
    jmp .cp
.done:
    mov byte [di], 0
    pop di
    ret

; ---------- print_dec_word: print AX as decimal ----------
print_dec_word:
    pusha
    mov bx, 10
    mov cx, 0xFFFF           ; stack sentinel
    push cx
.divide:
    xor dx, dx
    div bx                   ; AX / 10, DX = remainder
    add dl, '0'
    push dx
    test ax, ax
    jnz .divide
.print:
    pop ax
    cmp ax, 0xFFFF
    je .done
    mov ah, 0x0E
    int 0x10
    jmp .print
.done:
    popa
    ret

; ---------- print_bcd: print AL as two BCD digits ----------
print_bcd:
    push ax
    push bx
    mov bl, al
    shr al, 4
    and al, 0x0F
    add al, '0'
    mov ah, 0x0E
    int 0x10
    mov al, bl
    and al, 0x0F
    add al, '0'
    mov ah, 0x0E
    int 0x10
    pop bx
    pop ax
    ret

; ---------- shell data ----------
banner       db "SHOFTY shell v0.2", 13, 10
             db "Type 'help' for commands.", 13, 10, 13, 10, 0
prompt_open  db "shofty (", 0
prompt_close db ")> ", 0
shell_nl     db 13, 10, 0
msg_unknown  db "Unknown command. Try 'help'.", 13, 10, 0
msg_help     db "Commands:", 13, 10
             db "  help     - show this list", 13, 10
             db "  clear    - clear the screen", 13, 10
             db "  cat      - meow", 13, 10
             db "  vga      - graphics mode (any key returns)", 13, 10
             db "  disktest - test disk read/write", 13, 10
             db "  format   - create SFM filesystem on disk", 13, 10
             db "  chkdsk   - run disk examination", 13, 10
             db "  pmode    - jump to 32-bit protected mode", 13, 10
             db "  echo X   - print text X", 13, 10
             db "  about    - system info (alias: ver)", 13, 10
             db "  mem      - conventional memory size", 13, 10
             db "  time     - RTC clock", 13, 10
             db "  reboot   - restart the machine", 13, 10
             db "  ls       - list files", 13, 10
             db "  sh       - list files incl. hidden", 13, 10
             db "  cs N C   - create file N with content C", 13, 10
             db "  pstcon N C - overwrite file N content", 13, 10
             db "  remfil N - remove file N", 13, 10
             db "  readfil N - show content of file N", 13, 10, 0
cmd_help     db "help", 0
cmd_clear    db "clear", 0
cmd_cat      db "cat", 0
cmd_vga      db "vga", 0
cmd_disktest db "disktest", 0
cmd_format   db "format", 0
cmd_chkdsk   db "chkdsk", 0
cmd_corrupt  db "debug-corrupt", 0
cmd_pmode    db "pmode", 0
cmd_echo     db "echo ", 0
cmd_about    db "about", 0
cmd_ver      db "ver", 0
cmd_mem      db "mem", 0
cmd_time     db "time", 0
cmd_reboot   db "reboot", 0
cmd_ls       db "ls", 0
cmd_sh       db "sh", 0
cmd_cs       db "cs ", 0
cmd_pstcon   db "pstcon ", 0
cmd_remfil   db "remfil ", 0
cmd_readfil  db "readfil ", 0
msg_about    db "SHOFTY OS v0.2", 13, 10
             db "MetaSpawn Project - GPL-3.0", 13, 10
             db "x86 real-mode + 32-bit protected mode", 13, 10, 0
msg_mem      db "Conventional memory: ", 0
msg_kb       db " KB", 13, 10, 0
msg_time     db "RTC time: ", 0
msg_reboot   db "Rebooting...", 13, 10, 0
msg_pmode    db "Switching to protected mode...", 13, 10, 0
msg_read_ok  db "read OK!", 13, 10, 0
msg_dt_fail  db "disk error! code: ", 0
disk_buf     times 512 db 0
disk_buf2    db "SFM disk I/O works!", 13, 10, 0
             times 512-21 db 0
input_buffer times 64 db 0
name_buf     times 16 db 0
