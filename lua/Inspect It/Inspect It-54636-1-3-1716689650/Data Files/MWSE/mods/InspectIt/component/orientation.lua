---@class OrientationResolver
local this = {}
local logger = require("InspectIt.logger")

local fixedOrientations = {
    -- [tes3.objectType.activator] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.alchemy] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.ammunition] = tes3vector3.new(-90, 0, -90),
    [tes3.objectType.apparatus] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.armor] = tes3vector3.new(0, 0, 0), -- It's not aligned. It's a mess.
    [tes3.objectType.bodyPart] = tes3vector3.new(0, 0, -180),
    -- [tes3.objectType.book] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.cell] = tes3vector3.new(0, 0, 0),
    --[tes3.objectType.clothing] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.container] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.creature] = tes3vector3.new(0, 0, -180),
    -- [tes3.objectType.door] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.enchantment] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.ingredient] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.land] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.landTexture] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.leveledCreature] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.leveledItem] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.light] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.lockpick] = tes3vector3.new(-90, 0, -90),
    -- [tes3.objectType.magicEffect] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.miscItem] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileActor] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileCreature] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileNPC] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobilePlayer] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileProjectile] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileSpellProjectile] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.npc] = tes3vector3.new(0, 0, -180),
    [tes3.objectType.probe] = tes3vector3.new(-90, 0, -90),
    -- [tes3.objectType.reference] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.region] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.repairItem] = tes3vector3.new(-90, 0, -90),
    -- [tes3.objectType.spell] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.static] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.weapon] = tes3vector3.new(-90, 0, -90),
}

local armorSlot = {
    [tes3.armorSlot.boots] = tes3vector3.new(0, 0, 0),
    [tes3.armorSlot.cuirass] = tes3vector3.new(-90, 0, 0),
    [tes3.armorSlot.greaves] = tes3vector3.new(-90, 0, 0),
    [tes3.armorSlot.helmet] = tes3vector3.new(0, 0, 0),
    [tes3.armorSlot.leftBracer] = tes3vector3.new(0, 0, 180),
    [tes3.armorSlot.leftGauntlet] = tes3vector3.new(0, 0, 180),
    [tes3.armorSlot.leftPauldron] = tes3vector3.new(0, 0, 180),
    [tes3.armorSlot.rightBracer] = tes3vector3.new(0, 0, 0),
    [tes3.armorSlot.rightGauntlet] = tes3vector3.new(0, 0, 0),
    [tes3.armorSlot.rightPauldron] = tes3vector3.new(0, 0, 0),
    [tes3.armorSlot.shield] = tes3vector3.new(-90, 0, 0),
}

local clothSlot = {
    [tes3.clothingSlot.amulet] = tes3vector3.new(-90, 0, 0),
    [tes3.clothingSlot.belt] = tes3vector3.new(-90, 0, 0),
    [tes3.clothingSlot.leftGlove] = tes3vector3.new(-90, 0, 180),
    [tes3.clothingSlot.pants] = tes3vector3.new(-90, 0, 0),
    [tes3.clothingSlot.rightGlove] = tes3vector3.new(-90, 0, 0),
    [tes3.clothingSlot.ring] = tes3vector3.new(0, 0, 0),
    [tes3.clothingSlot.robe] = tes3vector3.new(-90, 0, 0),
    [tes3.clothingSlot.shirt] = tes3vector3.new(-90, 0, 0),
    [tes3.clothingSlot.shoes] = tes3vector3.new(0, 0, 0),
    [tes3.clothingSlot.skirt] = tes3vector3.new(-90, 0, 0),
}

local weaponType = {
    [tes3.weaponType.marksmanCrossbow] = tes3vector3.new(0, 0, -90),
}

---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@param bounds tes3boundingBox
---@return tes3vector3? degree
function this.GetOrientation(object, bounds)
    -- from table
    local orientation = fixedOrientations[object.objectType]
    if orientation then
        return orientation
    end

    -- unique type
    if object.objectType == tes3.objectType.armor then
        ---@cast object tes3armor
        local o = armorSlot[object.slot]
        if o then
            return o
        end
    elseif object.objectType == tes3.objectType.clothing then
        ---@cast object tes3clothing
        local o = clothSlot[object.slot]
        if o then
            return o
        end
    elseif object.objectType == tes3.objectType.weapon then
        ---@cast object tes3weapon
        local o = weaponType[object.type]
        if o then
            return o
        end
    elseif object.objectType == tes3.objectType.book then
        local size = bounds.max - bounds.min
        local ratio = size.y / math.max(size.x, math.fepsilon)
        logger:debug("book ratio %f / %f = %f", size.y, size.x, ratio)
        ---@cast object tes3book
        if object.type == tes3.bookType.book then
            -- FIXME The Third Door (BookSkill_Axe1) bounds.x wrong
            -- opened or closed
            if ratio > 1.75 then -- opened and rotation
                return tes3vector3.new(-90, 0, 90)
            end
            return tes3vector3.new(-90, 0, 0) -- closed
        else
            if ratio < 0.35 then -- rolled scroll?
                return tes3vector3.new(0, 0, 0)
            end
            if size.z < 3 then
                return tes3vector3.new(-90, 0, 0)
            end
            return tes3vector3.new(-90, 0, 0)
        end
    elseif object.objectType == tes3.objectType.door then
        -- expect axis aligned, almost centered
        local size = bounds.max - bounds.min
        if size.x > size.y then
            -- whitch bold thickness? face has handles?
            logger:debug("y-face %f, %f", bounds.max.y, bounds.min.y)
            if math.abs(bounds.max.y) - math.abs(bounds.min.y) >= 0 then
                return tes3vector3.new(0, 0, 0)
            else
                return tes3vector3.new(0, 0, 0) -- same face is front?
            end
        else
            logger:debug("x-face %f, %f", bounds.max.x, bounds.min.x)
            if math.abs(bounds.max.x) - math.abs(bounds.min.x) >= 0 then
                return tes3vector3.new(0, 0, -90)
            else
                return tes3vector3.new(0, 0, 90)
            end
        end
        -- TODO trap door
    end

    -- auto rotation
    -- dominant axis based
    -- TODO more better algorithm
    local size = bounds.max - bounds.min
    logger:debug("bounds size: %s", size)
    local my = 0
    if size.x < size.y and size.z < size.y then
        my = 1
    end
    local mz = 0
    if size.x < size.z and size.y < size.z then
        mz = 2
    end
    local imax = my + mz;
    my = 0
    if size.x > size.y and size.z > size.y then
        my = 1
    end
    mz = 0
    if size.x > size.z and size.y > size.z then
        mz = 2
    end
    local imin = my + mz;
    logger:debug("axis: max %d, min %d", imax, imin)
    if imax == 1 or imin == 2 then     -- depth is maximum or height is minimum, y-up
        -- if imax == 1 then -- just depth is maximum
        -- it seems that area ratio would be a better result.
        return tes3vector3.new(-60, 0, 0)
    end

    return nil -- tes3vector3.new(0, 0, 0) -- default
end

return this
