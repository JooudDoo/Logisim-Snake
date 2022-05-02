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
	asect 0xfe
switch_cell:
	asect 0xff
bot_backdoor:
	asect 0x60
player_tail_arr: ds 48
bot_tail_arr: ds 48

#Interuptions
	asect 0xf4 
	dc SNAKE_DEATH
	dc 1
	dc APPLE_EATED
	dc 1

	
#main data
	asect 0xc0
YBot: ds 1
XBot: ds 1
apple_coords: ds 1
tail_pos: ds 1 
bot_tail_pos: ds 1
player_score: ds 1
bot_score: ds 1
loop_testing_check: ds 1
YPacket: ds 1 #First 4-bits for Y-cord (Other MultiPurpose)
XPacket: ds 1 #First 4-bits for X-cord (Other MultiPurpose)

	asect 0xE8
#return to_main memory
enable_main_memory:
	ldi r1, switch_cell
	st r1, r1

asect 0x05
	#BOT MOVE
	ldi r0, XBot
	ld r0, r1
	ldi r2, apple_coords
	ld r2,r2
	ldi r3, 0b00001111
	and r3, r2
	cmp r2,r1
	bz bot_YMove #Bot in right row -> try to move up/down to apple
	bge bot_right#if we are to the left of the apple -> go right
bot_left: #else go left (we are to the right of the apple)
	dec r1
	dec r0
	
	#check if we have a loop (We checked all 4 sides)
	save r0
	ldi r2, loop_testing_check #load check value
	ld r2, r3
	save r2
	ldi r2, 0b00001000 #xor with some ID of side
	xor r2,r3
	restore
	ld r2, r0
	cmp r3, r0 #Compare new val with old
	restore
	ble bot_drawX #If new val lesser than old => we visit this part of code twice => make random move (We don't have right move)
	st r2, r3 #save new check val
	
	ld r0, r2
	ldi r3, bot_backdoor #peek for the left pixel
	st r3, r2
	st r3, r1
	ld r3, r3
	tst r3 #If pixel is ocuppied => try down
	bnz bot_down #If pixel is ocuppied => try down
	br bot_drawX #else make left move
bot_right:
	inc r1
	dec r0
	
	#check if we have a loop (We checked all 4 sides)
	save r0
	ldi r2, loop_testing_check #load check value
	ld r2, r3
	save r2
	ldi r2, 0b00000100 #xor with some ID of side
	xor r2,r3
	restore
	ld r2, r0
	cmp r3, r0  #Compare new val with old
	restore
	ble bot_drawX #If new val lesser than old => we visit this part of code twice => make random move (We don't have right move)
	st r2, r3 #save new check val
	
	ld r0, r2
	ldi r3, bot_backdoor #peek for the right pixel
	st r3, r2
	st r3, r1
	ld r3, r3
	tst r3 #If pixel is ocuppied => try up
	bnz bot_up #If pixel is ocuppied => try down
	#else make right move
bot_drawX:
	ld r0, r2 #load Y coord from memory
	inc r0
	st r0,r1 #save new X coord to memory
	br bot_draw #redraw head position on screen
	
bot_YMove:
	ldi r0, YBot
	ld r0, r2
	ldi r1, apple_coords
	ld r1,r1
	ldi r3, 0b11110000
	and r3, r1
	shr r1
	shr r1
	shr r1
	shr r1
	cmp r1, r2
	ld r0, r1
	bgt bot_up
bot_down:
	dec r2
	inc r0
	
	#check if we have a loop (We checked all 4 sides)
	save r0
	ldi r1, loop_testing_check #load check value
	ld r1, r3
	save r1
	ldi r1, 0b00000010 #xor with some ID of side
	xor r1,r3
	restore
	ld r1, r0
	cmp r3, r0  #Compare new val with old
	restore
	ble bot_drawY #If new val lesser than old => we visit this part of code twice => make random move (We don't have right move)
	st r1, r3 #save new check val
	
	ld r0, r1
	ldi r3, bot_backdoor	 #peek for the down pixel
	st r3, r2
	st r3, r1
	ld r3, r3
	tst r3  #If pixel is ocuppied => try right
	bnz bot_right  #If pixel is ocuppied => try right
	br bot_drawY #else go down
bot_up:
	inc r2
	inc r0
	
	
	#check if we have a loop (We checked all 4 sides)
	save r0
	ldi r1, loop_testing_check #load check value
	ld r1, r3
	save r1
	ldi r1, 0b00000001 #xor with some ID of side
	xor r1,r3
	restore
	ld r1, r0
	cmp r3, r0 #Compare new val with old
	restore
	ble bot_drawY #If new val lesser than old => we visit this part of code twice => make random move (We don't have right move)
	st r1, r3 #save new check val
	
	ld r0, r1 #check if any barrier at down
	ldi r3, bot_backdoor	
	st r3, r2
	st r3, r1
	ld r3, r3
	tst r3  #If pixel is ocuppied => try left
	bnz bot_left  #If pixel is ocuppied => try left
	#else go up
bot_drawY:
	ld r0, r1 #load X coord from memory
	dec r0
	st r0,r2 #save new Y coord to memory
#	br bot_draw [OPTIMIZED] #redraw head position on screen

bot_draw: #Draw new head and tail on ehe screen
	ldi r0, loop_testing_check  #Set 0 to check value
	clr r3 #Set 0 to check value
	st r0, r3 #Set 0 to check value
	ldi r0, displayIO
	st r0,r2 #draw new Y coord head position on screen
	st r0,r1 #draw new X coord head position on screen
	
	#delete tail
	ldi r1, bot_tail_pos #load position of ptr on tail array
	ld r1, r1
	ld r1, r3
	st r0, r3 #Draw pixel to delete (Like last element in snake tail)
 	#add new tail in arr (Current head position)
	ld r0, r3 #read current head (Refactored) (Read from device in form like YYYYXXXX)
	st r1, r3 #store head to current ptr on tail array
	dec r1 #Update ptr on tail array
	ldi r2, bot_tail_arr
	cmp r1,r2
	bge bot_updated #if player_tail_arr in right position  (r1 >= player_tail_arr) go next
	ldi r3, bot_score #else (tail not in right position) (r1 <player_tail_arr) make it right
	ld r3, r3
	add r3, r2
	move r2,r1
	
bot_updated:      
	ldi r0, bot_tail_pos
	st r0, r1
	ldi r0, displayIO
	br enable_main_memory #Switch memory bank to main memory

generate_new_apple:
	ldi r0, randomGenerator
	ld r0, r1
	inc r0
	st r0, r1
	ldi r0, apple_coords
	st r0, r1
	rts
	
BOT_WIN:
	ldi r1, 0 #Send image code (0 - "Lose") (16 - "Win")
	br freeDrawer

SNAKE_DEATH:
	ldi r1, 16 #Send image code (0 - "Lose") (16 - "Win")
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
	ldi r2, 48 #Current max score
	jsr generate_new_apple #Redraw apple on screen
	#update score
	ldi r0, bot_score #Load game score from memory
	ld r0, r1
	inc r1 #Increase score
	cmp r1, r2 #Check if player have enough score to win
	bz BOT_WIN
	st r0, r1
	#update score_display
	ldi r0, score_pointer #Redraw score on screen
	st r0, r1
	pop r2
	pop r1
	pop r0
	rti
end