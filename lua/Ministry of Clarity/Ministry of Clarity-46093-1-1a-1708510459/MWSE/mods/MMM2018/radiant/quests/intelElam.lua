local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[intelElam: DEBUG] " .. string)
	end
end
----------------------------------------------------------------------------------------------
--  IntelElam - Quest Logic for Mission 2: gather intelligence for Elam in Ministry of Clarity
--
----------------------------------------------------------------------------------------------
local this = {}
local common = require("MMM2018.radiant.common")
function this.getQuestData()
    return mwse.loadConfig("radiantQuests/intelElamData")
end

local cachedEntries = nil
function this.getCSEntries()
    if (cachedEntries) then
		--debugMessage("cache exists")
        return cachedEntries
    end

    local questData = this.getQuestData()
    local entryList = questData.csEntries

    local csEntries = {}    
    for type, entry in pairs(entryList) do
        csEntries[type] = tes3.getDialogueInfo({ dialogue = entry.topic, id = entry.info })
    end
    cachedEntries = csEntries
	
	debugMessage("No cache returning entries from questData")
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

--Wait 1 hour wait before quest becomes available again
local function restartQuest()
    updateStatus("wait")
    timer.start({ 
        duration = 24,
        callback = function() updateStatus("notStarted") end,
        type = timer.game
    })
end

--Check for quest completion
local function identifySleeper()
    if tes3.getPlayerTarget() then
        if  tes3ui.findMenu(tes3ui.registerID("MenuDialog")) then
		    local questData = this.getQuestData()
			local questType = questData.questType
			local currentQuestData = common.getCurrentQuestData(questType)
			local sleeperID = currentQuestData.sleeper.name
            if tes3.getPlayerTarget().object.id == sleeperID then
				local currentStatus = currentQuestData.status
                if status[currentStatus] == status.inProgress then
                    tes3.messageBox("You should report your findings to Elam Andas.")
                    currentStatus = "readyToHandIn"
                    updateStatus( currentStatus )
                    table.insert(currentQuestData.doneSleepers, sleeperID)
                end
            end
        end
    end
end

--Give player reward. Check for menuDialog to prevent activating from Journal
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

	debugMessage("Status = " .. currentStatus)
	local newText = questData.missionReport[currentStatus]
	
	-- Elam Quote if in progress
	if currentStatus == "inProgress" or currentStatus == "readyToHandIn" then
		newText = newText .. "Elam Andas - \"" .. currentQuestData.entries.intro .. "\"<p>"
	end

	newText = string.gsub(newText, "%[atlocation%]", questData.atLocation[currentQuestData.sleeper.location].text )
	newText = string.gsub(newText, "%[sleeper%]", currentQuestData.sleeper.name )
	e.text =  questData.missionReport.title .. newText
end


local function informantDialog(e)

	if  tes3ui.findMenu(tes3ui.registerID("MenuDialog")) then
		
		local questData = this.getQuestData()
		local currentQuestData = common.getCurrentQuestData(questData.questType)
		if status[currentQuestData.status] == status.inProgress then
		
			--Sleeper Denial
			if e.info == this.getCSEntries(true).denial then 
				--only if sleeper is awake - get local SleeperOn
				if e.reference.object.name == currentQuestData.sleeper.name then
					debugMessage("got the right sleeper")
					e.passes = e.passes and e.passes or false
				else
					debugMessage("Not the right sleeper: this is " .. e.reference.object.name .. ", we want " ..  currentQuestData.sleeper.name )
					e.passes = false
				end		
				
			--Sleeper confession	
			elseif e.info == this.getCSEntries(true).confession1 or e.info == this.getCSEntries(true).confession2 then
				--only if sleeper is awake - get local SleeperOn
				if e.reference.object.name == currentQuestData.sleeper.name then
					debugMessage("Got a confession: currently filtered to " .. (e.passes and "true" or "false") )
					e.passes = e.passes and e.passes or false
					return
				else
					debugMessage("Not the right sleeper: this is " .. e.reference.object.name .. ", we want " ..  currentQuestData.sleeper.name )
					e.passes = false
				end
			else
				
				--Informant: filter to class or specific informant
				local class = currentQuestData.sleeper.informantClass
				local informantId = currentQuestData.sleeper.informantId
				
				--By class? Check location too
				if class and e.actor.class and currentQuestData.sleeper.location:find(tes3.getPlayerCell().id) then
					--debugMessage("[intelElam] filtering by class")
					if class == e.actor.class.id then	
						debugMessage("class true")
						e.passes = e.passes and e.passes or false
					else
						e.passes = false
					end
				--or id
				elseif informantId then
					--debugMessage("[intelElam] filtering by id")
					if informantId == e.actor.id then 
						e.passes = e.passes and e.passes or false
					else
						e.passes = false
					end
				else
					--debugMessage("[intelElam ERROR] informantDialog - no class or id filter!")
					e.passes = false
				end
			end
		else
			e.passes = false
		end
	else
		e.passes = false
	end
end

--[[ Update status and tell player to go back to Elam ]]--
local function readyToHandIn()
	local questData = this.getQuestData()
	local currentQuestData = common.getCurrentQuestData(questData.questType)

	timer.start({ 
		duration = 0.01,
		callback = 
		function ()		
			if status[currentQuestData.status] == status.inProgress then
				updateStatus("readyToHandIn")
				tes3.messageBox("You should report your findings to Elam.")
			end
		end,
		type = timer.real
	})
end

--[[
Register events to track the quest progress
]]--	
local tracking = false
function this.startTrackingQuest()
	if tracking then 	
		return
	end
	tracking = true
	local questData = this.getQuestData()

    local csEntries = this.getCSEntries()
	
	event.register("infoGetText", giveReward, { filter = csEntries.reward } )
    event.register("infoGetText", restartQuest, { filter = csEntries.canceled } )
	event.register("infoGetText", function() updateStatus("inProgress") end, { filter = csEntries.accepted } )	
    --

	
	event.register("bookGetText", updateReport, { filter = tes3.getObject(questData.scrollID) } )
	
   --Custom dialog replacers 
	debugMessage("registering informant filters")
    event.register("infoFilter", informantDialog, { filter = csEntries.informantLowDisposition } )
	event.register("infoFilter", informantDialog, { filter = csEntries.informantMediumDisposition } )
	event.register("infoFilter", informantDialog, { filter = csEntries.revelation } )
	event.register("infoFilter", informantDialog, { filter = csEntries.denial } )
	event.register("infoFilter", informantDialog, { filter = csEntries.confession1 } )
	event.register("infoFilter", informantDialog, { filter = csEntries.confession2 } )

	debugMessage("registering confessions")
	event.register("infoGetText", readyToHandIn, { filter = csEntries.confession1 } )
	event.register("infoGetText", readyToHandIn, { filter = csEntries.confession2 } )	
end


--[[ Returns a quest object with entries (mapped to the quest template in the CS) and a table of variables
    used for quest tracking
    ]]--
function this.generateQuest()
	--TODO generate quest for intel
    
	local questData = this.getQuestData()

	local questType = questData.questType
        debugMessage("QuestType = " .. questType)
	--turns integers up to 30 into words (thirty)
	local entries = {}
    local sleeperList = {}
    local newSleeper = {}
	local rewards = {}
	local rewardAmount = {}
	--Generate radiant text for quest
	if questData then
        --Sleeper List persists across quests to keep track of which ones we've found already
        local currentQuestData = common.getCurrentQuestData(questType)
        if currentQuestData and currentQuestData.sleeperList then
            sleeperList = currentQuestData.sleeperList
        else
            sleeperList = questData.sleepers
        end
        --Get list of sleepers we haven't found yet
        local availableSleepers = {}
        for id,sleeper in pairs(sleeperList) do
            debugMessage("Sleeper: " .. id .. ", completed? " .. sleeper.completed )
            if sleeper.completed == "no" then 
                table.insert(availableSleepers, sleeper)
            end
        end
        --Pick a sleeper for this quest
        newSleeper = availableSleepers[ math.random( table.getn(availableSleepers) ) ]
        --And set him to completed so he won't be picked again
        sleeperList[newSleeper.name].completed = "yes"
    
		rewards = questData.rewards[  math.random( table.getn(questData.rewards) ) ]
		rewardAmount = math.random(rewards.min, rewards.max)
			
		--get random entries from available components and map to CS entries
		local components = questData.textComponents
		entries.intro 	        = components.intro[ math.random( table.getn(components.intro) ) ]
                                .. " " ..
                                components.goal[ math.random( table.getn(components.goal) ) ]            
                                
		entries.accepted        = components.agreed[ math.random( table.getn(components.agreed) ) ]
		entries.declined        = components.declined[ math.random( table.getn(components.declined) ) ]
		entries.reward          = components.succeeded[ math.random( table.getn(components.succeeded) ) ]
		entries.fail            = components.unfinished[ math.random( table.getn(components.unfinished) ) ]
        entries.canceled        = components.canceled[ math.random( table.getn(components.canceled) ) ]
		entries.wait            = components.wait[ math.random( table.getn(components.wait) ) ]
        
        --both return the same string
		entries.return_fail     = components.returned[ math.random( table.getn(components.returned) ) ]
		entries.return_success  = entries.return_fail 
        --informant/sleeper dialog
        entries.informantLowDisposition = components.informantLowDisposition[ math.random( table.getn(components.informantLowDisposition) ) ]
        entries.informantMediumDisposition = components.informantMediumDisposition[ math.random( table.getn(components.informantMediumDisposition) ) ]
        entries.revelation = newSleeper.revelation
        entries.denial = components.denial[ math.random( table.getn(components.denial) ) ]
        entries.confession1 = components.confession[ math.random( table.getn(components.confession) ) ]
		entries.confession2 = components.confession[ math.random( table.getn(components.confession) ) ]
		entries.elamdisturb = components.elamdisturb[ math.random( table.getn(components.elamdisturb) ) ]
		--Replace variables in text
		for entryType,entryText in pairs(entries) do
			entryText = string.gsub(entryText, "%[sleeper%]", newSleeper.name)
            entryText = string.gsub(entryText, "%[atlocation%]", questData.atLocation[newSleeper.location].text)
			entryText = string.gsub(entryText, "%[reward%]", rewards.name )	
			
			entries[entryType] = entryText
		end
		
	else
		print("[Radiant: intelElam] Quest data not found!")
	end

	local newQuestData = {}
	newQuestData.entries = entries
	newQuestData.rewards = rewards
	newQuestData.rewardAmount = rewardAmount
    newQuestData.sleeperList = sleeperList
    newQuestData.sleeper = newSleeper
    newQuestData.status = "questGenerated"
	debugMessage("Generating Quest")
	common.setCurrentQuestData(questType, newQuestData)
    return newQuestData
end

return this