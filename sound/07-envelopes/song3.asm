	.include "note_table.h"
	.include "sound_defs.h"

	.export song3_header

song3_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $BC           ;initial volume (C) and duty (10)
    .word song3_square1 ;pointer to stream
    .byte $80           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $3A           ;initial volume (A) and duty (00)
    .word song3_square2 ;pointer to stream
    .byte $80           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .word song3_tri     ;pointer to stream
    .byte $80           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  Our load routine will skip the
                        ;   rest of the reads if the status byte is 0.
                        ;   We are disabling Noise because we haven't covered it yet.
    
song3_square1:
    .byte eighth, A3, C4, E4, A4, C5, E5, A5, F3 ;some notes.  A minor
    .byte G3, B3, D4, G4, B4, D5, G5, E3  ;Gmajor
    .byte F3, A3, C4, F4, A4, C5, F5, C5 ;F major
    .byte F3, A3, C4, F4, A4, C5, F5, rest ;F major
    .byte $FF
    
song3_square2:
    .byte eighth, A3, A3, A3, E4, A3, A3, E4, A3 
    .byte G3, G3, G3, D4, G3, G3, D4, G3
    .byte F3, F3, F3, C4, F3, F3, C4, F3
    .byte F3, F3, F3, C4, F3, F3, C4, rest
    .byte $FF
    
song3_tri:
    .byte whole, A3, G3, F3, F3
    .byte $FF
	