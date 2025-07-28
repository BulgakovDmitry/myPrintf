section .bss
    buffer          resb BUFFER_SIZE             ; буфер
    bufferPosition  resb 1                       ; текущий индекс записи в buffer (позиция)

section .data
    hexTable db "0123456789ABCDEF"               ; шестадцатиричные символы для %x

    SYS_WRITE   equ 1                            ; номер системного вызова write
    FD_STDOUT   equ 1                            ; дескриптор stdout
    BUFFER_SIZE equ 128                          ; размер буфера
    MAX_SPECIDX equ 0x53   

section .text
    global myPrintf


;==================================================================================================
; ___________________________myPrintf______________________________________________________________  
; DESCRIPTION: stores the first 6 arguments in registers and starts parsing arguments
; ENTRY:       rdi, rsi, rcx, rdx, r8, r9
; EXIT:        rax (number of characters printed or -1 in case of error)
; DESTROY:     r10, rax, rsp
;==================================================================================================
    myPrintf:
        push r9                                  ; аргумент 6
        push r8                                  ; аргумент 5
        push rdx                                 ; аргумент 4
        push rcx                                 ; аргумент 3
        push rsi                                 ; аргумент 2
        push rdi                                 ; аргумент 1

        lea  r10, [rsp + 48]                     ; положим в регистр r10 адрес возврата (перепрыгиваем 6 8-байтных регистров => 6*8 = 48)
                                                    
        jmp  parse                               ; парсим буффер 

    exit:                                        ; точка выхода
        add  rsp, 48                             ; значения регистров уже не нужны => снимаем их 48 = 8 байт * 6 регистров
        ret                                          

;==================================================================================================
; ___________________________parse_________________________________________________________________  
; DESCRIPTION: main cycle in which buffer parsing takes place
; ENTRY:       rsp
; EXIT:        none
; DESTROY:     rax, rbx, rcx, rdx 
;==================================================================================================
    parse:
        mov  rax, [rsp]                          ; положим в rax адрес форматой строки (текущая вершина стека)
        lea  rbx, [rsp + 8]                      ; положим в rsp адрес первого аргумента myPrintf
        xor  rcx, rcx                            ; обнуление rcx
        mov  byte [bufferPosition], 0            ; инициализация позиции в буфере (стартовая позиция 0)

    mainCycle:
        xor     rdx, rdx                         ; обнуляем rdx
        mov     dl,  [rax]                       ; кладем текущую позицию форматной строки в младший байт rdx

        test  dl, dl                             ; if (*fmt == '\0')
        jz    mainCycleEnd                       ;     goto mainCycleEnd

        cmp   dl, '%'                            ; if (strcmp(*fmt, '%') == 0
        je    specificator                       ;     goto specificator

        cmp dl, '$'                              ; if (strcmp(*fmt, '%') == 0
        je    colorSpecificator                  ;     goto colorCpecificator

        ;                                        ; обработка "обычного" символа (не конец строки и не спецификатор)
        mov   dl, byte [rax]                     ;     положим текущий символ в младший байт rdx
        call  myPutc                             ;     выведем этот символ
        inc   rax                                ;     fmt++
        inc   rcx                                ;     увеличиваем на 1 счётчик напечатанных символов 
        jmp   mainCycle                          ;     возобновляем цикл для следующего символа

    specificator:

    colorSpecificator:

    mainCycleEnd :
        call  flush                              ; flush()
        mov   rax, rcx                           ; кладем в rax количество реально выведенных символов (-1 в случае ошибки)
        jmp   exit                               ; общее завершение

;==================================================================================================
; ___________________________myPutc________________________________________________________________ 
; DESCRIPTION: a function for outputting a character
; ENTRY:       dl (output symbol)
; EXIT:        none
; DESTROY:     none
;==================================================================================================
    myPutc :                             
        push rbx                                 ; сохраняем в стеке rbx

        xor rbx, rbx                             ; обнуляем rbx
        mov bl, byte [bufferPosition]            ; кладем в rbx номер позиции в буфере

        cmp   ebx, BUFFER_SIZE-1                 ; if (BUFFER_SIZE-1 != rbx)
        jb    writeSymbol                        ;     goto writeSymbol
        call  flush                              ; else flush()
        xor   ebx, ebx                           ; после сброса буфера кладем в rbx (позиция буффера) новую позицию 0     
    writeSymbol:
        mov   [buffer + rbx], dl                 ; сохраняем dl в буфере
        inc   bl                                 ; позиция++
        mov   [bufferPosition], bl               ; записываем новую позицию

        pop   rbx                                ; восстанавливаем rbx
        ret       

;==================================================================================================
; ___________________________flush_________________________________________________________________ 
; DESCRIPTION: function to flush the buffer
; ENTRY:       
; EXIT:        none
; DESTROY:     none
;==================================================================================================
    flush:
        push rax                                 ; сохранение
        push rdi                                 ; в стек
        push rsi                                 ; используемых
        push rdx                                 ; регистров

        xor rdx, rdx                             ; обнуление rdx
        mov dl, byte [bufferPosition]            ; поместим в dl текущую позицию буффера

        test  rdx, rdx                           ; if (bufferPosition == 0)
        jz    exitFlush                          ;     goto exitFlush
                                                 ; else
        mov   rax, SYS_WRITE                     ;     системный вызов write
        mov   rdi, FD_STDOUT                     ;     fd = stdout
        lea   rsi, [buffer]                      ;     rsi = buffer 
        syscall                                  ;     write(fd, buf, len)

        mov   byte [bufferPosition], 0           ; обнуление позиции буффера

    exitFlush:                                   ; выход из flush
        pop   rdx                                ;   | восстанавливаем 
        pop   rsi                                ;   | все используемые
        pop   rdi                                ;   | регистры
        pop   rax                                ;   | из стека
        ret                                      ; выход
