
.include "cartridge.inc"


.include "var.inc"

.BANK 0
.ORG 0
.SECTION "Nesprg"
NESReset:
	cld 
	lda #$00
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	lda #$14
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
	lda $C028,X
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	inx 
	cpx #$10
	bne label0001
	jsr Routinelabel0000
	ldx #$00
	lda #$00
	;---------------------
	;        sta $2003  SPRADDR
	jsr rsta_2003
	;------------
label0002:
	;---------------------
	;        sta $2004  SPRDATA
	jsr rsta_2004
	;------------
	dex 
	bne label0002
	lda #$14
	sta $0200
	lda #$01
	sta $0201
	lda #$02
	sta $0202
	lda #$08
	sta $0203
	jsr Routinelabel0001
	jsr Routinelabel0002
	lda #$02
	;---------------------
	;        sta $4014  DMASPRITEMEMACCESS
	jsr rsta_4014
	;------------
	lda #$00
	sta $0010
label0003:
	jsr Routinelabel0002
	lda #$01
	sta $4016
	lda #$00
	sta $4016
	lda $4016
	and #$01
	eor $0003
	sta $0003
	lda $0003
	cmp #$00
	bne label0004
	jsr Routinelabel0003
	inc $0010
	lda $0010
	cmp $001E
	bne label0004
	inc $0200
	inc $0203
	inc $0203
	lda $0203
	cmp #$80
	bcs label0004
	lda $0202
	eor #$A2
	sta $0202
label0004:
	jmp label0003

Routinelabel0000:
	lda #$06
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	rts 

Routinelabel0001:
	lda #$14
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

Routinelabel0003:
	lda #$02
	;---------------------
	;        sta $4014  DMASPRITEMEMACCESS
	jsr rsta_4014
	;------------
	rts 

NESNonMaskableInterrupt:
	jmp DebugHandler
NESIRQBRK:
	jmp DebugHandler


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

rsta_2003:
	php
	stx Xi
	ldx #$06
	jsr staioportroutine
	ldx Xi
	plp
	rts

rsta_2004:
	php
	stx Xi
	ldx #$08
	jsr staioportroutine
	ldx Xi
	plp
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

rsta_4014:
	php
	stx Xi
	ldx #$38
	jsr staioportroutine
	ldx Xi
	plp
	rts

.ENDS
