.pc = * "Demologo"

.namespace demologo
{
.const musicraster = 190

.const irqdebug = false
.const logoy = 1
.const logox = 3
.const logoheight = 16
.const logowidth = 34

.const updatepos = $81
.const updatepos2 = $82
.const loopcnt = $83
.const frame = $84

.const scrollerx = 147
.const scrollery = 159

.const pictureptrsrc = $90
.const pictureptrdst = $94

.const titlestate = $a0
.const fadebuf = $e000

init:
	:SetRasterInterrupt(irq, musicraster)
	//clear screen
	lda #%00000000
	sta $d011		// off
	lda #0
	jsr clearscreen

	//setup colors
	lda #1
	sta $d021	
	sta $d020
	lda #0
	sta $d021

	lda #11
	sta $d022
	lda #12
	sta $d023

	lda #<scrolltext
	sta scrolltextptr
	lda #>scrolltext
	sta scrolltextptr+1

	//fill in image
	.const destoff = logoy * 40 + logox
	.const destscreen = $0400 + destoff

	lda #<data.logocharset1map
	sta pictureptrsrc
	lda #>data.logocharset1map
	sta pictureptrsrc+1

	lda #<destscreen
	sta pictureptrdst
	lda #>destscreen
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
	cpy #logowidth
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

	ldx #0
	lda #9
!setcolor:
	sta $d800, x
	sta $d900, x
	sta $da00, x
	sta $db00, x

	dex
	bne !setcolor-

	ldx #0
	lda #0
	!clearbuf:
		sta fadebuf, x
		inx
		cpx #$ff
		bne !clearbuf-

	:SetScreenAndCharLocation($0400, $2800)
	:SetCharset(data.logocharset1, $2800)

	lda #%00010000
	sta $d011		//extended background mode off
	lda #%11011000
	sta $d016

	lda #0
	sta updatepos
	sta updatepos2
	sta titlestate
	sta frame
	sta spritescrollframe

	ldx #0
	lda #0
	!spriteclear:
		sta $2000, x
		sta $2100, x
		sta $2200, x
		sta $2300, x
		sta $2400, x
		sta $2500, x
		sta $2600, x
		sta $2700, x

		inx
		bne !spriteclear-

	rts

update:
	rts

draw:

	rts
	
cleanup:
	lda #%00000000
	sta $d011		//extended background mode off
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


	lda titlestate
	cmp #0
	bne !titlestate1+
	jsr updatestate0
	jmp !done+

!titlestate1:
	lda titlestate
	cmp #1
	bne !titlestate2+
	jsr updatestate1
	jmp !done+

!titlestate2:
	jsr updatestate2
	jmp !done+

!done:
/*
	ldx #0
	!color:
		ldy fadebuf, x //
		lda colorramp, y
		sta $d800+logoy*40, x
		sta $d800+[logoy+1]*40, x
		sta $d800+[logoy+2]*40, x
		sta $d800+[logoy+3]*40, x
		sta $d800+[logoy+4]*40, x
		sta $d800+[logoy+5]*40, x

		inx
		cpx #40
		bne !color-
*/
	//sprite data pointers
//	lda #$00
//	sta $d015

	:InterruptEnd()

updatestate0:
	clc
	lda frame
	adc #1
	sta frame
	cmp #15
	bne !skip+
	inc titlestate
!skip:
	rts

updatestate1:
	//update fadein
	jsr updatescroller

	ldx #0
	!loop:
		stx temp1
		//temp1 = x
		sec
		lda updatepos
		sbc temp1 		//updatepos - x
		bmi !out+		//not yet reached

		cmp #9
		bcc !skip+
		lda #9	//a = min(a, 5)
		!skip:
		sta fadebuf, x

		inx
		cpx updatepos
		bcc !loop- //if x < updatepos
	!out:
	lda #0
	!loop2:
		sta fadebuf, x
		inx
		cpx #49
		bcc !loop2-

	lda updatepos
	cmp #49
	beq !skip+
	inc updatepos
	lda updatepos
	lsr
	sta updatepos2
	!skip:

	lda currenttimelefthi
	cmp #0
	bne !done+
	lda currenttimeleftlo
	cmp #16 //16 fadeout
	bne !done+
	inc titlestate

!done:

	rts

updatestate2:
	lda currenttimelefthi
	bne !done+
	ldx currenttimeleftlo
	cpx #15
	bcs !done+

	//currenttimeleft <= 15
	lda colorrampout, x
	ldx #0
	!loop:
		sta fadebuf, x
		inx
		cpx #40
		bne !loop-

	!done:

	rts

updatescroller:
	lda #%11110000
	sta $d015
	lda #2
	sta $d02c
	sta $d02d
	sta $d02e
	lda #$00
	sta $d01b //priority

	lda #$0//3f
	sta $d01d //double width 
	sta $d017 //double heights

	//sprites 5-7
	lda #scrollerx
	sta $d00a
	lda #scrollerx+24
	sta $d00c
	lda #scrollerx+48
	sta $d00e

	lda #scrollery
	sta $d00b
	sta $d00d
	sta $d00f

	lda #$80+5
	sta $07fd
	lda #$80+6
	sta $07fe
	lda #$80+7
	sta $07ff
	jsr updatespritescroll
//	inc spritescrollframe
	rts


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
colorramp:
.byte 1, 1, 15, 15, 12, 12, 11, 11, 0, 0

colorrampout:
.byte 1, 1, 15, 15, 15, 12, 12, 12, 11, 11, 11, 2, 2, 0, 0, 0, 0

curve:
.byte 1, 15, 15, 12, 12, 11, 11, 0

scrolltext:
.text "ipsa scientia potestas est revision mmiv"
.byte $ff

}