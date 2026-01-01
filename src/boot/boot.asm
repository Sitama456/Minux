[org 0x7c00]

; 设置屏幕模式为文本模式，清楚屏幕
mov ax, 3
int 0x10

; 初始化段寄存器
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov si, booting
call print

; 目标内存
mov edi, 0x1000
; 起始扇区
mov ecx, 0x2
; 读取扇区个数
mov bl, 0x4
call read_disk

cmp word [0x1000], 0x55aa
jnz error

; 跳转到loader执行
jmp 0:0x1002

; 打印函数
print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret



read_disk:
    ; 设置读取扇区的个数
    mov dx, 0x1F2
    mov ax, bx
    out dx, ax

    ; 设置起始扇区
    inc dx                  ;  0x1F3
    mov al, cl              ;  0~7位
    out dx, al

    inc dx                  ;  0x1F4
    shr ecx, 8              ;  ecx的值右移8位
    mov al, cl              ;  8~15位
    out dx, al

    inc dx                  ;  0x1F5
    shr ecx, 8 
    mov al, cl              ;  16~23位
    out dx, al

    inc dx                  ;  0x1F6
    shr ecx, 8
    and cl, 0b1111          ; 将高四位置为0

    mov al, 0b1110_0000     ; 主盘，LBA模式
    or al, cl
    out dx, al

    ;发送读硬盘指令
    inc dx
    mov al, 0x20
    out dx, al

    xor ecx, ecx            ; 将ecx清空
    mov cl, bl             ; 得到扇区个数的数量

    ; 读写扇区
    .read:
        push cx             ; 先保存一下cx, 因为在reads中有循环会修改cx
        ; 等待数据准备完毕
        call .waits
        ; 读取一个扇区
        call .reads
        pop cx              ; 恢复cx

        loop .read          ; loop指令相当于 while(ecx != 0) 每次执行会将ecx--
    ret

    ; 等待硬盘准备好
    .waits:
        mov dx, 0x1f7
        .check:
            ; 读取状态到al寄存器
            in al, dx
            ; 需要一点点延迟
            jmp $+2         ; nop 直接跳转到下一行
            jmp $+2
            jmp $+2
            ; 关注第3位和第7位
            and al, 0b1000_1000
            ; 看第3位是否位1，第7位是否为0
            cmp al, 0b0000_1000
            ; 如果不相等, 继续check
            jnz .check
    ret
    ; 读取一个扇区
    .reads:
        mov cx, 256            ; 一个扇区256个字
        mov dx, 0x1f0
        ; 读取一个字
        .readw:
            in ax, dx
            ; 需要一点点延迟
            jmp $+2         ; nop 直接跳转到下一行
            jmp $+2
            jmp $+2
            mov [edi], ax
            add edi, 2
            loop .readw
    ret



booting:
    db "Booting Minux ...", 10, 13, 0 ; 10: \n, 13\r

error:
    mov si, .msg
    call print
    .msg:
        db "Booting Error !!!", 10, 13, 0 ; 10: \n, 13\r

    hlt
    jmp $



; 阻塞, $表示这一行
jmp $

; 填充剩下的区域为0
; times表示重复后面的指令
; $$ 表示开始的行
times 510 - ($ - $$) db 0



; bios要求，主引导扇区最后两个字节必须是0x55, 0xaa
db 0x55, 0xaa