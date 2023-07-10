; ----------------------------------------------------------------------------
;	xdisk 2.0
;	copyright (c) 2000 cisc.
; ----------------------------------------------------------------------------
;	uPD8251 �h���C�o
; ----------------------------------------------------------------------------
;	$Id: siodrv.asm,v 1.3 2000/01/05 13:34:33 cisc Exp $

;-----------------------------------------------------------------------------
;	�h���C�o�̊J�n�E��~
;	arg:	A	�{�[���[�g
;			0101	2400bps
;			0110	4800bps
;			0111	9600bps
;			1000	19200bps
;			1001	38400bps (2400/x1, ���M�̂�)
RsOpen:
		and	1111b
		push	af
		ld	a,(RsIsOpen)
		or	a
		call	nz,RsClose
		
		in	a,(6fh)
		ld	(RsOld6f),a
		ld	a,(PORT30)
		and	11001111b
		or	00100000b
		ld	(PORT30),a
		out	(30h),a
		
		pop	af
		
		di
		push	af
		call	RsInitUSART
		call	RsInitBuffer
		pop	af
		
		; ���荞�݃}�X�N�ݒ�
		; �������M�̎��͎�M���Ȃ�
		cp	9
		sbc	a,a
		and	00000100b
		ld	b,a
		
		ld	a,(PORTE6)
		and	not(00000100b)
		or	b
		ld	(PORTE6),a
		out	(0e6h),a
		ld	(RsIsOpen),a
		ei
		ret

RsClose:
		di
		ld	a,8
		call	RsInitUSART
		ld	a,(PORTE6)
		and	not(4)
		ld	(PORTE6),a
		out	(0e6h),a
		ei
		ld	a,(RsOld6f)
		out	(06fh),a
		xor	a
		ld	(RsIsOpen),a
		ret


RsEnterBurstMode:
		push	af
		push	bc
		push	de
		push	hl

RsEnterBurstMode_1:
		in	a,(21h)
		and	10000001b
		cp	10000001b
		jr	nz,RsEnterBurstMode_1
		
		ld	a,9
		call	RsOpen
		pop	hl
		pop	de
		pop	bc
		pop	af
		ret
		
RsExitBurstMode:
		push	af
		push	bc
		push	de
		push	hl
		xor	a
		call	RsSendByte
		call	RsSendByte
		
		ld	a,(RsOld6f)
		call	RsOpen
		pop	hl
		pop	de
		pop	bc
		pop	af
		ret

;-----------------------------------------------------------------------------
;	�P��������
;	arg:A	���镶��
;
RsSendByte:
		push	af
rssendbyte_1:
		in	a,(21h)
		and	10000001b
		cp	10000001b
		jr	nz,rssendbyte_1
		pop	af
		out	(20h),a
		ret

;-----------------------------------------------------------------------------
;	�o�b�t�@����ꕶ���擾
;	ret:	A	����
;		C	�ǂݍ���
;	uses:	AF	
;
RsRecvByte:
		ld	a,(RsFree)
		cp	255
		jr	nc,RsRecvByte
	;	ret	nc
		
		push	hl
		push	bc
		ld	hl,(RsBufR)
		ld	b,(hl)
		inc	l
		ld	(RsBufR),hl
	;
		ld	hl,RsError
		
		di
		res	0,(hl)
		inc	a
		ld	(RsFree),a
		
		; �t���[�}�������H
		cp	40h
		jr	c,RsRecvByte_1
		ld	a,(RsCommand)
		or	10b
		out	(21h),a
		ld	(RsCommand),a
RsRecvByte_1:
		ei
		ld	a,b
 		pop	bc
		pop	hl
		scf
		ret

;-----------------------------------------------------------------------------
;	�o�b�t�@�� 1 �����߂�
;
RsUngetc:
		push	hl
		push	af
		ld	hl,RsFree
		di
		ld	a,(hl)
		dec	a
		jr	c,RsUngetc_e
		ld	(hl),a
		pop	af
		ld	hl,(RsBufR)
		dec	l
		ld	(hl),a
		ld	(RsBufR),hl
		ei
		pop	hl
		or	a
		ret
RsUngetc_e:
		pop	af
		pop	hl
		ei
		scf
		ret

;-----------------------------------------------------------------------------
;	�o�b�t�@�̏�����
;	uses:	AHL
;
RsInitBuffer:
		ld	hl,RsBuffer
		ld	(RsBufW),hl
		ld	(RsBufR),hl
		ld	a,255
		ld	(RsFree),a
		ret

;-----------------------------------------------------------------------------
;	8251 ��������
;
;	mode:
;	01------  Stop bit 1
;	--00----  Parity   none
;	----11--  Data     8 bit
;	------10  Async    x16
;	------01  Async.   x1
;
RsInitUSART:
		push	af
		xor	a
		out	(21h),a
		pop	af
		
		ld	de,0011011101001110b	; RTS=1 RxE=1 DTR=1 TxEN=1
		cp	9
		jr	c,rsinitusart_1
		ld	de,0001001101001101b	; RTS=0 RxE=0 DTR=1 TxEN=1
		ld	a,0101b
rsinitusart_1:
		out	(6fh),a
		
		ld	a,(PORT30)		; 8251 �� sio �Ɏg���悤�ɐݒ�
		and	11001111b
		or	00100000b
		ld	(PORT30),a
		out	(30h),a
		
		xor	a			; reset
		out	(21h),a
		out	(21h),a
		out	(21h),a
		ld	a,40h
		out	(21h),a
		
		ld	a,e
		out	(21h),a
		ld	a,d
		out	(21h),a
		ld	(RsCommand),a
		ret

;-----------------------------------------------------------------------------;
;	RxRDY ���荞�ݏ���
;
RsIntr:
		push	af
		push	hl
		push	bc
		in	a,(20h)			; �P�����擾
		ld	c,a
		in	a,(21h)			; �X�e�[�^�X�`�F�b�N
		ld	b,a
		
		ld	a,(RsFree)		; �o�b�t�@�̋󂫂𒲂ׂ�
		cp	2
		jr	c,RsIntr_of		; �󂫂������Ȃ�I�[�o�[�t���[
		dec	a
		ld	(RsFree),a
		
		ld	hl,(RsBufW)		; �o�b�t�@�ɃZ�b�g
		ld	(hl),c
		inc	l			; �o�b�t�@�|�C���^�C���N�������g
		ld	(RsBufW),hl
		
		cp	64			; �t���[���䂷�邩�H
		jp	nc,RsIntr_1
		and	11111101b		; dtr �� off
		out	(21h),a
		ld	(RsCommand),a
RsIntr_1:
		ld	a,b			; �G���[�`�F�b�N
		and	00111000b
		jr	nz,RsIntr_er
RsIntr_3:
		ld	a,255
		out	(0e4h),a
		pop	bc
		pop	hl
		pop	af
		ei
		ret

RsIntr_of:	
		ld	c,'*'
		jp	RsIntr_cntl

RsIntr_er:
		ld	a,(RsCommand)
		or	00010000B
		out	(21h),a
		ld	c,'+'

	; command hdr
RsIntr_cntl:
		ld	hl,RsBuffer	
		ld	(RsBufR),hl
		ld	(HL),c
		inc	l
		ld	(RsBufW),hl
		ld	a,254
		ld	(RsFree),a
		jr	RsIntr_3
