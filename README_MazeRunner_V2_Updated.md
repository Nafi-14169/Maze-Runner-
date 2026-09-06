# Maze Runner --- 8086 Assembly (V2)

## Project Overview

**Maze Runner V2** is an 8086 Assembly language maze game developed for
**CSE341: Microprocessors** using **EMU8086 4.08**. The program is a
COM-format DOS program and expands the original maze/game structure with
a main menu, two playable levels, a predictive second enemy, Cheat Mode,
Escape Rope, and persistent fog-of-war exploration.

The game contains **Level 1 with one chaser**, **Level 2 with two
enemies (chaser + predictive ghost)**, and a **Cheat Mode** for
demonstration/testing.

## V2 Features

1.  **Main Menu & Level Management**
2.  **Player Controls, Movement & Escape Rope**
3.  **Enemy 1 Chaser AI**
4.  **Enemy 2 Predictive Ghost AI**
5.  **Keys, HP & Win/Lose Game Logic**
6.  **Fog of War, Persistent Exploration, Maze Rendering & Game UI**

## Game Objective

Collect both keys and reach the exit **G** before:

-   HP reaches `0`, or
-   the `80`-turn limit is reached.

## Main Menu

The main menu provides three gameplay options:

``` text
1. Level 1  (1 enemy - chaser)
2. Level 2  (2 enemies - chaser + predictive ghost)
3. Cheat Mode (guided demo win)
Q. Exit
```

## Levels

### Level 1 --- One Enemy

-   Contains **1 enemy**, represented by `X`.
-   Enemy 1 uses a simple chaser algorithm.
-   It compares its horizontal and vertical distance from the player.
-   It tries to move along the larger-distance axis first.
-   If that direction is blocked, it attempts the other axis.

### Level 2 --- Two Enemies

Level 2 adds a second enemy represented by `Y`.

-   **Enemy 1 (`X`)**: normal chaser.
-   **Enemy 2 (`Y`)**: predictive ghost.
-   The predictive ghost estimates where the player will be based on the
    player's last movement direction.
-   Prediction distance is `2` cells.
-   The ghost moves toward the predicted position while respecting maze
    walls.

## Cheat Mode

The main menu provides:

`3. Cheat Mode (guided demo win)`

Cheat Mode:

-   disables enemy movement,
-   disables the fog of war,
-   displays the full map,
-   shows the solution sequence for the fixed maze.

This mode is intended for demonstration and testing rather than normal
gameplay.

## Controls

  Key         Action
  ----------- ---------------------
  `W` / `w`   Move Up
  `S` / `s`   Move Down
  `A` / `a`   Move Left
  `D` / `d`   Move Right
  `R` / `r`   Use Escape Rope
  `M` / `m`   Return to Main Menu
  `Q` / `q`   Quit immediately

### Quit Behavior

Pressing `Q` or `q` immediately terminates the DOS program using:

``` asm
MOV AH, 4CH
INT 21H
```

The game does not wait for another input or display the game-over screen
after a quit command.

## Maze Symbols

  Symbol   Meaning
  -------- -------------------------------
  `P`      Player
  `X`      Enemy 1 --- Chaser
  `Y`      Enemy 2 --- Predictive Ghost
  `K`      Key
  `G`      Exit
  `#`      Wall
  `.`      Walkable cell
  `?`      Unexplored cell hidden by fog

## Player System

The player starts with:

-   **HP:** `3`
-   **Keys:** `0/2`
-   **Turns:** `0/80`

A valid movement:

1.  Checks whether the destination is walkable.
2.  Pushes the previous player position onto the CPU stack.
3.  Updates the player's position.
4.  Stores the movement direction.
5.  Increases the turn counter.
6.  Resolves keys, enemies, and game-state conditions.

## Escape Rope

The `R` command uses the **8086 CPU stack** as movement history.

When the player makes a valid move, the previous row/column position is
pushed onto the stack.

Using `R`:

-   pops the previous position,
-   restores the player to it,
-   decreases the stack-depth counter,
-   consumes a turn.

If there is no stored position, the game displays:

`Escape Rope stack is empty.`

## Enemy Collision

If an enemy reaches the player's position:

-   Player HP decreases by `1`.
-   The enemy is reset to its starting position.
-   The game continues unless HP becomes `0`.

Level 2 performs the same collision concept for the second enemy.

## Fog of War

Normal gameplay does not display the entire maze.

A cell is initially visible only when its distance from the player is
within:

-   **2 rows**
-   **4 columns**

Cells outside the current visibility range are displayed as `?`.

### Persistent Exploration

V2 uses **persistent exploration**. Once a cell has been revealed, it
remains visible even after the player moves away.

The maze is therefore uncovered progressively as the player explores it.

The existing `items` array is reused to store both key and exploration
information:

-   **bit 0** = key present
-   **bit 7 (`80h`)** = explored/revealed

The possible states are:

  Value   Meaning
  ------- -------------------------
  `00h`   Unexplored, no key
  `01h`   Unexplored, key present
  `80h`   Explored, no key
  `81h`   Explored, key present

When a key is collected, only bit 0 is cleared, so the explored state
remains.

The exploration state is reset when a new level is initialized.

### How Persistent Fog Works

The `IsVisible` procedure:

1.  Checks whether Cheat Mode has disabled the fog.
2.  Checks whether the target cell was already explored.
3.  If it was explored, the cell remains visible.
4.  Otherwise, it calculates the cell's distance from the player.
5.  If the cell is within the fog range, bit 7 is set and the cell
    becomes permanently revealed.
6.  Otherwise, the cell remains hidden as `?`.

## Turn Limit

The maximum number of turns is:

`80`

The turn counter increases after:

-   valid movement
-   Escape Rope usage

If the counter reaches `80` before the player wins, the game ends with
the turn-limit loss condition.

## Win Condition

The player wins only when both conditions are true:

1.  `keyCount == 2`
2.  The player is standing on the exit cell `G`.

The game then displays the win screen with a colored background.

## Lose Conditions

The player loses when either:

### HP Loss

`playerHP == 0`

### Turn Limit

`turnCount >= 80`

The program stores the loss reason so it can display the correct
message.

## Rendering

The maze is rendered row by row.

For each cell, the program checks in order:

1.  Is it the player?
2.  Is it hidden by fog?
3.  Is it Enemy 1?
4.  Is it Enemy 2?
5.  Is it a key?
6.  Is it a wall?
7.  Is it the exit?
8.  Otherwise, display a walkable cell.

Previously explored cells are not hidden again when the player moves
away.

## Important 8086 Concepts Used

-   Registers: `AX`, `BX`, `CX`, `DX`, `SI`
-   Procedures with `CALL` / `RET`
-   CPU stack with `PUSH` / `POP`
-   Arrays using indexed addressing
-   `MUL` and `DIV`
-   Conditional jumps
-   Loops
-   BIOS interrupt `INT 10H`
-   DOS interrupt `INT 21H`
-   COM program structure with `ORG 100H`
-   State variables
-   Simple enemy AI
-   Predictive movement
-   Bitwise `TEST`, `OR`, and `AND`
-   Fog-of-war rendering
-   Persistent exploration

## Important Interrupts

### DOS `INT 21H`

Used for:

-   keyboard input --- `AH = 01H`
-   string output --- `AH = 09H`
-   character output --- `AH = 02H`
-   immediate program termination --- `AH = 4CH`

### BIOS `INT 10H`

Used for:

-   clearing the screen,
-   applying screen color attributes,
-   resetting the cursor.

## Project Structure

The project is implemented as a single assembly source file.

The code uses procedures to separate major game operations, including:

-   `MAIN_MENU`
-   `GAME_LOOP`
-   `HandleKey`
-   `InitLevel`
-   `ResolveTurn`
-   `MoveEnemy1`
-   `MoveEnemy2`
-   `ComputePrediction`
-   `CheckAndCollectKey`
-   `CheckGameState`
-   `IsVisible`
-   `RenderMaze`
-   `RenderCell`
-   `DrawStatus`
-   screen and output helper procedures

Comments in the source explain the purpose of important instructions and
procedures without adding project-member ownership labels to every line.

## Running the Project

1.  Open **EMU8086 4.08**.
2.  Open the Maze Runner `.asm` source file.
3.  Compile/build the COM program.
4.  Run the generated COM program.
5.  Select Level 1, Level 2, or Cheat Mode from the main menu.

## Recommended Demonstration Order

1.  Show **Level 1** and demonstrate the chaser.
2.  Demonstrate **Escape Rope** using `R`.
3.  Show **Level 2** and demonstrate both `X` and `Y`.
4.  Explain the predictive ghost using the player's last movement
    direction.
5.  Demonstrate key collection, HP, and the 80-turn limit.
6.  Demonstrate **persistent fog exploration** by moving away from an
    explored area and returning to it.
7.  Demonstrate **immediate quit** using `Q`.
8.  Finally show **Cheat Mode** for the guided solution.

## V2 Changes from the Previous Version

The V2 version expands the original game with:

-   Main menu
-   Level selection
-   Level 1 with one enemy
-   Level 2 with two enemies
-   Predictive ghost AI
-   Cheat Mode
-   Menu return option
-   Updated maze rendering for `X` and `Y`
-   Updated status display with the current level
-   Persistent fog-of-war exploration
-   Immediate `Q` / `q` program termination
-   Escape Rope using the CPU stack

## Course Information

**Course:** CSE341 --- Microprocessors\
**Architecture:** Intel 8086\
**Environment:** EMU8086 4.08\
**Program Type:** COM\
**Project:** Maze Runner V2
