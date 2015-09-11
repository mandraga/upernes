
.include "snesregisters.inc"
.include "lorom.asm"
.include "zeromem.asm"
.include "LoadGraphics.asm"
.include "Strings.asm"

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
	ldx #$01FF
	txs

	; Clear memory
	jsr ClearRegisters
	jsr ClearVRAM
	jsr ClearCGRam
	
	; Clear the 1K text buffer
	jsr textclr

	
	; Video mode settings
	;; -----------------------------------------------
	sep #$30		; All 8bit
	; Mode 0 background
	lda #$00
	sta BGMODE

	;; -----------------------------------------------------
	; Copy nes CHR to VRAM for BG1 at vram $0000
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
	bpl tileloop
	plb			; Restore data bank
	; Set BG1 char data address to nes CHR second bank
	lda #$00		; 0x2000 -> second 4kWord=8k segment
	sta BG12NBA		; CHR data in VRAM starts at 0x2000

	;; -----------------------------------------------------
	; Create tile map for BG1
tile:
	rep #$10		; X/Y = 16 bit
	sep #$20		; mem/A = 8 bit
	; Vram increments 1 by 1 after VMDATAH write
	lda #$80
	sta VMAINC
	; CHR data is at $0000 and is 8k in size ie up to $2000
	; Tile data is at $3000 and is 2k in size
	lda #$00
	sta VMADDL		; Word address
	lda #$18
	sta VMADDH
	lda #$A1		; Tile number
	ldy #$01		; nes equivalent sprite bank because the strawberrie tile is on the second 4K/256 tiles set of the 8kb bank
	ldx #$0400		; Total number of tiles 32x32
quarth:
	sta VMDATAL		; Flip tile & palette selection: 0
	sty VMDATAH		; tile number
	dex
	bne quarth
	; 16, 15 <- tile
	lda #$CE
	sta VMADDL
	lda #$19
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
	lda #$18		; (1k word segment $3000 / $800)=$06 << 2
	sta BG1SC

	;; -----------------------------------------------------
	; Load palete for BG1
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
 	lda BGpalette.w,X
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
	; Load palete for BG3
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	; CG ram address to 40 where the BG3 palete is stored
	lda #$40
	sta CGADD
	ldx #$00
	phb
	lda #:BGpalette		; Bank of the palette
	pha
	plb			; A -> Datat Bank Register
palconv3:
 	lda BGpalette.w,X
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
	bne palconv3
	plb
			
	;; -----------------------------------------------
	; Load the 2KB ASCII table CHR data at VRAM $3800
        ;; -----------------------------------------------
	rep #$10	        ; A/mem=8bit, X/Y=16bit specifically for the print function
	sep #$20

; 	rep #$10		; mem/A = 8 bit
; 	phb
; 	lda #:ASCIITiles	; Bank of the CHR data
; 	pha
; 	plb			; A -> Datat Bank Register
; 	ldx #$0000
; 	ldy #$400		; 128 8x8 tiles, 1024 words
; 	lda #$00
; 	sta VMADDL		; Word address
; 	lda #$1C
; 	sta VMADDH
; 	; Vram increments 1 by 1 after VMDATAH write
; 	lda #$80
; 	sta VMAINC
; charloopBG3:
; 	lda ASCIITiles.w,X
; 	sta VMDATAL
;  	inx
;  	lda ASCIITiles.w,X
;  	sta VMDATAH
; 	inx
; 	dey
; 	bpl charloopBG3
; 	plb			; Restore data bank

	LoadBlockToVRAM ASCIITiles, $1C00, $0800        ;128 tiles * (2bit color = 2 planes) --> 2048 bytes

	;; -----------------------------------------------
	; BG3 CHR address
	; Ascii CHR data is in fact at $3800, this is from tile
	; $C0 to tile $FF ($C0 + 64 = $C0 + $40 = $100)
	lda #$01		; 0x2000 -> second 4kWord=8k segment (512 tiles, the asci table starts at 0x3800: tile 384/0x180
	sta BG34NBA		; CHR data in VRAM starts at 0x0001

	; Tilemap fixed addresses
        ;; -----------------------------------------------
        ; BG3 tilemap (nes name table + attibute tables)
        ; Set tile map address (Addr >> 11) << 2
	; $B000 >> 11 << 2= $58
        lda #$58                ; (1k word segment $B000 / $800)=$16 << 2
        sta BG3SC

	SetCursorPos  1, 1

	;; -----------------------------------------------------
	; Write text on BG3
	rep #$10	        ; A/mem=8bit, X/Y=16bit specifically for the print function
	sep #$20
	LDX #STRlabel_01
	JSR PrintF
	BRA END_STRlabel_01
STRlabel_01:
	.DB "Hello World Hello World!!", 0
END_STRlabel_01:

	PrintString "\n Hello World!!"
	PrintString "\n\n"

	PrintString "Test"

 	jsr textcpy

; 	;-----------------------------------------------------
; 	;Creates a test tile map for BG3
; 	rep #$10		; X/Y = 16 bit
; 	sep #$20		; mem/A = 8 bit
; 	; Vram increments 1 by 1 after VMDATAH write
; 	lda #$80
; 	sta VMAINC
; 	; Tile map is at $B000
; 	lda #$00
; 	sta VMADDL		; Word address (= $B000)
; 	lda #$58
; 	sta VMADDH
; 	; CHR data is at $3800 ($1C00 word @)
; 	lda #$80		; Tile number
; 	ldy #$01		; nes equivalent sprite bank
; 	ldx #$0400		; Total number of tiles 32x32
; quarthBG3:
; 	sta VMDATAL		; Flip tile & palette selection: 0
; 	sty VMDATAH		; tile number
; 	clc
; 	adc #$0001
; 	dex
; 	bne quarthBG3

	;; -----------------------------------------------------
	; Enable display
	rep #$30		;A/Mem=16bits, X/Y=16bits
	lda #%00000101	        ; Turn on BG1 and BG3
        sta TM
	lda #$0F		; Turn on screen, 100% brightness
	sta INIDISP

Inifiniteloop:
	jmp Inifiniteloop
.ENDS
