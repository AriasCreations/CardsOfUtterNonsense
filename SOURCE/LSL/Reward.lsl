
integer DEBUG = FALSE;
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
    //if(DEBUG)llSay(0, "SENDING "+llList2String(g_lReqs,1)+" REQUEST: "+URL+llList2String(g_lReqs,0));
    
    string append = "";
    if(llList2String(g_lReqs,1) == "GET")append = "?"+llDumpList2String(llList2List(lTmp,1,-1),"?");
    
    g_kCurrentReq = llHTTPRequest(URL + llList2String(lTmp,0) + append, [HTTP_METHOD, llList2String(g_lReqs,1), HTTP_MIMETYPE, "application/x-www-form-urlencoded"], llDumpList2String(llList2List(lTmp,1,-1),"?"));
}


key g_kID = NULL_KEY;
default
{
    state_entry()
    {
        llSetMemoryLimit(13000);
        llWhisper(0, "Game Rewards Ready ("+(string)llGetFreeMemory()+"b Free)");
        //llMessageLinked(LINK_SET, -30, "10", llGetOwner());
    }
    
    http_response(key r,integer s,list m,string b){
        //llWhisper(0, b);
        if(r==g_kCurrentReq){
            g_kCurrentReq=NULL_KEY;
            g_lReqs=llDeleteSubList(g_lReqs,0,1);
            
            list lTmp = llParseString2List(b,[";;",";"],[]);
            if(llList2String(lTmp,0)=="Get_Server_URL"){
                string URL = llList2String(lTmp,2);
                llHTTPRequest(URL, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], llList2Json(JSON_OBJECT, ["product", "Playing Card [ZNI]", "owner", g_kID]));
                llHTTPRequest(URL, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], llList2Json(JSON_OBJECT, ["product", "Playing Card [ZNI]", "owner", g_kID]));
                llMessageLinked(LINK_SET,-2,"","");
            }
            
            Sends();
        }
    }
    
    link_message(integer s,integer n,string m,key i){
        if(n==-30){
            integer points=(integer)m;
            if(points>=10){
                // begin
                llWhisper(0, "Stand by... sending reward : 2 Blank Cards");
                g_kID=i;
                Send("/Get_Server_URL.php?NAME=CRAFT", "GET");
            }else{
                llSay(0, "Sorry. A reward can only be sent if you won the game with 10 or more points. Try again next time!");
                llMessageLinked(LINK_SET,-2,"","");
            }
        }else if(n==-1){
            llResetScript();
        }
    }
}
