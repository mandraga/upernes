
; Tell WLA that the SNES has ROM at locations ;$8000-$FFFF in every bank
.MEMORYMAP
  SLOTSIZE    $8000
  DEFAULTSLOT 0		; There is only a single slot in SNES
  SLOT        0 $8000
.ENDME

.ROMBANKMAP
  BANKSTOTAL   4		; Number of 32KB rom banks
  BANKSIZE $8000      ; 32KB
  BANKS        4
.ENDRO

;.ROMBANKSIZE $8000
;.ROMBANKS        4

.EMPTYFILL $FF
