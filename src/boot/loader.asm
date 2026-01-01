[org 0x1000]

dw 0x55aa   ; 魔数判断

mov si, loading
call print

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

loading:
    db "Loading Minux ...", 10, 13, 0 ; 10: \n, 13\r