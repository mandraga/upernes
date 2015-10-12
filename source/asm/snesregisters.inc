.EQU INIDISP  $2100
.EQU OBSEL    $2101
.EQU BGMODE   $2105

.EQU CGADD    $2121
.EQU CGDATA   $2122
.EQU BG12NBA  $210B	; BG Character Address Registers (BG1&2)
.EQU BG34NBA  $210C	; BG Character Address Registers (BG3&4)

.EQU OAMADDL  $2102	; OAM sprite buffer address low byte
.EQU OAMADDH  $2103	; OAM high byte (not used)
.EQU OAMDATA  $2104	; OAM write

.EQU BG1SC    $2107	;; BG Tilemap Address Registers (BG1)
.EQU BG2SC    $2108	;; BG Tilemap Address Registers (BG2)
.EQU BG3SC    $2109	;; BG Tilemap Address Registers (BG3)
.EQU BG4SC    $210A	;; BG Tilemap Address Registers (BG4)

.EQU BG1HOFS  $210D
.EQU BG1VOFS  $210E

.EQU VMAINC   $2115	;; Vram address increment register
.EQU VMADDL   $2116     ;; VRAM Address Registers (Low)
.EQU VMADDH   $2117	;; VRAM Address Registers (High)

.EQU VMDATAL  $2118     ;; VRAM Data Write Registers (Low)
.EQU VMDATAH  $2119     ;; VRAM Data Write Registers (High)

.EQU TM       $212C     ;; Windows mask for main screen
.EQU TS       $212D     ;; Windows mask for sub screen

.EQU NMITIMEN $4200
.EQU NMIFLAG  $4210	;; Blank Non Maskable Interrupt flag
.EQU HVBJOY   $4212	;; V-Blank flag

.EQU MDMAEN   $420B

;------------ DMA1 ---------------
.EQU DMA1CTL     $4310
.EQU DMA1BDEST   $4311

.EQU DMA1ASRCL   $4312
.EQU DMA1ASRCH   $4313
.EQU DMA1ASRCBNK $4314	
		
.EQU DMA1SZL     $4315
.EQU DMA1SZH     $4316

.EQU DMA1RAMSRCL $4318
.EQU DMA1RAMSRCH $4319
