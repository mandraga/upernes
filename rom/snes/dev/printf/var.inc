
	;; All the variables used for nes emulation
	;; Located in sram $0800 just above the nes 2KB memory

;--------------------------------------------------------------------
.DEFINE	RAMBASE	$0800		; 2kB

;; Variables to avoid calling the stack during IO operations.
.DEFINE Acc				RAMBASE
.DEFINE Xi				RAMBASE + 2
.DEFINE Yi				RAMBASE + 4
.DEFINE SP				RAMBASE + 6
.DEFINE Flags			RAMBASE + 8

;; Addres of the emulated port
.DEFINE IOAddr			RAMBASE + 10

.DEFINE IndirAddress	RAMBASE + 12

; String Functions
.DEFINE Cursor			RAMBASE + 14    ; Holds the 16-bit position on screen

;--------------------------------------------------------------------
.DEFINE IOBASE	$0900
;; IO Emulation state machine variables

.DEFINE PPUR_RAM_routineAddr	IOBASE + 0  ; Contains the routine to read ppu ram depending on vram @
.DEFINE PPUW_RAM_routineAddr	IOBASE + 2  ; Contains the routine to write ppu ram depending on vram @

.DEFINE PPUmemaddrL				IOBASE + 4	; Current ppu vram address
.DEFINE PPUmemaddrH				IOBASE + 5
.DEFINE PPUmemaddrB				IOBASE + 6	; Low/Hight byte write

.DEFINE tmp_addr				IOBASE + 7	; Word, tmp address storage

.DEFINE PPUcontrolreg1			IOBASE + 12
.DEFINE PPUcontrolreg2			IOBASE + 14

.DEFINE	SpriteMemoryAddress		IOBASE + 16

;--------------------------------------------------------------------
.DEFINE SpriteMemoryBase	$0A00           ; 256 bytes

;--------------------------------------------------------------------
; String buffer
.DEFINE TextBuffer	        $0C00	        ; 1KB for the text buffer
; $0C00 $0D00 $0E00 $0F00 pages are FULL

