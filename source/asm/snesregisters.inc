
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
.EQU VMADDL   $2116 ;; VRAM Address Registers (Low)
.EQU VMADDH   $2117	;; VRAM Address Registers (High)

.EQU VMDATAL  $2118 ;; VRAM Data Write Registers (Low)
.EQU VMDATAH  $2119 ;; VRAM Data Write Registers (High)

.EQU TM       $212C ;; Windows mask for main screen
.EQU TS       $212D ;; Windows mask for sub screen

.EQU WMDATA   $2180 ;; WRAM Data Read/Write Register
.EQU WMADDL   $2181 ;; WRAM Address Registers (Low)
.EQU WMADDM   $2182 ;; WRAM Address Registers (Mid)
.EQU WMADDH   $2183	;; WRAM Address Registers (High) 

.EQU SETINI   $2133 ;; Screen resolutin parameters
.EQU HVLATCH  $2137 ;; H/V counters latch
.EQU STAT78   $213F ;; a status register
.EQU OPHCT    $213C ;; Horizontal value
.EQU OPVCT    $213D ;; Vertical value


.EQU NMITIMEN $4200 ;; NMI / TIMERS register
.EQU NMIFLAG  $4210	;; Blank Non Maskable Interrupt flag
.EQU HVBJOY   $4212	;; V-Blank flag

.EQU HTIMEL   $4207 ;; Horizontal timer value
.EQU HTIMEH   $4208
.EQU VTIMEL   $4209 ;; Vertical timer value
.EQU VTIMEH   $420A ;; 
.EQU HVTIME   $4211 ;; IRQ flag register

.EQU MDMAEN   $420B
.EQU HDMAEN   $420C

;------------ DMA1 ---------------
.EQU DMA1CTL     $4310
.EQU DMA1BDEST   $4311

.EQU DMA1A1SRCL   $4312
.EQU DMA1A1SRCH   $4313
.EQU DMA1A1SRCBNK $4314	
		
.EQU DMA1SZL     $4315
.EQU DMA1SZH     $4316

.EQU DMA1A2SRCL $4318
.EQU DMA1A2SRCH $4319

;------------ DMA2 ---------------
.EQU DMA2CTL      $4320
.EQU DMA2BDEST    $4321

.EQU DMA2A1SRCL   $4322
.EQU DMA2A1SRCH   $4323
.EQU DMA2A1SRCBNK $4324	
		
.EQU DMA2SZL      $4325
.EQU DMA2SZH      $4326

.EQU DMA2A2SRCL   $4328
.EQU DMA2A2SRCH   $4329

;------------ DMA7 ---------------
.EQU DMA7CTL      $4370
.EQU DMA7BDEST    $4371

.EQU DMA7A1SRCL   $4372
.EQU DMA7A1SRCH   $4373
.EQU DMA7A1SRCBNK $4374	
		
.EQU DMA7SZL      $4375
.EQU DMA7SZH      $4376

.EQU DMA7A2SRCL   $4378
.EQU DMA7A2SRCH   $4379
