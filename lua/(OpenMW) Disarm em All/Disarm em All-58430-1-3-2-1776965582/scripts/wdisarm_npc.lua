local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local I     = require("openmw.interfaces")

local shared   = require("scripts.wdisarm_shared")
local DEFAULTS = shared.DEFAULTS

local cachedSettings = {
    MOD_ENABLED          = DEFAULTS.MOD_ENABLED,
    DISARM_NPCS          = DEFAULTS.DISARM_NPCS,
    BASE_CHANCE          = DEFAULTS.BASE_CHANCE,
    STR_AGI_FACTOR       = DEFAULTS.STR_AGI_FACTOR,
    MAX_CHANCE           = DEFAULTS.MAX_CHANCE,
    CHARGE_THRESHOLD     = DEFAULTS.CHARGE_THRESHOLD,
    WEIGHT_CHECK_ENABLED = DEFAULTS.WEIGHT_CHECK_ENABLED,
    WEIGHT_THRESHOLD     = DEFAULTS.WEIGHT_THRESHOLD,
    SHIELD_PROTECTS      = DEFAULTS.SHIELD_PROTECTS,
    NPC_PICKUP_ENABLED   = DEFAULTS.NPC_PICKUP_ENABLED,
    CREATURE_COMBAT_MULT = DEFAULTS.CREATURE_COMBAT_MULT,
    DISARM_CREATURES     = DEFAULTS.DISARM_CREATURES,
    STRENGTH_AS_MULT     = DEFAULTS.STRENGTH_AS_MULT,
}

local function getHthSkill(actor)
    if types.NPC.objectIsInstance(actor) then
        return types.NPC.stats.skills.handtohand(actor).modified
    else
        return types.Creature.record(actor).combatSkill * cachedSettings.CREATURE_COMBAT_MULT
    end
end

local function calcChance(attacker, isUnarmed)
    local str    = types.Actor.stats.attributes.strength(attacker).modified
    local agi    = types.Actor.stats.attributes.agility(self.object).modified
    local chance = cachedSettings.BASE_CHANCE + (str - agi) * cachedSettings.STR_AGI_FACTOR
    if isUnarmed then
        local hth_att = getHthSkill(attacker)
        local hth_def = getHthSkill(self.object)
        chance = cachedSettings.BASE_CHANCE + (hth_att - hth_def) * cachedSettings.STR_AGI_FACTOR
    end
    return math.max(0, math.min(cachedSettings.MAX_CHANCE, chance))
end

return {
    engineHandlers = {
        onActive = function()
            I.Combat.addOnHitHandler(function(attack)
                if not cachedSettings.MOD_ENABLED then return end
                if attack.ngarde_perfectParry then return end
                local isNPC = types.NPC.objectIsInstance(self.object)
                if isNPC and not cachedSettings.DISARM_NPCS then return end
                if not isNPC and not cachedSettings.DISARM_CREATURES then return end
                if not attack.successful then return end
                if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end
                if not attack.attacker or not attack.attacker:isValid() then return end
                if shared.EXCLUDED_NPCS[string.lower(self.object.recordId)] then return end
                local useMult = cachedSettings.STRENGTH_AS_MULT
                local hitStrength = attack.strength or 0
                if not useMult and hitStrength < cachedSettings.CHARGE_THRESHOLD then return end

                local stance = types.Actor.getStance(self.object)
                if stance ~= 1 then return end

                local eqTable = types.Actor.getEquipment(self.object)
                if not eqTable then return end

                local weapon = eqTable[types.Actor.EQUIPMENT_SLOT.CarriedRight]
                if not weapon or not weapon:isValid() then return end
                if not types.Weapon.objectIsInstance(weapon) then return end

                local isUnarmed = not attack.weapon or not attack.weapon:isValid()

                if not isUnarmed then
                    if cachedSettings.SHIELD_PROTECTS then
                        local shield = eqTable[types.Actor.EQUIPMENT_SLOT.CarriedLeft]
                        if shield and shield:isValid() and types.Armor.objectIsInstance(shield) then
                            local weaponType = types.Weapon.record(weapon).type
                            local isTwoHanded = weaponType == types.Weapon.TYPE.LongBladeTwoHand
                                             or weaponType == types.Weapon.TYPE.BluntTwoClose
                                             or weaponType == types.Weapon.TYPE.BluntTwoWide
                                             or weaponType == types.Weapon.TYPE.SpearTwoWide
                                             or weaponType == types.Weapon.TYPE.AxeTwoHand
                            if not isTwoHanded then
                                return 
                            end
                        end
                    end

                    local victimWeaponWeight   = types.Weapon.record(weapon).weight or 0
                    local attackerWeaponWeight = types.Weapon.record(attack.weapon).weight or 0
                    if cachedSettings.WEIGHT_CHECK_ENABLED then
                        if attackerWeaponWeight < victimWeaponWeight - cachedSettings.WEIGHT_THRESHOLD then return end
                    end
                end

                local chance = calcChance(attack.attacker, isUnarmed)
                if useMult then
                    chance = chance * hitStrength
                end
                local roll = math.random()
                if roll > chance then return end

                core.sendGlobalEvent("Disarm_DoDisarm", {
                    victim   = self.object,
                    isPlayer = false,
                })
            end)
        end,

        onInactive = function()
            core.sendGlobalEvent("Disarm_DynamicScriptCleanup", { npc = self.object })
        end,
    },

    eventHandlers = {
        Disarm_SettingsUpdated = function(data)
            cachedSettings.MOD_ENABLED          = data.MOD_ENABLED
            cachedSettings.DISARM_NPCS          = data.DISARM_NPCS
            cachedSettings.BASE_CHANCE          = data.BASE_CHANCE
            cachedSettings.STR_AGI_FACTOR       = data.STR_AGI_FACTOR
            cachedSettings.MAX_CHANCE           = data.MAX_CHANCE
            cachedSettings.CHARGE_THRESHOLD     = data.CHARGE_THRESHOLD
            cachedSettings.WEIGHT_CHECK_ENABLED = data.WEIGHT_CHECK_ENABLED
            cachedSettings.WEIGHT_THRESHOLD     = data.WEIGHT_THRESHOLD
            cachedSettings.SHIELD_PROTECTS      = data.SHIELD_PROTECTS
            cachedSettings.NPC_PICKUP_ENABLED   = data.NPC_PICKUP_ENABLED
            cachedSettings.CREATURE_COMBAT_MULT = data.CREATURE_COMBAT_MULT
            cachedSettings.DISARM_CREATURES     = data.DISARM_CREATURES
            cachedSettings.STRENGTH_AS_MULT     = data.STRENGTH_AS_MULT
        end,

        Disarm_Reequip = function(data)
            if not data.weapon or not data.weapon:isValid() then return end
            local eq = types.Actor.getEquipment(self.object)
            if not eq then return end
            eq[types.Actor.EQUIPMENT_SLOT.CarriedRight] = data.weapon
            types.Actor.setEquipment(self, eq)
        end,
    },
}