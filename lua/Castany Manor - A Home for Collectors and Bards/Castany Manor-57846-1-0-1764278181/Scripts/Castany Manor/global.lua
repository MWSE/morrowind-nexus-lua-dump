-- Declarations --
local core = require("openmw.core")
local types = require('openmw.types')
local world = require('openmw.world')
local interfaces = require('openmw.interfaces')
local vfs = require('openmw.vfs')

local excludeList = {}


-- Startup Check --
if (core.API_REVISION < 71) then
    error("OpenMW 0.49.0 RC6 or newer is required.")
end

-- Internal Functions --
local function movetoContainer(item, container)
    item:moveInto(types.Container.inventory(container))
end


-- Autosort --
local function moveItems(actor, container, list)
    for _, item in ipairs(list)
    do
        if not (types.Actor.hasEquipped(actor, item) or string.find(item.recordId, "autosort_"))
        then
            movetoContainer(item, container)
        end
    end
end

local function autoSortVisualEffect(position)
    local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Jump]
    local model = types.Static.record(effect.castStatic).model
    core.sendGlobalEvent('SpawnVfx', {model = model, position = position})
end

-- Engine Handlers --
local function onItemActive(item)
    if item.recordId == "autosort_master_sorter"
    then
        local autosortScript = "scripts/Haus Mod/autosort.lua"
        if item:hasScript(autosortScript)
        then
            item:removeScript(autosortScript)
        end
        item:addScript(autosortScript)
        print('Auto Sort script baked on to autosort_master_sorter.')
    end
end

-- Event Handlers --
local function runAutoSort(data)
    local actor = data.actor
    local containers = data.containers
    local autoSortObject = data.autoSortObject
    local posInfo = data.posInfo

    local cell = world.getCellByName(data.cellInfo)
    local container
    for _, container_cur in pairs(cell:getAll(types.Container)) do
        if container_cur.recordId==data.containerInfo then
                container=container_cur
                break
        end
    end

    
    if types.Player.objectIsInstance(actor) and not (world.isWorldPaused())
    then
        if data.sortType == "alch" then
            print("test")
            moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Ingredient))
        elseif data.sortType == "armor" then
            moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Armor))
        elseif data.sortType == "weapons" then
            for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Weapon))
            do
                if not (types.Actor.hasEquipped(actor, item) or item.type.records[item.recordId].type==types.Weapon.TYPE.Arrow or item.type.records[item.recordId].type==types.Weapon.TYPE.Bolt or item.type.records[item.recordId].type==types.Weapon.TYPE.MarksmanThrown)  then
                    movetoContainer(item, container)
                end
            end
        elseif data.sortType == "potions" then
            moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Potion))
        elseif data.sortType == "projectiles" then
            for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Weapon))
            do
                if item.type.records[item.recordId].type==types.Weapon.TYPE.Arrow or item.type.records[item.recordId].type==types.Weapon.TYPE.Bolt or item.type.records[item.recordId].type==types.Weapon.TYPE.MarksmanThrown  then
                    movetoContainer(item, container)
                end
            end
        elseif data.sortType == "books" then
            for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book))
            do
                print("test")
                if string.len(item.type.records[item.recordId].enchant or '') == 0
                then
                    movetoContainer(item, container)
                end
            end
        elseif data.sortType == "scrolls" then
                for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book))
                do
                    if string.len(item.type.records[item.recordId].enchant or '') > 0
                    then
                        movetoContainer(item, container)
                    end
                end
        elseif data.sortType == "soulgems_filled" then
            for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous))
            do
                if string.find(item.recordId, "misc_soulgem_") and not (types.Item.itemData(item).soul == nil)
                then
                    movetoContainer(item, container)
                end
            end
        elseif data.sortType == "soulgems_empty" then
            for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous))
            do
                if string.find(item.recordId, "misc_soulgem_") and not (types.Item.itemData(item).soul ~= nil)
                then
                    movetoContainer(item, container)
                end
            end
        end

        actor:sendEvent("sortingComplete")
        autoSortVisualEffect(posInfo.position)
        autoSortObject:teleport(posInfo.cell, posInfo.position, posInfo.rotation)
    end
end

-- Return --
return {
    interfaceName = 'portable_autosorter',
    interface = {
        version = 2.0
    },
    engineHandlers = {
        --onItemActive = onItemActive
    },
    eventHandlers = {
        runAutoSort = runAutoSort
    }
}