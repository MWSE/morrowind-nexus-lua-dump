I = require('openmw.interfaces')
types = require('openmw.types')
self = require('openmw.self')
core = require('openmw.core')
storage = require('openmw.storage')
local debug = require('openmw.debug')

MODNAME = "SealedFate"
settingsSection = storage.playerSection('Settings'..MODNAME)
playerSection = storage.playerSection(MODNAME)
require("scripts.SealedFate.SF_HUD")
require("scripts.SealedFate.SF_settings")

lastDangerousState = false
local currentDangerLevel = 0
local aggroActors = {}
local harmfulEffects = {}
local playerDead = false
local cellCache = nil
local lastHealth = 1
PERMADEATH_ENABLED = false
local noseLevel = 140
TESTING = false
onFrameFunctions = {}


local damageEffects = {
	["firedamage"] = true,
	["frostdamage"] = true,
	["shockdamage"] = true,
	--["sundamage"] = true,

	["damagehealth"] = true,
	--["damagefatigue"] = true,
	--["damagemagicka"] = true,
	--["damageattribute"] = true,
	
	["absorbhealth"] = true,
	--["absorbfatigue"] = true,
	--["absorbmagicka"] = true,
	--["absorbattribute"] = true,
	
	["poison"] = true
}

local function checkHarmfulEffects()
	harmfulEffects = {}
	local activeSpells = types.Actor.activeSpells(self)
	
	for _, spell in pairs(activeSpells) do
		--if spell.caster ~= self then
			for _, effect in pairs(spell.effects) do
				local effectRecord = core.magic.effects.records[effect.id]
				if effectRecord and damageEffects[effectRecord.id] then
					table.insert(harmfulEffects, {
						spellId = spell.id,
						effectId = effect.id,
						caster = spell.caster
					})
				end
			end
		--end
	end
	return #harmfulEffects > 0
end

-- Calculate danger level
local function calculateDangerLevel()
	if not self.cell then return 0 end
	local danger = 0
	-- Add danger for harmful effects

	danger = danger + #harmfulEffects * 2
	
	-- Add danger for aggro actors
	local aggroCount = 0
	for actorId, data in pairs(aggroActors) do
		if data.isAggressive and core.getSimulationTime() - data.lastUpdate < 3 then
			aggroCount = aggroCount + 1000
		end
	end
	danger = danger + aggroCount
	--print(aggroCount)
	local waterLevel = self.cell.waterLevel or -99999999
	if waterLevel-noseLevel > self.position.z then
		danger = danger + 1000000
	end
	if debug.isGodMode() then
		danger = 0
	end
	return danger
end



-- Update dangerous state
local function updateDangerousState()
	local hasHarmfulEffects = checkHarmfulEffects()
	currentDangerLevel = calculateDangerLevel()
	local isDangerous = currentDangerLevel > 0
	if isDangerous ~= lastDangerousState then
		lastDangerousState = isDangerous
		
		if isDangerous then
			if PERMADEATH_ENABLED then
				playerSection:set(saveData.uniqueId, 1000)
				self.type.sendMenuEvent(self, 'SealedFate_storeSaveDir')
			else
				playerSection:set(saveData.uniqueId, 1)
			end
			print("SealedFate: Entered dangerous state:", currentDangerLevel)
			hudSkull.layout.props.alpha = 0.9
			hudSkull:update()
		else
			playerSection:set(saveData.uniqueId, nil)
			playerSection:set("DANGER_SAVE_DIR", nil)
			
			print("SealedFate: Exited dangerous state")
			hudSkull.layout.props.alpha = 0
			hudSkull:update()
		end
	end
end

-- Handle aggro updates from actors
local function handleAggroUpdate(data)
	local actorId = data.actorId
	local isAggressive = data.isAggressive
	
	aggroActors[actorId] = {
		isAggressive = isAggressive,
		lastUpdate = core.getSimulationTime()
	}
end

-- Clean up old aggro data
local function cleanupAggroData()
	local currentTime = core.getSimulationTime()
	for actorId, data in pairs(aggroActors) do
		if currentTime - data.lastUpdate > 3 then
			aggroActors[actorId] = nil
		end
	end
end

-- Check if player died
local function checkPlayerDeath()
	local health = types.Actor.stats.dynamic.health(self).current
	if health <= 0 and lastHealth <=0 and not playerDead then
		playerDead = true
		playerSection:set(saveData.uniqueId, nil)
		self.type.sendMenuEvent(self, 'SealedFate_checkDeletion')
	elseif health > 0 then
		playerDead = false
	end
	lastHealth = health
end

-- Cell change handler - request quick aggro update
local function checkCellChange()
	if cellCache ~= self.cell then
		aggroActors = {}
		cellCache = self.cell
	end
end

local function onFrame(dt)
	for _, f in pairs(onFrameFunctions) do
		f(dt)
	end
	updateDangerousState()
	cleanupAggroData()
	checkPlayerDeath()
	checkCellChange()
end

local function onLoad(data)
	if data then
		saveData = data
	else
		saveData = {}
	end
	if not saveData.uniqueId then
		saveData.uniqueId = "save"..math.random()
	end
	playerSection:set("FORCE_KILL_CHARACTER", nil)
	
	PERMADEATH_ENABLED = settingsSection:get("ENABLE_DELETION")
	if playerSection:get(saveData.uniqueId) then
		print("SealedFate: danger save loaded", playerSection:get(saveData.uniqueId), "'"..tostring(playerSection:get("DANGER_SAVE_DIR")).."'")
		if I.Roguelite then
			I.Roguelite.countDeath()
		end
		playerSection:set(saveData.uniqueId, nil)
	end
	
	self.type.sendMenuEvent(self, 'SealedFate_checkDeletion', "onLoad")
	
	waitForDeletionUntil = core.getRealTime() + 10
	onFrameFunctions["waitForDeletion"] = function()
		if playerSection:get("FORCE_KILL_CHARACTER") then
			playerDead = true
			types.Actor.stats.dynamic.health(self).current = 0
			playerSection:set("FORCE_KILL_CHARACTER", nil)
			onFrameFunctions["waitForDeletion"] = nil
		end
		if core.getRealTime() > waitForDeletionUntil then
			onFrameFunctions["waitForDeletion"] = nil
		end
	end

	aggroActors = {}
	harmfulEffects = {}
	playerDead = false
	lastDangerousState = false
	createSkull()
	local npcRecord = types.NPC.record(self)
	if npcRecord then
		if npcRecord.isMale then
			noseLevel = types.NPC.races.record(npcRecord.race).height.male*147.79
		else
			noseLevel = types.NPC.races.record(npcRecord.race).height.female*147.79
		end
	end
end

local function onSave()
	return saveData
end

return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
		onFrame = onFrame,
        onMouseWheel = onMouseWheel,
	},
	eventHandlers = {
		SealedFate_aggroUpdate = handleAggroUpdate,
		SealedFate_cellChanged = onCellChange,
	},
	interfaceName = "SealedFate",
	interface = {
		version = 2,
		generateSaveId = function()
			print("SealedFate: new Save ID")
			saveData.uniqueId = "save"..math.random() 
		end,
	}
}