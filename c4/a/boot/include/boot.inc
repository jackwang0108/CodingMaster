;-------------	 loader和kernel   ----------
LOADER_BASE_ADDR    equ 0x900
LOADER_START_SECTOR equ   0x2

;--------------   gdt描述符属性  -------------
DESC_G_4K           equ	  1000_0000_0000_0000_0000_0000b    ; 4K粒度
DESC_D_32           equ	   100_0000_0000_0000_0000_0000b
DESC_L	            equ	    00_0000_0000_0000_0000_0000b	;  64位代码标记，此处标记为0便可。
DESC_AVL            equ	     0_0000_0000_0000_0000_0000b	;  cpu不用此位，暂置为0  
DESC_LIMIT_CODE2    equ        1111_0000_0000_0000_0000b
DESC_LIMIT_DATA2    equ                 DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2   equ         000_0000_0000_0000_0000b
DESC_P	            equ		        1000_0000_0000_0000b
DESC_DPL_0          equ		         000_0000_0000_0000b
DESC_DPL_1          equ		         010_0000_0000_0000b
DESC_DPL_2          equ		         100_0000_0000_0000b
DESC_DPL_3          equ		         110_0000_0000_0000b
DESC_S_CODE         equ		           1_0000_0000_0000b
DESC_S_DATA         equ	                     DESC_S_CODE
DESC_S_sys          equ		           0_0000_0000_0000b
DESC_TYPE_CODE      equ	                 1000_0000_0000b	;x=1,c=0,r=0,a=0 代码段是可执行的,非依从的,不可读的,已访问位a清0.  
DESC_TYPE_DATA      equ	                 0010_0000_0000b	;x=0,e=0,w=1,a=0 数据段是不可执行的,向上扩展的,可写的,已访问位a清0.

; 平坦模式下段基地址都是0，所以高一个字节全是0, 除了显存段起始地址是0xb800
DESC_CODE_HIGH4     equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
DESC_DATA_HIGH4     equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
DESC_VIDEO_HIGH4    equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b

;--------------   选择子属性  ---------------
RPL0  equ   00b
RPL1  equ   01b
RPL2  equ   10b
RPL3  equ   11b
TI_GDT	 equ   000b
TI_LDT	 equ   100b