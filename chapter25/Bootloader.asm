section code vstart=0x7c00
    ; 约定: 
    ;   1. si用于打印字符串, 指向字符串开始位置
    ;   2. di备用
    Main:
        .SetupSegmentRegister:
            ; 初始化段寄存器
            xor ax, ax
            mov ds, ax
            mov es, ax
            mov ss, ax

        .SetupStackPointer:
            ; 使用0x7c00前的一些空间作为栈
            mov sp, 0x7c00

        ; 打印开始字符串
        mov si, BootloaderStart
        call PrintString

        ; 检查是否支持扩展int13, 使用BIOS中断的原因是BIOS对不同厂家的硬盘/固态已经做了屏蔽
        ; in/out读取的话需要查自己的硬盘/固态的厂家的端口说明
        .CheckInt13:
            ; int13是BIOS提供的读取磁盘的中断, 检测当前主板BIOS是否支持扩展的int13
            mov ah, 0x41 ; ah = 0x41, 检查是否支持int13扩展
            mov bx, 0x55aa  ; MagicNumber
            mov dl, 0x80  ; 选择读取的硬盘, 0x80表示主盘, 即BootLoader在的盘
            int 0x13
            cmp bx, 0xaa55 ; 如果当前主板支持扩展int13, 则bx高低位会被调换
            ; 当前主板不支持扩展int13中断则报错
            mov byte ds:[ShitHappens + 0x06], '1'
            jnz ErrorHappened

        ; 寻找MBR分区表中的活动分区
        .FindActivePartition:
            ; 程序被加载到 0x7c00 的位置, MBR分区0x01be偏移处开始分区表
            ; MBR分区表包含4个16字节的主分区入口, 循环读取, 看哪个分区是活动分区
            mov di, 0x7c00 + 0x01be
            mov cx, 4
            .judgeNextActivePatition:
                ; 启动扇区512字节已经被读取到内存了, 直接判断即可
                mov bl, [di]
                cmp bl, 0x80
                ; 找到活动分区, 读活动分区的FAT头
                je .ReadFatHead
                ; 没找到则判断下一个分区
                add di, 16
                loop .judgeNextActivePatition
            
            ; 四个都不是活动分区, 修改错误信息, 终止
            .NoActivatePartition:
                mov byte ds:[ShitHappens + 0x06], '2'
                jmp ErrorHappened

        ; FAT的物理结构:
        ;       |   FAT头   |   FAT表   | 根目录 |        FAT数据区        |
        ; 其中:
        ;       1. FAT头在的扇区/块称为保留扇区/块, 因为可以额外保留空间, 但一定小于512字节
        ;       2. FAT头前的区域称为隐藏扇区

        ; 读取FAT头到内存的7e00处, FAT头不大, 小于512字节, 所以读取512字节就保证一定能把FAT头读出来
        ; 计算数据区的首个块的LBA28地址只需要前90个字节的信息即可
        .ReadFatHead:
            ; 局部常量
            FatHeadMemAddr equ 0x7e00

            ; 打印BootLoader进程
            mov si, PatitionFound
            call PrintString
            ; 读取活动FAT分区的起始块号的LBA28地址, MBR标准中在首地址+8处
            ; 四个字节32位, 直接用ebx
            mov ebx, [di + 8]
            mov dword [BlockLow], ebx
            ; 保存目标内存起始地址
            mov word [BufferOffset], FatHeadMemAddr
            ; 明确物理块数
            mov byte [BlockCount], 1
            ; 读取
            call ReadDisk
        
        ; 接下来根据FAT头中的信息, 读取FAT数据区到内存中
        ; 所以要先准备FAT数据集的内容
        .PrepareReadFatData:
            FatDataMemAddr equ 0x8000

            ; 准备读取
            mov di, FatHeadMemAddr
            ; 读取保留扇区数
            xor ebx, ebx
            mov bx, [di + 0x0e] ; 1A0E
            ; 读取隐藏磁区数, 即FAT头所在的块前有多少个块, 2个字节, 位于0x0e偏移处
            mov eax, [di + 0x1c] ; 0080
            ; FAT分区表基址 = 保留区+隐藏区
            add ebx, eax

            ; 读取每簇扇区数, 为后续读取文件做准备
            xor eax, eax
            mov al, byte [di + 0x0d]
            push ax

            ; 计算数据区起始地址
            ; 获得FAT分区表数量
            xor cx, cx
            mov cl, [di + 0x10] ; 0002
            ; 获取FAT分区表大小
            mov eax, [di + 0x24] ; 000002F9
            .loopadd:
                add ebx, eax
                loop .loopadd

            ; 数据区起始LBA28地址 = 隐藏扇区块数 + 保留扇区块数 + FAT分区表大小 * FAT分区表数量
            mov dword [BlockLow], ebx
            mov word [BufferOffset], FatDataMemAddr

            ; 读取8个块(1个簇?), 放到内存其实地址为0x8000的地方
            mov di, FatDataMemAddr
            mov byte [BlockCount], 8

            call ReadDisk
            
            mov byte [ShitHappens + 0x06], '4'
        ; 读取了根目录在的第一个块之后, 查找Initial.bin文件
        ; FAT32使用32个字节表示一个FAT记录(一个文件/目录), 所以从0x0000偏移开始, 每次读取32个字节
        .FindInitialBin:
            cmp dword [di], 'INIT'
            jne .NextFile
            cmp dword [di + 4], "IAL "
            jne .NextFile
            cmp dword [di + 8], "BIN "
            jne .NextFile
            jmp .PrepareInitialBin

            .NextFile:
                cmp di, 0x9000
                ja ErrorHappened
                add di, 32
                jmp .FindInitialBin

        ; 找到Initial.bin之后, 准备读取该文件
        .PrepareInitialBin:
            mov si, InitialFound
            call PrintString

            ; 读取文件长度, 在32位记录中的的最后四位
            ; 低16位在0x1c中, 高16位在0x1e中, 单位是字节, 对512取除数和余数计算得到文件占了几个扇区
            mov ax, [di + 0x1c]
            mov dx, [di + 0x1e]
            ; cx是16位的, 所以除法是32位除法, 被除数放在ds:ax中, 除完后数放在dx, 商放在ax中
            mov cx, 512
            div cx
            cmp dx, 0
            je .NoExtraSector
            ; 余数不为0, 则需要多读一个扇区
            inc ax

            .NoExtraSector:
                mov [BlockCount], ax
                ; FAT32中不是使用小的块, 而是使用由几个块组成的簇, 一般一个簇由8个块组成
                ; 一个块一般为512字节, 所以一个簇一般为4096字节
                ; 具体一个簇有几个块需要看FAT头的0x0D处一个字节的值, pop出来前面准备的即可
                ; 此外, 一个簇用32位地址来标记, 高16位在0x14处, 低16位在0x1a处
                ; 簇地址从数据区第0个块开始记, 从2开始, 所以前面得到数据区的起始地址之后, 之后
                mov ax, word [di + 0x1a]
                ; 减2称以块数
                sub ax, 2
                pop cx
                mul cx
                ; 文件相对FAT数据区的偏移扇区数放在dx:ax中, 保存到ebx中去
                shl edx, 16
                and eax, 0x0000ffff
                add edx, eax

                ; 文件相对于磁盘头的偏移 = 文件相对FAT数据区的偏移扇区 + FAT数据区的偏移, 这个在读取FAT数据区开始的根目录时候依旧
                ; FAT数据区的偏移 在读取FAT数据区开始的根目录时候已经放到BlockLow里去了
                InitialBinMemAddr equ 0x9000
                mov eax, dword [BlockLow]
                add edx, eax
                mov dword [BlockLow], edx
                mov word [BufferOffset], InitialBinMemAddr

        ; 读取Initial.bin, 并且跳转过去运行
        .ReadInitialBin:
                mov di, InitialBinMemAddr
                call ReadDisk
                ; 打印字符串
                mov si, StartInitial
                call PrintString
                jmp di

    ; 读取磁盘的函数, 读取磁盘前要填充DiskAddressPacket结构体, 数据放在结构体中的BufferSeg:BufferOffset处
    ReadDisk:
        ; 保存寄存器
        push ax
        push dx
        push si

        ; 调用扩展int13中断
        mov ah, 0x42
        mov dl, 0x80
        mov si, DiskAddressPacket
        int 0x13
        test ah, ah
        mov byte [ShitHappens + 0x06], '3'
        jnz ErrorHappened

        ; 恢复寄存器
        pop si
        pop dx
        pop ax
        ret

    ErrorHappened:

        ; 发生错误之后, 打印错误字符串, 然后停机
        mov si, ShitHappens
        call PrintString
        hlt

    ; 同样, 主板BIOS对屏幕显示做了屏蔽, 利用主板BIOS中断来打印字符
    ; int10, ah=0x0e以打字机的方式打印字符, 所以直接传CR, LF即可
    PrintString:
        ; 保存寄存器
        push ax
        push cx
        mov cx, 512
        .printchar:
            mov al, [si]
            mov ah, 0x0e
            int 0x10
            ; 字符串是否到结尾
            cmp byte [si], 0x0a
            je .return
            ; 打印下一个字符串
            inc si
            loop .printchar
        .return:
            pop cx
            pop ax
            ret

DiskAddressPacket:
    ; DAP 是扩展int13, ah=0x42调用要求的参数, 类似于C函数传结构体
    ; 目前的标准是, 包大小为16字节, 第一个字节表示包大小, 第二个字节为保留字节, 第三四个字节表示读取多少个块
    ; 第五六个字节表示读到内存的段的偏移量, 第七八个字节表示读到哪个段
    ; LBA28, 用28个比特位, 4个字节(32位)表示块的地址, 所以最后四个字节表示读取的起始块的低地址, 后四个字节表示读取的起始块的高地址
    PackSize        db 0x10
    Reserved        db 0
    BlockCount      dw 0
    BufferOffset    dw 0
    BufferSegment   dw 0
    BlockLow        dd 0
    BlockHigh       dd 0

Prompts:
    CR equ 0x0d
    LF equ 0x0a
    BootloaderStart db "Start Boot!"
                    db CR, LF
    PatitionFound   db "FAT32 Partition found!"
                    db CR, LF
    InitialFound    db "initial found!"
                    db CR, LF
    StartInitial    db "Go initial!"
                    db CR, LF
    ; ErrorCode     Meaning
    ; 1             不支持扩展的int13, 即无法用BIOS的int13, AL
    ; 2             找不到活动分区
    ; 3             读取硬盘错误
    ; 4             没有找到initial.bin
    ShitHappens     db "Error 0, Shit happened T_T"
                    db CR, LF

; 填充余空间
times 446 - ($ - $$) db 0