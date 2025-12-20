local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local anim = require('openmw.animation')
local types = require("openmw.types")
local AI = require('openmw.interfaces').AI
local core = require('openmw.core')
local hasDied = false
local nextUpdate = 0
local isNPC = types.NPC.objectIsInstance(self)
local hasVfx = false
local deaths = {
	["death1"] = true,
	["death2"] = true,
	["death3"] = true,
	["death4"] = true,
	["death5"] = true,
	["deathknockdown"] = true,
	["deathknockout"] = true,
}

local function soultrapVFX()
	anim.addVfx(self, types.Static.records["VFX_Soul_Trap"].model)
end

I.AnimationController.addTextKeyHandler('', function(groupname, key) --self start/stop, touch start/stop, target start/stop
	--print(groupname)
	if deaths[groupname] and not hasDied and types.Actor.isDead(self) then
		--print(self.recordId.." died")
		for _, player in pairs(nearby.players) do
			player:sendEvent("Roguelite_actorDied", self)
		end
		hasDied = true
	end
end)

local function releaseCompanion(player)
	if saveData.companion == player then
		saveData.companion = nil
		types.NPC.stats.attributes["speed"](self).base = saveData.baseSpeed
		local idleTable = {
			idle2 = 60,
			idle3 = 50,
			idle4 = 40,
			idle5 = 30,
			idle6 = 20,
			idle7 = 10,
			idle8 = 0,
			idle9 = 25
		}
		AI.startPackage{
			type = 'Wander',
			distance = 5000,
			idle = idleTable,
			isRepeat = true
		}
	end
end
		
local function becomeCompanion(player)
	types.Actor.stats.dynamic.health(self).base = types.Actor.stats.dynamic.health(self).base*1.05 + types.Actor.stats.level(player).current* 3
	types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).base
	saveData.companion = player
	saveData.baseSpeed = types.NPC.stats.attributes["speed"](self).base
	
	if isNPC then
		saveData.playerSpeed = types.NPC.stats.attributes["speed"](saveData.companion).base
	else
		saveData.playerSpeed = types.NPC.stats.attributes["speed"](saveData.companion).base/2
	end
end

local function registerWither(player)
	saveData.witherPlayers[player.id] = true
	saveData.witherExists = true
end


local function cb(p)
	--print(self,p.type,p.target)
	if p and saveData.companion
	--and (p.type == "Follow" or p.type == "Combat" or p.type == "Pursue") 
	and (p.type == "Combat" or p.type == "Pursue") 
	then
		saveData.isInCombat = true
		if p.target and types.Player.objectIsInstance(p.target) then
			AI.startPackage{
				type = 'Follow',
				cancelOther = true,
				target = saveData.companion,
				--destPosition = player.position,
				isRepeat = true
			}
		end
	end
end

local function userDataLength (userData)
	local i = 0
	for _ in pairs(userData) do
		i=i+1
	end
	return i
end

local function onInactive()
	if saveData.companion and not types.Actor.isDead(self) then
		core.sendGlobalEvent("Roguelite_catchUpTeleport", {self, saveData.companion})
	else
		core.sendGlobalEvent("Roguelite_onhookObject", self)
	end
end


local function onUpdate()
	local removeVfx = hasVfx
	if not types.Actor.isDead(self) then
		if saveData.companion then
			local now = core.getSimulationTime()
			if now > nextUpdate then
				if isNPC then
					saveData.playerSpeed = types.NPC.stats.attributes["speed"](saveData.companion).base
				else
					saveData.playerSpeed = types.NPC.stats.attributes["speed"](saveData.companion).base/2
				end
				nextUpdate = now + 0.3+math.random()/5
				saveData.isInCombat = false
				AI.forEachPackage(cb)
			end
			local activeSpells = types.Actor.activeSpells(self)
			local newSpellCount = userDataLength(types.Actor.activeSpells(self))
			local distanceToPlayer = (self.position - saveData.companion.position):length()
			if distanceToPlayer > 5000 then
				core.sendGlobalEvent("Roguelite_catchUpTeleport", {self, saveData.companion})
			end
			if saveData.isInCombat then
				types.NPC.stats.attributes["speed"](self).base = saveData.baseSpeed
			else
				types.NPC.stats.attributes["speed"](self).base = math.max(saveData.baseSpeed, saveData.playerSpeed*0.7) + math.max(0,distanceToPlayer-100)/10
			end
			if newSpellCount ~= saveData.spellCount then
				for a,b in pairs(types.Actor.activeSpells(self)) do
					local friendlyFire = false
					if b.caster and types.Player.objectIsInstance(b.caster) then
						
						--local spell = core.magic.spells.records[b.id]
						for c,d in pairs(b.effects) do
							local effect = core.magic.effects.records[d.id]
							if effect.harmful then
								friendlyFire = true
							end
						end
					end
					if friendlyFire then
						types.Actor.activeSpells(self):remove(b.activeSpellId)
					end
				end
			end
			saveData.spellCount = newSpellCount
		elseif saveData.witherExists then
			local now = core.getSimulationTime()
			if now > nextUpdate then
				local isAttackingWither = false
				
				AI.forEachPackage(function(p)
					if p and p.target and saveData.witherPlayers[p.target.id] then
						if p.type ~= "Follow" then
							isAttackingWither = p.target
						end
					end
				end)
				if isAttackingWither then
					local mitigation = 0.25
					if isNPC then
						local luck = types.NPC.stats.attributes["luck"](self).modified
						mitigation = math.max(mitigation, luck / (luck+100))
					end
					local maxHealth = types.Actor.stats.dynamic.health(isAttackingWither).current
					local damageAmount = maxHealth * 0.03 * math.max(0.2, 1-(isAttackingWither.position - self.position):length()/1000) * (1-mitigation)
					if damageAmount > 0 then
						local currentHealth = types.Actor.stats.dynamic.health(self).current
						types.Actor.stats.dynamic.health(self).current = math.max(0, types.Actor.stats.dynamic.health(self).current - damageAmount)
						removeVfx = false
						if not hasVfx then
							local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.DamageHealth]
							local model = types.Static.records[effect.hitStatic].model
							anim.addVfx(self, model, {loop = true, vfxId = "rogueliteWitheringAuraVfx"})
							hasVfx = true
						end
					end
				end
				nextUpdate = now + 1
			else
				removeVfx = false
			end
		end
	end
	if removeVfx then
		anim.removeVfx(self, "rogueliteWitheringAuraVfx")
		hasVfx = false
	end
end


local function onLoad(data)
	saveData = data or {}
	saveData.witherPlayers = saveData.witherPlayers or {}
end

local function onSave()
	return saveData
end


return {
	engineHandlers = {
		onUpdate = onUpdate,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
		onInactive = onInactive,
	},
	eventHandlers = {
		Roguelite_soultrapVFX = soultrapVFX,
		Roguelite_becomeCompanion = becomeCompanion,
		Roguelite_releaseCompanion = releaseCompanion,
		Roguelite_registerWither = registerWither
	}
}