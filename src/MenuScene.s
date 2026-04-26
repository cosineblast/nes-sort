
.include "io_registers_h.s"
.include "vars_h.s"

.segment "CODE"

.export MenuScene_init
.export MenuScene_update
.export MenuScene_render

  .import rng
  .import rng_127

  .import sort_stage_update
  .import init_stage_update
  .import init_stage_render
  .import sort_stage_render

  .import get_input

  .import load_scene
  .import RootScene_init
  .import RootScene_update
  .import RootScene_render

  .import heap_sort
  .import insertion_sort

title_data:
  ;; "NESORT 1.0"
  .byte $26, $1D, $2B, $27, $2A, $2C, $00, $33, $3D, $34

;; helper function in python for generating byte sequences for the string
;; letter_byte = lambda c: '{:X}'.format(0x19 + ord(c) - ord('A'))
;; transform = lambda s: [letter_byte(c) if c.isalpha() else 0  for c in s]
;; >>> transform('MERGE SORT')
insertion_sort_string:
  ;; "INSERTION SORT"
  .byte $21, $26, $2B, $1D, $2A, $2C, $21, $27, $26, $00, $2B, $27, $2A, $2C

heap_sort_string:
  ;; "HEAP SORT"
  .byte $20, $1D, $19, $28, $00, $2B, $27, $2A, $2C

SORTING_ALGORITHM_COUNT = 2

;; TODO: rewrite as a procedure
;; X, Y: ppu addr
.macro write_static_str straddr, len
  jsr ppuctrl_write_to_right

  bit PPUSTATUS
  txa
  sta PPUADDR
  tya
  sta PPUADDR

  bit PPUSTATUS

  ldx #00      ; i = 0
  ldy #len     ; j = 10
:             ; do {
  lda straddr, x
  sta PPUDATA ; write_PPUDATA(title_data[i])
  inx    ; i ++
  dey    ; i --
  bne :- ; } while (j != 0)
.endmacro
  
MenuScene_init:
  jsr reset_colors

  ldx #$20
  ldy #$00
  jsr write_line

  ldx #$22
  ldy #$60
  jsr write_line

  ldx #$20
  ldy #$01 ;; we don't use the leftmost column
  jsr write_column

  ldx #$20
  ldy #$1E 
  jsr write_column

  ldx #$22
  ldy #$CB
  write_static_str title_data, 10

  ldx #$20
  ldy #$A6
  write_static_str insertion_sort_string, 14

  ldx #$20
  ldy #$C6
  write_static_str heap_sort_string, 9

  bit PPUSTATUS
  lda #00
  sta PPUSCROLL
  lda #224
  sta PPUSCROLL


  bit PPUSTATUS
  lda #%00001000                ; Enable background
  sta PPUMASK

  bit PPUSTATUS
  lda #%10000000                ; Enable NMI
  sta ppuctrl_value
  sta PPUCTRL

  lda #$00
  sta MenuScene_selected_sort
  rts

.proc MenuScene_update

  jsr get_input ;; input = get_input()
  lda controller_value

  and #%00000100
  beq @not_down ;; if (input & JOY_DOWN != 0) {

  ;; TODO: implement controller input differentiation
  ;; to only activate this during keypress, not on hold
  lda MenuScene_selected_sort
  cmp #SORTING_ALGORITHM_COUNT-1
  beq @not_down ;; if (selected_sort != SORTING_ALGORITHM_COUNT-1) {

  inc MenuScene_selected_sort ;; selected_sort += 1

  @not_down: ;; } }
  
  lda controller_value
  and #%00001000
  beq @not_up ;; if (input & JOY_UP != 0) {

  lda MenuScene_selected_sort
  beq @not_up ;; if (selected_sort != 0) {

  dec MenuScene_selected_sort ;; selected_sort -= 1

  @not_up: ;; } }

  lda controller_value
  and #%10000000
  beq @not_a ;; if (input & JOY_A != 0) {

  lda MenuScene_selected_sort
  asl
  tax
  lda @sorting_algorithm_table, x
  sta selected_sort_function
  lda @sorting_algorithm_table+1, x
  sta selected_sort_function+1 ; selected_sort_function = sorting_algorithm_table[selected_sort]

  lda #<RootScene_init
  sta local0
  lda #>RootScene_init
  sta local1

  lda #<RootScene_update
  sta update_procedure_address
  lda #>RootScene_update
  sta update_procedure_address+1 ; update_procedure_address = RootScene_update

  lda #<RootScene_render
  sta render_procedure_address
  lda #>RootScene_render
  sta render_procedure_address+1 ; render_procedure_address = RootScene_render

  ; longjump load_scene(RootScene_init)
  jmp load_scene


  @not_a: ;; }
  
  rts

@sorting_algorithm_table:
  .byte <insertion_sort
  .byte >insertion_sort
  .byte <heap_sort
  .byte >heap_sort
.endproc

.proc MenuScene_render
  jsr ppuctrl_write_downard ;; set_PPUCTRL_write_downards();

  ldx #00 ;; option_index = 0;

  bit PPUSTATUS
  lda #$20
  sta PPUADDR
  lda #$A4
  sta PPUADDR ;; set_PPUADDR(0x20, 0xA4)

@loop: 
  txa
  cmp #SORTING_ALGORITHM_COUNT
  beq @loop_end  ;; while (option_index != SORTING_ALOGIRTHM_COUNT) {  
  
  txa
  cmp MenuScene_selected_sort
  bne :+ ;;   if (option_index == selected_algorithm_index) {

  bit PPUSTATUS
  lda #$3E
  sta PPUDATA ;;     set_PPUDATA(RIGHT_ARROW_TILE)
  jmp :++
   :  ;;   } else {

  bit PPUSTATUS
  lda #00
  sta PPUDATA ;;     set_PPUDATA(EMPTY_TILE)
  : ;;   }

  inx ;; option_index += 1
  jmp @loop ;; }
@loop_end:

  bit PPUSTATUS
  lda #00
  sta PPUSCROLL
  lda #224
  sta PPUSCROLL ;; set_PPUSCROLL(0x00E0)
  
  rts                           ; return;
.endproc


.proc reset_colors
  ;; Changing palette colors
  bit PPUSTATUS
  lda #00
  sta PPUCTRL
  sta PPUMASK

  lda #$3f    ;; set_PPUADDR(0x3F00)
  sta PPUADDR
  lda #00
  sta PPUADDR

  lda #$0f    ;; set_PPUDATA(0x0F20)
  sta PPUDATA 
  lda #$20
  sta PPUDATA

  ;; Pallete Escape Hack
  lda #$3F     ;; avoid_PPADDR_pallette_corruption()
  sta PPUADDR  ;; https://www.nesdev.org/wiki/PPU_programmer_reference#PPUADDR_-_VRAM_address_($2006_write)
  lda #$0
  sta PPUADDR
  sta PPUADDR
  sta PPUADDR 
  rts

.endproc

;; base PPUADDR address: X..Y
write_line:
  jsr ppuctrl_write_to_right

  bit PPUSTATUS
  txa 
  sta PPUADDR
  tya
  sta PPUADDR  ; set_PPUADDR(X << 16 + Y)

  ; i = line_size
  ldx #30
  lda #24
  : ; do {
  sta PPUDATA ; set_PPUDATA(24)
  dex         ; i--
  bne :- ; } while (i != 0)
  rts

;; base PPUADDR address: X..Y
write_column:
  jsr ppuctrl_write_downard

  bit PPUSTATUS
  txa
  sta PPUADDR
  tya
  sta PPUADDR

  bit PPUSTATUS

  ldx #20 ;; i = 24
  lda #24
:             ; do {
  sta PPUDATA ; write_PPUDATA(24)
  dex         ; i--
  bne :- ; } while (i != 0)
  rts

.proc ppuctrl_write_to_right
  lda ppuctrl_value
  and #%11111011
  bit PPUSTATUS
  sta PPUCTRL 
  sta ppuctrl_value
  rts
.endproc

.proc ppuctrl_write_downard
  lda ppuctrl_value
  ora #%00000100
  bit PPUSTATUS
  sta PPUCTRL
  sta ppuctrl_value
  rts
.endproc
