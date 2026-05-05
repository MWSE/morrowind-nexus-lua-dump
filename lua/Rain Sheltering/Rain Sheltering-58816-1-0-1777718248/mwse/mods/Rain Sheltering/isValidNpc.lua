local config = require("Rain Sheltering.config")

local function isClassExcluded(npc)
    return config.excludedClasses[npc.object.class.id]
end

local function isIdNpcExcluded(npc)
    return config.excludedObjectIdNpc[npc.baseObject.id]
end

local function hasQuestBlock(npc)
    local requirements = config.questRequirements[npc.baseObject.id]
    -- Если у NPC нет квестов, из-за которого он не должен передвигаться
    if not requirements then return false end

    for _, requirement in ipairs(requirements) do
        local currentQuestStage = tes3.getJournalIndex({id = requirement.journal})
        if currentQuestStage < requirement.stageComplete then
            return true
        end
    end

    return false
end

-- Состояние NPC, при котором его нужно выписать из укрытия
---@param reference tes3reference
---@return boolean
return function(reference)
    if not reference or reference.deleted then
        return false
    end
    if not reference.mobile then
        return false
    end
    if reference.mobile.objectType ~= tes3.objectType.mobileNPC then
        return false
    end
    if reference.disabled then
        return false
    end
    if reference.mobile.isDead then
        return false
    end

    -- if escort/follow/activate
    local package = tes3.getCurrentAIPackageId({ reference = reference })
    if package ~= tes3.aiPackage.wander
        and package ~= tes3.aiPackage.travel
        and package ~= tes3.aiPackage.none then -- если NPC находится за activeCells - ему ставится none ?
        return false
    end

    if isClassExcluded(reference) then
        return false
    end

    if isIdNpcExcluded(reference) then
        return false
    end

    if hasQuestBlock(reference) then
        return false
    end

    return true
end