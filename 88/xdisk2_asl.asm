	relaxed on
	cpu Z80

	org $b400

not	function x,(~x)
high	function x,((x >> 8) & 0x00FF)
low	function x,(x & 0x00FF)
HIGH	function x,high(x)
LOW	function x,low(x)

ds	macro n
	db n dup 0
	endm

	include "xdisk2.asm"
