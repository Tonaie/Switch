/*
	
	Handles the HUD
	
*/

#define swHUDMethod$setCards 1			// (arr)cards - Cards are a bitwise: 0000FX 00DeckNumber 0000CardNumber
#define swHUDMethod$setRoundColor 2		// (int)color - -1 to wipe
#define swHUDMethod$ping 3				// void - Ping a game HUD, callbacks true/false
#define swHUDMethod$setTurn 4			// void - Pings the player that it's their turn
#define swHUDMethod$setClothes 5		// (int)clothes - Sets clothing layers. 0 = dressed, 1 = underwear, 2 = nude
#define swHUDMethod$on 6				// void - Detaches the HUD when received, owner only
#define swHUDMethod$attachTo 7			// (key)id - Request to attach to this player

#define swHUD$setCards(targ, arr) runMethod((str)targ, "sw HUD", swHUDMethod$setCards, arr, TNN)
#define swHUD$setRoundColor(targ, color) runMethod((str)targ, "sw HUD", swHUDMethod$setRoundColor, [color], TNN)
#define swHUD$ping(targ) runMethod((str)targ, "sw HUD", swHUDMethod$ping, [], "PING")
#define swHUD$setTurn(targ) runMethod((str)targ, "sw HUD", swHUDMethod$setTurn, [], TNN)
#define swHUD$setClothes(targ, clothes) runMethod((str)targ, "sw HUD", swHUDMethod$setClothes, [clothes], TNN)
#define swHUD$on() runMethod(llGetOwner(), "sw HUD", swHUDMethod$on, [], TNN)
#define swHUD$attachTo(targ, player) runMethod((str)targ, "sw HUD", swHUDMethod$attachTo, [player], TNN)

