
	.include "note_table.h"
	.include "sound_data.h"
	

	;; Exported symbols
	.export sound_init
	.export sound_disable
	.export	sound_load
	.export sound_play_frame

	.export sound_disable_flag
	.export sfx_playing
	.export stream_status

	.segment "SRAM1"

;;; A flag that keeps track of whether or the sound engine is disabled or not.
sound_disable_flag:	.res	1

;;; A primitive counter used to time notes in this demo
sound_frame_counter:	.res	1

;;; A flag that tells us if our sound is playing or not.
sfx_playing:		.res	1

;;; Our current position in the sound data.
sfx_index:		.res	1

;;; Reserve 6 bytes, one for each stream
	
stream_curr_sound:	.res	6 ; Current song/fx loaded
;;; Status byte. Bit 0 (1: stream enabled, 0: stream disabled)
stream_status:		.res	6


	.code
	
sound_init:
	lda	#$0f
	sta	$4015		; Enable Square 1, Square 2, Triangle and Noise channels

	lda	#$30
	sta	$4000		; Set Square 1 volume to 0
	sta	$4004		; Set Square 2 volumne to 0
	sta	$400c		; Set Noice volume to 0
	lda	#$80
	sta	$4008		; Silence Triangle

	lda	#$00
	sta	sound_disable_flag ; Clear disable flag
	;; Later, if we have other variables we want to initialize, we will do
	;; that here.
	sta	sfx_playing
	sta	sfx_index
	sta	sound_frame_counter
	
	rts

sound_disable:
	lda	#$00
	sta	$4015		; Disable all channels
	lda	#$01
	sta	sound_disable_flag ; Set disable flag
	rts

sound_load:
	lda	#$01
	sta	sfx_playing	; Set playing flag
	lda	#$00
	sta	sfx_index	; Reset the index and count
	sta	sound_frame_counter
	rts

sound_play_frame:
	lda	sound_disable_flag
	bne	@done		; If disable flag is set, don't advance a frame

	lda	sfx_playing
	beq	@done		; If our sound isn't playing, don't advance a frame

	inc	sound_frame_counter
	lda	sound_frame_counter
	;; *** Change this compare value to make the notes play faster or slower ***
	cmp	#$08
	bne	@done

	ldy	sfx_index
	;; Read the next byte from our sound data stream
	;; *** Uncomment one of the other lines below to play another data streams
	lda	sfx1_data, y
;	lda	sfx2_data, y
;	lda	sfx3_data, y

	cmp	#$ff
	bne	@note		; If not  #$FF, we have a note value
	lda	#$30		; Else if FF, we are at the end of the sound data
	sta	$4000		;  stop the sound and return
	lda	#$00
	sta	sfx_playing
	sta	sound_frame_counter
	rts

@note:
	asl	a		; Multiple by 2 because our note table is store as words
	tay			; We'll use this as an index into the note table

	lda	note_table, y	; Read the low byte of our period from the table
	sta	$4002
	lda	note_table+1, y	; Read the high byte of our period from the table
	sta	$4003
	lda	#$7f		; Duty cucle 01, volume F
	sta	$4000
	lda	#$08		; Set negate flag so low Square notes aren't silenced
	sta	$4001

	;; Move our index to the next byte position in the data stream
	inc	sfx_index
	;; Reset frame counter so we can start counting to 8 again
	lda	#$00
	sta	sound_frame_counter

@done:
	rts
