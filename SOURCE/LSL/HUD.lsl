integer g_iStartParam;
key g_kUser;
key g_kTable;

integer card_channel = -32988199;
integer hud_channel = -328478727;


s(string m){
    llInstantMessage(g_kUser,m);
}
list g_lCards;
Cards(){
    integer x = 0;
    integer e = 10;
    integer CurCard = 1;
    integer NCard = 0;
    for(x=0;x<e;x++){
        if(llGetListLength(g_lCards) > x){
            string card_params = llList2String(g_lCards,x);
            llMessageLinked(LINK_SET,0,llJsonGetValue(card_params,["text"]), "fw_data : card_text"+(string)CurCard);
        } else {
            NCard++;
            llMessageLinked(LINK_SET,0,"", "fw_data : card_text"+(string)CurCard);
        }
                    
        llMessageLinked(LINK_SET,0,"Cards Against Humanity","fw_data : card_helpertext"+(string)CurCard);    
        CurCard++;
    }
    
    if(NCard>0){
        integer CardsToRequest = NCard;
        if(CardsToRequest == 0)return;
        else {
            llRegionSayTo(g_kTable,hud_channel, llList2Json(JSON_OBJECT, ["type","card_request","count", CardsToRequest]));
        }
    }
}

POS(){
    if(!llGetAttached())return;
    vector local = <0.02395, 0.47113, -0.15166>;
    llSetPrimitiveParams([PRIM_POS_LOCAL, local]);
}

POS2(){
    if(!llGetAttached())return;
    vector local = <0.02395, 1.77734, -0.15166>;
    llSetPrimitiveParams([PRIM_POS_LOCAL, local]);
}

list g_lSelected = [];

Highlight(){
    integer i=1;
    integer end = 10;
    for(i=1;i<=end;i++){
        if(llListFindList(g_lSelected,[i])==-1){
            integer x=0;
            integer end2 = llGetNumberOfPrims();
            for(x=1;x<=end2;x++){
                string LinkName = llGetLinkName(x);
                if(LinkName=="Card"+(string)i){
                    llSetLinkColor(x, <1,1,1>, 2);
                    jump stopFor;
                }
            }
            @stopFor;
        } else {
            integer x = 0;
            integer end2 = llGetNumberOfPrims();
            for(x=1;x<=end2;x++){
                string LinkName = llGetLinkName(x);
                if(LinkName == "Card"+(string)i){
                    llSetLinkColor(x,<0,1,0>,2);
                    jump stopFor2;
                }
            }
            @stopFor2;
        }
    }
}

integer g_iSelectNum=0;
integer g_iCanSelect=0;
integer g_iListen=-1;
integer g_iChan;

ShowPrompt(){
    if(g_iListen==-1){
        g_iChan = llRound(llFrand(5493874));
        g_iListen = llListen(g_iChan, "", g_kUser, "");
    }
    
    llDialog(g_kUser, "Do you want to submit your selected card(s)?", ["Yes", "No"], g_iChan);
}

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
        
        Highlight();
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
        if(g_iStartParam == c){
            // listen for the UUID of who to attach the HUD to!
            if(llJsonGetValue(m,["type"])=="activate"){
                g_kTable = (key)llJsonGetValue(m,["table"]);
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
                    }
                }
            } else if(llJsonGetValue(m,["type"]) == "select"){
                if(llJsonGetValue(m,["czar"]) == (string)g_kUser){
                    s("You are the Card Czar, hiding the HUD");
                    POS2();
                    g_iCanSelect=0;
                } else {
                    g_iSelectNum = (integer)llJsonGetValue(m,["sel_count"]);
                    POS();
                    g_lSelected=[];
                    Highlight();
                    s("Select ("+(string)g_iSelectNum+") cards to submit");
                    s("Card czar: secondlife:///app/agent/"+llJsonGetValue(m,["czar"])+"/about");
                    Cards();
                    g_iCanSelect=1;
                }
            } else if(llJsonGetValue(m,["type"]) == "judging"){
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
                llSay(0, "(DEBUG)\nm: "+m+"\n-> Table: "+(string)g_kTable+"\n-> User: "+(string)g_kUser);
                if(llJsonGetValue(m,["table"])==(string)g_kTable){
                    if(llJsonGetValue(m,["avatar"])==(string)g_kUser || llJsonGetValue(m,["avatar"])==(string)NULL_KEY || llJsonGetValue(m,["avatar"])==""){
                        llSay(0, "Deactivating HUD");
                        state detach;
                    }
                }
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
                if(end == 0 || end!= g_iSelectNum){
                    s("You must select "+(string)g_iSelectNum+" cards!");
                }else {
                    list lToRemove = [];
                    for(x=0;x<end;x++){
                        integer CardNum = llList2Integer(g_lSelected, x);
                        string CardQuery = llList2String(g_lCards, (CardNum-1));
                        lToRemove += CardQuery;
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
                    llRegionSayTo(g_kTable, hud_channel, llList2Json(JSON_OBJECT, ["type", "cards", "cards", sActualCardData]));
                    POS2();
                }
            }
        }
    }
    
    touch_start(integer t){
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
            llRegionSayTo(g_kTable, hud_channel, llList2Json(JSON_OBJECT, ["type", "leave", "avatar", g_kUser]));
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
            
            llListen(hud_channel, "", "", "");
            Cards();
            POS2();
            
            s("HUD initialization completed");
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
        for(i=1;i<=end;i++){
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