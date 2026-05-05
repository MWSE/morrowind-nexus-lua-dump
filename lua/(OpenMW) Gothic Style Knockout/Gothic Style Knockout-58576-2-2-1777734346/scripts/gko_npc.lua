local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local async = require("openmw.async")
local anim  = require("openmw.animation")
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
    BH_COMPAT               = DEFAULTS.BH_COMPAT,
}

local knockedDown   = false
local bhPrisonerId = nil
local savedFatigue  = nil
local originalFight = types.Actor.stats.ai.fight(self).base
-- while true, gko_npc skips ALL knockdown logic and the NPC dies on. Used by BH
local disableKnockdown = false
-- used by BH
local bhMinLevel = 3

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

-- returns true if this NPC currently has a Follow package targeting the player
local function isFollowingPlayer()
    local found = false
    AI.forEachPackage(function(p)
        if (p.type == "Follow") and p.target
           and types.Player.objectIsInstance(p.target)
        then
            found = true
        end
    end)
    return found
end

local endKnockdown

local function suppressOwnCombat()
    if not knockedDown then return end

    -- suppress combat-related packages because the engine keeps firing combat back
    AI.filterPackages(function(p) return p.type ~= "Combat" end)
    async:newUnsavableSimulationTimer(1.0, suppressOwnCombat)
end

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
    suppressOwnCombat()

    -- suppress combat in nearby followers/allies so they don't kill the downed NPC
    core.sendGlobalEvent("GKD_BroadcastFollowerSuppress", {
        victim   = self.object,
        duration = cachedSettings.KNOCKDOWN_DURATION,
    })

    self.object:sendEvent("GKD_InternalStartKnockdown", { attacker = attacker })

   if attacker and attacker:isValid() and types.Player.objectIsInstance(attacker) then
        attacker:sendEvent("GKD_ShowMessage", {
            name = getNpcName(),
            npc  = self.object,
        })
    end
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

    AI.filterPackages(function(p) return p.type ~= "Combat" end)
    self.type.setStance(self, 0)

    -- send recovery taunt to player (only if the NPC is still alive)
    if not types.Actor.isDead(self.object) then
        local kh   = isKhajiit()
        local pool = kh and shared.KHAJIIT_RECOVERY_MESSAGES or shared.RECOVERY_MESSAGES
        local msg  = pickMsg(pool)
        local name = getNpcName()
        core.sendGlobalEvent("GKD_Recovery", { npc = self.object, recoveryMsg = name .. ": \"" .. msg .. "\"" })
    end
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

return {
    engineHandlers = {
        onActive = function()
            I.Combat.addOnHitHandler(function(attack)
                if not cachedSettings.MOD_ENABLED then return end

                local estDmg = estimateFinalDamage(attack)

                -- BH escape
                if disableKnockdown then return end

                -- while knocked out, any successful hit is execution
                if knockedDown then
                    if attack.successful then
                        knockedDown  = false
                        savedFatigue = nil
                        local healthStats = types.Actor.stats.dynamic.health(self)
                        healthStats.current = 0
                    end
                    return
                end

                if not attack.successful and estDmg <= 0 then
                    return
                end

                if not attack.attacker or not attack.attacker:isValid() then return end

                -- only melee hits can trigger knockout
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

                -- high-fight NPCs (criminals) just die... unless BH_COMPAT is on
                if cachedSettings.FIGHT_THRESHOLD_ENABLED then
                    -- BH integration: regardless of fight value, finish off an escaped criminal
                    if bhPrisonerId and self.object.id == bhPrisonerId then
                        return
                    end

                    -- above 100 usually means modified by mods like Bullseye
                    if originalFight > 100 then return end
                    if originalFight >= cachedSettings.FIGHT_THRESHOLD then
                        if cachedSettings.BH_COMPAT then
                            -- min-level gate: low-level criminals die normally
                            local lvl = types.Actor.stats.level(self).current or 1
                            if lvl < bhMinLevel then return end

                            local healthStats = types.Actor.stats.dynamic.health(self)
                            if estDmg <= 0 then return end
                            if healthStats.current - estDmg > 0 then return end

                            -- hitting a DIFFERENT high-fight criminal while we have a prisoner. Just kill them
                            if bhPrisonerId then
                                attack.attacker:sendEvent("BH_NotifyAlreadyEscorting", {})
                                return
                            end

                            -- fresh capture: knock out and hand off to BH
                            startKnockdown(attack.attacker)
                            core.sendGlobalEvent("BH_PrisonerKnockedOut", {
                                npc     = self.object,
                                player  = attack.attacker,
                            })
                        end
                        return
                    end
                end

                -- normal knockout path: lethal hit on a low-fight NPC
                local healthStats = types.Actor.stats.dynamic.health(self)
                if estDmg <= 0 then return end
                if healthStats.current - estDmg > 0 then return end

                startKnockdown(attack.attacker)

            end)
        end,

        onInactive = function()
            -- followers cause a hasScript desync
            if isFollowingPlayer() then return end

            core.sendGlobalEvent("GKD_DynamicScriptCleanup", { npc = self.object })
        end,

        onSave = function()
            -- persist disableKnockdown
            return { disableKnockdown = disableKnockdown }
        end,

        onLoad = function(data)
            if not data then return end
            if data.disableKnockdown then
                disableKnockdown = true
            end
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
            cachedSettings.BH_COMPAT               = s.BH_COMPAT
        end,

        -- sent by bh_npc when this NPC turns hostile during escort
        GKD_DisableKnockdown = function()
            disableKnockdown = true
        end,

        -- current min level
        BH_MinLevelUpdated = function(d)
            if d and d.MIN_PRISONER_LEVEL then
                bhMinLevel = d.MIN_PRISONER_LEVEL
            end
        end,

        BH_PlayerEscortState = function(d)
            bhPrisonerId = d.prisonerId
        end,

        GKD_InternalStartKnockdown = function(d)
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
                attacker = d.attacker,
            })
        end,

        -- NPC plays pickup animation, then global finalizes the weapon transfer
        GKD_StartWeaponPickup = function(d)
            if not d or not d.weapon or not d.weapon:isValid() then return end
            if types.Actor.isDead(self.object) then return end
            if d.weapon.cell == nil then return end

            AI.startPackage({
                type         = "Travel",
                destPosition = d.weapon.position,
                cancelOther  = false,
            })

            -- give the engine ~0.5s to rotate, then animate
            async:newUnsavableSimulationTimer(0.5, function()
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end
                if not d.weapon:isValid() or d.weapon.cell == nil then
                    AI.removePackages("Travel")
                    return
                end

                self:enableAI(false)
                local fired = false

                I.AnimationController.addTextKeyHandler("loot02", function(groupname, key)
                    if key == "attach" and not fired then
                        fired = true
                        core.sendGlobalEvent("GKD_FinalizeWeaponPickup", {
                            npc          = self.object,
                            weapon       = d.weapon,
                            reequipEvent = d.reequipEvent,
                        })
                    end
                end)

                I.AnimationController.playBlendedAnimation("loot02", {
                    startKey = "start",
                    stopKey  = "stop",
                    priority = anim.PRIORITY.Scripted,
                    speed    = 1,
                })
            end)

            -- end the pickup sequence: re-enable AI, clear travel
            async:newUnsavableSimulationTimer(2.5, function()
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end
                self:enableAI(true)
                AI.removePackages("Travel")
            end)
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
                return p.type ~= "Combat"
            end)
            types.Actor.stats.ai.fight(self).base = originalFight
            self.type.setStance(self, 0)
        end,

        GKD_LootPlayer = function(d)
            if not d.player or not d.player:isValid() then return end

            AI.filterPackages(function(p)
                return p.type ~= "Combat"
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

            -- ACTION: STEAL GOLD
            local function stealGold()
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end
                if not player:isValid() then return end

                self:enableAI(false)
                local fired = false

                I.AnimationController.addTextKeyHandler("loot02", function(groupname, key)
                    if key == "attach" and not fired then
                        fired = true
                        core.sendGlobalEvent("GKD_NpcStealGold", {
                            npc       = self.object,
                            player    = player,
                            name      = name,
                            isKhajiit = kh,
                        })
                    end
                end)

                I.AnimationController.playBlendedAnimation("loot02", {
                    startKey = "start",
                    stopKey  = "stop",
                    priority = anim.PRIORITY.Scripted,
                    speed    = 1.33,
                })
            end

            -- ACTION: TAKE WEAPON
            local function takeWeapon()
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end
                if not player:isValid() then return end

                self:enableAI(false)
                local fired = false

                I.AnimationController.addTextKeyHandler("loot02", function(groupname, key)
                    if key == "attach" and not fired then
                        fired = true
                        core.sendGlobalEvent("GKD_NpcTakePlayerWeapon", {
                            npc       = self.object,
                            player    = player,
                            name      = name,
                            isKhajiit = kh,
                        })
                    end
                end)

                I.AnimationController.playBlendedAnimation("loot02", {
                    startKey = "start",
                    stopKey  = "stop",
                    priority = anim.PRIORITY.Scripted,
                    speed    = 1.33,
                })
            end

            -- ACTION: STAND UP / RETURN TO NORMAL
            local function endLooting()
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end

                self:enableAI(true)
                AI.removePackages("Travel")
            end

            local hasWeapon = d.hasDroppedWeapon == true

            async:newUnsavableSimulationTimer(1.0, stealGold)
            if hasWeapon then
                async:newUnsavableSimulationTimer(3.0, takeWeapon)
                async:newUnsavableSimulationTimer(5.0, endLooting)
            else
                async:newUnsavableSimulationTimer(3.0, endLooting)
            end
        end,

        -- we do be suppressing stoopid followers
        -- kinda wish I had enough mental strength to make followers knock out NPCs but no
        -- mb later
        GKD_FollowerSuppressCombat = function(d)
            if not d or not d.duration or not d.victim then return end

            -- look up the player target
            local playerTarget = nil
            AI.forEachPackage(function(p)
                if (p.type == "Follow") and p.target
                   and types.Player.objectIsInstance(p.target)
                then
                    playerTarget = p.target
                end
            end)
            if not playerTarget then return end

            AI.startPackage({
                type = "Follow",
                target = playerTarget,
                cancelOther = true,
            })

            -- suppression loop because otherwise your follower will kill the poor gut you decided to rob
            local deadline = core.getSimulationTime() + d.duration
            local function loop()
                if not self:isActive() or types.Actor.isDead(self.object)
                   or core.getSimulationTime() >= deadline then
                    return
                end

                local activePack = AI.getActivePackage()
                if activePack and activePack.type == "Combat" and activePack.target
                   and activePack.target.id == d.victim.id
                then
                    AI.startPackage({
                        type        = "Follow",
                        target      = playerTarget,
                        cancelOther = true,
                    })
                end

                async:newUnsavableSimulationTimer(0.5, loop)
            end
            loop()
        end,
    },
}