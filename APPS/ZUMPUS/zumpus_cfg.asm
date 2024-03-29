; CONSTANTS
NUM_ROOMS    = 20
NUM_STAPLES  = 5
NUM_LOCS     = 6                    ; Number of locations for characters in game

STATE_OK         = 0                ; State of player
STATE_KIDNAPPED  = 1
STATE_FALLEN     = 2
STATE_DEAD       = 3
STATE_NO_STAPLES = 4

SHOT_MISSED      = 0
SHOT_HIT         = 1
SHOT_SELF        = 2

YESNO_ERR        = 0
YESNO_NO         = 1
YESNO_YES        = 2

Z_STATE_ASLEEP   = 0
Z_STATE_AWAKE    = 1

; ADDRESSES
RANDOM_LOCS  = $0500                ; Start of block of 6 locations
PLAYER_LOC   = RANDOM_LOCS          ; 0500 Specific synonym for this location
ZUMPUS_LOC   = PLAYER_LOC + 1       ; 0501    "        "     "    "     "
BAT1_LOC     = ZUMPUS_LOC + 1       ; 0502    "        "     "    "     "
BAT2_LOC     = BAT1_LOC + 1         ; 0503    "        "     "    "     "
PIT1_LOC     = BAT2_LOC + 1         ; 0504    "        "     "    "     "
PIT2_LOC     = PIT1_LOC + 1         ; 0505    "        "     "    "     "
STAPLE_COUNT = PIT2_LOC + 1         ; 0506
P_CONN_ROOMS = STAPLE_COUNT + 1     ; 0507-0590
Z_CONN_ROOMS = P_CONN_ROOMS + 3     ; 050A-050C
R_CONN_ROOMS = Z_CONN_ROOMS + 3     ; 050D-050F
FLAGS        = R_CONN_ROOMS + 3     ; 0510
INPUT_NUM    = FLAGS + 1            ; 0511, 0512
ROOM_NUM     = INPUT_NUM + 1        ; 0513        For temp holding of a room num
P_CONDITION  = ROOM_NUM + 1         ; 0514        Player's condition
STAPLE_RANGE = P_CONDITION + 1      ; 0515
Z_STATE      = STAPLE_RANGE + 1     ; 0516        Zumpus awake or asleep

DATA_START   = $7000				; There will be 4 bytes of header
GAMES_PLAYED = DATA_START + 4		; 8-bit number
GAMES_WON    = GAMES_PLAYED + 1     ; 8-bit number
DATA_END     = GAMES_WON + 1        ; For null EOF marker
DATA_SIZE    = DATA_END - DATA_START

; ERROR CODES --- should be sequential, starting at 1 (0 means no error)
; Used for looking up error message in Error Message Table in zumpus_data.asm
ERR_OS_ERROR = 1
ERR_ROOM_NOT_REACHABLE = 2
ERR_SYNTAX = 3
ERR_RANGE = 4

; FLAGS
PIT_WARNING_ISSUED = %00000001
BAT_WARNING_ISSUED = %00000010
