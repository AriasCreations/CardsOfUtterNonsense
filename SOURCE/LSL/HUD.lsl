integer g_iStartParam;
key g_kUser;
key g_kTable;
key g_kActualTable;
integer DEBUG=FALSE;

integer card_channel = -32988199;
integer hud_channel = -328478727;

vector g_vLastPos1 = <0.00000, 0.34831, -0.10162>;

s(string m){
    llInstantMessage(g_kUser,m);
}
list g_lCards;
integer g_iPoints = 0;
Cards(){
    llMessageLinked(LINK_SET,0,"<!c=magenta>Points: <!c=black>"+(string)g_iPoints, "fw_data : point_text");
    //if(!llGetAttached())return;
    integer x = 0;
    integer e = 10;
    integer CurCard = 1;
    integer NCard = 0;
    
    //if(DEBUG)llSay(0, "CARD LIST: "+llDumpList2String(g_lCards, " - "));
    
    for(x=0;x<e;x++){
        if(llGetListLength(g_lCards) > x){
            string card_params = llList2String(g_lCards,x);
            //if(DEBUG)llSay(0,"Card Parameters: "+card_params);
            llMessageLinked(LINK_SET,0,llJsonGetValue(card_params,["text"]), "fw_data : card_text"+(string)CurCard);

            if(llStringLength(llJsonGetValue(card_params,["text"]))>128){
                s("Card "+(string)x+": "+llJsonGetValue(card_params,["text"]));
            }
        } else {
            NCard++;
            llMessageLinked(LINK_SET,0,"", "fw_data : card_text"+(string)CurCard);
        }
                    
        llMessageLinked(LINK_SET,0,"Cards Against Humanity","fw_data : card_helpertext"+(string)CurCard);    
        CurCard++;
    }
    
    
    if(NCard>0){
        integer CardsToRequest = NCard;
        if(CardsToRequest>0)CardsToRequest=1;
        if(CardsToRequest == 0)return;
        else {
            llOwnerSay("Drawing "+(string)CardsToRequest+" cards");
            llRegionSayTo(g_kActualTable,hud_channel, llList2Json(JSON_OBJECT, ["type","card_request","count", CardsToRequest]));
        }
    }
}
integer g_iVis=0;
POS(){
    if(!llGetAttached())return;
    g_iVis=1;
    vector local = g_vLastPos1;
    llSetPrimitiveParams([PRIM_POS_LOCAL, local]);
}

POS2(){
    if(!llGetAttached())return;
    g_iVis=0;
    vector local = <0.02395, 1.77734, -0.15166>;
    if(llVecDist(llGetLocalPos(),local)>1){
        g_vLastPos1 = llGetLocalPos();
        llSetPrimitiveParams([PRIM_POS_LOCAL, local]);
    }
}

list g_lSelected = [];
list g_lActualCards = [1, 26, 
        2, 47,
        3, 68,
        4, 89,
        5, 110,
        6, 131,
        7, 152,
        8, 173,
        9, 194,
        10, 215
        ];

Highlight(){
    integer i=0;
    integer end = llGetListLength(g_lActualCards);
    for(i=0;i<end;i+=2){
        if(llListFindList(g_lSelected,[llList2Integer(g_lActualCards,i)])==-1){
            //llSay(0, "number : "+(string)llList2Integer(g_lActualCards,i)+" not found in selected card list.");
            llSetLinkColor(llList2Integer(g_lActualCards, i+1), <1,1,1>, 2);
            //llSay(0, "set "+llList2String(g_lActualCards,i+1)+" to white on face 2");
        } else {
            //llSay(0, "number : "+(string)llList2Integer(g_lActualCards,i)+" found in selected card list.");
            llSetLinkColor(llList2Integer(g_lActualCards,i+1), <0,1,0>, 2);
            //llSay(0, "set "+llList2String(g_lActualCards,i+1)+" to green on face 2");
        }
    }
    
}

integer g_iSelectNum=0;
integer g_iCanSelect=0;
integer g_iListen=-1;
integer g_iChan;
integer g_iUsePoint=0;


ShowPrompt(){
    if(g_iListen==-1){
        g_iChan = llRound(llFrand(5493874));
        g_iListen = llListen(g_iChan, "", g_kUser, "");
    }
    
    llDialog(g_kUser, "Do you want to submit your selected card(s)?", ["Yes", "No"], g_iChan);
}

czar(string m){
    
    llMessageLinked(LINK_SET, 0, "<!c=white>"+llJsonGetValue(m,["card"]), "fw_data : czarcard_text");
    integer num = (integer)llJsonGetValue(m,["num"]);
    if(num==0){
        llMessageLinked(LINK_SET,0,"<!c=white>Cards Against Humanity", "fw_data : czarcard_helpertext");
    } else {
        llMessageLinked(LINK_SET,0,"<!c=white>Pick ("+(string)num+")\nDraw ("+(string)num+")", "fw_data : czarcard_helpertext");
    }
}

integer g_iOldSel=0;
default
{
    state_entry()
    {
        llWhisper(0, "HUD was not rezzed or attached using the game table");
        llWhisper(0, "Some functionality may not work");
        llMessageLinked(LINK_SET,0,"","fw_reset");
        llWhisper(0, "HUD is now activating");
        
        g_kUser=llGetOwner();
        g_kTable = llGetOwner();
        
        //g_lSelected = [5, 7, 1];
        Highlight();
        
        llSetLinkColor(6, <0.078, 0.078, 0.078>, 0);
        llSetLinkColor(6, <0.078, 0.078, 0.078>, 1);
        llSetLinkColor(2, <1,1,1>,ALL_SIDES );
    }
    
    on_rez(integer t){
        if(t==0){
            llResetScript();
        }else {
            llSetPrimitiveParams([PRIM_TEMP_ON_REZ,TRUE]);
            g_iStartParam = t;
            llListen(t, "", "", "");
            llSay(hud_channel, llList2Json(JSON_OBJECT, ["type", "alive", "boot", t]));
        }
    }
    
    listen(integer c,string n,key i,string m){
        //if(DEBUG)llSay(0, m);
        if(g_iStartParam == c){
            // listen for the UUID of who to attach the HUD to!
            if(llJsonGetValue(m,["type"])=="activate"){
                g_kTable = (key)llJsonGetValue(m,["table"]);
                g_kActualTable = i;
                llWhisper(0, "HUD now activating...");
                key g_kUser = (key)llJsonGetValue(m, ["user"]);
                llRequestPermissions(g_kUser, PERMISSION_ATTACH);
                //Cards();
            }
        }else if(c == hud_channel){
            //llSay(0, "HUD message: "+m);
            if(llJsonGetValue(m,["type"])=="card"){
                if(llJsonGetValue(m,["avatar"])==(string)g_kUser){
                    if(llGetListLength(g_lCards)<10 && llListFindList(g_lCards,[llJsonGetValue(m,["card"])])==-1){
                        g_lCards += llJsonGetValue(m,["card"]);
                        s("Added card: "+llJsonGetValue(m,["card", "text"]));
                        g_iPoints = (integer)llJsonGetValue(m,["points"]);
                        Cards();
                    }
                }
            } else if(llJsonGetValue(m,["type"]) == "select"){
                if(g_kTable != (key)llJsonGetValue(m,["table"]))return;
                if(llJsonValueType(m,["points", (string)g_kUser])!=JSON_INVALID){
                    g_iPoints=(integer)llJsonGetValue(m,["points", (string)g_kUser]);
                }
                if(llJsonGetValue(m,["czar"]) == (string)g_kUser){
                    s("You are the Card Czar, hiding the HUD");
                    g_iCanSelect=0;
                    //g_iPoints = (integer)llJsonGetValue(m,["points"]);
                    Cards();
                    POS2();
                } else {
                    g_iSelectNum = (integer)llJsonGetValue(m,["sel_count"]);
                    g_lSelected=[];
                    Highlight();
                    s("Select ("+(string)g_iSelectNum+") cards to submit");
                    s("Card czar: secondlife:///app/agent/"+llJsonGetValue(m,["czar"])+"/about");
                    //g_iPoints = (integer)llJsonGetValue(m,["points"]);
                    Cards();
                    g_iCanSelect=1;
                    POS();
                }
            } else if(llJsonGetValue(m,["type"]) == "judging"){
                if(g_kTable != (key)llJsonGetValue(m,["table"]))return;
                s("Judging begun. HUD hidden!");
                POS2();
                g_lSelected=[];
                Highlight();
                g_iCanSelect=0;
                if(g_iListen!=-1){
                    llListenRemove(g_iListen);
                    g_iListen=-1;
                    g_iChan=0;
                }
            } else if(llJsonGetValue(m,["type"])=="die"){
                //if(DEBUG)llSay(0, "(DEBUG)\nm: "+m+"\n-> Table: "+(string)g_kTable+"\n-> User: "+(string)g_kUser);
                if(llJsonGetValue(m,["table"])==(string)g_kTable){
                    if(llJsonGetValue(m,["avatar"])==(string)g_kUser || llJsonGetValue(m,["avatar"])==(string)NULL_KEY || llJsonGetValue(m,["avatar"])==""){
                        llSay(0, "Deactivating HUD");
                        state detach;
                    }
                }
            } else if(llJsonGetValue(m,["type"])=="czar"){
                czar(m);
            }
        } else if(g_iChan == c){
            if(m == "No"){
                // reshow prompt until user selects yes
                ShowPrompt();
            } else if(m == "Yes"){
                // Gather card data and send to table
                //llWhisper(0, "Locating the cards...");
                integer x = 0;
                integer end = llGetListLength(g_lSelected);
                string sActualCardData;
                if(g_iUsePoint){
                    g_iOldSel=g_iSelectNum;
                    g_iSelectNum=end;
                }
                if(end == 0 || end!= g_iSelectNum){
                    s("You must select "+(string)g_iSelectNum+" cards!");
                }else {
                    list lToRemove = [];
                    for(x=0;x<end;x++){
                        integer CardNum = llList2Integer(g_lSelected, x);
                        string CardQuery = llList2String(g_lCards, (CardNum-1));
                        lToRemove += CardQuery;
                        CardQuery = llJsonSetValue(CardQuery, ["user"], g_kUser);
                        sActualCardData = llJsonSetValue(sActualCardData, [x], CardQuery);
                    }
                    x=0;
                    end=llGetListLength(g_lCards);
                    for(x=0;x<end;x++){
                        string CardData = llList2String(g_lCards, x);
                        if(llListFindList(lToRemove, [CardData])!=-1){
                            g_lCards = llDeleteSubList(g_lCards, x,x);
                            x=-1;
                            end = llGetListLength(g_lCards);
                        }
                        
                    }
                    g_lSelected=[];
                    Highlight();
                    Cards();
                    //llSay(0, "(DEBUG) Sending card(s) to table: "+sActualCardData);
                    if(!g_iUsePoint){
                        llRegionSayTo(g_kActualTable, hud_channel, llList2Json(JSON_OBJECT, ["type", "cards", "cards", sActualCardData]));
                        
                        POS2();
                    }
                    else{
                        g_iPoints--;
                        llSetLinkColor(2, <1,1,1>,ALL_SIDES );
                        g_iUsePoint=0;
                        llRegionSayTo(g_kActualTable, hud_channel, llList2Json(JSON_OBJECT, ["type", "use_point", "cards", sActualCardData]));
                        Cards();
                        g_iSelectNum=g_iOldSel;
                    }
                }
            }
        }
    }
    
    touch_start(integer t){
        if(DEBUG)llSay(0, "TOUCHED NUMBER: "+(string)llDetectedLinkNumber(0));
        if(llGetLinkName(llDetectedLinkNumber(0)) == "Use Point"){
            // activate card selector
            if(!g_iUsePoint){
                llSetLinkColor( llDetectedLinkNumber(0), <1,0,0>,ALL_SIDES );
                if(g_iPoints >0){
                    llDialog(llGetOwner(), "Select the card(s) you wish to return to the deck. You may return as many cards to the deck as you would like, you will then re-draw cards. This will cost you precisely (1) point.", ["-exit-"], -99);
                    g_iUsePoint=1;
                    return;
                } else {
                    llDialog(llGetOwner(), "ERROR: You do not have any points to exchange!", ["-exit-"], -99);
                    g_iUsePoint=0;
                    return;
                }
            } else {
                llDialog(llGetOwner(), "Points will not be redeemed. Cancelling selection process", ["-exit-"],-99);
                g_iUsePoint=0;
                g_lSelected=[];
                Highlight();
                llSetLinkColor( llDetectedLinkNumber(0), <1,1,1>,ALL_SIDES );
                return;
            }
        }
        if(g_iCanSelect){
            llMessageLinked(LINK_SET,0,llGetLinkName(llDetectedLinkNumber(0)),"fw_touchquery : "+(string)llDetectedLinkNumber(0) + ":" + (string)llDetectedTouchFace(0));
        }else s("You can't select a card right now");
        
    }
    
    run_time_permissions(integer p){
        if(p&PERMISSION_ATTACH){
            llAttachToAvatarTemp(ATTACH_HUD_CENTER_2);
        }
    }
    
    attach(key id){
        if(id == NULL_KEY){
            llWhisper(0, "HUD is deactivating...");
            llRegionSayTo(g_kActualTable, hud_channel, llList2Json(JSON_OBJECT, ["type", "leave", "avatar", g_kUser]));
            //llRemoveInventory(llGetScriptName());
        } else {
            g_kUser=id;
            POS();
            llMessageLinked(LINK_SET,0,"","fw_reset");
        }
    }
    
    link_message(integer s,integer n,string m,key i){
        if(i=="fw_ready"){
            llMessageLinked(LINK_SET,0,"c=black", "fw_conf");
            g_lCards=[];
            /*g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            g_lCards +=llList2Json(JSON_OBJECT, ["text", "This is test "+(string)llFrand(4382438)]);
            
            
            g_iPoints++;
            g_iCanSelect=1;*/
            llListen(hud_channel, "", "", "");
            Cards();
            POS2();
            
            s("HUD initialization completed");
            
            //czar(llList2Json(JSON_OBJECT, ["card", "This is a test", "num", 4]));
        }else if (i == "fw_touchreply") {
            list     tokens    = llParseStringKeepNulls(m, [":"], []);
            string   boxName   = llList2String(tokens, 0);
            integer  dx        = llList2Integer(tokens, 1);
            integer  dy        = llList2Integer(tokens, 2);
            string   rootName  = llList2String(tokens, 3);
            integer  x         = llList2Integer(tokens, 4);
            integer  y         = llList2Integer(tokens, 5);
            string   userData  = llList2String(tokens, 6);
            
            ShowPrompt();
            
            if(g_iUsePoint){
                integer CardNum = 0;
                if(rootName=="") CardNum = (integer)llGetSubString(userData, 4,-1);
                else CardNum = (integer)llList2String(llParseString2List(rootName, ["text"], []), -1);
                
                if(CardNum ==0)return;
                integer cardIndex = llListFindList(g_lSelected,[CardNum]);
                if(cardIndex!=-1){
                    g_lSelected = llDeleteSubList(g_lSelected, cardIndex, cardIndex);
                }else {
                    g_lSelected += CardNum;
                }
                Highlight();
                return;
            }
            
            if(rootName == ""){
                integer CardNum = (integer)llGetSubString(userData, 4,-1);
                if(CardNum ==0)return;
                else {
                    if(llListFindList(g_lSelected,[CardNum])!=-1){
                        g_lSelected = llDeleteSubList(g_lSelected, llListFindList(g_lSelected, [CardNum]), llListFindList(g_lSelected, [CardNum]));
                    } else{
                                    
                        if(llGetListLength(g_lSelected) == g_iSelectNum){
                            s("You already have "+(string)g_iSelectNum+" selected cards. Deselect one before changing your selection");
                            return;
                        }
                        g_lSelected += CardNum;
                    }
                    Highlight();
                }
            } else {
                list lParam = llParseString2List(rootName,["text"],[]);
                integer CardNum = (integer)llList2String(lParam,-1);
                if(CardNum==0)return;
                else{
                    if(llListFindList(g_lSelected,[CardNum])!=-1){
                        g_lSelected = llDeleteSubList(g_lSelected, llListFindList(g_lSelected, [CardNum]), llListFindList(g_lSelected, [CardNum]));
                    } else{
                                       
                        if(llGetListLength(g_lSelected) == g_iSelectNum){
                            s("You already have "+(string)g_iSelectNum+" selected cards. Deselect one before changing your selection");
                            return;
                        }
                        g_lSelected += CardNum;
                    }
                    Highlight();
                }
            }
        }
    }
}

state detach
{
    state_entry(){
        integer i=0;
        integer end = llGetNumberOfPrims();
        for(i=2;i<=end;i++){
            llSetLinkPrimitiveParamsFast(i,[PRIM_SIZE,ZERO_VECTOR,PRIM_POS_LOCAL,ZERO_VECTOR,PRIM_ROT_LOCAL,ZERO_ROTATION]);
        }
        llSleep(2);
        llRequestPermissions(g_kUser,PERMISSION_ATTACH);
    }
    
    run_time_permissions(integer p){
        if(p&PERMISSION_ATTACH){
            llDetachFromAvatar();
        }
    }
}