#Connected devices
	asect 0xf8
displayIO:
	asect 0xf9
randomGeneratorIO:
	asect 0xfa
appleIO:
	asect 0xfb
controllerIO:
	asect 0xfc
scorePointerIO:
	asect 0xfd
freeDrawIO:

#Interuptions
	asect 0xf4 
	dc SNAKE_DEATH
	dc 1
	dc APPLE_ATE
	dc 1

	
#main data
	asect 0x90
playerTailArr: ds 96
	asect 0xf0
playerTailPos: ds 1
gameScore: ds 1
yPlayer: ds 1 #First 4-bits for Y-cord (Other MultiPurpose)
xPlayer: ds 1 #First 4-bits for X-cord (Other MultiPurpose)
#r1 #UP/DOWN
#r2 #LEFT/RIGHT

	asect 0x00
init:
#Crutch for enabling interrupts
	ldi r0, data_initilization
	push r0
	ldi r0, 0b10000000
	push r0
	rti
	
data_initilization:
	setsp 0x8F
#init controller
	ldi r0, controllerIO 
	ldi r1, move_left
	st r0, r1
	ldi r1, move_right
	st r0, r1
	ldi r1, move_up
	st r0, r1
	ldi r1, move_down
	st r0, r1	
#prepare for game
	ldi r0, displayIO
	#load start position
	ldi r3, yPlayer
	ldi r1, 0b00000110
	st r3, r1
	st r0, r1
	inc r3
	st r3, r1
	st r0, r1
	ldi r1, 0b00000000
	st r0, r1
	#prepare for playerTailArr
	ldi r0, playerTailPos
	ldi r1, playerTailArr
	ldi r2, 0b01100110
	st r1,r2
	st r0, r1

	#wait for press to start
	ldi r1, controllerIO
	wait_for_press:
		ld r1,r0
		tst r0
	bz wait_for_press
	
	jsr generate_new_apple
	ldi r0, displayIO

	mainloop:
		ldi r1, controllerIO #read move_addr
		ld r1,r1
		push r1
		jsr load_XY_packets
		rts	#goto move
	br mainloop
	
move_left:
	dec r2
	br update_head
move_right:
	inc r2
	br update_head
move_up:
	inc r1
	br update_head
move_down:
	dec r1
	#br update_head [OPTIMIZATION]

update_head: #Uses vals from r1(Y) and r2(X) to update r0(IO-0)
	#update head position on screen
	st r0, r1 #write Head Y
	st r0, r2 #write Head X
	#Update in memory position of head
	ldi r3, yPlayer 
	st r3, r1
	inc r3
	st r3, r2
	
	#delete tail
	ldi r1, playerTailPos
	ld r1, r1
	ld r1, r3
	st r0, r3 #write delete tail XY on screen
 	#add new tail in arr
	ld r0, r3 #read current head (Refactored)
	st r1, r3 #store head to last delete position
	dec r1
	ldi r2, playerTailArr
	cmp r1,r2
	bge updated #if playerTailArr not in right position  (r1 < playerTailArr) (make it right)
	ldi r3, gameScore
	ld r3, r3
	add r3, r2
	move r2,r1
	
updated:      #else (tail in right position) (r1>=playerTailArr) store
	ldi r0, playerTailPos
	st r0, r1
	
	ldi r0, displayIO
	br mainloop
	
load_XY_packets:
	ldi r3, xPlayer
	ld r3,r2
	dec r3
	ld r3,r1
	rts
	
generate_new_apple:
	ldi r0, randomGeneratorIO
	ld r0, r1
	inc r0
	st r0, r1
	rts
	
PLAYER_WIN:
	ldi r1, 16 #Send image code (0 - "Lose") (16 - "Win")
	br freeDrawer

SNAKE_DEATH:
	ldi r1, 0 #Send image code (0 - "Lose") (16 - "Win")
#	br freeDrawer [OPTIMIZATION]

#Draws on the display selected preloaded image and shutdown processor
freeDrawer: #In r1 must lie number of picture
	ldi r0, freeDrawIO
	st r0, r1
	ldi r3, 16
	#push 16 signals to redraw display
	draw_loop: #write predefined text
		st r0, r1
		dec r3
	bnz draw_loop
	halt
	
APPLE_ATE:
	push r0
	push r1
	push r2
	ldi r2, 96 #Current max score
	jsr generate_new_apple #Redraw apple on screen
	#update score
	ldi r0, gameScore #Load game score from memory
	ld r0, r1
	inc r1 #Increase score
	cmp r1, r2 #Check if player have enough score to win
	bz PLAYER_WIN
	st r0, r1
	#update score_display
	ldi r0, scorePointerIO #Redraw score on screen
	st r0, r1
	pop r2
	pop r1
	pop r0
	rti
end