local common = require("mer.drip.common")
local logger = common.createLogger("Interop")
local Modifier = require("mer.drip.components.Modifier")
local Loot = require("mer.drip.components.Loot")
local config = common.config

local drip = {
    Loot = Loot,
    Modifier = Modifier,
    config = config,
}

function drip.registerMaterialPattern(str, isSuffix)
    local list = isSuffix and config.materialSuffixes or config.materialPrefixes
    --Puts patterns with multiple words at the front so they get caught first
    if string.find(str, " ") then
        table.insert(list, 1, str:lower())
    else
        table.insert(list, str:lower())
    end
end

drip.registerModifier = Modifier.register

function drip.registerWeapon(weaponId)
    logger:trace("registering weapon id %s", weaponId)
    config.weapons[weaponId:lower()] = true
end

function drip.registerArmor(armorId)
    logger:trace("registering armor id %s", armorId)
    config.armor[armorId:lower()] = true
end

function drip.registerClothing(clothingId)
    logger:trace("registering clothing id %s", clothingId)
    config.clothing[clothingId:lower()] = true
end


--[[
    Dripify an object using the standard DRIP
    chances. If the object is dripified, returns
    the loot. Otherwise, returns nil.
]]
---@param object tes3object|tes3misc
---@return Drip.Loot|nil
function drip.rollDrip(object)
    logger:info("Dripifying %s", object.name)
    if common.canBeDripified(object) then
        local modifiers = Modifier.rollForModifiers(object)
        if modifiers and #modifiers > 0 then
            logger:debug("Converting %s to loot", object.name)
            local loot = Loot:new{
                baseObject = object,
                modifiers = modifiers,
            }:initialize()
            if loot then
                logger:info("Converted to %s", loot.object.name)
                return loot
            end
        else
            logger:error("Unable to roll modifiers for %s", object.name)
        end
    end
    logger:error("%s can not be dripified", object.name)
    return nil
end

---Dripify with a guaranteed modifier
---@param object tes3object|tes3misc
---@param listId string
function drip.dripify(object, listId)
    local modifiers = {}
    local firstModifier = Modifier.getRandomModifier(object, common.config.modifiers[listId])
    if firstModifier then
        table.insert(modifiers, firstModifier)
    end

    if #modifiers > 0 then
        local loot = Loot:new{
            baseObject = object,
            modifiers = modifiers,
        }:initialize()
        if loot then
            logger:info("Converted to %s", loot.object.name)
            return loot
        end
    end
end

---Replace a reference with a dripified version
---@param reference tes3reference
---@param listId string
function drip.dripifyReference(reference, listId)
    local loot = drip.dripify(reference.object, listId)
    if not loot then
        logger:error("Failed to dripify %s", reference.object.id)
        return
    end

    local newRef = tes3.createReference{
        object = loot.object,
        position = reference.position,
        orientation = reference.orientation,
        cell = reference.cell,
        scale = reference.scale,
    }
    logger:info("Replaced %s with %s", reference.object.id, loot.object.id)
    reference:delete()
    loot:persist()
    return newRef
end

return drip