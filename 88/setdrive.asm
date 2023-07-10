; ----------------------------------------------------------------------------
;	xdisk 2.0
;	copyright (c) 2000 cisc.
; ----------------------------------------------------------------------------
;	$Id: setdrive.asm,v 1.2 2000/02/01 13:08:56 cisc Exp $

; ----------------------------------------------------------------------------
;	�A�N�Z�X����f�B�X�N�h���C�u�Ƃ��̎�ނ�ݒ�
;	arg:	[02] DRIVE TYPE
;		DRIVE = 00 or 01
;		TYPE (00:2D 01:2DD 03:2HD FF:AUTO DETECT, BIT7=WRITE PROTECT)
;	res:	TYPE (FF:UNKNOWN, FE=NO DISK)
;	2. �f�B�X�N�̃^�C�v�`�F�b�N
;
CmdSetDrive:
		; �f�B�X�N�̑}���`�F�b�N
		ld	a,(CmdPacket+1)
		ld	d,a
		cp	2
		ld	a,E_ARG
		jp	nc,CmdSetDrive_e
		call	DiCheckMedia
		jr	c,CmdSetDrive_1
		
		; �f�B�X�N�������Ă��Ȃ��I
		ld	h,0
		ld	l,d
		inc	hl
		push	hl
		call	putmsg
		db	"$5Insert target disk on drive $6$n$7.",13,10,10,0
		ld	a,E_DRIVEOPEN
		jp	CmdSetDrive_e
		
CmdSetDrive_1:
		ld	c,a
		ld	a,(CmdPacket+2)
		cp	0ffh
		jp	z,CmdSetDrive_4
		bit	7,a
		jr	z,CmdSetDrive_4
		bit	2,c
		jr	z,CmdSetDrive_4
		
		ld	h,0
		ld	l,d
		inc	hl
		push	hl
		call	putmsg
		db	"$5Disk in drive $6$n$7 is $2write protected$7!.",13,10,10,0
		ld	a,E_WRITEPROTECT
		jp	CmdSetDrive_e
		
CmdSetDrive_4:
		; �f�B�X�N�̎�ނ́H
		ld	e,a
		inc	a
		jr	z,CmdSetDrive_2
		res	7,e
		call	DiSetDrive
		jr	CmdSetDrive_3
CmdSetDrive_2:
		call	DiIdentifyType
		ld	a,E_TYPE
CmdSetDrive_3:
		jr	c,CmdSetDrive_e
		
		call	DiGetTypeStr
		push	hl
		ld	a,(DiDrive)
		inc	a
		ld	h,0
		ld	l,a
		push	hl
		call	putmsg
		db	13,10,"$5Disk in drive $7$n$5 is $6$s$5.",13,10,0
		
		ld	a,(DiType)
CmdSetDrive_e:
		jp	PtSendByteResult
		
		
