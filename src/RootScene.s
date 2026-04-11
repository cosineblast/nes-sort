

.include "IO_REGISTERS.s"
.include "vars_h.s"

.segment "CODE"

.export RootScene_init
.export RootScene_update
.export RootScene_render

  .import rng
  .import rng_127

  .import SortSetupScene_update
  .import SortSetupScene_render
  .import SortScene_update
  .import SortScene_render


RootScene_init:
  ;; Changing palette colors
  bit PPUSTATUS

  lda #$3f
  sta PPUADDR

  lda #0
  sta PPUADDR

  lda #$0f
  sta PPUDATA

  lda #$20
  sta PPUDATA

  ;; Pallete Escape Hack
  lda #$3F
  sta PPUADDR
  lda #$0
  sta PPUADDR
  sta PPUADDR
  sta PPUADDR

  lda #%10000100                ; Enable NMI, PPUDATA writes increment downard
  sta ppuctrl_value
  sta PPUCTRL

  lda #%00001010                ; Enable background and leftmost column
  sta PPUMASK

generate_numbers:

  lda #231                      ; setting rng_seed
  sta rng_seed

  lda #$ff
  sta rng_seed+1


  ;; Initialize array
  ;; 0..100 is initalized with 0..100
  ;; 101..127 is initalized with 1..7

  ; for (i8 i = 100; i >= 0;  i--) {
  ldx #100
@loop:

  ; sorting_array[i] = i
  txa
  sta sorting_array, x

  ; }
  dex
  bpl @loop

  ; j = 0
  ; for (i = 101; i != 127; i++) {
  ldx #101
  ldy #0
@loop2:

  ; sorting_array[i] = j
  tya
  sta sorting_array, x

  ; j += 4
  iny
  iny
  iny
  iny

  ; i += 1
  inx
  txa

  cmp #127
  bne @loop2
  ; }



  ;; jmp skip_shuffle
shuffle:

  ; index = 127
  ldy #127
  sty local0

  ; do {
@loop:

  ; rng1 = rng_127()
  jsr rng_127
  pha

  ; rng2 = rng_127()
  jsr rng_127
  tax
  pla
  tay

  ; tmp = sorting_array[rng1]
  lda sorting_array, x
  pha

  ; sorting_array[rng1] = sorting_array[rng2]
  lda sorting_array, y
  sta sorting_array, x

  ; sorting_array[rng2] = sorting_array[rng1]
  pla
  sta sorting_array, y

  ; index--
  ldy local0
  dey
  sty local0

  ; } while (index >= 0)
  bpl @loop
  skip_shuffle:

  rts

.proc RootScene_update
  ; if (current_sorting_stage == 0) {
  ;   SortSetupScene_update()
  ; }
  ; else {
  ;   SortScene_update()
  ; }
  lda current_sorting_stage
  beq @is_init
  cmp #PROGRAM_STAGE_SORT
  beq @is_sort
  jmp @end

  @is_init:
  jsr SortSetupScene_update
  jmp @end
  @is_sort:
  jsr SortScene_update
  @end:

  rts
.endproc

.proc RootScene_render
  lda current_sorting_stage
  beq @is_init
  cmp #1
  beq @is_sort
  jmp @end

@is_init:                    ; if (current_sorting_stage == 0) {
  jsr SortSetupScene_render      ;      SortSetupScene_render();
  jmp @end                   ; }

@is_sort:                       ; else if (current_sorting_stage == 1) {
  jsr SortScene_render         ;   SortScene_render();
@end:                           ; }

  rts                           ; return;
.endproc
