
;----------------------------------------------------------------------------
; Clears th address in A
; In: 16bit address @ $
;     Y size
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
.MACRO CLRMEM
	ldx #\2
	dex
clrmem\@:
	stz \1,X
	dex
	bpl clrmem\@
.ENDM

.MACRO CLRMEM16
	ldx #\2
	dex
clrmem16\@:
	stz \1,X
	stz \1,X
	dex
	bpl clrmem16\@
.ENDM	

	
.BANK 0 SLOT 0
.ORG 0
.SECTION "InitSNES" FORCE

;----------------------------------------------------------------------------
; Clears the ram as specified in the snes official manual
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
ClearRegisters:
        pha
        phx
	php

	sep #$30			; All 8bit
	lda #$8F		; Forced blank
	sta $2100
	CLRMEM  $2101 $03
	;; 2104 OAM data
	CLRMEM  $2105 $08
	CLRMEM16 $210D $08	; 16bit 2 writes words
	lda #$80
	sta $2115
	stz $2116
	stz $2117
	;; $2118 VRAM data
	;; $2119 VRAM data
	stz $211A
	stz $211B
	sta $01
	sta $211B
	CLRMEM16 $211C $02
	stz $211E
	lda #$01
	sta $211E
	CLRMEM16 $211F $02
	stz $2121
	;; $2122 CG data
	CLRMEM  $2123 $0C
	lda #$30
	sta $2130
	stz $2131
	lda #$E0
	sta $2132
	stz $2133
	stz $4200
	lda #$FF
	sta $4201
	CLRMEM  $4202 $0C
	plp
	plx
	pla
	rts

;----------------------------------------------------------------------------
; ClearVRAM -- Sets every byte of VRAM to zero
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
ClearVRAM:
   pha
   phx
   php

   rep #$10          ; mem/A = 8 bit, X/Y = 16 bit
   sep #$20

   lda #$80
   sta $2115         ;Set VRAM port to word access
   ldx #$1809
   stx $4300         ;Set DMA mode to fixed source, WORD to $2118/9
   ldx #$0000
   stx $2116         ;Set VRAM port address to $0000
   stx $0000         ;Set $00:0000 to $0000 (assumes scratchpad ram)
   stx $4302         ;Set source address to $xx:0000
   lda #$00
   sta $4304         ;Set source bank to $00
   ldx #$FFFF
   stx $4305         ;Set transfer size to 64k-1 bytes
   lda #$01
   sta $420B         ;Initiate transfer
   stz $2119         ;clear the last byte of the VRAM
   plp
   plx
   pla
   rts

;----------------------------------------------------------------------------
; ClearCGRam -- Reset all palette colors to zero
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
ClearCGRam:
   phx
   php
   rep #$10             ; mem/A = 8 bit, X/Y = 16 bit
   sep #$20
   stz $2121
   ldx #$0100
ClearPaletteLoop:
   stz $2122
   dex
   bne ClearPaletteLoop
   plp
   plx
   rts

.ENDS
