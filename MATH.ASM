; DE-CPOS MATH.SYS - Math Coprocessor Driver
; Floating Point and Math Functions Driver
; Version: 1.0 (AI Edition)

[ORG 0x0000]
[BITS 16]

; ===========================================
; Device Driver Header
; ===========================================
math_header:
    dd -1
    dw 0x8000
    dw math_strategy
    dw math_interrupt
    db 'MATH    '

; Math function codes
MATH_FADD    equ 0x01    ; Floating add
MATH_FSUB    equ 0x02    ; Floating subtract
MATH_FMUL    equ 0x03    ; Floating multiply
MATH_FDIV    equ 0x04    ; Floating divide
MATH_FSQRT   equ 0x05    ; Square root
MATH_FEXP    equ 0x06    ; Exponential
MATH_FLOG    equ 0x07    ; Logarithm
MATH_FSIN    equ 0x08    ; Sine
MATH_FCOS    equ 0x09    ; Cosine
MATH_FTAN    equ 0x0A    ; Tangent
MATH_FSIG    equ 0x0B    ; Sigmoid
MATH_FTANH   equ 0x0C    ; Hyperbolic tangent
MATH_FRELU   equ 0x0D    ; ReLU
MATH_FSOFT   equ 0x0E    ; Softmax

; Fixed point scaling (8-bit fractional part)
FIXED_SCALE  equ 256     ; 2^8 for 8.8 fixed point

; ===========================================
; Strategy Routine
; ===========================================
math_strategy:
    mov [math_req_off], bx
    mov [math_req_seg], es
    ret

; ===========================================
; Interrupt Routine
; ===========================================
math_interrupt:
    pusha
    push ds
    push es
    
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    les bx, [math_req]
    mov al, [es:bx+2]
    
    cmp al, 0
    je .init
    cmp al, 4
    je .read
    cmp al, 8
    je .write
    jmp .unsupported

; ===========================================
; Initialize Math Coprocessor
; ===========================================
.init:
    call init_math_coprocessor
    
    mov word [es:bx+14], math_end
    mov word [es:bx+16], cs
    or word [es:bx+3], 0x0100
    jmp .done

; ===========================================
; Read Math Status
; ===========================================
.read:
    mov di, [es:bx+14]
    mov ax, [es:bx+16]
    mov es, ax
    
    call get_math_result
    stosb
    
    mov ax, cs
    mov es, ax
    les bx, [math_req]
    mov word [es:bx+18], 1
    or word [es:bx+3], 0x0100
    jmp .done

; ===========================================
; Execute Math Function
; ===========================================
.write:
    mov si, [es:bx+14]
    mov ax, [es:bx+16]
    mov ds, ax
    
    lodsb               ; Function code
    mov ah, al
    lodsb               ; First operand
    mov bl, al
    lodsb               ; Second operand (if needed)
    mov bh, al
    
    push ax
    mov al, ah
    call execute_math_function
    pop ax
    
    mov ax, cs
    mov ds, ax
    les bx, [math_req]
    mov word [es:bx+18], 3  ; 3 bytes transferred
    or word [es:bx+3], 0x0100
    
.done:
    pop es
    pop ds
    popa
    retf

.unsupported:
    les bx, [math_req]
    or word [es:bx+3], 0x8103
    jmp .done

; ===========================================
; Math Functions
; ===========================================

; Initialize math coprocessor
init_math_coprocessor:
    pusha
    
    ; Check for FPU presence
    mov byte [fpu_present], 0
    fninit
    fnstsw ax
    cmp al, 0
    jne .no_fpu
    
    ; FPU detected
    mov byte [fpu_present], 1
    finit
    
.no_fpu:
    ; Initialize software FPU
    call init_soft_fpu
    
    ; Set status
    mov byte [math_ready], 1
    mov word [last_error], 0
    
    popa
    ret

; Initialize software FPU
init_soft_fpu:
    pusha
    
    ; Clear FPU registers
    mov cx, 8
    mov di, fpu_regs
    xor ax, ax
    rep stosw
    
    popa
    ret

; Execute math function
; Input: AL = function code, BL = operand1, BH = operand2
execute_math_function:
    pusha
    
    cmp al, MATH_FADD
    je .fadd
    cmp al, MATH_FSUB
    je .fsub
    cmp al, MATH_FMUL
    je .fmul
    cmp al, MATH_FDIV
    je .fdiv
    cmp al, MATH_FSQRT
    je .fsqrt
    cmp al, MATH_FSIG
    je .fsigmoid
    cmp al, MATH_FTANH
    je .ftanh
    cmp al, MATH_FRELU
    je .frelu
    jmp .done
    
.fadd:
    mov al, bl
    add al, bh
    mov [math_result], al
    jmp .done
    
.fsub:
    mov al, bl
    sub al, bh
    mov [math_result], al
    jmp .done
    
.fmul:
    mov al, bl
    mov ah, bh
    imul ah
    mov [math_result], al
    jmp .done
    
.fdiv:
    cmp bh, 0
    je .div_zero
    mov al, bl
    cbw
    idiv bh
    mov [math_result], al
    jmp .done
.div_zero:
    mov byte [math_result], 0
    jmp .done
    
.fsqrt:
    ; Square root approximation using integer math
    mov al, bl
    call sqrt_approx
    mov [math_result], al
    jmp .done
    
.fsigmoid:
    ; Sigmoid approximation using lookup table
    mov al, bl
    call sigmoid_approx
    mov [math_result], al
    jmp .done
    
.ftanh:
    ; Tanh approximation
    mov al, bl
    call tanh_approx
    mov [math_result], al
    jmp .done
    
.frelu:
    ; ReLU: max(0,x)
    mov al, bl
    cmp al, 128  ; Zero in fixed point?
    jae .relu_done
    mov al, 0    ; Set to zero
.relu_done:
    mov [math_result], al
    
.done:
    popa
    ret

; Square root approximation (integer)
; Input: AL = value (0-255)
; Output: AL = sqrt(value) approximated
sqrt_approx:
    pusha
    mov cx, 8
    mov bx, 0
    mov dx, 1
.sqrt_loop:
    mov ax, bx
    mul bx
    cmp al, [esp+8]  ; Compare with input
    jg .sqrt_done
    inc bx
    loop .sqrt_loop
.sqrt_done:
    mov al, bl
    popa
    ret

; Sigmoid approximation using lookup table
; Input: AL = input value (-128 to 127)
; Output: AL = sigmoid output (0-255 scaled)
sigmoid_approx:
    pusha
    
    ; Convert to signed
    cbw
    
    ; Simple piecewise linear approximation
    cmp ax, -50
    jl .sigmoid_0
    cmp ax, 50
    jg .sigmoid_255
    
    ; Linear region: y = (x + 50) * 255 / 100
    add ax, 50
    mov bl, 255
    imul bl
    mov bl, 100
    idiv bl
    jmp .sigmoid_done
    
.sigmoid_0:
    mov al, 0
    jmp .sigmoid_done
    
.sigmoid_255:
    mov al, 255
    
.sigmoid_done:
    mov [math_result], al
    popa
    ret

; Tanh approximation
; Input: AL = input value (-128 to 127)
; Output: AL = tanh output (-128 to 127 scaled)
tanh_approx:
    pusha
    
    ; Convert to signed
    cbw
    
    ; Simple approximation: tanh(x) ¡Ö x / (1 + |x|)
    mov bx, ax
    cmp ax, 0
    jge .tanh_pos
    neg bx
.tanh_pos:
    ; Compute denominator: 256 + |x|
    add bx, 256
    
    ; Compute x * 256 / (256 + |x|)
    mov ax, [esp+8]
    imul ax, 256
    idiv bx
    
    ; Result is in AL
.tanh_done:
    popa
    ret

; Get math result
get_math_result:
    pusha
    mov al, [math_result]
    popa
    ret

; Matrix multiplication (for neural networks)
; Input: SI = matrix A, DI = matrix B, CX = dimensions
matrix_multiply:
    pusha
    
    ; Simplified matrix multiplication
    mov ax, [si]
    mov bx, [di]
    imul bx
    mov [math_result], al
    
    popa
    ret

; Vector dot product
; Input: SI = vector A, DI = vector B, CX = length
dot_product:
    pusha
    
    xor ax, ax
    xor dx, dx
.dot_loop:
    mov bl, [si]
    mov bh, [di]
    imul bh
    add dx, ax
    inc si
    inc di
    loop .dot_loop
    
    mov [math_result], dl
    popa
    ret

; Activation function - ReLU
; Input: AL = input
; Output: AL = ReLU(input)
activation_relu:
    cmp al, 0
    jge .relu_out
    xor al, al
.relu_out:
    ret

; Activation function - Leaky ReLU
; Input: AL = input
; Output: AL = LeakyReLU(input)
activation_leaky_relu:
    cmp al, 0
    jge .leaky_out
    ; For negative values, multiply by 0.01 (approximately)
    sar al, 7           ; Divide by 128 (close to 0.01)
.leaky_out:
    ret

; Activation function - Sigmoid (fixed point)
; Input: AL = input
; Output: AL = sigmoid(input) in 8.8 fixed point
activation_sigmoid:
    pusha
    
    ; Use lookup table for fixed point sigmoid
    cbw
    add ax, 128         ; Shift to 0-255 range
    cmp ax, 255
    jbe .sigmoid_lookup
    mov al, 255
    jmp .sigmoid_done
.sigmoid_lookup:
    mov si, sigmoid_table
    add si, ax
    lodsb
.sigmoid_done:
    popa
    ret

; ===========================================
; Data Section
; ===========================================
math_req:
    math_req_off dw 0
    math_req_seg dw 0

math_ready      db 0
fpu_present     db 0
last_error      dw 0
math_result     db 0

; FPU registers (simulated)
fpu_regs        times 8 dw 0
fpu_stack_ptr   db 0

; Sigmoid lookup table (fixed point 8.8)
sigmoid_table:
    db 0, 0, 0, 0, 0, 0, 0, 0      ; -128 to -121
    db 0, 0, 0, 0, 0, 0, 0, 0      ; -120 to -113
    db 0, 0, 0, 0, 0, 0, 0, 0      ; -112 to -105
    db 0, 0, 0, 0, 0, 0, 0, 0      ; -104 to -97
    db 0, 0, 0, 0, 0, 0, 0, 0      ; -96 to -89
    db 0, 0, 0, 0, 0, 0, 0, 1      ; -88 to -81
    db 1, 1, 1, 1, 2, 2, 2, 3      ; -80 to -73
    db 3, 4, 4, 5, 6, 7, 8, 9      ; -72 to -65
    db 10, 12, 14, 16, 18, 21, 24, 27  ; -64 to -57
    db 31, 35, 40, 45, 50, 56, 62, 69  ; -56 to -49
    db 76, 84, 92, 100, 109, 118, 127, 137 ; -48 to -41
    db 147, 157, 168, 178, 189, 199, 210, 220 ; -40 to -33
    db 230, 239, 247, 255, 255, 255, 255, 255 ; -32 to -25
    times 24 db 255    ; -24 to -1
    times 128 db 255   ; 0 to 127

; Math constants in fixed point (8.8)
PI_FIXED     dw 804     ; 3.14159 * 256
E_FIXED      dw 695     ; 2.71828 * 256
ONE_FIXED    dw 256     ; 1.0 * 256
HALF_FIXED   dw 128     ; 0.5 * 256

math_end: