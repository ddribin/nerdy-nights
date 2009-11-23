	
	.include "sound_engine.h"

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
	
;;; main program sets this and waits for the NMI to clear it.  Ensures the main
;;; program is run only once per frame.  For more information, See Disch's document.
sleeping:		.res	1

needdraw:		.res	1 	; Drawing flag
dbuffer_index:		.res	1	; Current position in the drawing buffer
ptr1:			.res	2 	; An address pointer
sound_ptr:		.res	2
current_song:		.res 	1

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

	jsr	draw_background

	;; Enable sound channels
	jsr	sound_init

	lda	#$01
	sta	current_song

	lda	#$88
	sta	$2000		; Enable NMIs
	lda	#$18
	sta	$2001		; Turn PPU on
	
forever:
	inc	sleeping	; Go to sleep (wait for NMI).
	
	;; Wait for NMI to clear the sleeping flag and wake us up
@loop:
	lda	sleeping
	bne	@loop

	;; When NMI wakes us up, handle input and go back to sleep
	jsr	read_joypad
	jsr	handle_input
	jsr	prepare_dbuffer
	
	jmp	forever		; Go back to sleep

nmi:
	;; Push all registers on stack
	pha
	txa
	pha
	tya
	pha

	;; Do sprite DMA
	;; Update palettes if needed
	;; Draw stuff on the screen

	lda	needdraw
	beq	@drawing_done	; If drawing flag is clear, skip drawing
	lda	$2002		; Else, draw
	jsr	draw_dbuffer
	lda	#$00		; Finished drawing, so clear drawing flat
	sta	needdraw

@drawing_done:
	lda	#$00		; set scroll
	sta	$2005
	sta	$2005

	;; Run our sound engine after all drawing code is done.  This ensures
	;; our sound engine gets run once per frame.
	jsr	sound_play_frame

	lda	#$00
	sta	sleeping	; Wake up the main program

	;; Pull all registers from stack
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
	sta	joypad1_pressed	; Stores off-to-on transitions
	
	rts

;;;
;;; handle_input will perform actions based on input:
;;;  Up - Play current song
;;;  Down - Stop playing the song
;;;  Left - Cycle down a song
;;;  Right - Cycle up a song
;;; 
handle_input:
	lda	joypad1_pressed
	and	#$0f		; Check d-pad only
	beq	@done
@check_up:
	and	#$08		; Up
	beq	@check_down
	lda	current_song
	jsr	sound_load
@check_down:
	lda	joypad1_pressed
	and	#$04		; Down
	beq	@check_left
	lda	#$00
	jsr	sound_load
@check_left:
	lda	joypad1_pressed
	and	#$02		; Left
	beq	@check_right
	jsr	song_down
@check_right:
	lda	joypad1_pressed
	and	#$01		; Right
	beq	@done
	jsr	song_up
@done:
	rts

;;; song_down will move selection down a song.  Song 1 wraps around to last song.
song_down:
	dec	current_song
	lda	current_song
	bne	@done
	lda	#NUM_SONGS-1
	sta	current_song
@done:
	rts

;;; song_up will move selection up a song.  Last song will wrap to song 1
song_up:
	inc	current_song
	lda	current_song
	cmp	#NUM_SONGS
	bne	@done
	lda	#$01
	sta	current_song
@done:
	rts
	

;;;
;;; prepare_dbuffer fills the drawing buffer with the text strings we need.
;;;
prepare_dbuffer:
	;; First write either "PLAYING" or "NOT PLAYING" o the dbuffer
	
	;; If all streams disabled, write "NOT PLAYING"
	lda	stream_status
	ora	stream_status+1
	ora	stream_status+2
	ora	stream_status+3
	ora	stream_status+4
	ora	stream_status+5
	beq	@sound_not_playing
	;; If the sound disable flag is set, we want to write "NOT PLAYING" too
	lda	sound_disable_flag
	bne	@sound_not_playing
@sound_playing:
	;; Set ptr1 to point to beginning of text string
	lda	#.LOBYTE(text_playing)
	sta	ptr1
	lda	#.HIBYTE(text_playing)
	sta	ptr1+1
	jmp	@dbuffer1
@sound_not_playing:
	lda	#.LOBYTE(text_not_playing)
	sta	ptr1
	lda	#.HIBYTE(text_not_playing)
	sta	ptr1+1
@dbuffer1:
	;; Set target PPU address to $210B.  add_to_dbuffer expects the HI byte
	;; in A and the LO byte in Y.
	lda	#$21
	ldy	#$0b
	jsr	add_to_dbuffer

	jsr	song_num_to_dbuffer

	lda	#$01
	sta	needdraw	; Set drawing flag so the NMI knows to draw
	
	rts

;;;
;;; song_num_to_dbuffer tells the drawing buffer to write the currently
;;; selected song number on the screen.
song_num_to_dbuffer:
	ldx	dbuffer_index
	lda	#$01		; Write one byte
	sta	$0100, x
	lda	#$21
	sta	$0101, x
	lda	#$4a
	sta	$0102, x
	lda	current_song	; Which byte to write
	sta	$0103, x
	lda	#$00		; Terminate the dbuffer with 0
	sta	$0104, x
	txa			; Update our index
	clc
	adc	#$04
	sta	dbuffer_index
	rts
	
;;;
;;; add_to_dbuffer will convert a text string into a dbuffer string and add it
;;; to the drawing buffer
;;;   add_to_dbuffer expects:
;;; 	A - HI byte of the target PPU address
;;; 	B - LO byte of the target PPU address
;;; 	ptr1 - Pointer to the source text string
;;;   dbuffer string format
;;; 	byte 0: length of data (i.e. length of the text string)
;;; 	byte 1-2: target PPU address (HI byte first)
;;; 	byte 3-n: bytes to copy
;;;
;;; Note: dbuffer starts at $0100.  This is the stack page.  The stack counts
;;; backwards from $01FF, and this program is small enough that there will
;;; never be a conflicts.  But for larger prorams, watch out.
;;;
add_to_dbuffer:
	ldx	dbuffer_index
	sta	$0101, x	; Write target PPU address to dbuffer
	tya
	sta	$0102, x

	ldy	#$00
@loop:
	lda	(ptr1), y
	cmp	#$ff
	beq	@done
	sta	$0103, x	; Copy the text string to dbuffer
	iny
	inx
	bne	@loop
@done:
	ldx	dbuffer_index
	;; Y contains the string length. Store the string length at the beginning
	;; of the string header
	tya
	sta	$0100, x

	;; Update buffer index. new index = old index + 3-byte header + string length
	clc
	adc	dbuffer_index
	adc	#$03
	sta	dbuffer_index

	;; Stick a 0 on the end to terminate the dbuffer
	tax
	lda	#$00
	sta	$0100, x
	rts
	
;;;
;;; draw_dbuffer will write the contents of the drawing buffer to the PPU.
;;; dbuffer is made up of a series of drawing strings.  dbuffer is 0-terminated.
;;; See add_to_dbuffer for drawing string format.
;;; 
draw_dbuffer:
	ldy	#$00
@header_loop:
	lda	$0100, y
	beq	@done		; If 0, we are at the end of the dbuffer, so quit
	tax			; Else this is how many bytes we want to copy to the PPU
	iny
	lda	$0100, y	; Set the target PPU address
	sta	$2006
	iny
	lda	$0100, y
	sta	$2006
	iny
@copy_loop:
	lda	$0100, y	; Copy the contents of the drawing string to PPU
	sta	$2007
	iny
	dex
	bne	@copy_loop
	beq	@header_loop	; When we finish copying, see if there is another string
@done:
	;; Reset index and "empty" the dbuffer by sticking a zero in the first position
	ldy	#$00
	sty	dbuffer_index
	sty	$0100
	rts

;;; draw_background will draw some background strings on the screen.  This
;;; hard-coded routine is called only once during reset.
draw_background:
	lda	$2002
	lda	#$21
	sta	$2006
	lda	#$04
	sta	$2006

	;; $FF, a negative number, terminates our strings
	ldy	#$00
@loop1:
	lda	text_sound, y
	bmi	@sound_done
	sta	$2007
	iny
	bne	@loop1

@sound_done:
	lda	#$21
	sta	$2006
	lda	#$44
	sta	$2006
	
	ldy	#$00
@loop2:
	lda	text_song, y
	bmi	@done
	sta	$2007
	iny
	bne	@loop2
	
@done:
	rts

.segment "RODATA"

;;; These are our text strings.  They are all terminated by $FF.
	
text_song:
	;; "SONG:"
	.byte	$22, $1E, $1D, $16, $0D, $FF
text_sound:
	;; "SOUND:"
	.byte	$22, $1E, $24, $1D, $13, $0D, $FF
text_not_playing:
	;; "NOT "
	.byte 	$1D, $1E, $23, $00
text_playing:
	;; "PLAYING    "
	.byte 	$1F, $1B, $10, $28, $18, $1D, $16, $00, $00, $00, $00, $FF
	
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

	.incbin	"letters.chr"