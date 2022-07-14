; 显存地址
mov ax, 0b800h
mov ds, ax

; 现存的寻址空间，屏幕就是显存映像
mov byte [0x00], '2'
mov byte [0x02], '0'
mov byte [0x04], '2'
mov byte [0x06], '2'
mov byte [0x08], ','
mov byte [0x0a], ' '
mov byte [0x0c], 'H'
mov byte [0x0e], 'a'
mov byte [0x10], 'p'
mov byte [0x12], 'p'
mov byte [0x14], 'y'
mov byte [0x16], ' '
mov byte [0x18], 'N'
mov byte [0x1a], 'e'
mov byte [0x1c], 'w'
mov byte [0x1e], ' '
mov byte [0x20], 'Y'
mov byte [0x22], 'e'
mov byte [0x24], 'a'
mov byte [0x26], 'r'
mov byte [0x28], '!'

jmp $

times 510 - ($ - $$) db 0
db 0x55, 0xaa