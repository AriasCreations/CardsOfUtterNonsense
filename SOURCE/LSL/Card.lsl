
integer card_channel = -32988199;

integer g_iStart;
key g_kTable;

default
{
    state_entry()
    {
        llMessageLinked(LINK_SET,0,"","fw_reset");
        llSetLinkColor(LINK_ROOT, <1,1,1>,1);
        llSetLinkColor(LINK_ROOT, <1,1,1>,0);
        llWhisper(0, "You must not rez this card by itself!");
    }
    
    on_rez(integer t){
        if(t==0){
            llResetScript();
        }else{
            llSay(0, "Card is trying to find a table");
            llListen(t, "", "", "");
            g_iStart=t;
            llSay(card_channel, llList2Json(JSON_OBJECT, ["type", "alive", "boot", t]));
        }
    }
    
    listen(integer c,string n,key i,string m){
        if(c == g_iStart){
            if(llJsonGetValue(m, ["type"]) == "activate"){
                llListen(card_channel, "", i, "");
                llMessageLinked(LINK_SET,0,"","fw_reset");
                g_kTable = (key)llJsonGetValue(m,["table"]);
            }
        } else if(c == card_channel){
            if(llJsonGetValue(m,["type"]) == "position"){
                llSetPos((vector)llJsonGetValue(m,["pos"]));
            } else if(llJsonGetValue(m,["type"]) == "rotation"){
                llSetRot((rotation)llJsonGetValue(m,["rot"]));
            } else if(llJsonGetValue(m,["type"]) == "set"){
                string text = llJsonGetValue(m,["card", "text"]);
                integer color = (integer)llJsonGetValue(m,["card","color"]);
                integer num = (integer)llJsonGetValue(m,["card", "num"]);
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
