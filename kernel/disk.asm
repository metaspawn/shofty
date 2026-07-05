; ================= SHOFTY DISK I/O =================
; Raw sector read/write via BIOS int 0x13.
; Foundation for SFM (SYS File Manager).
;
; disk_read:  reads  1 sector -> memory
; disk_write: writes 1 sector <- memory
;
; Input for both:
;   AX = LBA sector number (0 = boot sector, 17 = superblock...)
;   ES:BX = memory buffer (512 bytes)
; Output:
;   carry flag set on error

disk_read:
    push ax
    push cx
    push dx
    call lba_to_chs         ; AX -> CH/CL/DH
    mov ah, 0x02            ; BIOS: read sectors
    mov al, 1               ; one sector
    mov dl, [boot_drive_k]
    
int 0x13
    mov [disk_err], ah  ; save error code before restoring regs
    pop dx
    pop cx
    pop ax
    ret

disk_write:
    push ax
    push cx
    push dx
    call lba_to_chs
    mov ah, 0x03            ; BIOS: write sectors
    mov al, 1
    mov dl, [boot_drive_k]
    int 0x13
    pop dx
    pop cx
    pop ax
    ret

; ---------- lba_to_chs: converts LBA in AX to CHS registers ----------
; Floppy geometry: 18 sectors/track, 2 heads
;   sector   = (LBA % 18) + 1  -> CL
;   head     = (LBA / 18) % 2  -> DH
;   cylinder = (LBA / 18) / 2  -> CH
lba_to_chs:
    push bx
    mov bx, 18
    xor dx, dx
    div bx                  ; AX = LBA/18, DX = LBA%18
    inc dl
    mov cl, dl              ; sector
    xor dx, dx
    mov bx, 2
    div bx                  ; AX = cylinder, DX = head
    mov dh, dl              ; head
    mov ch, al              ; cylinder
    pop bx
    ret

boot_drive_k db 0x00        ; drive number (0x00 = floppy A:)
