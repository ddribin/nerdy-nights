	.include "sound_engine.h"

	.export song4_header

song4_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $B0           ;initial duty (10)
    .byte ve_battlekid_1b  ;volume envelope
    .word song4_square1 ;pointer to stream
    .byte $60           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $30           ;initial duty (00)
    .byte ve_short_staccato ;volume envelope
    .word song4_square2 ;pointer to stream
    .byte $60           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .byte ve_battlekid_1b  ;volume envelope
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
    .byte loop
    .word song4_square1
    
song4_square2:
    .byte quarter
    .byte E3, B3, B3, B3, B2, Fs3, Fs3, Fs3
    .byte Fs3, A3, A3, A3, B2, E3, E3, E3
    .byte E3, B3, B3, B3, B3, A3, G3, Fs3
    .byte E3, B3, A3, Fs3, E3, E3, E3, E3;d_half, rest
    .byte loop
    .word song4_square2
    
song4_tri:
    .byte half, E4, G4, B3, Eb4
    .byte Fs4, A4, B3, E4
    .byte G4, B4, quarter, A4, B4, half, C5
    .byte eighth, E4, Fs4, G4, A4, B3, C4, D4, Eb4, A3, E4, d_half, rest
    .byte loop
    .word song4_tri