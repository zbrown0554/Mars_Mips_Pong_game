##################
# Pong game
# by Zachary Brown
##################


############################################################################################################################
# To start go to Tools -> Bitmap
#   unit width:      1
#   unit height:     1
#   Display width:   512
#   Display height:  512
#   Base address:    0x10010000 (static data)
# Then connect to MIPS
# Next go to Tools -> Keyboard and Display MMIO Simulator
# Then connect to MIPS
# Finally go Run -> Assemble -> Run the current program
############################################################################################################################



# ---------
# Constants
# ---------

# Frame delay
.eqv FRAME_DELAY,	50000

# Sizes
.eqv SCREEN_WIDTH, 	512
.eqv SCREEN_HEIGHT, 	512
.eqv PADDLE_WIDTH, 	10
.eqv PADDLE_HEIGHT, 	60
.eqv BALL_SIZE, 	8

# Speeds
.eqv PADDLE_SPEED, 		15
.eqv BALL_SPEED_BASE_X,	4
.eqv BALL_SPEED_BASE_Y,	2
.eqv BALL_SPEED_X, 		3
.eqv BALL_SPEED_Y, 		2

# Starting positions
.eqv LEFT_PADDLE_X, 		40
.eqv LEFT_PADDLE_START_Y, 	226
.eqv RIGHT_PADDLE_X, 		462
.eqv RIGHT_PADDLE_START_Y, 	226
.eqv BALL_START_X, 		256
.eqv BALL_START_Y, 		256

# Boundaries
.eqv TOP_BOUND, 		0
.eqv BOTTOM_BOUND, 		452
.eqv BOTTOM_BOUND_BALL, 	500
.eqv LEFT_BOUND, 		0
.eqv RIGHT_BOUND, 		512

# Colors
.eqv BLACK, 	0x000000
.eqv WHITE, 	0xffffff



# ------------
# Data Section
# ------------
.data

frame_buffer: .space 1048576

# Paddle positions
left_paddle_y: .word LEFT_PADDLE_START_Y
right_paddle_y: .word RIGHT_PADDLE_START_Y

# Ball position and velocity
ball_x: .word BALL_START_X
ball_y: .word BALL_START_Y
ball_dx: .word BALL_SPEED_X
ball_dy: .word BALL_SPEED_Y



# -----------
# Text Section
# -----------
.text

main:
	# Initialization
	# --------------

	jal init_video
	jal clear_screen

	# Draw initial left paddle
	li $t0, WHITE
	li $a0, LEFT_PADDLE_X
	li $a1, LEFT_PADDLE_START_Y
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	# Draw initial right paddle
	li $t0, WHITE
	li $a0, RIGHT_PADDLE_X
	li $a1, RIGHT_PADDLE_START_Y
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	# Draw initial ball
	jal new_ball
	
	jal game_loop
	
	end_game:
		li $v0, 10
		syscall
	
	# Game Loop
	# ---------

game_loop:
	# Update ball
	jal update_ball
	
	# Frame delay
	li $t6, FRAME_DELAY
	delay_loop:
		addi $t6, $t6, -1
		bnez $t6, delay_loop
	
	# Poll keyboard ready bit
	lw $t0, 0xffff0000
	beqz $t0, no_key
	
	# Read input
	lw $t0, 0xffff0004
	j handle_keys

no_key:
	li $t0, 0

handle_keys:
	li $t1, 'w'
	beq $t0, $t1, left_up
	li $t1, 's'
	beq $t0, $t1, left_down
	li $t1, 'p'
	beq $t0, $t1, right_up
	li $t1, 'l'
	beq $t0, $t1, right_down
	li $t1, 'q'
	beq $t0, $t1, end_game
	j game_loop



# ----------------
# Paddle Functions
# ----------------

left_up:
	# Erase old paddle
	li $t0, BLACK
	la $s1, left_paddle_y
	lw $t3, 0($s1)
	li $a0, LEFT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	# Move paddle up
	lw $t3, 0($s1)
	addi $t3, $t3, -PADDLE_SPEED
	
	# Check if paddle above screen
	blt $t3, TOP_BOUND, clamp_top_left
	j store_left_y
	
clamp_top_left:
	li $t3, TOP_BOUND
	
store_left_y:
	sw $t3, 0($s1)

	# Redraw paddle
	li $t0, WHITE
	li $a0, LEFT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect
	j game_loop

left_down:
	# Erase old paddle
	li $t0, BLACK
	la $s1, left_paddle_y
	lw $t3, 0($s1)
	li $a0, LEFT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	# Move paddle down
	lw $t3, 0($s1)
	addi $t3, $t3, PADDLE_SPEED
	
	# Check if paddle below screen
	bgt $t3, BOTTOM_BOUND, clamp_bottom_left
	j store_left_y_down
	
clamp_bottom_left:
	li $t3, BOTTOM_BOUND
	
store_left_y_down:
	sw $t3, 0($s1)

	# Redraw paddle
	li $t0, WHITE
	li $a0, LEFT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect
	j game_loop

right_up:
	# Erase old paddle
	li $t0, BLACK
	la $s1, right_paddle_y
	lw $t3, 0($s1)
	li $a0, RIGHT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	# Move paddle up
	lw $t3, 0($s1)
	addi $t3, $t3, -PADDLE_SPEED
	
	# Check if paddle above screen
	blt $t3, TOP_BOUND, clamp_top_right
	j store_right_y
	
clamp_top_right:
	li $t3, TOP_BOUND
	
store_right_y:
	sw $t3, 0($s1)

	# Redraw paddle
	li $t0, WHITE
	li $a0, RIGHT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect
	j game_loop

right_down:
	# Erase old paddle
	li $t0, BLACK
	la $s1, right_paddle_y
	lw $t3, 0($s1)
	li $a0, RIGHT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	# Move paddle down
	lw $t3, 0($s1)
	addi $t3, $t3, PADDLE_SPEED
	
	# Check if paddle below screen
	bgt $t3, BOTTOM_BOUND, clamp_bottom_right
	j store_right_y_down
	
clamp_bottom_right:
	li $t3, BOTTOM_BOUND
	
store_right_y_down:
	sw $t3, 0($s1)

	# Redraw paddle
	li $t0, WHITE
	li $a0, RIGHT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect
	j game_loop



# --------------
# Ball Functions
# --------------

new_ball:
	# Random x velocity
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall  
	addi $t2, $a0, BALL_SPEED_BASE_X
	# Random sign
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall 
	beq $a0, $zero, new_ball_dx
	sub $t2, $zero, $t2  
new_ball_dx:
	la $t0, ball_dx
	sw $t2, 0($t0)

	# Random y velocity
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	addi $t2, $a0, BALL_SPEED_BASE_Y
	# Random sign
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	beq $a0, $zero, new_ball_dy
	sub $t2, $zero, $t2
new_ball_dy:
	la $t0, ball_dy
	sw $t2, 0($t0)

	# Reset position
	la $t0, ball_x
	li $t1, BALL_START_X
	sw $t1, 0($t0)

	la $t0, ball_y
	li $t1, BALL_START_Y
	sw $t1, 0($t0)

	jr $ra

update_ball:
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# Erase old ball
	la $t4, ball_x
	lw $a0, 0($t4)
	la $t5, ball_y
	lw $a1, 0($t5)
	li $t0, BLACK
	move $t1, $t0
	li $a2, BALL_SIZE
	li $a3, BALL_SIZE
	jal draw_rect

	# Update position
	la $t0, ball_x
	lw $t2, 0($t0)
	la $t1, ball_dx
	lw $t3, 0($t1)
	add $t2, $t2, $t3
	sw $t2, 0($t0)

	la $t0, ball_y
	lw $t2, 0($t0)
	la $t1, ball_dy
	lw $t3, 0($t1)
	add $t2, $t2, $t3
	sw $t2, 0($t0)

	# Top/Bottom bounce
	la $t0, ball_y
	lw $t2, 0($t0)
	blt $t2, TOP_BOUND, wall_bounce
	bgt $t2, BOTTOM_BOUND_BALL, wall_bounce
	j continue_ball_update
wall_bounce:
	la $t1, ball_dy
	lw $t2, 0($t1)
	sub $t2, $zero, $t2
	sw $t2, 0($t1)
continue_ball_update:

	# Check if paddle hit left/right wall
	la $t0, ball_x
	lw $t1, 0($t0)
	li $t2, 0
	blt $t1, $t2, reset_ball
	add $t3, $t1, BALL_SIZE
	li $t2, SCREEN_WIDTH
	bgt $t3, $t2, reset_ball

	# Left paddle bounce
	la $t0, ball_x
	lw $t1, 0($t0)
	add $t2, $t1, BALL_SIZE
	li $t3, LEFT_PADDLE_X
	bge $t2, $t3, check_left_horiz
	j check_right
check_left_horiz:
	li $t4, LEFT_PADDLE_X
	addi $t4, $t4, PADDLE_WIDTH
	ble $t1, $t4, check_left_vert
	j check_right
check_left_vert:
	la $t5, ball_y
	lw $t5, 0($t5)
	add $t6, $t5, BALL_SIZE
	la $t7, left_paddle_y
	lw $t7, 0($t7)
	blt $t6, $t7, check_right
	add $t8, $t7, PADDLE_HEIGHT
	bge $t5, $t8, check_right

	la $t8, ball_dx
	lw $t7, 0($t8)
	sub $t7, $zero, $t7
	sw $t7, 0($t8)
	addi $t7, $t4, 1
	la $t8, ball_x
	sw $t7, 0($t8)
	j draw_ball

	# Right paddle bounce
check_right:
	la $t0, ball_x
	lw $t1, 0($t0)
	add $t2, $t1, BALL_SIZE
	li $t3, RIGHT_PADDLE_X
	ble $t2, $t3, draw_ball
	
check_right_horiz:
	li $t4, RIGHT_PADDLE_X
	addi $t4, $t4, PADDLE_WIDTH
	bge $t1, $t4, draw_ball
	
check_right_vert:
	la $t5, ball_y
	lw $t5, 0($t5)
	add $t6, $t5, BALL_SIZE
	la $t7, right_paddle_y
	lw $t7, 0($t7)
	blt $t6, $t7, draw_ball
	add $t8, $t7, PADDLE_HEIGHT
	bge $t5, $t8, draw_ball

	# Right paddle bounce
	la $t8, ball_dx
	lw $t7, 0($t8)
	sub $t7, $zero, $t7
	sw $t7, 0($t8)
	addi $t7, $t3, -BALL_SIZE
	addi $t7, $t7, -1
	la $t8, ball_x
	sw $t7, 0($t8)
	j draw_ball

reset_ball:
	jal new_ball
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

draw_ball:
	# Draw ball at updated position
	li $t0, WHITE
	la $t4, ball_x
	lw $a0, 0($t4)
	la $t5, ball_y
	lw $a1, 0($t5)
	li $a2, BALL_SIZE
	li $a3, BALL_SIZE
	jal draw_rect

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra



# ---------------
# Other Functions
# ---------------

init_video:
	la $s0, frame_buffer
	jr $ra

clear_screen:
	li $t0, BLACK
	move $t1, $s0
	addi $t2, $s0, 1048576
	
clearLoop:
	sw $t0, 0($t1)
	addi $t1, $t1, 4
	bge $t1, $t2, clearEnd
	j clearLoop
	
clearEnd:
	jr $ra

draw_rect:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $t1, 0
row_loop:
	beq $t1, $a3, draw_rect_done
	add $t2, $a1, $t1
	li $t3, 0
col_loop:
	beq $t3, $a2, next_row
	add $t4, $a0, $t3
	mul $t6, $t2, SCREEN_WIDTH
	add $t6, $t6, $t4
	sll $t6, $t6, 2
	add $t5, $s0, $t6
	sw $t0, 0($t5)
	addi $t3, $t3, 1
	j col_loop
next_row:
	addi $t1, $t1, 1
	j row_loop
draw_rect_done:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
