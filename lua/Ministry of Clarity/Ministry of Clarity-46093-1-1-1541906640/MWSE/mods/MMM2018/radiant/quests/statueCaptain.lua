local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[statueCaptain: DEBUG] " .. string)
	end
end
----------------------------------------------------------------------------------------------
--  statueCaptain - Quest logic for Wild Statue Radiant quests
--
----------------------------------------------------------------------------------------------
local this = {}
local common = require("MMM2018.radiant.common")
function this.getQuestData()
    return mwse.loadConfig("radiantQuests/statueCaptainData")
end

--Map quest entries to CS infos
local cachedEntries = nil
function this.getCSEntries()
    if (cachedEntries) then
		debugMessage("cache exists")
        return cachedEntries
    end

    local questData = this.getQuestData()
    local entryList = questData.csEntries

    local csEntries = {}    
    for type, entry in pairs(entryList) do
		debugMessage("entry: " .. type )
        csEntries[type] = tes3.getDialogueInfo({ dialogue = entry.topic, id = entry.info })
    end
    cachedEntries = csEntries
	
	debugMessage("No cache returning entries from questData: " .. questData.questType )
    return csEntries
end


local function numToString(number)
    local numbers = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", 
    "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty",
    "twenty one", "twenty two", "twenty three", "twenty four", "twenty five", "twenty six", "twenty seven", "twenty eight", "twenty nine", "thirty"}
    
    return numbers[number] or number
end	
--Map status to quest progress
local status = { 
    notStarted 		= 0, 
    inProgress 		= 1,
    readyToHandIn 	= 2,
    wait			= 3,
}
--sync questData status with global
local function updateStatus(newStatus)
	local questData = this.getQuestData()
	local questType = questData.questType
	
    local currentQuestData = common.getCurrentQuestData(questType)
    currentQuestData.status = newStatus
    common.setCurrentQuestData(questType, currentQuestData)
    
    tes3.setGlobal(questData.global, status[newStatus] )
    
    debugMessage("status " .. newStatus .. " = " .. status[newStatus] )
    debugMessage("New status: " .. common.getCurrentQuestData(questType).status .. ", " .. tes3.getGlobal(questData.global) )
end

--Wait one day in between Important Missions
local function restartQuest()
    updateStatus("wait")
    timer.start({ 
        duration = 12,
        callback = function() updateStatus("notStarted") end,
        type = timer.game
    })
end

--Check for quest completion
local function checkProgress(e)

    local questData = this.getQuestData()
	local questType = questData.questType
	
	local currentQuestData = common.getCurrentQuestData(questType)
    local currentStatus = currentQuestData.status
    
	if status[currentStatus] == status.inProgress then
		if e.reference.id:find(currentQuestData.statue.id) then
			tes3.messageBox("You should report your success to Captain Nolan.")
            currentStatus = "readyToHandIn"
			updateStatus( currentStatus )
		end
	end
end

local function giveReward()
    local questData = this.getQuestData()
	local questType = questData.questType
    if  tes3ui.findMenu(tes3ui.registerID("MenuDialog")) then
        local currentQuestData = common.getCurrentQuestData(questType)
        local rewards = currentQuestData.rewards
        local rewardAmount = currentQuestData.rewardAmount
        
        debugMessage("entering reward")
        timer.start({ 
            duration = 0.01,
            callback = 
            function ()		
              --Add rewards  
                for i,rewardID in ipairs(rewards.ids) do
                    mwscript.addItem{ reference=tes3.player, item=rewardID, count=rewardAmount }
                end
                restartQuest()
            end,
            type = timer.real
        })
        debugMessage("leaving reward")
    end
end

local function updateReport(e)
    local questData = this.getQuestData()
	local questType = questData.questType
	local currentQuestData = common.getCurrentQuestData(questType)
	local currentStatus = currentQuestData.status or "notStarted"
	
	local atLocation = currentQuestData.statue.atLocation
	
	debugMessage("Status = " .. currentStatus)
	local newText = questData.missionReport[currentStatus]
	
	--Elam Quote if in progress
	if currentStatus == "inProgress" or currentStatus == "readyToHandIn" then
		newText = newText .. "Captain Nolan Indoril - \"" .. currentQuestData.entries.intro .. "\"<p>"
	end
	newText = string.gsub(newText, "%[atlocation%]", atLocation )
	e.text =  questData.missionReport.title .. newText
end


local function startMission()
    local questData = this.getQuestData()
	local currentQuestData = common.getCurrentQuestData(questData.questType)	
	mwscript.enable({currentQuestData.statue.id})
	
	updateStatus("inProgress")
end

local function enableStatues(e)
    local questData = this.getQuestData()
	local currentQuestData = common.getCurrentQuestData(questData.questType)	
	debugMessage("Cell changed checking for statues")
	if not e.cell.isInterior then
		debugMessage("outdoors")
		for ref in e.cell:iterateReferences(tes3.objectType.creature) do
			debugMessage("Creature detected: " .. ref.id)
			if ref.id:find(currentQuestData.statue.id) then
				debugMessage("Statue detected: " .. ref.id)
				tes3.getWorldController().weatherController:switchTransition  ( tes3.weather.ash )
				mwscript.enable({ reference = ref })
			end
		end
	end	
end


--[[
Register events to track the quest progress
]]--	
local tracking = false
function this.startTrackingQuest()
	if tracking then 
		debugMessage("already tracking")
		return
	end
	tracking = true
	debugMessage("tracking")
	local questData = this.getQuestData()
	event.register("infoGetText", giveReward, { filter = this.getCSEntries().reward } )
	event.register("infoGetText", restartQuest, { filter = this.getCSEntries().canceled } )
	event.register("infoGetText", startMission, { filter = this.getCSEntries().accepted } )
	event.register("Radiant:statueKilled", checkProgress )
	event.register("cellChanged", enableStatues)
	event.register("bookGetText", updateReport, { filter = tes3.getObject(questData.scrollID) } )
end


--[[ Returns a quest object with entries (mapped to the quest template in the CS) and a table of variables
    used for quest tracking
    ]]--
function this.generateQuest()
	local questData = this.getQuestData()
	--turns integers up to 30 into words (thirty)

	local entries = {}
	local statue = {}
	local rewards = {}
	local rewardAmount = {}
	local missionReport = {}
	--Generate radiant text for quest  
	if questData then
		statue = questData.statues[ math.random( table.getn(questData.statues) ) ]
		
		rewards = questData.rewards[  math.random( table.getn(questData.rewards) ) ]
		rewardAmount = math.random(rewards.min, rewards.max)
			
		--get random entries from available components and map to CS entries
		local components = questData.textComponents
		entries.intro 	= components.intro[ math.random( table.getn(components.intro) ) ]
						.. " " ..
						components.goal[ math.random( table.getn(components.goal) ) ]            
		entries.accepted = components.agreed[ math.random( table.getn(components.agreed) ) ]
		entries.declined = components.declined[ math.random( table.getn(components.declined) ) ]
		--both return the same string
		entries.return_fail = components.returned[ math.random( table.getn(components.returned) ) ]
		entries.return_success = entries.return_fail 
		entries.reward = components.succeeded[ math.random( table.getn(components.succeeded) ) ]
		entries.fail = components.unfinished[ math.random( table.getn(components.unfinished) ) ]
        entries.canceled = components.canceled[ math.random( table.getn(components.canceled) ) ]
		entries.wait = components.wait[ math.random( table.getn(components.wait) ) ]

		--Replace variables in text
		for entryType,entryText in pairs(entries) do
			entryText = string.gsub(entryText, "%[atlocation%]", statue.atLocation )
			entryText = string.gsub(entryText, "%[reward%]", rewards.name )	
			entries[entryType] = entryText
		end
		
		
	else
		print("Quest data not found!")
	end

	local newQuestData = {}
	newQuestData.entries = entries
	newQuestData.statue = statue
	newQuestData.rewards = rewards
	newQuestData.rewardAmount = rewardAmount
	newQuestData.missionReport = missionReport
    newQuestData.status = "questGenerated"
	tes3.messageBox("Generating Quest")
	common.setCurrentQuestData(questData.questType, newQuestData)
    return newQuestData
end

return this