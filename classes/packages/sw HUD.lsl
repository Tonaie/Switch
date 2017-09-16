// First off you need to define that this script is the root script
#define SCRIPT_IS_ROOT
#include "switch/_core.lsl"

list PRIM_CARDS = [0,0,0,0,0,0,0,0,0,0,0,0,0];

// Cards held
list CARDS = [];
integer ROUND_COLOR = -1;
#define TABLE prRoot(llGetOwner())


integer BFL;
#define BFL_IN_GAME 0x1

// This draws the cards on your HUD
drawCards(){
    
    list out;
    integer i;
    for(i=0; i<NUM_CARDS; ++i){
            
        out+= [PRIM_LINK_TARGET, l2i(PRIM_CARDS, i)];
            
        integer card = l2i(CARDS, i);
            
        // No card here
        if(i>=count(CARDS))
            out+= [PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0];
                
        // Here we have a card
        else{
                
            integer nr = cardNumber(card);
            integer deck = cardDeckNumber(card);
            integer fx = cardFX(card)-1;            // -1 is used for the visual which starts at 0, whereas fx starts at 1
            
            //qd((str)i+" card: "+(str)card+" NR: "+(str)nr+" deck: "+(str)deck+" fx: "+(str)fx);
                
            integer offset = nr+(deck*12);

            integer y = llFloor(offset/TX_CARDS_X);
            integer x = offset-(y*TX_CARDS_X);
            
            
            out+= [PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0];
            out+= [PRIM_COLOR, CARD_FACE_MAIN, <1,1,1>, 1];
            
            out+= [
                PRIM_TEXTURE, CARD_FACE_MAIN, TX_CARDS, 
                <1, 1, 0>, 
                <(float)x/TX_CARDS_X, -(float)y/TX_CARDS_Y, 0>,
                0
            ];
            
            // Calculate the border
            list border = [ZERO_VECTOR, .5];
            if(deck == 3 || ROUND_COLOR == deck || ROUND_COLOR == -1 || !hasCardFromDeck(ROUND_COLOR)){
                
                border = [<1,1,1>,1];
                
            }
            /*
            else if(deck != 3 && ROUND_COLOR != deck && ROUND_COLOR != -1){
                qd("CARDS: "+mkarr(CARDS));
                qd("Has cards from deck: "+(str)ROUND_COLOR+" "+(str)hasCardFromDeck(ROUND_COLOR, TRUE));
            }
            */
            
            out+= [PRIM_COLOR, CARD_FACE_BORDER]+border;
                
            if(~fx){
                
                float xscale = (float)TX_CARDS_X/TX_EFFECTS_X;
                float yscale = (float)TX_CARDS_Y/TX_EFFECTS_Y;
                out+= [
                    PRIM_TEXTURE, CARD_FACE_OVERLAY, TX_EFFECTS,
                    <xscale, yscale, 0>,
                    <(float)fx/TX_EFFECTS_X,.5,0>,                                       // This needs to be changed if TX_EFFECTS x/y changes
                    0,
                        
                    PRIM_COLOR, CARD_FACE_OVERLAY, <1,1,1>, 1
                ];
                    
            }
                
        }
            
    }
        
    PP(0, out);
    
}

// Returns if player has a card from the played deck
integer hasCardFromDeck(integer deck){ // , integer debug
    
    integer i;
    for(i=0; i<count(CARDS); ++i){
        
        if(cardDeckNumber(l2i(CARDS, i)) == deck){
            //if(debug)qd(l2s(CARDS, i)+" is in deck "+(str)deck);
            return TRUE;
        }
        
    }
    
    return FALSE;
}


timerEvent(string id, string data){
    
    // Seat check
    if(id == "SC"){
        
        if(~llGetAgentInfo(llGetOwner())&AGENT_SITTING && BFL&BFL_IN_GAME){
            
            BFL = BFL&~BFL_IN_GAME;
            swHUD$setCards(LINK_THIS, []);
            
        }
    }
    
}


integer DIALOG_CHAN;
loadDialog(){
    
    list buttons = [
        "❔Help",
        "👙 JasX HUD"
    ];
            
    llDialog(llGetOwner(), "🐼 Welcome to Switch! 🐼\n\n⚠️ NEW RULES in v0.2, see HELP.\n☝️ First time playing? Hit HELP.\n🔒 RLV Stripping? Get a JasX HUD!", buttons, DIALOG_CHAN);
    
}

default 
{

    on_rez(integer blap){
        
        if(blap)
            llSetLinkPrimitiveParams(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
        
        llResetScript();
        
    }

    // Start up the script
    state_entry()
    {

        // Reset all other scripts
        resetAllOthers();
        
        // Start listening
        initiateListen();

        DIALOG_CHAN = llFloor(llFrand(0xFFFFFF));
        llListen(DIALOG_CHAN, "", llGetOwner(), "");

        list out = [];
        
        links_each(nr, name,
            
            list ex = explode(":", name);
            string label = l2s(ex, 0);
            
            if(label == "CARD")
                PRIM_CARDS = llListReplaceList(PRIM_CARDS, [nr], l2i(ex,1), l2i(ex,1));
        )
        
        integer i;
        for(i=0; i<count(PRIM_CARDS); ++i){
            
            integer nr = l2i(PRIM_CARDS, i);
            out+= [PRIM_LINK_TARGET, nr, PRIM_SIZE, <0.11, 0.15, 0.02000>];
            out+= [PRIM_POSITION, -<i*.05, .07+0.07*i, 0>];

        }
        
        PP(0,out);
        
        swHUD$setCards(LINK_THIS, []);
        
        
        // Player has worn it
        if(llGetAttached()){
            
            multiTimer(["SC", "", 1, TRUE]);
            // Ping if we're sitting on something
            swGame$ping(TABLE);
            swHUD$on();
            loadDialog();
            
        }
        
        else{
            
            // Tell the table we have been rezzed
            swGame$getAttachTarg(mySpawner());
            
        }
        
        
        
    }
    
    // Timer event
    timer(){multiTimer([]);}
    
    
    attach(key id){
        
        if(id)
            llResetScript();
        
    }
    
    
    touch_start(integer total){
        detOwnerCheck
        
        list splice = explode(":", llGetLinkName(llDetectedLinkNumber(0)));
        
        if(l2s(splice, 0) == "CARD"){
            
            // Send to TABLE
            swGame$playCard(TABLE, l2i(CARDS, l2i(splice,1)));
            

        }
        
        else if(llDetectedLinkNumber(0) == 1){
            
            loadDialog();
            
        }
        
        
    }
    
    run_time_permissions(integer perm){
        
        if(~perm&PERMISSION_ATTACH)
            return;
            
        integer pre = llGetAttached();
        if(pre)
            llDetachFromAvatar();
        else
            llAttachToAvatarTemp(0);
            
                
    }
    
    // This is the listener
    #define LISTEN_LIMIT_FREETEXT \
    if(llGetOwnerKey(id) != llGetOwner() && id != TABLE){\
        return; \
    } \
    if(chan == DIALOG_CHAN){ \
        if(message == "👙 JasX HUD") \
            llGiveInventory(llGetOwner(), "JasX HUD 0.4.0"); \
        else if(message == "❔Help") \
            llGiveInventory(llGetOwner(), "How To Play"); \
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
        
        
        if(id == TABLE && CB == "PLAY"){
            
            // Play request invalid
            if(!l2i(PARAMS, 0)){
                
                llPlaySound("d70302dc-912b-4540-1e90-ab517026aa6d", .5);
                llOwnerSay(l2s(PARAMS, 1));
                
            }
            
        }
        
        
        return;
    }
    
    if(METHOD == swHUDMethod$setCards){
        
        
        CARDS = [];
        list_shift_each(PARAMS, card,
            
            if(~(int)card)
                CARDS+= (int)card;
                
        )
        
        
        drawCards();
        BFL = BFL|BFL_IN_GAME;
        
    }
    
    
    if(METHOD == swHUDMethod$setRoundColor){
        
        ROUND_COLOR = l2i(PARAMS, 0);
        drawCards();
        
    }
    
    
    if(METHOD == swHUDMethod$ping && id == TABLE){
        
        CB_DATA = [TRUE];
        
    }
    
    if(METHOD == swHUDMethod$setTurn){
        
        llPlaySound("bff8378a-cccd-b9c3-57a9-0f9a256b71ca", .5);
        
    }
    
    if(METHOD == swHUDMethod$setClothes){
        
        
        integer layer = l2i(PARAMS, 0);
        list layers = ["dressed", "underwear", "bits"];
        
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes "+l2s(layers, layer));        
        
    }
    
    if(METHOD == swHUDMethod$attachTo && method$byOwner){
        
        key player = method_arg(0);
        if(~llGetAgentInfo(player)&AGENT_SITTING)
            llDie();
        
        else
            llRequestPermissions(player, PERMISSION_ATTACH);
        
    }
    
    
    if(METHOD == swHUDMethod$on && method$byOwner){
        
        llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        
    }
    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
