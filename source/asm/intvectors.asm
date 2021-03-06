
; Interrupt vector tables
.BANK 0 SLOT 0
.ORG    $7FE4		        ; = Native Mode = snes
.DW     NativeEmptyHandler  ; COP
.DW     NativeEmptyHandler  ; BRK
.DW     NativeEmptyHandler  ; ABORT
.DW     NativeEmptyNMI      ; NMI
.DW     $0000		        ; (Unused)
.DW     NativeVCountHandler ; EmptyHandler	; IRQ, never used in native mode. The native mode is only used for the IO callbacks.

.ORG    $7FF4				; = Emulation Mode = nes
.DW     EmptyHandler		; COP
.DW     $0000				; (Unused)
.DW     EmptyHandler		; ABORT
.DW     EmptyHandler	    ; NMI
.DW     Reset				; RESET            The entire program starts here and the calls NESReset
.DW     NESIRQBRKHandler	; NESIRQBRK IRQ/BRK

; ============================================

;.BASE $80 ; Fast ROM

.BANK 0 SLOT 0
.org 0
.SECTION "EmptyVectors" SEMIFREE


NESIRQBRKHandler:
	sei
	nop
	BREAK
	TOIOBANK
	pha
	lda HVIRQFLG    ; Vertical timer IRQ flag, cleared here
	jsr ReadVcount
	lda VCOUNTL
	cmp #VBSTARTLINE
	bcc LineBeforeNMI
	pla
	jmp NESNMIHandler
LineBeforeNMI:
	jsr VCountHandler
QuitIRQ:
	pla
	POPBANK
	jml $7E0862   ; This address ocntains an RTI
	;rti
	;jml NESIRQBRK ; Call the patched NMI vector code on the PRG bank. This is a 16 bit instruction called from emulation


NESNMIHandler:    ; Called in the timer IRQ... Otherwise it will cause bank problems between emulation and native rti

	; Fast ROM execution
	jml FastHandler
FastHandler:
	
	; If the nes nmi is enables, call it
	pha
	;-----------------------------------
	; Vblank bit update
	sep #$20		; A 8b
	lda PPUStatus
	; Set the Vblank flag to one
	ora #$80
	sta PPUStatus ; PPUSTATUS updated
	;-----------------------------------
	jsr ConfigureIRQForLine0
	;-----------------------------------
	; Id NMI disabled, return
	lda NESNMIENABLED
	beq QuitNMI
	;lda PPUcontrolreg1  ; Puts the 7th bit in the n flag
	;and #$80
	;beq QuitNMI
	lda #$01
	sta NMI_occurred
	pla
	; Read the vertical line counter position
	;jsr ReadHcout
	;BREAK ; something is wrong if removed
	;-------------------------------------------------------------------
	php		;Preserve registers
	pha
	phx
	phy
	;NATIVE
	clc			; native 65816 mode
	xce
	
.IFDEF COUNTCALLS
	; Reset the routine counters
	ldx #00
ClrShit:
	stz IOCallCOUNTER, X
	inx
	txa
	cmp #64
	bne ClrShit
.ENDIF	
	
	jsr UpdatePalettes
	jsr UpdateSpritesDMA
	;jsr UpdateBackgrounds       ; Copy changed bytes to the VRAMdddfffgcxcvsfgggcxxxcv
	
	;-------------------------------------------------------------------
	;EMULATION
	sec			; 6502 mulation mode
	xce
	; Restore registers
	ply
	plx
	pla
	plp		;Restore registers
	;plb

	; Read the vertical line counter position
	;jsr ReadHcout
	;BREAK ; something is wrong if removed

	;BREAK2
	POPBANK
	jml NESNMI ; Call the patched NMI vector code on the PRG bank. This is a 16 bit instruction called form emulation
QuitNMI:
	pla
	POPBANK
	; No interrupt can occur in bank 0, it is designed like this
	; But the code is in bank1 and the rti must go to bank $81
	;rti
	;; Go to an RTI in ram
	jml $7E0862   ; This address contains an RTI

	;;Prepare the stack for an RTL instead of RTI
	; pla
	; sta AccNmi    ; Pop and save Acc
	; pla
	; sta NmiStatus ; Pop the rti values from the stack
	; pla
	; sta NmiRetLo
	; pla
	; sta NmiRetHi
	; Add bank
	; lda #$81      ; Bank 1 in fast rom mode
	;;lda #$01      ; Bank 1
	; pha
	; lda NmiRetHi
	; pha
	; lda NmiRetLo
	; pha
	; Restore A and status flag
	; lda AccNmi
	; pha
	; Restore status
	; lda NmiStatus
	; pha
	; plp ; Restore Status
	; pla ; Restore Acc
	; nop
	; rtl
;;; put this on vblank




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
	nop
	nop
	nop
	nop
	nop
	jml $7E0862   ; This address ocntains an RTI
	;rti

EmptyHandler:
	sei ; Disable interrupts at start ot it will flood the stack
	pha
	lda $0918   ; use this to set a breakpoint
	nop
	nop
	pla
	jml $7E0862   ; This address ocntains an RTI
    ;rti

;----------------------------------------------------------------
; Same handlers but RTI pops also the bank
NativeEmptyHandler:
	sei ; Disable interrupts at start ot it will flood the stack
	;pha
	;php         ; Push status
	;sep #$20    ; Acc/Mem 8bits
	;lda $0918   ; use this to set a breakpoint
	;lda $0919   ; use this to set a breakpoint
	nop
	nop
	;plp
	;pla
    rti

NativeEmptyNMI:
	sei ; Disable interrupts at start
    pha
    ;php         ; Push status
	;sep #$20    ; Acc/Mem 8bits
	;lda $0918   ; use this to set a breakpoint
	;lda $0919   ; use this to set a breakpoint
	lda NMIFLAG  ; Clear NMI Flag
	nop
    ;plp
	pla
    rti

;----------------------------------------------------------------
; The Vcount IRQ could trigger while in emulation or native
;
NativeVCountHandler:
	sei ; Disable interrupts at start or it will flood the stack
	pha
	php ; Only to be able to pop A
	jml FastVcountHandler
FastVcountHandler:
	TOIOBANK
	jsr VCountHandler
	POPBANK
	plp ; Only to be able to pop A
	pla
	;cli                  <- RTI does it
	;plp  ; Restore flags <- RTI does it
	rti

.ENDS

