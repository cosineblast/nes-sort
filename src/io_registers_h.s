

;; PPUCTRL: Miscellaneous settings
;; 7  bit  0
;; ---- ----
;; VPHB SINN
;; |||| ||||
;; |||| ||++- Base nametable address
;; |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
;; |||| |+--- VRAM address increment per CPU read/write of PPUDATA
;; |||| |     (0: add 1, going across; 1: add 32, going down)
;; |||| +---- Sprite pattern table address for 8x8 sprites
;; ||||       (0: $0000; 1: $1000; ignored in 8x16 mode)
;; |||+------ Background pattern table address (0: $0000; 1: $1000)
;; ||+------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels – see PPU OAM#Byte 1)
;; |+-------- PPU master/slave select
;; |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
;; +--------- Vblank NMI enable (0: off, 1: on)
;; Note:
;; According to the NESDEV wiki on PPU registers:
;; "Changing NMI enable from 0 to 1 while the vblank flag in PPUSTATUS is 1 will immediately trigger an NMI.
;; This happens during vblank if the PPUSTATUS register has not yet been read.
;; It can result in graphical glitches by making the NMI routine execute too late in vblank to finish on time,
;; or cause the game to handle more frames than have actually occurred. To avoid this problem, it is prudent
;; to read PPUSTATUS first to clear the vblank flag before enabling NMI in PPUCTRL."
  PPUCTRL   = $2000
  PPUCTRL_ENABLE_NMI = %10000000
  PPUCTRL_WRITE_VERTICAL = %00000100


;; PPUMASK: Rendering settings
;; 7  bit  0
;; ---- ----
;; BGRs bMmG
;; |||| ||||
;; |||| |||+- Greyscale (0: normal color, 1: greyscale)
;; |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
;; |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
;; |||| +---- 1: Enable background rendering
;; |||+------ 1: Enable sprite rendering
;; ||+------- Emphasize red (green on PAL/Dendy)
;; |+-------- Emphasize green (red on PAL/Dendy)
;; +--------- Emphasize blue
  PPUMASK   = $2001
  PPUMASK_GREYSCALE = %00000001
  PPUMASK_ENABLE_BACKGROUND_LEFTMOST = %00000010
  PPUMASK_ENABLE_SPRITES_LEFTMOST = %00000100
  PPUMASK_ENABLE_BACKGROUND = %00001000
  PPUMASK_ENABLE_SPRITES = %00010000

  PPUSTATUS = $2002
  OAMADDR   = $2003
  OAMDATA   = $2004

;; PPUSCROLL:
;; "The PPU scroll registers share internal state with the PPU address registers.
;;  Because of this, PPUSCROLL and the nametable bits in PPUCTRL should be
;;  written after any writes to PPUADDR."
;; Reading from PPUSTATUS needs to be used when using this register.
;; See PPUADDR.
  PPUSCROLL = $2005

;; PPUADDR:
;; "The 16-bit address is written to PPUADDR one byte at a time, high byte first.
;;  Whether this is the first or second write is tracked by the PPU's internal w register, which is shared with PPUSCROLL.
;;  If w is not 0 or its state is not known, it must be cleared by reading PPUSTATUS before writing the address."
  PPUADDR   = $2006

  PPUDATA   = $2007

  OAMDMA = $4014

  JOY1 = $4016

  ppumem_pallete = $3F00
