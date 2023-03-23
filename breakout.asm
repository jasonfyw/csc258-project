################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Jason Wang, 1008584649
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       TODO
# - Unit height in pixels:      TODO
# - Display width in pixels:    TODO
# - Display height in pixels:   TODO
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# -----------------------------------
# DISPLAY AND KBD DATA
# -----------------------------------
# Display width in pixels
DISPLAY_WIDTH:
    .word 128
# Display height in pixels
DISPLAY_HEIGHT:
    .word 128
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
BG_COLOUR:
    .word 0x000000
# -----------------------------------
# WALL DATA
# -----------------------------------
# Colour of the walls
WALL_COLOUR:
    .word 0x555555
# Thickness of the top wall
TOP_WALL_THICKNESS:
    .word 8
# Thickness of one of the side walls
SIDE_WALL_THICKNESS:
    .word 4
# -----------------------------------
# BRICK DATA
# -----------------------------------
# Colour of the bricks
BRICK_COLOUR:
    .word 0x82d2c8
# Number of rows of bricks
BRICK_ROWS:
    .word 8
# Width of one brick in pixels
BRICK_WIDTH:
    .word 8
# Height of one brick in pixels
BRICK_HEIGHT:
    .word 4
# -----------------------------------
# PADDLE DATA
# -----------------------------------
# Colour of the paddle
PADDLE_COLOUR:
    .word 0xeeeeee
# Width of the paddle in pixels
PADDLE_WIDTH:
    .word 20
# Height of the paddle in pixels
PADDLE_HEIGHT:
    .word 4
# -----------------------------------
# BALL DATA
# -----------------------------------
# Colour of the ball
BALL_COLOUR:
    .word 0xe54b4b
# Width and height of the ball
BALL_SIZE:
    .word 4

##############################################################################
# Mutable Data
##############################################################################
# X position of the paddle
PADDLE_X:
    .word 56
# Y position of the paddle
PADDLE_Y:
    .word 120
# X position of the ball
BALL_X:
    .word 64
# Y position of the ball
BALL_Y:
    .word 72
# X component of the ball velocity in pixels per frame
BALL_VX:
    .word 0
# Y component of the ball velocity in pixels per frame
BALL_VY:
    .word 4

##############################################################################
# Code
##############################################################################
	.text
	.globl main
	
	

	# Run the Brick Breaker game.
main:
    # Initialize the game
    jal draw_walls
    jal draw_bricks
    b game_loop
    
exit:
    li $v0, 10              # terminate the program gracefully
    syscall

game_loop:
    # -----------------------------------
	# 1a. Check if key has been pressed
    lw $t0, ADDR_KBRD
    lw $t8, 0($t0)
    beq $t8, 1, keyboard_input
    b keyboard_input_done
    # -----------------------------------
    # 1b. Check which key has been pressed
    keyboard_input:
        lw $a0, 4($t0)
        beq $a0, 0x61, respond_to_a
        beq $a0, 0x64, respond_to_d
        beq $a0, 0x71, respond_to_q
        j keyboard_input_done

        # Move paddle left
        respond_to_a:
            # Draw over previous paddle with black
            lw $a0, PADDLE_X
            lw $a1, PADDLE_Y
            lw $a2, PADDLE_WIDTH
            add $a2, $a2, $a0
            lw $a3, PADDLE_HEIGHT
            add $a3, $a3, $a1

            addi $sp, $sp, -4 # preserve ra of draw_walls
            sw $ra, 0($sp)

            lw $t0, BG_COLOUR # pass in color argument on stack
            addi $sp, $sp, -4
            sw $t0, 0($sp)
            
            jal draw_rect
            
            lw $ra, 0($sp) # restore ra of draw_walls
            addi $sp, $sp, 4

            # Update paddle position
            lw $t1, PADDLE_X
            lw $t2, SIDE_WALL_THICKNESS
            # Move paddle if it is not moving into a wall
            bne $t1, $t2, respond_to_a_update_paddle
            j keyboard_input_done
            respond_to_a_update_paddle:
                add $t1, $t1, -4
                sw $t1, PADDLE_X
                j keyboard_input_done

        # Move paddle right
        respond_to_d:
            # Draw over previous paddle with black
            lw $a0, PADDLE_X
            lw $a1, PADDLE_Y
            lw $a2, PADDLE_WIDTH
            add $a2, $a2, $a0
            lw $a3, PADDLE_HEIGHT
            add $a3, $a3, $a1

            addi $sp, $sp, -4 # preserve ra of draw_walls
            sw $ra, 0($sp)

            lw $t0, BG_COLOUR # pass in color argument on stack
            addi $sp, $sp, -4
            sw $t0, 0($sp)
            
            jal draw_rect
            
            lw $ra, 0($sp) # restore ra of draw_walls
            addi $sp, $sp, 4

            # Update paddle position
            lw $t1, PADDLE_X
            lw $t2, SIDE_WALL_THICKNESS
            lw $t3, DISPLAY_WIDTH
            sub $t2, $t3, $t2
            lw $t3, PADDLE_WIDTH
            sub $t2, $t2, $t3
            # Move paddle if it is not moving into a wall
            bne $t1, $t2, respond_to_d_update_paddle
            j keyboard_input_done
            respond_to_d_update_paddle:
                add $t1, $t1, 4
                sw $t1, PADDLE_X
                j keyboard_input_done

        # Quit game when q pressed
        respond_to_q:
            j exit


    # -----------------------------------
    keyboard_input_done:
        # 2a. Check for collisions
        # 2b. Update locations (paddle, ball)
        # -----------------------------------
        # 3. Draw the screen
        jal draw_paddle
        jal update_ball_pos
        # 4. Sleep
        li 		$v0, 32
        li 		$a0, 200
        syscall

        # 5. Go back to 1
        b game_loop


# ======================================================================
# update_ball_pos() -> None
# ======================================================================
# Update the position of the ball for the next frame
update_ball_pos:
    # Draw over previous ball position with background colour
    lw $a0, BALL_X # t0 = BALL_X
    lw $a1, BALL_Y # t1 = BALL_Y
    lw $t0, BALL_SIZE
    add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
    add $a3, $a1, $t0 # t3 = BALL_Y + BALL_SIZE

    # # -----------------------------------
    # draw_rect()
    addi $sp, $sp, -4 # preserve ra of draw_ball
    sw $ra, 0($sp)

    lw $t0, BG_COLOUR # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_ball
    addi $sp, $sp, 4
    # -----------------------------------

    # Update ball position based on ball velocity
    lw $t0, BALL_X
    lw $t1, BALL_Y
    lw $t2, BALL_VX
    lw $t3, BALL_VY
    add $t0, $t0, $t2
    add $t1, $t1, $t3
    sw $t0, BALL_X
    sw $t1, BALL_Y

    # -----------------------------------
    # Draw ball at new position
    addi $sp, $sp, -4 # preserve ra of update_ball_pos
    sw $ra, 0($sp)

    jal draw_ball

    lw $ra, 0($sp) # restore ra of update_ball_pos
    addi $sp, $sp, 4

    jr $ra

# ======================================================================
# draw_walls() -> None
# ======================================================================
# Draw the three walls
draw_walls:
    # -----------------------------------
    # Draw top wall
    li $a0, 0 # t0 = x_start
    li $a1, 0 # t1 = y_start
    li $a2, 128 # t2 = x_end
    lw $a3, TOP_WALL_THICKNESS # t3 = y_end

    addi $sp, $sp, -4 # preserve ra of draw_walls
    sw $ra, 0($sp)

    lw $t0, WALL_COLOUR # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_walls
    addi $sp, $sp, 4
    # -----------------------------------  
    
    # -----------------------------------
    # Draw left wall
    li $a0, 0 # t0 = x_start
    lw $a1, TOP_WALL_THICKNESS # t1 = y_start
    lw $a2, SIDE_WALL_THICKNESS # t2 = x_end
    li $a3, 128 # t3 = y_end

    addi $sp, $sp, -4 # preserve ra of draw_walls
    sw $ra, 0($sp)

    lw $t0, WALL_COLOUR # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_walls
    addi $sp, $sp, 4
    # -----------------------------------
    
    # -----------------------------------
    # Draw right wall
    li $a0, 128 # t0 = x_start
    lw $t1, SIDE_WALL_THICKNESS
    sub $a0, $a0, $t1
    lw $a1, TOP_WALL_THICKNESS # t1 = y_start
    li $a2, 128 # t2 = x_end
    li $a3, 128 # t3 = y_end

    addi $sp, $sp, -4 # preserve ra of draw_walls
    sw $ra, 0($sp)

    lw $t0, WALL_COLOUR # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_walls
    addi $sp, $sp, 4
    # -----------------------------------
    jr $ra
# ======================================================================

# ======================================================================
# draw_bricks() -> None
# ======================================================================
# Draw all the bricks
draw_bricks:
    li $s0, 4 # t0 = 4 // start_x
    li $s1, 16 # t1 = 16 // start_y
    lw $t2, DISPLAY_WIDTH
    lw $t3, SIDE_WALL_THICKNESS
    sub $s2, $t2, $t3 # t2 = end_x
    lw $t3, BRICK_ROWS
    sll $t3, $t3, 2
    add $s3, $t3, $s1 # t3 = end_y
    lw $s4, BRICK_WIDTH
    lw $s5, BRICK_HEIGHT

    draw_bricks_loop_x: # for i in range(start_x, end_x) 
        beq $s0, $s2, draw_bricks_loop_x_end
        li $s1, 16
        draw_bricks_loop_y:
            beq $s1, $s3, draw_bricks_loop_y_end

            add $a0, $s0, $zero
            add $a1, $s1, $zero
            add $a2, $a0, $s4
            add $a3, $a1, $s5

            # -----------------------------------
            # draw_rect()
            addi $sp, $sp, -4 # preserve ra of draw_bricks
            sw $ra, 0($sp)

            lw $t0, BRICK_COLOUR # pass in color argument on stack
            addi $sp, $sp, -4
            sw $t0, 0($sp)
            
            jal draw_rect
            
            lw $ra, 0($sp) # restore ra of draw_bricks
            addi $sp, $sp, 4
            # -----------------------------------

            add $s1, $s1, $s5
            j draw_bricks_loop_y
        draw_bricks_loop_y_end:
            add $s0, $s0, $s4
            j draw_bricks_loop_x
    draw_bricks_loop_x_end:
        jr $ra
# ======================================================================

# ======================================================================
# draw_paddle() -> None
# ======================================================================
# Draw the paddle at position (PADDLE_X, PADDLE_Y) stored in immutable data
draw_paddle:
    lw $a0, PADDLE_X # t0 = PADDLE_X
    lw $a1, PADDLE_Y # t1 = PADDLE_Y
    lw $t0, PADDLE_WIDTH
    add $a2, $a0, $t0 # t2 = PADDLE_X + PADDLE_WIDTH
    lw $t1, PADDLE_HEIGHT
    add $a3, $a1, $t1 # t3 = PADDLE_Y + PADDLE_HEIGHT

    # -----------------------------------
    # draw_rect()
    addi $sp, $sp, -4 # preserve ra of draw_paddle
    sw $ra, 0($sp)

    lw $t0, PADDLE_COLOUR # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_paddle
    addi $sp, $sp, 4
    # -----------------------------------

    jr $ra
# ======================================================================

# ======================================================================
# draw_ball() -> None
# ======================================================================
# Draw the ball at position (BALL_X, BALL_Y) stored in immutable data
draw_ball:
    lw $a0, BALL_X # t0 = BALL_X
    lw $a1, BALL_Y # t1 = BALL_Y
    lw $t0, BALL_SIZE
    add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
    add $a3, $a1, $t0 # t3 = BALL_Y + BALL_SIZE

    # -----------------------------------
    # draw_rect()
    addi $sp, $sp, -4 # preserve ra of draw_ball
    sw $ra, 0($sp)

    lw $t0, BALL_COLOUR # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_ball
    addi $sp, $sp, 4
    # -----------------------------------

    jr $ra
# ======================================================================

# ======================================================================
# draw_rect(x_start: int, y_start: int, x_end: int, y_end: int, color: int) -> None
# ======================================================================
# Draw a rectangle with the top left coord of (x_start, y_start) and the bottom right coord of (x_end, y_end)
draw_rect:
    # read in parameters from $a0-$a3
    add $t0, $a0, $zero # t0 = x_start
    add $t1, $a1, $zero # t1 = y_start
    add $t2, $a2, $zero # t2 = x_end
    add $t3, $a3, $zero # t3 = y_end

    lw $t4, 0($sp) # t4 = color
    addi $sp, $sp, 4 # remove color parameter from stack

    draw_rect_loop_x: # for i in range(start_x, end_x)
        beq $t0, $t2, draw_rect_loop_x_end
        add $t1, $a1, $zero
        draw_rect_loop_y: # for j in range(start_y, end_y)
            beq $t1, $t3, draw_rect_loop_y_end
            
            lw $t7, ADDR_DSPL # load starting address of bitmap display

            # calculate offset from ADDR_DSPL
            sll $t5, $t0, 0 # t5 = t0 * 4
            sll $t6, $t1, 5 # t6 = t2 * 32
            
            add $t7, $t7, $t5
            add $t7, $t7, $t6
            sw $t4, 0($t7)
            
            addi $t1, $t1, 4
            j draw_rect_loop_y
        draw_rect_loop_y_end:
            addi $t0, $t0, 4
            j draw_rect_loop_x
    draw_rect_loop_x_end:
        jr $ra
