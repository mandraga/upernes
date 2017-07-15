
; This routine will update the sprites using the DMA or HDMA channels
; It will be called in the NMI during Vblank
.BANK 0
.ORG 0
.SECTION "SpritesUpdate"

UpdateSpritesDMA:
	sep #$20	; A 8b
	lda UpdateSprites
	bne TransferSprites
	jmp EndTransferSprites
TransferSprites:
	stz UpdateSprites
.DEFINE USEDMA
.IFDEF USEDMA
	;; Transfer the 256 bytes to the OAM memory port via DMA 1
	;; -------------------------------------------------------------
	stz MDMAEN      ; disable any dma channel
	;; Writes to OAMDATA from 0 to 256
	stz OAMADDL
	stz OAMADDH
	;; DMA mode:   CPU RAM to PPU RAM 0, x, x, 00 automatic increment, 00 one address per byte
	sep #$20		; A 8b
	lda #%00000000
	sta DMA1CTL     ; Write the mode before everything else
	lda #$04		; OAMDATA register, byte ($2104)
	sta DMA1BDEST
	;; Size = $100 = 256
	rep #$20		; A 16b
	lda #$0100
	sta DMA1SZL
	;; Source address (in RAM)
	rep #$20		; A 16b
	lda #SpriteMemoryBase
	sta DMA1A1SRCL
	sep #$20		; A 8b
	phb
	pla
	sta DMA1A1SRCBNK ; bank
	;; Start the transfert
	sep #$20	; A 8b
	lda #$02    ; channel 1
	sta MDMAEN
.ELSE
	; A loop instead of a dma transfert
	sep #$30		; all 8b
	stz OAMADDL     ; OAM address set to $00
	stz OAMADDH     ; OAM address set to $00	
	ldx #0
sprtransfertloop:
	lda SpriteMemoryBase,X  ; Copy the 256 bytes
	sta OAMDATA
	inx
	bne sprtransfertloop	; loop if not zero
.ENDIF
EndTransferSprites:
	rts		;Return to caller




;----------------------------------------------------------------------------
; HideLast64Sprites -- Hites the last 64 sprites somewhere
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
HideLast64Sprites:
	;rts
	sep #$30		; all 8b
	ldx #0
	lda #248
sprtHideloop:
	stz SpriteMemoryBase + 0, X
	sta SpriteMemoryBase + 1, X ; Y to 248
	stz SpriteMemoryBase + 2, X
	stz SpriteMemoryBase + 3, X
	inx
	inx
	inx
	inx
	bne sprtHideloop	; loop if not zero (256 times)
	;;------------------------------------------------------------------------------
	;; Then copy the 256 bytes into the OAM memory
wait_for_vblank_SPR:
	lda HVBJOY		;check the vblank flag
	bpl wait_for_vblank_SPR
	;; Transfer the 256 bytes to the OAM memory port via DMA 1
	;; -------------------------------------------------------------
	stz MDMAEN      ; disable any dma channel
	;; Writes to OAMDATA from 128 to 256Words
	lda #$80
	sta OAMADDL
	lda #$00
	sta OAMADDH
	;; DMA mode:   CPU RAM to PPU RAM 0, x, x, 00 automatic increment, 00 one address per byte
	sep #$20		; A 8b
	lda #%00000000
	sta DMA1CTL     ; Write the mode before everything else
	lda #$04		; OAMDATA register, byte ($2104)
	sta DMA1BDEST
	;; Size = $100 = 256
	rep #$20		; A 16b
	lda #$0100
	sta DMA1SZL
	;; Source address (in RAM)
	rep #$20		; A 16b
	lda #SpriteMemoryBase
	sta DMA1A1SRCL
	sep #$20		; A 8b
	;phb
	;pla
	lda #00
	sta DMA1A1SRCBNK ; bank
	;; Start the transfert
	sep #$20	; A 8b
	lda #$02    ; channel 1
	sta MDMAEN
	;; -------------------------------------------------------------
	;; Clear the buffer
	sep #$30		; all 8b
	ldx #0
	lda #00
sprtClearloop:
	sta SpriteMemoryBase + 1, X ; Y to 248
	inx
	inx
	inx
	inx
	bne sprtClearloop	; loop if not zero (256 times)
	rts

.ENDS