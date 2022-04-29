#Connected devices
	asect 0xf8
displayIO:
	asect 0xf9
randomGenerator:
	asect 0xfa
appleIO:
	asect 0xfb
controllerIO:
	asect 0xfc
score_pointer:
	asect 0xfd
freeDrawIO:
	asect 0xb0
tail_arr: ds 64

#Interuptions
	asect 0xf6
	dc APPLE_EATED
	dc 1

	
#main data
	asect 0xf0
apple_coords: ds 1
tail_pos: ds 1
game_score: ds 1
YPacket: ds 1 #First 4-bits for Y-cord (Other MultiPurpose)
XPacket: ds 1 #First 4-bits for X-cord (Other MultiPurpose)
#r1 #UP/DOWN
#r2 #LEFT/RIGHT

	asect 0x00
init:
#Crutch for enabling interrupts
	setsp 0xaf
	ldi r0, data_initilization
	push r0
	ldi r0, 0b10000000
	push r0
	rti
	
data_initilization:
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
	ldi r3, YPacket
	ldi r1, 0b00000110
	st r3, r1
	st r0, r1
	inc r3
	st r3, r1
	st r0, r1
	ldi r1, 0b00000000
	st r0, r1
	#prepare for tail_arr
	ldi r0, tail_pos
	ldi r1, tail_arr
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
		rts	#goto move
	br mainloop
	
move_left:
	jsr load_XY_packets
	dec r2
	br update_head
move_right:
	jsr load_XY_packets
	inc r2
	br update_head
move_up:
	jsr load_XY_packets
	inc r1
	br update_head
move_down:
	jsr load_XY_packets
	dec r1
	#br update_head [OPTIMIZATION]

update_head: #Uses vals from r1(Y) and r2(X) to update r0(IO-0)
	ldi r0, displayIO
	#update head position on screen
	st r0, r1 #write Head Y on screen
	st r0, r2 #write Head X on screen
	#check if snake goes into border -> DIE
#	ldi r3, 0b11110000 #load right mask
#	and r1, r3 #Check Y Coord
#	bnz PLAYER_LOSE
#	ldi r3, 0b11110000 #load right mask
#	and r2, r3 #Check X Coord
#	bnz PLAYER_LOSE
	#Update in memory position of head
	ldi r3, YPacket 
	st r3, r1
	inc r3
	st r3, r2
#	#check if we ate apple
#	ld r0, r1
#	ldi r3, apple_coords
#	ld r3,r3
#	cmp r1,r3
#	bz APPLE_EATED
#	APPLE_UPDATED:
	
	#delete tail
	ldi r1, tail_pos #read ptr on ptr on pixel to delete
	ld r1, r1	     #read ptr on pixel coords
	ld r1, r3	     #read pixel coord to delete
	st r0, r3 		 #write delete tail YX on screen
 	#add new tail in arr
	ld r0, r3 #read current head (Refactored) (Like YX)
	push r1 #safe last head	 position to delete
	st r1, r3 #store head to last delete position
	dec r1    #move to next delete position
	#check status of array (if need to loop to end - do)
	ldi r2, tail_arr
	cmp r1,r2
	ldi r3, game_score
	ld r3, r3
	bge updated #if tail in right pos - br(tail in right position) (r1>=tail_arr) than store
	add r3, r2 #else tail_arr not in right position - fix (r1 < tail_arr) (make it right)
	move r2, r1
	
updated:      
	ld r0, r2 #read current head position
	ldi r0, tail_pos
	st r0, r1 #Store last element to delete addr
	inc r3 #Increase cursor in array
#check is snake head have collisions with tail (In the tail)
#r2 - current head | r1 - array | r3 - game score
	ldi r1, tail_arr #Load start of aray
check_tail_bump_loop: #Check loop
	ld r1,r0 #Load element from array
	cmp r2,r0 #Compare it with head
	bz is_current_head #Check (If addr eq => current head => pass)
	check_tail_bump:
	inc r1 #Go to next elem
	dec r3 #Descrease counter (Like game score | Snake elements on screen)
	bnz check_tail_bump_loop
	pop r1 #Fix stack
	ldi r0, displayIO #Reload to r0 right addr
	br mainloop #Go to next frame
	
#Need to fix possible collisions when the current head is considered a tail
is_current_head: #Checks if current position is current head
	pop r0 #Take current head addr in memory
	cmp r1,r0 #Check
	bnz PLAYER_LOSE #Not head - DIE
	push r0 #save to stack head addr
	br check_tail_bump #Return to check cycle

load_XY_packets:
	ldi r3, XPacket
	ld r3,r2
	dec r3
	ld r3,r1
	rts
	
generate_new_apple:
	ldi r0, randomGenerator
	ld r0, r1
	inc r0
	st r0, r1
	ldi r0, apple_coords
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
	
APPLE_EATED:
	push r0
	push r1
	push r2
	ldi r2, 64 #Current max score
	jsr generate_new_apple #Redraw apple on screen
	#update score
	ldi r0, game_score #Load game score from memory
	ld r0, r1
	inc r1 #Increase score
	cmp r1, r2 #Check if player have enough score to win
	bz PLAYER_WIN
	st r0, r1
	#update score_display
	ldi r0, score_pointer #Redraw score on screen
	st r0, r1
	pop r2
	pop r1
	pop r0
	#br APPLE_UPDATED
end