org	10000h

	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ax,	0x00
	mov	ss,	ax
	mov	sp,	0x7c00

;===========display msg
	mov	ax,	1301h
	mov	bx,	000ah
	mov	dx,	0200h
	mov	cx,	0ch
	mov	bp,	LoaderMsg
	int	10h

	jmp	$

;============variables
LoaderMsg	db	"Start Loader"
	times	1024-($-$$)	db	0	; test if booter can correctly read FAT
