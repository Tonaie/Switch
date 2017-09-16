#define USE_EVENTS
#include "switch/_core.lsl"

#define BFL_GAME_STARTED 0x1
integer BFL;


integer NUM_STRIP_CARDS = CONF_DEFAULT_NR_STRIP_CARDS;

// Should be keys
list PLAYERS = [FALSE,FALSE,FALSE,FALSE];
list PRIMS_SEATS = [0,0,0,0];
list HUDQUEUE = [];          // Players that need HUDs

#define removeFromHudQueue(uuid) \
integer pos = llListFindList(HUDQUEUE, [(key)uuid]); \
if(~pos)HUDQUEUE = llDeleteSubList(HUDQUEUE, pos, pos);

list PLAY_ORDER;
integer FIRST_TURN = -1;    // Player who played the first turn this round
integer TURN = -1;          // Updated at the end of each ROUND
integer TURN_POINTER;       // Updated at the start of each SET

integer CARDS_PLAYED;       // 8bit integers with 00Deck, 0000number
integer CARDS_PLAYED_FX;    // 8 bit integers with the special tied to a card if any



integer COLOR_SCORE_BLUE = DEFAULT_COLORSCORE;   // colorScoreRed and colorScoreBlue are 5-bit combinations of score values in each color
integer COLOR_SCORE_RED = DEFAULT_COLORSCORE;    // First bit 1 means it's positive. When GETTing, it subtracts 16, when SETTING it adds 16

// Use the cardNumber, cardDeckNumber, cardFX macros from sw Game.lsl
// 13 cards per player (NUM_CARDS)
// Other than -1, these are UNIQUE IDs
list PLAYER_CARDS = [
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
];

// SET color scores
// 4 bit ints, only 16 bits are needed, made for easy comparisons
integer GAME_SCORE_RED;          
integer GAME_SCORE_BLUE;

// Macros
// Updates the Board with cards played
#define refreshCardsPlayed() swBoard$setCardsPlayedShort(CARDS_PLAYED, CARDS_PLAYED_FX)
// Updates the board with player turn
#define refreshTurn(turn, won) swBoard$setPlayerTurn(turn, won)
#define refreshGameScore() swBoard$setScore(GAME_SCORE_BLUE, GAME_SCORE_RED)
#define refreshColorScore() swBoard$colorScore(COLOR_SCORE_BLUE, COLOR_SCORE_RED) 

#define getPlayerCardsByIndex(index) llList2List(PLAYER_CARDS, NUM_CARDS*index, NUM_CARDS*index+NUM_CARDS-1)

#define COLOR_PLAYED ((CARDS_PLAYED>>(8*(3-FIRST_TURN)+4))&3)

// Requests a bot play if the current turn is a bot
#define getBotPlay() if(llGetListEntryType(PLAYERS, TURN) == TYPE_INTEGER && BFL&BFL_GAME_STARTED)swBot$getPlay(llList2List(PLAYER_CARDS, TURN*NUM_CARDS, TURN*NUM_CARDS+NUM_CARDS-1), COLOR_PLAYED, CARDS_PLAYED, FIRST_TURN, TURN); else swHUD$setTurn(l2s(PLAYERS, TURN))



onCardPlayed(integer card){
    
	if(~BFL&BFL_GAME_STARTED)
		return;
	
    integer isFirst = CARDS_PLAYED == 0;
    
    list cards = getPlayerCardsByIndex(TURN);
    integer pos = llListFindList(cards, [card]);
    cards = llListReplaceList(cards, [-1], pos, pos);
    PLAYER_CARDS = llListReplaceList(PLAYER_CARDS, cards, NUM_CARDS*TURN, NUM_CARDS*TURN+NUM_CARDS-1);
    
    // Add to cards played
    integer fx = cardFX(card);
    
    // Card data that should be stuck into the played integer are the 6 rightmost
    integer cdata = card & 63;
    
    integer cnr = cardNumber(cdata);
    integer color = cardDeckNumber(cdata);
    
    CARDS_PLAYED = CARDS_PLAYED|(cdata<<(8*(3-TURN)));
    
    // Card is prism or follows suit
    integer suitValid = (color == COLOR_PLAYED || color == DECK_PRISM);
    
    if(fx && suitValid){
        CARDS_PLAYED_FX = CARDS_PLAYED_FX|(fx<<(8*(3-TURN)));
        llTriggerSound("a9f1f07b-82a0-4b8b-6a23-acb9882cd378", .5);
    }
    // First card in a round
    if(isFirst){

        swBoard$setRoundColor(color);
        
        integer i;
        for(i=0; i<count(PLAYERS); ++i){
            
            if(llGetListEntryType(PLAYERS, i) != TYPE_INTEGER)
                swHUD$setRoundColor(l2s(PLAYERS, i), color);
        
        }
        
    }
    
    if(llGetListEntryType(PLAYERS, TURN) != TYPE_INTEGER)
        swHUD$setCards(l2s(PLAYERS, TURN), getPlayerCardsByIndex(TURN));
    
    // Switch sound
    if(cardNumber(cdata) == CARD_SWITCH && suitValid)
        llTriggerSound("357e4256-53a9-59e9-ed9b-0859b154bd88", 1);
    else
        llTriggerSound("647e68ee-be35-f542-1263-5c51adb037c1", 1);
    
    
    // Advance turn
    ++TURN;
    if(TURN >= count(PLAYERS))
        TURN = 0;
    
    // We have looped around, handle end of turn
    if(TURN == FIRST_TURN){
        TURN = -1;
    }
	
    refreshTurn(TURN, FALSE);
    refreshCardsPlayed();
    
    // We've reached end of turn, calculate round end
    if(TURN == -1)
        return multiTimer(["ROUND_END", "", 1, FALSE]);
    
    // Autoplays if the player is a bot
    getBotPlay();
    
}

onRoundStart(integer turn){
    
	TURN = turn;
    FIRST_TURN = TURN;
    
    // Reset cards played
    CARDS_PLAYED = 0;
    CARDS_PLAYED_FX = 0;
    refreshCardsPlayed();
    
    // Reset round color
    swBoard$setRoundColor(-1);
    
    // Generate the play order based on turn
    PLAY_ORDER = [0,1,2,3];
    if(TURN)
        PLAY_ORDER = llList2List(PLAY_ORDER, TURN, -1)+llList2List(PLAY_ORDER, 0, TURN-1);
    
    runOnPlayers(targ,
        swHUD$setRoundColor(targ, -1);
    )
    
    refreshTurn(TURN, FALSE);
    
    // If this player is a bot, request a play
    getBotPlay();
    
    raiseEvent(swGameEvt$roundStart, "");
    
}

onRoundEnd(){
    
    integer cc = COLOR_PLAYED;

    // Calculate the winner
    integer HIGHEST_PLAYER;
	integer LOWEST_PLAYER = -1;
	integer LOWEST_VALUE = CARDS_IN_DECK*2+1;
    integer HIGHEST_VALUE = -1;     // Start at -1 because red switch is 0
    integer i;
    
    list fxs = [];
    
    integer switches;
    
    for(i=0; i<4; ++i){
        
        
        integer card = (CARDS_PLAYED>>(8*(3-i)))&255;
        integer nr = cardNumber(card);
        integer deck = cardDeckNumber(card);
        
		// in suit or prism
        if(deck == DECK_PRISM || deck == cc){
        
			// Vib effects and stuff
            integer fx = (CARDS_PLAYED_FX>>(8*(3-i)))&255;
            if(fx)
                fxs += fx;
            
			// nr+1 because switch card is last and needs to be put first
            integer value = nr+1;
            if(nr == CARD_SWITCH){
                value = 0;
                switches++;
            }
               
			// Add deck size if prismatic to make it on top
            if(deck == DECK_PRISM)
                value += CARDS_IN_DECK;
            
            if(value > HIGHEST_VALUE){
                
                HIGHEST_VALUE = value;
                HIGHEST_PLAYER = i;
                
            }
			
			// Lowest non switch card
			if(value < LOWEST_VALUE && value != 0 && value != CARDS_IN_DECK){
			
				LOWEST_VALUE = value;
				LOWEST_PLAYER = i;
			
			}
            
        }
    }
    
    integer teamwin = HIGHEST_PLAYER%2;
	integer WINNING_PLAYER = HIGHEST_PLAYER;
    
	// Pick the lowest card
	if(switches%2){
		
		// In a game with only switches, the first player wins
		if(LOWEST_PLAYER == -1)
			LOWEST_PLAYER = FIRST_TURN;
			
		teamwin = LOWEST_PLAYER%2;
		WINNING_PLAYER = LOWEST_PLAYER;
		
	}
	
    list scores = [COLOR_SCORE_BLUE, COLOR_SCORE_RED];
    
    integer n = getColorScore(l2i(scores, teamwin), cc)+1;
    
    // Red wins
    if(teamwin)
        COLOR_SCORE_RED = setColorScore(COLOR_SCORE_RED, cc, n);
    else
        COLOR_SCORE_BLUE = setColorScore(COLOR_SCORE_BLUE, cc, n);
    
    refreshColorScore();
    raiseEvent(swGameEvt$colorScore, mkarr(([COLOR_SCORE_BLUE, COLOR_SCORE_RED])));
    
    refreshTurn(WINNING_PLAYER, TRUE);
    
    list out = [WINNING_PLAYER, mkarr(fxs)];
    raiseEvent(swGameEvt$roundEnd, mkarr(out));
    
    for(i=0; i<NUM_CARDS; ++i){
        
        if(llList2Integer(PLAYER_CARDS, i) != -1){
            
            multiTimer(["ROUND_START", (str)WINNING_PLAYER, 2, FALSE]);
            return;
            
        }
        
    }
    
    // All cards have been played
    multiTimer(["SET_END", "", 2, FALSE]);
    
    
    
}

onSetStart(){
    
    llTriggerSound("ecf779e1-5d87-eca9-20ad-40cad773f317", 1);
    
    // Reset set score
    COLOR_SCORE_BLUE =  DEFAULT_COLORSCORE;
    COLOR_SCORE_RED  = DEFAULT_COLORSCORE;
    
    refreshColorScore();
    
    // Select who should go first this set
    if(++TURN_POINTER > 3)
        TURN_POINTER = 0;
    TURN = TURN_POINTER;
    refreshTurn(TURN, FALSE);                  // Updates turn for the set
    
    // Start by evenly distributing the prismatics
    list prism;
    integer i;
    for(i=0; i<CARDS_IN_DECK; ++i)
        prism+= makeCard(i, DECK_PRISM, 0);
    
    // Shuffle
    prism = llListRandomize(prism, 1);
    
    // All the other decks
    list tri = [];
    for(i=0; i<3; ++i){
        
        integer card;
        for(card=0; card<CARDS_IN_DECK; ++card){
            
            tri+= makeCard(card, i, 0);
            
        }
        
        // Add an extra switch card
        tri+= makeCard(11, i, 0);
        
    }
    
    // Since trump only has 1 extra card, we also need to add a third switch to a primary color
    tri+= makeCard(11, llFloor(llFrand(3)), 0);
    
    
    tri = llListRandomize(tri, 1);

    // Hand out the cards
    for(i=0; i<count(PLAYERS); ++i){
        
        list cards = [];
        

        // Add prismatic cards
        cards = llList2List(prism, 0, 2);       // Prismatics need to be split evenly
        prism = llDeleteSubList(prism, 0, 2);

        // All other cards are random
        integer n = NUM_CARDS-count(cards);        // Nr of cards we should pull
        
        cards+= llList2List(tri, 0, n-1);
        tri = llDeleteSubList(tri, 0, n-1);
        
        cards = llListSort(cards, 1, FALSE);
        
        PLAYER_CARDS = llListReplaceList(PLAYER_CARDS, cards, i*NUM_CARDS, i*NUM_CARDS+count(cards)-1);
        
    }
    
    // add strip and FX cards
    // Builds a list of all card indexes and randomizes it
    list fxorder;
    for(i=0; i<count(PLAYER_CARDS); ++i)
        fxorder+= i;
    fxorder = llListRandomize(fxorder, 1);
    
    // Nr of strip cards to put in the deck
    integer nsc = NUM_STRIP_CARDS;
    while(nsc-- > 0){
        integer n = llList2Integer(fxorder, 0);
        fxorder = llDeleteSubList(fxorder, 0, 0);
        integer c = llList2Integer(PLAYER_CARDS,n)|(FX_STRIP<<6);
        PLAYER_CARDS = llListReplaceList(PLAYER_CARDS, [c], n, n);
    }
    fxorder = [];
    
    
    
    // Output to players
    for(i=0; i<count(PLAYERS); ++i){
        // Don't send to bots
        if(llGetListEntryType(PLAYERS, i) != TYPE_INTEGER){
            
            swHUD$setCards(l2s(PLAYERS, i), getPlayerCardsByIndex(i));
            
        }
    }
    
    raiseEvent(swGameEvt$setStart, "");
    
    onRoundStart(TURN);
    
    
}

onSetEnd(){
    
    
    
    llTriggerSound("60598949-ffad-fb93-71d5-f13b83bab4e5", 1);   
 
    integer blueScore;
    integer redScore;
    
    integer i;
    for(i=0; i<4; ++i){
        
        integer b = getColorScore(COLOR_SCORE_BLUE, i);
        integer r = getColorScore(COLOR_SCORE_RED, i);
        
        
        integer v = 1;
        if(i == DECK_PRISM)v = 2;
        
        if(b>r)blueScore+=v;
        else if(r>b)redScore+=v;
        
    }
    
    string text = "This set is a tie";
    if(blueScore>redScore){
        text = "Blue wins this set!";
        ++GAME_SCORE_BLUE;
    }
    else if(redScore>blueScore){
        text = "Red wins this set!"; 
        ++GAME_SCORE_RED;
    }
    
    refreshGameScore();
    
    if(GAME_SCORE_BLUE > 2 || GAME_SCORE_RED > 2){
        
        text = "RED Wins!";
        if(GAME_SCORE_BLUE > GAME_SCORE_RED)
            text = "Blue wins!";
        
        
        multiTimer(["GAME_END", "", 2, FALSE]);
        
    }
    else
        multiTimer(["SET_START", "", 2, FALSE]);
        
    runOnPlayers(targ,
        if((int)targ != -1)
            llRegionSayTo(targ, 0, text);
    )
        
    integer teamWins = redScore>blueScore;
    if(redScore == blueScore)
        teamWins = -1;
    raiseEvent(swGameEvt$setEnd, (str)teamWins);    
    
}


onGameStart(){
    
    raiseEvent(swGameEvt$gameStart, "");
    
    BFL = BFL|BFL_GAME_STARTED;
    
    // Reset game score
    GAME_SCORE_BLUE = 0;
    GAME_SCORE_RED = 0;
    TURN_POINTER = -1;
    refreshGameScore();
    
    
    
    integer numBots;
    integer i;
    for(i=0; i<count(PLAYERS); ++i){
        numBots+=(llGetListEntryType(PLAYERS, i) == TYPE_INTEGER);
    }
    
    runOnPlayers(targ,
        if((int)targ != -1)
            llRegionSayTo(targ, 0, "Starting game with "+(str)numBots+" bots!");
    )
    
    onSetStart();
    
}

onGameEnd(integer team_wins){
    
	// Wipe all timers
	multiTimer(["ROUND_END"]);
	multiTimer(["ROUND_START"]);
	multiTimer(["SET_END"]);
	multiTimer(["SET_START"]);
	multiTimer(["GAME_START"]);
	multiTimer(["GAME_END"]);
	
	
    raiseEvent(swGameEvt$gameEnd, (str)team_wins);
    BFL = BFL&~BFL_GAME_STARTED;
    
    
}


// Finds seated players
calculateSeats(){
    
    integer playersExist;
    
    list out;
    
    integer i; integer change; integer playIfBot;
    for(i=0; i<count(PRIMS_SEATS); ++i){
        
        integer isInt = (llGetListEntryType(PLAYERS, i) == TYPE_INTEGER);
        key lst = llAvatarOnLinkSitTarget(l2i(PRIMS_SEATS, i));
        integer isSitting = (lst != NULL_KEY);
        
        playersExist+=isSitting;
        
        if((isInt && isSitting) || (!isSitting && !isInt)){
            
            change = TRUE;
            
            string text = llGetDisplayName(l2s(PLAYERS, i))+" will be replaced by a bot.";
            
            list v = [FALSE];
            if(isSitting)
                v = [lst];
                
            PLAYERS = llListReplaceList(PLAYERS, v, i, i);
            
            
            if(isSitting){
                
                HUDQUEUE += lst;
                llRequestPermissions(lst, PERMISSION_TRIGGER_ANIMATION);
                multiTimer(["Q:"+(str)lst, "", 3, FALSE]);                  // Query for HUD
                swHUD$ping(lst);
                text = llGetDisplayName(lst)+" has joined the game.";
                
            }
            else{
                
                removeFromHudQueue(lst);
                multiTimer(["Q:"+(str)lst]);                  // Player unsat, stop query
                
                // Trigger the play if bot
                if(i == TURN)
                    playIfBot = TRUE;
                
            }
            
            out+= text;
            
        }
        
    }
    
    list_shift_each(out, text,
            
        runOnPlayers(targ, llRegionSayTo(targ, 0, text);)
            
    )
    
    if(change){
        
        raiseEvent(swGameEvt$players, mkarr(PLAYERS));
        
        // Mid-game changes
        if(BFL&BFL_GAME_STARTED){
        
            if(!playersExist){
                llWhisper(0, "Game has ended due to lack of players.");
                return onGameEnd(-1);
            }
        
            if(playIfBot){
                getBotPlay();
            }
            
        }
    }
    
    
    
}


timerEvent(string id, string data){
    
    list exp = explode(":", id);
    
    // Query for HUD timed out
    if(l2s(exp, 0) == "Q"){
        
        llRezAtRoot("Switch HUD", llGetPos()-<0,0,1>, ZERO_VECTOR, ZERO_ROTATION, 1);
        
    }
    
    // Trigger end of round
    else if(id == "ROUND_END")
        onRoundEnd();
    
    else if(id == "ROUND_START"){
        onRoundStart((int)data);
	}
    
    else if(id == "SET_END")
        onSetEnd();
    
    else if(id == "SET_START")
        onSetStart();
    
    else if(id == "GAME_END")
        onGameEnd(GAME_SCORE_RED > GAME_SCORE_BLUE);
    
}


onEvt(string script, integer evt, list data){
    
    if(evt == evt$TOUCH_START){
        
        string n = llGetLinkName(l2i(data, 0));
        key toucher = l2s(data, 1);
        
        if(n == "START" && ~BFL&BFL_GAME_STARTED && ~llListFindList(PLAYERS, [toucher])){
            
            onGameStart();
            
        }
        
    }
    
}



    

integer hasCardOfColor(integer playerIndex, integer color){
    
    list deck = getPlayerCardsByIndex(playerIndex);
    list_shift_each(deck, card,
        if(cardDeckNumber((integer)card) == color && (int)card != -1)
            return TRUE;
    )
    return FALSE;
    
}

default
{
    state_entry()
    {
        
        // Resets
        refreshCardsPlayed();
        refreshTurn(-1, FALSE);
        
        links_each(nr, name,
            
            list exp = explode(":", name);
            if(l2s(exp, 0) == "SEAT"){
                
                integer n = l2i(exp, 1);
                PRIMS_SEATS = llListReplaceList(PRIMS_SEATS, [nr], n, n);
                llLinkSitTarget(nr, <.1,0,.4>, llEuler2Rot(<0,0,PI>));
                
            }
            else 
                llLinkSitTarget(nr, ZERO_VECTOR, ZERO_ROTATION);
        
        )
        
        calculateSeats();
        
    }
    
    timer(){multiTimer([]);}
    
    changed(integer change){
        
        if(change&CHANGED_LINK){
            
            calculateSeats();
            
        }
        
    }
    
    run_time_permissions(integer perm){
        
        if(perm&PERMISSION_TRIGGER_ANIMATION)
            llStartAnimation("sit_1");
        
    }

    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        INDEX - (int)obj_index
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        
        if(METHOD == swHUDMethod$ping && SENDER_SCRIPT == "sw HUD" && CB == "PING"){
            
            // Remove the HUD detection timer
            multiTimer(["Q:"+(str)llGetOwnerKey(id)]);
            removeFromHudQueue(llGetOwnerKey(id));
            
            // pos is generated by the removeFromHudQueue macro
            pos = llListFindList(PLAYERS, [llGetOwnerKey(id)]);
            
            if(BFL&BFL_GAME_STARTED && ~pos){
                swHUD$setCards(l2s(PLAYERS, pos), getPlayerCardsByIndex(pos));
                swHUD$setRoundColor(l2s(PLAYERS, pos), COLOR_PLAYED);
            }
        }
        
        return;
    }
    
    if(METHOD == swGameMethod$playCard){
        
        // Ignore it if no turn is set
        if(TURN == -1)
            return;
        
        CB_DATA = [0];
        integer card = l2i(PARAMS, 0);
        
        // Make sure it's our turn
        if(
            (id == "" && llGetListEntryType(PLAYERS, TURN) == TYPE_INTEGER) ||
            (llGetOwnerKey(id) == l2k(PLAYERS, TURN))
        ){
            
            // Make sure we hold the card
            list deck = getPlayerCardsByIndex(TURN);
            if(~llListFindList(deck, [card]) && card != -1){
                
                // Make sure it was a valid card to play
                if(
                    !hasCardOfColor(
                        TURN, 
                        COLOR_PLAYED
                    ) ||      // Either you have no color of the turn
                    COLOR_PLAYED == cardDeckNumber(card) ||     // Or the color matched        
                    CARDS_PLAYED == 0 ||                        // Or this was the first card played this turn
                    cardDeckNumber(card) == DECK_PRISM          // Or this was a prismatic card
                ){
                    
                    CB_DATA = [1];
                    onCardPlayed(card);
                    
                }
                else 
                    CB_DATA += "Invalid card";
                
            }
            else
                CB_DATA += "Card not held";
            
        }
        else 
            CB_DATA+= "Not your turn";
        
        if(id == "" && !l2i(CB_DATA, 0)){
            qd("Invalid bot play: "+(str)card+" "+l2s(CB_DATA, 1));
        }
    }
    
    
    if(METHOD == swGameMethod$ping){
        
        if(~llListFindList(PLAYERS, [llGetOwnerKey(id)])){
            swHUD$ping(id);
        }
        
    }
    
    if(METHOD == swGameMethod$getAttachTarg && method$byOwner){
        
        swHUD$attachTo(id, l2k(HUDQUEUE, 0));
        HUDQUEUE = llDeleteSubList(HUDQUEUE, 0, 0);
        
    }
    
    if(METHOD == swGameMethod$setStripCards){
        NUM_STRIP_CARDS = l2i(PARAMS, 0);
    }
    
    
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
