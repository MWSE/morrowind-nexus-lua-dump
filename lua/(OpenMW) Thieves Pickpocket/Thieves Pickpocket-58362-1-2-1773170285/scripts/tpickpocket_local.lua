local self   = require("openmw.self")
local types  = require("openmw.types")
local nearby = require("openmw.nearby")
local core   = require("openmw.core")

local shared                = require("scripts.tshared")
local THIEF_FACTIONS        = shared.THIEF_FACTIONS
local THIEF_CLASSES         = shared.THIEF_CLASSES
local FACTION_IMMUNITY      = shared.FACTION_IMMUNITY
local GOLD_IDS              = shared.GOLD_IDS
local STEALABLE_MISC        = shared.STEALABLE_MISC
local STEALABLE_INGREDIENTS = shared.STEALABLE_INGREDIENTS
local STEALABLE_CLOTHING    = shared.STEALABLE_CLOTHING
local DEFAULTS              = shared.DEFAULTS
local STEAL_MESSAGES        = shared.STEAL_MESSAGES

local cachedSettings = {
    MOD_ENABLED     = DEFAULTS.MOD_ENABLED,
    STEAL_RADIUS    = DEFAULTS.STEAL_RADIUS,
    STEAL_CHANCE    = DEFAULTS.STEAL_CHANCE,
    MIN_GOLD        = DEFAULTS.MIN_GOLD,
    MAX_GOLD        = DEFAULTS.MAX_GOLD,
    AGILITY_MIN     = DEFAULTS.AGILITY_MIN,
    SNEAK_MIN       = DEFAULTS.SNEAK_MIN,
    SCAN_INTERVAL   = DEFAULTS.SCAN_INTERVAL,
    USE_DISPOSITION = DEFAULTS.USE_DISPOSITION,
    MAX_DISPOSITION = DEFAULTS.MAX_DISPOSITION,
    PLAY_SOUND      = DEFAULTS.PLAY_SOUND,
    SHOW_MESSAGE    = DEFAULTS.SHOW_MESSAGE,
    STEAL_ITEMS     = DEFAULTS.STEAL_ITEMS,
}

local activated = false
local scanTimer = 0

local function randomMessage()
    return STEAL_MESSAGES[math.random(#STEAL_MESSAGES)]
end

local function getFactionRank(actor, factionId)
    local ok, rank = pcall(types.NPC.getFactionRank, actor, factionId)
    if not ok then return 0 end
    return rank
end

local function getThiefFaction()
    for factionId, _ in pairs(THIEF_FACTIONS) do
        if getFactionRank(self.object, factionId) > 0 then
            return factionId
        end
    end
    return nil
end

local function isThiefByClassOnly()
    if getThiefFaction() then return false end
    local classId = types.NPC.record(self.object).class
    return classId and THIEF_CLASSES[classId:lower()] or false
end

local function isFactionProtected(player, thiefFaction)
    local immunity = FACTION_IMMUNITY[thiefFaction]
    if not immunity then return false end
    for immuneFactionId, _ in pairs(immunity) do
        if getFactionRank(player, immuneFactionId) > 0 then return true end
    end
    return false
end

local function isDispositionTooHigh(player)
    if not cachedSettings.USE_DISPOSITION then return false end
    return types.NPC.getDisposition(self.object, player) > cachedSettings.MAX_DISPOSITION
end

local function isVulnerable(player)
    local agility = types.Actor.stats.attributes.agility(player).modified
    local sneak   = types.NPC.stats.skills.sneak(player).modified
    if agility >= cachedSettings.AGILITY_MIN or sneak >= cachedSettings.SNEAK_MIN then return false end
    return true
end

local function buildStealPool(player)
    local pool = {}
    local inv  = types.Actor.inventory(player)

    local equippedCount = {}
    local eqTable = types.Actor.getEquipment(player)
    if eqTable then
        for _, item in pairs(eqTable) do
            if item and item:isValid() then
                local rid = string.lower(item.recordId)
                equippedCount[rid] = (equippedCount[rid] or 0) + 1
            end
        end
    end

    local inventoryCount = {}
    for _, item in ipairs(inv:getAll()) do
        local rid = string.lower(item.recordId)
        inventoryCount[rid] = (inventoryCount[rid] or 0) + item.count
    end

    for _, item in ipairs(inv:getAll()) do
        local rid = string.lower(item.recordId)

        if GOLD_IDS[rid] and item.count > 0 then
            local amount = math.min(
                math.random(cachedSettings.MIN_GOLD, cachedSettings.MAX_GOLD),
                item.count
            )
            pool[#pool + 1] = { kind = "gold", amount = amount }

        elseif cachedSettings.STEAL_ITEMS then

            if STEALABLE_MISC[rid] and item.count > 0 then
                pool[#pool + 1] = { kind = "item", recordId = rid }

            elseif STEALABLE_INGREDIENTS[rid] and item.count > 0 then
                pool[#pool + 1] = { kind = "item", recordId = rid }

            elseif STEALABLE_CLOTHING[rid] and item.count > 0 then
                local worn  = equippedCount[rid] or 0
                local inInv = inventoryCount[rid] or 0
                local free  = inInv - worn
                if free > 0 then
                    pool[#pool + 1] = { kind = "item", recordId = rid }
                end
            end
        end
    end

    return pool
end

local function trySteal(player)
    if math.random() > cachedSettings.STEAL_CHANCE then return end

    local pool = buildStealPool(player)
    if #pool == 0 then return end

    local choice  = pool[math.random(#pool)]
    local message = cachedSettings.SHOW_MESSAGE and randomMessage() or nil

    core.sendGlobalEvent("PickpocketDoSteal", {
        player    = player,
        npc       = self.object,
        choice    = choice,
        message   = message,
        playSound = cachedSettings.PLAY_SOUND,
    })
end

return {
    engineHandlers = {
        onActive = function()
            activated = false
            scanTimer = 0
        end,
        onUpdate = function(dt)
            if not cachedSettings.MOD_ENABLED then return end
            if activated then return end
            scanTimer = scanTimer + dt
            if scanTimer < cachedSettings.SCAN_INTERVAL then return end
            scanTimer = 0
            if types.Actor.isDead(self) then activated = true return end
            local stance = types.Actor.getStance(self)
            if stance == 1 or stance == 2 then return end
            local player = nil
            for _, actor in ipairs(nearby.actors) do
                if types.Player.objectIsInstance(actor) then
                    player = actor
                    break
                end
            end
            if not player then return end
            if isDispositionTooHigh(player) then return end
            local thiefFaction = getThiefFaction()
            if thiefFaction then
                if isFactionProtected(player, thiefFaction) then activated = true return end
            elseif not isThiefByClassOnly() then
                activated = true return
            end
            if not isVulnerable(player) then activated = true return end
            if (player.position - self.position):length() > cachedSettings.STEAL_RADIUS then return end
            activated = true
            trySteal(player)
        end,
    },
    eventHandlers = {
        TP_SettingsUpdated = function(data)
            cachedSettings = data
        end,
    },
}