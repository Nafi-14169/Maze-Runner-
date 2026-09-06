# 🧩 Maze Runner --- 8086 Assembly

A console-based **Maze Runner game written in 8086 Assembly Language**
for **EMU8086 4.08**.

The player must navigate through an 8×8 maze, collect **2 keys**, avoid
enemies, and reach the exit before losing all HP or exceeding the turn
limit.

------------------------------------------------------------------------

## 🎮 Game Overview

**Objective:**

> Collect both keys (`K`) and reach the exit (`G`) before your HP
> reaches 0 or the 80-turn limit is reached.

The game features:

-   🧍 Player movement
-   👾 Enemy 1 --- Chaser AI
-   👻 Enemy 2 --- Predictive Ghost AI in Level 2
-   🔑 Two fixed keys
-   🚪 Exit/goal
-   ❤️ 3 HP
-   🌫️ Fog of war with persistent exploration
-   🪢 Escape Rope for backtracking
-   ⏳ 80-turn limit
-   🟢 Green victory screen
-   🔴 Red game-over screen
-   ❌ Immediate quit option
-   🎮 Main menu with Level 1, Level 2 and Cheat Mode

------------------------------------------------------------------------

## 🛠️ Requirements

-   **EMU8086 4.08**
-   **8086 processor/emulator**
-   COM program support
-   DOS-compatible environment

The source file is configured as a COM program using:

``` asm
#make_COM#
ORG 100H
```

------------------------------------------------------------------------

## ▶️ How to Run

1.  Open **EMU8086**.
2.  Open the Maze Runner `.asm` file.
3.  Compile/assemble the program.
4.  Run the generated COM program.
5.  Select a mode from the main menu.
6.  Use the keyboard to control the player.

------------------------------------------------------------------------

## 🎯 Main Menu

The game starts with a main menu:

``` text
1. Level 1  (1 enemy - chaser)
2. Level 2  (2 enemies - chaser + predictive ghost)
3. Cheat Mode (guided demo win)
Q. Exit
```

### Level 1

Level 1 contains only **Enemy 1 (`X`)**, the normal chaser.

### Level 2

Level 2 contains both:

-   **Enemy 1 (`X`) --- Chaser**
-   **Enemy 2 (`Y`) --- Predictive Ghost**

### Cheat Mode

Cheat Mode:

-   disables enemy movement,
-   disables fog,
-   displays the complete map,
-   displays the fixed solution sequence.

It is intended mainly for demonstration and testing.

------------------------------------------------------------------------

## 🎯 Controls

  Key         Action
  ----------- -----------------------
  `W` / `w`   Move Up
  `S` / `s`   Move Down
  `A` / `a`   Move Left
  `D` / `d`   Move Right
  `R` / `r`   Use Escape Rope
  `M` / `m`   Return to Main Menu
  `Q` / `q`   Quit Game Immediately

------------------------------------------------------------------------

## 🗺️ Maze Symbols

  Symbol   Meaning
  -------- ------------------------------
  `P`      Player
  `X`      Enemy 1 --- Chaser
  `Y`      Enemy 2 --- Predictive Ghost
  `K`      Key
  `G`      Exit
  `#`      Wall
  `.`      Walkable path
  `?`      Hidden/Unexplored area

The program uses an **8×8 maze** and stores the maze as a linear array
of 64 cells.

The index is calculated using:

``` text
index = row × 8 + column
```

The maze itself is defined using `DB` values where:

``` text
0 = Walkable cell
1 = Wall
2 = Exit
```

------------------------------------------------------------------------

# 👾 Enemy Mechanism

The enemy system is one of the main gameplay mechanisms of Maze Runner
V2.

The game has **two different enemy AI systems**:

1.  **Enemy 1 --- Chaser**
2.  **Enemy 2 --- Predictive Ghost**

Enemy 2 is enabled only in **Level 2**.

Both enemies move after the player completes a valid turn and respect
the walls of the maze.

------------------------------------------------------------------------

## 👾 Enemy 1 --- Chaser AI

Enemy 1 is represented by:

``` text
X
```

Its starting position is:

``` text
Row 6, Column 5
```

The main procedure responsible for Enemy 1 movement is:

``` asm
MoveEnemy1
```

It uses two supporting procedures:

``` asm
Enemy1StepVertical
Enemy1StepHorizontal
```

### How Enemy 1 Decides Where to Move

Enemy 1 calculates its distance from the player in two directions:

``` text
Vertical Distance
Horizontal Distance
```

The vertical distance is calculated from:

``` text
|Enemy Row - Player Row|
```

The horizontal distance is calculated from:

``` text
|Enemy Column - Player Column|
```

The enemy then compares these two values.

### Movement Priority

The enemy prioritizes the axis with the **greater distance**.

For example:

``` text
Vertical distance   = 4
Horizontal distance = 2
```

Enemy 1 attempts to move **vertically** first.

If:

``` text
Vertical distance   = 2
Horizontal distance = 5
```

Enemy 1 attempts to move **horizontally** first.

This allows the enemy to continuously reduce its distance from the
player.

### Wall Handling

The enemy does not blindly move toward the player.

Before committing a movement, it checks the destination using:

``` asm
IsWalkable
```

If the preferred direction is blocked by a wall, Enemy 1 attempts the
other axis.

The basic decision flow is:

``` text
Calculate vertical distance
          ↓
Calculate horizontal distance
          ↓
Compare distances
          ↓
Choose larger-distance axis
          ↓
Try movement
          ↓
Is destination walkable?
       /       \
     Yes        No
      ↓          ↓
   Move       Try other axis
```

### Example

Suppose the player is located above and to the right of Enemy 1.

``` text
Player
   ↑
   |
   X Enemy
```

If the vertical distance is larger, Enemy 1 first attempts to move
upward.

If that cell contains a wall, it tries a horizontal movement instead.

This makes the enemy **goal-directed while still respecting the maze
structure**.

------------------------------------------------------------------------

## 👻 Enemy 2 --- Predictive Ghost AI

Enemy 2 is represented by:

``` text
Y
```

It appears only in **Level 2**.

Its starting position is:

``` text
Row 3, Column 5
```

Enemy 2 does not simply chase the player's current position.

Instead, it attempts to move toward a **predicted future position** of
the player.

The main procedures are:

``` asm
ComputePrediction
MoveEnemy2
Enemy2StepVertical
Enemy2StepHorizontal
```

------------------------------------------------------------------------

## 🔮 Prediction Mechanism

The predictive ghost uses the player's:

``` asm
lastMoveDir
```

This variable stores the direction of the player's most recent valid
movement.

The direction values are:

``` text
1 = Up
2 = Down
3 = Left
4 = Right
```

The prediction distance is:

``` asm
PREDICT_DIST EQU 2
```

Therefore, the ghost predicts a position **2 cells in the direction of
the player's last movement**.

### Example --- Player Moving Right

Suppose the player is at:

``` text
Row 3, Column 2
```

and the player's last movement was:

``` text
Right
```

The predicted position becomes approximately:

``` text
Row 3, Column 4
```

because:

``` text
Current column + 2
```

The ghost then attempts to move toward this predicted position.

### Example --- Player Moving Up

If the player is at:

``` text
Row 5, Column 4
```

and the last movement was:

``` text
Up
```

the predicted position becomes:

``` text
Row 3, Column 4
```

because:

``` text
Current row - 2
```

------------------------------------------------------------------------

## 🧠 Why the Predictive Ghost Is Different

Enemy 1 asks:

> "Where is the player now?"

Enemy 2 asks:

> "Where is the player likely to be based on their last movement?"

This makes the two enemies behave differently.

  Enemy   Strategy
  ------- ----------------------------------------
  `X`     Chases current player position
  `Y`     Moves toward predicted player position

The predictive mechanism makes Level 2 more challenging because
repeatedly moving in one direction can cause the ghost to anticipate the
player's movement.

------------------------------------------------------------------------

## 🧭 Enemy 2 Movement

After calculating the predicted position, Enemy 2 calculates:

``` text
Vertical distance to prediction
Horizontal distance to prediction
```

It then uses the same general axis-priority approach as Enemy 1:

1.  Compare vertical and horizontal distances.
2.  Choose the larger-distance axis.
3.  Attempt movement along that axis.
4.  Check whether the destination is walkable.
5.  If blocked, attempt the other axis.

The ghost therefore combines:

``` text
Player movement prediction
+
Distance-based movement
+
Wall checking
```

------------------------------------------------------------------------

## ⚔️ Enemy Turn Sequence

Enemies act after the player completes a valid turn.

The overall sequence is:

``` text
Player moves
     ↓
Collect key if present
     ↓
Check game state
     ↓
Enemy 1 collision check
     ↓
Enemy 1 moves
     ↓
Enemy 1 collision check
     ↓
Enemy 2 prediction
     ↓
Enemy 2 collision check
     ↓
Enemy 2 moves
     ↓
Enemy 2 collision check
     ↓
Final game-state check
```

This is handled mainly by:

``` asm
ResolveTurn
```

If the player wins or loses before enemy movement is required, the
remaining enemy actions are skipped.

------------------------------------------------------------------------

## 💥 Enemy Collision

If an enemy reaches the same cell as the player:

-   Player loses **1 HP**
-   The enemy is reset to its starting position
-   The game continues unless HP becomes `0`

Enemy 1 resets to:

``` text
Row 6, Column 5
```

Enemy 2 resets to:

``` text
Row 3, Column 5
```

The collision procedures are:

``` asm
CheckContact1
CheckContact2
```

This prevents an enemy from remaining on the player's position after
dealing damage.

------------------------------------------------------------------------

## ❤️ Health System

The player starts with:

``` asm
playerHP DB 3
```

Every enemy collision normally removes:

``` text
1 HP
```

The game ends when:

``` text
HP = 0
```

The player therefore has three points of health to survive enemy
encounters.

------------------------------------------------------------------------

## 🔑 Key System

There are **2 keys** placed at fixed positions.

``` text
Key 1 → Row 1, Column 6
Key 2 → Row 5, Column 1
```

The player must collect both keys before the exit can be used.

The exit is located at:

``` text
Row 6, Column 6
```

Simply reaching `G` is **not enough** to win.

The player must have:

``` text
keyCount = 2
```

and be standing on the exit.

### Key Storage

The existing `items` array stores key information.

The key is represented using **bit 0**.

This allows the program to combine key information with the persistent
exploration state described below.

------------------------------------------------------------------------

## 🌫️ Fog of War

The game includes a visibility system.

Only cells within a certain distance from the player are initially
visible.

The visibility limits are:

``` asm
FOG_ROWS EQU 2
FOG_COLS EQU 4
```

Cells outside the current visible area are displayed as:

``` text
?
```

The player itself is always displayed.

------------------------------------------------------------------------

## 🗺️ Persistent Exploration

Unlike a temporary fog system, Maze Runner V2 remembers areas that the
player has already explored.

Once a cell becomes visible, it remains visible even after the player
moves away.

The game therefore gradually reveals the maze as the player explores it.

The existing `items` array is reused to store both key and exploration
information.

``` text
Bit 0 = Key present
Bit 7 = Explored / Revealed
```

Possible values include:

  Value   Meaning
  ------- -------------------------
  `00h`   Unexplored, no key
  `01h`   Unexplored, key present
  `80h`   Explored, no key
  `81h`   Explored, key present

When the player collects a key, only the key bit is removed. The
explored bit remains set.

The exploration state is reset whenever a new level is initialized.

### Visibility Process

`IsVisible` works approximately as follows:

``` text
Is fog disabled?
      ↓
    Yes → Show cell
      ↓ No
Was cell already explored?
      ↓
    Yes → Show cell
      ↓ No
Calculate distance from player
      ↓
Within visibility range?
    /          \
  Yes           No
   ↓             ↓
Mark explored   Show ?
   ↓
Show cell
```

This creates a permanent exploration effect without requiring a separate
exploration array.

------------------------------------------------------------------------

## 🪢 Escape Rope

The `R` key activates the **Escape Rope**.

Every valid movement saves the player's previous position onto the CPU
stack.

The program maintains the number of saved positions using:

``` asm
pathDepth
```

When the player uses the rope:

1.  The previous position is popped from the stack.
2.  The player returns to that position.
3.  `pathDepth` decreases.
4.  The turn count increases.
5.  The turn is resolved.

If there are no saved positions, the game displays:

``` text
Escape Rope stack is empty.
```

This feature demonstrates the use of the **8086 stack for game-state
backtracking**.

------------------------------------------------------------------------

## ⏳ Turn System

The player has a maximum of:

``` asm
MAX_TURNS EQU 80
```

Every valid movement and Escape Rope action consumes one turn.

The current turn count is displayed during gameplay:

``` text
Turns: X/80
```

If the player reaches the 80-turn limit before winning, the game ends.

------------------------------------------------------------------------

## 🏆 Win Condition

The player wins when **both conditions** are satisfied:

1.  All 2 keys have been collected.
2.  The player reaches the exit `G`.

The game then displays a **green screen** with a victory message.

``` text
YOU WIN! 2 Keys collected and exit reached.
```

------------------------------------------------------------------------

## 💀 Lose Conditions

There are two ways to lose.

### 1. HP reaches zero

The player loses when:

``` text
HP = 0
```

The game displays a **red screen**:

``` text
GAME OVER! Your HP reached 0.
```

### 2. Turn limit reached

The player also loses if:

``` text
Turns = 80
```

The game displays:

``` text
GAME OVER! 80-turn limit reached.
```

------------------------------------------------------------------------

## ❌ Quit

The player can press:

``` text
Q
```

or:

``` text
q
```

at any time during gameplay.

The game immediately terminates using the DOS termination service:

``` asm
MOV AH, 4CH
INT 21H
```

It does not wait for another input or display the normal game-over
screen.

------------------------------------------------------------------------

## 🧠 Program Structure

The program is organized into multiple procedures:

  Procedure                Purpose
  ------------------------ --------------------------------------------------
  `MAIN_MENU`              Displays and processes the main menu
  `InitLevel`              Initializes player, enemies, keys and game state
  `HandleKey`              Processes keyboard input
  `ResolveTurn`            Handles events after each completed turn
  `MoveEnemy1`             Controls Enemy 1 chaser movement
  `Enemy1StepVertical`     Attempts vertical Enemy 1 movement
  `Enemy1StepHorizontal`   Attempts horizontal Enemy 1 movement
  `ComputePrediction`      Calculates the ghost's predicted target
  `MoveEnemy2`             Controls Enemy 2 predictive movement
  `Enemy2StepVertical`     Attempts vertical Enemy 2 movement
  `Enemy2StepHorizontal`   Attempts horizontal Enemy 2 movement
  `CheckContact1`          Checks Enemy 1 collision
  `CheckContact2`          Checks Enemy 2 collision
  `CheckAndCollectKey`     Detects and collects keys
  `CheckGameState`         Checks win/lose conditions
  `IsWalkable`             Determines whether a cell can be entered
  `ComputeIndex`           Converts row/column into maze-array index
  `IsVisible`              Handles fog and persistent exploration
  `DrawFrame`              Draws the complete game interface
  `RenderMaze`             Renders the maze
  `RenderCell`             Renders individual maze cells
  `DrawStatus`             Displays HP, keys, turns and stack depth
  `PrintByteNumber`        Prints numeric values
  `ColorScreen`            Creates colored final screens
  `PrintString`            Prints strings using DOS interrupt
  `PrintChar`              Prints individual characters
  `NewLine`                Moves to a new line
  `ClearScreen`            Clears the display
  `WaitKey`                Waits for keyboard input

------------------------------------------------------------------------

## ⚙️ Interrupts Used

The program primarily uses standard **8086/DOS interrupts**.

### INT 21H

Used for console input/output and program termination.

Important functions include:

``` asm
AH = 01H
```

Read a character from the keyboard.

``` asm
AH = 02H
```

Print a character.

``` asm
AH = 09H
```

Print a `$`-terminated string.

``` asm
AH = 4CH
```

Terminate the program immediately.

### INT 10H

Used by `ColorScreen` and `ClearScreen` to manipulate the display.

The program uses:

``` asm
AH = 06H
```

to clear the screen with a specified color attribute.

------------------------------------------------------------------------

## 📁 Project Structure

A simple project structure can be:

``` text
MazeRunner/
│
├── MazeRunner.asm
└── README.md
```

------------------------------------------------------------------------

## 📌 Technical Concepts Demonstrated

This project demonstrates several fundamental concepts of **8086
Assembly Language**:

-   Registers and register manipulation
-   Memory variables
-   Arrays using `DB`
-   Constants using `EQU`
-   Procedures
-   Stack operations (`PUSH` / `POP`)
-   Conditional jumps
-   Loops
-   Keyboard input
-   DOS interrupts
-   BIOS interrupts
-   Arithmetic operations
-   Multiplication using `MUL`
-   Division using `DIV`
-   Collision detection
-   State management
-   Array indexing
-   Bitwise operations using `TEST`, `OR`, and `AND`
-   Basic enemy AI
-   Predictive AI
-   Distance-based movement
-   Console rendering
-   Fog-of-war implementation
-   Persistent exploration
-   Game-state management

------------------------------------------------------------------------

## 🎓 Course Information

**Course:** CSE341 --- Microprocessors

**Project:** Maze Runner V2 --- Multi-Level Maze Game with Enemy AI

**Target:** 8086 / EMU8086 4.08

**Program Type:** COM

------------------------------------------------------------------------

## 👨‍💻 Author

Developed as a **CSE341 Microprocessors project** using 8086 Assembly
Language.

------------------------------------------------------------------------

## 📜 License

This project is intended for **educational purposes**.
