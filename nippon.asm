
.pc = * "Nippon"

.namespace nippon
{

.const fadein = $81
.const frame = $82
.const irqstate = $84
.const result = $90
.const nipponmove = $91

.const sourceptr = $e0
.const destptr = $e6
.const codegendataptr1 = $e8
.const codegenscreenptr = $ec
.const codegencolorptr = $ee
.const codegenaddress = $e000
.const usecodegen = true

.const y = [25-5]/2

.const scroller_xpos = $86
.const scroller_charflip = $87
.const scroller_y = 21
.const scroller_speed = 3

.const irqdebug = false
.const irq_raster0 = $10
.const irq_raster1 = $30
.const irq_raster2 = $c0

.const radius = 60
.const spritex = 160 - radius/2 - 5
.const spritey = 100 - radius/2 + 20

.const colorrampsize = 12
.const nipponimagex = 0
.const nipponimagewidth = 40 //in characters5
.const nipponimagey = 8
.const nipponimageheight = 10
.const tablex = nipponimagewidth * 2
.const tabley = nipponimageheight * 2


.macro MovetableNippon(screenptr, dataptr1, dataptr2)
{
	.const testbit = [1 << 7]
	ldy #0
	ldx #0
!xloop: 
	//bit0 = oikea alakulma
	//bit1 = vasen alakulma
	//bit2 = oikea yläkulma
	//bit3 = vasen yläkulma 
	lda #0
	sta result

	//lda / sta = 5 kelloa
	//rol zp = 5 kelloa
	//rol mem, x = 7 kelloa
	//4x rol = 8 kellon säästö pitäisi saada että rol mem, x kannattaa
//	stx temp3

	//vasen ylä
	lda dataptr1, y
	adc nipponmove+1
//	adc dataptr2, y
	cmp #testbit
	rol result		//insert bit from carry

	//oikea ylä
	lda dataptr1+1, y
	adc nipponmove+1
//	adc dataptr2+1, y
	cmp #testbit
	rol result

	//vasen ala
	lda dataptr1+tablex, y
	adc nipponmove+1
//	adc dataptr2+tablex, y
	cmp #testbit
	rol result

	//oikea ala
	lda dataptr1+tablex+1, y
	adc nipponmove+1
//	adc dataptr2+tablex+1, y
	cmp #testbit
	lda result
	rol //carry from last operation, special case

//	ldx temp3
	sta screenptr, x
	and #2
	sta screenptr+$d400, x
	iny
	iny
	inx
	cpx #nipponimagewidth
	bne !xloop-
}


init:
	:SetRasterInterrupt(irq, irq_raster0)

	lda #240
	jsr clearscreen
	//setup colors
	lda #1
	sta $d021
	lda #1
	sta $d020

	//setup characters at $3800
	lda #%00010000
	sta $d011		//extended background mode off
	:SetCharset(data.fontdata2x2, $2800)

	//	:SetCharset(charset0, $3000)
	//4x4 gridi = $3000
	ldx #0
	!init4x4:
	lda data.charset4x4, x
	sta $3000, x
	inx 
	cpx #16*8
	bne !init4x4-

	lda #0
	sta fadein
	sta irqstate
	sta scroller_xpos
	sta scroller_charflip
	sta nipponmove
	sta nipponmove+1

	//scroller color
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

	//spritedata = $2000
	//sprite data pointers
	lda #0
	sta $d015
/*
	lda #$80+0
	sta $07f8
	lda #$80+0
	sta $07f9
	lda #$80+0
	sta $07fa
	lda #$80+0
	sta $07fb
	lda #$80+0
	sta $07fc
	lda #$80+0
	sta $07fd
	lda #$80+0
	sta $07fe
	lda #$80+0
	sta $07ff

	lda #$ff
	sta $d01c //multicolor
	lda #$00
	sta $d01b //priority
	sta $d01d //double width 
	sta $d017 //double heights
*/

	//process table
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

	.if (usecodegen)
	{
		jsr generatecode
	}
	rts

draw:
	.if (usecodegen)
	{
		jsr codegenaddress
	}

	else
	{
		.for (var i = 0; i < nipponimageheight; i++)
		{
			.var xoff = nipponimagex
			.var screenoffset = 40*[i+nipponimagey] +xoff
			.var tableoffset = tablex * 2 * i
			:MovetableNippon($0400 + screenoffset, 
							 spiral.angletable_data+tableoffset,
							 spiral.perspectivetable_data+tableoffset)
		}
	}


!skipfade:
	rts
	
cleanup:
	rts

irq:
	:InterruptStart()
	asl $d019 //acknowledge interrupt

	lda irqstate
	bne !skip+

	jsr irq0
	jmp irq_done
!skip:
	cmp #1
	bne !skip+
	jsr irq1

!skip:
	cmp #2
	bne !skip+
	jsr irq2
!skip:


irq_done:
	:InterruptEnd()

irq0:
	jsr demoflowupdate

	.if (irqdebug)
	{
		lda #5
		sta $d020
	}
	clc
	lda nipponmove
	adc #$a0
	sta nipponmove
	lda nipponmove+1
	adc #$2
	sta nipponmove+1

/*
	lda frame
	adc #1
	sta frame

	:SetSpritePos(0, spritex, spritey)
	:SetSpritePos(1, spritex, spritey)
	:SetSpritePos(2, spritex, spritey)
	:SetSpritePos(3, spritex, spritey)
	:SetSpritePos(4, spritex, spritey)
	:SetSpritePos(5, spritex, spritey)
	:SetSpritePos(6, spritex, spritey)
	:SetSpritePos(7, spritex, spritey)

	//shared sprite colors
	lda #0
	sta $d025
	lda #1
	sta $d026 

	//sprite colors
	lda #6
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e
*/
	//clear scrolling
	lda $d016
	and #%11111000
	sta $d016

	lda #1
	sta irqstate
	lda #irq_raster1
	sta $d012
	rts

irq1:	//keskiosa, se missä on efekti 
	.if (irqdebug)
	{
		lda #7
		sta $d020
	}

	//set characters
	:SetScreenAndCharLocation($0400, $3000)

	//setup next irq
	lda #2
	sta irqstate
	lda #irq_raster2
	sta $d012
	rts

irq2:	//alaosa, scrolleri
	.if (irqdebug)
	{
		lda #11
		sta $d020
	}

	//set characters
	:SetScreenAndCharLocation($0400, $2800)

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

	//setup next
	lda #0
	sta irqstate
	lda #irq_raster0
	sta $d012
	rts

/*
.macro SetSpritePos(spritenum, spritex, spritey)
{
	//set y

	clc
	lda index + spritenum
	adc frame
	tax
	lda sinus_y, x
	clc
	adc #spritey
	sta $d001+spritenum*2

	//set x
	clc
	lda index + spritenum
	adc frame
	tax
	lda sinus_x, x
	clc
	adc #spritex
	sta $d000 + spritenum*2
	lda $d010 //high bits

	bcc !skip_carry+
	ora data.sprite_ormask + spritenum
	jmp !skip_carry2+

	!skip_carry:
	and data.sprite_andmask + spritenum
	!skip_carry2:
	sta $d010
}
*/
generatecode:
.if (usecodegen)
{

.var codesize = chunkend - chunkstart

.print "nippon chunk size " + toIntString(codesize) + " bytes"

	//setup pointers
	lda #<codegenaddress
	sta destptr
	lda #>codegenaddress
	sta destptr+1

	lda #<spiral.angletable_data
	sta codegendataptr1
	lda #>spiral.angletable_data
	sta codegendataptr1+1

	.var screenoffset = $0400 + 40*[nipponimagey]
	.var coloroffset =  $d800 + 40*[nipponimagey]

	lda #<screenoffset
	sta codegenscreenptr
	lda #>screenoffset
	sta codegenscreenptr+1

	lda #<coloroffset
	sta codegencolorptr
	lda #>coloroffset
	sta codegencolorptr+1

	ldx #0
!codegen:
	lda #<chunkstart
	sta sourceptr
	lda #>chunkstart
	sta sourceptr+1
	ldy #0
	!copychunk:
		cpy #9 //eka dataptr
		bne !+
		lda codegendataptr1
		sta (destptr), y
		iny
		lda codegendataptr1+1
		sta (destptr), y

		clc
		lda codegendataptr1
		adc #1
		sta codegendataptr1
		lda codegendataptr1+1
		adc #0
		sta codegendataptr1+1

		jmp !next+
	!:
		cpy #18 //toka dataptr
		bne !+
		lda codegendataptr1
		sta (destptr), y
		iny
		lda codegendataptr1+1
		sta (destptr), y

		clc
		lda codegendataptr1
		adc #tablex-1
		sta codegendataptr1
		lda codegendataptr1+1
		adc #0
		sta codegendataptr1+1

		jmp !next+
	!:
		cpy #27 //kolmas dataptr
		bne !+
		lda codegendataptr1
		sta (destptr), y
		iny
		lda codegendataptr1+1
		sta (destptr), y

		clc
		lda codegendataptr1
		adc #1
		sta codegendataptr1
		lda codegendataptr1+1
		adc #0
		sta codegendataptr1+1

		jmp !next+
	!:
		cpy #36 //neljäs dataptr
		bne !+
		lda codegendataptr1
		sta (destptr), y
		iny
		lda codegendataptr1+1
		sta (destptr), y

		//nyt ollaan liikuttu tablex-1, vähennetään tablex
		clc
		lda codegendataptr1
		adc #tablex-1
		sta codegendataptr1
		lda codegendataptr1+1
		adc #0
		sta codegendataptr1+1

		jmp !next+
	!:
		cpy #46 //screenptr
		bne !+
		lda codegenscreenptr
		sta (destptr), y
		iny
		lda codegenscreenptr+1
		sta (destptr), y

		clc
		lda codegenscreenptr
		adc #40
		sta codegenscreenptr
		lda codegenscreenptr+1
		adc #0
		sta codegenscreenptr+1
		jmp !next+
	!:

		cpy #51 //colorptr
		bne !+
		lda codegencolorptr
		sta (destptr), y
		iny
		lda codegencolorptr+1
		sta (destptr), y

		clc
		lda codegencolorptr
		adc #40
		sta codegencolorptr
		lda codegencolorptr+1
		adc #0
		sta codegencolorptr+1
		//default: copy byte	
		
		jmp !next+
	!:
		lda (sourceptr), y
		sta (destptr), y

	!next:
		iny
		cpy #codesize
		beq !done+
		jmp !copychunk-

	!done:

	clc

	lda destptr
	adc #codesize
	sta destptr
	lda destptr+1
	adc #0
	sta destptr+1

	inx
	cpx #nipponimageheight
	beq !done+
	jmp !codegen-
	!done:

	ldy #0
	lda #RTS
	sta (destptr), y

	rts
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

chunkstart:
	ldy #0 //0
	ldx #0 //2
!xloop:
	lda #0 //4
	sta result //6
	lda $0000, y //8
	adc nipponmove+1 //11
	cmp #$80 //13
	rol result //15
	lda $0000, y //17
	adc nipponmove+1 //20
	cmp #$80 //22
	rol result //24
	lda $0000, y //26
	adc nipponmove+1 //29
	cmp #$80 //31
	rol result //33
	lda $0000, y //35
	adc nipponmove+1 //38
	cmp #$80 //40
	lda result //42
	rol //44
	sta $0400, x //45
	and #2 //47
	sta $d800, x //49
	iny
	iny
	inx
	cpx #nipponimagewidth
	bne !xloop-
chunkend:


/*
sinus_x:
.fill 256,round(radius+[radius-1]*sin(2*toRadians(i*360/256)))
sinus_y:
.fill 256,round(radius+[radius-1]*cos(1*toRadians(i*360/256)))
index:
.fill 8, i * 16

.function render(globalangle, xres, yres)
{
	.var pixels = List()
	.for (var y = 0; y < yres; y++)
	{
		.for (var x = 0; x < xres; x++)
		{
			.var x2 = x - [xres / 2]
			.var y2 = y - [yres / 2]
			.var angle = atan2(y2, x2)
			.var d = s5qrt(x2*x2+y2*y2)

			.if (d < 15)
			{
				.eval pixels.add(255)
			}
			else
			{
				.eval pixels.add([2048*[angle+globalangle]/3.1415] & 255)
			}
		}
	}
	.return pixels
}

.function imageToCharset(image)
{
	.var charset = List()
	.for (var y = 0; y < 6; y++)
	{
		.var yoffset = y * 40 * 8*8 //character offset 
		.for (var x = 0; x < 40; x++)
		{
			.var imageoffset = yoffset + [x * 8]
			.for (var i = 0; i < 8; i++)
			{
				.eval charset.add(packCharacter(image, imageoffset + i * 320))
			}
		}
	}
	//empty char in the end 
	.for (var i = 0; i < 8; i++)
	{
		.eval charset.add(0)
	}
	.return charset
}
*/

//.var pixels0 = render(0.0, 320, 48)
/*
.var pixels0 = render(0.00)
.var pixels1 = render(0.01)
.var pixels2 = render(0.02)
.var pixels3 = render(0.03)
.var pixels4 = render(0.04)
.var pixels5 = render(0.05)
.var pixels6 = render(0.06)
.var pixels7 = render(0.07)
*/
//.var charsetdata0 = imageToCharset(pixels0)
/*
.var charsetdata1 = imageToCharset(pixels1)
.var charsetdata2 = imageToCharset(pixels2)
.var charsetdata3 = imageToCharset(pixels3)
.var charsetdata4 = imageToCharset(pixels4)
.var charsetdata5 = imageToCharset(pixels5)
.var charsetdata6 = imageToCharset(pixels6)
.var charsetdata7 = imageToCharset(pixels7)
*/
//charset0:
//.fill 241*8, charsetdata0.get(i)
/*
charset1:
.fill 241*8, charsetdata1.get(i)
charset2:
.fill 241*8, charsetdata2.get(i)
charset3:
.fill 241*8, charsetdata3.get(i)
charset4:
.fill 241*8, charsetdata4.get(i)
charset5:
.fill 241*8, charsetdata5.get(i)
charset6:
.fill 241*8, charsetdata6.get(i)
charset7:
.fill 241*8, charsetdata7.get(i)
*/

scrolltext:

.text " some velvet morning when i am straight "
.text "i am gonna open up your gate "
.text "and maybe tell you bout phaedra "
.text "and how she gave me life "
.text "and how she made it end "
.byte $ff

}