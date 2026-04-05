

.include "IO_REGISTERS.s"
.include "vars_h.s"

.segment "CODE"

.export MenuScene_main
.export MenuScene_render

  .import rng
  .import rng_127

  .import sort_stage_update
  .import init_stage_update
  .import init_stage_render
  .import sort_stage_render

title_data:
  ;; "NESORT 1.0"
  .byte $26, $1D, $2B, $27, $2A, $2C, $00, $33, $3D, $34

;; stack top: address to read
;; X: length
.proc string_to_table_index

.endproc
  
MenuScene_main:
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

  bit PPUSTATUS
  lda #00
  sta ppuctrl_value
  sta PPUCTRL ;; writes go rightward
  
  bit PPUSTATUS
  lda #$22
  sta PPUADDR
  lda #$CB
  sta PPUADDR

  bit PPUSTATUS

  ldx #00     ; i = 0
  ldy #10     ; j = 10
:             ; do {
  lda title_data, x
  sta PPUDATA ; write_PPUDATA(title_data[i])
  inx    ; i ++
  dey    ; i --
  bne :- ; } while (j != 0)

  

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

halt:
  jmp halt ; while (1) { }

MenuScene_render:
  rts                           ; return;


.proc reset_colors
  ;; Changing palette colors
  bit PPUSTATUS

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
  bit PPUSTATUS
  lda #00
  sta ppuctrl_value
  sta PPUCTRL ;; writes go rightward

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
  bit PPUSTATUS
  lda #%00000100 ; // PPUDATA increments downward
  sta ppuctrl_value
  sta PPUCTRL

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
