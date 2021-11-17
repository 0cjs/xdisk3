xdisk3
======

This is a port of cisc-san's excellent xdisk2, an RS232 PC-88xx disk and
ROM read/write tool, for unix systems (using file-type read and write
operations). 

All four modes are supported: b, r, w, s, both baud rates!


Building
--------

From the `pc` folder simply type `make`. Run the file to see usage().

Built and tested on a Pi400 + PC-8801mkII/FR.

(Branch "old" is simply a mirror of xdisk 2.0.7)


Client Usage
------------

If started without a diskette in the drive, the client will say `Couldn't
make comminucation with sub system!` This means that it could not find a
(formatted or unformatted) diskette in the drive. Inserting a diskette
should quickly produce an `Ok` message.


Bootstrapping Notes and Issues
------------------------------

### End of File

N-88 BASIC (at least in earlier versions) appears not to send an
end-of-file character (ASCII control-Z, decimal 26 or hex $1A) at the end
of a `SAVE "COM:"` command, nor does it end a `LOAD "COM:"` command on
receipt of that character.

It appears that for this reason the boostrap loader sends a line with just
a hyphen (`-`) after the BASIC program lines. This produces a `Direct
statement in file` error, which terminates the `LOAD` command, leaving in
memory the lines that have been loaded to that point. Without this the user
would have to observe the boostrap loader complete sending of the program
and then manually press `STOP` to return to the BASIC `Ok` prompt.

### Line Buffer Overflow

The bootstrap transfer of the BASIC program that contains the xdisk2 client
seems easily to overrun older machines, such as the PC-8801mkII SR with
N-88 BASIC Version 2.0, producing a `Line buffer overflow` error message.
This is probably due to BASIC being unable to finish parsing and tokenizing
a received line before either too many characters or the next line has been
received.

Unix users with [Minicom] installed can use its `ascii-xfer` program to
work around this issue by setting line and character delays with the `-l`
and `-c` options.  Delays are specified in milliseconds; a 100 ms delay
after each line (`-l 100`) or a 1 ms delay after each character (`-c 1`,
approxiimately equivalant to an 80 ms delay after each line) appears to
produce a reliable transfer. On Unix you can emulate the bootstrap transfer
code with a delays via:

    stty -F /dev/ttyUSB0 9600 cs8 -parenb  -crtscts -icrnl
    ascii-xfr -l 100 -v -s -n xdisk2.bas >/dev/ttyUSB0



<!-------------------------------------------------------------------->
[Minicom]: https://en.wikipedia.org/wiki/Minicom
