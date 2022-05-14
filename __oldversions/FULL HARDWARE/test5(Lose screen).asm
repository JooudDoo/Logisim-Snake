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

#Interuptions
	asect 0xf4 
	dc SNAKE_DEATH
	dc 1
	dc APPLE_EATED
	dc 1
#pre-loaded images
	asect 0xd0
lose_image: dc 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x44,0x6E,0x4A,0x88,0x4A,0x88,0x4A,0x4E,0x4A,0x28,0x4A,0x28,0x64,0xCE,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

#main data
	asect 0xf0
YPacket: ds 1 #First 4-bits for Y-cord (Other MultiPurpose)
XPacket: ds 1 #First 4-bits for X-cord (Other MultiPurpose)
#r1 #UP/DOWN
#r2 #LEFT/RIGHT

	asect 0x00
init:
#Crutch for enabling interrupts
	ldi r1, 0b10000000
	sub r0, r1
	bz data_initilization

	setsp 0xcf
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
	

	wait_for_press:
		ldi r1, controllerIO
		ld r1,r1
		tst r1
	bz wait_for_press
	
	jsr generate_new_apple
	ldi r0, displayIO

	mainloop:
		ldi r1, controllerIO
		ld r1,r1
		push r1
		rts	
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
	br update_head
update_head: #Uses vals from r1(Y) and r2(X) to update r0(IO-1)
	ld r0, r3
	st r0, r1
	st r0, r2
	st r0, r3
		
save_head:
	ldi r3, YPacket
	st r3, r1
	inc r3
	st r3, r2
	br mainloop
	
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
	ldi r2, lose_image
	
	draw_loop:
		ld r2, r1
		st r0, r1
		inc r2
		dec r3
	bnz draw_loop
	halt
	
APPLE_EATED:
	push r0
	push r1
	jsr generate_new_apple
	ldi r0, score_pointer
	ld r0, r1
	inc r1
	st r0, r1
	pop r1
	pop r0
	rti
	br save_head


end