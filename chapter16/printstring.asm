; 声明字符常量
NUL equ 0x00
CHARFONT equ 0x07
VIDEOMEM equ 0xb800
STRLEN equ 0xffff

section code align=16 vstart=0x7c00

    ; 主程序, ds默认为0, 利用si直接指向字符串地址
    mov si, SayHello
    xor di, di
    call PrintString

    mov si, SayByeBye
    xor di, di
    call PrintString
    jmp end

PrintString:
    .setup:
    ; 显存地址
    mov ax, VIDEOMEM
    mov es, ax

    ; 字符属性, 黑底白字
    mov bh, CHARFONT
    mov cx, STRLEN

    ; 输出单个字符
    .printchar:
        ; 读字符
        mov bl, [ds:si]
        inc si
        ; 写显存
        mov [es:di], bl
        ; 写字符属性
        inc di
        mov [es:di], bh
        inc di
        cmp bl, NUL
        jz .return
        loop .printchar
    .return:
        ret

SayHello db 'Hi there, I am Coding Master!'
        db 0x00
SayByeBye db "I think you can handle it, bye"
        db 0x00

; 结束部分
end: jmp end

times 510 - ($ - $$) db 0
    db 0x55, 0xAA