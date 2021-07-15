; ----------------------------------------------------------------------------
;	xdisk 2.0
;	copyright (c) 2000 cisc.
; ----------------------------------------------------------------------------
;	$Id: rle.asm,v 1.2 2000/01/14 13:24:34 cisc Exp $

 if 0
putadr:
		push	af
		push	de
		ld	de,0f3c8h+76
		ld	a,b
		call	putadr_1
		ld	a,c
		call	putadr_1
		pop	de
		pop	af
		ret
		
putadr_1:
		push	af
		rrca
		rrca
		rrca
		rrca
		call	putadr_2
		pop	af
putadr_2:
		and	0fh
		cp	10
		jr	c,$+4
		add	a,7
		add	a,'0'
		ld	(de),a
		inc	de
		ret
 endif

; ----------------------------------------------------------------------------
;	RLE ���k
;	in:	hl	���k����f�[�^
;		de	���k��
;		bc	�f�[�^�T�C�Y
;	out:	hl	���k��̃f�[�^�T�C�Y
;		nc
;
RLECompress:	
		push	de
		push	de
		exx
		pop	hl
RLECompress_1:
		ld	d,h	; DE' = mark
		ld	e,l
		inc	hl
		exx
		ld	e,0
RLECompress_2:
;	call	putadr
		ld	a,(hl)
		inc	hl
		cpi
		jp	po,RLECompress_3
		jr	z,RLECompress_4		; (HL-1) == (HL)
RLECompress_6:
		dec	hl
		exx
		ld	(hl),a
		inc	hl
		exx
		ld	a,e
		inc	e
		cp	7fh
		jr	c,RLECompress_2
		
		; ������
		exx
		ld	(de),a
		jp	RLECompress_1
		
RLECompress_3:	; 1 �o�C�g�ǂ񂾎��_�Ŏ��Ԑ؂�
		exx
		ld	(hl),a
		inc	hl
		exx
		ld	a,e
		exx
		ld	(de),a
		pop	de
		or	a
		sbc	hl,de
		ret

RLECompress_5:
		dec	hl
		inc	bc
		jp	RLECompress_6

RLECompress_4:
;	call	putadr
		cpi				; HL=ORG+3
		jp	po,RLECompress_5
		jr	nz,RLECompress_5
		; 3 �o�C�g��v�����݂���
		ld	d,a
		ld	a,e
		exx
		sub	1
		ld	(de),a
		jr	nc,RLECompress_11
		; ���O�� RLE �������ꍇ
		dec	hl
RLECompress_11:
		exx
		; �㉽�o�C�g��v���Ă���́H
		ld	a,d
		ld	e,81h
RLECompress_7:
		cpi			; HL=ORG+4
		jp	po,RLECompress_9
		jr	nz,RLECompress_8
		inc	e
		jr	nz,RLECompress_7
		dec	bc
		jr	RLECompress_10
RLECompress_8:				; HL = �s��v�_�̎�
		dec	hl
RLECompress_10:
		exx
		ld	e,a		; �L��
		exx
		dec	e
		ld	a,b
		or	c
		ld	a,e		; ��v��
		exx
		ld	(hl),a
		inc	hl
		ld	(hl),e
		inc	hl
		jp	nz,RLECompress_1
		jp	RLECompress_12

RLECompress_9:
		exx			; HL = �ŏI��v�_, �Œ��v�� = 4
		ld	e,a
		exx
		ld	a,e
		exx
		ld	(hl),a
		inc	hl
		ld	(hl),e
		inc	hl
RLECompress_12:
		pop	de
		or	a
		sbc	hl,de
		ret
		
