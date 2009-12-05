
	.include "sound_engine.h"
	
	.export	sound_opcodes

;;; This is our jump table.
sound_opcodes:
	.word	se_op_endsound	    ; $A0
	.word	se_op_infinite_loop ; $A1
	.word	se_op_change_ve	    ; $A2
	.word	se_op_duty	    ; $A3
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
	rts

se_op_duty:
	rts