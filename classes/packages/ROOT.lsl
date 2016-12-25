// First off you need to define that this script is the root script
#define SCRIPT_IS_ROOT
//#define USE_EVENTS
#include "switch/_core.lsl"

/*
list PLAYERS;

onEvt(string script, integer evt, list data){
    
    if(script == "sw Game" && evt == swGameEvt$players){
        
        PLAYERS = data;
        
    }
    
}
*/

list PLAYERS;
list PRIMS_SEATS = [0,0,0,0];

integer USE_VIBRATOR = TRUE;
integer NR_STRIP_CARDS = CONF_DEFAULT_NR_STRIP_CARDS;
integer BOT_DIFFICULTY = 1;

rebuildPlayers(){
    PLAYERS = [];
    integer i;
    for(i=0; i<count(PRIMS_SEATS); ++i){
        
        key t = llAvatarOnLinkSitTarget(l2i(PRIMS_SEATS, i));
        if(t)
            PLAYERS+=t;
        
    }
}


integer DIALOG_CHAN;
integer MENU;
#define MENU_DEFAULT 0
#define MENU_STRIP_CARDS 1
#define MENU_BOT_DIFFICULTY 2

list BOT_DIFFICULTIES = ["Dumb", "Average", "Expert"];

dialog(integer menu, key id){
    MENU = menu;
    
    string text = "Welcome to Switch!\nSettings:\n\n👙 "+(str)NR_STRIP_CARDS+"x Strip cards\n💓 Vibrator is ";
    if(USE_VIBRATOR)
        text+= "ON";
    else
        text+= "OFF";
    text+= "\n💻 Bot Skill: "+l2s(BOT_DIFFICULTIES, BOT_DIFFICULTY);
    
    list buttons = [
        "💓 Vibrator",
        "👙 Strip Cards",
        "💻 Bot Skill"
    ];
    
    if(menu == MENU_STRIP_CARDS){
        
        text = "How many strip cards should be generated at the start of each set? 0 Turns off strip cards.\n\nCurrent strip cards: "+(str)NR_STRIP_CARDS;
        buttons = ["◀ Back", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
        
    }
    
    else if(menu == MENU_BOT_DIFFICULTY){
        
        text = "Bot difficulty:\n\nCurrently: "+l2s(BOT_DIFFICULTIES, BOT_DIFFICULTY);
        buttons = ["◀ Back"]+BOT_DIFFICULTIES;
        
    }
    
    llDialog(id, text, buttons, DIALOG_CHAN);
    
}

default 
{
    // Initialize on attach
    on_rez(integer bap){
        
        raiseEvent(evt$SCRIPT_INIT, "");
            
    }
    
    // Start up the script
    state_entry()
    {

        // Reset all other scripts
        resetAllOthers();
        
        // Start listening
        initiateListen();
        
        DIALOG_CHAN = llCeil(llFrand(0xFFFFFFF));
        llListen(DIALOG_CHAN, "", "", "");
        
        links_each(nr, name,
            
            list exp = explode(":", name);
            if(l2s(exp, 0) == "SEAT"){
                
                integer n = l2i(exp, 1);
                PRIMS_SEATS = llListReplaceList(PRIMS_SEATS, [nr], n, n);
                
            }

        )
        
        rebuildPlayers();
 
    }
    
    // Timer event
    //timer(){multiTimer([]);}
    
    changed(integer change){
        
        if(change&CHANGED_OWNER){
            llResetScript();
        }
        
        if(change&CHANGED_LINK){
            rebuildPlayers();
        }
        
    }
    
    touch_start(integer total){
        
        key id = llDetectedKey(0);
        
        if(id != llGetOwner() && llListFindList(PLAYERS, [id] )== -1)\
            return;
        
        if(llGetLinkName(llDetectedLinkNumber(0)) == "SETTINGS"){
            dialog(0, llDetectedKey(0));
        }
        
        list data = [llDetectedLinkNumber(0), id];
        raiseEvent(evt$TOUCH_START, mkarr(data));
        
    }
    
    // This is the listener
    #define LISTEN_LIMIT_FREETEXT \
    if(llGetOwnerKey(id) != llGetOwner() && ~llListFindList(PLAYERS, [(string)llGetOwnerKey(id)] )== -1)\
        return; \
    if(chan == DIALOG_CHAN){ \
        if(MENU == MENU_STRIP_CARDS){ \
            if(message == "◀ Back") \
                return dialog(MENU_DEFAULT, id); \
            NR_STRIP_CARDS = (integer)message; \
            swGame$setStripCards(NR_STRIP_CARDS); \
            runOnPlayers(targ,llRegionSayTo(targ, 0, "The next set will have "+(str)NR_STRIP_CARDS+" strip cards.");) \
            dialog(MENU_STRIP_CARDS, id); \
        }\
        else if(MENU == MENU_BOT_DIFFICULTY){ \
            if(message == "◀ Back") \
                return dialog(MENU_DEFAULT, id); \
            BOT_DIFFICULTY = llListFindList(BOT_DIFFICULTIES, [message]); \
            if(BOT_DIFFICULTY<0)BOT_DIFFICULTY = 0;\
            swBot$setDifficulty(BOT_DIFFICULTY); \
			runOnPlayers(targ,llRegionSayTo(targ, 0, "Bot difficulty is now "+(str)l2s(BOT_DIFFICULTIES, BOT_DIFFICULTY));) \
            dialog(MENU_BOT_DIFFICULTY, id); \
        } \
        else if(MENU == MENU_DEFAULT){ \
            if(message == "💓 Vibrator"){ \
                USE_VIBRATOR = !USE_VIBRATOR; \
                swRLV$toggleVibrator(USE_VIBRATOR); \
                string text = "Vibration feature is now "; \
                if(USE_VIBRATOR)text+= "ON"; \
                else text+= "OFF"; \
                runOnPlayers(targ,llRegionSayTo(targ, 0, text);) \
                dialog(MENU_DEFAULT, id); \
            } \
            else if(message == "👙 Strip Cards") \
                dialog(MENU_STRIP_CARDS, id); \
            else if(message == "💻 Bot Skill") \
                dialog(MENU_BOT_DIFFICULTY, id); \
        } \
        return; \
    }
        
    #include "xobj_core/_LISTEN.lsl"
    
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

    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
