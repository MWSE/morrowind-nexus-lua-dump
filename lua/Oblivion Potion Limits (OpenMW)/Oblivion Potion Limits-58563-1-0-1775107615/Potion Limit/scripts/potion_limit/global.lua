local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')

local MAX_ACTIVE_POTIONS = 4
local CHECK_INTERVAL_SECONDS = 0.2
local nextCheckTime = 0

local function isPlayer(actor)
    return actor ~= nil and actor == world.players[1]
end

local function getActivePotionSpells(actor)
    local activePotionSpells = {}
    for _, spell in pairs(types.Actor.activeSpells(actor)) do
        if spell.temporary and types.Potion.records[spell.id] ~= nil then
            activePotionSpells[#activePotionSpells + 1] = {
                activeSpellId = spell.activeSpellId or -1,
                id = spell.id,
            }
        end
    end
    table.sort(activePotionSpells, function(a, b)
        return a.activeSpellId > b.activeSpellId
    end)
    return activePotionSpells
end

local function notifyLimitReached(actor)
    actor:sendEvent('PotionLimit_ShowLimitMessage')
end

local function enforcePotionCap(actor)
    local activePotionSpells = getActivePotionSpells(actor)
    local overflow = #activePotionSpells - MAX_ACTIVE_POTIONS
    if overflow <= 0 then
        return false
    end

    local activeSpells = types.Actor.activeSpells(actor)
    local inventory = types.Actor.inventory(actor)
    for i = 1, overflow do
        local spell = activePotionSpells[i]
        activeSpells:remove(spell.activeSpellId)
        world.createObject(spell.id, 1):moveInto(inventory)
    end

    return true
end

local function onUsePotion(_, actor)
    if not isPlayer(actor) then
        return
    end

    if #getActivePotionSpells(actor) >= MAX_ACTIVE_POTIONS then
        notifyLimitReached(actor)
        return false
    end
end

interfaces.ItemUsage.addHandlerForType(types.Potion, onUsePotion)

local function onUpdate()
    local now = core.getSimulationTime()
    if now < nextCheckTime then
        return
    end
    nextCheckTime = now + CHECK_INTERVAL_SECONDS

    local player = world.players[1]
    if not isPlayer(player) then
        return
    end

    if enforcePotionCap(player) then
        notifyLimitReached(player)
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
