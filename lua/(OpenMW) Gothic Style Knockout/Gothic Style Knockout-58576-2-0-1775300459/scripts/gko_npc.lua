local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local async = require("openmw.async")
local I     = require("openmw.interfaces")
local AI    = I.AI

local shared   = require("scripts.gko_shared")
local data     = require("scripts.gko_data")
local DEFAULTS = shared.DEFAULTS

local cachedSettings = {
    MOD_ENABLED          = DEFAULTS.MOD_ENABLED,
    KNOCKDOWN_DURATION   = DEFAULTS.KNOCKDOWN_DURATION,
    DROP_WEAPON          = DEFAULTS.DROP_WEAPON,
    SET_FIGHT            = DEFAULTS.SET_FIGHT,
    SET_DISPOSITION      = DEFAULTS.SET_DISPOSITION,
    HP_AFTER_KNOCKDOWN   = DEFAULTS.HP_AFTER_KNOCKDOWN,
    BLUNT_ONLY           = DEFAULTS.BLUNT_ONLY,
    NPC_LOOT_PLAYER      = DEFAULTS.NPC_LOOT_PLAYER,
    FIGHT_THRESHOLD_ENABLED = DEFAULTS.FIGHT_THRESHOLD_ENABLED,
    FIGHT_THRESHOLD         = DEFAULTS.FIGHT_THRESHOLD,
}

local knockedDown  = false
local savedFatigue = nil
local originalFight = types.Actor.stats.ai.fight(self).base

local isNPC    = types.NPC.objectIsInstance(self.object)
local excluded = isNPC and shared.EXCLUDED_NPCS[string.lower(self.object.recordId)] or false

local function getNpcName()
    local rec = types.NPC.record(self.object)
    return rec and rec.name or self.object.recordId
end

local function isKhajiit()
    local rec = types.NPC.record(self.object)
    local race = rec and rec.race or ""
    return shared.KHAJIIT_RACE[race:lower()] or false
end

local function pickMsg(pool)
    return pool[math.random(#pool)]
end

local endKnockdown

local function startKnockdown(attacker)
    if knockedDown then return end

    -- save from lethal damage
    local healthStats = types.Actor.stats.dynamic.health(self)
    healthStats.current = 10000

    -- drain fatigue to knock out
    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    savedFatigue = fatigue.current
    fatigue.current = -100

    knockedDown = true

    async:newUnsavableSimulationTimer(0, function()
        local hs = types.Actor.stats.dynamic.health(self)
        hs.current = 1
    end)

    -- schedule recovery
    async:newUnsavableSimulationTimer(cachedSettings.KNOCKDOWN_DURATION, function()
        if knockedDown then
            endKnockdown()
        end
    end)

    -- tell global to drop weapon and handle disposition
    core.sendGlobalEvent("GKD_DoKnockdown", {
        victim   = self.object,
        attacker = attacker,
    })
end

endKnockdown = function()
    knockedDown = false

    -- restore health
    local healthStats = types.Actor.stats.dynamic.health(self)
    local maxHp       = healthStats.base + healthStats.modifier
    local targetHp    = math.max(1, math.floor(maxHp * cachedSettings.HP_AFTER_KNOCKDOWN))
    healthStats.current = targetHp

    -- restore fatigue so NPC gets up naturally
    local fatigue    = types.Actor.stats.dynamic.fatigue(self)
    local maxFatigue = fatigue.base + fatigue.modifier
    fatigue.current  = savedFatigue or (maxFatigue * 0.5)
    savedFatigue     = nil

    -- set fight to configured post-knockdown value
    local fightStat = types.Actor.stats.ai.fight(self)
    fightStat.base = cachedSettings.SET_FIGHT

    -- remove combat-related packages
    AI.filterPackages(function(p)
        return p.type ~= "Combat" and p.type ~= "Pursue"
    end)
    self.type.setStance(self, 0)

    -- send recovery taunt to player
    local kh = isKhajiit()
    local pool = kh and shared.KHAJIIT_RECOVERY_MESSAGES or shared.RECOVERY_MESSAGES
    local msg = pickMsg(pool)
    local name = getNpcName()
    core.sendGlobalEvent("GKD_Recovery", { npc = self.object, recoveryMsg = name .. ": \"" .. msg .. "\"" })
end

return {
    engineHandlers = {
        onActive = function()
            I.Combat.addOnHitHandler(function(attack)
                if not cachedSettings.MOD_ENABLED then return end

                -- while knocked out, any successful hit is execution
                if knockedDown then
                    if attack.successful then
                        knockedDown  = false
                        savedFatigue = nil
                        local healthStats = types.Actor.stats.dynamic.health(self)
                        healthStats.current = 1
                    end
                    return
                end

                if not attack.successful then return end
                if not attack.attacker or not attack.attacker:isValid() then return end

                -- only melee hits can trigger knockdown
                if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end

                -- only NPCs can be knocked out
                if not isNPC or excluded then return end

                -- only player triggers knockout
                if not types.Player.objectIsInstance(attack.attacker) then return end

                -- blunt-only check
                if cachedSettings.BLUNT_ONLY then
                    if not attack.weapon or not attack.weapon:isValid() then return end
                    local rec = types.Weapon.record(attack.weapon)
                    if not rec or not data.BLUNT_TYPES[rec.type] then return end
                end

                -- high-fight NPCs just die
                if cachedSettings.FIGHT_THRESHOLD_ENABLED then
                    -- above 100 usually means modified by mods like Bullseye
                    if originalFight > 100 then return end
                    if originalFight >= cachedSettings.FIGHT_THRESHOLD then return end
                end

                -- check if this hit would be lethal
                local healthStats = types.Actor.stats.dynamic.health(self)
                local rawDmg = (attack.damage and attack.damage.health) or 0
                if rawDmg <= 0 then return end

                -- estimate damage after difficulty adjustment
                local estDmg = rawDmg
                local simAttack = { damage = { health = rawDmg } }
                local ok, _ = pcall(function()
                    I.Combat.adjustDamageForDifficulty(simAttack)
                end)
                if ok and simAttack.damage and simAttack.damage.health then
                    estDmg = simAttack.damage.health
                end

                if healthStats.current - estDmg > 0 then return end

                startKnockdown(attack.attacker)

                local name = getNpcName()
                attack.attacker:sendEvent("GKD_ShowMessage", { name = name })
            end)
        end,
    },

    eventHandlers = {
        GKD_SettingsUpdated = function(s)
            cachedSettings.MOD_ENABLED          = s.MOD_ENABLED
            cachedSettings.KNOCKDOWN_DURATION   = s.KNOCKDOWN_DURATION
            cachedSettings.DROP_WEAPON          = s.DROP_WEAPON
            cachedSettings.SET_FIGHT            = s.SET_FIGHT
            cachedSettings.SET_DISPOSITION      = s.SET_DISPOSITION
            cachedSettings.HP_AFTER_KNOCKDOWN   = s.HP_AFTER_KNOCKDOWN
            cachedSettings.BLUNT_ONLY           = s.BLUNT_ONLY
            cachedSettings.NPC_LOOT_PLAYER      = s.NPC_LOOT_PLAYER
            cachedSettings.FIGHT_THRESHOLD_ENABLED = s.FIGHT_THRESHOLD_ENABLED
            cachedSettings.FIGHT_THRESHOLD         = s.FIGHT_THRESHOLD
        end,

        GKD_Reequip = function(d)
            if not d.weapon or not d.weapon:isValid() then return end
            local eq = types.Actor.getEquipment(self.object)
            eq[types.Actor.EQUIPMENT_SLOT.CarriedRight] = d.weapon
            types.Actor.setEquipment(self, eq)
        end,

        GKD_SetDisposition = function(d)
            if not d.player or not d.player:isValid() then return end
            if not isNPC then return end
            types.NPC.setBaseDisposition(self, d.player, cachedSettings.SET_DISPOSITION)
        end,

        GKD_StopCombatFull = function()
            AI.filterPackages(function(p)
                return p.type ~= "Combat" and p.type ~= "Pursue"
            end)
            types.Actor.stats.ai.fight(self).base = originalFight
            self.type.setStance(self, 0)
        end,

        GKD_LootPlayer = function(d)
            if not d.player or not d.player:isValid() then return end

            AI.filterPackages(function(p)
                return p.type ~= "Combat" and p.type ~= "Pursue"
            end)
            self.type.setStance(self, 0)
            types.Actor.stats.ai.fight(self).base = originalFight

            if not cachedSettings.NPC_LOOT_PLAYER then return end

            local player = d.player
            local name   = getNpcName()
            local kh     = isKhajiit()

            AI.startPackage({
                type         = "Travel",
                destPosition = player.position,
                cancelOther  = false,
            })

            async:newUnsavableSimulationTimer(2.0, function()
                if not self:isActive() then return end
                if not player:isValid() then return end

                self.controls.sneak = true

                core.sendGlobalEvent("GKD_NpcStealGold", {
                    npc       = self.object,
                    player    = player,
                    name      = name,
                    isKhajiit = kh,
                })

                async:newUnsavableSimulationTimer(1.5, function()
                    if not self:isActive() then return end

                    core.sendGlobalEvent("GKD_NpcTakePlayerWeapon", {
                        npc       = self.object,
                        player    = player,
                        name      = name,
                        isKhajiit = kh,
                    })

                    async:newUnsavableSimulationTimer(1.0, function()
                        if not self:isActive() then return end
                        self.controls.sneak = false
                        AI.filterPackages(function(p)
                            return p.type ~= "Travel"
                        end)
                    end)
                end)
            end)
        end,
    },
}