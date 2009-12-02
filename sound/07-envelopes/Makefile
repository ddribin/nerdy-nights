PROGRAM	= envelopes
SOURCES	= envelopes.asm note_table.asm sound_engine.asm volume_envelopes.asm \
	songs.asm song0.asm song1.asm song2.asm song3.asm song4.asm song5.asm

CONFIG_FILE = nes.cfg

include ../../common.mk

envelopes.o: sound_engine.h
sound_engine.o: note_table.h sound_defs.h sound_engine.h
song0.o song1.o song2.o song3.o song4.o song5.o: note_table.h sound_defs.h
