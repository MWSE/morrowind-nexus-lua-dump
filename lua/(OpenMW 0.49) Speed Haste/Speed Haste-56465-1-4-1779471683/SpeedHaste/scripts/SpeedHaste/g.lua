world = require('openmw.world')
core = require('openmw.core')
storage = require('openmw.storage')
async = require('openmw.async')
I = require('openmw.interfaces')
types = require('openmw.types')

------------------------- CONSTANTS -------------------------
MODNAME = "SpeedHaste"
local NPC_SCRIPT = "scripts/SpeedHaste/npc.lua"

------------------------- SETTINGS -------------------------
require('scripts.SpeedHaste.settings')

------------------------- HOOK MANAGEMENT -------------------------
local function buildSettingsPayload()
	return {
		BaseWeaponSpeed     = S_BaseWeaponSpeed,
		BaseMagicSpeed      = S_BaseMagicSpeed,
		MinWeaponSkill      = S_MinWeaponSkill,
		WeaponSkillExponent = S_WeaponSkillExponent,
		HastePerWeaponSkill = S_HastePerWeaponSkill,
		MinMagicSkill       = S_MinMagicSkill,
		MagicSkillExponent  = S_MagicSkillExponent,
		HastePerMagicSkill  = S_HastePerMagicSkill,
		MinLevel            = S_MinLevel,
		LevelExponent       = S_LevelExponent,
		HastePerLevel       = S_HastePerLevel,
		MinSpellCost        = S_MinSpellCost,
		SpellCostExponent   = S_SpellCostExponent,
		SlowPerSpellCost    = S_SlowPerSpellCost,
	}
end

local function isHookable(actor)
	if not types.NPC.objectIsInstance(actor) then return false end
	if types.Player.objectIsInstance(actor) then return false end
	return true
end

-- called from settings
function F_rebuildHooks()
	for _, actor in ipairs(world.activeActors) do
		if isHookable(actor) then
			if S_NpcHaste then
				actor:addScript(NPC_SCRIPT)
				actor:sendEvent("SpeedHaste_setSettings", buildSettingsPayload())
			elseif actor:hasScript(NPC_SCRIPT) then
				actor:removeScript(NPC_SCRIPT)
			end
		end
	end
end

-- called from settings
function F_broadcastSettings()
	if not S_NpcHaste then return end
	for _, actor in ipairs(world.activeActors) do
		if isHookable(actor) then
			actor:sendEvent("SpeedHaste_setSettings", buildSettingsPayload())
		end
	end
end

------------------------- ENGINE HANDLERS -------------------------
-- also called onLoad:
local function onActorActive(actor)
	if S_NpcHaste and isHookable(actor) then
		actor:addScript(NPC_SCRIPT)
		actor:sendEvent("SpeedHaste_setSettings", buildSettingsPayload())
	end
end

local function onUnhookRequest(actor)
	if actor:hasScript(NPC_SCRIPT) then
		actor:removeScript(NPC_SCRIPT)
	end
end

return {
	engineHandlers = {
		onActorActive = onActorActive,
	},
	eventHandlers = {
		SpeedHaste_unhookSelf = onUnhookRequest,
	},
}
