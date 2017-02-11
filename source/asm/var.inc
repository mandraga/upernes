
	;; All the variables used for nes emulation
	;; Located in sram $0800 just above the nes 2KB memory

;--------------------------------------------------------------------
.DEFINE	RAMBASE	$0800		; 2kB

;; Theese variables are used to avoid using the stack when emulating I/O ports
.DEFINE Acc	        	RAMBASE
.DEFINE Xi	        	RAMBASE + 2
.DEFINE Yi	        	RAMBASE + 4
.DEFINE SP	        	RAMBASE + 6
.DEFINE Flags	        RAMBASE + 8

;; Address of the port to emulate
.DEFINE IOAddr	        RAMBASE + 10

.DEFINE IndirAddress    RAMBASE + 12

; String Functions
.DEFINE Cursor			RAMBASE + 14    ; Holds the 16-bit position on screen

;--------------------------------------------------------------------
; 
.DEFINE IOBASE	$0900
;; IO Emulation state machine variables

.DEFINE PPUR_RAM_routineAddr	IOBASE + 0  ; Contains the routine to read ppu ram depending on vram @
.DEFINE PPUW_RAM_routineAddr	IOBASE + 2  ; Contains the routine to write ppu ram depending on vram @

.DEFINE PPUmemaddrL				IOBASE + 4	; Current ppu vram address
.DEFINE PPUmemaddrH				IOBASE + 5
.DEFINE PPUmemaddrB				IOBASE + 6	; Low/Hight byte write

.DEFINE tmp_addr				IOBASE + 8	; Word, tmp address storage
.DEFINE tmp_dat 				IOBASE + 10	; Word, tmp data storage

.DEFINE PPUcontrolreg1			IOBASE + 12
.DEFINE PPUcontrolreg2			IOBASE + 14

.DEFINE	SpriteMemoryAddress		IOBASE + 16
.DEFINE PPTMP                   IOBASE + 17

.DEFINE CurScrolRegister        IOBASE + 20 ; 0 or 1 selects the vertical scroll register

.DEFINE attributeaddr           IOBASE + 22	; Used as the nes attribute table

.DEFINE BreakPointAddr          IOBASE + 24 ; Used to break in the debugger, look for $918
.DEFINE BreakPointAddr2         IOBASE + 25 ; Used to break in the debugger, look for $919

.MACRO BREAK
	pha
	lda $0918
	pla
.ENDM

.MACRO BREAK2
	pha
	lda $0919
	pla
.ENDM

;--------------------------------------------------------------------
.DEFINE SpriteMemoryBase		$0A00       ; 256 bytes

;--------------------------------------------------------------------
; String buffer
.DEFINE Printfbuffer            $0C00       ; 16bytes for the printf parameters
.DEFINE TextBuffer	        	$0C10	    ; 512B for the text buffer
; $0C00 $0D00

.DEFINE SPRITEFLAGSCONVTABLE    $0E00       ; Precalculated sprite flags nes to super nes, 256 bytes
; $0F00 not used


;--------------------------------------------------------------------
;               SNES VRAM defines (WORD addresses)
;--------------------------------------------------------------------
.DEFINE NAMETABLE1BASE          $7000
.DEFINE NAMETABLE2BASE          $7400


