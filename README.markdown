-*- markdown -*-

The Nerdy Nights ca65 Remix
===========================

The [Nerdy Nights][nn] is a series of tutorials on how to program for the NES on the Nintendo Age forums.  The walk the user through basic graphics and sound applications, with nice descriptions and sample projects.

The tutorials where originally written in [NESASM][nesasm] and tested on [FCEU XD SP][fceuxdsp].  However, these work best primarily on Windows, and I use Mac OS X.  This is the Nerdy Nights NES tutorials, ported to ca65, the macro assembler included with the [cc65 compiler][cc65] and tested on [Nestopia][nestopia].  I also prefer that ca65 uses a linker, and code can be separated out into multiple source files.

Differences from NESASM Source
==============================

Most of the differences between the NESASM code and ca65 are straight syntax differences.  For example, ca65 doesn't support `.dw` and uses `.word` instead.  ca65 also does not support the NES extensions, like the iNES header macros, like `.inesprg`.  We have to specify the exact bytes used for the iNES header.  I also prefer coding in all lower case.

The biggest difference is that ca65 uses a linker to place code at specific addresses, instead of `.org` statements.  The linker uses segments to separate code that belongs at different addresses, and defines this mapping in a configuration file.  The configuration file used when running `ld65` with the `-t nes`, it uses the `nes.cfg` linker configuration file.

The linker configuration file, included at the end of this document, essentially defines the iNES mapper and parameters we need to set in the header.  For example, the `ROM0` and `ROM2` memory regions require that we use mapper 0 (NROM) with 32KB of PRG-ROM and 8KB of CHR-ROM.  Thus, our iNES header is defined as:

<pre>
.segment "HEADER"
        
        .byte   "NES", $1A      ; iNES header identifier
        .byte   2               ; 2x 16KB PRG code
        .byte   1               ; 1x  8KB CHR data
        .byte   $01, $00        ; mapper 0, vertical mirroring
</pre>

The nes.cfg File
================

Here's the `nes.cfg` as shipping with cc65 version 2.13.0.

<pre>
MEMORY {

    ZP:  start = $02, size = $1A, type = rw, define = yes;

    # INES Cartridge Header
    HEADER: start = $0, size = $10, file = %O ,fill = yes;

    # 2 16K ROM Banks
    # - startup
    # - code
    # - rodata
    # - data (load)
    ROM0: start = $8000, size = $7ff4, file = %O ,fill = yes, define = yes;

    # Hardware Vectors at End of 2nd 8K ROM
    ROMV: start = $fff6, size = $c, file = %O, fill = yes;

    # 1 8k CHR Bank
    ROM2: start = $0000, size = $2000, file = %O, fill = yes;

    # standard 2k SRAM (-zeropage)
    # $0100-$0200 cpu stack
    # $0200-$0500 3 pages for ppu memory write buffer
    # $0500-$0800 3 pages for cc65 parameter stack
    SRAM: start = $0500, size = $0300, define = yes;

    # additional 8K SRAM Bank
    # - data (run)
    # - bss
    # - heap
    RAM: start = $6000, size = $2000, define = yes;

}

SEGMENTS {
    HEADER:   load = HEADER,          type = ro;
    STARTUP:  load = ROM0,            type = ro,  define = yes;
    LOWCODE:  load = ROM0,            type = ro,                optional = yes;
    INIT:     load = ROM0,            type = ro,  define = yes, optional = yes;
    CODE:     load = ROM0,            type = ro,  define = yes;
    RODATA:   load = ROM0,            type = ro,  define = yes;
    DATA:     load = ROM0, run = RAM, type = rw,  define = yes;
    VECTORS:  load = ROMV,            type = rw;
    CHARS:    load = ROM2,            type = rw;
    BSS:      load = RAM,             type = bss, define = yes;
    HEAP:     load = RAM,             type = bss, optional = yes;
    ZEROPAGE: load = ZP,              type = zp;
}

FEATURES {
    CONDES: segment = INIT,
	    type = constructor,
	    label = __CONSTRUCTOR_TABLE__,
	    count = __CONSTRUCTOR_COUNT__;
    CONDES: segment = RODATA,
	    type = destructor,
	    label = __DESTRUCTOR_TABLE__,
	    count = __DESTRUCTOR_COUNT__;
    CONDES: type = interruptor,
	    segment = RODATA,
	    label = __INTERRUPTOR_TABLE__,
	    count = __INTERRUPTOR_COUNT__;
}

SYMBOLS {
    __STACKSIZE__ = $0300;  	# 3 pages stack
}
</pre>

[nn]: http://www.nintendoage.com/faq/nerdy_nights_out.html
[nesasm]: http://www.nespowerpak.com/nesasm/NESASM3.zip
[fceuxdsp]: http://www.the-interweb.com/serendipity/exit.php?url_id=627&entry_id=90
[cc65]: http://www.cc65.org/
[nestopia]: http://www.bannister.org/software/nestopia.htm
