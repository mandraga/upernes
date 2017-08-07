
; This routine will update the nametables using the DMA or HDMA channels
; It will be called in the NMI
.BANK 0
.ORG 0
.SECTION "DmaBackgroundUpdate"

;--------------------------------------------------------------------------
; Rolling update
; This takes less time per frame and update everything, but the full screen update is delayed.
UpdateBackgroundsRolling:
;UpdateBackgrounds:
	;BREAK2
	;jsr UpdateNametables
	;jmp labs ; Jumps over the DMA update
	
	
	rep #$10	; X/Y = 16 bit
;jmp labs

	stz MDMAEN	;Clear the DMA control register

	lda BGTransferStep
	rep #$20
	and #$007F   ; This is the transfer step
	asl
	asl
	asl
	asl
	asl
	asl ; x32
	tax
	adc #$1000
	;ldx #$1000
    sta DMA2A1SRCL	  ; Store the data offset into DMA source offset
	sep #$20	; A 8bits
	;ldy #$0800        ; 4k
	ldy #$0080        ; 64words 128Bytes
	sty DMA2SZL 	  ; Store the size of the data block
	lda #$00
    sta DMA2A1SRCBNK  ;Store the data bank of the source data

	lda #$80
	sta VMAINC	;set VRAM transfer mode to word-access, increment by 1

    lda #$01	;Set the DMA mode (word, normal increment)
    sta DMA2CTL
    lda #$18	;Set the destination register (VRAM gate)
    sta DMA2BDEST
	
	rep #$20
	txa
	;clc
	lsr
	;adc #$0000
	sta VMADDL
	sep #$20

    lda #$04	;Initiate the DMA2 transfer
    sta MDMAEN

;jmp labs
	;stz MDMAEN	;Clear the DMA control register

	rep #$20
	txa
	adc #$1800
	;ldx #$1800
    sta DMA3A1SRCL	  ; Store the data offset into DMA source offset
	sep #$20
	;ldy #$0800        ; 4k
	ldy #$0080        ; 64words 128Bytes
	sty DMA3SZL 	  ; Store the size of the data block
	lda #$00
    sta DMA3A1SRCBNK  ;Store the data bank of the source data

	lda #$80
	sta VMAINC	;set VRAM transfer mode to word-access, increment by 1

    lda #$01	;Set the DMA mode (word, normal increment)
    sta DMA3CTL
    lda #$18	;Set the destination register (VRAM gate)
    sta DMA3BDEST

	rep #$20	
	txa
	clc
	lsr
	adc #$0400
	;ldy #$7400
	sta VMADDL
	sep #$20

    lda #$08	;Initiate the DMA3 transfer
    sta MDMAEN
	
labs:
	lda BGTransferStep
	and #$7F   ; This is the transfer step	
	adc #$02
	sta BGTransferStep
	rts		;Return to caller


.ENDS
