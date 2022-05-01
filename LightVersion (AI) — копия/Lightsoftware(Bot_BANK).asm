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
YPacket: ds 1 #First 4-bits for Y-cord (Other MultiPurpose)
XPacket: ds 1 #First 4-bits for X-cord (Other MultiPurpose)

	asect 0xDD
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
	bz bot_YMove#X position is true
	bge bot_right#Move left
bot_left:
	dec r1
	dec r0 #check if any barrier at left
	ld r0, r2
	ldi r3, bot_backdoor	
	st r3, r2
	st r3, r1
	ld r3, r3
	tst r3
	bnz bot_down #If exist try down
	inc r0
	br bot_drawX
bot_right:
	inc r1
	dec r0
	ld r0, r2 #check if any barrier at right
	ldi r3, bot_backdoor	
	st r3, r2
	st r3, r1
	ld r3, r3
	tst r3
	bnz bot_up #if exist try up
	inc r0
bot_drawX:
	st r0, r1
	dec r0
	ld r0,r2
	br bot_draw
	
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
	ld r0, r1 #check if any barrier at down
	ldi r3, bot_backdoor	
	st r3, r2
	st r3, r1
	ld r3, r3
	tst r3
	bnz bot_right #if exist go right
	dec r0
	br bot_drawY
bot_up:
	inc r2
bot_drawY:
	st r0, r2
	inc r0
	ld r0,r1
#	br bot_draw [OPTIMIZED]

bot_draw: #Draw new head and tail on ehe screen
	ldi r0, displayIO
	st r0,r2
	st r0,r1
	
	#delete tail
	ldi r1, bot_tail_pos
	ld r1, r1
	ld r1, r3
	st r0, r3 #write delete tail XY on screen
 	#add new tail in arr
	ld r0, r3 #read current head (Refactored)
	st r1, r3 #store head to last delete position
	dec r1
	ldi r2, bot_tail_arr
	cmp r1,r2
	bge bot_updated #if player_tail_arr not in right position  (r1 < player_tail_arr) (make it right)
	ldi r3, bot_score
	ld r3, r3
	add r3, r2
	move r2,r1
	
bot_updated:      #else (tail in right position) (r1>=player_tail_arr) store
	ldi r0, bot_tail_pos
	st r0, r1
	
	
	ldi r0, displayIO
	br enable_main_memory

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