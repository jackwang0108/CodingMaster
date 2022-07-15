section code align=16 vstart=0x9000
    Main:
        mov si, InitialPrompt
        call PrintString
        jmp MainEnd

    MainEnd:
        hlt
PrintString:
    push ax
    push cx
    push si

    mov cx, 512
    .putchar:
        mov al, [si]
        mov ah, 0x0e
        int 0x10
        cmp byte [si], 0x0a
        je .Return
        inc si
        loop .putchar

    .Return:
        pop si
        pop cx
        pop ax
        ret

InitialPrompt   db "I come from Initial.bin!"
                db 0x0d, 0x0a