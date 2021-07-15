; ----------------------------------------------------------------------------
;	xdisk 2.0
;	copyright (c) 2000 cisc.
; ----------------------------------------------------------------------------
;	�f�B�X�N���� (���C����)
; ----------------------------------------------------------------------------
;	$Id: disk.asm,v 1.4 2000/01/21 01:57:21 cisc Exp $


; ----------------------------------------------------------------------------
;	�g���b�N�̃f�[�^���󂯎��
;
DiRecvTrackData:
		call	DiGetTrackInfo
		ret	c
		ld	a,e
		or	a
		ret	z
		
	; ID ��
		push	bc
		add	a,a
		add	a,a
		ld	c,a
		ld	b,0
		rl	b
		ld	hl,IDTABLE
		ld	de,d_idtable
		call	DiRapidRecv
		pop	bc
	
	; DATA
		ld	hl,DATA
		ld	de,d_data
		srl	b
		rr	c
		srl	b
		rr	c
		call	DiRapidRecv
		ret
		

; ----------------------------------------------------------------------------
;	�f�B�X�N�V�X�e���� 2DD/2HD �Ή����H
;	out:	Z	���Ή�
;		NZ	�Ή�
;
DiSystemType:
		push	de
		push	de
		ld	de,1
		ld	b,d
		ld	c,e
		ld	h,d
		ld	l,d
		add	hl,sp
		call	DiRapidRecv
		pop	de
		pop	bc
		ld	hl,7eh
		sbc	hl,de
		ret

; ----------------------------------------------------------------------------
;	�h���C�u�Ƀf�B�X�N���Z�b�g����Ă��邩���m�F
;	in	D	drive
;	out	C	�����Ă���
;		NC	�����ĂȂ�
;
DiCheckMedia:
		ld	a,20
		call	DiSendCommand
		ld	a,d
		call	DiSendData
		call	DiRecvData
		rrca
		rrca
		rrca
		rrca
		ret
		

; ----------------------------------------------------------------------------
;	���삷��h���C�u�ԍ��Ǝ�ނ�ݒ�
;	in:	D	drive
;		E	type (0=2D, 1=2DD, 3=2HD)
;	out:	CY	�G���[
;		A	�G���[�^�C�v (E_TYPE, E_FDC)
;		
DiSetDrive:
		ld	hl,DsSetDrive
		call	DiExec
		ld	a,d
		ld	(DiDrive),a
		call	DiSendData
		ld	a,e
		ld	(DiType),a
		call	DiSendData
		call	DiRecvData
		push	af
		call	DiSetNTrack
		pop	af
		cp	1
		ccf
		ret

; ----------------------------------------------------------------------------
;	�h���C�u���w�肵�C���̃��f�B�A�̎�ނ𔻒肷��
;	in:	D	drive
;
DiIdentifyType:
		ld	hl,DsIdentifyType
		call	DiExec
		ld	a,d
		ld	(DiDrive),a
		call	DiSendData
		call	DiRecvData
		cp	4
		ccf
		ret	c
		ld	(DiType),a
		
DiSetNTrack:
		ld	a,(DiType)
		and	1
		ld	a,84
		jr	z,DiSetNTrack_1
		ld	a,164
DiSetNTrack_1:
		ld	(DiNumTracks),a
		ret

; ----------------------------------------------------------------------------
;	�g���b�N�ǂݍ���
;	in:	E 	track
;
DiReadTrack:
		ld	hl,DsReadTrack
		call	DiExec
		ld	a,e
		ld	(DiTrack),a
		jp	DiSendData

; ----------------------------------------------------------------------------
;	�g���b�N������
;	in:	E 	track
;		HL	�����݃V�[�N�G���X
;		BC	����
;
DiWriteTrack:
		push	de
		ld	de,d_data
		srl	b
		rr	c
		srl	b
		rr	c
		inc	bc
		call	DiRapidSend
		pop	de
		
		ld	hl,DsWrite
		call	DiExec
		ld	a,e
		jp	DiSendData

; ----------------------------------------------------------------------------
;	�ǂݍ��񂾃g���b�N�̏����擾
;	out:	CY	�G���[
;		A	�G���[��� (E_SEEK, ???)
;		E	�Z�N�^��
;		L	MFM �Z�N�^�����݂��Ȃ��Ȃ� 0
;		BC	�f�[�^���̃T�C�Y
;
DiGetTrackInfo:
		ld	hl,DsGetTrackInfo
		call	DiExec
		call	DiRecvData
		ld	d,a
		call	DiRecvData
		ld	e,a
		res	7,e
		and	80h
		ld	l,a
		ld	(DiMFM),a
		call	DiRecvData
		ld	b,a
		call	DiRecvData
		ld	c,a
		ld	(DiDataLength),bc
		ld	a,e
		ld	(DiSectors),a
		ld	a,d
		cp	1
		ccf
		ret
		
; ----------------------------------------------------------------------------
;	SUB ���ɃR�}���h�𑗂�(�^�C���A�E�g�t��)
;	in:	A	�R�}���h
;	ret:	CY	�^�C���A�E�g
;
DiSendCmdTC:
		push	hl
		ld	hl,0
		push	af
		ld	a,15
		out	(0ffh),a
DiSendCmdTC_1:
		dec	hl
		ld	a,h
		or	l
		jr	z,DiSendCmdTC_e0
		in	a,(0feh)
		and	00000010b
		jr	z,DiSendCmdTC_1
		
		ld	a,14
		out	(0ffh),a
		pop	af
		out	(0fdh),a
		ld	a,9
		out	(0ffh),a
DiSendCmdTC_2:
		dec	hl
		ld	a,h
		or	l
		jr	z,DiSendCmdTC_e1
		
		in	a,(0feh)
		and	00000100b
		jr	z,DiSendCmdTC_2
		ld	a,8
		out	(0ffh),a
DiSendCmdTC_3:
		dec	hl
		ld	a,h
		or	l
		jr	z,DiSendCmdTC_e1
		
		in	a,(0feh)
		and	00000100b
		jr	nz,DiSendCmdTC_3
		pop	hl
		ret

DiSendCmdTC_e0:
		pop	af
DiSendCmdTC_e1:
		pop	hl
		scf
		ret

; ----------------------------------------------------------------------------
;	�T�u���̃v���O���������s����
;
DiExec:
		ld	a,13
		call	DiSendCommand
		ld	a,h
		call	DiSendData
		ld	a,l
		jr	DiSendData

; ----------------------------------------------------------------------------
;	SUB ���ɃR�}���h/�f�[�^���M
;
DiSendCommand:
		push	af
		ld	a,15
		out	(0ffh),a
		db	03eh
DiSendData:
		push	af
DiSendData_1:
		in	a,(0feh)
		and	00000010b
		jr	z,DiSendData_1
		ld	a,14
		out	(0ffh),a
		pop	af
		out	(0fdh),a
		ld	a,9
		out	(0ffh),a
DiSendData_2:
		in	a,(0feh)
		and	00000100b
		jr	z,DiSendData_2
		ld	a,8
		out	(0ffh),a
DiSendData_3:
		in	a,(0feh)
		and	00000100b
		jr	nz,DiSendData_3
		ret

; ----------------------------------------------------------------------------
;	SUB ������f�[�^��M
;
DiRecvData:
		ld	a,0bh
		out	(0ffh),a
DiRecvData_1:
		in	a,(0feh)
		and	00000001b
		jr	z,DiRecvData_1
		ld	a,10
		out	(0ffh),a
		in	a,(0fch)
		push	af
		ld	a,13
		out	(0ffh),a
DiRecvData_2:
		in	a,(0feh)
		and	00000001b
		jr	nz,DiRecvData_2
		ld	a,12
		out	(0ffh),a
		pop	af
		ret

; ----------------------------------------------------------------------------
;	SUB ������f�[�^�������]��
;	in	HL	dest
;		DE	src (at sub)
;		BC	length/4
;	
DiRapidRecv:
		ld	a,1
		ld	(Critical),a
		push	hl
		ld	hl,DsRapidSend
		call	DiExecSendArg
		pop	hl
		
; ----------------------------------------------------------------------------
;	�����u���b�N��M
;	in	HL:	�f�[�^�i�[��
;		BC:	�f�[�^�T�C�Y/4
;
DiRecvFast:
		ld	a,93h
		ld	(Critical),a
		out	(0ffh),a
DiRecvFast_1:
		in	a,(0feh)
		rrca
		jp	nc,DiRecvFast_1
		in	a,(0fch)
		ld	e,a
		in	a,(0fdh)
		ld	d,a
		ld	a,9
		out	(0ffh),a
		ld	(hl),e
		inc	hl
		ld	(hl),d
		inc	hl
DiRecvFast_2:
		in	a,(0feh)
		rrca
		jp	c,DiRecvFast_2
		in	a,(0fch)
		ld	e,a
		in	a,(0fdh)
		ld	d,a
		ld	a,8
		out	(0ffh),a
		ld	(hl),e
		inc	hl
		ld	(hl),d
		cpi
		jp	pe,DiRecvFast_1
		
		
		
		ld	a,91h
		out	(0ffh),a
		xor	a
		ld	(Critical),a
		ret

; ----------------------------------------------------------------------------
;	SUB ���Ƀf�[�^�������]��
;	in	HL	src
;		DE	dest (at sub)
;		BC	length/4
;	
DiRapidSend:
		ld	a,1
		ld	(Critical),a
		push	hl
		ld	hl,DsRapidRecv
		call	DiExecSendArg
		pop	hl
; ----------------------------------------------------------------------------
;	�����u���b�N���M
;	in	HL:	�f�[�^�i�[��
;		BC:	�f�[�^�T�C�Y/4
;
DiSendFast:
		ld	a,81h
		ld	(Critical),a
		out	(0ffh),a
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		jr	DiSendFast_2
		
DiSendFast_1:
		in	a,(0feh)
		rrca
		jp	c,DiSendFast_1
		
DiSendFast_2:
		ld	a,e
		out	(0fch),a
		ld	a,d
		out	(0fdh),a
		ld	a,9
		out	(0ffh),a
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		
DiSendFast_3:
		in	a,(0feh)
		rrca
		jp	nc,DiSendFast_3
		
		ld	a,e
		out	(0fch),a
		ld	a,d
		out	(0fdh),a
		ld	a,8
		out	(0ffh),a
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		cpi
		jp	pe,DiSendFast_1
DiSendFast_4:
		in	a,(0feh)
		rrca
		jp	c,DiSendFast_4
		
		ld	a,91h
		out	(0ffh),a
		xor	a
		ld	(Critical),a
		ret

; ----------------------------------------------------------------------------
;	DEBC �� 4 �o�C�g�𑗂�
;		
DiExecSendArg:
		call	DiExec
DiSendArg:
		ld	a,d
		call	DiSendData
		ld	a,e
		call	DiSendData
		ld	a,b
		call	DiSendData
		ld	a,c
		call	DiSendData
		ret

; ----------------------------------------------------------------------------
;	SUB ���ɃR�[�h��]��
;
DiSetup:
		ld	hl,DISKMODULE
		ld	de,DISKCODEBEGIN
		ld	bc,DISKCODELEN
		
		ld	a,12
		call	DiSendCmdTC
		ret	c
		call	DiSendArg
DiSetup_1:
		ld	a,(hl)
		call	DiSendData
		cpi
		jp	pe,DiSetup_1
		or	a
		
		ld	hl,DsInit
		jp	DiExec

; ----------------------------------------------------------------------------
;	��Еt
;
DiCleanup:
		xor	a			; initialze
		call	DiSendCommand
		ret

; ----------------------------------------------------------------------------
;	�f�B�X�N�̎�ނ�������������擾
;
DiGetTypeStr:
		ld	a,(DiType)
		and	3
		add	a,a
		add	a,a
		add	a,LOW DiGetTypeStr_t
		ld	l,a
		ld	a,HIGH DiGetTypeStr_t
		adc	a,0
		ld	h,a
		ret
DiGetTypeStr_t	db	'2D',0,0,'2DD',0,'2HS',0,'2HD',0

; ----------------------------------------------------------------------------
;	�G���[�X�e�[�^�X�����Z�N�^�𐔂���
;	out:	A	�G���[�Z�N�^��
;
DiCountErrSectors:
		ld	hl,IDTABLE+idr_st0
		ld	a,(DiSectors)
		ld	b,a
		ld	c,0
		ld	de,10h
DiCountErrSectors_1:
		ld	a,(hl)
		add	hl,de
		rlca
		rlca
		ld	a,0
		adc	a,c
		ld	c,a
		djnz	DiCountErrSectors_1
		ret
		
; ----------------------------------------------------------------------------
;	�Z�N�^�𐔂��Ė��x�����Ƃ߂�
;	out:	A	���x (bit0: MFM  bit1: FM)
;
DiGetDensity:
		ld	hl,IDTABLE+idr_density
		ld	a,(DiSectors)
		ld	b,a
		ld	de,10h
		xor	a
DiGetDensity_1:
		bit	6,(hl)
		jr	z,DiGetDensity_2
		or	1
		jr	DiGetDensity_3
DiGetDensity_2:
		or	2
DiGetDensity_3:
		add	hl,de
		djnz	DiGetDensity_1
		ret
		
		