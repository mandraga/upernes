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
.include "mapper.inc"

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
; 8
;; Sound registers
.DW	WSNDSQR1CTRL		; $4000
.DW	WSNDSQR1E
.DW	WSNDSQR1PERIOD
.DW	WSNDSQR1LENPH
.DW	WSNDSQR2CTRL		; $4004
.DW	WSNDSQR2E
.DW	WSNDSQR2PERIOD
.DW	WSNDSQR2LENPH
; 16
.DW	WSNDTRIACTRL		; $4008
.DW     $0000
.DW	WSNDTRIAPERIOD		; $400A
.DW	WSNDTRIALENPH		; $400B
.DW	WSNDNOISECTRL		; $400C
.DW     $0000
.DW	WSNDNOISESHM		; $400E
.DW	WSNDNOISELEN		; $400F
; 24
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
; 32

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
;       |   7 | Enable VBlank as NMI irq trigger, 1 = generate interrupts on VBlank.

WPPUC1:
	sep #$30		    ; All 8 bit
	;cmp PPUcontrolreg1 	; Anything changed?
	;bne testPPUCtrl1Chg
	;jmp vblankend
	sta tmpPPUcontrolreg1
	;sta PPUcontrolreg1   ; Save the written value
;testPPUCtrl1Chg:
;	tax
	; If the lower bit changed, then change the screen hscrolling
	;eor PPUcontrolreg1
	;and #$01
	; Also check the bits in Th
	;lda tH
	;lsr
	;lsr
	;eor PPUcontrolreg1
	;beq NoScrollChange
	;----------------------------------------------------------
	; Set the TMP VRAM registers
	lda tH
	sta tmpV
	and #$F3  ; Clear the 2 bits
	sta tH
	lda tmpPPUcontrolreg1
	and #$03  ; 2 first bits
	asl
	asl
	ora tH
	sta tH
	cmp tmpV
	beq NoScrollChange
	;----------------------------------------------------------
;	txa
;	sta PPUcontrolreg1   ; Save the written value
	;----------------------------------------------------------
	; Update the scroll register bit 8
	jsr UpdateHScroll
	;
NoScrollChange:
;	txa

	;; ------------------------------------------
	;; Test Nametable @ bits
	;; Mirroring is the default value. FIXME add cartridge nametables?
	;and #$01
	;beq firstnametableaddress  ; If zero flag then it it the first nametable
    ;lda #$04            ; (1k word segment $0400)
	;ora #$01	         ; Right screen following the first one
    ;sta BG1SC
	;jmp endnametableaddress
firstnametableaddress:
	; Always on bank 0 and add this bit to the scrolling ergister
    lda #$00             ; (1k word segment $0000)
	ora #$01             ; Right screen following the first one
    sta BG1SC
endnametableaddress:
	;; ------------------------------------------
	lda tmpPPUcontrolreg1
	eor PPUcontrolreg1
	and #$08
	beq Spritebankend   ; Jump over if nothing changed
	;; ------------------------------------------
	;; Sprite pattern table address
	lda #$08
	bit tmpPPUcontrolreg1	; test bit 3 (#$08), zero if not set ("bit and" result)
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
	lda tmpPPUcontrolreg1
	sta PPUcontrolreg1
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

	;; Test Vblank
	;bit PPUcontrolreg1
	;bpl novblank		; Therefore bpl branches if the 7th bit is not set
	sep #$10            ;  Acc 8Bits
	lda PPUcontrolreg1  ; Puts the 7th bit in the n flag
	and #$80
	beq novblank
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
	and #$7E      ; Could be $7F but we do not need auto joystick update
	sta NMITIMEN
	sta SNESNMITMP
vblankend:
	;; ------------------------------------------
	; Test bit 2 of PPUCTRL: 1 or 32 nametable increment
	lda #$04
	bit PPUcontrolreg1	; test bit 2, zero if not set ("bit and" result)
	bne name_incr_32
	; +1
	rep #$20		; A 16bits
	lda #$0001
	sta PPURW_IncrementL
	jmp PPUIncEnds
name_incr_32:
	; +32
	; Vram increments 32 by 32 after VMDATAL write (words on the snes)
	rep #$20		; A 16bits
	lda #$0020
	sta PPURW_IncrementL
PPUIncEnds:	
	sep #$20		; A 8bits
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
	;BREAK
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
	sta TM			; Sprite enable (also bit 4)	
	; BG1 enabled?
	lda PPUcontrolreg2
	and #$08                ; Keep only the 3rd bit
	beq blankscreen
	lda #$0F		  ;Turn on screen, 100% brightness
	sta INIDISP
	; If the screen and sprites are enabled, then sprite 0 hit flag is enabled
	;jsr InitSprite0
	jmp endWPPUC2
blankscreen:
	lda #$80		  ;Turn off screen
	sta INIDISP

endWPPUC2:
	jsr InitSprite0
	RETW

RPPUC2:
	sta PPUcontrolreg2
	RETR

; ------+-----+---------------------------------------------------------------
; $2002 | R   | PPU Status Register
;       | 0-4 | Unknown (???)
;       |   5 | Sprite overflow bit
;       |   6 | Hit Flag, 1 = Sprite refresh has hit sprite #0.
;       |     | This flag resets to 0 when screen refresh starts
;       |     |
;       |   7 | VBlank Flag, 1 = PPU is in VBlank state.
;       |     | This flag resets to 0 when VBlank ends or CPU reads $2002
;       |     |
RPPUSTATUS:
	;BREAK
	sep #$20
	;; Power up test
	lda StarPPUStatus
	bne PowerUp     ; If 1, then it is power up (always here, even on reset)
	; Normal operation
	; The scroll registers latches are cleared by a read to this register
	stz WriteToggle
	lda PPUStatus     ; From the IRQ update	
	;jmp EndRPPUSTATUS
	RETR
PowerUp:
	stz StarPPUStatus ; Boot passed
	lda #$80          ; return boot PPUSTATUS
	sta PPUStatus
EndRPPUSTATUS:
	RETR

;;----------------------------------------
	
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
	tax              ; Should be in rom to use Y on it
	lda WRamSpriteFlagConvLI,X	
	;jsr convert_sprflags_to_snes ; Acc converted from NES vhoxxxpp to SNES vhoopppN
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
;       |     | which are both written via this port. The first value will
;       |     | appear in the Horizontal Scroll Register. The second value written
;       |     | will go into the Vertical Scroll Register (unless it is >239,
;       |     | then it will be ignored). Name Tables are assumed to be
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
	lda WriteToggle
	beq horizontal_scroll   ; 0 horizontal, 1 vertical
vertical_scroll:
	;----------------------------------------------------------
	; Set the TMP VRAM registers
	jmp forg2
	lda tL
	and #$E0
	sta tL
	txa
	and #$03
	sta tX
	txa
	lsr
	lsr
	lsr
	and #$1F
	sta tL
forg2:
	;----------------------------------------------------------
	; Set the Vscroll value but only updated  during vblank
	txa
	sta NESVSCROLL
	cmp #240		; > 239?
	bcs ignorescrollvalue	
	; Update vscroll only during vblank?
	;lda NESVSCROLL
	sta BG1VOFS             ; This register must be written twice
	stz BG1VOFS 		    ; High byte is 0
	jmp chgscrollregister
horizontal_scroll:
	sep #$30		; All 8b
	;----------------------------------------------------------
	; Set the TMP VRAM registers
	jmp forg1
	lda tL
	and #$1F
	sta tL
	txa
	asl
	asl
	and #$E0
	ora tL
	sta tL
	; H byte
	lda tH
	and #$0C
	sta tH
	txa
	ror
	ror
	ror
	and #$E0
	ora tH
	sta tH
	txa
	rol
	rol
	and #$03
	ora tH
	sta tH
forg1:
	;----------------------------------------------------------
	; Change the horisontal scroll values
	stx NESHSCROLL
	jsr UpdateHScroll
ignorescrollvalue:          ; ignore the value but change the register state
chgscrollregister:
	lda WriteToggle
	eor #$01		        ; Change the acessed scroll register
	sta WriteToggle
	RETW
	
SetSCrollRegister:
	rts

UpdateHScroll:
	pha
	stx XsavScroll
	lda tH
	and #$0C
	;BREAK2
	ldx NESHSCROLL
	lda tH                  ; Load the tmp register
	and #$0C
	beq BanlXScroll
	lda #$01
	jmp Ban2XScroll	
BanlXScroll:
	lda #$00
Ban2XScroll:
	stx BG1HOFS		        ; This register must be written twice
	sta BG1HOFS 		    ; High byte's lower bit comes from PPU control 1 lower bit when scrolling horizontally	
	ldx XsavScroll
	pla
	rts

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
	pha
	lda WriteToggle
	bne Relative
	inc WriteToggle
	pla
	sta PPUmemaddrH          ; A copy in ram is called
	RETW
Relative:
	pla
	sta PPUmemaddrL
	pha
	stz WriteToggle
	lda #$01
	sta PPUReadLatch
	lda PPUmemaddrH
	and #$3F
	sta tH
	pla
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
	sep #$20 ; A 8bits
	pha
	; Use the WRAM buffer of PPU@ routines.
	; Go to bank 7F
	rep #$20 ; A 16bits
	lda PPUmemaddrL ; Load the PPUADDRESS
	and #$3FF0 ; Clear the 2 upper and lower bits
	lsr
	lsr ; >> 2
	tax
	lda WRamPPUADDRJmpsLI, X
	sta tmp_addr
	sep #$20 ; A 8bits
	pla
	jmp (tmp_addr)   ; indirect jump to the routine for the PPU address.

.MACRO INCPPUADDR
	rep #$20		; A 16bits
	lda PPUmemaddrL
	clc
	adc PPURW_IncrementL
	sta PPUmemaddrL
	sep #$20		; A 8bit
.ENDM
	
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
	;--- Attr storage
	asl A			; Attibute palette are at bits 2 3 4 on snes, so shift the data.
	asl A
	and #$0C		; 00
	sta ATTRV + 0
	tya
	and #$0C		; 11
	sta ATTRV + 1
	tya
	lsr A
	lsr A
	and #$0C		; 22
	sta ATTRV + 2
	tya
	lsr A
	lsr A
	lsr A
	lsr A
	and #$0C		; 33
	sta ATTRV + 3
	;
	; First save the value for the next read in the table
	lda PPUmemaddrL
	sec
	sbc #$C0
	and #$3F        ; Protect against overflow
	tax
	lda PPUmemaddrH
	and #$04 ; Look at bit 2 for BANK 1 or 2
	bne AttBank2W
	jmp AttBank1W
AttBank2W:
	tya
	sta Attributebuffer2,X
		
	jsr ppuAddToVram
	rep #$10        ; X Y are 16bits
	ldx attributeaddr

	;--- @
	lda #$80
	sta VMAINC      ; increment on VMDATAH
	rep #$20		; A 16bits
	txa
	lsr
	clc
	adc #$0400
VramATTRLoad:
	BREAK2
	tax
	stx VMADDL
	adc #96
	pha
	sec
	sbc #32
	pha
	sec
	sbc #32
	pha
	;--- Data Line 0
	sep #$20		; A 8bits
	lda ATTRV + 0 
	sta VMDATAH
	sta VMDATAH
	lda ATTRV + 1
	sta VMDATAH
	sta VMDATAH
	;--- Data Line 1
	plx
	stx VMADDL
	lda ATTRV + 0 
	sta VMDATAH
	sta VMDATAH
	lda ATTRV + 1
	sta VMDATAH
	sta VMDATAH
	;--- Data Line 2
	plx
	stx VMADDL
	lda ATTRV + 2
	sta VMDATAH
	sta VMDATAH
	lda ATTRV + 3
	sta VMDATAH
	sta VMDATAH
	;--- Data Line 3
	plx
	stx VMADDL
	lda ATTRV + 2
	sta VMDATAH
	sta VMDATAH
	lda ATTRV + 3
	sta VMDATAH
	sta VMDATAH	

	INCPPUADDR ; jsr IncPPUmemaddrL
	RETW
	
AttBank1W:
	tya
	sta Attributebuffer1,X

	; Translate the address
	;lda AttrAddressTranslation,X ; Could be quicker with a 2*128byte table in wram
	jsr ppuAddToVram
	
	; 33|22|11|00
	; Copy the values in the name tables
	rep #$10        ; X Y are 16bits
	ldx attributeaddr

	;--- @
	lda #$80
	sta VMAINC      ; increment on VMDATAH
	rep #$20		; A 16bits
	txa
	lsr
	;clc
	;adc #$7000
	jmp VramATTRLoad

	;; -------------------------------------------------------------------------
	;; Name tables
NametableW:
	;RETW
	sep #$20		; A 8bits
	;; -----------------------------------
	; Store the byte
	;; -----------------------------------
	tay
	rep #$30		; A X Y 16bits
	lda PPUmemaddrL
	and #$07FF		; Lower address value
	; The adress is in word count (should be $(3/7)000 to $(3/7)003F)
	tax
	sep #$20		; A 8bits
	tya
	;; -----------------------------------
	sta NametableBaseBank1,X   ; Write to VRAM. This is the lower nametable byte, the character code number.
	; Update directly in vram
	stz VMAINC      ; VRAM Increment on the lower byte
	stx VMADDL
	sep #$30		; All 8bit
	sty VMDATAL

NoMoreUpdates:
	; Increment
	INCPPUADDR ; jsr IncPPUmemaddrL
nextWr:
	RETW


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
	INCPPUADDR ; jsr IncPPUmemaddrL
	RETW

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
	sep #$20 ; A 8bits
	pha
	; Use the WRAM buffer of PPU@ routines.
	; Go to bank 7F
	rep #$20 ; A 16bits
	lda PPUmemaddrL ; Load the PPUADDRESS
	and #$3FF0 ; Clear the 2 upper and lower bits
	lsr
	lsr ; >> 2
	tax
	lda WRamPPUADDRJmpsLI + 2, X
	sta tmp_addr
	sep #$20 ; A 8bits
	pla
	jmp (tmp_addr)   ; indirect jump to the routine for the PPU address.


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
	INCPPUADDR ; jsr IncPPUmemaddrL
	jmp AttrtableRend
AttBank1R:
	lda Attributebuffer1,X
	INCPPUADDR ; jsr IncPPUmemaddrL
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
	rep #$20		; A 16bits
	lda PPUmemaddrL
	and #$07FF		; Lower address value
	;asl             ; word adress
	; The adress is in word count (should be $(3/7)000 to $(3/7)003F)
	tax
	sep #$20		; A 8bits

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
	INCPPUADDR ; jsr IncPPUmemaddrL
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
	INCPPUADDR ; jsr IncPPUmemaddrL
	RETR

CHRDataR:
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
	INCPPUADDR ; jsr IncPPUmemaddrL
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
	rep #$20		; A 16bits
	lda PPUmemaddrL
	clc
	adc PPURW_IncrementL
	sta PPUmemaddrL
	sep #$20		; A 8bit
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
	; This conversion could be made in the Sound IRQ on line 150, it takes 16 lines.

	;;------------------------------------------------------------------------------
	;; First convert the 256 bytes of the memory area to 256bytes of snes oam data
	;
	; Simple copy for the bytes 1 and 2
testit:
	rep #$30    ; All 16b
	and #$0000  ;  X = 0
	tax
EzSprconversionloop:	
	lda $00,X	  ; Read Y, direct page  *(DP + $00 + X) and tile index
	sta SpriteMemoryBase + 1,X    ; Store it
	lda $00 + 4,X	  ; Read Y, and tile index
	sta SpriteMemoryBase + 5,X    ; Store it
	lda $00 + 8,X	  ; Read Y, and tile index
	sta SpriteMemoryBase + 9,X    ; Store it
	lda $00 + 12,X	  ; Read Y, and tile index
	sta SpriteMemoryBase + 13,X    ; Store it
	lda $00 + 16,X	  
	sta SpriteMemoryBase + 17,X    ; Store it
	lda $00 + 20,X	  
	sta SpriteMemoryBase + 21,X    ; Store it
	lda $00 + 24,X	  
	sta SpriteMemoryBase + 25,X    ; Store it
	lda $00 + 28,X	  
	sta SpriteMemoryBase + 29,X    ; Store it
	; Increment
	txa
	clc
	adc #32
	and #$00FF
	tax
	bne EzSprconversionloop	; loop if not zero	(passed 256)

	; Conversion
	sep #$30    ; All 8b
	;;;;ldy SpriteMemoryAddress ; Origin of the data OAMADDR not in use here 256 bytes
	; It uses a direct page indexed address, meaning it reads from the 256Bytes page with X as index.	
	ldx #$00
sprconversionloope:	
	lda $02,X	  ; Read the flags (direct page indexed)
	txy
	tax              ; Should be in rom to use Y on it
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 3,X    ; Store them
	lda $03,X	  ; Read X
	sta SpriteMemoryBase + 0,X    ; Store it
	;-------------------------------------------------------------
	lda $02 + 4,X	  ; Read the flags (direct page indexed)
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 7,X    ; Store them
	lda $03 + 4,X	  ; Read X
	sta SpriteMemoryBase + 4,X    ; Store it
	;-------------------------------------------------------------
	lda $02 + 8,X	  ; Read the flags (direct page indexed)
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 11,X   ; Store them
	lda $03 + 8,X	  ; Read X
	sta SpriteMemoryBase + 8,X    ; Store it
	;-------------------------------------------------------------
	lda $02 + 12,X	  ; Read the flags (direct page indexed)
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 15,X   ; Store them
	lda $03 + 12,X	  ; Read X
	sta SpriteMemoryBase + 12,X   ; Store it
	;-------------------------------------------------------------
	; Increment
	txa
	clc
	adc #16
	tax
	beq EndSprconversionloop	; loop if not zero	(passed 256)	
	jmp sprconversionloope
EndSprconversionloop:
	;;------------------------------------------------------------------------------
	;; Then copy the 256 bytes into the OAM memory
	sep #$20	; A 8b
	lda #$01
	sta UpdateSprites
;wait_for_vblank:
;    lda HVBJOY              ;check the vblank flag
;    bpl wait_for_vblank
;    jsr UpdateSpritesDMA	
	pld
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
	sta SNDCHANSW4015
	RETW

RSNDCHANSWITCH:
	lda SNDCHANSW4015
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
