.include "note_table.h"

.segment "HEADER"
	
	.byte	"NES", $1A	; iNES header identifier
	.byte	2		; 2x 16KB PRG code
	.byte	1		; 1x  8KB CHR data
	.byte	$01, $00	; Mapper 0, vertical mirroring

;;;;;;;;;;;;;;;

.zeropage

joypad1:		.res	1	; Button states for the current frame
joypad1_old:		.res 	1	; Last frame's button states
joypad1_pressed:	.res	1	; Current frame's off_to_on transitions
current_note:		.res	1	; Used to index into our note_table
note_value:		.res	1	; There are 12 possible note values.
					; (A-G#, represented by $00 - $0B)
note_octave:		.res	1	; What octave our note is in (1-9)
	
;;; Main program sets this and waits for the NMI to clear it.  Ensures the main
;;; program is run only once per frame.  For more information, See Disch's document.
sleeping:		.res	1

ptr1:			.res	2 	; An address pointer

;;;;;;;;;;;;;;;
	
;;; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

.segment "CODE"

reset:
	sei			; Disable IRQs
	cld			; Disable decimal mode
	ldx	#$ff		; Set up stack
	txs			;  .
	inx			; Now X = 0

	;; First wait for vblank to make sure PPU is ready
vblankwait1:
	bit	$2002
	bpl	vblankwait1

clear_memory:
	lda	#$00
	sta	$0000, x
	sta	$0100, x
	sta	$0300, x
	sta	$0400, x
	sta	$0500, x
	sta	$0600, x
	sta	$0700, x
	lda	#$fe
	sta	$0200, x	; Move all sprites off screen
	inx
	bne	clear_memory

	;; Second wait for vblank, PPU is ready after this
vblankwait2:
	bit	$2002
	bpl	vblankwait2

clear_nametables:
	lda	$2002		; Read PPU status to reset the high/low latch
	lda	#$20		; Write the high byte of $2000
	sta	$2006		;  .
	lda	#$00		; Write the low byte of $2000
	sta	$2006		;  .
	ldx	#$08		; Prepare to fill 8 pages ($800 bytes)
	ldy	#$00		;  x/y is 16-bit counter, high byte in x
	lda	#$00		; Fill with tile $00 (a transparent box)
				; Also sets attribute tables to $00
@loop:
	sta	$2007
	dey
	bne	@loop
	dex
	bne	@loop
	
	;; Set a couple palette colors. This demo only uses two.
init_palette:
	lda	$2002		; Reset PPU HI/LO latch
	
	lda	#$3f
	sta	$2006
	lda	#$00
	sta	$2006		; Palette data starts at $3F00

	lda	#$0f		; Black
	sta	$2007
	lda	#$30		; White
	sta	$2007

enable_sound_channels:
	lda	#%00000001
	sta	$4015		; Enable Square 1

	lda	#C4
	sta	current_note	; Start with a middle C
	jsr	get_note_and_octave

	lda	#$88
	sta	$2000		; Enable NMIs
	lda	#$18
	sta	$2001		; Turn PPU on
	
forever:
	inc	sleeping	; go to sleep (wait for NMI).
	
	;; Wait for NMI to clear the sleeping flag and wake us up
@loop:
	lda	sleeping
	bne	@loop

	;; When NMI wakes us up, handle input and go back to sleep
	jsr	read_joypad
	jsr	handle_input
	
	jmp	forever

nmi:
	;; Push all registers on the stack
	pha
	txa
	pha
	tya
	pha

	jsr	draw_note	; Draws the note and octave to the screen
	lda	#$00		; Set scroll
	sta	$2005
	sta	$2005

	lda	#$00
	sta	sleeping	; Wake up the main program

	;; Pull all registers off the stack
	pla
	tay
	pla
	tax
	pla
	
	rti

;;; 
;;; read_joypad will capture the current button state and store it in joypad1.
;;; Off-to-on transitions will be stored in joypad1_pressed
;;; 
read_joypad:
	lda	joypad1
	sta	joypad1_old	; Save last frame's joypad button states

	lda	#$01
	sta	$4016
	lda	#$00
	sta	$4016

	ldx	#$08
@loop:
	lda	$4016
	lsr	a
	rol	joypad1		; A, B, select, start, up, down, left right
	dex
	bne	@loop

	lda	joypad1_old	; What was pressed last frame. EOR to flip all the bits
	eor	#$ff		;  to find what was not pressed last frame.
	and	joypad1		; What is pressed this frame
	sta	joypad1_pressed	; Stores off-to-on transitoins
	
	rts

;;;
;;; handle_input will perform actions based on input:
;;;  up - play current note
;;;  down - stop playing the note
;;;  left - cycle down a note
;;;  right - cycle up a note
handle_input:
	lda	joypad1_pressed
	and	#$0f		; Check d-pad only
	beq	@done
@check_up:
	and	#$08		; Up
	beq	@check_down
	jsr	play_note
@check_down:
	lda	joypad1_pressed
	and	#$04		; Down
	beq	@check_left
	jsr	silence_note
@check_left:
	lda	joypad1_pressed
	and	#$02		; Left
	beq	@check_right
	jsr	note_down
@check_right:
	lda	joypad1_pressed
	and	#$01		; Right
	beq	@done
	jsr	note_up
@done:
	rts

;;;
;;; play_note plays the note stored in the current_note
;;; 
play_note:
	lda	#$7f		; Duty 01, volume F
	sta	$4000
	lda	#$08		; Set negate flag so low notes aren't silenced
	sta	$4001

	lda	current_note
	;; Multiply by 2 because we are indexing into a word table
	asl	a
	tay
	lda	note_table, y	; Read the low byte of the period
	sta	$4002		; Write to SQ1_LO
	lda	note_table+1, y	; Read the high byte of the period
	sta	$4003		; Write to SQ1_HI
	rts

;;;
;;; silence_note silences the square channel
;;; 
silence_note:
	lda	#$30
	sta	$4000		; Silence Square 1 by setting the volume to 0
	rts

;;;
;;; note_down will move current_note down a half-step (eg, C#4 -> C4).  Lowest note
;;; will wrap to highest note.
;;; 
note_down:
	dec	current_note
	lda	current_note
	cmp	#$ff
	bne	@done
	lda	#Fs9		; Highest note. We wrapped from 0.
	sta	current_note
@done:
	jsr	get_note_and_octave
	rts

;;;
;;; note_up will move the current_note up a half-set (eg C#4 -> D4).  Highest note
;;; will wrap to lowest note.
;;; 
note_up:
	inc	current_note
	lda	current_note
	cmp	#Fs9+1		; Did we move past the highest note index in our table?
	bne	@done
	sta	current_note
@done:
	jsr	get_note_and_octave
	rts

;;;
;;; get_note_and_octave will take current_note and separate the note part
;;; (A, B, F#, etc.) from the octave (1, 2, 3, etc.) and store them separately.
get_note_and_octave:
	;; x will count octavles. The lowest C is ocatve 2, so we start out at 2
	ldx	#$02
	lda	current_note
	cmp	#$0c
	bcc	@store_note_value ; If we are in the lowest octave already, we are done
	sec			  ; else we need to find out what octave we are in.
@loop:
	sbc	#$0c		; Subtract an octave
	inx			; Count how many subtractions we've made
	cmp	#$0c		; When we ar down to the lowest octave, quit
	bcs	@loop
@store_note_value:
	sta	note_value	; Store the note value
	cmp	#$03
	bcs	@store_octave
	dex			; On the NES, A, A# and B start at octave 1, not 2.
@store_octave:
	stx	note_octave
	rts

;;;
;;; draw_note will draw the note value and octave on the screen.  This subroutine
;;; writes to the PPU registers, so it should only be run during vblank (ie, in NMI)
;;; 
draw_note:
	lda	$2002
	lda	#$21
	sta	$2006
	lda	#$4d
	sta	$2006		; $214D is a nice place in the middle of the screen

	lda	note_value	; Use note_value as an index into our pointer table
	;; multiply by 2 because we are indexing into a word table
	asl	a
	tay
	lda	text_pointers, y ; Setup pointer to the text data
	sta	ptr1
	lda	text_pointers+1, y
	sta	ptr1+1
	ldy	#$00
@loop:
	lda	(ptr1), y	; read a byte from the string
	;; If negative, we are finished (our strings are terminated by $FF, a
	;; negative number)
	bmi	@end
	sta	$2007		; Else draw on the screen
	iny
	jmp	@loop
@end:
	lda	note_octave	; The CHR #s for the numbers are $01-$09, so we can
				;  just write the value directly.
	sta	$2007
	rts

.segment "RODATA"

;;; This is a table of poitners. These pointers point to the beginning of text strings
text_pointers:
	.word	text_A, text_Asharp, text_B, text_C, text_Csharp, text_D
	.word	text_Dsharp, text_E, text_F, text_Fsharp, text_G, text_Gsharp

;;; CHR
;;;  $00 = blank
;;;  $0a = "#"
;;;  $10-$16 = "A" - "G"
;;;  $ff = string terminator
.if 1
text_A:		.byte	$00, $10, $ff
text_Asharp:	.byte	$10, $0a, $ff
text_B:		.byte	$00, $11, $ff
text_C:		.byte	$00, $12, $ff
text_Csharp:	.byte	$12, $0a, $ff
text_D:		.byte	$00, $13, $ff
text_Dsharp:	.byte	$13, $0a, $ff
text_E:		.byte 	$00, $14, $ff
text_F:		.byte	$00, $15, $ff
text_Fsharp:	.byte	$15, $0a, $ff
text_G:		.byte	$00, $16, $ff
text_Gsharp:	.byte	$16, $0a, $ff
.else
	;; Alternate implementation using CA65's character maps
	.charmap	' ', $00
	.charmap	'#', $0a
	.charmap	'A', $10
	.charmap	'B', $11
	.charmap	'C', $12
	.charmap	'D', $13
	.charmap	'E', $14
	.charmap	'F', $15
	.charmap	'G', $16
	.charmap	'.', $ff
	
text_A:		.byte	" A."
text_Asharp:	.byte	"A#."
text_B:		.byte	" B."
text_C:		.byte	" C."
text_Csharp:	.byte	"C#."
text_D:		.byte	" D."
text_Dsharp:	.byte	"D#."
text_E:		.byte 	" E."
text_F:		.byte	" F."
text_Fsharp:	.byte	"F#."
text_G:		.byte	" G."
text_Gsharp:	.byte	"G#."
.endif
	
;;;;;;;;;;;;;;  
  
.segment "VECTORS"

	.word	0, 0, 0		; Unused, but needed to advance PC to $fffa.
	;; When an NMI happens (once per frame if enabled) the label nmi:
	.word	nmi
	;; When the processor first turns on or is reset, it will jump to the
	;; label reset:
	.word	reset
	;; External interrupt IRQ is not used in this tutorial 
	.word	0
  
;;;;;;;;;;;;;;  
  
.segment "CHARS"

	.incbin	"periods.chr"