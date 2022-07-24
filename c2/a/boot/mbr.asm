; 主引导程序
section mbr vstart=0x7c00  ; vstart=0x7c00，则nasm编译到这句话的时候会让cs为0x7c00
    ; 设置寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00


    ;清屏 利用0x06号功能，上卷全部行，则可清屏。
    ;------------------------------------------------------
    ;INT 0x10   功能号:0x06	   功能描述:上卷窗口
    ;------------------------------------------------------
    ;输入：
    ;AH 功能号= 0x06
    ;AL = 上卷的行数(如果为0,表示全部)
    ;BH = 上卷行属性
    ;(CL,CH) = 窗口左上角的(X,Y)位置
    ;(DL,DH) = 窗口右下角的(X,Y)位置
    ;无返回值：
    mov ah, 0x06
    mov al, 0
    mov cl, 0
    mov ch, 0
    mov dl, 79
    mov dh, 24
    int 0x10

    ;;;;;;;;;    下面这三行代码是获取光标位置    ;;;;;;;;;
    ;清屏 利用0x03号功能，上卷全部行，则可清屏。
    ;------------------------------------------------------
    ;INT 0x10   功能号:0x03	   功能描述:上卷窗口
    ;------------------------------------------------------
    ;输入：
    ;AH 功能号= 0x03
    ;BH = 获取光标的行号
    ;输出：
    ;ch = 光标开始行
    ;cl = 光标结束行
    ;dh = 光标所在行号
    ;dl = 光标所在列号
    mov ah, 3
    mov bh, 0
    int 0x10
    ;;;;;;;;;;;;;;    获取光标位置结束    ;;;;;;;;;;;;;;;;


    ;;;;;;;;;     打印字符串    ;;;;;;;;;;;
    ;还是用10h中断,不过这次是调用13号子功能打印字符串
    mov ax, message 
    mov bp, ax     ; es:bp 为串首地址, es此时同cs一致，开头时已经为sreg初始化

    ; 光标位置要用到dx寄存器中内容,cx中的光标位置可忽略
    mov cx, message_end - message      ; cx 为串长度,不包括结束符0的字符个数
    mov ax, 0x1301 ; 子功能号13是显示字符及属性,要存入ah寄存器,
            ; al设置写字符方式,只有低2位有意义
            ; al=01,显示字符串，光标跟随移动
    mov bx, 0x02  ; bh存储要显示的页号,此处是第0页, bl中是字符属性, 属性黑底绿字(bl = 02h)
    int 0x10       ; 执行BIOS 0x10 号中断
    ;;;;;;;;;      打字字符串结束	 ;;;;;;;;;;;;;;;

end: jmp end ; 使程序悬停在此

message db "1 MBR"
message_end:

times 510 - ($ - $$) db 0
    db 0x55, 0xaa
