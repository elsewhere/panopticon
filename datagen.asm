.namespace data
{
	.const mirrorblockcharset = true
	.var blockset = List()

	//eight distinct characters
	.for (var c = 0; c < 8; c++)
	{
		//create character
		.var character = List()
		.for (var y = 0; y < c; y++)
		{
			.var byte = 0
			.for (var x = 0; x < c; x++)
			{
				.eval byte = byte | [1 << x]
			}
			.eval character.add(byte)
		}
		//pad the rest of the character with empty
		.for (var y = c; y < 8; y++)
		{
			.eval character.add(0)
		}
		//add the character four/eight times to the charset
		.for (var i = 0; i < [mirrorblockcharset ? 4 : 8]; i++)
		{
			.for (var i2 = 0; i2 < 8; i2++)
			{
				.eval blockset.add(character.get(i2))
			}
		}
	}
	.if (mirrorblockcharset)
	{
		.for (var i = 255; i >= 0; i--)
		{
			.eval blockset.add(blockset.get(i)) //mirror the other side
		}
	}

//.pc = * "data: blockset"
blockcharsetdata:
.fill 512, blockset.get(i)

//dithercharsetdata:
//.import binary "charsettest.bin"

fontdata2x2:
.var data = readFont2x2(LoadPicture("gfx/2x2char.gif", List().add($000000, $ffffff)))
.fill $800, data.get(i)

fontdata1x1: //1x1 font 
.import binary "gfx/blue_max.64c"

eyespritedata:
//.var pic = LoadPicture("gfx/eye.gif")
.var eyepic1 = LoadPicture("gfx/eye2_1.gif")
.var eyepic2 = LoadPicture("gfx/eye2_2.gif")
.var eyepic3 = LoadPicture("gfx/eye2_3.gif")
	:readSprite(eyepic1, 0, 0)
	:readSprite(eyepic1, 1, 0)
	:readSprite(eyepic1, 2, 0)
	:readSprite(eyepic1, 3, 0)
	:readSprite(eyepic1, 0, 1)
	:readSprite(eyepic1, 1, 1)
	:readSprite(eyepic1, 2, 1)
	:readSprite(eyepic1, 3, 1)
	:readSprite(eyepic2, 0, 0)
	:readSprite(eyepic2, 1, 0)
	:readSprite(eyepic2, 2, 0)
	:readSprite(eyepic2, 3, 0)
	:readSprite(eyepic2, 0, 1)
	:readSprite(eyepic2, 1, 1)
	:readSprite(eyepic2, 2, 1)
	:readSprite(eyepic2, 3, 1)
	:readSprite(eyepic3, 0, 0)
	:readSprite(eyepic3, 1, 0)
	:readSprite(eyepic3, 2, 0)
	:readSprite(eyepic3, 3, 0)
	:readSprite(eyepic3, 0, 1)
	:readSprite(eyepic3, 1, 1)
	:readSprite(eyepic3, 2, 1)
	:readSprite(eyepic3, 3, 1)

atomspritedata:
//.var atompic1 = LoadPicture("gfx/atom_sprite.gif", List().add($ffffff,$959595,$6E3127,$000000))
//.var atompic1 = LoadPicture("gfx/atom_sprite.gif", List().add($ffffff,$959595,$6E3127,$000000))
//.var atompic1 = LoadPicture("gfx/atom_sprite.gif", List().add($ffffff,$959595,$9A6759,$000000))
.var atompic1 = LoadPicture("gfx/testi.gif", List().add($000000,$ffffff,$444444,$646464))//,
.var atompic2 = LoadPicture("gfx/atom_sprite2.gif")
.var atomeye1 = LoadPicture("gfx/eye3_001.gif")
.var atomeye2 = LoadPicture("gfx/eye3_002.gif")
.var atomeye3 = LoadPicture("gfx/eye3_003.gif")

//.var atomeye = LoadPicture("gfx/eye3.gif")

//	.for (var i = 0; i < 16; i++)
	{
		:getSpriteDebug(atompic1, 0, 0)
		:readSpriteInverted(atompic2, 0, 0)
	}
//	:readSpriteInverted(atomeye, 0, 0)
//	:readSpriteInverted(atomeye, 1, 0)
	:readSpriteInverted(atomeye3, 0, 0)
	:readSpriteInverted(atomeye3, 1, 0)
//	:readSpriteInverted(atomeye2, 0, 0)
//	:readSpriteInverted(atomeye2, 1, 0)
//	:readSpriteInverted(atomeye1, 0, 0)
//	:readSpriteInverted(atomeye1, 1, 0)

multicolorspritedata:
.var multicolorspritepic = LoadPicture("gfx/mcol_sprite.gif", List().add($000000,$ffffff,$444444,$9A6759))//,
:getSprite(multicolorspritepic, 0, 0)
:getSprite(multicolorspritepic, 1, 0)
:getSprite(multicolorspritepic, 2, 0)
:getSprite(multicolorspritepic, 3, 0)
:getSprite(multicolorspritepic, 0, 1)
:getSprite(multicolorspritepic, 1, 1)
:getSprite(multicolorspritepic, 2, 1)
:getSprite(multicolorspritepic, 3, 1)

.var charsetData = List()
.var screenData = List()

.eval importCharmap("gfx/priest_eye.gif", charsetData, screenData)
infopicturemap:
	.fill screenData.size(), screenData.get(i)
infocolormap:
	.import source "priestcolor.asm"
infocharset:
	.fill charsetData.size(), charsetData.get(i)

//	List().add($000000, $444444, $9A6759, $FFFFFF))
/*s	:readMulticolorSprite(multicolorspritepic, 0, 0)
	:readMulticolorSprite(multicolorspritepic, 1, 0)
	:readMulticolorSprite(multicolorspritepic, 2, 0)
	:readMulticolorSprite(multicolorspritepic, 3, 0)
	:readMulticolorSprite(multicolorspritepic, 0, 1)
	:readMulticolorSprite(multicolorspritepic, 1, 1)
	:readMulticolorSprite(multicolorspritepic, 2, 1)
	:readMulticolorSprite(multicolorspritepic, 3, 1)
*/
/*
	:readSpriteInPixels(multicolorspritepic, 0, 0)
	:readSpriteInPixels(multicolorspritepic, 24, 0)
	:readSpriteInPixels(multicolorspritepic, 48, 0)
	:readSpriteInPixels(multicolorspritepic, 72, 0)
	:readSpriteInPixels(multicolorspritepic, 0, 21)
	:readSpriteInPixels(multicolorspritepic, 24, 21)
	:readSpriteInPixels(multicolorspritepic, 48, 21)
	:readSpriteInPixels(multicolorspritepic, 72, 21)
*/
.var groupchars1 = List()
.var grouppositiondata1 = List()
.eval importCharmap("gfx/brslogo.png", groupchars1, grouppositiondata1)
groupcharsetdata1:
.fill groupchars1.size(), groupchars1.get(i)^$ff
groupcharsetdata1map:
.fill grouppositiondata1.size(), grouppositiondata1.get(i)

.var groupchars2 = List()
.var grouppositiondata2 = List()
.eval importCharmap("gfx/traction.gif", groupchars2, grouppositiondata2)
groupcharsetdata2:
.fill groupchars2.size(), groupchars2.get(i)^$ff
groupcharsetdata2map:
.fill grouppositiondata2.size(), grouppositiondata2.get(i)
/*
logocharset1:
.var logoChars = List()
.var logoData = List()
.eval importCharmap("gfx/demologo.gif", logoChars, logoData)
.fill logoChars.size(), logoChars.get(i)^$ff
logocharset1map:
.fill logoData.size(), logoData.get(i)
*/

logocharset1:
.import binary "gfx/panopticon.imap"

logocharset1map:
.import binary "gfx/panopticon.iscr"

sphereborder:
:loadCharsetPicture("gfx/sphere_border.gif", 1, 1)

spiralborderchars1:
.var borderChars1 = List()
.var borderData1 = List()
.eval importCharmap("gfx/spiral_up.gif", borderChars1, borderData1)
.fill borderChars1.size(), borderChars1.get(i)^$ff
spiralbordermap1:
.fill borderData1.size(), borderData1.get(i)+16 //offset the effect chars

spiralborderchars2:
.var borderChars2 = List()
.var borderData2 = List()
.eval importCharmap("gfx/spiral_down.gif", borderChars2, borderData2)
.fill borderChars2.size(), borderChars2.get(i)^$ff
spiralbordermap2:
.fill borderData2.size(), borderData2.get(i)+100 //offset effect + top border chars

charset4x4:
//0000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000

//0001
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111

//0010
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000

//0011
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111

//0100
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000

//0101
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111

//0110
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000

//0111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111

//1000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000

//1001
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111

//1010
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000

//1011
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111

//1100
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000

//1101
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %00001111
.byte %00001111
.byte %00001111
.byte %00001111

//1110
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11110000
.byte %11110000
.byte %11110000
.byte %11110000

//1111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111

sprite_andmask:
	.byte %11111110, %11111101, %11111011, %11110111, %11101111, %11011111, %10111111, %01111111
sprite_ormask:
	.byte %00000001, %00000010, %00000100, %00001000, %00010000, %00100000, %01000000, %10000000
}