local world  = require('openmw.world')
local types  = require('openmw.types')
local core   = require('openmw.core')
local async  = require('openmw.async')

local shared               = require('scripts.vaults_shared')
local VAULT_CELLS          = shared.VAULT_CELLS
local HOUSE_FACTIONS       = shared.HOUSE_FACTIONS
local NON_HOUSE_FACTIONS   = shared.NON_HOUSE_FACTIONS
local GUARD_PATTERNS       = shared.GUARD_PATTERNS
local GUARD_TR_PATTERNS    = shared.GUARD_TR_PATTERNS
local GUARD_EXCLUDE_PATTERNS = shared.GUARD_EXCLUDE_PATTERNS
local DEFAULTS             = shared.DEFAULTS

local GUARD_SCRIPT    = 'scripts/vaults_restricted.lua'
local BOUNTY_COOLDOWN = 10
local lastBountyTime  = 0
local pendingRemoval  = {}

local cachedSettings = {
    MOD_ENABLED         = DEFAULTS.MOD_ENABLED,
    COUNTDOWN           = DEFAULTS.COUNTDOWN,
    WITNESS_RADIUS      = DEFAULTS.WITNESS_RADIUS,
    BOUNTY_AMOUNT       = DEFAULTS.BOUNTY_AMOUNT,
    CHAMELEON_THRESHOLD = DEFAULTS.CHAMELEON_THRESHOLD,
    SNEAK_THRESHOLD     = DEFAULTS.SNEAK_THRESHOLD,
    SIGN_COMPAT         = DEFAULTS.SIGN_COMPAT,
}

local function scheduleRemoval(actor)
    if not actor or not actor:isValid() then return end
    local id = actor.id
    if pendingRemoval[id] then return end
    pendingRemoval[id] = true
    async:newUnsavableSimulationTimer(0.5, function()
        local shouldRemove = pendingRemoval[id]
        pendingRemoval[id] = nil
        if shouldRemove and actor:isValid() and actor:hasScript(GUARD_SCRIPT) then
            actor:removeScript(GUARD_SCRIPT)
        end
    end)
end

local function isGuard(id)
    for _, pattern in ipairs(GUARD_PATTERNS) do
        if id:find(pattern) then return true end
    end
    for _, pattern in ipairs(GUARD_TR_PATTERNS) do
        if id:find(pattern) then
            for _, exclude in ipairs(GUARD_EXCLUDE_PATTERNS) do
                if id:find(exclude) then return false end
            end
            return true
        end
    end
    return false
end

local function getVaultStatus(config, player)
    if config.alwaysIntruder then
        return true, config.messageType or 0
    end

    if config.questException then
        local quests = types.Player.quests(player)
        local quest = quests[config.questException.id]
        if quest and quest.started and quest.stage < config.questException.stageComplete then
            return false, config.messageType or 0
        end
    end

    local rank = types.NPC.getFactionRank(player, config.faction)
    if rank == 0 then
        return true, NON_HOUSE_FACTIONS[config.faction] or 2
    elseif rank < config.minRank then
        return true, config.messageType
    end
    return false, config.messageType or 0
end

local function buildEventData(isIntruder, messageType, faction)
    return {
        intruder           = isIntruder,
        messageType        = messageType,
        faction            = faction,
        countdown          = cachedSettings.COUNTDOWN,
        witnessRadius      = cachedSettings.WITNESS_RADIUS,
        modEnabled         = cachedSettings.MOD_ENABLED,
        chameleonThreshold = cachedSettings.CHAMELEON_THRESHOLD,
        sneakThreshold     = cachedSettings.SNEAK_THRESHOLD,
        signCompat         = cachedSettings.SIGN_COMPAT,
    }
end

local function applyGuardStatus(actor, isIntruder, messageType, faction)
    local payload = buildEventData(isIntruder, messageType, faction)
    if not actor:hasScript(GUARD_SCRIPT) then
        actor:addScript(GUARD_SCRIPT)
        async:newUnsavableSimulationTimer(0, function()
            if actor:isValid() then
                actor:sendEvent("VaultStatus", payload)
            end
        end)
    else
        actor:sendEvent("VaultStatus", payload)
    end
end

local function onSettingsUpdated(data)
    cachedSettings = data
end

local function onAddVaultBounty(data)
    local currentTime = core.getRealTime()
    if currentTime - lastBountyTime <= BOUNTY_COOLDOWN then return end

    local player        = data.player
    local currentBounty = types.Player.getCrimeLevel(player)
    types.Player.setCrimeLevel(player, currentBounty + cachedSettings.BOUNTY_AMOUNT)
    lastBountyTime = currentTime

    if data.faction then
        pcall(function()
            local rank = types.NPC.getFactionRank(player, data.faction)
            if rank and rank > 0 then
                types.NPC.expel(player, data.faction)
                local displayName = HOUSE_FACTIONS[data.faction]
                    and ("Great House " .. data.faction)
                    or data.faction
                player:sendEvent("GuardWarning", {
                    message = "You have been expelled from the " .. displayName .. "."
                })
            end
        end)
    end
end

local function onRequestRemoval(actor)
    scheduleRemoval(actor)
end

-- one guard's countdown expired (or they were attacked) and they're entering combat
-- tell every other vault guard in the same cell to drop their state and join
local function onAlertAllGuards(data)
    if not data or not data.cell or not data.player or not data.player:isValid() then return end
    local sourceId = data.sourceGuard and data.sourceGuard.id or nil

    for _, actor in ipairs(world.activeActors) do
        if actor.id ~= sourceId
           and actor:hasScript(GUARD_SCRIPT)
           and actor.cell
           and actor.cell.id == data.cell
           and not types.Actor.isDead(actor) then
            actor:sendEvent("VaultJoinCombat", {
                player  = data.player,
                faction = data.faction,
            })
        end
    end
end

local function onActorActive(actor)
    if not cachedSettings.MOD_ENABLED then return end
    local player = world.players[1]
    if not player then return end
    if not types.NPC.objectIsInstance(actor) then return end
    if not isGuard(actor.recordId:lower()) then return end
    local cell = actor.cell
    if not cell then return end
    local cellId = cell.id:lower()
    local config = VAULT_CELLS[cellId]
    if not config then
        if actor:hasScript(GUARD_SCRIPT) then
            scheduleRemoval(actor)
        end
        return
    end
    pendingRemoval[actor.id] = nil
    local isIntruder, messageType = getVaultStatus(config, player)
    applyGuardStatus(actor, isIntruder, messageType, config.faction)
end

return {
    eventHandlers = {
        VaultsRestricted_SettingsUpdated = onSettingsUpdated,
        AddVaultBounty                   = onAddVaultBounty,
        VaultsRestricted_RequestRemoval  = onRequestRemoval,
        VaultsAlertAllGuards             = onAlertAllGuards,
    },
    engineHandlers = {
        onActorActive = onActorActive,
    },
}