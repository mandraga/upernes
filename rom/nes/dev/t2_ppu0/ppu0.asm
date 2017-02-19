
; iNes header
; 1 16KB prg bank
	.inesprg    1
	.ineschr    1			; 1 8KB  chr bank
	.inesmir    1			; 1 Vertical mirroring
	.inesmap    0		

PPU0      equ  $2000
PPU1      equ  $2001
PPUSTATUS equ  $2002
PPUSCROLL equ  $2005
PPUADDRR  equ  $2006
PPURWR    equ  $2007

	.bank 0
	.org $C000

Init:
	cld			; Clear decimal mode flag
	lda #%10010000     	; Background patern able address = $1000 VRAM, NMI enabled
    sta PPU0          	; PPU control 1
    lda #%00011110
    sta PPU1		; PPU control 2 No cliping BG & Sprites visible

	; Palete
	lda #$3F		; 
	sta PPUADDRR  		; Set address of the palete in vram
	lda #$00
	sta PPUADDRR
	jmp paltewr
BGpalette:
	.db $0F,$2A,$09,$07, $0F,$30,$27,$15, $0F,$30,$02,$21, $0F,$30,$00,$10
SPRpalette:
	.db $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F
paltewr:
	; Write the palete
	ldx #$00
paletec:
	lda BGpalette,x
	sta PPURWR
	inx
	cpx #$20
	bne paletec

	jsr waitvblank
	jsr STOPPPU

	;-----------------------------------------------------------------
	; Background
	;jmp passAttributes
	lda #$23        	; Attribute table in vram at $23C0
	sta PPUADDRR
	lda #$C0
	sta PPUADDRR	
	lda #$E4            ; 00 11 22 33
	sta PPURWR
	sta PPURWR
passAttributes:
	
	; 'Clear' the screen to tile 0
	; Static name table dislay a tile in the middle of the screen
	lda #$20        	; name table in vram at $2000
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	lda #$1E        ; 30
	sta $0A	  		; Line counter in ram set to 30
re:
	lda #$00        ; default tile
	;lda #$A0        ; default tile
	ldx #$20        ; x32
quarth:
	sta PPURWR
	dex
	bne quarth
	lda #$00
	dec $0A
	cmp $0A
	bne re

	jsr STARTPPU
	jsr waitvblank
	jsr STOPPPU

	; First block of 16 tiles
	lda #$20        	; name table in vram at $2000
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	; +32
	lda #$20        	; name table in vram at $2020
	sta PPUADDRR
	lda #$20
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	; +32
	lda #$20        	; name table in vram at $2040
	sta PPUADDRR
	lda #$40
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	; +32
	lda #$20        	; name table in vram at $2060
	sta PPUADDRR
	lda #$60
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR	

	; Second block of 16 tiles
	lda #$20        	; name table in vram at $2004
	sta PPUADDRR
	lda #$04
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	; +32
	lda #$20        	; name table in vram at $2024
	sta PPUADDRR
	lda #$24
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	; +32
	lda #$20        	; name table in vram at $2044
	sta PPUADDRR
	lda #$44
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	; +32
	lda #$20        	; name table in vram at $2064
	sta PPUADDRR
	lda #$64
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR	
	
	jsr STARTPPU
	jsr waitvblank
	jsr STOPPPU
	
	; 16, 15 <- tile
	lda #$21        	; name table in vram at $2000
	sta PPUADDRR        ; Drawing tiles at $21CE
	lda #$CE
	sta PPUADDRR
	; Write tile data
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR

	jsr REFRESHPPUSCROL ; Must be done after every acces to VRAM write
	jsr STARTPPU	

iloop:
	jmp iloop


	; sub routines
STOPPPU:
        lda #%00000110
        sta PPU1
	rts

STARTPPU:	
        lda #%00011110 
        sta PPU1
	rts
	
REFRESHPPUSCROL:
		; Scrolling to  0, 0
		lda #$00
		sta PPUSCROLL
		sta PPUSCROLL
	rts


waitvblank:
	lda PPUSTATUS
	bpl waitvblank
	rts
			
NMI:
	rti

	;  Vector table
	.bank 1			
	.org    $FFFA
	.dw     NMI      ; NMI (NMI_Routine)
	.dw     Init     ; RESET (Reset_Routine)
	.dw     0        ; IRQ (IRQ_Routine)

	.bank 2
	.org $0000
	.incbin "test.chr"  ;gotta be 8192 bytes long
