; This routine will take charge of basic sprite 0 emulation.
; It will be called in the NMI
.BANK 0
.ORG 0
.SECTION "Sprite0Init"
	

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
	;BREAK2
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


.ENDS


	
