
; Tell WLA that the SNES has ROM at locations ;$8000-$FFFF in every bank
.MEMORYMAP
SLOTSIZE    $8000
DEFAULTSLOT 0		; There is only a single slot in SNES
SLOT        0 $8000
.ENDME

.ROMBANKMAP
BANKSTOTAL 3		; Number of 64KB rom banks
BANKSIZE $8000          ; 64KB
BANKS 3
.ENDRO

.EMPTYFILL $FF
