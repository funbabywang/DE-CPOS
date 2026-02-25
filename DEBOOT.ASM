; Deep Learning Command Prompt Operating System
; DE-CPOS (Deep Learning Command Prompt Operating System)
; DEBOOT.ASM - 深度学习命令提示符操作系统引导程序
; 版本: 1.0 (AI Edition)

[ORG 0x7C00]
[BITS 16]

; 常量定义
VIDEO_MEMORY   equ 0xB8000
SCREEN_WIDTH   equ 80
SCREEN_HEIGHT  equ 25
COLOR_NORMAL   equ 0x07      ; 灰色
COLOR_TITLE    equ 0x0F      ; 亮白色
COLOR_AI       equ 0x0A      ; 亮绿色
COLOR_DATA     equ 0x0B      ; 亮青色
COLOR_NEURAL   equ 0x0D      ; 亮粉色

; 启动入口
start:
    ; 初始化段寄存器
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; 保存引导驱动器号
    mov [boot_drive], dl

    ; 设置视频模式
    mov ax, 0x0003
    int 0x10

    ; 隐藏光标
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

    ; 显示欢迎信息
    mov si, welcome_msg
    call print_string
    
    mov si, logo_line1
    call print_string
    mov si, logo_line2
    call print_string
    mov si, logo_line3
    call print_string
    mov si, version_msg
    call print_string
    
    ; 等待按键
    mov si, press_key_msg
    call print_string
    call wait_for_key

    ; 系统启动完成
    mov si, system_ready
    call print_string
    
    ; 进入命令行
    call command_prompt

; 打印字符串函数
print_string:
    push ax
    push bx
    push si
    mov ah, 0x0E
    mov bh, 0x00
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    pop si
    pop bx
    pop ax
    ret

; 打印带颜色的字符串
print_color:
    push ax
    push bx
    push si
    mov ah, 0x0E
    mov bh, 0x00
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    pop si
    pop bx
    pop ax
    ret

; 等待按键
wait_for_key:
    mov ah, 0x00
    int 0x16
    ret

; 命令行提示符
command_prompt:
    call print_newline
    mov si, prompt
    call print_string
    
    ; 这里可以添加命令处理逻辑
    ; 目前只是循环显示提示符
    
    call wait_for_key
    cmp al, 0x0D           ; 回车
    jne command_prompt
    
    ; 显示命令回显
    call print_newline
    mov si, cmd_not_found
    call print_string
    jmp command_prompt

; 打印新行
print_newline:
    push ax
    mov al, 0x0D
    mov ah, 0x0E
    int 0x10
    mov al, 0x0A
    int 0x10
    pop ax
    ret

; 数据区
welcome_msg     db 'DE-CPOS v1.0 Boot Loader', 0x0D, 0x0A, 0
logo_line1      db '╔════════════════════════╗', 0x0D, 0x0A, 0
logo_line2      db '║  Deep Learning CPOS   ║', 0x0D, 0x0A, 0
logo_line3      db '╚════════════════════════╝', 0x0D, 0x0A, 0
version_msg     db 'Version: 1.0 (AI Edition)', 0x0D, 0x0A, 0x0D, 0x0A, 0
press_key_msg   db 'Press any key to continue...', 0x0D, 0x0A, 0
system_ready    db 'System ready.', 0x0D, 0x0A, 0x0D, 0x0A, 0
prompt          db 'DE-CPOS> ', 0
cmd_not_found   db 'Command not found', 0x0D, 0x0A, 0

boot_drive      db 0x00

; 填充剩余空间
times 510-($-$$) db 0

; 引导扇区标志
dw 0xAA55