; 不产生进位的加法
mov ax, 0001h
mov bx, 0002h
add ax, bx

; 产生进位的加法
mov ax, 0f000h
mov bx, 1000h
add ax, bx

; 不产生借位的减法
mov cx, 0003h
mov dx, 0002h
sub cx, dx

; 产生借位的减法
mov cx, 0001h
mov dx, 0002h
sub cx, dx


end: jmp end

times 510 - ($ - $$) db 0
db 0x55, 0xAA