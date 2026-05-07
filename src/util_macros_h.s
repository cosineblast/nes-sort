
.macro push v
	lda v
	pha
.endmacro

.macro pushx
	txa
	pha
.endmacro

.macro pushy
	tya
	pha
.endmacro

.macro pull v
	pla
	sta v
.endmacro

.macro pullx
	pla
	tax
.endmacro

.macro pully
	pla
	tay
.endmacro
