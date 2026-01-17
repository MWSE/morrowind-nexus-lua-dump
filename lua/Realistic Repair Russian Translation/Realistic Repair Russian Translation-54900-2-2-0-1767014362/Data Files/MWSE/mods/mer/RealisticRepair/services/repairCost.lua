

local PassTime = require("mer.RealisticRepair.services.PassTime")
local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Handles fatigue and time cost when repairing or enhancing
---@class RepairCost
local RepairCost = {}


function RepairCost.handleTimeCost()
    if not config.mcm.enableTimeCost then return end
    local skillValue = tes3.mobilePlayer:getSkillValue(tes3.skill.armorer)
    local timeCost = math.remap(skillValue, 0, 100,
        config.mcm.repairTimeMin, config.mcm.repairTimeMax)
    timeCost = math.clamp(timeCost, config.mcm.repairTimeMin, config.mcm.repairTimeMax)
    local secondsFadeOut = math.clamp(timeCost * 0.5, 0.25, 1)

    logger:debug("Applying time cost of %.2f hours", timeCost)
    PassTime.new{
        hoursPassed = timeCost,
        duration = secondsFadeOut
    }:run()
end

function RepairCost.handleFatigueCost()
    if not config.mcm.enableFatigueCost then return end
    local skillValue = tes3.mobilePlayer:getSkillValue(tes3.skill.armorer)
    local fatigueCost = math.remap(skillValue, 0, 100,
        config.mcm.repairFatigueMin, config.mcm.repairFatigueMax)
    fatigueCost = math.clamp(fatigueCost, config.mcm.repairFatigueMax, config.mcm.repairFatigueMin)
    --Prevent reducing fatigue below 0
    local currentFatigue = tes3.mobilePlayer.fatigue.current
    fatigueCost = math.min(fatigueCost, currentFatigue)

    logger:debug("Applying fatigue cost of %.2f", fatigueCost)
    tes3.modStatistic{
        reference = tes3.player,
        name = "fatigue",
        current = -fatigueCost
    }
end

return RepairCost