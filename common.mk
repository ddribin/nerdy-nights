ifdef CONFIG_FILE
LDCONFIG_FLAGS = --config $(CONFIG_FILE)
CACONFIG_FLAGS = -t nes
else
LDCONFIG_FLAGS = -t nes
CACONFIG_FLAGS = -t nes
endif


AS	= ca65
ASFLAGS	= -l -t nes
LD	= ld65
LDFLAGS	= -m $(PROGRAM).map -Ln $(PROGRAM).lbl --dbgfile $(PROGRAM).dbg $(LDCONFIG_FLAGS)
CA = ca65
CAFLAGS	= -l $(PROGRAM).lst -g $(CACONFIG_FLAGS)

OBJECTS = $(SOURCES:.asm=.o)

all: $(PROGRAM).nes

$(PROGRAM).nes: $(OBJECTS)
#	$(CA) $(CAFLAGS) $(SOURCES)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

open: $(PROGRAM).nes
	open $(PROGRAM).nes

clean:
	$(RM) *.o *.lst $(PROGRAM).nes $(PROGRAM).map $(PROGRAM).lbl $(PROGRAM).dbg

%.o: %.asm
	$(CA) $(CAFLAGS) $<


.PHONY: all clean open $(PROGRAM).nes
