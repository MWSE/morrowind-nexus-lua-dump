local common = require("OperatorJack.MagickaExpanded.common")

--- Functions functions module.
---@class MagickaExpanded.Functions
local this = {}

---Cell-agnostic method to get all actors from a target position and within a certain distance.
---@param cell tes3cell
---@param targetPosition tes3vector3
---@param distanceLimit number
---@return tes3reference[]
this.getActorsNearTargetPosition = function(cell, targetPosition, distanceLimit)
    ---@type tes3reference[]
    local actors = {}

    -- Iterate through the references in the cell.
    for ref in cell:iterateReferences() do
        -- Check that the reference is a creature or NPC.
        if (ref.object.objectType == tes3.objectType.npc or ref.object.objectType ==
            tes3.objectType.creature) then
            if (distanceLimit ~= nil) then
                -- Check that the distance between the reference and the target point is within the distance limit. If so, save the reference.
                local distance = targetPosition:distance(ref.position)
                if (distance <= distanceLimit) then table.insert(actors, ref) end
            else
                table.insert(actors, ref)
            end
        end
    end
    return actors
end

--[[
	For a given magic effect event, returns the first 
		effect that has the same ID as effectId.
]]
---@param event tes3magicEffectTickEventData | tes3magicEffectCollisionEventData A magic effect event created through tes3.addMagickEffect, such as onTick or onCollision.
---@param effectId tes3.effect A magic effect ID found in tes3.effect.
---@return tes3effect | nil
this.getEffectFromEffectOnEffectEvent = function(event, effectId)
    for i = 1, 8 do
        local effect = event.sourceInstance.source.effects[i]
        if (effect ~= nil) then if (effect.id == effectId) then return effect end end
    end
    return nil
end

--[[
	Calculates and returns a random magnitude based on a given effect min/max.
]]
---@param effect tes3effect The magic effect to calculate a random magnitude for.
---@return number
this.getCalculatedMagnitudeFromEffect = function(effect)
    local minMagnitude = math.floor(effect.min)
    local maxMagnitude = math.floor(effect.max)
    local magnitude = math.random(minMagnitude, maxMagnitude)
    return magnitude
end

--[[
	Performs linear interpolation between 2 sets of points, A and B, and returns
		a point that is `percent` percentage between them.
]]
---@param x1 number The X value of point A.
---@param y1 number The Y value of point A.
---@param x2 number The X value of point B.
---@param y2 number The Y value of point B.
---@param percent number The decimal percentage used to calculate a point between point A and point B.
---@return number, number
this.linearInterpolation = function(x1, y1, x2, y2, percent)
    return (x1 + ((x2 - x1) * percent)), (y1 + ((y2 - y1) * percent))
end

--[[
	Performs a ternary operation.
]]
---@param condition any The condition to evaluate in the ternary. This may be a static value or function call.
---@param T any The value to return if `condition` is true.
---@param F any The value to return if `condition` is false.
---@return any
this.ternary = function(condition, T, F)
    if condition then
        return T
    else
        return F
    end
end

this.getBoundWeaponEffectList = function() return table.copy(common.boundWeapons) end

this.getBoundArmorEffectList = function() return table.copy(common.boundArmors) end

this.getBoundItemEffectList = function()
    local list = {}
    for effect, value in pairs(this.getBoundWeaponEffectList()) do list[effect] = value end
    for effect, value in pairs(this.getBoundArmorEffectList()) do list[effect] = value end
    return list
end

this.getBoundWeaponIdList = function()
    local list = {}
    for _, value in pairs(this.getBoundWeaponEffectList()) do
        for _, item in pairs(value) do table.insert(list, item) end
    end
    return list
end

this.getBoundArmorIdList = function()
    local list = {}
    for _, value in pairs(this.getBoundArmorEffectList()) do
        for _, item in pairs(value) do table.insert(list, item) end
    end
    return list
end

this.getBoundItemIdList = function()
    local list = {}
    for _, value in ipairs(this.getBoundWeaponIdList()) do table.insert(list, value) end
    for _, value in ipairs(this.getBoundArmorIdList()) do table.insert(list, value) end
    return list
end

this.addSpellsToPlayer = function() common.addTestSpellsToPlayer() end

return this
