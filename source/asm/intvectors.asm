
; Interrupt vector tables
.BANK 0 SLOT 0
.ORG    $7FE4			; = Native Mode
.DW     EmptyHandler		; COP
.DW     EmptyHandler		; BRK
.DW     EmptyHandler		; ABORT
.DW     EmptyVBlank		; NMI
.DW     $0000			; (Unused)
.DW     DebugHandler		; IRQ

.ORG    $7FF4			; = Emulation Mode
.DW     EmptyHandler		; COP
.DW     $0000			; (Unused)
.DW     EmptyHandler		; ABORT
.DW     NESNonMaskableInterrupt	; NMI
.DW     Reset			; RESET            The entire program starts here and the calls NESReset
.DW     NESIRQBRK		; IRQ/BRK

; ============================================

.BANK 0 SLOT 0
.org 0
.SECTION "EmptyVectors" SEMIFREE

	;; Used in Supersleuth to stop somewhere using a brk instruction and setting break points on the nops
DebugHandler:
	nop
	nop
	nop
	nop
	nop
	pha
	lda #$E077    ; use this to set a breakpoint
	pla
	nop
	nop
	nop
	nop
	nop
	rti

EmptyHandler:
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
