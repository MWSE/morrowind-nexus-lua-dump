--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk -.-.- Actor Sniffer								   	   │
│  detect follow packages, relay hits/spells, tidy unhooks             │
╰──────────────────────────────────────────────────────────────────────╯
]]

-- if this lands on the player, unhook bc players are not companions
local AI = require('openmw.interfaces').AI
if not AI then
	core.sendGlobalEvent("SunsDusk_Unhook", self)
	return
end

-- ───────────────────────────────────────────────────────────────── Imports ─────────────────────────────────────────────────────────────────
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby') -- reserved for future proximity logic
local self = require('openmw.self')
local anim = require('openmw.animation')
local types  = require('openmw.types')
local core   = require('openmw.core')
local vfs	= require('openmw.vfs')

-- ───────────────────────────────────────────────────────────────── State ───────────────────────────────────────────────────────────────
local hasDied  = false
local isDead   = false
local nextUpdate = 0
local nextCompanionUpdate = 0
local isRogueliteCompanion = false  -- lever for future rulesets
local activeSpells = {}
local items = {}
local isDisabling = false

-- ╭────────────────────────────────────────────────────────────────╮
-- │ Companion Contract	  			                                │
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
-- │ Unhook			                                                 │
-- ╰─────────────────────────────────────────────────────────────────╯



-- ╭─────────────────────────────────────────────────────────────────╮
-- │ Spell Hit Detection                                             │
-- │ One event per new activeSpellId from the player                 │
-- ╰─────────────────────────────────────────────────────────────────╯

local function spellHitDetection()
	local newActiveSpells = {}
	for i, spell in pairs(types.Actor.activeSpells(self)) do
		if spell.caster and types.Player.objectIsInstance(spell.caster) then
			if not activeSpells[spell.activeSpellId] then
				spell.caster:sendEvent("SunsDusk_landedSpellHit", { self, spell.activeSpellId })
			end
			newActiveSpells[spell.activeSpellId] = true
			----------------- disable friendly fire:) ------------------
			-- local spell = core.magic.spells.records[b.id]
			--for c,d in pairs(spell.effects) do
			--	local effect = core.magic.effects.records[d.id]
			--	if effect.harmful then
			--		friendlyFire = true
			--	end
			--end
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
-- │ Main Loop (Cheap)                                                │
-- │ If following our saved handler -> we are companion				  │
-- │ If the follow package vanishes -> release						  │
-- ╰──────────────────────────────────────────────────────────────────╯

local function onUpdate()
	if saveData.companion and not isDead then
		local now = core.getRealTime()
		if now > nextUpdate then
			isDead = types.Actor.isDead(self)
			if not isDead then
				spellHitDetection()
			end
			
			nextUpdate = now + 0.3 + math.random() / 5
			local stillCompanion = false
			
			AI.forEachPackage(function(p)
				if p and p.type == "Follow" and p.target == saveData.companion then
					stillCompanion = true
				end
			end)
			
			if saveData.companion and not stillCompanion then
				--print("no follow pack found")
				releaseCompanion(saveData.companion)
			end
		end
		
	elseif not saveData.companion then
		local now = core.getRealTime()
		if now > nextUpdate then
			--isDead = types.Actor.isDead(self)
			--if not isDead then
				spellHitDetection()
				--AI.forEachPackage(function(p)
				--	if p and p.type == "Follow" and p.target and types.Player.objectIsInstance(p.target)
				--	then
				--		becomeCompanion(p.target)
				--	end
				--end)
			--end
			nextUpdate = now + 0.3 + math.random() / 5
		end
		if now > nextCompanionUpdate then
			--isDead = types.Actor.isDead(self)
			if not isDead then
				AI.forEachPackage(function(p)
					if p and p.type == "Follow" and p.target and types.Player.objectIsInstance(p.target)
					then
						becomeCompanion(p.target)
					end
				end)
			end
			nextCompanionUpdate = now + 1 + math.random() 
		end
	end
end

-- ╭───────────────────────────────────────────────────────────────────╮
-- │ Save only when tracking a companion.							   │
-- ╰───────────────────────────────────────────────────────────────────╯
local function onInactive()
	core.sendGlobalEvent("SunsDusk_Unhook", self)
	if saveData.companion then
		saveData.companion:sendEvent("SunsDusk_ReleaseCompanion", self)
		saveData.companion = nil
		nextCompanionUpdate = core.getRealTime() + 10000000000
	end
end
local function onLoad(data)
	saveData = data or {}
end

local function onSave()
	if saveData.companion then
		return saveData
	end
end

-- ╭───────────────────────────────────────────────────────────────────╮
-- │ Combat stuff			                                           │
-- ╰───────────────────────────────────────────────────────────────────╯

if I.Combat then
	I.Combat.addOnHitHandler(function(attack)
		if attack.attacker and types.Player.objectIsInstance(attack.attacker) then
			attack.attacker:sendEvent("SunsDusk_landedHit", { self, attack })
		end
	end)
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Handlers   									                    │
-- ╰────────────────────────────────────────────────────────────────────╯

return {
	engineHandlers = {
		onUpdate   = onUpdate,
		onLoad	 = onLoad,
		onInit	 = onLoad,
		onSave	 = onSave,
		onInactive = onInactive,
	},
	eventHandlers = {
		SunsDusk_aggroPlayer = aggroPlayer,
		Died = function()
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