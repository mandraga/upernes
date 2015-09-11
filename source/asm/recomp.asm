
.include "cartridge.inc"


.include "var.inc"

.BANK 0
.ORG 0
.SECTION "Nesprg"
NESReset:
	cld 
	lda #$10
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	lda #$1E
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	lda #$3F
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$00
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	jmp label0000
label0000:
	ldx #$00
label0001:
	lda $C018,X
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	inx 
	cpx #$20
	bne label0001
	jsr Routinelabel0002
	jsr Routinelabel0000
	lda #$20
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$00
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$1E
	sta $000A
label0002:
	lda #$24
	ldx #$20
label0003:
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bne label0003
	lda #$00
	dec $000A
	cmp $000A
	bne label0002
	jsr Routinelabel0001
	jsr Routinelabel0002
	jsr Routinelabel0000
	lda #$21
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$CE
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$A0
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	jsr Routinelabel0001
label0004:
	jmp label0004

Routinelabel0000:
	lda #$06
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	rts 

Routinelabel0001:
	lda #$1E
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	rts 

Routinelabel0002:
label0005:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	bpl label0005
	rts 


rsta_2000:
	php
	stx Xi
	ldx #$00
	jsr staioportroutine
	ldx Xi
	plp
	rts

rsta_2001:
	php
	stx Xi
	ldx #$02
	jsr staioportroutine
	ldx Xi
	plp
	rts

rlda_2002:
	php
	stx Xi
	ldx #$04
	jsr ldaioportroutine
	ldx Xi
	plp
	ora #$00		; test N Z flags without affecting A
	rts

rsta_2006:
	php
	stx Xi
	ldx #$0C
	jsr staioportroutine
	ldx Xi
	plp
	rts

rsta_2007:
	php
	stx Xi
	ldx #$0E
	jsr staioportroutine
	ldx Xi
	plp
	rts

.ENDS
