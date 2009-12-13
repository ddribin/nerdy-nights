
	;; Functions
	.global		sound_init
	.global 	sound_disable
	.global		sound_load
	.global 	sound_play_frame

	;; Sound engine globals
	.globalzp	sound_ptr
	.global 	sound_disable_flag

	;; Stream globals
	.global		stream_status
	.global		stream_channel
	.global		stream_ptr_lo
	.global		stream_ptr_hi
	.global		stream_ve
	.global		stream_ve_index
	.global		stream_vol_duty

	;; These are channel constants.
	SQUARE_1	= $00
	SQUARE_2	= $01
	TRIANGLE	= $02
	NOISE		= $03

	;; These are stream numer constants. Stream number is used to
	;; index into variables.
	MUSIC_SQ1	= $00
	MUSIC_SQ2	= $01
	MUSIC_TRI	= $02
	MUSIC_NOI	= $03
	SFX_1		= $04
	SFX_2		= $05


	;; Volume envelope constants
	ve_short_staccato	= $00
	ve_fade_in 		= $01
	ve_blip_echo 		= $02
	ve_tgl_1 		= $03
	ve_tgl_2 		= $04
	ve_battlekid_1 		= $05
	ve_battlekid_1b 	= $06
	ve_battlekid_2 		= $07
	ve_battlekid_2b 	= $08

	;; opcode constants
	endsound 	= $A0
	loop		= $A1
	volume_envelope	= $A2
	duty 		= $A3
	
	.include "note_table.h"
	.include "songs.h"
	
; Local Variables: 
; mode: asm
; End: 
