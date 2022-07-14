HDDPORT equ 0x1f0
section code align=16 vstart=0x7c00
    ; 主程序
    ; 准备读取硬盘
    mov si, word ds:[READSTART]
    mov cx, word ds:[READSTART + 0x02]
    xor ax, ax
    mov al, byte ds:[SECTORNUM]
    push ax

    ; 准备写入内存
    ; 8086是小端, 即低字节在低地址, 低地址放到ax, 高地址放到dx
    mov ax, word ds:[DESTMEM]
    mov dx, word ds:[DESTMEM + 0x02]
    ; 8086寻址方式是 物理地址 = 段寄存器左移四位(乘16) + 段内偏移
    ; 所以还要给物理地址dx:ax除以16, 然后把得到的段地址送ds,
    ; 后面直接ds:[段内偏移]或者[段内偏移]即可访问0x10000以后的内存
    mov bx, 0x10
    div bx
    ; 除完了之后ax存放的就是段地址
    mov ds, ax

    xor di, di
    pop ax

    ; 函数调用, 将程序加载到内存的0x10000处
    call ReadHDD

    ; 因为程序中的代码都是相对地址, 因此需要对其地址进行重定位, 转换到真实的物理地址
    ; 读取程序段地址
    ResetSegment:
        ; 程序的代码段逻辑地址的段内偏移量
        mov bx, 0x04

        ; 读取程序的段数, 为后面的循环重定位做准备
        xor cx, cx
        mov cl, byte ds:[0x10]
        .reset:
            ; 读取代码/数据/栈段的逻辑地址
            mov ax, word ds:[bx]
            mov dx, word ds:[bx + 2]
            ; 汇编地址要转物理地址, 具体来说就是加上0x10000(因为把程度读到这里来了)
            add ax, word [cs:DESTMEM]
            adc dx, word [cs:DESTMEM + 2]

            ; 修改段地址:
            ;     读取得到的地址是汇编地址, 而由于程序是被加载到了某个位置上去
            ;     因此所以要先计算得到物理地址, 计算完了之后先保存回去
            ;     一般右移四位即可, 这里除16
            mov si, 0x10
            div si
            mov ds:[bx], ax
            ; 转换下一个段地址
            add bx, 4
            loop .reset
    
    ResetEntry:
        mov ax, word ds:[0x13]
        mov dx, word ds:[0x15]
        add ax, word [cs:DESTMEM]
        adc dx, word [cs:DESTMEM + 2]

        mov si, 16
        div si

        mov [0x13], ax

        ; 低位两个字节一个字16位作ip, 高位两个字节一个字16位作cs
        jmp far [0x11]

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
        mov ah, 0xe0
        or al, ah
        out dx, al

        ; 写入0x1f7, 表示要读硬盘
        mov dx, HDDPORT + 7
        mov al, 0x20
        out dx, al

        ; 等待硬盘读取完毕
        .waits:
            ; 硬盘状态码在0x1f7端口上
            ; mov dx, HDDPORT + 7
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
            loop .readword

        .return:
            pop dx
            pop cx
            pop bx
            pop ax
            ret

READSTART dd 1
SECTORNUM db 1
DESTMEM dd 0x10000

BootloaderEnd: jmp BootloaderEnd
times 510 - ($ - $$) db 0
        db 0x55, 0xaa