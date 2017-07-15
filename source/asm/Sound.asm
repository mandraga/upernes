

; ------+-----+---------------------------------------------------------------
; $4000 |  W  | Square 1
;       | 0-3 | vol/env period
;       |   4 | env disable
;       |   5 | loop env/disable length
;       | 6-7 | duty

WSNDSQR1CTRL:
	RETW

; ------+-----+---------------------------------------------------------------
; $4001 |  W  | Square 1
;       | 0-2 | shift
;       |   3 | negative,
;       | 4-6 | period,
;       |   7 | enable sweep

WSNDSQR1E:
	RETW

; ------+-----+---------------------------------------------------------------
; $4002 |  W  | Square 1
;       | 0-7 | period low
	
WSNDSQR1PERIOD:
	RETW

; ------+-----+---------------------------------------------------------------
; $4003 |  W  | Square 1
;       | 0-2 | period high
;       | 3-7 |	length index

WSNDSQR1LENPH:
	RETW

;;############################################################################ 
; ------+-----+---------------------------------------------------------------
; $4004 |  W  | Square 2, see square 1


WSNDSQR2CTRL:
	RETW
	
WSNDSQR2E:
	RETW

WSNDSQR2PERIOD:
	RETW

WSNDSQR2LENPH:
	RETW

;;############################################################################ 
; ------+-----+---------------------------------------------------------------
; $4008 |  W  | Triangle Control
;       | 0-6 | linear counter load
;       |   7 | control

WSNDTRIACTRL:
	RETW
; ------+-----+---------------------------------------------------------------
; $400A |  W  | Triangle period
;       | 0-7 | period low

WSNDTRIAPERIOD:
	RETW

; ------+-----+---------------------------------------------------------------
; $400B |  W  | Triangle period
;       | 0-2 | period high
;       | 3-7 |	length index

WSNDTRIALENPH:
	RETW

;;############################################################################ 
; ------+-----+---------------------------------------------------------------
; $400C |  W  | Noise Control
;       | 0-3 | vol/env period
;       |   4 | env disable
;       |   5 | loop env/disable length

WSNDNOISECTRL:
	RETW

; ------+-----+---------------------------------------------------------------
; $400E |  W  | Noise
;       | 0-3 | period index
;       |   7 | short mode

WSNDNOISESHM:
	RETW

; ------+-----+---------------------------------------------------------------
; $400F |  W  | Noise
;       | 0-2 | unused
;       | 3-7 | length index

WSNDNOISELEN:
	RETW

;;############################################################################ 
; ------+-----+---------------------------------------------------------------
; $4010 |  W  | DMC
;       | 0-3 | frequency index
;       |   6 | loop
;       |   7 | IRQ enable

WSNDDMCCTRL:
	RETW

; ------+-----+---------------------------------------------------------------
; $4011 |  W  | DMC DAC
;       | 0-6 | DAC
	
WSNDDMCDAC:
	RETW

; ------+-----+---------------------------------------------------------------
; $4012 |  W  | DMC Sample @
;       | 0-7 | sample address

WSNDDMCSADDR:
	RETW

; ------+-----+---------------------------------------------------------------
; $4013 |  W  | DMC Sample
;       | 0-7 | sample length

WSNDDMCSLEN:
	RETW

; ------+-----+---------------------------------------------------------------
; $4017 |  W  | Frame Sequencer reset
;       | 0-5 | unused
;       |   6 | IRQ disable
;       |   7 | mode: 0:4step squence; 1:5step sequence

WSNDSEQUENCER:
	RETW
	
	
	
; ------+-----+---------------------------------------------------------------
; This routine reads the write only register values and updates the values
; in the SP700.
;
SoundAPURegUpdate:


	rts
