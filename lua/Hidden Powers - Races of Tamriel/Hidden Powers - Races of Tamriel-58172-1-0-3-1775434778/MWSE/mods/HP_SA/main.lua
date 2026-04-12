---@diagnostic disable: assign-type-mismatch
-- Starting up the dependencies and auxiliary code
local config = require("HP_SA.config")
local log = mwse.Logger.new()
local util = require("HP_SA.util") -- Not used yet, but just in case it contains a spell maker routine
-- The powers are saved in a table in interop
local interop = require("HP_SA.interop")
dofile("HP_SA.mcm")


--[[ Since this is a collaboration, I am trying to make an effort on documenting stuff (at least in main)
The objective of this code is to set up a few power handling routines and to try to set up a way to limit race selection
1. Powers to NPCs: This stream adds powers to NPCs. It was updated later on to separate NPCs and Guards
2. Filter playable races on new game
3. Unlock new races on discovering their related topics
4. Unlock new races when first starting a dialogue with them
00. Auxiliary stuff
]]

-- 1 -- Powers to NPCs
--- @param e mobileActivatedEventData
local function mobileActivatedCallback(e)
	if not (config.Guard_powerDistribution or config.NPC_powerDistribution) then log:debug("Powers distribution not enabled") return end
	if not e.mobile.object then return end
	-- Debug log to verify that the event is being fired
	log:debug("Mobile activated: %s", e.mobile.object.id)

	-- Excluding the player mobile from this logic
	if e.mobile == tes3.mobilePlayer then log:debug("This is the player mobile, so we are skipping power assignment logic") return end
	
	-- Check if the mobile is an NPC
	if e.mobile and (e.mobile.actorType ~= tes3.actorType.npc) then log:debug("Not an actor: %s", e.mobile.object.id) return end
	-- Check if the race is in the table of the powers
	local raceID = e.reference.object.race and e.reference.object.race.id
	log:debug("Race id: %s", raceID)
	if raceID == nil then log:error("No race found for mobile %s", e.mobile.object.id) return end
	local power = interop.NPCpowers[raceID:lower()]
	if power  == nil then log:error("Race power not found for %s",raceID) return end
	log:debug("Power id: %s", power)
	local powerObject = tes3.getObject(power)
	if powerObject == nil then log:error("Spell object '%s' not found in game data for race %s", power, raceID) return end
	
	-- Now we branch into to paths, one for guards and another for NPCs

	if e.mobile.object.isGuard then
		-- Check if power distribution to guards is enabled
		if not config.Guard_powerDistribution then log:debug("Guard powers distribution not enabled") return end
		-- Check if the level is enough. Now assumming a single one for all of the races and powers
		local Guard_level = e.reference.object.level
		log:debug("Guard level : %s", Guard_level)
		if Guard_level < config.Guard_unlockPowerLevel then return end
		log:debug("Guard level check passed. Guard Level: %s , minimum level %s", Guard_level, config.Guard_unlockPowerLevel)
		-- Check if the power is already added. If not, add it
		local hasPower = tes3.hasSpell{ mobile = e.mobile, spell = powerObject }
		log:debug("Does the Guard already have the power? : %s", hasPower)
		if not hasPower then
			local check = tes3.addSpell({ mobile = e.mobile, spell = powerObject})
			log:debug("Power added succesfully? : %s", check)
		end
	else
		-- Check if power distribution to NPCs is enabled
		if not config.NPC_powerDistribution then log:debug("NPC powers distribution not enabled") return end
		-- Check if the level is enough. Now assumming a single one for all of the races and powers
		local NPC_level = e.reference.object.level
		log:debug("NPC level : %s", NPC_level)
		if NPC_level < config.NPC_unlockPowerLevel then return end
		log:debug("NPC level check passed. NPC Level: %s , minimum level %s", NPC_level, config.NPC_unlockPowerLevel)
		-- Check if the power is already added. If not, add it
		local hasPower = tes3.hasSpell{ mobile = e.mobile, spell = powerObject }
		log:debug("Does the NPC already have the power? : %s", hasPower)
		if not hasPower then
			local check = tes3.addSpell({ mobile = e.mobile, spell = powerObject})
			log:debug("Power added succesfully? : %s", check)
		end
	end
end
event.register(tes3.event.mobileActivated, mobileActivatedCallback)

-- 2 -- Let's try to filter playable races
--- @param e loadedEventData
local function loadedCallback(e)
	-- Let's make sure that it only runs when starting a new game
	if not e.newGame then return end
	log:debug("New game detected. Trying to reset races")
	for _, race in ipairs(tes3.dataHandler.nonDynamicData.races) do
		local raceID = race.id:lower()
		race.isPlayable = interop.allRaces[raceID] or false -- interop.allRaces is initilized in the title screen. The function is in the "Auxiliary stuff" of this main.
    end
	-- Let's add some debug information
	if not config.playableRaceFiltering then log:info("Playable race filtering not enabled. If you would like to enable it, see the Mod Configuration Menu in the title screen to configure further.") return
		else log:info("Race filtering is enabled. If you are wondering why your favorite races are not showing, this is probably the case. See the see the Mod Configuration Menu in the title screen to configure further.")
	end
	-- Add an exception catcher if for some reason things go wrong with the config
	if (config.notPlayableRaces == nil) or (next(config.notPlayableRaces) == nil)  then log:debug("Playable race list is nil or empty.") return end
	-- Let's pick up the races from the game and modify their playability with the table stored in the configuration file
	-- local includedRacesInTheMod = table.keys(interop.thisModRaces)
	for _, race in ipairs(tes3.dataHandler.nonDynamicData.races) do
		local raceID = race.id:lower()
		if race.isPlayable and config.notPlayableRaces[raceID] then
			log:debug("Trying to restrict %s race because it has not yet been unlocked", raceID)
			race.isPlayable = false
		end
    end
end
event.register(tes3.event.loaded, loadedCallback, {priority = 9001}) --IT'S OVER 9000!!!!

-- 3 -- Here we use the topics in dialogue to unlock races
--- @param e dialogueFilteredEventData
local function dialogueFilteredCallback(e)
	if not config.unlockOnTopic then log:debug("Race discovery by topic disabled") return end
	-- Only trigger on clicking the topic. Thanks Greatness7!
	if e.context ~= tes3.dialogueFilterContext.clickTopic then return end
	-- We identify the topic and throw a debug line
	local topicName = e.dialogue.id:lower()
	log:debug("Attempting to unlock race by topic. Topic id in lowercase: %s", topicName)
	-- If it is not in the list of topics, exit
	if interop.topics[topicName] == nil then return end
	-- If it has a value, get the race to unlock. I could have skipped this and just use the interop.topics[topicName] as the key of the table, but this looks cleaner.
    local raceToUnlock = interop.topics[topicName]
	if config.notPlayableRaces[raceToUnlock] then
		-- Yeah, it needs to be false, as in "not on the blacklist". We only have exclusions list in the MCM, not "inclusions lists".
		config.notPlayableRaces[raceToUnlock] = false
		mwse.saveConfig(config.fileName, config) -- Important, otherwise it would not be registered when we restart the game
		local messageText = string.format("Congratulations, Outlander.  Now you may select %s in character creation." , topicName)
		tes3.messageBox({message = messageText, showInDialog = false})
	end
	-- Special case for the cats. Cats had to be special, as it turns to be. Oh well:
	if topicName == "khajiit" then
		-- Check what race the speaker is
		local raceID = e.actor.race.id:lower()
		if interop.khajiits[raceID] then
			if config.notPlayableRaces[raceID] then
			-- Yeah, it needs to be false, as in "not on the blacklist". We only have exclusions list in the MCM, not "inclusions lists".
			config.notPlayableRaces[raceID] = false
			mwse.saveConfig(config.fileName, config) -- Important, otherwise it would not be registered when we restart the game
			local messageText = string.format("Congratulations, Outlander.  Now you may select %s in character creation." , topicName)
			tes3.messageBox({message = messageText, showInDialog = false})
			end
		end
	end


end
event.register(tes3.event.dialogueFiltered, dialogueFilteredCallback, {priority = 1}) -- Just to put it above other mods that might use the same event

-- 4 -- Unlocking on meeting (activating) them
--- @param e activateEventData
local function activateCallback(e)
	if not config.unlockOnMeetingNewRace then log:debug("Race discovery by meeting them is disabled") return end
	-- Let's check if the player is doing the activating
	if e.activator ~= tes3.player then return end
	-- Let's check if the dialogue is with an NPC
	local ref	= e.target
	if ref.mobile == nil then log:debug("Activator does not have a mobile: %s", e.target.objectType) return end
	local isNPC = ref.mobile.actorType == tes3.actorType.npc
	if not isNPC then log:debug("Reference %s is not an NPC", ref.id) return end
	-- Check if it is dead
	if ref.mobile.isDead and (not config.unlockOnActivatingCorpse) then log:debug("Unlock by activating corpse is disabled.") return end
	-- Check if it has already been included
	local race = ref.object.race
	local raceID = race and race.id:lower()
	if not raceID then log:debug("raceID is nil in the activateCallback stream. Something went wrong") return end
	if config.notPlayableRaces[raceID] == false then log:debug("Race %s has already been unlocked", raceID) return
	else
		config.notPlayableRaces[raceID] = false
		mwse.saveConfig(config.fileName, config) -- Important, otherwise it would not be registered when we restart the game
		local messageText = string.format("Congratulations, Outlander.  Now you may select %s in character creation." , race.name)
		tes3.messageBox({message = messageText, showInDialog = false})
		log:debug("Race %s is now unlocked (id: %s)",race.name, race.id)
		return
	 end
	
	--[[ Keeping this here in case we need it later
	-- Check if it is included in the races that are missing topics list
	if interop.missingTopic[raceID] then
		config.notPlayableRaces[raceID] = false
		mwse.saveConfig(config.fileName, config) -- Important, otherwise it would not be registered when we restart the game
		local messageText = string.format("Congratulations, Outlander.  Now you may select %s in character creation." , ref.object.race.name)
		tes3.messageBox({message = messageText, showInDialog = false})
		return
	end
	-- As a last resort, let's check if the race is playable, and add it to the list
	if ref.object.race.isPlayable and (not table.contains(table.keys(interop.thisModRaces), raceID)) then
		table.insert(interop.notThisModRaces, raceID)
		config.notPlayableRaces[raceID] = false
		mwse.saveConfig(config.fileName, config) -- Important, otherwise it would not be registered when we restart the game
		local messageText = string.format("Congratulations, Outlander.  Now you may select %s in character creation." , ref.object.race.name)
		tes3.messageBox({message = messageText, showInDialog = false})
		return
	end
	]]
end
event.register(tes3.event.activate, activateCallback)


-- 00 -- Auxiliary stuff

-- Let's save the playable races in advance to avoid problems, such as player starting a new game from in game
--- @ param e initializedEventData
local function initializedCallback(e)
	log:debug("Trying to add races to the interop storage variable.")
	for _, race in ipairs(tes3.dataHandler.nonDynamicData.races) do
		local raceID = race.id:lower()
		interop.allRaces[raceID] = race.isPlayable
		log:debug("Race %s, with ID %s (lowercase version used by the mod: %s), is playable (True/False): %s", race.name, race.id, raceID, race.isPlayable )
		if race.isPlayable then
			interop.raceIDtoName[race.id:lower()] = race.name
		end
    end
	-- If it is missing in the config file, add it and set it as false (enabled by default)
	for id, _ in pairs(interop.raceIDtoName) do
		if config.notPlayableRaces[id] == nil then
			config.notPlayableRaces[id] = false
		end
	end

	-- Housekeeping: If it does not exist anymore in the races, but exists in the config file, remove it to avoid errors
	for id,_ in pairs(config.notPlayableRaces) do
		if interop.raceIDtoName[id] == nil then
			config.notPlayableRaces[id] = nil
		end
	end

end
event.register(tes3.event.initialized, initializedCallback, {priority = 9001}) --IT'S OVER 9000!!!!