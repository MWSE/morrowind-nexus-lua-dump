local world  = require('openmw.world')
local types  = require('openmw.types')
local core   = require('openmw.core')

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

local cachedSettings = {
    MOD_ENABLED    = DEFAULTS.MOD_ENABLED,
    COUNTDOWN      = DEFAULTS.COUNTDOWN,
    WITNESS_RADIUS = DEFAULTS.WITNESS_RADIUS,
    BOUNTY_AMOUNT  = DEFAULTS.BOUNTY_AMOUNT,
}

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

local pendingEvents = {}

local function buildEventData(isIntruder, messageType, faction)
    return {
        intruder      = isIntruder,
        messageType   = messageType,
        faction       = faction,
        countdown     = cachedSettings.COUNTDOWN,
        witnessRadius = cachedSettings.WITNESS_RADIUS,
        modEnabled    = cachedSettings.MOD_ENABLED,
    }
end

local function applyGuardStatus(actor, isIntruder, messageType, faction)
    local data = buildEventData(isIntruder, messageType, faction)
    if not actor:hasScript(GUARD_SCRIPT) then
        actor:addScript(GUARD_SCRIPT)
        table.insert(pendingEvents, { actor = actor, data = data })
    else
        actor:sendEvent("VaultStatus", data)
    end
end

return {
    eventHandlers = {
        VaultsRestricted_SettingsUpdated = function(data)
            cachedSettings = data
        end,
        AddVaultBounty = function(data)
            local currentTime = core.getRealTime()
            if currentTime - lastBountyTime > BOUNTY_COOLDOWN then
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
        end,
    },
    engineHandlers = {
        onUpdate = function()
            if #pendingEvents > 0 then
                for _, e in ipairs(pendingEvents) do
                    if e.actor:isValid() then
                        e.actor:sendEvent("VaultStatus", e.data)
                    end
                end
                for i = #pendingEvents, 1, -1 do
                    pendingEvents[i] = nil
                end
            end
        end,
        onActorActive = function(actor)
            if not cachedSettings.MOD_ENABLED then return end
            local player = world.players[1]
            if not player then return end
            if not types.NPC.objectIsInstance(actor) then return end
            if not isGuard(actor.recordId:lower()) then return end
            local cell = actor.cell
            if not cell then return end
            local cellId = cell.id:lower()
            local config = VAULT_CELLS[cellId]
            if not config then return end
            local isIntruder, messageType = getVaultStatus(config, player)
            applyGuardStatus(actor, isIntruder, messageType, config.faction)
        end,
    },
}