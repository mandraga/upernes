
.include "registers.asm"
.include "lorom.asm"
.include "zeromem.asm"
.include "LoadGraphics.asm"

.BANK 0
.ORG 0
.SECTION "Reset"

Reset:
	sei			; disable interrupts
	clc			; native mode
	xce

	rep #$38		; all regs 16 bits, decimal mode off

	; Direct page $00
	lda #$0000
	tcd
	; Data bank at $00


	; Stack pointer initial value
	ldx #$001F
	txs

	; Clear memory
	jsr ClearRegisters
	jsr ClearVRAM
	jsr ClearCGRam

	; Video mode settings
	;; -----------------------------------------------
	sep #$30		; All 8bit
	; Sprites: Object size is 8x8 or 16x16. Obj area at VRAM $0000
	;lda #$00
	;sta OBSEL
	; Mode 0 background
	lda #$00
	sta BGMODE

	;; -----------------------------------------------------
	; Copy nes CHR to VRAM
	rep #$30		; All 16bit
        ;LoadBlockToVRAM NESCHR, $0000, $2000  ; 2x256 8x8tiles*(2bit color)=8k
	rep #$10		; X/Y = 16 bit
	sep #$20		; mem/A = 8 bit
	phb
	lda #:NESCHR		; Bank of the CHR data
	pha
	plb			; A -> Datat Bank Register
	ldx #$0000
	ldy #$0200		; 2 x 256 8x8 tiles
	lda #$00
	sta VMADDL		; Word address
	lda #$00
	sta VMADDH
	; Vram increments 1 by 1 after VMDATAH write
	lda #$80
	sta VMAINC
tileloop:
	phy
	ldy #$0007
charloop:
;	lda NESCHR,X		; BUG!!!
	lda $8000,X
	sta VMDATAL
;	lda NESCHR + 0008,X	; BUG!!!
	lda $8008,X
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
	bpl tileloop
	plb			; Restore data bank
	; Set BG1 char data address to nes CHR second bank
	lda #$00		; 0x0000 -> first 4kWord=8k segment
	sta BG12NBA		; CHR data in VRAM starts at 0x0000

	;; -----------------------------------------------------
	; Create tile map for BG1
tile:
	rep #$10		; X/Y = 16 bit
	sep #$20		; mem/A = 8 bit
	; Vram increments 1 by 1 after VMDATAH write
	lda #$80
	sta VMAINC
	; Tiles are at $2000
	lda #$00
	sta VMADDL		; Word address
	lda #$10
	sta VMADDH
	lda #$24		; Tile number
	ldy #$01		; nes equivalent sprite bank
	ldx #$0400		; Total number of tiles 32x32
quarth:
	sta VMDATAL		; Flip tile & palette selection: 0
	sty VMDATAH		; tile number
	dex
	bne quarth
	; 16, 15 <- tile
	lda #$CE
	sta VMADDL
	lda #$11
	sta VMADDH
	lda #$A0
	sta VMDATAL
	sty VMDATAH
	sta VMDATAL
	sty VMDATAH
	sta VMDATAL
	sty VMDATAH
	sta VMDATAL
	sty VMDATAH
	; Set tile map address (Addr >> 10) << 2
	lda #$10		; (1k word segment $2000 / $800)=$04 << 2
	sta BG1SC
	;; -----------------------------------------------------
	; Load palete
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	; CG ram address to 0
	lda #$00
	sta CGADD
	ldx #$00
	phb
	lda #:BGpalette		; Bank of the palette
	pha
	plb			; A -> Datat Bank Register
palconv:
	lda $A000,X
 	;lda.b BGpalette.w,X	;  BUG!!!!
	lda $A000,X
	asl			; word index
	tay
	lda nes2snespalette,Y
	; Send it to CG ram
	sta CGDATA
	iny
	lda nes2snespalette,Y
	sta CGDATA
	inx
	txa
	cmp #$20
	bne palconv
	plb

	;; -----------------------------------------------------
	; Enable display
	lda #$01	          ;Turn on BG1
        sta TM
	lda #$0F		  ;Turn on screen, 100% brightness
	sta INIDISP

Inifiniteloop:
	jmp Inifiniteloop
.ENDS
