
integer ingredient_channel = -8392888;
integer containerChannel = -8392891;
integer updater_channel = 15418070;
integer card_channel = -32988199;
integer hud_channel = -328478727;

list g_lPoints;
integer g_iStarted;
GiveUserPoint(key kUser){
    // point list - user, num of points
    integer index = llListFindList(g_lPoints,[kUser]);
    if(index == -1){
        g_lPoints += [kUser, 1];
    }else {
        integer curPoint = llList2Integer(g_lPoints,index+1);
        curPoint++;
        g_lPoints=llListReplaceList(g_lPoints,[curPoint], index+1,index+1);
    }
    UpScores();
}

UpScores(){
    
    integer i=0;
    integer iScores;
    integer end = llGetNumberOfPrims();
    for(i=0;i<=end;i++){
        string name = llGetLinkName(i);
        if(name == "Scores"){
            iScores=i;
            jump outScore;
        }
    }
    @outScore;
    i=0;
    end=llGetListLength(g_lPoints);
    string sScores;
    for(i=0;i<end;i+=2){
        sScores += llKey2Name(llList2String(g_lPoints, i))+": "+llList2String(g_lPoints,i+1)+"\n";
    }
    llSetLinkPrimitiveParams(iScores, [PRIM_TEXT, sScores, <1,0,0>,1]);
}

list g_lJudgePile;
integer g_iTotalJudgeUsers;

string g_sVersion = "1.0.0.0000";
key g_kToken;
integer DEBUG = FALSE;
float offset;
list g_lReqs;
string URL = "https://api.zontreck.dev/ls_bionics";
Send(string Req,string method){
    g_lReqs += [Req,method];
    Sends();
}
Sends(){
    if(g_kCurrentReq == NULL_KEY){
        DoNextRequest();
    }
    //g_lReqs += [llHTTPRequest(URL + llList2String(lTmp,0), [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], llDumpList2String(llList2List(lTmp,1,-1), "?"))];
}

integer g_iCzar;
key g_kCurrentReq = NULL_KEY;
DoNextRequest(){
    if(llGetListLength(g_lReqs)==0)return;
    list lTmp = llParseString2List(llList2String(g_lReqs,0),["?"],[]);
    if(DEBUG)llSay(0, "SENDING REQUEST: "+URL+llList2String(g_lReqs,0));
    
    string append = "";
    if(llList2String(g_lReqs,1) == "GET")append = "?"+llDumpList2String(llList2List(lTmp,1,-1),"?");
    
    g_kCurrentReq = llHTTPRequest(URL + llList2String(lTmp,0) + append, [HTTP_METHOD, llList2String(g_lReqs,1), HTTP_MIMETYPE, "application/x-www-form-urlencoded"], llDumpList2String(llList2List(lTmp,1,-1),"?"));
}


integer Dice(integer NTimes, integer Max, integer Test1, integer Test2){
    integer i=0;
    integer LTotal=0;
    for(i=0;i<NTimes;i++){
        LTotal += llRound(llFrand(Max));
        llSleep(0.5);
    }
    integer Mean = LTotal / NTimes;
    if(Mean > Test1&&Mean < Test2)return TRUE;
    else return FALSE;
}

list g_lListener;
list g_lPending;
REZ(key i){
    if(g_iBlockRez)return;
    integer chan = llRound(llFrand(548937));
    
    llRezObject("Cards Against Humanity HUD [LS]", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, chan);
    
    g_lPending += [i, chan];
    
    integer rnd = llRound(llFrand(5843758));
    g_lListener += [i,rnd,llListen(rnd,"",i,"")];
    llDialog(i, "Are you male or female?", ["Female", "Male"], rnd);
    
    llRequestPermissions(i, PERMISSION_TRIGGER_ANIMATION);
}

Rescan(){
    list OldPlayers = Players;
    
    Players=[];
    integer i=0;
    integer end = llGetNumberOfPrims();
    integer ChairNumber = 0;
    //llSay(0, "Simulating player count");
    list ToEvict = [];
    for(i=0;i<=end;i++){
        vector Scale = llGetAgentSize(llGetLinkKey(i));
        if(Scale != ZERO_VECTOR){
            // This is an avatar
            integer Chair = llList2Integer(Chairs,ChairNumber);
            if(ChairNumber > llGetListLength(Chairs)) ToEvict += [llGetLinkKey(i)];
            ChairNumber++;
            //llSay(0, "Discover: Avatar ID : secondlife:///app/agent/"+(string)llGetLinkKey(i)+"/about");
            list ChairParams = llGetLinkPrimitiveParams(Chair, [PRIM_POS_LOCAL, PRIM_DESC]);
            list ChairData = llParseString2List(llList2String(ChairParams,1), ["`"],[]);
            Players += llGetLinkKey(i);
            if(llListFindList(OldPlayers, [llGetLinkKey(i)])==-1){
                llWhisper(0, "secondlife:///app/agent/"+(string)llGetLinkKey(i)+"/about has joined the game!");
                llInstantMessage(llGetLinkKey(i), "Rezzing a HUD. Please accept attachment permissions");
                REZ(llGetLinkKey(i));
            }
            llSetLinkPrimitiveParams(i, [PRIM_POS_LOCAL, llList2Vector(ChairParams,0)+<0,0,1>+(vector)llList2String(ChairData,1), PRIM_ROT_LOCAL, llEuler2Rot((vector)llList2String(ChairData,0)*DEG_TO_RAD)]);
        }
    }
    
    Compare(OldPlayers);
    Evict(ToEvict);
    
    if(llGetListLength(Players)==0 && llGetListLength(OldPlayers)!=0){
        llSay(0, "All players left the game. Resetting game and shuffling cards!");
        llResetScript();
    }
}
list Chairs=[];
list Players;

Compare(list OldList){
    // Check for who has left the game, then deactivate their HUD
    integer i=0;
    integer end = llGetListLength(OldList);
    for(i=0;i<end;i++){
        if(llListFindList(Players,[llList2Key(OldList,i)])==-1){
            llSay(0, "secondlife:///app/agent/"+llList2String(OldList,i)+"/about has left the game");
            llSay(hud_channel, llList2Json(JSON_OBJECT, ["type","die","table",g_kID,"avatar", llList2Key(OldList,i)]));
        }
    }
}

Evict(list lLst){
    integer i=0;
    integer end = llGetListLength(lLst);
    for(i=0;i<end;i++){
        llUnSit(llList2Key(lLst,i));
        llSay(hud_channel, llList2Json(JSON_OBJECT, ["type","die","table",g_kID,"avatar", llList2Key(lLst,i)]));
    }
    
    if(end!=0)Rescan();
}
key g_kID;
integer g_iBlockRez = 0;
key g_kCurrentBlackCard;
list g_lPendingCards;

default
{
    state_entry()
    {
        llSitTarget(ZERO_VECTOR,ZERO_ROTATION);
        Chairs=[];
        UpScores();
        //llSay(0, "Activating Setup Mode");
        //llSay(0, "Scanning linkset for positions of prims");
        integer i=0;
        integer end = llGetNumberOfPrims();
        for(i=0;i<=end;i++){
            string name = llGetLinkName(i);
            if(name == "Chair [LS]"){
                Chairs += i;
            }
        }
        //llSay(0, "Scanning for players");
        g_iBlockRez = 1;
        Rescan();
        //llSay(0, "Setup has completed!");
        
        llSetSitText("Play!");
        
        llWhisper(0, "Stand by...");
        g_kID = (key)llGetObjectDesc();
        if(g_kID == "new_lsk"){
            g_kID = llGenerateKey();
            llSetObjectDesc((string)g_kID);
            llSay(0, "First Rez! Thank you for your purchase of an LS Bionics product!\n \n[Generating License Key]");
            llSetObjectName("Cards Against Humanity [LS]");
            Send("/Put_Product_Data.php?PRODUCT=CAH_TABLE&KEYID="+(string)g_kID+"&NICKNAME=License&DATA=1","POST");
            return;
        }
        llWhisper(card_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID]));
        llWhisper(hud_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID, "avatar", NULL_KEY]));
        Evict(Players);
        
        
        state license_check;
    }
    
    http_response(key r,integer s,list m,string b){
        if(r==g_kCurrentReq){
            g_kCurrentReq = NULL_KEY;
            
            list lTmp = llParseString2List(b,[";;",";"],[]);
            if(llList2String(lTmp,0) == "Put_Product_Data"){
                llResetScript();
            }
        }
    }
    
    on_rez(integer t){
        llResetScript();
    }
}

state license_check
{
    state_entry(){
        //llSay(0, "Checking for a game license... Please hold on awhile while I process your request");
        Send("/Get_Product_Data.php?PRODUCT=CAH_TABLE&KEYID="+(string)g_kID+"&NICKNAME=License", "GET");
    }
    
    http_response(key r,integer s,list m, string b){
        if(r == g_kCurrentReq){
            g_kCurrentReq = NULL_KEY;
            g_lReqs = llDeleteSubList(g_lReqs,0,1);
            
            list lTmp = llParseString2List(b,[";;",";"],[]);
            string Script = llList2String(lTmp,0);
            if(Script == "Get_Product_Data")
            {
                string Variable = llList2String(lTmp,1);
                if(llList2String(lTmp,2) == "1"){
                    //llSay(0, "License is now activated!");
                    state active;
                } else {
                    llSay(0, "ERROR: No valid license key has been found. Try again later, or contact LS Bionics support\n\n[Error code: "+llList2String(lTmp,2)+"]");
                }
            }
            
            Sends();
        }
    }
    
    on_rez(integer t){
        llResetScript();
    }
    
    changed(integer t){
        if(t&CHANGED_REGION_START){
            llResetScript();
        }
    }
}
state active
{
    state_entry(){
        llSay(0, "Game Table now ready");
        llSay(0, "Shuffling cards...");
        Send("/Modify_Card.php?TYPE_OVERRIDE=MAKE_DECK&TABLE_ID="+(string)g_kID, "POST");
        g_iBlockRez=0;
        g_lPending=[];
        
        llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID]));
        llListen(hud_channel, "", "", "");
        llListen(card_channel, "", "", "");/*
        integer chan = llRound(llFrand(548378));
        g_lPendingCards += [chan, "null|black"];
        llRezObject("Playing Card [LS]", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, chan);*/
        
    }
    
    http_response(key r,integer s,list m,string b){
        if(r==g_kCurrentReq){
            g_kCurrentReq = NULL_KEY;
            g_lReqs = llDeleteSubList(g_lReqs,0,1);
            
            list lTmp = llParseString2List(b,[";;",";"],[]);
            if(DEBUG)llSay(0, "HTTP REPLY: "+b);
            string Script = llList2String(lTmp,0);
            if(Script == "Modify_Deck"){
                llSay(0, "Deck generated!");
            } else if(Script == "Get_Card"){
                key Sender = (key)llList2String(lTmp,1);
                list Params = llJson2List(llBase64ToString(llList2String(lTmp,2)));
                if(DEBUG)llSay(0, "PARAMETER LIST: "+llList2CSV(Params));

                //llParseString2List(llBase64ToString(llList2String(lTmp,2)), ["|"],[]);
                integer i=0;
                integer end = llGetListLength(Params);
                for(i=0;i<end;i++){
                    string card_text = llJsonGetValue(llList2String(Params,i), ["text"]);
                    integer color = (integer)llJsonGetValue(llList2String(Params,i), ["color"]);
                    integer num_req = (integer)llJsonGetValue(llList2String(Params,i),["num"]);
                    integer rezzed = (integer)llJsonGetValue(llList2String(Params,i), ["rezzed"]);
                    if(rezzed==0)
                        llRegionSayTo(Sender, hud_channel, llList2Json(JSON_OBJECT, ["type", "card", "avatar", llGetOwnerKey(Sender), "card", llList2Json(JSON_OBJECT, ["text", llJsonGetValue(llList2String(Params,i), ["text"])])]));
                    else{
                        if(color){
                            g_kCurrentBlackCard = Sender;
                            llSay(0, "A new black card has been played");
                            if(g_iCzar == -1){
                                llSay(0, "This is a new game, assigning random card czar");
                                g_iCzar = llRound(llFrand(llGetListLength(Players)));
                            } else {
                                g_iCzar++;
                                if(g_iCzar >= llGetListLength(Players)){
                                    g_iCzar = 0;
                                }
                            }
                            
                            key czar = llList2String(Players,g_iCzar);
                            llSay(0, "Card Czar is: secondlife:///app/agent/"+(string)czar+"/about");
                            
                            llRegionSay(hud_channel, llList2Json(JSON_OBJECT, ["type", "select", "czar", czar, "sel_count", num_req, "table", g_kID]));
                        }
                        llRegionSayTo(Sender, card_channel, llList2Json(JSON_OBJECT, ["type", "set", "card", llList2Json(JSON_OBJECT, ["text", card_text, "color", color, "num", num_req, "czar", llList2String(Players,g_iCzar), "user", llList2String(lTmp,3)])]));
                    }
                }
            } else if(Script == "Modify_Card"){
                string Sender = llList2String(lTmp,6);
                string Color = llList2String(lTmp,2);
                string Text = llBase64ToString(llList2String(lTmp,3));
                integer num = llList2Integer(lTmp,4);
                string user = llList2String(lTmp,5);
                
                if(DEBUG)llSay(0, "SEARCH RESULT: "+Text);
            } else if(Script == "No More Cards"){
                
                llSay(0, "Game over! No more black cards exist in the deck... Checking for winner...");
                integer iLastHigh;
                key kLastHigh;
                integer x=0;
                integer xe = llGetListLength(g_lPoints);
                for(x=0;x<xe;x++){
                    key User = llList2Key(g_lPoints,x);
                    integer points = llList2Integer(g_lPoints,x+1);
                    if(points>iLastHigh){
                        iLastHigh=points;
                        kLastHigh = User;
                    }
                }
                                
                llSay(0, "WINNER IS: secondlife:///app/agent/"+(string)kLastHigh+"/about with "+(string)iLastHigh+" points total!!");
                llResetScript();
            }
            
            
            Sends();
        }
    }
    
    listen(integer c,string n,key i, string m){
        if(DEBUG){
            llSay(0, "LISTEN: "+llDumpList2String([c,n,i,m], " - "));
        }
        if(c==hud_channel){
            if(llJsonGetValue(m,["type"])=="card_request"){
                integer card_count = (integer)llJsonGetValue(m,["count"]);
                Send("/Modify_Card.php?TYPE_OVERRIDE=GET_CARD&TABLE_ID="+(string)g_kID+"&COLOR=0&DRAW_COUNT="+(string)card_count+"&SENDER="+(string)i+"&REZZED=0", "POST");
            } else if(llJsonGetValue(m,["type"])=="alive"){
                integer index = llListFindList(g_lPending,[(integer)llJsonGetValue(m,["boot"])]);
                if(index==-1)return;
                else {
                    // Boot the HUD
                    if(DEBUG)llSay(0, "Sending HUD Activation signal");
                    index--;
                    
                    
                    llRegionSayTo(i,llList2Integer(g_lPending,index+1), llList2Json(JSON_OBJECT, ["type", "activate", "user", llList2String(g_lPending,index), "table", g_kID]));
                    g_lPending = llDeleteSubList(g_lPending, index,index+1);
                }
            } else if(llJsonGetValue(m,["type"]) == "cards"){
                list lCards = llJson2List(llJsonGetValue(m,["cards"]));
                g_lJudgePile += lCards;
                g_iTotalJudgeUsers++;
                
                if(g_iTotalJudgeUsers == llGetListLength(Players)-1){
                    llSay(hud_channel, llList2Json(JSON_OBJECT, ["type", "judging", "table", g_kID]));
                    llSay(0, "Card Czar: Pick the card you want!");
                    // Initiate the rezzing procedure
                    integer x =0;
                    integer e = llGetListLength(g_lJudgePile);
                    for(x=0;x<e;x++){
                        integer bootNum = llRound(llFrand(34857483));
                        string json = llList2String(g_lJudgePile, x);
                        key user = llJsonGetValue(json, ["user"]);
                        g_lPendingCards += [bootNum, (string)user+"|"+llJsonGetValue(json,["text"])];
                        
                        
                        llRezObject("Playing Card [LS]", llGetPos(), ZERO_VECTOR,ZERO_ROTATION, bootNum);
                    }
                }
            }
        } else if(c==card_channel){
            if(llJsonGetValue(m,["type"])=="alive"){
                //llSay(0, "IN ALIVE BLOCK");
                integer index = llListFindList(g_lPendingCards,[(integer)llJsonGetValue(m,["boot"])]);
                if(index==-1){
                    return;
                }
                
                string pendingCommand = llList2String(g_lPendingCards,index+1);
                list lCmd = llParseString2List(pendingCommand, ["|"],[]);
                
                g_lPendingCards = llDeleteSubList(g_lPendingCards,index,index+1);
                
                llRegionSayTo(i, (integer)llJsonGetValue(m,["boot"]), llList2Json(JSON_OBJECT, ["type", "activate", "table", g_kID]));
                // Calculate position offset
                llSleep(1);
                if(llList2String(lCmd,0) == "null"){
                    offset = 0.0;
                }
                llRegionSayTo(i, card_channel, llList2Json(JSON_OBJECT, ["type", "position", "pos", llGetPos()+<0,offset,0.75>]));
                if(DEBUG)llSay(0, "Alive request on the Cards Channel: "+m);
                
                string color = "1";
                offset += 0.25;
                string cmd= "GET_CARD";
                if(llList2String(lCmd,1) != "black"){
                    //cmd = "SEARCH&CARD_TEXT="+llStringToBase64(llList2String(lCmd,1))+"&AVATAR="+llList2String(lCmd,0);
                    color="0";
                    llRegionSayTo(i, card_channel, llList2Json(JSON_OBJECT, ["type", "set","card", llList2Json(JSON_OBJECT, ["text", llList2String(lCmd,1), "color", 0, "num", 0, "czar", llList2String(Players, g_iCzar), "user", llList2String(lCmd,0)])]));
                    return;
                }
                Send("/Modify_Card.php?TYPE_OVERRIDE="+cmd+"&TABLE_ID="+(string)g_kID+"&COLOR="+color+"&DRAW_COUNT=1&SENDER="+(string)i+"&REZZED=1", "POST");



            } else if(llJsonGetValue(m,["type"]) == "final"){
                key kUser = (key)llJsonGetValue(m,["user"]);
                GiveUserPoint(kUser);
                llWhisper(0, "secondlife:///app/agent/"+(string)kUser+"/about won the round and gets the point.");
                
                llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID]));
                // Start next round!
                // Load the next black card to trigger selection mode
                integer boot = llRound(llFrand(5483758));
                g_lPendingCards += [boot, "null|black"];
                
                integer x =0;
                integer ends = llGetListLength(g_lJudgePile);
                g_iTotalJudgeUsers = 0;
                for(x=0;x<ends;x++){
                    string card = llList2String(g_lJudgePile,x);
                    Send("/Modify_Card.php?TYPE_OVERRIDE=INSERT&TABLE_ID="+(string)g_kID+"&CARD_TEXT="+llStringToBase64(llJsonGetValue(card,["text"])), "POST");
                }
                
                g_lJudgePile=[];
                llRezObject("Playing Card [LS]", llGetPos(), ZERO_VECTOR,ZERO_ROTATION,boot);
            }
        } else if(llListFindList(g_lListener,[c])!=-1){
            integer index = llListFindList(g_lListener,[c]);
            index--;
            if(m == "Female"){
                llStartAnimation("female");
            } else {
                llStartAnimation("male");
            }
            
            llListenRemove(llList2Integer(g_lListener,index+2));
            g_lListener=llDeleteSubList(g_lListener,index,index+2);
            
        }
    }
    
    changed(integer t){
        if(t&CHANGED_REGION_START){
            llResetScript();
        } else if(t&CHANGED_LINK){
            Rescan();
        }
    }
    
    on_rez(integer t){
        llResetScript();
    }
    
    timer(){
        Sends();
    }
    
    touch_start(integer t){
        string name = llGetLinkName(llDetectedLinkNumber(0));
        if(name == "START"){
            if(g_iStarted)return;
            g_iStarted=TRUE;
            if(!(llGetListLength(Players) > 1)){
                llSay(0, "Must have more than 1 player to start!");
                return;
            }
            // Begin the game loop
            llSetTimerEvent(5);
            integer chan = llRound(llFrand(548378));
            g_lPendingCards += [chan, "null|black"];
            llRezObject("Playing Card [LS]", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, chan);
        } else if(name == "ANIM"){
            key i = llDetectedKey(0);
            
            integer rnd = llRound(llFrand(5843758));
            g_lListener += [i,rnd,llListen(rnd,"",i,"")];
            llDialog(i, "Are you male or female?", ["Female", "Male"], rnd);
            
            llRequestPermissions(i, PERMISSION_TRIGGER_ANIMATION);
        } else if(name == "STOP"){
            if(g_iStarted){
                Send("/Modify_Card.php?TYPE_OVERRIDE=NULCARD&TABLE_ID="+(string)g_kID,"GET");
                llSay(0, "Stopping the game please wait...");
            }
        }
    }
}