

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
; It comes from the source code of Mermblers nes Apu emulator
;
.DEFINE NesAPUEmulatorBinSize $2C00

setup_spc:
        php

		sep #$20		 ; A 8bits
        lda #$8F
        sta $2100        ; screen off

        stz $4200        ; nmi disabled

		rep #$10		 ; X, Y 16bits
		;---------------------------
		; Send all the data in one block
		phb
		lda #SPC700CodeBank
		pha
		plb

        ldx #$BBAA
WaitSPCEq:
        cpx $2140
        bne WaitSPCEq    ; wait for SPC to be ready

		ldy #$0000

		ldx #NesAPUEmulatorBinSize
		stx tmp_dat
        ldx #$0400       ; start address for writing
        stx $2142

        lda #$01
        sta $2141        ; block

		; send the load starter byte: $CC
        lda #$CC
        sta $2140
WaitSPC700Start:
        lda $2140
        cmp #$CC
        bne WaitSPC700Start
		; send the nlock
SendAll:
		lda SPC700_APU_Emulation, Y ; Get the SPC700 binary code from the rom
		sta $2141               ; send byte
		tya
		sta $2140
WaitSPCReply:
        cmp $2140
        bne WaitSPCReply        ; wait for SPC to reply with # sent
		iny
		cpy tmp_dat             ; test if transfer is finished
		bne SendAll
        ; send terminator block
		stz $2141
		ldx #$0400
		stx $2142
		; send the transfered byte count
		iny
		iny
		tya
		sta $2140
Spc700FwEnd:
		lda #$01
		sta APUInit
		plb ; Restore the bank
        plp
        rts

; ------+-----+---------------------------------------------------------------
; Main APU emulation routine
SoundAPURegUpdate:
.IFDEF DISABLESOUND
	rts
.ENDIF
	jsr update_dsp
	rts

.IFDEF SOUNDWORKINPROGRESS

; look at $83A9

; 1 $9242
Procedure?:
009242 lda $7f4000
009246 and #$20
009248 bne $9272

lda $7f4003
beq +22
sta $7f4103
lda #00
sta $7F0403
lda $7F4116
ora #01
sta $7F4116
bra $14
lda $7F4116
and $FE8F
asl
eor $7F8008

009272 lda $7f4003
009276 sta $7f4103
00927a lda $7f4004
00927e and #$20
009280 bne $92aa

0092aa lda $7f4007
0092ae sta $7f4107
0092b2 lda $7f4008
0092b6 and #$80
0092b8 bne $92e2
0092ba lda $7f400b
0092be beq $92d6
0092c0 sta $7f410b
0092c4 lda #$00
0092c6 sta $7f400b
0092ca lda $7f4116
0092ce ora #$04
0092d0 sta $7f4116
0092d4 bra $92ea

0092e2 lda $7f400b
0092e6 sta $7f410b
0092ea lda $7f400c
0092ee and #$20
0092f0 bne $931a
0092f2 lda $7f400f
0092f6 beq $930e
0092f8 sta $7f410f
0092fc lda #$00
0092fe sta $7f400f
009302 lda $7f4116
009306 ora #$08
009308 sta $7f4116
00930c bra $9322
00930e lda $7f4116
009312 and #$f7
009314 sta $7f4116
009318 bra $9322
00931a lda $7f400f
00931e sta $7f410f
009322 lda $7f4001
009326 and #$80
009328 beq $934e

00934e lda $7f4002
009352 sta $7f4102
009356 bra $9364

009364 lda $7f4005
009368 and #$80
00936a beq $9390

009390 lda $7f4006
009394 sta $7f4106
009398 bra $93a6

0093a6 rts

; $9400
009400 lda #$00
009402 sta $7f4115
009406 lda $7f4116
00940a and #$01
00940c beq $9435

009435 lda $7f4115
009439 ora #$01
00943b sta $7f4115
00943f lda $7f4000
009443 and #$20
009445 bne $9459

009459 lda $7f4116
00945d and #$02
00945f beq $9488

009488 lda $7f4115
00948c ora #$02
00948e sta $7f4115
009492 lda $7f4004
009496 and #$20
009498 bne $94ac

0094ac lda $7f4116
0094b0 and #$04
0094b2 beq $94db
0094b4 lda $7f410b
0094b8 pha
0094b9 and #$08
0094bb beq $94cf
0094bd pla
0094be lsr a
0094bf lsr a
0094c0 lsr a
0094c1 lsr a
0094c2 xba


0094db lda $7f4115
0094df ora #$04
0094e1 sta $7f4115
0094e5 lda $7f4008
0094e9 and #$80
0094eb bne $94ff
0094ed lda $1c
0094ef beq $94f5
0094f1 dec $1c
0094f3 bra $94ff

0094ff lda $7f4116
009503 and #$08
009505 beq $952e
009507 lda $7f410f
00950b pha
00950c and #$08
00950e beq $9522
009510 pla
009511 lsr a
009512 lsr a
009513 lsr a
009514 lsr a
009515 xba


00952e lda $7f4115
009532 ora #$08
009534 sta $7f4115
009538 lda $7f400c
00953c and #$20
00953e bne $9552
009540 lda $1b
009542 beq $9548
009544 dec $1b
009546 bra $9552


009552 lda $7f4115
009556 and $7f4015
00955a sta $7f4115
00955e rts

; backup_regs from the NSF player ROM, 100% ok
0093a7 lda $7f4000
0093ab sta $7f4100
0093af lda $7f4001
0093b3 sta $7f4101
0093b7 lda $7f4004
0093bb sta $7f4104
0093bf lda $7f4005
0093c3 sta $7f4105
0093c7 lda $7f4008
0093cb sta $7f4108
0093cf lda $7f4009
0093d3 sta $7f4109
0093d7 lda $7f400a
0093db sta $7f410a
0093df lda $7f400c
0093e3 sta $7f410c
0093e7 lda $7f400d
0093eb sta $7f410d
0093ef lda $7f400e
0093f3 sta $7f410e
0093f7 lda $7f4011
0093fb sta $7f4111
0093ff rts


; update_dsp from the NSF player ROM, 100% ok
00978a php
00978b sep #$10
00978d lda $2140
009790 cmp #$7d
009792 bne $978d
009794 lda #$d7
009796 sta $2140
009799 cmp $2140
00979c bne $9799
00979e ldx #$00
0097a0 stx $2140
0097a3 lda $7f4100,x
0097a7 sta $2141
0097aa cpx $2140
0097ad bne $97aa
0097af inx
0097b0 cpx #$17
0097b2 beq $97b9
0097b4 stx $2140
0097b7 bra $97a3
0097b9 plp
0097ba rts

; Last piece of code
0083b5 lda $7f4116
0083b9 and #$20
0083bb sta $7f4116

.ENDIF

; ------+-----+---------------------------------------------------------------
; This routine reads the write only register values and updates the values
; in the SP700.
; Code from Memblers APU emulator
; 
update_dsp:
		lda APUInit
		bne ContinueAPUUpdate
		rts
ContinueAPUUpdate:
        php
        sep #$30 ; All 8b
		phx
WaitSPC700Ready:
        lda $2140
        cmp #$7D                ; wait for SPC ready
        bne WaitSPC700Ready

        lda #$D7
        sta $2140               ; tell SPC that CPU is ready
WSPC700Reply:
        cmp $2140               ; wait for reply
        bne WSPC700Reply

        ldx #0
        stx $2140               ; clear port 0
xfer:
		lda SNDSQR1CTRL4000, X
        sta $2141               ; send data to port 1
WSPC700Reply2:
        cpx $2140               ; wait for reply on port 0
        bne WSPC700Reply2
        inx
        cpx #$17
        beq NesRegLoadEnds
        stx $2140
        bra xfer
NesRegLoadEnds:
		plx
        plp
        rts

; ------+-----+---------------------------------------------------------------
; I do not know exactly what this is
;
;
; To be called in the order: 
;
;        jsr detect_changes
;        jsr emulate_length_counter
;        jsr backup_regs
;        jsr update_dsp
;
;.DEFINE SOUNDWORKINPROGRESS
.IFDEF SOUNDWORKINPROGRESS
; ------+-----+---------------------------------------------------------------
; Backup of some APU registers
backup_regs:
        lda SNDSQR1CTRL4000
        sta SNDTMP4000
        lda SNDSQR1E4001
        sta SNDTMP4001
        lda SNDSQR2CTRL4004
        sta SNDTMP4004
        lda SNDSQR2E4005
        sta SNDTMP4005
        lda SNDTRIACTRL4008
        sta SNDTMP4008
        lda $7F4009
        sta SNDTMP4009
        lda $7F400A
        sta SNDTMP400A
        lda SNDNOISESHM400C
        sta SNDTMP400C
        lda SNDNOISELEN400D
        sta SNDTMP400D
        lda SNDDMCCTRL400E
        sta SNDTMP400E
        lda SNDDMCSLEN4011
        sta SNDTMP4011
        rts

; ------+-----+---------------------------------------------------------------
; Does something with the audio registers
detect_changes:
        lda $7F4000
        and #%00100000
        bne decay_disabled0

        lda $7F4003
        beq +
        sta $7F4103
        lda #0
        sta $7F4003

        lda $7F4116
        ora #%00000001
        sta $7F4116
        bra end_square0
+
        lda $7F4116
        and #%11111110
        sta $7F4116
        bra end_square0

decay_disabled0:
        lda $7F4003
        sta $7F4103

end_square0:

        lda $7F4004
        and #%00100000
        bne decay_disabled1

        lda $7F4007
        beq +
        sta $7F4107
        lda #0
        sta $7F4007

        lda $7F4116
        ora #00000010
        sta $7F4116
        bra end_square1
+
        lda $7F4116
        and #%11111101
        sta $7F4116
        bra end_square1

decay_disabled1:
        lda $7F4007
        sta $7F4107
end_square1:
                        ;       triangle wave
        lda $7F4008
        and #%10000000
        bne disabled3

        lda $7F400B
        beq +
        sta $7F410B
        lda #0
        sta $7F400B
        lda $7F4116
        ora #%00000100
        sta $7F4116
        bra end_tri
+
        lda $7F4116
        and #%11111011
        sta $7F4116
        bra end_tri

disabled3:
        lda $7F400B
        sta $7F410B
end_tri:

        lda $7F400C
        and #%00100000
        bne decay_disabled2

        lda $7F400F
        beq +
        sta $7F410F
        lda #0
        sta $7F400F

        lda $7F4116
        ora #%00001000
        sta $7F4116
        bra end_noise
+
        lda $7F4116
        and #%11110111
        sta $7F4116
        bra end_noise

decay_disabled2:
        lda $7F400F
        sta $7F410F
end_noise:
                        ; check freq for sweeps
        lda $7F4001
        and #%10000000
        beq sqsw1

        lda $7F4001
        and #%00000111
        beq sqsw1x
        lda $7F4002
        beq sqsw1
        sta $7F4102
        lda #0
        sta $7F4002
        lda $7F4116
        ora #%01000000
        sta $7F4116
        bra +


sqsw1:
        lda $7F4002
        sta $7F4102
+
        bra nextcheck
sqsw1x:
        lda $7F4116
        and #%10111111
        sta $7F4116
        bra sqsw1

nextcheck:

                        ; check freq for sweeps
        lda $7F4005
        and #%10000000
        beq sqsw12

        lda $7F4005
        and #%00000111
        beq sqsw1x2
        lda $7F4006
        beq sqsw12
        sta $7F4106
        lda #0
        sta $7F4006
        lda $7F4116
        ora #%10000000
        sta $7F4116
        bra +


sqsw12:
        lda $7F4006
        sta $7F4106
+
        bra nextcheck2
sqsw1x2:
        lda $7F4116
        and #%01111111
        sta $7F4116
        bra sqsw12

nextcheck2:

        rts

; ------+-----+---------------------------------------------------------------
; Does something with the audio registers
; Counter status emulation
		
length_d3_0:
        .db $06,$0B,$15,$29,$51,$1F,$08,$0F
        .db $07,$0D,$19,$31,$61,$25,$09,$11

length_d3_1:
        .db $80,$02,$03,$04,$05,$06,$07,$08
        .db $09,$0A,$0B,$0C,$0D,$0E,$0F,$10
		
emulate_length_counter:
        lda #0
        sta $7F4115
                                ; square 0
        lda $7F4116
        and #%00000001
        beq sq0_not_changed

        lda $7F4103        
        pha
        and #%00001000
        beq sq0_d3_0

        pla
        lsr a
        lsr a
        lsr a
        lsr a

        xba
        lda #0
        xba

        tax
        lda length_d3_1,x
        sta square0_length
        bra sq0_load_end

sq0_d3_0:
        pla
        lsr a
        lsr a
        lsr a
        lsr a

        tax
        lda length_d3_0,x
        sta square0_length        

sq0_load_end:

;        lda #0
;        sta $7F4003

sq0_not_changed:

        lda $7F4115
        ora #%00000001
        sta $7F4115

        lda $7F4000
        and #%00100000
        bne sq0_counter_disabled


        lda square0_length
        beq blahsq
        dec square0_length
        bra +
blahsq:
        lda $7F4115
        and #%11111110
        sta $7F4115

+
sq0_counter_disabled:
                                ; square 1
        lda $7F4116
        and #%00000010
        beq sq1_not_changed

        lda $7F4107
        pha
        and #%00001000
        beq sq1_d3_0

        pla
        lsr a
        lsr a
        lsr a
        lsr a

        xba
        lda #0
        xba

        tax
        lda length_d3_1,x
        sta square1_length
        bra sq1_load_end

sq1_d3_0:
        pla
        lsr a
        lsr a
        lsr a
        lsr a

        tax
        lda length_d3_0,x
        sta square1_length        

sq1_load_end:

;        lda #0
;        sta $7F4007

sq1_not_changed:

        lda $7F4115
        ora #%00000010
        sta $7F4115

        lda $7F4004
        and #%00100000
        bne sq1_counter_disabled

        lda square1_length
        beq sqblah
        dec square1_length
        bra +
sqblah:
        lda $7F4115
        and #%11111101
        sta $7F4115

+

sq1_counter_disabled:

                                ; triangle channel
        lda $7F4116
        and #%00000100
        beq tri_not_changed

        lda $7F410B
        pha
        and #%00001000
        beq tri_d3_0

        pla
        lsr a
        lsr a
        lsr a
        lsr a

        xba
        lda #0
        xba

        tax
        lda length_d3_1,x
        sta triangle_length
        bra tri_load_end

tri_d3_0:
        pla
        lsr a
        lsr a
        lsr a
        lsr a

        tax
        lda length_d3_0,x
        sta triangle_length        

tri_load_end:

;        lda #0
;        sta $7F400B

tri_not_changed:

        lda $7F4115
        ora #%00000100
        sta $7F4115

        lda $7F4008
        and #%10000000
        bne tri_counter_disabled

        lda triangle_length
        beq blah
        dec triangle_length
        bra +
blah:
        lda $7F4115
        and #%11111011
        sta $7F4115

+

tri_counter_disabled:

                                ; noise channel
        lda $7F4116
        and #%00001000          ; get length value (0 if unchanged)
        beq unchanged

        lda $7F410F
        pha
        and #%00001000
        beq d3_0

        pla
        lsr a
        lsr a
        lsr a
        lsr a

        xba
        lda #0
        xba

        tax
        lda length_d3_1,x
        sta noise_length

        bra load_end

d3_0:
        pla
        lsr a
        lsr a
        lsr a
        lsr a

        tax
        lda length_d3_0,x
        sta noise_length

load_end:
;        lda #0
;        sta $7F400F

unchanged:

        lda $7F4115
        ora #%00001000
        sta $7F4115

        lda $7F400C
        and #%00100000
        bne noise_counter_disabled

        lda noise_length
        beq pleh

        dec noise_length
        bra +

pleh:
        lda $7F4115
        and #%11110111
        sta $7F4115
+

noise_counter_disabled:

        lda $7F4115
        and $7F4015
        sta $7F4115

        rts
.ENDIF		
