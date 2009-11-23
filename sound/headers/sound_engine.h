	
	;; These are channel constants.
	SQUARE_1	= $00
	SQUARE_2	= $01
	TRIANGLE	= $02
	NOISE		= $03

	;; These are stream # constants. Stream # is used to index into variables.
	MUSIC_SQ1	= $00
	MUSIC_SQ2	= $01
	MUSIC_TRI	= $02
	MUSIC_NOI	= $03
	SFX_1		= $04
	SFX_2		= $05

	;; If you add a new song, change this number.  headers.asm checks this
	;; number in its song_up and song_down subroutines to determin when
	;; to wrap around.
	NUM_SONGS	= $04
	
;;;;;;;;;;;;;;;

	.import		sound_init
	.import 	sound_disable
	.import		sound_load
	.import 	sound_play_frame

	.import 	sound_disable_flag
	
	.import		stream_status

; Local Variables: 
; mode: asm
; End: 
