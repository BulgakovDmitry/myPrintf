    
    section .text
    global _start


    ;----------------------------------------------------------------------------------------------
    _start:

        lea rsi, messageForDisplaying            ; rsi = &message
        call myPrintf
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

        mov rbx, buffer                       ; create address of buffer (rbx)

        mov rdi, rsi                             ; rdi = rsi = &message
        call myStrlen                            ; rcx = strlen(message)

        call fillBuffer

        mov rsi, buffer 
    putc_loop:
        push rcx                                 ; save rcx because of syscall 
        call myPutc
        inc rsi
        pop rcx                                  ; save rcx because of syscall                                                                                         
        loop putc_loop

    ret
    ;----------------------------------------------------------------------------------------------


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
        je specifier                             ;      goto specifier
        jne notSpecifier                         ; else goto notSpecifier

    specifier:                                   ; ___specifier___
        mov al, '!'
        mov [rbx], al
        inc rbx
        inc rsi
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

    ret
    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    myPutc:    
    ;   Function myPutc used to display char on the screen
    ;   Entry:   rsi - char address, that should be displayed on the screen
    ;   Destr:   rax - number of system call sys_write
    ;            rdi - file descriptor for standard output (stdout)
    ;            rdx - length of the line displayed on the screen (1 for char)
    ;   Ret:     None 

        mov rdx, 1                               ; rdx = strlen([char]) = 1                        ; ------
        mov rax, 1                               ; sys_write                                       ; output
        mov rdi, 1                               ; stdout                                          ; to    
        syscall                                  ; system call                                     ; screen

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

   
    ;----------------------------------------------------------------------------------------------
    section .data                                                                                 

    messageForDisplaying:
        db "Hello wo%rld", 10
    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    section .bss

    buffer resb 100 ; reserve 100 bytes for the array
    ;----------------------------------------------------------------------------------------------