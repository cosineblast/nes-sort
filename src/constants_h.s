
;; Start of 6502 stack
stack_start = $0100

;; altough the $00 address is not used, a future implementation
;; might use $00-$07 instead of $01-$08 for the local registers
LOCAL_REGISTER_COUNT = 8

;; The height (in tiles of a column that will be rendered).
RENDER_COLUMN_HEIGHT = 26

;; The number of columns that will be
;; computed/rendered in the entire simulation.
COLUMNS_PER_SCREEN = 32


PROGRAM_STAGE_INIT = 0
PROGRAM_STAGE_SORT = 1
PROGRAM_STAGE_DONE = 2

NO_RENDER_COLUMN = $ff

SORTING_DATA_SIZE = 127

;; joystick values

JOY_A = $80
JOY_B = $40
JOY_SELECT = $20
JOY_START = $10
JOY_UP = $08
JOY_DOWN = $04
JOY_LEFT = $02
JOY_RIGHT = $01
