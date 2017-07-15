;-----------------------------------------------------
; Creates a table of routine @ in WRAM
; This table is used to get rid of PPU address test to
; get to the proper routine.
; I simplifies @ increments.
;

;.DEFINE WRamBank                $7F
;.DEFINE WRamPPUADDRJmps         $4000       ; Jump tables for all the PPU routines (PPU @ space size / 16 in word @ = $400 word@ = $800 bytes 2kBytes)
;.DEFINE PPUADDRJmps             $400

; The PPU memory space is $4000 = 16KB, we need to make a correspondance between the PPUADDRESS and the proper routine.
; Because of pallette routines, the granulrity must be of 16 bytes. $4000 >> 4 = $400 but we will store write and read
; routines. Therefore 4 bytes per 16 addresses.
; For a PPUADDRESS we do @ >> 2 to get the Write @ and (@ >> 2) + 2 to get the read @.
; 4K are needed to store the data. We have plenty in WRAM.
;
PrecalculateJumpTable:
	; Got to bank 7F
	phb
	lda #WRamBank
	pha
	plb
	;; ---------------------------------------------------------------------------
	; Add the routines for Pattern Table 0 and 1 from 0 to $2000 >> 2 == $0800
	rep #$30 ; All 16bits
	ldx #0000
InitPatternJumps:
	lda #emptyW ; This is assumed to be a ROM
	sta WRamPPUADDRJmps, X
	lda #CHRDataR
	sta WRamPPUADDRJmps + 2, X
	inx
	inx
	inx
	inx
	txa
	cmp #$0800 
	bne InitPatternJumps
	;; ---------------------------------------------------------------------------
	; Add the routines for Name Table 1 from $2000 to $23C0
	ldx #0000
InitName1Jmps:
	lda #NametableW
	sta WRamPPUADDRJmps + $0800, X
	lda #NametableR
	sta WRamPPUADDRJmps + $0802, X
	inx
	inx
	inx
	inx
	txa
	cmp #$00F0   ; $03C0 >> 2
	bne InitName1Jmps
	;; ---------------------------------------------------------------------------
	; Add the routines for Attribute Table 1 from $23C0 to $3000
	ldx #0000
InitAttr1Jmps:
	lda #AttrtableW
	sta WRamPPUADDRJmps + $08F0, X
	lda #AttrtableR
	sta WRamPPUADDRJmps + $08F2, X
	inx
	inx
	inx
	inx
	txa
	cmp #$0010   ; $0400 - $03C0 = $40     $40 >> 2 = 10
	bne InitAttr1Jmps
	;; ---------------------------------------------------------------------------
	; Copy the routines for NameTables2/Attr2 from the first nametable&attributes bank
	ldx #0000
InitName234Jmps:
	lda WRamPPUADDRJmps + $0800, X  ; $0400 >> 2 = $0100
	sta WRamPPUADDRJmps + $0900, X  ; NameTables2/Attr2
	sta WRamPPUADDRJmps + $0A00, X  ; NameTables3/Attr3
	sta WRamPPUADDRJmps + $0B00, X  ; NameTables4/Attr4
	lda WRamPPUADDRJmps + $0802, X
	sta WRamPPUADDRJmps + $0902, X
	sta WRamPPUADDRJmps + $0A02, X
	sta WRamPPUADDRJmps + $0B02, X
	inx
	inx
	inx
	inx
	txa
	cmp #$0100   ; $0400 >> 2
	bne InitName234Jmps
	;; ---------------------------------------------------------------------------
	; Add the routines for the empty range from $3000 to $4000 (not counting the palette)
	ldx #0000
InitEmpyJmps:
	lda #emptyW
	sta WRamPPUADDRJmps + $0C00, X  ; $3000 >> 2 = $0C00
	lda #emptyR
	sta WRamPPUADDRJmps + $0C02, X
	inx
	inx
	inx
	inx
	txa
	cmp #$0400   ; $1000 >> 2
	bne InitEmpyJmps
	;; ---------------------------------------------------------------------------
	; Add the palette routines on top of it
	ldx #0000
InitPaletteJmps:
	lda #paletteW
	sta WRamPPUADDRJmps + $0FC0, X  ; $3F00 >> 2 = $0FC0
	lda #paletteR
	sta WRamPPUADDRJmps + $0FC2, X
	inx
	inx
	inx
	inx
	txa
	cmp #$0008   ; $0020 >> 2
	bne InitPaletteJmps
	;; ---------------------------
	plb ; Restore the Data bank
	rts

