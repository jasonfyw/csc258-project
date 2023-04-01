# Atari Breakout using MIPS ASM

Atari Breakout implemented in MIPS Assembly for the CSC258 project (Winter 2023).

## How to play

Clone the repo or download `breakout.asm` and open `breakout.asm` with a MIPS assembler/simulator (e.g. Saturn or MARS).

Ensure that the keyboard and bitmap display are connected and the display is configured to 256x256 with 4px unit size. Then, run the game and use the following controls:

- `a` + `d`: move paddle left and right
- `space`: launch ball when starting an attempt
- `p`: pause the game
- `q`: quit the game

Launch the ball with `space` and then destroy all the bricks to win! Hitting the paddle in different spots results in the ball rebounding with a difference trajectory. If the ball reaches the bottom of the screen, a life will be lost. After three lives lost, the game will end.
