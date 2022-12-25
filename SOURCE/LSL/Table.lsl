
integer ingredient_channel = -8392888;
integer containerChannel = -8392891;
integer updater_channel = 15418070;
integer card_channel = -32988199;
integer hud_channel = -328478727;

integer g_iSelectNum;
list g_lPoints;
integer g_iStarted;
integer g_iExpectDeckLoad;

list StrideOfList(list src, integer stride, integer start, integer end)
{
    list l = [];
    integer ll = llGetListLength(src);
    if(start < 0)start += ll;
    if(end < 0)end += ll;
    if(end < start) return llList2List(src, start, start);
    while(start <= end)
    {
        l += llList2List(src, start, start);
        start += stride;
    }
    return l;
}


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

SetupDeck(){
    string deckStr;
    list decks;
    integer i=0;
    integer end = llGetListLength(g_lSelectedDecks);
    for(i=0;i<end;i+=2){
        if((integer)(llList2String(g_lSelectedDecks,i+1)))decks+=llList2String(g_lSelectedDecks,i);
    }
    deckStr=llDumpList2String(decks, ",");
    llMessageLinked(LINK_SET, 50, deckStr, "8");
    Send("/Modify_Card.php?TYPE_OVERRIDE=MAKE_DECK&TABLE_ID="+(string)g_kID+"&DECKS="+deckStr, "POST");
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
list g_lSelectedDecks = ["OFFICIAL",1];

string g_sVersion = "1.0.0.0005";
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
    //if(DEBUG)llSay(0, "SENDING "+llList2String(g_lReqs,1)+" REQUEST: "+URL+llList2String(g_lReqs,0));
    
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
                llMessageLinked(LINK_SET, 50, (string)llGetLinkKey(i), "9");
                llInstantMessage(llGetLinkKey(i), "Rezzing a HUD. Please accept attachment permissions");
                REZ(llGetLinkKey(i));
            }
            llSetLinkPrimitiveParams(i, [PRIM_POS_LOCAL, llList2Vector(ChairParams,0)+<0,0,1>+(vector)llList2String(ChairData,1), PRIM_ROT_LOCAL, llEuler2Rot((vector)llList2String(ChairData,0)*DEG_TO_RAD)]);
        }
    }
    
    Compare(OldPlayers);
    Evict(ToEvict);
    
    if(llGetListLength(Players)==0 && llGetListLength(OldPlayers)!=0){
        llMessageLinked(LINK_SET, 50, "", "10");
        llSleep(1);
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
            llMessageLinked(LINK_SET, 50, llList2String(OldList,i), "11");
            //llMessageLinked(LINK_SET, 50, "", "11");
            
            integer pointIndex = llListFindList(g_lPoints, [llList2Key(OldList,i)]);
            if(pointIndex!=-1){
                g_lPoints=llDeleteSubList(g_lPoints, pointIndex,pointIndex+1);
            }
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
integer g_iHaiku;
integer g_iCurRow=1;

AddLogEntry(string from, string to, integer cost, string notes){
    Send("/Logger.php?LOG_TYPE=ADD&ORIGIN="+llEscapeURL(from)+"&DESTINATION="+llEscapeURL(to)+"&PRICE="+(string)cost+"&NOTES="+llStringToBase64(notes), "POST");
}
default
{
    state_entry()
    {
        llMessageLinked(LINK_SET,-1,"","");
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
        
        llMessageLinked(LINK_SET, 50, "", "12");
        g_kID = (key)llGetObjectDesc();
        if(g_kID == "new_lsk"){
            llListen(99, "", llGetOwner(), "");
            llDialog(llGetOwner(), "Is this a new table or a upgraded one?", ["New", "Upgrade"], 99);
            
            /*g_kID = llGenerateKey();
            llSetObjectDesc((string)g_kID);
            llSay(0, "First Rez! Thank you for your purchase of an LS Bionics product!\n \n[Generating License Key]");
            llSetObjectName("Cards Against Humanity [LS]");
            Send("/Put_Product_Data.php?PRODUCT=CAH_TABLE&KEYID="+(string)g_kID+"&NICKNAME=License&DATA=1","POST");
            return;*/
            return;
        }
        llWhisper(card_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID]));
        llWhisper(hud_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID, "avatar", NULL_KEY]));
        Evict(Players);
        
        
        llMessageLinked(LINK_SET, 0, "", g_kID);
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
    
    listen(integer c,string n,key i,string m){
        if(c==99){
            if(m == "New"){
                g_kID = llGenerateKey();
                llSetObjectDesc((string)g_kID);
                llMessageLinked(LINK_SET, 50, "", "13");
                llSetObjectName("Cards Against Humanity [LS]");
                Send("/Put_Product_Data.php?PRODUCT=CAH_TABLE&KEYID="+(string)g_kID+"&NICKNAME=License&DATA=1", "POST");
                llResetScript();
            } else if(m == "Upgrade"){
                llListen(ingredient_channel+1, "", "", "");
                llSay(ingredient_channel, "scan");
                llWhisper(0, "Scanning for settings");
                return;
            }
        } else if(c==ingredient_channel+1){
            if(m == "rezzed CAH_TABLE" || m == "CAH_TABLE"){
                llSetObjectDesc(llList2String(llGetObjectDetails(i,[OBJECT_DESC]),0));
                llMessageLinked(LINK_SET, 50, "", "14");
                llRegionSayTo(i, ingredient_channel, (string)i);
                llResetScript();
            }
        }
    }
    
    on_rez(integer t){
        llResetScript();
    }
    
    link_message(integer s,integer n,string m,key i){
        if(n==1){
            g_lSelectedDecks = llParseString2List(m,["~"],[]);
            state active;
        }
    }
}

state active
{
    state_entry(){
        llSay(0, "Game Table now ready ("+(string)llGetFreeMemory()+"b)");
        SetupDeck();
        g_iBlockRez=0;
        g_lPending=[];
        
        llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID]));
        llListen(hud_channel, "", "", "");
        llListen(ingredient_channel+1, "", "", "");
        llListen(updater_channel, "", "", "");
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
            //if(DEBUG)llSay(0, "HTTP REPLY: "+b);
            string Script = llList2String(lTmp,0);
            if(Script == "Modify_Deck"){
                llMessageLinked(LINK_SET, 50, llList2String(lTmp,3), "15");
            } else if(Script == "Get_Card"){
                key Sender = (key)llList2String(lTmp,1);
                list Params = llJson2List(llBase64ToString(llList2String(lTmp,2)));
                //if(DEBUG)llSay(0, "PARAMETER LIST: "+llList2CSV(Params));

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
                            llMessageLinked(LINK_SET, 50, "", "16");
                            if(g_iCzar == -1){
                                llMessageLinked(LINK_SET, 50, "", "17");
                                g_iCzar = llRound(llFrand(llGetListLength(Players)));
                            } else {
                                g_iCzar++;
                                if(g_iCzar >= llGetListLength(Players)){
                                    g_iCzar = 0;
                                }
                            }
                            
                            key czar = llList2String(Players,g_iCzar);
                            llMessageLinked(LINK_SET, 50, (string)czar, "18");
                            
                            llRegionSay(hud_channel, llList2Json(JSON_OBJECT, ["type", "select", "czar", czar, "sel_count", num_req, "table", g_kID]));
                            llMessageLinked(LINK_SET, 50, card_text, "19");
                            if(card_text == "Make a haiku.")g_iHaiku=1;
                            
                            if(g_iHaiku){
                                llMessageLinked(LINK_SET, 50, "", "20");
                            }
                            llRegionSay(hud_channel, llList2Json(JSON_OBJECT, ["type", "czar", "card", card_text, "num", num_req]));

                            g_iSelectNum = num_req;
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
                
                //if(DEBUG)llSay(0, "SEARCH RESULT: "+Text);
            } else if(Script == "No More Cards"){
                
                llMessageLinked(LINK_SET, 50, "", "21");
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
            } else if(Script == "Modify_Product"){
                if(llList2String(lTmp,1)=="Cards Against Humanity [LS]"){
                    if(g_sVersion != llList2String(lTmp,2)){
                        AddLogEntry(llKey2Name(llGetOwner()), "SYSTEM", 0, "Request delivery of product update: "+llGetObjectName());
                        llRegionSayTo(g_kToken,updater_channel,(string)g_kToken);
                        Send("/Get_Server_URL.php?NAME=Products","GET");
                        llMessageLinked(LINK_SET, 50, "", "22");
                    } else {
                        llRegionSayTo(g_kToken, updater_channel, "no_update");
                        llWhisper(0, "I am up to date");
                    }
                }
            } else if(Script == "Get_Server_URL"){
                if(llList2String(lTmp,1)=="Products"){
                    llHTTPRequest(llList2String(lTmp,2), [HTTP_METHOD,"POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], llList2Json(JSON_OBJECT, ["creator", llGetInventoryCreator(llGetScriptName()), "owner", llGetOwner(), "product", "Cards Against Humanity [LS]"]));
                    state ingred;
                }
            }
            
            
            Sends();
        }
    }
    
    listen(integer c,string n,key i, string m){
        //if(DEBUG)            llSay(0, "LISTEN: "+llDumpList2String([c,n,i,m], " - "));
        if(c==hud_channel){
            if(llJsonGetValue(m,["type"])=="card_request"){
                integer card_count = (integer)llJsonGetValue(m,["count"]);
                Send("/Modify_Card.php?TYPE_OVERRIDE=GET_CARD&TABLE_ID="+(string)g_kID+"&COLOR=0&DRAW_COUNT="+(string)card_count+"&SENDER="+(string)i+"&REZZED=0", "POST");
            } else if(llJsonGetValue(m,["type"])=="alive"){
                integer index = llListFindList(g_lPending,[(integer)llJsonGetValue(m,["boot"])]);
                if(index==-1)return;
                else {
                    // Boot the HUD
                    //if(DEBUG)llSay(0, "Sending HUD Activation signal");
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
                    llDialog(llList2Key(Players,g_iCzar), "[LS Bionics]\nCards Against Humanity\n\nINSTRUCTIONS: Click the card you want to pick twice, once to select, a second time to confirm. If you have to select more than 1 card, you must select the first card first, then the second card. Once the required number of cards have been selected, the others will automatically de-rez and a new black card will be generated.\n\nPlay: "+(string)g_iSelectNum+" card(s)", ["-exit-"], -3999);
                    // Initiate the rezzing procedure
                    integer x =0;
                    integer e = llGetListLength(g_lJudgePile);
                    g_lJudgePile = llListRandomize(g_lJudgePile, 1);
                    for(x=0;x<e;x++){
                        integer bootNum = llRound(llFrand(34857483))+llRound(llFrand(45372));
                        string json = llList2String(g_lJudgePile, x);
                        key user = llJsonGetValue(json, ["user"]);
                        g_lPendingCards += [bootNum, (string)user+"|"+llJsonGetValue(json,["text"])];
                        g_lJudgePile = llDeleteSubList(g_lJudgePile,x,x);
                        x=-1;
                        e=llGetListLength(g_lJudgePile);
                        
                        llRezObject("Playing Card [LS]", llGetPos(), ZERO_VECTOR,ZERO_ROTATION, bootNum);
                    }
                }
            }
        } else if(c==card_channel){
            if(llJsonGetValue(m,["type"])=="alive"){
                //llSay(0, "IN ALIVE BLOCK");
                integer index = llListFindList(g_lPendingCards,[(integer)llJsonGetValue(m,["boot"])]);
                if(index==-1){
                    //llWhisper(0, "Bootup value not found: "+llJsonGetValue(m,["boot"]));
                    return;
                }
                
                string pendingCommand = llList2String(g_lPendingCards,index+1);
                list lCmd = llParseString2List(pendingCommand, ["|"],[]);
                
                g_lPendingCards = llDeleteSubList(g_lPendingCards,index,index+1);
                g_lPendingCards = llListRandomize(g_lPendingCards, 2);
                
                // Calculate position offset
                if(llList2String(lCmd,0) == "null"){
                    offset = 0.0;
                }
                vector relativeBase = <-0.43321, -0.44624, 0.54937>;
                float addtlRowOffset = 0.3;
                
                if(g_iSelectNum>1){
                    if(g_iCurRow == 1)addtlRowOffset=0;
                    else
                        addtlRowOffset = addtlRowOffset * (g_iCurRow-1);
                }
                else addtlRowOffset = 0;
                
                
                vector relativePos = relativeBase;
                relativePos.y += offset;
                relativePos.x += addtlRowOffset;
                relativePos = relativePos * llGetLocalRot();
                relativePos += llGetPos();
                //llWhisper(0, "Rez card to position for boot ("+llJsonGetValue(m,["boot"])+") : "+(string)relativePos);
                llRegionSayTo(i, (integer)llJsonGetValue(m,["boot"]), llList2Json(JSON_OBJECT, ["type", "activate", "table", g_kID, "pos", relativePos, "rot", llGetRot()]));
                //if(DEBUG)llSay(0, "Alive request on the Cards Channel: "+m);
                
                string color = "1";
                if(g_iSelectNum > 1){
                    if(g_iCurRow >= g_iSelectNum || g_iCurRow == 4){
                        offset += 0.2;
                        g_iCurRow = 1;
                    } else {
                        g_iCurRow++;
                    }
                } else 
                    offset += 0.25;
                
                string cmd= "GET_CARD";
                llSleep(3);
                if(llList2String(lCmd,1) != "black"){
                    //cmd = "SEARCH&CARD_TEXT="+llStringToBase64(llList2String(lCmd,1))+"&AVATAR="+llList2String(lCmd,0);
                    color="0";
                    llRegionSayTo(i, card_channel, llList2Json(JSON_OBJECT, ["type", "set","card", llList2Json(JSON_OBJECT, ["text", llList2String(lCmd,1), "color", 0, "num", 0, "czar", llList2String(Players, g_iCzar), "user", llList2String(lCmd,0)])]));
                    
                    //Send("/Modify_Card.php?TYPE_OVERRIDE=INSERT&TABLE_ID="+(string)g_kID+"&CARD_TEXT="+llEscapeURL(llStringToBase64(llList2String(lCmd,1))), "POST");
                    
                    // remove this card from judge pile
                    return;
                }
                Send("/Modify_Card.php?TYPE_OVERRIDE="+cmd+"&TABLE_ID="+(string)g_kID+"&COLOR="+color+"&DRAW_COUNT=1&SENDER="+(string)i+"&REZZED=1", "POST");



            } else if(llJsonGetValue(m,["type"]) == "final"){
                key kUser = (key)llJsonGetValue(m,["user"]);
                GiveUserPoint(kUser);
                g_iSelectNum--;
                g_iCurRow=1;
                
                if(g_iSelectNum == 0){
                
                    llMessageLinked(LINK_SET, 50, (string)kUser, "23");
                    
                    llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID]));
                    // Start next round!
                    // Load the next black card to trigger selection mode
                    if(!g_iHaiku){
                        integer boot = llRound(llFrand(5483758));
                        g_lPendingCards += [boot, "null|black"];
                        
                        /*integer x =0;
                        integer ends = llGetListLength(g_lJudgePile);
                        g_iTotalJudgeUsers = 0;
                        for(x=0;x<ends;x++){
                            string card = llList2String(g_lJudgePile,x);
                            Send("/Modify_Card.php?TYPE_OVERRIDE=INSERT&TABLE_ID="+(string)g_kID+"&CARD_TEXT="+llEscapeURL(llStringToBase64(llJsonGetValue(card,["text"]))), "POST");
                        }*/
                        
                        g_lJudgePile=[];
                        g_iTotalJudgeUsers=0;
                        llRezObject("Playing Card [LS]", llGetPos(), ZERO_VECTOR,ZERO_ROTATION,boot);
                    } else {
                        Send("/Modify_Card.php?TYPE_OVERRIDE=NULCARD&TABLE_ID="+(string)g_kID,"GET");
                    }
                } else {
                    g_iTotalJudgeUsers=0;
                    llRegionSayTo(i,card_channel, llList2Json(JSON_OBJECT, ["type", "die", "table", g_kID]));
                    llMessageLinked(LINK_SET, 50, (string)kUser, "23");
                    llMessageLinked(LINK_SET, 50, (string)g_iSelectNum, "24");
                }
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
            
        } else if(c==ingredient_channel+1){
            if(m == "rezzed Deck" || m == "Deck"){
                if(g_iExpectDeckLoad){
                    g_iExpectDeckLoad = 0;
                    string Deck = llList2String(llGetObjectDetails(i,[OBJECT_DESC]),0);
                    llWhisper(0, "Activating deck...");
                    llMessageLinked(LINK_SET,5,Deck,"");
                    llRegionSayTo(i, ingredient_channel, (string)i);
                    
                    llWhisper(0, "Deck activated!");
                }
            }
        } else if(c == updater_channel){
            if(m == "scan"){
                llRegionSayTo(i,c,"reply|CAH");
            } else if(m == "check"){
                llWhisper(0, "Checking for update..");
                g_kToken=i;
                Send("/Modify_Product.php?NAME="+llEscapeURL("Cards Against Humanity [LS]"), "GET");
            }
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
        
        if(llGetTime()>=15.0 && g_iExpectDeckLoad){
            g_iExpectDeckLoad=0;
            llWhisper(0, "No nearby deck found");
        }
    }
    
    touch_start(integer t){
        string name = llGetLinkName(llDetectedLinkNumber(0));
        if(name == "START"){
            if(g_iStarted)return;
            g_iStarted=TRUE;
            llMessageLinked(LINK_SET,11,"","");
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
    
    link_message(integer s,integer n,string m,key i){
        if(n==-2){
            llResetScript();
        } else if(n == 10){
            g_iExpectDeckLoad=1;
            llResetTime();
            llSay(ingredient_channel, "scan");
            llWhisper(0, "Scanning for a deck of cards");
        }
    }
}

state ingred
{
    state_entry(){
        llSetTimerEvent(0);
        llListen(ingredient_channel, "", "", "");
        llSetText("Cards Against Humanity Settings\n----\nQuantity: 1", <0,1,0>,1);
    }
    on_rez(integer t){
        llListen(ingredient_channel, "", "", "");
    }
    
    changed(integer c){
        if(c&CHANGED_REGION_START){
            llListen(ingredient_channel, "", "", "");
        }
    }
    
    listen(integer c,string n,key i,string m){
        if(m == "scan"){
            llRegionSayTo(i,ingredient_channel+1, "CAH_TABLE");
        }else if(m == (string)llGetKey()){
            llDie();
        }
    }
    
    touch_start(integer t){
        llSay(0, "Cards Against Humanity Settings\n___\nQuantity: 1");
        llSay(ingredient_channel+1, "CAH_TABLE");
    }
}