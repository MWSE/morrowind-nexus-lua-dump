--local crafting = require("Crafting.module")
--Common
local this = {}
local skillModule = require("OtherSkills.skillModule")

local activateFrostwind
local function checkFrostwindActive()
	if tes3.getGlobal("a_activate_frostwind") ~= activateFrostwind then
		activateFrostwind = tes3.getGlobal("a_activate_frostwind")
		local isActive = (activateFrostwind == 1 ) and "active" or "inactive"
		skillModule.updateSkill( "Survival", {active = isActive} )
	end
end

local function onSkillsReady()
	skillModule.registerSkill(
		"Survival", 
		{	name 			=		"Survival", 
			icon 			=		"Icons/survival/skill/survival.dds", 
			value			= 		5,
			attribute 		=		tes3.attribute.endurance,
			description 	= 		"The Survival skill determines your ability to deal with harsh weather conditions and perform actions such as chopping wood and creating campfires effectively.",
			specialization 	= 		tes3.specialization.stealth,
			active			= 		(tes3.getGlobal("a_activate_frostwind") and "active" or "inactive")
		}
	)
	print("[Frostwind INFO] skills registered")
	event.register("simulate", checkFrostwindActive)
end


local function onLoaded(e)
	--Persistent data stored on player reference 
	-- ensure data table exists
	local data = tes3.getPlayerRef().data
	data.frostwind = data.frostwind or {}
	-- create a public shortcut
	this.data = data.frostwind
	print("[Frostwind INFO] Common.lua loaded successfully")
end


--register events
event.register("loaded", onLoaded)
event.register("OtherSkills:Ready", onSkillsReady)

return this 