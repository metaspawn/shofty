; ================= SFM - SYS File Manager =================
; SHOFTY's native filesystem. v1.
;
; Disk layout:
;   sector 0      boot
;   sectors 1-16  kernel
;   sector 17     superblock: "SFM1" + file count
;   sectors 18-33 file table (16 sectors, 256 entries max)
;   sectors 34+   file data (1 sector per file in v1)
;
; Table entry (32 bytes):
;   name     16 bytes (null-terminated)
;   owner     8 bytes (null-terminated)
;   sector    2 bytes (where its data lives)
;   size      2 bytes (bytes used, max 512)
;   reserved  4 bytes

SFM_SUPER   equ 17          ; superblock sector
SFM_TABLE   equ 18          ; first table sector
SFM_DATA    equ 34          ; first data sector

; ---------- sfm_format: writes a virgin superblock ----------
; Creates: magic "SFM1" + file count 0. Wipes nothing else (v1).
sfm_format:
    ; build superblock in sfm_buf
    mov di, sfm_buf
    mov cx, 512
    mov al, 0
    push di
    rep stosb               ; clear buffer
    pop di

    mov byte [di+0], 'S'
    mov byte [di+1], 'F'
    mov byte [di+2], 'M'
    mov byte [di+3], '1'
    mov word [di+4], 0      ; file count = 0

    ; write it to the superblock sector
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_write
    jc .fail

    mov si, msg_fmt_ok
    call print_string
    ret
.fail:
    mov si, msg_fmt_fail
    call print_string
    mov al, [disk_err]
    call print_hex_byte
    mov si, sfm_nl
    call print_string
    ret

; ---------- sfm_check: reads superblock, verifies magic ----------
; Returns: carry SET if SFM not present/invalid
sfm_check:
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_read
    jc .bad

    cmp byte [sfm_buf+0], 'S'
    jne .bad
    cmp byte [sfm_buf+1], 'F'
    jne .bad
    cmp byte [sfm_buf+2], 'M'
    jne .bad
    cmp byte [sfm_buf+3], '1'
    jne .bad
    clc                     ; all good
    ret
.bad:
    stc
    ret

; ---------- SFM data ----------
msg_fmt_ok   db "SFM: disk formatted!", 13, 10, 0
msg_fmt_fail db "SFM: format failed! code: ", 0
msg_no_sfm   db "No SFM filesystem. Run 'format' first.", 13, 10, 0
sfm_nl       db 13, 10, 0
sfm_buf      times 512 db 0
