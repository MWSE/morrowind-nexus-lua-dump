---@diagnostic disable: undefined-field


---comment
---@param e table|spellTickEventData
event.register("spellTick", function(e)
    local probableCaster = e.target and e.target.mobile
    if not probableCaster then return end
    local instance = e.effectInstance
    local validSummon = instance.createdData
    and instance.createdData.object
    and (instance.createdData.object.objectType == tes3.objectType.reference)
    if not validSummon then return end
    if not instance.createdData.object.data.spa_StealSummon_summonnedCreature then
        instance.createdData.object.data.spa_StealSummon_summonnedCreature = {summonner = probableCaster, value = probableCaster:getSkillValue(tes3.skill.conjuration)}
    end
end)

---comment
---@param summon tes3reference
---@param targetMobile tes3mobileActor|tes3mobilePlayer|tes3mobileNPC|tes3mobileCreature
---@return boolean
local function validSteal(summon, targetMobile)
    local luck = targetMobile.luck.current
    local random = math.random(100)
    local type = targetMobile:getSkillStatistic(tes3.skill.conjuration) and targetMobile:getSkillStatistic(tes3.skill.conjuration).type
    if type and (random > luck/(2*(2^type))) then
        return false
    end
    local value = targetMobile:getSkillValue(tes3.skill.conjuration)
    if value and (summon.data.spa_StealSummon_summonnedCreature.value >= value) then
        return false
    end
    if not (type and value) then
        return false
    end
    summon.data.spa_StealSummon_summonnedCreature.value = value
    return true
end


---comment
---@param e table|attackEventData
event.register("attack", function(e)
    if not (e.targetMobile and e.targetReference) then return end
    if not (e.reference and e.mobile) then return end
    if not e.reference.data.spa_StealSummon_summonnedCreature then return end
    if not validSteal(e.reference, e.targetMobile) then return end
    e.mobile.fight = 30
    tes3.setAIFollow{reference = e.mobile, target = e.targetMobile, reset = false}
    e.mobile:startCombat(e.reference.data.spa_StealSummon_summonnedCreature.summonner)
    e.reference.data.spa_StealSummon_summonnedCreature.summonner = e.targetMobile
    if e.targetMobile == tes3.mobilePlayer then
        e.reference.data.spa_SR_summonnedCreature = true
    else
        e.reference.data.spa_SR_summonnedCreature = nil
    end
end)