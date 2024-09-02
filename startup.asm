/*
	ideoita: 
	http://csdb.dk/forums/?roomid=11&topicid=94634
	http://codefse64.org/doku.php?id=base:kick_assembler_macros


	TODO:
		Fadein ihan alusta
			- koodi
		Intro:
			- fiksaa spritellä kolmoskohdan paskaskraidu
		Panopticon:
		Teksti:

		Spiraali:
			- sanoja feidaa sisään ja ulos siinä alhaalla

		Atomi:

		Sphere:

		Priest:

		Endscroll:

		jos zoomaava shakkilauta on suorassa, niin neliön koko on x- ja y-akseleilla sama, ja lasketaan kerran per frame. Kaksi shakkilautaa, zoomeri. Piirtäminen tapahtuu xorraamalla. 






*/

.pc = $0800 "Main Program"
:BasicUpstart2(demostart)

.const currentdemopart = $10
.const demopartchangepending = $11
.const currenttimeleftlo = $12
.const currenttimelefthi = $13
.const framecounterlo = $14
.const framecounterhi = $15
.const framecountdown = $16
.const framecountup = $17	
.const temp1 = $20
.const temp2 = $21
.const temp3 = $22
.const temp4 = $23
.const scrolltextptr = $25
.const spritescrollframe = $27
.const randomseed = $28

.const completedemo = true
.const music = true
.const rastertimedebug = false
.const startfrom = 00
.const testpart = 03


//------------------------------------------------------
demostart:
	// background color 
	lda #$00
	sta $d020
	sta $d021

	//set up interrupt. Taken from http://codebase64.org/doku.php?id=base:introduction_to_raster_irqs	
	sei
	lda #$7f
	sta $dc0d //disable timer interrupts
	sta $dd0d
	lda $dc0d //clear CIA interrupt flags 
	lda $dd0d

	lda #$01
	sta $d01a //enable raster interrupts 

	lda #$35 //turn kernal rom off
	sta $01

	:SetRasterInterrupt(default_irq, $80)
	cli

	// init music
	.if (music)
	{
		lda #$00
		jsr $1000 
	}
	.if (completedemo)
	{
		//start from the beginning
		lda #0
		sta demopartchangepending
		lda #startfrom
		sta currentdemopart
	} 
	else
	{
		lda #testpart
		sta currentdemopart
		lda #0
		sta demopartchangepending
	}

	//init framecounter
	lda #$00
	sta framecounterhi
	sta framecounterlo

	lda #32 //clearcolor
	jsr clearscreen
	jsr initdemopart //init first demopart

mainloop:
	lda demopartchangepending
	beq skip_demopartinit //==0

	//we need to clean up the demo part. The pointer is created in initdemopart 
selfmod_cleanupfuncoffset:
	.byte $20, $00, $00 //jsr $xxyy, cleanup
	
	//we need to init the demo part. The pointer is created in initdemopart 
selfmod_initfuncoffset:
	.byte $20, $00, $00 //jsr $xxyy, init
	
	//clear out change 
	lda #00
	sta demopartchangepending
	
skip_demopartinit:
selfmod_drawfuncoffset:
	.byte $20, $00, $00 //jsr $xxyy, draw
	
	jmp mainloop	
	
	
initdemopart:
	ldx currentdemopart
	//create pointer to cleanup routine
	lda script_cleanuproutinelo, x
	sta selfmod_cleanupfuncoffset+1
	lda script_cleanuproutinehi, x
	sta	selfmod_cleanupfuncoffset+2

	//create pointer to init routine
	lda script_initroutinelo, x
	sta selfmod_initfuncoffset+1
	lda script_initroutinehi, x
	sta	selfmod_initfuncoffset+2

	//create pointer to draw
	lda script_drawroutinelo, x
	sta selfmod_drawfuncoffset+1
	lda script_drawroutinehi, x
	sta	selfmod_drawfuncoffset+2
	
	//set up effect timer
	lda script_durationlo, x
	sta currenttimeleftlo
	lda script_durationhi, x
	sta currenttimelefthi
	
	//call init in the next update 
	lda #1
	sta demopartchangepending

	rts

dummyfunc:
	rts

//----------------------------------------------------------

default_irq:
	:InterruptStart()

	asl $d019
	jsr demoflowupdate

	:InterruptEnd()
	
demoflowupdate:	
	//update timer
	inc framecounterlo
	lda framecounterhi
	adc #0
	sta framecounterhi
	
	//update music
	.if (music)
	{
		.if (rastertimedebug)
		{
			lda #3
			sta $d020
			jsr $1003
			lda #0
			sta $d020
		}
		else
		{
			jsr $1003
		}
	}

	//update countdown
	ldx framecountdown
	bne countdown_is_not_zero
	ldx #1 //will be decremented so results in zero
countdown_is_not_zero:
	dex
	stx framecountdown
	
	//update countup
	ldx framecountup
	cpx #$ff
	beq countup_is_at_maximum
	inx
countup_is_at_maximum:
	stx framecountup
	
	//update demo flow. Subtract effect timer
	.if (completedemo)
	{
		lda currenttimelefthi
		cmp #$ff			//#$ff = keep doing it forever
		beq dont_update_flow
		
		sec
		lda currenttimeleftlo
		sbc #1
		sta currenttimeleftlo
		lda currenttimelefthi
		sbc #0
		sta currenttimelefthi
		
		//test for zero
		lda currenttimeleftlo
		bne dont_update_flow
		lda currenttimelefthi
		bne dont_update_flow
		
		//time left is zero, so set up new demopart that will be initialized in the next
		//mainloop iteration
		inc currentdemopart
		jsr initdemopart
	}
		
	dont_update_flow:
	rts

clearscreen:
	ldx #00
clearloop:
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $06e8, x
	dex 
	bne clearloop
	rts

updatespritescroll:
	clc
	lda spritescrollframe
	adc #1
	cmp #8
	bcs !newletter+
	jmp !skip+
!newletter:

	ldy #0
	lda (scrolltextptr), y
	cmp #$ff
	beq !skip+//!nowrap+	//$ff ends 

	cmp #$fe
	bne !nowrap+

//	lda #<plasma.scrolltext
//	sta scrolltextptr
//	lda #>plasma.scrolltext
//	sta scrolltextptr+1

!nowrap:
	//font data offset wraps around at charindex > 32 but it's good enough
	asl
	asl
	asl
	tax

	.for (var i = 0; i < 8; i++)
	{
		//upper left
		lda data.fontdata1x1 + i + 2, x //
		sta $2000+8*64 + i * 3
	}

	//advance textpointer
	clc
	lda scrolltextptr
	adc #1
	sta scrolltextptr
	lda scrolltextptr+1
	adc #0
	sta scrolltextptr+1

	lda #0
!skip:
	sta spritescrollframe

	.for (var y = 0; y < 8; y++)
	{
		//muistista sprite seiskaan
		//sprite seiskasta sprite kutoseen
		clc
		.for (var sprite = 8; sprite > 4; sprite--)
		{
			rol $2000+sprite*64 + 2 + y * 3 
			rol $2000+sprite*64 + 1 + y * 3
			rol $2000+sprite*64 + 0 + y * 3 
		}
	}
	rts

getrandom:
	lda randomseed
	beq doEor
	asl
	beq noEor //if the input was $80, skip the EOR
	bcc noEor
doEor:    
	eor #$1d
noEor:  
	sta randomseed
	rts


//----------------------------------------------------------
.pc=$1000 "Music"
.import binary "funkee.bin"
//----------------------------------------------------------

spritefont:
.pc=$3800 "graphics data"

.import source "datagen.asm" //contains data

//script 
script_initroutinelo:

	.byte <intro.init
	.byte <demologo.init
//	.byte <plasma.init
	.byte <message.init
	.byte <spiral.init
	.byte <atomic.init
//	.byte <dotpart.init
//	.byte <nippon.init
	.byte <sphere.init
	.byte <information.init
	.byte <endscroll.init
	
script_initroutinehi:

	.byte >intro.init
	.byte >demologo.init
//	.byte >plasma.init
	.byte >message.init
	.byte >spiral.init
	.byte >atomic.init
//	.byte >dotpart.init
//	.byte >nippon.init
	.byte >sphere.init
	.byte >information.init
	.byte >endscroll.init

script_drawroutinelo:
	.byte <intro.draw
	.byte <demologo.draw
//	.byte <plasma.draw
	.byte <message.draw
	.byte <spiral.draw
	.byte <atomic.draw
//	.byte <dotpart.draw
//	.byte <nippon.draw
	.byte <sphere.draw
	.byte <information.draw
	.byte <endscroll.draw

script_drawroutinehi:
	.byte >intro.draw
	.byte >demologo.draw
//	.byte >plasma.draw
	.byte >message.draw
	.byte >spiral.draw
	.byte >atomic.draw
//	.byte >dotpart.draw
//	.byte >nippon.draw
	.byte >sphere.draw
	.byte >information.draw
	.byte >endscroll.draw
	
script_cleanuproutinelo:
	.byte <dummyfunc	//first part needs no cleanup
	.byte <intro.cleanup
	.byte <demologo.cleanup
//	.byte <plasma.cleanup
	.byte <message.cleanup
	.byte <spiral.cleanup
	.byte <atomic.cleanup
//	.byte <dotpart.cleanup
//	.byte <nippon.cleanup
	.byte <sphere.cleanup
	.byte <information.cleanup
	.byte <endscroll.cleanup
	
script_cleanuproutinehi:
	.byte >dummyfunc
	.byte >intro.cleanup
	.byte >demologo.cleanup
//	.byte >plasma.cleanup
	.byte >message.cleanup
	.byte >spiral.cleanup
	.byte >atomic.cleanup
//	.byte >dotpart.cleanup
//	.byte >nippon.cleanup
	.byte >sphere.cleanup
	.byte >information.cleanup
	.byte >endscroll.cleanup

script_durationlo:
	.byte $00   	//intro
	.byte $00   	//demologo
//	.byte $7f		//plasma
	.byte $00		//message
	.byte $7f 		//spiral
	.byte $00
//	.byte $00 		//dotpart
//	.byte $00 		//nippon
	.byte $7f  		//sphere
	.byte $60 		//information
	.byte $00		//endscroll
	
script_durationhi:
	.byte $01       //intro 
	.byte $02       //title 
//	.byte $01		//plasma
	.byte $02		//message
	.byte $02       //spiral
	.byte $03		//atomic
//	.byte $02		//dotpart
//	.byte $04  		//nippon
	.byte $03		//sphere
	.byte $03  		//information
	.byte $ff		//endscroll


//$d000-$dfff unusable

.const effectstart = *
.pc = * "***** Effects Start ******"
.import source "preacherlib.asm"
.import source "intro.asm"
//.import source "title.asm"	
.import source "demologo.asm"
//.import source "plasma.asm"	
.import source "message.asm"
.import source "spiral.asm"
//.import source "dotpart.asm"
//.import source "tunnel.asm"
//.import source "nippon.asm"
.import source "atomic.asm"
.import source "sphere.asm"
.import source "information.asm"
.import source "endscroll.asm"

.pc=* "***** Effects End ******"
.const effectend = *

.print "Effects size = " + toIntString([effectend - effectstart]) + " bytes"
