;; Each instruction accessing an io port or backup ram must
;; be emulated.
;; It is all the instructions with Absolute or Indirect addressing.
;; Indirect addressing is the difficult case because the
;; address is not known at compilation time.

;; A for accumulator operation, M for memory operation
;; --------------------------------------------------------------------
; Indirect and Absolute addressing:
;			Absolute		AbsX	ABSY	IndirectXY
; A	adc r		   Replacement		Y	Y	Y
; A	sbc r			-		Y	Y	Y
; A	and r			-		Y	Y	Y
; A	ora r			-		Y	Y	Y
; A	eor r			-		Y	Y	Y
; A	cmp r			-		Y	Y	Y
; A	lda r <- !!!	ldaioportroutine	Y	Y	Y
; A	sta w <- !!!	staioportroutine	Y	Y	Y
;
; Absolute replaced by:	 "sta Acc, lda emulation, sta $tmp, lda Acc, cmp/adc/ora... $tmp"
; Indexed replaced by:	 "pha, native, PEI @,X, pla, sta addr, lda IO, emulation, pla"
;
;; -------------------------------------------------------------------- 
; Absolute addressing:
;
; ???? These instructions may be never used to access the io ports because the 65C02 writes twice
; the result, or has a problem somewhere with this kind of instructions.
; And because io ports auto increment when accessed it can bring problems.
;
;			Absolute		 Absolute indexedX    indexedY
; M	asl r->w	   Replacement				Y	N
; M	dec r->w		-				-	-
; M	inc r->w		-				-	-
; M	lsr r->w		-				-	-
; M	rol r->w		-				-	-
; M	ror r->w		-				-	-
;
; Replaced by:	       "pha, sta IO, native, op A, emulation, lda IO, pla"
; Indexed replaced by: "pha, native, PEI @,X, pla, sta addr, sta IO, op A, lda IO, emulation, pla"
;
;; -------------------------------------------------------------------- 
; X	ldx r							N	Y
; Y	ldy r							Y	N
; Replaced by "pha, lda @ call, tax or tay, pla"
;
; X	stx w							N	Y
; Y	sty w							Y	N
; Replaced by "pha, txa or tya, sta @ call, pla"
;
; X	cpx r							N	N
; Y	cpy r							N	N
; Replaced by "pha, lda IOport emulation, sta $tmp, txa or tya, cmp $tmp, pla"
;
;; -------------------------------------------------------------------- 
; Nes registers:
; 	RW PPU Control Register 1
; 	RW PPU Control Register 2
; 	R  PPU Status Register
; 	 W Sprite Memory Address
; 	RW Sprite Memory Data
; 	 W Screen Scroll Offsets
; 	 W PPU Memory Address
; 	RW PPU Memory Data
; 	 W Sound registers	
; 	 W DMA Access to the Sprite Memory
; 	RW Sound Channel Switch/Sound Status
; 	RW Joystick1 + Strobe   Write not emulated!
; 	R  Joystick2 + Strobe
;; --------------------------------------------------------------------
; Nes Save ram:
; 	$6000 - $8000 8KB
; Any access replaced by:
;	set native 65816 mode
;	opcode $7Daddress if absolute addressing
;	return to 6502 mode
; The save ram must be 32KB because last 8KB are used

.include "cartridge.inc"
.include "var.inc"

.BANK 0 SLOT 0
.ORG 0
.SECTION "IOinstrEmulation" SEMIFREE

;; --------------------------------------------------------------------
;; ldaioportroutine
; Only used on:
; 	RW PPU Control Register 1
; 	RW PPU Control Register 2
; 	R  PPU Status Register
; 	RW Sprite Memory Data
; 	RW PPU Memory Data <- difficult because it points on different aeras/behaviours depending on the address
; 	RW Sound Channel Switch/Sound Status
; 	RW Joystick1 + Strobe   Write not emulated!
; 	R  Joystick2 + Strobe
;;
ldaioportroutine:
	sty YiLeveL1
	;; Native mode
	NATIVE
	TOIOBANK
.IFDEF COUNTCALLS
	rep #$20
	inc IOCallArray, X
	sep #$20
.ENDIF
	;; --------------------------------------------------------
	;; Go to the IO address read routine
	;; Jump to the routine
	rep #$10
	jmp (IORroutinestable,X)
RetIOroutineR:
	POPBANK
	;; Emulation mode
	EMULATION
	ldy YiLeveL1
	;; Done
	rts


;; --------------------------------------------------------------------
;; staioportroutine
; 	RW PPU Control Register 1
; 	RW PPU Control Register 2
; 	 W Sprite Memory Address
; 	RW Sprite Memory Data
; 	 W Screen Scroll Offsets
; 	 W PPU Memory Address
; 	RW PPU Memory Data <- difficult because it points on different aeras/behaviours depending on the address
; 	 W Sound registers
; 	 W DMA Access to the Sprite Memory
; 	RW Sound Channel Switch/Sound Status
;;
staioportroutine:
	sty YiLeveL1
	;; Native mode
	NATIVE
	TOIOBANK
.IFDEF COUNTCALLS
	rep #$20
	inc IOCallArray, X
	sep #$20
.ENDIF
	;; --------------------------------------------------------
	;; Go to the IO address write routine
	;; Jump to the routine
	rep #$10
	jmp (IOWroutinestable,X)
RetIOroutineW:
	POPBANK
	;; Emulation mode
	EMULATION
	ldy YiLeveL1
	;; Done
	rts


; ###############################################################
	
;; Converts a 16bits io port address in IOAddr to an io port index in 0-30
;; Changes A
;; Output in A and X
ConvertIOaddr2Index:
	sep #$30
	lda IOAddr + 1
	ror A
	ror A
	ror A
	and #$08		; Equals 8 if hbyte = 40
	clc
	adc IOAddr
	tax
	rts

NULLpointerError:
	;; Write a text using asccii tiles
	
	rts

StackOverflowError:
	;; Write a text using asccii tiles
	
	rts

.ENDS

