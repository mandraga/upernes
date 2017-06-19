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
	;BREAK
	sep #$30		     ; All 8 bit
	sta PPUcontrolreg1   ; Save the written value
	;; ------------------------------------------
	;; Test Nametable @ bits
	;; Mirroring is the default value. FIXME add cartridge nametables?
	;and #$01
	;beq firstnametableaddress  ; If zero flag then it it the first nametable
    ;lda #$74            ; (1k word segment $7400 / $400)=$1D << 2
	;ora #$01	         ; Right screen following the first one
    ;sta BG1SC
	;jmp endnametableaddress
firstnametableaddress:
	; Always on bank 0 and add this bit to the scrolling ergister
    lda #$70             ; (1k word segment $7000 / $400)=$1C << 2
	ora #$01             ; Right screen following the first one
    sta BG1SC
endnametableaddress:
	;; ------------------------------------------
	;; Sprite pattern table address
	lda #$08
	bit PPUcontrolreg1	; test bit 3 (#$08), zero if not set ("bit and" result)
	bne Spritesinsecondbank
	; Do not update the bank all the time, only if it changes
	lda SpriteCHRChg
	cmp #SprCHRB1
	beq Spritebankend
	lda #SprCHRB1
	sta SpriteCHRChg
	;; Do a conversion in the WRAM and then a DMA transfert to $0000 in vram
	lda #$00		;; TODO use a table to organise the sprite buffers as a cache
	ldy #$00
	jsr NesSpriteCHRtoWram
	jsr DMA_WRAMtoVRAM_sprite_bank
	jmp Spritebankend
Spritesinsecondbank:
	; Update the bank
	lda SpriteCHRChg
	cmp #SprCHRB2
	beq Spritebankend
	lda #SprCHRB2
	sta SpriteCHRChg
	; Bank 2 update
	lda #$01
	ldy #$01
	jsr NesSpriteCHRtoWram
	jsr DMA_WRAMtoVRAM_sprite_bank
	jmp Spritebankend
Spritebankend:
	sep #$30		; All 8 bit
	;; ------------------------------------------
	;; Test Screen Pattern Table Address (BG chr 4kB bank 0 or 1)
	lda #$10 ; FIXME it should be bit 0?
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
	lda #$01
	sta NESNMIENABLED
	lda SNESNMITMP
	ora #$80
	sta NMITIMEN
	sta SNESNMITMP
	jmp vblankend
novblank:
	; Vblank interrupt disabled
	stz NESNMIENABLED	
	lda SNESNMITMP
	;and #$7E
	and #$00    ; Try to limitate the effect
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
;       |     |
;       |   7 | VBlank Flag, 1 = PPU is in VBlank state.
;       |     | This flag resets to 0 when VBlank ends or CPU reads $2002
;       |     |
RPPUSTATUS:
	sep #$20
	;; vblank
	lda #$01
	cmp StarPPUStatus
	beq PowerUp     ; If 1, then it is power up (always here, even on reset)
	jsr updateSprite0Flag
	; If the nes NMI on Vblank is disabled it does not mean that VBlank is not occuring
	; Just compare the counter value
	rep #$20 ;  A 16bits
	;BREAK
	lda VCOUNTL
	cmp #239
	bcs InVblank ; A >= 239
	lda #$00
	jmp GetSprite0Flag
InVblank:
	lda #$80   ; Vblank enabled
GetSprite0Flag:
	sep #$20
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
	; Copy the word to be updated into the OAM memory
	lda SpriteMemoryBase,X      ; Source address from the buffer used to store the nes OAM
	lda SpriteMemoryBase + 1,X
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
	eor #$30  ; On the nes: 0 for front or 1 for back. On the Snes 2 or 3 for front or 0 for back of BG 1.  Reverse the value
	;ora #$30 ; Force to max prior
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
	BREAK2
	tax
	cmp #240		; > 239?
	bcs ignorescrollvalue
	lda CurScrolRegister
	beq horizontal_scroll   ; 0 horizontal, 1 vertical
vertical_scroll:
	txa
	sta BG1VOFS             ; This register must be written twice
	stz BG1VOFS 		    ; High byte is 0
	jmp chgscrollregister
horizontal_scroll:
	sep #$30		; All 8b
	lda PPUcontrolreg1  ; FIXME works only with horizontal mappers
	and #$01
	stx BG1HOFS		        ; This register must be written twice
	sta BG1HOFS 		    ; High byte's lower bit comes from PPU control 1 lower bit when scrolling horizontally
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
	; Set the latch for the next read operation
	lda #$01
	sta PPUReadLatch
	;; Select the routine for it's address range
	lda PPUmemaddrH
	;; Find the address range
	cmp #$20		     ; On the nes, below $2000, it is CHR data
	bcc CHRdata          ; A < #$20
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
CHRdata:
;; -------------------------------------------------------------------------
	; CHR data on the other bus can be read using the PPU port.
	rep #$20 ; A 16bits
	lda #emptyW ; This is assumed to be a ROM
	sta PPUW_RAM_routineAddr
	lda #CHRDataR
	sta PPUR_RAM_routineAddr
	RETW	
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
	;RETW
	;jsr ppuAddToVram
	;; Attributes routines
	rep #$20 ; A 16bits
	lda #AttrtableW
	sta PPUW_RAM_routineAddr
	lda #AttrtableR
	sta PPUR_RAM_routineAddr
	RETW
	
ppuAddToVram:
	sep #$30		; Acc X Y 8bits
	pha
	phy
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
	;
	clc
	adc tmp_addr
	; Store the nametable address
	sta attributeaddr
	sep #$30		; Acc X Y 8bits
	ply
	pla
	rts

;; -------------------------------------------------------------------------
nametables:
	;jsr SetNametableOffset
	;
set_nametables_routines:
	;; Tile map routines
	rep #$20		; A 16bits
	lda #NametableW
	sta PPUW_RAM_routineAddr
	lda #NametableR
	sta PPUR_RAM_routineAddr
	RETW
	
SetNametableOffset:
	pha
	rep #$20		; A 16bits
	lda PPUmemaddrL
	and #$03FF		; Lower address value
	asl             ; word adress
	; The adress is in word count (should be $(3/7)000 to $(3/7)003F)
	sta NameAddresL
	sep #$20		; A 8bits
	pla
	rts
	
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
	
	;BREAK ; break at $0918
	;RETW
	sep #$30		; Acc X Y 8bits
	tay
	; First save the value for the next read in the table
	lda PPUmemaddrL
	sec
	sbc #$C0
	and #$3F        ; Protect against overflow
	tax
	lda PPUmemaddrH
	and #$04 ; Look at bit 2 for BANK 1 or 2
	beq AttBank1W
AttBank2W:
	tya
	sta Attributebuffer2,X
	jsr ppuAddToVram
	rep #$10        ; X Y are 16bits
	tya
	asl A			; Attibute palette are at bits 2 3 4 on snes, so shift the data.
	asl A
	and #$0C		; 00
	ldx attributeaddr
	sta NametableBaseBank2+1,X    ; Store the value in the ram buffer
	sta NametableBaseBank2+3,X
	sta NametableBaseBank2+65,X   ; the line below
	sta NametableBaseBank2+67,X
	tya
	and #$0C		; 11
	sta NametableBaseBank2+5,X    ; Store the value in the ram buffer
	sta NametableBaseBank2+7,X
	sta NametableBaseBank2+69,X
	sta NametableBaseBank2+71,X
	;; Lower 2 x 4 tiles
	tya
	lsr A
	lsr A
	and #$0C		; 22
	sta NametableBaseBank2+129,X  ; Store the value in the ram buffer
	sta NametableBaseBank2+131,X
	sta NametableBaseBank2+193,X
	sta NametableBaseBank2+195,X
	;
	tya
	lsr A
	lsr A
	lsr A
	lsr A
	and #$0C		; 33
	sta NametableBaseBank2+133,X  ; Store the value in the ram buffer
	sta NametableBaseBank2+135,X
	sta NametableBaseBank2+197,X
	sta NametableBaseBank2+199,X
	jsr IncPPUmemaddrL
	RETW
	
AttBank1W:
	tya
	sta Attributebuffer1,X
	; Translate the address
	;lda AttrAddressTranslation,X ; Could be quicker with a 2*128byte table in wram
	;tax
	;sta attributeaddr
	;tya
	jsr ppuAddToVram
	
	; 33|22|11|00
	; Copy the values in the name tables
	rep #$10        ; X Y are 16bits
	tya
	asl A			; Attibute palette are at bits 2 3 4 on snes, so shift the data.
	asl A
	and #$0C		; 00
	ldx attributeaddr
	sta NametableBaseBank1+1,X    ; Store the value in the ram buffer
	sta NametableBaseBank1+3,X
	sta NametableBaseBank1+65,X   ; the line below
	sta NametableBaseBank1+67,X
	tya
	and #$0C		; 11
	sta NametableBaseBank1+5,X    ; Store the value in the ram buffer
	sta NametableBaseBank1+7,X
	sta NametableBaseBank1+69,X
	sta NametableBaseBank1+71,X
	;; Lower 2 x 4 tiles
	tya
	;clc
	lsr A
	lsr A
	and #$0C		; 22
	sta NametableBaseBank1+129,X  ; Store the value in the ram buffer
	sta NametableBaseBank1+131,X
	sta NametableBaseBank1+193,X
	sta NametableBaseBank1+195,X
	;
	tya
	;clc
	lsr A
	lsr A
	lsr A
	lsr A
	and #$0C		; 33
	sta NametableBaseBank1+133,X  ; Store the value in the ram buffer
	sta NametableBaseBank1+135,X
	sta NametableBaseBank1+197,X
	sta NametableBaseBank1+199,X
	;; Add the updated tile data to the tiles to be updated by dma

	;; Increment the Attribute address
	jsr IncPPUmemaddrL
	;rep #$20		; Acc 16bits
	;lda attributeaddr
	;clc
	;adc #$0008
	;sta attributeaddr
	;and #$003F		; addr % 64 = 0?
	;beq add256		; If 0 then it is on the begining of the line
	;; Done
	RETW
;add256:
	;lda attributeaddr
	;clc
	;adc #$0100
	;sta attributeaddr
	;; Done
	;RETW

	;; -------------------------------------------------------------------------
	;; Name tables
NametableW:
	sep #$20		; A 8bit
	rep #$10        ; X Y are 16bits
	;BREAK
	; Store the byte

	jsr SetNametableOffset
	ldx NameAddresL
	pha
	lda PPUmemaddrH
	and #$04 ; Look at bit 2 for BANK 1 or 2
	beq NameBank1W
	pla
	cmp NametableBaseBank2,X
	beq NoMoreUpdates  ; Same value, do nothing
	sta NametableBaseBank2,X
	;BREAK
	;jsr UpdateNametablesBitsBank2
	jmp NoMoreUpdates
NameBank1W:
	pla
	sta NametableBaseBank1,X   ; Write to VRAM. This is the lower nametable byte, the character code number.
	;BREAK
	;jsr UpdateNametablesBitsBank1
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
	jsr IncPPUmemaddrL
	RETW

	; Enable the update of the column
UpdateNametablesBitsBank2:
	sep #$30		; All 8bit
	txa
	; Find the column
	and #$3F
	lsr ; A/2
	pha
	and $07 ; Get the bit value
	tax
	pla
	; Find the byte
	lsr
	lsr
	lsr
	; Set the bit
	tay
	lda ColumnUpdateFlags + 4,Y
	ora UpdateFlags,X
	sta ColumnUpdateFlags + 4,Y
	rts

UpdateNametablesBitsBank1:
	sep #$30		; All 8bit
	txa
	; Find the column
	and #$3F
	lsr ; A/2
	pha
	and $07 ; Get the bit value
	tax
	pla
	; Find the byte
	lsr
	lsr
	lsr
	; Set the bit
	tay
	lda ColumnUpdateFlags,Y
	ora UpdateFlags,X
	sta ColumnUpdateFlags,Y
	rts

	;; ---------------------------------------------------------------
	;; nes palette address: write in cg ram
	;; Converts the nes color to snes BGR 555
	;; Depending on the address it writes at BG0 palete or sprite palette
paletteW:
	tax
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	; CG ram address to (PPUmemaddr - $3F00), in fact ommit the $3F
	lda PPUmemaddrL
	; Save the byte in sram for the next read and for CGRAM transfer during VBlank
	and #$1F
	tay
	txa
	sta Palettebuffer,Y
	; Test for index 0 mirroring
	lda PPUmemaddrL
	and #$1F
	cmp #$10  ; using $3FC0 as a mirror port makes the screen black in SMB1, it must be a masked color... http://wiki.nesdev.com/w/index.php/PPU_palettes
	beq UpdateAllMirrorColors
	; Indicate a change in this palette
	tya
	lsr A
	lsr A
	tay
	lda UpdateFlags,Y  ; Set the palette bit to one
	ora UpdatePalette
	sta UpdatePalette
	; Adr
endwpumem:
	;; Increments the index equally as CGDATA
	jsr IncPPUmemaddrL
	;; Test for address oveflow
	rep #$20		; 16bit A
	lda PPUmemaddrL
	cmp #$3F20
	beq changewrfunction
	RETW
changewrfunction:
	jmp emptyrange

	; The first palette index is mirrored on every palette
UpdateAllMirrorColors:
	sep #$30
	txa
	sta Palettebuffer
	sta Palettebuffer + 4
	sta Palettebuffer + 8
	sta Palettebuffer + 12
	sta Palettebuffer + 16
	sta Palettebuffer + 20
	sta Palettebuffer + 24
	sta Palettebuffer + 28
	lda #$FF
	sta UpdatePalette
	jmp	endwpumem

	
;----------------------------------------------------------------------
; 
RPPUMEMDATA:
	jmp (PPUR_RAM_routineAddr)   ; Indirect jump to the routine for the address.

AttrtableR:
	; Read it from the sram buffer
	sep #$30		; All 8bit
	lda PPUReadLatch
	bne LatchedAttrValue
	lda PPUmemaddrL
	sec
	sbc #$C0
	and #$3F
	tax
	lda PPUmemaddrH
	and #$04 ; Look at bit 2 for BANK 1 or 2
	beq AttBank1R
AttBank2R:
	lda Attributebuffer2,X
	jsr IncPPUmemaddrL
	jmp AttrtableRend
AttBank1R:
	lda Attributebuffer1,X
	jsr IncPPUmemaddrL
	jmp AttrtableRend
LatchedAttrValue:
	lda #$00  ; Return zero at the first read after the write to $2006
	sta PPUReadLatch
AttrtableRend:
	RETR

NametableR:
	; Read it from the sram buffer
	sep #$20		; A 8bit
	rep #$10        ; X Y are 16bits
	lda PPUReadLatch
	bne LatchedNameValue
	; Store the byte
	jsr SetNametableOffset
	ldx NameAddresL
	; Bank selection
	lda PPUmemaddrH
	and #$04 ; Look at bit 2 for BANK 1 or 2
	beq NameBank1R
NameBank2R:
	lda NametableBaseBank2,X
	jmp NameBankREnd
NameBank1R:
	lda NametableBaseBank1,X
NameBankREnd:	
	tax
	; Increment the PPU address
	jsr IncPPUmemaddrL
	; Done
	sep #$20		; A 8bit
	txa
	jmp NametableRend
LatchedNameValue:
	lda #$00  ; Return zero at the first read after the write to $2006, a ccorect read is mandatory to emulate balloonficght.nes background stars.
	sta PPUReadLatch
NametableRend:
	RETR

paletteR:
	; Read it from the CG buffer in sram
	sep #$30		; All 8bit
	lda PPUmemaddrL
	and #$1F
	tax
	lda Palettebuffer,X
	jsr IncPPUmemaddrL
	RETR

CHRDataR:
	BREAK
	sep #$30		; All 8bit
	lda PPUReadLatch
	bne LatchedCHRDataValue
	sep #$20		; mem/A = 8 bit
	; Change the bank to the CHR bank on the ROM
	phb
	lda #:NESCHR	; Bank of the CHR data
	pha
	plb			    ; Data Bank Register = A
	rep #$10		; X/Y = 16 bit
	ldx PPUmemaddrL ; Load the PPU bus address between $0000 and $2000
	lda NESCHR.w,X  ; Load the value
	plb			; Restore data bank	
	tax
	; Increment the PPU address
	jsr IncPPUmemaddrL
	txa
	jmp CHRDataRend
LatchedCHRDataValue:
	lda #$00  ; Return zero at the first read after the write to $2006
	sta PPUReadLatch
CHRDataRend:
	RETR


;----------------------------------------------------------
; Increments the adress register
IncPPUmemaddrL:
	sep #$20		; A 8bits
	; Test bit 2 of PPUCTRL: 1 or 32 nametable increment
	lda #$04
	bit PPUcontrolreg1	; test bit 2, zero if not set ("bit and" result)
	bne name_incr_32
	; +1
	rep #$30		; All 16bits
	lda PPUmemaddrL
	;tax
	clc
	adc #$0001
	sta PPUmemaddrL
	; If only the lower bits changed, do nothing with the routines
	;txa
	;and #$FFC0
	;sta tmp_addr
	;lda PPUmemaddrL
	;and #$FFC0
	;cmp tmp_addr
	;beq IncPPUmemaddrEnd
	jmp IncPPUmemaddrLEnds
name_incr_32:
	; +32
	; Vram increments 32 by 32 after VMDATAL write (words on the snes)
	rep #$20		; A 16bits
	;lda NameAddresL
	;clc
	;adc #$0040
	;sta NameAddresL
	; Other than nametables
	lda PPUmemaddrL
	clc
	adc #$0020
	sta PPUmemaddrL
IncPPUmemaddrLEnds:
	; Check if the adress is greater or equal to $2000
	cmp #$2000
	bcc CHRSpace
	; Check if the adress is greater or equal to $23C0 in order to set the proper routines.
	and #$F3FF      ; Get an @ in all the banks: $2000 $2400 $2800 $2C00
	cmp #$23C0
	bcc NametableSpace
	;cmp $3F00
	cmp #$3000
	bcs PaletteSpace
	; Change the address to attribute tables
	lda #AttrtableW
	sta PPUW_RAM_routineAddr
	lda #AttrtableR
	sta PPUR_RAM_routineAddr
	jmp IncPPUmemaddrEnd
CHRSpace:
	lda #emptyW ; This is assumed to be a ROM
	sta PPUW_RAM_routineAddr
	lda #CHRDataR
	sta PPUR_RAM_routineAddr
	jmp IncPPUmemaddrEnd
NametableSpace:
	lda #NametableW
	sta PPUW_RAM_routineAddr
	lda #NametableR
	sta PPUR_RAM_routineAddr
	jmp IncPPUmemaddrEnd
PaletteSpace:
IncPPUmemaddrEnd:
	sep #$30		; All 8bit
	rts
	
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
