
.include "cartridge.inc"


.include "var.inc"

.BANK 0
.ORG 0
.SECTION "Nesprg"
NESReset:
	lda #$00
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
label0000:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	bpl label0000
	sei 
	cld 
	ldx #$FF
	txs 
	ldx #$12
	lda #$00
label0001:
	sta $00,X
	inx 
	bne label0001
	ldx #$02
label0002:
	lda $07FA,X
	cmp $C078,X
	bne label0003
	dex 
	bpl label0002
	bmi label0009
label0003:
	ldx #$00
	txa 
label0004:
	sta $00,X
	sta $0700,X
	inx 
	bne label0004
	lda #$32
	sta $15
label0005:
	lda #$32
	jsr Routinelabel0072
	lda #$00
	sta $46
	jsr Routinelabel0013
	dec $15
	bne label0005
	ldx #$0E
label0006:
	lda $C07B,X
	sta $0629,X
	dex 
	bpl label0006
	ldx #$04
label0007:
	lda #$00
	sta $03,X
	dex 
	bpl label0007
	lda #$00
	jsr Routinelabel0072
	ldx #$02
label0008:
	lda $C078,X
	sta $07FA,X
	dex 
	bpl label0008
label0009:
	lda #$1E
	sta $01
	lda #$90
	sta $00
	jmp label0460
NESNonMaskableInterrupt:
	pha 
	txa 
	pha 
	tya 
	pha 
	lda #$00
	;---------------------
	;        sta $2003  SPRADDR
	jsr rsta_2003
	;------------
	lda #$02
	;---------------------
	;        sta $4014  DMASPRITEMEMACCESS
	jsr rsta_4014
	;------------
	lda $52
	cmp $53
	beq label0010
	jsr Routinelabel0008
label0010:
	jsr Routinelabel0069
	jsr Routinelabel0075
	inc $19
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
	lda #$00
	;---------------------
	;        sta $2005  SCROLOFFSET
	jsr rsta_2005
	;------------
	;---------------------
	;        sta $2005  SCROLOFFSET
	jsr rsta_2005
	;------------
	jsr Routinelabel0143
	lda #$01
	sta $02
	lda $16
	beq label0013
label0011:
	;---------------------
	;        lda $2002  PPUSTATUS
	jsr rlda_2002
	;------------
	bmi label0011
	ldx #$04
	ldy #$C6
label0012:
	dey 
	bne label0012
	dex 
	bne label0012
	lda $18
	ora $00
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	lda $17
	;---------------------
	;        sta $2005  SCROLOFFSET
	jsr rsta_2005
	;------------
	lda #$00
	;---------------------
	;        sta $2005  SCROLOFFSET
	jsr rsta_2005
	;------------
label0013:
	pla 
	tay 
	pla 
	tax 
	pla 
	rti 
NESIRQBRK:
label0014:
	jmp label0014

Routinelabel0000:
	lda $00
	and #$7F
label0015:
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	sta $00
	rts 

Routinelabel0001:
	lda $00
	ora #$80
	bne label0015

Routinelabel0002:
	lda #$00
label0016:
	pha 
	jsr Routinelabel0123
	pla 
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	rts 

Routinelabel0003:
label0017:
	lda $01
	bne label0016

Routinelabel0004:
label0018:
	jsr Routinelabel0007
	ldy #$00
label0019:
	lda $0057,Y
	sta $0300,X
	inx 
	iny 
	cpy $56
	bne label0019
	stx $53
	rts 

Routinelabel0005:
label0020:
	lda #$57
	ldy #$00

Routinelabel0006:
label0021:
	sta $21
	sty $22
	txa 
	pha 
	ldy #$02
	lda ($21),Y
	clc 
	adc #$03
	sta $12
	ldx $53
	ldy #$00
label0022:
	lda ($21),Y
	sta $0300,X
	inx 
	iny 
	cpy $12
	bne label0022
	stx $53
	pla 
	tax 
	rts 

Routinelabel0007:
	ldx $53
	lda #$00
	sta $12
	lda $55
	asl A
	asl A
	asl A
	asl A
	rol $12
	asl A
	rol $12
	ora $54
	pha 
	lda $12
	ora #$20
	sta $0300,X
	inx 
	pla 
	sta $0300,X
	inx 
	lda $56
	sta $0300,X
	inx 
	rts 

Routinelabel0008:
label0023:
	tya 
	pha 
	txa 
	pha 
	jsr Routinelabel0009
	pla 
	tax 
	pla 
	tay 
	rts 

Routinelabel0009:
label0024:
	ldx $52
	lda $0300,X
	inx 
	sta $50
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda $0300,X
	inx 
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	ldy $0300,X
	inx 
label0025:
	lda $0300,X
	inx 
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dey 
	bne label0025
	lda $50
	cmp #$3F
	bne label0026
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
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
label0026:
	stx $52
	cpx $53
	bne label0024
	rts 
label0027:
	lda #$20
	sta $F2
	jsr Routinelabel0011
	jsr Routinelabel0012
	lda #$FF
	sta $CD
	lda #$A3
	sta $23
	lda #$C4
	sta $24
	lda #$80
	sta $91
	sta $0488
	lda #$70
	sta $9A
	jsr Routinelabel0040
	lda #$00
	sta $41
	sta $C9
	sta $CA
	sta $BA
	sta $C5
	sta $C8
	jsr Routinelabel0126
	ldx #$13
label0028:
	lda #$FF
	sta $0530,X
	lda #$F0
	sta $04A4,X
	dex 
	bpl label0028
label0029:
	jsr Routinelabel0125
	jsr Routinelabel0085
	lda $C5
	bne label0030
	jsr Routinelabel0018
label0030:
	lda $19
	lsr A
	bcs label0031
	jmp label0041
label0031:
	lda $C5
	beq label0032
	dec $C5
	jmp label0041
label0032:
	lda $17
	bne label0033
	lda $18
	eor #$01
	sta $18
label0033:
	dec $17
	lda $0488
	beq label0035
	inc $0488
	lda $0488
	cmp #$F0
	bcc label0034
	lda #$00
	sta $0488
label0034:
	lda $BD
	beq label0035
	inc $91
label0035:
	ldx #$07
label0036:
	lda $055D,X
	bmi label0037
	inc $0567,X
	lda $0567,X
	cmp #$F8
	bne label0037
	lda #$FF
	sta $055D,X
	lda #$F0
	sta $057B,X
	lda #$00
	sta $05CE
label0037:
	dex 
	bpl label0036
	ldx #$13
label0038:
	lda $0530,X
	bmi label0039
	inc $0490,X
	lda $0490,X
	cmp #$F8
	bcc label0039
	lda #$F0
	sta $04A4,X
	sta $0530,X
label0039:
	dex 
	bpl label0038
	lda $17
	and #$07
	bne label0041
	ldx $88
	dex 
	bmi label0041
	lda #$00
	sta $3E
	lda #$01
	jsr Routinelabel0072
	inc $C9
	lda $C9
	and #$1F
	bne label0040
	inc $CA
	lda $CA
	cmp #$0A
	bne label0040
	lda #$02
	sta $CA
	ldy $BA
	iny 
	tya 
	and #$03
	sta $BA
label0040:
	ldx $CA
	lda $C3B5,X
	asl A
	tay 
	lda $C3AB,Y
	sta $25
	lda $C3AC,Y
	sta $26
	jsr Routinelabel0010
label0041:
	ldx #$07
label0042:
	lda $055D,X
	bmi label0043
	jsr Routinelabel0044
	lda $05CD
	beq label0043
	dec $05CD
	inc $05CE
	txa 
	pha 
	lda $0559
	jsr Routinelabel0072
	pla 
	tax 
label0043:
	jsr Routinelabel0043
	dex 
	bpl label0042
	ldx #$13
label0044:
	lda $0530,X
	bmi label0047
	lda $C5
	bne label0046
	jsr Routinelabel0027
	lda $04A4,X
	cmp #$02
	bcs label0045
	jsr Routinelabel0030
label0045:
	cmp #$D8
	bcc label0046
	jsr Routinelabel0030
label0046:
	jsr Routinelabel0033
label0047:
	lda $19
	and #$07
	lsr A
	tay 
	lda $C9D3,Y
	pha 
	lda $19
	lsr A
	txa 
	bcc label0048
	sta $12
	lda #$13
	sbc $12
label0048:
	asl A
	asl A
	tay 
	pla 
	sta $02B1,Y
	lda $04A4,X
	sta $02B0,Y
	lda $0490,X
	sta $02B3,Y
	lda #$00
	sta $02B2,Y
	dex 
	bpl label0044
	lda $05CE
	cmp #$14
	bcc label0049
	inc $47
	lda #$00
	jsr Routinelabel0072
	dec $47
	lda #$10
	sta $F2
	inc $C8
	jsr Routinelabel0054
	jsr Routinelabel0011
	dec $C8
	ldx #$64
	jsr Routinelabel0122
	lda #$20
	sta $F2
label0049:
	ldx #$F0
	lda $0488
	beq label0050
	ldx #$88
label0050:
	stx $0200
	stx $0204
	sta $0203
	clc 
	adc #$08
	sta $0207
	lda $19
	and #$03
	sta $0202
	sta $0206
	ldx #$E3
	stx $0201
	inx 
	stx $0205
	lda $88
	bmi label0051
	jmp label0029
label0051:
	jsr Routinelabel0013
	lda #$01
	sta $F0
	jsr Routinelabel0123
	lda #$02
	sta $F2
	jmp label0488

Routinelabel0010:
	;---------------------
	;        jmp ($0025)
	jmp IndJmp0025
	;------------

Routinelabel0011:
	jsr Routinelabel0045
	asl $0559
	lda $0559
	asl A
	asl A
	adc $0559
	sta $0559
	rts 

Routinelabel0012:
	lda #$00
	sta $12
label0052:
	lda $12
	asl A
	asl A
	adc $12
	sta $1D
	lda #$07
	sta $1E
	ldy #$04
label0053:
	lda ($1D),Y
	cmp $0003,Y
	bcc label0055
	bne label0054
	dey 
	bpl label0053
	bmi label0055
label0054:
	inc $12
	lda $12
	cmp #$32
	bne label0052
	dec $12
label0055:
	inc $12
	lda $12
	pha 
	sta $43
	ldy #$0A
	jsr Routinelabel0073
	sta $4A
	lda $43
	sta $49
	pla 
	sta $12
	rts 

Routinelabel0013:
	jsr Routinelabel0012
	dec $12
	lda #$31
	sec 
	sbc $12
	sta $13
	asl A
	asl A
	adc $13
	tay 
	lda $12
	asl A
	asl A
	adc $12
	sta $1D
	clc 
	adc #$05
	sta $1F
	lda #$07
	sta $1E
	sta $20
	tya 
	beq label0057
	dey 
label0056:
	lda ($1D),Y
	sta ($1F),Y
	dey 
	bne label0056
	lda ($1D),Y
	sta ($1F),Y
label0057:
	ldy #$04
label0058:
	lda $0003,Y
	sta ($1D),Y
	dey 
	bpl label0058
	rts 
label0059:
	lda $048D
	lsr A
	lsr A
	lsr A
	tax 
	lda $048A
	bne label0060
	lda $C5AD,X
	jmp label0061
label0060:
	lda $C5B1,X
label0061:
	sta $87
	ldx #$08
	jsr Routinelabel0083
	lda $048C
	beq label0066
	ldx $048B
	lda $048D
	cmp #$20
	bne label0062
	lda #$FF
	sta $88,X
	bmi label0065
label0062:
	bcs label0066
	lda $0450
	bne label0063
	lda $99
	clc 
	adc #$04
	bne label0064
label0063:
	lda $99
	sec 
	sbc #$04
label0064:
	sta $91,X
	lda $A2
	sec 
	sbc #$0A
	sta $9A,X
label0065:
	jsr Routinelabel0083
label0066:
	rts 

Routinelabel0014:
	lda #$FF
	sta $048B
	ldx #$07
label0067:
	lda $88,X
	bmi label0068
	lda $9A,X
	cmp #$B4
	bcc label0068
	lda $91,X
	cmp $99
	beq label0069
label0068:
	dex 
	bpl label0067
	rts 
label0069:
	stx $048B
	lda $0448,X
	sta $0450
	lda #$00
	sta $048A
	sta $048D
	sta $048C
	sta $0489
	lda #$DC
	sta $A2
	rts 

Routinelabel0015:
	inc $99
	lda $99
	cmp #$B1
	bcc label0070
	lda #$40
	sta $99
label0070:
	rts 

Routinelabel0016:
	lda $0489
	bne label0071
	dec $A2
	lda $A2
	cmp #$C4
	bcs label0072
	inc $A2
	inc $048A
	inc $0489
	bne label0072
label0071:
	inc $A2
label0072:
	inc $048D
	lda $048D
	cmp #$18
	bne label0073
	ldx $048B
	lda $88,X
	bmi label0073
	lda $9A,X
	clc 
	adc #$10
	cmp $A2
	bcc label0073
	ldy $0451,X
	lda $C6AE,Y
	sta $0451,X
	lda #$00
	sta $7F,X
	sta $88,X
	lda $F2
	ora #$40
	sta $F2
	inc $048C
label0073:
	lda $048A
	beq label0075
	lda $048D
	cmp #$28
	beq label0074
	cmp #$30
	bne label0075
label0074:
	lda #$CC
	sta $A2
label0075:
	rts 

Routinelabel0017:
	lda $0489
	bne label0078
	ldx $048B
	lda $88,X
	bmi label0076
	lda $9A,X
	cmp #$B4
	bcc label0076
	lda $91,X
	cmp #$40
	bcc label0076
	cmp #$B1
	bcc label0077
label0076:
	lda #$30
	sec 
	sbc $048D
	sta $048D
	inc $0489
	bne label0078
label0077:
	lda $91,X
	sta $99
	lda $0448,X
	sta $0450
label0078:
	rts 

Routinelabel0018:
	lda $87
	bpl label0080
	jsr Routinelabel0015
	jsr Routinelabel0014
	lda $048B
	bpl label0079
	rts 
label0079:
	lda #$40
	sta $F3
label0080:
	jsr Routinelabel0017
	jsr Routinelabel0016
	jmp label0059

Routinelabel0019:
	ldx #$01
label0081:
	lda #$FF
	sta $0530,X
	sta $0544,X
	dex 
	bpl label0081
	jsr Routinelabel0021

Routinelabel0020:
	ldx $3C
	cpx #$18
	bcc label0082
	ldx #$18
label0082:
	lda $C73E,X
	sta $BA
	lda $C757,X
	sta $B8
	lda #$F0
	sta $02E0
	sta $02E4
	sta $02E8
	lda #$03
	jmp label0095

Routinelabel0021:
label0083:
	lda $A3
	bpl label0085
label0084:
	sta $A4
	rts 
label0085:
	jsr Routinelabel0115
label0086:
	cmp $A3
	bcc label0084
	beq label0084
	clc 
	sbc $A3
	jmp label0086

Routinelabel0022:
	lda $19
	and #$7F
	beq label0088
label0087:
	rts 
label0088:
	dec $B8
	bne label0087
	ldx #$00
	lda $0530,X
	bmi label0089
	inx 
	lda $0530,X
	bmi label0089
	lda #$01
	sta $B8
	rts 
label0089:
	ldy $A4
	sty $A5
	bpl label0090
	rts 
label0090:
	lda #$80
	sta $04B8,X
	sta $04CC,X
	lda #$00
	sta $0530,X
	lda $00B2,Y
	sta $0490,X
	lda $00B5,Y
	sta $04A4,X
	ldy $BA
	jsr Routinelabel0115
	and #$1F
	adc $C895,Y
	sta $0508,X
	lda $C8A1,Y
	sta $051C,X
	lda $C89B,Y
	sta $04E0,X
	lda $C8A7,Y
	sta $04F4,X
	jsr Routinelabel0115
	and #$03
	sta $0544,X
	tay 
	lda $C88D,Y
	clc 
	adc $0490,X
	sta $0490,X
	lda $C891,Y
	clc 
	adc $04A4,X
	sta $04A4,X
	lda $C885,Y
	beq label0091
	jsr Routinelabel0029
label0091:
	lda $C889,Y
	beq label0092
	jsr Routinelabel0031
label0092:
	lda $BA
	cmp #$05
	bcs label0093
	inc $BA
label0093:
	lda #$06
	sec 
	sbc $BA
	sta $B8
	lda $F0
	ora #$04
	sta $F0
	jmp label0083

Routinelabel0023:
	lda $B8
	cmp #$01
	bne label0096
	lda $0530
	bmi label0094
	lda $0531
	bmi label0094
	lda #$02
	sta $B8
	rts 
label0094:
	lda $19
	and #$7F
	cmp #$40
	bcc label0096
	bne label0095
	lda $F1
	ora #$08
	sta $F1

Routinelabel0024:
label0095:
	and #$03
	tax 
	lda $C881,X
	sta $5A
	ldx $A4
	bmi label0096
	lda #$23
	sta $57
	lda $A6,X
	sta $58
	lda #$01
	sta $59
	jsr Routinelabel0025
	lda $A9,X
	sta $58
	jsr Routinelabel0025
	lda $AC,X
	sta $58
	jsr Routinelabel0025
	lda $AF,X
	sta $58

Routinelabel0025:
	lda #$57
	ldy #$00
	jmp label0021
label0096:
	rts 

Routinelabel0026:
	ldx #$01
label0097:
	lda $0530,X
	bpl label0098
	jmp label0107
label0098:
	lda $0544,X
	bmi label0101
	tay 
	txa 
	pha 
	ldx $A5
	lda $B2,X
	adc $C9DB,Y
	sta $02E3
	sta $02E7
	sta $02EB
	lda $B5,X
	adc $C9EB,Y
	sta $02E0
	adc $C9FB,Y
	sta $02E4
	adc $C9FB,Y
	sta $02E8
	tya 
	and #$03
	tax 
	tya 
	lsr A
	lsr A
	tay 
	lda $19
	lsr A
	lsr A
	bcs label0099
	tya 
	adc #$05
	tay 
label0099:
	lda $CA0B,Y
	sta $02E1
	lda $CA15,Y
	sta $02E5
	lda $CA1F,Y
	sta $02E9
	lda $CA29,X
	sta $02E2
	sta $02E6
	sta $02EA
	pla 
	tax 
	lda $19
	and #$07
	bne label0100
	lda $0544,X
	clc 
	adc #$04
	sta $0544,X
	cmp #$14
	bcc label0100
	lda #$FF
	sta $0544,X
label0100:
	lda $0544,X
	cmp #$10
	bcs label0101
	jmp label0107
label0101:
	jsr Routinelabel0027
	lda $0490,X
	cmp #$02
	bcs label0102
	jsr Routinelabel0028
label0102:
	lda $0490,X
	cmp #$F7
	bcc label0103
	jsr Routinelabel0028
label0103:
	lda $04A4,X
	cmp #$02
	bcs label0104
	jsr Routinelabel0030
label0104:
	lda $04A4,X
	cmp #$E0
	bcc label0105
	lda #$FF
	sta $0530,X
	lda #$F0
	sta $04A4,X
	jmp label0107
label0105:
	jsr Routinelabel0032
	jsr Routinelabel0033
	ldy $0530,X
	iny 
	tya 
	and #$07
	sta $0530,X
	ldy $0530,X
	lda $C9D3,Y
	sta $12
	txa 
	asl A
	asl A
	clc 
	tay 
	lda $04A4,X
	cmp #$D0
	sta $0200,Y
	lda $0490,X
	sta $0203,Y
	lda $12
	sta $0201,Y
	lda #$00
	bcc label0106
	lda #$20
label0106:
	sta $0202,Y
label0107:
	dex 
	bmi label0108
	jmp label0097
label0108:
	rts 

Routinelabel0027:
	lda $0508,X
	clc 
	adc $04B8,X
	sta $04B8,X
	lda $04E0,X
	adc $0490,X
	sta $0490,X
	lda $051C,X
	clc 
	adc $04CC,X
	sta $04CC,X
	lda $04F4,X
	adc $04A4,X
	sta $04A4,X
	rts 

Routinelabel0028:
	lda $F3
	ora #$80
	sta $F3

Routinelabel0029:
	lda #$00
	sec 
	sbc $0508,X
	sta $0508,X
	lda #$00
	sbc $04E0,X
	sta $04E0,X
	rts 

Routinelabel0030:
	lda $F3
	ora #$80
	sta $F3

Routinelabel0031:
	lda #$00
	sec 
	sbc $051C,X
	sta $051C,X
	lda #$00
	sbc $04F4,X
	sta $04F4,X
	rts 

Routinelabel0032:
	ldy $CD
label0109:
	lda #$00
	sta $CC
	lda ($27),Y
	sec 
	sbc #$08
	cmp $04A4,X
	bcs label0117
	adc #$03
	cmp $04A4,X
	bcc label0110
	lda #$01
	bne label0111
label0110:
	lda ($29),Y
	cmp $04A4,X
	bcc label0117
	sbc #$03
	cmp $04A4,X
	bcs label0114
	lda #$02
label0111:
	sta $CC
	lda ($23),Y
	cmp #$10
	beq label0112
	sec 
	sbc #$04
	cmp $0490,X
	bcs label0113
label0112:
	lda ($25),Y
	cmp $0490,X
	bcs label0114
label0113:
	lda #$00
	sta $CC
label0114:
	lda ($23),Y
	cmp #$10
	beq label0115
	sec 
	sbc #$08
	cmp $0490,X
	bcs label0117
	adc #$03
	cmp $0490,X
	bcc label0115
	lda $CC
	ora #$04
	bne label0116
label0115:
	lda ($25),Y
	cmp #$FF
	beq label0117
	cmp $0490,X
	bcc label0117
	sbc #$03
	bcs label0117
	lda $CC
	ora #$08
label0116:
	sta $CC
label0117:
	lda $CC
	bne label0120
label0118:
	dey 
	bmi label0119
	jmp label0109
label0119:
	rts 
label0120:
	lsr $CC
	bcc label0121
	lda $04F4,X
	bmi label0121
	jsr Routinelabel0030
label0121:
	lsr $CC
	bcc label0122
	lda $04F4,X
	bpl label0122
	jsr Routinelabel0030
label0122:
	lsr $CC
	bcc label0123
	lda $04E0,X
	bmi label0123
	jsr Routinelabel0028
label0123:
	lsr $CC
	bcc label0124
	lda $04E0,X
	bpl label0124
	jsr Routinelabel0028
label0124:
	jmp label0118

Routinelabel0033:
	ldy #$01
label0125:
	lda $0088,Y
	bmi label0126
	beq label0126
	lda $00BD,Y
	bne label0126
	lda $0490,X
	sec 
	sbc $0091,Y
	jsr Routinelabel0103
	cmp #$08
	bcs label0126
	lda $04A4,X
	sec 
	sbc $009A,Y
	sec 
	sbc #$08
	jsr Routinelabel0103
	cmp #$0C
	bcs label0126
	lda #$00
	sta $0088,Y
	lda #$01
	sta $007F,Y
	sta $00C1,Y
	lda #$0B
	sta $0451,Y
	lda #$20
	sta $045A,Y
	lda $F0
	ora #$80
	sta $F0
	lda #$F0
	sta $04A4,X
	lda #$FF
	sta $0530,X
label0126:
	dey 
	bpl label0125
	rts 

Routinelabel0034:
	ldx $05D1
	bmi label0129
label0127:
	jsr Routinelabel0035
	lda $0604,X
	beq label0128
	txa 
	eor $19
	and #$01
	bne label0128
	ldy $05FA,X
	iny 
	tya 
	and #$03
	sta $05FA,X
	jsr Routinelabel0038
	lda $05FA,X
	cmp #$01
	bne label0128
	dec $060E,X
	bne label0128
	dec $0604,X
label0128:
	dex 
	bpl label0127
label0129:
	rts 

Routinelabel0035:
	ldy #$07
	lda $0604,X
	bne label0130
	jmp label0136
label0130:
	lda $0088,Y
	bmi label0135
	beq label0135
	cpy #$02
	bcc label0131
	cmp #$01
	beq label0135
label0131:
	lda $0091,Y
	clc 
	adc #$08
	sec 
	sbc $05D2,X
	sta $12
	jsr Routinelabel0103
	cmp #$12
	bcs label0135
	lda $009A,Y
	clc 
	adc #$0C
	sec 
	sbc $05DC,X
	sta $13
	jsr Routinelabel0103
	cmp #$12
	bcs label0135
	lda $12
	bmi label0132
	cmp #$03
	bcc label0133
	lda #$02
	sta $041B,Y
	jsr Routinelabel0036
	jsr Routinelabel0097
	bne label0133
label0132:
	cmp #$FD
	bcs label0133
	lda #$FE
	sta $041B,Y
	jsr Routinelabel0097
	jsr Routinelabel0036
label0133:
	lda $13
	bmi label0134
	cmp #$03
	bcc label0135
	lda #$02
	sta $042D,Y
	jsr Routinelabel0096
	jsr Routinelabel0036
	bne label0135
label0134:
	cmp #$FD
	bcs label0135
	lda #$FE
	sta $042D,Y
	jsr Routinelabel0096
	jsr Routinelabel0036
label0135:
	dey 
	bpl label0130
	rts 

Routinelabel0036:
	lda $F1
	ora #$02
	sta $F1
	rts 
label0136:
	lda $0088,Y
	bmi label0139
	beq label0139
	cpy #$02
	bcc label0137
	lda $05FA,X
	cmp #$03
	bne label0137
	lda $05D2,X
	sec 
	sbc #$0A
	cmp $0091,Y
	bcs label0137
	adc #$04
	cmp $0091,Y
	bcc label0137
	lda $05DC,X
	sec 
	sbc #$1C
	cmp $009A,Y
	bcs label0137
	adc #$04
	cmp $009A,Y
	bcc label0137
	jsr Routinelabel0037
label0137:
	lda $0091,Y
	clc 
	adc #$08
	sec 
	sbc $05D2,X
	jsr Routinelabel0103
	sta $12
	lda $009A,Y
	clc 
	adc #$0C
	sec 
	sbc $05DC,X
	jsr Routinelabel0103
	sta $13
	lda $05FA,X
	cmp #$03
	beq label0138
	lda $12
	pha 
	lda $13
	sta $12
	pla 
	sta $13
label0138:
	lda $12
	cmp #$14
	bcs label0139
	lda $13
	cmp #$0B
	bcs label0139
	lda #$01
	sta $0604,X
	lda #$32
	sta $060E,X
label0139:
	dey 
	bmi label0140
	jmp label0136
label0140:
	rts 

Routinelabel0037:
	txa 
	pha 
	tya 
	tax 
	inc $CB
	jsr Routinelabel0091
	pla 
	tax 
	rts 

Routinelabel0038:
	lda $05F0,X
	sta $57
	lda $05E6,X
	sta $58
	lda #$03
	sta $59
	ldy $05FA,X
	lda $CD1C,Y
	sta $5A
	lda $CD20,Y
	sta $5B
	lda $CD24,Y
	sta $5C
	jsr Routinelabel0039
	lda $CD28,Y
	sta $5A
	lda $CD2C,Y
	sta $5B
	lda $CD30,Y
	sta $5C
	jsr Routinelabel0039
	lda $CD34,Y
	sta $5A
	lda $CD38,Y
	sta $5B
	lda $CD3C,Y
	sta $5C

Routinelabel0039:
	tya 
	pha 
	lda #$57
	ldy #$00
	jsr Routinelabel0006
	pla 
	tay 
	lda $58
	clc 
	adc #$20
	sta $58
	bcc label0141
	inc $57
label0141:
	rts 

Routinelabel0040:
	ldx #$09
label0142:
	lda #$FF
	sta $055D,X
	lda #$F0
	sta $057B,X
	dex 
	bpl label0142
	rts 

Routinelabel0041:
	dec $05CC
	beq label0143
	rts 
label0143:
	lda $1B
	and #$3F
	adc #$28
	sta $05CC
	ldx #$09
label0144:
	lda $055D,X
	bmi label0145
	dex 
	bpl label0144
	rts 
label0145:
	lda #$00
	sta $055D,X
	sta $0599,X
	sta $058F,X
	lda #$80
	sta $0571,X
	sta $0585,X
	lda #$D0
	sta $057B,X
	jsr Routinelabel0115
	and #$03
	tay 
	lda $CEA4,Y
	sta $0567,X
	ldy #$00
	lda $1B
	sta $05B7,X
	bpl label0146
	dey 
label0146:
	tya 
	sta $05C1,X
	dec $05CB
	rts 

Routinelabel0042:
	ldx #$09
label0147:
	lda $055D,X
	bmi label0151
	beq label0148
	lda $0599,X
	sta $12
	lda $058F,X
	sta $13
	jsr Routinelabel0114
	lda $05B7,X
	clc 
	adc $12
	sta $05B7,X
	sta $12
	lda $05C1,X
	adc $13
	sta $05C1,X
	sta $13
	jsr Routinelabel0114
	lda $0599,X
	sec 
	sbc $12
	sta $0599,X
	lda $058F,X
	sbc $13
	sta $058F,X
	lda $0571,X
	clc 
	adc $0599,X
	sta $0571,X
	lda $0567,X
	adc $058F,X
	sta $0567,X
label0148:
	lda $0585,X
	sec 
	sbc $055A
	sta $0585,X
	bcs label0149
	dec $057B,X
label0149:
	lda $057B,X
	cmp #$F0
	beq label0150
	cmp #$A8
	bcs label0151
	lda #$01
	sta $055D,X
	bne label0151
label0150:
	lda #$FF
	sta $055D,X
label0151:
	jsr Routinelabel0043
	jsr Routinelabel0044
	dex 
	bmi label0152
	jmp label0147
label0152:
	rts 

Routinelabel0043:
label0153:
	ldy $055D,X
	iny 
	lda $CEA8,Y
	sta $13
	txa 
	sta $12
	asl A
	adc $12
	asl A
	asl A
	tay 
	lda $057B,X
	sta $0250,Y
	sta $0254,Y
	clc 
	adc #$08
	sta $0258,Y
	lda $0567,X
	sta $0253,Y
	clc 
	adc #$04
	sta $025B,Y
	clc 
	adc #$04
	sta $0257,Y
	lda $13
	sta $0252,Y
	sta $0256,Y
	sta $025A,Y
	lda $055D,X
	bmi label0154
	lda #$A8
	sta $0251,Y
	lda #$A9
	sta $0255,Y
	lda $19
	lsr A
	lsr A
	lsr A
	lsr A
	and #$07
	stx $13
	tax 
	lda $CEAB,X
	sta $0259,Y
	lda $025A,Y
	eor $CEB3,X
	sta $025A,Y
	ldx $13
	rts 
label0154:
	lda #$F0
	sta $057B,X
	lda #$AC
	sta $0251,Y
	lda #$AD
	sta $0255,Y
	lda #$FC
	sta $0259,Y
	rts 

Routinelabel0044:
	ldy #$01
label0155:
	lda $0088,Y
	bmi label0156
	beq label0156
	lda $055D,X
	bmi label0157
	lda $009A,Y
	cmp #$C0
	bcs label0156
	sec 
	sbc $057B,X
	jsr Routinelabel0103
	cmp #$18
	bcs label0156
	lda $0091,Y
	sec 
	sbc $0567,X
	jsr Routinelabel0103
	cmp #$10
	bcs label0156
	lda #$FF
	sta $055D,X
	lda $05CD,Y
	clc 
	adc #$01
	sta $05CD,Y
	lda #$02
	sta $F0
	rts 
label0156:
	dey 
	bpl label0155
label0157:
	rts 
label0158:
	lda #$20
	sta $F2
	jsr Routinelabel0045
	jsr Routinelabel0040
	ldx $40
label0159:
	lda $41,X
	bmi label0160
	jsr Routinelabel0118
label0160:
	dex 
	bpl label0159
	ldx #$00
	stx $BD
	stx $BE
	lda #$14
	sta $05CB
label0161:
	jsr Routinelabel0125
	inc $4C
	jsr Routinelabel0078
	jsr Routinelabel0085
	lda $05CB
	beq label0162
	jsr Routinelabel0041
label0162:
	jsr Routinelabel0042
	lda $05CB
	bne label0161
	ldx #$09
label0163:
	lda $055D,X
	bpl label0161
	dex 
	bpl label0163
	lda $19
	bne label0161
	jsr Routinelabel0051
	ldx #$02
	stx $46
	jsr Routinelabel0122
	lda #$21
	ldy #$D1
	jsr Routinelabel0006
	lda #$50
	ldy #$D1
	jsr Routinelabel0006
	lda #$5B
	ldy #$D1
	jsr Routinelabel0006
	ldx $40
label0164:
	lda #$20
	sta $91,X
	lda $D194,X
	sta $9A,X
	lda #$03
	sta $7F,X
	lda #$01
	sta $0448,X
	jsr Routinelabel0118
	jsr Routinelabel0083
	dex 
	bpl label0164
	lda #$44
	sta $0567
	sta $0568
	lda #$54
	sta $057B
	lda #$74
	sta $057C
	lda #$01
	sta $055D
	sta $055E
	ldx $40
label0165:
	jsr Routinelabel0043
	dex 
	bpl label0165
	jsr Routinelabel0121
	lda #$2B
	sta $57
	lda #$24
	sta $58
	sta $59
	lda #$0C
	sta $54
	lda #$0B
	sta $55
	lda #$05
	sta $56
	lda $05CD
	jsr Routinelabel0048
	lda $40
	beq label0166
	lda #$0F
	sta $55
	lda $05CE
	jsr Routinelabel0048
label0166:
	jsr Routinelabel0121
	lda $0559
	sta $57
	lda #$00
	sta $58
	sta $59
	lda #$08
	sta $54
	lda #$0B
	sta $55
	lda #$03
	sta $56
	lda $0559
	jsr Routinelabel0004
	lda $40
	beq label0167
	lda #$0F
	sta $55
	jsr Routinelabel0004
label0167:
	lda #$FF
	sta $055D
	sta $055E
	ldx $40
label0168:
	jsr Routinelabel0043
	dex 
	bpl label0168
	lda #$02
	sta $F0
	ldx #$02
	jsr Routinelabel0122
	ldx $40
label0169:
	jsr Routinelabel0043
	dex 
	bpl label0169
	jsr Routinelabel0047
	jsr Routinelabel0121
	lda #$01
	sta $F0
	jsr Routinelabel0046
	bne label0171
	lda #$66
	ldy #$D1
	jsr Routinelabel0006
	jsr Routinelabel0123
	ldx #$1A
label0170:
	lda $D17A,X
	sta $57,X
	dex 
	bpl label0170
	lda $055B
	sta $68
	lda $055C
	sta $69
	jsr Routinelabel0005
	lda #$10
	sta $F2
label0171:
	ldx #$78
	jsr Routinelabel0122
	jsr Routinelabel0047
label0172:
	lda #$00
	sta $3E
	ldx #$04
	jsr Routinelabel0050
	jsr Routinelabel0005
	lda $40
	beq label0173
	inc $3E
	ldx #$12
	jsr Routinelabel0050
	lda #$65
	ldy #$00
	jsr Routinelabel0006
label0173:
	lda #$01
	sta $F1
	ldx #$02
	jsr Routinelabel0122
	lda $5D
	cmp #$24
	bne label0172
	lda $40
	beq label0174
	lda $006B
	cmp #$24
	bne label0172
label0174:
	ldx #$0A
	jsr Routinelabel0122
	jsr Routinelabel0046
	bne label0176
	lda $055B
	sta $47
	lda $055C
	sta $48
	lda $40
	sta $3E
label0175:
	jsr Routinelabel0071
	dec $3E
	bpl label0175
	lda #$01
	sta $F1
	jsr Routinelabel0121
label0176:
	lda #$00
	sta $47
	sta $48
	ldx #$01
label0177:
	lda $41,X
	bpl label0178
	sta $88,X
label0178:
	dex 
	bpl label0177
	jmp label0485

Routinelabel0045:
	ldx $0558
	lda $D103,X
	sta $0559
	lda $D108,X
	sta $055A
	lda $D10D,X
	sta $055B
	lda $D112,X
	sta $055C
	cpx #$04
	bcs label0179
	inc $0558
label0179:
	lda #$00
	sta $05CD
	sta $05CE
	rts 

Routinelabel0046:
	lda $05CD
	clc 
	adc $05CE
	cmp #$14
	rts 

Routinelabel0047:
	ldx #$1C
label0180:
	lda $D134,X
	sta $57,X
	dex 
	bpl label0180
	ldx #$04
	ldy $05CD
	jsr Routinelabel0049
	ldx #$12
	ldy $05CE
	jsr Routinelabel0049
	jsr Routinelabel0005
	lda $40
	bne label0181
	rts 
label0181:
	lda #$65
	ldy #$00
	jmp label0021

Routinelabel0048:
	ldy #$00
label0182:
	cmp #$0A
	bcc label0183
	iny 
	sbc #$0A
	jmp label0182
label0183:
	sty $5A
	sta $5B
	jmp label0018

Routinelabel0049:
label0184:
	dey 
	bmi label0187
	lda $0559
	clc 
	adc $59,X
	cmp #$0A
	bcc label0185
	sbc #$0A
	inc $58,X
label0185:
	sta $59,X
	lda $58,X
	cmp #$0A
	bcc label0186
	sbc #$0A
	inc $57,X
	sta $58,X
label0186:
	jmp label0184
label0187:
	ldy #$00
label0188:
	lda $57,X
	beq label0189
	cmp #$24
	bne label0190
label0189:
	lda #$24
	sta $57,X
	inx 
	iny 
	cpy #$04
	bne label0188
label0190:
	rts 

Routinelabel0050:
	lda $59,X
	cmp #$24
	beq label0193
	tay 
	bne label0192
	lda $58,X
	cmp #$24
	beq label0193
	lda $58,X
	bne label0191
	lda $57,X
	cmp #$24
	beq label0193
	lda #$0A
	sta $58,X
	dec $57,X
label0191:
	lda #$0A
	sta $59,X
	dec $58,X
label0192:
	dec $59,X
	txa 
	pha 
	lda #$0A
	jsr Routinelabel0072
	pla 
	tax 
label0193:
	jmp label0187

Routinelabel0051:
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
	jsr Routinelabel0052
	jsr Routinelabel0052
	jsr Routinelabel0001
	jsr Routinelabel0003
	ldx #$3F
	ldy #$00
	sty $4C
label0194:
	lda #$F0
	sta $0200,Y
	iny 
	iny 
	iny 
	iny 
	dex 
	bpl label0194
	rts 

Routinelabel0052:
	ldx #$F0
	lda #$24
label0195:
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
	dex 
	bne label0195
	ldx #$40
	lda #$00
label0196:
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bne label0196
	rts 

Routinelabel0053:
	jsr Routinelabel0002
	jsr Routinelabel0000
	lda $16
	beq label0197
	jmp label0223
label0197:
	ldy $3B
	lda $DB20,Y
	sta $1D
	lda $DB30,Y
	sta $1E
	jsr Routinelabel0056
	ldx #$00
label0198:
	jsr Routinelabel0057
	cmp #$FF
	beq label0201
	sta $54
	jsr Routinelabel0057
	sta $55
	ldy #$03
label0199:
	jsr Routinelabel0059
	lda #$04
	sta $12
	lda $D489,Y
label0200:
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	clc 
	adc #$04
	dec $12
	bne label0200
	inc $55
	dey 
	bpl label0199
	lda $55
	sec 
	sbc #$04
	sta $55
	jsr Routinelabel0060
	sta $A6,X
	inc $54
	inc $54
	jsr Routinelabel0060
	sta $A9,X
	inc $55
	inc $55
	jsr Routinelabel0060
	sta $AF,X
	dec $54
	dec $54
	jsr Routinelabel0060
	sta $AC,X
	stx $A4
	lda #$03
	jsr Routinelabel0024
	jsr Routinelabel0008
	ldx $A4
	lda $54
	asl A
	asl A
	asl A
	clc 
	adc #$10
	sta $B2,X
	lda $55
	asl A
	asl A
	asl A
	sta $B5,X
	inx 
	jmp label0198
label0201:
	dex 
	stx $A3
	ldx #$00
label0202:
	jsr Routinelabel0057
	cmp #$FF
	beq label0203
	sta $54
	jsr Routinelabel0057
	sta $55
	jsr Routinelabel0057
	sta $05FA,X
	lda $54
	asl A
	asl A
	asl A
	adc #$0C
	sta $05D2,X
	lda $55
	asl A
	asl A
	asl A
	adc #$0C
	sta $05DC,X
	lda #$00
	sta $0604,X
	jsr Routinelabel0059
	sta $05E6,X
	lda $13
	sta $05F0,X
	jsr Routinelabel0062
	jsr Routinelabel0061
	inc $54
	inc $54
	jsr Routinelabel0061
	inc $55
	inc $55
	jsr Routinelabel0061
	dec $54
	dec $54
	jsr Routinelabel0061
	inx 
	jmp label0202
label0203:
	dex 
	stx $05D1
	jsr Routinelabel0057
	sta $1F
	jsr Routinelabel0057
	sta $20
	ldy #$00
	lda ($1F),Y
	tax 
	dex 
	bpl label0204
	inc $C8
	jmp label0206
label0204:
	iny 
label0205:
	lda ($1F),Y
	iny 
	sta $93,X
	lda ($1F),Y
	iny 
	sta $9C,X
	lda ($1F),Y
	iny 
	sta $0453,X
	lda #$02
	sta $81,X
	lda #$01
	sta $8A,X
	lda $C6
	sta $0441,X
	dex 
	bpl label0205
label0206:
	jsr Routinelabel0057
	sta $CD
	jsr Routinelabel0057
	sta $23
	jsr Routinelabel0057
	tay 
	sta $24
	lda $23
	jsr Routinelabel0055
	sta $25
	sty $26
	jsr Routinelabel0055
	sta $27
	sty $28
	jsr Routinelabel0055
	sta $29
	sty $2A
label0207:
	jsr Routinelabel0067
	jsr Routinelabel0054
	jsr Routinelabel0001
	jmp label0017

Routinelabel0054:
	ldx #$22
label0208:
	lda $D42D,X
	sta $57,X
	dex 
	bpl label0208
	lda $C8
	bne label0211
	lda $3B
	and #$0C
	ora #$03
	tay 
	ldx #$03
label0209:
	lda $D450,Y
	sta $5A,X
	dey 
	dex 
	bpl label0209
label0210:
	jmp label0020
label0211:
	ldx $0558
	lda $D460,X
	sta $1D
	lda $D465,X
	sta $1E
	ldx #$03
	ldy #$07
label0212:
	lda ($1D),Y
	sta $72,X
	dey 
	dex 
	bpl label0212
	lda $16
	bne label0210
label0213:
	lda ($1D),Y
	sta $005A,Y
	dey 
	bpl label0213
	bmi label0210

Routinelabel0055:
	sec 
	adc $CD
	bcc label0214
	iny 
label0214:
	rts 

Routinelabel0056:
label0215:
	jsr Routinelabel0057
	sta $1F
	jsr Routinelabel0057
	sta $20
	tax 
	beq label0220
label0216:
	jsr Routinelabel0058
	tax 
	beq label0215
	and #$7F
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	jsr Routinelabel0058
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	jsr Routinelabel0058
	sta $12
	txa 
	and #$80
	lsr A
	lsr A
	lsr A
	lsr A
	lsr A
	ora $00
	;---------------------
	;        sta $2000  PPUC1
	jsr rsta_2000
	;------------
	txa 
	and #$40
	bne label0218
label0217:
	jsr Routinelabel0058
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dec $12
	bne label0217
	beq label0216
label0218:
	jsr Routinelabel0058
label0219:
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dec $12
	bne label0219
	beq label0216
label0220:
	rts 

Routinelabel0057:
	ldy #$00
	lda ($1D),Y
	inc $1D
	bne label0221
	inc $1E
label0221:
	rts 

Routinelabel0058:
	ldy #$00
	lda ($1F),Y
	inc $1F
	bne label0222
	inc $20
label0222:
	rts 

Routinelabel0059:
	lda $55
	sta $12
	lda #$00
	asl $12
	asl $12
	asl $12
	asl $12
	rol A
	asl $12
	rol A
	ora #$20
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	sta $13
	lda $12
	ora $54
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	rts 

Routinelabel0060:
	lda $55
	and #$FC
	asl A
	sta $12
	lda $54
	lsr A
	lsr A
	ora $12
	ora #$C0
	pha 
	lda $55
	and #$02
	sta $12
	lda $54
	and #$02
	lsr A
	ora $12
	tay 
	pla 
	rts 

Routinelabel0061:
	lda #$23
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	jsr Routinelabel0060
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	;---------------------
	;        lda $2007  PPUMEMDATA
	jsr rlda_2007
	;------------
	;---------------------
	;        lda $2007  PPUMEMDATA
	jsr rlda_2007
	;------------
	and $D55A,Y
	ora $D55E,Y
	pha 
	lda #$23
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	jsr Routinelabel0060
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	pla 
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	rts 

Routinelabel0062:
	jsr Routinelabel0038
	jmp label0023
label0223:
	lda #$C0
	ldy #$23
	jsr Routinelabel0063
	lda #$C0
	ldy #$27
	jsr Routinelabel0063
	ldy #$23
	lda #$60
	jsr Routinelabel0065
	ldy #$27
	lda #$60
	jsr Routinelabel0065
	inc $C8
	jmp label0207

Routinelabel0063:
	;---------------------
	;        sty $2006  PPUMEMADDR
	jsr rsty_2006
	;------------
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	ldx #$00
label0224:
	lda $DCA4,X
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	inx 
	cpx #$08
	bne label0224
	lda #$00
	ldx #$28
	jsr Routinelabel0064
	lda #$AA
	ldx #$10

Routinelabel0064:
label0225:
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bne label0225
	rts 

Routinelabel0065:
	;---------------------
	;        sty $2006  PPUMEMADDR
	jsr rsty_2006
	;------------
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	ldx #$20
	lda #$58
	jsr Routinelabel0066
	ldx #$40
	lda #$5C

Routinelabel0066:
	sta $12
label0226:
	txa 
	and #$03
	eor #$03
	ora $12
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bne label0226
	rts 

Routinelabel0067:
	ldx #$00
label0227:
	jsr Routinelabel0070
	jsr Routinelabel0068
	lda $51
	ora #$04
	sta $51
	jsr Routinelabel0068
	inx 
	inx 
	cpx #$80
	bne label0227
	rts 

Routinelabel0068:
	lda $51
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda $50
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	;---------------------
	;        lda $2007  PPUMEMDATA
	jsr rlda_2007
	;------------
	;---------------------
	;        lda $2007  PPUMEMDATA
	jsr rlda_2007
	;------------
	cmp #$24
	bne label0228
	txa 
	and #$03
	tay 
	jmp label0231
label0228:
	rts 

Routinelabel0069:
	lda $4C
	beq label0230
	dec $4C
	lda $4F
	clc 
	adc #$02
	and #$3F
	sta $4F
	tax 
	jsr Routinelabel0070
	lda $51
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda $50
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	;---------------------
	;        lda $2007  PPUMEMDATA
	jsr rlda_2007
	;------------
	;---------------------
	;        lda $2007  PPUMEMDATA
	jsr rlda_2007
	;------------
	ldy #$03
label0229:
	cmp $D642,Y
	beq label0231
	dey 
	bpl label0229
label0230:
	rts 
label0231:
	lda $51
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda $50
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda $D643,Y
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	rts 

Routinelabel0070:
	lda $D652,X
	sta $50
	lda $D653,X
	sta $51
	rts 

Routinelabel0071:
	lda #$00

Routinelabel0072:
	sta $43
	lda $3A
	beq label0233
label0232:
	rts 
label0233:
	ldx $3E
	cpx #$02
	bcs label0232
	lda $41,X
	bmi label0232
	ldy #$64
	jsr Routinelabel0073
	clc 
	adc $48
	sta $45
	ldy #$0A
	jsr Routinelabel0073
	sta $44
	ldx $3F
	lda $D76F,X
	sta $21
	lda #$06
	sta $22
	lda $3E
	asl A
	asl A
	ora $3E
	tax 
	clc 
	lda $03,X
	adc $43
	jsr Routinelabel0074
	sta $03,X
	lda $04,X
	adc $44
	jsr Routinelabel0074
	sta $04,X
	lda $05,X
	adc $45
	jsr Routinelabel0074
	sta $05,X
	lda $06,X
	adc $47
	jsr Routinelabel0074
	sta $06,X
	lda $07,X
	adc #$00
	jsr Routinelabel0074
	sta $07,X
	inx 
	inx 
	inx 
	inx 
	ldy #$04
label0234:
	lda $03,X
	cmp ($21),Y
	bcc label0237
	bne label0235
	dex 
	dey 
	bpl label0234
label0235:
	ldy #$00
	lda $3E
	asl A
	asl A
	ora $3E
	tax 
label0236:
	lda $03,X
	sta ($21),Y
	inx 
	iny 
	cpy #$05
	bne label0236
label0237:
	ldy #$04
label0238:
	lda ($21),Y
	sta $000D,Y
	dey 
	bpl label0238
	inc $46
	lda $16
	beq label0239
	jsr Routinelabel0012
label0239:
	rts 

Routinelabel0073:
	sty $12
	ldx #$FF
	lda $43
label0240:
	sec 
	sbc $12
	inx 
	bcs label0240
	clc 
	adc $12
	sta $43
	txa 
	rts 

Routinelabel0074:
	cmp #$0A
	bcs label0241
	rts 
label0241:
	sec 
	sbc #$0A
	rts 

Routinelabel0075:
	ldy $46
	dey 
	beq label0242
	bpl label0247
	rts 
label0242:
	lda #$20
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$43
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$8E
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	ldx #$04
label0243:
	lda $03,X
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bpl label0243
	lda #$00
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	lda #$24
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	ldx #$8C
	;---------------------
	;        stx $2007  PPUMEMDATA
	jsr rstx_2007
	;------------
	inx 
	;---------------------
	;        stx $2007  PPUMEMDATA
	jsr rstx_2007
	;------------
	ldx #$04
label0244:
	lda $0D,X
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bpl label0244
	lda #$00
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	lda #$24
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	lda $16
	bne label0254
	lda $40
	beq label0246
	lda #$8F
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	ldx #$04
label0245:
	lda $08,X
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bpl label0245
	lda #$00
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
label0246:
	dec $46
	rts 
label0247:
	dec $46
	lda #$20
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$62
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda $41
	jsr Routinelabel0076
	lda $40
	beq label0251
	lda #$20
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda #$75
	;---------------------
	;        sta $2006  PPUMEMADDR
	jsr rsta_2006
	;------------
	lda $42

Routinelabel0076:
	bmi label0252
label0248:
	sta $50
	ldx #$06
label0249:
	lda #$24
	cpx $50
	bcs label0250
	lda #$2A
label0250:
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bpl label0249
label0251:
	rts 
label0252:
	lda $40
	beq label0248
	ldx #$08
label0253:
	lda $D841,X
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dex 
	bpl label0253
	rts 
label0254:
	ldy #$04
label0255:
	lda $D862,Y
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dey 
	bpl label0255
	lda $4A
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	lda $49
	;---------------------
	;        sta $2007  PPUMEMDATA
	jsr rsta_2007
	;------------
	dec $46
	rts 

Routinelabel0077:
	sta $12
	stx $13
	sty $14
	ldx #$01
label0256:
	lda $061A,X
	bmi label0257
	dex 
	bpl label0256
	ldx #$01
	lda $0619
	cmp $0618
	bcc label0257
	dex 
label0257:
	lda #$64
	sta $0618,X
	lda $12
	sta $061A,X
	tay 
	txa 
	asl A
	asl A
	asl A
	tax 
	lda $D8C7,Y
	sta $02F1,X
	lda $D8CD,Y
	sta $02F5,X
	ldy $13
	lda $009A,Y
	sec 
	sbc #$08
	sta $02F0,X
	sta $02F4,X
	lda $0091,Y
	sta $02F3,X
	clc 
	adc #$08
	sta $02F7,X
	lda $3E
	sta $02F2,X
	sta $02F6,X
	ldy $14
	ldx $13
	lda $12
	rts 

Routinelabel0078:
	ldx #$01
label0258:
	lda $061A,X
	bmi label0259
	dec $0618,X
	bne label0259
	lda #$FF
	sta $061A,X
	txa 
	asl A
	asl A
	asl A
	tay 
	lda #$F0
	sta $02F0,Y
	sta $02F4,Y
label0259:
	dex 
	bpl label0258
	rts 

Routinelabel0079:
	ldx #$01
label0260:
	lda #$00
	sta $0618,X
	lda #$FF
	sta $061A,X
	dex 
	bpl label0260
	rts 

Routinelabel0080:
	jsr Routinelabel0051
	jsr Routinelabel0002
	jsr Routinelabel0123
	jsr Routinelabel0000
	lda #$22
	sta $1D
	lda #$D9
	sta $1E
	jsr Routinelabel0056
	jsr Routinelabel0001
	jmp label0017

Routinelabel0081:
label0261:
	jsr Routinelabel0001
	jsr Routinelabel0080
	lda #$00
	sta $19
label0262:
	jsr Routinelabel0123
	lda $19
	beq label0265
	jsr Routinelabel0082
	jsr Routinelabel0087
	tax 
	and #$10
	bne label0264
	txa 
	and #$20
	beq label0263
	lda #$00
	sta $19
	ldx $3F
	lda $DAFB,X
	sta $3F
label0263:
	jmp label0262
label0264:
	rts 
label0265:
	inc $3A
	inc $40
	lda #$00
	;---------------------
	;        sta $4015  SNDCHANSWITCH
	jsr rsta_4015
	;------------
	sta $16
	jsr Routinelabel0116
	lda #$00
	sta $3A
	beq label0261
	ora ($02,X)
	brk 

Routinelabel0082:
	lda $3F
	lsr A
	sta $16
	lda $3F
	tax 
	and #$01
	sta $40
	lda $DB1D,X
	sta $057B
	lda #$2C
	sta $0567
	ldx #$00
	stx $055D
	jmp label0153

Routinelabel0083:
	lda $E388,X
	sta $1F
	lda $19
	lsr A
	bcc label0266
	lda $E391,X
	sta $1F
label0266:
	lda #$02
	sta $20
	lda $88,X
	bpl label0269
	cmp #$FF
	beq label0267
	jmp label0285
label0267:
	ldy #$14
label0268:
	lda #$F0
	sta ($1F),Y
	dey 
	dey 
	dey 
	dey 
	bpl label0268
	rts 
label0269:
	cpx #$08
	beq label0271
	lda $7F,X
	asl A
	asl A
	adc $0436,X
	cpx #$02
	bcs label0270
	ldy $88,X
	adc $E342,Y
	tay 
	lda $E242,Y
	sta $1D
	lda $E28E,Y
	sta $1E
	lda $BD,X
	beq label0272
	ldy $88,X
	lda $E345,Y
	adc $0436,X
	tay 
	lda $E2DA,Y
	sta $1D
	lda $E2E2,Y
	sta $1E
	jmp label0272
label0270:
	ldy $88,X
	clc 
	adc $E348,Y
	tay 
	lda $E2EA,Y
	sta $1D
	lda $E316,Y
	sta $1E
	bne label0272
label0271:
	ldy $7F,X
	bmi label0267
	lda $E37A,Y
	sta $1D
	lda $E381,Y
	sta $1E
label0272:
	lda $91,X
	sta $15
	lda $9A,X
	sta $12
	txa 
	beq label0274
	cpx #$01
	bne label0273
	lda #$01
	bne label0274
label0273:
	lda $0451,X
	clc 
	adc #$02
	and #$03
label0274:
	ldy $0448,X
	beq label0275
	ora #$40
label0275:
	ldy $88,X
	cpy #$02
	bne label0276
	ldy $7F,X
	cpy #$05
	bne label0276
	eor #$40
label0276:
	ldy $9A,X
	cpy #$C9
	bcs label0277
	cpx #$09
	bne label0278
label0277:
	ora #$20
label0278:
	sta $14
	lda #$39
	sta $21
	lda #$E0
	sta $22
	lda $0448,X
	beq label0279
	lda #$6F
	sta $21
	lda #$E0
	sta $22
label0279:
	ldy #$00
	lda ($1D),Y
	inc $1D
	bne label0280
	inc $1E
label0280:
	asl A
	sta $13
	asl A
	adc $13
	adc $21
	sta $21
	bcc label0281
	inc $22
label0281:
	txa 
	pha 
	ldx #$05
	ldy #$00
label0282:
	lda $12
	clc 
	adc $E033,X
	sta ($1F),Y
	sta $12
	iny 
	sty $13
	ldy #$00
	lda ($1D),Y
	inc $1D
	bne label0283
	inc $1E
label0283:
	ldy $13
	sta ($1F),Y
	iny 
	lda $14
	sta ($1F),Y
	iny 
	sty $13
	ldy #$00
	lda $15
	clc 
	adc ($21),Y
	inc $21
	bne label0284
	inc $22
label0284:
	ldy $13
	sta ($1F),Y
	iny 
	dex 
	bpl label0282
	pla 
	tax 
	rts 
label0285:
	txa 
	pha 
	ldy $1F
	lda $9A,X
	sta $0200,Y
	sta $0204,Y
	clc 
	adc #$08
	sta $0208,Y
	sta $020C,Y
	lda #$F0
	sta $0210,Y
	sta $0214,Y
	lda $91,X
	sta $0203,Y
	sta $020B,Y
	clc 
	adc #$08
	sta $0207,Y
	sta $020F,Y
	lda $9A,X
	cmp #$D0
	lda #$03
	bcc label0286
	lda #$23
label0286:
	sta $0202,Y
	lda $7F,X
	bne label0289
	lda $0202,Y
	sta $0206,Y
	sta $020A,Y
	sta $020E,Y
	lda #$DA
	sta $0201,Y
	lda #$DB
	sta $0205,Y
	lda #$DC
	sta $0209,Y
	lda #$DD
	sta $020D,Y
	ldx $1F
	lda $19
	and #$20
	beq label0288
	lda $19
	and #$40
	bne label0287
	inc $0200,X
	inc $0204,X
	bne label0288
label0287:
	inc $0203,X
	inc $020B,X
label0288:
	pla 
	tax 
	rts 
label0289:
	lda $0202,Y
	ora #$40
	sta $0206,Y
	ora #$80
	sta $020E,Y
	and #$BF
	sta $020A,Y
	lda #$DE
	sta $0201,Y
	sta $0205,Y
	sta $0209,Y
	sta $020D,Y
	dec $045A,X
	bpl label0290
	lda #$FF
	sta $88,X
	lda #$F0
	sta $9A,X
	lda #$04
	sta $F1
label0290:
	pla 
	tax 
	rts 

Routinelabel0084:
	ldx $BB
	bmi label0294
	lda $E5BB,X
	sta $1D
	lda $E5C0,X
	sta $1E
	ldy #$00
	ldx #$00
label0291:
	lda ($1D),Y
	sta $02E0,X
	iny 
	inx 
	cmp #$F0
	bne label0292
	inx 
	inx 
	inx 
label0292:
	cpx #$10
	bne label0291
	ldy #$0F
label0293:
	lda $02E0,Y
	clc 
	adc $BC
	sta $02E0,Y
	dey 
	dey 
	dey 
	dey 
	bpl label0293
	lda $19
	and #$03
	bne label0294
	dec $BB
label0294:
	rts 

Routinelabel0085:
	jsr Routinelabel0101
	ldx #$07
label0295:
	lda $88,X
	bpl label0296
	cmp #$FF
	beq label0300
	jsr Routinelabel0099
	jmp label0300
label0296:
	cpx #$02
	bcc label0297
	cmp #$01
	bne label0297
	lda $7F,X
	cmp #$02
	bcs label0297
	lda $F1
	ora #$20
	sta $F1
label0297:
	dec $043F,X
	bne label0299
	lda #$03
	sta $043F,X
	cpx #$02
	bcs label0298
	dec $BF,X
	bne label0298
	lda #$00
	sta $BD,X
label0298:
	jsr Routinelabel0092
	stx $3E
	jsr Routinelabel0098
	jsr Routinelabel0089
label0299:
	jsr Routinelabel0093
	jsr Routinelabel0100
	jsr Routinelabel0091
label0300:
	jsr Routinelabel0083
	dex 
	bpl label0295
	rts 

Routinelabel0086:
	cpx #$02
	bcs label0303
	lda $19
	and #$0F
	bne label0301
	jsr Routinelabel0115
	sta $31,X
label0301:
	lda $3A
	bne label0303
	jsr Routinelabel0088
	lda $061C,X
	sta $31,X
label0302:
	rts 
label0303:
	lda $9A,X
	cmp #$A0
	bcc label0304
	lda $31,X
	ora #$40
	sta $31,X
	rts 
label0304:
	dec $045A,X
	bne label0302
	jsr Routinelabel0115
	ldy $0451,X
	and $E758,Y
	adc $E75B,Y
	sta $045A,X
	stx $12
	lda $19
	rol A
	rol A
	eor $12
	and #$01
	tay 
	lda $0088,Y
	bmi label0305
	lda $00BD,Y
	bne label0305
	lda #$00
	sta $31,X
	lda $009A,Y
	sec 
	sbc #$04
	cmp $9A,X
	bcs label0306
label0305:
	lda #$40
	sta $31,X
label0306:
	lda $91,X
	cmp $0091,Y
	bcs label0307
	lda $31,X
	ora #$01
	sta $31,X
	rts 
label0307:
	lda $31,X
	ora #$02
	sta $31,X
	rts 

Routinelabel0087:
	ldx #$00

Routinelabel0088:
	lda #$01
	sta $4016
	lda #$00
	sta $4016
	ldy #$07
label0308:
	lda $4016,X
	sta $12
	lsr A
	ora $12
	lsr A
	rol $061C,X
	dey 
	bpl label0308
	ldy $061E,X
	lda $061C,X
	sta $061E,X
	tya 
	eor $061C,X
	and $061C,X
	rts 

Routinelabel0089:
	lda $88,X
	bne label0310
label0309:
	lda #$00
	sta $0424,X
	sta $042D,X
	rts 
label0310:
	cmp #$02
	beq label0311
	cpx #$02
	bcc label0311
	lda $7F,X
	cmp #$02
	bcs label0309

Routinelabel0090:
	lda $0424,X
	sta $12
	lda $042D,X
	sta $13
	jsr Routinelabel0114
	lda $0463,X
	clc 
	adc $12
	sta $0463,X
	sta $12
	lda $046C,X
	adc $13
	sta $046C,X
	sta $13
	jsr Routinelabel0114
	lda $0424,X
	sec 
	sbc $12
	sta $0424,X
	lda $042D,X
	sbc $13
	sta $042D,X
	rts 
label0311:
	lda $7F,X
	cmp #$06
	bcc label0312
	rts 
label0312:
	lda $7F,X
	cmp #$04
	bne label0315
	lda $31,X
	and #$02
	beq label0313
	lda $0448,X
	beq label0315
	bne label0314
label0313:
	lda $31,X
	and #$01
	beq label0315
	lda $0448,X
	bne label0315
label0314:
	lda #$05
	sta $7F,X
label0315:
	lda $7F,X
	cmp #$02
	bne label0319
	lda $31,X
	and #$02
	beq label0316
	lda #$00
	beq label0317
label0316:
	lda $31,X
	and #$01
	beq label0318
	lda #$01
label0317:
	cmp $0448,X
	beq label0319
label0318:
	lda #$04
	sta $7F,X
label0319:
	lda $7F,X
	cmp #$04
	bcc label0322
	lda $31,X
	and #$02
	beq label0320
	lda $0448,X
	bne label0322
	beq label0321
label0320:
	lda $31,X
	and #$01
	beq label0322
	lda $0448,X
	beq label0322
label0321:
	lda #$02
	sta $7F,X
label0322:
	lda $7F,X
	cmp #$03
	bne label0323
	lda $31,X
	and #$03
	beq label0323
	lda #$02
	sta $7F,X
label0323:
	lda $7F,X
	cmp #$04
	bcs label0326
	lda $31,X
	and #$02
	beq label0324
	lda #$00
	beq label0325
label0324:
	lda $31,X
	and #$01
	beq label0326
	lda #$01
label0325:
	sta $0448,X
label0326:
	lda $7F,X
	cmp #$04
	bcc label0328
	lda $0436,X
	cmp #$01
	bne label0328
	ldy $0451,X
	lda $0448,X
	beq label0327
	lda $0424,X
	sec 
	sbc $E61B,Y
	sta $0424,X
	lda $042D,X
	sbc #$00
	jmp label0332
label0327:
	lda $0424,X
	clc 
	adc $E61B,Y
	sta $0424,X
	lda $042D,X
	adc #$00
	jmp label0332
label0328:
	lda $7F,X
	beq label0329
	cmp #$02
	beq label0333
	cmp #$03
	beq label0329
	jmp label0336
label0329:
	lda $0436,X
	cmp #$01
	beq label0330
	jmp label0336
label0330:
	ldy $0451,X
	lda $31,X
	and #$02
	beq label0331
	lda $0424,X
	sec 
	sbc $E60F,Y
	sta $0424,X
	lda $042D,X
	sbc #$00
	jmp label0332
label0331:
	lda $31,X
	and #$01
	beq label0336
	lda $0424,X
	clc 
	adc $E60F,Y
	sta $0424,X
	lda $042D,X
	adc #$00
label0332:
	sta $042D,X
	jmp label0336
label0333:
	lda $0436,X
	cmp #$01
	bne label0336
	ldy $0451,X
	lda $31,X
	and #$02
	beq label0334
	lda $0424,X
	sec 
	sbc $E61B,Y
	sta $0424,X
	lda $042D,X
	sbc #$00
	jmp label0335
label0334:
	lda $31,X
	and #$01
	beq label0336
	lda $0424,X
	clc 
	adc $E61B,Y
	sta $0424,X
	lda $042D,X
	adc #$00
label0335:
	sta $042D,X
	lda $31,X
	and #$03
	beq label0336
	cpx #$02
	bcs label0336
	lda $F0
	ora #$08
	sta $F0
label0336:
	lda $7F,X
	cmp #$04
	bcc label0340
	lda $0448,X
	bne label0337
	lda $042D,X
	bmi label0340
	bpl label0338
label0337:
	lda $042D,X
	bpl label0340
label0338:
	lda $7F,X
	cmp #$05
	bne label0339
	lda $0448,X
	eor #$01
	sta $0448,X
label0339:
	lda #$03
	sta $7F,X
	lda #$00
	sta $0424,X
	sta $042D,X
label0340:
	rts 

Routinelabel0091:
	lda $CB
	bne label0343
	lda $BD,X
	beq label0341
	lda $0488
	beq label0341
	sec 
	sbc $91,X
	jsr Routinelabel0103
	cmp #$05
	bcc label0343
label0341:
	cpx #$02
	bcc label0342
	lda $88,X
	cmp #$02
	bne label0344
label0342:
	lda $7F,X
	cmp #$02
	bcc label0344
	cmp #$06
	bcs label0344
	lda #$01
	sta $7F,X
	sta $045A,X
	rts 
label0343:
	lda #$00
	sta $0412,X
	sta $041B,X
	sta $0409,X
	sta $CB
	cpx #$02
	bcc label0346
	lda $88,X
	cmp #$02
	beq label0345
	cmp #$01
	bne label0344
	lda $7F,X
	cmp #$02
	bcs label0344
	lda #$02
	sta $7F,X
	lda $C6
	sta $043F,X
	lda #$00
	sta $0424,X
	sta $042D,X
	sta $0463,X
	sta $046C,X
	lda #$40
	sta $F1
label0344:
	rts 
label0345:
	lda #$00
	sta $7F,X
	lda #$01
	sta $045A,X
	rts 
label0346:
	lda $7F,X
	cmp #$01
	bne label0349
	cmp #$06
	bcs label0349
	lda $0424,X
	ora $042D,X
	bne label0347
	lda #$03
	bne label0348
label0347:
	lda #$02
label0348:
	sta $7F,X
label0349:
	rts 

Routinelabel0092:
	cpx #$02
	bcs label0350
	lda $BD,X
	bne label0352
	lda $7F,X
	cmp #$01
	beq label0351
	cmp #$03
	bne label0352
	beq label0351
label0350:
	lda $7F,X
	cmp #$01
	beq label0351
	cmp #$03
	bcc label0352
	lda $19
	and #$03
	bne label0353
	beq label0352
label0351:
	lda $19
	and #$07
	bne label0353
label0352:
	inc $0436,X
label0353:
	lda $0436,X
	and #$03
	sta $0436,X
	bne label0354
	lda $7F,X
	bne label0354
	inc $7F,X
label0354:
	rts 

Routinelabel0093:
	lda $0475,X
	beq label0355
	dec $0475,X
label0355:
	cpx #$02
	bcs label0357
	lda $C1,X
	beq label0357
	lda $19
	lsr A
	bcc label0356
	inc $0436,X
	lda $0436,X
	and #$03
	sta $0436,X
	lda #$01
	sta $7F,X
	dec $045A,X
	bne label0356
	lda #$00
	sta $C1,X
	sta $7F,X
	lda #$20
	sta $F0
label0356:
	rts 
label0357:
	lda $0412,X
	clc 
	ldy $0451,X
	adc $E5F7,Y
	sta $0412,X
	bcc label0358
	inc $041B,X
label0358:
	lda $041B,X
	bmi label0360
	cmp $E663,Y
	bcc label0362
	bne label0359
	lda $0412,X
	cmp $E657,Y
	bcc label0362
label0359:
	lda $E657,Y
	sta $0412,X
	lda $E663,Y
	sta $041B,X
	jmp label0362
label0360:
	cmp $E67B,Y
	bcc label0361
	bne label0362
	lda $0412,X
	cmp $E66F,Y
	bcs label0362
label0361:
	lda $E66F,Y
	sta $0412,X
	lda $E67B,Y
	sta $041B,X
label0362:
	jsr Routinelabel0095
	cmp #$F8
	bcs label0364
	cmp #$E8
	bcc label0364
	lda #$FF
	sta $88,X
	lda #$04
	sta $BB
	lda $91,X
	sta $BC
	cpx #$02
	bcc label0363
	lda #$80
	sta $88,X
	lda #$00
	sta $7F,X
	lda #$01
	sta $F3
	bne label0364
label0363:
	lda $C8
	bne label0364
	lda #$40
	sta $F0
label0364:
	lda $042D,X
	bmi label0366
	cmp $E633,Y
	bcc label0368
	bne label0365
	lda $0424,X
	cmp $E627,Y
	bcc label0368
label0365:
	lda $E627,Y
	sta $0424,X
	lda $E633,Y
	sta $042D,X
	jmp label0368
label0366:
	cmp $E64B,Y
	bcc label0367
	bne label0368
	lda $0424,X
	cmp $E63F,Y
	bcs label0368
label0367:
	lda $E63F,Y
	sta $0424,X
	lda $E64B,Y
	sta $042D,X
label0368:
	jsr Routinelabel0094
	lda $16
	beq label0371
	lda $91,X
	cmp #$10
	bcs label0369
	lda #$10
label0369:
	cmp #$E0
	bcc label0370
	lda #$E0
label0370:
	sta $91,X
label0371:
	lda $C8
	beq label0373
	lda $88,X
	bne label0373
	lda $9A,X
	cmp #$C8
	bcc label0373
	lda #$C7
	sta $9A,X
	lda $0451,X
	cmp #$0B
	bne label0372
	dec $0451,X
	jsr Routinelabel0109
	jmp label0457
label0372:
	lda #$02
	sta $88,X
	lda #$03
	sta $0451,X
label0373:
	rts 

Routinelabel0094:
	lda $0400,X
	clc 
	adc $0424,X
	sta $0400,X
	lda $91,X
	adc $042D,X
	sta $91,X
	rts 

Routinelabel0095:
	lda $0409,X
	clc 
	adc $0412,X
	sta $0409,X
	lda $9A,X
	adc $041B,X
	sta $9A,X
	rts 

Routinelabel0096:
	jsr Routinelabel0106
	jsr Routinelabel0094
	jmp label0452

Routinelabel0097:
	jsr Routinelabel0106
	jsr Routinelabel0095
	jmp label0452

Routinelabel0098:
	cpx #$02
	bcs label0375
	lda $88,X
	bne label0374
	lda $0436,X
	bne label0374
	lda #$00
	sta $7F,X
	rts 
label0374:
	lda $7F,X
	cmp #$06
	bcc label0381
	lda #$01
	sta $7F,X
	dec $88,X
	rts 
label0375:
	lda $88,X
	cmp #$02
	beq label0381
	lda $0436,X
	bne label0377
	lda $88,X
	bne label0376
	lda #$00
	sta $7F,X
	rts 
label0376:
	lda $7F,X
	bne label0378
	inc $7F,X
label0377:
	rts 
label0378:
	cmp #$02
	bcc label0377
	dec $045A,X
	bne label0380
	lda $C7
	sta $045A,X
	inc $7F,X
	lda $7F,X
	cmp #$07
	bcc label0380
	lda #$02
	sta $88,X
	lda #$00
	sta $7F,X
	ldy $0451,X
	lda $ECA4,Y
	ldy $047E,X
	bne label0379
	dec $047E,X
	lda $0451,X
	and #$03
label0379:
	sta $0451,X
	lda #$FE
	sta $041B,X
label0380:
	rts 
label0381:
	jsr Routinelabel0086
	lda $31,X
	and #$C3
	beq label0382
	cpx #$02
	bcs label0382
	lda #$00
	sta $BD,X
label0382:
	lda $31,X
	and #$40
	bne label0384
	lda $31,X
	and #$80
	bne label0383
	lda #$00
	sta $0620,X
	beq label0388
label0383:
	lda $0620,X
	bne label0388
label0384:
	lda $7F,X
	cmp #$02
	bcc label0385
	dec $9A,X
	dec $9A,X
	lda #$00
	sta $0412,X
	sta $041B,X
	beq label0386
label0385:
	cmp #$01
	beq label0386
	lda $0436,X
	bne label0388
label0386:
	lda #$00
	sta $7F,X
	lda #$01
	sta $0436,X
	lda #$01
	sta $0620,X
	ldy #$00
	cpx #$02
	bcc label0387
	iny 
label0387:
	lda $00F0,Y
	ora #$10
	sta $00F0,Y
	lda $0412,X
	sec 
	ldy $0451,X
	sbc $E603,Y
	sta $0412,X
	bcs label0388
	dec $041B,X
label0388:
	rts 

Routinelabel0099:
	lda $7F,X
	bne label0392
	jsr Routinelabel0090
	jsr Routinelabel0094
	lda $0409,X
	sec 
	sbc #$60
	sta $0409,X
	lda $9A,X
	sbc #$00
	sta $9A,X
	cmp #$F1
	bcc label0389
	lda #$FF
	sta $88,X
label0389:
	txa 
	pha 
	ldy #$01
label0390:
	lda $0088,Y
	beq label0391
	bmi label0391
	lda $9A,X
	sec 
	sbc $009A,Y
	jsr Routinelabel0103
	cmp #$18
	bcs label0391
	lda $91,X
	sec 
	sbc $0091,Y
	jsr Routinelabel0103
	cmp #$10
	bcs label0391
	lda #$FF
	sta $7F,X
	lda #$03
	sta $045A,X
	lda #$78
	sta $C5
	lda #$02
	sta $F0
	lda #$32
	sty $3E
	jsr Routinelabel0072
	lda #$01
	ldx $3E
	jsr Routinelabel0077
	pla 
	tax 
	rts 
label0391:
	dey 
	bpl label0390
	pla 
	tax 
label0392:
	rts 

Routinelabel0100:
	ldy $88,X
	dey 
	bpl label0394
label0393:
	rts 
label0394:
	lda $9A,X
	cmp #$F9
	bcc label0395
	lda $041B,X
	bpl label0393
	lda #$00
	sta $CC
	jmp label0408
label0395:
	ldy $CD
	bmi label0392
label0396:
	lda #$00
	sta $CC
	lda ($27),Y
	sec 
	sbc #$18
	cmp $9A,X
	bcs label0404
	adc #$03
	cmp $9A,X
	bcc label0397
	lda #$01
	bne label0398
label0397:
	lda ($29),Y
	cmp $9A,X
	bcc label0404
	sbc #$03
	cmp $9A,X
	bcs label0401
	lda #$02
label0398:
	sta $CC
	lda ($23),Y
	cmp #$10
	beq label0399
	sec 
	sbc #$0C
	cmp $91,X
	bcs label0400
label0399:
	lda ($25),Y
	cmp #$FF
	beq label0401
	sec 
	sbc #$04
	cmp $91,X
	bcs label0401
label0400:
	lda #$00
	sta $CC
label0401:
	lda ($23),Y
	sec 
	sbc #$10
	beq label0402
	cmp $91,X
	bcs label0404
	adc #$04
	cmp $91,X
	bcc label0402
	lda $CC
	ora #$04
	bne label0403
label0402:
	lda ($25),Y
	cmp #$FF
	beq label0404
	cmp $91,X
	bcc label0404
	sbc #$04
	cmp $91,X
	bcs label0404
	lda $CC
	ora #$08
label0403:
	sta $CC
label0404:
	lda $CC
	bne label0406
	dey 
	bmi label0405
	jmp label0396
label0405:
	rts 
label0406:
	lsr $CC
	bcc label0407
	lda $041B,X
	bmi label0407
	lda ($27),Y
	sbc #$18
	sta $9A,X
	inc $9A,X
	lda #$01
	sta $CB
label0407:
	lsr $CC
	bcc label0410
	lda $041B,X
	bpl label0410
	lda ($29),Y
label0408:
	sta $9A,X
	jsr Routinelabel0109
	jsr Routinelabel0113
	cpx #$02
	bcs label0409
	jsr Routinelabel0036
label0409:
	lda $CB
	bne label0413
label0410:
	lsr $CC
	bcc label0411
	lda $042D,X
	bmi label0411
	bpl label0412
label0411:
	lsr $CC
	bcc label0413
	lda $042D,X
	bpl label0413
label0412:
	jsr Routinelabel0108
	jsr Routinelabel0112
	lda $042D,X
	ora $0424,X
	beq label0413
	lda $0448,X
	eor #$01
	sta $0448,X
	lda $F1
	ora #$02
	sta $F1
label0413:
	rts 

Routinelabel0101:
	ldx #$07
label0414:
	stx $12
	ldy $12
	dey 
	bpl label0416
label0415:
	jmp label0431
label0416:
	lda $88,X
	bmi label0415
	beq label0415
	lda $0088,Y
	bmi label0415
	beq label0415
	lda #$00
	sta $CC
	lda $009A,Y
	sec 
	sbc $9A,X
	jsr Routinelabel0103
	cmp #$18
	bcs label0422
	lda $9A,X
	clc 
	adc #$18
	sta $12
	lda $009A,Y
	clc 
	adc #$07
	sec 
	sbc $12
	jsr Routinelabel0103
	cmp #$04
	bcs label0417
	lda #$01
	bne label0418
label0417:
	lda $009A,Y
	clc 
	adc #$11
	sec 
	sbc $9A,X
	jsr Routinelabel0103
	cmp #$04
	bcs label0419
	lda #$02
label0418:
	sta $CC
	lda $0091,Y
	sec 
	sbc $91,X
	jsr Routinelabel0103
	cmp #$10
	bcc label0419
	lda #$00
	sta $CC
label0419:
	lda $91,X
	clc 
	adc #$10
	sta $12
	lda $0091,Y
	clc 
	adc #$07
	sec 
	sbc $12
	jsr Routinelabel0103
	cmp #$04
	bcs label0420
	lda #$04
	bne label0421
label0420:
	lda $0091,Y
	clc 
	adc #$09
	sec 
	sbc $91,X
	jsr Routinelabel0103
	cmp #$04
	bcs label0422
	lda #$08
label0421:
	ora $CC
	sta $CC
label0422:
	lda #$00
	sta $4B
	lsr $CC
	bcc label0423
	jsr Routinelabel0105
	bmi label0424
label0423:
	lsr $CC
	bcc label0426
	jsr Routinelabel0105
	bmi label0426
label0424:
	jsr Routinelabel0107
	bcs label0425
	jsr Routinelabel0109
	jsr Routinelabel0113
	jsr Routinelabel0106
	jsr Routinelabel0109
	jsr Routinelabel0113
	jsr Routinelabel0106
label0425:
	lda #$01
	sta $4B
label0426:
	lsr $CC
	bcc label0427
	jsr Routinelabel0104
	bmi label0428
label0427:
	lsr $CC
	bcc label0430
	jsr Routinelabel0104
	bmi label0430
label0428:
	jsr Routinelabel0107
	bcs label0429
	jsr Routinelabel0108
	jsr Routinelabel0112
	jsr Routinelabel0106
	jsr Routinelabel0108
	jsr Routinelabel0112
	jsr Routinelabel0106
label0429:
	lda #$01
	sta $4B
label0430:
	jsr Routinelabel0102
	jsr Routinelabel0106
	jsr Routinelabel0102
	jsr Routinelabel0106
label0431:
	dey 
	bmi label0432
	jmp label0416
label0432:
	dex 
	bmi label0433
	jmp label0414
label0433:
	rts 

Routinelabel0102:
	cpx #$02
	bcc label0434
	cpy #$02
	bcc label0434
	jmp label0449
label0434:
	lda #$00
	sta $0487
	lda $0475,X
	beq label0435
	jmp label0449
label0435:
	lda $4B
	bne label0436
	jmp label0449
label0436:
	cpx #$02
	bcs label0437
	lda $BD,X
	beq label0438
	jmp label0449
label0437:
	lda $88,X
	cmp #$01
	bne label0438
	lda $7F,X
	cmp #$02
	bcs label0439
	lda #$01
	sta $0487
label0438:
	lda $009A,Y
	clc 
	adc #$04
	cmp $9A,X
	bcc label0439
	jmp label0449
label0439:
	lda #$14
	sta $0475,X
	lda #$00
	sta $0436,X
	cpy #$02
	bcc label0440
	lda $0088,Y
	cmp #$02
	beq label0440
	jmp label0449
label0440:
	lda $F0
	ora #$02
	sta $F0
	lda $88,X
	cmp #$02
	bne label0442
	cpx #$02
	bcs label0442
	sty $12
	ldy $7F,X
	lda $F049,Y
	ldy $12
	pha 
	pla 
	bne label0441
	jmp label0449
label0441:
	sta $7F,X
	lda #$00
	sta $0436,X
	beq label0446
label0442:
	dec $88,X
	bne label0443
	lda #$FF
	sta $041B,X
	lda #$00
	sta $0412,X
label0443:
	lda #$00
	sta $7F,X
	sta $0424,X
	sta $042D,X
	lda $91,X
	bmi label0444
	lda #$FF
	bne label0445
label0444:
	lda #$00
label0445:
	sta $046C,X
	lda #$80
	sta $0463,X
label0446:
	sty $12
	ldy $0451,X
	lda $F054,Y
	sta $0451,X
	lda #$01
	sta $047E,X
	ldy $12
	cpy #$02
	bcs label0449
	lda $0451,X
	cmp #$07
	beq label0447
	cmp #$08
	bcc label0447
	lda $F1
	ora #$80
	sta $F1
label0447:
	ldy $0451,X
	lda $F060,Y
	sta $13
	lda $0487
	beq label0448
	lda $F06C,Y
	sta $13
label0448:
	lda $F078,Y
	clc 
	adc $0487
	sta $14
	lda $12
	sta $3E
	pha 
	txa 
	pha 
	lda $13
	pha 
	lda $14
	jsr Routinelabel0077
	pla 
	jsr Routinelabel0072
	pla 
	tax 
	pla 
	tay 
label0449:
	lda $0451,X
	cmp #$0B
	bne label0450
	lda $C8
	bne label0450
	lda #$20
	sta $F0
label0450:
	rts 

Routinelabel0103:
	pha 
	pla 
	bpl label0451
	eor #$FF
	clc 
	adc #$01
label0451:
	rts 

Routinelabel0104:
	lda $0424,Y
	sec 
	sbc $0424,X
	lda $042D,Y
	sbc $042D,X
	rts 

Routinelabel0105:
	lda $0412,Y
	sec 
	sbc $0412,X
	lda $041B,Y
	sbc $041B,X
	rts 

Routinelabel0106:
label0452:
	stx $12
	sty $13
	ldx $13
	ldy $12
	rts 

Routinelabel0107:
	cpx #$02
	bcc label0453
	lda $7F,X
	cmp #$02
	bcc label0453
	lda #$01
	cmp $88,X
	bcs label0453
	cpy #$02
	bcc label0453
	lda $007F,Y
	cmp #$02
	bcc label0453
	lda #$01
	cmp $0088,Y
label0453:
	rts 

Routinelabel0108:
	lda #$00
	sec 
	sbc $0424,X
	sta $0424,X
	lda #$00
	sbc $042D,X
	sta $042D,X
	lda #$00
	sec 
	sbc $0463,X
	sta $0463,X
	lda #$00
	sbc $046C,X
	sta $046C,X
	lda $31,X
	and #$40
	sta $31,X
	rts 

Routinelabel0109:
	lda #$00
	sec 
	sbc $0412,X
	sta $0412,X
	lda #$00
	sbc $041B,X
	sta $041B,X
	rts 

Routinelabel0110:
	sta $2D
	lda $2C
	bpl label0454
	lda #$00
	sec 
	sbc $2B
	sta $2B
	lda #$00
	sbc $2C
	sta $2C
	jsr Routinelabel0111
	lda #$00
	sec 
	sbc $2E
	sta $2E
	lda #$00
	sbc $2F
	sta $2F
	lda #$00
	sbc $30
	sta $30
	rts 

Routinelabel0111:
label0454:
	txa 
	pha 
	lda #$00
	sta $2E
	sta $2F
	sta $30
	ldx #$08
label0455:
	asl $2E
	rol $2F
	rol $30
	asl $2D
	bcc label0456
	clc 
	lda $2B
	adc $2E
	sta $2E
	lda $2C
	adc $2F
	sta $2F
	lda #$00
	adc $30
	sta $30
label0456:
	dex 
	bne label0455
	pla 
	tax 
	rts 

Routinelabel0112:
	lda $0424,X
	sta $2B
	lda $042D,X
	sta $2C
	lda #$CD
	jsr Routinelabel0110
	lda $2F
	sta $0424,X
	lda $30
	sta $042D,X
	rts 

Routinelabel0113:
label0457:
	lda $0412,X
	sta $2B
	lda $041B,X
	sta $2C
	lda #$CD
	jsr Routinelabel0110
	lda $2F
	sta $0412,X
	lda $30
	sta $041B,X
	rts 

Routinelabel0114:
	ldy #$04
label0458:
	lda $13
	asl A
	ror $13
	ror $12
	dey 
	bne label0458
	rts 

Routinelabel0115:
	txa 
	pha 
	ldx #$0B
label0459:
	asl $1B
	rol $1C
	rol A
	rol A
	eor $1B
	rol A
	eor $1B
	lsr A
	lsr A
	eor #$FF
	and #$01
	ora $1B
	sta $1B
	dex 
	bne label0459
	pla 
	tax 
	lda $1B
	rts 
label0460:
	jsr Routinelabel0081
	ldx #$09
label0461:
	lda #$00
	sta $03,X
	dex 
	bpl label0461
	sta $3E
	inc $41
	jsr Routinelabel0072
	lda #$0F
	;---------------------
	;        sta $4015  SNDCHANSWITCH
	jsr rsta_4015
	;------------
	lda #$01
	sta $F0
	lda #$02

Routinelabel0116:
	sta $41
	ldy $40
	bne label0462
	lda #$FF
label0462:
	sta $42
	ldx #$00
	stx $0488
	stx $3B
	stx $3C
	stx $0558
	dex 
	stx $89
	ldx $40
label0463:
	jsr Routinelabel0118
	dex 
	bpl label0463
label0464:
	lda #$00
	sta $C8
	lda $3C
	lsr A
	lsr A
	cmp #$08
	bcc label0465
	lda #$08
label0465:
	tax 
	lda $F3B0,X
	sta $C6
	lda $F3B9,X
	sta $C7
	lda $3C
	cmp #$02
	bcs label0466
	lda #$03
	sta $C6
	sta $C7
label0466:
	ldx #$07
label0467:
	lda #$00
	sta $0448,X
	sta $0475,X
	sta $047E,X
	sta $0424,X
	sta $042D,X
	sta $0412,X
	sta $041B,X
	sta $0463,X
	sta $046C,X
	sta $0400,X
	sta $0409,X
	lda #$01
	sta $043F,X
	sta $045A,X
	lda #$03
	sta $0436,X
	dex 
	bpl label0467
	ldx #$05
label0468:
	lda #$FF
	sta $8A,X
	dex 
	bpl label0468
	ldx $40
label0469:
	jsr Routinelabel0117
	dex 
	bpl label0469
	jsr Routinelabel0051
	jsr Routinelabel0053
	lda $C6
	cmp #$10
	bcs label0470
	lda #$58
	sta $C6
label0470:
	jsr Routinelabel0126
	jsr Routinelabel0079
	lda $16
	beq label0471
	jmp label0027
label0471:
	lda $C8
	beq label0472
	jmp label0158
label0472:
	jsr Routinelabel0019
	lda $3B
	and #$03
	bne label0473
	lda #$08
	sta $F2
	ldx $3A
	bne label0474
label0473:
	lda #$FF
	sta $3D
	inc $3C
label0474:
	jsr Routinelabel0125
	lda $3D
	beq label0475
	dec $3D
	jsr Routinelabel0119
label0475:
	jsr Routinelabel0115
	jsr Routinelabel0085
	jsr Routinelabel0018
	jsr Routinelabel0022
	jsr Routinelabel0023
	jsr Routinelabel0026
	jsr Routinelabel0078
	jsr Routinelabel0084
	jsr Routinelabel0034
	inc $4C
	ldx $40
label0476:
	lda $88,X
	bpl label0477
	lda $3A
	bne label0479
	lda $41,X
	bmi label0477
	dec $C3,X
	bne label0480
	txa 
	pha 
	jsr Routinelabel0020
	pla 
	tax 
	ldy #$02
	dec $41,X
	sty $46
	bmi label0477
	jsr Routinelabel0117
	jsr Routinelabel0118
	lda #$80
	sta $F2
label0477:
	dex 
	bpl label0476
	lda $41
	bpl label0478
	lda $42
	bmi label0487
label0478:
	lda $3A
	beq label0480
	jsr Routinelabel0087
	lda $061C
	and #$30
	beq label0474
label0479:
	rts 
label0480:
	ldx #$05
label0481:
	lda $8A,X
	beq label0482
	bpl label0474
label0482:
	dex 
	bpl label0481
	lda $BB
	bpl label0474
	ldx $40
label0483:
	ldy $88,X
	dey 
	bpl label0484
	lda $41,X
	bmi label0484
	lda #$FF
	sta $88,X
	lda #$01
	sta $C3,X
	jmp label0474
label0484:
	dex 
	bpl label0483
	lda #$02
	sta $F2
label0485:
	ldx #$96
	jsr Routinelabel0122
	ldx $3B
	inx 
	cpx #$10
	bne label0486
	ldx #$04
label0486:
	stx $3B
	jmp label0464
label0487:
	lda #$01
	sta $F2
label0488:
	lda #$00
	sta $17
	sta $18
	sta $15
	jsr Routinelabel0120
label0489:
	jsr Routinelabel0123
	jsr Routinelabel0087
	and #$30
	bne label0490
	dec $15
	bne label0489
label0490:
	jmp label0460

Routinelabel0117:
	lda $41,X
	bmi label0492
	lda $F3A4,X
	sta $91,X
	lda #$B8
	sta $9A,X
	sta $BD,X
	lda #$C8
	sta $BF,X
	lda #$5A
	ldy $41,X
	bpl label0491
	lda #$01
label0491:
	sta $C3,X
	lda #$00
	sta $C1,X
	sta $042D,X
	sta $0424,X
label0492:
	rts 

Routinelabel0118:
	lda #$03
	sta $0451,X
	lda #$02
	sta $88,X
	rts 

Routinelabel0119:
	lda $3D
	and #$20
	beq label0494
	ldx #$0A
label0493:
	lda $F3EB,X
	sta $57,X
	dex 
	bpl label0493
	ldy #$0A
	lda $3C
	sta $43
	jsr Routinelabel0073
	sta $60
	lda $43
	sta $61
	jmp label0020
label0494:
	lda #$F6
	ldy #$F3
	jmp label0021

Routinelabel0120:
	jsr Routinelabel0123
	ldx #$01
label0495:
	lda $F431,X
	ldy $F433,X
	jsr Routinelabel0006
	dex 
	bpl label0495
	ldx #$0F
label0496:
	lda #$24
	sta $5A,X
	dex 
	bpl label0496
	lda #$10
	sta $59
	lda #$21
	sta $57
	ldx #$02
label0497:
	lda $F435,X
	sta $58
	jsr Routinelabel0005
	dex 
	bpl label0497
	rts 

Routinelabel0121:
	ldx #$14

Routinelabel0122:
label0498:
	jsr Routinelabel0123
	dex 
	bne label0498
	rts 

Routinelabel0123:
	lda #$00
	sta $02

Routinelabel0124:
label0499:
	lda $02
	beq label0499
	dec $02
label0500:
	rts 

Routinelabel0125:
	jsr Routinelabel0124
	lda $3A
	bne label0500
	jsr Routinelabel0087
	and #$10
	beq label0500
	lda #$04
	sta $F2
	lda $01
	and #$EF
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
label0501:
	jsr Routinelabel0123
	jsr Routinelabel0087
	and #$10
	beq label0501
	lda $01
	;---------------------
	;        sta $2001  PPUC2
	jsr rsta_2001
	;------------
	ldy #$04
	lda $C8
	ora $16
	beq label0502
	ldy #$20
label0502:
	sty $F2
	rts 

Routinelabel0126:
	lda #$01
	sta $048E
	sta $048F
	lda #$FF
	sta $BB
	sta $87
	sta $048C
	ldx #$01
	stx $0459
	stx $90
	inx 
	stx $46
	lda #$40
	sta $99
	rts 
label0503:
	jsr Routinelabel0135
label0504:
	rts 
label0505:
	lda #$00
	tax 
	sta $FD
	beq label0508
label0506:
	txa 
	lsr A
	tax 
label0507:
	inx 
	txa 
	cmp #$04
	beq label0504
	lda $FD
	clc 
	adc #$04
	sta $FD
label0508:
	txa 
	asl A
	tax 
	lda $E0,X
	sta $FE
	lda $E1,X
	sta $FF
	lda $E1,X
	beq label0506
	txa 
	lsr A
	tax 
	dec $D0,X
	bne label0507
label0509:
	ldy $E8,X
	inc $E8,X
	lda ($FE),Y
	beq label0503
	tay 
	cmp #$FF
	beq label0510
	and #$C0
	cmp #$C0
	beq label0511
	jmp label0513
label0510:
	lda $D8,X
	beq label0512
	dec $D8,X
	lda $EC,X
	sta $E8,X
	bne label0512
label0511:
	tya 
	and #$3F
	sta $D8,X
	dec $D8,X
	lda $E8,X
	sta $EC,X
label0512:
	jmp label0509
label0513:
	tya 
	bpl label0515
	and #$0F
	clc 
	adc $DF
	tay 
	lda $F660,Y
	sta $D4,X
	tay 
	txa 
	cmp #$02
	beq label0522
label0514:
	ldy $E8,X
	inc $E8,X
	lda ($FE),Y
label0515:
	tay 
	txa 
	cmp #$03
	beq label0525
	pha 
	tax 
	cmp #$01
	beq label0521
label0516:
	ldx $FD
	lda $F601,Y
	beq label0517
	;---------------------
	;        sta $4002,X  SNDSQR1PERIOD
	jsr rsta_4002AbsX
	;------------
	lda $F600,Y
	ora #$08
	;---------------------
	;        sta $4003,X  SNDSQR1LENPH
	jsr rsta_4003AbsX
	;------------
label0517:
	tay 
	pla 
	tax 
	tya 
	bne label0518
	ldy #$00
	txa 
	cmp #$02
	beq label0519
	ldy #$10
	bne label0519
label0518:
	ldy $DC,X
label0519:
	tya 
	ldy $FD
	;---------------------
	;        sta $4000,Y  SNDSQR1CTRL
