
; Interrupt vector tables
.BANK 0 SLOT 0
.ORG    $7FE4			; = Native Mode = snes
.DW     EmptyHandler	; COP
.DW     EmptyHandler	; BRK
.DW     EmptyHandler	; ABORT
.DW     EmptyVBlank		; NMI
.DW     $0000			; (Unused)
.DW     EmptyHandler	; IRQ, never used in native mode. The native mode is only used for the IO callbacks.

.ORG    $7FF4				; = Emulation Mode = nes
.DW     EmptyHandler		; COP
.DW     $0000				; (Unused)
.DW     EmptyHandler		; ABORT
.DW     DMAUpdateHandler	; NMI
.DW     Reset				; RESET            The entire program starts here and the calls NESReset
.DW     NESIRQBRKHandler	; NESIRQBRK IRQ/BRK

; ============================================

.MACRO NATIVE
	sei         ; disable interrupts, because we do not want any interrupt in the native mode
	clc			; native 65816 mode
	xce
.ENDM

.MACRO EMULATION
	sec			; 6502 emulation mode
	xce
	; Any call to sta lda sti will restore the status register and hence interrupt mask bit
.ENDM

; ============================================

.BANK 0 SLOT 0
.org 0
.SECTION "EmptyVectors" SEMIFREE

DMAUpdateHandler:
	; V blank NMI
	;jsr InitSprite0

	; Read the V value
	;sep #$20    ; A 8bits
	; Low first
	;lda STAT78
	; Latch the H and V counters
	;lda HVLATCH
	;lda #$00
	;lda OPVCT   ; Low Byte
	;swa
	;lda HVLATCH
	;lda OPVCT
	;and #$01    ; Mask the open bus shit
	;swa
	;rep #$20    ; A 16bits
	;sta TMPVCOUNTL + 2
	
	;BREAK2 ; something is wrong if removed
	jsr UpdatePalettes
	jsr UpdateBackgrounds       ; Copy changed bytes to the VRAMdddfffgcxcvsfgggcxxxcv
	; If the nes nmi is enables, call it
	;pha
	;lda NESNMIENABLED
	;beq QuitNMI
	;pla
	;BREAK2
	;lda #$01
	;sta NESNMIENABLED
	jml NESNMI ; Call the patched NMI vector code on the PRG bank. This is a 16 bit instruction called form emulation
QuitNMI:
	pla
	sta AccNmi
	pla
	sta NmiStatus
	pla
	sta NmiRetLo
	pla
	sta NmiRetHi
	lda #$01      ; Bank
	pha
	lda NmiRetHi
	pha
	lda NmiRetLo
	pha
	lda AccNmi
	rtl
;;; put this on vblank

NESIRQBRKHandler:
	jmp NESIRQBRK ; Call the patched NMI vector code on the PRG bank. This is a 16 bit instruction called from emulation

; Called by the Native IRQ handler
VCountHandler:
	sei ; Disable interrupts at start ot it will flood the stack
	php
	sep #$20		; A 8b
	pha
	lda SNESNMITMP
	and #%00100000  ; Check the V count interrupt enabled flag
	beq NoVcountIntEnabled
	lda HVTIME      ; Vertical timer IRQ flag, cleared here
	and #$80        ; Get rid of the open bus value (MDR in bsnes emulator's source code)
	beq HCountFlagCleared ; If not set, do nothing
	; Check the line of the interrupt
	rep #$20		; A 16bits

	lda HCOUNTERL
	cmp #$0105      ; Is it line 261?
	beq VBlankEnds
	lda #$0105
	sta VTIMEL
	sta HCOUNTERL    ; The next interrupt will be on the line 261, at the end of vblank
	sep #$20		; A 8b
	; Sprite 0 hit
	; Set the Sprite 0 flag bit to one
	lda #SPRITE0FLGAG_VALUE
	sta SPRITE0FLAG
	jmp Sprite0HitEnds
VBlankEnds:
	sep #$20		; A 8b
	; Set the sprite zero flag to 0
	stz SPRITE0FLAG
	; Set the counter for the sprite zero hit
	lda SpriteMemoryBase + 1 ; Loads sprite 0 Y position
	sta VTIMEL
	sta HCOUNTERL
	stz VTIMEH
	stz HCOUNTERH   ; The next interrupt will be on the sprite zero Y position (0 to 255)
	;
NoVcountIntEnabled:
HCountFlagCleared:
Sprite0HitEnds:
	sep #$20		; A 8b
	pla
	plp  ; A length restored to whatever value it was: 8 or 16bits
	cli
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
		nop
		nop
		pla
        rti

EmptyVBlank:
	rep #30
    pha
    php          ; Push status
	sep #$20     ; Acc/Mem 8bits
	lda NMIFLAG ; Clear NMI Flag
    plp
    pla
    rti

	
.ENDS

;-------------------------------------------------------------------------------------
; Routine called through the ram code
.BANK 0 SLOT 0
.ORG    $7000
.SECTION "Entry" SEMIFREE
RamCodeDestPoint:
	stx XiLevel1
	cmp #READROUTINESINDEX
	bcc StoreRoutine ; Acc < index
	cmp #INDJMPINDEX
	bcs IndJumpRoutine ;  Acc >= index
ReadRoutine:
	asl
	tax ; Get the routine address in the table
	; Things pushed on the stack:
	; - PC Hi
	; - PC Lo
	; - Status P
	; - Acc
	;
	; Get the PC, and get the routine code
	pla
	;sta AccIt
	pla
	sta Status
	pla
	sta RetLow
	pla
	sta RetHi
	;lda AccIt
	jsr (BRKRoutinesTable,X) ; Jump to the routine for the selected address
	ldx XiLevel1
	sta AccIt
	; restore the bank
	lda #$01
	pha
	; Restore the return address
	lda RetHi
	pha
	lda RetLow
	pha
	lda Status
	pha
	lda AccIt
	;BREAK
	;nop
	plp
	ora #$00 ; Update the flags
	rtl ; Return long

StoreRoutine:
	asl
	tax ; Get the routine address in the table
	; Things pushed on the stack:
	; - PC Hi
	; - PC Lo
	; - Status P
	; - Acc
	;
	; Get the PC, and get the routine code
	pla
	sta AccIt
	pla
	sta Status
	pla
	sta RetLow
	pla
	sta RetHi
	lda AccIt    ; Could be an sta
	;ldx XiLevel1 ; Could be an stx
	jsr (BRKRoutinesTable,X) ; Jump to the routine for the selected address
	ldx XiLevel1
	; restore the bank
	lda #$01
	pha
	; Restore the return address
	lda RetHi
	pha
	lda RetLow
	pha
	lda Status
	pha
	lda AccIt
	;BREAK
	plp
	rtl ; Return long

	; Remove the data of the jsr call from the stack and jump to the routine
IndJumpRoutine:
	asl
	;sta JumpAddress
	tax ; Get the routine address in the table
	pla ; Acc
	sta AccIt
	pla ; Status
	sta Status
	pla ; RetLow
	pla ; RetHi
	lda Status
	pha
	lda AccIt
	plp
	jmp (BRKRoutinesTable,X) ; Jump to the routine for the selected address, X needs to be restored in the routine

.ENDS

