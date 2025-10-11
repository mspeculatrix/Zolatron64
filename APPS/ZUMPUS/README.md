## ZUMPUS

A 6502 assembly version of the classic Hunt the Wumpus game, somewhat modified.

Instead of the nasty Wumpus beast, you have to contend with Zumpus, an evil-smelling and foul-tempered middle manager. Assisting him are two constantly muttering sales reps.

As with the original Wumpus, the game takes place in a network of 20 locations. Each room is linked to three other rooms. At each turn, you can choose to move into a room or shoot a staple from your specially modified, high-powered staple gun. This has a range of up to five rooms - you select how far it goes. You get to choose the first room, but after that it travels at random through subsequent rooms and can even come back to hit you.

If you enter a room containing Zumpus (or he comes into your room), you're dead ... well, fired. Whenever Zumpus is in a room adjacent to yours, you can smell him.

There are also two bottomless pits (actually dangerously exposed lift shafts). Enter a room with one of those and ... well, I'm sure you can work that out. If a lift shaft is in an adjoining room, you can feel a chill and a rush of air.

If you enter a room containing a sales rep, he will grab you and transport you to another, randomly chosen room. The rep will then return to his original location. The sales reps never carry you to a room containing Zumpus, one of the lift shafts or the other sales rep. If a sales rep is in an adjoining room, you can hear him muttering.

At the start of the game, you, Zumpus, the lift shafts and two sales reps are placed randomly in the rooms.

The game also begins with Zumpus sleeping. But every time you fire a staple, you run the risk of waking him. Once that has happened, he starts randomly wandering around the building.

The commands are in the format:

- m <room_number>
- s <room_number> <range>

Eg,
m 11 - to move into room 11
s 8 3 - to shoot into room 8 with a range of 3 rooms

### Status

Version 1.0.0 - 14/06/2022 - Completed.
