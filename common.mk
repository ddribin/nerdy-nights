ifdef CONFIG_FILE
CONFIG_FLAGS = --config $(CONFIG_FILE)
else
CONFIG_FLAGS = -t nes
endif


AS	= ca65
ASFLAGS	= -l
LD	= ld65
LDFLAGS	= -m $(PROGRAM).map $(CONFIG_FLAGS)
CL	= cl65
CLFLAGS	= -l -t nes


OBJECTS = $(SOURCES:.asm=.o)

all: $(PROGRAM).nes

$(PROGRAM).nes:
	$(CL) $(CLFLAGS) $(LDFLAGS) -o $@ $(SOURCES)

open: $(PROGRAM).nes
	open $(PROGRAM).nes

clean:
	$(RM) *.o $(PROGRAM).nes $(PROGRAM).map $(SOURCES:.asm=.lst)

.PHONY: all clean open $(PROGRAM).nes
