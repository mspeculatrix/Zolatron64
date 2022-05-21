## ZUMPUS

A 6502 assembly version of the classic Hunt the Wumpus game, somewhat modified.

*** WORK IN PROGRESS ***

Instead of the nasty Wumpus beast, you have to contend with Zumpus, an evil-smelling and foul-tempered middle manager. Assisting him are two constantly muttering sales reps.

If you enter a room containing Zumpus (or he comes into your room), you're dead ... well, fired. Whenever Zumpus is in a room adjacent to yours, you can smell him.

If you enter a room containing a sales rep, he will grab you and transport you to another, randomly chosen room. The rep will then return to his original room. If a sales rep is in an adjoining room, you can hear him muttering.

There are also two bottomless pits (actually dangerously exposed lift shafts). Enter a room with one of those and ... well, I'm sure you can work that out. If a lift shaft is in an adjoining room, you can feel a chill and a rush of air.

You have one thing in your favour - a highly modified and very powerful stapler. It has a range of up to five rooms, and even at that limit will discomfort Zumpus enough that he will leave the building.

As is traditional with Hunt the Wumpus, there are 20 rooms. At the start of the game, you, Zumpus, the lift shafts and two sales reps are placed randomly in the rooms.

At each turn, you have the choice of either moving to an adjacent room or firing the stapler. In either case, you specify the number of the room you want to move or fire into.

In the case of firing the stapler, you also specify how many rooms (1-5) you want the staple to traverse. But beware! Once the staple has entered the room you specified, all subsequent rooms in its flight path are chosen at random. Although choosing a long range has a better chance of hitting Zumpus, it also increases the probability of it looping round into your room - at which point it's game over.

The commands are in the format:
* m <room_number>
* s <room_number> <range>

Eg,
m 11    - to move into room 11
s 8 3   - to shoot into room 8 with a range of 3 rooms

Also, Zumpus starts the game asleep in one of the rooms. Firing a staple might wake him up. Once he's awake he may start moving around, making your job of hunting him more difficult.

### Status

The description above is what I'm aiming for. Here's how far I've actually got.

* Created random number routine for placing elements in the room map, deciding the flight of the staple, the movement of Zumpus, etc.
* Created a routine for calculating which rooms are adjacent.
