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
    

# void draw_walls()
# 
# Draw the three walls
draw_walls:
    # ====================================
    # Draw top wall
    li $t0, 0 # t0 = x_start
    li $t1, 0 # t1 = y_start
    li $t2, 128 # t2 = x_end
    li $t3, 8 # t3 = y_end
    
    draw_top_loop_x:
        beq $t0, $t2, draw_top_loop_x_end
        li $t1, 0
        draw_top_loop_y:
            beq $t1, $t3, draw_top_loop_y_end
            
            sll $t5, $t0, 0 # t5 = t0 * 4
            sll $t6, $t1, 5 # t6 = t2 * 128
            
            lw $t4, ADDR_DSPL
            add $t4, $t4, $t5
            add $t4, $t4, $t6
            li $t7, 0x555555
            sw $t7, 0($t4)
            
            addi $t1, $t1, 4
            j draw_top_loop_y
        draw_top_loop_y_end:
            addi $t0, $t0, 4
            j draw_top_loop_x
    draw_top_loop_x_end:
    # ====================================  
    
    # ====================================
    # Draw top wall
    li $t0, 0 # t0 = x_start
    li $t1, 8 # t1 = y_start
    li $t2, 4 # t2 = x_end
    li $t3, 128 # t3 = y_end
    
    draw_left_loop_x:
        beq $t0, $t2, draw_left_loop_x_end
        li $t1, 0
        draw_left_loop_y:
            beq $t1, $t3, draw_left_loop_y_end
            
            sll $t5, $t0, 0 # t5 = t0 * 4
            sll $t6, $t1, 5 # t6 = t2 * 128
            
            lw $t4, ADDR_DSPL
            add $t4, $t4, $t5
            add $t4, $t4, $t6
            li $t7, 0x555555
            sw $t7, 0($t4)
            
            addi $t1, $t1, 4
            j draw_left_loop_y
        draw_left_loop_y_end:
            addi $t0, $t0, 4
            j draw_left_loop_x
    draw_left_loop_x_end:
    # ====================================
    
    # ====================================
    # Draw right wall
    li $t0, 124 # t0 = x_start
    li $t1, 8 # t1 = y_start
    li $t2, 128 # t2 = x_end
    li $t3, 128 # t3 = y_end
    
    draw_right_loop_x:
        beq $t0, $t2, draw_right_loop_x_end
        li $t1, 0
        draw_right_loop_y:
            beq $t1, $t3, draw_right_loop_y_end
            
            sll $t5, $t0, 0 # t5 = t0 * 4
            sll $t6, $t1, 5 # t6 = t2 * 128
            
            lw $t4, ADDR_DSPL
            add $t4, $t4, $t5
            add $t4, $t4, $t6
            li $t7, 0x555555
            sw $t7, 0($t4)
            
            addi $t1, $t1, 4
            j draw_right_loop_y
        draw_right_loop_y_end:
            addi $t0, $t0, 4
            j draw_right_loop_x
    draw_right_loop_x_end:
        jr $ra
    # ====================================
    