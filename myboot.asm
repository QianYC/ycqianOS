	org	0x7c00
BaseOfStack	equ 0x7c00

;========= start of the first sector

	jmp	short	Label_Start
	nop
	BS_OEMName	db	"ycqianOS"
	BPB_BytesPerSec	dw	512
	BPB_SecPerClus	db	1
	BPB_RsvdSecCnt	dw	1
	BPB_NumFATs	db	2
	BPB_RootEntCnt	dw	224
	BPB_TotSec16	dw	2880
	BPB_Media	db	0xf0
	BPB_FATSz16	dw	9
	BPB_SecPerTrk	dw	18
	BPB_NumHeads	dw	2
	BPB_HiddSec	dd	0
	BPB_TotSec32	dd	0
	BS_DrvNum	db	0
	BS_Reserved1	db	0
	BS_BootSig	db	0x29
	BS_VolID	dd	0
	BS_VolLab	db	"boot loader"
	BS_FileSysType	db	"FAT12   "

BaseOfLoader	equ	0x1000
OffsetOfLoader	equ	0x00

RootDirSectors	equ	14	; num of sectors of root dir
FirstRootSector	equ	19
FirstFAT1Sector	equ	1
SectorBalance	equ	31	; cluster number + SectorBalance = real sector number

;========== boot code

Label_Start:

;========== initialize ds, es, ss, sp
	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ss,	ax
	mov	sp,	BaseOfStack

;========== clean the screen
	mov	ax,	0600h	
	mov	cx,	0000h
	mov	dx,	3250h
	int	10h

;========== set the cursor
	mov	ax,	0200h
	mov	dx,	0000h
	mov	bx,	0000h
	int	10h

;========== echo boot msg
	mov	ax,	1301h
	mov	cx,	10h
	mov	bx,	000fh
	mov	bp,	BootMsg
	int	10h

;========== reset floppy
	xor	ah,	ah
	xor	dl,	dl
	int	13h

;========== search root dir 4 loader.bin
	mov	word[SectorNo],	FirstRootSector
	mov	word[RootDirLoop],	RootDirSectors

Label_SearchInRootDir:

	cmp	word[RootDirLoop],	0
	jz	Label_LoaderNotFound
	dec	word[RootDirLoop]
	mov	ax,	00h
	mov	es,	ax
	mov	bx,	8000h
	mov	ax,	[SectorNo]
	mov	cl,	1
	call	Func_ReadSectors
	mov	si,	LoaderName
	mov	di,	8000h
	cld			; enable address to grow automatically when comparing filename
	mov	dx,	10h	; a sector contains 16 entry, loop

Label_SearchForLoader:

	cmp	dx,	0
	jz	Label_NextSector
	dec	dx
	mov	cx,	0bh

Label_CmpFileName:

	cmp	cx,	0
	jz	Label_FileNameFound
	dec	cx
	lodsb			; load byte from si to al
	cmp	al,	byte[es:di]
	jz	Label_NextChar
	jmp	Label_Different

Label_NextChar:

	inc	di
	jmp	Label_CmpFileName

Label_Different:

	and	di,	0ffe0h	; clear last 5 bits of di => move di to the begining of current root dir entry
	add	di,	20h	; mov di to next root dir entry
	mov	si,	LoaderName
	jmp	Label_SearchForLoader

Label_NextSector:

	add	word[SectorNo],	1
	jmp	Label_SearchInRootDir

Label_FileNameFound:

	mov	ax,	RootDirSectors	; di points to the dir entry of loader bin
	and	di,	0ffe0h	; move di to the begining of current dir entry
	add	di,	01ah	; move di to the cluster field in dir entry
	mov	ax,	word[es:di]	; read the cluster number to ax
	mov	cx,	BaseOfLoader
	mov	es,	cx
	mov	bx,	OffsetOfLoader

Label_LoadLoader:

	push	ax
	push	ax
	push	bx
	mov	ah,	0eh
	mov	al,	'.'
	mov	bl,	0fh
	int	10h		; print . on the screen to show the progress
	pop	bx
	pop	ax

	cmp	ax,	0ff8h
	jc	Label_ContinueLoading
	jmp	Label_LoaderLoaded

Label_ContinueLoading:

	add	ax,	SectorBalance
	mov	cl,	1
	call	Func_ReadSectors
	add	bx,	[BPB_BytesPerSec]
	pop	ax
	call	Func_GetNextFAT
	cmp	ax,	0ff7h
	jz	Label_LoaderSpoiled
	jmp	Label_LoadLoader

Label_LoaderSpoiled:

	mov	ax,	1301h
	mov	dx,	0100h	; screen position
	mov	cx,	0eh
	mov	bx,	000ch
	mov	bp,	LoaderSpoiledMsg
	int	10h
	jmp	$

Label_LoaderLoaded:

	jmp	BaseOfLoader:OffsetOfLoader

Label_LoaderNotFound:

	mov	ax,	1301h
	mov	dx,	0100h	; screen position
	mov	cx,	16h
	mov	bx,	000ch
	mov	bp,	NoLoaderMsg
	int	10h

	jmp	$

;========== functions

;==================
; ax: the first sector to be read
; cl: nums of sectors
; bx: the buffer address
;==================
Func_ReadSectors:
	push	bp
	mov	bp,	sp
	sub	esp,	2
	mov	byte[bp-2],	cl
	push	bx
	mov	bl,	[BPB_SecPerTrk]
	div	bl
	inc	ah
	mov	cl,	ah
	mov	dh,	al
	shr	al,	1
	mov	ch,	al
	mov	dl,	[BS_DrvNum]
	pop	bx
Label_ContinueReading:
	mov	ah,	02h
	mov	al,	byte[bp-2]
	int	13h
	jc	Label_ContinueReading	; until read successfully
	add	esp,	2
	pop	bp
	ret

;=====================
; ah: stores the FAT id
;=====================
Func_GetNextFAT:
	push	es
	push	bx
	push	ax
	mov	ax,	00
	mov	es,	ax
	pop	ax
	mov	bx,	12
	mul	bx
	mov	bx,	[BPB_BytesPerSec]
	div	bx
	push	dx
	mov	bx,	8000h
	add	ax,	FirstFAT1Sector
	mov	cl,	2
	call	Func_ReadSectors
	pop	dx
	add	bx,	dx
	mov	ax,	[es:bx]
	shr	ax,	4
	and	ax,	0fffh
	pop	bx
	pop	es
	ret

;========== variables
BootMsg		db	"ycqianOS Booting"
LoaderSpoiledMsg	db	"Loader Spoiled"
NoLoaderMsg	db	"ERROR:Loader Not Found"
LoaderLoadedMsg	db	"Loader Loaded Success"
LoaderName	db	"LOADER  BIN",0
RootDirLoop	dw	0
SectorNo	dw	0
Odd		db	0

	times	510-($-$$)	db	0
	dw	0xaa55
	
