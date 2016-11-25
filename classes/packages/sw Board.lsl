#define USE_EVENTS
#include "switch/_core.lsl"

list PRIM_SEATS = [0,0,0,0];            // Seat prims: [blue0, red0, blue1, red1]

#define PC_MIDDLE 0
integer PRIM_CENTER;                    // Card placer at the center
list PC_ORDER = [6,5,3,4];              // Highlighters: [blue0, red0, blue1, red1]

list PRIM_CARDS = [0,0,0,0];            // Card placers: [blue0, red0, blue1, red1]

#define BULB_FACE_LAMP 1
#define BULB_FACE_POLARITY 0
#define BULB_FACE_SCORE 5
list PRIM_BULBS = [0,0,0,0,0,0,0,0];    // Color bulbs: [bluer, blueg, blueb, bluep, redr, redg, redb, redp]

#define SCORE_FACES [5,0,4]
list PRIM_SCORE = [0,0];                // Score lamps: [blue, red]



#define replaceListEntry(input, replace, index) \
    llListReplaceList(input, replace, index, index)


// Vars
integer ROUND_COLOR = -1;        // Color for this round


onEvt(string script, integer evt, list data){
    
    if(script == "sw Game"){
        
        if(evt == swGameEvt$gameStart){
        
            llLinkParticleSystem(PRIM_CENTER, []);
        
        }
        
        if(evt == swGameEvt$gameEnd){
            
            vector color = <.5,.75,1>;
            if(l2i(data, 0))
                color = <1,.5,.5>;
                
            llTriggerSound("1f6a2ff2-0fd4-dc36-f5a7-bf86b572e527", 1);
                
            llLinkParticleSystem(PRIM_CENTER, [  
                PSYS_PART_FLAGS,
                    PSYS_PART_EMISSIVE_MASK|
                    PSYS_PART_INTERP_COLOR_MASK|
                    PSYS_PART_INTERP_SCALE_MASK|
                    PSYS_PART_BOUNCE_MASK|
                    //PSYS_PART_WIND_MASK|
                    //PSYS_PART_FOLLOW_SRC_MASK|
                    //PSYS_PART_TARGET_POS_MASK|
                    PSYS_PART_FOLLOW_VELOCITY_MASK
                    
                ,
                PSYS_PART_MAX_AGE, .2,
                
                PSYS_PART_START_COLOR, color,
                PSYS_PART_END_COLOR, color,
                
                PSYS_PART_START_SCALE,<.0,.0,0>,
                PSYS_PART_END_SCALE,<.5,.5,0>, 
                                
                PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                
                PSYS_SRC_BURST_RATE, 0.01,
                
                PSYS_SRC_ACCEL, <0,0,0.1>,
                
                PSYS_SRC_BURST_PART_COUNT, 2,
                
                PSYS_SRC_BURST_RADIUS, .5,
                
                PSYS_SRC_BURST_SPEED_MIN, 0.0,
                PSYS_SRC_BURST_SPEED_MAX, 0.01,
                
                //PSYS_SRC_TARGET_KEY,"",
                
                PSYS_SRC_ANGLE_BEGIN,   0.0, 
                PSYS_SRC_ANGLE_END,     0.0,
                
                PSYS_SRC_OMEGA, <0,0,0>,
                
                PSYS_SRC_MAX_AGE, 0,
                                
                PSYS_SRC_TEXTURE, "4fe2bc25-c239-1956-6391-12324609d4a2",
                
                PSYS_PART_START_ALPHA, 1,
                PSYS_PART_END_ALPHA, 1,
                
                PSYS_PART_START_GLOW, 0.5,
                PSYS_PART_END_GLOW, 0.1
                
            ]);
            
            multiTimer(["particles", "", 3, FALSE]);
            
        }
        
    }
    
    
}

timerEvent(string id, string data){
    
    if(id == "particles"){
        llLinkParticleSystem(PRIM_CENTER, []);
    }
    
}

default
{
    state_entry()
    {
        links_each(nr, name,
            
            list spl = explode(":", name);
            string label = l2s(spl, 0);
            
            if(label == "centerPiece")
                PRIM_CENTER = nr;
            
            else if(label == "CARD")
                PRIM_CARDS = replaceListEntry(PRIM_CARDS, [nr], l2i(spl,1));
            
            else if(label == "SEAT")
                PRIM_SEATS = replaceListEntry(PRIM_SEATS, [nr], l2i(spl,1));
            
            else if(label == "SCORE")
                PRIM_SCORE = replaceListEntry(PRIM_SCORE, [nr], l2i(spl, 1));
            
            else if(label == "BULB")
                PRIM_BULBS = replaceListEntry(PRIM_BULBS, [nr], l2i(spl,2)+(4*l2i(spl,1)));
            
            
        )
        
        llLinkParticleSystem(PRIM_CENTER, []);
        //onEvt("sw Game", swGameEvt$gameEnd, [0]);
        
        // Reset the lamps
        //setColorScore(DEFAULT_COLORSCORE, 0, -1)
        swBoard$colorScore(DEFAULT_COLORSCORE, DEFAULT_COLORSCORE);
        
        // Reset the cards
        swBoard$setCardsPlayed(
            0,0,0, 
            0,0,0,
            0,0,0,
            0,0,0
        );
        
        // Reset player turns
        swBoard$setPlayerTurn(-1, FALSE);
        
        // Reset the the round color
        swBoard$setRoundColor(-1);
        
        // reset the score counters
        swBoard$setScore(0,0);
        
        
        
    }
    
    timer(){multiTimer([]);}

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
        
    if(METHOD == swBoardMethod$setCardsPlayed){
        
        // Bitwise combination going from left to right
        integer active = l2i(PARAMS, 0);
        integer effects = l2i(PARAMS, 1);
        
        list out = [];
        
        integer i;
        for(i=0; i<4; i++){
            
            // Bitwise combination. 4 rightmost bits are the card ID, 3 to the left of that are deck ID
            integer cData = (active>>((3-i)*8))&255;
            
            integer cardPlayed = (cData&15)-1;
            integer deckPlayed = (cData&48)>>4;
            integer cardSpecial = ((effects>>((3-i)*8))&255)-1;
            
            
            out+= [PRIM_LINK_TARGET, l2i(PRIM_CARDS, i)];
            
            // qd("Player "+(str)i +" >> Card: "+(str)cardPlayed+" Deck: "+(str)deckPlayed+" Effect: "+(str)cardSpecials);
            if(~cardPlayed){
                
                integer offset = cardPlayed+(deckPlayed*12);
                integer y = llFloor(offset/TX_CARDS_X);
                integer x = offset-(y*TX_CARDS_X);
                out+= [PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0, PRIM_FULLBRIGHT, ALL_SIDES, FALSE];
                out+= [
                    PRIM_COLOR, CARD_FACE_MAIN, <1,1,1>*.5, 1,
                    PRIM_COLOR, CARD_FACE_BORDER, <1,1,1>*.5, 1
                ];
                
                if(ROUND_COLOR == deckPlayed || deckPlayed == DECK_PRISM)
                    out+= [
                        PRIM_FULLBRIGHT, ALL_SIDES, TRUE,
                        PRIM_COLOR, CARD_FACE_MAIN, <1,1,1>, 1,
                        PRIM_COLOR, CARD_FACE_BORDER, <1,1,1>, 1
                    ];
                
                out+= [
                    PRIM_TEXTURE, CARD_FACE_MAIN, TX_CARDS, 
                    <1, 1, 0>, 
                    <(float)x/TX_CARDS_X, -(float)y/(TX_CARDS_Y), 0>,
                    0
                ];
                
                if(~cardSpecial){
                    
                    float xscale = (float)TX_CARDS_X/TX_EFFECTS_X;
                    float yscale = (float)TX_CARDS_Y/TX_EFFECTS_Y;
                    out+= [
                        PRIM_TEXTURE, CARD_FACE_OVERLAY, TX_EFFECTS,
                        <xscale, yscale, 0>,
                        <(float)cardSpecial/TX_EFFECTS_X,.5,0>,                                       // This needs to be changed if TX_EFFECTS x/y changes
                        0,
                        
                        PRIM_COLOR, CARD_FACE_OVERLAY, <1,1,1>, 1
                    ];
                    
                }
                
            }
            else
                out+= [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0];
            
        }
        
        PP(0,out);
        
    }
    
    else if(METHOD == swBoardMethod$setPlayerTurn){
        
        integer player = l2i(PARAMS, 0);
        integer won = l2i(PARAMS, 1);
        
        list out = []; integer i;
        for(i=0; i<4; ++i){
            
            integer face = l2i(PC_ORDER, i);
            
            list l = [PRIM_COLOR, face, <.1,.1,.1>, 1, PRIM_FULLBRIGHT, face, FALSE, PRIM_GLOW, face, 0];
            if(player == i){
                
                vector color = <1,1,1>; float glow = 0.1;
                if(won == 1){
                    color = <1,1,0>;
                    glow = 0.3;
                }
                else if(won == -1){
                    color = <0,0,1>;
                    glow = 0.3;
                }
                    
                l = [PRIM_COLOR, face, color, 1, PRIM_FULLBRIGHT, face, TRUE, PRIM_GLOW, face, glow];
                
            }
            
            out+= l;
            
        }
        
        PP(PRIM_CENTER, out);
        
    }
    
    
    // Changes the color of the center piece
    else if(METHOD == swBoardMethod$setRoundColor){
        
        ROUND_COLOR = l2i(PARAMS, 0);
        
        list out = [PRIM_COLOR, PC_MIDDLE, <.1,.1,.1>, 1, PRIM_FULLBRIGHT, PC_MIDDLE, FALSE, PRIM_GLOW, PC_MIDDLE, 0];
        if(~ROUND_COLOR)
            out = [PRIM_COLOR, PC_MIDDLE, l2v(DECK_GLOWS, ROUND_COLOR), 1, PRIM_FULLBRIGHT, PC_MIDDLE, TRUE, PRIM_GLOW, PC_MIDDLE, 0.05];
        
        PP(PRIM_CENTER, out);
        
    }
    
    // Updates the primary scoreboard
    else if(METHOD == swBoardMethod$setScore){
        
        
        // PARAMS are [teamBlueScore, teamRedScore]
        integer i; integer lamp;
        list out;
        for(i=0; i<count(PARAMS); ++i){
            
            out+= [PRIM_LINK_TARGET, l2i(PRIM_SCORE,i)];
            vector color = l2v(TEAM_COLORS, i);
            
            integer sc = l2i(PARAMS, i);
            for(lamp = 0; lamp<3; ++lamp){
                
                integer face = l2i(SCORE_FACES, lamp);
                if(i)
                    face = l2i(SCORE_FACES, 2-lamp);
                
                
                list l = [PRIM_COLOR, face, <0.1,0.1,0.1>, 1, PRIM_FULLBRIGHT, face, FALSE, PRIM_GLOW, face, 0];
                if(sc > lamp)
                    l = [PRIM_COLOR, face, color, 1, PRIM_FULLBRIGHT, face, TRUE, PRIM_GLOW, face, 0.1];
                
                out+= l;
                
            }
            
        }
        
        PP(0, out);
        
    }
    
    // Updates the color scoreboard
    else if(METHOD == swBoardMethod$colorScore){
        
        integer blueScore = l2i(PARAMS, 0);
        integer redScore = l2i(PARAMS, 1);
       
        list out = [];
       
        integer i;
        for(i=0; i<4; ++i){
            
            // Red/blue
            list prims = [l2i(PRIM_BULBS, i), l2i(PRIM_BULBS, i+4)];
            
            list scores = [
                getColorScore(blueScore, i),
                getColorScore(redScore, i)
            ];
                        
            // Figure out the winning team of this color
            integer winningTeam = l2i(scores, 1) > l2i(scores, 0);
            if(l2i(scores, 1) == l2i(scores, 0))
                winningTeam = -1;
            
            integer team;
            for(team=0; team<2; ++team){
                
                // Set target prim
                out+= [PRIM_LINK_TARGET, l2i(prims, team)];
                            
                // Calculate if the bulb should be on or off
                integer score = l2i(scores, team);
                
                
                list bulb = [PRIM_COLOR, BULB_FACE_LAMP, l2v(DECK_GLOWS, i)*.8, 1, PRIM_FULLBRIGHT, BULB_FACE_LAMP, FALSE, PRIM_GLOW, BULB_FACE_LAMP, 0];
                if(team == winningTeam)
                    bulb = [PRIM_COLOR, BULB_FACE_LAMP, l2v(DECK_GLOWS, i), 1, PRIM_FULLBRIGHT, BULB_FACE_LAMP, TRUE, PRIM_GLOW, BULB_FACE_LAMP, .1];
                out+= bulb;
                
                // Put the score on the board
                integer y = llFloor(llFabs(score)/TX_NUMBERS_X);
                integer x = llAbs(score)-y*TX_NUMBERS_X;
                out+= [
                    PRIM_TEXTURE, BULB_FACE_SCORE, TX_NUMBERS,  
                    <1./TX_NUMBERS_X, 1./TX_NUMBERS_Y, 0>, 
                    <-1./TX_NUMBERS_X/2-1./TX_NUMBERS_X*TX_NUMBERS_X/2+1./TX_NUMBERS_X*x, 1./TX_NUMBERS_Y-1./TX_NUMBERS_Y*y, 0>, 
                    PI_BY_TWO
                ];
                
                // Colorize the score NUMBERS
                if(winningTeam == team)
                    out+= [PRIM_COLOR, BULB_FACE_SCORE, <.5,1,.5>, 1];
                else if(~winningTeam)
                    out+= [PRIM_COLOR, BULB_FACE_SCORE, <1,.5,.5>, 1];
                else
                    out+= [PRIM_COLOR, BULB_FACE_SCORE, <1,1,1>, 1];
                
                
                // Set the +- icons
                vector polarityPos = <1./TX_NUMBERS_X/2+1./TX_NUMBERS_X, 0,0>;
                vector polarityColor = <.5,1,.5>;
                if(score<0){
                    polarityPos.x += 1./TX_NUMBERS_X; 
                    polarityColor = <.5,.5,1>;
                }
                out+= [
                    PRIM_TEXTURE, BULB_FACE_POLARITY, TX_NUMBERS, 
                    <1./TX_NUMBERS_X, 1./TX_NUMBERS_Y,0>, 
                    polarityPos, 
                    PI_BY_TWO,
                    PRIM_COLOR, BULB_FACE_POLARITY, polarityColor, 1
                ];
                
                
            }
            
                
        }
        
        PP(0, out);
        
    }


    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
