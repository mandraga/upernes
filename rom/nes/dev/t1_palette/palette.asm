
; iNes header
; 1 16KB prg bank
	.inesprg    1
	.ineschr    1			; 1 8KB  chr bank
	.inesmir    1			; 1 Vertical mirroring
	.inesmap    0		

PPU0      equ  $2000
PPU1      equ  $2001
PPUSTATUS equ  $2002
PPUSCROL  equ  $2005
PPUADDRR  equ  $2006
PPURWR    equ  $2007

PAL_INDEX equ  $0B           	; A byte in ram
REFR_CTR  equ  $0C           	; A byte in ram

ATTR_TABLE_SZ   equ 64
VRAM_NAME_TABLE equ $2000
VRAM_PAL_ADDR   equ $3F00

	.bank 0
	.org $C000

Init:
	cld					; Clear decimal mode flag
	lda PPUSTATUS		; reset a latch?
	lda #%00010000     	; Background patern table address at VRAM $1000
    sta PPU0          	; PPU control 1
    lda #%00011110
    sta PPU1			; PPU control 2 No cliping BG & Sprites visible
	jmp overpal
PaletteData:
	.db $0F,$00,$01,$02, $0F,$03,$04,$05, $0F,$06,$07,$08, $0F,$09,$0A,$0B
	.db $0F,$0C,$0E,$10, $0F,$11,$12,$13, $0F,$14,$15,$16, $0F,$17,$18,$19
	.db $0F,$1A,$1B,$1C, $0F,$1D,$1E,$1F, $0F,$20,$21,$22, $0F,$23,$24,$25
	.db $0F,$26,$27,$28, $0F,$29,$2A,$2B, $0F,$2C,$2D,$2E, $0F,$2F,$30,$31
	.db $0F,$32,$33,$34, $0F,$35,$36,$37, $0F,$38,$39,$3A, $0F,$3B,$3C,$3D

overpal:
	lda #$00
	sta PAL_INDEX 		; set the palete index to 0
	sta REFR_CTR
	jsr PALETE_CHG

	; Start the graphics
	jsr STARTPPU
	jsr waitvblank
	jsr STOPPPU

	; Scrolling to 0
	lda #HIGH(PPUSCROL)
	sta PPUADDRR
	lda #LOW(PPUSCROL)
	sta PPUADDRR
	lda #$00
	sta PPURWR
	sta PPURWR

	jsr WRITE_BG_TILES
	jsr ATTRIBUTE_TILES
	jsr STARTPPU

	lda REFR_CTR
iloop:
	; Bank test
	lda $918
	ldy #$00
	lda #$CC
	sta $0000
	lda #$34
	sta $00CC
	lda #$00
	lda [$00], y
	;
	jsr waitvblank
	inc REFR_CTR
	lda #$40
	cmp REFR_CTR
	bne nochg
	lda #$00
	sta REFR_CTR
	jsr STOPPPU
	jsr PALETE_CHG
	; The attribute table must be rewrittent on palete change.
	jsr ATTRIBUTE_TILES
	jsr STARTPPU
nochg:
	jmp iloop

	; sub routines
	;----------------------------------------------------
STOPPPU:
        lda #%00000110
        sta PPU1
	rts

	;----------------------------------------------------
STARTPPU:	
        lda #%00011110 
        sta PPU1
	rts

	;----------------------------------------------------
waitvblank:
	lda PPUSTATUS
	bpl waitvblank
	rts

	;----------------------------------------------------
ATTRIBUTE_TILES:
	;  Atribute data
	ldy #ATTR_TABLE_SZ
	lda #$23               ; Attribute Table 0 at $23C0
	sta PPUADDRR
	lda #$C0
	sta PPUADDRR
beginattributes:
	lda #$00              	; palete 0 0 0 0
	;lda #$1B              	; palete 0 1 2 3
	sta PPURWR
	dey
	bne beginattributes
	rts

	;----------------------------------------------------
WRITE_BG_TILES:
	; Write the Background tiles
	ldy #$F0		        ; 240 * 4 writes
	lda #HIGH(VRAM_NAME_TABLE)     	; name table in vram at $2000
	sta PPUADDRR
	lda #LOW(VRAM_NAME_TABLE)
	sta PPUADDRR
	; Write tile data, first tile in CHR
	lda #$00
begintiles:
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	dey
	bne begintiles
	rts

	;----------------------------------------------------
	; Loads the palete to VRAM (16 values)
PALETE_CHG:
	; Palete
	lda #HIGH(VRAM_PAL_ADDR) ; 
	sta PPUADDRR  		 ; Set address of the palete in vram
	lda #LOW(VRAM_PAL_ADDR)
	sta PPUADDRR
paltewr:
	; Write the palete
	ldx PAL_INDEX
	ldy #$00
paletec:
	lda PaletteData, X
	sta PPURWR
	inx
	lda PaletteData, X
	sta PPURWR
	inx
	lda PaletteData, X
	sta PPURWR
	inx
	lda PaletteData, X
	sta PPURWR
	inx
	iny
	iny
	iny
	iny
	cpy #$20
	bne paletec
	; Change the palete index
	lda PAL_INDEX
	;adc #$10
	;cmp #$50        	; end of the palete values
	bcs clear_palindex
	bne next_pal
clear_palindex:	
	lda #$00                ; return to the begining of the palete
next_pal:
	sta PAL_INDEX	
	rts

	;----------------------------------------------------
	;  Vector table
	.bank 1			
	.org    $FFFA
	.dw     0        ; NMI (NMI_Routine)
	.dw     Init     ; RESET (Reset_Routine)
	.dw     0        ; IRQ (IRQ_Routine)

	.bank 2
	.org $0000
	.incbin "test.chr"  ; must be 8192 bytes long

