; This routine will take charge of basic sprite 0 emulation.
; It will be called in the NMI
.BANK 0
.ORG 0
.SECTION "Sprite0Init"
	
; USELESS for now
; This
InitSprite0
	php		;Preserve registers
	pha
	sep #$20	; A 8bits
	;
	stz SPRITE0FLAG             ; Sprite0 hit flag set to 0
	; Check if the sprite 0 hit flag is enabled (BG or sprites enabled)
	lda PPUcontrolreg2
	and #%00011000
	eor #%00011000              ; xor with the enabled value (the result should be zero if enabled)
	beq spr0Enabled
	jmp EndInitSprite0
spr0Enabled:
	;;--------------------------------------------------
	;  Configure the timer
	; It will set the IRQ flag on the line Y and therefore emulate the sprite 0 for basic usage
	;
	;sei
	lda SNESNMITMP
	ora #%00100000 ; Enable V timer
	sta NMITIMEN
	sta SNESNMITMP	
	;
	lda SpriteMemoryBase + 0 ; Get Y
	sta VTIMEL
	stz VTIMEH

	;stz HTIMEL
	;stz HTIMEH
	;;--------------------------------------------------
EndInitSprite0
	pla
	plp		;Restore registers
	rts		;Return to caller


; Updates the sprite zero flag only by reading to the counter
updateSprite0Flag:
	rep #$20    ; A 16bits
	lda TMPVCOUNTL
	;lda TMPVCOUNTL + 2
	;
	sep #$20    ; A 8bits
	lda #$00
	sta TMPVCOUNTH
	lda SpriteMemoryBase + 1 ; sprite 0's Y
	sta TMPVCOUNTL
	
	; Low first
	lda STAT78
	; Latch the H and V counters
	lda HVLATCH
	;lda #$00
	lda OPVCT   ; Low Byte
	swa
	lda HVLATCH
	lda OPVCT
	and #$01    ; Mask the open bus shit
	swa
	rep #$20    ; A 16bits
	sta TMPVCOUNTL + 2
	;swa
	;lda OPVCT   ; Hight Byte
	;swa
	cmp TMPVCOUNTL ; Compare to sprite 0's Y
	bcc Sprite0NotSet        ; If below, the sprite is not set
	;lda OPHCT                ; Horizontal value
	;cmp SpriteMemoryBase + 0 ; Compare to sprite 0's X
	;bcc Sprite0NotSet        ; If below, the sprite is not set
	; Sprite0 is set
	sep #$20    ; A 8bits
	lda #SPRITE0FLGAG_VALUE
	sta SPRITE0FLAG
	rts
Sprite0NotSet:
	sep #$20    ; A 8bits
	stz SPRITE0FLAG
	rts
	
.ENDS


	