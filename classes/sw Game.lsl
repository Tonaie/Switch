/*
	
	Handles the actual gameplay
	
	NUMBERING GOES FROM LEFT TO RIGHT
	so for 8 bit blocks, 00000000(0) 0000000(1) 00000000(2) 00000000(3)
	
	Concepts:
	Cards played is a bitwise combination of 4x 8 bit integers, these 8 bit integers are split like follows:
	4 rightmost bits are the card played, 0-12. 0 is null. If above 0, subtract one and use that value for the card. 0-11
	2x bits left of above represent the color, between 0-3
	
	Specials is a bitwise combination of 4x 8 bit integers. The rightmost bit is if the card is a strip card or not.
	
	colorScoreRed and colorScoreBlue are 5-bit combinations of score values in each color, the first bit from the left is positive
	2 integers are used for quick comparisons ie: (scoreBlue&15)>(scoreRed&15)
	Polarities are 1 bit going from left to right where 8 is red, 4 green, 2 blue, 1 prism, ex: 0b0001 means prism is switched
	
*/



// Player card held is an array of 12x4 integers. These integers are either a bitwise combination describing the card (see below)
// or -1 if no card is bound on that slot
#define cardNumber(card) ((card&15)-1)
#define cardDeckNumber(card) ((card>>4)&3)
#define cardFX(card) ((card>>6)&15)
#define makeCard(card, deck, fx) ((fx<<6)|(deck<<4)|(card+1))




#define swGameMethod$ping 1				// void | Sent by the HUD on attach, should force trigger an swHUD$ping(lst);
#define swGameMethod$getAttachTarg 2	// void | Sent from a HUD on rez. triggers the swHUD$attachTo method to attach to a player
#define swGameMethod$playCard 10		// (int)card (should contain the full card bitwise). Callbacks TRUE/FALSE success
#define swGameMethod$setStripCards 11	// (int)nr | Sets how many strip cards should be in the game

#define swGameEvt$players 1				// (arr)players
#define swGameEvt$colorScore 2			// (int)blue, (int)red

#define swGameEvt$gameStart 10			// void
#define swGameEvt$gameEnd 11			// (int)winning_team
#define swGameEvt$setStart 12			// void
#define swGameEvt$setEnd 13				// (int)winning_team
#define swGameEvt$roundStart 14			// void
#define swGameEvt$roundEnd 15			// (int)playerIndex, (arr)fxs


#define swGame$ping(targ) runMethod((str)targ, "sw Game", swGameMethod$ping, [], TNN)
#define swGame$playCard(targ, card) runMethod((str)targ, "sw Game", swGameMethod$playCard, [card], "PLAY")
#define swGame$getAttachTarg(targ) runMethod((str)targ, "sw Game", swGameMethod$getAttachTarg, [], TNN)
#define swGame$setStripCards(nr) runMethod((str)LINK_ROOT, "sw Game", swGameMethod$setStripCards, [nr], TNN)
