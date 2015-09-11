
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

PAD0	  equ  $4016
PAD1	  equ  $4017

IMPADBASE equ  $21
IMPADOFFP equ  $A8
IMPADOFFS equ  $C8
IMPADOFFN equ  $E8

SELECT	equ	$01
START	equ	$02
UP	equ	$03
DOWN	equ	$04
LEFT	equ	$05
RIGHT	equ	$06

	.bank 0
	.org $C000

Init:
	cld			; Clear decimal mode flag
	lda #%00010000     	; Background patern table address = $1000 VRAM
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
	.db $0F,$2D,$3D,$10, $0F,$07,$17,$16, $0F,$30,$02,$21, $0F,$30,$00,$10
SPRpalette:
	.db $0F,$29,$1A,$0F, $0F,$36,$17,$0F, $0F,$30,$21,$0F, $0F,$27,$17,$0F
paltewr:
	; Write the palete
	ldx #$00
paletec:
	lda BGpalette,x
	sta PPURWR
	inx
	cpx #$20
	bne paletec

; 	jsr waitvblank
; 	jsr STOPPPU

	; Static name table dislay a tile in the middle of the screen
	lda #$20        	; name table in vram at $2000
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	lda #$1E
	sta $0A	  		; Line counter in ram

	;; Fill the screen with transparent tiles (Nametable)
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

; 	jsr ShowallButtons

	;; Palete write in attribute table for red buttons
	lda #$23
	sta PPUADDRR
	lda #$DC
	sta PPUADDRR
	lda #%01010101
	sta PPURWR
	sta PPURWR

	jsr STARTPPU

iloop:
	;; Get joystick 1 data
	;; latch
	lda #1
	sta PAD0
	lda #0
	sta PAD0
	;; Read buttons
	lda PAD0
	and #$01
	sta $0A
	lda PAD0
	and #$01
	sta $0B
	lda PAD0
	and #$01
	sta SELECT
	lda PAD0
	and #$01
	sta START
	lda PAD0
	and #$01
	sta UP
	lda PAD0
	and #$01
	sta DOWN
	lda PAD0
	and #$01
	sta LEFT
	lda PAD0
	and #$01
	sta RIGHT


	jsr waitvblank
 ; 	jsr STOPPPU

	jsr ShowallButtons
	
	jmp iloop


;; -------------------------------------------------------------------------

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
	;; Reseted vblank flag
	rts
	
ShowallButtons:
	;; left nothing right select start A B
	lda #IMPADBASE        	; name table in vram at $2000
	sta PPUADDRR
	lda #IMPADOFFS
	sta PPUADDRR
	;; left
	lda LEFT
	cmp #0
	beq showleft
	lda #$24
	jmp wrleft
showleft:
	lda #$01
wrleft:
	sta PPURWR
	;; Cursor center
	lda #$04
	sta PPURWR
	;; right
	lda RIGHT
	cmp #0
	beq showright
	lda #$24
	jmp wrright
showright:
	lda #$02
wrright:
	sta PPURWR
	;; 2 Spaces
	lda #$24
	sta PPURWR
	sta PPURWR
	;; select
	lda SELECT
	cmp #0
	beq showselect
	lda #$24
	jmp wrselect
showselect:
	lda #$00
wrselect:
	sta PPURWR
	;; Space
	lda #$24
	sta PPURWR
	;; start
	lda START
	cmp #0
	beq showstart
	lda #$24
	jmp wrstart
showstart:
	lda #$00
wrstart:
	sta PPURWR
	;; Spaces
	lda #$24
	sta PPURWR
	sta PPURWR
	;; B
	lda $0B
	cmp #0
	beq showB
	lda #$24
	jmp wrB
showB:
	lda #$06
wrB:
	sta PPURWR
	;; Space
	lda #$24
	sta PPURWR
	;; A
	lda $0A
	cmp #0
	beq showA
	lda #$24
	jmp wrA
showA:	
	lda #$06
wrA:
	sta PPURWR

	;; Up/Down buttons
	lda #IMPADBASE        	; name table in vram at $2000
	sta PPUADDRR
	lda #IMPADOFFP + 1
	sta PPUADDRR
	;; UP
	lda UP
	cmp #0
	beq showUP
	lda #$24
	jmp wrUP
showUP:
	lda #$03
wrUP:
	sta PPURWR

	lda #IMPADBASE        	; name table in vram at $2000
	sta PPUADDRR
	lda #IMPADOFFN + 1
	sta PPUADDRR
	;; DOWN
	lda DOWN
	cmp #0
	beq showDOWN
	lda #$24
	jmp wrDOWN
showDOWN:
	lda #$13
wrDOWN:
	sta PPURWR
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
