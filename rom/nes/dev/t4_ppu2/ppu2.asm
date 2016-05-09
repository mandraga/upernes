
; iNes header
; 1 16KB prg bank
	.inesprg    1
	.ineschr    1			; 1 8KB  chr bank
	.inesmir    1			; 1 Vertical mirroring
	.inesmap    0		

PPU0      equ  $2000
PPU1      equ  $2001
PPUSTATUS equ  $2002
SCRSCROLL equ  $2005
PPUADDRR  equ  $2006
PPURWR    equ  $2007
	
SPRADDR	  equ  $2003
SPRDATA   equ  $2004

DMAACCESS equ  $4014

PAD0	  equ  $4016
PAD1	  equ  $4017


YPOS	equ $0200
TILE	equ $0201
ATTR	equ $0202
XPOS	equ $0203

ENABLEDMA equ $0003

SCROLLX	  equ $000E
SCROLLY   equ $000F

	.bank 0
	.org $C000

Init:
	cld			; Clear decimal mode flag
	lda #%00010000     	; Background patern able address = $1000 VRAM
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

	; Static name table dislay a tile in the middle of the screen
	lda #$20        	; name table in vram at $2000
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	lda #$1E
	sta $0A	  		; Line counter in ram
re:
	lda #$24
	ldx #$20
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
	
	; 16, 15 <- tile
	lda #$21        	; name table in vram at $2000
	sta PPUADDRR
	lda #$CE
	sta PPUADDRR
	lda #$A0
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR

	;; Clear sprite memory
	ldx #0
	lda #0
	sta SPRADDR
resetsprites:
	sta SPRDATA
	dex
	bne resetsprites

	;; Load sprites
	lda #$00
	sta SPRADDR
	sta ENABLEDMA
	;; First sprite
	lda #$00
	sta YPOS
	lda YPOS		; Y position
	sta SPRDATA
	lda #$01		; Sprite tile
	sta TILE
	sta SPRDATA
	lda #$%00000010		; palete 2, no flip
	sta ATTR
	sta SPRDATA
	lda #$08
	sta XPOS
	lda XPOS		; X position
	sta SPRDATA
	
	jsr STARTPPU

	lda #$00
	sta SCROLLX
	sta SCROLLY

iloop:
	jsr waitvblank
	;; latch paddle 1
	lda #1
	sta PAD0
	lda #0
	sta PAD0
	;; Read A
	lda PAD0
	and #$01
	eor ENABLEDMA
	sta ENABLEDMA
	;; move sprites using dma
	lda ENABLEDMA
	cmp #0
	bne noinc
	jsr movespritesDMA
	inc $00
	lda $00
	cmp $1E
	bne noinc
	inc YPOS
	inc XPOS
	inc XPOS
	lda XPOS
	cmp #$80
	bcs noinc
	lda ATTR
	eor #%10100010		; palete chg, flip
	sta ATTR
	;; Scrolling
	lda SCROLLX
	sta SCRSCROLL
	inc SCROLLX
	lda SCROLLY
	sta SCRSCROLL
	lda SCROLLX
	cmp #$4A
	bcs noinc
	inc SCROLLY
noinc:
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

waitvblank:
	lda PPUSTATUS
	bpl waitvblank
	rts

movespritesDMA:
	lda #$02		; Sprite table at 512 (2 * $100)
	sta DMAACCESS		; start the transfert
	rts


	;  Vector table
	.bank 1
	.org    $FFFA
	.dw     0        ; NMI (NMI_Routine)
	.dw     Init     ; RESET (Reset_Routine)
	.dw     0        ; IRQ (IRQ_Routine)

	.bank 2
	.org $0000
	.incbin "test.chr"  ;gotta be 8192 bytes long
