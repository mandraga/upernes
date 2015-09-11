
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

SNDSQR1CTRL	equ	$4000
SNDSQR1E	equ	$4001
SNDSQR1PERIOD	equ	$4002
SNDSQR1LENPH	equ	$4003

SNDSQR2CTRL	equ	$4004
SNDSQRE2	equ	$4005
SNDSQR2PERIOD	equ	$4006
SNDSQR2LENPH	equ	$4007

SNDTRIACTRL	equ	$4008
; unused 
SNDTRIAPERIOD	equ	$400A
SNDTRIALENPH	equ	$400B

SNDNOISECTRL	equ	$400C
; unused
SNDNOISESHM	equ	$400E
SNDNOISELEN	equ	$400F

SNDDMCCTRL	equ	$4010
SNDDMCDAC	equ	$4011
SNDDMCSADDR	equ	$4012
SNDDMCSLEN	equ	$4013


SNDCHANSWITCH	equ	$4015
JOYSTICK1	equ	$4016
SNDSEQUENCER	equ	$4017

CNT		equ	$0012
PERL		equ	$0013
PERH		equ	$0014
CHAN		equ	$0015

	.bank 0
	.org $C000

Init:
	cld			; Clear decimal mode flag
	lda #%00010000     	; Background patern able address = $1000 VRAM
        sta PPU0          	; PPU control 1
        lda #%00011110 
        sta PPU1		; PPU control 2 No cliping BG & Sprites visible
	jsr waitvblank
	jsr STOPPPU
	;; Sound output

	;; Square 1
; 	lda #$88
; 	sta SNDSQR1CTRL
; 	lda #$71
; 	sta SNDSQR1E
; 	lda #$DA
; 	sta SNDSQR1PERIOD
; 	lda #$F0
; 	sta SNDSQR1LENPH

	lda #$FF
	sta SNDSQR1CTRL
	lda #$31
	sta SNDSQR1E
	lda #$FF
	sta SNDSQR1PERIOD
	lda #$50
	sta SNDSQR1LENPH

	;; Triangle
	lda #$7E
	sta SNDTRIACTRL
	lda #$55
	sta SNDTRIAPERIOD
	lda #$55
	sta SNDTRIALENPH

	;; Noise
	lda #$FF	 ; Like $4000 we just write all 1s 'cause
	sta SNDNOISECTRL ; we don't mind all the stuff in there being "on".
	lda #$50	 ; play rate of 5 (5), lower sounding mode (0)
	sta SNDNOISESHM
	lda #$AB
	sta SNDNOISELEN

 	;; Channel enable
 	lda #%00000001
 	sta SNDCHANSWITCH

	jsr STARTPPU
	lda #0
	sta CNT
	sta PERL
	sta PERH
	sta CHAN
iloop:
	jsr waitvblank		; used as a timer...
	inc CNT
	lda CNT
	cmp #$FF
	bne continue
 	;; Channel enable
	lda CHAN
	eor #1
	sta CHAN
	beq continue
 	sta SNDCHANSWITCH
	;; Change frequency
	lda PERL
	clc
	adc #1
	sta PERL
	lda PERH
	adc #0
	and #$03
	sta PERH
	;; Square 1
	lda PERL
	sta SNDSQR1PERIOD
	lda PERH
	sta SNDSQR1LENPH
continue
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
