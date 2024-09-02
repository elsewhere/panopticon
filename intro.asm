.pc = * "Intro"

.namespace intro
{
.const musicraster = 0

.const x = 1
.const speed = 1
.const irqdebug = false

.const chartemp = $87
.const scrollflip = $88

.const tilpey = 100
.const tilpex = 100
.const emptychar = 254

.const introstate = $90
.const introtimer = $91
.const colorindex = $92

.const pictureptrsrc = $90
.const pictureptrdst = $94

.const logoy = 7
.const logox = 10
.const logoheight = 9
.const logowidth = 20

.const logoy2 = 0
.const logox2 = 10
.const logoheight2 = 24
.const logowidth2 = 18

init:
	//clear screen
	lda #emptychar
	jsr clearscreen
	:TextScreenColor(0)
	//setup colors
	lda #1
	sta $d021	
	lda #1
	sta $d020

	lda #0
	sta $d015	//sprites off 	

	//setup characters at $3800
	lda #%00010000
	sta $d011		//extended background mode off

	lda #0
	sta introstate
	sta introtimer
	sta colorindex

	jsr initpicture1
	jsr initpicture2

	:SetScreenAndCharLocation($0400, $2000)
	:SetCharset(data.groupcharsetdata1, $2000)
	:SetCharset(data.groupcharsetdata2, $2800)

	lda #0
	sta $2800 + emptychar * 8
	sta $2800 + emptychar * 8 + 1
	sta $2800 + emptychar * 8 + 2
	sta $2800 + emptychar * 8 + 3
	sta $2800 + emptychar * 8 + 4
	sta $2800 + emptychar * 8 + 5
	sta $2800 + emptychar * 8 + 6
	sta $2800 + emptychar * 8 + 7
	sta $2000 + emptychar * 8
	sta $2000 + emptychar * 8 + 1
	sta $2000 + emptychar * 8 + 2
	sta $2000 + emptychar * 8 + 3
	sta $2000 + emptychar * 8 + 4
	sta $2000 + emptychar * 8 + 5
	sta $2000 + emptychar * 8 + 6
	sta $2000 + emptychar * 8 + 7
	:SetRasterInterrupt(irq, musicraster)

	rts

draw:
	rts
	
cleanup:
	:SetScreenAndCharLocation($0400, $2800)
	rts

irq:
	:InterruptStart()
	asl $d019 //acknowledge interrupt
	jsr demoflowupdate

	.if (irqdebug)
	{
		lda #2
		sta $d020
	}

	clc
	lda introtimer
	adc #2
	sta introtimer
	bcc !skipadvance+
	lda #0

	sta introtimer
	sta colorindex
	inc introstate

	//init second logo
	:SetScreenAndCharLocation($3400, $2800)

	//set color for second logo
	//eka pala
	//start char: 14,6
	//end char 18,9

	lda #2
	ldx #20
	!loop:
		sta $d800+14+6*40, x
		sta $d800+14+7*40, x
		sta $d800+14+8*40, x

		dex
		bne !loop-

	//toka pala
	//start 0, 14
	//end 11, 15
	lda #2
	ldx #20
	!loop:
		sta $d800+0+14*40, x
		sta $d800+0+15*40, x

		dex
		bne !loop-

	//kolams start 12, 14
	//end 18, 15
	lda #2
	ldx #10
	!loop:
		sta $d800+21+14*40, x
		sta $d800+21+15*40, x

		dex
		bne !loop-

	//neljäs start 5, 21
	lda #12
	ldx #10
	!loop:
		sta $d800+8+21*40, x
		sta $d800+8+22*40, x
		sta $d800+8+23*40, x
		dex
		bne !loop-



!skipadvance:
	lda introstate
	cmp #0
	bne !notstate0+

	jsr introstate0
	jmp !done+

!notstate0:
	jsr introstate1

!done:
	:InterruptEnd()

	rts

introstate0:
	//fadein
	lda currenttimeleftlo 
	cmp #255-15
	bcc !done+
	//currenttimeleft >= 240
	sec
	lda #255
	sbc currenttimeleftlo
	tax
	lda colorrampup, x
	jsr screencolor

!done:
	rts

introstate1:
	lda currenttimelefthi
	bne !done+
	ldx currenttimeleftlo
	cpx #15
	bcs !done+

	//currenttimeleft <= 15
	lda colorrampdown, x
	jsr screencolor

!done:
	rts


screencolor:
	ldx #00
	!fadeout:
		sta $d800, x
		sta $d900, x
		sta $da00, x
		sta $db00, x
		dex
		bne !fadeout-
	rts

initpicture1:
	lda #<data.groupcharsetdata1map
	sta pictureptrsrc
	lda #>data.groupcharsetdata1map
	sta pictureptrsrc+1

	//fill in image
	.const destoff1 = logoy * 40 + logox
	.const destscreen1 = $0400 + destoff1

	lda #<destscreen1
	sta pictureptrdst
	lda #>destscreen1
	sta pictureptrdst+1

	ldx #logoheight
!copyloop:
	txa
	pha
	ldy #0
!copyline:
	lda (pictureptrsrc), y
	sta (pictureptrdst), y

	iny
	cpy #20
	bne !copyline- 

	.const advance = 40
	clc
	lda pictureptrsrc
	adc #logowidth
	sta pictureptrsrc
	lda pictureptrsrc+1
	adc #0
	sta pictureptrsrc+1

	lda pictureptrdst
	adc #advance
	sta pictureptrdst
	lda pictureptrdst+1
	adc #0
	sta pictureptrdst+1

	pla
	tax
	dex
	bne !copyloop-

	rts

initpicture2:

	lda #emptychar
	ldx #0
	!clear:
		sta $3400, x
		sta $3500, x
		sta $3600, x
		sta $3700, x
		dex
		bne !clear-

	lda #<data.groupcharsetdata2map
	sta pictureptrsrc
	lda #>data.groupcharsetdata2map
	sta pictureptrsrc+1

	//fill in image
	.const destoff2 = logoy2 * 40 + logox2
	.const destscreen2 = $3400 + destoff2

	lda #<destscreen2
	sta pictureptrdst
	lda #>destscreen2
	sta pictureptrdst+1

	ldx #logoheight2
!copyloop:
	txa
	pha
	ldy #0
!copyline:
	lda (pictureptrsrc), y
	sta (pictureptrdst), y

	iny
	cpy #18
	bne !copyline- 

	.const advance2 = 40
	clc
	lda pictureptrsrc
	adc #logowidth2
	sta pictureptrsrc
	lda pictureptrsrc+1
	adc #0
	sta pictureptrsrc+1

	lda pictureptrdst
	adc #advance2
	sta pictureptrdst
	lda pictureptrdst+1
	adc #0
	sta pictureptrdst+1

	pla
	tax
	dex
	bne !copyloop-

	rts

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

colorrampdown:
.byte 1, 1, 1, 1, 1, 15, 15, 12, 12, 11, 11, 0, 0
colorrampup:
.byte 0, 0, 11, 11, 12, 12, 15, 15, 1, 1, 1, 1, 1
}