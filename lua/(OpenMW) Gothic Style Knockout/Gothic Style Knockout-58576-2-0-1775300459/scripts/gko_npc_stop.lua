local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local async = require("openmw.async")
local I     = require("openmw.interfaces")
local AI    = I.AI

local shared   = require("scripts.gko_shared")
local DEFAULTS = shared.DEFAULTS

local cachedSettings = {
    NPC_LOOT_PLAYER = DEFAULTS.NPC_LOOT_PLAYER,
}

local originalFight = types.Actor.stats.ai.fight(self).base

local function getNpcName()
    local rec = types.NPC.record(self.object)
    return rec and rec.name or self.object.recordId
end

local function isKhajiit()
    local rec = types.NPC.record(self.object)
    local race = rec and rec.race or ""
    return shared.KHAJIIT_RACE[race:lower()] or false
end

return {
    engineHandlers = {
        onInactive = function()
            core.sendGlobalEvent("GKD_DynamicScriptCleanup", { npc = self.object })
        end,
    },

    eventHandlers = {
        GKD_SettingsUpdated = function(s)
            cachedSettings.NPC_LOOT_PLAYER = s.NPC_LOOT_PLAYER
        end,

        GKD_SetOriginalFight = function(d)
            if d.fight then
                originalFight = d.fight
            end
        end,

        GKD_StopCombatFull = function()
            if AI then
                AI.filterPackages(function(p)
                    return p.type ~= "Combat" and p.type ~= "Pursue"
                end)
            end
            types.Actor.stats.ai.fight(self).base = originalFight
            self.type.setStance(self, 0)
        end,

        GKD_LootPlayer = function(d)
            if not d.player or not d.player:isValid() then return end

            -- stop combat and reset fight
            if AI then
                AI.filterPackages(function(p)
                    return p.type ~= "Combat" and p.type ~= "Pursue"
                end)
            end
            self.type.setStance(self, 0)
            types.Actor.stats.ai.fight(self).base = originalFight

            if not cachedSettings.NPC_LOOT_PLAYER then return end

            local player = d.player
            local name   = getNpcName()
            local kh     = isKhajiit()

            -- walk to player
            if AI then
                AI.startPackage({
                    type         = "Travel",
                    destPosition = player.position,
                    cancelOther  = false,
                })
            end

            -- loot phase
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
                        if AI then
                            AI.filterPackages(function(p)
                                return p.type ~= "Travel"
                            end)
                        end
                    end)
                end)
            end)
        end,
    },
}
