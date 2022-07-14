; 常量声明
NUL equ 0x00
CHARFONT equ 0x07
VIDEOMEM equ 0xb800
STRLEN equ 0xffff

section head align=16 vstart=0
    ; Length    Address
    ; 4B        0x00
    Size dd ProgramEnd

    SegmentAddr:
        ; Length    Address
        ; 4B        0x04
        CodeSeg dd section.code.start   ; nasm提供的伪操作
        ; 4B        0x08
        DataSeg dd section.data.start
        ; 4B        0x0c
        StackSeg dd section.stack.start

    SegmentNum:
        ; Length    Address
        ; 1B        0x10
        SegNum db (SegmentNum - SegmentAddr) / 4

    ; 程序入口 = 段地址:偏移地址
        ; Length    Address
        ; 2B        0x11
    Enrty dw Main
        ; 4B        0x13
        dd section.code.start

section code align=16 vstart=0
    Main:
        mov ax, [DataSeg]
        mov ds, ax
        xor si, si
        call PrintString

        MainEnd: jmp MainEnd


    ; 打印字符串的函数
    PrintString:
        .setup:
        ; 保存通用寄存器
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        mov ax, es
        push ax

        ; 显存地址
        mov ax, VIDEOMEM
        mov es, ax
        xor di, di

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
            pop ax
            mov es, ax
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            ret
section data align=16 vstart=0
    Hell db "Hello, I come from program on hard disk sector 1, loaded by bootloader"

section stack align=16 vstart=0
    resb 128

section end align=16 
    ProgramEnd: