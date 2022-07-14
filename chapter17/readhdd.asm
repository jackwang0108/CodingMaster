HDDPORT equ 0x1f0
NUL equ 0x00
CHARFONT equ 0x07
VIDEOMEM equ 0xb800
STRLEN equ 0xffff

section code align=16 vstart=0x7c00
    ; 主程序
    ; 准备读取硬盘
    mov si, word [READSTART]
    mov cx, word [READSTART + 0x02]
    xor ax, ax
    mov al, [SECTORNUM]
    push ax

    ; 准备写入内存
    ; 8086是小端, 即低字节在低地址, 低地址放到ax, 高地址放到dx
    mov ax, word [DESTMEM]
    mov dx, word [DESTMEM + 0x02]
    ; 物理地址需要转换为逻辑地址, 即段号+段内偏移, 所以还要给值除以16, 8086每个段64K, 所以用四位表示段号
    mov bx, 0x10
    div bx
    ; 除完了之后dx:ax存放的就是段号
    mov ds, ax

    xor di, di
    pop ax

    ; 函数调用
    call ReadHDD
    xor si, si
    call PrintString
    jmp end

    ; 读取硬盘的函数
    ReadHDD:
        push ax
        push bx
        push cx
        push dx

        ; HDD的端口标准
        ; 读取的块数量写入0x1f2, 因为端口号超过了255, 所以要先把端口号放到dx寄存器中
        mov dx, HDDPORT + 2
        ; out指令将al中的内容送到dx中的端口中
        out dx, al

        ; 起始逻辑块好的0-7位置, 写入0x1f3的位置
        mov dx, HDDPORT + 3
        mov ax, si
        out dx, al
        ; 写入剩余的位置

        mov dx, HDDPORT + 4
        ; 8-15位在ah
        mov al, ah
        out dx, al

        mov dx, HDDPORT + 5
        ; 16-23位在cl
        mov al, cl
        out dx, al

        mov dx, HDDPORT + 6
        ; 24-32位在dh, 但是由于使用28位LBA, 所以取第四位即可
        mov al, ch
        or al, 0xe0
        out dx, al

        ; 写入0x1f7, 表示要读硬盘
        mov dx, HDDPORT + 7
        mov al, 0x20
        out dx, al

        ; 等待硬盘读取完毕
        .waits:
            ; 硬盘状态码在0x1f7端口上
            mov dx, HDDPORT + 7
            in al, dx
            ; 第3, 7位分别是1和0, 表示硬盘准备好了和硬盘不忙
            and al, 0x88
            cmp al, 0x08
            jnz .waits
        
        ; 读取硬盘
        mov dx, HDDPORT
        ; 一次读取2字节, 需要读取512字节, 循环读取256次
        mov cx, 256
        .readword:
            in ax, dx
            mov [ds:di], ax
            add di, 2
            ; 判断是否到结尾
            or ah, 0x00
            jnz .readword

        .return:
            pop dx
            pop cx
            pop bx
            pop ax
            ret

    ; 打印字符串的函数
    PrintString:
        .setup:
        ; 保存通用寄存器
        push ax
        push bx
        push cx
        push si
        push di
        mov ax, es
        push ax

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
            pop ax
            mov es, ax
            pop di
            pop si
            pop cx
            pop bx
            pop ax
            ret
; section data align=16
; LBA28用28个比特位表示读写的逻辑块编号, 所以需要一个double byte 32位来保存开始读取的逻辑块的编号
READSTART dd 10
; 读取1个块
SECTORNUM db 1
; 写入内存的物理地址, 8086CPU是20位寻址, 大于16, 小于32, 所以是double byte
DESTMEM dd 0x10000


end: jmp end
times 510- ($ - $$) db 0
                    db 0x55, 0xAA