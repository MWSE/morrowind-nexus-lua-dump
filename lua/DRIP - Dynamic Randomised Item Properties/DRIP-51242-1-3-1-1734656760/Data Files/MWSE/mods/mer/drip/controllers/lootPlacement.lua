local common = require("mer.drip.common")
local logger = common.createLogger("LootPlacement")
local Loot = require("mer.drip.components.Loot")
local Modifier = require("mer.drip.components.Modifier")


local function addToRef(reference)
    if reference.data.dripified then return end
    reference.data.dripified = true
    --If a reference has an inventory (such as an NPC or container)
    -- search for objects that can be Lootified
    local container = reference.object
    local inventory = container.inventory
    logger:debug("\n\nDripifying %s", container.name)
    ---@param stack tes3itemStack
    for _, stack in pairs(inventory) do
        --Check if it's a lootifiable object
        if common.canBeDripified(stack.object)  then
            local modifiers = Modifier.rollForModifiers(stack.object)
            if modifiers and #modifiers > 0 then
                logger:debug("Converting %s to loot", stack.object.name)
                local loot = Loot:new{
                    baseObject = stack.object,
                    modifiers = modifiers,
                }:initialize()
                if loot then
                    logger:debug("Converted to %s", loot.object.name)
                    logger:debug("Replacing existing object with enchanted version")
                    loot:replaceLootInInventory(reference, stack)
                else
                    logger:trace("Failed to convert %s to loot", stack.object.name)
                end
            end
        end
    end
end


---@param e mobileActivatedEventData
event.register("mobileActivated", function(e)
    if not common.config.mcm.enabled then return end
    if e.reference.baseObject.objectType == tes3.objectType.npc then
        addToRef(e.reference)
    end
end)

--Checks whether the spawner has been dripified, and if it's the first item, delay a frame to set the flag
---@param spawner tes3reference
local function checkSpawnerDripified(spawner)
    if not spawner then return end
    if not spawner.supportsLuaData then return end
    if not spawner.data.dripifiedSpawnerState then
        logger:debug("checkSpawnerDripified: Spawner %s has not beed dripified, setting state to 1 and delaying a frame to set to 2", spawner)
        spawner.data.dripifiedSpawnerState = 1
        local safeRef = tes3.makeSafeObjectHandle(spawner)
        if not safeRef then
            logger:error("checkSpawnerDripified: Failed to make safe handle for spawner %s", spawner)
            return
        end
        timer.delayOneFrame(function()
            if safeRef:valid() then
                logger:debug("checkSpawnerDripified: Setting spawner %s state to 2", spawner)
                safeRef:getObject().data.dripifiedSpawnerState = 2
            end
        end)
        return false
    elseif spawner.data.dripifiedSpawnerState == 1 then
        logger:debug("checkSpawnerDripified: Spawner %s has been partially dripified", spawner)
        return false
    elseif spawner.data.dripifiedSpawnerState == 2 then
        logger:debug("checkSpawnerDripified: Spawner %s has already been dripified", spawner)
        return true
    end
end

--[[
    Add loot to leveled items
]]
---@param e leveledItemPickedEventData
local function onLeveledItemPicked(e)
    if not common.config.mcm.enabled then return end
    if not e.pick then return end
    if common.canBeDripified(e.pick)  then
        if checkSpawnerDripified(e.spawner) == true then return end
        local object = e.pick
        local modifiers = Modifier.rollForModifiers(object)
        if modifiers then
            logger:debug("Converting leveled item %s to loot", object.name)
            local loot = Loot:new{
                baseObject = object, ---@diagnostic disable-line: assign-type-mismatch
                modifiers = modifiers,
            }:initialize()
            if loot then
                logger:debug("Converted to %s", loot.object.name)
                logger:debug("Replacing existing object with enchanted version")
                e.pick = loot.object ---@diagnostic disable-line: assign-type-mismatch
                loot:persist()
            end
        end
    end
end
event.register("leveledItemPicked", onLeveledItemPicked)

local initialized
event.register("initialized", function() initialized = true end)

event.register("objectCreated", function(e)
    if not initialized then return end
    if not e.copiedFrom then return end
    local modifiers = Modifier.getObjectModifiers(e.copiedFrom)
    if #modifiers > 0 then
        logger:info("Registering copied loot. Original: %s, New: %s",
        e.copiedFrom.id, e.object.id)
        local modifierIds = {}
        --store modified by string
        for _, modifier in ipairs(modifiers) do
            table.insert(modifierIds, modifier.id)
        end
        common.config.persistent.generatedLoot[e.object.id:lower()] = {
            modifiers = modifierIds,
        }
    end
end)