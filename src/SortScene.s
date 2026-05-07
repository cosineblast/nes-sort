.include "vars_h.s"
.include "io_registers_h.s"

;; column.s
.import notify_update

;; coroutine.s
.import coroutine_resume
.import coroutine_yield

;; insertion_sort.s
.import insertion_sort

;; heap_sort.s
.import heap_sort

;; input.s
.import get_input




.code

;; .exports are at the bottom of the file
;;   for scope reasons.

.proc SortScene_update

  jsr handle_input




    jsr coroutine_resume  ;    (result, swap_indexes) = coroutine_resume();

    lda local2 ; note: local2 is the register that indicates
               ; whether the sorting coroutine has ended or not

    bne @coroutine_done              ; if (result == 0) {

    jmp notify_update                ;      notify_update(swap_indexes);
                                     ;      return;
@coroutine_done:                           ; }

    lda #PROGRAM_STAGE_DONE          ; else {
    sta current_sorting_stage        ;   current_sorting_stage = PROGRAM_STAGE_DONE;
    rts                              ; return;
                                     ; }
.endproc

.proc handle_input
  jsr get_input

  ; if ((controller_value & JOY_RIGHT) &&
  ;      array_scroll_offset < SORTING_DATA_SIZE) {
  lda controller_value
  and #JOY_RIGHT
  beq :+
  lda array_scroll_offset
  cmp #SORTING_DATA_SIZE/2
  bcs :+

  ; array_scroll_offset += 1
  inc array_scroll_offset

  ; }
  :

  ; if ((controller_value & JOY_LEFT) &&
  ;      array_scroll_offset != 0) {
  lda controller_value
  and #JOY_LEFT
  beq :+
  lda array_scroll_offset
  beq :+
  dec array_scroll_offset

: ; }

  rts
.endproc

;; Sorting coroutine function.
;; This is the entry point of the coroutine that sorts the array.
;; When the coroutine does some visualizable array operation,
;; such as swapping, it will call coroutine_yield and tell what operation
;; was done.
;; 
;; When the coroutine yields, the value of the local registers on the original execution
;; context  gets set to the values of the local registers of the coroutine at yield, meaning
;; that the main execution context can directly see the values of the locals at yield,
;; and it uses this information to tell on the reason for the coroutine yield.
;; local2 is used to indicate whether the coroutine has ended its execution or not.
;; local0 and local1 indicate the indices of the array elements that were swapped.
.proc sort_array

  lda #>sort_end
  pha
  lda #<sort_end
  pha
  jmp (selected_sort_function)
  nop
  sort_end:
  nop

  .import load_scene
  .import MenuScene_init
  .import MenuScene_update
  .import MenuScene_render
  
  lda #<MenuScene_init
  sta local0
  lda #>MenuScene_init
  sta local1

  lda #<MenuScene_update
  sta update_procedure_address
  lda #>MenuScene_update
  sta update_procedure_address+1 ; update_procedure_address = MenuScene_update

  lda #<MenuScene_render
  sta render_procedure_address
  lda #>MenuScene_render
  sta render_procedure_address+1 ; render_procedure_address = MenuScene_render

  ; longjump load_scene(MenuScene_init)
  jmp load_scene
  rts

  lda #1
  sta local2
  jsr coroutine_yield     ;  yield 1
  @UB:                    ; resuming again is undefined behaviour
  jmp @UB
.endproc

;; A: index0
;; X: index1
;; clobbers: A,X,Y, local0, local1, local2
;; TODO: rename to sortapi_swap
.proc swap

; tmp = array[index0]
  tay
  lda sorting_array, x
  sta local0

; array[index0] = array[index1]
  lda sorting_array, y
  sta sorting_array, x

; array[index1] = tmp
  lda local0
  sta sorting_array, y


  stx local0
  sty local1
  lda #0
  sta local2
  jmp coroutine_yield
.endproc

;; A: index0
;; clobbers: A, local0, local1, local2, X , Y
.proc sortapi_signal_read

  sta local0
  sta local1

  lda #0
  sta local2

  jmp coroutine_yield
.endproc

;; A: index0
;; X: index1
;; clobbers  A, local0, local1, local2, X , Y
.proc sortapi_signal_read2
  sta local0
  stx local1

  lda #0
  sta local2

  jmp coroutine_yield
.endproc

.proc SortScene_render

.import render_columns_from_positions
  jsr render_columns_from_positions

  bit PPUSTATUS

  ;; we reset PPUCTRL, because after touching
  ;; ppuaddr, the base namespace gets modified.
  lda ppuctrl_value
  sta PPUCTRL
  sta ppuctrl_value

  ; set_PPUSCROLL(array_scroll_offset * 4);
  bit PPUSTATUS
  lda array_scroll_offset
  asl A
  asl A
  sta PPUSCROLL

  lda #00
  sta OAMADDR
  lda #>oam_buffer
  sta OAMDMA; domain expansion: direct memory access

  ; set_PPUSCROLL(224);
  lda #224
  sta PPUSCROLL

  rts

.endproc


.export coroutine_start_location = sort_array
.export swap
.export SortScene_update
.export SortScene_render
.export sortapi_signal_read
.export sortapi_signal_read2
