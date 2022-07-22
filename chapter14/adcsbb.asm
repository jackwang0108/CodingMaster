; bx:ax = 0x0001f000
mov bx, 0001h
mov ax, 0f000h

; dx:cx = 0x00101000
mov dx, 0010h
mov cx, 1000h

add ax, cx
adc bx, dx

end: jmp end

times 510 - ($ - $$) db 0
    db 0x55, 0xAA