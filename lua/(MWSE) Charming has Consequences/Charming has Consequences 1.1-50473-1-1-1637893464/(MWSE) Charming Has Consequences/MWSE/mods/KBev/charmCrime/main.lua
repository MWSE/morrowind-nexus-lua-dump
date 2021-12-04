--Config Load
local confPath = "KBev_charmCrime"
local config = mwse.loadConfig(confPath)
---default settings
if not config then
	config = { 
		bHighSkillPreventsCrime = true, 
		iCrimeAvoidanceThreshold = 100,
		iCharmBounty = 30
	}
end


--Functions
---reportCrime: Sends a crime event in which the caster is the criminal, and their target is the victim. Force
local function reportCrime(effect)
	tes3.triggerCrime({ 
		criminal = effect.caster,
		type = tes3.crimeType.attack, 
		value = config.iCharmBounty, 
		victim = effect.target 
	})
end

---isTargetNPC: Checks if the effect's target is an NPC
local function isTargetNPC(effect)
	--Failsafe in case effect is broken
	if (effect.target == nil) then
		return false
	end
	
	return (effect.target.object.objectType == tes3.objectType.npc)
end

---isEffectExpired: checks to see if an effect has expired (elapsed time >= effect duration)
----11/25/2021: Edited to check effectInstance.state, rather than faffing about with tables, which should slightly improve performance
local function isEffectExpired(e)
	return (e.effectInstance.state == tes3.spellState.ending)
end

---isCrimeDetectable: returns false if Skill based crime avoidance is enabled and the caster meets the threshold
local function isCrimeDetectable(e)
	return not ((config.bHighSkillPreventsCrime) and (e.caster.mobile.illusion.current >= config.iCrimeAvoidanceThreshold))
end

--Events
---onSpellTick: checks to validate effect state, then reports crime if necessary
local function onSpellTick(e)
	if (not(e.target == e.caster)) and (isTargetNPC(e)) and (e.effectId == tes3.effect.charm) and (isEffectExpired(e)) and (isCrimeDetectable(e)) then
		reportCrime(e)
	end
end

--MCM Code
local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Charming has Consequences")
	template:saveOnClose(confPath, config)
    local page = template:createPage()
    page:createOnOffButton {
		label = "Enable Crime Avoidance with high illusion?",
		variable = EasyMCM.createTableVariable {
			id = "bHighSkillPreventsCrime",
			table = config,
			defaultSetting = true
		}
	}
	page:createSlider {
		label = "Skill Threshold for Crime Avoidance (Default 100)",
		min = 0, max = 100,
		variable = EasyMCM:createTableVariable {
			id = "iCrimeAvoidanceThreshold",
			table = config,
			defaultSetting = 100
		}
	}
	page:createSlider {
		label = "Bounty for charming an NPC (Default 30)",
		min = 5, max = 1000,
		step = 5, jump = 25,
		variable = EasyMCM:createTableVariable {
			id = "iCharmBounty",
			table = config,
			defaultSetting = 30
		}
	}
	
    EasyMCM.register(template)
end


--initialization
local function onInit()
	event.register("spellTick", onSpellTick)
end
event.register("initialized", onInit)
event.register("modConfigReady", registerModConfig)