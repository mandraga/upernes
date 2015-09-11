
;; --------------------------------------------------------------------
;; Cartridge header
;;
;; Part 1
.BANK 0
.ORG    $7FB0
.DB     "00"			; New Licensee Code
.DB     "SNES"			; ID
.ORG    $7FC0
.DB     "test nes ppu0"		; Title (21 bytes)
;       "123456789012345678901"
.ORG    $7FD5
.DB     $20			; Memory Mode ($20=Slow LoRom, $21=Slow HiRom)

;; Part 2
.ORG    $7FD6
.DB     $02			; Contents ($00=ROM only, $01=ROM and RAM, $02=ROM and Save RAM)
.DB     $08			; ROM Size ($08=2Mbit, $09=4Mbit, $0A=8Mbit, $0B=16Mbit... etc)
.DB     $00			; SRAM Size ($00=0bits, $01=16kbits, $02=32kbits, $03=64kbits)
.DB     $01			; Country ($01=USA)
.DB     $00			; Licensee Code
.DB	$00			; Version
.DW	$0000			; Checksum Complement  (not calculated here)
.DW	$0000			; Checksum

;; --------------------------------------------------------------------
; PRG
.BANK 1 SLOT 0
.ORG 16384
; .SECTION "OriginalPRGrom"
	
PRGrom:
	.INCBIN "nesprg.bin"
;.ENDS

;; --------------------------------------------------------------------
; CHR
.BANK 2 SLOT 0
.ORG 0
.SECTION "CharacterData"
NESCHR:
	.INCBIN "neschr.bin"
BG3palette:
        .db $22,$2A,$09,$07, $0F,$30,$27,$15, $0F,$30,$02,$21, $0F,$30,$00,$10
ASCIITiles:
	.INCBIN	"data/ascii.pic"
nes2snespalette:
	.INCBIN "data/palette.dat"
.ENDS

; -------------------------------------------------
