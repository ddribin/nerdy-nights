PROGRAM	= skeleton
SOURCES	= skeleton.asm note_table.asm sound_engine.asm sound_data.asm

include ../../common.mk

skeleton.o: sound_engine.h
sound_engine.o: note_table.h sound_data.h
sound_data.o: note_table.h
