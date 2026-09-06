; ============================================================================
; CSE341 MICROPROCESSORS PROJECT
; Project: MAZE RUNNER WITH 1 ENEMY & COLORED END SCREENS (2 KEYS)
; Target : EMU8086 4.08, 8086, COM program
; ============================================================================

#make_COM#
ORG 100H

JMP START

; ============================================================================
; CONSTANTS
; ============================================================================
ROWS          EQU 8
COLS          EQU 8
MAZE_SIZE     EQU 64           ; 8 * 8
WALL          EQU 1
EXIT_CELL     EQU 2
MAX_TURNS     EQU 80
FOG_ROWS      EQU 2
FOG_COLS      EQU 4

PLAYER_START_ROW EQU 1
PLAYER_START_COL EQU 1

; FIXED KEY POSITIONS
KEY1_ROW      EQU 1
KEY1_COL      EQU 6

KEY2_ROW      EQU 5
KEY2_COL      EQU 1

E1_START_ROW  EQU 6
E1_START_COL  EQU 5

; ============================================================================
; MAZE ARRAY
; Address formula: index = row * 8 + column
; GOAL 'G' (2) is fixed at Row 6, Col 6.
; ============================================================================
maze DB 1,1,1,1,1,1,1,1
     DB 1,0,0,0,1,0,0,1
     DB 1,0,1,0,1,0,0,1
     DB 1,0,1,0,0,0,0,1
     DB 1,0,1,1,1,0,0,1
     DB 1,0,0,0,0,0,0,1
     DB 1,0,0,0,0,0,2,1
     DB 1,1,1,1,1,1,1,1

; Separate item array.
; 0 = no item, 1 = key
items DB MAZE_SIZE DUP(0)

; ============================================================================
; GAME VARIABLES
; ============================================================================
playerRow   DB PLAYER_START_ROW
playerCol   DB PLAYER_START_COL
playerHP    DB 3               ; Changed from 5 to 3
keyCount    DB 0
turnCount   DB 0

; Number of old player positions currently saved on the CPU stack.
pathDepth   DB 0

; actionCode values: 0=none, 1=move, 2=rope, 3=quit
actionCode  DB 0

enemy1Row   DB E1_START_ROW
enemy1Col   DB E1_START_COL

; gameState values: 0=playing, 1=win, 2=lose, 3=quit
gameState   DB 0

; loseReason values: 1=HP zero, 2=turn limit
loseReason  DB 0

inputKey    DB 0
newRow      DB 0
newCol      DB 0
renderRow   DB 0
renderCol   DB 0
testRow     DB 0
testCol     DB 0
verticalDistance   DB 0
horizontalDistance DB 0

; ============================================================================
; TEXT MESSAGES
; ============================================================================
titleMsg     DB 13,10,'=== MAZE RUNNER WITH ENEMY ===',13,10,'$'
controlsMsg  DB 'Controls: W=UP S=DOWN A=LEFT D=RIGHT R=ROPE Q=QUIT',13,10,'$'
legendMsg    DB 'Legend: P Player  X Enemy  K Key  G Exit  # Wall  ? Fog',13,10,'$'
objectiveMsg DB 'Goal: collect 2 Keys and reach G before HP becomes 0.',13,10,'$'

hpMsg        DB 'HP: $'
keyMsg       DB '   Keys: $'
keyTotalMsg  DB '/2$'
turnMsg      DB '   Turns: $'
slashMsg     DB '/80$'
historyMsg   DB '   Stack: $'

promptMsg    DB 13,10,'Your move: $'
wallMsg      DB 13,10,'Wall! Choose another direction.',13,10,'$'
ropeEmptyMsg DB 13,10,'Escape Rope stack is empty.',13,10,'$'

winMsg       DB 13,10,'YOU WIN! 2 Keys collected and exit reached.',13,10,'$'
loseHPMsg    DB 13,10,'GAME OVER! Your HP reached 0.',13,10,'$'
loseTurnMsg  DB 13,10,'GAME OVER! 80-turn limit reached.',13,10,'$'
quitMsg      DB 13,10,'Game ended by user.',13,10,'$'

; ============================================================================
; PROGRAM START
; ============================================================================
START:
    CALL InitGame

GAME_LOOP:
    CALL ClearScreen
    CALL DrawFrame

    CMP gameState, 0
    JNE GAME_FINISHED

    LEA DX, promptMsg
    CALL PrintString

    ; DOS INT 21h, AH=01h reads one character with echo
    MOV AH, 1
    INT 21H
    MOV inputKey, AL

    CALL HandleKey

    CMP actionCode, 1
    JE MAIN_DO_MOVE

    CMP actionCode, 2
    JE MAIN_DO_ROPE

    CMP actionCode, 3
    JE MAIN_DO_QUIT

    JMP GAME_LOOP

; ----------------------------------------------------------------------------
; VALID MOVEMENT
; ----------------------------------------------------------------------------
MAIN_DO_MOVE:
    MOV AL, newRow
    MOV BL, newCol
    CALL IsWalkable

    CMP AL, 1
    JE MOVE_IS_VALID

    LEA DX, wallMsg
    CALL PrintString
    CALL WaitKey
    JMP GAME_LOOP

MOVE_IS_VALID:
    MOV AH, playerRow
    MOV AL, playerCol
    PUSH AX
    INC pathDepth

    MOV AL, newRow
    MOV playerRow, AL
    MOV AL, newCol
    MOV playerCol, AL

    INC turnCount
    CALL ResolveTurn
    JMP GAME_LOOP

; ----------------------------------------------------------------------------
; ESCAPE ROPE / BACKTRACK
; ----------------------------------------------------------------------------
MAIN_DO_ROPE:
    CMP pathDepth, 0
    JNE ROPE_AVAILABLE

    LEA DX, ropeEmptyMsg
    CALL PrintString
    CALL WaitKey
    JMP GAME_LOOP

ROPE_AVAILABLE:
    POP AX
    MOV playerCol, AL
    MOV playerRow, AH
    DEC pathDepth

    INC turnCount
    CALL ResolveTurn
    JMP GAME_LOOP

MAIN_DO_QUIT:
    MOV gameState, 3
    JMP GAME_LOOP

; ============================================================================
; FINAL STATE (COLORED SCREENS)
; ============================================================================
GAME_FINISHED:
    CMP gameState, 1
    JE SHOW_WIN

    CMP gameState, 2
    JE SHOW_LOSE

    JMP SHOW_QUIT

SHOW_WIN:
    MOV BH, 2Fh         ; 2 = Green Background, F = Bright White Text
    CALL ColorScreen    
    LEA DX, winMsg
    CALL PrintString
    JMP PROGRAM_EXIT

SHOW_LOSE:
    MOV BH, 4Fh         ; 4 = Red Background, F = Bright White Text
    CALL ColorScreen    
    CMP loseReason, 1
    JE SHOW_HP_LOSS

    LEA DX, loseTurnMsg
    CALL PrintString
    JMP PROGRAM_EXIT

SHOW_HP_LOSS:
    LEA DX, loseHPMsg
    CALL PrintString
    JMP PROGRAM_EXIT

SHOW_QUIT:
    CALL ClearScreen
    LEA DX, quitMsg
    CALL PrintString

PROGRAM_EXIT:
    MOV AX, 4C00H
    INT 21H

; ============================================================================
; PROCEDURE: ColorScreen
; Standard 8086 BIOS interrupt to color the terminal.
; Input: BH = color attribute byte
; ============================================================================
ColorScreen PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; INT 10h, AH=06h: Scroll up window (clears screen if AL=0)
    MOV AH, 06h
    MOV AL, 00h        
    ; BH already contains color code passed into procedure
    MOV CX, 0000h       ; Top-left corner (Row 0, Col 0)
    MOV DX, 184Fh       ; Bottom-right corner (Row 24, Col 79)
    INT 10h

    ; INT 10h, AH=02h: Set cursor position back to Top-Left
    MOV AH, 02h
    MOV BH, 0           ; Video Page 0
    MOV DX, 0000h       ; Row 0, Col 0
    INT 10h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
ColorScreen ENDP

; ============================================================================
; PROCEDURE: InitGame
; ============================================================================
InitGame PROC
    PUSH AX
    PUSH BX
    PUSH SI

    ; Place Key 1
    MOV AL, KEY1_ROW
    MOV BL, KEY1_COL
    CALL ComputeIndex
    MOV items[SI], 1

    ; Place Key 2
    MOV AL, KEY2_ROW
    MOV BL, KEY2_COL
    CALL ComputeIndex
    MOV items[SI], 1

    POP SI
    POP BX
    POP AX
    RET
InitGame ENDP

; ============================================================================
; PROCEDURE: HandleKey
; ============================================================================
HandleKey PROC
    PUSH AX
    MOV actionCode, 0
    MOV AL, inputKey

    CMP AL, 'w'
    JE HK_UP
    CMP AL, 'W'
    JE HK_UP
    CMP AL, 's'
    JE HK_DOWN
    CMP AL, 'S'
    JE HK_DOWN
    CMP AL, 'a'
    JE HK_LEFT
    CMP AL, 'A'
    JE HK_LEFT
    CMP AL, 'd'
    JE HK_RIGHT
    CMP AL, 'D'
    JE HK_RIGHT
    CMP AL, 'r'
    JE HK_ROPE
    CMP AL, 'R'
    JE HK_ROPE
    CMP AL, 'q'
    JE HK_QUIT
    CMP AL, 'Q'
    JE HK_QUIT

    JMP HK_DONE

HK_UP:
    MOV AL, playerRow
    DEC AL
    MOV newRow, AL
    MOV AL, playerCol
    MOV newCol, AL
    MOV actionCode, 1
    JMP HK_DONE

HK_DOWN:
    MOV AL, playerRow
    INC AL
    MOV newRow, AL
    MOV AL, playerCol
    MOV newCol, AL
    MOV actionCode, 1
    JMP HK_DONE

HK_LEFT:
    MOV AL, playerRow
    MOV newRow, AL
    MOV AL, playerCol
    DEC AL
    MOV newCol, AL
    MOV actionCode, 1
    JMP HK_DONE

HK_RIGHT:
    MOV AL, playerRow
    MOV newRow, AL
    MOV AL, playerCol
    INC AL
    MOV newCol, AL
    MOV actionCode, 1
    JMP HK_DONE

HK_ROPE:
    MOV actionCode, 2
    JMP HK_DONE

HK_QUIT:
    MOV actionCode, 3

HK_DONE:
    POP AX
    RET
HandleKey ENDP

; ============================================================================
; PROCEDURE: ResolveTurn
; ============================================================================
ResolveTurn PROC
    CALL CheckAndCollectKey

    CALL CheckGameState
    CMP gameState, 0
    JNE RT_DONE

    CALL CheckContact
    CMP AL, 1
    JE RT_AFTER_ENEMY

    CALL MoveEnemy1

    CALL CheckContact

RT_AFTER_ENEMY:
    CALL CheckGameState

RT_DONE:
    RET
ResolveTurn ENDP

; ============================================================================
; PROCEDURE: MoveEnemy1
; ============================================================================
MoveEnemy1 PROC
    PUSH AX
    PUSH BX

    MOV AL, enemy1Row
    CMP AL, playerRow
    JGE E1_ROW_GREATER_EQUAL
    MOV BL, playerRow
    SUB BL, AL
    MOV verticalDistance, BL
    JMP E1_VERTICAL_DONE

E1_ROW_GREATER_EQUAL:
    SUB AL, playerRow
    MOV verticalDistance, AL

E1_VERTICAL_DONE:
    MOV AL, enemy1Col
    CMP AL, playerCol
    JGE E1_COL_GREATER_EQUAL
    MOV BL, playerCol
    SUB BL, AL
    MOV horizontalDistance, BL
    JMP E1_HORIZONTAL_DONE

E1_COL_GREATER_EQUAL:
    SUB AL, playerCol
    MOV horizontalDistance, AL

E1_HORIZONTAL_DONE:
    MOV AL, verticalDistance
    CMP AL, horizontalDistance
    JL E1_HORIZONTAL_FIRST

E1_VERTICAL_FIRST:
    CALL Enemy1StepVertical
    CMP AL, 1
    JE E1_MOVE_FINISHED
    CALL Enemy1StepHorizontal
    JMP E1_MOVE_FINISHED

E1_HORIZONTAL_FIRST:
    CALL Enemy1StepHorizontal
    CMP AL, 1
    JE E1_MOVE_FINISHED
    CALL Enemy1StepVertical

E1_MOVE_FINISHED:
    POP BX
    POP AX
    RET
MoveEnemy1 ENDP

; ============================================================================
; PROCEDURE: Enemy1StepVertical
; ============================================================================
Enemy1StepVertical PROC
    PUSH BX

    MOV AL, enemy1Row
    CMP AL, playerRow
    JE E1V_NO_MOVE
    JL E1V_MOVE_DOWN

    DEC AL
    JMP E1V_TEST

E1V_MOVE_DOWN:
    INC AL

E1V_TEST:
    MOV testRow, AL
    MOV AL, enemy1Col
    MOV testCol, AL

    MOV AL, testRow
    MOV BL, testCol
    CALL IsWalkable

    CMP AL, 1
    JNE E1V_NO_MOVE

E1V_COMMIT:
    MOV AL, testRow
    MOV enemy1Row, AL
    MOV AL, 1
    JMP E1V_DONE

E1V_NO_MOVE:
    MOV AL, 0

E1V_DONE:
    POP BX
    RET
Enemy1StepVertical ENDP

; ============================================================================
; PROCEDURE: Enemy1StepHorizontal
; ============================================================================
Enemy1StepHorizontal PROC
    PUSH BX

    MOV AL, enemy1Col
    CMP AL, playerCol
    JE E1H_NO_MOVE
    JL E1H_MOVE_RIGHT

    DEC AL
    JMP E1H_TEST

E1H_MOVE_RIGHT:
    INC AL

E1H_TEST:
    MOV testCol, AL
    MOV AL, enemy1Row
    MOV testRow, AL

    MOV AL, testRow
    MOV BL, testCol
    CALL IsWalkable

    CMP AL, 1
    JNE E1H_NO_MOVE

E1H_COMMIT:
    MOV AL, testCol
    MOV enemy1Col, AL
    MOV AL, 1
    JMP E1H_DONE

E1H_NO_MOVE:
    MOV AL, 0

E1H_DONE:
    POP BX
    RET
Enemy1StepHorizontal ENDP

; ============================================================================
; PROCEDURE: CheckContact
; ============================================================================
CheckContact PROC
    MOV AL, enemy1Row
    CMP AL, playerRow
    JNE CC_NO_HIT

    MOV AL, enemy1Col
    CMP AL, playerCol
    JE CC_HIT
    JMP CC_NO_HIT

CC_NO_HIT:
    MOV AL, 0
    RET

CC_HIT:
    CMP playerHP, 0
    JE CC_RESET
    DEC playerHP

CC_RESET:
    MOV enemy1Row, E1_START_ROW
    MOV enemy1Col, E1_START_COL
    MOV AL, 1
    RET
CheckContact ENDP

; ============================================================================
; PROCEDURE: CheckAndCollectKey
; ============================================================================
CheckAndCollectKey PROC
    PUSH AX
    PUSH BX
    PUSH SI

    MOV AL, playerRow
    MOV BL, playerCol
    CALL ComputeIndex

    CMP items[SI], 1
    JNE CCK_DONE

    MOV items[SI], 0
    INC keyCount

CCK_DONE:
    POP SI
    POP BX
    POP AX
    RET
CheckAndCollectKey ENDP

; ============================================================================
; PROCEDURE: CheckGameState
; ============================================================================
CheckGameState PROC
    PUSH AX
    PUSH BX
    PUSH SI

    CMP playerHP, 0
    JNE CGS_TURN_CHECK
    MOV gameState, 2
    MOV loseReason, 1
    JMP CGS_DONE

CGS_TURN_CHECK:
    MOV AL, turnCount
    CMP AL, MAX_TURNS
    JL CGS_EXIT_CHECK
    MOV gameState, 2
    MOV loseReason, 2
    JMP CGS_DONE

CGS_EXIT_CHECK:
    MOV AL, playerRow
    MOV BL, playerCol
    CALL ComputeIndex

    CMP maze[SI], EXIT_CELL
    JNE CGS_DONE

    CMP keyCount, 2
    JNE CGS_DONE

    MOV gameState, 1

CGS_DONE:
    POP SI
    POP BX
    POP AX
    RET
CheckGameState ENDP

; ============================================================================
; PROCEDURE: IsWalkable
; ============================================================================
IsWalkable PROC
    PUSH SI
    CALL ComputeIndex
    CMP maze[SI], WALL
    JE IW_WALL
    MOV AL, 1
    JMP IW_DONE

IW_WALL:
    MOV AL, 0
IW_DONE:
    POP SI
    RET
IsWalkable ENDP

; ============================================================================
; PROCEDURE: ComputeIndex (Uses basic 8086 MUL)
; ============================================================================
ComputeIndex PROC
    PUSH AX
    PUSH BX
    PUSH DX

    XOR AH, AH
    MOV DL, COLS
    MUL DL

    XOR BH, BH
    ADD AX, BX
    MOV SI, AX

    POP DX
    POP BX
    POP AX
    RET
ComputeIndex ENDP

; ============================================================================
; PROCEDURE: IsVisible
; ============================================================================
IsVisible PROC
    PUSH BX
    PUSH CX
    PUSH DX

    MOV DL, AL
    MOV DH, BL

    MOV AL, DL
    CMP AL, playerRow
    JGE IV_ROW_GE
    MOV CL, playerRow
    SUB CL, AL
    JMP IV_ROW_DONE

IV_ROW_GE:
    SUB AL, playerRow
    MOV CL, AL

IV_ROW_DONE:
    CMP CL, FOG_ROWS
    JG IV_HIDDEN

    MOV AL, DH
    CMP AL, playerCol
    JGE IV_COL_GE
    MOV CL, playerCol
    SUB CL, AL
    JMP IV_COL_DONE

IV_COL_GE:
    SUB AL, playerCol
    MOV CL, AL

IV_COL_DONE:
    CMP CL, FOG_COLS
    JG IV_HIDDEN
    MOV AL, 1
    JMP IV_DONE

IV_HIDDEN:
    MOV AL, 0
IV_DONE:
    POP DX
    POP CX
    POP BX
    RET
IsVisible ENDP

; ============================================================================
; PROCEDURE: DrawFrame
; ============================================================================
DrawFrame PROC
    LEA DX, titleMsg
    CALL PrintString
    CALL RenderMaze
    CALL DrawStatus
    LEA DX, controlsMsg
    CALL PrintString
    LEA DX, legendMsg
    CALL PrintString
    LEA DX, objectiveMsg
    CALL PrintString
    RET
DrawFrame ENDP

; ============================================================================
; PROCEDURE: RenderMaze
; ============================================================================
RenderMaze PROC
    MOV renderRow, 0

RM_ROW_LOOP:
    CMP renderRow, ROWS
    JGE RM_DONE
    MOV renderCol, 0

RM_COL_LOOP:
    CMP renderCol, COLS
    JGE RM_END_ROW
    CALL RenderCell
    INC renderCol
    JMP RM_COL_LOOP

RM_END_ROW:
    CALL NewLine
    INC renderRow
    JMP RM_ROW_LOOP

RM_DONE:
    RET
RenderMaze ENDP

; ============================================================================
; PROCEDURE: RenderCell
; ============================================================================
RenderCell PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    MOV AL, renderRow
    CMP AL, playerRow
    JNE RC_CHECK_FOG
    MOV AL, renderCol
    CMP AL, playerCol
    JNE RC_CHECK_FOG
    MOV DL, 'P'
    CALL PrintChar
    JMP RC_DONE

RC_CHECK_FOG:
    MOV AL, renderRow
    MOV BL, renderCol
    CALL IsVisible
    CMP AL, 1
    JE RC_VISIBLE
    MOV DL, '?'
    CALL PrintChar
    JMP RC_DONE

RC_VISIBLE:
    MOV AL, renderRow
    CMP AL, enemy1Row
    JNE RC_ARRAY_CELL
    MOV AL, renderCol
    CMP AL, enemy1Col
    JNE RC_ARRAY_CELL
    MOV DL, 'X'
    CALL PrintChar
    JMP RC_DONE

RC_ARRAY_CELL:
    MOV AL, renderRow
    MOV BL, renderCol
    CALL ComputeIndex

    CMP items[SI], 1
    JNE RC_MAP_VALUE
    MOV DL, 'K'
    CALL PrintChar
    JMP RC_DONE

RC_MAP_VALUE:
    CMP maze[SI], WALL
    JE RC_WALL

    CMP maze[SI], EXIT_CELL
    JE RC_EXIT

    MOV DL, '.'
    CALL PrintChar
    JMP RC_DONE

RC_WALL:
    MOV DL, '#'
    CALL PrintChar
    JMP RC_DONE

RC_EXIT:
    MOV DL, 'G'
    CALL PrintChar

RC_DONE:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
RenderCell ENDP

; ============================================================================
; PROCEDURE: DrawStatus
; ============================================================================
DrawStatus PROC
    PUSH AX
    PUSH DX

    LEA DX, hpMsg
    CALL PrintString
    MOV DL, playerHP
    ADD DL, '0'
    CALL PrintChar

    LEA DX, keyMsg
    CALL PrintString
    MOV DL, keyCount
    ADD DL, '0'
    CALL PrintChar
    LEA DX, keyTotalMsg
    CALL PrintString

    LEA DX, turnMsg
    CALL PrintString
    MOV AL, turnCount
    CALL PrintByteNumber
    LEA DX, slashMsg
    CALL PrintString

    LEA DX, historyMsg
    CALL PrintString
    MOV AL, pathDepth
    CALL PrintByteNumber

    CALL NewLine

    POP DX
    POP AX
    RET
DrawStatus ENDP

; ============================================================================
; PROCEDURE: PrintByteNumber (Uses basic 8086 DIV)
; ============================================================================
PrintByteNumber PROC
    PUSH AX
    PUSH BX
    PUSH DX

    XOR AH, AH
    MOV BL, 10
    DIV BL
    CMP AL, 0
    JE PBN_ONES

    MOV DL, AL
    ADD DL, '0'
    CALL PrintChar

PBN_ONES:
    MOV DL, AH
    ADD DL, '0'
    CALL PrintChar

    POP DX
    POP BX
    POP AX
    RET
PrintByteNumber ENDP

; ============================================================================
; PROCEDURES: PrintString, PrintChar, NewLine, ClearScreen, WaitKey
; All utilize standard MS-DOS interrupts (INT 21h) natively supported by 8086.
; ============================================================================
PrintString PROC
    PUSH AX
    MOV AH, 9
    INT 21H
    POP AX
    RET
PrintString ENDP

PrintChar PROC
    PUSH AX
    MOV AH, 2
    INT 21H
    POP AX
    RET
PrintChar ENDP

NewLine PROC
    PUSH AX
    PUSH DX
    MOV AH, 2
    MOV DL, 13
    INT 21H
    MOV DL, 10
    INT 21H
    POP DX
    POP AX
    RET
NewLine ENDP

ClearScreen PROC
    PUSH CX
    MOV CX, 27
CLEAR_LOOP:
    CALL NewLine
    LOOP CLEAR_LOOP
    POP CX
    RET
ClearScreen ENDP

WaitKey PROC
    PUSH AX
    MOV AH, 1
    INT 21H
    POP AX
    RET
WaitKey ENDP