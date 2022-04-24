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
	asect 0xf4 
	dc SNAKE_DEATH
	dc 1
	dc APPLE_EATED
	dc 1

	
#main data
	asect 0xf0
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
	ldi r0, game_score
	ldi r1, 2
	st r0, r1
	
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
	#Update in memory position of head
	ldi r3, YPacket 
	st r3, r1
	inc r3
	st r3, r2
	
	#delete tail
	ldi r1, tail_pos #read ptr on ptr on pixel to delete
	ld r1, r1	     #read ptr on pixel coords
	ld r1, r3	     #read pixel coord to delete
	st r0, r3 		 #write delete tail YX on screen
 	#add new tail in arr
	ld r0, r3 #read current head (Refactored) (Like YX)
	push r1 #safe last head position to delete
	st r1, r3 #store head to last delete position
	dec r1    #move to next delete position
	#check status of array (if need to loop to end - do)
	ldi r2, tail_arr
	cmp r1,r2
	ldi r3, game_score
	ld r3, r3
	bge updated #if tail_arr not in right position  (r1 < tail_arr) (make it right)
	add r3, r2
	move r2, r1
	
updated:      #else (tail in right position) (r1>=tail_arr) store
	ld r0, r2 #read current head position
	ldi r0, tail_pos
	st r0, r1
	inc r3
#check is snake head in bad position (In the tail)
#r2 - current head | r1 - array | r3 - game score
	ldi r1, tail_arr
check_tail_bump_loop:
	ld r1,r0
	cmp r2,r0
	bz is_current_head
	check_tail_bump:
	inc r1
	dec r3
	bnz check_tail_bump_loop
	pop r1
	ldi r0, displayIO
	br mainloop
	
is_current_head:
	pop r0
	cmp r1,r0
	bnz SNAKE_DEATH
	push r0
	br check_tail_bump

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
	rts
	
SNAKE_DEATH:
	ldi r0, freeDrawIO
	ldi r3, 32
	#write 16x16 display with text "LOSE"
	# 32 means 16 = 8+8 => 16*2 = 32
	draw_loop: #write predefined text
		st r0, r1
		dec r3
	bnz draw_loop
	halt
	
APPLE_EATED:
	push r0
	push r1
	jsr generate_new_apple
	#update score
	ldi r0, game_score
	ld r0, r1
	inc r1
	st r0, r1
	#update score_display
	ldi r0, score_pointer
	st r0, r1
	pop r1
	pop r0
	rti
end