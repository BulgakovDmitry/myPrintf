    section .text
    global _start

    ;----------------------------------------------------------------------------------------------
    _start:

        lea rsi, message                         ; rsi = &message
        call myPrintf   

        call exit0
    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    myPrintf:    
    ;   Function myPrintf is used to display text on the screen
    ;   Entry:   rsi - message, that should be displayed on the screen
    ;   Destr:   rax - ret value in function myStrlen - number of system call sys_write
    ;            rdi - value for "repne scasb" in function myStrlen - file descriptor for standard output (stdout)
    ;            rdx - length of the line displayed on the screen
    ;   Ret:     None 
        mov rdi, rsi                             ; rdi = rsi = &message
        call myStrlen                            ; rax = strlen(message)

        mov rdx, rax                             ; rdx = strlen(Hello world) + strlen(\n) = 11 + 2 ; ------ 
        mov rax, 1                               ; sys_write                                       ; output
        mov rdi, 1                               ; stdout                                          ; to    
        syscall                                  ; system call                                     ; screen

        ret
    ;----------------------------------------------------------------------------------------------


    ;----------------------------------------------------------------------------------------------
    myStrlen:
    ;   Function myStrlen is used to count the number of characters in a string
    ;   Entry:   rdi - string address
    ;   Destr:   rax - al = 0 for "repne scasb" - ret value
    ;   Ret:     rax - len of the string
        push rcx                                 ; save rcx

        xor rcx, rcx                             ; rcx = 0
        dec rcx                                  ; rcx = 0xFFFFFFFF (max)
        xor al, al                               ; al = 0

        cld                                      ; rdi will increase
        repne scasb                              ; while (cx-- && al != rsi++)

        neg rcx                                  ; rcx * (-1) [it is len + 1 at the moment]
        dec rcx                                  ; rcx--      [it is len     at the moment]
        mov rax, rcx                             ; rax = rcx = len

        pop rcx                                  ; save rcx
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

    message:
        db "Hello world", 10
    ;----------------------------------------------------------------------------------------------


    