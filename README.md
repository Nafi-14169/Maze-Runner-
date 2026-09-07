# 🧩 Maze Runner 

A console-based **Maze Runner game written in 8086 Assembly Language** for **EMU8086 4.08**.

The player must navigate through an 8×8 maze, collect **2 keys**, avoid an enemy, and reach the exit before losing all HP or exceeding the turn limit.

---

## 🎮 Game Overview

**Objective:**

> Collect both keys (`K`) and reach the exit (`G`) before your HP reaches 0 or the 80-turn limit is reached.

The game features:

* 🧍 Player movement
* 👾 One enemy that follows the player
* 🔑 Two fixed keys
* 🚪 Exit/goal
* ❤️ 3 HP
* 🌫️ Fog of war
* 🪢 Escape Rope for backtracking
* ⏳ 80-turn limit
* 🟢 Green victory screen
* 🔴 Red game-over screen
* ❌ Quit option

---

## 🛠️ Requirements

* **EMU8086 4.08**
* **8086 processor/emulator**
* COM program support
* DOS-compatible environment

The source file is configured as a COM program using:

```asm
#make_COM#
ORG 100H
```

---

## ▶️ How to Run

1. Open **EMU8086**.
2. Open `MazeRunner.asm`.
3. Compile/assemble the program.
4. Run the generated COM program.
5. Use the keyboard to control the player.

---

## 🎯 Controls

| Key       | Action          |
| --------- | --------------- |
| `W` / `w` | Move Up         |
| `S` / `s` | Move Down       |
| `A` / `a` | Move Left       |
| `D` / `d` | Move Right      |
| `R` / `r` | Use Escape Rope |
| `Q` / `q` | Quit Game       |

---

## 🗺️ Maze Symbols

| Symbol | Meaning            |
| ------ | ------------------ |
| `P`    | Player             |
| `X`    | Enemy              |
| `K`    | Key                |
| `G`    | Exit               |
| `#`    | Wall               |
| `.`    | Walkable path      |
| `?`    | Hidden/Fogged area |

The program uses an **8×8 maze** and stores the maze as a linear array of 64 cells. The index is calculated using:

```text
index = row × 8 + column
```

The maze itself is defined using `DB` values where:

```text
0 = Walkable cell
1 = Wall
2 = Exit
```

---

## ❤️ Health System

The player starts with:

```asm
playerHP DB 3
```

When the enemy reaches the same cell as the player:

* Player loses **1 HP**
* Enemy returns to its starting position

The game ends when:

```text
HP = 0
```

---

## 🔑 Key System

There are **2 keys** placed at fixed positions.

```text
Key 1 → Row 1, Column 6
Key 2 → Row 5, Column 1
```

The player must collect both keys before the exit can be used.

The exit is located at:

```text
Row 6, Column 6
```

Simply reaching `G` is **not enough** to win.

The player must have:

```text
keyCount = 2
```

and be standing on the exit.

---

## 👾 Enemy System

The game contains one enemy.

Starting position:

```text
Row 6, Column 5
```

After each valid player action, the enemy attempts to move toward the player.

The enemy compares:

* Vertical distance
* Horizontal distance

It then prioritizes the direction with the greater distance.

If the preferred direction is blocked by a wall, the enemy attempts the other direction.

If the enemy reaches the player's position, the player loses 1 HP.

---

## 🌫️ Fog of War

The game includes a simple visibility system.

Only cells within a certain distance from the player are visible.

The visibility limits are:

```asm
FOG_ROWS EQU 2
FOG_COLS EQU 4
```

Cells outside the visible area are displayed as:

```text
?
```

The player itself is always displayed.

---

## 🪢 Escape Rope

The `R` key activates the **Escape Rope**.

Every valid movement saves the player's previous position onto the CPU stack.

The program maintains the number of saved positions using:

```asm
pathDepth
```

When the player uses the rope:

1. The previous position is popped from the stack.
2. The player returns to that position.
3. `pathDepth` decreases.
4. The turn count increases.
5. The turn is resolved.

If there are no saved positions, the game displays:

```text
Escape Rope stack is empty.
```

This feature demonstrates the use of the **8086 stack for game-state backtracking**.

---

## ⏳ Turn System

The player has a maximum of:

```asm
MAX_TURNS EQU 80
```

Every valid movement and Escape Rope action consumes one turn.

The current turn count is displayed during gameplay:

```text
Turns: X/80
```

If the player reaches the 80-turn limit before winning, the game ends.

---

## 🏆 Win Condition

The player wins when **both conditions** are satisfied:

1. All 2 keys have been collected.
2. The player reaches the exit `G`.

The game then displays a **green screen** with a victory message.

```text
YOU WIN! 2 Keys collected and exit reached.
```

---

## 💀 Lose Conditions

There are two ways to lose.

### 1. HP reaches zero

The player loses when:

```text
HP = 0
```

The game displays a **red screen**:

```text
GAME OVER! Your HP reached 0.
```

### 2. Turn limit reached

The player also loses if:

```text
Turns = 80
```

The game displays:

```text
GAME OVER! 80-turn limit reached.
```

---

## ❌ Quit

The player can press:

```text
Q
```

at any time during gameplay.

The game ends and displays:

```text
Game ended by user.
```

---

## 🧠 Program Structure

The program is divided into multiple procedures:

| Procedure              | Purpose                                   |
| ---------------------- | ----------------------------------------- |
| `InitGame`             | Initializes keys and game data            |
| `HandleKey`            | Processes keyboard input                  |
| `ResolveTurn`          | Handles events after each turn            |
| `MoveEnemy1`           | Controls enemy movement                   |
| `Enemy1StepVertical`   | Attempts vertical enemy movement          |
| `Enemy1StepHorizontal` | Attempts horizontal enemy movement        |
| `CheckContact`         | Checks player-enemy collision             |
| `CheckAndCollectKey`   | Detects and collects keys                 |
| `CheckGameState`       | Checks win/lose conditions                |
| `IsWalkable`           | Determines whether a cell can be entered  |
| `ComputeIndex`         | Converts row/column into maze-array index |
| `IsVisible`            | Handles fog-of-war visibility             |
| `DrawFrame`            | Draws the complete game interface         |
| `RenderMaze`           | Renders the maze                          |
| `RenderCell`           | Renders individual maze cells             |
| `DrawStatus`           | Displays HP, keys, turns and stack depth  |
| `PrintByteNumber`      | Prints numeric values                     |
| `ColorScreen`          | Creates colored final screens             |
| `PrintString`          | Prints strings using DOS interrupt        |
| `PrintChar`            | Prints individual characters              |
| `NewLine`              | Moves to a new line                       |
| `ClearScreen`          | Clears the display                        |
| `WaitKey`              | Waits for keyboard input                  |

---

## ⚙️ Interrupts Used

The program primarily uses standard **8086/DOS interrupts**.

### INT 21H

Used for console input/output and program termination.

Important functions include:

```asm
AH = 01H
```

Read a character from the keyboard.

```asm
AH = 02H
```

Print a character.

```asm
AH = 09H
```

Print a `$`-terminated string.

```asm
AX = 4C00H
```

Terminate the program.

### INT 10H

Used by `ColorScreen` to manipulate the display.

The program uses:

```asm
AH = 06H
```

to clear the screen with a specified color attribute.

---

## 📁 Project Structure

A simple project structure can be:

```text
MazeRunner/
│
├── MazeRunner.asm
└── README.md
```

---

## 📌 Technical Concepts Demonstrated

This project demonstrates several fundamental concepts of **8086 Assembly Language**:

* Registers and register manipulation
* Memory variables
* Arrays using `DB`
* Constants using `EQU`
* Procedures
* Stack operations (`PUSH` / `POP`)
* Conditional jumps
* Loops
* Keyboard input
* DOS interrupts
* BIOS interrupts
* Arithmetic operations
* Multiplication using `MUL`
* Division using `DIV`
* Collision detection
* State management
* Array indexing
* Basic game logic
* Console rendering
* Fog-of-war implementation

---

## 🎓 Course Information

**Course:** CSE341 — Microprocessors

**Project:** Maze Runner with 1 Enemy & Colored End Screens

**Target:** 8086 / EMU8086 4.08

**Program Type:** COM

---

## 👨‍💻 Author

Developed as a **CSE341 Microprocessors project** using 8086 Assembly Language.

---

## 📜 License

This project is intended for **educational purposes**.
