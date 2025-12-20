I = require('openmw.interfaces')
types = require('openmw.types')
self = require('openmw.self')
core = require('openmw.core')
storage = require('openmw.storage')
nearby = require('openmw.nearby')
local debug = require('openmw.debug')

MODNAME = "SealedFate"
settingsSection = storage.playerSection('Settings'..MODNAME)
playerSection = storage.playerSection(MODNAME)
require("scripts.SealedFate.SF_HUD")
require("scripts.SealedFate.SF_settings")

lastDangerousState = false
currentDangerLevel = 0
local aggroActors = {}
local harmfulEffects = {}
local hasSunDamage = false
local playerDead = false
local cellCache = nil
local lastHealth = 1
PERMADEATH_ENABLED = false
local noseLevel = 140
TESTING = false
onFrameFunctions = {}
local sunsDusk = nil
if I.SunsDusk and I.SunsDusk.version >= 2 then
	sunsDusk = I.SunsDusk.getSaveData()
end

local fallDistanceMin = core.getGMST("fFallDamageDistanceMin")
local fallAcroBase = core.getGMST("fFallAcroBase")
local fallAcroMult = core.getGMST("fFallAcroMult")
local fallDistanceBase = core.getGMST("fFallDistanceBase")
local fallDistanceMult = core.getGMST("fFallDistanceMult")
local fFatigueBase = core.getGMST("fFatigueBase")
local fFatigueMult = core.getGMST("fFatigueMult")


--local fMagicSunBlockedMult = core.getGMST("fMagicSunBlockedMult") --idk

local function getSunPct()
	if not core.weather then
		return 0
	end
	if self.cell.isExterior or self.cell:hasTag("QuasiExterior") then
		return core.weather.getCurrentSunPercentage(self.cell)
	else
		return 0
	end
end

local damageEffects = {
	["firedamage"] = true,
	["frostdamage"] = true,
	["shockdamage"] = true,
	["sundamage"] = true,

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
	hasSunDamage = false
	local activeSpells = types.Actor.activeSpells(self)
	
	for _, spell in pairs(activeSpells) do
		--if spell.caster ~= self then
			for _, effect in pairs(spell.effects) do
				local effectRecord = core.magic.effects.records[effect.id]
				if effectRecord and damageEffects[effectRecord.id] then
					if effectRecord.id == "sundamage" then
						hasSunDamage = true
					else
						table.insert(harmfulEffects, {
							spellId = spell.id,
							effectId = effect.id,
							caster = spell.caster
						})
					end
				end
			end
		--end
	end
	return #harmfulEffects > 0
end

local function getFallDamage(fallHeight)
	--const float fallDistanceMin = store.find("fFallDamageDistanceMin")->mValue.getFloat();
	if fallHeight < fallDistanceMin then return 0 end
	
	local acrobaticsSkill = types.NPC.stats.skills.acrobatics(self).modified -- const float acrobaticsSkill = static_cast<float>(ptr.getClass().getSkill(ptr, ESM::Skill::Acrobatics));
	local jumpSpellBonus = types.Actor.activeEffects(self):getEffect("jump").magnitude -- const float jumpSpellBonus = ptr.getClass().getCreatureStats(ptr).getMagicEffects().getOrDefault(ESM::MagicEffect::Jump).getMagnitude();
	--const float fallAcroBase = store.find("fFallAcroBase")->mValue.getFloat();
	--const float fallAcroMult = store.find("fFallAcroMult")->mValue.getFloat();
	--const float fallDistanceBase = store.find("fFallDistanceBase")->mValue.getFloat();
	--const float fallDistanceMult = store.find("fFallDistanceMult")->mValue.getFloat();

	local x = fallHeight - fallDistanceMin --float x = fallHeight - fallDistanceMin;
	x = x - ((1.5 * acrobaticsSkill) + jumpSpellBonus) --x -= (1.5f * acrobaticsSkill) + jumpSpellBonus;
	x = math.max(0, x) --x = std::max(0.0f, x);
	local a = fallAcroBase + fallAcroMult * (100 - acrobaticsSkill) --float a = fallAcroBase + fallAcroMult * (100 - acrobaticsSkill);
	x = fallDistanceBase + fallDistanceMult * x --x = fallDistanceBase + fallDistanceMult * x;
	x = x * a --x *= a;
	
	local fatigue = types.Actor.stats.dynamic.fatigue(self)
	local fatigueMax = math.max(fatigue.base, 1) --float max = getFatigue().getModified();
	local fatigueCurrent = fatigue.current --float current = getFatigue().getCurrent();
	--float fFatigueBase = store.find("fFatigueBase")->mValue.getFloat();
	--float fFatigueMult = store.find("fFatigueMult")->mValue.getFloat();
	local fatigueTerm = fFatigueBase - fFatigueMult * (1 - fatigueCurrent / fatigueMax) --return fFatigueBase - fFatigueMult * (1 - current/max);
	x = x * (1.0 - 0.25 * fatigueTerm) --float realHealthLost = healthLost * (1.0f - 0.25f * fatigueTerm)
	
	return x
end




-- Calculate danger level
local function calculateDangerLevel()
	if not self.cell then return 0 end
	local danger = 0
	danger = danger + #harmfulEffects * 2
	
	local aggroCount = 0
	for actorId, data in pairs(aggroActors) do
		if data.isAggressive and core.getSimulationTime() - data.lastUpdate < 3 then
			aggroCount = aggroCount + 1000
		end
	end
	danger = danger + aggroCount
	
	if hasSunDamage then
		if getSunPct() > 0.01 then
			danger = danger + 100000
		end
	end
	
	local waterLevel = self.cell.waterLevel or -99999999
	if waterLevel-noseLevel > self.position.z then
		danger = danger + 1000000
	end
	
	if not types.Actor.isOnGround(self) and debug.isCollisionEnabled() then
		local newPos = self.position
		-- Track peak height
		if not saveData.fallStart or newPos.z > saveData.fallStart then
			saveData.fallStart = newPos.z
		end
		-- Raycast to find landing point
		local rayEnd = util.vector3(newPos.x, newPos.y, newPos.z - 100000)
		local ray = nearby.castRay(newPos, rayEnd, { collisionType = nearby.COLLISION_TYPE.AnyPhysical, ignore = self })
		if ray.hit then
			local totalFallHeight = saveData.fallStart - ray.hitPos.z
			local currentHealth = types.Actor.stats.dynamic.health(self).current
			if getFallDamage(totalFallHeight) >= currentHealth then
				danger = danger + 10000000
			end
		end
	else
		saveData.fallStart = nil
	end
	
	if sunsDusk then
		if sunsDusk.m_temp and sunsDusk.m_temp.currentSlowDebuff then
			danger = danger + 100000000
		end
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
			--print("SealedFate: Entered dangerous state:", currentDangerLevel)
			hudSkull.layout.props.alpha = 0.9
			hudSkull:update()
		else
			playerSection:set(saveData.uniqueId, nil)
			playerSection:set("DANGER_SAVE_DIR", nil)
			
			--print("SealedFate: Exited dangerous state")
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