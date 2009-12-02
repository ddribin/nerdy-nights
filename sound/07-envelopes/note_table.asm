;;; NTSC Period Lookup Table.  Thanks Celius!
;;; http://www.freewebs.com/the_bott/NotesTableNTSC.txt

.export	note_table
.export note_length_table
	
note_table:
.word                                                                       $07F1, $0780
.word $06AD, $064D, $05F3, $059D, $054D, $0500, $04B8, $0475, $0435, $03F8, $03BF, $0389
.word $0356, $0326, $02F9, $02CE, $02A6, $027F, $025C, $023A, $021A, $01FB, $01DF, $01C4 ; C3-B3 ($0F-$1A)
.word $01AB, $0193, $017C, $0167, $0151, $013F, $012D, $011C, $010C, $00FD, $00EF, $00E2 ; C4-B4 ($1B-$26)
.word $00D2, $00C9, $00BD, $00B3, $00A9, $009F, $0096, $008E, $0086, $007E, $0077, $0070 ; C5-B5 ($27-$32)
.word $006A, $0064, $005E, $0059, $0054, $004F, $004B, $0046, $0042, $003F, $003B, $0038 ; C6-B6 ($33-$3E)
.word $0034, $0031, $002F, $002C, $0029, $0027, $0025, $0023, $0021, $001F, $001D, $001B ; C7-B7 ($3F-$4A)
.word $001A, $0018, $0017, $0015, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D ; C8-B8 ($4B-$56)
.word $000C, $000C, $000B, $000A, $000A, $0009, $0008              

.word $0000			; Rest

note_length_table:
	.byte	$01		; 32nd note
	.byte	$02		; 16th note
	.byte	$04		; 8th note
	.byte	$08		; Quarter note
	.byte	$10		; Half note
	.byte	$20		; Whole note

	;; Dotted notes
	.byte	$03		; Dotted 16th note
	.byte	$06		; Dotted 8th note
	.byte	$0c		; Dotted quarter note
	.byte	$18		; Dotted half note
	.byte	$30		; Dotted whole note?

	;; Other
	;; Modified quarter to fit after d_sixtength triplets
	.byte	$07