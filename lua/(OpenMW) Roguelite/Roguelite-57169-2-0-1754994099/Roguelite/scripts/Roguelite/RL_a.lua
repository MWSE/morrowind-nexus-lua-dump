local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local anim = require('openmw.animation')
local types = require("openmw.types")
local AI = require('openmw.interfaces').AI
local core = require('openmw.core')
local hasDied = false
local nextUpdate = 0
local deaths = {
["death1"] = true,
["death2"] = true,
["death3"] = true,
["death4"] = true,
}

local function soultrapVFX()
    anim.addVfx(self, types.Static.records["VFX_Soul_Trap"].model)
end

I.AnimationController.addTextKeyHandler('', function(groupname, key) --self start/stop, touch start/stop, target start/stop
	if deaths[groupname] and not hasDied and types.Actor.isDead(self) then
		print(self.recordId.." died")
		for _, player in pairs(nearby.players) do
			player:sendEvent("Roguelite_actorDied", self)
		end
		hasDied = true
	end
end)

local function releaseCompanion(player)
	if companion == player then
		companion = nil
		types.NPC.stats.attributes["speed"](self).base = baseSpeed
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
	types.Actor.stats.dynamic.health(self).base = types.Actor.stats.dynamic.health(self).base*1.1 + types.Actor.stats.level(player).current* 5
	types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).base
	companion = player
	baseSpeed = types.NPC.stats.attributes["speed"](self).base
	
	isNPC = types.NPC.objectIsInstance(self)
	if isNPC then
		playerSpeed = types.NPC.stats.attributes["speed"](companion).base
	else
		playerSpeed = types.NPC.stats.attributes["speed"](companion).base/2
	end
end


local function cb(p)
	--print(self,p.type,p.target)
	if p and companion
	--and (p.type == "Follow" or p.type == "Combat" or p.type == "Pursue") 
	and (p.type == "Combat" or p.type == "Pursue") 
	then
		isInCombat = true
		if p.target and types.Player.objectIsInstance(p.target) then
			AI.startPackage{
				type = 'Follow',
				cancelOther = true,
				target = companion,
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
	if companion and not types.Actor.isDead(self) then
		core.sendGlobalEvent("Roguelite_catchUpTeleport", {self, companion})
	end
end


local function onUpdate()
	if companion and not types.Actor.isDead(self) then
		local now = core.getRealTime()
		if now > nextUpdate then
			if isNPC then
				playerSpeed = types.NPC.stats.attributes["speed"](companion).base
			else
				playerSpeed = types.NPC.stats.attributes["speed"](companion).base/2
			end
			nextUpdate = now + 0.3+math.random()/5
			isInCombat = false
			AI.forEachPackage(cb)
		end
		local activeSpells = types.Actor.activeSpells(self)
		local newSpellCount = userDataLength(types.Actor.activeSpells(self))
		local distanceToPlayer = (self.position - companion.position):length()
		if distanceToPlayer > 5000 then
			core.sendGlobalEvent("Roguelite_catchUpTeleport", {self, companion})
		end
		if isInCombat then
			types.NPC.stats.attributes["speed"](self).base = baseSpeed
		else
			types.NPC.stats.attributes["speed"](self).base = math.max(baseSpeed, playerSpeed*0.7) + math.max(0,distanceToPlayer-100)/10
		end
		if newSpellCount ~=spellCount then
			for a,b in pairs(types.Actor.activeSpells(self)) do
				local friendlyFire = false
				if types.Player.objectIsInstance(b.caster) then
					
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
		spellCount = newSpellCount
	end
end


local function onLoad(data)
	if data then
		companion = data.companion
		baseSpeed = data.baseSpeed
		---------------------
		isNPC = types.NPC.objectIsInstance(self)
		if isNPC then
			playerSpeed = types.NPC.stats.attributes["speed"](companion).base
		else
			playerSpeed = types.NPC.stats.attributes["speed"](companion).base/2
		end
	end
end

local function onSave()
	if companion then
		return {companion = companion, 
				baseSpeed = baseSpeed,
				}
	end
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
		Roguelite_releaseCompanion = releaseCompanion
    }
}
