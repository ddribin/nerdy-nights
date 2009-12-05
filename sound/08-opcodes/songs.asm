
	.include "sound_engine.h"
	
;;; This is our pointer table. Each entry is a pointer to a song header
	.import song0_header
	.import song1_header
	.import song2_header
	.import song3_header
	.import	song4_header
	.import	song5_header
	
song_headers:
	.word	song0_header	; This is a silence song.
	.word	song1_header	; Evil, demented notes
	.word	song2_header	; A sound effect. Try playing it over other songs
	.word	song3_header	; A little chord progression
	.word	song4_header
	.word	song5_header
	