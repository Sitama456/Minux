[org 0x1000]

dw 0x55aa   ; 魔数判断

mov si, msg_loading
call print

; 检测内存
call detect_memory

; 进入保护模式
jmp prepare_protected_mode


jmp $

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

detect_memory:
    .prepare:
        ; 清零EBX
        xor ebx, ebx
        ; 设置缓冲区
        mov ax, 0
        mov es, ax
        mov edi, ards_buffer

        ; 设置edx为固定签名
        mov edx, 0x534d4150
    .detect:
        ; 设置eax为0xe820，子功能号
        mov eax, 0xe820
        ; 设置ards结构体的字节大小为20 bytes
        mov ecx, 20
        ; 调用BIOS中断
        int 0x15

        ; 检测标志寄存器CF位置，如果置位，说明出错
        jc error
        ; 没有问题，将buffer指针指向下一个ards地址
        add edi, ecx
        ; 判断ebx是否为0，为0表示结束
        cmp ebx, 0
        jnz .detect

        ; 检测结束
        mov si, msg_detect_memory
        call print
ret

msg_loading:
    db "Loading Minux ...", 10, 13, 0 ; 10: \n, 13\r

msg_detect_memory:
    db "detecting memroy  success ...", 10, 13, 0 ; 10: \n, 13\r

prepare_protected_mode:
    cli                 ; 关中断，很重要，不然可能会有奇奇怪怪的错误
    ; 打开A20地址线
    in al, 0x92
    or al, 0b10
    out 0x92, al

    lgdt [gdt_ptr] ; 加载gdt指针
    ; 将cr0寄存器bit 0 置1，启动保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 跳转刷新缓存
    jmp dword code_selector:protected_mode

; 提醒编译器到了32 bit
[bits 32]
protected_mode:
    ; 初始化段寄存器
    mov ax, data_selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; 设置栈顶指针
    mov esp, 0x10000
    jmp $


error:
    mov si, .msg
    call print
    .msg:
        db "Loading Error !!", 10, 13, 0
    hlt
    jmp $

code_selector equ (1 << 3)
data_selector equ (2 << 3)

; 内存段基地址
memory_base equ 0
; 内存段界限，粒度是4K，所以是 4G / 4K  - 1
memory_limit equ ((1024 * 1024 * 1024 * 4) / (1024 * 4)) - 1

; 全局描述符指针
gdt_ptr:
    dw (gdt_end - gdt_base) - 1
    dd gdt_base

; 全局描述符表
; 第一个全局描述符必须是0
gdt_base:
    dd 0, 0
; 代码段全局描述符
gdt_code:
    dw memory_limit & 0xffff        ; 段界限bit 0~15
    dw memory_base & 0xffff         ; 内存段基址bit 0~15
    db (memory_base >> 16) & 0xff   ; 内存段基址bit 16~23
    ; 存在 - dpl 0 - S - 代码段 - 非已从 - 可读 - 没有被访问过
    db 0b_1_00_1_1_0_1_0
    ; 4K粒度 - 32位 - 不是64位 - 段界限 bit 16~19
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf
    db (memory_base >> 24) & 0xff   ; 内存段及地址 bit 24~31

; 代码段全局描述符
gdt_data:
    dw memory_limit & 0xffff        ; 段界限bit 0~15
    dw memory_base & 0xffff         ; 内存段基址bit 0~15
    db (memory_base >> 16) & 0xff   ; 内存段基址bit 16~23
    ; 存在 - dpl 0 - S - 数据段 - 向上 - 可写 - 没有被访问过
    db 0b_1_00_1_0_0_1_0
    ; 4K粒度 - 32位 - 不是64位 - 段界限 bit 16~19
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf
    db (memory_base >> 24) & 0xff   ; 内存段及地址 bit 24~31
gdt_end:


; e820 数组个数
ards_count:
    dw 0

; e820 数组
ards_buffer:
