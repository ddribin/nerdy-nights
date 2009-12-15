
	.include "note_table.h"

	.export	sfx1_data
	.export	sfx2_data
	.export	sfx3_data

sfx1_data:
	;; Cm/9
	.byte	C3, D3, Ds3, G3, C4, D4, Ds4, G4
	.byte	C5, D5, Ds5, G5, C6, D6, Ds6, G6, C7, $FF
sfx2_data:
	;; Cmaj7
	.byte	C3, E3, G3, B3, C4, E4, G4, B4
	.byte	C5, E5, G5, B5, C6, E6, G6, B6, C7, $FF
sfx3_data:
         ;; Cm/7/6
	.byte	C3, Ds3, G3, A3, B3, C4, Ds4, G4, A4, B4 
	.byte	C5, Ds5, G5, A5, B5, C6, Ds6, G6, $FF