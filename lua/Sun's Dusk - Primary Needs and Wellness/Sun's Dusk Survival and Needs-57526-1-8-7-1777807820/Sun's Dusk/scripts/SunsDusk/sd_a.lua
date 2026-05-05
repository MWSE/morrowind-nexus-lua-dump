-- ╭──────────────────────────────────────────────────────────────────────╮
-- │  Sun's Dusk /-./-.-\.-\ Actors                                       │
-- │  detect followers, relay hits/spells                                 │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- ───────────────────────────────────────────────────────────────── Imports ─────────────────────────────────────────────────────────────────
local I      = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self   = require('openmw.self')
local anim   = require('openmw.animation')
local types  = require('openmw.types')
local core   = require('openmw.core')
local vfs    = require('openmw.vfs')
local typesActorActiveSpellsSelf
local typesActorActiveEffectsSelf


-- if this lands on the player, unhook bc players are not companions
local AI = I.AI
if not AI then
	core.sendGlobalEvent("SunsDusk_Unhook", self)
	return
end

-- ───────────────────────────────────────────────────────────────── State ───────────────────────────────────────────────────────────────
local isDead   = false
local nextUpdate = 0
local nextCompanionUpdate = 0
local activeSpells = {}
local items = {}
local isDisabling = false

-- ╭────────────────────────────────────────────────────────────────╮
-- │ Companion Contract                                             │
-- ╰────────────────────────────────────────────────────────────────╯

local function releaseCompanion(player)
	if saveData.companion == player then
		saveData.companion = nil
		player:sendEvent("SunsDusk_ReleaseCompanion", self)
	end
end
	
local function becomeCompanion(player)
	saveData.companion = player
	isNPC = types.NPC.objectIsInstance(self)
	player:sendEvent("SunsDusk_RegisterCompanion", self)
end

-- ╭─────────────────────────────────────────────────────────────────╮
-- │ Spell Hit Detection                                             │
-- ╰─────────────────────────────────────────────────────────────────╯

local function spellHitDetection()
	typesActorActiveEffectsSelf = typesActorActiveEffectsSelf or types.Actor.activeEffects(self)
	if typesActorActiveEffectsSelf:getEffect(core.magic.EFFECT_TYPE.AbsorbHealth).magnitude < 1 then
		return
	end
	local newActiveSpells = {}
	
	typesActorActiveSpellsSelf = typesActorActiveSpellsSelf or types.Actor.activeSpells(self)
	for i, spell in pairs(typesActorActiveSpellsSelf) do
		if spell.caster and types.Player.objectIsInstance(spell.caster) then
			if not activeSpells[spell.activeSpellId] then
				spell.caster:sendEvent("SunsDusk_landedSpellHit", { self, spell.activeSpellId })
			end
			newActiveSpells[spell.activeSpellId] = true
		end
	end
	activeSpells = newActiveSpells
end

local function aggroPlayer(player)
	if saveData.companion ~= player then
		AI.startPackage{
			type = 'Combat',
			cancelOther = true,
			target = player,
			--destPosition = player.position,
			--isRepeat = true
		}
	end
end

-- ╭──────────────────────────────────────────────────────────────────╮
-- │ Main Loop                                                        │
-- ╰──────────────────────────────────────────────────────────────────╯

-- timers cause errors when the script is unhooked...

local function onUpdate()
	if core.getRealTime() < nextUpdate then return end
	
	local now = core.getRealTime()
	nextUpdate = now + 0.3 + math.random() / 5
	
	if isDead then return end
	
	spellHitDetection()
	
	if saveData.companion then
		-- followers: still-companion check
		local stillCompanion = false
		AI.forEachPackage(function(p)
			if p and p.type == "Follow" and p.target == saveData.companion then
				stillCompanion = true
			end
		end)
		if not stillCompanion then
			releaseCompanion(saveData.companion)
		end
	else
		-- companion detection
		if now > nextCompanionUpdate then
			AI.forEachPackage(function(p)
				if p and p.type == "Follow" and p.target and types.Player.objectIsInstance(p.target)
				then
					becomeCompanion(p.target)
				end
			end)
			nextCompanionUpdate = now + 1 + math.random()
		end
	end
end

-- ╭───────────────────────────────────────────────────────────────────╮
-- │ Becoming inactive / Unhook                                        │
-- ╰───────────────────────────────────────────────────────────────────╯
local function onInactive()
	core.sendGlobalEvent("SunsDusk_Unhook", self)
	if saveData.companion then
		saveData.companion:sendEvent("SunsDusk_ReleaseCompanion", self)
		saveData.companion = nil
		nextCompanionUpdate = core.getRealTime() + 10000000000
	end
end

-- ╭───────────────────────────────────────────────────────────────────╮
-- │ Combat stuff                                                      │
-- ╰───────────────────────────────────────────────────────────────────╯

if I.Combat then
	I.Combat.addOnHitHandler(function(attack)
		if attack.attacker and types.Player.objectIsInstance(attack.attacker) then
			attack.attacker:sendEvent("SunsDusk_landedHit", { self, attack })
		end
	end)
end

-- ╭───────────────────────────────────────────────────────────────────╮
-- │ onLoad, onSave                                                    │
-- ╰───────────────────────────────────────────────────────────────────╯

local function onLoad(data)
	saveData = data or {}
end

local function onSave()
	if saveData.companion then
		return saveData
	end
end

-- ╭───────────────────────────────────────────────────────────────────╮
-- │ Return                                                            │
-- ╰───────────────────────────────────────────────────────────────────╯

return {
	engineHandlers = {
		onUpdate   = onUpdate,
		onLoad     = onLoad,
		onInit     = onLoad,
		onSave     = onSave,
		onInactive = onInactive,
	},
	eventHandlers = {
		SunsDusk_aggroPlayer = aggroPlayer,
		Died = function()
			isDead = true
			for _, player in pairs(nearby.players) do
				player:sendEvent("SunsDusk_actorDied", self)
			end
			if saveData.companion then
				saveData.companion:sendEvent("SunsDusk_ReleaseCompanion", self)
				saveData.companion = nil
			end
			nextCompanionUpdate = core.getRealTime() + 10000000000
			core.sendGlobalEvent("SunsDusk_Unhook", self)
		end
	},
}