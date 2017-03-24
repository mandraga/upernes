
; This routine will update the palettes in CGRAM during vblank (if needed).
.BANK 0
.ORG 0
.SECTION "PaletteUpdate"

;--------------------------------------------------------------------------------------------------
; Updates the palette in CGRAM during NMI
UpdatePalettes:

	;phb
	php		;Preserve registers
	pha
	phx
	phy

	sep #$30	; All 8bits

	; Test each bit corresponding to a palette
	; If 0, then do nothing
	lda UpdatePalette
	and #$01
	beq BGpalette1
	ldx #$00
	ldy #$00             ; Destination in CGRAM
	jsr transferPalette  ; BG palette zer0 must be converted and transfered
BGpalette1:
	lda UpdatePalette
	and #$02
	beq BGpalette2
	ldx #$04             ; BG palette 1
	ldy #$04             ; Destination
	jsr transferPalette
BGpalette2:
	lda UpdatePalette
	and #$04
	beq BGpalette3
	ldx #$08             ; BG palette 2
	ldy #$08             ; Destination
	jsr transferPalette	
BGpalette3:
	lda UpdatePalette
	and #$08
	beq EndBGpalette
	ldx #$0C             ; BG palette 3
	ldy #$0C             ; Destination
	jsr transferPalette	
EndBGpalette:
	; Sprite palettes, they are spaced by 16words
	lda UpdatePalette
	and #$10
	beq SprPalette1
	ldx #$10
	ldy #$80                ; Destination in CGRAM
	jsr transferPalette  ; Sprites palette zer0 must be converted and transfered
SprPalette1:
	lda UpdatePalette
	and #$20
	beq SprPalette2
	ldx #$14                ; Sprites palette 1
	ldy #$90                ; Destination
	jsr transferPalette
SprPalette2:
	lda UpdatePalette
	and #$40
	beq SprPalette3
	ldx #$18                ; Sprites palette 2
	ldy #$A0                ; Destination
	jsr transferPalette	
SprPalette3:
	lda UpdatePalette
	and #$80
	beq EndSprPalette
	ldx #$1C                ; Sprites palette 3
	ldy #$B0                ; Destination
	jsr transferPalette	
EndSprPalette:	
	stz UpdatePalette       ; Nothing to be updated

	ply
	plx
	pla
	plp		;Restore registers
	;plb
	rts		;Return to caller

;--------------------------------------------------------------------------------------------------	
; This routine converts the nes color values from the palette in sram to snes color valurs in CGRAM
; Y is the CG address
; X is the nes color address
transferPalette:
	sty CGADD               ; Set the palette address register
	phb
	lda #:nes2snespalette	; Bank of the palette conversion table
	pha
	plb			            ; A -> Data Bank Register
	ldy #$04                ; 4 values
Loop4ColorPalette:
	; Copy the 4 colors
	lda Palettebuffer,X     ; get the nes color value
	inx
	asl			            ; word index in the BGR 555 conversion values
	phy
	tay
	lda nes2snespalette,Y   ; Load the palette conversion value
	; Send it to CG ram
	sta CGDATA
	iny
	lda nes2snespalette,Y
	sta CGDATA
	ply
	dey
	bne Loop4ColorPalette
	plb    ; Restores the data bank register
	rts

;--------------------------------------------------------
; Fills an array of bit masks
InitUpdateFlags:
	sep #$30	; All 8bits
	lda #$01
	sta UpdateFlags
	rol A
	sta UpdateFlags + 1
	rol A
	sta UpdateFlags + 2
	rol A
	sta UpdateFlags + 3
	rol A
	sta UpdateFlags + 4
	rol A
	sta UpdateFlags + 5
	rol A
	sta UpdateFlags + 6
	rol A
	sta UpdateFlags + 7
	rts

; Not used
colormirroring:
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	;; Copy the color at every b0000XX00 address
	;; BG palette
	lda #$00
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$04
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$08
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$0C
	sta CGADD
	stx CGDATA
	sty CGDATA
	;; Sprite palette color 0 mirroring (jump 16 words for each color)
	lda #$80
	sta CGADD
	stx CGDATA
	sty CGDATA	
	lda #$90
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$A0
	sta CGADD
	stx CGDATA
	sty CGDATA
	lda #$B0
	sta CGADD
	stx CGDATA
	sty CGDATA
	jmp endwpumem

.ENDS
