
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

.DEFINE VideoIncrementL         IOBASE + 26  ; Video increment value
.DEFINE VideoIncrementH         IOBASE + 27  ; Video increment value

.DEFINE NamesBank1UpdateCounter IOBASE + 28  ; Counts the updated tiles in the background bank 1
.DEFINE NamesBank2UpdateCounter IOBASE + 29  ; Counts the updated tiles in the background bank 2
.DEFINE NameAddresL             IOBASE + 30  ; Address in the ametable
.DEFINE NameAddresH             IOBASE + 31
.DEFINE MaxNameHDMAUpdates      128          ; Up to 128 updated tiles, otherwise it will be a full update

.DEFINE Printfbuffer            IOBASE + 32  ; 16bytes for the printf parameters
.DEFINE PrintfbufferSz          16

.DEFINE Attributebuffer         IOBASE + 48  ; 64bytes to store the attributes to do the reads
.DEFINE AttributebufferSz       64

.DEFINE Palettebuffer           IOBASE + 112 ; 16bytes to store the palete to do the reads
.DEFINE PalettebufferSz         16

;--------------------------------------------------------------------
.DEFINE SpriteMemoryBase		$0A00       ; 256 bytes

.DEFINE NametableChanges        $0B00       ; 256 bytes, the changed bytes in the nametables, up to 128 names.
.DEFINE NametableBaseBank1      $1000       ; 4KB nes nametable, updated with HDMA or DMA if more than 128 updates.
.DEFINE NametableBaseBank2      $1800       ;

;--------------------------------------------------------------------
; String buffer
.DEFINE TextBuffer	        	$0C00	    ; 1024B for the text buffer tiles (512 tiles)
.DEFINE TextBufferSize          1024
; up to $0FFF


;--------------------------------------------------------------------
;               SNES VRAM defines (WORD addresses)
;--------------------------------------------------------------------
; Memory maping
.DEFINE TEXTCHRBASE             $1000
.DEFINE TEXTNAMEBASE            $1800
.DEFINE SPRITECHRBASE           $2000  ; OBSEL has 8K granularity
.DEFINE BGCHRBASE               $3000

.DEFINE NAMETABLE1BASE          $7000
.DEFINE NAMETABLE2BASE          $7400






