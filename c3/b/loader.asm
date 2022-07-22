%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
    mov byte [gs:0x00], '2'
    mov byte [gs:0x01], 0b1010_0100
    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0b1010_0100
    mov byte [gs:0x04], 'L'
    mov byte [gs:0x05], 0b1010_0100
    mov byte [gs:0x06], 'o'
    mov byte [gs:0x07], 0b1010_0100
    mov byte [gs:0x08], 'a'
    mov byte [gs:0x09], 0b1010_0100
    mov byte [gs:0x0a], 'd'
    mov byte [gs:0x0b], 0b1010_0100
    mov byte [gs:0x0c], 'e'
    mov byte [gs:0x0d], 0b1010_0100
    mov byte [gs:0x0e], 'r'
    mov byte [gs:0x0f], 0b1010_0100

end: jmp end