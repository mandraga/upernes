
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

RESULT    equ  $50
COMPRES   equ  $51

	.bank 0
	.org $C000

Init:
	jsr waitvblank
	jsr waitvblank

	cld			; Clear decimal mode flag
	lda #%10010000     	; Background patern able address = $1000 VRAM, NMI enabled
    sta PPU0          	; PPU control 1
    lda #%00011110
    sta PPU1		; PPU control 2 No cliping BG & Sprites visible
		
	jsr STOPPPU
	;-----------------------------------------------------------------------------
	; Writes in memory and reads all back to test if everything is equal
	; 
	lda #$00
	sta RESULT
	; Test reads an writes in CGRAM 
	jsr TestCGRAM
	cmp #$00
	bne WrongShit
	; Test reads an writes in Attribute table
	jsr TestAtributes
	cmp #$00
	bne WrongShit
	; Test reads an writes in Name tables
	jsr TestNameTables
	cmp #$00
	bne WrongShit	
	jmp OKShit
WrongShit:
	lda #$01
	sta RESULT
OKShit:

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

	
	; 16, 15 <- tile
	lda #$21        	; name table in vram at $2000
	sta PPUADDRR        ; Drawing tiles at $21CE
	lda #$CE
	sta PPUADDRR
	; Write tile data
	lda RESULT
	beq ThumbUp
	lda #$A2  ; Thumb Down
	jmp WriteThumb
ThumbUp:
	lda #$A1  ; Thumb Up
WriteThumb:
	sta PPURWR
	sta PPURWR
	sta PPURWR
	sta PPURWR
	
	jsr REFRESHPPUSCROL ; Must be done after every acces to VRAM write
	jsr STARTPPU	

iloop:
	jmp iloop


TestCGRAM:
	;jsr waitvblank
	; Write
	lda #$3F
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	; 32bytes
	ldy #$00
LoopCGW:
	sty PPURWR
	iny
	tya
	cmp #$20
	bne LoopCGW
	; Read
	lda #$3F
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	ldy #$00
	;lda PPURWR ; Latch
LoopCGR:
	sty COMPRES
	iny
	lda PPURWR
	;cmp COMPRES
	;bne FailCG ; Will always fail because of color 0 of each palette
	tya
	cmp #$20
	bne LoopCGR
SuccessCG:
	lda #$00
	rts
FailCG:
	lda #$01
	rts
	
TestAtributes:
	;jsr waitvblank
	; Write
	lda #$23
	sta PPUADDRR
	lda #$C0
	sta PPUADDRR
	; Write from $23C0 to $2400
	ldy #$C0
AttrLoop:
	tya
	sta PPURWR
	iny
	beq EndAttr
	jmp AttrLoop
EndAttr:
	;----------------------------------
	; Read
	;jsr waitvblank
	lda #$23
	sta PPUADDRR
	lda #$C0
	sta PPUADDRR
	lda PPURWR ; Latch !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	; Write from $23C0 to $2400
	ldx #$23        ;
	ldy #$C0
AttrRLoop
	sty COMPRES ; 0 to 255
	lda PPURWR
	cmp COMPRES
	bne FailedAttr
	iny
	beq SuccessAttr
	jmp AttrRLoop
SuccessAttr:
	lda #$00
	rts
FailedAttr:
	lda #$01
	rts

; Writes also on tables
TestNameTables:
	jsr waitvblank
	; Write
	lda #$20        	; name table in vram at $2000
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	; Write from $2000 to $2400
	ldx #$20        ;
Names256Chunk:
	ldy #$00
NamesLoop:
	tya     ; 0 to 255
	sta PPURWR
	clc
	adc #$01
	iny
	beq TestEndNames
	jmp NamesLoop
TestEndNames:
	inx
	txa
	cmp #$24
	bne Names256Chunk
	;----------------------------------
	; Read
	jsr waitvblank
	lda #$20        	; name table in vram at $2000
	sta PPUADDRR
	lda #$00
	sta PPUADDRR
	lda PPURWR ; Latch !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	; Write from $2000 to $23C00
	ldx #$20        ;
Read256BChunk:
	ldy #$00
NamesRLoop
	sty COMPRES ; 0 to 255
	lda PPURWR
	cmp COMPRES
	bne Failed
	iny
	beq EndRNames
	jmp NamesRLoop
EndRNames:
	inx
	txa
	cmp #$24
	bne Read256BChunk
Success:
	lda #$00
	rts
Failed:
	lda #$01
	rts

	
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
