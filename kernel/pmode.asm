; pmode.asm - real mode -> 32-bit protected mode + graphical desktop (mode 13h)
bits 16

switch_to_pmode:
    mov ax, 0x0013
    int 0x10
    cli
    call enable_a20
    lgdt [gdt_descriptor]
    mov eax, cr0
    or  eax, 1
    mov cr0, eax
    jmp CODE_SEG:pmode_entry

enable_a20:
    in  al, 0x92
    or  al, 2
    and al, 0xFE
    out 0x92, al
    ret

gdt_start:
gdt_null:
    dd 0
    dd 0
gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

bits 32

pmode_entry:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    call draw_desktop
.hang:
    hlt
    jmp .hang

draw_desktop:
    mov al, 3
    call clear_screen13

    mov esi, 12
    mov edi, 12
    mov ecx, 26
    mov edx, 26
    mov al, 15
    call fill_rect
    mov esi, 14
    mov edi, 14
    mov ecx, 22
    mov edx, 22
    mov al, 1
    call fill_rect

    mov esi, 0
    mov edi, 185
    mov ecx, SCR_W
    mov edx, 15
    mov al, 7
    call fill_rect
    mov esi, 0
    mov edi, 185
    mov ecx, SCR_W
    mov edx, 1
    mov al, 15
    call fill_rect

    mov esi, 3
    mov edi, 188
    mov ecx, 44
    mov edx, 9
    mov al, 8
    call fill_rect
    mov esi, 3
    mov edi, 188
    mov ecx, 44
    mov edx, 1
    mov al, 15
    call fill_rect
    mov esi, 3
    mov edi, 188
    mov ecx, 1
    mov edx, 9
    mov al, 15
    call fill_rect
    mov esi, 6
    mov edi, 189
    mov ebx, str_start
    mov dl, 15
    call draw_string

    mov esi, 270
    mov edi, 188
    mov ecx, 46
    mov edx, 9
    mov al, 8
    call fill_rect
    mov esi, 270
    mov edi, 188
    mov ecx, 46
    mov edx, 1
    mov al, 15
    call fill_rect
    mov esi, 273
    mov edi, 189
    mov ebx, str_clock
    mov dl, 15
    call draw_string
    ret

str_start: db "START", 0
str_clock: db "12:00", 0

%include "drivers/vga13.asm"
