
	
		;; This program moves sprites only using a buffer transfered via DMA

	
; iNes header
; 1 16KB prg bank
	.inesprg    1
	.ineschr    1			; 1 8KB  chr bank
	.inesmir    1			; 1 Vertical mirroring
	.inesmap    0		

PPU0      equ  $2000
PPU1      equ  $2001
PPUSTATUS equ  $2002
PPUADDRR  equ  $2006
PPURWR    equ  $2007
	
SPRADDR	  equ  $2003
SPRDATA   equ  $2004

DMAACCESS equ  $4014

PAD0	  equ  $4016
PAD1	  equ  $4017


DELAYTMP equ $0010
		
YPOS	 equ $0200   		; The buffer it at offset 512 in ram
TILE	 equ $0201
ATTR	 equ $0202
XPOS	 equ $0203

ENABLEDMA equ $0003
	
	.bank 0
	.org $C000

Init:
	cld			; Clear decimal mode flag
	lda #%00000000     	; base nametable @ $2000,patern table at $0 for background and sprites
        sta PPU0          	; PPU control 1
        lda #%00010100		; Show sprites and left column, background not enabled
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

	; Write the sprite palete
 	ldx #$00
paleted:
 	lda SPRpalette,x
 	sta PPURWR
 	inx	
 	cpx #$10
 	bne paleted

	;jsr STARTPPU
	;jsr waitvblank
	jsr STOPPPU

	;; Clear sprite memory
	ldx #0
	lda #0
	sta SPRADDR
resetsprites:
	sta SPRDATA
	dex
	bne resetsprites

	;; First sprite, initial position
	lda #20
	sta YPOS                ; Y position
	lda #$01		; Sprite tile 1
	sta TILE
	lda #%00000010		; palete 2, no flip
	sta ATTR
	lda #$08
	sta XPOS                ; X position

	jsr STARTPPU
testtmp:
	jsr waitvblank


	lda #$02		; Sprite table at 512 (2 * $100)
	sta DMAACCESS		; start the transfert

	lda #$00
	sta DELAYTMP
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
	jsr movespritesDMA	; Start the buffer transfert
	inc DELAYTMP
	lda DELAYTMP            ; Increment the position once every 256 counts
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
noinc:
	jmp iloop


	; sub routines
STOPPPU:
        lda #%00000110
        sta PPU1
	rts

STARTPPU:
        lda #%00010100
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
