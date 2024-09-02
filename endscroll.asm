.pc = * "Endscroll"

.namespace endscroll
{

.const musicraster = 250
.const scrollpos = $80
.const scrollflip = $81
.const scrollframe = $82
.const eyeframe = $83
.const eyetimer = $84
.const eyestate = $85
.const eyecolor = $a2
.const eyeflip = $a3

.const spritecolorindex = $88

.const tilpey = $a0
.const tilpex = $a1

.const x = 7
.const speed = 1
.const irqdebug = false
.const blinkspeed = 5

.const doublesize = false

.const ypos = $86
.const chartemp = $87

.const state = $90
.const timer = $91

init:
	:SetRasterInterrupt(default_irq, musicraster)

	lda #100
	sta tilpex
	sta tilpey

	//clear screen
	lda #32
	jsr clearscreen
	//setup colors
	lda #1
	sta $d021	
	lda #1
	sta $d020

	ldx #0
	!colloop:
		lda #0
		sta $d800, x
		sta $d900, x
		sta $da00, x
		sta $db00, x
		sta $0400, x
		sta $0500, x
		sta $0600, x
		sta $0700, x

		dex
		bne !colloop-

	ldx #0
	!fadeloop:
//		lda #1
//		sta $d800, x
//		sta $d800 + 24*40, x
		lda #1
		sta $d8
		lda #15
		sta $d800 + 0*40, x
		sta $d800 + 24*40, x
		lda #12
		sta $d800 + 1*40, x
		sta $d800 + 23*40, x
		lda #11
		sta $d800 + 2*40, x
 		sta $d800 + 22*40, x

		inx
		cpx #40
		bne !fadeloop-

	//setup characters at $3800
	:SetScreenAndCharLocation($0400, $3000)
	:SetCharset(data.fontdata2x2, $3000)

	lda #0
	sta ypos
	sta scrollflip
	sta scrollframe
	sta eyeframe
	sta eyeflip
	sta spritecolorindex
	sta state
	sta timer

	lda #$7f
	sta eyetimer

	lda #7
	sta eyestate //will wrap to 0

	ldx #00
!spritecopyloop:
	lda data.eyespritedata, x
	sta $2000, x
	lda data.eyespritedata+$100, x
	sta $2100, x
	lda data.eyespritedata+$200, x
	sta $2200, x
	lda data.eyespritedata+$300, x
	sta $2300, x
	lda data.eyespritedata+$400, x
	sta $2400, x
	lda data.eyespritedata+$500, x
	sta $2500, x

	dex
	bne !spritecopyloop-
/*
	lda #0
	sta temp1
	ldx #00
!spritefliploop:
	//move these to $2600
	lda $2000, x
	jsr reverse
   	sta $2600, x

	lda $2100, x
	jsr reverse
   	sta $2700, x

	lda $2200, x
	jsr reverse
   	sta $2800, x

	lda $2300, x
	jsr reverse
   	sta $2900, x

	lda $2400, x
	jsr reverse
   	sta $2a00, x

	lda $2500, x
	jsr reverse
   	sta $2b00, x

	dex
	bne !spritefliploop-
*/
	:SetRasterInterrupt(irq, musicraster)
	lda #%00010000
	sta $d011		//extended background mode off

	rts

/*
reverse:
	bit temp1
!s1:
	php
   	asl
   	bne !s1-
!s2: 
	rol
   	plp
   	bne !s2-
   	rts
*/
draw:
	rts
	
cleanup:
	rts

irq:
	:InterruptStart()

	.if (irqdebug)
	{
		lda #2
		sta $d020
	}
	asl $d019 //acknowledge interrupt

	lda state

	//sprite data pointers
	jsr updateanimation
	lda #$ff
	sta $d015

	lda #$ff	
	sta $d01b //priority

	lda #$00
	sta $d01d //double width 
	sta $d017 //double heights
	sta $d01c //multicolor

	clc
	lda tilpey
	sta $d001
	sta $d003
	sta $d005
	sta $d007
	.if (doublesize)
	{
		adc #41
	}
	else
	{
		adc #21
	}
	sta $d009
	sta $d00b
	sta $d00d
	sta $d00f

	//sprite x-positions

	.var add = doublesize ? 48 : 24

	clc
	lda tilpex
	sta $d000
	sta $d008
	adc #add
	sta $d002
	sta $d00a
	adc #add
	sta $d004
	sta $d00c
	adc #add
	sta $d006
	sta $d00e
	bcc !no_overflow+
	//last sprites overflowed
	lda $d010
	ora #%10001000
	sta $d010
	jmp !sprites_done+
!no_overflow:
	lda #0
	sta $d010
!sprites_done:


//	jsr demoflowupdate
	inc scrollframe
	lda scrollframe
	and #1
	beq !slowdown+
	jmp !dontmovescroll+

!slowdown:

	//scroll
	lda ypos
	sec
	sbc #speed
	and #$07
	sta ypos
	bcc !skip+	 //we need to move the chars
	jmp !dontmovescroll+
!skip:
	ldx #7
!movescroller:
	.for (var y = 0; y < 25; y++)
	{
		lda $0400+[y+1]*40, x
		sta $0400+[y+0]*40, x
	}

	inx
	cpx #7 + 12*2
	beq !done+

	jmp !movescroller-

!done:
	//insert new 
	lda scrollflip
	bne !skip+		//== 1
	//==0
	inc scrollflip
	clc
	lda stringlinepointer+1
	adc #12
	sta stringlinepointer+1
	lda stringlinepointer+2
	adc #0
	sta stringlinepointer+2

	jmp !done+
!skip:
	lda #0
	sta scrollflip

!done:
	jsr drawstring

!dontmovescroll:
	lda #%00010000
	ora ypos
	sta $d011
	jsr demoflowupdate

	.if (irqdebug)
	{
		lda #3
		sta $d020
	}

	:InterruptEnd()

drawstring:
	//self modifying code to select correct character line
	lda scrollflip
	beq !drawupper+
	lda #0
	jmp !selectdone+
!drawupper:
	lda #2
!selectdone:
	sta stringselfmod_charselect+1 //adc #2 for the lower line, adc #0 for the upper 

	ldx #0
!writeline:
	txa
	asl
	tay
stringlinepointer: 
	lda text, x
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

!nowrap:
	asl
	asl
stringselfmod_charselect:
	adc #0
	sta $0400+24*40 + x, y
	adc #1
	iny
	sta $0400+24*40 + x, y
	inx
	cpx #12
	bne !writeline-
	jmp !done+

!done:
	ldx #7+24
	lda #0
	!clean:
		sta $0400+24*40, x

		inx
		cpx #40
		bne !clean-

	rts


updateanimation:

	//animaatiostatet
	//  värit fadeup
	//  pysyy hetken framessa 1
	//  silmän animaatioframet 1, 2, 3
	//  pysyy hetken animaatioframessa 3
	//  animaatioframet 3, 2, 1
	//  pysyy hetken framessa 1
	//  värit fadedown
	//  wait 


	sec
	lda eyetimer
	sbc #1
	sta eyetimer
	beq !skip+ //==0, handle new case 
	jmp animationupdatedone //timer != 0

!skip:
	//move to next state
	clc
	lda eyestate
	adc #1
	cmp #8
	bne !wrap+
	lda #0
!wrap:
	sta eyestate

	//init state
	lda eyestate
	cmp #0
	bne !skip+
	//init eyestate0 = värit fadeup

	lda #25
	sta eyetimer
	lda #0
	sta eyeframe

	jmp animationupdatedone

!skip:
	cmp #1
	bne !skip+
	//eyestate1 = pysyy hetken framessa 1

	lda #20
	sta eyetimer
	lda #0
	sta eyeframe

	jmp animationupdatedone

!skip:
	cmp #2
	bne !skip+
	//eyestate2 = pysyy hetken animaatioframessa 2

	lda #5
	sta eyetimer
	lda #1
	sta eyeframe

	jmp animationupdatedone

!skip:
	cmp #3
	bne !skip+
	//eyestate3 =pysyy hetken animaatioframessa 3

	lda #5
	sta eyetimer
	lda #2
	sta eyeframe

	jmp animationupdatedone

!skip:
	cmp #4
	bne !skip+
	//eyestate4 = pysyy hetken animaatioframessa 2

	lda #5
	sta eyetimer
	lda #1
	sta eyeframe

	jmp animationupdatedone

!skip:
	cmp #5
	bne !skip+
	//eyestate5 = pysyy hetken animaatioframessa 1

	lda #20
	sta eyetimer
	lda #0
	sta eyeframe

	jmp animationupdatedone

!skip:
	cmp #6
	bne !skip+
	//eyestate6 = värit fadedown

	lda #25
	sta eyetimer
	lda #0
	sta eyeframe

	jmp animationupdatedone

!skip:
	//eyestate7 = uuden odotus
	lda #90
	sta eyetimer
	jsr getrandom
	//a = random value 8bit
	and #127
	clc
	adc #70
	sta tilpex

	jsr getrandom
	//a = random value 8bit
	and #127
	clc
	adc #60
	sta tilpey

	jsr getrandom
	and #1
	sta eyeflip




animationupdatedone:
	//update colors here
	lda eyestate
	cmp #0
	beq !fadeupcolor+
	cmp #6
	beq !fadedowncolor+
	cmp #7
	beq !eyewait+
	lda #0
	jmp !colordone+

!fadeupcolor:
	ldx eyetimer
	lda spritecolorsfadeup, x
	jmp !colordone+

!fadedowncolor:
	ldx eyetimer
	lda spritecolorsfadedown, x
	jmp !colordone+

!eyewait:
	lda #1
!colordone:

	sta eyecolor

	//select frame
	lda eyeframe
	asl
	asl
	asl
/*	
	ldx eyeflip
	bne !skip+
//	clc
//	adc #3
	asl

!skip:
*/
	clc
	adc #$80
	ldx #0
	!loop:
		sta $07f8, x
		adc #1
		inx
		cpx #8
		bne !loop-

	lda eyecolor
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e

	rts
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precalc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

spritecolorsfadeup:
//.byte 1, 1, 1, 15, 15, 15, 12, 12, 12, 0, 0, 0, 1

.byte 0, 0, 0, 0, 0
.byte 11, 11, 11, 11, 11
.byte 12, 12, 12, 12, 12
.byte 15, 15, 15, 15, 15
.byte 1, 1, 1, 1, 1

spritecolorsfadedown:
.byte 1, 1, 1, 1, 1
.byte 15, 15, 15, 15, 15
.byte 12, 12, 12, 12, 12
.byte 11, 11, 11, 11, 11
.byte 0, 0, 0, 0, 0


text:
.text "            "
.text "you have now"
.text "reached the "
.text "end of      "
.text "panopticon  "
.text "by traction "
.text "        and "
.text "brainstorm  "
.text "a small c64 "
.text "onefiler at "
.text "revision 14 "
.text "            "
.text "credits for "
.text "this demo   "
.text "go to...    "
.text "            "
.text "code        "
.text "    preacher"
.text "music       "
.text "      buzzer"
.text "graphics    "
.text "      phase1"
.text "            "
.text "tools used  "
.text "kick asm by "
.text "slammer     "
.text "sid wizard  "
.text "by hermit   "
.text "pucrunch by "
.text "pasi ojala  "
.text "            "
.text "this is my  "
.text "first 8 bit "
.text "production  "
.text "and to quote"
.text "a famous c64"
.text "scener      "
.text "but hell    "
.text "what fun it "
.text "is to do a  "
.text "c64 demo    "
.text "            "
.text "we are now  "
.text "officially  "
.text "going over  "
.text "to c64.     "
.text "            "
.text "more to come"
.text "and that is "
.text "a promise   "
.text "            "
.text "we only have"
.text "greetings to"
.text "go so enjoy "
.text "the music   "
.text "and the cold"
.text "beer in your"
.text "hand...     "
.text "            "
.text "     we love"
.text "            "
.text "     ate bit"
.text "   bauknecht"
.text "   black sun"
.text "booze design"
.text "  byterapers"
.text "     camelot"
.text "      censor"
.text "      chorus"
.text "    creators"
.text "    darklite"
.text "   dekadence"
.text "      extend"
.text "   fairlight"
.text "       focus"
.text "      glance"
.text "      hitmen"
.text "   inversion"
.text "       lepsi"
.text "         lft"
.text "     offence"
.text "   onslaught"
.text "      oxyron"
.text "       noice"
.text "panda design"
.text "         pwp"
.text "    prosonix"
.text "    resource"
.text "       samar"
.text "       triad"
.text "    trilobit"
.text "wrath design"
.text " and all our"
.text "  pc friends"
.text "            "
.text "good night  "
.text "and see you "
.text "soon        "
.text "            "
.text "............"
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "            "
.text "well to be  "
.text "honest i did"
.text "lie a little"
.text "and there is"
.text "plenty more "
.text "ram to fill "
.text "so maybe ill"
.text "ramble a bit"
.text "now that we "
.text "have got the"
.text "scroller up "
.text "and running."
.text "i have done "
.text "quite a few "
.text "demos on the"
.text "pc over the "
.text "years and   "
.text "followed the"
.text "c64 scene as"
.text "well but it "
.text "seemed quite"
.text "intimidating"
.text "to finally  "
.text "start coding"
.text "on a machine"
.text "that others "
.text "have a head "
.text "start of 30 "
.text "years on.   "
.text "            "
.text "this demo is"
.text "technically "
.text "very simple "
.text "of course   "
.text "but i am    "
.text "quite happy "
.text "of how the  "
.text "end result  "
.text "turned out. "
.text "next time i "
.text "intend using"
.text "a loader so "
.text "that i have "
.text "more memory "
.text "to do more  "
.text "complicated "
.text "effects. it "
.text "was quite a "
.text "realization "
.text "that since  "
.text "my memory is"
.text "filled with "
.text "data and fx "
.text "there was no"
.text "memory left "
.text "for all the "
.text "speedcode   "
.text "that better "
.text "effects need"
.text "and i had to"
.text "cut out some"
.text "ideas that i"
.text "had. still, "
.text "i am quite  "
.text "content with"
.text "what i could"
.text "come up with"
.text "while having"
.text "so much fun."
.text "            "
.text "i would like"
.text "to give very"
.text "special thx "
.text "to my lovely"
.text "elina for   "
.text "her patience"
.text "and support "
.text "and phase1  "
.text "for kicking "
.text "my coding   "
.text "into higher "
.text "gear than it"
.text "would have  "
.text "otherwise   "
.text "reached.    "
.text "            "
.text "maybe it is "
.text "now time to "
.text "wrap up this"
.text "scrolly and "
.text "fix the last"
.text "few visual  "
.text "bugs after  "
.text "which this  "
.text "will finally"
.text "be done.    " 
.text "            "
.text "thank you   "
.text "and see you "
.text "at x!       " 
.text "            "
.text "............"
.text "            "
.text "            "


.byte $ff



}