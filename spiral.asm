.pc = * "Spiral"

.namespace spiral
{
.const spiraloffset = $80

.const spiraloffset2lo = $81
.const spiraloffset2 = $82
.const spiraltilpecolor = $b1
.const spiraltilpecolorindex = $b2
.const spiraltilpecountdown = $b3

.const result = $c0
.const state = $c2
.const statetimer = $c3
.const fadetimer = $c4

.const codegenloop = $e0
.const codegentemp1 = $e2
.const codegentemp2 = $e4
.const codegenptr = $e6
.const codegendataptr1 = $e8
.const codegendataptr2 = $ea
.const codegenscreenptr = $ec
.const codegencolorptr = $ee
.const codegenscreenptr2 = $f0

.const spiraltilpelength = 40
.const tilpey = 210
.const usefade = false

.const test4x4 = true
.const generatedcodeaddress = $e000
.const usecodegen = true
.const generatedchunksize = 72

.var spiralx = 3
.var spiralwidth = 30
.var spiraly = 2
.var spiralheight = 20

.var tablex = spiralwidth 
.var tabley = spiralheight

.if (test4x4)
{
	.eval spiralx = 0
	.eval spiralwidth = 40 //in characters5
	.eval spiraly = 8
	.eval spiralheight = 10

	.eval tablex = spiralwidth * 2
	.eval tabley = spiralheight * 2
}


/*
	4x4 bitti jokaiselle kvadrantille
		16 eri merkkiä

         ___________
		|     |     |
		|  3  |  2  |
		|_____|_____|
		|     |     |
		|  1  |  0  |
		|_____|_____|

//bit0 = oikea alakulma
//bit1 = vasen alakulma
//bit2 = oikea yläkulma
//bit3 = vasen yläkulma 
*/

.macro MovetableSpiral2(screenptr, dataptr1, dataptr2)
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
	stx temp3

	//vasen ylä
	lda dataptr1, y
	adc spiraloffset2
	tax
	lda spiral.spiralsin, x

	adc dataptr2, y
	adc spiraloffset
	cmp #testbit
	rol result		//insert bit from carry

	//oikea ylä
	lda dataptr1+1, y
	adc spiraloffset2
	tax
	lda spiral.spiralsin, x
	adc dataptr2+1, y

	adc spiraloffset
	cmp #testbit
	rol result

	//vasen ala
	lda dataptr1+tablex, y
	adc spiraloffset2
	tax
	lda spiral.spiralsin, x
	adc dataptr2+tablex, y

	adc spiraloffset
	cmp #testbit
	rol result

	//oikea ala
	lda dataptr1+tablex+1, y
	adc spiraloffset2
	tax
	lda spiral.spiralsin, x
	adc dataptr2+tablex+1, y
	adc spiraloffset
	cmp #testbit
	lda result
	rol //carry from last operation, special case

	ldx temp3
//	sta screenptr-5*40, x
//	sta screenptr+5*40, x
	sta screenptr, x
	and #2
	sta screenptr+$d400, x
	iny
	iny
	inx
	cpx #spiralwidth
	bne !xloop-
}

init:
	:SetRasterInterrupt(default_irq, 10)
	//clear screen
	lda #%00000000
	sta $d011		//screen off
	
	lda #0 //clearcolor
	jsr clearscreen
	sta $d015
	
	//setup colors
	lda #1
	sta $d021
	lda #4
	sta $d022
	lda #6
	sta $d023
	lda #11
	sta $d024
	:TextScreenColor(1)
	
	lda #1
	sta $d020

	:SetScreenAndCharLocation($0400, $2800)

	.if (test4x4)
	{
		ldx #0
		!init4x4:
		lda data.charset4x4, x
		sta $2800, x

		inx 
		cpx #16*8
		bne !init4x4-

		ldx #$00
		!initchars1:
			lda data.spiralborderchars1, x
			sta $2800+16*8, x
			lda data.spiralborderchars1+$100, x
			sta $2800+16*8+$100, x
			dex
			bne !initchars1-

		ldx #$00
		!initchars2:
			lda data.spiralborderchars2, x
			sta $2800+100*8, x
			lda data.spiralborderchars2+$100, x
			sta $2800+100*8+$100, x
			dex
			bne !initchars2-


		:TextScreenColor(1)

		//codegenptr osoittaa koodiin
		.if (usecodegen)
		{
			jsr generatecode
		}
	}

	//spritedata = $2000
	//sprite data pointers
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
	lda #%11000000
	sta $d015		//turn on all sprites

	lda #$00
	sta $d017 //double heights
	sta $d01d //double width 
	sta $d01c //multicolor
	sta $d01b //priority

	lda #0
	sta spiraltilpecolor
	sta spiraltilpecolorindex
	sta state
	sta statetimer
	sta fadetimer

	lda #1 //will be decremented
	sta spiraltilpecountdown

	lda #$ff
	sta framecountdown	

	//sprites data at $2000
	ldx #00
	lda #0
!spritecopyloop:
	sta $2000, x
	sta $2100, x
	dex
	bne !spritecopyloop-	

	//top border
	//320x40 = 40*5 = 200 chars
	ldx #0
	!borderloop:
		lda data.spiralbordermap1, x
		sta $0400 + [spiraly-5]*40, x
		inx
		cpx #200
		bne !borderloop-

	//bottom border
	//320x32 = 160 chars
	ldx #0
	!borderloop:
		lda data.spiralbordermap2, x
		sta $0400 + [spiraly+spiralheight]*40, x
		inx
		cpx #160
		bne !borderloop-
	:SetRasterInterrupt(irq, 10)
	lda #%00010000
	sta $d011		//disable extended background mode

	rts
	
update:
	rts
	
draw:
	lda state
	beq !skip+
	jsr generatedcodeaddress
!skip:
	rts
	
cleanup:
	lda #0
	sta $d015
	rts
	
irq:
	:InterruptStart()

	asl $d019 //acknowledge interrupt
	jsr demoflowupdate

	lda state
	cmp #0
	bne !state1+
	jsr updatestate0
	jmp !done+

!state1:
	cmp #1
	bne !state2+
	jsr updatestate1
	jmp !done+

!state2:
	jsr updatestate2

!done:
	:InterruptEnd()

updatestate0:
//	lda #6
//	sta $d020
//	jsr updatespiral
//	jsr updatespritescroll

	ldx #0
	lda #1
	ldx #39
	!clearloop:
		.for (var i = 0; i < spiralheight; i++)
		{
			sta $d800 + [spiraly+i]*40, x
		}
		dex
		bpl !clearloop-
	clc
	lda statetimer
	adc #1
	sta statetimer
	cmp #41
	bcc !skip+	//jump if less
	inc state //move to state 1
!skip:
	//clear

	sec
	lda statetimer
//	sbc #3
	sta fadetimer

	ldx #0
	lda #0

	!borderloop:
		sta $d800 + [spiraly-5]*40, x
		sta $d800 + [spiraly-4]*40, x
		sta $d800 + [spiraly-3]*40, x
		sta $d800 + [spiraly-2]*40, x
		sta $d800 + [spiraly-1]*40, x
		inx
		cpx fadetimer
		bmi !borderloop-
/*
	lda #11
	sta $d800 + [spiraly-5]*40, x
	sta $d800 + [spiraly-4]*40, x
	sta $d800 + [spiraly-3]*40, x
	sta $d800 + [spiraly-2]*40, x
	sta $d800 + [spiraly-1]*40, x
	inx

	lda #12
	sta $d800 + [spiraly-5]*40, x
	sta $d800 + [spiraly-4]*40, x
	sta $d800 + [spiraly-3]*40, x
	sta $d800 + [spiraly-2]*40, x
	sta $d800 + [spiraly-1]*40, x
	inx

	lda #15
	sta $d800 + [spiraly-5]*40, x
	sta $d800 + [spiraly-4]*40, x
	sta $d800 + [spiraly-3]*40, x
	sta $d800 + [spiraly-2]*40, x
	sta $d800 + [spiraly-1]*40, x
	inx
*/
	//bottom border
	//320x32 = 160 chars
	ldx #0
	lda #0
	!borderloop:
		sta $d800 + [spiraly+spiralheight]*40, x
		sta $d800 + [spiraly+spiralheight+1]*40, x
		sta $d800 + [spiraly+spiralheight+2]*40, x
		sta $d800 + [spiraly+spiralheight+3]*40, x
		inx
		cpx fadetimer
		bmi !borderloop-
	rts

updatestate1:
//	lda #2
//	sta $d020
	jsr updatespiral
//	jsr updatespritescroll

	lda currenttimelefthi
	bne !skip+
	lda currenttimeleftlo
	cmp #40
	bcs !skip+ //jump if greater
	//40 frames left, move to last state
	inc state
!skip:
	rts

updatestate2:
//	lda #3
//	sta $d020
	jsr updatespiral
//	jsr updatespritescroll
	rts


updatespiral:
	//move the effect
	lda spiraloffset
	adc #3
	sta spiraloffset
	
	clc
	lda spiraloffset2lo
	adc #$a0
	sta spiraloffset2lo
	lda spiraloffset2
	adc #0
	sta spiraloffset2

	dec spiraltilpecountdown
	bne !tilpe_sync_ok+
	lda #0
	sta spiraltilpecolorindex
	lda #spiraltilpelength
	sta spiraltilpecountdown
	
!tilpe_sync_ok:
	
	//sprite colors
	ldx spiraltilpecolorindex
	lda spiraltilpecolorramp, x
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e
	
	cpx #6
	beq !skip+
	inc spiraltilpecolorindex
!skip:

	//sprite y-positions
	lda #tilpey
	sta $d001
	sta $d003
	sta $d005
	sta $d007
	sta $d009
	sta $d00b
	sta $d00d
	sta $d00f

	lda framecountdown
	bne !skip+
	lda #$ff
	sta framecountdown

!skip:

	lda #200
	sta $d00c
	lda #224
	sta $d00e

	rts

.macro insert()
{
	sta (codegenptr), y
	iny
}
.var codegenstart = *

generatecode:
.if (usecodegen)
{
	//init pointers on zero page
	lda #<generatedcodeaddress
	sta codegenptr
	lda #>generatedcodeaddress
	sta codegenptr+1

	lda #<perspectivetable_data
	sta codegentemp1
	lda #>perspectivetable_data
	sta codegentemp1+1

	lda #<angletable_data
	sta codegentemp2
	lda #>angletable_data
	sta codegentemp2+1

	//temp1 = dataptr1
	//temp2 = dataptr2

	.var screenoffset = $0400 + 40*[spiraly]

	lda #<screenoffset
	sta codegenscreenptr
	lda #>screenoffset
	sta codegenscreenptr+1

	lda #<screenoffset+$d400
	sta codegencolorptr
	lda #>screenoffset+$d400
	sta codegencolorptr+1

	//all pointers are in place, generate spiralheight lines of code
	lda #0
	sta codegenloop

!generateall:
	lda codegentemp1
	sta codegendataptr2
	lda codegentemp1+1
	sta codegendataptr2+1

	lda codegentemp2
	sta codegendataptr1
	lda codegentemp2+1
	sta codegendataptr1+1
	
	ldy #0
	jsr generatecodeline
	//increase pointers

	clc
	lda codegenptr
	adc #generatedchunksize				//generoidun rutiinin koko
	sta codegenptr
	bcc !+
	inc codegenptr+1
	!:
	clc

	.const off = 40
	clc
	lda codegenscreenptr
	adc #off
	sta codegenscreenptr
	bcc !+
	inc codegenscreenptr+1
	!:
	clc

	lda codegencolorptr
	adc #off
	sta codegencolorptr
	bcc !+
	inc codegencolorptr+1
	!:
	clc

	lda codegentemp1
	adc #tablex*2
	sta codegentemp1
	bcc !+
	inc codegentemp1+1
	!:
	clc

	lda codegentemp2
	adc #tablex*2
	sta codegentemp2
	bcc !+
	inc codegentemp2+1
	!:

	clc
	lda codegenloop
	adc #1
	sta codegenloop
	cmp #spiralheight
	bne !generateall-

	//final rts
	ldy #0
	lda #RTS
	sta (codegenptr), y

	rts
}

generatecodeline:
.if (usecodegen)
{
	.const testbit = [1 << 7]
	//ldy #0
	lda #LDY_IMM
	:insert()
	lda #0
	:insert()

	//ldx #0
	lda #LDX_IMM
	:insert()
	lda #0
	:insert()
//xloop:
	//lda #0
	lda #LDA_IMM
	:insert()
	lda #0
	:insert()
	//sta result
	lda #STA_ZP
	:insert()
	lda #result
	:insert()

	//lda dataptr1, y
	lda #LDA_ABSY
	:insert()
	lda codegendataptr1
	:insert()
	lda codegendataptr1+1
	:insert()

	//adc dataptr2, y
	lda #ADC_ABSY
	:insert()
	lda codegendataptr2
	:insert()
	lda codegendataptr2+1
	:insert()

	//adc spiraloffset
	lda #ADC_ZP
	:insert()
	lda #spiraloffset
	:insert()

	//cmp #testbit
	lda #CMP_IMM
	:insert()
	lda #testbit
	:insert()
	//rol result
	lda #ROL_ZP
	:insert()
	lda #result
	:insert()

	//dataptr1 ja dataptr2 lisätään yhdellä

	clc
	inc codegendataptr1
	lda codegendataptr1+1
	adc #0
	sta codegendataptr1+1
	inc codegendataptr2
	lda codegendataptr2+1
	adc #0
	sta codegendataptr2+1

	//lda dataptr1, y
	lda #LDA_ABSY
	:insert()
	lda codegendataptr1 
	:insert()
	lda codegendataptr1+1
	:insert()

	//adc dataptr2, y
	lda #ADC_ABSY
	:insert()
	lda codegendataptr2
	:insert()
	lda codegendataptr2+1
	:insert()

	//adc spiraloffset
	lda #ADC_ZP
	:insert()
	lda #spiraloffset
	:insert()

	//cmp #testbit
	lda #CMP_IMM
	:insert()
	lda #testbit
	:insert()
	//rol result
	lda #ROL_ZP
	:insert()
	lda #result
	:insert()

	//dataptr1 ja dataptr2 lisätään tablesizellä
	clc
	lda codegendataptr1
	adc #tablex-1
	sta codegendataptr1	
	lda codegendataptr1+1
	adc #0
	sta codegendataptr1+1

	lda codegendataptr2
	adc #tablex-1
	sta codegendataptr2	
	lda codegendataptr2+1
	adc #0
	sta codegendataptr2+1

	//lda dataptr1, y
	lda #LDA_ABSY
	:insert()
	lda codegendataptr1
	:insert()
	lda codegendataptr1+1
	:insert()

	//adc dataptr2, y
	lda #ADC_ABSY
	:insert()
	lda codegendataptr2
	:insert()
	lda codegendataptr2+1
	:insert()

	//adc spiraloffset
	lda #ADC_ZP
	:insert()
	lda #spiraloffset
	:insert()

	//cmp #testbit
	lda #CMP_IMM
	:insert()
	lda #testbit
	:insert()
	//rol result
	lda #ROL_ZP
	:insert()
	lda #result
	:insert()

	//dataptr1 ja dataptr2 lisätään yhdellä
	clc
	inc codegendataptr1
	lda codegendataptr1+1
	adc #0
	sta codegendataptr1+1
	inc codegendataptr2
	lda codegendataptr2+1
	adc #0
	sta codegendataptr2+1

	//lda dataptr1, y
	lda #LDA_ABSY
	:insert()
	lda codegendataptr1
	:insert()
	lda codegendataptr1+1
	:insert()

	//adc dataptr2, y
	lda #ADC_ABSY
	:insert()
	lda codegendataptr2
	:insert()
	lda codegendataptr2+1
	:insert()

	//adc spiraloffset
	lda #ADC_ZP
	:insert()
	lda #spiraloffset
	:insert()

	//cmp #testbit
	lda #CMP_IMM
	:insert()
	lda #testbit
	:insert()
	//lda result
	lda #LDA_ZP
	:insert()
	lda #result
	:insert()
	//rol 
	lda #ROL
	:insert()
	//sta screenptr, x
	lda #STA_ABSX
	:insert()
	lda codegenscreenptr
	:insert()
	lda codegenscreenptr+1
	:insert()

	//and #2
	lda #AND_IMM
	:insert()
	lda #2
	:insert()
	//sta screenptr+$d400, x

	lda #STA_ABSX
	:insert()
	lda codegencolorptr
	:insert()
	lda codegencolorptr+1
	:insert()

	//iny
	lda #INY
	:insert()
	//iny
	lda #INY
	:insert()

	//inx
	lda #INX
	:insert()

	//cpx #spiralwidth
	lda #CPX_IMM
	:insert()
	lda #spiralwidth
	:insert()

	//bne !xloop-
	lda #BNE_REL
	:insert()
	lda #-68
	:insert()

	rts
	.var codegenend = *

//	.print "code generator size = " + [codegenend - codegenstart]
}


/*
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

	//vasen ylä
	lda dataptr1, y
	adc dataptr2, y
	adc spiraloffset
	cmp #testbit
	rol result		//insert bit from carry

	//oikea ylä
	lda dataptr1+1, y
	adc dataptr2+1, y
	adc spiraloffset
	cmp #testbit
	rol result

	//vasen ala
	lda dataptr1+tablex, y
	adc dataptr2+tablex, y
	adc spiraloffset
	cmp #testbit
	rol result

	//oikea ala
	lda dataptr1+tablex+1, y
	adc dataptr2+tablex+1, y
	adc spiraloffset
	cmp #testbit
	lda result
	rol //carry from last operation, special case

	sta screenptr, x
	and #2
	sta screenptr+$d400, x
	iny
	iny
	inx
	cpx #spiralwidth
	bne !xloop-
*/

//		(zero page, x)	
//		//zero pagella siis taulukko pointtereita ja x on indeksi niihin
//		lda ($50, x) //a = muisti(ptr[$50 + x])
//		tällä voi siis lukea muistista pointterin arvon
//		byte a = muisti[zeropage[arvo+x]]
//
//		lda ($14), y //a = muisti(ptr[$14] + y)
//		zero pagella pointteri ja y on offsetti siihen
//		
//		654b
//		6591

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/*
chunkstart:
	ldy #0
	ldx #0
!xloop:
	lda #0
	sta result
	lda $0000, y
	lda $0000, y
	adc spiraloffset
	cmp #$80
	rol result
	lda $0000, y
	lda $0000, y
	adc spiraloffset
	cmp #$80
	rol result
	lda $0000, y
	lda $0000, y
	adc spiraloffset
	cmp #$80
	rol result
	lda $0000, y
	lda $0000, y
	adc spiraloffset
	cmp #$80
	lda result
	rol
	sta $0000, x
	and #2
	sta $0000, x
	iny
	iny
	inx
	cpx #spiralwidth
	bne !xloop-
chunkend:
*/


//scrolltext:
//.text " that became spirals of self modifying code and the sinking feeling of a surrender "
//.byte $ff


spiralsin:
.fill 256, 127.5 + 127*sin(toRadians(i*360*2/256))

spiraltilpecolorramp:
//.byte 1, 7, 9, 15, 12, 11, 0
.byte 0, 11, 12, 15, 9, 7, 0

.var angletableData = List()
.var perspectivetableData = List()
.var sqrttableData = List()

.for (var y = 0; y < tabley; y++)
{
	.for (var x = 0; x < tablex; x++)
	{
		.var x2 = x - [tablex/2]
		.var y2 = y - [tabley/2]
		.var s = sqrt(x2*x2 + y2*y2)
		.var angle = atan2(y2,x2)
		.var d = s*s*s/4//16
		.if (d < 0)
		{
			.eval d = 0
		}
		else .if (d > 255)
		{
			.eval d = 255
		}
		.eval sqrttableData.add(d)
		.eval angletableData.add(angle*256/3.141592)
		.eval perspectivetableData.add(2048 / s)
//		.eval tunneltableData.add( [[[[angle*16] / 3.141592]&15] << 4] | [[256 / s]&15])	
	}
}

sqrttable_data:
.if (usefade)
{
	.fill tablex*tabley, sqrttableData.get(i)
}

perspectivetable_data:
.fill tablex*tabley, perspectivetableData.get(i)

angletable_data:
.fill tablex*tabley, angletableData.get(i)
}

