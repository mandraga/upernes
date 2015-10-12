
.include "snesregisters.inc"

.BANK 0
.ORG 0
.SECTION "CHR"

NesBackgroundCHRtoVram:
	;; -----------------------------------------------------
	; Copy nes CHR data to VRAM. See memap.txt
	rep #$30		; All 16bit
	rep #$10		; X/Y = 16 bit
	sep #$20		; mem/A = 8 bit
	phb
	lda #:NESCHR		; Bank of the CHR data
	pha
	plb			; Data Bank Register = A
	; Vram increments 1 by 1 after VMDATAH write
	lda #$80
	sta VMAINC
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $2000 (= $4000 bytes)
	lda #$20
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; Second 4k (nes chr bank 1 @ $1000 in nes ppu address space)
	; --------------------------
	ldx #$1000		; Offset in CHR data
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $3000 (= $6000 bytes)
	lda #$30
	sta VMADDH
	jsr copyBGchr	
	
	; --------------------------
	plb			; Restore data bank
	; Set BG1 char data address to nes CHR first bank : snes VRAM $2000W -> 2nd 4KW Segment
	lda #$02		; 0x0002 -> second 4kWord segment = 8kB@
	sta BG12NBA		; CHR data in VRAM starts at 0x6000
	rts

	;; Copy NES CHR to SNES BG VRAM routine
copyBGchr:
tileloop:
	phy
	ldy #$0007
charloop:
	lda NESCHR.w,X
	sta VMDATAL
	lda NESCHR.w + 8,X
	sta VMDATAH
	inx
	dey
	bpl charloop
	rep #$20		; mem/A = 16 bit
	txa
	clc
	adc #$0008
	tax
	sep #$20		; mem/A = 8 bit
	;; Tile count
	ply
	dey
	bne tileloop     	; > 0 then branch
	rts

;; --------------------------------------------------------------------------
/*
NesSpriteCHRtoVram:
	;; -----------------------------------------------------
	; Copy nes CHR to VRAM for sprites. Needs another function
	; because on the snes sprites are 4bits per pixel instead
	; of 2.
	; Same copy but a group of 16bytes is set to 0 between 2
	; tiles (color bits 2 and 3 set to 0).
	rep #$30		; All 16bit
	rep #$10		; X/Y = 16 bit
	sep #$20		; mem/A = 8 bit
	phb
	lda #:NESCHR		; Bank of the CHR data
	pha
	plb			; A -> Data Bank Register
	; Vram increments 1 by 1 after VMDATAH write
	lda #$80
	sta VMAINC
	; --------------------------
	; First 4k -> $0000 4kW
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address
	lda #$00
	sta VMADDH
	jsr copySPRchr
	; --------------------------
	; Second 4k -> $4000 4kW
	; (nes chr bank 1 @ $1000 in nes ppu address space)
	; --------------------------
	;ldx #$1000		; Offset in CHR data
	;ldy #$0100		; 256 8x8 tiles
	;lda #$00
	;sta VMADDL		; Word address
	;lda #$20
	;sta VMADDH
	;jsr copySPRchr
	; --------------------------
	plb			; Restore data bank
	rts

copySPRchr:
Stileloop:
	phy
	ldy #$0007
Scharloop:
	lda NESCHR.w,X
	sta VMDATAL
	lda NESCHR.w + 8,X
	sta VMDATAH
	inx
	dey
	bpl Scharloop
	;; next 16bytes set to 0 in Vram
	ldy #$0007
clr16loop:
	stz VMDATAL
	stz VMDATAH
	dey
	bpl clr16loop
	rep #$20		; mem/A = 16 bit
	txa
	clc
	adc #$0008
	tax
	sep #$20		; mem/A = 8 bit
	;; Tile count
	ply
	dey
	bne Stileloop		; > 0 then branch
	rts
*/
;; --------------------------------------------------------------------------

	;; Y is the nes Rom bank number
	;; Acc is the destination bank number in WRAM $7F segment of 128KB (8KB to 56KB used, 7 sprite conversion banks)
NesSpriteCHRtoWram:
	;; -----------------------------------------------------
	; Copies a nes CHR bank to WRAM for sprite use on the snes.
	; Needs another function because on the snes sprites are
	; 4bits per pixel instead of 2.
	; Same copy as BG data but a group of 16bytes is set to
	; 0 between 2 tiles (color bits 2 and 3 set to 0).
	; The data will be copied later via a DMA transfer.
	;; -----------------------------------------------------
	; Set the WRAM address register
	sep #$20		; mem/A = 8 bit
	stz WMADDL              ; @ lower byte to 0
	clc
	adc #$01                ; Starts at 8K, therefore add 1 to the segment index
	clc
	asl                     ; the segment number is shifted to a multiple of 8K, to the bit 13 of the address
	asl
	asl
	asl
	asl
	sta WMADDM
	stz WMADDH              ; Do not access past 64K
	; Set the CHR bank address from #$1000 or #$0000
	tya
	cmp #$00
	rep #$10		; X/Y = 16 bit, does not affect the z flag
	beq firstbank
	; Second bank
	ldx #$1000              ; Sets X to the bank address $1000
	jmp databanktoCHR
firstbank:
	ldx #$0000              ; Sets X to the bank address $0000
databanktoCHR:
	phb
	lda #:NESCHR		; Bank of the CHR data
	pha
	plb			; A -> Data Bank Register
	; WRAM address increments by 1 after each write
	; --------------------------
	; First nes 4kB -> snes 4kW
	; --------------------------
	ldy #$0100		; 256 8x8 tiles
	jsr copySPRchrWRAM
	; --------------------------
	plb			; Restore data bank
	rts

copySPRchrWRAM:
StileloopWR:
	sep #$20		; mem/A = 8 bit
	rep #$10		; X/Y = 16 bit, does not affect the z flag
	phy
	ldy #$0007
ScharloopWR:
	lda NESCHR.w,X
	sta WMDATA
	lda NESCHR.w + 8,X
	sta WMDATA
	inx
	dey
	bpl ScharloopWR
	;; next 16bytes set to 0 in wram
	ldy #$0007
clr16loopWR:
	stz WMDATA
	stz WMDATA
	dey
	bpl clr16loopWR
	rep #$20		; mem/A = 16 bit
	txa
	clc
	adc #$0008
	tax
	sep #$20		; mem/A = 8 bit
	;; Tile count
	ply
	dey
	bne StileloopWR		; > 0 then branch
	rts

/*
WRAMtoVRAM:
	sep #$20		; mem/A = 8 bit
	stz VMADDL		; Word address
	stz VMADDH
	stz WMADDL              ; @ lower byte to 0
	lda #$20
	sta WMADDM
	stz WMADDH              ; Do not access past 64K
	rep #$10  		; X Y 16bits
	ldx #$1000             	; 4KW
wvramloop:
	lda WMDATA
	sta VMDATAL
	lda WMDATA
	sta VMDATAH
	dex
	bne wvramloop
	sep #$30
	rts
*/

.ENDS
