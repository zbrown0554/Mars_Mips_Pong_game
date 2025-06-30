##################
# Pong game
# by Zachary Brown
##################


############################################################################################################################
# To start go to Tools -> Bitmap
#   unit width      1
#   unit height     1
#   Display width   512
#   Display height  512
#   Base address    0x10010000 (static data)
# Then connect to MIPS
# Next go to Tools -> Keyboard and Display MMIO Simulator
# Then connect to MIPS
############################################################################################################################



# ---------
# Constants
# ---------

# Sizes
.eqv SCREEN_WIDTH,	512
.eqv SCREEN_HEIGHT,	512
.eqv PADDLE_WIDTH,	10
.eqv PADDLE_HEIGHT,	60
.eqv BALL_SIZE,		8

# Speeds
.eqv PADDLE_SPEED,	8
.eqv BALL_SPEED_X,	3
.eqv BALL_SPEED_Y,	2

# Starting positions
.eqv LEFT_PADDLE_X,		20
.eqv LEFT_PADDLE_START_Y,	226
.eqv RIGHT_PADDLE_X,		486
.eqv RIGHT_PADDLE_START_Y,	226
.eqv BALL_START_X,		256
.eqv BALL_START_Y,		256

# Boundaries
.eqv TOP_BOUND,		0
.eqv BOTTOM_BOUND,	452
.eqv LEFT_BOUND,	0
.eqv RIGHT_BOUND,	504

# Colors
.eqv BLACK	0x000000
.eqv WHITE	0xffffff

# ------------
# Data Section
# ------------
.data

frame_buffer:	 .space 1048576

# Paddle positions
left_paddle_y:  .word LEFT_PADDLE_START_Y
right_paddle_y: .word RIGHT_PADDLE_START_Y

# Ball position and velocity
ball_x:		 .word BALL_START_X
ball_y:		 .word BALL_START_Y
ball_dx:	 .word BALL_SPEED_X
ball_dy:	 .word BALL_SPEED_Y



# -----------
# Text Section
# -----------
.text

main:
    
	# Initialization
	# --------------
    
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	jal init_video
	jal clear_screen

	# Draw initial left paddle
	li $t0, WHITE
	la $s1, left_paddle_y
	lw $t3, 0($s1)
	li $a0, LEFT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	# Draw initial right paddle
	la $s1, right_paddle_y
	lw $t3, 0($s1)
	li $a0, RIGHT_PADDLE_X
	move $a1, $t3
	li $a2, PADDLE_WIDTH
	li $a3, PADDLE_HEIGHT
	jal draw_rect

	jal game_loop

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

game_loop:

	# Poll keyboard ready bit
	lw $t0, 0xffff0000
	beqz $t0, no_key
    
	# Read input
	lw $t0, 0xffff0004
	j handle_keys

no_key:
	li   $t0, 0

handle_keys:
	li $t1, 'w'
	beq $t0, $t1, left_up
	li $t1, 's'
	beq $t0, $t1, left_down
	li $t1, 'o'
	beq $t0, $t1, right_up
	li $t1, 'l'
	beq $t0, $t1, right_down
	j game_loop

# ---------------
# Paddle Routines
# ---------------

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
	sub $t3, $t3, PADDLE_SPEED   
    
	# Check if paddle would go above screen
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
	add $t3, $t3, PADDLE_SPEED
    
	# Check if paddle would go below screen
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
	sub $t3, $t3, PADDLE_SPEED
    
	# Check if paddle would go above screen
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
	add $t3, $t3, PADDLE_SPEED
    
	# Check if paddle would go below screen
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



# -------------------
# Supporting Routines
# -------------------

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
	addiu $sp, $sp, -4
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
	addiu $t3, $t3, 1
	j col_loop
next_row:
	addiu $t1, $t1, 1
	j row_loop
draw_rect_done:
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	