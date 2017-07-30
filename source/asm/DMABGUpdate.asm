
; This routine will update the nametables using the DMA or HDMA channels
; It will be called in the NMI
.BANK 0
.ORG 0
.SECTION "DmaBackgroundUpdate"


;---------------------------------------------------------------------
; Updates a column of 30 tiles using the CPU
; X is the colum first name object in RAM
; All registers must be in 16 bits wide
ColumnUpdateBank1:
	rep #$30
	; X is the column from 0 to 32
	txa
	; The address in VRAM
	clc
	adc #$7000
	sta VMADDL
	txa                   ; Column offset
	asl                   ; In words (attr, name)
	tax
	; 30 lines
	lda NametableBaseBank1, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 1, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 2, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 3, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 4, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 5, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 6, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 7, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 8, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 9, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 10, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 11, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 12, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 13, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 14, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 15, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 16, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 17, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 18, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 19, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 20, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 21, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 22, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 23, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 24, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 25, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 26, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 27, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 28, X
	sta VMDATAL
	lda NametableBaseBank1 + 64 * 29, X
	sta VMDATAL
	; End column
	rts

ColumnUpdateBank2:
	rep #$30
	; X is the column from 0 to 32
	txa
	; The address in VRAM
	clc
	adc #$7400
	sta VMADDL
	txa                   ; Column offset
	asl                   ; In words (attr, name)
	tax
	; 30 lines
	lda NametableBaseBank2, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 1, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 2, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 3, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 4, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 5, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 6, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 7, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 8, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 9, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 10, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 11, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 12, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 13, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 14, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 15, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 16, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 17, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 18, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 19, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 20, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 21, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 22, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 23, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 24, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 25, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 26, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 27, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 28, X
	sta VMDATAL
	lda NametableBaseBank2 + 64 * 29, X
	sta VMDATAL
	; End column
	rts

	
.IFDEF HORIZONTALSCROLLING
UpdateBackgroundsS:
	BREAK
	;
	; Set increment to 32 words
	sep #$20
	lda #%10000001 ; Addres increments by 32
	sta VMAINC	
	;
	rep #$30   ; All 16bits
	ldx #$0000
	; Will update each colume form 0 to 32
	; Bank 1
UpdateNextColumns:
	lda LineColUpdate, X
	beq nextColumns
	; Something to update
	and #$00FF
	beq NextCol
	; Set the addresses
	phx
	jsr ColumnUpdateBank1
	plx
NextCol:
	lda LineColUpdate, X
	and #$FF00
	beq nextColumns
	; Set the addresses
	phx
	inx
	jsr ColumnUpdateBank1
	plx	
nextColumns:
	stz LineColUpdate, X  ; Cleared
	inx
	inx
	cpx #32
	bne UpdateNextColumns
	; Will update each colume form 32 to 64
	; Bank 2
UpdateNextColumnsB2:
	lda LineColUpdate, X
	beq nextColumnsB2
	; Something to update
	and #$00FF
	beq NextColB2
	; Set the addresses
	phx
	jsr ColumnUpdateBank2
	plx
NextColB2:
	lda LineColUpdate, X
	and #$FF00
	beq nextColumnsB2
	; Set the addresses
	phx
	jsr ColumnUpdateBank2
	plx	
nextColumnsB2:
	stz LineColUpdate, X  ; Cleared
	inx
	inx
	cpx #64
	bne UpdateNextColumnsB2	
	rts
.ELSE
UpdateBackgrounds:
	rts
.ENDIF


;--------------------------------------------------------------------------
; Local update or full DMA update
FullUpdateBackgrounds:
;UpdateBackgrounds:
	BREAK
	
	rep #$30   ; All 16bits
	ldx #$0000
UpdateNextColumns22:
	stz LineColUpdate, X

	inx
	inx
	cpx #64
	bne UpdateNextColumns22
	jmp fullDMAUpdate
	;---------------------------------------------------
	; Fifo update only
	sep #$20	      ; A 8bits
	lda BGUpdateFIFOSZ
	beq EndBGupdate ; if zero quit
	jmp fullDMAUpdate ;  shortcut
	cmp #BGFifoMax
	bcs fullDMAUpdate
	; Get each value and copy it
EmpyTheFifo:
	;BREAK3
	lda BGUpdateFIFOSZ
	sep #$20	      ; A 8bits
	lda #$80
	sta VMAINC	;set VRAM transfer mode to word-access, increment by 1
	lda BGUpdateFIFOSZ
	asl
	tax
	rep #$20
	lda BGUpdateFIFO, X ; PPU Address
	and #$7FE
	;asl
	sta VMADDL
	lda NametableBaseBank1,X
	sta VMDATAL
	dec BGUpdateFIFOSZ
	bne EmpyTheFifo
	jmp EndBGupdate
	;---------------------------------------------------
	; Full update
fullDMAUpdate:
	rep #$10	; X/Y = 16 bit
	stz MDMAEN	;Clear the DMA control register
	
	ldx #$1000
    stx DMA2A1SRCL	  ; DMA source
	sep #$20	      ; A 8bits
	ldy #$1000        ; 4k
	sty DMA2SZL 	  ; Store the size of the data block
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
	sep #$20

    lda #$04	;Initiate the DMA2 transfer
    sta MDMAEN
	
EndBGupdate:
	sep #$20	      ; A 8bits
	stz BGUpdateFIFOSZ
	stz BGUpdateFIFOSZ + 1
	rts

;--------------------------------------------------------------------------
; Rolling update
; This takes less time per frame and update everything, but the full screen update is delayed.
UpdateBackgroundsRolling:
UpdateBackgrounds:
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
	clc
	lsr
	adc #$7000
	;ldy #$7000
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
	adc #$7400
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

;---------------------------------------------------------------------
; Create columns transfert tables
; Creates 64 arrays of 16bit adresses in WRAM. Those bytes will be transfered during HDMA.
; 30 words at a time.
;
InitNameTransferTables:
	phb
	lda #$7E   ; The complete WROM can only be accessed from $7E or $7F
	pha
	plb
	rep #$30	; All 16 bit
	ldy #$0000
	ldx #$0000 ; The index of the start of the table
	lda #$0000
FillLoop:
	sta NameTransferTables,x
	inx
	inx
	clc
	adc #32
	cmp #$0400 ; 32 * 32
	bne FillLoop
	tya
	clc
	adc #$0002 ; Next column
	cmp #$0080 ; compare to 128 meaning end of the 2 banks
	beq EndInitTransfertTables
	tay
	tax
	lda #$0000
	jmp FillLoop
EndInitTransfertTables:
	plb
	rts

;---------------------------------------------------------------------
; Looks for the colums to be updated
;
.IFDEF MOREJUNKCODE
HeighColumnsUpdate:
	rep #$30	; All 16 bit
	bit #$01
	BNE Upd1
	clc
	lda ColumnTableLo
	;adc #0000 ; Firts column
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%11111110
	sta ColumnUpdateFlags
	lda UpdateCtr ; No more updates
	bne Upd1
	jmp UpdEnds
Upd1:
	bit #$02
	BNE Upd2
	lda ColumnTableLo
	clc
	adc #1 ; Second column
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%11111101
	sta ColumnUpdateFlags
	lda UpdateCtr
	bne Upd2
	jmp UpdEnds
Upd2:
	bit #$04
	BNE Upd3	
	clc
	lda ColumnTableLo
	adc #2 ; ...
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%11111011
	sta ColumnUpdateFlags
	lda UpdateCtr
	bne Upd3
	jmp UpdEnds
Upd3:
	bit #$08
	BNE Upd4	
	clc
	lda ColumnTableLo
	adc #3
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%11110111
	sta ColumnUpdateFlags
	lda UpdateCtr
	beq UpdEnds
Upd4:
	bit #$10
	BNE Upd5
	clc
	lda ColumnTableLo
	adc #4
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%11101111
	sta ColumnUpdateFlags
	lda UpdateCtr
	beq UpdEnds
Upd5:
	bit #$20
	BNE Upd6
	clc
	lda ColumnTableLo
	adc #5
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%11011111
	sta ColumnUpdateFlags
	lda UpdateCtr
	beq UpdEnds
Upd6:
	bit #$40
	BNE Upd7
	clc
	lda ColumnTableLo
	adc #6
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%10111111
	sta ColumnUpdateFlags
	lda UpdateCtr
	beq UpdEnds
Upd7:
	bit #$80
	BNE UpdEnds
	clc
	lda ColumnTableLo
	adc #7
	jsr ColumnUpdate
	lda ColumnUpdateFlags
	and #%01111111
	sta ColumnUpdateFlags
	lda UpdateCtr
	beq UpdEnds
UpdEnds:
	rts

;---------------------------------------------------------------------
; Updates the colums with bit at 1
;
UpdateNametables:
	rep #$30	; All 16 bit
	; Vram port base address
	ldy #NAMETABLE1BASE
	sty VMADDL
	; Set increment to 32 words
	lda #%10000001 ; Addres increments by 32
	sta VMAINC
	;sta ColumnTableLo
	lda #COLUMUPDATENUMBER
	sta UpdateCtr ; When it gets to zero, stop updating
	lda ColumnUpdateFlags
	beq next8col
	lda #0000
	jsr HeighColumnsUpdate
	lda UpdateCtr
	bne next8col
	jmp endNameTableUpdate
next8col:
	lda ColumnUpdateFlags + 1
	beq second8col
	lda #$0008  ; Second group 16 bytes away
	sta ColumnTableLo
	jsr HeighColumnsUpdate
	lda UpdateCtr
	bne second8col
	jmp	endNameTableUpdate
second8col:
	lda ColumnUpdateFlags + 2
	beq third8col
	lda #$0010
	sta ColumnTableLo
	jsr HeighColumnsUpdate
	lda UpdateCtr
	bne third8col
	jmp	endNameTableUpdate
third8col:
	lda ColumnUpdateFlags + 3
	beq SecondBankUpdate
	lda #$0018
	sta ColumnTableLo
	jsr HeighColumnsUpdate
	lda UpdateCtr
	beq endNameTableUpdate
	;---------------------------------------------------------
	; Second bank
	;
SecondBankUpdate:
	ldy #NAMETABLE2BASE
	sty VMADDL
	lda #NAMETABLEINTERVAL  ; Second bank offset relative to the first bank
	sta ColumnTableLo
	lda ColumnUpdateFlags + 4
	beq B2next8col
	jsr HeighColumnsUpdate
	lda UpdateCtr
	beq endNameTableUpdate
B2next8col:
	lda ColumnUpdateFlags + 5
	beq B2second8col
	lda #NAMETABLEINTERVAL + 16
	sta ColumnTableLo
	jsr HeighColumnsUpdate
	lda UpdateCtr
	beq endNameTableUpdate
B2second8col:
	lda ColumnUpdateFlags + 6
	beq B2third8col
	lda #NAMETABLEINTERVAL + 32
	sta ColumnTableLo
	jsr HeighColumnsUpdate
	lda UpdateCtr
	beq endNameTableUpdate
B2third8col:
	lda ColumnUpdateFlags + 7
	beq endNameTableUpdate
	lda #NAMETABLEINTERVAL + 48
	sta ColumnTableLo
	jsr HeighColumnsUpdate
	;
endNameTableUpdate:
	rts
.ENDIF


;---------------------------------------------------------------------
; Updates a column of 30 tiles
; Uses the HDMA 4 to 7 to update the tables.
; The data is in WROM
; A is the index of the table in WROM
;
ColumnUpdate2:

	sep #$20	; A 8bits
	rep #$10	; X/Y = 16 bit
	
    stz MDMAEN	; Clear the DMA control register

	ldx #$1000
    stx DMA2A1SRCL	  ; Store the data offset into DMA source offset
	ldy #$0800        ; 4k
	sty DMA2SZL 	  ; Store the size of the data block
	lda #$00
    sta DMA2A1SRCBNK  ; Store the data bank of the source data

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

labs2:
	rts

.ENDS
