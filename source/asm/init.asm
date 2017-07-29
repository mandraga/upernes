
	;; Initialises the snes and loads the CHR data in VRAM and WRAM

.include "var.inc"
.include "cartridge.inc"

.include "rom.asm"

.BASE $80 ; Fast ROM

.include "patchedPrg.asm"
.include "CHR.asm"
.include "PaletteUpdate.asm"
.include "DMABGUpdate.asm"
.include "SpritesUpdate.asm"
.include "sprite0.asm"
.include "intvectors.asm"
.include "LoadGraphics.asm"
.include "zeromem.asm"
.include "ppujmp.asm"
.include "Strings.asm"
.include "print.asm"

.BANK 0
.ORG 0
.SECTION "Reset"

Reset:
	sei			; disable interrupts
	clc			; native mode
	xce
	
	rep #$3E    ; all regs 16 bits, decimal mode off

	; Direct page $00
	pea $0000
	pld

	;----------------------------------------------------------------------------
	; Clear the sram from 8KB down to 2KB (mirrored on the nes but used as variables & buffers on the snes)
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

	; Move the last 64 sprites to a corner
	;; -----------------------------------------------
	jsr HideLast64Sprites
	
	; Load the APU simulator into the SPC700
	;; -----------------------------------------------
	stz APUInit
	jsr setup_spc ; Membler's Nes Apu emulator on the SPC700
	lda #$0F
    sta SNDCHANSW4015

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
	lda #$00
	sta WriteToggle   ; The first adressed PPU adresse byte is the most significant byte.
	stz StarPPUStatus
	inc StarPPUStatus ; Boot state in vblank flag of PPUSTATUS
	stz PPUmemaddrL
	stz PPUmemaddrH
	stz PPUcontrolreg2
	stz PPUStatus
    stz	SpriteMemoryAddress
	stz attributeaddr
	stz HCOUNTERL
	stz HCOUNTERH
	stz UpdatePalette
	jsr InitUpdateFlags
	stz PPUReadLatch
	lda #SprCHRInit
	sta SpriteCHRChg
	stz BGTransferStep
	lda #$01
	sta NESNMIENABLED
	stz VblankState
	stz NMI_occurred
	stz BGUpdateFIFOSZ
	stz BGUpdateFIFOSZ + 1
	stz TMPVTIMEL
	stz TMPVTIMEH
	; Do not touch this it is hardcoded
	lda #$40     ; RTI
	sta LocalRTI ; used to call an irq close to NMI

	;----------------------------------------------------------------------------
	; Precalculate a PPU routine jump table
	jsr PrecalculateJumpTable

	;----------------------------------------------------------------------------
	; A table to convert sprite flags, could be in ROM	
	jsr InitSpriteFlagsConversions
	
	;----------------------------------------------------------------------------
	; Copy the emulation patching code to the ram
	phb
	sep #$20 ; A 8bits
	rep #$10 ; X Y are 16bits
	lda #:RamEmulationCode		; Bank of the CHR data
	pha
	plb			; Data Bank Register = A
	ldx #$0000
	ldy #$0000
copyRamCode:
	lda RamEmulationCode.w,X
	sta PatchRoutinesBuff.w,X
	inx
	lda RamEmulationCode.w,X
	sta PatchRoutinesBuff.w,X
	inx
	iny
	tya
	cmp #RAMBINWSIZE
	bne copyRamCode
	plb ; Restore the data bank
	lda #$00
	sta JumpAddress
	sta JumpAddress + 1
	sta JumpAddress + 2

	;; -----------------------------------------------
	; Setup the timer interrupt routines
	; Set the first interrupt on line 261 which is the end of Vblank on the nes
	lda #$05
	sta VTIMEL
	sta HCOUNTERL
	lda #$01
	sta VTIMEH
	sta HCOUNTERH
	
	stz HTIMEL
	stz HTIMEH

	; Enable
	lda #$81
	sta SNESNMITMP     ; NMI on Vblank always enabled
	lda SNESNMITMP
	;ora #%00100000 ; Enable V timer
	;ora #%00010000 ; Enable H timer
	sta NMITIMEN
	sta SNESNMITMP

	; Return to emulation mode and jump to the
	; recompiled nes reset routine.
	;; -----------------------------------------------
	; Data bank is bank 1 containing original source code
	; Program bank is 0 contains recompiled source code
	; Bank 2 is chr data 
	sep #$30		; All 8bits
	lda #$01        ; Data bank
	pha
	plb
	; Set 6502 emulation mode
	sec
	xce

	lda #$0F		  ;Turn on screen, 100% brightness
	sta INIDISP

	;; -----------------------------------------------
	; Use fast rom
	lda #$01 
	sta MEMSEL

	;; -----------------------------------------------
	; NMI on Vblank always enable because used to update the palettes and backgrounds.
	lda SNESNMITMP
	sta NMITIMEN
	sta SNESNMITMP

	;; -----------------------------------------------
	; Does nothing. Just here to help finding the end of the initialisation, and the call of the nes reset vector.
	nop
	nop
	nop
	nop
	; Go to the start of the nes routine
	BREAK
	jmp NESRESET  ; Long jump to the other bank with patched IO and indirect jumps. 16bits instructions are still available here.

.ENDS

