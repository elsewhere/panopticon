/*
	General macro stuff 
*/

.importonce

.var debug = true

.var _createDebugFiles = debug && cmdLineVars.get("afo") == "true"
.print "File creation " + [_createDebugFiles
    ? "enabled (creating breakpoint file)"
    : "disabled (no breakpoint file created)"]
.var brkFile
.if(_createDebugFiles) {
    .eval brkFile = createFile("breakpoints.txt")
    }
.macro break() {
.if(_createDebugFiles) {
    .eval brkFile.writeln("break " + toHexString(*))
    }
}


.macro TextScreenColor(color)
{
	ldx #0
	lda #color
clearloop:
	sta $d800, x
	sta $d900, x
	sta $da00, x
	sta $db00, x
	dex 
	bne clearloop
}


.macro SetExtendedCharset(charset, address)
{
	ldx #$00
	//we use 64 lower characters, 8 bytes per character
!copycharloop:
	lda charset, x
	sta address, x
	lda charset+$100, x
	sta address+$100, x

	dex
	bne !copycharloop-
}

.macro SetCharset(charset, address)
{
	ldx #$00
	//we use 256 characters, 8 bytes per character
!copycharloop:
	lda charset, x
	sta address, x
	lda charset+$100, x
	sta address+$100, x
	lda charset+$200, x
	sta address+$200, x
	lda charset+$300, x
	sta address+$300, x
	lda charset+$400, x
	sta address+$400, x
	lda charset+$500, x
	sta address+$500, x
	lda charset+$600, x
	sta address+$600, x
	lda charset+$700, x
	sta address+$700, x

	dex
	bne !copycharloop-
}

.macro SetSpriteData(data, address)
{
	ldx #00
!spritecopyloop:
	lda data, x
	sta address, x
	lda data+$100, x
	sta address+$100, x
	dex
	bne !spritecopyloop-	

}

.macro SetRasterInterrupt(ptr, rasterline)
{
	sei
	lda #<ptr
	sta $fffe
	lda #>ptr
	sta $ffff
	asl $d019
	lda #rasterline
	sta $d012
	cli
}

.macro InterruptStart()
{
	pha
	txa
	pha
	tya
	pha
}

.macro InterruptEnd()
{
	pla
	tay
	pla
	tax
	pla
	rti

}


.macro readSprite(picture, xoffset, yoffset) {
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte picture.getSinglecolorByte(x + xoffset * 3, y + yoffset*21) 
	.byte 0
}

.macro readSpriteInverted(picture, xoffset, yoffset) {
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte picture.getSinglecolorByte(x + xoffset * 3, y + yoffset*21)^$ff
	.byte 0
}

.macro readMulticolorSprite(picture, xoffset, yoffset)
{
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte picture.getMulticolorByte(x + xoffset * 3, y + yoffset*21) 
	.byte 0
}
.macro readMulticolorSpriteInverted(picture, xoffset, yoffset)
{
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte picture.getMulticolorByte(x + xoffset * 3, y + yoffset*21)^$ff
	.byte 0
}

.macro readSpriteInPixels(picture, xoffset, yoffset)
{
	.var sprite = List()
	.for (var y = 0; y < 21; y++)
	{
		.for (var x = 0; x < 3; x++)
		{
			.var u = xoffset + x*8
			.var v = y + yoffset
			.const threshold = $100000
			.var bit7 = [picture.getPixel(u, v) < threshold] ? 1 : 0
			.var bit6 = [picture.getPixel(u + 1, v) < threshold] ? 1 : 0
			.var bit5 = [picture.getPixel(u + 2, v) < threshold] ? 1 : 0
			.var bit4 = [picture.getPixel(u + 3, v) < threshold] ? 1 : 0
			.var bit3 = [picture.getPixel(u + 4, v) < threshold] ? 1 : 0
			.var bit2 = [picture.getPixel(u + 5, v) < threshold] ? 1 : 0
			.var bit1 = [picture.getPixel(u + 6, v) < threshold] ? 1 : 0
			.var bit0 = [picture.getPixel(u + 7, v) < threshold] ? 1 : 0

			.var spritebyte = [bit7 << 7] | [bit6 << 6] | [bit5 << 5] | [bit4 << 4] | [bit3 << 3] | [bit2 << 2] | [bit1 << 1] | bit0
			.eval sprite.add(spritebyte)
		}
	}
	.fill sprite.size(), sprite.get(i)
	.byte $0 //padding
}

.function packCharacter(source, offset)
{
	.const threshold = 127
	.var bit7 = [source.get(offset) > threshold] ? 1 : 0
		.var bit6 = [source.get(offset+1) > threshold] ? 1 : 0
		.var bit5 = [source.get(offset+2) > threshold] ? 1 : 0
		.var bit4 = [source.get(offset+3) > threshold] ? 1 : 0
		.var bit3 = [source.get(offset+4) > threshold] ? 1 : 0
		.var bit2 = [source.get(offset+5) > threshold] ? 1 : 0
		.var bit1 = [source.get(offset+6) > threshold] ? 1 : 0
		.var bit0 = [source.get(offset+7) > threshold] ? 1 : 0

	.var charsetbyte = [bit7 << 7] | [bit6 << 6] | [bit5 << 5] | [bit4 << 4] | [bit3 << 3] | [bit2 << 2] | [bit1 << 1] | bit0
	.return charsetbyte
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
.function pictureToCharset(image)
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
//				.eval charset.add(image.getSinglecolorByte(
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


.function readFont2x2(pic)
{
	.var data = List()
	.var charcount = pic.width / 16
	.print "charcount " + charcount

	.for (var i = 0; i < charcount; i++)
	{
		.var offsetx = i * 16
		//top left byte
		.for (var y = 0; y < 8; y++)
		{
			.eval data.add(pic.getSinglecolorByte(offsetx / 8, y))
		}
		//top right byte
		.for (var y = 0; y < 8; y++)
		{
			.eval data.add(pic.getSinglecolorByte([offsetx / 8] + 1, y))
		}
		//bottom left byte
		.for (var y = 0; y < 8; y++)
		{
			.eval data.add(pic.getSinglecolorByte(offsetx / 8, y + 8))
		}
		//bottom right byte
		.for (var y = 0; y < 8; y++)
		{
			.eval data.add(pic.getSinglecolorByte([offsetx / 8] + 1, y + 8))
		}
	}
	.return data

}
.macro getSprite(spritePic, spritex, spritey) 
{
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte spritePic.getMulticolorByte(x + spritex * 3, y + spritey * 21) 
	.byte 0
}
.macro getSpriteDebug(spritePic, spritex, spritey) 
{
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
		{
			.var d = spritePic.getMulticolorByte(x + spritex * 3, y + spritey * 21) 
			.byte d
		}
	.byte 0
}

.macro SetScreenAndCharLocation(screen, charset) 
{
	lda	#[[screen & $3FFF] / 64] | [[charset & $3FFF] / 1024]
	sta	$D018
}
.function importCharmap(filename, characters, screen)
{
	.var charMap = Hashtable()
	.var charNo = 0
//	.var screenData = List()
//	.var charsetData = List()
	.var pic = LoadPicture(filename)

	// Graphics should fit in 8x8 Single collor / 4 x 8 Multi collor blocks
	.var PictureSizeX = pic.width/8
	.var PictureSizeY = pic.height/8

	.for (var charY=0; charY<PictureSizeY; charY++) 
	{
		.for (var charX=0; charX<PictureSizeX; charX++) 
		{
			//create hash
			.var currentCharBytes = List()
			.var key = ""
			.for (var i=0; i<8; i++) 
			{
				.var byteVal = pic.getSinglecolorByte(charX, charY*8 + i)
				.eval key = key + toHexString(byteVal) + ","
				.eval currentCharBytes.add(byteVal)
			}
			.var currentChar = charMap.get(key)
			.if (currentChar == null) 
			{
				.eval currentChar = charNo
				.eval charMap.put(key, charNo)
				.eval charNo++
				.for (var i=0; i<8; i++) 
				{
					.eval characters.add(currentCharBytes.get(i))
				}
			}
			.eval screen.add(currentChar)
		}
	}
	.var charsetSize = toIntString(characters.size())
	.var screenSize = toIntString(screen.size())
	.var totalSize = toIntString(characters.size() + screen.size())
	.print "image " + filename + " size: " + totalSize + " (charset: " + charsetSize + " (" + toIntString(characters.size() / 8) + " chars), screendata: " + screenSize + ")"
}

.macro loadCharsetPicture(filename, sizex, sizey)
{
	.var pictureSizeX = sizex
	.var pictureSizeY = sizey
	.var pic = LoadPicture(filename)

	.for (var charY = 0; charY < pictureSizeY; charY++)
	{
		.for (var charX = 0; charX < pictureSizeX; charX++)
		{
			.var currentCharBytes = List()
			.for (var i = 0; i < 8; i++)
			{
				.var byteVal = pic.getSinglecolorByte(charX, charY*8 + i)^$ff
				.eval currentCharBytes.add(byteVal)
			}
			.fill currentCharBytes.size(), currentCharBytes.get(i)
		}
	}

}