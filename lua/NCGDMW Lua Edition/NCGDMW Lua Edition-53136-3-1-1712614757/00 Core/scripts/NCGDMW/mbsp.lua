local async = require('openmw.async')
local self = require('openmw.self')
local types = require('openmw.types')
local Player = require('openmw.types').Player
local dynamic = types.Actor.stats.dynamic

local S = require('scripts.NCGDMW.settings')
local C = require('scripts.NCGDMW.common')

local storedMagicka = 0

local magicSkills = {
    destruction = true,
    restoration = true,
    conjuration = true,
    mysticism = true,
    illusion = true,
    alteration = true,
}

local deltaMTable = {}

local function getRefund(skill, cost)
    local refund
    refund = S.playerMBSPStorage:get("refundMult") * cost * (math.sqrt(math.max((skill - S.playerMBSPStorage:get("refundStart")), 0)) / 100)
    if refund > cost then
        refund = cost
    end
    return refund
end

local function addDeltaMagicka(val)
    table.insert(deltaMTable, val)
end

local function removeOldestDeltaMagicka()
    table.remove(deltaMTable, 1)
end

local function getDeltaMagicka()
    if #deltaMTable > 0 then
        return math.max(unpack(deltaMTable), 0)
    else
        return 0
    end
end

----------------Engine Handlers--------------------

local function getSkillUsedHandler()
    return function(skillId, params)
        if not magicSkills[skillId] or not S.playerMBSPStorage:get("mbspEnabled") then return end

        local magickaXPRate = S.playerMBSPStorage:get("magickaXPRate")
        local cost = Player.getSelectedSpell(self).cost
        C.debugPrint(
                "MBSP: Magic skill '%s' increase, base gain = %s, cost = %s, XP rate = %s, final gain = %s",
                skillId, params.skillGain, cost, magickaXPRate, params.skillGain * cost / magickaXPRate
        )
        params.skillGain = params.skillGain * cost / magickaXPRate
        if S.playerMBSPStorage:get("refundEnabled") then
            local refund = getRefund(Player.stats.skills[skillId](self).base, cost)
            if refund > 0 then
                C.debugPrint("MBSP: Magic skill %s refund: %s", skillId, refund)
                C.modMagicka(refund)
            end
        end
    end
end

local lastOnFrame = 1

-- MBSP + Uncapper, only for openmw 0.48
local function onFrame(deltaTime)
    if S.isLuaApiRecentEnough then return end
    lastOnFrame = lastOnFrame + deltaTime
    if lastOnFrame < 0.5 then return end
    lastOnFrame = 0

    local deltaMagicka = 0
    if S.playerMBSPStorage:get("mbspEnabled") then
        --Stores all changes in magicka in the last 2 seconds
        if storedMagicka - dynamic.magicka(self).current > 1 then
            addDeltaMagicka(storedMagicka - dynamic.magicka(self).current)
            async:newSimulationTimer(
                    2,
                    async:registerTimerCallback(
                            "removeOldestDeltaMagicka",
                            function()
                                removeOldestDeltaMagicka()
                            end
                    )
            )
        end
        deltaMagicka = getDeltaMagicka()
    end

    for skillId, _ in pairs(C.skillProgress()) do
        local progress = Player.stats.skills[skillId](self).progress
        local skillGain = 0
        if Player.stats.skills[skillId](self).base < 100 then
            local progressDiff = progress - C.skillProgress()[skillId]
            --If the skill has leveled up normally
            if progressDiff < -0.5 then
                C.skillProgress()[skillId] = 0
                --If increase in skill progress is detected
            elseif progressDiff > 0.001 then
                skillGain = progressDiff
                if magicSkills[skillId] and S.playerMBSPStorage:get("mbspEnabled") then
                    skillGain = skillGain * deltaMagicka / S.playerMBSPStorage:get("magickaXPRate")
                    Player.stats.skills[skillId](self).progress = Player.stats.skills[skillId](self).progress + skillGain - progressDiff
                    if Player.stats.skills[skillId](self).progress >= 1 then
                        C.increaseSkill(skillId)
                        Player.stats.skills[skillId](self).progress = 0
                    end
                end
                C.skillProgress()[skillId] = Player.stats.skills[skillId](self).progress
            end
        else
            if S.playerSkillsStorage:get("uncapperEnabled") then
                skillGain = progress
                if skillGain > 0.001 then
                    if magicSkills[skillId] and S.playerMBSPStorage:get("mbspEnabled") then
                        skillGain = skillGain * deltaMagicka / S.playerMBSPStorage:get("magickaXPRate")
                    end
                    C.skillProgress()[skillId] = C.skillProgress()[skillId] + skillGain
                    if C.skillProgress()[skillId] >= 1 then
                        C.increaseSkill(skillId)
                        C.skillProgress()[skillId] = 0
                    end
                end
            else
                C.skillProgress()[skillId] = 0
            end
            Player.stats.skills[skillId](self).progress = 0
        end
        if skillGain > 0.001 then
            C.debugPrint("MBSP: Used skill %s, progress is %s, skill gain is %s, new progress is %s", skillId, progress, skillGain, C.skillProgress()[skillId])
            if deltaMagicka > 0 and magicSkills[skillId] and S.playerMBSPStorage:get("mbspEnabled") then
                local refund = 0
                if S.playerMBSPStorage:get("refundEnabled") then
                    refund = getRefund(Player.stats.skills[skillId](self).base, deltaMagicka)
                    C.modMagicka(refund)
                end
                C.debugPrint("MBSP: Used skill %s, cost is %s, refund is %s", skillId, deltaMagicka, refund)
            end
        end
    end

    storedMagicka = dynamic.magicka(self).current
end

return {
    onFrame = onFrame,
    getSkillUsedHandler = getSkillUsedHandler,
}
