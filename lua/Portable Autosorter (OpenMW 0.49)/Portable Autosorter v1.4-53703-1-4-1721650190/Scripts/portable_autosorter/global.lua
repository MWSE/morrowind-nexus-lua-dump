-- Declarations --
local core = require("openmw.core")
local types = require('openmw.types')

-- Startup Check --
if (core.API_REVISION < 37) then
    error("Newer version of OpenMW is required")
end
if (core.contentFiles ~= nil and not core.contentFiles.has("portable_autosorter.omwaddon")) then
    error("Portable Autosorter omwaddon is not enabled.")
end

-- Internal Functions --
local function checkDoNotUse(container)
    for _, item in ipairs(types.Container.inventory(container):getAll(types.Miscellaneous)) do
        if item.recordId == "autosort_target_donotuse" then
            print("Found the donotuse item, ignoring this container")
            return true
        end
    end
    return false
end

-- Engine Handlers --
local function onItemActive(item)
    if item.recordId == "autosort_master_sorter"
    then
        local autosortScript = "scripts/portable_autosorter/autosort.lua"
        if item:hasScript(autosortScript)
        then
            item:removeScript(autosortScript)
        end
        item:addScript(autosortScript)
        print('Auto Sort script baked on to autosort_master_sorter.')
    end
end

-- Event Handlers --
local function moveItems(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(data.list)
        do
            if not (types.Actor.hasEquipped(data.actorObject, item) or string.find(item.recordId, "autosort_"))
            then
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveBooks(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(types.Actor.inventory(data.actorObject):getAll(types.Book))
        do
            if string.len(types.Book.record(item).enchant) == 0
            then
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveGold(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(types.Actor.inventory(data.actorObject):getAll(types.Miscellaneous))
        do
            if string.find(item.recordId, "gold_")
            then
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveKeys(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(types.Actor.inventory(data.actorObject):getAll(types.Miscellaneous))
        do
            if types.Miscellaneous.record(item).isKey
            then
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveMisc(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(types.Actor.inventory(data.actorObject):getAll(types.Miscellaneous))
        do
            if not (types.Miscellaneous.record(item).isKey or string.find(item.recordId, "autosort_") or string.find(item.recordId, "gold_") or string.find(item.recordId, "misc_soulgem_"))
            then
                print(item.recordId)
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveScrolls(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(types.Actor.inventory(data.actorObject):getAll(types.Book))
        do
            if string.len(types.Book.record(item).enchant) > 0
            then
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveSoulGems(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(types.Actor.inventory(data.actorObject):getAll(types.Miscellaneous))
        do
            if string.find(item.recordId, "misc_soulgem_")
            then
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveOverflow(data)
    if not checkDoNotUse(data.container) then
        for _, item in ipairs(types.Actor.inventory(data.actorObject):getAll())
        do
            -- Never move Gold to the overflow container.
            if not (string.find(item.recordId, "autosort_") or types.Actor.hasEquipped(data.actorObject, item) or string.find(item.recordId, "gold_"))
            then
                item:moveInto(types.Container.inventory(data.container))
            end
        end
    end
end

local function moveAutosortMaster(data)
    print("moveAutosortMaster")
    data.item:moveInto(types.Actor.inventory(data.actorObject))
    data.actorObject:sendEvent("sendPickupSound")
end

-- Return --
return {
    interfaceName = 'portable_autosorter',
    interface = {
        version = 1.0
    },
    engineHandlers = {
        onItemActive = onItemActive
    },
    eventHandlers = {
        moveItems = moveItems,
        moveBooks = moveBooks,
        moveGold = moveGold,
        moveKeys = moveKeys,
        moveMisc = moveMisc,
        moveScrolls = moveScrolls,
        moveSoulGems = moveSoulGems,
        moveOverflow = moveOverflow,
        moveAutosortMaster = moveAutosortMaster
    }
}