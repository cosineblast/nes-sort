
  ;; vars_h.s 

  ;; this header file contains the manual location definition for 
  ;; all of our global variables and constants.
  ;; In the future, we might change this so that it uses 
  ;; compiler-defined variable allocation.

  ;; Start of 6502 stack
  stack_start = $0100

  ;; General Purpose zero page "registers", 8 in total

  ;; altough the $00 address is not used, a future implementation
  ;; might use $00-$07 instead of $01-$08 for the local registers
  LOCAL_REGISTER_COUNT = 8
  local0 = $01
  local1 = $02
  local2 = $03
  local3 = $04
  local4 = $05
  local5 = $06
  local6 = $07
  local7 = $08

  ;; The height (in tiles of a column that will be rendered).
  RENDER_COLUMN_HEIGHT = 26

  ;; The number of columns that will be 
  ;; computed/rendered in the entire simulation.
  COLUMNS_PER_SCREEN = 32

  ;; Array of 2*RENDER_COLUMN_HEIGHT (RCH, for short) bytes
  ;; containing the tiles for the two
  ;; columns that will be rendered on the next frame.
  ;; the first RCH elements represent the first column,
  ;; and the last RCH elements represent the second column.

  ;; this is stored in zero page because it is heavily accessed 
  ;; during vblank, in which we don't have a lot of cycles.
  ;; the address is $c3 = $ff - 60 for simplicity, but we could defined
  ;; it as $ff - 2 * RENDER_COLUMN_HEIGHT
  render_columns = $c3

  ;; bool, whether the program is currently runnning update code or not.
  ;; 0 if an update is not running (and it is ok for a render to run).
  ;; 1 if update code is/should be running (NMI code should rti immediately)
  is_updating = $0200

  ;; 0 when the program is doing the initial render of the tiles
  ;; 1 when the program is already rendering the algorithm steps
  ;; 2 when the program is done with the algorithm
  current_sorting_stage = $0201

  PROGRAM_STAGE_INIT = 0
  PROGRAM_STAGE_SORT = 1
  PROGRAM_STAGE_DONE = 2


  ;; The rng_seed for the random number generation
  ;; Two bytes
  rng_seed = $0202

  ;; The on-screen indexes of the columns that must be rendered
  ;; -1 means don't render anything
  ;; Two bytes, two numbers
  render_columns_positions = $0204

  NO_RENDER_COLUMN = $ff

  ;; Initial Stage Specific:

  ;; The index of the next two elements to process
  ;; One byte
  init_stage_index = $0206

  ;; The numbers to be sorted
  ;; 128 bytes
  sorting_array = $0300

  SORTING_DATA_SIZE = 127

  ;; Coroutine specific :
  coroutine_started = $0280
  coroutine_s_register = $0284
  coroutine_local0 = $0285 ; 8 bytes

  ;; entire page
  coroutine_stack_start = $0400


