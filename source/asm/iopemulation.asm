	;; IO ports are not identical between the nes and snes (except compatibility for the paddles)
	;; In order to recompile a nes game for the super nes, the instructions
	;; using io ports must be replaced by code doing the equivalent thing on the super nes.
	;;
	;; The documentation for io ports taken from the "Nintendo Entertainment System
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

;; Write ports, this is an array of write port routines addresses
IOWroutinestable:
.DW	WPPUC1				; $2000
.DW	WPPUC2				; $2001
.DW	$0000
.DW	WSPRADDR			; $2003
.DW	WSPRDATA			; $2004
.DW	WSCROLOFFSET		; $2005
.DW	WPPUMEMADDR			; $2006
.DW	WPPUMEMDATA			; $2007
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
.DW	WSNDDMCCTRL			; $4010
.DW	WSNDDMCDAC			; $4011
.DW	WSNDDMCSADDR		; $4012
.DW	WSNDDMCSLEN			; $4013
;; DMA
.DW	WDMASPRITEMEMACCESS	; $4014
;; Sound again
.DW	WSNDCHANSWITCH		; $4015
;; Joystick but not replaced
.DW	WJOYSTICK1			; $4016 WJOYSTICK1
.DW	WSNDSEQUENCER		; WSNDSEQUENCER / WJOYSTICK2

;; Read ports
IORroutinestable:
.DW	RPPUC1				; $2000
.DW	RPPUC2				; $2001
.DW	RPPUSTATUS			; $2002
.DW	$0000
.DW	RSPRDATA			; $2004
.DW	$0000
.DW	$0000
.DW	RPPUMEMDATA			; $2007
;; Sound registers
.DW	$0000				; $4000
.DW	$0000				; $4001
.DW	$0000				; $4002
.DW	$0000				; $4003
.DW	$0000				; $4004
.DW	$0000				; $4005
.DW	$0000				; $4006
.DW	$0000				; $4007
.DW	$0000				; $4008
.DW	$0000				; $4009
.DW	$0000				; $400A
.DW	$0000				; $400B
.DW	$0000				; $400C
.DW	$0000				; $400D
.DW	$0000				; $400E
.DW	$0000				; $400F
.DW	$0000				; $4010
.DW	$0000				; $4011
.DW	$0000				; $4012
.DW	$0000				; $4013
;; DMA
.DW	$0000				; $4014 DMA
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
	sep #$30		; All 8 bit
	sta PPUcontrolreg1      ; Save the written value
	;; ------------------------------------------
	;; Test Nametable @ bits
	;; Mirroring is the default value. FIXME add cartridge nametables?
	and #$01
	beq firstnametableaddress  ; If zero flag then it it the first nametable
    lda #$74                ; (1k word segment $7400 / $400)=$1D << 2
	ora #$01                ; Right screen following the first one
    sta BG1SC
	jmp endnametableaddress
firstnametableaddress:	
    lda #$70                ; (1k word segment $7000 / $400)=$1C << 2
	ora #$01                ; Right screen following the first one
    sta BG1SC
endnametableaddress:
	;; ------------------------------------------
	;; Sprite pattern table address
	lda #$08
	bit PPUcontrolreg1	; test bit 3 (#$08), zero if not set ("bit and" result)
	bne Spritesinsecondbank
	;; Do a conversion in the WRAM and then a DMA transfert to $0000 in vram
	lda #$00		;; TODO use a table to organise the sprite buffers as a cache
	ldy #$00
	jsr NesSpriteCHRtoWram
	jsr DMA_WRAMtoVRAM_sprite_bank
	jmp Spritebankend
Spritesinsecondbank:
	lda #$01
	ldy #$01
	jsr NesSpriteCHRtoWram
	jsr DMA_WRAMtoVRAM_sprite_bank
	jmp Spritebankend
Spritebankend:
	sep #$30		; All 8 bit
	;; ------------------------------------------
	;; Test Screen Pattern Table Address (BG chr 4kB bank 0 or 1)
	lda #$10
	bit PPUcontrolreg1
	bne secondbgchrbank
	lda #$02		; 0x0002 -> 4kWord=8kB segment 2
	sta BG12NBA		; CHR data in VRAM starts at 0x2000
	jmp BGbankend
secondbgchrbank:
	lda #$03		; 0x0003 -> 4kWord=8kB segment 3
	sta BG12NBA		; CHR data in VRAM starts at 0x3000
BGbankend:
	;; ------------------------------------------
	;; Sprite size
	;; ------------------------------------------

	;; FIXME is it used on the nes?.???? enable and disable screen?????????????????????????????????,,,,,,,
	lda #$0F		  ;Turn on screen, 100% brightness
	sta INIDISP
	;lda #$8F		  ;Turn off screen, 100% brightness
	;sta INIDISP

	;; Test Vblank
	;lda #$80
	bit PPUcontrolreg1  ; Puts the 7th bit in the n flag
	bpl novblank		; Therefore bpl branches if the 7th bit is not set
	; Vblank interrupt enabled
	lda SNESNMITMP
	ora #$80
	sta NMITIMEN
	sta SNESNMITMP
	jmp vblankend
novblank:
	; Vblank interrupt disabled
	lda SNESNMITMP
	and #$7F
	sta NMITIMEN
	sta SNESNMITMP
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
	sta tmp_dat
	;; Test bit 4:	Sprite enable
	lda PPUcontrolreg2
	and #$10                ; Keep only the 4rth bit
	ora tmp_dat
	sta TM			; BG1 enabled as a main screen, Sprite enable (also bit 4)
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
	lda #$01
	cmp StarPPUStatus
	beq PowerUp     ; If 1, then it is power up (always here, even on reset)
	;lda HVBJOY
	lda NMIFLAG 	; NMIFLAG has the same behaviour as the nes, and not HVBJOY flag
	and #$80
	;; sprite 0
	ora SPRITE0FLAG
	jmp EndRPPUSTATUS
PowerUp:
	stz StarPPUStatus ; Boot passed
	lda #$80          ; return boot PPUSTATUS
EndRPPUSTATUS:
	RETR

; ------+-----+---------------------------------------------------------------
; $2003 | W   | Sprite Memory Address
;       |     | Used to set the address of the 256-byte Sprite Memory to be 
;       |     | accessed via $2004. This address will increment by 1 after
;       |     | each access to $2004. Sprite Memory contains coordinates,
;       |     | colors, and other sprite attributes (see "Sprites").
WSPRADDR:
	; OAM direct address conversion: addresses 4bytes on nes, and 4bytes on snes
	; but OAM is a word address and can be updated by dma
	; and therefore a buffer in ram could be nice and therefore
	; a buffer it will be in order to keep Byte addressing.
	sta SpriteMemoryAddress
	;##############
	; Useless, will be configured later
	;lsr A          		; Word address on the snes
	;sta OAMADDL         ; OAM address Low   set to Acc
	;stz OAMADDH         ; OAM address Hight set to $00
	; OAM = $00 Acc
	;##############
	RETW

; ------+-----+---------------------------------------------------------------
; $2004 | RW  | Sprite Memory Data
;       |     | Used to read/write the Sprite Memory. The address is set via
;       |     | $2003 and increments by 1 after each access. Sprite Memory 
;       |     | contains coordinates, colors, and other sprite attributes
;       |     | sprites (see "Sprites").
; Writes directly in OAM but because the sprite format is
; not the same, a lot of address changes occur.
;
WR_OAMconversionroutines:
	.DW WRITE_SPR_Y
	.DW WRITE_SPR_TILE
	.DW WRITE_SPR_FLAGS
	.DW WRITE_SPR_X
; Byte          Byte
; 0 yyyyyyyy -> 1                y pos
; 1 cccccccc -> 2                tile number
; 2 vho--ppp -> 3 + conversion   flipv fliph priority palete
; 3 xxxxxxxx -> 0                x pos
WSPRDATA:
	;BREAK ; break at $0918
	sep #$30		; All 8bits
	tay             ; save the byte in Y
	ldx #$00
	lda SpriteMemoryAddress ; Read the address written in OAMADDR
	;; Test which of the 4 bytes is to be written
	and #$03
	asl A			; x2 to get the routine index address (+ 0 2 4 6 in WR_OAMconversionroutines)
	tax
	jmp (WR_OAMconversionroutines,X) ; Jump to the routine for the selected address
	; The sprite information will be stored in ram in snes format, therefore, converted to snes format.
WRITE_SPR_Y:
	lda SpriteMemoryAddress  ; Y offset 0 to 1
	and #$FC
	ora #01
	tax
	tya
	sta SpriteMemoryBase,X   ; Store it
	jmp sprwrdoneLo          ; Update in video ram lower word
WRITE_SPR_TILE:
	lda SpriteMemoryAddress  ; TileNumber offset 1 to 2
	and #$FC
	ora #02
	tax
	tya
	sta SpriteMemoryBase,X   ; Store it
	jmp sprwrdoneHi          ; Update in video ram highter word
WRITE_SPR_FLAGS:
	lda SpriteMemoryAddress
	and #$FC
	ora #03
	tax
	tya
	jsr convert_sprflags_to_snes ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tay
	sta SpriteMemoryBase,X
	jmp sprwrdoneHi
WRITE_SPR_X:
	lda SpriteMemoryAddress  ; X offset 3 to 0
	and #$FC
	tax
	tya
	sta SpriteMemoryBase,X
	jmp sprwrdoneLo

	;; Writes the byte twice: first converts it and writes in the buffer and then writes a word
	;; in the coresponding OAM address to update it.
sprwrdoneHi:
	lda SpriteMemoryAddress
	and #$FC  ; The address is a multiple of 4bytes
	ora #$02  ; Take the last 2 bytes (Hi)
	jmp updateOAM
sprwrdoneLo:
	lda SpriteMemoryAddress
	and #$FC  ; Take the first 2 bytes
	; Just update the 4 bytes
updateOAM:
	tax
	lsr A                       ; Word address
	;sta OAMADDL                 ; Destination address in OAM memory, words
	;stz OAMADDH
	; Copy the word to be updated into the OAM memory
	lda SpriteMemoryBase,X      ; Source address from the buffer used to store the nes OAM
	;sta OAMDATA
	lda SpriteMemoryBase + 1,X
	;sta OAMDATA               ;; FIXME TODO it is a bug here, the data is written at the end of OAM, maybe because of vblank, do not update?
IncSprAddr:
	;; Increment the buffer's byte address
	ldy SpriteMemoryAddress
	tya
	cmp #$FF		; If 256 do not loop od what? FIXME TODO
	beq endWSPRDATA
	iny
	sty SpriteMemoryAddress ; Incrementd by one
endWSPRDATA:
	RETW

; Acc contains the byte
; NES vhoxxxpp   SNES vhoopppN
convert_sprflags_to_snes:
	; pp
	tay
	and #$03
	asl
	;lda #$00 ; Force to palete 0
	sta PPTMP
	tya
	; vh
	and #$E0		; Keep vh and 0
	ora #$30 ; Force to max priority
	ora PPTMP		; Add pp
	;; o (priority flag) will be 2 or 0. If 1 the sprite will be above BG3 and 4
	;; maximum priority: 3 = over everything but the printf BG must be on top, so use 2
	; force priority lda #$34
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
	lsr A
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
	sep #$30		; All 8b
	tax
	cmp #240		; > 239?
	bcs ignorescrollvalue
	lda CurScrolRegister
	beq horizontal_scroll   ; 0 horizontal, 1 vertical
vertical_scroll:
	txa
	clc
	adc #$08                ; Add 8 because the first row is not visible on nes boot.
	sta BG1VOFS             ; This register must be written twice
	stz BG1VOFS 		    ; High byte is 0
	jmp chgscrollregister
horizontal_scroll:
	txa
	sta BG1HOFS		        ; This register must be written twice
	stz BG1HOFS 		    ; High byte is 0
ignorescrollvalue:          ; ignore the value but change the register state
chgscrollregister:
	lda CurScrolRegister
	eor #$01		        ; Change the acessed scroll register
	sta CurScrolRegister
	RETW

; ------+-----+---------------------------------------------------------------
; $2006 | W   | PPU Memory Address
;       |     | Used to set the address of PPU Memory to be accessed via
;       |     | $2007. The first write to this register will set 6 upper
;       |     | address bits. The second write will set 8 lower bits. The
;       |     | address will increment either by 1 or by 32 after each
;       |     | access to $2007 (see "PPU Memory").
	;; This code section will update the PPU address and change the routines to be called during the access 
	;; to $2007 wich is the PPU memory data.
	;;
	;; Name table, Attribute table, Palette, ou empty
WPPUMEMADDR:
	sep #$30            ; All 8b
	ldy PPUmemaddrB     ; Get the adressed byte
	sta PPUmemaddrL,Y	; Store the address in this byte
	tya
	eor #$01
	sta PPUmemaddrB		; Toggle the accessed byte (0 or 1)
	ora #$00	        ; Test if address update is finished (byte 1) or not finished (byte 0). Return if not finished (0).
	beq ppumaddret
	;; -----------------------------------------------
	;; The address write is completed here
	;; Select the routine for it's address range
	lda PPUmemaddrH
	;; Find the address range
	cmp #$20		     ; On the nes, below $2000, it is CHR data
	bcc emptyrangej		 ; A < #$20, prepare an empty routine
	cmp #$30
	bcs afternametablesj ; A >= #$30  Past $3000 empty or palette
	;; #$20 <= @ < #$30
	;; $2000 to $23C0 = Nametables  $23C0 to $2400 = Attributes
	;jsr set_tilemap_addr
	lda PPUmemaddrL      ; xxxx xx11 11xx xxxx means attribute table
	and #$C0		     ; Lo bits $C0 11xx.  Keep only bits 6-7
	sta tmp_addr
	lda PPUmemaddrH
	and #$03             ; Hi bits $03 xx11
    ora tmp_addr
	cmp #$C3             ; Test if all 4 bits are set
	beq attributetables	 ; == it is an attribute table: above $x3C00
	jmp nametables       ; else it is a nametable
ppumaddret:
	RETW
emptyrangej:
	jmp emptyrange
afternametablesj:
	jmp afternametables
;; -------------------------------------------------------------------------
attributetables:
	; attribute table addresses are not directly equivalent
	; For a given attribute address the line and column of the first tile of a 4x4 group is:
	; line   = 4 * ((attr@ - base@) / 8)
	; column = 4 * ((attr@ - base@) % 8) = 4 * ((attr@ - base) & $03)
	;
	; 32/4 = 8 blocks per line, 8 blocks vertically
	; writing at 0 4 8 12 16 20 24 28 ; and then 32 * 4 + 32, + 36...
	; First tile = ((offset / 8) * 128) + ((offset % 8) * 4)
	;            = ((offset >> 3) << 7) + ((offset & $07) << 2)
	;
	; A row of nes attributes (8bytes) covers 128 tiles (4 rows of 32 tiles = 128 tiles)
	; line is (@ / 8)  row is (@ & $07)
	; Snes @ = line * 32 * 4 * 2 + row * 4 * 2
	; So first of, @ * 8, then masks, then add
	;BREAK2 ; break at $0919
	;RETW
	jsr ppuAddToVram
	;; Attributes routines
	rep #$20 ; A 16bits
	lda #AttrtableW
	sta PPUW_RAM_routineAddr
	lda #AttrtableR
	sta PPUR_RAM_routineAddr
	RETW
	
ppuAddToVram:
	rep #$30		; A 16bits XY 16bits
	lda PPUmemaddrL	; Load the ppu memory address suposed to be in the attribute range: $23C0 to $2400 or 27C0 to 2800
	and #$FBFF      ; Get an @ in $23C0 to $2400
	; Do not optimise, it is easier to debug.
	sec        ; Set carry otherwise the result of sbc will be a two's complement.
	sbc #$23C0 ; Substract the base @
	tay
	; Colum
	and #$0007 ; 8 Blocks of 4 per line
	asl A
	asl A
	asl A			; << 3  x8
	sta tmp_addr
	; line:
	tya
	and #$0038 ; line * 16 * 8 * 2 = 32 * 8 (already shifted 3 = * 8) -> *32
	asl A
	asl A
	asl A
	asl A
	asl A			; << 5  x32
	clc
	adc tmp_addr
	; Store the nametable address
	sta attributeaddr
	rts

;; -------------------------------------------------------------------------
nametables:
	rep #$20		; A 16bits
	lda PPUmemaddrL
	and #$07FF		; Lower address value
	;BREAK
	asl             ; word adress
	;sta tmp_addr
	;tya             ; y is VRAM base @ set by set_tilemap_addr
	;clc
	;adc tmp_addr
	; Set the address in snes register
	sep #$20		; A 8bits
	; The adress is in word count (should be $(3/7)000 to $(3/7)003F)
	sta NameAddresL
	xba
	sta NameAddresH
	; Test bit 2 of PPUCTRL: 1 or 32 nametable increment
	lda #$04
	bit PPUcontrolreg1	; test bit 2, zero if not set ("bit and" result)
	bne name_incr_32
	; Vram increments 1 by 1 after VMDATAL write, 2bytes on the snes because nametables are words name + palette
	lda #$02
	sta VideoIncrementL
	;lda VideoIncrement 		; after VMDATAL w;
	;sta VMAINC
	jmp set_nametables_routines
name_incr_32:
	; Vram increments 32 by 32 after VMDATAL write (words on the snes)
	lda #$40
	sta VideoIncrementL
	;lda VideoIncrement 		; after VMDATAL wr
	sta VMAINC
set_nametables_routines:
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
	bcc emptyrange	; empty area before palette data
	lda PPUmemaddrL
	cmp #$20		; End of the palette area
	bcs emptyrange	; if greater than $20, then it is an empty area
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
;set_tilemap_addr
;.8BIT
;	sep #$20		; A 8bit
;	rep #$10        ; X Y are 16bits
;	lda PPUmemaddrH	; address hight byte
;	and #$04		; bit 11: 0 = Tables 0 & 2; 1 = Tables 1 & 3 (TODO not always mirror???)
;	cmp #$04
;	beq Tables1_3
;	ldy #NAMETABLE1BASE	; snes BG1 names/attributes VRAM address: $7000 (Word addres)
;	rts
;Tables1_3:
;	ldy #NAMETABLE2BASE	; snes BG1 names/attributes VRAM address: $7400 (Word addres)
;	rts

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
	jmp (PPUW_RAM_routineAddr)   ; Indirect jump to the routine for the address.

	;; -------------------------------------------------------------------------	
	;; Attribute tables
	;; write the highter 6bits of the words at $A000 4x4 tiles at time.
	;; In fact only 2bits on the nes.
	;;
AttrtableW:
	;; Attribute byte: 33|22|11|00
	;; Tiles:   00 00 | 11 11
	;;          00 00 | 11 11
	;;          -------------
	;;          22 22 | 33 33
	;;          22 22 | 33 33
	;; Therefore 4 writes + 3 * 4 writes at @+28

	;; SNES
	; vhopppcc cccccccc
	; v/h        = Vertical/Horizontal flip this tile.
	; o          = Tile priority.
	; ppp        = Tile palette. The number of entries in the palette depends on the Mode and the BG.
	; cccccccccc = Tile number. Do ont care for the higher cc
	;RETW
	;BREAK ; break at $0918
	sep #$20		; Acc 8bits
	tay
	; First save the value for a read
	lda PPUmemaddrL
	sec
	sbc #$C0
	and #$3F        ; Protect against overflow
	tax
	tya
	sta Attributebuffer,X
	; Copy the values in the name tables
	rep #$10        ; X Y are 16bits	
	;txa
	asl A			; Attibute palette are at bits 2 3 4 on snes, so shift the data.
	asl A
	and #$0C		; 00
	ldx attributeaddr
	sta NametableBaseBank1+1,X    ; Store the value in the ram buffer
	sta NametableBaseBank1+3,X
	sta NametableBaseBank1+65,X ; The line below
	sta NametableBaseBank1+67,X
	tya
	and #$0C		; 11
	sta NametableBaseBank1+5,X  ; Store the value in the ram buffer
	sta NametableBaseBank1+7,X
	sta NametableBaseBank1+69,X
	sta NametableBaseBank1+71,X
	;; Lower 2 x 4 tiles
	tya
	clc
	ror A
	ror A
	tay
	ror A
	ror A
	and #$0C		; 33
	sta NametableBaseBank1+133,X  ; Store the value in the ram buffer
	sta NametableBaseBank1+135,X
	sta NametableBaseBank1+197,X
	sta NametableBaseBank1+199,X
	tya
	and #$0C		; 22
	sta NametableBaseBank1+129,X   ; Store the value in the ram buffer
	sta NametableBaseBank1+131,X
	sta NametableBaseBank1+193,X
	sta NametableBaseBank1+195,X
	;; Add the updated tile data to the tiles to be updated by dma

	;; Increment the Attribute address
	lda PPUmemaddrL	; Load the ppu memory address
	clc
	adc #$0001      ; increment it and store it
	sta PPUmemaddrL
	rep #$20		; Acc 16bits
	lda attributeaddr
	clc
	adc #$0008
	sta attributeaddr
	and #$003F		; addr % 64 = 0?
	beq add256		; If 0 then it is on the begining of the line
	;; Done
	RETW
add256:
	lda attributeaddr
	clc
	adc #$0100
	sta attributeaddr
	;; Done
	RETW

	;; -------------------------------------------------------------------------
	;; Name tables
NametableW:
	sep #$20		; A 8bit
	rep #$10        ; X Y are 16bits
	; Store the byte
	ldx NameAddresL
	sta NametableBaseBank1,X   ; Write to VRAM. This is the lower nametable byte, the character code number.
	; If room is available for a HDMA transfer, store the word to be updated
	;tay
	;lda NamesBank1UpdateCounter
	;sbc MaxNameHDMAUpdates
	;beq NoMoreUpdates
	; Add the word to be updated to the HDMA table
	;tya ; Restore Acc
	
	;clc
	;adc #$0001	
	;sta NamesBank1UpdateCounter
NoMoreUpdates:
	; Increment
	rep #$20		; A 16bit
	lda NameAddresL
	clc
	adc VideoIncrementL
	sta NameAddresL
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
	; Save the byte in sram for the next read
	and #$1F
	tay
	txa
	sta Palettebuffer,Y
	; CG ram address to (PPUmemaddr - $3F00), in fact ommit the $3F
	lda PPUmemaddrL
	; Test if it is a sprite address
	cmp #$10		; A >= $10
	bcs paladdr_add_128
	jmp setcgaddr
paladdr_add_128:
	pha
	;and #$EF        ; remove the $10
	and #$EC        ; remove the 2 lower bits
	asl             ; Shift right twice because the paletes on the snes contain 16 colors and not 4.
	asl
	ora #$80		; Add 128
	sta tmp_dat
	pla
	and #$03
	ora tmp_dat
	
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

;----------------------------------------------------------------------
; 
RPPUMEMDATA:
	jmp (PPUW_RAM_routineAddr)   ; Indirect jump to the routine for the address.

AttrtableR:
	; Read it from the sram buffer
	sep #$30		; All 8bit
	lda PPUmemaddrL
	sec
	sbc #$C0
	and #$3F
	tax
	tya
	lda Attributebuffer,X
	; Increment
	rep #$30		; 16bit XY and A
	ldx PPUmemaddrL
	inx
	stx PPUmemaddrL
	RETR

NametableR:
	; Read it from the sram buffer
	sep #$20		; A 8bit
	rep #$10        ; X Y are 16bits
	; Store the byte
	ldx NameAddresL
	lda NametableBaseBank1,X 
	; Increment the address
	rep #$20		; A 16bit
	lda NameAddresL
	clc
	adc VideoIncrementL
	sta NameAddresL
	RETR

paletteR:
	; Read it from the CG buffer in sram
	sep #$30		; All 8bit
	lda PPUmemaddrL
	and #$1F
	tax
	lda Palettebuffer,X
	; Increment
	rep #$30		; 16bit XY and A
	ldx PPUmemaddrL
	inx
	stx PPUmemaddrL
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
; Makes a copy of 256 bytes form the memory at $100*N (typically $0200-$02FF)
; to the OAM data memory.
WDMASPRITEMEMACCESS:
	;;------------------------------------------------------------------------------
	;; Point the direct page register on the indicated page
	phd			; pushes the D 16bit register
	sep #$20    ; A 8b
	swa			; clear the upper byte of A
	lda #0
	;swa kept in the higher byte because when not in emulation @ = [0 DH $Byte] + Y 
	;    Like if D = 2 Byte = 3 then @ = $000203
	rep #$20	; A 16b
	;pha			; push the page of the sprite data
	;pld			; Here every zero page read is in the indicated page
	tcd
	;;------------------------------------------------------------------------------
	;; First convert the 256 bytes of the memory area to 256bytes of snes oam data
	sep #$30    ; All 8b
	ldx #0
	;;;;ldy SpriteMemoryAddress ; Origin of the data OAMADDR not in use here 256 bytes
	; It uses a direct page indexed address, meaning it reads from the 256Bytes page with X as index.
sprconversionloop:	
	lda $00,X	  ; Read Y, direct page  *(DP + $00 + X)
	sec
	sbc #$08      ; Sub 8 because the first line is not seen
	sta SpriteMemoryBase + 1,X    ; Store it
	lda $01,X	  ; Read cccccc (tile index)
	sta SpriteMemoryBase + 2,X    ; Store it
	lda $02,X	  ; Read the flags
	jsr convert_sprflags_to_snes  ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	sta SpriteMemoryBase + 3,X    ; Store them
	lda $03,X	  ; Read X
	sta SpriteMemoryBase + 0,X    ; Store it	
	inx
	inx
	inx
	inx
	bne sprconversionloop	; loop if not zero	(passed 256)	
	;;------------------------------------------------------------------------------
	;; Then copy the 256 bytes into the OAM memory
wait_for_vblank:
	lda HVBJOY		;check the vblank flag
	bpl wait_for_vblank
.DEFINE USEDMA
.IFDEF USEDMA
	;; Transfer the 256 bytes to the OAM memory port via DMA 1
	;; -------------------------------------------------------------
	stz MDMAEN      ; disable any dma channel
	;; Writes to OAMDATA from 0 to 256
	stz OAMADDL
	stz OAMADDH
	;; DMA mode:   CPU RAM to PPU RAM 0, x, x, 00 automatic increment, 00 one address per byte
	sep #$20		; A 8b
	lda #%00000000
	sta DMA1CTL     ; Write the mode before everything else
	lda #$04		; OAMDATA register, byte ($2104)
	sta DMA1BDEST
	;; Size = $100 = 256
	rep #$20		; A 16b
	lda #$0100
	sta DMA1SZL
	;; Source address (in RAM)
	rep #$20		; A 16b
	lda #SpriteMemoryBase
	sta DMA1A1SRCL
	sep #$20		; A 8b
	phb
	pla
	sta DMA1A1SRCBNK ; bank
	;; Start the transfert
	sep #$20	; A 8b
	lda #$02    ; channel 1
	sta MDMAEN
	pld			; restore the direct page register
	RETW
.ELSE
	; A loop instead of a dma transfert
	sep #$30		; all 8b
	stz OAMADDL     ; OAM address set to $00
	stz OAMADDH     ; OAM address set to $00	
	ldx #0
sprtransfertloop:
	lda SpriteMemoryBase,X  ; Copy the 256 bytes
	sta OAMDATA
	inx
	bne sprtransfertloop	; loop if not zero
	pld			; restore the direct page register
	RETW
.ENDIF
	
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
