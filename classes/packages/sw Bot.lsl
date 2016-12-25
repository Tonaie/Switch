#define USE_EVENTS
#include "switch/_core.lsl"

integer COLOR_SCORE_BLUE = DEFAULT_COLORSCORE;
integer COLOR_SCORE_RED = DEFAULT_COLORSCORE;

integer DIFFICULTY = 1;

onEvt(string script, integer evt, list data){
    
    if(script == "sw Game"){
        
        if(evt == swGameEvt$gameStart){
            
            COLOR_SCORE_BLUE = DEFAULT_COLORSCORE;
            COLOR_SCORE_RED = DEFAULT_COLORSCORE;
            
        }
        
        else if(evt == swGameEvt$colorScore){
            
            COLOR_SCORE_BLUE = l2i(data, 0);
            COLOR_SCORE_RED = l2i(data, 1);
            
            //qd("\n == ROUND ==");
            
        }
        
        
    }
    
}

list reverse(list input){
    list output;
    integer i;
    for(i=0; i<count(input); ++i){
        output = llList2List(input, i, i)+output;
    }
    return output;
}


// Returns the highest value non switch card or 0 if doesn't exist
integer getHighestNonSwitchCard(list cards){
    
    integer highest;
    
    integer i;
    for(i=0; i<count(cards); ++i){
        
        integer c = l2i(cards, i);
        integer v = cardNumber(c);
        
        if(v == CARD_SWITCH)
            return highest;
        
        highest = c;
        
    }
    
    return highest;
    
}

// between 0->23 where 0 = switch, 11 = 10 in suit, 12 = prism switch, 13 = prism 10
integer getCardScore(integer card){
    
    integer cValue = cardNumber(card);
    if(cValue == CARD_SWITCH)
        cValue-= CARDS_IN_DECK;
    if(cardDeckNumber(card) == DECK_PRISM)
        cValue+= CARDS_IN_DECK;
    return cValue+1;
    
}


// Returns a list of cards of a specified color
list getDeckByColor(list deck, integer color){
    
    if(color == -1)
        return deck;
    
    list out;
    
    list_shift_each(deck, card,
        if(cardDeckNumber((integer)card) == color && (integer)card != -1){
            out+= (integer)card;
        }
    )
    
    return out;
    
}

integer scoreDifference(integer color, integer isRed){
    
    list scores = [getColorScore(COLOR_SCORE_BLUE, color), getColorScore(COLOR_SCORE_RED, color)];
    return l2i(scores, isRed)-l2i(scores, !isRed);
    
}

timerEvent(string id, string data){
    
    if(id == "PLAY")
        swGame$playCard(LINK_THIS, (int)data);
    
}

list COLORS = ["RED", "GREEN", "BLUE", "PRISM"];

#define reason(text) 
//#define reason(text) qd("Player ["+(str)player_index+"]: "+text+" ["+l2s(COLORS, cardDeckNumber(play))+" "+(str)cardNumber(play)+"]")

default
{
    state_entry()
    {
    }

    timer(){
        multiTimer([]);
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
        return;
    }
    
    // Only allow internal code
    if(!(method$internal))
        return;
    
    if(METHOD == swBotMethod$getPlay){
        
        integer i;
        
        
        list cards = reverse(llJson2List(method_arg(0)));    // 8-bit Card flags
        integer roundcolor = l2i(PARAMS, 1);        // -1 to 3, -1 means you go first
        integer cards_played = l2i(PARAMS, 2);      // Cards played so far this round
        integer first_player = l2i(PARAMS, 3);      // Player who went first 0-3
        integer player_index = l2i(PARAMS, 4);      // index of the bot, 0-3
        
        if(cards_played == 0)
            roundcolor = -1;
        
        integer team = player_index%2;
        
        
        list cp_data;               // Data about cards played so far this round
        list viable;                // Cards in my hand that can actually be played. 
                                    // Selected card HAS to be in this list
        list in_suit;               // Cards held in suit
        list prismatics;            // Prismatic cards
        integer isSwitched;         // If the board currently is switched
        integer highestCard = -1;   // Card that is currently the highest
        integer highestTeam = -1;   // Team owning the highest card
        integer play = -1;               // Card we want to play
        integer has_card_color;     // Has a card of round color
        list score_offsets;         // Scoring offsets compared to the other team
        integer leadingOnBoard;     // Nr color points we are ahead, can be negative
                
        
        // Calculate score offsets
        for(i=0; i<4; ++i){
            
            integer dif = scoreDifference(i, team);
            
            integer n = dif>0;
            
            if(dif<0)
                n = -n;
            
            if(i == 3)
                n*= 2;
                
            leadingOnBoard += n;
            score_offsets += dif;
            
        }
        
        // Get the cards played so far in a list from first card to last card
        integer n = first_player;
        
        for(i=0; i<4; ++i){
            
            integer cdata = (cards_played>>(8*(3-n)))&255; // 8bit
            
            integer cValue = getCardScore(cdata);
            
            if(cardNumber(cdata) == CARD_SWITCH)
                isSwitched = !isSwitched;

            if(cdata > 0)
                cp_data += cdata;       // Add to the list of played cards
            else
                i = 100;                // Break
            
            if(cValue > getCardScore(highestCard) || highestCard == -1){
                /*
                if(highestCard != -1)
                    qd("Highest card is now "+l2s(COLORS, cardDeckNumber(cdata))+" "+(str)cardNumber(cdata)+" because it beats "+l2s(COLORS, cardDeckNumber(highestCard))+" "+(str)cardNumber(highestCard)+". Player is "+(str)n+" who belongs to team "+(str)(n%2));
                */
                highestCard = cdata;
                highestTeam = n%2;
                
            }
            
            if(++n>3)
                n = 0;
                
            
        }
        
        
        has_card_color = count(getDeckByColor(cards, roundcolor));
        
        // Get cards that can actually be played
        for(i=0; i<count(cards); ++i){
            
            integer card = l2i(cards, i);
            integer cc = cardDeckNumber(card);
            
            if(card != -1 && cc == roundcolor)
                in_suit += card;
            if(card != -1 && cc == DECK_PRISM)
                prismatics += card;
            
            if(
                card != -1 &&           // Card exists AND
                (
                    !cards_played ||            // This is the first turn of the round OR
                    cc == DECK_PRISM ||         // Card is a trump card
                    !has_card_color ||          // Does not have a card in suit
                    cc == roundcolor
                )
            ){
                
                viable += card;
                
            }
            
        }
        // Give normal bots a 20% chance of a misplay
        if(DIFFICULTY > 0 && (DIFFICULTY == 2 || llFrand(1) < 0.8)){
            // We go first
            if(roundcolor == -1 && (DIFFICULTY >= 2 || llFrand(1)<.5)){
                
                integer highest = getHighestNonSwitchCard(prismatics);      // Highest value prismatic
                
                if(
                    // only 3 points in prism can be won, do not play prism first if it can't win
                    llAbs(l2i(score_offsets, DECK_PRISM)) < 1 && 
                    // Attempt to snipe the prismatic here
                    (cardNumber(highest) > 6 || count(prismatics) == 1)
                ){
                    
                    play = highest;
                    reason("1st: Trying to snipe a color");
                    
                }
                
                else{
                    
                    // Find a regular color to play
                    list scoreSort;
                    for(i=0; i<count(score_offsets); ++i)
                        scoreSort += [l2i(score_offsets, i), i];
                    
                    // The lowest scoring color is now first, highest scoring is on top
                    scoreSort = llListSort(scoreSort, 2, TRUE);
                    
                    // Currently leading, consider blocking by playing a heavy losing one or heavy winning one
                    if(leadingOnBoard > 0){
                        
                        list ss = llListSort(scoreSort, 2, FALSE);
                        for(i=0; i<count(ss) && play == 0; i+=2){
                            
                            list select = getDeckByColor(cards, l2i(ss, i+1));
                            if(llAbs(l2i(ss, i)) > 1 && select != []){
                                
                                // Prefer a non switch card
                                integer highest = getHighestNonSwitchCard(select);
                                // If highest is pretty low, allow switches
                                if(highest < 4)
                                    highest = l2i(select, -1);
                                
                                play = highest;
                                reason("1st: Trying to block");
                                
                            }
                            
                        }
                        
                    }
                    
                    // Try to snipe the easiest color if we can't block
                    if(play == -1){
                        
                        // As close to 0 as possible
                        integer closest = -1;
                        list lowest;
                        for(i=0; i<count(scoreSort); i+=2){
                            
                            integer d = l2i(scoreSort, i+1);            // Deck
                            list select = getDeckByColor(cards, d);
                            
                            integer val = llAbs(l2i(scoreSort, i));     // Score offset
                            
                            if((closest == -1 || val <= closest) && select != [] && d != DECK_PRISM && l2i(scoreSort, i)<1){
                                
                                if(val < closest){
                                    lowest = [];
                                    closest = val;
                                }
                                
                                lowest+= d;
                                
                            }
                            
                        }
                        
                        if(lowest){
                            
                            // Pick the suit to play
                            integer el = (int)randElem(lowest);
                            // Find some cards int he deck
                            list select = getDeckByColor(cards, el);
                            // Prefer a non switch card
                            
                            integer highest = getHighestNonSwitchCard(select);
                            // If highest is pretty low, allow a switch if exists
                            if(highest < 4)
                                highest = l2i(select, -1);
                                
                            play = highest;
                            reason("1st: Trying to block low. Cards in suit: "+mkarr(select)+" ");
                            
                        }
                        
                        
                    }
                    
                    // If nothing else works, just play the highest card you have
                    if(play == -1){
                        
                        integer highest;
                        for(i=0; i<count(cards) && play == -1; ++i){
                            
                            integer c = l2i(cards, i);
                            integer v = cardNumber(i);
                            if(v != CARD_SWITCH && v > highest){
                                
                                highest = v;
                                play = c;
                                reason("1st: Playing the highest card");
                                
                            }
                            
                            
                        }
                        
                    }
                    
                }
            }
            
            // We are not going first, try to find a winning card
            else{
                
                    
                integer offset = llAbs(l2i(score_offsets, roundcolor));
                list inSuit = getDeckByColor(cards, roundcolor);
                
                
                // Try to switch if possible, allow prism switch if you're the last player
                if(isSwitched && highestTeam == team){
                        
                    // Switch is always last
                    integer c = l2i(inSuit, -1);
                    if(cardNumber(c) == CARD_SWITCH){
                        
                        play = c;
                        reason("Switching because we're leading and the board is switched");
                        
                    }
                    
                    c = l2i(prismatics, -1);
                    if(play == -1 && cardNumber(c) == CARD_SWITCH && count(cp_data) >= 3){
                        
                        play = c;
                        reason("Using prismatic switch to unswitch and win");
                        
                    }
                        
                }
                    
                // Try to switch if possible, allow prism switch only if the leading card is prismatic
                if(play == -1 && !isSwitched && highestTeam != team){
                    
                    // Switch is always last
                    integer c = l2i(inSuit, -1);
                    if(cardNumber(c) == CARD_SWITCH){
                        
                        play = c;
                        reason("Playing switch to undo a losing round. Pre SWITCHED was "+(str)isSwitched+" and us winning prior to switch was "+(str)(highestTeam == team));
                        
                    }
                    
                    c = l2i(prismatics, -1);
                    if(play == -1 && cardNumber(c) == CARD_SWITCH && cardDeckNumber(highestCard) == DECK_PRISM){
                        
                        play = c;
                        reason("Playing prismatic switch to undo a losing round. SWITCHED was: "+(str)isSwitched+". Highest card deck is Prism (ACTUALLY "+l2s(COLORS, cardDeckNumber(highestCard))+")");
                        
                    }
                        
                }
                
                if(inSuit){
                    
                    // Play the lowest card in hand if switched or we're already winning. Switch dynamic is handled above
                    if(play == -1 && (
                        isSwitched || 
                        (!isSwitched && highestTeam == team && llFrand(1)<.75)
                    )){
                        
                        for(i=0; i<count(viable) && play == -1; ++i){
                            integer c = l2i(viable, 0);
                            if(cardNumber(c) != CARD_SWITCH){
                                play = c;
                            }
                        }
                        
                        reason("Playing the lowest card in my hand because of switch or we're already winning. Card ID: "+(str)play+" HighestTeam: "+(str)highestTeam+" switch: "+(str)isSwitched+" switch in hand was "+(str)(cardNumber(l2i(inSuit, -1)) == CARD_SWITCH));
                        
                    }
                    
                    // Play the lowest winning card of suit if it will win
                    for(i=0; i<count(inSuit) && play == -1; ++i){
                        
                        if(getCardScore(l2i(inSuit, i)) > getCardScore(highestCard)){
                            
                            play = l2i(inSuit, i);
                            reason("Playing the  highest default card in my hand because it will win (Highest is "+llList2String(COLORS, cardDeckNumber(highestCard))+" "+(str)cardNumber(highestCard)+"). Switch was "+(str)isSwitched);
                            
                        }
                        
                    }
                    
                }
                
                // Play a trump card if it will win and isn't a switch
                if(!isSwitched){
                    for(i=0; i<count(prismatics) && play == -1; ++i){
                            
                        if(getCardScore(l2i(prismatics, i)) > getCardScore(highestCard) && cardNumber(l2i(prismatics, i)) != CARD_SWITCH){
                            
                            play = l2i(prismatics, i);
                            reason("Playing a trump card to win");
                            
                        }
                            
                    }
                }
                        
                // Play the lowest viable non-switch
                if(play == -1){
                    
                    integer l = -1;
                    integer lp;
                    for(i=0; i<count(viable); ++i){
                        
                        integer c = l2i(viable, i);
                        integer score = getCardScore(c);
                        if((score<l || l == -1) && cardNumber(c) != CARD_SWITCH){
                            
                            l = score;
                            lp = c;
                            
                        }
                        
                    }
                    
                    if(lp != 0){
                        play = lp;
                        reason("Playing the lowest viable card because I have nothing better. Card played: "+(str)play+" ");
                    }
                    //
                    
                }
                    
                            
            }
        }
        
        // Pick a card at random, since heuristics failed
        if(play <= 0){
            
            play = (int)randElem(viable);
            reason("Heuristics failed:");
            /*
            reason("cp_data: "+mkarr(cp_data));
            reason("in_suit: "+mkarr(in_suit));
            reason("prismatics: "+mkarr(prismatics));
            reason("isSwitched: "+(str)isSwitched);
            reason("highestCard: "+(str)highestCard);
            reason("highestTeam: "+(str)highestTeam);
            reason("has_card_color: "+(str)has_card_color);
            reason("score_offsets: "+mkarr(score_offsets));
            reason("leadingOnBoard: "+(str)leadingOnBoard);
            */
        }
        
		if(play == 0){
			qd("Bot play failed. Held cards were: "+mkarr(cards));
			qd("Viable: "+mkarr(viable));
		}
        
        multiTimer(["PLAY", play, .5, FALSE]);
        

        
        //qd("Playing card:deck "+(str)cardNumber(play)+":"+(str)cardDeckNumber(play));
        
    }
	
	else if(METHOD == swBotMethod$setDifficulty){
		DIFFICULTY = l2i(PARAMS, 0);
	}
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
