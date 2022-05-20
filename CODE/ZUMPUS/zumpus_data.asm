; zumpus_data.asm

.connections
  ; Each entry ends with a null byte because that makes it four bytes per
  ; entry. When doing the lookup, we have to multiply by the number of bytes
  ; per entry, and multiplying by 4, using ASL, is easier than by 3.
  equs 1,4,7,0    ; 0
  equs 0,2,9,0    ; 1
  equs 1,3,12,0   ; 2
  equs 2,4,13,0   ; 3
  equs 3,0,5,0    ; 4
  equs 4,6,14,0   ; 5
  equs 5,7,16,0   ; 6
  equs 0,6,8,0    ; 7
  equs 7,9,17,0   ; 8
  equs 1,8,10,0   ; 9
  equs 9,11,18,0  ; 10
  equs 2,10,12,0  ; 11
  equs 11,13,19,0 ; 12
  equs 3,12,14,0  ; 13
  equs 5,13,15,0  ; 14
  equs 14,16,19,0 ; 15
  equs 6,15,17,0  ; 16
  equs 8,16,18,0  ; 17
  equs 10,17,19,0 ; 18
  equs 12,15,18,0 ; 19

;.room_lookup_table
;  equs " 1 2 3 4 5 6 7 8 91011121314151617181920",0

.start_msg
  equs "***************************",10
  equs "***   HUNT the ZUMPUS   ***",10
  equs "***************************",10,10
  equs "Version: 0.0.1", 10, 10
  equs "It is with a sense of dread that you realise the only people left in",10
  equs "the office tonight are you, your evil-smelling middle manager",10
  equs "Damian Zumpus and his two vile sales reps.",10,10
  equs "Also, you've only just got around to reading the memo about the", 10
  equs "lifts. Yes, they're still out of order. But now they don't have",10
  equs "doors and the lights are out in the lobbies. If you enter either",10
  equs "one ... well, you're on the 13th floor and that could be bad.",10,10
  equs "Zumpus is apparently in a bad mood, which has made him even more",10
  equs "odiferous than normal. And the sales reps are constantly muttering",10
  equs "about wanting to abduct you.",10,10
  equs "Luckily, you finally got around to modifying that staple gun. It's",10
  equs "powerful enough to fire through as many as five adjacent rooms.",10
  equs "And it stings enough to make the Zumpus want to go home.",10
  equs "But be careful - you have only five staples.",10,0

.instructions
  equs "At each turn, you can either move or fire a staple.",10
  equs "To move, type 'm' followed by the number of the room you want to",10
  equs "move into - eg:",10
  equs "   m 15",10
  equs "To shoot, type 's' followed by the number of the room you want to",10
  equs "shoot into and then the distance you want the staple to go in terms",10
  equs "of number of rooms (1-5) - eg",10
  equs "   s 15 3",10
  equs "Note that, after the first room, the staple will take a random",10
  equs "course and might even end up back in the room you're in - in",10
  equs "which case it's all over for you.",10,0

.init_msg
  equs "We need to initialise the random locations for you and the",10
  equs "threats. This means hitting the ENTER key at least six times",10
  equs "(maybe more).",10,0
.init_done_msg
  equs "Initialising completed. Well done!",10,0
.press_enter_msg
  equs "Hit the ENTER key to continue...",0

.staple_count_msg
  equs "You have ",0
.staple_count_msg_end
  equs " staples left",0
.staple_count_none_msg
  equs "Argh! You have no staples left. You're fired!",10,0

.connecting_rooms_msg
  equs "Connecting rooms are: ",0
.current_room_msg
  equs "You are in room ",0

.prompt_move_or_fire
  equs "Move or Shoot?",0
.prompt_which_room
  equs "Into which room?",0
.prompt_how_many_rooms
  equs "How many rooms should the staple traverse (1-5)",0

.zumpus_hit_msg
  equs "An anguished wail of pain and indignation means you scored a hit!",10
  equs "Zumpus is so humiliated, he's resigned. You win!",10,0
.zumpus_miss_msg
  equs "A faint snicker of contempt tells you the staple missed.",10,0
.zumpus_own_goal
  equs "Ouch! The staple came back and hit you!",10,0

.warning_zumpus_msg
  equs "Ugh! There's a stench of sweat, cheap cologne and failure.",10
  equs "Zumpus is near!",10,0
.warning_bat_msg
  equs "Can you hear that muttering sound?",10,0
.warning_pit_msg
  equs "It's chilly in here, and there's a sensation like sucking air.",10,0

; --- FOR DEBUGGING ONLY ---
.debug_heading
  equs "DEBUG:",10,"ZUMPUS_LOC:",0
.bat1_msg
  equs "BAT1_LOC  :",0
.bat2_msg
  equs "BAT2_LOC  :",0
.pit1_msg
  equs "PIT1_LOC  :",0
.pit2_msg
  equs "PIT2_LOC  :",0
