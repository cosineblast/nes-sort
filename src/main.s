;; Note: includes must always be followed by segment directives
;; since includes may include their own segment directives

.include "IO_REGISTERS.s"
.include "vars_h.s"

.segment "HEADER"
    .byte $4E, $45, $53, $1A    ; Header
    .byte 2                     ; 16kb PRG blocks
    .byte 1                     ; 8kb CHR blocks
    .byte $01, $00              ; mapper 0, vertical mirroring

.segment "STARTUP"
.segment "VECTORS"
    ;; NMI Handler, Reset Handler, IRQ Handler
    .addr nmi_handler
    .addr on_reset
    .addr 0


  .segment "CODE"
  .import RootScene_init
  .import RootScene_update
  .import RootScene_render

  .import MenuScene_init
  .import MenuScene_update
  .import MenuScene_render

;; Change here to set initial scene
  SCENE_INIT = MenuScene_init
  SCENE_UPDATE = MenuScene_update
  SCENE_RENDER = MenuScene_render

on_reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs
  inx		; now X = 0
  stx ppuctrl_value
  stx PPUCTRL	; disable NMI
  stx PPUMASK 	; disable rendering
  stx $4010 	; disable DMC IRQs


  ;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit PPUSTATUS
  bpl vblankwait1

clear_memory:
  lda #0
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

  ;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit PPUSTATUS
  bpl vblankwait2

main:
  lda #1                      ; Begin first update
  sta is_updating

  jsr SCENE_INIT

update: ;; while (true) {

  ; while (!is_updating) {  }
  @wait_update:
  lda is_updating
  beq @wait_update

  jsr SCENE_UPDATE

  lda #0
  sta is_updating;; is_updating = 0

  jmp update ; } // while (true)

nmi_handler:
  php
  pha

  lda is_updating               ; if (is_updating) {
  beq :+
  pla
  plp
  rti                           ; return
:                               ; }
  jsr SCENE_RENDER

  lda #1
  sta is_updating

  pla
  plp
  rti


.segment "CHARS"

.incbin "pattern-table.bin"
.incbin "alphabet-table.bin"
