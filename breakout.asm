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
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main
	
	

	# Run the Brick Breaker game.
main:
    # Initialize the game
    jal draw_walls
    j exit
    
exit:
    li $v0, 10              # terminate the program gracefully
    syscall

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to 1
    b game_loop
    

# ===================================
# void draw_walls()
# 
# Draw the three walls
draw_walls:
    # -----------------------------------
    # Draw top wall
    li $a0, 0 # t0 = x_start
    li $a1, 0 # t1 = y_start
    li $a2, 128 # t2 = x_end
    li $a3, 8 # t3 = y_end

    addi $sp, $sp, -4 # preserve ra of draw_walls
    sw $ra, 0($sp)

    li $t0, 0x555555 # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_walls
    addi $sp, $sp, 4
    # -----------------------------------  
    
    # -----------------------------------
    # Draw left wall
    li $a0, 0 # t0 = x_start
    li $a1, 8 # t1 = y_start
    li $a2, 4 # t2 = x_end
    li $a3, 128 # t3 = y_end

    addi $sp, $sp, -4 # preserve ra of draw_walls
    sw $ra, 0($sp)

    li $t0, 0x555555 # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_walls
    addi $sp, $sp, 4
    # -----------------------------------
    
    # -----------------------------------
    # Draw right wall
    li $a0, 124 # t0 = x_start
    li $a1, 8 # t1 = y_start
    li $a2, 128 # t2 = x_end
    li $a3, 128 # t3 = y_end

    addi $sp, $sp, -4 # preserve ra of draw_walls
    sw $ra, 0($sp)

    li $t0, 0x555555 # pass in color argument on stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rect
    
    lw $ra, 0($sp) # restore ra of draw_walls
    addi $sp, $sp, 4
    # -----------------------------------
    jr $ra
# ===================================


# ===================================
# draw_rect(x_start: int, y_start: int, x_end: int, y_end: int, color: int) -> None
# 
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
