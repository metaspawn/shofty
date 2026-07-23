; pmode.asm - switch from 16-bit real mode to 32-bit protected mode
; Entered in real mode. Once the far jump happens, the BIOS is gone:
; no more int 0x10 or int 0x13.

bits 16

switch_to_pmode:
    cli                         ; no interrupts until an IDT exists

    call enable_a20

    lgdt [gdt_descriptor]       ; load the segment table

    mov eax, cr0
    or  eax, 1                  ; set the PE bit
    mov cr0, eax

    ; The far jump is required: it flushes the prefetch queue and
    ; loads CS with the new 32-bit code selector.
    jmp CODE_SEG:pmode_entry

; ---------------------------------------------------------------
; A20 gate - without this, address line 20 stays stuck and every
; address above 1MB wraps back around to zero.
; ---------------------------------------------------------------
enable_a20:
    in  al, 0x92                ; fast A20 via the system control port
    or  al, 2
    and al, 0xFE                ; keep bit 0 clear: setting it resets the CPU
    out 0x92, al
    ret

; ---------------------------------------------------------------
; Global Descriptor Table: flat model, both segments span 0-4GB
; ---------------------------------------------------------------
gdt_start:

gdt_null:                       ; the first entry must be all zeros
    dd 0
    dd 0

gdt_code:                       ; base 0, limit 0xFFFFF, 4KB granularity
    dw 0xFFFF                   ; limit  0:15
    dw 0x0000                   ; base   0:15
    db 0x00                     ; base  16:23
    db 10011010b                ; present, ring 0, code, readable
    db 11001111b                ; granularity, 32-bit, limit 16:19
    db 0x00                     ; base  24:31

gdt_data:                       ; same span, writable data segment
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b                ; present, ring 0, data, writable
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; size, minus one
    dd gdt_start                ; linear address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; ---------------------------------------------------------------
; From here on the CPU runs 32-bit code.
; ---------------------------------------------------------------
bits 32

pmode_entry:
    mov ax, DATA_SEG            ; reload every data segment register
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000            ; a stack somewhere safe

    call clear_screen32

    mov esi, msg_banner
    call print_string32

    mov esi, msg_line
    call print_string32

    mov eax, 32
    call print_dec32

    mov esi, msg_bits
    call print_string32

.hang:
    hlt
    jmp .hang

msg_banner: db 'SHOFTY', 10, 0
msg_line:   db 'Protected mode reached. Running in ', 0
msg_bits:   db '-bit mode.', 10, 0


%include "drivers/vga32.asm"

    ; Write straight into VGA text memory. There is no BIOS here,
    ; so this is the only way to put anything on screen.
    mov edi, 0xB8000
    mov byte [edi],     'P'
    mov byte [edi + 1], 0x0F    ; white on black
    mov byte [edi + 2], 'M'
    mov byte [edi + 3], 0x0F

.hang:
    hlt
    jmp .hang
