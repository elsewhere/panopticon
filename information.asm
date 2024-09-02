
.pc = * "Information"

.namespace information
{
.const scrollframe = $80
.const framecount = $81

.const state = $82

.const tilpex = 135
.const tilpey = 64
.const tilpewidth = 24

.const picturex = 12
.const picturey = 0
.const picturewidth = 16
.const pictureheight = 25

.const pictureptrsrc = $90
.const colorptrsrc = $92
.const pictureptrdst = $94
.const colorptrdst = $96

.const main_irq_raster = $00
.const irq_split = $80
.const irqstate = $83

.const plasmax = 181
.const plasmay = 239
.const plasmawidth = 7
.const plasmaheight = 6
.const plasmacolor = $a9
.const a1 = $a0
.const a2 = $a2
.const a3 = $a4
.const a4 = $a6
.const plasmacolortimer = $aa
.const plasmacolorindex = $ab

.const s1 = $70
.const s2 = $41
.const s3 = $2f
.const s4 = $9e

.const xbuf = $e000
.const ybuf = $f000
.const plasma_addr1 = $3000
.const plasma_addr2 = $3000 + 64


init:
	:SetRasterInterrupt(irq, main_irq_raster)
	//clear screen
	lda #0//clearcolor
	ldx #0
!clearloop:
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $0700, x
	dex 
	bne !clearloop-
	
	lda #$00
	sta $d01b
	sta $d01c
	//setup characters at $3800
	:SetScreenAndCharLocation($0400, $2800)
//	:SetExtendedCharset(data.fontdata1x1+2, $2800)
	:SetCharset(data.infocharset, $2800)

	lda #0
	sta state
	sta irqstate

	lda #0
	sta $d021
	lda #1
	sta $d020
	lda #2
	sta plasmacolor
	lda #0
	sta plasmacolortimer
	sta plasmacolorindex

	:TextScreenColor(1)

	//fill in image
	//source pointers
	lda #<data.infopicturemap
	sta pictureptrsrc
	lda #>data.infopicturemap
	sta pictureptrsrc+1

	lda #<data.infocolormap
	sta colorptrsrc
	lda #>data.infocolormap
	sta colorptrsrc+1

	.const destoff = picturex + picturey * 40
	.const destscreen = $0400 + destoff
	.const destcolor = $d800 + destoff

	//dest pointers
	lda #<destscreen
	sta pictureptrdst
	lda #>destscreen
	sta pictureptrdst+1
	lda #<destcolor
	sta colorptrdst
	lda #>destcolor+1
	sta colorptrdst+1

	ldx #pictureheight
!copyloop:
	txa
	pha
	ldy #0
!copyline:
	lda (pictureptrsrc), y
	sta (pictureptrdst), y
	lda (colorptrsrc), y
	sta (colorptrdst), y

	iny
	cpy #16
	bne !copyline- 

	.const off = 40// - picturewidth
	clc

	lda pictureptrsrc
	adc #16
	sta pictureptrsrc
	lda pictureptrsrc+1
	adc #0
	sta pictureptrsrc+1

	lda pictureptrdst
	adc #off
	sta pictureptrdst
	lda pictureptrdst+1
	adc #0
	sta pictureptrdst+1

	lda colorptrsrc
	adc #16
	sta colorptrsrc
	lda colorptrsrc+1
	adc #0
	sta colorptrsrc+1

	lda colorptrdst
	adc #off
	sta colorptrdst
	lda colorptrdst+1
	adc #0
	sta colorptrdst+1

	pla
	tax
	dex
	bne !copyloop-

	ldx #00
	lda #00
!spriteclear:
	sta $2000, x
	sta $2100, x
	dex
	bne !spriteclear-

ldx #$7f
lda #$ff
!spritewhite:
	sta $2280, x
	dex
	bne !spritewhite-

	//scroller borders
/*
 	lda #$ff
 	.for (var sprite = 0; sprite < 8; sprite++)
 	{
	 	sta $2000+sprite*64+18
	 	sta $2000+sprite*64+19
	 	sta $2000+sprite*64+20
	 	sta $2000+sprite*64+48
	 	sta $2000+sprite*64+49
	 	sta $2000+sprite*64+50
	 }
*/
	lda #0
	sta framecount

	lda #%00011000
	sta $d011		//extended background mode off


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
	lda #0
	sta $d011		//extended background mode off
	rts
	
irq:
	:InterruptStart()

	asl $d019 //acknowledge interrupt

	lda irqstate
	bne !irqstate1+
	jsr irq0
	inc irqstate
	jmp !irqdone+

!irqstate1:
	jsr irq1
	lda #0
	sta irqstate

!irqdone:

	:InterruptEnd()		




irq0:
	jsr demoflowupdate
	jsr updatescroller

	lda state
	bne !not_state0+

	//state 0
	clc
	lda framecount
	adc #1
	sta framecount
	cmp #$ff
	bne !done+
	inc state

	jmp !done+

!not_state0:
	cmp #1
	bne !not_state1+
	jmp !done+

!not_state1:


!done:
	//set up split
	lda #irq_split
	sta $d012
	rts

irq1:

	lda state
	beq !state0+
	//state 1, have plasma
	lda #%10111111
	sta $d015 //on
	jsr updateplasma
	jmp !done+

!state0:
	lda #%00111111
	sta $d015 //on
!done:

	//cover background
	lda #$80+$a
	sta $07f8
	sta $07f9
	sta $07fa
	sta $07fb
	sta $07fc
	sta $07fd

	//small plasma at $3000
	lda #$c0
	sta $07fe
	lda #$c0
	sta $07ff

	lda #$7f
	sta $d01d //double width 

	.const startx1 = 0
	.const starty = 240
	.const addx = 48
	.const startx2 = 224
	lda #startx1
	sta $d000
	clc
	adc #addx
	sta $d002
	clc
	adc #addx
	sta $d004

	lda #startx2
	sta $d006
	clc
	adc #addx
	sta $d008
	clc
	adc #addx
	sta $d00a
//	clc
//	adc #addx
//	sta $d00c

	lda #starty
	sta $d001
	sta $d003
	sta $d005
	sta $d007
	sta $d009
	sta $d00b

	lda #plasmax
	sta $d00c
	sta $d00e
	lda #plasmay
	sta $d00d
	sta $d00f

	lda #%00110000
	sta $d010

	//sprite colors
	lda #1
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	ldx plasmacolorindex
	lda plasmacolortable, x
	sta $d02d
//	adc #1
	sta $d02e

	cpx #0
	beq !skip+
	dex
	stx plasmacolorindex

	!skip:

	//set up main 
	lda #main_irq_raster
	sta $d012
	rts


updatescroller:
	//sprite setup
	lda #$3f
	sta $d015 //on
	lda #$00
	sta $d017 //double heights
	sta $d01d //double width 
	sta $d01c //multicolor

	//sprite colors
	lda #1
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e

	//sprite pointers
	//spritedata = $2000
	lda #$80+0
	sta $07f8
	lda #$80+1
	sta $07f9
	lda #$80+2
	sta $07fa
	lda #$80+3
	sta $07fb
	lda #$80+4
	sta $07fc
	lda #$80+5
	sta $07fd
	lda #$80+6
	sta $07fe
	lda #$80+7
	sta $07ff

	lda #tilpex
	sta $d000
	clc
	adc #tilpewidth
	sta $d002
	clc
	adc #tilpewidth
	sta $d004
	clc
	adc #tilpewidth
	sta $d006
	clc
	adc #tilpewidth

	lda #tilpey
	sta $d001
	sta $d003
	sta $d005
	sta $d007

	lda #0
	sta $d010


	//sprite scroll
	clc
	lda scrollframe
	adc #1
	cmp #8
	bcs !newletter+
	jmp !skip+
!newletter:
	lda scrolltext
	cmp #$ff
	bne !nowrap+

	//wrap text
	lda #<scrolltext
	sta !newletter- + 1
	lda #>scrolltext
	sta !newletter- + 2
	jmp !newletter-
!nowrap:
	//font data offset wraps around at charindex > 32
	asl
	asl
	asl
	tax

	.for (var i = 0; i < 8; i++)
	{
		//upper left
		.const offset = 47 //start indexing from this, kludgee1111!
		lda data.fontdata1x1 + offset*8 + i + 2, x //fontissa jotain paskaa alussa 2 tavua
		sta $2000+8*64 + i * 3 + 24
 	}

	//advance textpointer

	clc
	lda !newletter- + 1
	adc #1
	sta !newletter- + 1
	lda !newletter- + 2
	adc #0
	sta !newletter- + 2

	lda #0
!skip:
	sta scrollframe

	.for (var y = 8; y < 16; y++)
	{
		//muistista sprite seiskaan
		//sprite seiskasta sprite kutoseen
		clc
		.for (var sprite = 8; sprite >= 0; sprite--)
		{
			rol $2000+sprite*64 + 2 + y * 3 
			rol $2000+sprite*64 + 1 + y * 3
			rol $2000+sprite*64 + 0 + y * 3 
		}
	}
	rts

updateplasma:

	//clear srpites
	ldx #64
	lda #0
	!clearloop:
		sta plasma_addr1, x
		sta plasma_addr2, y
		dex
		bne !clearloop-


	clc
	lda a1
	adc #s1
	sta a1
	lda a1+1
	adc #0
	sta a1+1

	lda a2
	adc #s2
	sta a2
	lda a2+1
	adc #0
	sta a2+1

	lda a3
	adc #s3
	sta a3
	lda a3+1
	adc #0
	sta a3+1

	lda a4
	adc #s4
	sta a4
	lda a4+1
	adc #0
	sta a4+1

	lda currenttimeleftlo
	sta temp1

	ldx #0
	!plasmax:
		txa
		adc a1+1
		tay
		lda sintable, y
		sta temp1
		txa
		adc a2+1
		tay
		lda sintable, y
		adc temp1

		sta xbuf, x
		inx
		cpx #plasmawidth
		bne !plasmax-

	ldx #0
	!plasmay:
		txa
		adc a3+1
		tay
		lda sintable, y
		sta temp1
		txa
		adc a4+1
		tay
		lda sintable, y
		adc temp1
		sta ybuf, x
		inx
		cpx #plasmaheight
		bne !plasmay-

	ldy #0
	!yloop:
		lda ybuf, y
		sta temp2
		ldx #0
		stx temp3 //temp3 = result
		stx temp4 //temp4 = result2

		!xloop:
			lda temp2
			adc xbuf, x

			//a = plasmaval
			and #%10000000 //test bit
			beq !nobit+
			//bit set
			//tämä on x:s bitti
			lda temp3
			ora ormask, x
			sta temp3
			jmp !donebit+

		!nobit:
			//bit not set 
			lda temp4
			ora ormask, x
			sta temp4

		!donebit:
			inx
			cpx #plasmawidth
			bne !xloop-

		//temp3 = result
		tya
		asl
		tax

		lda plasma_addrtable1, x
		sta selfmod1+1
		lda plasma_addrtable2, x
		sta selfmod2+1
		inx
		lda plasma_addrtable1, x
		sta selfmod1+2
		lda plasma_addrtable2, x
		sta selfmod2+2

		lda temp3
		selfmod1:
		sta plasma_addr1, y//(plasmadstptr), y

		lda temp4
		selfmod2:
		sta plasma_addr2, y

		iny
		cpy #plasmaheight
		bne !yloop-

	clc
	lda plasmacolortimer
	adc #1
	cmp #70
	bcc !skip+
		//next color
		lda #9
		sta plasmacolorindex
		lda #0

	!skip:
	sta plasmacolortimer

	rts

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

plasmacolortable:
.byte 2, 2, 11, 11, 12, 12, 15, 15, 1, 1

ormask:
.byte %10000000
.byte %01000000
.byte %00100000
.byte %00010000
.byte %00001000
.byte %00000100
.byte %00000010
.byte %00000001

plasma_addrtable1:
.for (var i = 0; i < plasmaheight; i++)
	.word plasma_addr1 + i * 2

plasma_addrtable2:
.for (var i = 0; i < plasmaheight; i++)
	.word plasma_addr2 + i * 2


scrolltext:
.text "abbaabababbabbaaabbabaababbabbbaabbaaaab"
.byte $ff


sintable:
.fill 256, 127 + 127*sin(toRadians(8*i*360/256))
}