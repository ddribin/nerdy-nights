ifdef CONFIG_FILE
LDCONFIG_FLAGS = --config $(CONFIG_FILE)
CACONFIG_FLAGS = -t nes
else
LDCONFIG_FLAGS = -t nes
CACONFIG_FLAGS = -t nes
endif


AS	= ca65
ASFLAGS	= -g $(CACONFIG_FLAGS)
LD	= ld65
LDFLAGS	= -m $(PROGRAM).map -Ln $(PROGRAM).lbl --dbgfile $(PROGRAM).dbg $(LDCONFIG_FLAGS)
OPEN ?= open

OBJECTS = $(SOURCES:.asm=.o)

all: $(PROGRAM).nes

$(PROGRAM).nes: $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

open: $(PROGRAM).nes
	$(OPEN) $(PROGRAM).nes

clean:
	$(RM) *.o *.lst $(PROGRAM).nes $(PROGRAM).map $(PROGRAM).lbl $(PROGRAM).dbg

%.o: %.asm
	$(AS) $(ASFLAGS) -l $(*).lst -o $@ $<


.PHONY: all clean open
