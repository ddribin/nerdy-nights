
	.include "sound_engine.h"
	
;;; This is our pointer table. Each entry is a pointer to a song header
	.import song0_header
	.import song1_header
	.import song2_header
	.import song3_header
	.import	song4_header
	.import	song5_header
	.import	song6_header
	.import	song7_header
	
song_headers:
	.word	song0_header	; This is a silence song.
	.word	song1_header	; The Guardian Legend Boss song
	.word	song2_header	; A sound effect. Try playing it over other songs
	.word	song3_header	; Dragon Warrior overland song
	.word	song4_header	; Song using note lengths and rests
	.word	song5_header
	.word	song6_header
	.word	song7_header
	