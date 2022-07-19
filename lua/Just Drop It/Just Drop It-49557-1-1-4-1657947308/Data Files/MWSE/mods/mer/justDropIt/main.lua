local config = require('mer.justDropIt.config')
local orient = require("mer.justDropIt.orient")
local logger = require("logging.logger").new{
    name = "Just Drop It",
    logLevel = config.mcmConfig.logLevel
}
local modName = config.modName

local deathAnimations = {
    [tes3.animationGroup.deathKnockDown] = true,
    [tes3.animationGroup.deathKnockOut] = true,
    [tes3.animationGroup.death1] = true,
    [tes3.animationGroup.death2] = true,
    [tes3.animationGroup.death3] = true,
    [tes3.animationGroup.death4] = true,
    [tes3.animationGroup.death5] = true,
}
local validObjectTypes = {
    [tes3.objectType.creature]=true,
    [tes3.objectType.npc]=true
}

--Initialisation
local function onItemDrop(e)
    if config.mcmConfig.enabled then
        logger:debug("Orienting %s on itemDropped", e.reference)
        orient.orientRefToGround{ ref = e.reference }
    end
end
event.register("itemDropped", onItemDrop)

---@param e playGroupEventData
local function onNPCDying(e)
    if config.mcmConfig.enabled and config.mcmConfig.orientOnDeath then
        if deathAnimations[e.group] then
            if not e.reference.data.justDropItOrientedOnDeath then
                logger:debug("Orienting %s on death", e.reference)
                local result = orient.getGroundBelowRef({ref = e.reference})
                if result then
                    orient.orientRef(e.reference, result)
                    e.reference.data.justDropItOrientedOnDeath = true
                end
            end
        end
    end
end
event.register("playGroup", onNPCDying)

--Reset orientation when ref is resurrected manually
---@param e mobileActivatedEventData
local function onRefResurrected(e)
    if validObjectTypes[e.reference.baseObject.objectType] then
        logger:debug("Restoring vertical orientation of %s on referenceActivated", e.reference)
        orient.resetXYOrientation(e.reference)
        e.reference.data.justDropItOrientedOnDeath = nil
    end
end
event.register("mobileActivated", onRefResurrected)

---@param object tes3object|tes3light
local function isCarryable(object)
    local unCarryableTypes = {
        [tes3.objectType.light] = true,
        [tes3.objectType.container] = true,
        [tes3.objectType.static] = true,
        [tes3.objectType.door] = true,
        [tes3.objectType.activator] = true,
        [tes3.objectType.npc] = true,
        [tes3.objectType.creature] = true,
    }
    if object then
        if object.canCarry then
            return true
        end
        local objType = object.objectType
        if unCarryableTypes[objType] then
            return false
        end
        return true
    end
end

--Determine ref width using bounding box
---@param reference tes3reference
---@return number
local function getMaxWidth(reference)
    local bbox = reference.object.boundingBox
    local width = math.max(
        bbox.max.x - bbox.min.x,
        bbox.max.y - bbox.min.y,
        bbox.max.z - bbox.min.z
    )
    return width
end

---@param reference tes3reference
local function dropNearbyObjects(reference, processedRefs)
    processedRefs = processedRefs or {}
    processedRefs[reference] = true
    logger:debug("Dropping nearby objects for %s", reference)
    local nearbyRefs = {}
    for _, cell in pairs( tes3.getActiveCells() ) do
        for nearbyRef in cell:iterateReferences() do
            if not processedRefs[nearbyRef] then
                if isCarryable(nearbyRef.baseObject) then
                    local closeEnough = orient.getCloseEnough{
                        ref1 = reference,
                        ref2 = nearbyRef,
                        distHorizontal = getMaxWidth(reference)
                    }
                    if closeEnough then
                        table.insert(nearbyRefs, nearbyRef)
                    end
                end
            end
        end
    end

    --Sort from lowest to heighest
    table.sort(nearbyRefs, function(a, b)
        return a.position.z < b.position.z
    end)
    for _, nearbyRef in pairs(nearbyRefs) do
        logger:debug("Dropping %s near %s", nearbyRef, reference)
        local result = orient.getGroundBelowRef({ref = nearbyRef})
        if result and result.reference == reference then
            local safeParent = tes3.makeSafeObjectHandle(reference)
            local parentZ = reference.position.z
            local safeRef = tes3.makeSafeObjectHandle(nearbyRef)
            timer.delayOneFrame(function()timer.delayOneFrame(function()
                if safeParent:valid() and math.isclose(parentZ, reference.position.z) then
                    logger:debug("Parent %s still exists and wasn't moved, don't bother dropping children", reference)
                    return
                end
                if safeRef:valid() then
                    dropNearbyObjects(nearbyRef, processedRefs)
                    orient.orientRefToGround{ref = nearbyRef, ignoreBlackList = true}
                end
            end)end)
        end
    end
end

---@param e activateEventData
local function onActivate(e)
    if isCarryable(e.target.object) then
        dropNearbyObjects(e.target)
    end
end
event.register("activate", onActivate, {priority = 1000})

--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(modName, config.mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = string.format("Enable %s", modName),
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config.mcmConfig}
    }

    settings:createDropdown{
        label = "Log Level",
        description = "Set the logging level for mwse.log. Keep on INFO unless you are debugging.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcmConfig },
        callback = function(self)
            logger:setLogLevel(self.variable.value)
        end
    }

    settings:createOnOffButton{
        label = "Orient Corpses on Death",
        description = "Orients the corpses of creatures and NPCs when they die. Death animations are extremely buggy in Morrowind, and this setting doesn't fix all the bugginess. So don't come complaining to me when a cliff racer falls through a rock or a guar hovers 3 feet over one. These are vanilla bugs and there's only so much I can do!",
        variable = mwse.mcm.createTableVariable{id = "orientOnDeath", table = config.mcmConfig}
    }

    settings:createOnOffButton{
        label = string.format("Ignore Non-Static Ground Orientation"),
        description = "If this is enabled, items will remain upright when placed on a non-static mesh. Default: Off",
        variable = mwse.mcm.createTableVariable{id = "noOrientNonStatic", table = config.mcmConfig}
    }

    settings:createSlider{
        label = "Max Orientation Steepness for Flat Objects",
        description = "Determines how many degrees an object will be rotated to orient with the ground it's being placed on. This is for objects whose height is smaller than its width and depth. Recommended: 40",
        variable = mwse.mcm.createTableVariable{ id = "maxSteepnessFlat", table = config.mcmConfig},
        max = 180
    }

    settings:createSlider{
        label = "Max Orientation Steepness for Tall Objects",
        description = "Determines how many degrees an object will be rotated to orient with the ground it's being placed on. This is for objects whose height is larger than its width or depth. Recommended: 5",
        variable = mwse.mcm.createTableVariable{ id = "maxSteepnessTall", table = config.mcmConfig},
        max = 180
    }


    template:createExclusionsPage{
        label = "Mod Blacklist",
        description = "Add plugins to the blacklist, so any items added by the mod are not affected. ",
        variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config.mcmConfig},
        filters = {
            {
                label = "Plugins",
                type = "Plugin"
            }
        }
    }
end
event.register("modConfigReady", registerModConfig)

