;; main.s: Dynamic dispatch scene
;; This project uses a NES runtime organization model
;; such that execution is always divided between 'updates'
;; and 'renders'.
;; Updates can run for as long as necessary, and NMI calls during updates
;; simply get ignored. This is controlled with is_update.
;; Update code doesn't touch the PPU unless it disables rendering with
;; PPUMASK and PPUCTRL.
;; The nmi handler and update handlers decide which function to run based on
;; dynamic dispatch of the update_procedure_address and render_procedure_address
;; global addresses.

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
    .addr reset_handler
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

reset_handler:
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

  lda #1                      ; Begin first update
  sta is_updating

first_load:
  lda #<SCENE_INIT
  sta local0
  lda #>SCENE_INIT
  sta local1

  lda #<SCENE_UPDATE
  sta update_procedure_address
  lda #>SCENE_UPDATE
  sta update_procedure_address+1

  lda #<SCENE_RENDER
  sta render_procedure_address
  lda #>SCENE_RENDER
  sta render_procedure_address+1

;; This is a JMP-call procedure (as opposed to JSR-call)
;; that replaces the current root scene being rendered by the application.
;; It assumes the init address is located in local0..local1, and that
;; the global variables (render|update)_procedure_address have been set
;; to the update and render addresses of the procedures
;; This procedure must be called during an update.
load_scene:
  ;; reset stack
  ldx #$ff
  txs

  lda #>load_return
  pha 
  lda #<load_return
  pha
  jmp (local0)
;; considering load_jmp sets the return address to this position,
;; we need the no op since rts expects the return address to be
;; the original jsr instruction pointer, not the next address
;; this same technique is used later on in other indirect jumps
load_return:
  nop

update: ;; while (true) {
  ; while (!is_updating) {  }
  @wait_update:
  lda is_updating
  beq @wait_update

  lda #>update_return
  pha
  lda #<update_return
  pha
  jmp (update_procedure_address)
update_return:
  nop

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

  ;; render_procedure_address()
  lda #>render_return
  pha
  lda #<render_return
  pha
  jmp (render_procedure_address)
render_return:
  nop

  lda #1
  sta is_updating

  pla
  plp
  rti


.segment "CHARS"

.incbin "pattern-table.bin"
.incbin "alphabet-table.bin"
.export load_scene
