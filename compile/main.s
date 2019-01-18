	.file	"main.c"
	.intel_syntax noprefix
	.comm	list,64,32
	.globl	haha
	.data
	.align 4
	.type	haha, @object
	.size	haha, 11
haha:
	.string	"Haha = lol"
	.section	.rodata
.LC0:
	.string	"Hello World!"
	.text
	.globl	main
	.type	main, @function
main:
	lea	ecx, [esp+4]
	and	esp, -16
	push	DWORD PTR [ecx-4]
	push	ebp
	mov	ebp, esp
	push	ecx
	sub	esp, 36
	mov	DWORD PTR [ebp-36], 5
	sub	esp, 12
	push	OFFSET FLAT:.LC0
	call	puts
	add	esp, 16
	sub	esp, 12
	push	50
	call	malloc
	add	esp, 16
	mov	DWORD PTR [ebp-12], eax
	sub	esp, 4
	push	50
	push	0
	push	DWORD PTR [ebp-12]
	call	memset
	add	esp, 16
	fld	DWORD PTR .LC1
	fstp	DWORD PTR [ebp-16]
	fld	DWORD PTR .LC2
	fstp	DWORD PTR [ebp-20]
	fld	DWORD PTR [ebp-16]
	fadd	DWORD PTR [ebp-20]
	fstp	DWORD PTR [ebp-24]
	mov	DWORD PTR [ebp-28], 11
	mov	eax, 10
	mov	ecx, DWORD PTR [ebp-4]
	leave
	lea	esp, [ecx-4]
	ret
	.size	main, .-main
	.section	.rodata
	.align 4
.LC1:
	.long	1080033280
	.align 4
.LC2:
	.long	1085392657
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.10) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
