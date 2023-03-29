################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Jason Wang, 1008584649
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    256
# - Display height in pixels:   256
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
    .word 256
# Display height in pixels
DISPLAY_HEIGHT:
    .word 256
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# Background colour
BG_COLOUR:
    .word 0x000000
# Milliseconds between each frame
FRAME_TIME:
    .word 60
# -----------------------------------
# ON SCREEN DISPLAY
# -----------------------------------
# Starting offsets for each heart
HEART_ADDR:
    .word 520, 556, 592
HEART_FULL_COLOUR:
    .word 0xe54b4b
HEART_EMPTY_COLOUR:
    .word 0x000000
SCORE_ADDR:
    .word 716, 732, 748
# -----------------------------------
# WALL DATA
# -----------------------------------
# Colour of the walls
WALL_COLOUR:
    .word 0x555555
# Thickness of the top wall
TOP_WALL_THICKNESS:
    .word 36
# Thickness of one of the side walls
SIDE_WALL_THICKNESS:
    .word 8
# -----------------------------------
# BRICK DATA
# -----------------------------------
# Colour of the bricks
BRICK_COLOUR:
    .word 0x82d2c8
# Number of rows of bricks
BRICK_ROWS:
    .word 28
# y height of first row of bricks
BRICK_START_HEIGHT:
    .word 56
# Width of one brick in pixels
BRICK_WIDTH:
    .word 16
# Height of one brick in pixels
BRICK_HEIGHT:
    .word 8
# -----------------------------------
# PADDLE DATA
# -----------------------------------
# Colour of the paddle
PADDLE_COLOUR:
    .word 0xeeeeee
PADDLE_COLOUR_CENTRE:
    .word 0xbbbbbb
# Width of the paddle in pixels
PADDLE_WIDTH:
    .word 36
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
    .word 112
# Y position of the paddle
PADDLE_Y:
    .word 252
# X position of the ball
BALL_X:
    .word 128
# Y position of the ball
BALL_Y:
    .word 228
# X component of the ball velocity in pixels per frame
BALL_VX:
    .word -4
# Y component of the ball velocity in pixels per frame
BALL_VY:
    .word -4
# Boolean for whether the game is paused or not
IS_PAUSED:
    .word 0
# Boolean for whether the user is launching the ball or not
IS_LAUNCHING:
    .word 1
# Number of lives
LIVES:
    .word 3
# Score of the number of bricks broken
SCORE:
    .word 0


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
    jal draw_initial_hearts
    jal draw_score
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
        lw $t1, IS_PAUSED
        beq $a0, 0x71, respond_to_q
        beq $a0, 0x70, respond_to_p
        beqz $t1, game_loop_keyboard_not_paused
        j keyboard_input_done
        game_loop_keyboard_not_paused:
            beq $a0, 0x20, respond_to_space
            beq $a0, 0x61, respond_to_a
            beq $a0, 0x64, respond_to_d
            j keyboard_input_done

        # Move paddle left
        respond_to_a:
            # Draw over previous paddle with black
            lw $a0, PADDLE_X
            lw $a1, PADDLE_Y
            addi $a1, $a1, -4
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
            addi $a1, $a1, -4
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

        # Launch ball when space pressed
        respond_to_space:
            lw $t0, IS_LAUNCHING
            bnez $t0, respond_to_space_is_launching
            j keyboard_input_done

            respond_to_space_is_launching:
                li $t1, 0
                sw $t1, IS_LAUNCHING

                j keyboard_input_done

        # Quit game when q pressed
        respond_to_q:
            j exit

        # Pause game loop
        respond_to_p:
            lw $t1, IS_PAUSED
            li $t2, 1
            sub $t1, $t2, $t1
            sw $t1, IS_PAUSED
            j keyboard_input_done


    # -----------------------------------
    keyboard_input_done:
        # 2a. Check for collisions
        # 2b. Update locations (paddle, ball)
        # -----------------------------------
        # 3. Draw the screen
        lw $t1, IS_PAUSED
        beqz $t1, game_loop_not_paused
        li 		$v0, 32
        lw 		$a0, FRAME_TIME
        syscall
        b game_loop

        game_loop_not_paused:
            jal draw_paddle
            jal update_ball_pos
            # 4. Sleep
            li 		$v0, 32
            lw 		$a0, FRAME_TIME
            syscall

            # 5. Go back to 1
            b game_loop



# ======================================================================
# lose_life() -> None
# ======================================================================
# On death, remove one life and display game over if all lives run out
lose_life:
    lw $t0, LIVES
    addi $t0, $t0, -1
    sw $t0, LIVES

    # -----------------------------------
    # Update hearts display
    la $t1, HEART_ADDR # address of HEART_ADDR
    sll $t2, $t0, 2 # offset from HEART_ADDR
    add $t2, $t2, $t1 # HEART_ADDR + offset
    lw $a0, ($t2)
    # add $a0, $t1, $t2
    lw $a1, HEART_EMPTY_COLOUR
    
    addi $sp, $sp, -4 # preserve ra
    sw $ra, 0($sp)
    jal draw_heart
    lw $ra, 0($sp) # restore ra
    addi $sp, $sp, 4
    # -----------------------------------

    lw $t0, LIVES
    beqz $t0, game_over # if LIVES == 0

    # -----------------------------------
    # Draw over previous paddle position
    lw $a0, PADDLE_X # t0 = PADDLE_X
    lw $a1, PADDLE_Y # t1 = PADDLE_Y
    addi $a1, $a1, -4
    lw $t0, PADDLE_WIDTH
    add $a2, $a0, $t0 # t2 = PADDLE_X + PADDLE_WIDTH
    lw $t1, PADDLE_HEIGHT
    add $a3, $a1, $t1 # t3 = PADDLE_Y + PADDLE_HEIGHT

    # -----------------------------------
    # draw_rect()
    addi $sp, $sp, -4 # preserve ra of draw_paddle
    sw $ra, 0($sp)

    lw $t0, BG_COLOUR # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_paddle
    addi $sp, $sp, 4
    # -----------------------------------


    # else reset mutable data
    li $t0, 112
    sw $t0, PADDLE_X

    li $t0, 252
    sw $t0, PADDLE_Y

    li $t0, 128
    sw $t0, BALL_X

    li $t0, 228
    sw $t0, BALL_Y

    li $t0, -4
    sw $t0, BALL_VX

    li $t0, -4
    sw $t0, BALL_VY

    li $t0, 1
    sw $t0, IS_LAUNCHING

    li $t0, 112
    sw $t0, PADDLE_X

    j game_loop

    game_over:
        j exit


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
    # Check if there is an obstacle toward the top of the ball and move accordingly
    lw $t1, IS_LAUNCHING
    beqz $t1, update_ball_pos_not_launching
    
    lw $t0, PADDLE_X
    lw $t1, PADDLE_WIDTH
    # li $t2, 2
    # div $t1, $t1, $t2
    addi $t1, $t1, -20
    add $t0, $t0, $t1
    sw $t0, BALL_X

    j update_ball_pos_continue

    update_ball_pos_not_launching:
        addi $sp, $sp, -4 # preserve ra of update_ball_pos
        sw $ra, 0($sp)

        jal update_ball_x

        lw $ra, 0($sp) # restore ra of update_ball_pos
        addi $sp, $sp, 4

        addi $sp, $sp, -4 # preserve ra of update_ball_pos
        sw $ra, 0($sp)

        jal update_ball_y

        lw $ra, 0($sp) # restore ra of update_ball_pos
        addi $sp, $sp, 4

        addi $sp, $sp, -4 # preserve ra of update_ball_pos
        sw $ra, 0($sp)

        jal update_ball_corner

        lw $ra, 0($sp) # restore ra of update_ball_pos
        addi $sp, $sp, 4


        lw $t0, BALL_X
        lw $t1, BALL_Y
        lw $t2, BALL_VX
        lw $t3, BALL_VY
        add $t0, $t0, $t2
        add $t1, $t1, $t3
        sw $t0, BALL_X
        sw $t1, BALL_Y

        j update_ball_pos_continue

    update_ball_pos_continue:
        # -----------------------------------
        # Draw ball at new position
        addi $sp, $sp, -4 # preserve ra of update_ball_pos
        sw $ra, 0($sp)

        jal draw_ball

        lw $ra, 0($sp) # restore ra of update_ball_pos
        addi $sp, $sp, 4

        jr $ra
# ======================================================================


# ======================================================================
# update_ball_x() -> None
# ======================================================================
# Update the position of the ball in the x direction
update_ball_x:
    lw $s0, BALL_X
    lw $s1, BALL_Y
    lw $t2, BALL_VX
    lw $t3, BALL_VY

    add $s0, $s0, $t2

    lw $t4, ADDR_DSPL # load starting address of bitmap display
    sll $t5, $s0, 0 # t5 = s0 * 4
    sll $t6, $s1, 6 # t6 = t2 * 64
    add $t4, $t4, $t5
    add $t4, $t4, $t6
    lw $t7, 0($t4) # t7 = colour of pixel at (BALL_X - 1, BALL_Y)
    lw $t8, BG_COLOUR

    bne $t7, $t8, update_ball_x_collision
    jr $ra
    # If (BALL_X - 1, BALL_Y) is NOT an empty pixel
    update_ball_x_collision:
        # Set BALL_VX = -BALL_VX
        lw $t2, BALL_VX
        sub $t2, $zero, $t2
        sw $t2, BALL_VX

        lw $t8, PADDLE_COLOUR_CENTRE
        beq $t7, $t8, update_ball_x_collision_paddle_centre
        
        # Check if collision tile is a brick
        lw $t8, BRICK_COLOUR
        beq $t7, $t8, update_ball_x_collision_brick
        jr $ra

        update_ball_x_collision_paddle_centre:
            li $t2, 0
            sw $t2, BALL_VY
            jr $ra

        update_ball_x_collision_brick:
            lw $t9, SCORE
            addi $t9, $t9, 1
            sw $t9, SCORE

            addi $sp, $sp, -4 # preserve ra
            sw $ra, 0($sp)
            jal draw_score
            lw $ra, 0($sp) # restore ra
            addi $sp, $sp, 4

            lw $t3, BALL_VX
            bgtz $t3 update_ball_x_collision_brick_left
            bltz $t3 update_ball_x_collision_brick_right
            jr $ra

            update_ball_x_collision_brick_left:
                # add $a0, $s0, $zero
                lw $a0, BALL_X
                lw $t0, BRICK_WIDTH
                sub $a0, $a0, $t0


                add $a1, $s1, $zero
                lw $t0, BRICK_START_HEIGHT
                sub $a1, $a1, $t0
                lw $t1, BRICK_HEIGHT
                div $a1, $a1, $t1
                mul $a1, $a1, $t1
                add $a1, $a1, $t0


                # add $a1, $s1, $zero
                # lw $a1, BALL_Y
                # lw $t0, BRICK_HEIGHT
                # sub $a1, $a1, $t0






                lw $t0, BRICK_WIDTH
                lw $t1, BRICK_HEIGHT
                add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                # -----------------------------------
                # draw_rect()
                addi $sp, $sp, -4 # preserve ra of draw_ball
                sw $ra, 0($sp)

                lw $t0, BG_COLOUR # pass in color argument on stack
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                
                jal draw_rect
                
                lw $ra, 0($sp) # restore ra of draw_ball
                addi $sp, $sp, 4

                jr $ra

            update_ball_x_collision_brick_right:
                # add $a0, $s0, $zero
                lw $a0, BALL_X
                # lw $t0, BRICK_WIDTH
                addi $a0, $a0, 4


                add $a1, $s1, $zero
                lw $t0, BRICK_START_HEIGHT
                sub $a1, $a1, $t0
                lw $t1, BRICK_HEIGHT
                div $a1, $a1, $t1
                mul $a1, $a1, $t1
                add $a1, $a1, $t0


                # add $a1, $s1, $zero
                # lw $a1, BALL_Y
                # lw $t0, BRICK_HEIGHT
                # sub $a1, $a1, $t0






                lw $t0, BRICK_WIDTH
                lw $t1, BRICK_HEIGHT
                add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                # -----------------------------------
                # draw_rect()
                addi $sp, $sp, -4 # preserve ra of draw_ball
                sw $ra, 0($sp)

                lw $t0, BG_COLOUR # pass in color argument on stack
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                
                jal draw_rect
                
                lw $ra, 0($sp) # restore ra of draw_ball
                addi $sp, $sp, 4

                jr $ra



# =====================================================

# ======================================================================
# update_ball_y() -> None
# ======================================================================
# Update the position of the ball in the y direction
update_ball_y:
    lw $s0, BALL_X
    lw $s1, BALL_Y
    lw $t2, BALL_VX
    lw $t3, BALL_VY

    add $s1, $s1, $t3

    lw $t4, DISPLAY_HEIGHT
    addi $t4, $t4, -4

    bgt $s1, $t4, update_ball_y_lose_life
    b update_ball_y_continue

    update_ball_y_lose_life:
        # -----------------------------------
        
        j lose_life

        # -----------------------------------
    update_ball_y_continue:
        lw $t4, ADDR_DSPL # load starting address of bitmap display
        sll $t5, $s0, 0 # t5 = s0 * 4
        sll $t6, $s1, 6 # t6 = t2 * 64
        add $t4, $t4, $t5
        add $t4, $t4, $t6
        lw $t7, 0($t4) # t7 = colour of pixel at (BALL_X, BALL_Y - 1)
        lw $t8, BG_COLOUR

        bne $t7, $t8, update_ball_y_collision

        jr $ra

        # -----------------------------------
        # If (BALL_X, BALL_Y - 1) is NOT an empty pixel
        update_ball_y_collision:
            # Set BALL_VY = -BALL_VY
            lw $t3, BALL_VY
            sub $t3, $zero, $t3
            sw $t3, BALL_VY

            lw $t8, PADDLE_COLOUR_CENTRE
            beq $t7, $t8, update_ball_y_collision_paddle_centre

            lw $t8, PADDLE_COLOUR
            beq $t7, $t8, update_ball_y_collision_paddle

            lw $t8, BRICK_COLOUR
            beq $t7, $t8, update_ball_y_collision_brick
            jr $ra

            update_ball_y_collision_paddle_centre:
                li $t2, 0
                sw $t2, BALL_VX
                jr $ra

            update_ball_y_collision_paddle:
                lw $t2, BALL_VX
                beqz $t2, update_ball_y_collision_paddle_zero_vx
                jr $ra

                update_ball_y_collision_paddle_zero_vx:
                    lw $t1, PADDLE_X
                    lw $t0, PADDLE_WIDTH
                    li $t2, 3
                    div $t0, $t0, $t2
                    add $t1, $t1, $t0

                    lw $t5, BALL_X

                    ble $t5, $t1, update_ball_y_collision_paddle_zero_vx_left
                    li $t2, 4
                    sw $t2, BALL_VX
                    jr $ra

                    update_ball_y_collision_paddle_zero_vx_left:
                        li $t2, -4
                        sw $t2, BALL_VX
                        jr $ra

            update_ball_y_collision_brick:
                lw $t9, SCORE
                addi $t9, $t9, 1
                sw $t9, SCORE
                
                addi $sp, $sp, -4 # preserve ra
                sw $ra, 0($sp)
                jal draw_score
                lw $ra, 0($sp) # restore ra
                addi $sp, $sp, 4

                lw $t3, BALL_VY
                bgtz $t3 update_ball_y_collision_brick_top
                bltz $t3 update_ball_y_collision_brick_bottom
                jr $ra

                update_ball_y_collision_brick_top:
                    add $a0, $s0, $zero
                    lw $t0, SIDE_WALL_THICKNESS
                    sub $a0, $a0, $t0
                    lw $t1, BRICK_WIDTH
                    div $a0, $a0, $t1
                    mul $a0, $a0, $t1
                    add $a0, $a0, $t0


                    add $a1, $s1, $zero
                    lw $a1, BALL_Y
                    lw $t0, BRICK_HEIGHT
                    sub $a1, $a1, $t0

                    lw $t0, BRICK_WIDTH
                    lw $t1, BRICK_HEIGHT
                    add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                    add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                    # -----------------------------------
                    # draw_rect()
                    addi $sp, $sp, -4 # preserve ra of draw_ball
                    sw $ra, 0($sp)

                    lw $t0, BG_COLOUR # pass in color argument on stack
                    addi $sp, $sp, -4
                    sw $t0, 0($sp)
                    
                    jal draw_rect
                    
                    lw $ra, 0($sp) # restore ra of draw_ball
                    addi $sp, $sp, 4

                    jr $ra

                update_ball_y_collision_brick_bottom:
                    add $a0, $s0, $zero
                    lw $t0, SIDE_WALL_THICKNESS
                    sub $a0, $a0, $t0
                    lw $t1, BRICK_WIDTH
                    div $a0, $a0, $t1
                    mul $a0, $a0, $t1
                    add $a0, $a0, $t0


                    add $a1, $s1, $zero
                    lw $a1, BALL_Y
                    # lw $t0, BRICK_HEIGHT
                    addi $a1, $a1, 4

                    lw $t0, BRICK_WIDTH
                    lw $t1, BRICK_HEIGHT
                    add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                    add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                    # -----------------------------------
                    # draw_rect()
                    addi $sp, $sp, -4 # preserve ra of draw_ball
                    sw $ra, 0($sp)

                    lw $t0, BG_COLOUR # pass in color argument on stack
                    addi $sp, $sp, -4
                    sw $t0, 0($sp)
                    
                    jal draw_rect
                    
                    lw $ra, 0($sp) # restore ra of draw_ball
                    addi $sp, $sp, 4

                    jr $ra



update_ball_corner:
    lw $s0, BALL_X
    lw $s1, BALL_Y
    lw $t2, BALL_VX
    lw $t3, BALL_VY

    add $s0, $s0, $t2
    add $s1, $s1, $t3

    lw $t4, ADDR_DSPL # load starting address of bitmap display
    sll $t5, $s0, 0 # t5 = s0 * 4
    sll $t6, $s1, 6 # t6 = t2 * 64
    add $t4, $t4, $t5
    add $t4, $t4, $t6
    lw $t7, 0($t4) # t7 = colour of pixel at (BALL_X + BALL_VX, BALL_Y + BALL_VY)
    lw $t8, BRICK_COLOUR

    beq $t7, $t8, update_ball_corner_collision

    jr $ra

    update_ball_corner_collision:
        lw $t3, BALL_VX
        lw $t4, BALL_VY
        sub $t3, $zero, $t3
        sub $t4, $zero, $t4
        sw $t3, BALL_VX
        sw $t4, BALL_VY

        bltz $t2, update_ball_corner_collision_left
        bgtz $t2, update_ball_corner_collision_right
        jr $ra

        update_ball_corner_collision_left:
            lw $t9, SCORE
            addi $t9, $t9, 1
            sw $t9, SCORE
            
            addi $sp, $sp, -4 # preserve ra
            sw $ra, 0($sp)
            jal draw_score
            lw $ra, 0($sp) # restore ra
            addi $sp, $sp, 4

            bltz $t3, update_ball_corner_collision_topleft
            bgtz $t3, update_ball_corner_collision_bottomleft
            jr $ra

            update_ball_corner_collision_topleft:
                lw $a0, BALL_X
                lw $t0, BRICK_WIDTH
                sub $a0, $a0, $t0
                # subi $a0, $a0, 4

                # add $a1, $s1, $zero
                lw $a1, BALL_Y
                lw $t0, BRICK_HEIGHT
                sub $a1, $a1, $t0
                # subi $a1, $a1, 4


                lw $t0, BRICK_WIDTH
                lw $t1, BRICK_HEIGHT
                add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                # -----------------------------------
                # draw_rect()
                addi $sp, $sp, -4 # preserve ra of draw_ball
                sw $ra, 0($sp)

                lw $t0, BG_COLOUR # pass in color argument on stack
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                
                jal draw_rect
                
                lw $ra, 0($sp) # restore ra of draw_ball
                addi $sp, $sp, 4

                jr $ra
            update_ball_corner_collision_bottomleft:
                lw $a0, BALL_X
                lw $t0, BRICK_WIDTH
                sub $a0, $a0, $t0
                # subi $a0, $a0, 4

                # add $a1, $s1, $zero
                lw $a1, BALL_Y
                # lw $t0, BRICK_HEIGHT
                # sub $a1, $a1, $t0
                addi $a1, $a1, 4


                lw $t0, BRICK_WIDTH
                lw $t1, BRICK_HEIGHT
                add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                # -----------------------------------
                # draw_rect()
                addi $sp, $sp, -4 # preserve ra of draw_ball
                sw $ra, 0($sp)

                lw $t0, BG_COLOUR # pass in color argument on stack
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                
                jal draw_rect
                
                lw $ra, 0($sp) # restore ra of draw_ball
                addi $sp, $sp, 4

                jr $ra

        update_ball_corner_collision_right:
            lw $t9, SCORE
            addi $t9, $t9, 1
            sw $t9, SCORE
            
            addi $sp, $sp, -4 # preserve ra
            sw $ra, 0($sp)
            jal draw_score
            lw $ra, 0($sp) # restore ra
            addi $sp, $sp, 4

            bltz $t3, update_ball_corner_collision_topright
            bgtz $t3, update_ball_corner_collision_bottomright
            jr $ra

            update_ball_corner_collision_topright:
                lw $a0, BALL_X
                # lw $t0, BRICK_WIDTH
                # sub $a0, $a0, $t0
                addi $a0, $a0, 4

                # add $a1, $s1, $zero
                lw $a1, BALL_Y
                lw $t0, BRICK_HEIGHT
                sub $a1, $a1, $t0
                # subi $a1, $a1, 4


                lw $t0, BRICK_WIDTH
                lw $t1, BRICK_HEIGHT
                add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                # -----------------------------------
                # draw_rect()
                addi $sp, $sp, -4 # preserve ra of draw_ball
                sw $ra, 0($sp)

                lw $t0, BG_COLOUR # pass in color argument on stack
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                
                jal draw_rect
                
                lw $ra, 0($sp) # restore ra of draw_ball
                addi $sp, $sp, 4
                jr $ra
            update_ball_corner_collision_bottomright:
                lw $a0, BALL_X
                # lw $t0, BRICK_WIDTH
                # sub $a0, $a0, $t0
                addi $a0, $a0, 4

                # add $a1, $s1, $zero
                lw $a1, BALL_Y
                # lw $t0, BRICK_HEIGHT
                # sub $a1, $a1, $t0
                addi $a1, $a1, 4


                lw $t0, BRICK_WIDTH
                lw $t1, BRICK_HEIGHT
                add $a2, $a0, $t0 # t2 = BALL_X + BALL_SIZE
                add $a3, $a1, $t1 # t3 = BALL_Y + BALL_SIZE

                # -----------------------------------
                # draw_rect()
                addi $sp, $sp, -4 # preserve ra of draw_ball
                sw $ra, 0($sp)

                lw $t0, BG_COLOUR # pass in color argument on stack
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                
                jal draw_rect
                
                lw $ra, 0($sp) # restore ra of draw_ball
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
    lw $a2, DISPLAY_WIDTH # t2 = x_end
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
    lw $a3, DISPLAY_HEIGHT # t3 = y_end

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
    lw $a0, DISPLAY_WIDTH # t0 = x_start
    lw $t1, SIDE_WALL_THICKNESS
    sub $a0, $a0, $t1
    lw $a1, TOP_WALL_THICKNESS # t1 = y_start
    lw $a2, DISPLAY_WIDTH # t2 = x_end
    lw $a3, DISPLAY_HEIGHT # t3 = y_end

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
    lw $s0, SIDE_WALL_THICKNESS # t0 = start_x
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
        lw $s1, BRICK_START_HEIGHT
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
    addi $a1, $a1, -4
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





    lw $a0, PADDLE_X # t0 = PADDLE_X
    lw $t0, PADDLE_WIDTH
    li $t2, 3
    div $t3, $t0, $t2
    add $a0, $a0, $t3

    lw $a1, PADDLE_Y # t1 = PADDLE_Y
    addi $a1, $a1, -4

    add $a2, $a0, $t3 # t2 = PADDLE_X + PADDLE_WIDTH

    lw $t1, PADDLE_HEIGHT
    add $a3, $a1, $t1 # t3 = PADDLE_Y + PADDLE_HEIGHT

    # -----------------------------------
    # draw_rect()
    addi $sp, $sp, -4 # preserve ra of draw_paddle
    sw $ra, 0($sp)

    lw $t0, PADDLE_COLOUR_CENTRE # pass in color argument on stack
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
# draw_initial_hearts() -> None
# ======================================================================
# Draw three red hearts
draw_initial_hearts:
    la $t0, HEART_ADDR
    lw $a0, 0($t0)
    lw $a1, HEART_FULL_COLOUR
    addi $sp, $sp, -4 # preserve ra
    sw $ra, 0($sp)
    jal draw_heart
    lw $ra, 0($sp) # restore ra
    addi $sp, $sp, 4

    la $t0, HEART_ADDR
    lw $a0, 4($t0)
    lw $a1, HEART_FULL_COLOUR
    addi $sp, $sp, -4 # preserve ra
    sw $ra, 0($sp)
    jal draw_heart
    lw $ra, 0($sp) # restore ra
    addi $sp, $sp, 4

    la $t0, HEART_ADDR
    lw $a0, 8($t0)
    lw $a1, HEART_FULL_COLOUR
    addi $sp, $sp, -4 # preserve ra
    sw $ra, 0($sp)
    jal draw_heart
    lw $ra, 0($sp) # restore ra
    addi $sp, $sp, 4

    jr $ra


# ======================================================================
# draw_heart(top_left_corner: int, colour: int) -> None
# ======================================================================
# Draw a heart in the 7x5 region extending from <top_left_corner>
draw_heart:
    add $t0, $zero, $a0 # load in <top_left_corner>
    lw $t1, DISPLAY_WIDTH
    # -----------------------------------
    lw $t7, ADDR_DSPL
    add $t7, $t7, $t0

    sw $a1, 4($t7)
    sw $a1, 8($t7)
    sw $a1, 16($t7)
    sw $a1, 20($t7)
    # -----------------------------------
    lw $t7, ADDR_DSPL
    add $t7, $t7, $t0
    add $t7, $t7, $t1

    sw $a1, 0($t7)
    sw $a1, 4($t7)
    sw $a1, 8($t7)
    sw $a1, 12($t7)
    sw $a1, 16($t7)
    sw $a1, 20($t7)
    sw $a1, 24($t7)
    # -----------------------------------
    lw $t7, ADDR_DSPL
    add $t7, $t7, $t0
    add $t7, $t7, $t1
    add $t7, $t7, $t1

    sw $a1, 4($t7)
    sw $a1, 8($t7)
    sw $a1, 12($t7)
    sw $a1, 16($t7)
    sw $a1, 20($t7)
    # -----------------------------------
    lw $t7, ADDR_DSPL
    add $t7, $t7, $t0
    add $t7, $t7, $t1
    add $t7, $t7, $t1
    add $t7, $t7, $t1

    sw $a1, 8($t7)
    sw $a1, 12($t7)
    sw $a1, 16($t7)
    # -----------------------------------
    lw $t7, ADDR_DSPL
    add $t7, $t7, $t0
    add $t7, $t7, $t1
    add $t7, $t7, $t1
    add $t7, $t7, $t1
    add $t7, $t7, $t1

    sw $a1, 12($t7)
    
    jr $ra


# ======================================================================
# draw_score() -> None
# ======================================================================
# Draw the current score
draw_score:
    lw $t0, SCORE

    li $t1, 10      # Load the divisor (10) into $t1
    div $t0, $t0, $t1  # Divide $t0 by $t1 to get rid of the least significant digit

    mflo $t2       # Move the quotient of the division (the value in $t0) to $t2
    li $t1, 10      # Load the value 10 into $t1
    mul $t2, $t2, $t1  # Multiply the quotient in $t2 by the value 10
    lw $t0, SCORE
    sub $t6, $t0, $t2

    # -----------------------------------

    la $t9, SCORE_ADDR
    lw $a0, 8($t9)
    add $a1, $zero, $t6
    addi $sp, $sp, -4 # preserve ra
    sw $ra, 0($sp)
    jal draw_digit
    lw $ra, 0($sp) # restore ra
    addi $sp, $sp, 4



    

    lw $t0, SCORE
    li $t1, 10
    div $t0, $t0, $t1

    li $t1, 10      # Load the divisor (10) into $t1
    div $t0, $t0, $t1  # Divide $t0 by $t1 to get rid of the least significant digit

    mflo $t2       # Move the quotient of the division (the value in $t0) to $t2
    li $t1, 10      # Load the value 10 into $t1
    mul $t2, $t2, $t1  # Multiply the quotient in $t2 by the value 10
    lw $t0, SCORE
    li $t1, 10
    div $t0, $t0, $t1
    sub $t7, $t0, $t2



    la $t9, SCORE_ADDR
    lw $a0, 4($t9)
    add $a1, $zero, $t7
    addi $sp, $sp, -4 # preserve ra
    sw $ra, 0($sp)
    jal draw_digit
    lw $ra, 0($sp) # restore ra
    addi $sp, $sp, 4







    lw $t0, SCORE
    li $t1, 100
    div $t0, $t0, $t1

    li $t1, 10      # Load the divisor (10) into $t1
    div $t0, $t0, $t1  # Divide $t0 by $t1 to get rid of the least significant digit

    mflo $t2       # Move the quotient of the division (the value in $t0) to $t2
    li $t1, 10      # Load the value 10 into $t1
    mul $t2, $t2, $t1  # Multiply the quotient in $t2 by the value 10
    lw $t0, SCORE
    li $t1, 100
    div $t0, $t0, $t1
    sub $t8, $t0, $t2

    la $t9, SCORE_ADDR
    lw $a0, 0($t9)
    add $a1, $zero, $t8
    addi $sp, $sp, -4 # preserve ra
    sw $ra, 0($sp)
    jal draw_digit
    lw $ra, 0($sp) # restore ra
    addi $sp, $sp, 4

    jr $ra
# ======================================================================

# ======================================================================
# draw_digit(top_left_corner: int, val: int) -> None
# ======================================================================
# Draw a 3x5 digit in white extending from <top_left_corner> with value <val>
draw_digit:
    add $t0, $zero, $a0 # load in <top_left_corner>
    lw $t1, DISPLAY_WIDTH

    # -----------------------------------

    lw $t7, ADDR_DSPL
    add $t7, $t7, $t0
    lw $t8, WALL_COLOUR
    sw $t8, 0($t7)
    sw $t8, 4($t7)
    sw $t8, 8($t7)
    add $t7, $t7, $t1
    sw $t8, 0($t7)
    sw $t8, 4($t7)
    sw $t8, 8($t7)
    add $t7, $t7, $t1
    sw $t8, 0($t7)
    sw $t8, 4($t7)
    sw $t8, 8($t7)
    add $t7, $t7, $t1
    sw $t8, 0($t7)
    sw $t8, 4($t7)
    sw $t8, 8($t7)
    add $t7, $t7, $t1
    sw $t8, 0($t7)
    sw $t8, 4($t7)
    sw $t8, 8($t7)

    # -----------------------------------

    li $t8, 0xffffff

    li $t9, 0
    beq $a1, $t9, draw_digit_0
    li $t9, 1
    beq $a1, $t9, draw_digit_1
    li $t9, 2
    beq $a1, $t9, draw_digit_2
    li $t9, 3
    beq $a1, $t9, draw_digit_3
    li $t9, 4
    beq $a1, $t9, draw_digit_4
    li $t9, 5
    beq $a1, $t9, draw_digit_5
    li $t9, 6
    beq $a1, $t9, draw_digit_6
    li $t9, 7
    beq $a1, $t9, draw_digit_7
    li $t9, 8
    beq $a1, $t9, draw_digit_8
    li $t9, 9
    beq $a1, $t9, draw_digit_9

    draw_digit_0:
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra
    draw_digit_1:
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 4($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 4($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 4($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra
    draw_digit_2:
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra
    draw_digit_3:
    # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra
    draw_digit_4:
    # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)

        jr $ra
    draw_digit_5:
    # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra
    draw_digit_6:
    # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra
    draw_digit_7:
    # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)

        jr $ra
    draw_digit_8:
    # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra
    draw_digit_9:
    # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 8($t7)
        # -----------------------------------
        lw $t7, ADDR_DSPL
        add $t7, $t7, $t0
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1
        add $t7, $t7, $t1

        sw $t8, 0($t7)
        sw $t8, 4($t7)
        sw $t8, 8($t7)

        jr $ra


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
            sll $t6, $t1, 6 # t6 = t2 * 64
            
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
