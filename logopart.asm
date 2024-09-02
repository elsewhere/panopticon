//sprite = 24x21 -> kuvan resoluutio 96x42

.pc = * "Logopart"

.var logopartirqdebug = true
.var logopos_x = $80
.var logopos_xhi = $81
.var logopos_y = $82
.var logocolor = $83
.var logocolorindex = $84
.var logosyncindex = $85

.const logoflashinterval = 64
.const logoflashlength = 40

logopart_init:
	:SetExtendedCharset(blockcharsetdata, $3800)
	//setup characters at $3800
	lda #%00011110
	sta $d018

	lda #0	
	lda #35
	jsr clearscreen
	
	//sprites data at $2000
	ldx #00
!spritecopyloop:
	lda logospritedata, x
	sta $2000, x
	lda logospritedata+$100, x
	sta $2100, x
	dex
	bne !spritecopyloop-
	
	lda #$00
	sta $d01c //multicolor
	sta $d01b //priority
	lda #$ff
	sta $d01d //double width 
	sta $d017 //double heights

	//$d025 = sprite extra color (only bits 0..3)
	//$d026 = sprite extra color (only bits 0..3)
	//$d027 = sprite 0 color
	//$d028 = sprite 1 color
	
	lda #$ff
	sta $d015		//turn on all sprites
	lda #$1b
	sta $d011
	
	//init separate irq
	:SetRasterInterrupt(logopart_irq, $c0)

	lda #logoflashinterval
	sta framecountdown
	lda #0
	sta logocolor
	sta logocolorindex
	sta logosyncindex
	
	lda #6
	sta $d021
	
	rts
	
logopart_update:	
	rts

logopart_cleanup:
	lda #0
	sta $d015
	rts
	
logopart_draw:
	rts

.macro RotateCharByte(byte)
{
	lda $3800+35*8+byte
	asl
	bcc !skip+
	ora #1
!skip:
	sta $3800+35*8+byte
	
}
	
logopart_irq:
	asl $d019 //acknowledge interrupt
	jsr demoflowupdate
	
	:RotateCharByte(0)
	:RotateCharByte(1)
	:RotateCharByte(2)
	:RotateCharByte(3)
	:RotateCharByte(4)
	:RotateCharByte(5)
	:RotateCharByte(6)
	:RotateCharByte(7)

	//animate sync
	lda logosyncindex
	beq !nosync+ //!=0
	dec logosyncindex

!nosync:

	lda framecountdown
	bne logopart_skipsync1	//!= 0

	//sync logo
	lda #0
	sta logocolorindex
	lda #logoflashinterval
	sta framecountdown
	lda #logoflashlength-1
	sta logosyncindex
	
logopart_skipsync1:
	//set logo position
	
	ldx logocolorindex
	cpx #6
	beq skip_logofadeup
	inx
	stx logocolorindex
	
skip_logofadeup:
	lda logocolorramp, x
	sta logocolor

	lda #80
	sta logopos_y
	ldx framecounterlo
	lda logosinus, x
	sta logopos_x
	
	//sprite colors
	lda logocolor
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e
	
	//sprite x-positions
	:SetLogopartSpritePos(0)	
	:SetLogopartSpritePos(1)	
	:SetLogopartSpritePos(2)	
	:SetLogopartSpritePos(3)	
	:SetLogopartSpritePos(4)	
	:SetLogopartSpritePos(5)	
	:SetLogopartSpritePos(6)	
	:SetLogopartSpritePos(7)	
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
	
	pla
	tay
	pla
	tax
	pla
	rti

//parametrit:
//x = spriten numero
.macro SetLogopartSpritePos(spritenum)
{
	//set y
	ldx logosyncindex
	lda logopos_y
	.if (spritenum >= 4)
	{
		adc #41
	}

	adc sprite_pathy + spritenum*logoflashlength, x 
	sta $d001+spritenum*2

	//set x
	lda logopos_x
	clc
	adc sprite_pathx + spritenum*logoflashlength, x
	adc spritepositions_x + spritenum
	sta $d000 + spritenum*2
	lda $d010 //high bits

	bcc !skip_carry+
	ora sprite_ormask + spritenum
	jmp !skip_carry2+

	!skip_carry:
	and sprite_andmask + spritenum
	!skip_carry2:
	sta $d010
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

spritepositions_x:
	.byte 00, 1*46, 2*46, 3*46, 00, 1*46, 2*46, 3*46

logosinus:
	.fill 256,round(127.5+63*sin(2*toRadians(i*360/256)))-32

logocolorramp:
.byte 0, 11, 12, 15, 9, 7, 1

sprite_pathx:
	.fill logoflashlength, round(15-15*cos(2*toRadians(i*360/256)))
	.fill logoflashlength, round(13-13*cos(2*toRadians(2*i*360/256)))
	.fill logoflashlength, round(20-20*cos(2*toRadians(i*360/256)))
	.fill logoflashlength, round(15-15*cos(4*2*toRadians(i*360/256)))
	.fill logoflashlength, round(15-15*cos(2*2*toRadians(i*360/256)))
	.fill logoflashlength, round(20-20*cos(4*toRadians(i*360/256)))
	.fill logoflashlength, round(20-20*cos(2*2*toRadians(i*360/256)))
	.fill logoflashlength, round(10-10*cos(4*2*toRadians(i*360/256)))

sprite_pathy:
	.fill logoflashlength, round(30-30*cos(2*toRadians(i*360/256)))
	.fill logoflashlength, round(25-25*cos(2*toRadians(2*i*360/256)))
	.fill logoflashlength, round(40-40*cos(2*toRadians(i*360/256)))
	.fill logoflashlength, round(15-15*cos(3*2*toRadians(i*360/256)))
	.fill logoflashlength, round(15-15*cos(2*2*toRadians(i*360/256)))
	.fill logoflashlength, round(20-20*cos(2*toRadians(i*360/256)))
	.fill logoflashlength, round(20-20*cos(2*2*toRadians(i*360/256)))
	.fill logoflashlength, round(15-15*cos(3*2*toRadians(i*360/256)))

	
logospritedata:

.var logopic = LoadPicture("gfx/brslogo.gif")
	:readSprite(logopic, 0, 0)
	:readSprite(logopic, 1, 0)
	:readSprite(logopic, 2, 0)
	:readSprite(logopic, 3, 0)
	:readSprite(logopic, 0, 1)
	:readSprite(logopic, 1, 1)
	:readSprite(logopic, 2, 1)
	:readSprite(logopic, 3, 1)
