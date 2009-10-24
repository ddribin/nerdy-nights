PROGRAM	= background
SOURCES	= background.asm


AS	= ca65
ASFLAGS	= -l
LD	= ld65
LDFLAGS	= -t nes -m $(PROGRAM).map

all: $(PROGRAM).nes

%.o: %.asm
	$(AS) $(ASFLAGS) $<

$(PROGRAM).nes: $(SOURCES:.asm=.o)
	$(LD) $(LDFLAGS) $^ -o $@

clean:
	$(RM) *.o $(PROGRAM).nes $(PROGRAM).map

.PHONY: all clean