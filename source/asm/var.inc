
	;; All the variables used for nes emulation
	;; Located in sram $0800 just above the nes 2KB memory

;--------------------------------------------------------------------
.DEFINE	RAMBASE	 $0800		; 2kB

.DEFINE STACKTOP $01FF

;; Theese variables are used to avoid using the stack when emulating I/O ports
.DEFINE Acc	        	RAMBASE
.DEFINE notused      	RAMBASE + 1
.DEFINE Xi	        	RAMBASE + 2
.DEFINE Yi	        	RAMBASE + 4
.DEFINE SP	        	RAMBASE + 6
.DEFINE Flags	        RAMBASE + 8

;; Address of the port to emulate
.DEFINE IOAddr	        RAMBASE + 10

.DEFINE IndirAddress    RAMBASE + 12

; String Functions
.DEFINE Cursor			RAMBASE + 14    ; Holds the 16-bit position on screen

.DEFINE EmulationStackPtr  RAMBASE + 16 ; The emulation stack pointer backup
.DEFINE NativeStackPtr     RAMBASE + 18 ; Native mode stack

.DEFINE SNESNMITMP         RAMBASE + 19 ; Saves the NMI/TIMER regiser

.DEFINE SPRITE0FLAG        RAMBASE + 20 ; Sprite 0 hit flag
.DEFINE SPRITE0FLGAG_VALUE %01000000

.DEFINE HCOUNTERL          RAMBASE + 21
.DEFINE HCOUNTERH          RAMBASE + 22
.DEFINE TMPVCOUNTL         RAMBASE + 23
.DEFINE TMPVCOUNTH         RAMBASE + 24

.DEFINE NESNMIENABLED      RAMBASE + 25 ; Nes NMI enabled, the snes NMI should always be on, and call the nes NMI only when this flag is set.
.DEFINE PPUReadLatch       RAMBASE + 26 ; Set to One when the ppu addresse register is changed, 0 on the first read

.DEFINE AccIt              RAMBASE + 27
.DEFINE Status             RAMBASE + 28 ; Status register storage
.DEFINE RetLow             RAMBASE + 29 ; Return values storage
.DEFINE RetHi              RAMBASE + 30 ;
.DEFINE SignatureLo        RAMBASE + 31 ; Address of the signature
.DEFINE SignatureHi        RAMBASE + 32 ;
;//.DEFINE XiLevel1           RAMBASE + 33 ; This is used to save X during IO emulation call
.DEFINE YiLeveL1           RAMBASE + 34

.DEFINE JumpAddress        RAMBASE + 36 ; Stores an address in order to avoid using X
.DEFINE AccNmi             RAMBASE + 37 ;
.DEFINE NmiRetLo           RAMBASE + 38 ;
.DEFINE NmiRetHi           RAMBASE + 39 ;
.DEFINE NmiStatus          RAMBASE + 40 ;

.DEFINE VblankState        RAMBASE + 41 ; State of the Vblank flag
.DEFINE VblankStateOff     $00
.DEFINE VblankStateOn      $01
.DEFINE VblankStateClr     $02

;//.DEFINE TMPPPUAL           RAMBASE + 42 ; Stores the PPUC address
.DEFINE TMPPPUAH           RAMBASE + 43 ;

.DEFINE NMI_occurred       RAMBASE + 44 ; To one when nmi occured
.DEFINE UpdateSprites      RAMBASE + 45 ; Update sprite in the Vblank interval



;.DEFINE SoundEmuLineL	   RAMBASE + 46	; Routine JMP address
;.DEFINE SoundEmuLineH	   RAMBASE + 47
;;----------------------------------------------
;; Sound emulation write only registers
;; Written direclty from the patch.
;; Like 'sta $4000' replaced by 'sta RAMBASE + 48' = 'sta $830'
.DEFINE SNDSQR1CTRL4000    RAMBASE + 48
.DEFINE SNDSQR1E4001       RAMBASE + 49
.DEFINE SNDSQR1PERIOD4002  RAMBASE + 50
.DEFINE SNDSQR1LENPH4003   RAMBASE + 51
.DEFINE SNDSQR2CTRL4004    RAMBASE + 52
.DEFINE SNDSQR2E4005       RAMBASE + 53
.DEFINE SNDSQR2PERIOD4006  RAMBASE + 54
.DEFINE SNDSQR2LENPH4007   RAMBASE + 55
.DEFINE SNDTRIACTRL4008    RAMBASE + 56
.DEFINE SNDTRIAPERIOD4009  RAMBASE + 57
.DEFINE SNDTRIALENPH400A   RAMBASE + 58
.DEFINE SNDNOISECTRL400B   RAMBASE + 59
.DEFINE SNDNOISESHM400C    RAMBASE + 60
.DEFINE SNDNOISELEN400D    RAMBASE + 61
.DEFINE SNDDMCCTRL400E     RAMBASE + 62
.DEFINE SNDDMCDAC400F      RAMBASE + 63
.DEFINE SNDDMCSADDR4010    RAMBASE + 64
.DEFINE SNDDMCSLEN4011     RAMBASE + 65
.DEFINE SNDCOMONCTRL14012  RAMBASE + 66
.DEFINE SNDCOMONCTRL24013  RAMBASE + 67
;;--------
.DEFINE SNDSTATUS          RAMBASE + 68


.DEFINE TMPVTIMEL          RAMBASE + 96
.DEFINE TMPVTIMEH          RAMBASE + 97

.DEFINE IOCallCOUNTER      RAMBASE + 127 ; Stores the shit from hell (counts Io calls)
.DEFINE IOCallArray        RAMBASE + 128 ; Stores the shit from hell (counts Io calls)
.DEFINE COUNTCALLS                     ; Enables counting IO accesses on the previous RAM area

;--------------------------------------------------------------------
; 
.DEFINE IOBASE	$0900
;; IO Emulation state machine variables

;//.DEFINE PPUR_RAM_routineAddr	IOBASE + 0  ; Contains the routine to read ppu ram depending on vram @
;//.DEFINE PPUW_RAM_routineAddr	IOBASE + 2  ; Contains the routine to write ppu ram depending on vram @

.DEFINE PPURW_IncrementL        IOBASE + 0  ; One or 32
.DEFINE PPURW_IncrementH        IOBASE + 1  ; One or 32

.DEFINE PPUmemaddrL				IOBASE + 4	; Current ppu vram address
.DEFINE PPUmemaddrH				IOBASE + 5
.DEFINE WriteToggle				IOBASE + 6	; Low/Hight byte write for the vertical scroll register od PPU address regster

.DEFINE tmp_addr				IOBASE + 8	; Word, tmp address storage
.DEFINE tmp_dat 				IOBASE + 10	; Word, tmp data storage

.DEFINE PPUcontrolreg1			IOBASE + 11
.DEFINE PPUcontrolreg2			IOBASE + 12
.DEFINE PPUStatus               IOBASE + 13 ; Used to check visually with the debugger
.DEFINE	SpriteMemoryAddress		IOBASE + 14
.DEFINE	NESVSCROLL              IOBASE + 15 ; Equal to ppu mem Addr.
.DEFINE	NESHSCROLL              IOBASE + 16
.DEFINE PPTMP                   IOBASE + 17
.DEFINE StarPPUStatus           IOBASE + 18 ; 1 on start
.DEFINE VCOUNTL                 IOBASE + 19 ;
.DEFINE VCOUNTH                 IOBASE + 20 ;

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

.DEFINE BreakPointAddr3         IOBASE + 26  ; Video increment value
.DEFINE BreakPointAddr4         IOBASE + 27  ; Video increment value

.MACRO BREAK3
	pha
	lda $091A
	pla
.ENDM

.MACRO BREAK4
	pha
	lda $091B
	pla
.ENDM

.DEFINE NamesBank1UpdateCounter IOBASE + 28  ; Counts the updated tiles in the background bank 1
.DEFINE NamesBank2UpdateCounter IOBASE + 29  ; Counts the updated tiles in the background bank 2
.DEFINE NameAddresL             IOBASE + 30  ; Address in the nametable
.DEFINE NameAddresH             IOBASE + 31
.DEFINE MaxNameHDMAUpdates      128          ; Up to 128 updated tiles, otherwise it will be a full update

.DEFINE Printfbuffer            IOBASE + 32  ; 16bytes for the printf parameters
.DEFINE PrintfbufferSz          16

.DEFINE SprCHRB1                 0
.DEFINE SprCHRB2                 1
.DEFINE SprCHRInit               2
.DEFINE SpriteCHRChg            IOBASE + 48  ; Sprite chr has not changed

.DEFINE ColumnUpdateFlags       IOBASE + 49  ; 8 bytes to update the colums of the 2 banks
.DEFINE UpdateCtr               IOBASE + 57  ;
.DEFINE ColumnTableLo           IOBASE + 58  ;
.DEFINE ColumnTableHi           IOBASE + 59  ;
.DEFINE COLUMUPDATENUMBER       4

.DEFINE BGTransferStep          IOBASE + 60  ; To use dma on a group of lines only
; 58 unused bytes

.DEFINE Palettebuffer           IOBASE + 112 ; 2 x 16bytes to store the palettes to do the reads and conversions during NMI
.DEFINE PalettebufferSz         32
.DEFINE UpdatePalette           IOBASE + 144 ; Update palette flags, one bit for each one of the 8 palettes
.DEFINE UpdateFlags             IOBASE + 145 ; Used to build the flag (8 bytes)

; Vram/X Y scrolling registers
.DEFINE tL                      IOBASE + 160 ; tmp vram address Low
.DEFINE tH                      IOBASE + 161 ; tmp vram address hi
.DEFINE tX                      IOBASE + 162 ; tmp X 'fine' scroll
.DEFINE tmpV                    IOBASE + 163 ; 
.DEFINE tmpPPUcontrolreg1       IOBASE + 164 ; 
.DEFINE XsavScroll              IOBASE + 165 ;

.DEFINE BGUpdateFIFOSZ          IOBASE + 166 ; Number of element in the fifo, if less than 16, update them. Else update all.
.DEFINE BGUpdateFIFO            IOBASE + 168 ;
.DEFINE BGFifoMax                 32

;--------------------------------------------------------------------
.DEFINE SpriteMemoryBase		$0A00       ; 256 bytes

.DEFINE NametableChanges        $0B00       ; 256 bytes, the changed bytes in the nametables, up to 128 names.

;--------------------------------------------------------------------
; String buffer
.DEFINE TextBuffer	        	$0C00	    ; 1024B for the text buffer tiles (512 tiles)
.DEFINE TextBufferSize          1024
; up to $0FFF

.DEFINE PatchRoutinesBuff       $0E00 ; This area contains the code in ram used to jump to the bank 0 and emulate IO accesses.

;--------------------------------------------------------------------

.DEFINE NametableBaseBank1      $1000       ; 4KB nes nametable, updated with HDMA or DMA if more than 128 updates.
.DEFINE NametableBaseBank2      $1800       ;
.DEFINE NAMETABLEBASEINTERVAL   $0800

.DEFINE Attributebuffer1        $1780       ;  64bytes to store the attributes to do the reads
.DEFINE Attributebuffer2        $17C0       ;  64bytes to store the attributes of bank 2
.DEFINE AttributebufferSz       64

.DEFINE AttributePrecalc        $1F80       ; 128Bytes to precalculate the Attribute @ nes to snes conversion

;--------------------------------------------------------------------
; Wram table at bank $7E or $7F
;--------------------------------------------------------------------
.DEFINE NameTransferTables      $8000       ; Used to transfer the data with HDMA

.DEFINE NAMETABLE1BASE          $7000
.DEFINE NAMETABLE2BASE          $7400
.DEFINE NAMETABLEINTERVAL       $0400

.DEFINE WRamBank                $7F
.DEFINE WRamPPUADDRJmps         $4000       ; Jump tables for all the PPU routines (PPU @ space size / 16 in word @ = $400 word@ = $800 bytes 2kBytes)
.DEFINE PPUADDRJmps             $400

;--------------------------------------------------------------------
;               SNES VRAM defines (WORD addresses)
;--------------------------------------------------------------------
; Memory maping
.DEFINE TEXTCHRBASE             $1000
.DEFINE TEXTNAMEBASE            $1800
.DEFINE SPRITECHRBASE           $2000  ; OBSEL has 8K granularity
.DEFINE BGCHRBASE               $3000



