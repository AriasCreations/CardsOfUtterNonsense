string g_sPath;
integer g_iColor;
integer g_iNum;
string g_sText;
key g_kAuthor;

integer g_iChan;
integer g_iLstn;
default
{
    state_entry()
    {
        llMessageLinked(LINK_SET,0,"","fw_reset");
    }

    changed(integer x){
        if(x&CHANGED_REGION_START){
            llResetScript();
        }
    }

    on_rez(integer t){
        if(t == 0){
            llResetScript();
        }
    }

    link_message(integer s,integer n,string m,key i){
        if(n==0){
            if(i=="fw_ready"){
                g_sPath = "/";
                llMessageLinked(LINK_SET,0,"c=black", "fw_conf : card_text");
                llMessageLinked(LINK_SET,0,"c=black", "fw_conf : card_helpertext");
                llSetLinkColor(LINK_ROOT, <1,1,1>, 0);
                llSetLinkColor(LINK_ROOT, <1,1,1>, 1);
                g_iChan = llRound(llFrand(54738577));
                g_iLstn = llListen(g_iChan, "", llGetOwner(), "");
                llDialog(llGetOwner(), "[Playing Card]\n\nIs this card supposed to be a black card or a white card?", ["White", "Black"], g_iChan);
            }
        }
    }

    listen(integer c,string n,key i,string m){
        if(g_sPath == "/"){
            if(m == "White"){
                g_iColor=0;
                llMessageLinked(LINK_SET,0,"Cards Against Humanity", "fw_data : card_helpertext");
                llTextBox(llGetOwner(), "[Playing Card]\n\nWhat text should be on the card?", g_iChan);
                g_sPath = "/text";
            } else if(m == "Black"){
                g_iColor=1;
                llMessageLinked(LINK_SET,0,"c=white","fw_conf : card_text");
                llMessageLinked(LINK_SET,0,"c=white","fw_conf : card_helpertext");
                llSetLinkColor(LINK_ROOT,<0.2,0.2,0.2>,1);
                llSetLinkColor(LINK_ROOT,<0.2,0.2,0.2>,0);

                g_sPath = "/num_req";
                llDialog(llGetOwner(), "[Playing Card]\n\nHow many cards do you want to require the player to draw?", ["1","2", "3", "4"], g_iChan);
            }
        } else if(g_sPath == "/text"){
            llMessageLinked(LINK_SET,0,m,"fw_data : card_text");
            g_sText = m;
            g_sPath = "/confirm";
            llDialog(llGetOwner(), "Does this card look correct?\n\nIf you select yes, your card will be uploaded to the community deck for this year. If you decide you no longer wish your card to be uploaded, you will need to contact ZNI Support", ["Yes", "No"], g_iChan);
        } else if(g_sPath == "/num_req"){
            g_iNum = (integer)m;
            g_sPath = "/text";
            if(g_iNum == 1){
                llMessageLinked(LINK_SET,0,"Cards Against Humanity", "fw_data : card_helpertext");
            }else llMessageLinked(LINK_SET,0,"Pick ("+(string)g_iNum+")\nDraw ("+(string)g_iNum+")", "fw_data : card_helpertext");
            llTextBox(llGetOwner(), "What text do you want on this card?", g_iChan);
        } else if(g_sPath == "/confirm"){
            if(m == "Yes"){
                llSay(0, "Uploading card...");
                list dat = llParseString2List(llGetDate(),["-"],[]);
                llSetObjectName("CAH: "+llList2String(dat,0)+" Playing Card [ZNI]");
                llSetObjectDesc("Card created by: "+llKey2Name(llGetOwner()));
                g_kAuthor = llGetOwner();
                string CARD_ID = (string)llGetOwner()+"-"+(string)llGetUnixTime();
                llHTTPRequest("https://api.zontreck.dev/zni/Modify_Card.php", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], "DECK="+llList2String(dat,0)+"&CARD_TEXT="+llStringToBase64(g_sText)+"&COLOR="+(string)g_iColor+"&DRAW_COUNT="+(string)g_iNum+"&CARD_ID="+llEscapeURL(CARD_ID));
                state myCard;
            } else if(m == "No"){
                llSay(0, "Card creation cancelled! Deleting temp data");
                llResetScript();
            }
        }
    }
}

state myCard
{
    state_entry(){
        llRemoveInventory("FURWARE text v2.0.1");
        llSay(0, "You now have the only permanent physical copy of this card on the grid as you are the card's creator!");
        llSay(0, "You can play with this card if you have this year's community deck purchased.");
        llSay(0, "NOTE: If you decide to remove this card from play in the community deck, you will need to send this physical card object to the LS support representative.");
        llSay(0, "(This card is now read-only. The required script for modification of the mesh text has been removed)");
    }
    touch_start(integer t){
        llSay(0, "/me created by secondlife:///app/agent/"+(string)g_kAuthor+"/about");
    }
}
