
	;; Ascii strings are displayed on the background 3 layer.
	;; They are used when stoping on an unidentified indirect jump.
	;; The then unknown indirect address is printed on the BG3.

; .include "cartridge.inc"
.include "snesregisters.inc"

.BANK 0
.ORG 0
.SECTION "BG3"

;; -----------------------------------------------
;; 
;; Prints strings, ints and hexadecimal values on BG3
;; 
;; -----------------------------------------------
init_BG3_and_textbuffer:
	rep #$10	        ; X/Y=16bit
	sep #$20		; A/mem=8bit

	; Set the text start to the second line
	SetCursorPos  1, 1
 	; Clear the 1K text buffer
	jsr textclr

	; Load the 2KB ASCII table CHR data at VRAM $1000W ($2000B)
	;; -----------------------------------------------
	rep #$10	        ; X/Y=16bit
	sep #$20		; A/mem=8bit
	LoadBlockToVRAM ASCIITiles, $1000, $0800	;128 tiles * (2bit color = 2 planes) --> 2048 bytes

	; BG3 CHR address
	; Ascii CHR data is constitued of 128 tiles at $2000B
	;; -----------------------------------------------
	lda #$01		; 0x2000 -> second 4kWord=8k segment (512 tiles, the asci table starts at offset 0x0000: tile 384/0x180
	sta BG34NBA

	; BG3 palette
	;; -----------------------------------------------
	sep #$30		; mem/A = 8 bit, X/Y = 8 bit
	; CG ram address to 40 where the BG3 palete is stored
	lda #$40
	sta CGADD
	ldx #$00
	phb
	lda #:BG3palette 	; Bank of the palette
	pha
	plb			; A -> Datat Bank Register
palconv3:
	lda BG3palette.w,X
        asl                     ; word index
        tay
        lda nes2snespalette,Y
        ; Send it to CG ram
        sta CGDATA
        iny
        lda nes2snespalette,Y
        sta CGDATA
        inx
        txa
        cmp #$20
        bne palconv3
        plb
	
	; BG3 Tilemap fixed addresses
        ;; -----------------------------------------------
        ; BG3 tilemap (nes name table + attibute tables)
        ; Set tile map address (Addr >> 11) << 2
	; $1800 >> 11 << 2= $0C
        lda #$0C                ; (1k word segment number << 2, 11b << 2 = $0C)
        sta BG3SC
	
	rts


;; -----------------------------------------------
;;
;; Prints the indirect jump information of an unknown
;; indirect jump address.
;;
;; -----------------------------------------------
	;; All 16bit here
	;; Acc is the address of the indirect address
	;; X   is the indirect address
	;;     the jump opcode address in the original rom is not given it could be multiple for one indirect address address
endindjmp:
	;; Print error msg
	;; "Unknown indirect jump \"$pc@ jmp ($06)\" to @"
	rep #$30
	SetCursorPos  1, 1
	swa
	tay
	PrintString "Unknown indirect jump:\n jmp ($%x "  ; higher byte of A
	swa
	tay
	PrintString "%x) to @ $"			; lower byte of A
	txa
	swa
	tay
	PrintString "%x"
	swa
	tay
	PrintString "%x"
	;; Enable BG3 FIXME should be enabled
	lda #$04
	sta TM
        lda #$0C                ; (1k word segment number << 2, 11b << 2 = $0C)
        sta BG3SC
	;; Send all the string buffer to the BG3 VRAM name table
	jsr textcpy
	;; Loop unitl reset
infloopindjmp:
	jsr infloopindjmp

.ENDS
