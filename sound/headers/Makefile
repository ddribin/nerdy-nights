PROGRAM	= headers
SOURCES	= headers.asm note_table.asm sound_engine.asm sound_data.asm song0.asm \
	song1.asm
CONFIG_FILE = nes.cfg

include ../../common.mk

skeleton.o: sound_engine.h
sound_engine.o: note_table.h sound_data.h sound_defs.h
song0.o song1.o: note_table.h sound_defs.h
