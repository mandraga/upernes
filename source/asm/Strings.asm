;------------------------------------------------------------------------
;-  Written by: Neviksti
;-     If you use my code, please share your creations with me
;-     as I am always curious :)
;-
;-  Note: These routines were originally from examples released
;-     by Grog. I fixed up some stuff to make his code work on the
;-     real SNES and then added a bunch of features.
;-
;------------------------------------------------------------------------
;- Changes applied for inclusion in the nes rom recompiler.
;------------------------------------------------------------------------

; .include "var.inc"

.define BASETILE $80

; SetCursorPos  y, x 
.MACRO SetCursorPos
	ldx #32*\1 + \2
	stx Cursor
.ENDM


.MACRO PrintString
	LDX #STRlabel\@
	JSR PrintF
	BRA END_STRlabel\@
STRlabel\@:
	.DB \1, 0
END_STRlabel\@:
.ENDM

; here's a macro for printing a number (a byte)
;
; ex:  PrintNum $2103 	;print value of reg $2103
;      PrintNum #9	;print 9
.MACRO PrintNum
	lda \1
	jsr PrintInt8_noload
.ENDM

.MACRO PrintHexNum
	lda \1
	jsr PrintHex8_noload
.ENDM


.BANK 0 SLOT 0
.SECTION "Print_Handler"

	;============================================================================
	;; Routine to copy text tile data to BG3 vram
textcpy:
	rep #$10		; X/Y = 16 bit
	sep #$20		; mem/A = 8 bit
	; Vram increments 1 by 1 after VMDATAH write
	lda #$80
	sta VMAINC
	; Tile map is at $B000 (CHR data is at $3800 ($1C00 word @))
	lda #$00
	sta VMADDL		; Word address (= $5800word for $B000byte)
	lda #$58
	sta VMADDH
	; Counters
	ldy #$0400		; Total number of tiles 32x32, 1024 tiles for a screen
	ldx #$0000
BG3strloop:
	lda TextBuffer.w,X	; Ascii tile number
	sta VMDATAL		; Flip tile & palette selection: 0
	lda #$01		; Second set of 256 tiles
	sta VMDATAH		; tile attributes high byte
	inx
	dey
	bne BG3strloop
	rts
	;============================================================================

	;============================================================================
	;; Routine to clear the TextBuffer
textclr:
	rep #$30		;A/Mem=16bits, X/Y=16bits
	pha
	phx
	phy
	rep #$10		; X/Y = 16 bit
	sep #$20		; mem/A = 8 bit
	; Counters
	ldy #$0400		; Total number of tiles/chars for a screen  (32x32 = 1024)
	ldx #$0000
	lda #$FF
strclrloop:
	sta TextBuffer.w,X	; Ascii char
	inx
	dey
	bne strclrloop	
	rep #$30		; A/Mem=16bits, X/Y=16bits
	ply
	plx
	pla
	rts
	;============================================================================

;============================================================================

; Print -- Print an ASCII character to the BG3 buffer
;	  which needs to be copied into VRAM in the NMI handler.
;         Of course, an 8x8 ASCII tile set must
;         be loaded and the VRAM pointer set ahead of time
;  In: A -- ASCII code to print
;  Out: none
;  Modifies: P
Print:
	PHX
	; expectations: A/Mem=8bit, X/Y=16bit - necessary to add this in order to avoid assembly
	; of 16bit instrucitons instead of 8bit
	rep #$10	        ; A/mem=8bit, X/Y=16bit
	sep #$20

	; ASCII CHR is at $3800 = $2000 + 6 x 1024 first tile is at 128+256. Offset 256 in the high byte set by the
	; textclr toutine and 128 is set here as the ORA $80.
	ORA #$80
	LDX Cursor
	STA TextBuffer, X	; Output character
	INX
	STX Cursor

	PLX
	RTS

; PrintF -- Print a Formatted, NULL terminated string to Stdout
;  In:   X -- points to format string
;      Y -- points to parameter buffer
;  Out: none
;  Modifies: none
; Notes:
;     Supported Format characters:
;       %s -- sub-string (reads 16-bit pointer from Y data)
;       %d -- 16-bit Integer (reads 16-bit data from Y data)
;       %b -- 8-bit Integer (reads 8-bit data from Y data)
;       %x -- 8-bit hex Integer (reads 8-bit data from Y data)
;       %% -- normal %
;       \n -- Newline
;       \t -- Tab
;       \b -- Page break
;       \\ -- normal slash
;     String pointers all refer to current Data Bank (DB)
PrintF:         ;Assumes 8b mem, 16b index
	PHP
	PHA
	PHX
	PHY

	rep #$10	        ; A/mem=8bit, X/Y=16bit
	sep #$20

PrintFLoop:
	LDA $0000,X             ; Read next format string character
	BEQ PrintFDone          ; Check for NULL terminator
	INX                     ; Increment input pointer
	CMP #'%'
	BEQ PrintFFormat        ; Handle Format character
	CMP #'\'
	BEQ PrintFControl       ; Handle Control character
NormalPrint:
	JSR Print               ; Print the character normally
	BRA PrintFLoop

PrintFDone:
	PLY
	PLX
	PLA
	PLP
	RTS

PrintFControl:
	LDA $0000,X             ; Read control character
	BEQ PrintFDone          ; Check for NULL terminator
	INX                     ; Increment input pointer
	CMP #'n'
_cn:
	BNE _ct
	rep #$30                ; 16b mem, 16b X
	LDA Cursor		; Get Current position
	CLC
	ADC #$0020		; move to the next line
	AND #$FFE0
	STA Cursor		; Save new position
	sep #$20		; 8b mem, 16b X
	BRA PrintFLoop
_ct:
	CMP #'t'
	BNE _cb
	rep #$30                ; 16b mem, 16b X
	LDA Cursor		; Get Current position
	CLC
	ADC #$0008		; move to the next tab
	AND #$FFF8
	STA Cursor		; Save new position
	sep #$20		; 8b mem, 16b X
	BRA PrintFLoop
_cb:	CMP #'b'
	BNE _defaultC
	STZ Cursor		; Page break
	STZ Cursor+1
	BRA NormalPrint
_defaultC:
	LDA #'\'                ; Normal \
	BRA NormalPrint

PrintFFormat:
	LDA $0000,X             ; Read format character
	BEQ PrintFDone          ; Check for NULL terminator
	INX                     ; Increment input pointer
_sf:
	CMP #'s'
	BNE _df
	PHX                     ; Preserve current format string pointer
	LDX 0,Y                 ; Load sub-string pointer
	INY
	INY
	JSR PrintF              ; Call PrintF recursively with sub-string
	PLX
	BRA PrintFLoop
_df:
	CMP #'d'
	BNE _bf
	JSR PrintInt16          ; Print 16-bit Integer
	BRA PrintFLoop
_bf:	
	CMP #'b'
	BNE _xf
	JSR PrintInt8           ; Print 8-bit Integer
	BRA PrintFLoop
_xf:	
	CMP #'x'
	BNE _defaultF
	JSR PrintHex8           ; Print 8-bit Hex Integer
	JMP PrintFLoop
_defaultF:
	LDA #'%'
	jmp NormalPrint

; PrintInt16 -- Read a 16-bit value pointed to by Y and print it to stdout
;  In:  Y -- Points to integer in current data bank
;  Out: Y=Y+2
;  Modifies: P
; Notes: Uses Print to output ASCII to stdout
PrintInt16:     ;Assume 8b mem, 16b index
	LDA #$00
	PHA			;Push $00
	LDA $0000,Y
	STA $4204		;DIVC.l 
	LDA $0001,Y
	STA $4205		;DIVC.h  ... DIVC = [Y]
	INY
	INY
DivLoop:
	LDA #$0A	
	STA $4206		;DIVB = 10 --- division starts here (need to wait 16 cycles)
	NOP			; 2 cycles
	NOP			; 2 cycles
	NOP			; 2 cycles
	PHA			; 3 cycles
	PLA			; 4 cycles
	LDA #'0'		; 2 cycles
	CLC			; 2 cycles
	ADC $4216		; A = '0' + DIVC % DIVB
	PHA			; Push character
	LDA $4214		; Result.l -> DIVC.l
	STA $4204
	BEQ _Low_0
	LDA $4215		; Result.h -> DIVC.h
	STA $4205
	BRA DivLoop
_Low_0: 
	LDA $4215		; Result.h -> DIVC.h
	STA $4205
	BEQ IntPrintLoop	; if ((Result.l==$00) and (Result.h==$00)) then we're done, so print
	BRA DivLoop
IntPrintLoop:		        ; until we get to the end of the string... 
	PLA			; keep pulling characters and printing them
	BEQ _EndOfInt		
	JSR Print
	BRA IntPrintLoop
_EndOfInt: 
	RTS

; PrintInt8 -- Read an 8-bit value pointed to by Y and print it to stdout
;  In:  Y -- Points to integer in current data bank
;  Out: Y=Y+1
;  Modifies: P
; Notes: Uses Print to output ASCII to stdout
PrintInt8:                     ; Assume 8b mem, 16b index
	LDA $0000,Y
	INY
PrintInt8_noload:
	STA $4204
	LDA #$00
	STA $4205
	PHA
	BRA DivLoop

PrintInt16_noload:              ; Assume 8b mem, 16b index
	LDA #$00
	PHA			; Push $00
	STX $4204		; DIVC = X
	JSR DivLoop

; PrintHex8 -- Read an 8-bit value pointed to by Y and print it in hex to scr
;  In:  Y -- Points to integer in current data bank
;  Out: Y=Y+1
;  Modifies: P
; Notes: Uses Print to output ASCII to stdout
PrintHex8:     ;Assume 8b mem, 16b index
	lda $0000,Y
	iny
PrintHex8_noload:
	pha
	lsr A
	lsr A
	lsr A
	lsr A
	jsr PrintHexNibble
	pla
	and #$0F
	jsr PrintHexNibble
	rts	

PrintHexNibble:                 ; Assume 8b mem, 16b index
	cmp #$0A
	bcs _nletter
	clc
	adc #'0'
	jsr Print
	rts

_nletter: 	
	clc
	adc #'A'-10		
	jsr Print
	rts

.ENDS
