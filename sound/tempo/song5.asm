	.include "note_table.h"
	.include "sound_defs.h"

	.export song5_header
	
song5_header:
    .byte $01           ;1 stream
    
    .byte SFX_1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $7F           ;initial volume (F) and duty (01)
    .word song5_square2 ;pointer to stream
    .byte $FF           ;tempo..very fast tempo
    
    
song5_square2:
    .byte thirtysecond, C4, D8, C5, D7, C6, D6, C7, D5, C8, D8 ;some random notes played very fast
    .byte $FF
	