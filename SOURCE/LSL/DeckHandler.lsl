list g_lSelectedDecks= ["OFFICIAL",1];
DecksMenu(key id){    
    integer i=0;
    list Buttons = [];
    string Prompt;
    integer end = llGetListLength(g_lSelectedDecks);
    for(i=0;i<end;i+=2){
        Buttons+=cbox((integer)llList2String(g_lSelectedDecks,i+1), llList2String(g_lSelectedDecks,i));
    }
    if(g_iDecksListen!=-1){
        llListenRemove(g_iDecksListen);
    }
    g_iDecksChan = llRound(llFrand(5483785));
    g_iDecksListen = llListen(g_iDecksChan, "", llDetectedKey(0), "");
    llDialog(id, "[Cards Against Humanity]\n© ZNI 2021\n\nSelect the decks you wish to modify, when finished, select 'CONFIRM' to lock in your choices and combine the decks for use", Buttons+["CONFIRM", "LOAD"], g_iDecksChan);
}
string cbox(integer a, string b){
    if(a)return "[X] "+b;
    else return "[ ] "+b;
}

UploadCards(list lTmp){
    
    while(llGetListLength(lTmp)){
        // send card back to server
        Send("/Modify_Card.php?TYPE_OVERRIDE=INSERT&CARD_TEXT="+llEscapeURL(llJsonGetValue(llList2String(lTmp, 0), ["card", "text"]))+"&TABLE_ID="+(string)g_kID, "POST");
        lTmp = llDeleteSubList(lTmp, 0,0);
    }
}

key g_kID;
integer g_iDecksChan;
integer g_iDecksListen=-1;
UpDecks(){
    if(llGetListLength(g_lSelectedDecks)==0)    llMessageLinked(LINK_SET, 50, "", "1");
    Send("/Modify_Card.php?TYPE_OVERRIDE=SET_OPTIONS&TABLE_ID="+(string)g_kID+"&DECK="+llEscapeURL(llStringToBase64(llDumpList2String(g_lSelectedDecks, "~"))), "POST");
}



string g_sVersion = "1.0.0.0000";
integer DEBUG = TRUE;
list g_lReqs;
string URL = "https://api.zontreck.dev/zni";
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

key g_kCurrentReq = NULL_KEY;
DoNextRequest(){
    if(llGetListLength(g_lReqs)==0)return;
    list lTmp = llParseString2List(llList2String(g_lReqs,0),["?"],[]);
    //if(DEBUG)llSay(0, "SENDING REQUEST: "+URL+llList2String(g_lReqs,0));
    
    string append = "";
    if(llList2String(g_lReqs,1) == "GET")append = "?"+llDumpList2String(llList2List(lTmp,1,-1),"?");
    
    g_kCurrentReq = llHTTPRequest(URL + llList2String(lTmp,0) + append, [HTTP_METHOD, llList2String(g_lReqs,1), HTTP_MIMETYPE, "application/x-www-form-urlencoded"], llDumpList2String(llList2List(lTmp,1,-1),"?"));
}

integer g_iStarted;
integer g_iExpectDeckLoad=0;
integer ingredient_channel = -8392888;

default
{
    state_entry(){
        llSetMemoryLimit(35000);
        g_kID = (key)llGetObjectDesc();
        llWhisper(0, "Decks Handler ("+(string)llGetFreeMemory()+"b)");
        llListen(ingredient_channel+1, "", "", "");
    }
    
    link_message(integer s,integer n,string m,key i){
        if(n == 0){
            Send("/Get_Product_Data.php?PRODUCT=CAH_TABLE&NICKNAME=License&KEYID="+(string)i, "GET");
        } else if(n==-1)llResetScript();
        else if(n == -5){
            g_lSelectedDecks+=[m,1];
            UpDecks();
        } else if(n == -11){
            g_iStarted=1;
        } else if(n == -12){
            UploadCards(llJson2List(m));
        }
    }
    
    on_rez(integer t){
        llResetScript();
    } 
    
    changed(integer c){
        if(c&CHANGED_REGION_START)llResetScript();
        
        if(c&CHANGED_OWNER)llResetScript();
        
    }
    
    touch_start(integer t){
        string name = llGetLinkName(llDetectedLinkNumber(0));
        if(name == "DECKS"){
            if(g_iStarted){
                llMessageLinked(LINK_SET, 50, "", "2");
                return;
            }
            DecksMenu(llDetectedKey(0));
            
        }
    }
    http_response(key r,integer s,list m, string b){
        //llOwnerSay(b);
        if(s!=200){
            llSay(0, "Error code :"+(string)s);
            g_kCurrentReq=NULL_KEY;
            Sends();
            return;
        }
        if(r == g_kCurrentReq){
            if(s!=200){
                llMessageLinked(LINK_SET, 50, "", "3");
            }
            g_kCurrentReq = NULL_KEY;
            g_lReqs = llDeleteSubList(g_lReqs,0,1);
            
            list lTmp = llParseString2List(b,[";;",";"],[]);
            string Script = llList2String(lTmp,0);
            if(Script == "Get_Product_Data")
            {
                string Variable = llList2String(lTmp,1);
                if(Variable == "License"){
                    if(llList2String(lTmp,2) == "1"){
                        llMessageLinked(LINK_SET, 50, "", "4");
                        //state active;
                        llMessageLinked(LINK_SET, 50, "", "5");
                        Send("/Modify_Card.php?TYPE_OVERRIDE=OPTIONS&TABLE_ID="+(string)g_kID, "GET");
                       //Send("/Get_Product_Data.php?PRODUCT=CAH_TABLE&KEYID="+(string)g_kID+"&NICKNAME=Decks", "GET"); 
                    } else {
                        llMessageLinked(LINK_SET, 50, llList2String(lTmp,2), "6");
                    }
                }
            } else if(Script == "Card_Options"){
                g_lSelectedDecks = llParseString2List(llList2String(lTmp,1),["~"],[]);
                if(llList2String(lTmp,1) == "0"){
                    g_lSelectedDecks = ["OFFICIAL",1];
                    Send("/Modify_Card.php?TYPE_OVERRIDE=SET_OPTIONS&DECK="+llEscapeURL(llStringToBase64("OFFICIAL~1"))+"&TABLE_ID="+(string)g_kID,"POST");
                    Send("/Modify_Card.php?TYPE_OVERRIDE=OPTIONS&TABLE_ID="+(string)g_kID, "GET"); 
                    
                } else {
                    llMessageLinked(LINK_SET,1,llDumpList2String(g_lSelectedDecks,"~"),"");
                    llMessageLinked(LINK_SET,999,"","");
                }
                
            } else if(Script == "Set_Card_Options"){
                Send("/Modify_Card.php?TYPE_OVERRIDE=OPTIONS&TABLE_ID="+(string)g_kID,"GET");
            }
            
            Sends();
        }
    }
    
    timer(){
        if(llGetListLength(g_lSelectedDecks)==0){
            llMessageLinked(LINK_SET,-2,"","");
            llSetTimerEvent(0);
        }
        Sends();
        
        if(llGetTime()>=15.0 && g_iExpectDeckLoad){
            g_iExpectDeckLoad=0;
            llWhisper(0, "No nearby deck found");
        }
    }
    
    listen(integer c,string n,key i,string m){
         if(c == g_iDecksChan){
            list lPar = llParseString2List(m,["[", "] "], []);
            integer iNewDeck = 0;
            if(llList2String(lPar,0)=="X"){
                //Disable the deck
                iNewDeck = 0;
            } else {
                iNewDeck = 1;
            }
            
            integer pos = llListFindList(g_lSelectedDecks,[llList2String(lPar,1)]);
            if(pos==-1){
                if(m == "CONFIRM"){
                    llListenRemove(g_iDecksListen);
                    g_iDecksListen=-1;
                    UpDecks();
                    
                    llSetTimerEvent(5);
                } else if(m == "LOAD"){
                    g_iExpectDeckLoad=1;
                    llResetTime();
                    llSay(ingredient_channel, "scan");
                    llSetTimerEvent(1);
                    return;
                } else llMessageLinked(LINK_SET, 50, "", "7");
            } else {
                g_lSelectedDecks = llListReplaceList(g_lSelectedDecks, [iNewDeck], pos+1,pos+1);
            }
            
            
            DecksMenu(i);
        } else if(c==ingredient_channel+1){
            if(m == "rezzed Deck" || m == "Deck"){
                if(g_iExpectDeckLoad){
                    g_iExpectDeckLoad = 0;
                    string Deck = llList2String(llGetObjectDetails(i,[OBJECT_DESC]),0);
                    llWhisper(0, "Activating deck...");
                    llMessageLinked(LINK_SET,-5,Deck,"");
                    llRegionSayTo(i, ingredient_channel, (string)i);
                    
                    llWhisper(0, "Deck activated!");
                }
            }
        }
    }
            
}
