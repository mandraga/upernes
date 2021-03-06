; This routine will take charge of basic sprite 0 emulation.
; It will be called in the NMI
.BANK 0
.ORG 0
.SECTION "Sprite0Init"

.DEFINE VBSTARTLINE  240
.DEFINE VBSTOPLINE     0

.DEFINE SPRITEOYADD    5

.DEFINE MAXSPR0Y     236

ReadVcount:
	sep #$20	; A 8bits
	; Low first
	lda STAT78
	; Latch the H and V counters
	lda HVLATCH
	lda OPVCT   ; Low Byte
	swa
	lda HVLATCH
	lda OPVCT
	and #$01    ; Mask the open bus shit
	swa
	rep #$20    ; A 16bits
	sta VCOUNTL
	rts

;------------------------------------------------------------------
;
; Initialises the IRQ for The Vblank flags but also NMI emulation
;
InitSprite0:
	php		;Preserve registers
	sep #$20	; A 8bits
	pha
	;
	; Check if the sprite 0 hit flag is enabled (BG or sprites enabled)
	;lda PPUcontrolreg2
	;and #%00011000         ; $18 Test if BG and sprites enabled
	;beq spr0Enabled        ; If Zero, quit
	;jmp EndInitSprite0
;spr0Enabled:
	;;--------------------------------------------------
	; Configure the timer on the nex encountered line.
	; It will set the IRQ flag on the line Y and therefore emulate the sprite 0 for basic usage
	;	
	lda SpriteMemoryBase + 1 ; Loads sprite 0 Y position
	rep #$20	; A 16bits
	and #$00FF
	clc
	adc #SPRITEOYADD
	sta IRQLineSPR0Y     ; Set the sprite 0 line

	lda #VBSTOPLINE      ; VBlank ends
	sta IRQLineStart
	lda IRQLineSPR0Y     ; Sprite 0 hits
	sta IRQLineSPR0Y
	lda #SOUNDEMULINE
	sta IRQLineSound
	lda #VBSTARTLINE 
	sta IRQLineVBlank    ; VBlank starts

	jsr ReadVcount
	rep #$20             ; A 16bits
	lda VCOUNTL
	; Is it greater or equal than VBlank line 240?
	cmp IRQLineVBlank
	bcs VblankStartPoint ; A >= 240

	lda IRQLineSPR0Y
	cmp IRQLineSound
	bcs SoundPoint       ; Sprite y >= Sound line
				         ; Sprite y < Sound line
	lda VCOUNTL
	; V >= Sprite0_Y
	cmp IRQLineSPR0Y
	bcs VblankEndPoint
	; V < Sprite0_Y
SpritePoint:
	sep #$20	         ; A 8bits
	lda IRQLineSPR0Y
	jmp ProgramVcounter
	
SoundPoint:
	lda VCOUNTL
	cmp IRQLineSound
	bcs VblankEndPoint
	sep #$20             ; A 8bits	
	lda IRQLineSound     ; next: sound
	jmp ProgramVcounter

VblankEndPoint:          ; Line 0
	sep #$20             ; A 8bits	
	lda IRQLineVBlank    ; next: VBlank
	jmp ProgramVcounter

VblankStartPoint:        ; > Line 240
	sep #$20	         ; A 8bits
	lda IRQLineStart     ; Next is line 0
	jmp ProgramVcounter

ProgramVcounter:
	sta VTIMEL
	stz VTIMEH

	;stz HTIMEL
	;stz HTIMEH
	;sei
	lda SNESNMITMP
	ora #%00100000  ; Enable V timer
	sta NMITIMEN
	sta SNESNMITMP	

	;;--------------------------------------------------
EndInitSprite0:
	sep #$20	; A 8bits
	pla
	plp		;Restore registers
	rts		;Return to caller


; Updates the sprite zero flag only by reading to the counter
updateSprite0Flag:
	;
	sep #$20    ; A 8bits
	lda #$00
	sta IRQLineSPR0Y
	lda SpriteMemoryBase + 1 ; sprite 0's Y
	clc
	adc #$05 ; Ack fixme
	sta IRQLineSPR0Y

	; Read the vertical line counter position
	jsr ReadVcount

	cmp IRQLineSPR0Y ; Compare to sprite 0's Y
	bcc Sprite0NotSet        ; If below, the sprite is not set
	;cmp #260                 ; If above 260, it is pre render
	;bcs Sprite0NotSet        ; Say it is pre render
	;lda OPHCT                ; Horizontal value
	;cmp SpriteMemoryBase + 0 ; Compare to sprite 0's X
	;bcc Sprite0NotSet        ; If below, the sprite is not set
	; Sprite0 is set
	sep #$20    ; A 8bits
	lda #SPRITE0FLGAG_VALUE
	sta SPRITE0FLAG
	rts
Sprite0NotSet:
	sep #$20    ; A 8bits
	stz SPRITE0FLAG
	rts

;-------------------------------------------------------------------
; Sprite 0 and Vblank update routine
; It triggers when:
;
; vblank starts line 240 <- Set in NMI
; vblank ends on line 0
; Sprite0 Hit line if enabled
; Custom line where to proceed to APU emulation (sound registers updated), say line 150
;

; Clears the flag and sets the nex interrupt on line 0
ConfigureIRQForLine0:
	lda HVIRQFLG    ; Vertical timer IRQ flag, cleared here
	stz TMPVTIMEL   
	stz VTIMEL      ; The next interrupt will be on line 0
	stz VTIMEH
	rts

; Called by the Native IRQ handler
VCountHandler:
	sep #$20		; A 8b
	pha

	;lda SNESNMITMP
	;and #%00100000  ; Check the V count interrupt enabled flag
	;bne continueWithIRQ2
	;jmp NoVcountIntEnabled

	;---------------------------------------------------------
	; Check the line of the interrupt
	;jsr ReadVcount
	rep #$20		; A 16bits
	;lda IRQLineSPR0Y
	;cmp #MAXSPR0Y   ; Check if sprite 0 Y is past 236
	;bcs NoSprite0OnScreen
	
	; Check if Sprite 0 line is above Sound Line
	lda IRQLineSPR0Y
	cmp IRQLineSound
	bcc CaseSprYInfSound  ; SprY < SoundLine
	cmp IRQLineVBlank
	bcs CaseSpr0Hidden  ; SprY >= VBSTARTLINE (sprite not visible)
	;---------------------------------------------------------
	; Case SoundLine <= Sprite0Y < VBSTARTLINE
	lda VCOUNTL
	cmp IRQLineSound
	bcc PrepareSoundIRQFromVblanEnd
	cmp IRQLineSPR0Y
	bcc PrepareSpr0IRQFromSoundLine
	jmp PrepareVblankIRQFromSPr0  	; VBlank
	;---------------------------------------------------------
CaseSpr0Hidden:
	lda VCOUNTL
	cmp IRQLineSound
	bcc PrepareSoundIRQFromVblanEnd
	jmp PrepareVblankIRQ  	; VBlank
	;---------------------------------------------------------
CaseSprYInfSound:
	lda VCOUNTL
	cmp IRQLineSPR0Y     ; VCOUNT < Spr0Y?
	bcc PrepareSpr0IRQ   ; Yes
	cmp IRQLineSound
	bcc PrepareSoundIRQFromSpr0
	jmp PrepareVblankIRQ  	; VBlank
	;---------------------------------------------------------
PrepareSpr0IRQFromSoundLine:
	rep #$20		   ; A 16bits
	; Call the update routine
	jsr SoundAPURegUpdate	
	; Convert the sprite buffer
	;jsr SprConv
PrepareSpr0IRQ:
	; Line 0
	; Set the counter for the sprite zero hit
	sep #$20		; A 8b
	lda SpriteMemoryBase + 1 ; Loads sprite 0 Y position
	clc
	adc #SPRITEOYADD
	; The next interrupt will be on the sprite zero Y position (0 to 255)
	sta TMPVTIMEL
	sta IRQLineSPR0Y
	; Set the Sprite zero and Vblank flags to 0
	sep #$20		   ; A 8b
	stz PPUStatus      ; PPUSTATUS updated
	lda IRQLineSPR0Y   ; Load the Byte
	jmp SetIRQCounter
	;---------------------------------------------------------
	; When the sound IRQ if after VBlank
PrepareSoundIRQFromVblanEnd:
	sep #$20		   ; A 8b
	stz PPUStatus      ; PPUSTATUS updated
	rep #$20		   ; A 16bits
	lda IRQLineSound   ; Load Sound Emu line IRQ trigger
	sta TMPVTIMEL
	jmp SetIRQCounter
	;---------------------------------------------------------
	; This is were the sprite zero hits	
PrepareSoundIRQFromSpr0:
	sep #$20		   ; A 8bits
	; Check if sprite Zero is enabled
	lda PPUcontrolreg2
	and #%00011000
	cmp #%00011000     ; $18 Test if BG and sprites enabled
	bne SetSoundIRQ    ; If Zero, wait for the Sound interrupt
Sprite0Hits:
	; Set the Sprite 0 flag bit to one
	sep #$20		   ; A 8bits
	lda #SPRITE0FLGAG_VALUE	
	ora PPUStatus
	sta PPUStatus      ; PPUSTATUS updated
	;--------------------
SetSoundIRQ:
	rep #$20		   ; A 16bits
	lda IRQLineSound   ;  Load Sound Emu line IRQ trigger
	sta TMPVTIMEL
	jmp SetIRQCounter
	;---------------------------------------------------------
	; Sound registers update
PrepareVblankIRQ:
SoundLine:
	; Set the counter for the line where the APU register update to SPC700 is called
	rep #$20		   ; A 16bits
	; Call the update routine
	jsr SoundAPURegUpdate
	; Convert the sprite buffer
	;jsr SprConv
	lda IRQLineVBlank  ;  Load Vblank start as Vcount IRQ trigger
	sta TMPVTIMEL
	jmp SetIRQCounter
PrepareVblankIRQFromSPr0:
	sep #$20		   ; A 8bits
	lda #SPRITE0FLGAG_VALUE	
	ora PPUStatus
	sta PPUStatus      ; PPUSTATUS updated
	; Set the counter for the line where the APU register update to SPC700 is called
	rep #$20		   ; A 16bits
	lda IRQLineVBlank  ;  Load Vblank start as Vcount IRQ trigger
	sta TMPVTIMEL
	jmp SetIRQCounter

;VblankStarts:
;	; Set the counter for the VBlank end                 Moved to NMI interrupt
;	rep #$20		; A 16bits
;	lda IRQLineVBlank
;	sta TMPVTIMEL
;	sta VTIMEL      ; The next interrupt will be on the line 0, at the end of vblank
;	; Set the Vblank flag to one
;	sep #$20		; A 8b
;	lda PPUStatus
;	ora #$80
;	sta PPUStatus ; PPUSTATUS updated
;	jmp VlineCheckEnds

SetIRQCounter:
	sta VTIMEL
	stz VTIMEH
	;stz HCOUNTERL
	;stz HCOUNTERH
	;
VlineCheckEnds:
	sep #$20		; A 8b
	pla
	rts  ; To the nes IRQ

;-------------------------------------------------------------------
; This converts sprites in 8x16 size;
;	
Convert8x16:
	php
	pha
	phy
	phx
	NATIVE
	sep #$20    ; A 8b
	lda PPUcontrolreg1
	and #$0020      ; Test if sprites size is 8x16?
	beq SprAre8x8
		BREAK2
	;-------------------------------
	; 8x16 format conversion
	rep #$10    ; X Y 16b
	lda #$0000  ; X = 0
	tax
	;sep #$20    ; A 8b
Sprconversionloop:	
	lda SpriteMemoryBase,X	    ; Y
	pha
	lda SpriteMemoryBase + 3,X  ; X
	sta SpriteMemoryBase,X
	;
	lda SpriteMemoryBase + 2,X 	; Attr
	pha
	;
	lda SpriteMemoryBase + 1,X 	; Name
	and #$01
	beq CHRBank0
	lda SpriteMemoryBase + 1,X 	; Name
	;lsr
	sta SpriteMemoryBase + 2,X 
	jmp SprAttr
CHRBank0:
	lda SpriteMemoryBase + 1,X 	; Name	
	sta SpriteMemoryBase + 2,X

SprAttr:
	pla
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	ora #$01
	sta SpriteMemoryBase + 3,X 
	; Y
	pla
	sta SpriteMemoryBase + 1,X 
	; Increment
	txa
	clc
	adc #04
	and #$00FF
	tax
	bne Sprconversionloop	; loop if not zero	(passed 256)	
	; Finished
	jmp SprConvFinished

SprAre8x8:
	;-------------------------------
	; 8x8 format conversion
	rep #$10    ; X Y 16b
	lda #$0000  ; X = 0
	tax
	;sep #$20    ; A 8b
Sprconversionloop8x8:	
	lda SpriteMemoryBase,X	    ; Y
	pha
	lda SpriteMemoryBase + 3,X  ; X
	sta SpriteMemoryBase,X
	;
	lda SpriteMemoryBase + 2,X 	; Attr
	pha
	;
	lda SpriteMemoryBase + 1,X 	; Name
	;and #$01
	;beq CHRBank0
	lda SpriteMemoryBase + 1,X 	; Name
	;lsr
	sta SpriteMemoryBase + 2,X 
	jmp SprAttr8x8
CHRBank08x8:
	lda SpriteMemoryBase + 1,X 	; Name
	sec
	ror
	sta SpriteMemoryBase + 2,X 	
SprAttr8x8:
	pla
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 3,X 
	; Y
	pla
	sta SpriteMemoryBase + 1,X 
	; Increment
	txa
	clc
	adc #04
	and #$00FF
	tax
	bne Sprconversionloop8x8	; loop if not zero	(passed 256)	
	; Finished
	
SprConvFinished:
	EMULATION
	plx
	ply
	pla
	plp
	rts
	
	

;;------------------------------------------------------------------------------
;; Sprite buffer conversion routine
;;
SprConv:
	php
	pha
	phy
	phx
	NATIVE
	rep #$30    ; All 16b
	and #$0000  ;  X = 0
	tax
EzSprconversionloopIRQ:	
	lda SpriteMemoryBaseTmp,X	  ; Read Y, direct page  *(DP + $00 + X) and tile index
	sta SpriteMemoryBase + 1,X    ; Store it
	lda SpriteMemoryBaseTmp + 4,X	  ; Read Y, and tile index
	sta SpriteMemoryBase + 5,X    ; Store it
	lda SpriteMemoryBaseTmp + 8,X	  ; Read Y, and tile index
	sta SpriteMemoryBase + 9,X    ; Store it
	lda SpriteMemoryBaseTmp + 12,X	  ; Read Y, and tile index
	sta SpriteMemoryBase + 13,X    ; Store it
	lda SpriteMemoryBaseTmp + 16,X	  
	sta SpriteMemoryBase + 17,X    ; Store it
	lda SpriteMemoryBaseTmp + 20,X	  
	sta SpriteMemoryBase + 21,X    ; Store it
	lda SpriteMemoryBaseTmp + 24,X	  
	sta SpriteMemoryBase + 25,X    ; Store it
	lda SpriteMemoryBaseTmp + 28,X	  
	sta SpriteMemoryBase + 29,X    ; Store it
	; Increment
	txa
	clc
	adc #32
	and #$00FF
	tax
	bne EzSprconversionloopIRQ	; loop if not zero	(passed 256)

	; Conversion
	sep #$30    ; All 8b
	;;;;ldy SpriteMemoryAddress ; Origin of the data OAMADDR not in use here 256 bytes
	; It uses a direct page indexed address, meaning it reads from the 256Bytes page with X as index.	
	ldx #$00
sprconversionloopeIRQ:	
	lda SpriteMemoryBaseTmp + 2,X	  ; Read the flags (direct page indexed)
	txy
	tax              ; Should be in rom to use Y on it
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 3,X    ; Store them
	lda SpriteMemoryBaseTmp + 3,X	  ; Read X
	sta SpriteMemoryBase + 0,X    ; Store it
	;-------------------------------------------------------------
	lda SpriteMemoryBaseTmp + 2 + 4,X	  ; Read the flags (direct page indexed)
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 7,X    ; Store them
	lda SpriteMemoryBaseTmp + 3 + 4,X	  ; Read X
	sta SpriteMemoryBase + 4,X    ; Store it
	;-------------------------------------------------------------
	lda SpriteMemoryBaseTmp + 2 + 8,X	  ; Read the flags (direct page indexed)
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 11,X   ; Store them
	lda SpriteMemoryBaseTmp + 3 + 8,X	  ; Read X
	sta SpriteMemoryBase + 8,X    ; Store it
	;-------------------------------------------------------------
	lda SpriteMemoryBaseTmp + 2 + 12,X	  ; Read the flags (direct page indexed)
	txy
	tax
	lda WRamSpriteFlagConvLI,X    ; Acc converted from NES vhoxxxpp to SNES vhoopppN
	tyx
	sta SpriteMemoryBase + 15,X   ; Store them
	lda SpriteMemoryBaseTmp + 3 + 12,X	  ; Read X
	sta SpriteMemoryBase + 12,X   ; Store it
	;-------------------------------------------------------------
	; Increment
	txa
	clc
	adc #16
	tax
	beq EndSprconversionloopIRQ	; loop if not zero	(passed 256)	
	jmp sprconversionloopeIRQ
EndSprconversionloopIRQ:
	EMULATION
	plx
	ply
	pla
	plp
	rts
	
.ENDS

