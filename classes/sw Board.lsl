/*
	
	Handles the board visuals
	
*/


#define swBoardMethod$setCardsPlayed 1				// (int)cards_played, (int)specials - Both values are 8bit values
#define swBoardMethod$setPlayerTurn 2				// (int)player, (int)won - Sets current player, -1 to wipe. Won can be TRUE to highlight a winner
#define swBoardMethod$setRoundColor 3				// (int)color - Sets the color this round is played for. -1 to wipe
#define swBoardMethod$setScore 4					// (int)teamBlue, (int)teamRed - Updates the set score lamps
#define swBoardMethod$colorScore 5					// (int)teamBlueScore, (int)teamRedScore -  See sw Game for more info

// 
#define swBoard$setCardsPlayed(	\
	player0_card, player0_color, player0_special, \
	player1_card, player1_color, player1_special, \
	player2_card, player2_color, player2_special, \
	player3_card, player3_color, player3_special \
) runMethod((str)LINK_THIS, "sw Board", swBoardMethod$setCardsPlayed, [ \
	(((player0_color<<4)|player0_card) << 24) | \
	(((player1_color<<4)|player1_card) << 16) | \
	(((player2_color<<4)|player2_card) << 8) | \
	((player3_color<<4)|player3_card), \
	\
	((player0_special)<<24) | \
	((player1_special)<<16) | \
	((player2_special)<<8) | \
	(player3_special) \
], TNN)

#define swBoard$setCardsPlayedShort(played, specials) runMethod((str)LINK_THIS, "sw Board", swBoardMethod$setCardsPlayed, [played, specials], TNN)


#define swBoard$setPlayerTurn(player, won) runMethod((str)LINK_THIS, "sw Board", swBoardMethod$setPlayerTurn, [player, won], TNN)
#define swBoard$setRoundColor(color) runMethod((str)LINK_THIS, "sw Board", swBoardMethod$setRoundColor, [color], TNN)
#define swBoard$setScore(teamBlue, teamRed) runMethod((str)LINK_THIS, "sw Board", swBoardMethod$setScore, [teamBlue, teamRed], TNN)
#define swBoard$colorScore(teamBlue, teamRed) runMethod((str)LINK_THIS, "sw Board", swBoardMethod$colorScore, [teamBlue, teamRed], TNN)


