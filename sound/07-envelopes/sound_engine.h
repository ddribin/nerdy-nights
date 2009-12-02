	
	;; If you add a new song, change this number.  headers.asm checks this
	;; number in its song_up and song_down subroutines to determine when
	;; to wrap around.
	NUM_SONGS	= $06
	
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
