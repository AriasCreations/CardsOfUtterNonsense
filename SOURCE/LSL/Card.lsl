
integer card_channel = -32988199;

string g_sText="NA";
integer g_iStart;
key g_kTable;
integer genericListen = -1;
key g_kUser= NULL_KEY;
key g_kCzar = NULL_KEY;
integer g_iInitialized;
integer g_iConfirm;
default
{
    state_entry()
    {
        llMessageLinked(LINK_SET,0,"","fw_reset");
        llSetLinkColor(LINK_ROOT, <1,1,1>,1);
        llSetLinkColor(LINK_ROOT, <1,1,1>,0);
        genericListen = llListen(card_channel, "", "", "");
        llWhisper(0, "You must not rez this card by itself!");
    }
    
    on_rez(integer t){
        if(t==0){
            llResetScript();
        }else{
            llListenRemove(genericListen);
            genericListen = llListen(card_channel, "", "", "");
            //llSay(0, "Card is trying to find a table");
            llListen(t, "", "", "");
            g_iStart=t;
            //llSleep(2+llFrand(5));
            llSetTimerEvent(1);
            llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "alive", "boot", t]));
        }
    }
    
    touch_start(integer t){
        if(llDetectedKey(0) == g_kCzar){
            if(!g_iConfirm){
                llWhisper(0, g_sText);
                llSay(0, "Touch this card again to confirm you want to select this card as winner for this round!");
                llSetColor(<0,1,0>,2);
                llSetTexture(TEXTURE_BLANK, 2);
                
                llResetTime();
                llSetTimerEvent(1);
            }
            g_iConfirm++;
            
            if(g_iConfirm==2){
                llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "final", "user", g_kUser, "text", g_sText]));
            }
        }
    }
    
    timer(){
        if(llGetTime()>=10.0 && g_iInitialized){
            g_iConfirm=0;
            llSetColor(ZERO_VECTOR,2);
            llSetTexture(TEXTURE_TRANSPARENT,2);
            llSetTimerEvent(0);
        }
        
        if(!g_iInitialized && llGetTime()>=5.0){
            llResetTime();
            llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "alive", "boot", g_iStart]));
        }
    }
    
    listen(integer c,string n,key i,string m){
        if(c == g_iStart){
            if(llJsonGetValue(m, ["type"]) == "activate" && !g_iInitialized){
                g_kTable = (key)llJsonGetValue(m,["table"]);
                llListen(card_channel, "", i, "");
                llListenRemove(genericListen);
                llMessageLinked(LINK_SET,0,"","fw_reset");
                g_iInitialized=1;
                llSetPos((vector)llJsonGetValue(m,["pos"]));
                llSetRot((rotation)llJsonGetValue(m,["rot"]));
            }
        } else if(c == card_channel){
            if(llJsonGetValue(m,["type"]) == "position"){
                llSetPos((vector)llJsonGetValue(m,["pos"]));
                llSetRot((rotation)llJsonGetValue(m,["rot"]));
            } else if(llJsonGetValue(m,["type"]) == "rotation"){
                llSetRot((rotation)llJsonGetValue(m,["rot"]));
            } else if(llJsonGetValue(m,["type"]) == "set" && g_sText == "NA"){
                string text = llJsonGetValue(m,["card", "text"]);
                integer color = (integer)llJsonGetValue(m,["card","color"]);
                integer num = (integer)llJsonGetValue(m,["card", "num"]);
                g_kUser = (key)llJsonGetValue(m,["card", "user"]);
                g_kCzar = (key)llJsonGetValue(m,["card","czar"]);
                
                if(color){
                    // black
                    llSetLinkColor(LINK_ROOT, <0.2,0.2,0.2>, 1);
                    llSetLinkColor(LINK_ROOT, <0.2,0.2,0.2>, 0);
                    
                    llMessageLinked(LINK_SET, 0, "c=white", "fw_conf");
                }else {
                    llSetLinkColor(LINK_ROOT, <1,1,1>,1);
                    llSetLinkColor(LINK_ROOT, <1,1,1>,0);
                    llMessageLinked(LINK_SET,0,"c=black", "fw_conf");
                }
                g_sText=text;
                if(llStringLength(text)>128){
                    llSay(0, text);
                }
                llMessageLinked(LINK_SET,0,text, "fw_data : card_text");
                
                if(num > 1){
                    llMessageLinked(LINK_SET,0,"Pick ("+(string)num+")\nDraw ("+(string)num+")", "fw_data : card_helpertext");
                } else {
                    llMessageLinked(LINK_SET,0,"Cards Against Humanity", "fw_data : card_helpertext");
                }
            } else if(llJsonGetValue(m, ["type"]) == "die"){
                llDie();
            }
        }
    }
}
