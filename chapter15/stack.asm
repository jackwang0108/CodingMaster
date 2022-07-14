; 设置ss寄存器
mov bx, 0x0000
mov ss, bx

; 设置sp寄存器
mov sp, 0x0000

; ax压栈
push ax

; ax出栈
pop ax


; 循环补0
end: jmp end


times 510 - ($ - $$) db 0
    db 0x55, 0xAA