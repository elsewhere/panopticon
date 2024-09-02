.pc = * "Sphere"


.namespace sphere
{
.const globalcolor1 = 1
.const globalcolor2 = 2
.const spritecolor = 0

.const irqdebug = false

.const irq_raster0 = $10
.const irq_raster1 = $c8

.const tilpex = 140
.const tilpey = 130

.const sphereoffset = $80

.const sphereoffset2lo = $81
.const sphereoffset2 = $82
.const spheretilpecolor = $b1
.const spheretilpecolorindex = $b2
.const spheretilpecountdown = $b3
.const spheretilpepath = $b4

.const scroller_xpos = $86
.const scroller_charflip = $87
.const scroller_y = 22
.const scroller_speed = 3

.const irqstate = $88
.const state = $90
.const frames = $91

.const result = $c0
.const testvalue = $c1

.const codegenloop = $e0
.const codegentemp1 = $e2
.const codegentemp2 = $e4
.const codegenptr = $e6
.const codegendataptr1 = $e8
.const codegendataptr2 = $ea
.const codegenscreenptr = $ec
.const codegencolorptr = $ee
.const codegenscreenptr2 = $f0

.const spheretilpelength = 40
.const usefade = true

.const test4x4 = true
.const generatedcodeaddress = $e000
.const usecodegen = false

.var spherex = 3
.var spherewidth = 30
.var spherey = 2
.var sphereheight = 20


.var tablex = spherewidth 
.var tabley = sphereheight


.if (test4x4)
{
	.eval spherex = 0
	.eval spherewidth = 40 //in characters5
	.eval spherey = 8
	.eval sphereheight = 10

	.eval tablex = spherewidth * 2
	.eval tabley = sphereheight * 2
}

.var sphereborder1 = spherey-1//2
.var sphereborder2 = spherey + sphereheight //+ 1

.macro MovetableSphere2(screenptr, dataptr1, dataptr2)
{
	.const testbit = [1 << 6]
	ldy #0
	ldx #0
!xloop: 
	//bit0 = oikea alakulma
	//bit1 = vasen alakulma
	//bit2 = oikea yläkulma
	//bit3 = vasen yläkulma 
	lda #0
	sta result
	stx temp3

	//vasen ylä
	lda dataptr1, y
	adc sphereoffset2
	tax
	lda sphere.spheresin, x

	adc dataptr2, y
	adc sphereoffset
	cmp #testbit
	rol result		//insert bit from carry

	//oikea ylä
	lda dataptr1+1, y
	adc sphereoffset2
	tax
	lda sphere.spheresin, x
	adc dataptr2+1, y

	adc sphereoffset
	cmp #testbit
	rol result

	//vasen ala
	lda dataptr1+tablex, y
	adc sphereoffset2
	tax
	lda sphere.spheresin, x
	adc dataptr2+tablex, y

	adc sphereoffset
	cmp #testbit
	rol result

	//oikea ala
	lda dataptr1+tablex+1, y
	adc sphereoffset2
	tax
	lda sphere.spheresin, x
	adc dataptr2+tablex+1, y
	adc sphereoffset
	cmp #testbit
	lda result
	rol //carry from last operation, special case

	ldx temp3
	sta screenptr, x
	and #2
	sta screenptr+$d400, x
	iny
	iny
	inx
	cpx #spherewidth
	bne !xloop-
}

init:
	//clear screen
	lda #00
	jsr clearscreen
	//setup colors
	lda #1
	sta $d021	
	lda #1
	sta $d020

	:SetScreenAndCharLocation($0400, $2800)
	:SetCharset(data.fontdata2x2, $2000)

/*
	ldx #00
!spritecopyloop:
	lda data.illuminatidata, x
	sta $2000, x
	lda data.illuminatidata+$100, x
	sta $2100, x
	lda data.illuminatidata, x
	sta $2200, x
	lda data.illuminatidata+$100, x
	sta $2300, x
	dex
	bne !spritecopyloop-	
*/
/*
	ldx #00
!spritecopyloop:
	lda data.multicolorspritedata, x
	sta $3000, x
	lda data.multicolorspritedata+$100, x
	sta $3100, x
	lda data.multicolorspritedata, x
	sta $3200, x
	lda data.multicolorspritedata+$100, x
	sta $3300, x
	dex
	bne !spritecopyloop-	
*/
	ldx #00
!spritecopyloop:
	lda data.multicolorspritedata, x
	sta $3000, x
	lda data.multicolorspritedata+$100, x
	sta $3100, x
	lda data.multicolorspritedata, x
	sta $3200, x
	lda data.multicolorspritedata+$100, x
	sta $3300, x
	dex
	bne !spritecopyloop-	

	lda #%00010000
	sta $d011		//extended background mode off

	.if (test4x4)
	{
		ldx #0
		!init4x4:
			lda data.charset4x4, x
			sta $2800, x

			inx 
			cpx #16*8
			bne !init4x4-

		lda #[1 << 6]
		sta testvalue

		ldx #0
		!initborder:
			lda data.sphereborder, x
			sta $2800+16*8, x
			inx
			cpx #8
			bne !initborder-

//		:TextScreenColor(5)

		//codegenptr osoittaa koodiin
		.if (usecodegen)
		{
			jsr generatecode
		}
	}
/*
	.if (startfrom == 5)
	{
		ldy #0
		!processtable:

			ldx #0
			!xloop:
				!addr1:
				lda spiral.angletable_data, x
				asl
				asl
				!addr2:
				sta spiral.angletable_data, x

				inx
				cpx #tablex
				bne !xloop-

			clc
			lda !addr1- +1
			adc #tablex
			sta !addr1- +1
			lda !addr1- +2
			adc #0
			sta !addr1- +2

			lda !addr2- +1
			adc #tablex
			sta !addr2- +1
			lda !addr2- +2
			adc #0
			sta !addr2- +2

			iny
			cpy #tabley
			bne !processtable-
	}
*/
	lda #0
	sta frames
	sta state
	sta irqstate
	sta spheretilpepath

	sta scroller_xpos
	sta scroller_charflip

	ldx #0
!scrollersetup:
	lda #0
	sta $d800+scroller_y*40, x
	sta $d800+[scroller_y+1]*40, x

	inx
	cpx #40
	bne !scrollersetup-
	//scroller fade
	lda #1
	sta $d800+[scroller_y+1]*40
	sta $d800+scroller_y*40
	sta $d800+[scroller_y+1]*40+38
	sta $d800+scroller_y*40+38
	lda #15
	sta $d800+[scroller_y+1]*40+1
	sta $d800+scroller_y*40+1
	sta $d800+[scroller_y+1]*40+38-1
	sta $d800+scroller_y*40+38-1
	lda #12
	sta $d800+[scroller_y+1]*40+2
	sta $d800+scroller_y*40+2
	sta $d800+[scroller_y+1]*40+38-2
	sta $d800+scroller_y*40+38-2
	lda #11
	sta $d800+[scroller_y+1]*40+3
	sta $d800+scroller_y*40+3
	sta $d800+[scroller_y+1]*40+38-3
	sta $d800+scroller_y*40+38-3

	ldy #0
	!processtable:

		ldx #0
		!xloop:
			!addr1:
			lda spiral.angletable_data, x
			asl
			asl
			!addr2:
			sta spiral.angletable_data, x

			inx
			cpx #tablex
			bne !xloop-

		clc
		lda !addr1- +1
		adc #tablex
		sta !addr1- +1
		lda !addr1- +2
		adc #0
		sta !addr1- +2

		lda !addr2- +1
		adc #tablex
		sta !addr2- +1
		lda !addr2- +2
		adc #0
		sta !addr2- +2

		iny
		cpy #tabley
		bne !processtable-

	ldx #0
	!border:
		lda #16
		sta $0400 + 40*[sphereborder1], x
		sta $0400 + 40*[sphereborder2], x
		lda #0
		sta $d800 + 40*[sphereborder1], x
		sta $d800 + 40*[sphereborder2], x
		inx
		cpx #40
		bne !border-

	:SetRasterInterrupt(irq, irq_raster0)
	rts

draw:
	.if (test4x4)
	{
		.if (usecodegen)
		{
			jsr generatedcodeaddress
		}
		else
		{
			lda state
			bne !skip+
			rts //no draw if state == 0

			!skip:
			.var t = *
			.for (var i = 0; i < sphereheight; i++)
			{
				.var xoff = spherex
				.var screenoffset = 40*[i+spherey] +xoff
				.var tableoffset = tablex * 2 * i

				:MovetableSphere2($0400 + screenoffset, 
								 spiral.angletable_data+tableoffset,
								 spiral.perspectivetable_data+tableoffset)

			}
			.var t2 = *
			.print "sphere code size = " + [t2-t]
		}

	}
	rts
	
cleanup:
	lda #0
	sta $d011
	rts

irq:
	:InterruptStart()
	asl $d019 //acknowledge interrupt

//	jsr irq0

	lda irqstate
	bne !skip+

	jsr irq0
	jmp irq_done
!skip:
	cmp #1
	bne !skip+
	jsr irq1
!skip:

irq_done:
	:InterruptEnd()


irq0:
	jsr demoflowupdate
	:SetScreenAndCharLocation($0400, $2800)

	//reset scrolling
	lda #$c0
	sta $d016

	.if (irqdebug)
	{
		lda #2
		sta $d020
	}

	//scroll border
	ldx #7
	!scrollborder:
		clc
		lda $2800+16*8, x
		rol
		bcc *+4//!skip+
		ora #1
//		!skip:
		sta $2800+16*8, x
		dex
		bpl !scrollborder-

	clc
	lda frames
	adc #1
	sta frames
	cmp #$30
	bne !skip+
	inc state 

!skip:
	//move the effect
	lda sphereoffset
	adc #3
	sta sphereoffset
	
	clc
	lda sphereoffset2lo
	adc #$f0
	sta sphereoffset2lo
	lda sphereoffset2
	adc #0
	sta sphereoffset2

	//sprite data pointers
	lda #$c0+0
	sta $07f8
	lda #$c0+1
	sta $07f9
	lda #$c0+2
	sta $07fa
	lda #$c0+3
	sta $07fb
	lda #$c0+4
	sta $07fc
	lda #$c0+5
	sta $07fd
	lda #$c0+6
	sta $07fe
	lda #$c0+7
	sta $07ff

	lda #$ff
	sta $d015

	lda #$00	
	sta $d01b //priority
	lda #$00
	sta $d01d //double width 
	sta $d017 //double heights
	lda #$ff
	sta $d01c //multicolor


	.const ysize = 21
	.const xsize = 24
	//sprite y

	ldx spheretilpepath
	inx
	stx spheretilpepath

	clc
	lda #tilpey
	adc path_y, x

	sta $d001
	sta $d003
	sta $d005
	sta $d007
	clc
	adc #ysize
	sta $d009
	sta $d00b
	sta $d00d
	sta $d00f

	//sprite x

	clc
	lda #tilpex
	adc path_x, x
	sta $d000
	sta $d008
	clc
	adc #xsize
	sta $d002
	sta $d00a
	clc
	adc #xsize
	sta $d004
	sta $d00c
	clc
	adc #xsize
	sta $d006
	sta $d00e

	//sprite colors
	lda #globalcolor1
	sta $d025 //global color 1
	lda #globalcolor2
	sta $d026 //global color 2 
	lda #spritecolor
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e

	lda #irq_raster1
	sta $d012
	inc irqstate

//	lda #4
//	sta $d020

	rts

irq1:
//	lda #6
//	sta $d020

	//set characters
	:SetScreenAndCharLocation($0400, $2000)

	lda scroller_xpos
	sec
	sbc #scroller_speed
	and #$07
	sta scroller_xpos
	bcs !dontmovescroll+	

	//copy 
	ldx #0
!movescroller:
	lda $0400+[scroller_y]*40 + 1,x
	sta $0400+[scroller_y]*40,x
	lda $0400+[scroller_y+1]*40 + 1,x
	sta $0400+[scroller_y+1]*40,x
	inx
	cpx #40
	bne !movescroller-

	//insert new 
scrollerselfmod: 
	lda scrolltext
	cmp #$ff
	bne !insertnew+

	//insert empty after we have gone past the end of the scroller
	lda #0
	sta $0400+[scroller_y]*40+39
	sta $0400+[scroller_y]*40+39+40

	jmp !dontmovescroll+
!insertnew:
	//insert new character from the string 
	ldx scroller_charflip	//which side? 
	beq !otherhalf+	

	asl
	asl
	adc #1
	sta $0400+[scroller_y]*40+39
	adc #2
	sta $0400+[scroller_y+1]*40+39
	inc scroller_charflip

	// Advance textpointer
	clc
	lda scrollerselfmod+1
	adc #1
	sta scrollerselfmod+1
	lda scrollerselfmod+2
	adc #0
	sta scrollerselfmod+2

	jmp !dontmovescroll+

!otherhalf:
    dec scroller_charflip

	asl
	asl
	sta $0400+[scroller_y]*40+39
	adc #2
	sta $0400+[scroller_y+1]*40+39

!dontmovescroll:
	lda #$c0
	ora scroller_xpos
	sta $d016


	lda #0
	sta irqstate
	lda #irq_raster0
	sta $d012

	rts

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

spheresin:
.fill 256, 31.5 + 31*sin(toRadians(i*360*2/256))

path_y:
.fill 256, floor(8*[0.5*sin(toRadians(i*360*2/256))+0.5*cos(toRadians(i*360*5/256))])

path_x:
.fill 256, floor(10*[0.5*cos(toRadians(i*360*3/256))+0.5*cos(toRadians(i*360*2/256))])

scrolltext:

.text " take their horses                   "
.text " let them crawl                   "
.text " put them in their cages                  "
.text " thats righteous for the soul "
.byte $ff

}
