.bets_first_char
  equs "CTHEOBR",0

.bets_sections
  equw bet_c
  equw bet_t
  equw bet_h
  equw bet_e
  equw bet_o
  equw bet_b
  equw bet_r

.bets
  equs "0",0,    35
  equs "1",0,    35
  equs "2",0,    35
  equs "3",0,    35
  equs "4",0,    35
  equs "5",0,    35
  equs "6",0,    35
  equs "7",0,    35
  equs "8",0,    35
  equs "9",0,    35
  equs "10",0,   35
  equs "11",0,   35
  equs "12",0,   35
  equs "13",0,   35
  equs "14",0,   35
  equs "15",0,   35
  equs "16",0,   35
  equs "17",0,   35
  equs "18",0,   35
  equs "19",0,   35
  equs "20",0,   35
  equs "21",0,   35
  equs "22",0,   35
  equs "23",0,   35
  equs "24",0,   35
  equs "25",0,   35
  equs "26",0,   35
  equs "27",0,   35
  equs "28",0,   35
  equs "29",0,   35
  equs "30",0,   35
  equs "31",0,   35
  equs "32",0,   35
  equs "33",0,   35
  equs "34",0,   35
  equs "35",0,   35
  equs "36",0,   35
  equs "00",0,   35
.bet_c
  equs "C1",0,    2 ; 38 - Column 1
  equs "C2",0,    2 ; 39 - Column 2
  equs "C3",0,    2 ; 40 - Column 3
.bet_t
  equs "T1",0,    2 ; 41 - 1st twelve
  equs "T2",0,    2 ; 42 - 2nd twelve
  equs "T3",0,    2 ; 43 - 3rd twelve
.bet_h
  equs "H1",0,    1 ; 44 - H1
  equs "H2",0,    1 ; 45 - H2
.bet_e
  equs "E",0,     1 ; 46 - Even
.bet_o
  equs "O",0,     1 ; 47 - Odd
.bet_b
  equs "B",0,     1 ; 48 - Black
.bet_r
  equs "R",0,     1 ; 49 - Red
  equs 0


  ;  column twelve  half   O/E colour
.numbers                ; The number itself is the index
  equs 0,      0,       0,     0,    0,		  ; 0
  equs 38,     41,      44,    47,   49,		; 1
  equs 39,     41,      44,    46,   48,		; 2
  equs 40,     41,      44,    47,   49,		; 3
  equs 38,     41,      44,    46,   48,		; 4
  equs 39,     41,      44,    47,   49,		; 5
  equs 40,     41,      44,    46,   48,		; 6
  equs 38,     41,      44,    47,   49,		; 7
  equs 39,     41,      44,    46,   48,		; 8
  equs 40,     41,      44,    47,   49,		; 9
  equs 38,     41,      44,    46,   48,		; 10
  equs 39,     41,      44,    47,   48,		; 11
  equs 40,     41,      44,    46,   49,		; 12
  equs 38,     42,      44,    47,   48,		; 13
  equs 39,     42,      44,    46,   49,		; 14
  equs 40,     42,      44,    47,   48,		; 15
  equs 38,     42,      44,    46,   49,		; 16
  equs 39,     42,      44,    47,   48,		; 17
  equs 40,     42,      44,    46,   49,		; 18
  equs 38,     42,      45,    47,   49,		; 19
  equs 39,     42,      45,    46,   48,		; 20
  equs 40,     42,      45,    47,   49,		; 21
  equs 38,     42,      45,    46,   48,		; 22
  equs 39,     42,      45,    47,   49,		; 23
  equs 40,     42,      45,    46,   48,		; 24
  equs 38,     43,      45,    47,   49,		; 25
  equs 39,     43,      45,    46,   48,		; 26
  equs 40,     43,      45,    47,   49,		; 27
  equs 38,     43,      45,    46,   48,		; 28
  equs 39,     43,      45,    47,   48,		; 29
  equs 40,     43,      45,    46,   49,		; 30
  equs 38,     43,      45,    47,   48,		; 31
  equs 39,     43,      45,    46,   49,		; 32
  equs 40,     43,      45,    47,   48,		; 33
  equs 38,     43,      45,    46,   49,		; 34
  equs 39,     43,      45,    47,   48,		; 35
  equs 40,     43,      45,    46,   49,		; 36
  equs 0,      0,       0,     0,    0 		  ; 37 '00'

.table_layout
  equs "Table layout",10
  equs "(* = Red)",10
  equs "---------------",10
  equs " 1*    2     3*",10
  equs " 4     5*    6 ",10
  equs " 7*    8     9*",10
  equs "10    11    12*",10
  equs "---------------",10
  equs "13    14*   15 ",10
  equs "16*   17    18*",10
  equs "19*   20    21*",10
  equs "22    23*   24 ",10
  equs "---------------",10
  equs "25*   26    27*",10
  equs "28    29    30*",10
  equs "31    32*   33 ",10
  equs "34*   35    36*",10
  equs "---------------",10
  equs "    00    0    ",10,0


.bet_codes
  equs "35:1 bets:"
  equs "  Numbers 0-36, 00",10,10
  equs "2:1 bets:",10
  equs "  T1  1st twelve   T2  2nd twelve   T3  3rd twelve",10
  equs "  C1  Column 1     C2  Column 2     C3  Column 3",10,10
  equs "Even money:",10
  equs "  H1  1-18         H2  19-36",10
  equs "  E   Even         O   Odd",10
  equs "  B   Black        R   Red",10,10

.play_amount_msg
  equs "You have: ",0

.house_amount_msg
  equs "The house has: ",0

.instructions
  equs "At each turn, type a bet code and press <enter>.",10
  equs "Then type the amount you wish to bet, followed by <enter>.",10
  equs "Type I <enter> to view the bet codes again.",10,10,0

.place_bet_msg
  equs "Place your bet!",10,0

.bet_code_prompt
  equs "Bet code: ",0
.bet_amount_code
  equs "Amount: ",0
