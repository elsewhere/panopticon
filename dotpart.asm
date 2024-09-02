.pc = * "Dotpart"


.namespace dotpart
{
.const globalcolor1 = 2
.const globalcolor2 = 12
.const sprite0color = 0 
.const sprite1color = 0 
.const sprite2color = 0 
.const sprite3color = 0 
.const sprite4color = 0 
.const sprite5color = 0 
.const sprite6color = 0 
.const sprite7color = 0 

.const musicraster = $7f
.const irqdebug = false

.const xcoord = 45
.const ycoord = 30
.const charsetdata = $2800
.const charptr = $e0

.const tilpey = 100
.const tilpex = 100

/*
	32x8 charmode =  256x64

	1. valitaan oikea rivi merkkejä: 
		row = y >> 3
	2. valitaan oikea merkki = (y >> 3) * 32 + (x >> 3)
		char = (row * 32) + (x >> 3)
	3. osoitin oikealle riville
		ptr = char * 256 + (y & 7)
	4. bitmaski taulukosta


	//y coord = [0, 64]
	//x coord = [0, 256]

	lda xcoord
	and #7
	sta temp
	tay 		//y = x & 7
	lda ycoord
	and #7
	sta temp2


	ldx ycoord
	lda yrowtable, x //(row*32)

	clc
	ldx xcoord
	adc shift3table, x //a = (row * 32) + (x >> 3)
	//a = char

	//a = oikea merkki ja x-koordinaatilla voidaan valita oikea bitmask taulukosta. Kuinka osoittaa muistia? 
	ldx bitmasktable, y


*/

init:
	:SetRasterInterrupt(irq, musicraster)

	//clear screen
	lda #00
	jsr clearscreen
	//setup colors
	lda #1
	sta $d021	
	lda #1
	sta $d020

	//setup characters at $3800
	:SetScreenAndCharLocation($0400, charsetdata)

	//clear charset
/*	
	ldx #0
	lda #0
	!clearchars:
//		txa
		sta charsetdata, x
		sta charsetdata+$0100, x
		sta charsetdata+$0200, x
		sta charsetdata+$0300, x
		sta charsetdata+$0400, x
		sta charsetdata+$0500, x
		sta charsetdata+$0600, x
		sta charsetdata+$0700, x

		inx
		bne !clearchars-

	//setup screen
	ldx #0
	lda #0
	ldy #0
	sta temp1
	!setupscreen:
		clc
		lda temp1
		.for (var i = 0; i < 8; i++)
		{
			sta $0400+i*40, x
//			sta $0400+[i+8]*40, x
//			sta $0400+[i+16]*40, x
			tya
		}
		inc temp1
		inx
		cpx #32
		bne !setupscreen-

	:TextScreenColor(0)

	lda #$00
	sta charptr
	lda #$28
	sta charptr+1
*/


	ldx #00
!spritecopyloop:
	lda data.multicolorspritedata, x
	sta $2000, x
	lda data.multicolorspritedata+$100, x
	sta $2100, x
	lda data.multicolorspritedata, x
	sta $2200, x
	lda data.multicolorspritedata+$100, x
	sta $2300, x
	dex
	bne !spritecopyloop-	

	lda #%00010000
	sta $d011		//extended background mode off

	rts

update:
	rts

draw:
	rts
	
cleanup:
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

	//sprite data pointers
//	lda #$00
//	sta $d015


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

	lda #$ff
	sta $d015

	lda #0
	sta $d027

	lda #$ff	
	sta $d01b //priority
	sta $d01d //double width 
	sta $d017 //double heights

	lda #$ff
	sta $d01c //multicolor

	lda #tilpey
	sta $d001
	sta $d003
	sta $d005
	sta $d007
	adc #41
	sta $d009
	sta $d00b
	sta $d00d
	sta $d00f

	//sprite x-positions

	lda #tilpex
	sta $d000
	sta $d008
	adc #48
	sta $d002
	sta $d00a
	adc #48
	sta $d004
	sta $d00c
	adc #48
	sta $d006
	sta $d00e

	//sprite colors
	lda #globalcolor1
	sta $d025 //global color 1
	lda #globalcolor2
	sta $d026 //global color 2 
	lda #sprite0color
	sta $d027
	lda #sprite1color
	sta $d028
	lda #sprite2color
	sta $d029
	lda #sprite3color
	sta $d02a
	lda #sprite4color
	sta $d02b
	lda #sprite5color
	sta $d02c
	lda #sprite6color
	sta $d02d
	lda #sprite7color
	sta $d02e

	jsr effectupdate

	:InterruptEnd()



effectupdate:
	lda #xcoord
	and #7
	sta temp1
	//y vapaana? 
	lda #ycoord
	and #7
	sta temp2

	ldx ycoord
	lda yrowtable, x //(row*32)

	clc
	ldx xcoord
	adc shift3table, x //a = (row * 32) + (x >> 3)
	//a = merkin indeksi 
	tax
	lda charptrtablelo, x
	adc temp2
	sta charptr
	lda charptrtablehi, x
	sta charptr+1

	//charptr oikea merkki ja x-koordinaatilla voidaan valita oikea bitmask taulukosta. Kuinka osoittaa muistia? 
	ldy temp1
	ldy #0
	lda (charptr), y
	ora #$ff//bitmasktable, y
	sta (charptr), y


	//clear out
/*
	ldy #0
	lda #0
	sta (charptr), y
	iny
	sta (charptr), y
	iny
	sta (charptr), y
	iny
	sta (charptr), y
	iny
	sta (charptr), y
	iny
	sta (charptr), y
	iny
	sta (charptr), y
	iny
	sta (charptr), y

	lda framecounterhi
	and #7
	tay 
	lda #$ee
	sta (charptr), y
*/	
	rts

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

shift3table:
.for (var i = 0; i < 256; i++)
{
	.byte i >> 3
}
yrowtable: 
.for (var i = 0; i < 256; i++)
{
	.byte [i >> 3] * 32
}
bitmasktable: 
.byte %00000001
.byte %00000010
.byte %00000100
.byte %00001000
.byte %00010000
.byte %00100000
.byte %01000000
.byte %10000000

.var lo = List()
.var hi = List()
.for (var i =0 ; i < 256; i++)
{
	.var addr = charsetdata + i * 8
	.eval lo.add(<addr)
	.eval hi.add(>addr)
}

charptrtablelo: 
.fill 256, lo.get(i)
charptrtablehi: 
.fill 256, hi.get(i)


}
