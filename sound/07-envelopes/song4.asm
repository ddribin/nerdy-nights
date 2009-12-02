	.include "note_table.h"
	.include "sound_defs.h"

	.export song4_header

song4_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $BC           ;initial volume (C) and duty (10)
    .word song4_square1 ;pointer to stream
    .byte $60           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $3A          ;initial volume (A) and duty (00)
    .word song4_square2 ;pointer to stream
    .byte $60           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .word song4_tri     ;pointer to stream
    .byte $60           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  Our load routine will skip the
                        ;   rest of the reads if the status byte is 0.
                        ;   We are disabling Noise because we haven't covered it yet.
                        
song4_square1:
    .byte half, E4, quarter, G4, eighth, Fs4, E4, d_sixteenth, Eb4, E4, Fs4, t_quarter, rest, half, rest
    .byte       Fs4, quarter, A4, eighth, G4, Fs4, d_sixteenth, E4, Fs4, G4, t_quarter, rest, half, rest
    .byte       G4, quarter, B4, eighth, A4, G4, quarter, A4, B4, C5, eighth, B4, A4
    .byte       B4, A4, G4, Fs4, Eb4, E4, Fs4, G4, Fs4, E4, d_half, rest
    .byte $FF
    
song4_square2:
    .byte eighth, E3, rest, B3, rest, B3, rest, B3, rest, B2, rest, Fs3, rest, Fs3, rest, Fs3, rest
    .byte         Fs3, rest, A3, rest, A3, rest, A3, rest, B2, rest, E3, rest, E3, rest, E3, rest
    .byte         E3, rest, B3, rest, B3, rest, B3, rest, B3, rest, A3, rest, G3, rest, Fs3, rest
    .byte eighth, E3, rest, B3, rest, A3, rest, Fs3, rest, E3, rest, d_half, rest
    .byte $FF
    
song4_tri:
    .byte half, E4, G4, B3, Eb4
    .byte Fs4, A4, B3, E4
    .byte G4, B4, quarter, A4, B4, half, C5
    .byte eighth, E4, Fs4, G4, A4, B3, C4, D4, Eb4, A3, E4, d_half, rest
    .byte $FF
