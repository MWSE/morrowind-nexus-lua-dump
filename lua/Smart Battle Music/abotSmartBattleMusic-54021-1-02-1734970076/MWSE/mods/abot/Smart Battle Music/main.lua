--[[
only attack to/from player will trigger Battle music
]]

local defaultConfig = {
keepPlayingLastExploreTrack = false,
eventPriority = 20000, -- increase if needed
logLevel = 0,
}

local author = 'abot'
local modName = 'Smart Battle Music'
local modPrefix = author .. '/'.. modName
local mcmName = author .. "'s " .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local keepPlayingLastExploreTrack, eventPriority
local logLevel, logLevel1, logLevel2

local function updateFromConfig()
	keepPlayingLastExploreTrack = config.keepPlayingLastExploreTrack
	eventPriority = config.eventPriority
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
end
updateFromConfig()

local lastAttacker, lastTarget
local function resetLastAttackerAndTarget()
	lastAttacker = nil
	lastTarget = nil
end

-- set in loaded()
local player, mobilePlayer, audioController

local function combatStarted(e)
	lastAttacker = e.actor
	lastTarget = e.target
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_escort = tes3.aiPackage.escort
---local tes3_aiPackage_wander = tes3.aiPackage.wander
--- nope no room local tes3_aiPackage_none = tes3.aiPackage.none

---local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

local function isValidMobile(mob)
	local mobRef = mob.reference
	if mobRef.disabled then
		return false
	end
	if mobRef.deleted then
		return false
	end
	if mob.actorType == tes3_actorType_npc then
		return true
	end
	local mobObj = mobRef.object
	local lcId = string.lower(mobObj.id)
	if lcId == 'ab01guguarpackmount' then -- this is a good one
		return true
	end
	if string.startswith(lcId, 'ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
		return false
	end
	local script = mobObj.script
	if script then
		local lcId2 = string.lower(script.id)
		if string.startswith(lcId2, 'ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
			if logLevel >= 3 then
				mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, mobRef.id)
			end
			return false
		end
	end
	return true
end

local function isValidFollower(mob)
	local aiPlanner = mob.aiPlanner
	if not aiPlanner then
		return false
	end
	local activePackage = aiPlanner:getActivePackage()
	if activePackage then
		local ai = activePackage.type
		if (ai == tes3_aiPackage_follow)
		or (ai == tes3_aiPackage_escort) then
			local targetActor = activePackage.targetActor
			if mobilePlayer == targetActor then
				return true
			end
		end
	end
	return false
end

local tes3_musicSituation_combat = tes3.musicSituation.combat
local tes3_musicSituation_explore = tes3.musicSituation.explore

local situations = table.invert(tes3.musicSituation)

local lastExploreTrack

local function musicSelectTrack(e)
	local situation = e.situation
	if (situation == tes3_musicSituation_explore) then

		if keepPlayingLastExploreTrack
		and lastExploreTrack then
			if logLevel1 then
				mwse.log([[%s: musicSelectTrack(e) situation = %s (%s)
keep playing "%s" lastExploreTrack]],
					modPrefix, situation, situations[situation], lastExploreTrack)
			end
			tes3.streamMusic({path = lastExploreTrack, situation = tes3_musicSituation_explore})
			return
		end

		local currTrack = audioController.currentMusicFilePath
		if currTrack
		and ( not string.multifind(string.lower(currTrack),
				{'morrowind title', 'silence'}, 1, true) ) then
			lastExploreTrack = currTrack
			if logLevel1 then
				mwse.log([[%s: musicSelectTrack(e) situation = %s (%s)
now playing "%s" lastExploreTrack]],
					modPrefix, situation, situations[situation], currTrack)
			end
		end

		return
	end

	if not (e.situation == tes3_musicSituation_combat) then
		return
	end
	if not lastAttacker then
		return
	end
	if not lastAttacker.reference then
		return
	end
	if not lastTarget then
		return
	end
	if not lastTarget.reference then
		return
	end
	if lastTarget == mobilePlayer then
		return
	end
	if lastAttacker == mobilePlayer then
		return
	end
	if logLevel2 then
		mwse.log([[%s: musicSelectTrack(e) e.situation = %s (%s)
lastAttacker = "%s", lastTarget = "%s", skip changing music]],
		modPrefix, e.situation, situations[e.situation], lastAttacker.reference, lastTarget.reference)
	end
	if isValidFollower(lastAttacker)
	and isValidMobile(lastAttacker) then
		return
	end
	if isValidFollower(lastTarget)
	and isValidMobile(lastTarget) then
		return
	end
	if logLevel1 then
		mwse.log([[%s: musicSelectTrack(e) e.situation = %s (%s)
lastAttacker = "%s", lastTarget = "%s", skip changing music]],
		modPrefix, e.situation, situations[e.situation], lastAttacker.reference, lastTarget.reference)
	end
	resetLastAttackerAndTarget()
	return false
end

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	event.register('musicSelectTrack', musicSelectTrack, {priority = eventPriority})
	event.register('combatStarted',	combatStarted, {priority = eventPriority})
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	audioController = tes3.worldController.audioController
	resetLastAttackerAndTarget()
	initOnce()
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local preferences = template:createSideBarPage({label = 'Info',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({
text = [[Only attack to/from player or companions will trigger Battle music]]
	})

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory({})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton({
		label = 'Keep playing last Explore track',
		description = getYesNoDescription([[Default: %s.
Keep playing last Explore track after battle end.]], 'keepPlayingLastExploreTrack'),
		variable = createConfigVariable('keepPlayingLastExploreTrack')
	})

	controls:createSlider({
		label = 'Event priority',
		description = getDescription([[Default: %s.
musicSelectTrack(e) event priority.
You could try increasing it if and only if the mod does not seem to work due to a conflict with some other MWSE-Lua music mod using the same event.]], 'eventPriority'),
		variable = createConfigVariable('eventPriority')
		,min = 20000, max = 100000, step = 1, jump = 10
	})

	local optionList = {'Off', 'Low', 'Medium'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createDropdown({
		label = "Log level:",
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()	event.register('loaded', loaded) end---, {doOnce = true}
)