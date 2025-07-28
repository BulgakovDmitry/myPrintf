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
; EXIT:        none
; DESTROY:     r10
;==================================================================================================
myPrintf:
    push r9                                      ; аргумент 6
    push r8                                      ; аргумент 5
    push rdx                                     ; аргумент 4
    push rcx                                     ; аргумент 3
    push rsi                                     ; аргумент 2
    push rdi                                     ; аргумент 1

    lea  r10, [rsp + 48]                         ; положим в регистр r10 адрес возврата (перепрыгиваем 6 8-байтных регистров => 6*8 = 48)
                                                 
    jmp  parse                                   ; парсим буффер 

exit:                                            ; точка выхода
    add  rsp, 48                                 ; значения регистров уже не нужны => снимаем их 48 = 8 байт * 6 регистров
    ret                                          

