#####################################################################################
#
# CSCB58 Winter 2022 Assembly Final Project 				 
# University of Toronto, Scarborough 					
# Student: Awais Aziz,  1006103681,   azizawai, awais.aziz@mail.utoronto.ca 					#
#									
# BitMap Display Configuration:							
#  - Unit width in pixels: 8								
#  - Unit height in pixels: 8						
#  - Display width in pixels: 256						
#  - Display height in pixels: 256					
#  - Base address for Display: 0x1000800 ($gp)
#		
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# - Milestone 1 -- Basic Graphic
# - Milestone 2 -- Basic Control
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health/Score
# 2. Fail Condition
# 3. Moving Objects
# 4. Moving platform
# 5. Jump Thrice
# 									
# Link to video demonstration for final submission:			
#	https://www.youtube.com/watch?v=onQcB3-JdNU
#
# Are you OK with us sharing the video with people outside course staff? - Yes	
# - yes / no / yes, and please share this project github link as well!
#	
#
# Any additional information that the TA needs to know:	Thanks for a wonderful Semester			
#####################################################################################


.eqv 	BASE_ADDRESS 	0x10008000
.eqv	RED		0x00ff0000
.eqv	GREEN		0x0000ff00
.eqv	YELLOW		0x00FFFF00
.eqv	BLACK		0x00000000
.eqv	WHITE		0x00ffffff
.eqv	BROWN		0x00A52A2A

.data
PLAYER_CENTER:	.word	0:3	# [player's central pixel number, X coordinate, Y coordinate]
OBJ1_CENTER:	.word	0:3	# [obj1's central pixel number, X coordinate, Y coordinate]
OBJ2_CENTER:	.word	0:3	# [obj2's central pixel number, X coordinate, Y coordinate]
OBJ3_CENTER:	.word	0:3	# [obj3's central pixel number, X coordinate, Y coordinate]
OBJ4_CENTER:	.word	0:3	# [obj4's central pixel number, X coordinate, Y coordinate]
OBJ5_CENTER:	.word	0:3	# [obj5's central pixel number, X coordinate, Y coordinate]

ENE1_CENTER:	.word	0:3	# [obj3's central pixel number, X coordinate, Y coordinate]
ENE2_CENTER:	.word	0:3	# [obj3's central pixel number, X coordinate, Y coordinate]

PLAYER_PIXELS:	.word	0:6	# Contains all pixel values of the player

.text
.globl main
main: 
	jal INIT_DIS	# Initialize the display
	li $s4, 3	# $s4 <- Number of lives
	li $s2, 2	# $s2 <- Number of Jumps
	li $s7, 80	# $s7 <- Default Speed
	li $s6, 200	# $s6 <- Default gravity

main_loop:
	li $v0, 32			# Sleep here
	move $a0, $s7
	syscall

	# PART I: CHECK FOR INPUT
	li $t9, 0xffff0000		# $t9 = address where key pressed boolean stored	
	lw $t8, 0($t9)			# Checking if input given
	beq $t8, 1, key_pressed	# Key was pressed
	j move_objects_ene

key_pressed:
	# PART II: MOVE THE PLAYER (OR RESTART GAME)
	lw $a0, 4($t9)			# Load the key that was pressed as an argument
	bgt $s6, 50, dec
	jal MOVE_PLAYER			# Call helper function that handles player movement

move_objects_ene:
	jal CONST_MOVE	# Constant move of gravity

	# PART III: MOVING THE OBJECTS (Plat Form)
	jal MOVE_OBJ1
	jal MOVE_OBJ2
	jal MOVE_OBJ3
	jal MOVE_OBJ4
	jal MOVE_OBJ5

	# Moving Enemy
	jal MOVE_ENE1
	jal MOVE_ENE2

	# PART IV: CHECKING FOR COLLISIONS
	la $t0, PLAYER_PIXELS		# Initialize the PLAYER_PIXELS array
	la $t1, PLAYER_CENTER
	lw $t1, 0($t1)
	sw $t1, 0($t0)
	addi $t2, $t1, 4
	sw $t2, 4($t0)
	addi $t2, $t1, 4
	sw $t2, 8($t0)
	addi $t2, $t1, 124
	sw $t2, 12($t0)
	addi $t2, $t1, 252
	sw $t2, 16($t0)
	addi $t2, $t1, 380
	sw $t2, 20($t0)

	jal COLL_LINE		# Call helper function that will check for collisions
	bgtz $v0, coll_occur
	jal COLL_ENE1		# Call helper function that will check for collisions
	bgtz $v0, coll_occur
	jal COLL_ENE2		# Call helper function that will check for collisions
	bgtz $v0, coll_occur
	j main_loop

coll_occur:
	#PART V: COLLISION OCCURRED
	li $s7, 82		# Change game speed back to default
	li $s6, 200
	addi $s4, $s4, -1, 	# Decrease life by one
	beqz $s4, game_over	# Number of lives == 0, so game over

	li $v0, 32		# Wait .2 seconds
	li, $a0, 200
	syscall	
	move $a0, $s4		# Clear a life from bitmap
	jal CLEAR_LIFE
	li $v0, 32		# Wait .2 seconds
	li, $a0, 200
	syscall	
	# Clear the player and place at start
	li $t5, 1672		# Ship's center pixel number in bytes
	move $a1, $t5
	la $t6, PLAYER_CENTER	# Update the PLAYER_CENTER array
	sw $t5, 0($t6)
	li $t5, 13
	sw $t5, 4($t6)
	li $t5, 2
	sw $t5, 8($t6)
	jal DRAW_PLAYER
	li $v0, 32		# Wait .5 seconds
	li, $a0, 500
	syscall

	jal CLEAR_OBJ1
	jal CLEAR_OBJ2
	jal CLEAR_OBJ3
	jal CLEAR_OBJ4
	jal CLEAR_OBJ5

	jal CLEAR_ENE1
	jal CLEAR_ENE2

	jal CREATE_OBJ1
	jal CREATE_OBJ2
	jal CREATE_OBJ3
	jal CREATE_OBJ4
	jal CREATE_OBJ5

	jal CREATE_ENE1
	jal CREATE_ENE2
	j main_loop

game_over:
	# PART VI: GAME OVER
	# Clear player, objects, HP, green line
	jal CLEAR_PLAYER
	jal CLEAR_OBJ1
	jal CLEAR_OBJ2
	jal CLEAR_OBJ3
	jal CLEAR_OBJ4
	jal CLEAR_OBJ5

	jal CLEAR_ENE1
	jal CLEAR_ENE2

	jal CLEAR_HP
	jal CLEAR_LINE
	move $a0, $s4
	jal CLEAR_LIFE

	# Write game over & wait 5 seconds
	li $a0, WHITE
	jal SKULL_DISPLAY
	li $v0, 32		
	li, $a0, 5000
	syscall	

	# Restart the game
	li $a0, BLACK		
	jal SKULL_DISPLAY
	j main

quit_game: # terminate the program gracefully
	li $v0, 10
	syscall

dec:
	addi $s6, $s6, -1	# Increase speed of game
	jal MOVE_PLAYER		# Call helper function that handles player movement
	j move_objects_ene

INIT_DIS: # void IN_DIS()
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	li $t3, GREEN
	li $t2, YELLOW

line:	# PART I: Creating Yellow line
	move $t4, $t0		# $t4 = (0,0)
	addi $t4, $t4, 3328	# $t4 = (26,0), start for blue line
	addi $t5, $t4, 128	# $t5 = address for end condition -> (27, 0)

loop0:
	beq $t4, $t5, player	# Continue to loop until last pixel reached
	sw $t2, 0($t4)	# Make it Yellow color
	addi $t4, $t4, 4	# Go to next pixel to the right
	j loop0	# Jump back to loop start

player:	# PART II: Creating the player
	move $t4, $t0		# $t4 = (0,0)
	li $t5, 1672		# Ship's center pixel number in bytes
	add $t4, $t4, $t5	# $t4 = (13,2), center of player

	la $t6, PLAYER_CENTER	# Update the PLAYER_CENTER array
	sw $t5, 0($t6)
	li $t5, 13
	sw $t5, 4($t6)
	li $t5, 2
	sw $t5, 8($t6)

	sw $t3, 0($t4)		# Make players pixel's blue
	sw $t3, 4($t4)
	sw $t3, 8($t4)
	sw $t3, 132($t4)	# (14, 3)
	sw $t3, 260($t4)
	sw $t3, 388($t4)

	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)

	jal CREATE_OBJ1
	jal CREATE_OBJ2
	jal CREATE_OBJ3
	jal CREATE_OBJ4
	jal CREATE_OBJ5

	jal CREATE_ENE1
	jal CREATE_ENE2

	# PART IV: Creating the number of lives
	jal CREATE_HP

	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra

CLEAR_LINE: # void CLEAR_LINE()
	li $t0, BASE_ADDRESS
	li $t1, BLACK

	addi $t2, $t0, 3328	# $t2 = (26,0), start for green line
	addi $t3, $t2, 128	# $t3 = address for end condition -> (27, 0)

loop9:
	beq $t2, $t3, return0	# Continue to loop until last pixel reached
	sw $t1, 0($t2)		# Make it black color (Clear it)
	addi $t2, $t2, 4	# Go to next pixel to the right
	j loop9			# Jump back to loop start

SKULL_DISPLAY: # void SJULL_DIPLAY($a0 <- color to draw in)
	li $t0, BASE_ADDRESS
	move $t1, $a0

	addi $t2, $t0, 1592	# First row
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)

	addi $t2, $t0, 1716	# Second row
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)
	sw $t1, 20($t2)
	sw $t1, 24($t2)

	addi $t2, $t0, 1840	# Third row
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)
	sw $t1, 20($t2)
	sw $t1, 24($t2)
	sw $t1, 28($t2)
	sw $t1, 32($t2)

	addi $t2, $t0, 1968	# Fourth row
	sw $t1, 0($t2)
	sw $t1, 8($t2)
	sw $t1, 16($t2)
	sw $t1, 24($t2)
	sw $t1, 32($t2)

	addi $t2, $t0, 2096	# Fifth row
	sw $t1, 0($t2)
	sw $t1, 16($t2)
	sw $t1, 32($t2)

	addi $t2, $t0, 2224	# Sixth row
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)
	sw $t1, 20($t2)
	sw $t1, 24($t2)
	sw $t1, 28($t2)
	sw $t1, 32($t2)

	addi $t2, $t0, 2356	# Seventh row
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 20($t2)
	sw $t1, 24($t2)

	addi $t2, $t0, 2488	# Eighth row
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)

	addi $t2, $t0, 2620	# Ninth row
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	jr $ra			# Jump back to caller

CONST_MOVE: 
	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)
	
	li $s0, 115
	move $a0, $s0	# Gravity move
	jal MOVE_PLAYER

	li $v0, 32	# Sleep here
	move $a0, $s6
	syscall
	lw $ra, 0($sp)		# Load the caller's return address
	addi $sp, $sp, 4
	jr $ra			# Jump back to caller

MOVE_PLAYER: # void MOVE_PLAYER(key pressed -> $a0)
	# $t0 = Ship Center in bytes  $t1 = X coordinate  $t2 = Y coordinate  $t3 = Load Color
	# $t9 = address of PLAYER_CENTER
	la $t9, PLAYER_CENTER		
	lw $t0, 0($t9)		# Ship's center pixel number in bytes
	lw $t1, 4($t9)		# Ship's center x coordinate
	lw $t2, 8($t9)		# Ship's center y coordinate

	beq $a0, 119, gravity_up		# Up = w = 119
	beq $a0, 97, player_left 		# Left = a = 97
	beq $a0, 100, player_right		# Right = d = 100
	beq $a0, 115, gravity_down	# Down = s = 115
	beq $a0, 112, restart_game	# Restart = p = 112
	beq $a0, 113, quit_game		# Quit = q = 113
	jr $ra		# Invalid key pressed, jump back to caller

gravity_up:
	
	bltz $s2, return0	# Jump only 3 times land on a platform only then restore jump
	addi $s2, $s2, -1	# reduce number of jump
	
	addi $t4, $t1, -3	# $t4 = x - 3
	bltz $t4, return0	# Cannot move up
	# Can move up
	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)
	
	addi $sp, $sp, -4	# Store $t0
	sw $t0, 0($sp)
	
	jal CLEAR_PLAYER		# Call to clear current player's position
	
	lw $t0, 0($sp)		# Restore $t0
	addi $sp, $sp, 4
	
	addi $t0, $t0, -384	# $t0 = new pixel center for the player
	move $a1, $t0		# Call to move to new player's position

	addi $sp, $sp, -12	# Store $t0, $t4, $t9
	sw $t0, 0($sp)
	sw $t4, 4($sp)
	sw $t9, 8($sp)

	jal DRAW_PLAYER

	lw $t0, 0($sp)		# Restore $t0, $t4, $t9
	lw $t4, 4($sp)
	lw $t9, 8($sp)
	addi $sp, $sp, 12
	
	sw $t0, 0($t9)		# Update the PLAYER_CENTER array
	sw $t4, 4($t9)	
	lw $ra, 0($sp)		# Load the caller's return address
	addi $sp, $sp, 4
	jr $ra			# Jump back to caller
	
gravity_down:
	# $s0 = Pixel below (character T) check brown $t6 = load brown
	la $s0, PLAYER_CENTER
	lw $s0, 0($s0)	# Ship's center pixel number in bytes
	addi $s0, $s0, 516
	li $t6, BASE_ADDRESS
	add $s0, $s0, $t6
	lw $s0, 0($s0)
	li $t6, BROWN

	beq $s0, $t6, return_down	# If brown (No Gravity)

	addi $t4, $t1, 1	# $t4 = x + 1
	bgt $t4, 28, return0	# Cannot move up
	# Can move up
	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)
	addi $sp, $sp, -4	# Store $t0
	sw $t0, 0($sp)

	jal CLEAR_PLAYER		# Call to clear current player's position

	lw $t0, 0($sp)		# Restore $t0
	addi $sp, $sp, 4

	addi $t0, $t0, 128	# $t0 = new pixel center for the player
	move $a1, $t0		# Call to move to new player's position

	addi $sp, $sp, -12	# Store $t0, $t4, $t9
	sw $t0, 0($sp)
	sw $t4, 4($sp)
	sw $t9, 8($sp)

	jal DRAW_PLAYER

	lw $t0, 0($sp)		# Restore $t0, $t4, $t9
	lw $t4, 4($sp)
	lw $t9, 8($sp)
	addi $sp, $sp, 12

	sw $t0, 0($t9)		# Update the PLAYER_CENTER array
	sw $t4, 4($t9)	
	lw $ra, 0($sp)		# Load the caller's return address
	addi $sp, $sp, 4
	jr $ra			# Jump back to caller

player_left:
	addi $t4, $t2, -1	# $t4 = y - 1
	bltz $t4, return0	# Cannot move left
	# Can move left
	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	addi $sp, $sp, -4	# Store $t0
	sw $t0, 0($sp)

	jal CLEAR_PLAYER		# Call to clear current player's position

	lw $t0, 0($sp)		# Restore $t0
	addi $sp, $sp, 4

	addi $t0, $t0, -4	# $t0 = new pixel center for the player
	move $a1, $t0		# Call to move to new player's position

	addi $sp, $sp, -12	# Store $t0, $t4, $t9
	sw $t0, 0($sp)
	sw $t4, 4($sp)
	sw $t9, 8($sp)

	jal DRAW_PLAYER

	lw $t0, 0($sp)		# Restore $t0, $t4, $t9
	lw $t4, 4($sp)
	lw $t9, 8($sp)
	addi $sp, $sp, 12

	sw $t0, 0($t9)		# Update the PLAYER_CENTER array
	sw $t4, 8($t9)
	lw $ra, 0($sp)		# Load the caller's return address
	addi $sp, $sp, 4
	jr $ra			# Jump back to caller

player_right:
	addi $t4, $t2, 1	# $t4 = y + 1
	bgt $t4, 29, return0	# Cannot move left
	# Can move left
	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	addi $sp, $sp, -4	# Store $t0
	sw $t0, 0($sp)

	jal CLEAR_PLAYER		# Call to clear current player's position

	lw $t0, 0($sp)		# Restore $t0
	addi $sp, $sp, 4

	addi $t0, $t0, 4	# $t0 = new pixel center for the player
	move $a1, $t0		# Call to move to new player's position

	addi $sp, $sp, -12	# Store $t0, $t4, $t9
	sw $t0, 0($sp)
	sw $t4, 4($sp)
	sw $t9, 8($sp)

	jal DRAW_PLAYER

	lw $t0, 0($sp)		# Restore $t0, $t4, $t9
	lw $t4, 4($sp)
	lw $t9, 8($sp)
	addi $sp, $sp, 12

	sw $t0, 0($t9)		# Update the PLAYER_CENTER array
	sw $t4, 8($t9)
	lw $ra, 0($sp)		# Load the caller's return address
	addi $sp, $sp, 4
	jr $ra			# Jump back to caller

restart_game:
	# Clear player and objects
	jal CLEAR_PLAYER
	jal CLEAR_OBJ1
	jal CLEAR_OBJ2
	jal CLEAR_OBJ3
	jal CLEAR_OBJ4
	jal CLEAR_OBJ5
	jal CLEAR_ENE1
	jal CLEAR_ENE2
	j main

return_down:
	li $s2, 2
return0: 
	jr $ra			# Return back to caller

DRAW_PLAYER: # void DRAW_PLAYER(pixel number -> $a1)
	# $t0 = GREEN  $t1 = BASE_ADDRESS  $t3 = address of player center
	li $t0, GREEN		# Get the green color
	li $t1, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t1, $a1	# Get the address of the player's center

	sw $t0, 0($t3)		# Make players pixel's green
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	sw $t0, 132($t3)
	sw $t0, 260($t3)
	sw $t0, 388($t3)
	jr $ra			# Jump back to caller

CLEAR_PLAYER: # void CLEAR_PLAYER(), center of player stored in PLAYER_CENTER
	# $t0 = BLACK  $t1 = Ship Center in bytes  $t2 = BASE ADDRESS  $t3 = address of player center
	li $t0, BLACK		# Get the black color
	la $t1, PLAYER_CENTER	# Get the pixel number for player center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the player's center

	sw $t0, 0($t3)		# Make players pixel's black (clearing it)
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	sw $t0, 132($t3)
	sw $t0, 260($t3)
	sw $t0, 388($t3)
	jr $ra			# Jump back to caller

CREATE_HP: # void CREATE_HP()
	li $t0, BASE_ADDRESS
	li $t1, YELLOW
	
	# Write the H
	addi $t2, $t0, 3588	# H starts at (28,2)
	sw $t1, 0($t2)
	sw $t1, 8($t2)
	sw $t1, 128($t2)
	sw $t1, 132($t2)
	sw $t1, 136($t2)
	sw $t1, 256($t2)
	sw $t1, 264($t2)
	sw $t1, 384($t2)
	sw $t1, 392($t2)
	
	# Write the P
	addi $t2, $t0, 3604	# P starts at (28,6)
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 128($t2)
	sw $t1, 136($t2)
	sw $t1, 256($t2)
	sw $t1, 260($t2)
	sw $t1, 264($t2)
	sw $t1, 384($t2)
	
	# Write the colon
	addi $t2, $t0, 3748
	sw $t1, 0($t2)
	sw $t1, 256($t2)
	
	li $t1, GREEN
	# Write the health squares
	addi $t2, $t0, 3756	# 1st Health
	sw $t1, 0($t2)
	sw $t1, 128($t2)
	
	addi $t2, $t0, 3772	# 2nd Health
	sw $t1, 0($t2)
	sw $t1, 128($t2)
	
	addi $t2, $t0, 3788	# 3rd Health
	sw $t1, 0($t2)
	sw $t1, 128($t2)
	jr $ra			# Jump back to caller
	
CLEAR_HP: # void CLEAR_HP
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	
	# Clear the H
	addi $t2, $t0, 3588	# H starts at (28,2)
	sw $t1, 0($t2)
	sw $t1, 8($t2)
	sw $t1, 128($t2)
	sw $t1, 132($t2)
	sw $t1, 136($t2)
	sw $t1, 256($t2)
	sw $t1, 264($t2)
	sw $t1, 384($t2)
	sw $t1, 392($t2)
	
	# Clear the P
	addi $t2, $t0, 3604	# P starts at (28,6)
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 128($t2)
	sw $t1, 136($t2)
	sw $t1, 256($t2)
	sw $t1, 260($t2)
	sw $t1, 264($t2)
	sw $t1, 384($t2)
	
	# Clear the colon
	addi $t2, $t0, 3748
	sw $t1, 0($t2)
	sw $t1, 256($t2)
	jr $ra			# Jump back to caller
	
CLEAR_LIFE: # void CLEAR_LIFE($a0 <- Number of lives remaining)
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	# If a0 == 0, clear 1st life
	beqz $a0, clear_one
	# If a0 == 1, clear 2nd life
	li $t2, 1
	beq $a0, $t2, clear_two
	# a0 == 2, clear 3rd life
	addi $t2, $t0, 3788
	sw $t1, 0($t2)
	sw $t1, 128($t2)
	jr $ra			# Jump back to caller
	
clear_one:
	addi $t2, $t0, 3756	# 1st Health
	sw $t1, 0($t2)
	sw $t1, 128($t2)
	jr $ra
	
clear_two:
	addi $t2, $t0, 3772	# 2nd Health Square
	sw $t1, 0($t2)
	sw $t1, 128($t2)
	jr $ra

# All Objects

CREATE_OBJ1: # void CREATE_OBJ1(), creates at top right
	# ($t0, $t1) = (x, y)  $t2 = Center of OBJ1  $t3 = Address of OBJ1 array
	li $t0, 17		# x coordinate of center is 17
	li $t1, 2		# y coordinate of center is 2
	li $t2, 2184		# Pixel number in bytes is 2184

	la $t3, OBJ1_CENTER	# Update OBJ1_CENTER array
	sw $t2, 0($t3)
	sw $t0, 4($t3)	# x coordinate
	sw $t1, 8($t3)	# y coordinate

	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)

	move $a0, $t2		# Function call to draw the obstacle
	jal DRAW_OBJ1

	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra

DRAW_OBJ1: # void DRAW_OBJ1(), $a0 = Pixel number of center
	# $t0 = BASE_ADDRESS  $t1 = Center of OBJ1 address  $t2 = BROWN
	li $t0, BASE_ADDRESS	# Initialize the registers
	add $t1, $t0, $a0
	li $t2, BROWN
	
	sw $t2, 0($t1)		# Make OBJ1's pixels brown
	sw $t2, 4($t1)
	sw $t2, 8($t1)
	sw $t2, 12($t1)
	sw $t2, 16($t1)
	jr $ra			# Jump back to caller

CLEAR_OBJ1: # void CLEAR_OBJ1(), center of OBJ1 stored in OBJ1_CENTER
	# $t0 = BLACK  $t1 = OBJ1 Center in bytes  $t2 = BASE ADDRESS $t3 = address of OBJ1 center
	li $t0, BLACK		# Get the black color
	la $t1, OBJ1_CENTER	# Get the pixel number for object center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the object's center
	
	sw $t0, 0($t3)		# Make OBJ1's pixels black (clearing it)
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	sw $t0, 12($t3)
	sw $t0, 16($t3)
	jr $ra			# Jump back to caller

MOVE_OBJ1: # void MOVE_OBJ1()
	# $t0 = address of OBJ1_CENTER  $t1 = OBJ1 center pixel number  $t2 = BASE address
	# $t3 = Y coordinate

	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	la $t0, OBJ1_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate

	bltz $t3, recreate_OBJ1

	# Can move left
	addi $t1, $t1, -4
	addi $t3, $t3, -1
	
	li $t4, BROWN		# Get the black color
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t5, $t2, $t1	# Get the address of the object's center
	
	sw $t4, 0($t5)		# Make OBJ1's pixels black (clearing it)
	li $t4, BLACK		# Get the brown color
	sw $t4, 20($t5)

	sw $t1, 0($t0)		# Update the OBJ1_CENTER array
	sw $t3, 8($t0)

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

recreate_OBJ1: # $t4 = random number generated $t5 = new center pixel
	jal CLEAR_OBJ1		# Function call to clear OBJ1 from the screen
	
	la $t0, OBJ1_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate
	
	li $v0, 42		# Produce random number between [0,2] -> $t4
	li $a0, 0
	li $a1, 4
	syscall
	move $t4, $a0

	li $t5, 27	# column (Y coordinate)
	sw $t5, 8($t0)	# Y coordinate	
	addi $t4, $t4, 17
	sw $t4, 4($t0) 	# Store $t4 right away: X coordinate

	mul $t4, $t4, 32
	add $t5, $t5, $t4
	sll $t5, $t5, 2
	sw $t5, 0($t0)	# center pixel
	
	move $a0, $t5
	jal DRAW_OBJ1		# Function call to recreate OBJ1 on screen

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

CREATE_OBJ2: # void CREATE_OBJ2(), creates at top right
	# ($t0, $t1) = (x, y)  $t2 = Center of OBJ2  $t3 = Address of OBJ2 array
	li $t0, 15		# x coordinate of center is 15
	li $t1, 15		# y coordinate of center is 15
	li $t2, 1980		# Pixel number in bytes is 1980

	la $t3, OBJ2_CENTER	# Update OBJ2_CENTER array
	sw $t2, 0($t3)
	sw $t0, 4($t3)	# x coordinate
	sw $t1, 8($t3)	# y coordinate

	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)

	move $a0, $t2		# Function call to draw the obstacle
	jal DRAW_OBJ2

	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra

DRAW_OBJ2: # void DRAW_OBJ2(), $a0 = Pixel number of center
	# $t0 = BASE_ADDRESS  $t1 = Center of OBJ2 address  $t2 = BROWN
	li $t0, BASE_ADDRESS	# Initialize the registers
	add $t1, $t0, $a0
	li $t2, BROWN

	sw $t2, 0($t1)		# Make OBJ2's pixels brown
	sw $t2, 4($t1)
	sw $t2, 8($t1)
	sw $t2, 12($t1)
	sw $t2, 16($t1)
	jr $ra			# Jump back to caller

CLEAR_OBJ2: # void CLEAR_OBJ2(), center of OBJ2 stored in OBJ2_CENTER
	# $t0 = BLACK  $t1 = OBJ2 Center in bytes  $t2 = BASE ADDRESS $t3 = address of OBJ2 center
	li $t0, BLACK		# Get the black color
	la $t1, OBJ2_CENTER	# Get the pixel number for object center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the object's center

	sw $t0, 0($t3)		# Make OBJ2's pixels black (clearing it)
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	sw $t0, 12($t3)
	sw $t0, 16($t3)
	jr $ra			# Jump back to caller

MOVE_OBJ2: # void MOVE_OBJ2()
	# $t0 = address of OBJ2_CENTER  $t1 = OBJ2 center pixel number  $t2 = BASE address
	# $t3 = Y coordinate

	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	la $t0, OBJ2_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate

	bltz $t3, recreate_OBJ2

	# Can move left
	addi $t1, $t1, -4
	addi $t3, $t3, -1
	
	li $t4, BROWN		# Get the black color
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t5, $t2, $t1	# Get the address of the object's center
	
	sw $t4, 0($t5)		# Make OBJ1's pixels black (clearing it)
	li $t4, BLACK		# Get the brown color
	sw $t4, 20($t5)

	sw $t1, 0($t0)		# Update the OBJ1_CENTER array
	sw $t3, 8($t0)

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

recreate_OBJ2: # $t4 = random number generated $t5 = new center pixel
	jal CLEAR_OBJ2		# Function call to clear OBJ2 from the screen
	
	la $t0, OBJ2_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate
	
	li $v0, 42		# Produce random number between [0,2] -> $t4
	li $a0, 0
	li $a1, 3
	syscall
	move $t4, $a0
	addi $t4, $t4, -2
	
	li $v0, 42		# Produce random number between [0,26] -> $t5
	li $a0, 0
	li $a1, 27
	syscall
	
	move $t5, $a0	# column (Y coordinate)
	add $t5, $t5, $t4
	sw $t5, 8($t0)	# Y coordinate	
	addi $t4, $t4, 15
	sw $t4, 4($t0) 	# Store $t4 right away: X coordinate

	mul $t4, $t4, 32
	add $t5, $t5, $t4
	sll $t5, $t5, 2
	sw $t5, 0($t0)	# center pixel
	
	move $a0, $t5
	jal DRAW_OBJ2		# Function call to recreate OBJ2 on screen

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

CREATE_OBJ3: # void CREATE_OBJ3(), creates at top right
	# ($t0, $t1) = (x, y)  $t2 = Center of OBJ3  $t3 = Address of OBJ3 array
	li $t0, 12		# x coordinate of center is 12
	li $t1, 26		# y coordinate of center is 26
	li $t2, 1640		# Pixel number in bytes is 1640

	la $t3, OBJ3_CENTER	# Update OBJ3_CENTER array
	sw $t2, 0($t3)
	sw $t0, 4($t3)	# x coordinate
	sw $t1, 8($t3)	# y coordinate

	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)

	move $a0, $t2		# Function call to draw the obstacle
	jal DRAW_OBJ3

	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra

DRAW_OBJ3: # void DRAW_OBJ3(), $a0 = Pixel number of center
	# $t0 = BASE_ADDRESS  $t1 = Center of OBJ3 address  $t2 = BROWN
	li $t0, BASE_ADDRESS	# Initialize the registers
	add $t1, $t0, $a0
	li $t2, BROWN

	sw $t2, 0($t1)		# Make OBJ2's pixels brown
	sw $t2, 4($t1)
	sw $t2, 8($t1)
	sw $t2, 12($t1)
	sw $t2, 16($t1)
	jr $ra			# Jump back to caller

CLEAR_OBJ3: # void CLEAR_OBJ3(), center of OBJ3 stored in OBJ3_CENTER
	# $t0 = BLACK  $t1 = OBJ3 Center in bytes  $t2 = BASE ADDRESS $t3 = address of OBJ3 center
	li $t0, BLACK		# Get the black color
	la $t1, OBJ3_CENTER	# Get the pixel number for object center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the object's center

	sw $t0, 0($t3)		# Make OBJ3's pixels black (clearing it)
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	sw $t0, 12($t3)
	sw $t0, 16($t3)
	jr $ra			# Jump back to caller

MOVE_OBJ3: # void MOVE_OBJ3()
	# $t0 = address of OBJ3_CENTER  $t1 = OBJ3 center pixel number  $t2 = BASE address
	# $t3 = Y coordinate

	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	la $t0, OBJ3_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate

	bltz $t3, recreate_OBJ3

	# Can move left
	addi $t1, $t1, -4
	addi $t3, $t3, -1
	
	li $t4, BROWN		# Get the black color
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t5, $t2, $t1	# Get the address of the object's center
	
	sw $t4, 0($t5)		# Make OBJ1's pixels black (clearing it)
	li $t4, BLACK		# Get the brown color
	sw $t4, 20($t5)

	sw $t1, 0($t0)		# Update the OBJ1_CENTER array
	sw $t3, 8($t0)

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

recreate_OBJ3: # $t4 = random number generated $t5 = new center pixel
	jal CLEAR_OBJ3		# Function call to clear OBJ3 from the screen
	
	la $t0, OBJ3_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate
	
	li $v0, 42		# Produce random number between [0,2] -> $t4
	li $a0, 0
	li $a1, 3
	syscall
	move $t4, $a0
	addi $t4, $t4, -2

	li $t5, 26	# column (Y coordinate)
	add $t5, $t5, $t4
	sw $t5, 8($t0)	# Y coordinate	
	addi $t4, $t4, 12
	sw $t4, 4($t0) 	# Store $t4 right away: X coordinate

	mul $t4, $t4, 32
	add $t5, $t5, $t4
	sll $t5, $t5, 2
	sw $t5, 0($t0)	# center pixel
	
	move $a0, $t5
	jal DRAW_OBJ3		# Function call to recreate OBJ3 on screen

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

CREATE_OBJ4: # void CREATE_OBJ4(), creates at top right
	# ($t0, $t1) = (x, y)  $t2 = Center of OBJ4  $t3 = Address of OBJ4 array
	li $t0, 22		# x coordinate of center is 22
	li $t1, 25		# y coordinate of center is 25
	li $t2, 2916		# Pixel number in bytes is 2916

	la $t3, OBJ4_CENTER	# Update OBJ4_CENTER array
	sw $t2, 0($t3)
	sw $t0, 4($t3)	# x coordinate
	sw $t1, 8($t3)	# y coordinate

	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)

	move $a0, $t2		# Function call to draw the obstacle
	jal DRAW_OBJ4

	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra

DRAW_OBJ4: # void DRAW_OBJ4(), $a0 = Pixel number of center
	# $t0 = BASE_ADDRESS  $t1 = Center of OBJ4 address  $t2 = BROWN
	li $t0, BASE_ADDRESS	# Initialize the registers
	add $t1, $t0, $a0
	li $t2, BROWN

	sw $t2, 0($t1)		# Make OBJ4's pixels brown
	sw $t2, 4($t1)
	sw $t2, 8($t1)
	jr $ra			# Jump back to caller

CLEAR_OBJ4: # void CLEAR_OBJ4(), center of OBJ4 stored in OBJ4_CENTER
	# $t0 = BLACK  $t1 = OBJ4 Center in bytes  $t2 = BASE ADDRESS $t3 = address of OBJ4 center
	li $t0, BLACK		# Get the black color
	la $t1, OBJ4_CENTER	# Get the pixel number for object center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the object's center
	
	sw $t0, 0($t3)		# Make OBJ4's pixels black (clearing it)
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	jr $ra			# Jump back to caller

MOVE_OBJ4: # void MOVE_OBJ4()
	# $t0 = address of OBJ4_CENTER  $t1 = OBJ4 center pixel number  $t2 = BASE address
	# $t3 = Y coordinate

	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	la $t0, OBJ4_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate

	bltz $t3, recreate_OBJ4

	# Can move left
	addi $t1, $t1, -4
	addi $t3, $t3, -1
	
	li $t4, BROWN		# Get the black color
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t5, $t2, $t1	# Get the address of the object's center
	
	sw $t4, 0($t5)		# Make OBJ4's pixels black (clearing it)
	li $t4, BLACK		# Get the brown color
	sw $t4, 12($t5)

	sw $t1, 0($t0)		# Update the OBJ4_CENTER array
	sw $t3, 8($t0)

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

recreate_OBJ4: # $t4 = random number generated $t5 = new center pixel
	jal CLEAR_OBJ4		# Function call to clear OBJ4 from the screen

	la $t0, OBJ4_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate

	li $v0, 42		# Produce random number between [0,2] -> $t4
	li $a0, 0
	li $a1, 3
	syscall
	move $t4, $a0

	li $t5, 26	# column (Y coordinate)
	add $t5, $t5, $t4
	sw $t5, 8($t0)	# Y coordinate	
	addi $t4, $t4, 22
	sw $t4, 4($t0) 	# Store $t4 right away: X coordinate

	mul $t4, $t4, 32
	add $t5, $t5, $t4
	sll $t5, $t5, 2
	sw $t5, 0($t0)	# center pixel

	move $a0, $t5
	jal DRAW_OBJ4		# Function call to recreate OBJ4 on screen

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

CREATE_OBJ5: # void CREATE_OBJ5(), creates at top right
	# ($t0, $t1) = (x, y)  $t2 = Center of OBJ5  $t3 = Address of OBJ5 array
	li $t0, 8		# x coordinate of center is 8
	li $t1, 11		# y coordinate of center is 11
	li $t2, 1068		# Pixel number in bytes is 1068

	la $t3, OBJ5_CENTER	# Update OBJ5_CENTER array
	sw $t2, 0($t3)
	sw $t0, 4($t3)	# x coordinate
	sw $t1, 8($t3)	# y coordinate

	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)

	move $a0, $t2		# Function call to draw the obstacle
	jal DRAW_OBJ5

	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra

DRAW_OBJ5: # void DRAW_OBJ5(), $a0 = Pixel number of center
	# $t0 = BASE_ADDRESS  $t1 = Center of OBJ5 address  $t2 = BROWN
	li $t0, BASE_ADDRESS	# Initialize the registers
	add $t1, $t0, $a0
	li $t2, BROWN

	sw $t2, 0($t1)		# Make OBJ2's pixels brown
	sw $t2, 4($t1)
	sw $t2, 8($t1)
	sw $t2, 12($t1)
	jr $ra			# Jump back to caller

CLEAR_OBJ5: # void CLEAR_OBJ5(), center of OBJ5 stored in OBJ5_CENTER
	# $t0 = BLACK  $t1 = OBJ5 Center in bytes  $t2 = BASE ADDRESS $t3 = address of OBJ5 center
	li $t0, BLACK		# Get the black color
	la $t1, OBJ5_CENTER	# Get the pixel number for object center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the object's center

	sw $t0, 0($t3)		# Make OBJ5's pixels black (clearing it)
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	sw $t0, 12($t3)
	jr $ra			# Jump back to caller

MOVE_OBJ5: # void MOVE_OBJ5()
	# $t0 = address of OBJ5_CENTER  $t1 = OBJ5 center pixel number  $t2 = BASE address
	# $t3 = Y coordinate

	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	la $t0, OBJ5_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate

	bltz $t3, recreate_OBJ5

	# Can move left
	addi $t1, $t1, -4
	addi $t3, $t3, -1

	li $t4, BROWN		# Get the black color
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t5, $t2, $t1	# Get the address of the object's center

	sw $t4, 0($t5)		# Make OBJ1's pixels black (clearing it)
	li $t4, BLACK		# Get the brown color
	sw $t4, 16($t5)

	sw $t1, 0($t0)		# Update the OBJ1_CENTER array
	sw $t3, 8($t0)

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

recreate_OBJ5: # $t4 = random number generated $t5 = new center pixel
	jal CLEAR_OBJ5		# Function call to clear OBJ5 from the screen

	la $t0, OBJ5_CENTER	# Initialization
	lw $t1, 0($t0)	# center pixel
	lw $t3, 8($t0) 	# y coordinate

	li $v0, 42		# Produce random number between [0,2] -> $t4
	li $a0, 0
	li $a1, 3
	syscall
	move $t4, $a0
	addi $t4, $t4, -2

	li $t5, 28	# column (Y coordinate)
	add $t5, $t5, $t4
	sw $t5, 8($t0)	# Y coordinate	
	addi $t4, $t4, 8
	sw $t4, 4($t0) 	# Store $t4 right away: X coordinate

	mul $t4, $t4, 32
	add $t5, $t5, $t4
	sll $t5, $t5, 2
	sw $t5, 0($t0)	# center pixel

	move $a0, $t5
	jal DRAW_OBJ5		# Function call to recreate OBJ5 on screen

	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

# All Enemy

return_ENE:
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

CREATE_ENE1: # void CREATE_ENE1(), creates at (9,32)
	# ($t0, $t1) = (x, y)  $t2 = Center of ENE1  $t3 = Address of ENE1 array
	li $t0, 9		# x coordinate of center is 9
	li $t1, 32		# y coordinate of center is 32
	li $t2, 1276		# Pixel number in bytes is 1276

	la $t3, ENE1_CENTER	# Update ENE1_CENTER array
	sw $t2, 0($t3)
	sw $t0, 4($t3)
	sw $t1, 8($t3)

	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)
	
	move $a0, $t2		# Function call to draw the obstacle
	jal DRAW_ENE1
	
	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra
	
DRAW_ENE1: # void DRAW_ENE1(), $a0 = Pixel number of center
	# $t0 = BASE_ADDRESS  $t1 = Center of ENE1 address  $t2 = RED
	li $t0, BASE_ADDRESS	# Initialize the registers
	add $t1, $t0, $a0
	li $t2, RED
	
	sw $t2, 0($t1)		# Make ENE1's pixels red
	sw $t2, -128($t1)
	sw $t2, 128($t1)
	sw $t2, -256($t1)
	jr $ra			# Jump back to caller
	
CLEAR_ENE1: # void CLEAR_ENE1(), center of ENE1 stored in ENE1_CENTER
	# $t0 = BLACK  $t1 = ENE1 Center in bytes  $t2 = BASE ADDRESS  $t3 = address of ENE1 center
	li $t0, BLACK		# Get the black color
	la $t1, ENE1_CENTER	# Get the pixel number for object center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the object's center
	
	sw $t0, 0($t3)		# Make ENE1's pixels black (clearing it)
	sw $t0, -128($t3)
	sw $t0, 128($t3)
	sw $t0, -256($t3)
	jr $ra			# Jump back to caller
	
MOVE_ENE1: # void MOVE_ENE1()
	# $t0 = address of ENE1_CENTER  $t1 = ENE1 center pixel number  $t2 = X coordinate
	# $t3 = Y coordinate  $t4 = random number generated  $t5 = compare value
	
	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)

	jal CLEAR_ENE1		# Function call to clear ENE1 from the screen

	la $t0, ENE1_CENTER	# Initialization
	lw $t1, 0($t0)
	
loop2:	
	li $v0, 42		# Produce random number between [0,2] -> $t0
	li $a0, 0
	li $a1, 3
	syscall
	move $t4, $a0
	
	lw $t2, 4($t0)
	lw $t3, 8($t0)
	
	beqz $t4, ENE1_up	# Move up if 0 generated
	li $t5, 1		# Move down if 1 generated
	beq $t4, $t5, ENE1_down
	# Move left since 2 generated
	addi $t3, $t3, -2	# $t3 = y - 2
	bltz $t3, recreate_ENE1# Cannot move left, so recreate ENE1
	
	# Can move left
	addi $t1, $t1, -4
	addi $sp, $sp, -12	# Store $t0, $t1, $t3 on stack
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t3, 8($sp)
	
	move $a0, $t1		# Function call to draw ENE1 at new position
	jal DRAW_ENE1
	
	lw $t0, 0($sp)		# Pop $t0, $t1, $t3 from stack
	lw $t1, 4($sp)
	lw $t3, 8($sp)
	addi $sp, $sp, 12
	
	sw $t1, 0($t0)		# Update the ENE1_CENTER array
	addi $t3, $t3, 1
	sw $t3, 8($t0)
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller
	
recreate_ENE1:
	jal CLEAR_ENE1		# Function call to clear ENE1 from screen
	jal CREATE_ENE1		# Function call to recreate ENE1 on screen
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller
	
ENE1_up:
	addi $t2, $t2, -3	# $t2 = x - 3
	bltz $t2, loop2		# Cannot move up, generate again
	
	# $s0 = Pixel below (character T) check brown $t6 = load brown
	la $s0, ENE1_CENTER
	lw $s0, 0($s0)	# center pixel number in bytes
	addi $s0, $s0, -384
	li $t6, BASE_ADDRESS
	add $s0, $s0, $t6
	lw $s0, 0($s0)
	li $t6, BROWN

	beq $s0, $t6, return_ENE	# If brown

	# Can move up
	addi $t1, $t1, -128
	addi $sp, $sp, -12	# Store $t0, $t1, $t2 on stack
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	
	move $a0, $t1		# Function call to draw ENE1 at new position
	jal DRAW_ENE1

	lw $t0, 0($sp)		# Pop $t0, $t1, $t2 from stack
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	
	sw $t1, 0($t0)		# Update the ENE1_CENTER array
	addi $t2, $t2, 2
	sw $t2, 4($t0)
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller
	
ENE1_down:
	addi $t2, $t2, 3	# $t2 = x + 3
	li $t5, 24
	bgt $t2, $t5, loop2	# Cannot move down, generate again
	
	# $s0 = Pixel below (character T) check brown $t6 = load brown
	la $s0, ENE1_CENTER
	lw $s0, 0($s0)	# center pixel number in bytes
	addi $s0, $s0, 384
	li $t6, BASE_ADDRESS
	add $s0, $s0, $t6
	lw $s0, 0($s0)
	li $t6, BROWN

	beq $s0, $t6, return_ENE	# If brown

	# Can move down
	addi $t1, $t1, 128
	addi $sp, $sp, -12	# Store $t0, $t1, $t2 on stack
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	
	move $a0, $t1		# Function call to draw ENE1 at new position
	jal DRAW_ENE1
	
	lw $t0, 0($sp)		# Pop $t0, $t1, $t2 from stack
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	
	sw $t1, 0($t0)		# Update the ENE1_CENTER array
	addi $t2, $t2, -2
	sw $t2, 4($t0)
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

CREATE_ENE2: # void CREATE_ENE2(), creates at (23, 32)
	# ($t0, $t1) = (x, y)  $t2 = Center of ENE2  $t3 = Address of ENE2 array
	li $t0, 23		# x coordinate of center is 23
	li $t1, 32		# y coordinate of center is 32
	li $t2, 3068		# Pixel number in bytes is 3068
	
	la $t3, ENE2_CENTER	# Update ENE2_CENTER array
	sw $t2, 0($t3)
	sw $t0, 4($t3)
	sw $t1, 8($t3)
	
	addi $sp, $sp, -4	# Store caller return address on stack
	sw $ra, 0($sp)
	
	move $a0, $t2		# Function call to draw the obstacle
	jal DRAW_ENE2
	
	lw $ra, 0($sp)		# Restore return address and return to caller
	addi $sp, $sp, 4
	jr $ra

DRAW_ENE2: # void DRAW_ENE2(), $a0 = Pixel number of center
	# $t0 = BASE_ADDRESS  $t1 = Center of ENE2 address  $t2 = RED
	li $t0, BASE_ADDRESS	# Initialize the registers
	add $t1, $t0, $a0
	li $t2, RED
	
	sw $t2, 0($t1)		# Make ENE2's pixels red
	sw $t2, -4($t1)
	sw $t2, -8($t1)
	sw $t2, -140($t1)
	sw $t2, 116($t1)
	jr $ra			# Jump back to caller

CLEAR_ENE2: # void CLEAR_ENE2(), center of ENE2 stored in ENE2_CENTER
	# $t0 = BLACK  $t1 = ENE2 Center in bytes  $t2 = BASE ADDRESS  $t3 = address of ENE2 center
	li $t0, BLACK		# Get the black color
	la $t1, ENE2_CENTER	# Get the pixel number for object center
	lw $t1, 0($t1)
	li $t2, BASE_ADDRESS	# Get the base address of the bitmap
	add $t3, $t2, $t1	# Get the address of the object's center

	sw $t0, 0($t3)		# Make ENE2's pixels black (clearing it)
	sw $t0, -4($t3)
	sw $t0, -8($t3)
	sw $t0, -140($t3)
	sw $t0, 116($t3)
	jr $ra			# Jump back to caller

MOVE_ENE2: # void MOVE_ENE2()
	# $t0 = address of ENE2_CENTER  $t1 = ENE2 center pixel number  $t2 = X coordinate
	# $t3 = Y coordinate  $t4 = random number generated  $t5 = compare value
	
	addi $sp, $sp, -4	# Store the caller return address on stack
	sw $ra, 0($sp)
	
	jal CLEAR_ENE2		# Function call to clear ENE2 from the screen
	
	la $t0, ENE2_CENTER	# Initialization
	lw $t1, 0($t0)
	
loop4:	
	li $v0, 42		# Produce random number between [0,2] -> $t0
	li $a0, 0
	li $a1, 3
	syscall
	move $t4, $a0
	
	lw $t2, 4($t0)
	lw $t3, 8($t0)
	
	beqz $t4, ENE2_up	# Move up if 0 generated
	li $t5, 1		# Move down if 1 generated
	beq $t4, $t5, ENE2_down
	# Move left since 2 generated
	addi $t3, $t3, -4	# $t3 = y - 4
	bltz $t3, recreate_ENE2	# Cannot move left, so recreate ENE2

	# Can move left
	addi $t1, $t1, -4
	addi $sp, $sp, -12	# Store $t0, $t1, $t3 on stack
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t3, 8($sp)
	
	move $a0, $t1		# Function call to draw ENE2 at new position
	jal DRAW_ENE2
	
	lw $t0, 0($sp)		# Pop $t0, $t1, $t3 from stack
	lw $t1, 4($sp)
	lw $t3, 8($sp)
	addi $sp, $sp, 12
	
	sw $t1, 0($t0)		# Update the ENE2_CENTER array
	addi $t3, $t3, 3
	sw $t3, 8($t0)
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller
	
recreate_ENE2:
	jal CLEAR_ENE2		# Function call to clear ENE2 from screen
	jal CREATE_ENE2		# Function call to recreate ENE2 on screen
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

ENE2_up:
	addi $t2, $t2, -2	# $t2 = x - 2
	bltz $t2, loop4		# Cannot move up, generate again
	
	# $s0 = Pixel below (character T) check brown $t6 = load brown
	la $s0, ENE2_CENTER
	lw $s0, 0($s0)	# center pixel number in bytes
	addi $s0, $s0, -268
	li $t6, BASE_ADDRESS
	add $s0, $s0, $t6
	lw $s0, 0($s0)
	li $t6, BROWN

	beq $s0, $t6, return_ENE	# If brown

	# Can move up
	addi $t1, $t1, -128
	addi $sp, $sp, -12	# Store $t0, $t1, $t2 on stack
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	
	move $a0, $t1		# Function call to draw ENE2 at new position
	jal DRAW_ENE2
	
	lw $t0, 0($sp)		# Pop $t0, $t1, $t2 from stack
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	
	sw $t1, 0($t0)		# Update the ENE2_CENTER array
	addi $t2, $t2, 1
	sw $t2, 4($t0)
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller
	
ENE2_down:
	addi $t2, $t2, 2	# $t2 = x + 2
	li $t5, 25
	bgt $t2, $t5, loop4	# Cannot move down, generate again

	# $s0 = Pixel below (character T) check brown $t6 = load brown
	la $s0, ENE2_CENTER
	lw $s0, 0($s0)	# center pixel number in bytes
	addi $s0, $s0, 244
	li $t6, BASE_ADDRESS
	add $s0, $s0, $t6
	lw $s0, 0($s0)
	li $t6, BROWN

	beq $s0, $t6, return_ENE	# If brown

	# Can move down
	addi $t1, $t1, 128
	addi $sp, $sp, -12	# Store $t0, $t1, $t2 on stack
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	
	move $a0, $t1		# Function call to draw ENE2 at new position
	jal DRAW_ENE2
	
	lw $t0, 0($sp)		# Pop $t0, $t1, $t2 from stack
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	
	sw $t1, 0($t0)		# Update the ENE2_CENTER array
	addi $t2, $t2, -1
	sw $t2, 4($t0)
	
	lw $ra, 0($sp)		# Restore the original return address
	addi $sp, $sp, 4	
	jr $ra			# Return to the caller

# All Collision with enemy or base line

COLL_LINE:
# $t0 = Pixel of the character $s0 = Load Yellow $t1 = current pixel compare
	la $t0, PLAYER_CENTER
	lw $t0, 0($t0)	# Ship's center pixel number in bytes
	li $t1, BASE_ADDRESS
	add $t0, $t0, $t1
	li $s0, YELLOW
	
	# Check Yellow on left and right if co collided
	lw $t1, 384($t0)	# bottom (T) left
	beq $t1, $s0, coll_line
	lw $t1, 392($t0)	# bottom (T) right
	beq $t1, $s0, coll_line
	lw $t1, 256($t0)
	beq $t1, $s0, coll_line
	lw $t1, 264($t0)
	beq $t1, $s0, coll_line
	lw $t1, 128($t0)
	beq $t1, $s0, coll_line
	lw $t1, 136($t0)
	beq $t1, $s0, coll_line
	j no_coll

coll_line:
	addi $sp, $sp, -4	# Save $ra to the stack
	sw $ra, 0($sp)
	li $v0, 1
	jal CLEAR_PLAYER		# Clear the player
	sw $s0, 388($t3)

	lw $ra, 0($sp)	# pop
	addi $sp, $sp, 4	# Save $ra to the stack
	jr $ra
	
no_coll:
	li $v0, 0
	jr $ra
coll:
	addi $sp, $sp, -4	# Save $ra to the stack
	sw $ra, 0($sp)
	jal CLEAR_PLAYER		# Clear the player
	
	li $v0, 1
	lw $ra, 0($sp)	# pop
	addi $sp, $sp, 4	# Save $ra to the stack
	jr $ra

COLL_ENE1: # boolean COLL_ENE1(), returns in $v0
	# $t0-t3 = ENE1 pixel values  $t7 = PLAYER_PIXELS address  $s0 = PLAYER_PIXELS[i]
	# PART I: Assign each pixel of ENE1
	la $t0, ENE1_CENTER
	lw $t0, 0($t0)
	addi $t1, $t0, -128
	addi $t2, $t0, 128 
	addi $t3, $t0, -256

	# PART II: Check each pixel, seeing if they equal
	la $t7, PLAYER_PIXELS  
	li $t8, 0		# i = 0
	li $t9, 6		# Loop end condition

loop6:
	beq $t8, $t9, no_coll	# All pixels checked but no collision found
	lw $s0, 0($t7)		# Load value of pixel in player
	beq $t0, $s0, coll	# Branch if collision found
	beq $t1, $s0, coll
	beq $t2, $s0, coll
	beq $t3, $s0, coll
	addi $t7, $t7, 4	# Go to next pixel of the player
	addi $t8, $t8, 1	# Increment i
	j loop6			# Jump back to loop

COLL_ENE2: # boolean COLL_ENE2(), returns in $v0
	# $t0-t4 = ENE2 pixel values  $t5 = PLAYER_PIXELS address  $t8 = PLAYER_PIXELS[i]
	# PART I: Assign each pixel of ENE2
	la $t0, ENE2_CENTER
	lw $t0, 0($t0)
	addi $t1, $t0, -140
	addi $t2, $t0, 116
	addi $t3, $t0, -4
	addi $t4, $t0, -8
	
	# PART II: Check each pixel, seeing if they equal
	la $t5, PLAYER_PIXELS  
	li $t6, 0		# i = 0
	li $t7, 6		# Loop end condition
loop8:	
	beq $t6, $t7, no_coll	# All pixels checked but no collision found
	lw $t8, 0($t5)		# Load value of pixel in player
	beq $t0, $t8, coll	# Branch if collision found
	beq $t1, $t8, coll
	beq $t2, $t8, coll
	beq $t3, $t8, coll
	beq $t4, $t8, coll
	addi $t5, $t5, 4	# Go to next pixel of the player
	addi $t6, $t6, 1	# Increment i
	j loop8			# Jump back to loop

