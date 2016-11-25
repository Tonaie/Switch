#define USE_EVENTS
#include "switch/_core.lsl"

list PLAYERS;

integer PLAYER_CLOTHES;     // Split into 4 pieces of 8 (1 per player). The 2 rightmost bits are stripped_layers
                            // 0 means fully dressed, 1 means underwear and 2 is naked
#define getPlayerClothes(player) ((PLAYER_CLOTHES>>(8*(3-player)))&3)
#define setPlayerClothes(player, n) PLAYER_CLOTHES = ((PLAYER_CLOTHES&~(3<<(8*(3-player))))) | (n<<(8*(3-player)))

// Refreshes the clothing status in the JasX HUD if the target is an avatar
#define outputClothesIfAvatar(index) \
    if(llGetListEntryType(PLAYERS, index) != TYPE_INTEGER){ \
        swHUD$setClothes(l2s(PLAYERS, index), getPlayerClothes(index)); \
    }

list PRIMS_SEATS = [0,0,0,0];
list PRIMS_VIB = [  // Vibrator seats, stride of 2: [(int)bottom, (int)top]
    0,0,
    0,0,
    0,0,
    0,0
];
list VIBRATORS_ON = [0,0,0,0];

// List of integer seats that need perms requested for
list PERM_QUEUE;

integer BFL;
#define BFL_VIB_UP 0x1
#define BFL_PERM_QUEUE 0x2
#define BFL_DISABLE_VIBRATOR 0x4

#define VIB_BASE_HEIGHT 0.619873
#define VIB_BASE_SCALE <0.399834, 0.198138, 0.209000>


onEvt(string script, integer evt, list data){
    
    if(script == "sw Game"){
        
        if(evt == swGameEvt$players){
            PLAYERS = data;
            
            integer i;
            for(i=0; i<count(PLAYERS); ++i){
                outputClothesIfAvatar(i);
            }
        }
        
        if(evt == swGameEvt$gameStart){
            
            // Reset clothes
            PLAYER_CLOTHES = 0;
            integer i;
            for(i=0; i<4; ++i)
                outputClothesIfAvatar(i);
                
            
            toggleChairs([0,0,0,0]);
            llLinkParticleSystem(LINK_SET, []);
            
        }
        
        if(evt == swGameEvt$setEnd){
            
            // Draw
            if(l2i(data, 0) == -1)        
                return;
                
            // Vibrate the losing team
            list chairs = [-1,1,-1,1];
            if(l2i(data, 0)){
                chairs = [1, -1, 1, -1];
            }
            toggleChairs(chairs);
            
        }
        
        else if(evt == swGameEvt$roundEnd){
            
            integer player = l2i(data, 0);
            list fxs = llJson2List(l2s(data, 1));
            
            // In case of a double strip, we only want to send one command
            integer stripped;
            integer vibrate;
            
            integer lvl = getPlayerClothes(player);
            
            list_shift_each(fxs, fx,
                
                if((integer)fx == FX_STRIP){
                    
                    
                    if(lvl < 2){
                        ++lvl;
                        setPlayerClothes(player, lvl);
                        stripped = TRUE;
                                                
                    }
                    // Vibrate nude player
                    else{
                        
                        vibrate = TRUE;
                        
                    }
                    
                }
                    
                
            )
            
            if(stripped){
                
                key uuid = llAvatarOnLinkSitTarget(l2i(PRIMS_SEATS, player));
                string txt = "The bot ";
                if(uuid)
                    txt = llGetDisplayName(uuid)+" ";
                
                list states = ["", "is now in their underwear.", "is now nude."];
                txt+= l2s(states, lvl);
                
                runOnPlayers(targ,
                    
                    llRegionSayTo(targ, 0, txt);
                    
                )
                
                llTriggerSound("a76b6a1f-60b1-9dc5-579a-92271bc8c71e", 1);
                outputClothesIfAvatar(player);
                
            }else if(vibrate){
                
                list chairs = ([-1,-1,-1,-1]);
                chairs = llListReplaceList(chairs, [1], player, player);
                toggleChairs(chairs);
                
            }                 
            
        }
        
    }
    
    
}

timerEvent(string id, string data){
    
    // Vibration tick
    if(id == "V"){
        
        float z = VIB_BASE_HEIGHT;
        vector scale = VIB_BASE_SCALE;
        BFL = BFL^BFL_VIB_UP;
        
        if(BFL&BFL_VIB_UP){
            z += .005;
            scale*= 1.03;
        }
        
        list out;
                
        integer i;
        for(i=0; i<count(VIBRATORS_ON); ++i){
            
            if(l2i(VIBRATORS_ON, i)){
                
                
                vector xy = l2v(llGetLinkPrimitiveParams(l2i(PRIMS_VIB, i*2+1), [PRIM_POS_LOCAL]), 0);
                xy.z = z;
                
                out+= [
                    PRIM_LINK_TARGET, l2i(PRIMS_VIB, i*2+1),
                    PRIM_SIZE, scale,
                    PRIM_POSITION, xy
                ];
                
                
            }
            
        }
        
        PP(0, out);
        
    }
    else if(llGetSubString(id, 0, 2) == "VS:"){
        
        integer player = (int)llGetSubString(id, 3, 3);
        
        list chairs = [-1,-1,-1,-1];
        chairs = llListReplaceList(chairs, [0], player, player);
        toggleChairs(chairs);
                
    }
    
    else if(id == "Q"){
        
        permQueue(-1, TRUE);
        
    }
    
}


permQueue(integer user, integer force){
    
    if(force){
        BFL = BFL&~BFL_PERM_QUEUE;
    }
    
    if(llListFindList(PERM_QUEUE, [user]) == -1 && user != -1)
        PERM_QUEUE+= user;
    
    if(BFL&BFL_PERM_QUEUE || !count(PERM_QUEUE))
        return;
    
    
    list_shift_each(PERM_QUEUE, index,
        
        integer idx = (integer)index;
        key sitter = llAvatarOnLinkSitTarget(l2i(PRIMS_SEATS, idx));
        if(sitter){
            
            BFL = BFL|BFL_PERM_QUEUE;
            
            llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
			
            return multiTimer(["Q", "", 2, FALSE]);
            
        }
    
    )
    
}

// Chairs is a list of booleans, TRUE turns on that seat vibrator, FALSE turns it off, -1 ignores
toggleChairs(list chairs){
    
    if(BFL&BFL_DISABLE_VIBRATOR)
        return;
    
    list out = [];
    
    integer triggerSound;
    
    integer i;
    for(i=0; i<count(chairs); ++i){
        
        integer vib = l2i(chairs, i);
        
        if(vib != -1){
            
            integer pre = l2i(VIBRATORS_ON, i);
            VIBRATORS_ON = llListReplaceList(VIBRATORS_ON, [vib], i, i);
                        
            // Enable vibration
            if(vib){
                
                // Vibration timeout
                multiTimer(["VS:"+(str)i, "", 10, FALSE]);
                
                // Show Vibrator
                out+= [
                    // Chair
                    PRIM_LINK_TARGET, l2i(PRIMS_SEATS, i),
                    PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
                    
                    // Bottom
                    PRIM_LINK_TARGET, l2i(PRIMS_VIB, i*2),
                    PRIM_COLOR, ALL_SIDES, <1,1,1>, 1,
                    
                    PRIM_LINK_TARGET, l2i(PRIMS_VIB, i*2+1),
                    PRIM_COLOR, ALL_SIDES, <1,1,1>, 1
                    
                ];
                
            }
            else if(l2i(chairs, i) == 0){
                
                multiTimer(["VS:"+(str)i]);
                
                // Hide vibrator
                out+= [
                    // Chair
                    PRIM_LINK_TARGET, l2i(PRIMS_SEATS, i),
                    PRIM_COLOR, ALL_SIDES, <1,1,1>, 1,
                    
                    // Bottom
                    PRIM_LINK_TARGET, l2i(PRIMS_VIB, i*2),
                    PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
                    
                    PRIM_LINK_TARGET, l2i(PRIMS_VIB, i*2+1),
                    PRIM_COLOR, ALL_SIDES, <1,1,1>, 0
                    
                ];
                
                
                
            }

            
            key targ = llAvatarOnLinkSitTarget(l2i(PRIMS_SEATS, i));
            if(pre != vib){
                
                permQueue(i, FALSE);
                
                
                llLinkParticleSystem(l2i(PRIMS_VIB, i*2+1), []);
                llLinkParticleSystem(l2i(PRIMS_VIB, i*2+1), [  
                    PSYS_PART_FLAGS,
                        PSYS_PART_EMISSIVE_MASK|
                        PSYS_PART_INTERP_COLOR_MASK|
                        PSYS_PART_INTERP_SCALE_MASK|
                        //PSYS_PART_BOUNCE_MASK|
                        //PSYS_PART_WIND_MASK|
                        //PSYS_PART_FOLLOW_SRC_MASK|
                        //PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_FOLLOW_VELOCITY_MASK
                        
                    ,
                    PSYS_PART_MAX_AGE, .25,
                    
                    PSYS_PART_START_COLOR, <.5,.8,1>,
                    PSYS_PART_END_COLOR, <1,1,1>,
                    
                    PSYS_PART_START_SCALE,<.0,.0,0>,
                    PSYS_PART_END_SCALE,<1.5,1.5,0>, 
                                    
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    
                    PSYS_SRC_BURST_RATE, 0.05,
                    
                    PSYS_SRC_ACCEL, <0,0,0>,
                    
                    PSYS_SRC_BURST_PART_COUNT, 1,
                    
                    PSYS_SRC_BURST_RADIUS, 0.1,
                    
                    PSYS_SRC_BURST_SPEED_MIN, 0.0,
                    PSYS_SRC_BURST_SPEED_MAX, 0.5,
                    
                    //PSYS_SRC_TARGET_KEY,"",
                    
                    PSYS_SRC_ANGLE_BEGIN,   0.0, 
                    PSYS_SRC_ANGLE_END,     0.0,
                    
                    PSYS_SRC_OMEGA, <0,0,0>,
                    
                    PSYS_SRC_MAX_AGE, 0.5,
                                    
                    PSYS_SRC_TEXTURE, "c7c58cc4-878a-71ae-29e9-dc2f32241162",
                    
                    PSYS_PART_START_ALPHA, 1,
                    PSYS_PART_END_ALPHA, 0,
                    
                    PSYS_PART_START_GLOW, .1,
                    PSYS_PART_END_GLOW, 0.0
                    
                ]);
                
                if(vib)
                    llTriggerSound("d366735c-b98c-7de1-7ee0-58184d613287", 1);
                
            }
            
        }
    }
    
    if(out)
        PP(0, out);
    
    
    // Checks if the timer should stop
    for(i=0; i<count(VIBRATORS_ON); ++i){
        
        if(l2i(VIBRATORS_ON, i)){
            
            llLoopSound("33b4f7c0-66f1-5860-0e80-2edbb53d8f06", 1);
            return multiTimer(["V", "", 0.1, TRUE]);
            
        }
        
    }
    
    llStopSound();
    
    multiTimer(["V"]);
    
}



default
{
    state_entry()
    {
        PLAYERS = [(str)llGetOwner()];
        
        links_each(nr, name,
            
            list split = explode(":", name);
            
            if(l2s(split, 0) == "SEAT")
                PRIMS_SEATS = llListReplaceList(PRIMS_SEATS, [nr], l2i(split, 1), l2i(split, 1));
            
            else if(l2s(split, 0) == "VIB"){
                
                integer n = 2*l2i(split, 1)+l2i(split, 2);
                PRIMS_VIB = llListReplaceList(PRIMS_VIB, [nr], n, n);
                list data = llGetLinkPrimitiveParams(nr, [PRIM_POS_LOCAL, PRIM_SIZE]);
                
            }
            
        )
        
        toggleChairs([0,0,0,0]);
        //toggleChairs([1,0,1,0]);
        
    }
    
    run_time_permissions(integer perm){
        
        if(perm&PERMISSION_TRIGGER_ANIMATION){
            
            key id = llGetPermissionsKey();
            integer i;
            for(i=0; i<count(PRIMS_SEATS); ++i){
                
                key sitter = llAvatarOnLinkSitTarget(l2i(PRIMS_SEATS, i));
                if(id == sitter){
                    
                    integer vib = l2i(VIBRATORS_ON, i);
                    if(vib)
                        llStartAnimation("vibs_ab_v");
                    else 
                        llStopAnimation("vibs_ab_v");
                    
                    return permQueue(-1, TRUE);
                }
                
            }
            
        }
        
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
    
    if(METHOD == swRLVMethod$toggleVibrator){
        
        if(l2i(PARAMS, 0))
            BFL = BFL&~BFL_DISABLE_VIBRATOR;
        else
            BFL = BFL|BFL_DISABLE_VIBRATOR;
        
    }
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
