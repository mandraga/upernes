
.include "snesregisters.inc"

.BANK 0
.ORG 0
.SECTION "CHR"

NesBackgroundCHRtoVram:
	;; -----------------------------------------------------
	; Copy nes CHR to VRAM
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
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$10
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; Second 4k (nes chr bank 1 @ $1000 in nes ppu address space)
	; --------------------------
	ldx #$1000		; Offset in CHR data
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $3000 = $6000 bytes
	lda #$30
	sta VMADDH
	jsr copyBGchr


	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$00
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$08
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$20
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$28
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$38
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$40
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$48
	sta VMADDH
	jsr copyBGchr

	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$50
	sta VMADDH
	jsr copyBGchr
	; --------------------------
	; First 4k
	; --------------------------
	ldx #$0000
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address $1000 (= $2000 bytes)
	lda #$58
	sta VMADDH
	jsr copyBGchr
	
	
	; --------------------------
	plb			; Restore data bank
	; Set BG1 char data address to nes CHR second bank : snes VRAM $6000 -> 3rd 4KW Segment
	lda #$03		; 0x0003 -> third 4kWord=8k segment
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
	ldx #$1000		; Offset in CHR data
	ldy #$0100		; 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address
	lda #$20
	sta VMADDH
	jsr copySPRchr
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

.ENDS
