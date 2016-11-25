// Config
#define DISREGARD_TOKEN
#ifndef PC_SALT
#define PC_SALT 13268712
#endif

#define CONF_DEFAULT_NR_STRIP_CARDS 2

#define runOnPlayers(targ, code) {integer _i; for(_i=0; _i<count(PLAYERS); ++_i){string targ = l2s(PLAYERS, _i); code}}

#define TEAM_BLUE 0
#define TEAM_RED 1
#define TEAM_COLORS [<.5,.8,1>,<1,.5,.5>]

#define PLAYER_BLUE_A 0
#define PLAYER_BLUE_B 1
#define PLAYER_RED_A 2
#define PLAYER_RED_B 3

#define CARD_FACE_BORDER 1
#define CARD_FACE_MAIN 0
#define CARD_FACE_OVERLAY 2	// 4
// This one is a third optional overlay
//#define CARD_FACE_MAX 2

#define DECK_RED 0
#define DECK_GREEN 1
#define DECK_BLUE 2
#define DECK_PRISM 3

#define CARD_SWITCH 11

// Resources and textures
// Glows for each deck color
#define DECK_GLOWS [<1,.5,.5>,<.5,1,.5>,<.5,.6,1>,<1,1,1>]

// Num cards to be added to hand
#define NUM_CARDS 13
// Num cards in each color
#define CARDS_IN_DECK 12

#define TX_CARDS "651b579f-c239-835c-f05e-28625cc73107"
#define TX_CARDS_X 8
#define TX_CARDS_Y 6

#define TX_NUMBERS "c1ccd9c4-a596-4e44-3e80-3926b0fac6af"
#define TX_NUMBERS_X 8
#define TX_NUMBERS_Y 3
#define TX_NUMBERS_INDEX_PLUS 15
#define TX_NUMBERS_INDEX_MINUS 16

#define TX_EFFECTS "3b08b220-43b0-509a-4d63-0865a0c965d3"
#define TX_EFFECTS_X 8
#define TX_EFFECTS_Y 1


/* Card effects */
#define FX_STRIP 1



/* INT conversions */
#define DEFAULT_COLORSCORE 541200
#define getColorScore(score, index) (((score>>(5*(3-index)))&31)-16)
#define setColorScore(score, index, value) ((score&~(31<<(5*(3-index))))|((value+16)<<(5*(3-index))))



// Includes
#include "xobj_core/_ROOT.lsl"
#include "./classes/ROOT.lsl"
#include "./classes/sw Game.lsl"
#include "./classes/sw Board.lsl"
#include "./classes/sw HUD.lsl"
#include "./classes/sw Bot.lsl"
#include "./classes/sw RLV.lsl"

