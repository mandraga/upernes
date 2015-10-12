	;; IO ports are not identical (except compatibility for the paddles)
	;; In order to recompile a nes game for the super nes, the instructions
	;; using io ports must be replaced by code doing the equivalent thing 
	;; on the super nes.
	;;
	;; Documentation for io ports from the "Nintendo Entertainment System
	;; Architecture" version 2.6 (01/24/2005) by Marat Fayzullin

.include "snesregisters.inc"
.include "var.inc"

.MACRO RETR
	jmp RetIOroutineR
.ENDM

.MACRO RETW
	jmp RetIOroutineW
.ENDM

.include "cartridge.inc"

.BANK 0
.ORG 0
.SECTION "IOemulation"

IOWroutinestable:
.DW	WPPUC1			; $2000
.DW	WPPUC2			; $2001
.DW	$0000
.DW	WSPRADDR		; $2003
.DW	WSPRDATA		; $2004
.DW	WSCROLOFFSET		; $2005
.DW	WPPUMEMADDR		; $2006
.DW	WPPUMEMDATA		; $2007
;; Sound registers
.DW	WSNDSQR1CTRL		; $4000
.DW	WSNDSQR1E
.DW	WSNDSQR1PERIOD
.DW	WSNDSQR1LENPH
.DW	WSNDSQR2CTRL		; $4004
.DW	WSNDSQR2E
.DW	WSNDSQR2PERIOD
.DW	WSNDSQR2LENPH
.DW	WSNDTRIACTRL		; $4008
.DW     $0000
.DW	WSNDTRIAPERIOD		; $400A
.DW	WSNDTRIALENPH		; $400B
.DW	WSNDNOISECTRL		; $400C
.DW     $0000
.DW	WSNDNOISESHM		; $400E
.DW	WSNDNOISELEN		; $400F
.DW	WSNDDMCCTRL		; $4010
.DW	WSNDDMCDAC		; $4011
.DW	WSNDDMCSADDR		; $4012
.DW	WSNDDMCSLEN		; $4013
;; DMA
.DW	WDMASPRITEMEMACCESS	; $4014
;; Sound again
.DW	WSNDCHANSWITCH		; $4015
;; Joystick but not replaced
.DW	WJOYSTICK1		; $4016 WJOYSTICK1
.DW	WSNDSEQUENCER		; WSNDSEQUENCER / WJOYSTICK2


IORroutinestable:
.DW	RPPUC1			; $2000
.DW	RPPUC2			; $2001
.DW	RPPUSTATUS		; $2002
.DW	$0000
.DW	RSPRDATA		; $2004
.DW	$0000
.DW	$0000
.DW	RPPUMEMDATA		; $2007
;; Sound registers
.DW	$0000			; $4000
.DW	$0000			; $4001
.DW	$0000			; $4002
.DW	$0000			; $4003
.DW	$0000			; $4004
.DW	$0000			; $4005
.DW	$0000			; $4006
.DW	$0000			; $4007
.DW	$0000			; $4008
.DW	$0000			; $4009
.DW	$0000			; $400A
.DW	$0000			; $400B
.DW	$0000			; $400C
.DW	$0000			; $400D
.DW	$0000			; $400E
.DW	$0000			; $400F
.DW	$0000			; $4010
.DW	$0000			; $4011
.DW	$0000			; $4012
.DW	$0000			; $4013
;; DMA
.DW	$0000			; $4014 DMA
.DW	RSNDCHANSWITCH		; $4015 APU status register
.DW	RJOYSTICK1
.DW	RJOYSTICK2


; ------+-----+---------------------------------------------------------------
; $2000 | RW  | PPU Control Register 1
;       | 0-1 | Name Table Address:
;       |     |
;       |     |           +-----------+-----------+
;       |     |           | 2 ($2800) | 3 ($2C00) |
;       |     |           +-----------+-----------+
;       |     |           | 0 ($2000) | 1 ($2400) |
;       |     |           +-----------+-----------+
;       |     |
;       |     | Remember that because of the mirroring there are only 2  
;       |     | real Name Tables, not 4. Also, PPU will automatically
;       |     | switch to another Name Table when running off the current
;       |     | Name Table during scroll (see picture above).
;       |   2 | Vertical Write, 1 = PPU memory address increments by 32:
;       |     |
;       |     |    Name Table, VW=0          Name Table, VW=1
;       |     |   +----------------+        +----------------+
;       |     |   |----> write     |        | | write        |
;       |     |   |                |        | V              |
;       |     |
;       |   3 | Sprite Pattern Table Address, 1 = $1000, 0 = $0000.
;       |   4 | Screen Pattern Table Address, 1 = $1000, 0 = $0000.
;       |   5 | Sprite Size, 1 = 8x16, 0 = 8x8.
;       |   6 | PPU Master/Slave Mode, not used in NES.
;       |   7 | VBlank Enable, 1 = generate interrupts on VBlank.

WPPUC1:
	sta PPUcontrolreg1
	;; ------------------------------------------
	;; Sprite pattern table address
	lda #$08
	bit PPUcontrolreg1	; test if bit 3 (#$08), zero if not set (and result)
	bne Spritesinsecondbank
	;; $0000 in snes Vram
	lda #$00                ; 8x8 sprites @ $0000 8KB segment 0
	sta OBSEL
	jmp Spritebankend
Spritesinsecondbank:
	;; $4000 in snes Vram
	lda #$01		; 8x8 sprites @ $4000 8kB segment 2
	sta OBSEL
Spritebankend:
	;; ------------------------------------------
	;; Test Screen Pattern Table Address (BG chr 4kB bank 0 or 1)
	lda #$10
	bit PPUcontrolreg1
	bne secondbgchrbank
	lda #$01		; 0x0001 -> 4kWord=8kB segment 1
	sta BG12NBA		; CHR data in VRAM starts at 0x2000
	jmp BGbankend
secondbgchrbank:
	lda #$03		; 0x0003 -> 4kWord=8kB segment 3
	sta BG12NBA		; CHR data in VRAM starts at 0x6000
BGbankend:
	;; ------------------------------------------
	;; Test Vblank
	lda #$80
	bit PPUcontrolreg1
	bne vblank
	lda #$0F		  ;Turn on screen, 100% brightness
	sta INIDISP
	jmp vblankend
vblank:
	lda #$8F		  ;Turn off screen, 100% brightness
	sta INIDISP
vblankend:
	RETW

RPPUC1:
	lda PPUcontrolreg1
	RETR

; ------+-----+---------------------------------------------------------------
; $2001 | RW  | PPU Control Register 2
;       |   0 | Unknown (???)
;       |   1 | Image Mask, 0 = don't show left 8 columns of the screen.
;       |   2 | Sprite Mask, 0 = don't show sprites in left 8 columns. 
;       |   3 | Screen Enable, 1 = show picture, 0 = blank screen.
;       |   4 | Sprites Enable, 1 = show sprites, 0 = hide sprites.
;       | 5-7 | Background Color, 0 = black, 1 = blue, 2 = green, 4 = red.
;       |     | Do not use any other numbers as you may damage PPU hardware.

WPPUC2:
	cmp PPUcontrolreg2 	; Anything changed?
	beq endWPPUC2
	sta PPUcontrolreg2
	;; Test bit 3:	Background enable
	lda #$08
	bit PPUcontrolreg2	; A contains $08 if BG enabled
	lsr A
	lsr A
	lsr A
        sta TM			; BG1 enabled as a main screen if A=$01
	;; Test bit 4:	Sprite enable
	lda #$10
	bit PPUcontrolreg2	; A contains $10 if Sprites enabled
	;; TODO Sprite enable!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
endWPPUC2:
	RETW

RPPUC2:
	sta PPUcontrolreg2
	RETR

; ------+-----+---------------------------------------------------------------
; $2002 | R   | PPU Status Register
;       | 0-5 | Unknown (???)
;       |   6 | Hit Flag, 1 = Sprite refresh has hit sprite #0.
;       |     | This flag resets to 0 when screen refresh starts
;       |     | (see "PPU Details").
;       |   7 | VBlank Flag, 1 = PPU is in VBlank state.
;       |     | This flag resets to 0 when VBlank ends or CPU reads $2002
;       |     | (see "PPU Details").

RPPUSTATUS:
	sep #$20
	;; vblank
	lda HVBJOY
	and #$80
	;; TODO sprite 0

	;; Flags must be kept like it was a real lda
; 	????????????????
; 	tax			; save a
; 	php			; push status register
; 	pla			; pop status register
; 	and #$82		; keep N and Z flags like the lda function
; 	sta Flags
; 	txa			; restore a
	RETR

; ------+-----+---------------------------------------------------------------
; $2003 | W   | Sprite Memory Address
;       |     | Used to set the address of the 256-byte Sprite Memory to be 
;       |     | accessed via $2004. This address will increment by 1 after
;       |     | each access to $2004. Sprite Memory contains coordinates,
;       |     | colors, and other sprite attributes (see "Sprites").

WSPRADDR:
	; OAM direct address conversion: 4bytes on nes, 4bytes on snes
	; but OAM is a word address and can be update by dma
	; and therefore a buffer in ram could be nice and therfore
	; a buffer it will be in order to keep Byte addressing.
	sta SpriteMemoryAddress
	RETW

; ------+-----+---------------------------------------------------------------
; $2004 | RW  | Sprite Memory Data
;       |     | Used to read/write the Sprite Memory. The address is set via
;       |     | $2003 and increments by 1 after each access. Sprite Memory 
;       |     | contains coordinates, colors, and other sprite attributes
;       |     | sprites (see "Sprites").
;       |     | Writes directly in OAM but because the sprite format is
;       |     | not the same, a lot of address changes occur.

WR_OAMconversionroutines:
	.DW WRITE_SPR_Y
	.DW WRITE_SPR_TILE
	.DW WRITE_SPR_FLAGS
	.DW WRITE_SPR_X

; 0 yyyyyyyy -> 1
; 1 cccccccc -> 2
; 2 vho--ppp -> 3 + conversion
; 3 xxxxxxxx -> 0

WSPRDATA:
	sep #$30		; All 8bits
	tay
	ldx #$00
	lda SpriteMemoryAddress
	;; Test which of the 4 bytes is to be written
	and #$03
	asl
	tax
	jmp (WR_OAMconversionroutines,X)

	;; Writes th byte twice: first converts it and writes in the buffer and then write a word
	;; in the coresponding OAM address to update it.
sprwrdoneHi:
	lda SpriteMemoryAddress
	and #$FC
	ora #$02
	jmp updateOAM

sprwrdoneLo:
	lda SpriteMemoryAddress
	and #$FC
updateOAM:
	tax
	sta OAMADDL
	lda SpriteMemoryBase,X
	sta OAMDATA
	lda SpriteMemoryBase + 1,X
	sta OAMDATA
IncSprAddr:
	;; Increment the buffer's bytes address
	ldy SpriteMemoryAddress
	iny
	sty SpriteMemoryAddress
	RETW

WRITE_SPR_Y:
	lda SpriteMemoryAddress
	and #$FC
	ora #01
	tax
	tya
	sta SpriteMemoryBase,X
	jmp sprwrdoneLo
WRITE_SPR_TILE:
	lda SpriteMemoryAddress
	and #$FC
	ora #02
	tax
	tya
	sta SpriteMemoryBase,X
	jmp sprwrdoneHi
WRITE_SPR_FLAGS:
	lda SpriteMemoryAddress
	and #$FC
	ora #03
	tax
	tya
	jsr convert_sprflags_to_snes
	tay
	sta SpriteMemoryBase,X
	jmp sprwrdoneHi
WRITE_SPR_X:
	lda SpriteMemoryAddress
	and #$FC
	tax
	tya
	sta SpriteMemoryBase,X
	jmp sprwrdoneLo

; NES vhoxxxpp   SNES vhoopppN
convert_sprflags_to_snes:
	; pp
	and #$03
	asl
	sta PPTMP
	tya
	; vh
	and #$D0		; Keep vh
	ora PPTMP		; Add pp
	;; Test o (priority flag)
	;; TODO use bit instruction or a mask
	;; maximum priority: 3
	ora #$30
	rts

;; --------------------------------------------------------------------
RD_OAMconversionroutines:
	.DW READ_SPR_Y
	.DW READ_SPR_TILE
	.DW READ_SPR_FLAGS
	.DW READ_SPR_X

RSPRDATA:
	;; Load the content of the tmp buffer
	lda SpriteMemoryAddress
	ldx #$0000
	tay
	;; Test which of the 4 bytes is to be read
	and #$03
	asl
	tax
	tya
	and #$FC
	jmp (RD_OAMconversionroutines,X)
ReadOAM:
	tax
	sta SpriteMemoryBase,X

incrementsprindex:
	tay
	lda SpriteMemoryAddress
	clc
	adc #1
	sta SpriteMemoryAddress
	tya
	RETR

READ_SPR_Y:
	ora #01
	jmp ReadOAM
READ_SPR_TILE:
	ora #02
	jmp ReadOAM
READ_SPR_FLAGS:
	ora #03
	tax
	sta SpriteMemoryBase,X
	jsr convert_sprflags_to_nes
	jmp incrementsprindex
READ_SPR_X:
	;; index 0
	jmp ReadOAM
	
; NES vhoxxxpp   SNES vhoopppN
convert_sprflags_to_nes:
	pha
	; pp
	and #$06
	lsr
	sta PPTMP
	pla
	; vh
	and #$D0		; Keep vh
	ora PPTMP		; Add pp
	;; Test o (priority flag)
	;; TODO use bit instruction or a mask
	rts

; ------+-----+---------------------------------------------------------------
; $2005 | W   | Screen Scroll Offsets
;       |     | There are two scroll registers, vertical and horizontal, 
;       |     | which are both written via this port. The first value written
;       |     | will go into the Vertical Scroll Register (unless it is >239,
;       |     | then it will be ignored). The second value will appear in the
;       |     | Horizontal Scroll Register. Name Tables are assumed to be
;       |     | arranged in the following way:
;       |     |
;       |     |           +-----------+-----------+
;       |     |           | 2 ($2800) | 3 ($2C00) |
;       |     |           +-----------+-----------+
;       |     |           | 0 ($2000) | 1 ($2400) |
;       |     |           +-----------+-----------+
;       |     |
;       |     | When scrolled, the picture may span over several Name Tables.
;       |     | Remember that because of the mirroring there are only 2 real
;       |     | Name Tables, not 4.
WSCROLOFFSET:
	sep #$03		; All 8b
	tax
	cmp #240		; > 239?
	bcs ignorescrollvalue
	lda CurScrolRegister
	beq vertical_scroll
horizontal_scroll:
	txa
	sta BG1HOFS
	stz BG1HOFS 		; High byte is 0
	jmp chgscrollregister
vertical_scroll:
	txa
	sta BG1VOFS
	stz BG1VOFS 		; High byte is 0
chgscrollregister:
	lda CurScrolRegister
	eor #$01		; Change the acessed scroll register
	sta CurScrolRegister
ignorescrollvalue:
	RETW

; ------+-----+---------------------------------------------------------------
; $2006 | W   | PPU Memory Address
;       |     | Used to set the address of PPU Memory to be accessed via
;       |     | $2007. The first write to this register will set 6 upper
;       |     | address bits. The second write will set 8 lower bits. The
;       |     | address will increment either by 1 or by 32 after each
;       |     | access to $2007 (see "PPU Memory").
	;; Utilise des pointeurs sur routine en fonction de l'addresse
	;; saisie ici.
	;; Name table, Attribute table, Palette, ou empty
WPPUMEMADDR:
	sep #$30
	ldy PPUmemaddrB
	sta PPUmemaddrL,Y	; Store the address in this byte
	tya
	eor #$01
	sta PPUmemaddrB		; Change accessed byte (0 or 1)
	ora #$00		; Test if address update is finished: 0
	beq ppumaddret
	;; Address write completed here
	;; Select the routine for this address range
	lda PPUmemaddrH
	;; Find the address range
	cmp #$20		; On the nes, below $2000 is CHR data
	bcc emptyrangej		; A < #$20
	cmp #$30
	bcs afternametablesj	; A >= #$30  Past $3000 empty or palette
	;; #$20 <= @ < #$30
	;; $2000 to $23C0 = Nametables  $23C0 to $2400 = Attributes
	jsr set_tilemap_addr
	lda PPUmemaddrL
	and #$F0		; Keep only bits 4-7 for attribute table
	cmp #$C0
	bcc nametables		; A < #$C0
	jmp attributetables
ppumaddret:
	RETW
emptyrangej:
	jmp emptyrange
afternametablesj:
	jmp afternametables
;; -------------------------------------------------------------------------
attributetables:
	; attribute table addresses are not directly equivalent
	; $100 - $0C0 = $40 = 64 for 1024 tiles = 16 tiles color upper bits per byte
	; 32/4 = 8 blocks per line, 8 blocks vertically
	; writing at 0 4 8 12 16 20 24 28 ; and then 32 * 4 + 32, + 36...
	; First tile = ((offset / 8) * 128) + ((offset % 8) * 4)
	;            = ((offset >> 3) << 7) + ((offset & $07) << 2)
	;
	; line = (@ / 8) * 128 = (@ >> 3) << 7) = (@ & $F8) << 4
	; row  = (@ & 0x07) << 2
	; c = @ << 2; addr = ((c & 0x00E0) << 2) + (c & 0x1C)
	rep #$20		; A 16bits
	lda PPUmemaddrL		; Load the ppu memory address suposed to be in the attribute range: $23C0 to $2400 or 27C0 to 2800
	asl A
	asl A			; << 2
	pha
	and #$00E0		; Lower address value
	asl A
	asl A
	sta tmp_addr		; (c & 0x00E0) << 2
	pla
	and #$001C		; (c & 0x1C)
	clc
	adc tmp_addr		; ((c & 0x00E0) << 2) + (c & 0x1C)
	sta tmp_addr
	tya
	clc
	adc tmp_addr		; snes VRAM segment + Addr
	; Store the address
	sta attributeaddr
	; Set the address in snes register
	sep #$20		; A 8bits
	; The adress is in word count (should be $(3/7)000 to $(3/7)003F)
	sta VMADDL
	xba
	sta VMADDH
	; Vram increments 1 by 1 after VMDATAH write
	lda #$80
	sta VMAINC
	;; Attributes routines
	rep #$20
	lda #AttrtableW
	sta PPUW_RAM_routineAddr
	lda #AttrtableR
	sta PPUR_RAM_routineAddr
	RETW
;; -------------------------------------------------------------------------
nametables:
	rep #$20		; A 16bits
	lda PPUmemaddrL
	and #$03FF		; Lower address value
	sta tmp_addr
	tya
	clc
	adc tmp_addr
	; Set the address in snes register
	sep #$20		; A 8bits
	; The adress is in word count (should be $(3/7)000 to $(3/7)003F)
	sta VMADDL
	xba
	sta VMADDH
	; Vram increments 1 by 1 after VMDATAL write
	lda #$00
	sta VMAINC
	;; Tile map routines
	rep #$20		; A 16bits
	lda #NametableW
	sta PPUW_RAM_routineAddr
	lda #NametableR
	sta PPUR_RAM_routineAddr
	RETW
;; -------------------------------------------------------------------------
afternametables:
	sep #$30		; 8bit total
	cmp #$3F
	bcc emptyrange		; empty area before palette data
	lda PPUmemaddrL
	cmp #$20		; End of the palette area
	bcs emptyrange		; if greater then it is an empty area
	rep #$30		; All 16bits
	;; palette routines
	lda #paletteW
	sta PPUW_RAM_routineAddr
	lda #paletteR
	sta PPUR_RAM_routineAddr
	RETW
;; -------------------------------------------------------------------------
emptyrange:
	;; empty routines
	lda #emptyW
	sta PPUW_RAM_routineAddr
	lda #emptyR
	sta PPUR_RAM_routineAddr
	RETW

;; -------------------------------------------------------------------------
; Select where goes the name table data in VRAM
set_tilemap_addr
;.8BIT
	sep #$30		; BUG!!!!!!!!!!!!
	lda PPUmemaddrH		; address hight byte
	and #$04		; bit 11: 0 = Tables 0 & 2; 1 = Tables 1 & 3
	cmp #$04
	beq Tables1_3
	rep #$10                ;  X Y are 16bits
	ldy #$1800		; snes BG1 names/attributes VRAM address: $3000 >> 1 (Word addres)
	rts
Tables1_3:
	ldy #$3800		; snes BG2 names/attributes VRAM address: $7000 >> 1
	rts

emptyW:
	RETW

emptyR:
	RETR

; ------+-----+---------------------------------------------------------------
; $2007 | RW  | PPU Memory Data
;       |     | Used to read/write the PPU Memory. The address is set via
;       |     | $2006 and increments after each access, either by 1 or by 32
;       |     |
;       |     | PPU Memory contains:
;       |     | CHR data - but ROM on most cartridges
;       |     | Name and attributes tables for backgrounds
;       |     |	16 colors Background and Sprites Palettes

WPPUMEMDATA:
	jmp (PPUW_RAM_routineAddr)

	;; -------------------------------------------------------------------------	
	;; Attribute tables
	;; write the highter 6bits of the words at $A000 4x4 tiles at time.
	;; In fact only 2bits on the nes.
	;;
AttrtableW:
	;; Attribute byte: 33|22|11|00
	;; Tiles:		00 00 | 11 11
	;;			00 00 | 11 11
	;;			-------------
	;;			22 22 | 33 33
	;;			22 22 | 33 33
	;; Therefore 4 writes + 3 * 4 writes at @+28

	;; SNES
	; vhopppcc cccccccc
	; v/h        = Vertical/Horizontal flip this tile.
	; o	     = Tile priority.
	; ppp        = Tile palette. The number of entries in the palette depends on the Mode and the BG.
	; cccccccccc = Tile number.
	sep #$30		; All 8bits
	tax
	rep #$20		; Acc 16bits
	lda attributeaddr
	sta VMADDL
	sep #$20		; Acc 8bits
	txa
	and #$03		; 00
	asl A			; Attibute palette are at bits 2 3 4 on snes
	asl A
	tay
	sta VMDATAH
	sta VMDATAH
	txa
	and #$0C		; 11
	pha
	sta VMDATAH
	sta VMDATAH
	;; Add 32 to the @
	rep #$20		; Acc 16bits
	lda attributeaddr
	clc
	adc #32			; Next line
 	sta VMADDL
	;; 
	sep #$20		; Acc 8bits
	tya
	sta VMDATAH
	sta VMDATAH
	pla			; 11
	sta VMDATAH
	sta VMDATAH
	;; Lower 2 x 4 tiles
	txa
	ror A
	ror A
	tay
	ror A
	ror A
	and #$0C		; 33
	tax
	;; Add 64 to the @
	rep #$20		; Acc 16bits
	lda attributeaddr
	clc
	adc #64			; Next line
 	sta VMADDL
	;;
	sep #$20		; Acc 8bits
	tya
	and #$03		; 22
	tay
	sta VMDATAH
	sta VMDATAH
	txa
	sta VMDATAH
	sta VMDATAH
	;; Add 96 to the @
	rep #$20		; Acc 16bits
	lda attributeaddr
	clc
	adc #96			; Next line
 	sta VMADDL
	;;
	sep #$20		; Acc 8bits
	tya
	sta VMDATAH
	sta VMDATAH
	txa
	sta VMDATAH
	sta VMDATAH
	;; Increment the Attribute address
	rep #$20		; Acc 16bits
	lda attributeaddr
	clc
	adc #$0004
	sta attributeaddr
	and #$001F		; addr % 32 = 0?
	beq add128		; If 0 the it is on the begining of the line
	;; Done
	RETW
add128:
	lda attributeaddr
	clc
	adc #128
	sta attributeaddr
	;; Done
	RETW

	;; -------------------------------------------------------------------------
	;; Name tables
NametableW:
	sep #$20		; Acc Mem 8bits
	sta VMDATAL             ; Write to VRAM
	RETW

	;; ---------------------------------------------------------------
	;; nes palette address: write in cg ram
	;; Converts the nes color to snes BGR 555
	;; Depending on the address it writes at BG0 palete or sprite palette
paletteW:
	tax
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	; CG ram address to (PPUmemaddr - $3F00), in fact ommit the $3F
	lda PPUmemaddrL
	; Test if it is a sprite address
	cmp #$10		; A >= $10
	bcs paladdr_add_128
	jmp setcgaddr
paladdr_add_128:
	ora #$80		; Add 128 and remove the $10
	and #$EF
setcgaddr:
	sta CGADD               ; Set the palette address register
	phb
	lda #:nes2snespalette	; Bank of the palette conversion table
	pha
	plb			; A -> Data Bank Register
	txa			; X contains the color value
	asl			; word index in the BGR 555 conversion values
	tay
	lda nes2snespalette,Y   ; Load the palette conversion value
	; Send it to CG ram
	sta CGDATA
	tax			; Save it in case of mirroring
	iny
	lda nes2snespalette,Y
	tay			; Save it in case of mirroring
	sta CGDATA
	plb                     ; Restores the data bank register
	;; Return if the color is already set
	;; FIXME
	;; If the address 2 lower bits are 0 then emulate mirroring
	;; FIXME try to insert this before writing the first two bytes and branch
	lda PPUmemaddrL
	and #$03
	cmp #0                  ; The first address is mirrored on all the palette, but not on the snes -> 2x4 writes
	beq colormirroring
endwpumem:
	;; Increments the index equally as CGDATA
	rep #$30		; 16bit XY and A
	ldx PPUmemaddrL
	inx
	stx PPUmemaddrL
	;; Test for address oveflow
	txa
	cmp #$3F20
	beq changewrfunction
	;; If the index equals $10 then set CGADD to 128 where the sprite palette is
	cmp #$3F10
	beq moveCGADDto128
	RETW
moveCGADDto128:
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	lda #128
	sta CGADD               ; FIXME this is set before each write, test if not neede here
	RETW
changewrfunction:
	jmp emptyrange

colormirroring:
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	;; Copy the color at every b0000XX00 address
	;; BG palette
	lda #$00
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$04
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$08
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$0C
	sta CGADD
	stx CGDATA
	sty CGDATA
	;; Sprite palette
	lda #$80
	sta CGADD
	stx CGDATA
	sty CGDATA	
	lda #$84
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$88
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$8C
	sta CGADD
	stx CGDATA
	sty CGDATA
	jmp endwpumem


RPPUMEMDATA:
	;; TODO
	RETR


AttrtableR:
	RETR

NametableR:
	RETR

paletteR:
	RETR

; ------+-----+---------------------------------------------------------------
; $4000-$4013 | Sound Registers
;             | See "Sound".

.include "Sound.asm"
	
; 	;; TODO
;   {0x4000, "SNDSQR1CTRL"},
;   {0x4001, "SNDSQR1E"},
;   {0x4002, "SNDSQR1PERIOD"},
;   {0x4003, "SNDSQR1LENPH"},
;   {0x4004, "SNDSQR2CTRL"},
;   {0x4005, "SNDSQR2E"},
;   {0x4006, "SNDSQR2PERIOD"},
;   {0x4006, "SNDSQR2LENPH"},
;   {0x4007, "SNDTRIACTRL"},
;   {0x4008, "SNDTRIAPERIOD"},
;   {0x4009, "SNDTRIALENPH"},
;   {0x400A, "SNDNOISECTRL"},
;   {0x400B, "SNDNOISESHM"},
;   {0x400C, "SNDNOISELEN"},
;   {0x400D, "SNDDMCCTRL"},
;   {0x400E, "SNDDMCDAC"},
;   {0x400F, "SNDDMCSADDR"},
;   {0x4010, "SNDDMCSLEN"},
;   {0x4011, "SNDCOMONCTRL1"},
;   {0x4012, "SNDCOMONCTRL2"},
;   {0x4013, "SNDSTATUS"},

; ------+-----+---------------------------------------------------------------
; $4014 | W   | DMA Access to the Sprite Memory
;       |     | Writing a value N into this port causes an area of CPU memory
;       |     | at address $100*N to be transferred into the Sprite Memory.

WDMASPRITEMEMACCESS:
	;; Point the direct page register on the indicated page
	phd			; pushes the D 16bit register
	sep #$20		; A 8b
	swa			; clear the upper byte of A
	lda #0
	swa
	rep #$20		; A 16b
	pha			; push the page of the sprite data
	pld			; Here every zero page read is in the indicated page
	;; Convert the 256 bytes of the memory area to 256bytes of snes oam data
	sep #$30			; all 8b
	ldx #0
sprconversionloop:
	lda $03,X			; sprite X position
	sta SpriteMemoryBase + 0,X
	lda $00,X			; sprite Y position
	sta SpriteMemoryBase + 1,X
	lda $01,X			; sprite tile number
	sta SpriteMemoryBase + 2,X
	lda $02,X			; sprite flags
	;; Convert the flags to the snes sprite flags
	jsr convert_sprflags_to_nes
	sta SpriteMemoryBase + 3,X
	inx
	inx
	inx
	inx
	bne sprconversionloop		; loop if not zero

	;; Loop transfert
	stz OAMADDL
	ldx #0
looptransfert:
	lda SpriteMemoryBase,X	; sprite X position
	sta OAMDATA
	inx
	bne looptransfert		; loop if not zero

	pld				; restore the direct page register
	RETW

	;; TODO DMA use seems stupid because a loop has been already executed...
	;; Transfert the 256 bytes to the OAM memory port via DMA 1
	;; -------------------------------------------------------------
	;; Writes to OAMDATA from 0 to 256
	stz OAMADDL
	lda #$04		; OAMDATA register low byte ($2104)
	sta DMA1BDEST
	;; Size = $100 = 256
	lda #$01
	sta DMA1SZH
	stz DMA1SZL
	;; Source address (in RAM)
	rep #$20		; A 16b
	lda SpriteMemoryBase
	sta DMA1RAMSRCL
	sep #$20		; A 8b
	;; DMA mode:   CPU RAM to PPU RAM 0, x, x, 00 automatic increment, 00 one address per byte
	lda #%00000000
	sta DMA1CTL
	;; Start the transfert
	lda #$02
	sta MDMAEN
	RETW

;; NES
; Sprite Attribute RAM:
; | Sprite#0 | Sprite#1 | ... | Sprite#62 | Sprite#63 |
;      |          |
;      +---- 4 bytes: 0: Y position of the left-top corner - 1
;                     1: Sprite pattern number
;                     2: Color and attributes:
;                        bits 1,0: two upper bits of color:	 4colors palette selection
;                        bits 2,3,4: Unknown (???)
;                        bit 5: if 1, display sprite behind background
;                        bit 6: if 1, flip sprite horizontally
;                        bit 7: if 1, flip sprite vertically
;                     3: X position of the left-top corner
;; 
; 0 yyyyyyyy -> 1
; 1 cccccccc -> 2
; 2 vho--ppp -> 3 + conversion
; 3 xxxxxxxx -> 0

;3 0 1 conversion(2)

;; SNES
; xxxxxxxx
; yyyyyyyy
; cccccccc
; vhoopppN
;; 
; Xxxxxxxxx = X position of the sprite. Basically, consider this signed but see below.
; yyyyyyyy  = Y position of the sprite.^
; cccccccc  = First tile of the sprite.^^
; N         = Name table of the sprite. See below for the calculation of the VRAM address.
; ppp       = Palette of the sprite. The first palette index is 128+ppp*16.
; oo        = Sprite priority. See below for details.
; h/v       = Horizontal/Vertical flip flags.^^^
; s         = Sprite size flag. See below for details.

; ------+-----+---------------------------------------------------------------
; $4015 |  W  | Sound Channel Switch
;       |   0 | Channel 1, 1 = enable sound.
;       |   1 | Channel 2, 1 = enable sound.
;       |   2 | Channel 3, 1 = enable sound.
;       |   3 | Channel 4, 1 = enable sound.
;       |   4 | Channel 5, 1 = enable sound.
;       | 5-7 | Unused (???)
; Status if Read:
;       |  R 
;	|   0 | PULS1 length counter status
;	|   1 |	PULS2 length counter status
;	|   2 | TRIAN length counter status
;	|   3 | NOISE length counter status
;	|   4 | DMC   length counter status
;	|     |
;	|   6 | frame IRQ
;	|   7 | DMC IRQ

WSNDCHANSWITCH:
	RETW

RSNDCHANSWITCH:
	RETR

; ;------+-----+---------------------------------------------------------------
; ;$4016 | RW  | Joystick1 + Strobe
; ;      |   0 | Joystick1 Data (see "Joysticks).
; ;      |   1 | Joystick1 Presence, 0 = connected.
; ;      | 2-5 | Unused, set to 000 (???)
; ;      | 6-7 | Unknown, set to 10 (???)

WJOYSTICK1:
	sep #$20	; A 8b
	sta $4016	; Same register, Same function, latch the data:
			; In fact no need to change the instruction from the NES
	RETW

RJOYSTICK1:
	sep #$20	; A 8b
	lda $4016
	; and #$FD 	; Clear bit 2 (2nd paddle input bit)
	ora #$40	; bits 7-6 set to 01
	RETR

;------+-----+---------------------------------------------------------------
;$4017 | RW? | Joystick2 + Strobe
;      |   0 | Joystick2 Data (see "Joysticks).
;      |   1 | Joystick2 Presence, 0 = connected.
;      | 2-5 | Unused, set to 000 (???)
;      | 6-7 | Unknown, set to 10 (???)
;------+-----+---------------------------------------------------------------
RJOYSTICK2:
	sep #$20	; A 8b
	lda $4016
	rol A		; Paddle 2 bit goes from bit 1 to bit 0
	ora #$40	; bits 7-6 set to 01
	RETR
.ENDS
