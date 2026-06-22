# libasm
Create a library in asm, compile with NASM and Intel syntax (NewGame+)

## Difference between Intel Syntax and AT&T Syntax

Src: https://imada.sdu.dk/u/kslarsen/dm546/Material/IntelnATT.htm

- Intel Syntax

	Registre		Destination,Source
	mov     		eax,1

	Si la donne est en hexadecimal
		- on rajoute le suffixe 'h'
		Si le premier character hexadecimal est une lettre
			- On le precede d'un '0'

- AT&T Sybtax

	Registre	Source,Destination
	movl    	$1,%eax



## Section vs Segment
	Segment contient les informations neccaissaire pour lancer
	Section contient les informations besoin a l'instant T

## Registre

Il y a different type de registre "callee-saved" "caller-saved"
	- Les callee sont des registre volatille (d'autre fonction comme malloc peux les ecraser)
	- Les caller ne peuvent pas etre ecraser par d'autre fonction

## Pop et Push

	- Push: Mets ta variable en haut de la pile
	- Pop: Recupere la 1er variable de la pile