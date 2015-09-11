; == LoRom ========================= 

; Tell WLA that the SNES has ROM at locations ;$8000-$FFFF in every bank
.MEMORYMAP
SLOTSIZE $8000          ; and that this area is $8000 bytes in size.
DEFAULTSLOT 0           ; There is only a single slot in SNES, other consoles
SLOT 0 $8000            ;       may have more slots per bank.
.ENDME

.ROMBANKSIZE $8000      ; Every ROM bank is 32 KBytes in size
.ROMBANKS 2             ; number of ROM banks for this cartridge
.DEFINE HEADER_OFF $0000
; ===========================

; === Cartridge Header - part 1 - =====================
.BANK 0 SLOT 0  ; The SLOT 0 may be ommited, as SLOT 0 is the DEFAULTSLOT
.ORG    $7FB0 + HEADER_OFF
.DB     "00"                        ; New Licensee Code
.DB     "SNES"                      ; ID
.ORG    $7FC0 + HEADER_OFF
.DB     "test nes ppu0"             ; Title (21 bytes)
;       "123456789012345678901"
.ORG    $7FD5 + HEADER_OFF
.DB     $20                         ; Memory Mode ($20=Slow LoRom, $21=Slow HiRom)

; === Cartridge Header - part 2 - =====================
.BANK 0 SLOT 0
.ORG    $7FD6 + HEADER_OFF
; Contents ($00=ROM only, $01=ROM and RAM, $02=ROM and Save RAM)
.DB     $02
; ROM Size ($08=2Mbit, $09=4Mbit, $0A=8Mbit, $0B=16Mbit... etc)
.DB     $08
; SRAM Size ($00=0bits, $01=16kbits, $02=32kbits, $03=64kbits)
.DB     $00
.DB     $01                   ; Country ($01=USA)
.DB     $00                   ; Licensee Code
.DB     $00                   ; Version
.DW    $0000                  ; Checksum Complement  (not calculated here)
.DW    $0000                  ; Checksum


; Interrupt vector tables
.BANK 0 SLOT 0
.ORG    $7FE4 + HEADER_OFF    ; = Native Mode
.DW     EmptyHandler          ; COP
.DW     EmptyHandler          ; BRK
.DW     EmptyHandler          ; ABORT
.DW     EmptyVBlank           ; NMI
.DW     $0000                 ; (Unused)
.DW     EmptyHandler          ; IRQ

.ORG    $7FF4 + HEADER_OFF    ; = Emulation Mode
.DW     EmptyHandler          ; COP
.DW     $0000                 ; (Unused)
.DW     EmptyHandler          ; ABORT
.DW     EmptyHandler          ; NMI
.DW     Reset                 ; RESET
.DW     EmptyHandler          ; IRQ/BRK

; ============================================

.BANK 0 SLOT 0
.org HEADER_OFF
.SECTION "EmptyVectors" SEMIFREE

EmptyHandler:
        rti

EmptyVBlank:
        rep #30
        pha
        php

        sep #$20
        lda $4210               ;clear NMI Flag

        plp
        pla
        rti

.ENDS

; -------------------------------------------------
; CHR
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"
NESCHR:
         .INCBIN "test.chr"
BGpalette:
	.db $22,$2A,$09,$07, $0F,$30,$27,$15, $0F,$30,$02,$21, $0F,$30,$00,$10
SPRpalette:
	.db $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F
nes2snespalette:
	.INCBIN "palette.dat"
	
.ENDS

; -------------------------------------------------

.EMPTYFILL $FF

