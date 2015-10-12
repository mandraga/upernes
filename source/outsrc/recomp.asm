
.include "cartridge.inc"


.include "var.inc"

.BANK 0
.ORG 0
.SECTION "Nesprg"
NESReset:
	sei 
	cld 
	lda #$10
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	ldx #$FF
	txs 
label0000:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	bpl label0000
label0001:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	bpl label0001
	ldy #$FE
	ldx #$05
label0002:
	lda $07D7,X
	cmp #$0A
	bcs label0003
	dex 
	bpl label0002
	lda $07FF
	cmp #$A5
	bne label0003
	ldy #$D6
label0003:
	jsr Routinelabel0015
	;---------------------
	;        sta $4011  SNDDMCDAC
	jsr rsta_4011
	;------------
	sta $0770
	lda #$A5
	sta $07FF
	sta $07A7
	lda #$0F
	;---------------------
	;        sta $4015  SNDCHANSWITCH
	jsr rsta_4015
	;------------
	lda #$06
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	jsr Routinelabel0003
	jsr Routinelabel0006
	inc $0774
	lda $0778
	ora #$80
	jsr Routinelabel0012
label0004:
	jmp label0004
	lda $0778
	and #$7F
	sta $0778
	and #$7E
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	lda $0779
	and #$E6
	ldy $0774
	bne label0005
	lda $0779
	ora #$1E
label0005:
	sta $0779
	and #$E7
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	;---------------------
	;        ldx $2002  PPUSTATUS
	jsr rldx_2002
	;------------
	lda #$00
	jsr Routinelabel0011
	;---------------------
	;        sta $2003  SPRADDR
	jsr rsta_2003
	;------------
	lda #$02
	;---------------------
	;        sta $4014  DMASPRITEMEMACCESS
	jsr rsta_4014
	;------------
	ldx $0773
	lda $805A,X
	sta $00
	lda $806D,X
	sta $01
	jsr Routinelabel0010
	ldy #$00
	ldx $0773
	cpx #$06
	bne label0006
	iny 
label0006:
	ldx $8080,Y
	lda #$00
	sta $0300,X
	sta $0301,X
	sta $0773
	lda $0779
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	jsr Routinelabel0016
	jsr Routinelabel0008
	jsr Routinelabel0000
	jsr Routinelabel0013
	lda $0776
	lsr A
	bcs label0011
	lda $0747
	beq label0007
	dec $0747
	bne label0010
label0007:
	ldx #$14
	dec $077F
	bpl label0008
	lda #$14
	sta $077F
	ldx #$23
label0008:
	lda $0780,X
	beq label0009
	dec $0780,X
label0009:
	dex 
	bpl label0008
label0010:
	inc $09
label0011:
	ldx #$00
	ldy #$07
	lda $07A7
	and #$02
	sta $00
	lda $07A8
	and #$02
	eor $00
	clc 
	beq label0012
	sec 
label0012:
	ror $07A7,X
	inx 
	dey 
	bne label0012
	lda $0722
	beq label0016
label0013:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	and #$40
	bne label0013
	lda $0776
	lsr A
	bcs label0014
	jsr Routinelabel0004
	jsr Routinelabel0001
label0014:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	and #$40
	beq label0014
	ldy #$14
label0015:
	dey 
	bne label0015
label0016:
	lda $073F
	;---------------------
	;        sta $2005  SCROLOFFSET
	jsr rsta_2005
	;------------
	lda $0740
	;---------------------
	;        sta $2005  SCROLOFFSET
	jsr rsta_2005
	;------------
	lda $0778
	pha 
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	lda $0776
	lsr A
	bcs label0017
	jsr Routinelabel0002
label0017:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	pla 
	ora #$80
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	rti 

Routinelabel0000:
	lda $0770
	cmp #$02
	beq label0018
	cmp #$01
	bne label0022
	lda $0772
	cmp #$03
	bne label0022
label0018:
	lda $0777
	beq label0019
	dec $0777
	rts 
label0019:
	lda $06FC
	and #$10
	beq label0020
	lda $0776
	and #$80
	bne label0022
	lda #$2B
	sta $0777
	lda $0776
	tay 
	iny 
	sty $FA
	eor #$01
	ora #$80
	bne label0021
label0020:
	lda $0776
	and #$7F
label0021:
	sta $0776
label0022:
	rts 

Routinelabel0001:
	ldy $074E
	lda #$28
	sta $00
	ldx #$0E
label0023:
	lda $06E4,X
	cmp $00
	bcc label0025
	ldy $06E0
	clc 
	adc $06E1,Y
	bcc label0024
	clc 
	adc $00
label0024:
	sta $06E4,X
label0025:
	dex 
	bpl label0023
	ldx $06E0
	inx 
	cpx #$03
	bne label0026
	ldx #$00
label0026:
	stx $06E0
	ldx #$08
	ldy #$02
label0027:
	lda $06E9,Y
	sta $06F1,X
	clc 
	adc #$08
	sta $06F2,X
	clc 
	adc #$08
	sta $06F3,X
	dex 
	dex 
	dex 
	dey 
	bpl label0027
	rts 

Routinelabel0002:
	lda $0770
	jsr Routinelabel0005
	and ($82),Y

Routinelabel0003:
	ldy #$00
	bit $04A0

Routinelabel0004:
