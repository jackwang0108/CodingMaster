;主引导程序 
;------------------------------------------------------------
%include "boot.inc"

section mbr vstart=0x7c00
    ; 设置段寄存器
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax

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
    ;直接写显存
    mov byte [gs:0x00], '1'
    mov byte [gs:0x01], 0b1010_0100
    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0b1010_0100
    mov byte [gs:0x04], 'M'
    mov byte [gs:0x05], 0b1010_0100
    mov byte [gs:0x06], 'B'
    mov byte [gs:0x07], 0b1010_0100
    mov byte [gs:0x08], 'R'
    mov byte [gs:0x09], 0b1010_0100
    ;;;;;;;;;      打字字符串结束	 ;;;;;;;;;;;;;;;

    ;;;;;;;;;     读取硬盘    ;;;;;;;;;;;
    ; LBA28地址需要4个字节存储，所以放在eax
    mov eax, LOADER_START_SECTOR
    ; 读取后内存放到的地址
    mov bx, LOADER_BASE_ADDR
    ; 读取一个扇区
    mov cx, 4
    call rd_disk_m_16

    ; 跳转到BootLoader处运行
    jmp LOADER_BASE_ADDR

    ;;;;;;;;;     硬盘读取结束    ;;;;;;;;;;;

;-------------------------------------------------------------------------------
;功能:读取硬盘n个扇区
rd_disk_m_16:	   
; eax=LBA扇区号
; ebx=将数据写入的内存地址
; ecx=读入的扇区数
;-------------------------------------------------------------------------------
    ; 此时是16位实模式，不能push32位的寄存器
    mov esi, eax	  ;备份eax
    mov di, cx		  ;备份cx
    ;读写硬盘:
    ;第1步：设置要读取的扇区数
    mov dx, 0x1f2
    mov al, cl
    out dx, al            ;读取的扇区数

    mov eax,esi	   ;恢复ax

    ;第2步：将LBA地址存入0x1f3 ~ 0x1f6

    ;LBA地址7~0位写入端口0x1f3
    mov dx, 0x1f3                       
    out dx, al                          

    ;LBA地址15~8位写入端口0x1f4
    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al

    ;LBA地址23~16位写入端口0x1f5
    shr eax, cl
    mov dx, 0x1f5
    out dx, al

    shr eax, cl
    and al, 0x0f	   ;lba第24~27位
    or al, 0xe0	   ; 设置7～4位为1110,表示lba模式
    mov dx, 0x1f6
    out dx, al

    ;第3步：向0x1f7端口写入读命令，0x20, 0x1f7是一个8位寄存器
    mov dx, 0x1f7
    mov al, 0x20                        
    out dx, al

    ;第4步：检测硬盘状态
    .not_ready:
        ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
        nop
        in al, dx
        and al, 0x88	   ;第4位为1表示硬盘控制器已准备好数据传输，第7位为1表示硬盘忙
        cmp al, 0x08
        jnz .not_ready	   ;若未准备好，继续等。

    ;第5步：从0x1f0端口读数据
    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax	    ; di为要读取的扇区数，一个扇区有512字节，每次读入一个字，
                    ; 共需di*512/2次，所以di*256
    mov dx, 0x1f0
    .go_on_read:
        in ax, dx
        mov [bx], ax
        add bx, 2		  
        loop .go_on_read

    ret

times 510 - ($ - $$) db 0
db 0x55, 0xaa