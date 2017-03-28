
	;; Initialises the snes and loads the CHR data in VRAM and WRAM

.include "var.inc"
.include "cartridge.inc"

.include "rom.asm"
.include "romprg.asm"
.include "CHR.asm"
.include "PaletteUpdate.asm"
.include "DMABGUpdate.asm"
.include "sprite0.asm"
.include "intvectors.asm"
.include "LoadGraphics.asm"
.include "zeromem.asm"
.include "Strings.asm"
.include "print.asm"

.BANK 0
.ORG 0
.SECTION "Reset"

Reset:
	sei			; disable interrupts
	clc			; native mode
	xce

	rep #$38	; all regs 16 bits, decimal mode off

	; Direct page $00
	pea $0000
	pld

	;----------------------------------------------------------------------------
	; Clear the sram from 8KB down to 2KB (mirrored on the nes but used as variables & buffers on the snes)s
	ldx #$1800      ; 6k 
eraseSnesRamLoop:
	dex
	dex
	sta $0800,X
	bne eraseSnesRamLoop
	;----------------------------------------------------------------------------
	; Clears the 2KB of ram (even the stack so this is not a routine)
	; Uses the pattern FFFFFFFF00000000 like fceux
	ldx #$0800      ; 2k
eraseNesRamLoop:
	dex
	dex
	lda #$FFFF
	sta $0000,X
	dex
	dex
	sta $0000,X
	dex
	dex
	lda #$0000
	sta $0000,X
	dex
	dex
	sta $0000,X
	bne eraseNesRamLoop
		
	; Stack pointer initial value
	ldx #STACKTOP
	txs

	; Clear memory
	jsr ClearBGBuffer
	jsr ClearPPUEmuBuffer
	jsr ClearRegisters
	jsr ClearVRAM
	jsr ClearCGRam
	; Sprite init
	;; -----------------------------------------------
	jsr ClearOAMHposMSB
	sep #$30		; All 8bit
	lda #$01        ; 8kW
	sta OBSEL       ; Sprite base address for object data at 8kw (1 * 8k), OBJ size 8/16

	; Load the APU simulator into the SPC700
	;; -----------------------------------------------
	;; TODO

	; Video mode settings
	;; -----------------------------------------------
	sep #$20		; All 8bit
	; Resolution: NMI occurs at 240
	lda #%00000100
	sta SETINI
	; Mode 0 background
	lda #$00
	sta BGMODE

	; Initialises the memory and Backgound 3 for text
	; display
	;; -----------------------------------------------
	jsr init_BG3_and_textbuffer
		
	; Load the nes cartridge's CHR data in the snes VRAM
	; 4KB
	;; -----------------------------------------------
	rep #$30		; All 16bits
	jsr NesBackgroundCHRtoVram
		
	; Tilemap fixed addresses
	;; -----------------------------------------------
	; BG1 tilemap (fusion of the "nes name table + attibute tables")
	; Set tile map address (Addr >> 11) << 2
	sep #$30		;  All 8bits
	lda #$70		; (1k word segment $7000 / $400)=$1C << 2
	sta BG1SC       ;  the two lower bits are the screen size and are set to 00 : only one screen

	; Initialises the nes port emulation vars
	;; -----------------------------------------------
	stz PPUmemaddrB
	inc PPUmemaddrB   ; The first adressed PPU adresse byte is the most significant byte.
	stz StarPPUStatus
	inc StarPPUStatus ; Boot state in vblank flag of PPUSTATUS
	stz PPUmemaddrL
	stz PPUmemaddrH
	stz CurScrolRegister
	stz PPUcontrolreg2
    stz	SpriteMemoryAddress
	stz attributeaddr
	stz VideoIncrementL
	stz VideoIncrementH
	lda #$80
	sta SNESNMITMP     ; NMI on Vblank always enabled
	stz HCOUNTERL
	stz HCOUNTERH
	stz UpdatePalette
	jsr InitUpdateFlags
	stz PPUReadLatch

	
	;lda SNESNMITMP
	;ora #%00100000 ; Enable V timer
	;;ora #%00010000 ; Enable H timer
	;sta NMITIMEN
	;sta SNESNMITMP	
	;
	; Set the first interrupt on line 261 which is the end of Vblank on the nes
	;lda #$05
	;sta VTIMEL
	;sta HCOUNTERL
	;lda #$01
	;sta VTIMEH
	;sta HCOUNTERH
	
	;cli

	; Return to emulation mode and jump to the
	; recompiled nes reset routine.
	;; -----------------------------------------------
	; Data bank is bank 1 containing original source code
	; Program bank is 0 contains recompiled source code
	; Bank 2 is chr data 
	sep #$30		;  All 8bits
	lda #$01
	pha
	plb
	; Set 6502 emulation mode
	sec
	xce
	
	;; -----------------------------------------------
	; NMI on Vblank always enable because used to update the palettes and backgrounds.
	;lda SNESNMITMP
	;sta NMITIMEN
	;sta SNESNMITMP
	;; -----------------------------------------------
	; Does nothing. Just here to help finding the end of the initialisation, and the call of the nes reset vector.
	nop
	nop
	nop
	nop
	; Go to the start of the nes routine
	BREAK
	jmp NESReset

.ENDS

