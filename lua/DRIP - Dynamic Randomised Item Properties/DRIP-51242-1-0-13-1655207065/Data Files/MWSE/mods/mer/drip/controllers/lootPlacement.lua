local common = require("mer.drip.common")
local logger = common.createLogger("LootPlacement")
local Loot = require("mer.drip.components.Loot")
local Modifier = require("mer.drip.components.Modifier")
local modifierConfig = common.config.modifiers

local function getFirstModifier(object)
    if math.random(100) <= common.config.mcm.modifierChance then
        local list = math.random() < 0.5 and modifierConfig.prefixes or modifierConfig.suffixes
        return Modifier:getRandomModifier(object, list)
    end
end

local function rollForModifiers(object)
    --Roll for fist modifier, and if it succeeds, roll for second modifier
    --First modifier has 50/50 chance of being prefix or suffix
    local modifiers = {}

    logger:trace("Object: %s", object.name)

    local firstModifier = getFirstModifier(object)
    if not firstModifier then
        return
    end
    table.insert(modifiers, firstModifier)
    local secondModifier
    --If first modifier was wild, guarantee a second.
    --If wild is the second modifier, we already have another to apply the wild to
    if firstModifier.wild or math.random(100) < common.config.mcm.secondaryModifierChance then
        if firstModifier.prefix then
            secondModifier = Modifier:getRandomModifier(object, modifierConfig.suffixes)
        else
            secondModifier = Modifier:getRandomModifier(object, modifierConfig.prefixes)
        end
    end
    if secondModifier then
        table.insert(modifiers, secondModifier)
    end

    if #modifiers > 0 then
        return modifiers
    end
end


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
            local modifiers = rollForModifiers(stack.object)
            if modifiers and #modifiers > 0 then
                logger:debug("Converting %s to loot", stack.object.name)
                local loot = Loot:new{
                    baseObject = stack.object,
                    modifiers = modifiers,
                }
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
    local objectIds = common.getAllLootObjectIds()
    if objectIds[e.pick.id:lower()] then
        if checkSpawnerDripified(e.spawner) == true then return end
        local object = e.pick
        local modifiers = rollForModifiers(object)
        if modifiers then
            logger:debug("Converting leveled item %s to loot", object.name)
            local loot = Loot:new{
                baseObject = object,
                modifiers = modifiers,
            }
            if loot then
                logger:debug("Converted to %s", loot.object.name)
                logger:debug("Replacing existing object with enchanted version")
                e.pick = loot.object
                loot:persist()
            end
        end
    end
end
event.register("leveledItemPicked", onLeveledItemPicked)