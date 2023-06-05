-- Importing necessary modules
--- The 'config' module holds the configuration data for the Set Bonus mod
local log = require("Static.logger")
local config = require("Static.SetBonus.config")
-- 'countItemsEquipped' function checks if a character reference has each item from a given list equipped
---@param ref tes3reference
---@param items tes3item[]
---@return number
local function countItemsEquipped(ref, items)
    log:trace("countItemsEquipped: Starting function with ref: %s, items: %s", ref, items)
    if not items or type(items) ~= "table" then
        log:error("countItemsEquipped: Invalid items input. Must be a table.")
        return 0
    end
    local count = 0
    -- Loop over the items
    for _, item in ipairs(items) do
        -- Check if the item is equipped by the given reference (typically a character)
        ---@diagnostic disable-next-line
        if ref.object:hasItemEquipped(item) then
            count = count + 1
        end
    end
    -- Log the counted items
    log:debug("countItemsEquipped: Counted %s equipped items for ref: %s", count, ref)
    return count -- Returns the count of equipped items
end
-- 'addSetBonus' function applies a set bonus based on the number of items a character has equipped from the same set
---@param set table
---@param ref tes3reference
---@param numEquipped number
local function addSetBonus(set, ref, numEquipped)
    log:trace("addSetBonus: Starting function with set: %s, ref: %s, numEquipped: %s", set, ref, numEquipped)
        -- Add bonuses based on the number of equipped items
    if numEquipped >= 6 then
        log:debug("addSetBonus: Adding max bonus spell for ref: %s, Spell: %s", ref, set.maxBonus)
        tes3.removeSpell{ reference = ref, spell = set.midBonus }
        tes3.removeSpell{ reference = ref, spell = set.minBonus }
        tes3.addSpell{ reference = ref, spell = set.maxBonus }
    elseif numEquipped >= 4 then
        log:debug("addSetBonus: Adding mid bonus spell for ref: %s, Spell: %s", ref, set.midBonus)
        tes3.removeSpell{ reference = ref, spell = set.maxBonus }
        tes3.removeSpell{ reference = ref, spell = set.minBonus }
        tes3.addSpell{ reference = ref, spell = set.midBonus }
    elseif numEquipped >= 2 then
        log:debug("addSetBonus: Adding min bonus spell for ref: %s, Spell: %s", ref, set.minBonus)
        tes3.removeSpell{ reference = ref, spell = set.midBonus }
        tes3.removeSpell{ reference = ref, spell = set.maxBonus }
        tes3.addSpell{ reference = ref, spell = set.minBonus }
    else
        log:debug("addSetBonus: No bonuses applicable for ref: %s", ref)
        tes3.removeSpell{ reference = ref, spell = set.minBonus }
        tes3.removeSpell{ reference = ref, spell = set.midBonus }
        tes3.removeSpell{ reference = ref, spell = set.maxBonus }
    end
    log:trace("addSetBonus: Exit point")
end
-- 'equipsChanged' function handles the event when a character's equipment changes
---@param e equippedEventData
local function equipsChanged(e)
    log:trace("equipsChanged: Starting function with event data: %s", e)
    -- Get the item id from the event
    local id = e and e.item and e.item.id
    if not id then
        return
    end
    -- Find the set that the item belongs to
    local linkSet = config.setLinks[id:lower()]
    if not linkSet then
        log:debug("equipsChanged: No set associated with item ID: %s", id)
        return
    end
    -- Iterate over each set in the linkSet dictionary
    for setName, _ in pairs(linkSet) do
        local set = config.sets[setName]
        if set then
            local numEquipped = countItemsEquipped(e.reference, set.items)
            -- Log the number of equipped items
            log:debug("equipsChanged: Reference: %s has %s items from set: %s equipped", e.reference, numEquipped, setName)
            -- Provide a notification if the character is the player
            if e.reference == tes3.player then
                tes3.messageBox("You have %s items of the %s set equipped", numEquipped, setName)
            end
            --- Apply set bonus using timer
            addSetBonus(set, e.reference, numEquipped)
        end
    end
    log:trace("equipsChanged: Exit point")
end
-- Registering events to call 'equipsChanged' function when equipment changes
event.register(tes3.event.equipped, equipsChanged)
event.register(tes3.event.unequipped, equipsChanged)
-- 'npcLoaded' function handles the event when an NPC is loaded into the game
---@param e mobileActivatedEventData
local function npcLoaded(e)
    log:trace("npcLoaded: Starting function with event data: %s", e)
    if not e.reference or not e.reference.object.equipment then 
        log:error("npcLoaded: Event data is missing NPC reference or equipment.")
        return
    end
    log:debug("npcLoaded: NPC reference and equipment are valid.")
    -- Create a table to store the count of items from each set the NPC has equipped
    local setCounts = {}
    local allowedTypes = {
      [tes3.objectType.armor] = true,
      [tes3.objectType.clothing] = true,
      [tes3.objectType.weapon] = true
    }
    log:debug("npcLoaded: Defined allowed equipment types: %s", allowedTypes)
    for _, stack in pairs(e.reference.object.equipment) do
        log:trace("npcLoaded: Evaluating equipment item with stack: %s", stack)
        if allowedTypes[stack.object.objectType] then
            log:debug("npcLoaded: Equipment item type is allowed: %s", stack.object.objectType)
            local keySets = config.setLinks[stack.object.id:lower()] -- Ensure the ID is in lowercase
            log:trace("npcLoaded: Checking if item belongs to a set, item id: %s", stack.object.id)
            if keySets ~= nil then
                log:debug("npcLoaded: Item belongs to a set(s): %s", keySets)
                for set, _ in pairs(keySets) do
                    setCounts[set] = (setCounts[set] or 0) + 1
                    log:debug("npcLoaded: Increased count for set: %s, new count: %s", set, setCounts[set])
                end
            else
                log:debug("npcLoaded: Item does not belong to any set.")
            end
        end
    end
    -- For each set, apply the set bonus
    for setName, count in pairs(setCounts) do
        log:trace("npcLoaded: Evaluating set: %s with count: %s", setName, count)
        local set = config.sets[setName:lower()]
        if set then
            log:debug("npcLoaded: Found set in configuration: %s", setName)
            addSetBonus(set, e.reference, count)
        else
            log:debug("npcLoaded: Set not found in configuration: %s", setName)
        end
    end
    log:trace("npcLoaded: Function execution finished.")
end
-- Registering events to call 'npcLoaded' function when an NPC is loaded
event.register(tes3.event.mobileActivated, npcLoaded)
event.register(tes3.event.loaded, npcLoaded)