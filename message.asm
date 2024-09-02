.pc = * "Message"

.namespace message
{
.const musicraster = 250
.const scrollpos = $80

.const textdrawn = $93
.const state = $90
.const timer = $91
.const fadetimer = $92
.const line_y = $a0

init:
	//clear screen
	//setup colors
	lda #%00000000
	sta $d011		//screen off
	lda #%11001000
	sta $d016
	lda #1
	sta $d021
	lda #1
	sta $d020

	:SetScreenAndCharLocation($0400, $2800)
	:SetCharset(data.fontdata2x2, $2800)

	lda #0
	sta timer
	sta fadetimer
	sta state
	sta textdrawn

	jsr clearscreen

	ldx #0
	lda #1
	!loop:
		sta $d800, x
		sta $d900, x
		sta $da00, x
		sta $db00, x

		dex
		bne !loop-

	:SetRasterInterrupt(irq, musicraster)

	rts

draw:
	ldx fadetimer 
	cpx #25
	bcs !skip+
	//x = rivi

	txa
	asl
	tax //x = 2*timer
	lda ytable2, x
	sta selfmod +1
	lda ytable2+1, x
	sta selfmod +2
	inx
	inx
	lda ytable2, x
	sta selfmod2 +1
	lda ytable2+1, x
	sta selfmod2 +2

	inx
	inx
	lda ytable2, x
	sta selfmod3 +1
	lda ytable2+1, x
	sta selfmod3 +2

	inx
	inx
	lda ytable2, x
	sta selfmod4 +1
	lda ytable2+1, x
	sta selfmod4 +2

	ldy #0
	!fillloop:
		lda #0
		selfmod:
		sta $1234, y
		lda #11
		selfmod2:
		sta $1234, y
		lda #12
		selfmod3:
		sta $1234, y

		lda #15
		selfmod4:
		sta $1234, y

		iny
		cpy #40
		bne !fillloop-
!skip:

//	lda #%00010000
//	sta $d011		//extended background mode off

	lda #%00010000
	sta $d011		//extended background mode off

	//why does this prevent a crash? ?
	ldx #$ff
!delay:
	nop
	nop
	nop
	nop
	nop
	dex
	bne !delay-

	rts
	
cleanup:
	rts

irq:
	:InterruptStart()
	asl $d019 //acknowledge interrupt
	jsr demoflowupdate

	lda textdrawn
	bne !skip+

	lda #<text
	sta stringlinepointer+1
	lda #>text
	sta stringlinepointer+2 
	jsr inittext
	inc textdrawn

!skip:


	inc timer

	lda state
	bne !skip+
	jsr updatestate0
	jmp !done+
!skip:
	cmp #1
	bne !skip+
	jsr updatestate1
	jmp !done+

!skip:
	//state 2
	jsr updatestate2

!done:


	:InterruptEnd()

updatestate0:
	//fadeup
	lda timer
	lsr
	lsr
	sta fadetimer
	cmp #40
	bcc !skip+
	inc state
	lda #0
	sta timer
!skip:

	rts

updatestate1:
	//fade red
	lda timer
	sta fadetimer

	cmp #35
	bcc !skip+
	inc state
	lda #0
	sta timer

!skip:

	ldx #0
	lda #6
	!col:
		sta $d800+23*40+5, x
		sta $d800+24*40+5, x
		inx
		cpx fadetimer
		bcc !col-

	rts

updatestate2:
	//do nothing
	rts

inittext:
	ldx #1
	!loop:
		stx line_y
		txa
		pha
		jsr drawstring
		pla
		tax
		inx
		inx
		cpx #24
		bcc !loop-
/*
	lda #0
	ldx #0
	!loop:
		sta $d800, x
		sta $d900, x
		sta $da00, x
		sta $db00, x
		dex
		bne !loop-
*/
	rts

//y = line_y
drawstring:
	lda line_y
	asl //16bit
	tax

	//top row
	lda ytable, x
	sta offs1+1
	sta offs2+1
	lda ytable+1, x
	sta offs1+2
	sta offs2+2

	//bottom row
	inx
	inx
	lda ytable, x
	lda ytable, x
	sta offs3+1
	dec offs3+1   //-1
	sta offs4+1
	lda ytable+1, x
	sta offs3+2
	sta offs4+2

	ldx #0
!writeline:
	txa
	asl
	tay				//y = 2*x = offsetti, koska 2x2 fontti
stringlinepointer: 
	lda text, x
/*
	cmp #$ff
	bne !nowrap+
	//we have reached the end, wrap text

	lda #<text
	sta stringlinepointer+1
	lda #>text
	sta stringlinepointer+2
	ldx #0
	lda #0
	!clean:
		sta $0400+24*40, x

		inx
		cpx #40
		bne !clean-
	rts
*/
!nowrap:
	asl
	asl
	adc #0
	offs1:
	sta $0000, y
	adc #1
	iny
	offs2:
	sta $0000, y
	adc #1
	offs3:
	sta $0000, y
	adc #1
	offs4:
	sta $0000, y
	inx
	cpx #20
	bne !writeline-
	jmp !done+

!done:
	clc
	lda stringlinepointer+1
	adc #20
	sta stringlinepointer+1
	lda stringlinepointer+2
	adc #0
	sta stringlinepointer+2
	rts

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


upramp:
.byte 1, 1, 1, 1, 15, 15, 12, 12, 1, 1, 0, 0

ytable:
.for (var i = 0; i < 25; i++)
{
	.var val = $0400 + i * 40
	.byte <val
	.byte >val
}

ytable2:
.for (var i = 0; i < 30; i++)
{
	.var val2 = $d800 + i * 40
	.byte <val2
	.byte >val2

}

text:
.text "as the unity of the "
.text "modern world becomes"
.text "increasingly a techn"
.text "ological rather than"
.text "a social affair, the"
.text "techiques of the art"
.text "s provide the most  "
.text "valuable means of in"
.text "sight into the real "
.text "direction of our own"
.text "collective process  "
.text "    marshall mcluhan"

.byte $ff

}