/*
	
	Handles the Bots
	
*/

#define swBotMethod$getPlay 1			//  | Causes the bot to send a play method.
										// Cards is an array of cards held
										// color_played might incorrectly be 0 at the start of turn, check if cards_played is 0 in that case
#define swBotMethod$setDifficulty 2		// (int)difficulty

#define swBot$getPlay(cards, color_played, cards_played, first_player, playerIndex) runMethod((str)LINK_THIS, "sw Bot", swBotMethod$getPlay, [mkarr(cards), color_played, cards_played, first_player, playerIndex], TNN)
#define swBot$setDifficulty(difficulty) runMethod((str)LINK_THIS, "sw Bot", swBotMethod$setDifficulty, [difficulty], TNN)

