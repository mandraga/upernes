; This routine will take charge of basic sprite 0 emulation.
; It will be called in the NMI
.BANK 0
.ORG 0
.SECTION "Sprite0Init"

;.DEFINE VBSTARTLINE  237  ; Should be 240 but gives an interrupt conflict
.DEFINE VBSTOPLINE     0

.DEFINE SPRITEOYADD    5

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


; USELESS for now
; This
InitSprite0:
	php		;Preserve registers
	pha
	sep #$20	; A 8bits
	;
	; Check if the sprite 0 hit flag is enabled (BG or sprites enabled)
	lda PPUcontrolreg2
	and #%00011000         ; $18 Test if BG and sprites enabled
	beq spr0Enabled        ; If Zero, quit
	jmp EndInitSprite0
spr0Enabled:
	;;--------------------------------------------------
	; Configure the timer on the nex encountered line.
	; It will set the IRQ flag on the line Y and therefore emulate the sprite 0 for basic usage
	;	
	lda SpriteMemoryBase + 1 ; Loads sprite 0 Y position
	clc
	adc #SPRITEOYADD
	rep #$20	; A 16bits
	and #$00FF
	sta TMPVCOUNTL

	lda #VBSTOPLINE  ; VBlank ends
	sta SPR0Y0
	lda TMPVCOUNTL   ; Sprite 0 hits
	sta SPR0Y1
	lda #SOUNDEMULINE
	sta SPR0Y2
	;lda #VBSTARTLINE 
	;sta SPR0Y3       ; VBlank starts

	jsr ReadVcount
	rep #$20    ; A 16bits
	lda VCOUNTL
	; Is it greater or equal than VBlank line 240?
	;cmp SPR0Y3
	;bcs VblankEndPoint ; A >= 240
	; V >= Sprite0_Y
	cmp TMPVCOUNTL
	bcs VblankEndPoint
	; V < Sprite0_Y
SpritePoint:
	sep #$20	; A 8bits
	lda TMPVCOUNTL
	jmp ProgramVcounter

VblankEndPoint:
	sep #$20	; A 8bits	
	lda #VBSTOPLINE ; VBlank
	jmp ProgramVcounter

;VblankStartPoint:
;	sep #$20	; A 8bits	
;	lda #VBSTARTLINE ; VBlank
;	jmp ProgramVcounter

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
	pla
	plp		;Restore registers
	rts		;Return to caller



; Updates the sprite zero flag only by reading to the counter
updateSprite0Flag:
	;
	sep #$20    ; A 8bits
	lda #$00
	sta TMPVCOUNTH
	lda SpriteMemoryBase + 1 ; sprite 0's Y
	clc
	adc #$05 ; Ack fixme
	sta TMPVCOUNTL

	; Read the vertical line counter position
	jsr ReadVcount

	cmp TMPVCOUNTL ; Compare to sprite 0's Y
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

; Called by the Native IRQ handler
VCountHandler:
	sep #$20		; A 8b
	pha
	lda HVIRQFLG    ; Vertical timer IRQ flag, cleared here
	and #$80        ; Get rid of the open bus value (MDR in bsnes emulator's source code)
	beq HCountFlagCleared ; If not set, return to the interrupt routine to call the nes vector
	lda SNESNMITMP
	and #%00100000  ; Check the V count interrupt enabled flag
	beq NoVcountIntEnabled
	;---------------------------------------------------------
	; Check the line of the interrupt
	jsr ReadVcount
	rep #$20		; A 16bits
	lda VCOUNTL
	;lda TMPVTIMEL
	; Is it line 0?
	cmp SPR0Y1 ; VBSTOPLINE
	bcs testSoundIRQLine ; A >= Spr0
	jmp VBlankEnds       ; A <  Spr0
	; Is it line 240?
	;cmp SPR0Y3
	;beq VblankStarts
	; Is it sound emulation time?
testSoundIRQLine:
	cmp SPR0Y2
	bcs SoundLine   ; A >= Sound Emu Line
	;-----------------------------------
	; A < Sound Emu Line && A >= Spr0Y
Sprite0Hits:
	; Check if the sprite 0 is not off screen
	sep #$20		; A 8bits
	lda SPR0Y1 ; Load the Byte
	cmp #236   ; Checl if it is past 236
	bcs SoundLine ; if Spr0Y > 236 wait for Sound Emulaiton IRQ
	; Set the counter for the line where the APU register update to SPC700 is called
	rep #$20		; A 16bits
	lda SPR0Y2    ; The next interrupt will be on the sound update line from the 'ini' file
	sta TMPVTIMEL
	sta VTIMEL
	; Set the Sprite 0 flag bit to one
	sep #$20		; A 8bits
	lda #SPRITE0FLGAG_VALUE	
	ora PPUStatus
	sta PPUStatus   ; PPUSTATUS updated
	rep #$20		; A 16bits
	lda SPR0Y2      ;  Load Sound Emu line IRQ trigger
	sta TMPVTIMEL
	sta VTIMEL      ; The next interrupt will be on the sound update line from the 'ini' file
	jmp VlineCheckEnds
SoundLine:
	; Set the counter for the line where the APU register update to SPC700 is called
	rep #$20		; A 16bits
	lda SPR0Y0      ;  Load Vblank stop as Vcount IRQ trigger
	sta TMPVTIMEL
	sta VTIMEL      ; The next interrupt will be on the sound update line from the 'ini' file
	; Call the update routine
	jsr SoundAPURegUpdate
	jmp VlineCheckEnds
;VblankStarts:
;	; Set the counter for the VBlank end                 Moved to NMI interrupt
;	rep #$20		; A 16bits
;	lda SPR0Y3
;	sta TMPVTIMEL
;	sta VTIMEL      ; The next interrupt will be on the line 0, at the end of vblank
;	; Set the Sprite 0 flag bit to one
;	sep #$20		; A 8b
;	lda PPUStatus
;	; Set the Vblank flag to one
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
	sta SPR0Y1
	sta VTIMEL
	stz VTIMEH
	;stz HCOUNTERL
	;stz HCOUNTERH
	;
	; Set the Sprite zero and Vblank flags to 0
	sep #$20		; A 8b
	stz PPUStatus   ; PPUSTATUS updated
HCountFlagCleared:
	jmp VlineCheckEnds
NoVcountIntEnabled:
	; It should not be here
	; Clear the flag in the register
	;lda NMIFLAG ; ????
	sep #$20		; A 8b
	lda HVIRQFLG
	stz VTIMEL
	stz VTIMEH	
	lda SNESNMITMP
	and #$81 ; Disable the timers
	sta NMITIMEN
	sta SNESNMITMP
VlineCheckEnds:
	sep #$20		; A 8b
	pla
	rts  ; To the nes IRQ

.ENDS


	
