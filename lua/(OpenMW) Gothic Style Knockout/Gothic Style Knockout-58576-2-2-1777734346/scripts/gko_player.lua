local self    = require("openmw.self")
local core    = require("openmw.core")
local types   = require("openmw.types")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local ui      = require("openmw.ui")
local I       = require("openmw.interfaces")

local shared   = require("scripts.gko_shared")
local data     = require("scripts.gko_data")
local DEFAULTS = shared.DEFAULTS
local GUARD_CLASS = shared.GUARD_CLASS

local section = storage.playerSection("SettingsGKD")

local function get(key)
    local val = section:get(key)
    if val ~= nil then return val end
    return DEFAULTS[key]
end

local cachedSettings = {}

local function refreshCache()
    cachedSettings.MOD_ENABLED          = get("MOD_ENABLED")
    cachedSettings.KNOCKDOWN_DURATION   = get("KNOCKDOWN_DURATION")
    cachedSettings.DROP_WEAPON          = get("DROP_WEAPON")
    cachedSettings.PICKUP_DELAY         = get("PICKUP_DELAY")
    cachedSettings.SET_FIGHT            = get("SET_FIGHT")
    cachedSettings.SET_DISPOSITION      = get("SET_DISPOSITION")
    cachedSettings.HP_AFTER_KNOCKDOWN   = get("HP_AFTER_KNOCKDOWN")
    cachedSettings.BLUNT_ONLY           = get("BLUNT_ONLY")
    cachedSettings.PLAYER_KNOCKDOWN     = get("PLAYER_KNOCKDOWN")
    cachedSettings.NPC_LOOT_PLAYER      = get("NPC_LOOT_PLAYER")
    cachedSettings.LOOT_MIN_PERCENT     = get("LOOT_MIN_PERCENT")
    cachedSettings.FIGHT_THRESHOLD_ENABLED = get("FIGHT_THRESHOLD_ENABLED")
    cachedSettings.FIGHT_THRESHOLD         = get("FIGHT_THRESHOLD")
    cachedSettings.PLAYER_FIGHT_THRESHOLD_ENABLED = get("PLAYER_FIGHT_THRESHOLD_ENABLED")
    cachedSettings.PLAYER_FIGHT_THRESHOLD         = get("PLAYER_FIGHT_THRESHOLD")
    cachedSettings.BOUNTY_THRESHOLD_ENABLED = get("BOUNTY_THRESHOLD_ENABLED")
    cachedSettings.BOUNTY_THRESHOLD         = get("BOUNTY_THRESHOLD")
    cachedSettings.BH_COMPAT               = get("BH_COMPAT")

    core.sendGlobalEvent("GKD_SettingsUpdated", {
        MOD_ENABLED          = cachedSettings.MOD_ENABLED,
        KNOCKDOWN_DURATION   = cachedSettings.KNOCKDOWN_DURATION,
        DROP_WEAPON          = cachedSettings.DROP_WEAPON,
        PICKUP_DELAY         = cachedSettings.PICKUP_DELAY,
        SET_FIGHT            = cachedSettings.SET_FIGHT,
        SET_DISPOSITION      = cachedSettings.SET_DISPOSITION,
        HP_AFTER_KNOCKDOWN   = cachedSettings.HP_AFTER_KNOCKDOWN,
        BLUNT_ONLY           = cachedSettings.BLUNT_ONLY,
        PLAYER_KNOCKDOWN     = cachedSettings.PLAYER_KNOCKDOWN,
        NPC_LOOT_PLAYER      = cachedSettings.NPC_LOOT_PLAYER,
        LOOT_MIN_PERCENT     = cachedSettings.LOOT_MIN_PERCENT,
        FIGHT_THRESHOLD_ENABLED = cachedSettings.FIGHT_THRESHOLD_ENABLED,
        FIGHT_THRESHOLD         = cachedSettings.FIGHT_THRESHOLD,
        PLAYER_FIGHT_THRESHOLD_ENABLED = cachedSettings.PLAYER_FIGHT_THRESHOLD_ENABLED,
        PLAYER_FIGHT_THRESHOLD         = cachedSettings.PLAYER_FIGHT_THRESHOLD,
        BOUNTY_THRESHOLD_ENABLED = cachedSettings.BOUNTY_THRESHOLD_ENABLED,
        BOUNTY_THRESHOLD         = cachedSettings.BOUNTY_THRESHOLD,
        BH_COMPAT               = cachedSettings.BH_COMPAT,
    })
end

section:subscribe(async:callback(function()
    refreshCache()
end))

local knockedDown  = false
local savedFatigue = nil
local npcOriginalFights = {}

-- BH comp
local killPlayerPrisoners = {}

local endPlayerKnockdown

local function startPlayerKnockdown(attacker)
    if knockedDown then return end

    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    savedFatigue = fatigue.current
    fatigue.current = -100

    knockedDown = true

    ui.showMessage("You are knocked out!")

    async:newUnsavableSimulationTimer(cachedSettings.KNOCKDOWN_DURATION, function()
        if knockedDown then
            endPlayerKnockdown()
        end
    end)

    core.sendGlobalEvent("GKD_DoPlayerKnockdown", {
        player   = self.object,
        attacker = attacker,
    })
end

endPlayerKnockdown = function()
    knockedDown = false

    local healthStats = types.Actor.stats.dynamic.health(self)
    local maxHp       = healthStats.base + healthStats.modifier
    local targetHp    = math.max(1, math.floor(maxHp * cachedSettings.HP_AFTER_KNOCKDOWN))
    healthStats.current = targetHp

    local fatigue    = types.Actor.stats.dynamic.fatigue(self)
    local maxFatigue = fatigue.base + fatigue.modifier
    fatigue.current  = savedFatigue or (maxFatigue * 0.5)
    savedFatigue     = nil

    ui.showMessage("You regain consciousness.")

    core.sendGlobalEvent("GKD_PlayerRecovery", { player = self.object })
end

local function isAttackerGuard(attacker)
    local rec = types.NPC.record(attacker)
    if rec and rec.class and GUARD_CLASS[string.lower(rec.class)] then
        return true
    end
    local rid = string.lower(attacker.recordId)
    for _, pattern in ipairs(shared.GUARD_PATTERNS) do
        if rid:find(pattern, 1, true) then return true end
    end
    return false
end

local function isAttackerKillOnly(attacker)
    return shared.KILL_PLAYER_NPCS[string.lower(attacker.recordId)] or false
end

local function estimateFinalDamage(attack)
    local rawDmg = (attack.damage and attack.damage.health) or 0
    if rawDmg <= 0 then return 0 end

    local simAttack = { damage = { health = rawDmg } }
    local ok, _ = pcall(function()
        I.Combat.adjustDamageForDifficulty(simAttack)
    end)
    return (ok and simAttack.damage and simAttack.damage.health) or rawDmg
end

refreshCache()

I.Combat.addOnHitHandler(function(attack)
    if not cachedSettings.MOD_ENABLED then return end
    if not cachedSettings.PLAYER_KNOCKDOWN then return end

    local estDmg = estimateFinalDamage(attack)
    if not attack.successful and (not estDmg or estDmg <= 0) then
        return
    end

    if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end
    if not types.NPC.objectIsInstance(attack.attacker) then return end

    -- guards and excluded NPCs always kill
    if isAttackerGuard(attack.attacker) then return end
    if isAttackerKillOnly(attack.attacker) then return end

    -- An escorted prisoner that turned hostile must be allowed to kill the player
    if killPlayerPrisoners[attack.attacker.id] then return end

    -- high bounty = NPCs kill instead of knockout
    if cachedSettings.BOUNTY_THRESHOLD_ENABLED then
        local bounty = types.Player.getCrimeLevel(self.object)
        if bounty >= cachedSettings.BOUNTY_THRESHOLD then return end
    end

    -- use cached original fight
    if cachedSettings.PLAYER_FIGHT_THRESHOLD_ENABLED then
        local fightVal = npcOriginalFights[attack.attacker.id] or types.Actor.stats.ai.fight(attack.attacker).base
        if fightVal > 100 then return end
        if fightVal >= cachedSettings.PLAYER_FIGHT_THRESHOLD then return end
    end

    -- blunt-only check
    if cachedSettings.BLUNT_ONLY then
        if not attack.weapon or not attack.weapon:isValid() then return end
        local rec = types.Weapon.record(attack.weapon)
        if not rec or not data.BLUNT_TYPES[rec.type] then return end
    end

    local healthStats = types.Actor.stats.dynamic.health(self)
    if healthStats.current - estDmg > 0 then return end

    healthStats.current = 10000

    async:newUnsavableSimulationTimer(0.1, function()
        local hs = types.Actor.stats.dynamic.health(self)
        hs.current = 1
    end)

    startPlayerKnockdown(attack.attacker)
end)

return {
    engineHandlers = {
        onInit  = function() refreshCache() end,
        onLoad  = function(loadData)
            refreshCache()
            npcOriginalFights = {}
            -- killPlayerPrisoners survives across saves
            if loadData and loadData.killPlayerPrisoners then
                killPlayerPrisoners = {}
                for k, v in pairs(loadData.killPlayerPrisoners) do
                    killPlayerPrisoners[k] = v
                end
            else
                killPlayerPrisoners = {}
            end
        end,
        onSave = function()
            return { killPlayerPrisoners = killPlayerPrisoners }
        end,
    },
    eventHandlers = {
        GKD_ShowMessage = function(d)
            local name = d.name or "Someone"
            ui.showMessage(name .. " is knocked out.")
        end,
        GKD_ShowRecoveryMessage = function(d)
            if d.msg then
                ui.showMessage(d.msg)
            end
        end,
        GKD_NpcFightCached = function(d)
            if d.npcId and d.fight then
                npcOriginalFights[d.npcId] = d.fight
            end
        end,
        GKD_NpcFightRemoved = function(d)
            if d.npcId then
                npcOriginalFights[d.npcId] = nil
            end
        end,
        -- BH integration
        BH_PrisonerSetKillPlayer = function(d)
            if d and d.npc and d.npc:isValid() then
                killPlayerPrisoners[d.npc.id] = true
            end
        end,
        BH_PrisonerClearKillPlayer = function(d)
            if d and d.npc and d.npc:isValid() then
                killPlayerPrisoners[d.npc.id] = nil
            end
        end,
    },
}