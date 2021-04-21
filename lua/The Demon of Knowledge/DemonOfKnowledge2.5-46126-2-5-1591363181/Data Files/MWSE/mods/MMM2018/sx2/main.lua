if (mwse.buildDate == nil) or (mwse.buildDate < 20181102) then
    local function warning()
        tes3.messageBox(
            "[Demon Of Knowledge ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

local skillModule = require("OtherSkills.skillModule")
local common = require("MMM2018.sx2.common")


if not skillModule then
    local function warningSkill()
        tes3.messageBox(
            "[Demon Of Knowledge ERROR] You need to install Skills Module to use this mod!"
        )
    end
    event.register("initialized", warningSkill)
    event.register("loaded", warningSkill)
    return
end

--Needs to be initialized before "initialized" for fader event to work
local apocryphaFader = require("MMM2018.sx2.apocryphaFader")
local function initialized(e)

	if not tes3.isModActive("DemonOfKnowledge.ESP") then
		print("[Demon of Knowledge: INFO] ESP not loaded")
		return
	end

	
	local stickyBook = require("MMM2018.sx2.stickyBook")
	local enemyEffects = require("MMM2018.sx2.enemyEffects")
	local tomeOfDiscovery = require("MMM2018.sx2.tomeOfDiscovery")
	local occulomiconOpen = require("MMM2018.sx2.occulomiconOpen")
	local inscribe = require("MMM2018.sx2.inscribe")
	local inkwell = require("MMM2018.sx2.inkwell")
	local clutter = require("MMM2018.sx2.clutter")
	print("[Demon of Knowledge: INFO] Initialized Hermaeus Mora")
	event.trigger("Hermes:Initialized")
end
event.register("initialized", initialized)

--SKILLS------------------------------------------------------
local activateSkill
local function checkGlobal()
	local global = tes3.getGlobal(common.globalIds.inscriptionSkill)
	if global ~= activateSkill then
		activateSkill = globalW
		skillModule.updateSkill( common.inscriptionSkillId, { active = ( global == 1 and "active" or "inactive" ) } )
	end
end

local function onSkillsReady()
	skillModule.registerSkill(
		common.inscriptionSkillId, 
		{	name 			=		"Inscription", 
			icon 			=		"Icons/MMM2018/inscription.dds", 
			value			= 		30,
			attribute 		=		tes3.attribute.intelligence,
			description 	= 		"The Inscription skill determines your ability to write magical scrolls using a quill.",
			specialization 	= 		tes3.specialization.magic,
			active			= 		(tes3.getGlobal("sx2_inscription_active") and "active" or "inactive")
		}
	)
	event.unregister("simulate", checkGlobal)
	event.register("simulate", checkGlobal)
end
event.register("OtherSkills:Ready", onSkillsReady)