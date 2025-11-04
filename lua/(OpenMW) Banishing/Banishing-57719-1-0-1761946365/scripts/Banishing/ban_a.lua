
-- if this lands on the player, unhook bc players are not companions
local AI = require('openmw.interfaces').AI
if not AI then
	core.sendGlobalEvent("Banishing_Unhook", self)
	return
end


-- ============================== Imports ==============================
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby') -- reserved for future proximity logic
local self = require('openmw.self')
local anim = require('openmw.animation')
local types  = require('openmw.types')
local core   = require('openmw.core')
local vfs    = require('openmw.vfs')


local isDead   = false
local nextUpdate = 0
local activeSpells = {}
local removeTimer = math.huge
local summoner

AI.forEachPackage(function(p)
	if p and p.type == "Follow" and p.target 
	then
		summoner = p.target 
	end
end)
if summoner then
	local summonerHasSummonSpell = false
	for i, spell in pairs(types.Actor.activeSpells(summoner)) do
		if spell.caster and types.Player.objectIsInstance(spell.caster) then
			for _, effect in pairs(spell.effects) do
				if effect.id:find("summon") then
					summonerHasSummonSpell = effect.id
				end
			end
		end
	end
	if not summonerHasSummonSpell then
		summoner = nil
	end
end

if not summoner and self.type.record(self).type ~= types.Creature.TYPE.Daedra and self.type.record(self).type ~= types.Creature.TYPE.Undead then
	--print("unhooked",self, not summoner , self.type.record(self).type ~= types.Creature.TYPE.Daedra , self.type.record(self).type ~= types.Creature.TYPE.Undead )
	core.sendGlobalEvent("Banishing_Unhook", self)
	return
end
local myLevel = types.Actor.stats.level(self).current

local function onInactive()
	core.sendGlobalEvent("Banishing_Unhook", self)
end

local function onUpdate()
	if core.getRealTime() > removeTimer then
		core.sendGlobalEvent("Banishing_deleteMe", self)
		removeTimer = math.huge
	end
end

local function banish(data)
	local caster = data[1]
	local fakeFx = data[3]
	local ownerMult = summoner == caster and 2 or 1
	local ownerAdd = summoner == caster and 10 or 1
	local magnitude = data[2] * ownerMult + ownerAdd
	--print(ownerMult, magnitude, healthMod, daedraMod, dispellChance)
	if fakeFx then
		local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Dispel]
		core.sound.playSound3d(effect.hitSound, self, {volume=1.25})
		local model = types.Static.records[effect.hitStatic].model
		anim.addVfx(self, model)
	end
	types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - magnitude*0.9
	
	local healthMod = types.Actor.stats.dynamic.health(self).current/types.Actor.stats.dynamic.health(self).base
	local dispellChance = (magnitude/(myLevel*healthMod*8))^3 -- 500 / 600 = 0.75
	
	if summoner then
		if math.random() < dispellChance then
			types.Actor.stats.dynamic.fatigue(self).current = -40
			removeTimer = core.getRealTime() + 0.8
			anim.addVfx(self, types.Static.records["VFX_Soul_Trap"].model)
		end
	end
end

return {
	engineHandlers = {
		onUpdate   = onUpdate,
		onInactive = onInactive,
	},
	eventHandlers = {
		Banishing_banish = banish
	},
}