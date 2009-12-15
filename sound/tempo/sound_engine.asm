
	.include "note_table.h"
	.include "sound_defs.h"

	;; Exported symbols
	.export sound_init
	.export sound_disable
	.export	sound_load
	.export sound_play_frame

	.export sound_disable_flag
	.export stream_status

	.zeropage
	
	sound_ptr:		.res	2

	.segment "SRAM1"

;;; A flag that keeps track of whether or the sound engine is disabled or not.
sound_disable_flag:	.res	1
sound_temp1:		.res	1
sound_temp2:		.res	1
sound_sq1_old:		.res	1 ; The last value written to $4003
sound_sq2_old:		.res	1 ; The last value written to $4007
soft_apu_ports:		.res	16

;;; Reserve 6 bytes, one for each stream
	
stream_curr_sound:	.res	6 ; Current song/fx loaded
;;; Status byte.
;;;   Bit 0 (1: stream enabled, 0: stream disabled)
;;;   Bit 1 (1: resting, 0: not resting)
stream_status:		.res	6
stream_channel:		.res	6 ; What channel is this stream playing on?
stream_ptr_lo:		.res	6 ; Low byte of pointer to data stream
stream_ptr_hi:		.res	6 ; High byte of pointer to data stream
stream_vol_duty:	.res	6 ; Stream volume/duty settings
stream_note_lo:		.res	6 ; Low 8 bits of period for current note
stream_note_hi:		.res	6 ; High 3 bites of period for current note
stream_tempo:		.res	6 ; The value to add to our ticker each frame
stream_ticker_total:	.res	6 ; Our running ticker totoal
stream_note_length_counter: .res 6
stream_note_length:	.res	6
	

;;;;;;;;;;;;;;;

	.code
	
sound_init:
	;; Enable Square 1, Square 2, Triangle and Noise channels
	lda	#$0f
	sta	$4015

	lda	#$00
	sta	sound_disable_flag ; Clear disable flag
	;; Later, if we have other variables we want to initialize, we will do
	;; that here.

	;; Initializing these to $FF ensures that the first notes of these
	;; songs ins't skipped.
	lda	#$ff
	sta	sound_sq1_old
	sta	sound_sq2_old

se_silence:	
	lda	#$30
	sta	soft_apu_ports	; Set Square 1 volume to 0
	sta	soft_apu_ports+4 ; Set Square 2 volumne to 0
	sta	soft_apu_ports+12 ; Set Noise volume to 0
	lda	#$80
	sta	soft_apu_ports+8 ; Silence Triangle
	
	rts

sound_disable:
	lda	#$00
	sta	$4015		; Disable all channels
	lda	#$01
	sta	sound_disable_flag ; Set disable flag
	rts

;;; 
;;; sound_load will preprate the sound engine to play a song or sfx.
;;; Inputs:
;;; 	A: song/sfx number to play
;;; 
sound_load:
	sta	sound_temp1	; Save song number
	asl	a		; Multiply by 2. Index into a table of pointers.
	tay
	lda	song_headers, y	; Setup the pointer to our song header
	sta	sound_ptr
	lda	song_headers+1, y
	sta	sound_ptr+1

	ldy	#$00
	lda	(sound_ptr), y	; Read the first byte: # streams
	;; Store in a temp variable. We will use this as a loop counter: how
	;; many streams to read stream headers for
	sta	sound_temp2
	iny
@loop:
	lda	(sound_ptr), y	; Stream number
	tax			; Stream number acts as our variable index
	iny

	lda	(sound_ptr), y	; Status byte. 1=enable, 0=disable
	sta	stream_status, x
	;; If status byte is 0, stream disable, so we are done
	beq	@next_stream
	iny

	lda	(sound_ptr), y	; Channel number
	sta	stream_channel, x
	iny

	lda	(sound_ptr), y	; Initial duty and volume settings
	sta	stream_vol_duty, x
	iny

	;; Pointer to stream data. Little endian, so low byte first
	lda	(sound_ptr), y
	sta	stream_ptr_lo, x
	iny

	lda	(sound_ptr), y
	sta	stream_ptr_hi, x
	iny

	lda	(sound_ptr), y
	sta	stream_tempo, x

	lda	#$ff
	sta	stream_ticker_total, x

	lda	#$01
	sta	stream_note_length_counter, x
	sta	stream_note_length, x
@next_stream:
	iny

	lda	sound_temp1	; Song number
	sta	stream_curr_sound, x

	dec	sound_temp2	; Our loop counter
	bne	@loop
	
	rts

sound_play_frame:
	lda	sound_disable_flag
	bne	@done		; If disable flag is set, dont' advance a frame

	;; Silence all channels. se_set_apu will set volumen later for all
	;; channels that are enabled. The purpose of this subroutine call is
	;; to silence all channels that aren't used by any streams
	jsr	se_silence

	ldx	#$00
@loop:
	lda	stream_status, x
	and	#$01		; Check whether the stream is active
	beq	@endloop	; If the channel isn't active, skip it

	;; Add the tempo to the ticker total.  If there is an $FF -> 0
	;; transition, there is a tick
	lda	stream_ticker_total, x
	clc
	adc	stream_tempo, x
	sta	stream_ticker_total, x
	;; Carry clear = no tick. If no tick, we are done with this stream.
	bcc	@set_buffer

	;; Else there is a tick. Decrement the note length counter
	dec	stream_note_length_counter, x
	;; If counter is non-zero, our note isn't finished playing yet
	bne	@set_buffer
	;; Else our note is finished. Reload the note length counter
	lda	stream_note_length, x
	sta	stream_note_length_counter, x
	
	jsr	se_fetch_byte
@set_buffer:
	;; Copy the current stream's sound data for the current from into our
	;; temporary APU vars (soft_apu_ports)
	jsr	se_set_temp_ports
@endloop:
	inx
	cpx	#$06
	bne	@loop
	;; Copy the temporary APU variables (soft_apu_ports) to the real
	;; APU ports ($4000, $4001, etc.)
	jsr	se_set_apu
@done:
	rts

;;;
;;; se_fetch_byte reads one byte from the sound data stream and handles it
;;; Inputs:
;;; 	X: stream number
;;; 
se_fetch_byte:
	lda	stream_ptr_lo, x
	sta	sound_ptr
	lda	stream_ptr_hi, x
	sta	sound_ptr+1

	ldy	#$00
@fetch:
	lda	(sound_ptr), y
	bpl	@note		; If < #$80, it's a Note
	cmp	#$A0
	bcc	@note_length	; Else if < #$A0, it's a Note Length
@opcode:			; Else it's an opcode
	;; Do Opcode stuff

	;; If $FF, end of stream so disable it and silence
	cmp	#$ff
	bne	@end
	lda	stream_status, x
	and	#%11111110
	sta	stream_status, x ; Clear enable flag in status byte

	lda	stream_channel, x
	cmp	#TRIANGLE
	;; Triangle is silenced differently from squares and noise
	beq	@silence_tri
	lda	#$30		; Squaures and noise silenced with #$30
	bne	@silence
@silence_tri:
	lda	#$80		; Triangle silenced with #$80
@silence:
	sta	stream_vol_duty, x ; Store silence value in the stream's volume
	jmp	@update_pointer	   ; Done
@note_length:
	;; Do Note Length stuff
	and	#%01111111	; Chop off bit 7
	sty	sound_temp1	; Save Y because we are about to destroy it
	tay
	lda	note_length_table, y ; Get the note length count value
	sta	stream_note_length, x
	sta	stream_note_length_counter, x
	ldy	sound_temp1	; Restore Y
	iny
	jmp	@fetch		; Fetch another byte
@note:
	;; Do Note stuff
	sty	sound_temp1	; Save our index into the data stream
	asl	a
	tay
	lda	note_table, y
	sta	stream_note_lo, x
	lda	note_table+1, y
	sta	stream_note_hi, x
	ldy	sound_temp1	; Restore data stream index

	;; Check if it's a rest and modify the status flag appropriately
	jsr	se_check_rest
@update_pointer:
	iny
	tya
	clc
	adc	stream_ptr_lo, x
	sta	stream_ptr_lo, x
	bcc	@end
	inc	stream_ptr_hi, x
@end:
	rts


;;;
;;; se_check_rest will read a byte from the data stream and determine if
;;; it is a rest or not.  It will set our clear the current stream's
;;; rest flag accordingly.
;;; Inputs:
;;; 	X: stream number
;;; 	Y: data stream index
;;; 
se_check_rest:
	lda	(sound_ptr), y	; Read the note byte again
	cmp	#rest
	bne	@not_rest
@rest:
	lda	stream_status, x
	ora	#%00000010	; Set the rest bit in the status byte
	bne	@store		; This will always branch (cheaper than a jmp)
@not_rest:
	lda	stream_status, x
	and	#%11111101	; Clear the rest bit in the status byte
@store:
	sta	stream_status, x
	rts

;;;
;;; se_set_temp_ports will copy a stream's sound data to the temporary APU
;;; variables.
;;; Inputs:
;;; 	X: stream number
;;; 
se_set_temp_ports:
	lda	stream_channel, x
	;; Multiply by 4 so our index will point to the right set of registers
	asl	a
	asl	a
	tay
	
	;; Volume
	lda	stream_vol_duty, x
	sta	soft_apu_ports, y

	;; Sweep
	lda	#$08
	sta	soft_apu_ports+1, y
	
	;; Period lo
	lda	stream_note_lo, x
	sta	soft_apu_ports+2, y
	
	;; Period high
	lda	stream_note_hi, x
	sta	soft_apu_ports+3, y

	;; Check the rest flag. If set, overwrite volume with silence value
	lda	stream_status, x
	and	#%00000010
	beq	@done		; If clear, no rest, so quit
	lda	stream_channel, x
	cmp	#TRIANGLE	; If Triangle, silence with #$80
	beq	@tri
	lda	#$30		; Square and Noise, silence with #$30
	bne	@store
@tri:
	lda	#$80
@store:
	sta	soft_apu_ports, y
@done:
	rts
	
;;; 
;;; se_set_apu copies the temporary APU variables to the real APU ports.
;;; 
se_set_apu:
@square1:
	lda	soft_apu_ports+0
	sta	$4000
	lda	soft_apu_ports+1
	sta	$4001
	lda	soft_apu_ports+2
	sta	$4002
	lda	soft_apu_ports+3
	cmp	sound_sq1_old	; Compare to last write
	beq	@square2	; Don't write this frame if they were equal
	sta	$4003
	sta	sound_sq1_old	; Save the value we just wrote to $4003
@square2:
	lda	soft_apu_ports+4
	sta	$4004
	lda	soft_apu_ports+5
	sta	$4005
	lda	soft_apu_ports+6
	sta	$4006
	;; Conditionally write $4007, as above
	lda	soft_apu_ports+7
	cmp	sound_sq2_old
	beq	@triangle
	sta	$4007
	sta	sound_sq2_old
@triangle:
	lda	soft_apu_ports+8
	sta	$4008
	lda	soft_apu_ports+10 ; There is no $4009, so we skip it
	sta	$400a
	lda	soft_apu_ports+11
	sta	$400b
@noise:
	lda	soft_apu_ports+12
	sta	$400c
	lda	soft_apu_ports+14 ; There is no $400E, so we skip it
	sta	$400e
	lda	soft_apu_ports+15
	sta	$400f
	rts

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