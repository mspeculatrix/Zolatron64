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

.current_state
  equs STATE_OK         ; 0
  equs STATE_KIDNAPPED  ; 1
  equs STATE_DEAD       ; 2

.breakline
  equs "-----",10,0

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
  equs "course and might even end up back in the room you're in -",10
  equs "in which case it's all over for you.",10,10
  equs "You can also type:",10
  equs "  I - to see these instructions again",10
  equs "  Q - to quit",10,0

.start_msg
  equs "***************************",10
  equs "***   HUNT the ZUMPUS   ***",10
  equs "***************************",10,10
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


.init_msg
  equs "We need to initialise the random locations for you and the",10
  equs "threats. This means hitting the ENTER key at least six times",10
  equs "(probably more).",10,0
.init_done_msg
  equs "Initialising completed. Well done!",10,0
.press_enter_msg
  equs "Hit the ENTER key to continue...",0

.staple_count_msg
  equs "Staples left: ",0
.connecting_rooms_msg
  equs "Connecting rooms are: ",0
.current_room_msg
  equs "You are in room ",0

.zumpus_prompt
  equs "Move or Shoot? ",0
.instr_prompt
  equs "Do you want instructions (Y for Yes, anything else for No)? ",0
.go_again_msg
  equs "Another game (Y/n)? ",0

.you_are_dead
  equs "ARGH!! The Zumpus has found you! It's been nice knowing you...",10,0
.you_have_fallen
  equs "OOOOOOOoooooo........ Down the lift shaft you go. Sorry!",10,0
.you_are_kidnapped
  equs "Oh-oh! You're suddenly in the presence of one of the sales reps.",10
  equs "He grabs you and hustles you to another room. But eventually a life",10
  equs "of bad food and cheap drinks means he becomes exhausted and scuttles",10
  equs "back, wheezing, to his cubicle.",10,0
.you_have_no_staples
  equs "Alas, you are out of staples. It's now only a matter of time before",10
  equs "Zumpus gets you. So long old friend...",10,0

;.shot_msg_table
;  equw zumpus_miss_msg
;  equw zumpus_hit_msg
;  equw zumpus_own_goal
.shot_miss_msg
  equs "A distant snicker of contempt tells you the staple missed.",10,0
.shot_hit_msg
  equs "WELL DONE!",10
  equs "An anguished wail of pain and indignation means you scored a hit!",10
  equs "Zumpus flees the building. You win!",10,0
.shot_nearhit_msg
  equs "Ooo! So close! Zumpus managed to dodge the staple.",10,0
.shot_self_msg
  equs "Ouch! The staple came back and hit you!",10,0
.shot_nearself_msg
  equs "Phew! That was close. The staple came back and nearly hit you!",10,0

.warning_zumpus_msg
  equs "Ugh! There's a stench of sweat, cheap cologne and failure.",10
  equs "Beware, Zumpus is near!",10,0
.warning_bat_msg
  equs "Can you hear that muttering sound?",10,0
.warning_pit_msg
  equs "It's chilly in here, and there's a sensation like sucking air.",10,0

.zumpus_awakes_msg
  equs "A snort, a fart and a bellow from somewhere in the bowels of the",10
  equs "building suggest that Zumpus has awoken.",10
  equs "He will now ramble at random around the building.",10
  equs "You have been warned...",10,0

\ ---  ERRORS  -----------------------------------------------------------------
.err_input
  equs "Huh? I didn't understand that...",10,0
.err_invalid_room
  equs "You can't get there from here.",10,0

; ERROR MESSAGE TABLE
.error_msg_ptrs
  equw err_os_err
  equw err_rm_not_reachable
  equw err_syntax
  equw err_range

.err_os_err
  equs "I had a problem with that. Try again...",10,0
.err_rm_not_reachable
  equs "You can't get to that room from here.",10,0
.err_syntax
  equs "That didn't make any sense to me.",10,0
.err_range
  equs "Your range is 1-5 with these staples.",10,0

