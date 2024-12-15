
; Touch!
; Updates the access time for files. If the file doesn't exist, creates it.
; 
; touch [drive:][path]filename...
;

[map all ./lst/touch.map]
[DEFAULT REL]
BITS 64
%include "./inc/dosMacro.mac"
%include "./inc/dosStruc.inc"
%include "./inc/dosError.inc"
touch:
;Temporarily used to update the date/time of a file or create it anew
    lea rsi, qword [r8 + psp.progTail]
    xor ecx, ecx    ;Clear the number of files updated count
.lp:
    call skipDelims ;Goto the first non-delimiter char
    cmp al, CR
    je .exit
    mov rdx, rsi    ;Point rdx to the start of the path
    call findDelimOrCR
    xor eax, eax
    xchg al, byte [rsi] ;rsi points to the delim/CR char, so swap with null
    push rax
    push rcx
    call doTouch
    pop rcx
    pop rax
    jc .noIncCnt
    inc ecx
.noIncCnt:
    xchg byte [rsi], al ;replace the null with the original delimiter
    cmp al, CR
    jne .lp
.exit:
    mov ah, 4Ch
    mov al, cl  ;Retval is the number of files we updated
    int 21h

doTouch:
;Input: rdx -> Path to file to do magic to
;Output: CF=CY : File not updated
;        CF=NC : File updated
    mov eax, 5B00h  ;Create unique file 
    xor ecx, ecx
    int 21h
    jnc .close
    cmp al, errFilExist ;Does the file exist?
    jne .err        ;If not, this is a proper error!
    mov eax, 3D00h  ;R/O open instead to update the access time!!
    int 21h
    jc .err
.close:
    movzx ebx, ax   ;Save the handle here
    mov eax, 120Dh  ;Get date/time words from the DOS
    int 2fh
    mov ecx, eax    ;Move the time here
    xchg edx, ecx   ;Get them in the right place
    mov eax, 5701h  ;Set the date/time for bx
    int 21h
    mov eax, 3e00h  ;Close file immediately
    int 21h
    clc     ;Ensure we clear the flag in the even of Close not closing rn
    return  ;Returns CF=NC
.err:
    mov rdi, rdx
    mov eax, 1212h  ;Get the strlen for path pointed to in rdi in ecx
    int 2Fh
    mov ebx, 1
    mov eax, 4000h  ;Write the path name 
    int 21h
    lea rdx, accDenStr  ;Append the access denied magic
    mov eax, 0900h
    int 21h
    stc
    return

skipDelims:
;Points rsi to the first non-delimiter char in a string, loads al with value
    lodsb
    call isALDelim
    jz skipDelims
;Else, point rsi back to that char :)
    dec rsi
    return

findDelimOrCR:
;Point rsi to the first delim or cmdtail terminator, loads al with value
    lodsb
    call isALDelimOrCR
    jnz findDelimOrCR
    dec rsi ;Point back to the delim or CR char
    return

isALDelimOrCR:
    cmp al, CR
    rete
isALDelim:
    cmp al, SPC
    rete
    cmp al, TAB
    rete
    cmp al, "="
    rete
    cmp al, ","
    rete
    cmp al, ";"
    return

accDenStr db " -- Access denied",CR,LF,"$" 