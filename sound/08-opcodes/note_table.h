.import note_table
.import note_length_table

	
;;; Note: octaves in music traditionally start at C, not A
A1  = $00		; the "1" means Octave 1
As1 = $01		; the "s" means "sharp"
Bb1 = $01		; the "b" means "flat"  A# == Bb, so same value
B1  = $02

C2  = $03
Cs2 = $04
Db2 = $04
D2  = $05
Ds2 = $06
Eb2 = $06
E2  = $07
F2  = $08
Fs2 = $09
Gb2 = $09
G2  = $0A
Gs2 = $0B
Ab2 = $0B
A2  = $0C
As2 = $0D
Bb2 = $0D
B2  = $0E

C3  = $0F
Cs3 = $10
Db3 = $10
D3  = $11
Ds3 = $12
Eb3 = $12
E3  = $13
F3  = $14
Fs3 = $15
Gb3 = $15
G3  = $16
Gs3 = $17
Ab3 = $17
A3  = $18
As3 = $19
Bb3 = $19
B3  = $1a

C4  = $1b
Cs4 = $1c
Db4 = $1c
D4  = $1d
Ds4 = $1e
Eb4 = $1e
E4  = $1f
F4  = $20
Fs4 = $21
Gb4 = $21
G4  = $22
Gs4 = $23
Ab4 = $23
A4  = $24
As4 = $25
Bb4 = $25
B4  = $26

C5  = $27
Cs5 = $28
Db5 = $28
D5  = $29
Ds5 = $2a
Eb5 = $2a
E5  = $2b
F5  = $2c
Fs5 = $2d
Gb5 = $2d
G5  = $2e
Gs5 = $2f
Ab5 = $2f
A5  = $30
As5 = $31
Bb5 = $31
B5  = $32

C6  = $33
Cs6 = $34
Db6 = $34
D6  = $35
Ds6 = $36
Eb6 = $36
E6  = $37
F6  = $38
Fs6 = $39
Gb6 = $39
G6  = $3a
Gs6 = $3b
Ab6 = $3b
A6  = $3c
As6 = $3d
Bb6 = $3d
B6  = $3e

C7  = $3f
Cs7 = $40
Db7 = $40
D7  = $41
Ds7 = $42
Eb7 = $42
E7  = $43
F7  = $44
Fs7 = $45
Gb7 = $45
G7  = $46
Gs7 = $47
Ab7 = $47
A7  = $48
As7 = $49
Bb7 = $49
B7  = $4a

C8  = $4b
Cs8 = $4c
Db8 = $4c
D8  = $4d
Ds8 = $4e
Eb8 = $4e
E8  = $4f
F8  = $50
Fs8 = $51
Gb8 = $51
G8  = $52
Gs8 = $53
Ab8 = $53
A8  = $54
As8 = $55
Bb8 = $55
B8  = $56

C9  = $57
Cs9 = $58
Db9 = $58
D9  = $59
Ds9 = $5a
Eb9 = $5a
E9  = $5b
F9  = $5c
Fs9 = $5d
Gb9 = $5d

rest = $5e

;;; Note length constants (aliases)
thirtysecond = $80
sixteenth = $81
eighth = $82
quarter = $83
half = $84
whole = $85
d_sixteenth = $86
d_eighth = $87
d_quarter = $88
d_half = $89
d_whole = $8A   ;don't forget we are counting in hex
t_quarter = $8B
five_eighths = $8C
five_sixteenths = $8D
	
; Local Variables: 
; mode: asm
; End: 
