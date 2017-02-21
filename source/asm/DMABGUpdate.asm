
; This routine will update the nametables using the DMA or HDMA channels
; It will be called in the NMI
.BANK 0
.ORG 0
.SECTION "DmaBackgroundUpdate"

UpdateBackgrounds:

	;phb
	php		;Preserve registers
	pha
	phx
	phy
	
	;NATIVE
	clc			; native 65816 mode
	xce
	
	;BREAK2	
	sep #$20	; A 8bits
	rep #$10	; X/Y = 16 bit
;jmp labs
    stz MDMAEN	;Clear the DMA control register

	ldx #$1000
    stx DMA2A1SRCL	  ;Store the data offset into DMA source offset
	ldy #$1000        ; 4k
	sty DMA2SZL 	  ;Store the size of the data block
	lda #$00
    sta DMA2A1SRCBNK  ;Store the data bank of the source data

	lda #$80
	sta VMAINC	;set VRAM transfer mode to word-access, increment by 1

    lda #$01	;Set the DMA mode (word, normal increment)
    sta DMA2CTL
    lda #$18	;Set the destination register (VRAM gate)
    sta DMA2BDEST
	
	ldy #$7000
	sty VMADDL

    lda #$04	;Initiate the DMA2 transfer
    sta MDMAEN
labs:
	;EMULATION
	sec			; 6502 mulation mode
	xce
	
	ply
	plx
	pla
	plp		;Restore registers
	;plb
	rts		;Return to caller
rts

.ENDS