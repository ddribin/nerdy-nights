The Nerdy Nights ca65 Remix
===========================

The [Nerdy Nights][nn] is a series of tutorials on how to program for the NES, originally posted to the Nintendo Age forums.  They walk the user through basic graphics and sound applications, with nice descriptions and sample projects.

The tutorials where originally written in [NESASM][nesasm] and tested on [FCEU XD SP][fceuxdsp].  However, these work best primarily on Windows, and I use Mac OS X.  This is the Nerdy Nights NES tutorials, ported to ca65, the macro assembler included with the [cc65 compiler][cc65] and tested on [Nestopia][nestopia].  I also prefer that ca65 uses a linker, since it's more flexible than a single source file.

Differences from NESASM Source
==============================

Most of the differences between the NESASM code and ca65 are straight syntax differences.  For example, ca65 doesn't support `.dw` and uses `.word` instead.  ca65 also does not support the NES extensions, like the iNES header macros, like `.inesprg`.  We have to specify the exact bytes used for the iNES header.  I also prefer coding in all lower case.

The biggest difference is that ca65 uses a linker to place code at specific addresses, instead of `.org` statements.  The linker uses segments to separate code that belongs at different addresses, and defines this mapping in a configuration file.  The configuration file used when running `ld65` with the `-t nes`, it uses the `nes.cfg` linker configuration file.  In order to keep things simple, all apps use the default NES linker configuration file.

The NES linker configuration file, included at the end of this document, essentially defines the iNES mapper and parameters we need to set in the header.  For example, the `ROM0` and `ROM2` memory regions require that we use mapper 0 (NROM) with 32KB of PRG-ROM and 8KB of CHR-ROM.  Thus, our iNES header is defined as:

<pre>
.segment "HEADER"
        
        .byte   "NES", $1A      ; iNES header identifier
        .byte   2               ; 2x 16KB PRG code
        .byte   1               ; 1x  8KB CHR data
        .byte   $01, $00        ; mapper 0, vertical mirroring
</pre>

All apps can be built using the default target of the included `Makefile`.  In addition, they can be run in Nestopia using the `open` target.  Thus to compile, link, and run, you just type:

    %  make open

Most apps can be built easily using a single command, too.  For example, the background app can be built like:

    % cl65 -t nes -o background.nes background.asm

The nes.cfg File
================

Here's the `nes.cfg` as shipping with cc65 version 2.18. A customized version is used for some projects to add SRAM segments usable by the asembler.

```
SYMBOLS {
    __STACKSIZE__: type = weak, value = $0300; # 3 pages stack
}
MEMORY {
    ZP:     file = "", start = $0002, size = $001A, type = rw, define = yes;

    # INES Cartridge Header
    HEADER: file = %O, start = $0000, size = $0010, fill = yes;

    # 2 16K ROM Banks
    # - startup
    # - code
    # - rodata
    # - data (load)
    ROM0:   file = %O, start = $8000, size = $7FFA, fill = yes, define = yes;

    # Hardware Vectors at End of 2nd 8K ROM
    ROMV:   file = %O, start = $FFFA, size = $0006, fill = yes;

    # 1 8k CHR Bank
    ROM2:   file = %O, start = $0000, size = $2000, fill = yes;

    # standard 2k SRAM (-zeropage)
    # $0100-$0200 cpu stack
    # $0200-$0500 3 pages for ppu memory write buffer
    # $0500-$0800 3 pages for cc65 parameter stack
    SRAM:   file = "", start = $0500, size = __STACKSIZE__, define = yes;

    # additional 8K SRAM Bank
    # - data (run)
    # - bss
    # - heap
    RAM:    file = "", start = $6000, size = $2000, define = yes;
}
SEGMENTS {
    ZEROPAGE: load = ZP,              type = zp;
    HEADER:   load = HEADER,          type = ro;
    STARTUP:  load = ROM0,            type = ro,  define   = yes;
    LOWCODE:  load = ROM0,            type = ro,  optional = yes;
    ONCE:     load = ROM0,            type = ro,  optional = yes;
    CODE:     load = ROM0,            type = ro,  define   = yes;
    RODATA:   load = ROM0,            type = ro,  define   = yes;
    DATA:     load = ROM0, run = RAM, type = rw,  define   = yes;
    VECTORS:  load = ROMV,            type = rw;
    CHARS:    load = ROM2,            type = rw;
    BSS:      load = RAM,             type = bss, define   = yes;
}
FEATURES {
    CONDES: type    = constructor,
            label   = __CONSTRUCTOR_TABLE__,
            count   = __CONSTRUCTOR_COUNT__,
            segment = ONCE;
    CONDES: type    = destructor,
            label   = __DESTRUCTOR_TABLE__,
            count   = __DESTRUCTOR_COUNT__,
            segment = RODATA;
    CONDES: type    = interruptor,
            label   = __INTERRUPTOR_TABLE__,
            count   = __INTERRUPTOR_COUNT__,
            segment = RODATA,
            import  = __CALLIRQ__;
}
```

[nn]: https://nerdy-nights.nes.science
[nesasm]: http://nespowerpak.com/nesasm/
[fceuxdsp]: http://www.the-interweb.com/serendipity/index.php?/archives/90-Release-of-FCEUXD-SP-1.07.html
[cc65]: https://cc65.github.io/
[nestopia]: http://www.bannister.org/software/nestopia.htm
