AS	= ca65
ASFLAGS	= -l
LD	= ld65
LDFLAGS	= -m $(PROGRAM).map

ifdef CONFIG_FILE
LDFLAGS	+= --config $(CONFIG_FILE)
else
LDFLAGS += -t nes
endif

all: $(PROGRAM).nes

%.o: %.asm
	$(AS) $(ASFLAGS) $<

$(PROGRAM).nes: $(SOURCES:.asm=.o)
	$(LD) $(LDFLAGS) $^ -o $@

open: $(PROGRAM).nes
	open $(PROGRAM).nes

clean:
	$(RM) *.o $(PROGRAM).nes $(PROGRAM).map $(SOURCES:.asm=.lst)

.PHONY: all clean open
