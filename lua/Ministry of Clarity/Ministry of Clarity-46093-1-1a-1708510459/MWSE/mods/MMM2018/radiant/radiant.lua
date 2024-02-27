local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		print("[Ministry of Clarity: DEBUG] " .. string)
	end
end

--[[
	Radiant Quest
	Create a radiant quest with random components and overwrite the CS quest entries
]]--
local common = require("MMM2018.radiant.common")
local this = {} --Use this so I know when I'm using outer scope variables
this.questObjects = require("MMM2018.radiant.quests")

local isInJournal

--Generate quest if needed and update dialogue
local function updateEntry(e, questType, entryType)

    debugMessage("Entering updateEntry") 
    local currentQuestObject = this.questObjects[questType]
    local currentQuestData = common.getCurrentQuestData(questType)
    --If we don't have a quest yet, generate one and start tracking
    if  tes3ui.findMenu(tes3ui.registerID("MenuDialog")) then 
        if ( not currentQuestData ) or ( not currentQuestData.entries ) or ( currentQuestData.status == "notStarted" ) then
            debugMessage("Generating new quest for quest type " .. questType) 
            currentQuestData = currentQuestObject.generateQuest()
            currentQuestObject.startTrackingQuest()
        end
    end    
    --update text
    local newEntry = currentQuestData.entries[entryType]
    e.text = newEntry or "QUEST ENTRY MISSING"

end


local function dataReady(e)
	--Register events for all entries within each quest
	for questType,questObject in pairs(this.questObjects) do
		debugMessage("loading questdata for " .. questType )
		local csEntries = questObject.getCSEntries()
		for entryType,entry in pairs(csEntries) do
			debugMessage("Registering event for " .. entryType .. ", questType " .. questType)
			event.register("infoGetText", function(e) updateEntry(e, questType, entryType) end, { filter = entry } )
		end
	end
    --Start tracking existing quests
    
    
    --Begin tracking for active quests
    for questType, quest in pairs(this.questObjects) do
        local currentQuestData = common.getCurrentQuestData(questType)	
        if currentQuestData.entries then
            debugMessage("startTrackingQuest - questType: " .. questType)
            this.questObjects[questType].startTrackingQuest()
        end
    end
end

event.register("Radiant:dataReady", dataReady )