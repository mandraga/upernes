
; iNes header
; 1 16KB prg bank
	.inesprg    1
	.ineschr    1			; 1 8KB  chr bank
	.inesmir    1			; 1 Vertical mirroring
	.inesmap    0		

INDADDR   equ  $0008
	
PPU0      equ  $2000
PPU1      equ  $2001
PPUSTATUS equ  $2002
PPUADDRR  equ  $2006
PPURWR    equ  $2007

	.bank 0
	.org $C000

Init:
	cld			; Clear decimal mode flag
	lda #%00010000     	; Background patern able address = $1000 VRAM
        sta PPU0          	; PPU control 1
        lda #%00011110 
        sta PPU1		; PPU control 2 No cliping BG & Sprites visible

	;; Stores the label address in memory ($C020 @ $0008)
	lda #$20
	sta INDADDR
	lda #$C0
	sta INDADDR + 1
	;; Jumps to the address specified
	; jmp ($0008)
	;; nesasm fails on the indirect jump and translates it to a static jump
	;; Therefore entered manually
	.db $6C, $08, $00
	nop
	nop
	nop
	jmp iloop
	
	.org $C020
indirectjumplabel:
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

waitvblank:
	lda PPUSTATUS
	bpl waitvblank
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
