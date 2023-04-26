local skillModule = require("OtherSkills.skillModule")
local socket = require("socket")
local pRXPGain = 0.002;
local weightRatioForPerks = 0.7
--[[
    Thanks to Merlord for SkillsModule, and troubleshooting in discord!

]]--

local function setFeather()
    --tes3.messageBox("Attempting Feather Perk")
    
    tes3.removeSpell{
        reference = tes3.player,
        spell = "packrat_feather"
    }

    local skill = skillModule.getSkill("Packrat")

    local featherSpell = tes3.getObject("packrat_feather")

    featherSpell.effects[1].min = skill.value
    featherSpell.effects[1].max = skill.value
    tes3.addSpell{
        reference = tes3.player,
        spell = "packrat_feather"
    }
end


local function setPackratGainValue()
    local weightRatio = tes3.mobilePlayer.encumbrance.current / tes3.mobilePlayer.encumbrance.base
    local skill = skillModule.getSkill("Packrat")
    if (weightRatio > weightRatioForPerks) then
        if (tes3.mobilePlayer.isMovingForward or tes3.mobilePlayer.isMovingBack or tes3.mobilePlayer.isMovingLeft or tes3.mobilePlayer.isMovingRight) then
            skill:progressSkill(pRXPGain)
        end
    end
end

local function onSkillReady() -- create the skill
    skillModule.registerSkill(
         "Packrat",
         {
             name = "Packrat",
             icon = "Icons/RFD/Gool/Packrat.dds",
             value = 1,
             progress = 0,
             attribute = tes3.attribute.strength,
             description = "This skill lets organize your inventory more effectively.",
             specialization = tes3.specialization.stealth
         }
     )
    tes3.addSpell{
        reference = tes3.player,
        spell = "packrat_feather"
    }
end

local function initCalcPackrat()
    event.register("exerciseSkill", setPackratGainValue,{filter = 8})
end

local function initialized()
    event.register("OtherSkills:Ready", onSkillReady)
    event.register("menuEnter", setFeather)
end    

event.register("initialized", initialized)
event.register("initialized", initCalcPackrat)
