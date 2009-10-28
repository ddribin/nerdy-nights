.segment "HEADER"
	
	.byte	"NES", $1A	; iNES header identifier
	.byte	2		; 2x 16KB PRG code
	.byte	1		; 1x  8KB CHR data
	.byte	$01, $00	; mapper 0, vertical mirroring

;;;;;;;;;;;;;;;

;;; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

.segment "CODE"

reset:

	sei			; disable IRQs
	cld			; disable decimal mode
	ldx	#$40
	stx	$4017		; disable APU frame IRQ
	ldx	#$ff		; set up stack
	txs			;  .
	inx			; now X = 0
	stx	$2000		; disable NMI
	stx	$2001		; disable rendering
	stx	$4010		; disable DMC IRQs

	;; first wait for vblank to make sure PPU is ready
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
	sta	$0200, x	; move all sprites off screen
	inx
	bne	clear_memory

	;; second wait for vblank, PPU is ready after this
vblankwait2:
	bit	$2002
	bpl	vblankwait2

clear_nametables:
	lda	$2002		; read PPU status to reset the high/low latch
	lda	#$20		; clear PPU memory starting from $2000
	sta	$2006
	lda	#$00
	sta	$2006
	ldx	#$08		; prepare to fill 8 pages ($800 bytes)
	ldy	#$00		;  x/y is 16-bit counter, high byte in x
	lda	#$27		; fill with tile $27 (a solid box)
@loop:
	sta	$2007
	dey
	bne	@loop
	dex
	bne	@loop
	
load_palettes:
	lda	$2002		; read PPU status to reset the high/low latch
	lda	#$3f		; write the high byte of $3f00
	sta	$2006		;  .
	lda	#$00		; write the low byte of $3f00
	sta	$2006		;  .
	ldx	#$00
@loop:
	lda	palette, x	; load palette byte
	sta	$2007		; write to PPU
	inx			; set index to next byte
	cpx	#$20
	bne	@loop		; if x = $20, 32 bytes copied, all done
	
vblankwait3:	
	bit	$2002
	bpl	vblankwait3
	
load_sprites:
	ldx	#$00		; start at 0
@loop:
	lda	sprites, x	; load data from address (sprites + x)
	sta	$0200, x	; store into RAM address ($0200 + x)
	inx			; x = x + 1
	cpx	#$10		; copmare x to hex $10, decimal 16
	bne	@loop

load_background:
	lda	$2002		; read PPU status to reset the high/low latch
	lda	#$20
	sta	$2006		; write the high byte of $2000 address
	lda	#$00
	sta	$2006		; write the low byte of $2000 address
	ldx	#$00		; start out at 0
@loop:
	lda	background, x	; load data from address (background + x)
	sta	$2007		; write to PPU
	inx			; x = x + 1
	cpx	#$80		; compare x to hex $80, decimal 128
	bne	@loop

load_attribute:
	lda	$2002		; read PPU status to reset the high/low latch
	lda	#$23
	sta	$2006		; write the high byte of $23c0 address
	lda	#$c0
	sta	$2006		; write the low byte of $23c0 address
	ldx	#$00		; start out at 0
@loop:
	lda	attribute, x	; load data from address (attribute + x)
	sta	$2007		; write to PPU
	inx			; x = x + 1
	cpx	#$08		; compare x to hex $08, decimal 8
	bne	@loop
	
	lda	#%10010000	; enable NMI, sprites from pattern table 0,
	sta	$2000		;  background from pattern table 1
	lda	#%00011110	; enable sprites, enable background,
	sta	$2001		;  no clipping on left

forever:
	jmp	forever

;;; 
;;; NMI handler
;;; 

nmi:
	lda	#$00		; set the low byte (00) of the RAM address
	sta	$2003
	lda	#$02		; set the high byte (02) of the RAM address 
	sta	$4014		; start the transfer

latch_controller:
	lda	#$01
	sta	$4016
	lda	#$00
	sta	$4016		; tell both controllers to latch buttons

read_a:
	lda	$4016		; player 1 - A
	and	#%00000001	; only look at bit 0
	beq	@done		; branch to @done if button is NOT pressed (0)
	;; add instructions here to do something when button IS pressed
	lda	$0203		; load sprite 0 X-position
	clc			; make sure the carry flag is clear
	adc	#$01		; a = a + 1
	sta	$0203		; save sprite 0 X-position
	sta	$020b		; save sprite 2 X-position

	lda	$0207		; load sprite 1 X-position
	clc			; add one to it
	adc	#$01		;  .
	sta	$0207		; save sprite 1 X-position
	sta	$020f		; save sprite 3 X-position
@done:

read_b:	
	lda	$4016		; player 1 - B
	and	#%00000001	; only look at bit 0
	beq	@done		; branch to @done if button is NOT pressed (0)
	;; add instructions here to do something when button IS pressed
	lda	$0203		; load sprite 0 X-position
	sec			; make sure the carry flag is set
	sbc	#$01		; a = a - 1
	sta	$0203		; save sprite 0 X-position
	sta	$020b

	lda	$0207		; load sprite 1 X-position
	sec			; add one to it
	sbc	#$01		;  .
	sta	$0207		; save sprite 1 X-position
	sta	$020f		; save sprite 3 X-position
@done:

	;; This is the PPU clean up section, so rendering the next frame starts
	lda	#%10010000	; enable NMI, sprites from pattern table 0,
	sta	$2000		;  background from pattern table 1
	lda	#%00011110	; enable sprites, enable background,
	sta	$2001		;  no clipping on left

	lda	#$00		; tell the PPU there is no background
	sta	$2005		;  scrolling
	sta	$2005		;  .
	
	rti			; return from interrupt

palette:
	;; Background palette
	.byte 	$22,$29,$1A,$0F
	.byte	$22,$36,$17,$0F
	.byte	$22,$30,$21,$0F
	.byte	$22,$27,$17,$0F
	;; Sprite palette
	.byte	$22,$16,$27,$18
	.byte	$22,$1C,$15,$14
 	.byte	$22,$02,$38,$3C
	.byte	$22,$1C,$15,$14
@end:

sprites:
	;;      vert tile attr horiz
	.byte	$80, $32, $00, $80 ; sprite 0
	.byte	$80, $33, $00, $88 ; sprite 1
	.byte	$88, $34, $00, $80 ; sprite 2
	.byte	$88, $35, $00, $88 ; sprite 3

background:
	;; row 1, all sky
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

	;; row 2, all sky
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

	;; row 3, some brick tops
.byte $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24

	;; row 4, some brick bottoms
.byte $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24

attribute:
	.byte	%00000000, %00010000, %01010000, %00010000
	.byte	%00000000, %00000000, %00000000, %00110000

;;;;;;;;;;;;;;  
  
.segment "VECTORS"

	.word	0, 0, 0		; Unused, but needed to advance PC to $fffa.
	;; When an NMI happens (once per frame if enabled) the label nmi:
	.word	nmi
	;; When the processor first turns on or is reset, it will jump
	;; to the label reset:
	.word	reset
	;; External interrupt IRQ is not used in this tutorial 
	.word	0
  
;;;;;;;;;;;;;;  
  
.segment "CHARS"

	.incbin	"mario.chr"	; includes 8KB graphics from SMB1
