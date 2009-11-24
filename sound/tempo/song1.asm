	.include "note_table.h"
	.include "sound_defs.h"

	.export song1_header

song1_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $77           ;initial volume (7) and duty (01)
    .word song1_square1 ;pointer to stream
    .byte $40		;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $B7           ;initial volume (7) and duty (10)
    .word song1_square2 ;pointer to stream
    .byte $40		;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .word song1_tri     ;pointer to stream
    .byte $40		;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  Our load routine will skip the
                        ;   rest of the reads if the status byte is 0.
                        ;   We are disabling Noise because we haven't covered it yet.
    
song1_square1:
    .byte B2, D3, F3, Gs3, B3, D4, F4, Gs4, B4, D5, F5, Gs5, B5, D6, F6, Gs6    ;bunch of minor thirds.  diminished sound
    .byte Bb2, Db3, E3, G3, Bb3, Db4, E4, G4, Bb4, Db5, E5, G5, Bb5, Db6, E6, G6 ;same again but down a half step
    .byte $FF
    
song1_square2:
    .byte Gs5, F5, D5, Gs5, F5, D5, B4, F5, D5, B4, Gs4, D5, B4, Gs4, F4, B4
    .byte G5, E5, Db5, G5, E5, Db5, Bb4, E5, Db5, Bb4, G4, Db5, Bb4, G4, E4, Bb4
    .byte $FF
    
song1_tri:
    .byte F6, D6, B5, D6, B5, Gs5, B5, Gs5, F5, Gs5, F5, D5, F5, D5, B4, Gs4
    .byte E6, Db6, Bb5, Db6, Bb5, G5, Bb5, G5, E5, G5, E5, Db5, E5, Db5, Bb4, G4
    .byte $FF