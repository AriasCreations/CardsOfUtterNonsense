default
{
    state_entry(){
        llSay(0, "Table Messages ready ("+(string)llGetFreeMemory()+"b)");
    }
    link_message(integer s,integer n,string m,key i){
        if(n == -1)
        {
            llResetScript();
        } else if(n == 50){
            integer val = (integer)((string)i);
            if(val == 1){
                llWhisper(0, "You cannot have no decks selected. The official deck will be automatically used as default when no decks are selected");
            } else if(val == 2){
                
                llSay(0, "You cannot change decks while a game is in progress! Stop the game first");
            } else if(val == 3){
                llSay(0, "Error received while waiting for a response from server");
            } else if(val == 4){
                llSay(0, "License is now activated!");
            } else if(val == 5){
                llWhisper(0, "Downloading list of decks...");
            } else if(val == 6){
                llSay(0, "ERROR: No valid license key has been found. Try again later, or contact LS Bionics support\n\n[Error code: "+m+"]");
            } else if(val == 7){
                llSay(0, "ERROR WHEN TOGGLING DECK. THIS IS A BUG. REPORT IT TO LS BIONICS (L:644)");
            } else if(val == 8){
                
                llSay(0, "Shuffling cards for decks: "+m);
            } else if(val == 9){
                llWhisper(0, "secondlife:///app/agent/"+m+"/about has joined the game!");
            } else if(val == 10){
                
                llSay(0, "All players left the game. Resetting game and shuffling cards!");
            } else if(val == 11){
                llSay(0, "secondlife:///app/agent/"+m+"/about has left the game");
            } else if(val == 12){
                llWhisper(0, "Stand by...");
            } else if(val == 13){
                llSay(0, "First Rez! Thank you for your purchase of an LS Bionics product!\n \n[Generating License Key]");
            } else if(val == 14){
                llWhisper(0, "Loaded Settings");
            } else if(val == 15){
                llSay(0, "Deck generated with total cards: "+m);
            } else if(val == 16){
                llSay(0, "A new black card has been played");
            } else if(val == 17){
                llSay(0, "This is a new game, assigning random card czar");
            } else if(val == 18){
                llSay(0, "Card Czar is: secondlife:///app/agent/"+m+"/about");
            } else if(val == 19){
                llSay(0, "Black Card: "+m);
            } else if(val == 20){
                llSay(0, "(ALERT) The Haiku card has been played. After this round the game will declare the winner(s)");
            } else if(val == 21){
                llSay(0, "Game over! No more black cards exist in the deck... Checking for winner...");
            } else if(val == 22){
                llWhisper(0, "Requesting product update delivery");
            } else if(val == 23){
                llWhisper(0, "secondlife:///app/agent/"+m+"/about receives a point");
            } else if(val == 24){
                
                llWhisper(0, "Card Czar: "+m+" more cards are required");
            }
        }
    }
}
