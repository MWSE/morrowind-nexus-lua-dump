local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[radiant common: DEBUG] " .. string)
	end
end
--[[
	Radiant common
	]]--
local this = {}
local currentQuestData = {}

function this.getCurrentQuestData(questType)
    --debugMessage("getCurrentQuestData - questType: " .. questType)
	return currentQuestData[questType] or {}
end
	
function this.setCurrentQuestData(questType, newQuestData)
	currentQuestData[questType] = newQuestData
    debugMessage("setCurrentQuestData - questType: " .. questType)
	return newQuestData
end
	
	
local function loaded(e)
	--Persistent data stored on player reference 
	-- ensure data table exists
	local data = tes3.getPlayerRef().data
	data.clarity_quests = data.clarity_quests or {}
	-- create outer scope shortcut
	currentQuestData = data.clarity_quests
	print("[Ministry Of Clarity] Radiant.lua loaded successfully")
	event.trigger("Radiant:dataReady")
end
	
	
event.register("loaded", loaded )

return this