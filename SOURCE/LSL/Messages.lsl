default
{
    state_entry(){
        llSetMemoryLimit(15000);
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
                llSay(0, "ERROR: No valid license key has been found. Try again later, or contact ZNI Support\n\n[Error code: "+m+"]");
            } else if(val == 7){
                llSay(0, "ERROR WHEN TOGGLING DECK. THIS IS A BUG. REPORT IT TO ZNI (L:644)");
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
                llSay(0, "First Rez! Thank you for your purchase of a ZNI product!\n \n[Generating License Key]");
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
            } else if(val == 25){
                llWhisper(0, "Sorry! secondlife:///app/agent/"+m+"/about please join the game during the judging phase while a card is being selected.");
            } else if(val == 26){
                llWhisper(0, "Restarting round, a player left before judging could begin. All submitted cards will be reinserted into the deck and shuffled");
            } else if(val == 27){
                llDialog(i,  "[ZNI]\nCards Against Humanity\n\nINSTRUCTIONS: Click the card you want to pick twice, once to select, a second time to confirm. If you have to select more than 1 card, you must select the first card first, then the second card. Once the required number of cards have been selected, the others will automatically de-rez and a new black card will be generated.\n\nPlay: "+m+" card(s)", ["-exit-"], -3999);
            }
        }
    }
}
