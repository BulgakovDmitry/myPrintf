section .bss
    buffer          resb BUFFER_SIZE             ; буфер
    bufferPosition  resb 1                       ; текущий индекс записи в buffer (позиция)

section .data
    hexTable db "0123456789ABCDEF"               ; шестадцатиричные символы для %x

    SYS_WRITE   equ 1                            ; номер системного вызова write
    FD_STDOUT   equ 1                            ; дескриптор stdout
    BUFFER_SIZE equ 128                          ; размер буфера
    MAX_SPECIDX equ 0x53                         ; диапазон jump таблицы

    jumpTable:                                   ; jump таблица                    
                dq percent                       ;     '%'
    times 60    dq invalid                       ;     
                dq bin                           ;     'b'
                dq char                          ;     'c'
                dq dec                           ;     'd'
    times 10    dq invalid
                dq oct                           ;     'o'
    times 3     dq invalid
                dq str                           ;     's'
    times 4     dq invalid
                dq hex                           ;     'x'

section .text
    global myPrintf


;==================================================================================================
; ___________________________myPrintf______________________________________________________________  
; DESCRIPTION: stores the first 6 arguments in registers and starts parsing arguments
; ENTRY:       rdi, rsi, rcx, rdx, r8, r9
; EXIT:        rax (number of characters printed or -1 in case of error)
; DESTROY:     r10, rsp
;==================================================================================================
    myPrintf:
        push r9                                  ; аргумент 6
        push r8                                  ; аргумент 5
        push rcx                                 ; аргумент 4
        push rdx                                 ; аргумент 3
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
; EXIT:        rax (number of characters printed or -1 in case of error)
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
        inc   rax                                ; rax = fmt
        xor rdx, rdx                             ; обнуляем rdx
        mov dl, byte [rax]                       ; положим в dl спецификатор
        sub   edx, '%'                           ; вычитание кода '%' для джамп таблицы
        cmp   edx, MAX_SPECIDX                   ; проверка диапазона таблицы
        ja    invalid                            ; неизвестный символ  ошибка
        jmp   [jumpTable + rdx*8]                ; прямое разветвление


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

;==================================================================================================
; ___________________________NEXT_ARG______________________________________________________________ 
; DESCRIPTION: transitions to the next argument,
;              if you come across a slot with the RET address, skip it
; ENTRY:       none
; EXIT:        none
; DESTROY:     rbx
;==================================================================================================
    %macro NEXT_ARG 0
        add   rbx, 8                             ; rbx следующий слот
        cmp   rbx, r10                           ; if (rbx != return addr)
        jne   %%ok                               ;     goto ok
        add   rbx, 8                             ; else skip return addr
    %%ok:
    %endmacro

;==================================================================================================
;____________________________SPECIFICATORS_________________________________________________________ 
;==================================================================================================
    percent:    
        mov   dl, '%'                            ; dl = '%'
        call  myPutc                             ; myPutc(dl)
        inc   rax                                ; fmt++
        inc   rcx                                ; счётчик напечатанных символов увеличиваем на 1                     
        jmp   mainCycle                          ; возвращаемся в главный цикл

    char:                            
        push  rax                                ; сохраняем в стек fmt

        mov   rax, [rbx]                         ; rax = аргумент
        mov   dl, al                             ; dl  = символ
        call  myPutc                             ; myPutc(dl)

        pop   rax                                ; возвращаем из стека fmt

        NEXT_ARG                                 ; rbx = & следующего аргумента
        inc   rax                                ; fmt++
        inc   rcx                                ; счётчик напечатанных символов увеличим на 1
        jmp   mainCycle                          ; вернемся в главный цикл

    dec:      
        push  rax                                ; сохраняем в стек fmt

        mov   rax, [rbx]                         ; rax = аргумент
        call  printDecimalNumber                 ; печать числа

        pop   rax                                ; возвращаем из стека fmt

        NEXT_ARG                                 ; rbx = & следующего аргумента
        inc   rax                                ; fmt++
        jmp   mainCycle                          ; вернемся в главный цикл

    hex:                
        push  rax                                ; сохраняем в стек fmt

        mov   rax, [rbx]                         ; rax = аргумент
        call  printHexadecimalNumber             ; печать числа

        pop   rax                                ; возвращаем из стека fmt

        NEXT_ARG                                 ; rbx = & следующего аргумента
        inc   rax                                ; fmt++
        jmp   mainCycle                          ; вернемся в главный цикл

    oct: 
        push  rax                                ; сохраняем в стек fmt

        mov   rax, [rbx]                         ; rax = аргумент
        call  printOctalNumber                   ; печать числа

        pop   rax                                ; возвращаем из стека fmt

        NEXT_ARG                                 ; rbx = & следующего аргумента
        inc   rax                                ; fmt++
        jmp   mainCycle                          ; вернемся в главный цикл

    bin:      
        push  rax                                ; сохраняем в стек fmt

        mov   rax, [rbx]                         ; rax = аргумент
        call  printBinaryNumber                  ; печать числа

        pop   rax                                ; возвращаем из стека fmt

        NEXT_ARG                                 ; rbx = & следующего аргумента
        inc   rax                                ; fmt++
        jmp   mainCycle                          ; вернемся в главный цикл

    str:         
        push  rax                                ; сохраняем в стек fmt


        mov   rax, [rbx]                         ; rax = ptr строки
        call  printString                        ; печать строки

        pop   rax                                ; возвращаем из стека fmt

        NEXT_ARG                                 ; rbx = & следующего аргумента
        inc   rax                                ; fmt++  
        jmp   mainCycle                          ; вернемся в главный цикл

    invalid:                                     ; неизвестный спецификатор
        mov   rcx, -1                            ; rcx = -1 (код ошибки)
        jmp   mainCycleEnd                       ; завершаем главный цикл с текущим кодом ошибки

;==================================================================================================
; ___________________________EXTRACT_______________________________________________________________ 
; DESCRIPTION: extract the number of numbers in the stack (common to all bases)
; ENTRY:       3 numbers (macro args)
; EXIT:        none
; DESTROY:     rdx, rbx, rax
;==================================================================================================
    %macro EXTRACT 3                             ; #define EXTRACT(base, shift, mask)
    %%loop:
        %if %1 = 10                              ; if (base == 10)
            xor  rdx, rdx                        ;     rdx = 0  // подготовка перед делением
            mov  rbx, 10                         ;     rbx = 10 // делитель
            div  rbx                             ;     rax /= 10, rdx %= 10
            push rdx                             ;     кладём цифру (0…9) в стек
        %else                                    ; else
            mov  rdx, rax                        ;     rdx = rax = само число
            and  rdx, %3                         ;     маской оставляем младший разряд
            %if %1 = 16                          ;     if (base == 16)
                mov  dl, [hexTable + rdx]        ;         dl = символ 0…F
            %else                                ;     else
                add  dl, '0'                     ;         dl = '0' + цифра
            %endif                               ;     endif
            push rdx                             ;     кладём цифру в стек
            shr  rax, %2                         ;     сдвигаем исходное число
        %endif                                   ; endif
        inc  rcx                                 ; увеличиваем счётчик цифр
        test rax, rax                            ; if (rax != 0) // закончилось ли число
        jnz  %%loop                              ;     goto loop (еще итерация)
    %endmacro

;==================================================================================================
;____________________________PRINT_NUMBERS_________________________________________________________ 
;==================================================================================================
    printDecimalNumber:
        push rcx                                 ; сохраняем 
        push rdx                                 ; регистры
        push rbx                                 ; в стек

        xor   rcx, rcx                           ; счётчик цифр в стеке = 0
        cmp   rax, 0                             ; if (число >= 0)?
        jge   extractDec                         ;     goto extractDec
        neg   rax                                ; else число = -число // делаем его положительным
        mov   dl, '-'                            ;    dl = '-'      //  печатаем
        call  myPutc                             ;    myPutc(dl)    //  минус

    extractDec:                                  ; извлечение цифр десятичного
        EXTRACT 10,0,0                           ; числа в стек (маска не требуется)

    printDecimal:
        cmp   rcx, 0                             ; if (количество цифр в стеке [rcx] == 0)
        je    printDecimalEnd                    ;     goto end
        pop   rax                                ; берём очередную цифру
        add   al, '0'                            ; al = '0' + цифра
        mov   dl, al                             ; dl = al = ASCII цифры для вывода
        call  myPutc                             ; myPutc(dl)
        dec   rcx                                ; уменьшаем количество цифр в стеке, так как мы вывели число
        jmp   printDecimal                       ; goto printDecimal // возобновляем цикл
    printDecimalEnd:
        pop   rbx                                ; возвращаем 
        pop   rdx                                ; регистры 
        pop   rcx                                ; из стека
        ret

    printHexadecimalNumber:
        push rcx                                 ; сохраняем используемые
        push rbx                                 ; регистры в стек

        xor   rcx, rcx                           ; обнуляем счетчик rcx
        EXTRACT 16,4,0xF                         ; извлечь hex‑цифры

    printHexadecimal:
        cmp   rcx, 0                             ; if (количество цифр в стеке [rcx] == 0)
        je    printHexadecimalEnd                ;     goto end
        pop   rax                                ; берём очередную цифру
        mov   dl, al                             ; al уже символ 0…F, положим его в dl
        call  myPutc                             ; myPutc(dl)
        dec   rcx                                ; уменьшаем количество цифр в стеке, так как мы вывели число
        jmp   printHexadecimal                   ; goto printHexadecimal // возобновляем цикл

    printHexadecimalEnd:
        pop   rbx                                ; возвращаем сохраненные
        pop   rcx                                ; регистры из стека
        ret

    printOctalNumber:
        push rcx                                 ; сохраняем используемые
        push rbx                                 ; регистры в стек

        xor   rcx, rcx                           ; обнуляем счетчик rcx
        EXTRACT 8,3,0x7                          ; извлечь oct‑цифры

    printOctal:
        cmp   rcx, 0                             ; if (количество цифр в стеке [rcx] == 0)
        je    printOctalEnd                      ;     goto end
        pop   rax                                ; берём очередную цифру
        mov   dl, al                             ; al уже '0'…'7', кладем al в dl
        call  myPutc                             ; myPutc(dl)
        dec   rcx                                ; уменьшаем количество цифр в стеке, так как мы вывели число
        jmp   printOctal                         ; goto printHexadecimal // возобновляем цикл

    printOctalEnd:
        pop   rbx                                ; возвращаем сохраненные
        pop   rcx                                ; регистры из стека
        ret

    printBinaryNumber:

    printString: