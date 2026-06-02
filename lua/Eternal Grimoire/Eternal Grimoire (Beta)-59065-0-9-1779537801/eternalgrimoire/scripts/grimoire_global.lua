-- ============================================================
-- The Eternal Grimoire — GLOBAL Script
-- ============================================================

local core    = require('openmw.core')
local world   = require('openmw.world')
local types   = require('openmw.types')
local storage = require('openmw.storage')
local async   = require('openmw.async')

local spellPool = require('scripts.spell_pool')

local EG = storage.globalSection('EternalGrimoire')

local SECS_PER_DAY  = 86400
local RESTORE_DELAY = 1
local SPELL_TYPE_SPELL = 0

local scheduleDailyRefresh
local scheduleSpellRestoration

local function ensureStateInitialized()
    if EG:get('state') == nil then
        EG:set('state', 'NORMAL')
    end
end

local function getGameDayNumber()
    return math.floor(core.getGameTime() / SECS_PER_DAY)
end

local function getPlayer()
    local players = world.players
    if not players or #players == 0 then return nil end
    return players[1]
end

-- ----------------------------------------------------------------
-- Create grimoire spells — uses time-based seed for uniqueness
-- ----------------------------------------------------------------
local function createGrimoireSpells(seedTime)
    local player = getPlayer()
    local createdSpells = spellPool.generateSpellsForTime(seedTime, core, player)

    local spellIds = {}

    for _, spellDef in ipairs(createdSpells) do
        if not spellDef.effects or #spellDef.effects == 0 then
            goto continue
        end

        local alreadyExists = false
        local checkOk = pcall(function()
            local existing = core.magic.spells.record(spellDef.id)
            if existing then alreadyExists = true end
        end)

        if alreadyExists then
            spellIds[#spellIds + 1] = spellDef.id
            goto continue
        end

        local ok, result = pcall(function()
            local draft = core.magic.spells.createRecordDraft({
                id      = spellDef.id,
                name    = spellDef.name,
                type    = core.magic.SPELL_TYPE.Spell,
                cost    = spellDef.cost,
                effects = spellDef.effects,
            })
            return world.createRecord(draft)
        end)

        if ok and result then
            spellIds[#spellIds + 1] = result.id
        end

        ::continue::
    end

    return spellIds
end

-- ----------------------------------------------------------------
-- Remove grimoire spells immediately
-- ----------------------------------------------------------------
local function removeGrimoireSpells(player)
    local grimSpells = EG:get('grimoireSpells') or {}
    local spells     = types.Actor.spells(player)

    for _, id in ipairs(grimSpells) do
        pcall(function() spells:remove(id) end)
    end

    EG:set('grimoireSpells', {})
end

-- ----------------------------------------------------------------
-- Restore player's own spells (called after RESTORE_DELAY)
-- ----------------------------------------------------------------
local function restorePlayerSpells(player)
    local cached = EG:get('cachedSpells') or {}
    local spells = types.Actor.spells(player)

    for _, id in ipairs(cached) do
        pcall(function() spells:add(id) end)
    end

    EG:set('cachedSpells', {})
    EG:set('state', 'NORMAL')

    player:sendEvent('EG_SpellsRestored', {})
end

-- ----------------------------------------------------------------
-- Cache player spells, remove them, add grimoire spells
-- ----------------------------------------------------------------
local function cacheAndReplaceSpells(player)
    local spells = types.Actor.spells(player)

    local cached = {}
    for _, spell in pairs(spells) do
        local id = spell.id
        if spell.type == SPELL_TYPE_SPELL and id and id ~= '' then
            if not string.match(id, '^eg_grimoire_') then
                cached[#cached + 1] = id
            end
        end
    end

    EG:set('cachedSpells', cached)

    for _, id in ipairs(cached) do
        pcall(function() spells:remove(id) end)
    end

    local seedTime = math.floor(core.getGameTime())
    local grimoireIds = createGrimoireSpells(seedTime)

    local addedIds = {}
    for _, id in ipairs(grimoireIds) do
        pcall(function() spells:add(id) end)
        addedIds[#addedIds + 1] = id
    end

    EG:set('grimoireSpells', addedIds)
    EG:set('lastRefreshDay', getGameDayNumber())
    EG:set('state', 'ACTIVE')

    player:sendEvent('EG_GrimoireActiveConfirm', { count = #addedIds })
end

-- ----------------------------------------------------------------
-- Daily refresh
-- ----------------------------------------------------------------
local function doDailyRefresh()
    if EG:get('state') ~= 'ACTIVE' then return end

    local player = getPlayer()
    if not player then
        scheduleDailyRefresh()
        return
    end

    local currentDay  = getGameDayNumber()
    local lastRefresh = EG:get('lastRefreshDay') or -1

    if currentDay > lastRefresh then
        removeGrimoireSpells(player)

        local seedTime = math.floor(core.getGameTime())
        local grimoireIds = createGrimoireSpells(seedTime)
        local spells      = types.Actor.spells(player)

        local addedIds = {}
        for _, id in ipairs(grimoireIds) do
            pcall(function() spells:add(id) end)
            addedIds[#addedIds + 1] = id
        end

        EG:set('grimoireSpells', addedIds)
        EG:set('lastRefreshDay', currentDay)
        player:sendEvent('EG_SpellsRefreshed', { spells = addedIds })
    end

    scheduleDailyRefresh()
end

local dailyRefreshCallback = async:registerTimerCallback("dailyRefresh", doDailyRefresh)

scheduleDailyRefresh = function()
    local secsUntil = SECS_PER_DAY - (core.getGameTime() % SECS_PER_DAY)
    async:newGameTimer(secsUntil, dailyRefreshCallback)
end

-- ----------------------------------------------------------------
-- Restoration timer (fires after RESTORE_DELAY in PENDING_REST)
-- ----------------------------------------------------------------
local function doRestoration()
    if EG:get('state') ~= 'PENDING_REST' then return end
    local player = getPlayer()
    if not player then return end
    restorePlayerSpells(player)
end

local restorationCallback = async:registerTimerCallback("restoration", doRestoration)

scheduleSpellRestoration = function()
    async:newGameTimer(RESTORE_DELAY, restorationCallback)
end

-- ----------------------------------------------------------------
-- Event: grimoire picked up
-- ----------------------------------------------------------------
local function onGrimoirePickedUp()
    local state  = EG:get('state') or 'NORMAL'
    local player = getPlayer()

    if not player then return end

    if state == 'PENDING_REST' then
        restorePlayerSpells(player)
    end

    if state == 'NORMAL' or state == 'PENDING_REST' then
        cacheAndReplaceSpells(player)
        scheduleDailyRefresh()
    end
end

-- ----------------------------------------------------------------
-- Event: grimoire dropped
-- ----------------------------------------------------------------
local function onGrimoireDropped()
    local state = EG:get('state') or 'NORMAL'

    if state ~= 'ACTIVE' then return end

    local player = getPlayer()
    if not player then return end

    removeGrimoireSpells(player)

    EG:set('state', 'PENDING_REST')
    scheduleSpellRestoration()

    player:sendEvent('EG_PendingRestNotify', {})
end

-- ----------------------------------------------------------------
-- Engine handlers
-- ----------------------------------------------------------------
local function onUpdate(dt) end
local function onSave()   return {} end

local function onLoad(data)
    ensureStateInitialized()
    local savedState = EG:get('state') or 'NORMAL'

    if savedState == 'ACTIVE' then
        scheduleDailyRefresh()
    elseif savedState == 'PENDING_REST' then
        scheduleSpellRestoration()
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
    eventHandlers = {
        EG_GrimoirePickedUp = onGrimoirePickedUp,
        EG_GrimoireDropped  = onGrimoireDropped,
    },
}