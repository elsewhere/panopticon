.pc = * "Atomic"

.namespace atomic
{
//.const globalcolor1 = 0
//.const globalcolor2 = 11
//.const spritecolor = 12
.const globalcolor1 = 11
.const globalcolor2 = 12
.const spritecolor = 15
.const framecount = $80
.const sequenceptr = $81
.const randomupdate = $83

.const electron1 = $50
.const electron2 = $51
.const electron3 = $52

.const state = $90
.const spritecolorindex = $91

.const eyestate = $92
.const eyetimer = $94

.const atom_x = 165
.const atom_y = 130
.const eyeoffset_x = -10
.const eyeoffset_y = 0
.const dataheight = 8
.const data_y = 9

.const databuffer = $f000
.const sourceptr = $a0
.const destptr = $a2
.const wordptr = $a4
.const worddest = $a6

init:
	:SetRasterInterrupt(irq, $a0)
	//clear screen
	lda #0//clearcolor
	ldx #0
!clearloop:
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $0700, x

	sta databuffer, x
	dex 
	bne !clearloop-
	
	//setup characters at $3800
	:SetScreenAndCharLocation($0400, $2800)
	:SetCharset(data.fontdata1x1+2, $2800)

	lda #%00010000
	sta $d011		//extended background mode off

	lda #1
	sta $d021
	sta $d020

	lda #0
	sta state
	sta framecount
	sta randomupdate
	sta spritecolorindex
//	sta eyestate
//	lda #100
//	sta eyetimer

	:TextScreenColor(11)

	lda #0
	sta electron1
	lda #[256/3]
	sta electron2
	lda #[2*256/3]
	sta electron3

	//sprite setup
	ldx #0
	!spritecopy:
		lda data.atomspritedata, x
		sta $2000, x

		dex
		bne !spritecopy-

	//sprite pointers
	lda #$80+0
	sta $07f8
	lda #$80+1
	sta $07f9
	lda #$80+0
	sta $07fa
	lda #$80+1
	sta $07fb
	lda #$80+0
	sta $07fc
	lda #$80+1
	sta $07fd
	lda #$80+2
	sta $07fe
	lda #$80+3
	sta $07ff

	//sprite colors
	//sprite colors
	lda #globalcolor1
	sta $d025 //global color 1
	lda #globalcolor2
	sta $d026 //global color 2 

	//under text
	lda #$ff
	sta $d01b

	//setup initial data buffer
	lda #<databuffer
	sta sourceptr
	lda #>databuffer
	sta sourceptr+1

	ldx #dataheight
!yloop:
	txa
	pha

	ldy #0
	!xloop:
		jsr getrandom
		and #3
		cmp #0
		bne !+
		//== 0
		lda #'0'
		jmp !next+

		!:
		cmp #1
		bne !+
		//== 1
		lda #'1'
		jmp !next+

		!:
		//isompi luku, tyhjä
		lda #' '

		!next:
		sta (sourceptr), y
		iny
		cpy #40
		bne !xloop-

	clc
	lda sourceptr
	adc #40
	sta sourceptr
	lda sourceptr+1
	adc #0
	sta sourceptr+1

	pla
	tax
	dex
	bne !yloop-

	lda #<words
	sta wordptr
	lda #>words
	sta wordptr+1

	lda #$ff
	sta $d015 //sprites
	lda #%00111111
	sta $d01c //multicolor

	rts
	
draw:
	//open border
/*
	lda #$f9
	cmp $d012
	bne * - 3

	//Trick the VIC and open the border!!
	lda $d011
	and #$f7
	sta $d011

	//Wait until scanline 255
	lda #$ff
	cmp $d012
	bne * - 3

	//Reset bit 3 for the next frame
	lda $d011
	ora #$08
	sta $d011
*/
	rts
	
cleanup:
	rts
	
irq:
	:InterruptStart()
	asl $d019 //acknowledge interrupt

	lda #spritecolor
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e
/*
	//eye
	lda eyestate
	bne !eyestate1+
	lda #$80+2
	sta $07fe
	lda #$80+3
	sta $07ff
	jmp !eyedone+

!eyestate1:
	cmp #1
	bne !eyestate2+
	lda #$80+4
	sta $07fe
	lda #$80+5
	sta $07ff
	jmp !eyedone+

!eyestate2:
	lda #$80+4
	sta $07fe
	lda #$80+5
	sta $07ff

!eyedone:
*/
	inc framecount
	jsr demoflowupdate

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
	jsr updatestate2

!done:

	:InterruptEnd()

updatestate0:
	clc
	ldx spritecolorindex
	cpx #9
	bcs !+
	inx
	stx spritecolorindex
!:
	jsr updateatom
	lda framecount
	cmp #100
	bcc !+

//	lda #100
//	sta eyetimer
	inc state
!:
	rts

updatestate1:
//	jsr updateeye
	jsr updateatom
	jsr updatedata
	lda currenttimelefthi
	bne !+
	lda currenttimeleftlo
	cmp #20
	bcs !+
	inc state
!:
	rts

updatestate2:

	lda #0
	sta $d015
	clc
	ldx spritecolorindex
	cpx #0
	beq !+
	dex
	stx spritecolorindex

!:
	jsr updateatom
//	jsr updatedata

	ldx #0
	lda #1
	!clear:
		sta $d800, x
		sta $d900, x
		sta $da00, x
		sta $db00, x
		dex
		bne !clear-

	lda #0
	jsr clearscreen

	rts
/*
updateeye:
	sec
	lda eyetimer
	sbc #1
	cmp #0
	bne !skip+

	//switch to new state
	lda eyestate
	bne !eyestateskip0+
	//current eyestate == 0
	inc eyestate //switch to state 1
	lda #30
	jmp !skip+

!eyestateskip0:
	cmp #1
	bne !eyestateskip1+
	//current eyestate == 1
	inc eyestate //switch to state 2
	lda #30
	jmp !skip+

!eyestateskip1:
	//current eyestate == 2
	lda #0
	sta eyestate
	lda #100

!skip:
	sta eyetimer
	rts
*/
updateatom:
	//positions
	lda electron1
	clc
	adc #1
	sta electron1
	clc
	adc framecount
	and #127
	tax
	lda atompath1, x
	sta $d000
	lda atompath1+128, x
	sta $d001
	dex
//	dex
	lda atompath1, x
	sta $d002
	lda atompath1+128, x
	sta $d003

	clc
	lda electron2
	adc #1
	sta electron2
	clc
	adc framecount
	and #127
	tax
	lda atompath2, x
	sta $d004
	lda atompath2+128, x
	sta $d005
	dex
//	dex
	lda atompath2, x
	sta $d006
	lda atompath2+128, x
	sta $d007

	clc
	lda electron3
	adc #1
	sta electron3
	clc
	adc framecount
	and #127
	tax
	lda atompath3, x
	sta $d008
	lda atompath3+128, x
	sta $d009
	dex
//	dex
	lda atompath3, x
	sta $d00a
	lda atompath3+128, x
	sta $d00b

	lda #atom_x+eyeoffset_x
	sta $d00c
	clc
	adc #24
	sta $d00e
	lda #atom_y+eyeoffset_y
	sta $d00d
	sta $d00f

	//colors
	ldx spritecolorindex
	lda colorramp, x

	//6, 7 = eye
	sta $d02d
	sta $d02e
/*
	//0, 2, 4 = electron
	sta $d027
	sta $d029
	sta $d02b

	//1, 3, 5 = trail
	lda trailcolorramp, x
	sta $d028
	sta $d02a
	sta $d02c

*/
	//trail


	rts

updatedata:

	//update screen
	.const destoff = $0400+data_y*40
	lda #<databuffer
	sta sourceptr
	lda #>databuffer
	sta sourceptr+1

	lda #<destoff
	sta destptr
	lda #>destoff
	sta destptr+1

	ldx #dataheight
!yloop:
	ldy #0
	!xloop:
		lda (sourceptr), y
		sta (destptr), y

		iny
		cpy #40
		bne !xloop-

	clc
	lda sourceptr
	adc #40
	sta sourceptr
	lda sourceptr+1
	adc #0
	sta sourceptr+1

	lda destptr
	adc #40
	sta destptr
	lda destptr+1
	adc #0
	sta destptr+1

	dex
	bne !yloop-

	//update data

	clc
	lda randomupdate
	adc #1
	sta randomupdate
	cmp #40
	beq !continue+
	jmp !done+ //stupid 128 byte offsets

!continue:
	lda #0
	sta randomupdate

	//switch bits
	lda #<databuffer
	sta sourceptr
	lda #>databuffer
	sta sourceptr+1

	ldx #dataheight
!yloop:
	txa
	pha

	ldy #0
	!xloop:
		jsr getrandom
		and #3
		cmp #0
		bne !+
		//== 0
		lda #'0'
		jmp !next+

		!:
		cmp #1
		bne !+
		//== 1
		lda #'1'
		jmp !next+

		!:
		//isompi luku, tyhjä
		lda #' '

		!next:
		sta (sourceptr), y
		iny
		cpy #40
		bne !xloop-

	clc
	lda sourceptr
	adc #40
	sta sourceptr
	lda sourceptr+1
	adc #0
	sta sourceptr+1

	pla
	tax
	dex
	bne !yloop-

	//write words
	lda #>databuffer
	sta worddest+1

	clc
	jsr getrandom
	adc #<databuffer
	sta worddest
	lda worddest+1
	adc #0
	sta worddest+1

	//TODO: offset > 255

	ldy #0
!wordloop:
	lda (wordptr), y
	iny
	cmp #0
	beq !nextword+	//next word on $00
	cmp #$ff
	bne !noreset+
	//loop into beginning on $ff
	lda #<words
	sta wordptr
	lda #>words
	sta wordptr+1
	jmp !done+
!noreset:
	//a = merkki
	sta (worddest), y
	jmp !wordloop-
!nextword:
	sty temp1
	clc
	lda wordptr
	adc temp1
	sta wordptr
	lda wordptr+1
	adc #0
	sta wordptr+1


!done:		
	rts


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

.function calculateEllipse(count, radius1, radius2, theta)
{
	.var points = List()
	.for (var i = 0; i < count; i++)
	{
		.var t = [i / count] * 2 * 3.141592
		.var x = radius1 * sin(t)
		.var y = radius2 * cos(t)

		.var rot = RotationMatrix(0, 0, theta)
		.var p = Vector(x, y, 0) //* rot
		.eval p = rot * p
		.eval points.add(p)

	}
	.return points
}


atompath1:
.var data1 = calculateEllipse(128, 60, 30, 0)
.fill 128, atom_x + data1.get(i).getX()
.fill 128, atom_y + data1.get(i).getY()

atompath2:
.var data2 = calculateEllipse(128, 60, 30, 1)
.fill 128, atom_x + data2.get(i).getX()
.fill 128, atom_y + data2.get(i).getY()

atompath3:
.var data3 = calculateEllipse(128, 60, -30, -1)
.fill 128, atom_x + data3.get(i).getX()
.fill 128, atom_y + data3.get(i).getY()

words:
.text "i"
.byte 0
.text "spy"
.byte 0
.text "with"
.byte 0
.text "my"
.byte 0
.text "little"
.byte 0
.text "eye"
.byte 0
.text "i"
.byte 0
.text "see"
.byte 0
.text "with"
.byte 0
.text "my"
.byte 0
.text "little"
.byte 0
.text "eye"
.byte $ff

colorramp:
.byte 1, 1, 15, 15, 12, 12, 11, 11, 0, 0

trailcolorramp:
.byte 1, 1, 1, 1, 15, 15, 15, 15, 15
}