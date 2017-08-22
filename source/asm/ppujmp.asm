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
	; Add the routines for Pattern Table 0 and 1 from 0 to $2000 >> 3 == $0400
	rep #$10 ; X Y 16bits
	ldx #0000
InitPatternJumps:
	sep #$20 ; A 8bits
	lda #IemptyW ; This is assumed to be a ROM
	sta WRamPPUADDRJmps, X
	lda #ICHRDataR
	sta WRamPPUADDRJmps + 1, X
	inx
	inx
	rep #$20 ; A 16bits
	txa
	cmp #$0400
	bne InitPatternJumps
	;; ---------------------------------------------------------------------------
	; Add the routines for Name Table 1 from $2000 to $23C0
	ldx #0000
InitName1Jmps:
	sep #$20 ; A 8bits
	lda #INametableW
	sta WRamPPUADDRJmps + $0400, X
	lda #INametableR
	sta WRamPPUADDRJmps + $0401, X
	inx
	inx
	rep #$20 ; A 16bits
	txa
	cmp #$0078   ; $03C0 >> 3
	bne InitName1Jmps
	;; ---------------------------------------------------------------------------
	; Add the routines for Attribute Table 1 from $23C0 to $3000
	ldx #0000
InitAttr1Jmps:
	sep #$20 ; A 8bits
	lda #IAttrtableW
	sta WRamPPUADDRJmps + $0478, X
	lda #IAttrtableR
	sta WRamPPUADDRJmps + $0479, X
	inx
	inx
	rep #$20 ; A 16bits
	txa
	cmp #$0008   ; $0400 - $03C0 = $40     $40 >> 3 = 08
	bne InitAttr1Jmps
	;; ---------------------------------------------------------------------------
	; Copy the routines for NameTables2/Attr2 from the first nametable&attributes bank
	rep #$20 ; A 16bits
	ldx #0000
InitName234Jmps:
	lda WRamPPUADDRJmps + $0400, X  ; $0400 >> 2 = $0100
	sta WRamPPUADDRJmps + $0480, X  ; NameTables2/Attr2
	sta WRamPPUADDRJmps + $0500, X  ; NameTables3/Attr3
	sta WRamPPUADDRJmps + $0580, X  ; NameTables4/Attr4
	inx
	inx
	txa
	cmp #$0080   ; $0400 >> 3
	bne InitName234Jmps
	;; ---------------------------------------------------------------------------
	; Add the routines for the empty range from $3000 to $4000 (not counting the palette)
	ldx #0000
InitEmpyJmps:
	sep #$20 ; A 8bits
	lda #IemptyW
	sta WRamPPUADDRJmps + $0600, X  ; $3000 >> 3 = $0600
	lda #IemptyR
	sta WRamPPUADDRJmps + $0601, X
	inx
	inx
	rep #$20 ; A 16bits
	txa
	cmp #$0200   ; $1000 >> 3
	bne InitEmpyJmps
	;; ---------------------------------------------------------------------------
	; Add the palette routines on top of it
	ldx #0000
InitPaletteJmps:
	sep #$20 ; A 8bits
	lda #IpaletteW
	sta WRamPPUADDRJmps + $07E0, X  ; $3F00 >> 3 = $07E0
	lda #IpaletteR
	sta WRamPPUADDRJmps + $07E1, X
	inx
	inx
	rep #$20 ; A 16bits
	txa
	cmp #$0004   ; $0020 >> 3
	bne InitPaletteJmps
	;; ---------------------------
	plb ; Restore the Data bank
	rts

