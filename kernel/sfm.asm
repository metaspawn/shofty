; ================= SFM - SYS File Manager =================
; SHOFTY's native filesystem. v1.
;
; Disk layout:
;   sector 0      boot
;   sectors 1-32  kernel (16 KB)
;   sector 40     superblock: "SFM1" + file count
;   sectors 41-56 file table (16 sectors, 256 entries max)
;   sectors 57+   file data (1 sector per file in v1)
;
; Table entry (32 bytes):
;   name     16 bytes (null-terminated)
;   owner     8 bytes (null-terminated)
;   sector    2 bytes (where its data lives)
;   size      2 bytes (bytes used, max 512)
;   reserved  4 bytes

SFM_SUPER   equ 40          ; superblock sector
SFM_TABLE   equ 41          ; first table sector
SFM_DATA    equ 57          ; first data sector

; ---------- sfm_format: writes a virgin superblock ----------
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

    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_write
    jc .fail

    mov byte [sfm_active], 1    ; guard is now armed
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

; ---------- sfm_guard: integrity check with AUTO-REPAIR ----------
; Detects corruption, attempts to rebuild the superblock,
; panics only if the repair itself fails.
sfm_guard:
    cmp byte [sfm_active], 1
    jne .ok                 ; not formatted yet - nothing to guard
    push ax
    push bx
    xor ax, ax
    mov es, ax
    call sfm_check          ; superblock still "SFM1"?
    pop bx
    pop ax
    jnc .ok                 ; healthy

    ; --- CORRUPTION DETECTED ---
    mov si, err_detect
    call warning

    ; --- ATTEMPT AUTO-REPAIR ---
    mov si, msg_repairing
    call print_string

    push ax
    push bx
    xor ax, ax
    mov es, ax
    call sfm_rebuild
    pop bx
    pop ax
    jc .repair_failed

    call sfm_check          ; did the repair actually take?
    jc .repair_failed

    mov si, msg_repaired
    call print_string
.ok:
    ret

.repair_failed:
    mov si, err_fatal
    jmp panic               ; disk is dying - no return

; ---------- sfm_rebuild: writes a fresh superblock (silent) ----------
sfm_rebuild:
    mov di, sfm_buf
    mov cx, 512
    mov al, 0
    push di
    rep stosb
    pop di
    mov byte [di+0], 'S'
    mov byte [di+1], 'F'
    mov byte [di+2], 'M'
    mov byte [di+3], '1'
    mov word [di+4], 0      ; file count reset (v1: files lost)
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_write         ; carry passes through to caller
    ret

; ---------- sfm_corrupt: sabotage for testing (secret command) ----------
sfm_corrupt:
    mov di, sfm_buf
    mov cx, 512
    mov al, 0xFF            ; garbage
    rep stosb
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_write
    mov si, msg_corrupted
    call print_string
    ret

; ---------- sfm_diskcheck: disk examination (chkdsk) ----------
sfm_diskcheck:
    mov si, chk_head
    call print_string

    ; --- test 1: boot sector readable + signature? ---
    mov si, chk_t1
    call print_string
    mov ax, 0
    mov bx, sfm_buf
    call disk_read
    jc .t1_bad
    cmp word [sfm_buf+510], 0xAA55
    jne .t1_bad
    mov si, chk_ok
    call print_string
    jmp .test2
.t1_bad:
    mov si, chk_bad
    call print_string

.test2:
    ; --- test 2: SFM superblock healthy? ---
    mov si, chk_t2
    call print_string
    call sfm_check
    jc .t2_bad
    mov si, chk_ok
    call print_string
    jmp .test3
.t2_bad:
    mov si, chk_bad
    call print_string

.test3:
    ; --- test 3: write/read round trip on scratch sector ---
    mov si, chk_t3
    call print_string
    mov ax, 39              ; scratch sector (before SFM area)
    mov bx, sfm_buf
    mov byte [sfm_buf], 0x77
    call disk_write
    jc .t3_bad
    mov byte [sfm_buf], 0
    mov ax, 39
    mov bx, sfm_buf
    call disk_read
    jc .t3_bad
    cmp byte [sfm_buf], 0x77
    jne .t3_bad
    mov si, chk_ok
    call print_string
    jmp .done
.t3_bad:
    mov si, chk_bad
    call print_string

.done:
    mov si, chk_foot
    call print_string
    ret

; ---------- SFM data ----------
sfm_active    db 0
msg_fmt_ok    db "SFM: disk formatted!", 13, 10, 0
msg_fmt_fail  db "SFM: format failed! code: ", 0
msg_no_sfm    db "No SFM filesystem. Run 'format' first.", 13, 10, 0
err_detect    db "SFM superblock corrupted - integrity check failed", 0
msg_repairing db "  attempting automatic repair...", 13, 10, 0
msg_repaired  db "  superblock rebuilt successfully. crisis averted.", 13, 10, 13, 10, 0
err_fatal     db "auto-repair FAILED - disk is not responding", 0
msg_corrupted db "superblock destroyed. the guard will notice...", 13, 10, 0
chk_head      db 13, 10, "  SHOFTY DISK EXAMINATION", 13, 10
              db "  =======================", 13, 10, 0
chk_t1        db "  [1/3] boot sector integrity...... ", 0
chk_t2        db "  [2/3] SFM superblock health...... ", 0
chk_t3        db "  [3/3] disk write/read test....... ", 0
chk_ok        db "OK", 13, 10, 0
chk_bad       db "FAIL", 13, 10, 0
chk_foot      db 13, 10, "  Examination complete.", 13, 10, 13, 10, 0
sfm_nl        db 13, 10, 0
sfm_buf       times 512 db 0
