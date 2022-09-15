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

	lda 	#$80
	sta 	$2000		; enable NMIs


enable_sound_channels:
	lda	#%00000111
	sta	$4015		; enable Square 1, Square 2 and Triangle
    
	;; Square 1: Duty 00, Length Counter disabled,
	;; Saw Envelopes disabled, Volume 8
	lda	#%00111000
	sta 	$4000
	lda 	#$C9		; $0C9 is a C# in NTSC mode
	sta 	$4002		; low 8 bits of period
	lda 	#$00
	sta	$4003   	; high 3 bits of period
    
	;; Square 2
	lda	#%01110110	; Duty 01, Volume 6
	sta	$4004
	lda	#$A9        	; $0A9 is an E in NTSC mode
	sta	$4006
	lda	#$00
	sta	$4007

	;; Triangle
	lda	#$81    	; disable internal counters, channel on
	sta	$4008
	lda	#$42    	; $042 is a G# in NTSC mode
	sta	$400A
	lda	#$00
	sta	$400B
	
forever:
	jmp	forever

nmi:
	rti
 
;;;;;;;;;;;;;;  
  
.segment "VECTORS"

	;; When an NMI happens (once per frame if enabled) the label nmi:
	.word	nmi
	;; When the processor first turns on or is reset, it will jump to the
	;; label reset:
	.word	reset
	;; External interrupt IRQ is not used in this tutorial 
	.word	0
  
;;;;;;;;;;;;;;  
  
.segment "CHARS"

;;; No CHR-ROM needed for this app
