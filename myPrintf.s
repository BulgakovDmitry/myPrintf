    ; //TODO create locals points 
    ;----------------------------------------------------------------------------------------------
    section .data                                                                                 

    ;cases:                dq case_blue, case_per, case_reset  ; dq для 64-битных адресов
    defaultCase:          dq caseDefault              ; Адрес для случая по умолчанию
    itoaBuffer:           db "00000000000000000000", 0
    messageForDisplaying: db "Hello %b wo %g rld", 3
    blueColor           : db "\033[1;34m", 0
    whiteColor          : db "\033[1;37m", 0
    resetColor          : db "\033[0m", 0
    mangColor           : db "\033[1;35m", 0
    greenColor          : db "\033[1;32m", 0

    lenColor              equ 11
    lenReset              equ 8

    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    section .bss

    buffer resb 100 ; reserve 100 bytes for the array
    ;----------------------------------------------------------------------------------------------
    
    ;----------------------------------------------------------------------------------------------
    section .text
    global _start

    _start:

        lea rsi, messageForDisplaying            ; rsi = &message
        call myPrintf
        ;pop rax
        ;lea rdi, [itoaBuffer]   ; Загружаем адрес буфера в rdi
        ;call myItoa           ; Вызываем функцию itoa
        ;; Выводим строку на экран
        ;mov rax, 1          ; syscall: write
        ;mov rdi, 1          ; файловый дескриптор: stdout
        ;lea rsi, [itoaBuffer]   ; адрес строки
        ;mov rdx, 20         ; длина строки (максимум 20 символов)
        ;syscall
        ;ret

        call exit0
    ;----------------------------------------------------------------------------------------------

    ;----------------------------------------------------------------------------------------------
    myPrintf:
    ;   Function myPrintf is used to display text on the screen
    ;   Entry:   rsi - message, that should be displayed on the screen & address of buffer
    ;   Destr:   rax - [destr myPutc]
    ;            rbx - addess of buffer
    ;            rdi - [entry myStrlen] & [destr myPutc]
    ;            rdx - [destr myPutc]
    ;            rcx - [ret myStrlen]
    ;   Ret:     None 

        lea rbx, buffer                          ; create address of buffer (rbx)

        mov rdi, rsi                             ; rdi = rsi = &message
        call myStrlen                            ; rcx = strlen(message)

        call fillBuffer                          ; fillbuffer()
        lea rsi, buffer                          ; rsi = buffer (ptr)

    putc_loop:                                   ; cycle putc_loop
        call myPutc                              ; myputc()
        inc rsi                                  ; buffer++
        ;loop putc_loop                           ; end of cycle putc_loop

        mov al, [rsi]                            ; al = message[i]
        sub al, 3                                ; al - 3 = k
        test al, al                              ; al and al (k == 3)
        jnz putc_loop                            ; while k == 3

    ret

    ;----------------------------------------------------------------------------------------------
    ; lea r9, [blueColor]
    ; mov r10, lenColor
    codegenCase:
    ;
    ;   Entry:   r9  - nameColor
    ;            r10 - lenColor
    ;
        pop rdx ; len

        push rcx
        mov rcx, r10
        copy_loop1:
            mov al, byte [r9]                 ; Чтение символа из colorArray
            mov byte [rbx], al                 ; Запись символа в buffer
            inc r9                            ; Переход к следующему символу в colorArray
            inc rbx                            ; Переход к следующей позиции в buffer
            loop copy_loop1  
        pop rcx

        inc rsi

        push rdx
    ret
    ;----------------------------------------------------------------------------------------------

    ;----------------------------------------------------------------------------------------------

    ;fillBufferStart:
    ;    push rdi
   ; 
   ;     lea rdi, [greenColor]                     ; rdi = &blueColor;;

    ;    push rcx
    ;    mov rcx, lenColor
    ;    fillBufferStartCycle:
    ;        mov al, byte [rdi]                 ; Чтение символа из colorArray
    ;        mov byte [rbx], al                 ; Запись символа в buffer
    ;        inc rdi                            ; Переход к следующему символу в colorArray
    ;        inc rbx                            ; Переход к следующей позиции в buffer
    ;;        ;test al, al                        ; Проверка на нулевой терминатор
    ;        ;jnz copy_loop                     ; Продолжить цикл, если не конец строки
    ;        loop fillBufferStartCycle  
    ;    pop rcx
    ;    pop rdi
    ;ret

    ;----------------------------------------------------------------------------------------------
    fillBuffer:
    ;   
    ;
    ;
        push rcx                                 ; save len of messageForDisplaying

    fillBufferCycle:
        mov al, '%'                              ; al = '%'
        mov dl, [rsi]                            ; dl = *rsi = *(messageForDisplaying + i)
        cmp dl, al                               ; if (al == dl)
        jne notSpecifier                         ; else goto notSpecifier

    specifier:                                   ; ___specifier___
        inc rbx                                  ; buffer++
        inc rsi                                  ; message++


        mov al, [rsi]                            ; +__________switch buffer[i]__________+ //TODO LODSB

        cmp rax, 'b'                             ; if (buffer[i] == 'd')
        je case_blue                                ;         goto case_d
        cmp rax, 'g'                             ; if (buffer[i] == 'b')
        je case_green                                ;         goto case_b
        ;cmp rax, 'R'                             ; if (buffer[i] == 'c')
        ;je case_reset                                ;         goto case_c
        cmp rax, '%'                             ; if (buffer[i] == '%')
        je case_per                              ;         goto case_per

        jmp caseDefault                          ; else    goto caseDefaout

    case_blue:                                      ; ___case_blue___
    
        lea r9, [blueColor]
        mov r10, lenColor
        call codegenCase
        jmp switchEnd

    case_green:                                      ; ___case_green___
    
        lea r9, [greenColor]
        mov r10, lenColor
        call codegenCase
        jmp switchEnd

    ;case_reset:                                      ; ___case_green___
    ;
    ;    lea r9, [resetColor]
    ;    mov r10, lenReset
    ;    call codegenCase
    ;    jmp switchEnd

    case_per:                                    ; ___case_per___
        mov al, '%'
        mov [rbx], al
        inc rbx
        inc rsi
        jmp switchEnd

    caseDefault:                                 ; ___caseDefault___
        inc rsi
        jmp switchEnd

    switchEnd:                                  ; +__________switchEnd__________+

        jmp endOfCycle

    notSpecifier:                                ; ___notSpecifier___
        mov al, [rsi]                            ; al = *rsi = *(messageForDisplaying + i)
        mov [rbx], al                            ; *(rbx) = *(buffer) = al = *rsi = *(messageForDisplaying + i)
        inc rsi                                  ; rsi++
        inc rbx                                  ; rbi++
        jmp endOfCycle                           ; goto endOfCycle

    endOfCycle:

        loop fillBufferCycle                     ; while (cx--)
        pop rcx                                  ; save len of messageForDisplaying
        ;call myPutc

    ret
    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    myItoa:
        push rsi
        push rdi
        push rax
        push rcx
        push rdx

        mov rcx, 10         ; Основание системы счисления (10 для десятичной)
        mov rsi, rdi        ; Сохраняем адрес буфера в rsi
        add rsi, 19         ; Перемещаемся в конец буфера
        mov byte [rsi], 0   ; Записываем нулевой символ (конец строки)
        dec rsi             ; Перемещаемся на одну позицию влево

        ; Проверяем, если число равно 0
        cmp rax, 0
        je .zero_case

    .convert_loop:
        xor rdx, rdx        ; Очищаем rdx перед делением
        div rcx             ; Делим rax на 10, остаток в rdx
        add dl, '0'         ; Преобразуем остаток в символ
        mov [rsi], dl       ; Сохраняем символ в буфер
        dec rsi             ; Перемещаемся на одну позицию влево
        cmp rax, 0          ; Проверяем, если число стало 0
        jne .convert_loop   ; Если не 0, продолжаем цикл

        ; Если число было 0
    .zero_case:
        cmp rsi, rdi        ; Проверяем, если буфер не был использован
        jae .done           ; Если буфер использован, завершаем
        mov byte [rsi], '0' ; Записываем '0' в буфер

    .done:
        ; Сдвигаем результат в начало буфера
        inc rsi             ; Перемещаемся на начало строки
        mov rdi, rsi        ; Копируем адрес начала строки в rdi
        
        pop rdx
        pop rcx
        pop rax
        pop rdi
        pop rsi

    ret
    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    myPutc:    
    ;   Function myPutc used to display char on the screen
    ;   Entry:   rsi - char address, that should be displayed on the screen
    ;   Destr:   ;;;rax - number of system call sys_write
    ;            ;;;;;rdi - file descriptor for standard output (stdout)
    ;            ;;;;;rdx - length of the line displayed on the screen (1 for char)
    ;   Ret:     None 

        push rdi
        push rdx
        push rax
        push rcx

        mov rdx, 1                               ; rdx = strlen([char]) = 1                        ; ------
        mov rax, 1                               ; sys_write                                       ; output
        mov rdi, 1                               ; stdout                                          ; to    
        syscall                                  ; system call                                     ; screen
        
        pop rcx
        pop rax
        pop rdx                                                                                      
        pop rdi

    ret
    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    myStrlen:
    ;   Function myStrlen is used to count the number of characters in a string
    ;   Entry:   rdi - string address
    ;   Destr:   rax - al = 0 for "repne scasb"
    ;            rcx - counter
    ;   Ret:     rcx - len of the string

        xor rcx, rcx                             ; rcx = 0
        dec rcx                                  ; rcx = 0xFFFFFFFF (max)
        xor al, al                               ; al = 0

        cld                                      ; rdi will increase
        repne scasb                              ; while (cx-- && al != rsi++)

        neg rcx                                  ; rcx * (-1) [it is len + 2 at the moment]
        sub rcx, 2                               ; rcx-= 2    [it is len     at the moment]
        

    ret
    ;----------------------------------------------------------------------------------------------

   
    ;----------------------------------------------------------------------------------------------
    exit0:
    ;   Function exit0 is used to termitate the program with exit code 0
    ;   Entry:   None
    ;   Destr:   rax - number of system call "sys_exit"
    ;            rdi - exit code
    ;   Ret:     None
        mov rax, 60                              ; sys_exit     ;
        xor rdi, rdi                             ; rdi = 0      ; exit(0)
        syscall                                  ; system call  ;

    ret
    ;----------------------------------------------------------------------------------------------