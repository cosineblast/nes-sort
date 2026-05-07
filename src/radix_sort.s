
.include "vars_h.s"
.include "util_macros_h.s"

.import sorting_array
.import aux_array


.import sortapi_signal_read

LEN = 128

.proc radix_sort
	lda #%00000011
	sta local0
	lda #0
	sta local1
	jsr counting_sort  ; countingSort(arr, aux, 0b00000011, 0, len);
	
	lda #%00001100
	sta local0
	lda #2
	sta local1
	jsr counting_sort  ; countingSort(arr, aux, 0b00001100, 2, len);
	
	lda #%00110000
	sta local0
	lda #4
	sta local1
	jsr counting_sort  ; countingSort(arr, aux, 0b00110000, 4, len);
	
	lda #%11000000	
	sta local0
	lda #6
	sta local1
	jsr counting_sort  ; countingSort(arr, aux, 0b11000000, 6, len);

	rts
.endproc


.proc counting_sort
	;; local0: mask
	;; local1: shift

	lda #00
	sta local4
	sta local4+1
	sta local4+2
	sta local4+3 ; table: [4]u8 = @splat(0)


	ldy #0              ; i = 0

@count_loop:
	tya
	cmp #LEN
	beq @end_count_loop ; while (i != len) {

	push local0
	push local1
	push local2
	pushx
	pushy

	tya
	jsr sortapi_signal_read

	pully
	pullx
	pull local2
	pull local1
	pull local0


	lda sorting_array, y
	and local0
	ldx local1
	jsr shift_right     ;  value = (arr[i] & mask) >> shift

	tax
	inc local4, x       ;  table[value] += 1;

	iny                 ;  i += 1

	jmp @count_loop     ; }
@end_count_loop:

	lda #00
	sta local2        ; sum = 0

	ldy #00           ; i = 0

@sum_loop:
	tya
	cmp #4
	beq @end_sum_loop ; while (i != 4) {

	lda local4, y     ;  count = table[i]

	pha
	lda local2
	sta local4, y     ;  table[i] = sum

	pla
	clc
	adc local2
	sta local2        ;  sum = count + sum
	

	iny               ;  i += 1
	jmp @sum_loop
@end_sum_loop:        ; }


	ldy #00                 ; i = 0

@redirect_loop:
	tya
	cmp #LEN
	beq @end_redirect_loop ; while (i != len) {

	;; NOTE: we could make a signal_read here, considering we
	;; reading from the array.
	;; However, in real counting sort implementations (with even number of counting sort rounds), we
	;; don't have the copy step, and instead we alternate between sorting using the main and auxiliary,
	;; arrays. For visualization purposes, we don't do that here, but we compensate in timing for the
	;; copy step by not signaling the redirect step.

	lda sorting_array, y
	and local0
	ldx local1
	jsr shift_right         ;  value = (arr[i] & mask) >> shift

	pha
	tax
	lda local4, x
	tax
	lda sorting_array, y
	sta aux_array, x        ;  aux[table[value]] = arr[i]

	pla
	tax
	inc local4, x           ; table[value] += 1;

	iny                     ; i += 1

	jmp @redirect_loop
@end_redirect_loop:

	ldy #00              ; i = 0

	ldx #00              ; j = 0

@copy_loop:
	tya
	cmp #LEN
	beq @end_copy_loop   ; while (i != LEN) {


	lda aux_array, x 
	sta sorting_array, y ;  sorting_array[i] = aux_array[j]

	pushx
	pushy

	tya
	jsr sortapi_signal_read ; TODO: use sortapi_signal_write

	pully
	pullx

	iny                  ;  i += 1

	inx                  ;  j += 1

	jmp @copy_loop       ; }
@end_copy_loop:

	rts ; return
.endproc 


.proc shift_right
	;; A: value to shift
	;; x: amount to shift
	;; result stored in A

	cpx #00
	beq @skip
	
@loop:
	lsr A
	dex
	bne @loop

@skip:
	rts

.endproc

.export radix_sort

; fn radixSort(arr: [*]u8, aux: [*]u8, len: usize) void {
;     countingSort(arr, aux, 0b00000011, 0, len);
;     countingSort(arr, aux, 0b00001100, 2, len);
;     countingSort(arr, aux, 0b00110000, 4, len);
;     countingSort(arr, aux, 0b11000000, 6, len);
; }

; const MASKED_LIMIT: comptime_int = 4;
; fn countingSort(noalias arr: [*]u8, noalias aux: [*]u8, mask: u8, shift: u3, len: usize) void {
;     var table: [MASKED_LIMIT]u8 = @splat(0);
    
;     for (0..len) |i| {
;         const value = @shrExact((arr[i] & mask), shift);
;         table[value] += 1;
;     }

;     var sum: u8 = 0;

;     for (0..MASKED_LIMIT) |i| {
;         const count = table[i];
;         table[i] = sum;
;         sum += count;
;     }

;     for (0..len) |i| {
;         const value = @shrExact(arr[i] & mask, shift);

;         aux[table[value]] = arr[i];
;         table[value] += 1;
;     }

;     @memcpy(arr[0..len], aux[0..len]);
; }
