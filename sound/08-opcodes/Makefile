PROGRAM	= opcodes
SOURCES	= opcodes.asm note_table.asm sound_engine.asm volume_envelopes.asm \
	sound_opcodes.asm \
	songs.asm song0.asm song1.asm song2.asm song3.asm song4.asm \
	song5.asm song6.asm

CONFIG_FILE = nes.cfg

include ../../common.mk

sound_engine.h: note_table.h songs.h
opcodes.o: sound_engine.h
sound_engine.o: sound_engine.h
songs.o song0.o song1.o song2.o song3.o song4.o song5.o: sound_engine.h
