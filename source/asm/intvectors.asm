
; Interrupt vector tables
.BANK 0 SLOT 0
.ORG    $7FE4			; = Native Mode = snes
.DW     EmptyHandler	; COP
.DW     EmptyHandler	; BRK
.DW     EmptyHandler	; ABORT
.DW     EmptyVBlank		; NMI
.DW     $0000			; (Unused)
.DW     VCountHandler	; IRQ, Why is it always in native mode???

.ORG    $7FF4				; = Emulation Mode = nes
.DW     EmptyHandler		; COP
.DW     $0000				; (Unused)
.DW     EmptyHandler		; ABORT
.DW     DMAUpdateHandler	; NMI
.DW     Reset				; RESET            The entire program starts here and the calls NESReset
.DW     NESIRQBRK			; NESIRQBRK IRQ/BRK

; ============================================

.BANK 0 SLOT 0
.org 0
.SECTION "EmptyVectors" SEMIFREE

DMAUpdateHandler:
	BREAK
	; V blank NMI
	jsr InitSprite0
	jsr UpdateBackgrounds       ; Copy changed bytes to the VRAMdddfffgcxcvsfgggcxxxcv
	jmp NESNonMaskableInterrupt ; Call the recompiled NMI vector

VCountHandler
	; Check ifit is the V counter interruption
	BREAK2
	php
	pha
	sei
	lda SNESNMITMP
	and #%00100000  ; Check the V count interrupt enabled flag
	beq NoVcountIntEnabled
	lda HVTIME      ; Vertical timer IRQ flag, cleared here
	and #$80        ; Get rid of the open bus value (MDR in bsnes emulator's source code)
	beq Spr0Cleared ; If not set, do nothing
	; Else set the Sprite 0 flag bit to one
	lda #SPRITE0FLGAG_VALUE
	sta SPRITE0FLAG
	lda SNESNMITMP
	and #%11011111  ; Disable V timer
	sta NMITIMEN
	sta SNESNMITMP
NoVcountIntEnabled:
Spr0Cleared:
	pla
	plp
	rti

	;; Used in Supersleuth to stop somewhere using a brk instruction and setting break points on the nops
DebugHandler:
	nop
	nop
	nop
	nop
	nop
	pha
	lda $0916    ; use this to set a breakpoint
	pla
	lda HVTIME   ; Vertical timer IRQ flag
	and #$80     ; Get rid of the open bus value (the MDR)
	nop
	nop
	nop
	nop
	nop
	rti

EmptyHandler:
		pha
		lda $0917    ; use this to set a breakpoint
		pla
        rti

EmptyVBlank:
	rep #30
        pha
        php			; Push status

	sep #$20		; Acc/Mem 8bits
        lda $4210               ; Clear NMI Flag

        plp
        pla
        rti

.ENDS
