section .data
    welcome_msg db 'Simple Assembly Calculator', 0xA, 0
    welcome_len equ $ - welcome_msg
    
    menu_msg db '1. Addition', 0xA, '2. Subtraction', 0xA, '3. Multiplication', 0xA, '4. Division', 0xA, '5. Exit', 0xA, 'Enter choice: ', 0
    menu_len equ $ - menu_msg
    
    num1_msg db 'Enter first number: ', 0
    num1_len equ $ - num1_msg
    
    num2_msg db 'Enter second number: ', 0
    num2_len equ $ - num2_msg
    
    result_msg db 'Result: ', 0
    result_len equ $ - result_msg
    
    newline db 0xA, 0
    newline_len equ $ - newline
    
    div_zero_msg db 'Error: Division by zero!', 0xA, 0
    div_zero_len equ $ - div_zero_msg
    
    invalid_msg db 'Invalid choice!', 0xA, 0
    invalid_len equ $ - invalid_msg

section .bss
    choice resb 2
    num1 resb 12
    num2 resb 12
    result resb 20

section .text
    global _start

_start:
    ; Print welcome message
    mov eax, 4
    mov ebx, 1
    mov ecx, welcome_msg
    mov edx, welcome_len
    int 0x80

main_loop:
    ; Print menu
    mov eax, 4
    mov ebx, 1
    mov ecx, menu_msg
    mov edx, menu_len
    int 0x80
    
    ; Read choice
    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2
    int 0x80
    
    ; Convert choice to integer and check
    mov al, [choice]
    sub al, '0'
    
    cmp al, 1
    je addition
    cmp al, 2
    je subtraction
    cmp al, 3
    je multiplication
    cmp al, 4
    je division
    cmp al, 5
    je exit_program
    
    ; Invalid choice
    mov eax, 4
    mov ebx, 1
    mov ecx, invalid_msg
    mov edx, invalid_len
    int 0x80
    jmp main_loop

addition:
    call get_numbers
    add eax, ebx
    call print_result
    jmp main_loop

subtraction:
    call get_numbers
    sub eax, ebx
    call print_result
    jmp main_loop

multiplication:
    call get_numbers
    imul eax, ebx
    call print_result
    jmp main_loop

division:
    call get_numbers
    cmp ebx, 0
    je div_by_zero
    ; Clear edx before division
    xor edx, edx
    ; Check if dividend is negative
    test eax, eax
    jns div_positive
    ; Handle negative dividend
    neg eax
    div ebx
    neg eax
    jmp print_div_result
div_positive:
    div ebx
print_div_result:
    call print_result
    jmp main_loop

div_by_zero:
    mov eax, 4
    mov ebx, 1
    mov ecx, div_zero_msg
    mov edx, div_zero_len
    int 0x80
    jmp main_loop

get_numbers:
    ; Get first number
    mov eax, 4
    mov ebx, 1
    mov ecx, num1_msg
    mov edx, num1_len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num1
    mov edx, 12
    int 0x80
    
    ; Convert first number string to integer
    mov esi, num1
    call str_to_int
    push eax  ; Store first number
    
    ; Get second number
    mov eax, 4
    mov ebx, 1
    mov ecx, num2_msg
    mov edx, num2_len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num2
    mov edx, 12
    int 0x80
    
    ; Convert second number string to integer
    mov esi, num2
    call str_to_int
    mov ebx, eax  ; Store second number in ebx
    pop eax       ; Restore first number to eax
    ret

str_to_int:
    ; Convert string pointed by esi to integer in eax
    ; Handles both positive and negative numbers
    xor eax, eax    ; Clear result
    xor ecx, ecx    ; Clear counter
    xor edx, edx    ; Clear sign flag
    
    ; Check for negative sign
    mov bl, [esi]
    cmp bl, '-'
    jne parse_digits
    mov edx, 1      ; Set negative flag
    inc esi         ; Skip the minus sign
    
parse_digits:
    mov bl, [esi + ecx]
    cmp bl, 0xA     ; Check for newline
    je conversion_done
    cmp bl, 0       ; Check for null terminator
    je conversion_done
    cmp bl, ' '     ; Check for space
    je conversion_done
    
    ; Check if it's a valid digit
    cmp bl, '0'
    jl conversion_done
    cmp bl, '9'
    jg conversion_done
    
    ; Convert character to digit and add to result
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc ecx
    jmp parse_digits

conversion_done:
    ; Apply negative sign if needed
    test edx, edx
    jz str_to_int_done
    neg eax

str_to_int_done:
    ret

print_result:
    ; Print "Result: "
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, result_msg
    mov edx, result_len
    int 0x80
    pop eax
    
    ; Convert integer to string and print
    call int_to_str
    
    ; Print newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, newline_len
    int 0x80
    ret

int_to_str:
    ; Convert integer in eax to string and print it
    mov edi, result
    add edi, 19     ; Point to end of buffer
    mov byte [edi], 0
    
    ; Handle zero case
    test eax, eax
    jnz check_negative
    dec edi
    mov byte [edi], '0'
    jmp print_number

check_negative:
    ; Check if number is negative
    test eax, eax
    jns convert_positive
    ; Handle negative number
    neg eax
    push eax        ; Save absolute value
    
    ; Convert digits
convert_negative_digits:
    dec edi
    xor edx, edx
    mov ebx, 10
    div ebx
    add dl, '0'
    mov [edi], dl
    test eax, eax
    jnz convert_negative_digits
    
    ; Add minus sign
    dec edi
    mov byte [edi], '-'
    jmp print_number

convert_positive:
    dec edi
    xor edx, edx
    mov ebx, 10
    div ebx
    add dl, '0'
    mov [edi], dl
    test eax, eax
    jnz convert_positive

print_number:
    ; Calculate length and print
    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    mov edx, result
    add edx, 20
    sub edx, ecx
    int 0x80
    ret

exit_program:
    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80