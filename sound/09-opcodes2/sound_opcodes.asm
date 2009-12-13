
	.include "sound_engine.h"
	
	.export	sound_opcodes

;;; This is our jump table.
sound_opcodes:
	.word	se_op_endsound	    	 ; $A0
	.word	se_op_infinite_loop 	 ; $A1
	.word	se_op_change_ve	    	 ; $A2
	.word	se_op_duty	    	 ; $A3
	.word	se_op_set_loop1_counter	 ; $A4
	.word	se_op_loop1		 ; $A5
	.word	se_op_set_note_offset	 ; $A6
	.word 	se_op_adjust_note_offset ; $A7
	.word	se_op_transpose		 ; $A8
	;; etc, 1 entry per subroutine

;;; These are the actual opcode subroutines

se_op_endsound:
	lda	stream_status, x ; End of stream, so disable it and silence
	and	#%11111110
	sta	stream_status, x ; Clear enable flag in status byte

	lda	stream_channel, x
	cmp	#TRIANGLE
	beq	@silence_tri	; Triangle is silenced differently
	lda	#$30		; Squares and noise silenced with #$30
	bne	@silence	; This will always branch, cheaper than jmp
@silence_tri:
	lda	#$80		; Triangle silenced with #$80
@silence:
	sta	stream_vol_duty, x
	
	rts

se_op_infinite_loop:
	lda	(sound_ptr), y	 ; Read ptr low from the data stream
	sta	stream_ptr_lo, x ; Update our data stream position
	iny			 ; Next byte
	lda	(sound_ptr), y	 ; Read ptr high from the data stream
	sta	stream_ptr_hi, x ; Update our data stream position

	;; Update the pontier to reflect the new position
	sta	sound_ptr+1
	lda	stream_ptr_lo, x
	sta	sound_ptr

	;; After opcodes return, we do an iny.  Since we reset the stream
	;; buffer position, we will want y to restart at 0 again.
	ldy	#$FF
	
	rts

se_op_change_ve:
	lda	(sound_ptr), y	; Read the argument
	sta	stream_ve, x	; Store it in our volume envelope variable
	lda	#$00
	sta	stream_ve_index, x ; Reset envelope index to beginning
	rts

se_op_duty:
	lda	(sound_ptr), y	; Read the argument
	sta	stream_vol_duty, x
	rts

se_op_set_loop1_counter:
	lda	(sound_ptr), y	; Read the argument (# times to loop)
	sta	stream_loop1, x	; Store it in the loop counter variable
	rts

se_op_loop1:
	dec	stream_loop1, x	; Decrement the counter
	lda	stream_loop1, x
	beq	@last_iteration	; If zero, we are done looping
	jmp	se_op_infinite_loop ; If not zero, jump back
@last_iteration:
	;; Skip the first byte of the address argument.  The second byte
	;; will be skipped automatically upon return. See se_fetch_byte
	;; after "jsr se_opcode_launcher"
	iny
	rts

se_op_set_note_offset:
	lda	(sound_ptr), y	; Read the argument
	sta	stream_note_offset, x ; Set the note offset
	rts

se_op_adjust_note_offset:
	lda	(sound_ptr), y	; Read the argument (what value to add)
	clc
	adc	stream_note_offset, x ; Add it to the current offset
	sta	stream_note_offset, x ;  and save it.
	rts
	
se_op_transpose:
	lda	(sound_ptr), y	; Read low byte of pointer to lookup table
	sta	sound_ptr2
	iny
	lda	(sound_ptr), y	; Read high byte of pointer to lookup table
	sta	sound_ptr2+1

	;; Get loop counter, and put it in Y. This will be our idex into
	;; the lookup table.
	sty	sound_temp1
	lda	stream_loop1, x
	tay
	dey			; Subtract 1 because indexes start from 0

	;; Read a value from the table, and add it to the note offset.
	lda	(sound_ptr2), y
	clc
	adc	stream_note_offset, x
	sta	stream_note_offset, x

	ldy	sound_temp1	; Restore Y
	rts
