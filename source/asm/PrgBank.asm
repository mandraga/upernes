;------------------------------------------------------------------
; Prg bank switching emulation code
;
; The PRG banks are copied to the WRAM $7E bank.
; And executed there
;
;------------------------------------------------------------------

;------------------------------------------------------------------
; Routine for the simplest mapper.
; Just making a copy of the bank 1 to bank $EF for now.
; Does not care if it is a 16KB or 32KB rom.
;------------------------------------------------------------------

.DEFINE PRGBANKSIZE $8000

CopyPrgBank:
	phb
	sep #$20    ; A 8bits
	lda #$7E    ; Bank of the PRG ROM
	pha
	plb			; Data Bank Register = A
	rep #$30    ; A X Y are 16bits
	ldx #$0000
copyPRGCode:
	lda $818000,X
	sta $7E8000,X
	inx
	inx
	txa
	cmp #PRGBANKSIZE
	bne copyPRGCode
	sep #$20    ; A 8bits
	plb ; Restore the data bank
	rts

