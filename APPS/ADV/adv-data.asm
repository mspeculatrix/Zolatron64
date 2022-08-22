; ------------------------------------------------------------------------------
; ----  CHARACTERS
; ------------------------------------------------------------------------------
.character_table
  equw char_hr_mgr

.char_hr_mgr
  ;   loc   short            desc
  ;         name
  equs 23,  "HR manager",0   "Bald and desperate looking...",0


; ------------------------------------------------------------------------------
; ----  LOCATIONS
; ------------------------------------------------------------------------------
.location_table
  equw loc_start                    ; 0

.loc_start
   ;    adjoining locs
   ; lateral adjoining locs   1=movement possible, 0=movement not possible
   ; vertical adjoining locs
   ; bits are: 0  N
   ;           1  NE
   ;           2  E
   ;           3  SE
   ;           4  S
   ;           5  SW
   ;           6  W
   ;           7  NW
   equb %10001000
   ; vertical adjoining locs
   ; bits are: 0
   ;           1
   ;           2
   ;           3
   ;           4
   ;           5
   ;           6  UP
   ;           7  DOWN

   equb %00000010
   equb
   ;    short description
   equs "Blah, blah, blah.",0
   ;    long description
   equs "Also, blah, blah, blah.",0


; ------------------------------------------------------------------------------
; ----  OBJECTS
; ------------------------------------------------------------------------------
.object_table
  equw obj_stapler

.obj_stapler
  ;    loc   movable  weight  short        desc
  ;                           name
  equs 25,   1,       3,      "stapler",0  "A stapler blah blah",0

; ------------------------------------------------------------------------------
; ----  GAME STATE
; ------------------------------------------------------------------------------
; This is the section of memory that gets saved when you use the SAVE command.
.gamestate

.current_level
  equb 0
.current_loc
  equb 0

.char_state
  equb 67           ; current location

.object_state
  equb 25           ; current location - 255=being carried
  equb 9            ; Bitwise flags for status: activated, expended

.loc_state
  ; One byte per location, with Bitwise flags
  ; bits are: 0  VISITED
  ;           1  ACTIVATED
  ;           2
  ;           3
  ;           4
  ;           5
  ;           6
  ;           7

.gamestate_end
