﻿local types = require("openmw.types")
local Actor = types.Actor
local dynamicStats = Actor.stats.dynamic
local attributesStats = Actor.stats.attributes
local core = require("openmw.core")
local self = require("openmw.self")
local async = require("openmw.async")

local saveTime
local saveTimeFatigue
local gameTime
local healthMax
local magikaMax
local fatigueMax
local health
local magika
local fatigue
local saveHealth
local saveMagika
local timeDelta
local healthGain
local magikaGain
local fatigueGain


local function onSave()
    return {
		ST = saveTime,
		SH = saveHealth,
		SM = saveMagika,
		STF = saveTimeFatigue,
		SF = saveFatigue,
    }
end

local function onLoad(data)
	if data then
		saveTime = data.ST
		saveHealth = data.SH
		saveMagika = data.SM
		saveTimeFatigue = data.STF
		saveFatigue = data.SF
	end
end


local function rest()
	--if self.recordId ~= "arrille" then return end
	
	async:newUnsavableSimulationTimer(10, rest)

	gameTime = core.getGameTime()
	health = dynamicStats.health(self).current
	magika = dynamicStats.magicka(self).current
	
	if Actor.isDead(self) or Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Paralyze).magnitude > 0 then
		saveTime = gameTime
		saveHealth = health
		saveMagika = magika
		saveFatigue = nil
		return
	end
	
	if saveFatigue then
		fatigue = dynamicStats.fatigue(self).current
		fatigueMax = dynamicStats.fatigue(self).base + dynamicStats.fatigue(self).modifier
		if fatigue < fatigueMax then
			timeDelta = gameTime - saveTimeFatigue
			fatigueGain = timeDelta / 30 * (core.getGMST("fFatigueReturnBase") + core.getGMST("fFatigueReturnMult") * attributesStats.endurance(self).modified) -- by default, natural fatigue regeneration is 2.5 + (0.02 * Endurance) every 30 s (game time)
			if saveFatigue >= fatigue then
				dynamicStats.fatigue(self).current = fatigue + fatigueGain
			elseif saveFatigue + fatigueGain > fatigue then
				dynamicStats.fatigue(self).current = saveFatigue + fatigueGain
			end
			if dynamicStats.fatigue(self).current > fatigueMax then
				dynamicStats.fatigue(self).current = fatigueMax
			end
		end
		saveFatigue = nil
	end
	
	if saveTime == nil then
		saveTime = core.getGameTime()
		return
	end
	timeDelta = gameTime - saveTime
	if timeDelta < 3600 then return end -- 3600 = 1h; i choose to wait 1h of gametime before calculate the rest gain

	healthMax = dynamicStats.health(self).base + dynamicStats.health(self).modifier
	if health < healthMax then
		healthGain = timeDelta * attributesStats.endurance(self).modified * 0.000014 -- timeDelta/3600 * (endurance * 0.1) / 2 (/2 because i consider he spend 50% of time to rest)
		if saveHealth == nil or saveHealth >= health then
			dynamicStats.health(self).current = health + healthGain
		elseif saveHealth + healthGain > health then
			dynamicStats.health(self).current = saveHealth + healthGain
		end
		if dynamicStats.health(self).current > healthMax then
			dynamicStats.health(self).current = healthMax
		end
	end
	
	magikaMax = dynamicStats.magicka(self).base + dynamicStats.magicka(self).modifier
	if magika < magikaMax then
		magikaGain = timeDelta * attributesStats.intelligence(self).modified * 0.000021 -- timeDelta/3600 * (intelligence * 0.15) / 2 (/2 because i consider he spend 50% of time to rest)
		if saveMagika == nil or saveMagika >= magika then
			dynamicStats.magicka(self).current = magika + magikaGain
		elseif saveMagika + magikaGain > magika then
			dynamicStats.magicka(self).current = saveMagika + magikaGain
		end
		if dynamicStats.magicka(self).current > magikaMax then
			dynamicStats.magicka(self).current = magikaMax
		end
	end
	
	saveTime = gameTime
	saveHealth = dynamicStats.health(self).current
	saveMagika = dynamicStats.magicka(self).current

end

local function save_fatigue()
	saveFatigue = dynamicStats.health(self).current
	saveTimeFatigue = core.getGameTime()
end

return {
    engineHandlers = {
		onLoad = onLoad,
		onSave = onSave,
		onActive = rest,
		onInactive = save_fatigue,
    },
    eventHandlers = {
    }
}

