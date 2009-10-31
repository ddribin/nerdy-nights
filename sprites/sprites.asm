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
	stx	$4017		; dsiable APU frame IRQ
	ldx	#$ff		; Set up stack
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

load_palettes:
	lda	$2002		; read PPU status to reset the high/low latch
	lda	#$3f
	sta	$2006
	lda	#$00
	sta	$2006
	ldx	#$00
@loop:
	lda	palette, x	; load palette byte
	sta	$2007		; write to PPU
	inx			; set index to next byte
	cpx	#$20
	bne	@loop		; if x = $20, 32 bytes copied, all done

	lda	#$80
	sta	$0200		; put sprite 0 in center ($80) of screen vert
	sta	$0203		; put sprite 0 in center ($80) of screen horiz
	lda	#$00
	sta	$0201		; tile number = 0
	sta	$0202		; color = 0, no flipping

	lda	#%10000000	; enable NMI, sprites from Pattern Table 0
	sta	$2000

	lda	#%00010000	; enable sprites
	sta	$2001
	
forever:
	jmp	forever

nmi:
	lda	#$00		; set the low byte (00) of the RAM address
	sta	$2003
	lda	#$02		; set the high byte (02) of the RAM address 
	sta	$4014		; start the transfer
	
	rti			; return from interrupt

palette:
	;; Background palette
	.byte	$0F,$31,$32,$33
	.byte	$0F,$35,$36,$37
	.byte	$0F,$39,$3A,$3B
	.byte	$0F,$3D,$3E,$0F
	;; Sprite palette
	.byte 	$0F,$1C,$15,$14
	.byte	$0F,$02,$38,$3C
	.byte	$0F,$1C,$15,$14
	.byte	$0F,$02,$38,$3C
 
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

	.incbin	"mario.chr"	; includes 8KB graphics from SMB1
