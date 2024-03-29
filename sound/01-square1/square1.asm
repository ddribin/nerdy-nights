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

	lda	#%00000001
	sta	$4015		; enable Square 1

	;; Square 1: Duty 00, Length Counter disabled,
	;; Saw Envelopes disabled, Volume 8
	lda	#%10111111
	sta	$4000
    
	lda	#$C9    	; $0C9 is a C# in NTSC mode
	sta	$4002		; low 8 bits of period
	lda 	#$00
	sta 	$4003   	; high 3 bits of period

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
