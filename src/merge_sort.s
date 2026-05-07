
.code

.include "vars_h.s"
.include "util_macros_h.s"


.import sortapi_signal_read

LEN = 128

.proc merge_sort
	lda #00
	sta local0

	lda #LEN
	sta local1
	jmp merge_sort_internal
.endproc

; fn mergeSort(arr: [*]u8, aux: [*]u8, start: usize, end: usize) void {
;     if (start == end) {
;         return;
;     }

;     const len = end - start;

;     if (len == 1) {
;         return;
;     }

;     const mid = start + @divFloor(len, 2);
;     mergeSort(arr, aux, start, mid);
;     mergeSort(arr, aux, mid, end);

;     merge(arr, aux, start, mid, end);
; }
.proc merge_sort_internal
	;; local0: start
	;; local1: end

	lda local0
	cmp local1
	bne :+ ; if (start == end) {
	rts ; return
: ; }

	lda local1
	sec
	sbc local0
	sta local2 ; len = end - start

	cmp #1 
	bne :+ ; if (len == 1) {
	rts  ; return
: ; }

	lsr
	clc
	adc local0
	sta local2 ; mid = (len / 2) + start

	push local0
	push local1
	push local2

	lda local2
	sta local1
	jsr merge_sort_internal ; mergeSort(start, mid)

	pull local2
	pull local1
	pull local0

	push local0
	push local1
	push local2

	lda local2
	sta local0
	jsr merge_sort_internal ; mergeSort(mid, end)

	pull local2
	pull local1
	pull local0
	
	jsr merge ; merge(start, end, mid)

	rts
.endproc

	
; fn merge(arr: [*]u8, aux: [*]u8, start: usize, mid: usize, end: usize) void {
;     var left = start;
;     var right = mid;
;     var target = start;

;     while (true) {
;         if (left == mid) {
;             copy(aux, arr, target, right, end);
;             break;
;         } else if (right == end) {
;             copy(aux, arr, target, left, end);
;             break;
;         }

;         const left_value = arr[left];
;         const right_value = arr[right];

;         if (left_value < right_value) {
;             aux[target] = left_value;
;             left += 1;
;         } else {
;             aux[target] = right_value;
;             right += 1;
;         }

;         target += 1;
;     }

;     copy(arr, aux, start, start, end);
; }
.proc merge
	;; local0: start
	;; local1: end
	;; local2: mid

	start = local0
	end = local1
	mid = local2
	

	left = local3
	lda start
	sta left ; left = start

	right = local4
	lda mid
	sta right ; right = mid

	target = local5
	lda start
	sta target ; target = start


loop: ; while (true) {

	lda left
	cmp mid
	bne :+; if (left == mid) {

	lda target
	tax
	lda right
	tay
	lda end
	sta local6
	jsr copy_aux  ; copy_aux(target, right, end)

	jmp endloop  ; break

: ; } else {

	lda right
	cmp end
	bne :+; if (right == end) {

	lda target
	tax
	lda left
	tay
	lda end
	sta local6
	jsr copy_aux ; copy_aux(target, left, end)

	jmp endloop ; break

: ;  } }


	push local0
	push local1
	push local2

	push right

	lda left
	jsr sortapi_signal_read ; sortapi_signal_read(left)

	pla
	jsr sortapi_signal_read ; sortapi_signal_read(right)
	

	pull local2
	pull local1
	pull local0

	left_value = local6
	ldx left
	lda sorting_array, x
	sta left_value
	
	right_value = local7
	ldx right
	lda sorting_array, x
	sta right_value

	lda left_value
	cmp right_value
	beq :+
	bpl :+ ; if (left_value < right_value) {

	ldx target
	lda left_value
	sta aux_array, x ; aux_array[target] = left_value

	inc left ; left += 1

	jmp :++
: ; } else {

	ldx target
	lda right_value
	sta aux_array, x; aux_array[target] = right_valeu

	inc right ; right += 1

: ; } 

	inc target ; target += 1
	
	jmp loop
	endloop: ; } // while

	lda start
	tax
	lda start
	tay
	lda end
	sta local6
	jsr copy_main ; copy_main(start, start, end)

	rts
	
.endproc


; fn copy(dest: [*]u8, source: [*]u8, dest_offset: usize, source_start: usize, source_end: usize) void {
;     @memcpy(dest[dest_offset..(dest_offset+source_end-source_start)], source[source_start..source_end]);
; }
.proc copy_aux
	;; X: dest_offset
	;; Y: source_start
	;; local6: source_end

@loop:
	tya 
 	cmp local6 
	beq @loop_end        ; while (y != source_end) { 

	lda sorting_array, y
	sta aux_array, x     ;   aux_array[x] = sorting_array[y]

	iny                  ;   y += 1
	inx                  ;   x += 1

	jmp @loop
@loop_end:               ; }

	rts  ; return

.endproc


.proc copy_main
	;; X: dest_offset
	;; Y: source_start
	;; local6: source_end
@loop:
	tya 
 	cmp local6
	beq @loop_end        ; while (y != source_end) { 

	lda aux_array, y
	sta sorting_array, x ;   sorting_array[x] = aux_array[y]
	pushy
	pushx

	push local0
	push local1
	push local2

	txa
	jsr sortapi_signal_read ; sortapi_signal_read(x) // TODO: use sortapi_signal_write

	pull local2
	pull local1
	pull local0

	pully
	pullx

	iny                  ;   y += 1
	inx                  ;   x += 1

	jmp @loop
@loop_end:               ; }

	rts  ; return

.endproc


.export merge_sort
