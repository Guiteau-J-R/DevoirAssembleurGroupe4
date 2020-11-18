;Faculte des Sciences de l'Universite d'Etat d'Haiti
;Devoir d'assembleur
;Professeur: M. Gary Antoine
;Preparer par: Justinien R. Guiteau
;Date: 16 Octobre 2020

.MODEL SMALL
.STACK 100H
.DATA

;The strings that will be print on screen 
MSG1  DB '***Average of 8 numbers***$'
MSG2 DB 'Enter a number: $'
MSG3 DB 'Average: $'
MSG4 DB "Presser n pour quiter ou n'importe quel bouton pour recommencer.$"

AVG   DW ? ;Variable to contain the average


.CODE
; This macro prints a char in AL and advances
; the current cursor position:
putc    MACRO   CHAR
        PUSH    AX
        MOV     AL, CHAR
        MOV     AH, 0EH
        INT     10H     
        POP     AX
ENDM

;This macro pass to a newline
newline MACRO
        PUSH AX
        MOV AL, 0AH
        MOV AH, 0EH
        INT 10H
     
        MOV AL, 0DH
        MOV AH, 0EH
        INT 10H
        POP AX
ENDM

;This macro print a msg to the screen
affichmsg MACRO msg
          PUSH AX
          LEA DX, msg
          MOV AH, 09H
          INT 21H
          POP AX
ENDM

;MAIN PROCEDURE
MAIN PROC FAR
     MOV AX, @DATA
     MOV DS, AX
     
     affichmsg MSG1                 ;print the message contained in MSG1
     
     begin:
     newline                        ;Pass to a new line
     MOV AVG, 0000H                 ;Clear AVG
     MOV CX, 8                      ;to loop 8 time
     loop1:
     PUSH CX                        ;Load CX in the stack
     affichmsg MSG2                 ;Print the message contained in MSG2
     CALL SCAN_NUM                  ;Prompt the user for an input
     ADD AVG, CX                    ;Add the number entered by the user to AVG
     newline                        ;Pass to a new line
     POP CX                         ;Return CX that was loaded
     LOOP loop1                     ;Return to loop1
     
     XOR DX, DX                     ;Clear DX
     MOV BX, 08H                    ;Assign the value 8 to BX
     MOV AX, AVG                    ;Assign the value of AVG  to AX
     DIV BX                         ;Division of AX and BX
     
     MOV AVG, AX                    ;Load the value of AX in AVG
     
     newline                        ;Pass to a newline
     affichmsg MSG3                 ;Print the message contained in MSG3
     CALL PRINT_NUM_UNS             ;Print the value in AX on the screen
     
     newline                        ;Pass to a new line
     newline                        ;Pass to a new line
     affichmsg MSG4                 ;Print the message contained in MSG3
     
     ;Prompt the user for input without printing
     MOV AH, 00h                    
     INT 16h
     
     CMP AL, 'N'
     JE exit                        ;Jump to exit if the user's input is N
     CMP AL, 'n'
     JE exit                        ;Jump to exit if the user's input is n
     
     newline                        ;Pass to a new line
     JMP begin                      ;return to begin
     
     exit:
     ;Interrupt the program
     MOV AH,4CH 
     INT 21H
     
MAIN ENDP
     


SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8                      ; backspace.
        PUTC    ' '                    ; clear last entered not digit.
        PUTC    8                      ; backspace again.        
        JMP     next_digit             ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX                  ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2                ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX                  ; restore the backuped value before add.
        MOV     DX, 0                   ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten                  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8                       ; backspace.
        PUTC    ' '                     ; clear last entered digit.
        PUTC    8                       ; backspace again.        
        JMP     next_digit              ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?               ; used as a flag.
SCAN_NUM        ENDP





; this procedure prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

        PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP



; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0                   ; set flag.

        MOV     DX, 0
        DIV     BX                      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h                 ; convert to ASCII code.
        PUTC    AL


        MOV     AX, DX                  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten                  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
        PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP



ten             DW      10              ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.
     
     


