; ================= SFM - SYS File Manager =================
; SHOFTY's native filesystem. v1.
;
; Disk layout:
;   sector 0       boot
;   sectors 1-64   kernel (32 KB)
;   sector 80      superblock: "SFM1" + file count
;   sectors 81-96  file table (16 sectors, 256 entries, 16 per sector)
;   sectors 97+    file data (1 sector per file in v1)
;
; Table entry (32 bytes):
;   name     16 bytes (null-terminated)
;   owner     8 bytes (null-terminated)
;   sector    2 bytes (where its data lives)
;   size      2 bytes (bytes used, max 512)
;   reserved  4 bytes

SFM_SUPER   equ 80          ; superblock sector (past the 64-sector kernel)
SFM_TABLE   equ 81          ; first table sector (81..96 = 16 sectors)
SFM_DATA    equ 97          ; first data sector

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

; ================================================================
; SFM v1 file operations
; Table entry (32 bytes): name[16] owner[8] sector[2] size[2] resv[4]
; An entry is FREE when its first name byte is 0.
; 16 entries per 512-byte table sector; 256 entries -> sectors 81..96.
; ================================================================

SFM_ENTRY_SZ  equ 32
SFM_MAX_FILES equ 256
SFM_MAX_SIZE  equ 50            ; per-file content cap (bytes)

; sfm_find leaves these set on a hit, so callers can persist:
;   sfm_cur_sector = table sector that was read into sfm_tbl
;   sfm_cur_index  = 0..255 entry index
;   DI             = pointer to the entry inside sfm_tbl

; ---------- sfm_load_entry: read the table sector for index CX ----------
; Input:  CX = entry index. Output: DI -> entry in sfm_tbl,
;         sfm_cur_sector set, carry on disk error.
sfm_load_entry:
    push ax
    push bx
    mov ax, cx
    shr ax, 4                  ; sector index = CX / 16 (16 entries per sector)
    add ax, SFM_TABLE
    mov [sfm_cur_sector], ax
    mov bx, sfm_tbl
    call disk_read
    jc .err
    mov di, cx
    and di, 15
    shl di, 5                  ; (CX & 15) * 32
    add di, sfm_tbl
    pop bx
    pop ax
    clc
    ret
.err:
    pop bx
    pop ax
    stc
    ret

; ---------- sfm_find: locate a file by name ----------
; Input:  SI = name (0-terminated)
; Output: carry CLEAR + DI -> entry, sfm_cur_sector/index set; carry SET if not
sfm_find:
    xor cx, cx
.scan:
    cmp cx, SFM_MAX_FILES
    jae .notfound
    call sfm_load_entry
    jc .notfound
    cmp byte [di], 0           ; free -> skip
    je .next
    push si
    push di
    call sfm_streq             ; SI vs DI
    pop di
    pop si
    jc .found
.next:
    inc cx
    jmp .scan
.found:
    mov [sfm_cur_index], cx
    clc
    ret
.notfound:
    stc
    ret

; ---------- sfm_streq: compare name SI (0-term) vs entry name DI ----------
sfm_streq:
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
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

; ---------- sfm_fill_data: put content DX (capped) into sfm_buf ----------
; Output: CX = actual byte count written
sfm_fill_data:
    push si
    push di
    mov di, sfm_buf
    mov cx, 512
    mov al, 0
    rep stosb                  ; clear buffer
    mov si, dx
    mov di, sfm_buf
    xor cx, cx
.cp:
    mov al, [si]
    test al, al
    jz .done
    cmp cx, SFM_MAX_SIZE
    jae .done
    mov [di], al
    inc si
    inc di
    inc cx
    jmp .cp
.done:
    pop di
    pop si
    ret

; ---------- sfm_create: make a new file with content ----------
; Input: SI = name (0-terminated), DX = content ptr (0-terminated)
sfm_create:
    push si
    push dx
    call sfm_find
    pop dx
    pop si
    jnc .exists

    ; find first free slot
    xor cx, cx
.free:
    cmp cx, SFM_MAX_FILES
    jae .full
    call sfm_load_entry
    jc .fail
    cmp byte [di], 0
    je .slot
    inc cx
    jmp .free

.slot:
    ; DI -> free entry in sfm_tbl, CX = index, sfm_cur_sector set
    mov [sfm_cur_index], cx

    ; clear entry
    push si
    push dx
    push di
    mov cx, SFM_ENTRY_SZ
    mov al, 0
    rep stosb
    pop di
    pop dx
    pop si

    ; copy name (max 15 + null)
    push di
    mov cx, 15
.nm:
    mov al, [si]
    test al, al
    jz .nm_end
    mov [di], al
    inc si
    inc di
    dec cx
    jnz .nm
.nm_end:
    pop di

    ; owner from current_user (max 7)
    push di
    push si
    add di, 16
    mov si, current_user
    mov cx, 7
.ow:
    mov al, [si]
    test al, al
    jz .ow_end
    mov [di], al
    inc si
    inc di
    dec cx
    jnz .ow
.ow_end:
    pop si
    pop di

    ; data sector = SFM_DATA + index
    mov ax, [sfm_cur_index]
    add ax, SFM_DATA
    mov [di+24], ax

    ; write content into that data sector
    push di
    call sfm_fill_data         ; CX = size, sfm_buf filled
    pop di
    mov [di+26], cx            ; store size

    mov ax, [di+24]            ; data sector
    mov bx, sfm_buf
    call disk_write
    jc .fail

    ; persist the table sector
    mov ax, [sfm_cur_sector]
    mov bx, sfm_tbl
    call disk_write
    jc .fail

    call sfm_bump_count
    mov si, msg_created
    call print_string
    clc
    ret

.exists:
    mov si, msg_exists
    call print_string
    stc
    ret
.full:
    mov si, msg_full
    call print_string
    stc
    ret
.fail:
    mov si, msg_op_fail
    call print_string
    stc
    ret

; ---------- sfm_write: replace content of an existing file ----------
; Input: SI = name, DX = content ptr
sfm_write:
    push dx
    call sfm_find              ; DI -> entry, sfm_cur_sector set
    pop dx
    jc .nofile

    push di
    call sfm_fill_data         ; CX = new size, sfm_buf filled
    pop di
    mov [di+26], cx            ; update size in the entry

    mov ax, [di+24]            ; data sector
    mov bx, sfm_buf
    call disk_write
    jc .fail

    ; persist the table sector (size changed)
    mov ax, [sfm_cur_sector]
    mov bx, sfm_tbl
    call disk_write
    jc .fail

    mov si, msg_written
    call print_string
    clc
    ret
.nofile:
    mov si, msg_nofile
    call print_string
    stc
    ret
.fail:
    mov si, msg_op_fail
    call print_string
    stc
    ret

; ---------- sfm_delete: remove a file by name ----------
; Input: SI = name
sfm_delete:
    call sfm_find
    jc .nofile

    ; wipe the 32-byte entry (name[0]=0 marks it free)
    push di
    mov cx, SFM_ENTRY_SZ
    mov al, 0
    rep stosb
    pop di

    ; persist that table sector
    mov ax, [sfm_cur_sector]
    mov bx, sfm_tbl
    call disk_write
    jc .fail

    call sfm_drop_count
    mov si, msg_deleted
    call print_string
    clc
    ret
.nofile:
    mov si, msg_nofile
    call print_string
    stc
    ret
.fail:
    mov si, msg_op_fail
    call print_string
    stc
    ret

; ---------- sfm_list: DL=0 hide dotfiles, DL=1 show all ----------
sfm_list:
    mov [sfm_show_hidden], dl
    mov si, msg_list_head
    call print_string
    xor cx, cx
.scan:
    cmp cx, SFM_MAX_FILES
    jae .done
    call sfm_load_entry
    jc .done
    cmp byte [di], 0
    je .next
    cmp byte [sfm_show_hidden], 1
    je .show
    cmp byte [di], '.'         ; hidden and not showing -> skip
    je .next
.show:
    mov si, di
    call print_string
    mov si, sfm_nl
    call print_string
.next:
    inc cx
    jmp .scan
.done:
    ret

; ---------- sfm_read: print the content of a file by name ----------
; Input: SI = name (0-terminated)
sfm_read:
    call sfm_find              ; DI -> entry, if found
    jc .nofile

    mov bp, [di+26]            ; BP = stored size (bytes)
    mov ax, [di+24]            ; data sector
    mov bx, sfm_buf
    call disk_read
    jc .fail

    ; print exactly BP bytes from sfm_buf
    mov si, sfm_buf
    xor cx, cx
.putc:
    cmp cx, bp
    jae .done
    mov al, [si]
    mov ah, 0x0E
    int 0x10
    inc si
    inc cx
    jmp .putc
.done:
    mov si, sfm_nl
    call print_string
    clc
    ret
.nofile:
    mov si, msg_nofile
    call print_string
    stc
    ret
.fail:
    mov si, msg_op_fail
    call print_string
    stc
    ret

; ---------- superblock file counter ----------
sfm_bump_count:
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_read
    jc .end
    inc word [sfm_buf+4]
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_write
.end:
    ret

sfm_drop_count:
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_read
    jc .end
    cmp word [sfm_buf+4], 0
    je .end
    dec word [sfm_buf+4]
    mov ax, SFM_SUPER
    mov bx, sfm_buf
    call disk_write
.end:
    ret

; ---------- op data ----------
sfm_show_hidden db 0
sfm_cur_sector  dw 0
sfm_cur_index   dw 0
sfm_tbl         times 512 db 0
msg_created   db "file created.", 13, 10, 0
msg_written   db "content written.", 13, 10, 0
msg_deleted   db "file removed.", 13, 10, 0
msg_exists    db "a file with that name already exists.", 13, 10, 0
msg_nofile    db "no such file.", 13, 10, 0
msg_full      db "file table is full.", 13, 10, 0
msg_op_fail   db "disk operation failed.", 13, 10, 0
msg_list_head db "files:", 13, 10, 0
