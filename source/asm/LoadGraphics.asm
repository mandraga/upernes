;------------------------------------------------------------------------
;-  Written by: Neviksti
;-     If you use my code, please share your creations with me
;-     as I am always curious :)
;-
;-  Note: some of these routines were originally from examples released
;-     by Grog. I don't remember which ones.
;------------------------------------------------------------------------

;============================================================================
; LoadBlockToVRAM -- Macro that simplifies calling LoadVRAM to copy data to VRAM
;----------------------------------------------------------------------------
; In: SRC_ADDR -- 24 bit address of source data
;     DEST -- VRAM address to write to (WORD address!!)
;     SIZE -- number of BYTEs to copy
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: A, X, Y
;---------------------------------------------------------------------------

;LoadBlockToVRAM SRC_ADDRESS, DEST, SIZE
;   requires:  mem/A = 8 bit, X/Y = 16 bit
.MACRO LoadBlockToVRAM 
	ldx #\2		; DEST
	stx $2116
	lda #:\1	; SRCBANK
	ldx #\1		; SRCOFFSET
	ldy #\3		; SIZE
	jsr LoadVRAM
.ENDM

.BANK 0 SLOT 0
.ORG 0
.SECTION "LoadVramCode" SEMIFREE

;============================================================================
; LoadVRAM -- Load data into VRAM
;----------------------------------------------------------------------------
; In: A:X  -- points to the data
;     Y     -- Number of bytes to copy (0 to 65535)  (assumes 16-bit index)
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: none
;----------------------------------------------------------------------------
; Notes:  Assumes VRAM address has been previously set!!
;----------------------------------------------------------------------------
LoadVRAM:
	pha
	phx
	phy
	phb
	php		;Preserve registers

	sep #$20	;Careful not to SEP $10, or it will erase upper half of Y!
	rep #$10	; X/Y = 16 bit

    stz $420B	;Clear the DMA control register
    stx $4302	;Store the data offset into DMA source offset
	sty $4305	;Store the size of the data block
    sta $4304	;Store the data bank of the source data

	lda #$80
	sta $2115	;set VRAM transfer mode to word-access, increment by 1

    lda #$01	;Set the DMA mode (word, normal increment)
    sta $4300
    lda #$18	;Set the destination register (VRAM gate)
    sta $4301
    lda #$01	;Initiate the DMA transfer
    sta $420B

	plp		;Restore registers
	plb
	ply
	plx
	pla
	rts		;Return to caller
;============================================================================

;============================================================================
; DMA_WRAMtoVRAM
;----------------------------------------------------------------------------
; In: A sprite chr bank number 0 to 7
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: none
;----------------------------------------------------------------------------
; Notes:  Assumes VRAM address has been previously set!!
;----------------------------------------------------------------------------
DMA_WRAMtoVRAM_sprite_bank:
	pha
	phy
	php			;Preserve registers
	
	sep #$20		; A 8bits
	rep #$10		; X Y 16bits
	
	; Calculate the 8KB bank number
	adc #$01                ; Starts at 8K, therefore add 1 to the segment index
	clc
	asl                     ; the segment number is shifted to a multiple of 8K, to the bit 13 of the address
	asl
	asl
	asl
	asl
	; Set the Wram address
	sta WMADDM
	lda #$00
	sta WMADDL
	sta WMADDH

	stz VMADDL              ; VRAM $0000 is the destination
	stz VMADDH

	stz MDMAEN      ; Clear the DMA control register, all channels are disabled

	ldy #WMDATA
	sty DMA1A1SRCL	; A bus data offset into DMA source offset.
	lda #$00		; any bank given the WMDATA register is accessed
    sta DMA1A1SRCBNK	        ; Stores the A bus data bank of the source data
	ldy #$2000
	sty DMA1SZL		; Stores the size in bytes of the data block, always 8KB

	lda #$80
	sta VMAINC		; Sets VRAM transfer mode to word-access, increment by 1

    lda #$09		; DMA mode: Abus -> Bbus, absolute, Fixed src @, 2 addresses L H
    sta DMA1CTL
    lda #$18		; Sets the destination register (VRAM gate)
    sta DMA1BDEST
    lda #$02		; Initiate the DMA transfer
    sta MDMAEN

	plp			; Restore registers
	ply
	pla
	rts			; Return to caller
;============================================================================

.ENDS




