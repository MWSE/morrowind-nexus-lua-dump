local this = {}
local common = require("mer.bardicInspiration.common")
local messages = require("mer.bardicInspiration.messages.messages")
local tipTimer

local totalTips = nil

--Internal Functions---------------------------------------------------


local function calculateLuckIntervalEffect()
    --calculate luck effect
    local maxLuckEffect = common.staticData.maxLuckTipIntervalEffect
    local luck = tes3.mobilePlayer.luck.current
    local luckEffect = math.remap(luck, 40, 100, 1.0, maxLuckEffect)
    luckEffect = math.clamp(luckEffect, maxLuckEffect, 1.0)
    common.log:debug("Luck effect for interval: %s", luckEffect)
    return luckEffect
end

local function calculateSkillIntervalEffect()
    if not common.skills.performance then return end
    --calculate skill effect
    local maxSkillEffect = common.staticData.maxSkillTipIntervalEffect
    local skill = common.skills.performance.value
    local skillEffect = math.remap(skill, 0, 100, 1.0, maxSkillEffect)
    common.log:debug("Skill effect for tip: %s", skillEffect)
    return skillEffect
end

local function generateTipInterval()
    local luckEffect = calculateLuckIntervalEffect()
    local skillEffect = calculateSkillIntervalEffect()
    --calculate min interval
    local minInterval = common.staticData.baseTipInterval * luckEffect * skillEffect
    common.log:debug("Min interval: %s seconds", minInterval)
    --generate tip interval
    local interval = math.random(minInterval, common.staticData.maxTipInterval)
    common.log:debug("Generated interval of %s seconds", interval)
    return interval
end

local function generateTipMessage()
    local message = table.choice(messages.tips)
    common.log:debug("Messagee chosen: %s", message)
    return message
end

local function calculateDifficultyTipEffect()
    local difficulty = common.data.currentSongDifficulty or "beginner"
    return common.staticData.difficulties[difficulty].tipMulti
end

local function calculateSkillTipEffect()
    --calculate skill effect
    local maxSkillEffect = common.staticData.maxSkillTipEffect
    local skill = common.skills.performance.value
    local skillEffect = math.remap(skill, 0, 100, 1.0, maxSkillEffect)
    common.log:debug("Skill effect for tip: %s", skillEffect)
    return skillEffect
end

local function generateTip()
    local skillEffect = calculateSkillTipEffect()
    local difficultyEffect = calculateDifficultyTipEffect()
    --Calcaulte max tip
    local maxTip = common.staticData.baseTip * skillEffect * difficultyEffect
    common.log:debug("Max tip: %s gold", maxTip)
    --generate actual tip
    local tip = math.random(common.staticData.minTip, maxTip)
    common.log:debug("Generated tip of %s gold", tip)
    return tip
end

local function doTip()
    local tip = generateTip()
    common.log:debug("Giving player tip of %s gold", tip)
    tes3.addItem({
        reference = tes3.player,
        item = "gold_001",
        count = tip
    })
    common.log:debug("Playing tip message")
    local message = string.format(generateTipMessage(), tip)
    tes3.messageBox(message)

    totalTips = totalTips + tip
    common.log:debug("Adding to total, which is now %d", totalTips)

    common.log:debug("restarting tip timer")
    this.start()
end


--Public Functions---------------------------------------------------
function this.start()
    if totalTips == nil then totalTips = 0 end
    common.log:debug("\nStarting tip timer")
    tipTimer = timer.start{
        duration = generateTipInterval(),
        iterations = 1,
        callback = doTip
    }
end

function this.stop()
    totalTips = nil
    common.log:debug("Stopping tip timer\n")
    if tipTimer then
        tipTimer:cancel()
    end
end

function this.getTotal()
    common.log:debug("Returning total tips of %d", totalTips or 0)
    return totalTips or 0
end

--Stop timer on game load
local function clearOnLoad()
    this.stop()
end
event.register("BardicInspiration:DataLoaded", clearOnLoad)

return this