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
	
continueWithIRQ2:
	;---------------------------------------------------------
	; Check the line of the interrupt
	;jsr ReadVcount
	rep #$20		; A 16bits
	;lda IRQLineSPR0Y
	;cmp #MAXSPR0Y   ; Check if sprite 0 Y is past 236
	;bcs NoSprite0OnScreen
	; Test sprite 0 line, it should be below the sound IRQ line
	lda VCOUNTL
	cmp IRQLineSPR0Y ; SPR0LINE
	bcs testSoundIRQLine ; A >= Spr0
;NoSprite0OnScreen:
	; Test a second time in case sound line < sprite line
	cmp IRQLineSound
	bcs SoundLine   ; A >= Sound Emu Line
	jmp VBlankEnds       ; A <  Spr0
	; Is it sound emulation time?
testSoundIRQLine:
	cmp IRQLineSound
	bcs SoundLine   ; A >= Sound Emu Line
	;-----------------------------------
	; A < Sound Emu Line && A >= Spr0Y
Sprite0Hits:
	sep #$20		; A 8bits
	; Check if sprite Zero is enabled
	lda PPUcontrolreg2
	and #%00011000         ; $18 Test if BG and sprites enabled
	bne spr0Sequence       
	jmp PrepareSoundIRQ    ; If Zero, wait for the Sound interrupt
spr0Sequence:
	; Check if the sprite 0 is not off screen
	lda IRQLineSPR0Y ; Load the Byte
	cmp #MAXSPR0Y ; Check if it is past 236
	bcs SoundLine ; if Spr0Y > 236 wait for Sound Emulaiton IRQ
	; Set the counter for the line where the APU register update to SPC700 is called
	rep #$20		; A 16bits
	lda IRQLineSound    ; The next interrupt will be on the sound update line from the 'ini' file
	sta TMPVTIMEL
	sta VTIMEL
	; Set the Sprite 0 flag bit to one
	sep #$20		; A 8bits
	lda #SPRITE0FLGAG_VALUE	
	ora PPUStatus
	sta PPUStatus   ; PPUSTATUS updated
PrepareSoundIRQ:
	rep #$20		; A 16bits
	lda IRQLineSound      ;  Load Sound Emu line IRQ trigger
	sta TMPVTIMEL
	sta VTIMEL      ; The next interrupt will be on the sound update line from the 'ini' file
	jmp VlineCheckEnds
SoundLine:
	; Set the counter for the line where the APU register update to SPC700 is called
	rep #$20		; A 16bits
	
	lda IRQLineVBlank  ;  Load Vblank start as Vcount IRQ trigger
	sta TMPVTIMEL
	sta VTIMEL      ; The next interrupt will be on the sound update line from the 'ini' file
	; Call the update routine
	jsr SoundAPURegUpdate
	jmp VlineCheckEnds
;VblankStarts:
;	; Set the counter for the VBlank end                 Moved to NMI interrupt
;	rep #$20		; A 16bits
;	lda IRQLineVBlank
;	sta TMPVTIMEL
;	sta VTIMEL      ; The next interrupt will be on the line 0, at the end of vblank
;	; Set the Vblank flag to one
;	sep #$20		; A 8b
	lda PPUStatus
;	ora #$80
;	sta PPUStatus ; PPUSTATUS updated
;	jmp VlineCheckEnds
VBlankEnds:
	; Set the counter for the sprite zero hit
	sep #$20		; A 8b
	lda SpriteMemoryBase + 1 ; Loads sprite 0 Y position
	clc
	adc #SPRITEOYADD
	; The next interrupt will be on the sprite zero Y position (0 to 255)
	sta TMPVTIMEL
	sta IRQLineSPR0Y
	cmp IRQLineSound      ; Compare to the sound interrupt line
	bcc useSpr0Line ; If below then it will be the next IRQ
	lda IRQLineSound      ; else it is the sound line
useSpr0Line:
	sta VTIMEL
	stz VTIMEH
	;stz HCOUNTERL
	;stz HCOUNTERH
	;
	; Set the Sprite zero and Vblank flags to 0
	sep #$20		; A 8b
	stz PPUStatus   ; PPUSTATUS updated
HCountFlagCleared:
VlineCheckEnds:
	sep #$20		; A 8b
	pla
	rts  ; To the nes IRQ

.ENDS


	
