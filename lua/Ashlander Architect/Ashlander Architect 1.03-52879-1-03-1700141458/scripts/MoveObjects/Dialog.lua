
local ui = require("openmw.ui")


local randomLines = {
    "I wonder what time it is...",
    "When do you think it will start getting colder?",
    "Well, hello there! Great to see you!",
    "We sure could use some more food here! Just kidding.",
    "Hello Mayor!",
    "How are you?",


}
local TypeTable = { {
    MarkerID = "zhac_jbmarker_alchemist",
    NPCPostfix = "al",
    FriendlyName = "Alchemist"
}, {
    MarkerID = "zhac_jbmarker_blacksmith",
    NPCPostfix = "bl",
    FriendlyName = "Blacksmith"
}, {
    MarkerID = "zhac_jbmarker_bookseller",
    NPCPostfix = "bo",
    FriendlyName = "Bookseller"
}, {
    MarkerID = "zhac_jbmarker_caravaneer",
    NPCPostfix = "ca",
    FriendlyName = "Caravaneer"
}, {
    MarkerID = "zhac_jbmarker_clothier",
    NPCPostfix = "cl",
    FriendlyName = "Clothier"
}, {
    MarkerID = "zhac_jbmarker_enchanter",
    NPCPostfix = "En",
    FriendlyName = "Enchanter"
}, {
    MarkerID = "zhac_jbmarker_gguide",
    NPCPostfix = "gg",
    FriendlyName = "Guild Guide"
}, {
    MarkerID = "zhac_jbmarker_healer",
    NPCPostfix = "he",
    FriendlyName = "Healer"
}, {
    MarkerID = "zhac_jbmarker_publican",
    NPCPostfix = "pu",
    FriendlyName = "Publican"
}, {
    MarkerID = "zhac_jbmarker_shipmaster",
    NPCPostfix = "sh",
    FriendlyName = "Shipmaster"
}, {
    MarkerID = "zhac_jbmarker_sorcerer",
    NPCPostfix = "so",
    FriendlyName = "Sorcerer"
}, {
    MarkerID = "zhac_jbmarker_trader",
    NPCPostfix = "tr",
    FriendlyName = "Trader"
} }

local function sayGreeting(actorRecord,playerRecord,jobSiteData)

    if jobSiteData and jobSiteData.FriendlyName == "Clothier" then

        ui.showMessage("Hello! I'm "..actorRecord.name .. ".")
        ui.showMessage("Are you needing some clothing? I think I can help.")
    elseif jobSiteData and jobSiteData.FriendlyName == "Trader" then
    
            ui.showMessage("Hello! I'm "..actorRecord.name .. ".")
            ui.showMessage("I've got a lot of random things. Perhaps you'll find some of it useful for growing our town!")
        elseif jobSiteData and jobSiteData.FriendlyName == "Enchanter" then
        
                ui.showMessage("Hello! I'm "..actorRecord.name .. ".")
                ui.showMessage("I've got some magic scrolls! Just for you.")
    else
        local lineToUse = math.random(1,#randomLines)
        ui.showMessage(randomLines[lineToUse])
   
    end

end

return{sayGreeting = sayGreeting}