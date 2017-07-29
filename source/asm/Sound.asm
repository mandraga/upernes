

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
	jsr update_dsp
	rts

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
		BREAK
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

		BREAK2
        ldx #0
        stx $2140               ; clear port 0
xfer:
        ;lda $7F4100,x
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
;        lda $7F4002
;        sta $7F4102
        lda SNDSQR2CTRL4004
        sta SNDTMP4004
        lda SNDSQR2E4005
        sta SNDTMP4005
;        lda $7F4006
;        sta $7F4106
        lda SNDTRIACTRL4008
        sta SNDTMP4008
        lda $7F4009
        sta SNDTMP4009
        lda $7F400A
        sta SNDTMP400A
;        lda $7F400B
;        sta $7F410B
        lda SNDNOISESHM400C
        sta SNDTMP400C
        lda SNDNOISELEN400D
        sta SNDTMP400D
        lda SNDDMCCTRL400E
        sta SNDTMP400E
        lda SNDDMCSLEN4011
        sta SNDTMP4011
;        lda $7F4015
;        sta $7F4115
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
