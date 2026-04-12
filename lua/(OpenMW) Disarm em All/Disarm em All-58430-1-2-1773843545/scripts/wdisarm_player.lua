local self    = require("openmw.self")
local types   = require("openmw.types")
local core    = require("openmw.core")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local I       = require("openmw.interfaces")

local shared   = require("scripts.wdisarm_shared")
local DEFAULTS = shared.DEFAULTS

local section = storage.playerSection("SettingsDisarm")

local function get(key)
    local val = section:get(key)
    if val ~= nil then return val end
    return DEFAULTS[key]
end

local cachedSettings = {
    MOD_ENABLED          = get("MOD_ENABLED"),
    DISARM_NPCS          = get("DISARM_NPCS"),
    DISARM_CREATURES     = get("DISARM_CREATURES"),
    DISARM_PLAYER        = get("DISARM_PLAYER"),
    BASE_CHANCE          = get("BASE_CHANCE"),
    STR_AGI_FACTOR       = get("STR_AGI_FACTOR"),
    MAX_CHANCE           = get("MAX_CHANCE"),
    PLAYER_CHANCE_MULT   = get("PLAYER_CHANCE_MULT"),
    CHARGE_THRESHOLD     = get("CHARGE_THRESHOLD"),
    PICKUP_RADIUS        = get("PICKUP_RADIUS"),
    PICKUP_DELAY         = get("PICKUP_DELAY"),
    WEIGHT_CHECK_ENABLED = get("WEIGHT_CHECK_ENABLED"),
    WEIGHT_THRESHOLD     = get("WEIGHT_THRESHOLD"),
    SHIELD_PROTECTS      = get("SHIELD_PROTECTS"),
    NPC_PICKUP_ENABLED   = get("NPC_PICKUP_ENABLED"),
    NPC_PICKUP_CHANCE    = get("NPC_PICKUP_CHANCE"),
    DAMAGE_THRESHOLD     = get("DAMAGE_THRESHOLD"),
    SKILL_THRESHOLD      = get("SKILL_THRESHOLD"),
    CREATURE_COMBAT_MULT = get("CREATURE_COMBAT_MULT"),
}

local function refreshCache()
    for k in pairs(cachedSettings) do
        cachedSettings[k] = get(k)
    end
    core.sendGlobalEvent("Disarm_SettingsUpdated", {
        MOD_ENABLED          = cachedSettings.MOD_ENABLED,
        DISARM_NPCS          = cachedSettings.DISARM_NPCS,
        DISARM_CREATURES     = cachedSettings.DISARM_CREATURES,
        DISARM_PLAYER        = cachedSettings.DISARM_PLAYER,
        BASE_CHANCE          = cachedSettings.BASE_CHANCE,
        STR_AGI_FACTOR       = cachedSettings.STR_AGI_FACTOR,
        MAX_CHANCE           = cachedSettings.MAX_CHANCE,
        PLAYER_CHANCE_MULT   = cachedSettings.PLAYER_CHANCE_MULT,
        CHARGE_THRESHOLD     = cachedSettings.CHARGE_THRESHOLD,
        PICKUP_RADIUS        = cachedSettings.PICKUP_RADIUS,
        PICKUP_DELAY         = cachedSettings.PICKUP_DELAY,
        WEIGHT_CHECK_ENABLED = cachedSettings.WEIGHT_CHECK_ENABLED,
        WEIGHT_THRESHOLD     = cachedSettings.WEIGHT_THRESHOLD,
        SHIELD_PROTECTS      = cachedSettings.SHIELD_PROTECTS,
        NPC_PICKUP_ENABLED   = cachedSettings.NPC_PICKUP_ENABLED,
        NPC_PICKUP_CHANCE    = cachedSettings.NPC_PICKUP_CHANCE,
        DAMAGE_THRESHOLD     = cachedSettings.DAMAGE_THRESHOLD,
        SKILL_THRESHOLD      = cachedSettings.SKILL_THRESHOLD,
        CREATURE_COMBAT_MULT = cachedSettings.CREATURE_COMBAT_MULT,
    })
end

section:subscribe(async:callback(function()
    refreshCache()
end))

local function getHthSkill(actor)
    if types.NPC.objectIsInstance(actor) then
        return types.NPC.stats.skills.handtohand(actor).modified
    else
        return types.Creature.record(actor).combatSkill * cachedSettings.CREATURE_COMBAT_MULT
    end
end

local function calcChance(attacker, isUnarmed)
    local str     = types.Actor.stats.attributes.strength(attacker).modified
    local agi     = types.Actor.stats.attributes.agility(self.object).modified
    local chance  = cachedSettings.BASE_CHANCE + (str - agi) * cachedSettings.STR_AGI_FACTOR
    if isUnarmed then
        local hth_att = getHthSkill(attacker)
        local hth_def = getHthSkill(self.object)
        chance = chance + (hth_att - hth_def) * cachedSettings.STR_AGI_FACTOR
    end
    chance = chance * cachedSettings.PLAYER_CHANCE_MULT
    return math.max(0, math.min(cachedSettings.MAX_CHANCE, chance))
end

local handlerRegistered = false

local function registerHandler()
    if handlerRegistered then return end
    handlerRegistered = true
    I.Combat.addOnHitHandler(function(attack)
        if not cachedSettings.MOD_ENABLED then return end
        if not cachedSettings.DISARM_PLAYER then return end
        if not attack.successful then return end
        if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end
        if not attack.attacker or not attack.attacker:isValid() then return end

        if not attack.weapon or not attack.weapon:isValid() then
            if cachedSettings.NPC_PICKUP_ENABLED then
                core.sendGlobalEvent("Disarm_CheckPickup", { npc = attack.attacker })
            end
            if (attack.strength or 0) >= cachedSettings.CHARGE_THRESHOLD then
                local stance = types.Actor.getStance(self.object)
                if stance == 1 then
                    local eqTable = types.Actor.getEquipment(self.object)
                    if eqTable then
                        local weapon = eqTable[types.Actor.EQUIPMENT_SLOT.CarriedRight]
                        if weapon and weapon:isValid() and types.Weapon.objectIsInstance(weapon) then
                            local chance = calcChance(attack.attacker, true)
                            local roll = math.random()
                            if roll > chance then return end
                            core.sendGlobalEvent("Disarm_DoDisarm", {
                                victim   = self.object,
                                isPlayer = true,
                            })
                        end
                    end
                end
            end
            return
        end

        if (attack.strength or 0) < cachedSettings.CHARGE_THRESHOLD then return end

        local stance = types.Actor.getStance(self.object)
        if stance ~= 1 then return end

        local eqTable = types.Actor.getEquipment(self.object)
        if not eqTable then return end

        local weapon = eqTable[types.Actor.EQUIPMENT_SLOT.CarriedRight]
        if not weapon or not weapon:isValid() then return end
        if not types.Weapon.objectIsInstance(weapon) then return end

        local victimWeaponWeight   = types.Weapon.record(weapon).weight or 0
        local attackerWeaponWeight = types.Weapon.record(attack.weapon).weight or 0
        if cachedSettings.WEIGHT_CHECK_ENABLED then
            if attackerWeaponWeight < victimWeaponWeight - cachedSettings.WEIGHT_THRESHOLD then return end
        end

        local chance = calcChance(attack.attacker, false)
        local roll = math.random()
        if roll > chance then return end

        core.sendGlobalEvent("Disarm_CheckPickup", { npc = attack.attacker })
        core.sendGlobalEvent("Disarm_DoDisarm", {
            victim   = self.object,
            isPlayer = true,
        })
    end)
end

return {
    engineHandlers = {
        onInit = function()
            refreshCache()
            registerHandler()
        end,
        onLoad = function()
            refreshCache()
            registerHandler()
        end,
    },
}