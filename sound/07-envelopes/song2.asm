	.include "note_table.h"
	.include "sound_defs.h"

	.export song2_header

song2_header:
    .byte $01           ;1 stream
    
    .byte SFX_1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $7F           ;initial volume (F) and duty (01)
    .word song2_square2 ;pointer to stream
    .byte $80           ;tempo
    
    
song2_square2:
    .byte eighth, D3, D2
    .byte $FF
	
