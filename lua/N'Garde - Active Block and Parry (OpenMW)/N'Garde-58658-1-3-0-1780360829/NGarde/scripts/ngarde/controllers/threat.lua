---@omw-context local
local I = require('openmw.interfaces')
local util = require('openmw.util')
local animation = require('openmw.animation')
local logging = require('scripts.ngarde.helpers.logger').new()
local Constants            = require('scripts.ngarde.helpers.constants')


local clamp = util.clamp

local threatController = {}

threatController.useToAttackType = {
    [2] = 0, -- chop
    [3] = 1, -- slash
    [4] = 2, -- thrust
}

threatController.weaponTypeToAnimationMap = {
    ["shortbladeonehand"] = "weapononehand",
    ["longbladeonehand"] = "weapononehand",
    ["longbladetwohand"] = "weapontwohand",
    ["bluntonehand"] = "weapononehand",
    ["blunttwoclose"] = "weapontwohand",
    ["blunttwowide"] = "weapontwowide",
    ["speartwowide"] = "weapontwowide",
    ["axeonehand"] = "weapononehand",
    ["axetwohand"] = "weapontwohand",
    ["marksmanbow"] = "bowandarrow",
    ["marksmancrossbow"] = "crossbow",
    ["marksmanthrown"] = "throwweapon",
    ["handtohand"] = "handtohand"
}

threatController.getGroupAndKey = function(group, key)
    return ("%s: %s"):format(group, key)
end

threatController.meleeAttackBoundaryTextKeys = {
    ["handtohand"] = {
        [0] = { min = "chop min attack", max = "chop max attack" },
        [1] = { min = "slash min attack", max = "slash max attack" },
        [2] = { min = "thrust min attack", max = "thrust max attack" }
    },
    ["weapononehand"] = {
        [0] = { min = "chop min attack", max = "chop max attack" },
        [1] = { min = "slash min attack", max = "slash max attack" },
        [2] = { min = "thrust min attack", max = "thrust max attack" }
    },
    ["weapontwohand"] = {
        [0] = { min = "chop min attack", max = "chop max attack" },
        [1] = { min = "slash min attack", max = "slash max attack" },
        [2] = { min = "thrust min attack", max = "thrust max attack" }
    },
    ["weapontwowide"] = {
        [0] = { min = "chop min attack", max = "chop max attack" },
        [1] = { min = "slash min attack", max = "slash max attack" },
        [2] = { min = "thrust min attack", max = "thrust max attack" }
    },
}

threatController.rangedAttackBoundaryTextKeys = {
    ["crossbow"] = { [0] = { min = "shoot min attack", max = "shoot max attack" } },
    ["bowandarrow"] = { [0] = { min = "shoot min attack", max = "shoot max attack" } },
    ["throwweapon"] = { [0] = { min = "shoot min attack", max = "shoot max attack" } },
}

threatController.weaponDrawTimesTable = {}


threatController.registerRangedTextKeyHandler = function(parent)
    for groupname, attackTypes in pairs(threatController.meleeAttackBoundaryTextKeys) do
        I.AnimationController.addTextKeyHandler(groupname, function(_, key)
            for _, textKeys in pairs(attackTypes) do
                if key == textKeys.min then
                    parent.myMeleeThreat.minReached = true
                end
            end
        end)
    end
    for groupname, attackTypes in pairs(threatController.rangedAttackBoundaryTextKeys) do
        I.AnimationController.addTextKeyHandler(groupname, function(_, key)
            for _, textKeys in pairs(attackTypes) do
                if key == textKeys.min then
                    parent.myRangedThreat.minReached = true
                end
            end
            if key == "shoot release" then
                if not parent.myRangedThreat.sent then
                    threatController.sendRangedThreat(parent)
                end
            end
        end)
    end
end

threatController.getMaxAttackChargeDuration = function(actorSelf, parent)
    local combinedBoundaryTable = {
        threatController.meleeAttackBoundaryTextKeys,
        threatController.rangedAttackBoundaryTextKeys,
    }
    for _, boundaryTable in ipairs(combinedBoundaryTable) do
        for group, attackTypes in pairs(boundaryTable) do
            local drawTimesPerAttackType = {}
            for key, textKeys in pairs(attackTypes) do
                local maxKey = threatController.getGroupAndKey(group, textKeys.max)
                local minKey = threatController.getGroupAndKey(group, textKeys.min)
                local maxTime = animation.getTextKeyTime(actorSelf, maxKey)
                local minTime = animation.getTextKeyTime(actorSelf, minKey)
                local drawTime = 0
                if maxTime and minTime then
                    drawTime = maxTime - minTime
                    drawTimesPerAttackType[key] = drawTime
                end
            end
            threatController.weaponDrawTimesTable[group] = drawTimesPerAttackType
        end
    end
end

threatController.prepareOrSendRangedThreat = function(parent, dT)
    parent.myRangedThreat.sent = false
    parent.myRangedThreat.timeDrawn = parent.myRangedThreat.timeDrawn + dT
    local weaponTypeString = Constants.weaponToTypeMap[parent.recordEquippedR.type]
    local weaponAnimation = threatController.weaponTypeToAnimationMap[weaponTypeString]
    local drawTimes = threatController.weaponDrawTimesTable[weaponAnimation]
    local drawTime = drawTimes[0] -- ranged attack - always the same attack type
    if clamp(parent.myRangedThreat.timeDrawn / drawTime, 0, 1) >= 0.5 then
        threatController.sendRangedThreat(parent)
        parent.myRangedThreat.sent = true
    end
end

threatController.sendRangedThreat = function(parent)
    local drawTime = threatController.weaponDrawTimesTable
        [threatController.weaponTypeToAnimationMap[Constants.weaponToTypeMap[parent.recordEquippedR.type]]][0]
    parent.myRangedThreat.drawStrength = util.clamp(
        parent.myRangedThreat.timeDrawn / drawTime, 0, 1)
    logging:debug("Sending ranged threat event")
    parent.myRangedThreat.threatType = parent.recordEquippedR.type
    parent.myRangedThreat.threatReach = parent.recordEquippedR.reach
    for _, target in pairs(parent.targets) do
        target:sendEvent("ngarde_onRangedThreat", parent.myRangedThreat)
    end
    logging:debug(parent.myRangedThreat)
    parent.myRangedThreat.timeDrawn = 0
    parent.myRangedThreat.minReached = false
    -- parent.myRangedThreat.maxReached = false
end


threatController.sendMeleeThreat = function(actorSelf, parent)
    for _, target in pairs(parent.targets) do
        target:sendEvent(
            "ngarde_onThreat",
            {
                actor = actorSelf,
                threatType = parent.recordEquippedR.type,
                threatReach = parent.recordEquippedR.reach

            })
    end
end

threatController.readMeleeWindup = function(parent, dT, use)
    local attackType = threatController.useToAttackType[use]
    parent.myMeleeThreat.timeDrawn = parent.myMeleeThreat.timeDrawn + dT
    local weaponTypeString = Constants.weaponToTypeMap[parent.recordEquippedR.type]
    local weaponAnimation = threatController.weaponTypeToAnimationMap[weaponTypeString]
    local drawTimes = threatController.weaponDrawTimesTable[weaponAnimation]
    local drawTime = drawTimes[attackType]
    parent.myMeleeThreat.currentCharge = clamp(parent.myMeleeThreat.timeDrawn / drawTime, 0, 1)
end

--#endregion

return threatController
