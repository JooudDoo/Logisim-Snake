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

#main data
	asect 0x90
tailArr: ds 96
	asect 0xf0
appleCoords: ds 1
tailPos: ds 1
gameScore: ds 1
yPlayer: ds 1 #First 4-bits for Y-cord (Other MultiPurpose)
xPlayer: ds 1 #First 4-bits for X-cord (Other MultiPurpose)
#r1 #UP/DOWN
#r2 #LEFT/RIGHT

	asect 0x00
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
	#prepare for tailArr
	ldi r0, tailPos
	ldi r1, tailArr
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
	ldi r0, displayIO
	#update head position on screen
	st r0, r1 #write Head Y on screen
	st r0, r2 #write Head X on screen
		
	#Update in memory position of head
	ldi r3, yPlayer 
	st r3, r1
	inc r3
	st r3, r2
	
	#check if snake goes into border -> DIE
	ldi r3, 0b11110000 #load mask
	and r1, r3 #Check Y Coord
	bnz PLAYER_LOSE
	ldi r3, 0b11110000 #load mask
	and r2, r3 #Check X Coord
	bnz PLAYER_LOSE
	
	#check if we ate apple
	ld r0, r1
	ldi r3, appleCoords
	ld r3,r3
	cmp r1,r3
	bz APPLE_ATE
	APPLE_UPDATED:
	
	#delete tail
	ldi r1, tailPos #read ptr on ptr on pixel to delete
	ld r1, r1	     #read ptr on pixel coords
	ld r1, r3	     #read pixel coord to delete
	st r0, r3 		 #write delete tail YX on screen
	
#check is snake head have collisions with tail (In the tail)
#r2 - current head | r1 - array | r3 - game score
	ldi r3, gameScore
	ld r3,r3
	inc r3
	ldi r1, tailArr #Load start of array
	ld r0, r2 #read current head (Refactored) (Like YX)

check_tail_bump_loop: #Check loop
	ld r1,r0 #Load element from array
	cmp r2,r0 #Compare it with head
	bz PLAYER_LOSE
	inc r1 #Go to next elem
	dec r3 #Descrease counter (Like game score | Snake elements on screen)
	bnz check_tail_bump_loop
	
	ldi r0, displayIO
 	#add new tail in arr
	ldi r1, tailPos #read ptr on ptr on pixel to delete
	ld r1, r1	     #read ptr on pixel coords
	ld r0, r3 #read current head (Refactored) (Like YX)
	st r1, r3 #store head to last delete position
	dec r1    #move to next delete position
	#check status of array (if need to loop to end - do)
	ldi r2, tailArr
	cmp r1,r2	
	bge updated #if tail in right pos - br(tail in right position) (r1>=tailArr) than store
	ldi r3, gameScore
	ld r3,r3
	add r3, r2 #else tailArr not in right position - fix (r1 < tailArr) (make it right)
	move r2, r1
updated:      
	ld r0, r2 #read current head position
	ldi r0, tailPos
	st r0, r1 #Store last element to delete addr
	ldi r0, displayIO #Reload to r0 right addr
	br mainloop #Go to next frame
	
	
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
	ldi r0, appleCoords
	st r0,r1
	rts


PLAYER_WIN:
	ldi r1, 16 #Send image code (0 - "Lose") (16 - "Win")
	br freeDrawer	

PLAYER_LOSE:
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
	br APPLE_UPDATED
end