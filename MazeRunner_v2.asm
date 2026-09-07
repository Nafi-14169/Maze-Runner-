; ============================================================================
; CSE341 MICROPROCESSORS PROJECT ; Main Menu & Level Management
; Project: MAZE RUNNER - MAIN MENU + LEVEL 1 (1 ENEMY) + LEVEL 2 (2 ENEMIES)
; Target : EMU8086 4.08, 8086, COM program
; ============================================================================
#make_COM#
ORG 100H
JMP START
ROWS          EQU 8
COLS          EQU 8
MAZE_SIZE     EQU 64
WALL          EQU 1
EXIT_CELL     EQU 2
MAX_TURNS     EQU 80
FOG_ROWS      EQU 2 ; Fog visibility range
FOG_COLS      EQU 4 ; Fog visibility range
MAX_ROW_INDEX EQU 7
MAX_COL_INDEX EQU 7
PLAYER_START_ROW EQU 1
PLAYER_START_COL EQU 1
KEY1_ROW      EQU 1 ; Key 1 location
KEY1_COL      EQU 6 ; Key 1 location
KEY2_ROW      EQU 5 ; Key 2 location
KEY2_COL      EQU 1 ; Key 2 location
E1_START_ROW  EQU 6 ; Enemy 1 starting position
E1_START_COL  EQU 5 ; Enemy 1 starting position
E2_START_ROW  EQU 3 ; Enemy 2 starting position
E2_START_COL  EQU 5 ; Enemy 2 starting position
PREDICT_DIST  EQU 2 ; Prediction distance
maze DB 1,1,1,1,1,1,1,1
     DB 1,0,0,0,1,0,0,1
     DB 1,0,1,0,1,0,0,1
     DB 1,0,1,0,0,0,0,1
     DB 1,0,1,1,1,0,0,1
     DB 1,0,0,0,0,0,0,1
     DB 1,0,0,0,0,0,2,1
     DB 1,1,1,1,1,1,1,1
items DB MAZE_SIZE DUP(0)
playerRow   DB PLAYER_START_ROW ; Player position
playerCol   DB PLAYER_START_COL ; Player position
playerHP    DB 3 ; Player HP
keyCount    DB 0 ; Key collection state
turnCount   DB 0 ; Turn counter
pathDepth   DB 0 ; Escape Rope stack depth
actionCode  DB 0 ; Input action result
currentLevel  DB 1 ; Current level state
enemy2Active  DB 0 ; Level 2 enemy switch
cheatMode      DB 0 ; Cheat mode state
enemiesEnabled DB 1 ; Enemy enable/disable
fogDisabled    DB 0 ; Fog enable/disable
enemy1Row   DB E1_START_ROW ; Enemy 1 row
enemy1Col   DB E1_START_COL ; Enemy 1 column
enemy2Row   DB E2_START_ROW ; Enemy 2 row
enemy2Col   DB E2_START_COL ; Enemy 2 column
predictedRow DB 0 ; Predicted target row
predictedCol DB 0 ; Predicted target column
gameState   DB 0 ; Win/lose/quit state
loseReason  DB 0 ; Loss reason
inputKey    DB 0 ; Keyboard input
newRow      DB 0 ; Candidate row
newCol      DB 0 ; Candidate column
intendedDir DB 0 ; Requested direction
lastMoveDir DB 0 ; Last movement direction
renderRow   DB 0 ; Render row
renderCol   DB 0 ; Render column
testRow     DB 0
testCol     DB 0
verticalDistance    DB 0 ; Enemy 1 vertical distance
horizontalDistance  DB 0 ; Enemy 1 horizontal distance
verticalDistance2   DB 0 ; Enemy 2 vertical distance
horizontalDistance2 DB 0 ; Enemy 2 horizontal distance
rowBuffer   DB COLS DUP('.'), 13, 10, '$' ; Screen row buffer
menuTitleMsg   DB 13,10,'================================',13,10 ; Menu messages
               DB '        MAZE RUNNER - MENU',13,10
               DB '================================',13,10,'$'
menuOptionsMsg DB 13,10,'1. Level 1  (1 enemy - chaser)' ; Level selection options
               DB 13,10,'2. Level 2  (2 enemies - chaser + predictive ghost)'
               DB 13,10,'3. Cheat Mode (guided demo win)' ; Cheat mode option
               DB 13,10,'Q. Exit',13,10,'$'
menuPromptMsg  DB 13,10,'Select an option: $'
cheatBannerMsg       DB 13,10,'*** CHEAT MODE: enemies off, full map visible ***',13,10,'$' ; Cheat/fog banner
cheatSolutionTitleMsg DB 13,10,'=== CHEAT MODE - FULL SOLUTION (this fixed map) ===',13,10,'$'
cheatKey1Msg         DB 13,10,'Key 1  : DDSSDDDWW$'
cheatKey2Msg         DB 13,10,'Key 2  : SSSSAAAAA$'
cheatGateMsg         DB 13,10,'GATE   : SDDDDD$'
cheatContinueMsg     DB 13,10,13,10,'Press any key to start playing this sequence...',13,10,'$'
titleMsg     DB 13,10,'=== MAZE RUNNER ===',13,10,'$' ; Display title
controlsMsg  DB 'Controls: W=UP S=DOWN A=LEFT D=RIGHT R=ROPE M=MENU Q=QUIT',13,10,'$' ; Player controls
legendMsg    DB 'Legend: P Player  X Enemy  Y Ghost  K Key  G Exit  # Wall  ? Fog',13,10,'$' ; Display legend
objectiveMsg DB 'Goal: collect 2 Keys and reach G before HP becomes 0.',13,10,'$' ; Game objective
levelMsg     DB 'Level: $' ; Status labels
hpMsg        DB '   HP: $' ; Status labels
keyMsg       DB '   Keys: $' ; Status labels
keyTotalMsg  DB '/2$'
turnMsg      DB '   Turns: $' ; Status labels
slashMsg     DB '/80$'
historyMsg   DB '   Stack: $' ; Status labels
promptMsg    DB 13,10,'Your move: $' ; Player input prompt
wallMsg      DB 13,10,'Wall! Choose another direction.',13,10,'$'
ropeEmptyMsg DB 13,10,'Escape Rope stack is empty.',13,10,'$'
winMsg       DB 13,10,'YOU WIN! 2 Keys collected and exit reached.',13,10,'$' ; Win message
loseHPMsg    DB 13,10,'GAME OVER! Your HP reached 0.',13,10,'$' ; HP loss message
loseTurnMsg  DB 13,10,'GAME OVER! 80-turn limit reached.',13,10,'$' ; Turn limit message
quitMsg      DB 13,10,'Game ended by user.',13,10,'$'
START: ; Program entry
    JMP MAIN_MENU
MAIN_MENU: ; Main menu feature
    CALL ClearScreen
    LEA DX, menuTitleMsg
    CALL PrintString
    LEA DX, menuOptionsMsg
    CALL PrintString
    LEA DX, menuPromptMsg
    CALL PrintString
    MOV AH, 1
    INT 21H
    MOV inputKey, AL
    CMP inputKey, '1'
    JE MENU_LEVEL1
    CMP inputKey, '2'
    JE MENU_LEVEL2
    CMP inputKey, '3'
    JE MENU_CHEAT
    CMP inputKey, 'q'
    JE MENU_EXIT
    CMP inputKey, 'Q'
    JE MENU_EXIT
    JMP MAIN_MENU
MENU_LEVEL1: ; Start Level 1
    MOV currentLevel, 1
    MOV enemy2Active, 0
    CALL InitLevel
    JMP GAME_LOOP
MENU_LEVEL2: ; Start Level 2
    MOV currentLevel, 2
    MOV enemy2Active, 1
    CALL InitLevel
    JMP GAME_LOOP
MENU_CHEAT: ; Start Cheat Mode
    MOV currentLevel, 1
    MOV enemy2Active, 0
    CALL InitLevel
    MOV enemiesEnabled, 0
    MOV fogDisabled, 1
    MOV cheatMode, 1
    CALL ShowCheatSolution
    JMP GAME_LOOP
MENU_EXIT: ; Exit from menu
    CALL ClearScreen
    LEA DX, quitMsg
    CALL PrintString
    JMP PROGRAM_EXIT
GAME_LOOP: ; Main gameplay input loop
    CALL ClearScreen
    CALL DrawFrame
    CMP gameState, 0
    JNE GAME_FINISHED
    LEA DX, promptMsg ; Read player command
    CALL PrintString
    MOV AH, 1
    INT 21H
    MOV inputKey, AL
    CALL HandleKey ; Decode player command
    CMP actionCode, 1
    JE MAIN_DO_MOVE
    CMP actionCode, 2
    JE MAIN_DO_ROPE
    CMP actionCode, 3
    JE MAIN_DO_QUIT
    CMP actionCode, 4
    JE MAIN_DO_MENU
    JMP GAME_LOOP
MAIN_DO_MOVE: ; Validate and perform movement
    MOV AL, newRow
    MOV BL, newCol
    CALL IsWalkable
    CMP AL, 1
    JE MOVE_IS_VALID
    LEA DX, wallMsg
    CALL PrintString
    CALL WaitKey
    JMP GAME_LOOP
MOVE_IS_VALID: ; Valid movement: save old position
    MOV AH, playerRow
    MOV AL, playerCol
    PUSH AX ; Push previous position for Rope
    INC pathDepth ; Increase Rope history depth
    MOV AL, newRow
    MOV playerRow, AL
    MOV AL, newCol
    MOV playerCol, AL
    MOV AL, intendedDir
    MOV lastMoveDir, AL
    INC turnCount ; A valid move consumes a turn
    CALL ResolveTurn
    JMP GAME_LOOP
MAIN_DO_ROPE: ; Escape Rope action
    CMP pathDepth, 0
    JNE ROPE_AVAILABLE
    LEA DX, ropeEmptyMsg
    CALL PrintString
    CALL WaitKey
    JMP GAME_LOOP
ROPE_AVAILABLE: ; Restore previous player position
    POP AX ; Pop previous position
    MOV playerCol, AL
    MOV playerRow, AH
    DEC pathDepth ; Decrease Rope history depth
    MOV lastMoveDir, 0
    INC turnCount ; Rope use consumes a turn
    CALL ResolveTurn
    JMP GAME_LOOP
MAIN_DO_QUIT:
    MOV AH, 4CH ; Q exits the game immediately
    INT 21H ; DOS terminate process
MAIN_DO_MENU:
    JMP RETURN_TO_MENU
GAME_FINISHED: ; Route finished game to result
    CMP gameState, 1
    JE SHOW_WIN
    CMP gameState, 2
    JE SHOW_LOSE
    JMP SHOW_QUIT
SHOW_WIN: ; Win screen
    MOV BH, 2Fh
    CALL ColorScreen
    LEA DX, winMsg
    CALL PrintString
    CALL WaitKey
    JMP RETURN_TO_MENU
SHOW_LOSE: ; Lose screen
    MOV BH, 4Fh
    CALL ColorScreen
    CMP loseReason, 1 ; Distinguish loss reason
    JE SHOW_HP_LOSS
    LEA DX, loseTurnMsg
    CALL PrintString
    CALL WaitKey
    JMP RETURN_TO_MENU
SHOW_HP_LOSS:
    LEA DX, loseHPMsg
    CALL PrintString
    CALL WaitKey
    JMP RETURN_TO_MENU
SHOW_QUIT:
    CALL ClearScreen
    LEA DX, quitMsg
    CALL PrintString
PROGRAM_EXIT: ; DOS program termination
    MOV AX, 4C00H
    INT 21H
RETURN_TO_MENU: ; Return safely to menu
    MOV AL, pathDepth
    XOR AH, AH
    SHL AX, 1
    ADD SP, AX
    MOV pathDepth, 0
    JMP MAIN_MENU
ColorScreen PROC ; Colored result-screen rendering
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AH, 06h
    MOV AL, 00h
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h
    MOV AH, 02h
    MOV BH, 0
    MOV DX, 0000h
    INT 10h
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ColorScreen ENDP
ClearScreen PROC ; Normal screen clearing
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AH, 06h
    MOV AL, 00h
    MOV BH, 07h
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h
    MOV AH, 02h
    MOV BH, 0
    MOV DX, 0000h
    INT 10h
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ClearScreen ENDP
InitLevel PROC ; Reset selected level
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    MOV playerRow, PLAYER_START_ROW
    MOV playerCol, PLAYER_START_COL
    MOV playerHP, 3
    MOV keyCount, 0
    MOV turnCount, 0
    MOV pathDepth, 0
    MOV gameState, 0
    MOV loseReason, 0
    MOV lastMoveDir, 0
    MOV intendedDir, 0
    MOV cheatMode, 0
    MOV enemiesEnabled, 1
    MOV fogDisabled, 0
    MOV enemy1Row, E1_START_ROW
    MOV enemy1Col, E1_START_COL
    MOV enemy2Row, E2_START_ROW
    MOV enemy2Col, E2_START_COL
    MOV CX, MAZE_SIZE
    MOV SI, 0
IL_CLEAR_ITEMS:
    MOV items[SI], 0
    INC SI
    LOOP IL_CLEAR_ITEMS
    MOV AL, KEY1_ROW
    MOV BL, KEY1_COL
    CALL ComputeIndex
    MOV items[SI], 1
    MOV AL, KEY2_ROW
    MOV BL, KEY2_COL
    CALL ComputeIndex
    MOV items[SI], 1
    POP SI
    POP CX
    POP BX
    POP AX
    RET
InitLevel ENDP
ShowCheatSolution PROC
    CALL ClearScreen
    LEA DX, cheatSolutionTitleMsg
    CALL PrintString
    CALL RenderMaze
    LEA DX, cheatKey1Msg
    CALL PrintString
    LEA DX, cheatKey2Msg
    CALL PrintString
    LEA DX, cheatGateMsg
    CALL PrintString
    LEA DX, cheatContinueMsg
    CALL PrintString
    CALL WaitKey
    RET
ShowCheatSolution ENDP
HandleKey PROC ; Keyboard command handler
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
    CMP AL, 'm'
    JE HK_MENU
    CMP AL, 'M'
    JE HK_MENU
    CMP AL, 'q'
    JE HK_QUIT
    CMP AL, 'Q'
    JE HK_QUIT
    JMP HK_DONE
HK_UP: ; W/UP movement
    MOV AL, playerRow
    DEC AL
    MOV newRow, AL
    MOV AL, playerCol
    MOV newCol, AL
    MOV intendedDir, 1
    MOV actionCode, 1
    JMP HK_DONE
HK_DOWN: ; S/DOWN movement
    MOV AL, playerRow
    INC AL
    MOV newRow, AL
    MOV AL, playerCol
    MOV newCol, AL
    MOV intendedDir, 2
    MOV actionCode, 1
    JMP HK_DONE
HK_LEFT: ; A/LEFT movement
    MOV AL, playerRow
    MOV newRow, AL
    MOV AL, playerCol
    DEC AL
    MOV newCol, AL
    MOV intendedDir, 3
    MOV actionCode, 1
    JMP HK_DONE
HK_RIGHT: ; D/RIGHT movement
    MOV AL, playerRow
    MOV newRow, AL
    MOV AL, playerCol
    INC AL
    MOV newCol, AL
    MOV intendedDir, 4
    MOV actionCode, 1
    JMP HK_DONE
HK_ROPE: ; R/ROPE command
    MOV actionCode, 2
    JMP HK_DONE
HK_MENU: ; M/MENU command
    MOV actionCode, 4
    JMP HK_DONE
HK_QUIT: ; Q/QUIT command
    MOV actionCode, 3
HK_DONE:
    POP AX
    RET
HandleKey ENDP
ResolveTurn PROC ; Resolve each completed turn
    CALL CheckAndCollectKey ; Collect key on current cell
    CALL CheckGameState ; Check win/lose state
    CMP gameState, 0
    JNE RT_DONE
    CMP enemiesEnabled, 0
    JE RT_SKIP_E1
    CALL CheckContact1
    CMP AL, 1
    JE RT_SKIP_E1
    CALL MoveEnemy1
    CALL CheckContact1
RT_SKIP_E1:
    CMP enemy2Active, 0 ; Enable Enemy 2 in Level 2
    JE RT_AFTER_ENEMIES
    CALL ComputePrediction ; Predict player's next position
    CALL CheckContact2
    CMP AL, 1
    JE RT_SKIP_E2
    CALL MoveEnemy2
    CALL CheckContact2
RT_SKIP_E2:
RT_AFTER_ENEMIES:
    CALL CheckGameState ; Final state check after enemies
RT_DONE:
    RET
ResolveTurn ENDP
ComputePrediction PROC ; Predictive ghost calculation
    PUSH AX
    MOV AL, playerRow ; Start prediction from player position
    MOV predictedRow, AL
    MOV AL, playerCol
    MOV predictedCol, AL
    MOV AL, lastMoveDir ; Use last move direction
    CMP AL, 1
    JE CP_UP
    CMP AL, 2
    JE CP_DOWN
    CMP AL, 3
    JE CP_LEFT
    CMP AL, 4
    JE CP_RIGHT
    JMP CP_DONE
CP_UP: ; Predict upward
    MOV AL, predictedRow
    CMP AL, PREDICT_DIST
    JL CP_UP_CLAMP
    SUB AL, PREDICT_DIST
    MOV predictedRow, AL
    JMP CP_DONE
CP_UP_CLAMP:
    MOV predictedRow, 0
    JMP CP_DONE
CP_DOWN: ; Predict downward
    MOV AL, predictedRow
    ADD AL, PREDICT_DIST
    CMP AL, ROWS
    JL CP_DOWN_OK
    MOV AL, MAX_ROW_INDEX
CP_DOWN_OK:
    MOV predictedRow, AL
    JMP CP_DONE
CP_LEFT: ; Predict left
    MOV AL, predictedCol
    CMP AL, PREDICT_DIST
    JL CP_LEFT_CLAMP
    SUB AL, PREDICT_DIST
    MOV predictedCol, AL
    JMP CP_DONE
CP_LEFT_CLAMP:
    MOV predictedCol, 0
    JMP CP_DONE
CP_RIGHT: ; Predict right
    MOV AL, predictedCol
    ADD AL, PREDICT_DIST
    CMP AL, COLS
    JL CP_RIGHT_OK
    MOV AL, MAX_COL_INDEX
CP_RIGHT_OK:
    MOV predictedCol, AL
CP_DONE:
    POP AX
    RET
ComputePrediction ENDP
MoveEnemy1 PROC ; Enemy 1 chaser AI
    PUSH AX
    PUSH BX
    MOV AL, enemy1Row ; Measure Enemy 1 row distance
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
    MOV AL, enemy1Col ; Measure Enemy 1 column distance
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
    MOV AL, verticalDistance ; Choose closest axis
    CMP AL, horizontalDistance
    JL E1_HORIZONTAL_FIRST
E1_VERTICAL_FIRST:
    CALL Enemy1StepVertical ; Try vertical chase
    CMP AL, 1
    JE E1_MOVE_FINISHED
    CALL Enemy1StepHorizontal ; Try horizontal fallback
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
Enemy1StepVertical PROC ; Enemy 1 vertical step
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
    MOV testRow, AL ; Test vertical destination
    MOV AL, enemy1Col
    MOV testCol, AL
    MOV AL, testRow
    MOV BL, testCol
    CALL IsWalkable ; Reject wall / accept walkable cell
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
Enemy1StepHorizontal PROC ; Enemy 1 horizontal step
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
    MOV testCol, AL ; Test horizontal destination
    MOV AL, enemy1Row
    MOV testRow, AL
    MOV AL, testRow
    MOV BL, testCol
    CALL IsWalkable ; Reject wall / accept walkable cell
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
MoveEnemy2 PROC ; Enemy 2 predictive movement
    PUSH AX
    PUSH BX
    MOV AL, enemy2Row ; Measure distance to predicted target
    CMP AL, predictedRow
    JGE E2_ROW_GE
    MOV BL, predictedRow
    SUB BL, AL
    MOV verticalDistance2, BL
    JMP E2_VERT_DONE
E2_ROW_GE:
    SUB AL, predictedRow
    MOV verticalDistance2, AL
E2_VERT_DONE:
    MOV AL, enemy2Col
    CMP AL, predictedCol
    JGE E2_COL_GE
    MOV BL, predictedCol
    SUB BL, AL
    MOV horizontalDistance2, BL
    JMP E2_HORZ_DONE
E2_COL_GE:
    SUB AL, predictedCol
    MOV horizontalDistance2, AL
E2_HORZ_DONE:
    MOV AL, verticalDistance2 ; Choose closest axis to prediction
    CMP AL, horizontalDistance2
    JL E2_HORZ_FIRST
E2_VERT_FIRST:
    CALL Enemy2StepVertical
    CMP AL, 1
    JE E2_MOVE_DONE
    CALL Enemy2StepHorizontal
    JMP E2_MOVE_DONE
E2_HORZ_FIRST:
    CALL Enemy2StepHorizontal
    CMP AL, 1
    JE E2_MOVE_DONE
    CALL Enemy2StepVertical
E2_MOVE_DONE:
    POP BX
    POP AX
    RET
MoveEnemy2 ENDP
Enemy2StepVertical PROC ; Enemy 2 vertical step
    PUSH BX
    MOV AL, enemy2Row
    CMP AL, predictedRow
    JE E2V_NO_MOVE
    JL E2V_MOVE_DOWN
    DEC AL
    JMP E2V_TEST
E2V_MOVE_DOWN:
    INC AL
E2V_TEST:
    MOV testRow, AL
    MOV AL, enemy2Col
    MOV testCol, AL
    MOV AL, testRow
    MOV BL, testCol
    CALL IsWalkable
    CMP AL, 1
    JNE E2V_NO_MOVE
    MOV AL, testRow
    MOV enemy2Row, AL
    MOV AL, 1
    JMP E2V_DONE
E2V_NO_MOVE:
    MOV AL, 0
E2V_DONE:
    POP BX
    RET
Enemy2StepVertical ENDP
Enemy2StepHorizontal PROC ; Enemy 2 horizontal step
    PUSH BX
    MOV AL, enemy2Col
    CMP AL, predictedCol
    JE E2H_NO_MOVE
    JL E2H_MOVE_RIGHT
    DEC AL
    JMP E2H_TEST
E2H_MOVE_RIGHT:
    INC AL
E2H_TEST:
    MOV testCol, AL
    MOV AL, enemy2Row
    MOV testRow, AL
    MOV AL, testRow
    MOV BL, testCol
    CALL IsWalkable
    CMP AL, 1
    JNE E2H_NO_MOVE
    MOV AL, testCol
    MOV enemy2Col, AL
    MOV AL, 1
    JMP E2H_DONE
E2H_NO_MOVE:
    MOV AL, 0
E2H_DONE:
    POP BX
    RET
Enemy2StepHorizontal ENDP
CheckContact1 PROC ; Enemy 1 collision check
    MOV AL, enemy1Row
    CMP AL, playerRow
    JNE CC1_NO_HIT
    MOV AL, enemy1Col
    CMP AL, playerCol
    JE CC1_HIT
    JMP CC1_NO_HIT
CC1_NO_HIT:
    MOV AL, 0
    RET
CC1_HIT:
    CMP playerHP, 0 ; Collision reduces HP
    JE CC1_RESET
    DEC playerHP
CC1_RESET:
    MOV enemy1Row, E1_START_ROW ; Reset Enemy 1 after hit
    MOV enemy1Col, E1_START_COL
    MOV AL, 1
    RET
CheckContact1 ENDP
CheckContact2 PROC ; Enemy 2 collision check
    CMP enemy2Active, 0
    JE CC2_NO_HIT
    MOV AL, enemy2Row
    CMP AL, playerRow
    JNE CC2_NO_HIT
    MOV AL, enemy2Col
    CMP AL, playerCol
    JE CC2_HIT
    JMP CC2_NO_HIT
CC2_NO_HIT:
    MOV AL, 0
    RET
CC2_HIT: ; Collision reduces HP and resets ghost
    CMP playerHP, 0
    JE CC2_RESET
    DEC playerHP
CC2_RESET:
    MOV enemy2Row, E2_START_ROW
    MOV enemy2Col, E2_START_COL
    MOV AL, 1
    RET
CheckContact2 ENDP
CheckAndCollectKey PROC ; Key collection logic
    PUSH AX
    PUSH BX
    PUSH SI
    MOV AL, playerRow
    MOV BL, playerCol
    CALL ComputeIndex
    TEST items[SI], 1 ; Check key bit while preserving explored bit
    JE CCK_DONE
    AND items[SI], 80h ; Remove key but keep cell permanently explored
    INC keyCount ; Increment collected keys
CCK_DONE:
    POP SI
    POP BX
    POP AX
    RET
CheckAndCollectKey ENDP
CheckGameState PROC ; Win/lose condition logic
    PUSH AX
    PUSH BX
    PUSH SI
    CMP playerHP, 0 ; HP defeat condition
    JNE CGS_TURN_CHECK
    MOV gameState, 2
    MOV loseReason, 1
    JMP CGS_DONE
CGS_TURN_CHECK:
    MOV AL, turnCount ; Turn-limit defeat condition
    CMP AL, MAX_TURNS
    JL CGS_EXIT_CHECK
    MOV gameState, 2
    MOV loseReason, 2
    JMP CGS_DONE
CGS_EXIT_CHECK:
    MOV AL, playerRow ; Exit condition
    MOV BL, playerCol
    CALL ComputeIndex
    CMP maze[SI], EXIT_CELL
    JNE CGS_DONE
    CMP keyCount, 2 ; Require both keys
    JNE CGS_DONE
    MOV gameState, 1 ; Set WIN state
CGS_DONE:
    POP SI
    POP BX
    POP AX
    RET
CheckGameState ENDP
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
IsVisible PROC ; Fog check with permanent exploration
    CMP fogDisabled, 0 ; Cheat mode disables fog
    JE IV_NORMAL
    MOV AL, 1
    JMP IV_DONE
IV_NORMAL:
    CALL ComputeIndex ; Get target cell index using AL=row and BL=column
    TEST items[SI], 80h ; Previously explored cells stay visible
    JNZ IV_VISIBLE
    CMP AL, playerRow ; Compare target row with player
    JGE IV_ROW_GE
    MOV CL, playerRow
    SUB CL, AL
    JMP IV_ROW_DONE
IV_ROW_GE:
    SUB AL, playerRow
    MOV CL, AL
IV_ROW_DONE:
    CMP CL, FOG_ROWS ; Check current row visibility range
    JG IV_HIDDEN
    MOV AL, BL
    CMP AL, playerCol ; Compare target column with player
    JGE IV_COL_GE
    MOV CL, playerCol
    SUB CL, AL
    JMP IV_COL_DONE
IV_COL_GE:
    SUB AL, playerCol
    MOV CL, AL
IV_COL_DONE:
    CMP CL, FOG_COLS ; Check current column visibility range
    JG IV_HIDDEN
IV_VISIBLE:
    OR items[SI], 80h ; Permanently reveal this explored cell
    MOV AL, 1
    JMP IV_DONE
IV_HIDDEN:
    MOV AL, 0
IV_DONE:
    RET
IsVisible ENDP
DrawFrame PROC ; Build complete game frame
    CMP cheatMode, 0
    JE DF_TITLE
    LEA DX, cheatBannerMsg
    CALL PrintString
DF_TITLE:
    LEA DX, titleMsg ; Draw title
    CALL PrintString
    CALL RenderMaze ; Draw maze
    CALL DrawStatus ; Draw status
    LEA DX, controlsMsg ; Draw controls
    CALL PrintString
    LEA DX, legendMsg ; Draw legend
    CALL PrintString
    LEA DX, objectiveMsg ; Draw objective
    CALL PrintString
    RET
DrawFrame ENDP
RenderMaze PROC ; Maze rendering loop
    MOV renderRow, 0
RM_ROW_LOOP:
    CMP renderRow, ROWS
    JGE RM_DONE
    MOV renderCol, 0
RM_COL_LOOP:
    CMP renderCol, COLS
    JGE RM_END_ROW
    CALL RenderCell ; Render one maze cell
    INC renderCol
    JMP RM_COL_LOOP

RM_END_ROW:
    LEA DX, rowBuffer
    CALL PrintString
    INC renderRow
    JMP RM_ROW_LOOP
RM_DONE:
    RET
RenderMaze ENDP
RenderCell PROC ; Cell rendering logic
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
    MOV DL, 'P' ; Render player
    JMP RC_STORE
RC_CHECK_FOG:
    MOV AL, renderRow
    MOV BL, renderCol
    CALL IsVisible
    CMP AL, 1
    JE RC_VISIBLE
    MOV DL, '?' ; Render fog
    JMP RC_STORE
RC_VISIBLE:
    CMP enemiesEnabled, 0
    JE RC_CHECK_E2
    MOV AL, renderRow
    CMP AL, enemy1Row
    JNE RC_CHECK_E2
    MOV AL, renderCol
    CMP AL, enemy1Col
    JNE RC_CHECK_E2
    MOV DL, 'X' ; Render Enemy 1
    JMP RC_STORE
RC_CHECK_E2:
    CMP enemy2Active, 0
    JE RC_ARRAY_CELL
    MOV AL, renderRow
    CMP AL, enemy2Row
    JNE RC_ARRAY_CELL
    MOV AL, renderCol
    CMP AL, enemy2Col
    JNE RC_ARRAY_CELL
    MOV DL, 'Y' ; Render Enemy 2
    JMP RC_STORE
RC_ARRAY_CELL:
    MOV AL, renderRow
    MOV BL, renderCol
    CALL ComputeIndex
    TEST items[SI], 1 ; Check key bit without losing explored flag
    JE RC_MAP_VALUE
    MOV DL, 'K' ; Render key
    JMP RC_STORE

RC_MAP_VALUE:
    CMP maze[SI], WALL
    JE RC_WALL

    CMP maze[SI], EXIT_CELL
    JE RC_EXIT
    MOV DL, '.'
    JMP RC_STORE
RC_WALL:
    MOV DL, '#' ; Render wall
    JMP RC_STORE
RC_EXIT:
    MOV DL, 'G' ; Render exit
RC_STORE:
    MOV BL, renderCol
    XOR BH, BH
    MOV rowBuffer[BX], DL ; Store rendered character
RC_DONE:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
RenderCell ENDP
DrawStatus PROC ; Draw player/game status
    PUSH AX
    PUSH DX
    LEA DX, levelMsg
    CALL PrintString
    MOV AL, currentLevel ; Display level
    CALL PrintByteNumber
    LEA DX, hpMsg ; Display HP
    CALL PrintString
    MOV DL, playerHP
    ADD DL, '0'
    CALL PrintChar
    LEA DX, keyMsg ; Display keys
    CALL PrintString
    MOV DL, keyCount
    ADD DL, '0'
    CALL PrintChar
    LEA DX, keyTotalMsg
    CALL PrintString
    LEA DX, turnMsg ; Display turns
    CALL PrintString
    MOV AL, turnCount
    CALL PrintByteNumber
    LEA DX, slashMsg
    CALL PrintString
    LEA DX, historyMsg ; Display Rope stack depth
    CALL PrintString
    MOV AL, pathDepth
    CALL PrintByteNumber
    CALL NewLine
    POP DX
    POP AX
    RET
DrawStatus ENDP
PrintByteNumber PROC ; Number formatting/output helper
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
PrintString PROC ; DOS string output helper
    PUSH AX
    MOV AH, 9
    INT 21H
    POP AX
    RET
PrintString ENDP
PrintChar PROC ; DOS character output helper
    PUSH AX
    MOV AH, 2
    INT 21H
    POP AX
    RET
PrintChar ENDP
NewLine PROC ; New-line helper
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
WaitKey PROC ; Pause for key input
    PUSH AX
    MOV AH, 1
    INT 21H
    POP AX
    RET
WaitKey ENDP
