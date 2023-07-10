; ----------------------------------------------------------------------------
;	xdisk 2.0
;	copyright (c) 2000 cisc.
; ----------------------------------------------------------------------------
;	�߂���
; ----------------------------------------------------------------------------
;	$Id: main.asm,v 1.4 2000/02/01 13:08:56 cisc Exp $

E_TYPE		equ	0ffh
E_DRIVEOPEN	equ	0feh
E_FDC		equ	0fdh
E_SEEK		equ	0fch
E_SEQUENCE	equ	0fbh
E_WRITE		equ	0fah
E_WRITEPROTECT	equ	0f9h
E_ARG		equ	0f8h

; ----------------------------------------------------------------------------

Main:
		ld	(MainStack),sp
		in	a,(6fh)
		ld	(Main_6fh),a
		call	SelectN88ROM
Main0:
		ld	a,0
Main_6fh	equ	$-1
		call	RsOpen
Main0a:
		ld	sp,0
MainStack	equ	$-2
	
 if DEBUG
	call	putmsg
	db	13,10,'$6>$7 ',0
 endif
		ld	hl,Main0a
		push	hl
Main_1:
		call	RsRecvByte
		cp	'!'
		jr	z,Main_2
		cp	'*'
		jr	z,Main_of
		cp	'+'
		jr	nz,Main_1
		call	putmsg
		db	'$2SIO Error$7',13,10,0
		ret
Main_of:
		call	putmsg
		db	'$2Buffer overflow$7',13,10,0
		ret
Main_brk:
		call	putmsg
		db	'$2Broken Packet$7',13,10,0
		ret
		
		; �L���ȃR�}���h�p�P�b�g����̂���
Main_2:
		ld	hl,CmdPacket
		call	PtRecv
		jr	c,Main_brk
		
		ld	(PtIndex),ix
		
 if DEBUG
	ld	a,(CmdPacket)
	push	af
	call	putmsg
	db	'[$b]',0
 endif
		
		ld	a,(CmdPacket)
		cp	MAXCMDINDEX + 1
		push	af
		sbc	a,a
		
		; ACK ��Ԃ�
		; �R�}���h�����߂ł��Ȃ���� 0 ��Ԃ�
		
		ld	hl,PacketBuffer
		ld	(hl),a
		ld	bc,1
		ld	a,'%'
		call	PtSend
		
		pop	af
		jr	nc,Main_unk
		
		; �R�}���h�����s
		
		add	a,a
		add	a,low(CmdTable)
		ld	l,a
		ld	a,high(CmdTable)
		adc	a,0
		ld	h,a
		
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		jp	(hl)
		
Main_unk:
		push	af
		call	putmsg
		db	"$2Unknown command $7($6$b$7)",13,10,0
		ret

MAXCMDINDEX	equ	10
		
CmdTable	dw	CmdCompleted,		CmdSendSystemInfo
		dw	CmdSetDrive,		CmdReadTrack
		dw	CmdSendTrack,		CmdSendAndReadTrack
		dw	CmdSendLastPacket,	CmdSendROM
		dw	CmdQuit,		CmdWriteTrack

; ----------------------------------------------------------------------------
;	�I��
;
CmdCompleted:
		call	putmsg
		db	13,10,'$7Completed.',13,10,0
		ret
		
; ----------------------------------------------------------------------------
;	xdisk88 ���I��
;
CmdQuit:
		pop	af
		ret
		
; ----------------------------------------------------------------------------
;	�Ō�ɓ]�������f�[�^�p�P�b�g���đ�
;
CmdSendLastPacket:
		ld	a,(CmdPacket+1)
		or	a
		push	af
		call	nz,RsEnterBurstMode
		call	SelectRAM
		ld	a,'$'
		ld	hl,(PtLastPtr)
		ld	bc,(PtLastLen)
		call	PtSend
		call	SelectN88ROM
		pop	af
		call	nz,RsExitBurstMode
		ret
		
		
