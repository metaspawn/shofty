; ================= SHOFTY DISK I/O v2 =================
; Raw sector read/write via BIOS int 0x13 EXTENSIONS (LBA).
; Modern, no CHS conversion needed. Foundation for SFM.
;
; disk_read:  reads  1 sector -> memory
; disk_write: writes 1 sector <- memory
;
; Input for both:
;   AX = LBA sector number
;   BX = memory buffer offset (segment 0 assumed)
; Output:
;   carry flag set on error, error code in [disk_err]

disk_read:
    push ax
    push dx
    push si
    mov [dap_lba], ax       ; LBA into the packet
    mov [dap_buf_off], bx   ; buffer offset into the packet
    mov ah, 0x42            ; BIOS: extended read
    mov dl, [boot_drive_k]
    mov si, dap             ; DS:SI -> Disk Address Packet
    int 0x13
    mov [disk_err], ah
    pop si
    pop dx
    pop ax
    ret

disk_write:
    push ax
    push dx
    push si
    mov [dap_lba], ax
    mov [dap_buf_off], bx
    mov ah, 0x43            ; BIOS: extended write
    mov al, 0               ; no verify
    mov dl, [boot_drive_k]
    mov si, dap
    int 0x13
    mov [disk_err], ah
    pop si
    pop dx
    pop ax
    ret

; ---------- Disk Address Packet (DAP) ----------
dap:
    db 0x10                 ; packet size (16 bytes)
    db 0                    ; reserved
dap_count:
    dw 1                    ; sectors to transfer
dap_buf_off:
    dw 0                    ; buffer offset
dap_buf_seg:
    dw 0                    ; buffer segment (0)
dap_lba:
    dd 0                    ; LBA (low 32 bits)
    dd 0                    ; LBA (high 32 bits, always 0 for us)

; ---------- disk data ----------
boot_drive_k db 0x80        ; real value comes from bootloader (DL)
disk_err     db 0           ; last BIOS int 0x13 error code
