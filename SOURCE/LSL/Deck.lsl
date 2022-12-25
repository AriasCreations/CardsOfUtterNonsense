
integer ingredient_channel = -8392888;

default
{
    state_entry()
    {
        llListen(ingredient_channel, "", "", "");
        llSetText("Deck of Cards\n-----\nQuantity: 1", <0,1,0>,1);
    }
    
    touch_start(integer t){
        llSay(0, llGetObjectDesc()+" Deck of Cards; Quantity: 1");
    }
    
    on_rez(integer t){
        llResetScript();
    }
    
    listen(integer c,string n,key i,string m){
        if(m == "scan"){
            llSay(c+1, "Deck");
        }else if(m == (string)llGetKey()){
            llDie();
        }
    }
}
