; This rom uses the sprite 0 flag to update a sprite X coordinate.
;
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
	
SPRADDR	  equ  $2003
SPRDATA   equ  $2004

DMAACCESS equ  $4014

PAD0	  equ  $4016
PAD1	  equ  $4017


YPOS	equ $0200
TILE	equ $0201
ATTR	equ $0202
XPOS	equ $0203
; +4 for the second sprite

BGX  	equ $0208
PPU0TMP equ $0209
PPU1TMP equ $020A
LINECT  equ $0210

ENABLEDMA equ $0003
	
	.bank 0
	.org $C000

Init:
	sei
	cld              ; Clear decimal mode flag
	lda #%00010000   ; Background patern table address = $1000 VRAM
	sta PPU0TMP
    sta PPU0         ; PPU control 1
    ldx #$ff         ; reset stack pointer
    txs
	
	jsr waitvblank
	jsr waitvblank
	
    lda #%00011110 
	sta PPU1TMP
    sta PPU1         ; PPU control 2 No cliping BG & Sprites visible
		
	jsr STOPPPU
	
	; Palete
	lda #$3F		 ; 
	sta PPUADDRR  	 ; Set address of the palete in vram
	lda #$00
	sta PPUADDRR
	jmp paltewr
BGpalette:
	.db $0F,$2A,$09,$07, $0F,$30,$27,$15, $0F,$30,$02,$21, $0F,$30,$00,$10
SPRpalette:
	.db $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F
paltewr:
	; Write the background palete
	ldx #$00
paletec:
	lda BGpalette,x
	sta PPURWR
	inx
	cpx #$10
	bne paletec

	; Write the sprite palete
 	ldx #$00
paleted:
 	lda SPRpalette,x
 	sta PPURWR
 	inx	
 	cpx #$10
 	bne paleted
	
	;; ----------------------------------------------------------------
	; Background
	; 'Clear' the screen to tile A0
	; Static name table dislay a tile in the middle of the screen
	lda #$20        	; name table in vram at $2000
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	ldy #30
re:
	lda #$A0        ; default tile
	ldx #$20        ; x32
quarth:
	sta PPURWR
	dex
	bne quarth
	dey
	bne re

	jsr waitvblank
	jsr REFRESHPPUSCROL ; Must be done after every acces to VRAM write
	
	;loopLikeSuperMario1:
	;jmp loopLikeSuperMario1

	;; ----------------------------------------------------------------
	; Sprites
	; Clear sprite memory
	lda #255
	sta YPOS

	lda #0
	sta SPRADDR	
	ldx #0
resetsprites:
	lda #255
	sta SPRDATA
	lda #0
	sta SPRDATA
	lda #0
	sta SPRDATA
	lda #0
	sta SPRDATA
	dex
	dex
	dex
	dex
	bne resetsprites
	
	;; Load sprites
	lda #$00
	sta SPRADDR
	;; First sprite will be used for sprite 0
	;lda #239
	lda #116
	sta YPOS		; Y position
	sta SPRDATA
	lda #$00		; Sprite tile 0	
	sta TILE
	sta SPRDATA
	lda #%00000010	; palete 2, no flip
	sta ATTR
	sta SPRDATA
	lda #$00        ; X position
	sta XPOS
	sta SPRDATA

	;; Second sprite is suposed to move
	lda #100
	sta YPOS + 4		; Y position
	sta SPRDATA
	lda #$01		; Sprite tile 1
	sta TILE + 4
	sta SPRDATA
	lda #%00000010	; palete 2, no flip
	sta ATTR + 4
	sta SPRDATA
	lda #$08        ; X position
	sta XPOS + 4
	sta SPRDATA
	
	jsr waitvblank
	jsr ENABLENMI
	jsr STARTPPU
	
	
	cli
loopLikeSuperMario:
	jmp loopLikeSuperMario


;-------------------------------------------------------------------------------------------------
; Nmi with sprite zero like in super mario
NMI:
	jsr DISABLENMI
	
	lda #$02		; Sprite table at 512 (2 * $100)
	sta DMAACCESS	; start the transfert

    ldx PPUSTATUS   ;reset flip-flop and reset scroll registers to zero
	jsr REFRESHPPUSCROL

	; Code taken from the comented Super mario comprehensive disassembly.
	; Wait for sprite 0 hit
Sprite0Clr:
	lda PPUSTATUS             ; wait for sprite 0 flag to clear, which will
	and #%01000000            ; not happen until vblank has ended
	bne Sprite0Clr            ; branch if not cleared (waits for vblank)
Sprite0Hit:
	lda PPUSTATUS             ; do sprite #0 hit detection
	and #%01000000
	beq Sprite0Hit
	; At this time, the PPU is drawing the first pixel of sprite 0, change X scrolling and sprite 1 position

	lda #$07
	sta SPRADDR
	lda XPOS + 4
	clc
	adc #$01
	and #$7F
	sta SPRDATA
	sta XPOS + 4

	; Scrolling to  XPOS, 0
	;lda #$00
	sta XPOS + 4
	sta PPUSCROLL
	lda #$00
	sta PPUSCROLL

	jsr ENABLENMI
	rti


DISABLENMI:
	; Disable NMI
	lda PPU0TMP
	and #%01111111
	sta PPU0TMP
	sta PPU0
	rts

ENABLENMI:	
	; Enable NMI
	lda PPU0TMP
	ora #%10000000
	sta PPU0TMP
	sta PPU0
	rts
	
	; sub routines
STOPPPU:
	lda PPU1TMP
	and #%00000110
	sta PPU1
	sta PPU1TMP
	rts

STARTPPU:
	lda #%00011110
	sta PPU1
	sta PPU1TMP
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

movespritesDMA:
	lda #$02		; Sprite table at 512 (2 * $100)
	sta DMAACCESS	; start the transfert
	rts


	;  Vector table
	.bank 1
	.org    $FFFA
	.dw     NMI      ; NMI (NMI_Routine)
	.dw     Init     ; RESET (Reset_Routine)
	.dw     0        ; IRQ (IRQ_Routine)

	.bank 2
	.org $0000
	.incbin "test.chr"  ;gotta be 8192 bytes long
