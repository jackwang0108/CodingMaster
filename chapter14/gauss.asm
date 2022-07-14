; 设定循环初值
mov cx, 100

; 循环相加
xor ax, ax
sum:
    add ax, cx
    loop sum

end: jmp end
times 510 - ($ - $$) db 0
    db 55h, 0AAh