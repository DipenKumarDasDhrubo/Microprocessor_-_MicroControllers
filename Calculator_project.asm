#make_COM#       ; EMU8086 directive to create COM file
ORG 100h         ; COM programs start at offset 100h

; ===================== DATA SECTION =====================
MENU        DB  10, 13, 'Disk Calculator', 10, 13
            DB  '1. Addition', 10, 13
            DB  '2. Subtraction', 10, 13
            DB  '3. Multiplication', 10, 13
            DB  '4. Division', 10, 13
            DB  '5. Exit', 10, 13, 10
            DB  'Enter choice (1-5): $'

PROMPT1     DB  10, 13, 'Enter first number (2-digit): $'
PROMPT2     DB  10, 13, 'Enter second number (2-digit): $'
RESULT_MSG  DB  10, 13, 'Result: $'
ERR_DIV0    DB  10, 13, 'Error: Cannot divide by zero!$'
FILENAME    DB  'CALCS.TXT', 0
HANDLE      DW  ?
BUFFER      DB  20 DUP(0)
NEWLINE     DB  10, 13, '$'

; ===================== CODE SECTION =====================
START:
    MOV AX, @DATA   ; Initialize data segment
    MOV DS, AX

MAIN_LOOP:
    CALL CLEAR_BUFFER
    
    ; Display menu
    MOV AH, 09h
    LEA DX, MENU
    INT 21h
    
    ; Get user choice
    CALL GET_CHOICE
    CMP AL, 5
    JE EXIT_PROGRAM
    
    ; Get numbers
    CALL GET_NUMBER
    MOV CL, AL       ; Store first number in CL
    
    CALL GET_NUMBER
    MOV CH, AL       ; Store second number in CH
    
    ; Perform calculation
    CALL CALCULATE
    
    ; Display result
    CALL SHOW_RESULT
    
    ; Save to file
    CALL SAVE_RESULT
    
    JMP MAIN_LOOP

EXIT_PROGRAM:
    MOV AX, 4C00h    ; Exit to DOS
    INT 21h

; ==================== SUBROUTINES =====================

; Clears the buffer
CLEAR_BUFFER PROC
    MOV CX, 20
    LEA DI, BUFFER
    MOV AL, 0
    REP STOSB
    RET
CLEAR_BUFFER ENDP

; Gets user choice (1-5)
GET_CHOICE PROC
    MOV AH, 01h      ; Read character
    INT 21h
    SUB AL, '0'      ; Convert ASCII to number
    RET
GET_CHOICE ENDP

; Gets 2-digit number (returns in AL)
GET_NUMBER PROC
    MOV AH, 09h
    LEA DX, PROMPT1  ; First prompt
    INT 21h
    
    MOV AH, 0Ah      ; Buffered input
    LEA DX, BUFFER
    INT 21h
    
    ; Convert ASCII to number
    MOV AL, BUFFER[2]
    SUB AL, '0'
    MOV BL, 10
    MUL BL
    MOV BL, AL
    
    MOV AL, BUFFER[3]
    SUB AL, '0'
    ADD AL, BL
    RET
GET_NUMBER ENDP

; Performs calculation based on user choice
CALCULATE PROC
    CMP BL, 1
    JE DO_ADD
    CMP BL, 2
    JE DO_SUB
    CMP BL, 3
    JE DO_MUL
    CMP BL, 4
    JE DO_DIV
    
DO_ADD:
    MOV AL, CL
    ADD AL, CH
    JMP CALC_DONE
    
DO_SUB:
    MOV AL, CL
    SUB AL, CH
    JMP CALC_DONE
    
DO_MUL:
    MOV AL, CL
    MUL CH
    JMP CALC_DONE
    
DO_DIV:
    CMP CH, 0
    JE DIV_ERROR
    MOV AL, CL
    XOR AH, AH
    DIV CH
    JMP CALC_DONE
    
DIV_ERROR:
    MOV AH, 09h
    LEA DX, ERR_DIV0
    INT 21h
    JMP MAIN_LOOP
    
CALC_DONE:
    MOV DL, AL      ; Store result in DL
    RET
CALCULATE ENDP

; Displays the result
SHOW_RESULT PROC
    MOV AH, 09h
    LEA DX, RESULT_MSG
    INT 21h
    
    MOV AL, DL      ; Get result
    AAM             ; Convert to BCD
    ADD AX, 3030h   ; Convert to ASCII
    
    MOV BX, AX
    MOV AH, 02h     ; Display tens digit
    MOV DL, BH
    INT 21h
    
    MOV DL, BL      ; Display units digit
    INT 21h
    
    MOV AH, 09h     ; New line
    LEA DX, NEWLINE
    INT 21h
    RET
SHOW_RESULT ENDP

; Saves result to file
SAVE_RESULT PROC
    ; Create/open file
    MOV AH, 3Ch
    MOV CX, 0       ; Normal file
    LEA DX, FILENAME
    INT 21h
    JC SAVE_ERROR
    MOV HANDLE, AX
    
    ; Write to file
    MOV AH, 40h
    MOV BX, HANDLE
    MOV CX, 20      ; Bytes to write
    LEA DX, BUFFER
    INT 21h
    
    ; Close file
    MOV AH, 3Eh
    MOV BX, HANDLE
    INT 21h
    RET
    
SAVE_ERROR:
    RET             ; Skip save if error occurs
SAVE_RESULT ENDP

END START