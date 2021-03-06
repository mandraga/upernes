
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

	sep #$30		; All 8bit
	lda #$8F		; Forced blank
	sta $2100
	CLRMEM  $2101 $03
	;; 2104 OAM data
	CLRMEM  $2105 $08
	CLRMEM16 $210D $08	; 16bit 2 writes words
	lda #$80
	sta VMAINC
	stz VMADDL
	stz VMADDH
	;; $2118 VRAM data
	;; $2119 VRAM data
	; Mode 7 shit
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
	stz $4202 ; Multiplier L
	stz $4203 ; Multiplier H
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

;----------------------------------------------------------------------------
; ClearBGBuffer -- Clears the background emulation buffer
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
ClearBGBuffer:
   phx
   php
   rep #$30             ; mem/A, X/Y = 16 bit
   ldx #$1000           ; 8k
   lda #$0000
ClearBGmem:
   dex
   dex
   sta NametableBaseBank1,X
   bne ClearBGmem
   plp
   plx
   rts
 
;----------------------------------------------------------------------------
; ClearPPUEmuBuffer -- Clears the buffers used to store the read values
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
ClearPPUEmuBuffer:
   phx
   php
   rep #$30             ; mem/A, X/Y = 16 bit
   ; Attributes
   ldx #AttributebufferSz
   lda #$00
ClearAttrmem:
   dex
   dex
   sta Attributebuffer1,X
   sta Attributebuffer2,X
   bne ClearAttrmem
   ; Palette
   ldx #PalettebufferSz
   lda #$00
ClearPalmem:
   dex
   sta Palettebuffer,X
   bne ClearPalmem
   ;
   plp
   plx
   rts
   

;----------------------------------------------------------------------------
; ClearOAMHposMSB -- Set the hight OAM bits to 00 (small sprites, Hpos MSB to 0)
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
ClearOAMHposMSB:
   phx
   php
   sep #$30		; mem/A = 8 bit, X/Y = 8 bit   
   ; Sprite Size and H position msb
   lda #$00
   sta OAMADDL  ; Word address
   lda #$01
   sta OAMADDH
   ldx #$20     ; 16 words
   lda #$00
ClearOAMH:
   sta OAMDATA
   dex
   bne ClearOAMH
   plp
   plx
   rts

;----------------------------------------------------------------------------
; ClearWRAM - Clear bank $7F (64KB) and $7E (56KB)
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
ClearWRAM:
   BREAK
   phx
   php
   phb
   ; $7F
   sep #$20             ; A 8bits
   lda #$7F
   pha
   plb
   rep #$30             ; mem/A, X/Y = 16 bit
   ldx #$0000           ; 64k
   lda #$0000
Clear7F:
   dex
   dex
   sta $7F0000,X
   bne Clear7F
   ; $7E
   sep #$20             ; A 8bits
   lda #$7E
   pha
   plb
   rep #$30             ; mem/A, X/Y = 16 bit
   ldx #$C000          ; 56k
   lda #$0000
Clear7E:
   dex
   dex
   sta $7E2000,X          ; It begins at 8K
   bne Clear7E
   plb
   plp
   plx
   rts
   
.ENDS
