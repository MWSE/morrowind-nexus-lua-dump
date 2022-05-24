local this = {}
local common = require("mer.bardicInspiration.common")


local function calculateDispositionEffect(publican)
    --Disposition Effect
    local maxDispEffect = common.staticData.maxDispRewardEffect
    local disposition = publican.disposition or 50
    local dispEffect = math.remap(disposition, 0, 100, 1.0, maxDispEffect)
    common.log:trace("disp: %s effect: %s", disposition, dispEffect)
    return dispEffect
end

local function calculateSkillEffect()
    --Skill Effect
    if not common.skills.performance then return end
    local maxSkill = common.staticData.maxSkillRewardEffect
    local skill = common.skills.performance.value
    local skillEffect = math.remap(skill, 0, 100, 1.0, maxSkill)
    common.log:trace("skill: %s, Effect effect: %s", skill, skillEffect)
    return skillEffect
end

function this.calculate(publican)

    local dispEffect = calculateDispositionEffect(publican)
    local skillEffect = calculateSkillEffect()
    if not skillEffect then return end
    --Calculate Reward
    local baseRewardAmount = common.staticData.baseRewardAmount
    local reward = baseRewardAmount * dispEffect * skillEffect
    common.log:debug('setting reward amount to %s', reward)
    tes3.findGlobal("mer_perform_reward").value = reward
    return reward
end

function this.get()
    return tes3.findGlobal("mer_perform_reward").value
end

function this.give(amount)
    assert(amount)
    assert(type(amount) == "number")
    tes3.addItem({
        reference = tes3.player,
        item = "gold_001",
        count = amount
    })
    timer.frame.delayOneFrame(function()
        tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, amount, tes3.getObject("Gold_001").name)
    end)
end

function this.raiseDisposition(e)
    assert(e.actorId)
    assert(e.rewardAmount)
    local dispIncrease = math.clamp(
        e.rewardAmount * common.staticData.dispIncreasePerRewardAmount,
        1, common.staticData.maxDispositionIncrease
    )
    common.log:debug("Increasing %s's disposition by %s", e.actorId, dispIncrease)
    local command = string.format('modDisposition %d', dispIncrease)
    tes3.runLegacyScript{ reference = e.actorId, command = command }
end

return this