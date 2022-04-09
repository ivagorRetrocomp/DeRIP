; RIP packer decompressor Intel 8080 version by Ivan Gorodetsky (2022-04-09)
; Based on Z80 version by Roman Petrov

; 1. Compress files with RIP packer by eugene77 (https://gitlab.com/eugene77/rip)
; RIP infile compressedfile
;
; 2. Reverse bitstream, for example with bitrev.exe (https://github.com/usr38259/bitrev-cli)
; BITREV compressedfile outfile
; 
; 3. Use derip.asm to decompress bitreversed outfile
; HL = source address (compressed data) 
; DE = destination address-1
; call derip

; 317 bytes

workarea 	.equ 0FA3Eh ;It has to be >=#0200 and even
;workareaSize=1474=05C2h bytes
maintree	.equ workarea
tree		.equ maintree+(120h*4)
bitlens2	.equ tree+(120h)


derip:
		shld SetHL1+1
		push d			;dest-1
		lxi b,1280h
		lxi d,tree-1
		push d
L0:
		mvi a,10h
L1:
		mov h,a
		mov a,c
		add a
		cz mWBYTE
		mov c,a
		mov a,h
		ral
		jnc L1
		inx d
		stax d
		dcr b
		jnz L0
		push b
		lxi h,18+1
		call mMTRE
		pop b
		pop d			;tree-1
GETLEN0:
		call mHFMAI
		cpi 16
		jc GETLEN_
		ldax d
		inx d
		stax d
GETLEN_:
		inx d
		stax d
		jnz GETLEN0
GETLENQ:
		push b
		lxi h,120h+1
		call mMTRE
		lxi h,32+1
		shld SetDE1+1
		lxi h,bitlens2-2
		shld SetDE2+1
		lxi d,tree
		call mTRE
		pop b
		pop d
MAINLOOP2:
		inx d
MAINLOOP1:
		call mHFMAI
		stax d
		dcr h
		jnz MAINLOOP2
		ora a
		rz
		call LLEN		;match len
		push h
		lxi h,tree
		call mHFM
		ora a
		jz CPY1
		call LLEN		;new offset
		shld MOFFSET+1
		xra a
		ora h
CPY1:
		pop h			;len
		push b
		jz COPY			; offset<256 or using last offset?
		inx h
COPY:
MOFFSET:
		lxi b,0
		mov a,e
		sub c
		mov c,a
		mov a,d
		sbb b
		mov b,a
Ldir:
		ldax b
		stax d
		inx b
		inx d
		dcx h
		mov a,l
		ora h
		jnz Ldir
		pop b			;restore bitbuf
		jmp MAINLOOP1

; Read byte
mWBYTE:
		push h
SetHL1:
		lxi h,0
		mov a,m
		inx h
		shld SetHL1+1
		pop h
		ral
		ret

mMTRE:
		shld SetDE1+1
		lxi h,tree-2
		shld SetDE2+1
		lxi d,maintree

; Build tree
mTRE:
		mov h,d
		mov l,e
		xra a
		push psw
		inr a
		push h
		push psw
		mov c,a
mTRE0:
		push d
		push h
SetDE1:
		lxi d,0
		lhld SetDE2+1
		dad d
		shld SetDE2+1
		xchg
		shld SetBC1+1
		.db 0DAh		;jc ...
mTRE1:
		push d
		push h
		mov b,a
		lhld SetBC1+1
SetDE2:
		lxi d,0
Search:
		ldax d
		cmp c
		dcx d
		dcx h
		jz $+9
		mov a,l
		ora h
		jnz Search
		stc
		shld SetBC1+1
		xchg
		shld SetDE2+1
		pop h
		pop d
		mov a,b
		jnc mTREY
		inr c
		jmp mTRE0

mTREdip:
		inr e\ inx d\ inr e\ inx d
		mov m,d			;ptr to children
		inx h
		mov m,e
		mov h,d
		mov l,e
		inr a
		push h
		push psw
mTREY:
		cmp c
		jnz mTREdip
SetBC1:
		lxi b,0
		dcx b
		mov m,b			;leaf
		inx h
		mov m,c
		mov c,a
		pop psw
		rz
		pop h
		inr l
		inx h
		jmp mTRE1

LLEN:
		adi -5
		rnc
		aci 1
		rar
		mov b,a
		aci 2
		sub b
		mov l,a
		mov a,c
		dad h
		add a
		cz mWBYTE
		jnc $+4
		inr l
		dcr b
		jnz $-10
		mov c,a
		inx h
		ret

; Read code from tree
mHFMAI:
		lxi h,maintree
mHFM:
		mov a,c
		add a
		cz mWBYTE
		mov c,a
		jnc $+5
		inr l
		inx h
		mov a,m
		inx h
		cmp h			;H>=2
		mov l,m
		mov h,a
		jnc mHFM
		mov a,l
		ret

		.end
