; 字符常量
CR equ 0x0d
LF equ 0x0a
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
        ; 初始化段寄存器
        mov ax, [StackSeg]
        mov ss, ax
        mov sp, StackEnd
        xor si, si
        ; 最后在设置数据寄存器
        mov ax, [DataSeg]
        mov ds, ax

        call ClearScreen
        call PrintString

        MainEnd: jmp MainEnd
    
    ; 清屏函数
    ClearScreen:
        mov ax, VIDEOMEM
        mov es, ax
        xor di, di
        mov bl, ' '
        mov bh, CHARFONT
        mov cx, 2000

        .putSpace:
            mov es:[di], bl
            inc di
            mov es:[di], bh
            inc di
            loop .putSpace

        ret

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

            ; 显示特殊字符
            ; 是否为回车
            cmp bl, CR
            jz .putcr
            ; 是否为换行
            cmp bl, LF
            jz .putlf

            ; 是否到结尾
            cmp bl, NUL
            jz .return

            ; 写正常字符
            inc si

            ; 写显存
            mov [es:di], bl
            ; 写字符属性
            inc di
            mov [es:di], bh
            inc di
            
            ; 移动光标
            call SetCursor
            jmp .putNext

        .putNext:
            loop .printchar

        .putcr:
            ; dos的设置一行80个字符, 每个字符一个字节存储ASCII码, 一个字符存储字符属性
            ; 所以160个字节一行字符
            mov bl, 160
            ; di指向当前显存处
            mov ax, di
            ; 计算得到当前行, 商放在ah处, 余数放在al处
            div bl
            shr ax, 8
            ; 移动指针到行首
            sub di, ax
            call SetCursor
            inc si
            jmp .putNext

        .putlf:
            ; 160个字节一行字符, 直接加160到下一行
            add di, 160
            call SetCursor
            inc si
            jmp .putNext

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
    
    ; 设置光标的函数, 光标的位置要放在bx中, dos标准80列25行,  bx的值对80取余就是列号, 整除就是行号
    SetCursor:
        ; 保存寄存器
        push ax
        push dx
        push bx

        ; di是当前的字符指针(字符ASCII+字符属性)的位置
        mov ax, di
        mov bx, 2
        div bx
        ; 读取光标当前的位置, 计算得到光标的位置
        mov bx, ax

        ; 端口清零, 准备访问显卡端口
        mov dx, 0
        ; 写显卡的0x3d4端口, 内容为中稍后0x3d5端口送来的数据写到显卡的哪个寄存器
        mov dx, 0x3d4
        mov al, 0x0e
        ; 向0x3d4端口发送0x0e表示稍后向0x3d5写得输入将写入显卡的0x0e寄存器
        ; 0x0e寄存器是光标的高八位地址, 0x0f是光标的低八位地址
        out dx, al

        ; 写高八位数据
        mov dx, 0x3d5
        mov al, bh
        out dx, al

        ; 准备写低八位地址
        mov dx, 0x3d4
        mov al, 0x0f
        out dx, al

        ; 写低八位数据
        mov dx, 0x3d5
        mov al, bl
        out dx, al

        ; 恢复寄存器
        pop bx
        pop dx
        pop ax
        ret

section data align=16 vstart=0
    Hello db "Hello, I come from program on section 1 with new strings, loaded by bootloader!"
        db CR, LF
        db "Haha, This is a new line!"
        db LF
        db "Just 0a"
        db CR
        db "Just 0d"
        db CR, LF
        db 0x00
section stack align=16 vstart=0
    times 128 db 0
    StackEnd:
section end align=16
    ProgramEnd: