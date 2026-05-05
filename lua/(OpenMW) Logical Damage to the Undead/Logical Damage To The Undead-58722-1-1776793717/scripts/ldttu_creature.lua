local self   = require("openmw.self")
local core   = require("openmw.core")
local types  = require("openmw.types")
local I      = require("openmw.interfaces")
local data   = require("scripts.ldttu_data")
local shared = require("scripts.ldttu_shared")

local cachedSettings = shared.DEFAULTS
local myGroup = nil
local hitHandlerRegistered = false

local function getWeaponCategory(attacker)
    local weapon = types.Actor.getEquipment(attacker, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon and types.Weapon.objectIsInstance(weapon) then
        local record = types.Weapon.record(weapon)
        if record then
            return data.WEAPON_MAP[record.type]
        end
    end
    return nil
end

return {
    eventHandlers = {
        LDTTU_UpdateSettings = function(newSettings)
            cachedSettings = newSettings
        end
    },
    engineHandlers = {
        onActive = function()
            myGroup = shared.determineGroup(self.recordId)
            if not myGroup then return end

            if hitHandlerRegistered then
                return
            end
            hitHandlerRegistered = true

            I.Combat.addOnHitHandler(function(attack)
                if not cachedSettings.MOD_ENABLED then
                    return
                end

                if not attack.successful or not attack.attacker or not attack.attacker:isValid() then
                    return
                end

                if not attack.damage or not attack.damage.health then
                    return
                end

                local weaponCat = getWeaponCategory(attack.attacker)
                local mult = 1.0
                local categoryName = weaponCat or "hand_to_hand"

                if myGroup == "ghost" then
                    if weaponCat == "blade" or weaponCat == "axe" then
                        mult = cachedSettings.GHOST_BLADE_MULT
                    elseif weaponCat == "blunt" or weaponCat == "spear" then
                        mult = cachedSettings.GHOST_HEAVY_MULT
                    elseif weaponCat == "marksman" then
                        mult = cachedSettings.GHOST_MARKSMAN_MULT
                    else
                        mult = cachedSettings.GHOST_H2H_MULT
                    end
                else
                    if weaponCat == "blunt" then
                        mult = cachedSettings.PHYS_BLUNT_AXE_MULT
                    elseif weaponCat == "blade" or weaponCat == "axe" then
                        mult = cachedSettings.PHYS_BLADE_MULT
                    elseif weaponCat == "spear" then
                        mult = cachedSettings.PHYS_SPEAR_MULT
                    elseif weaponCat == "marksman" then
                        mult = cachedSettings.PHYS_MARKSMAN_MULT
                    else
                        mult = cachedSettings.PHYS_H2H_MULT
                    end
                end

                local baseHealth = attack.damage.health
                attack.damage.health = baseHealth * mult

                if cachedSettings.DEBUG_LOGGING then
                    print(string.format(
                        "[LDTTU] %s | Base: %.1f | Mult: %.2fx (%s) | Final: %.1f",
                        self.recordId, baseHealth, mult, categoryName, attack.damage.health
                    ))
                end
            end)
        end,
        onInactive = function()
            core.sendGlobalEvent("LDTTU_RequestRemoval", self.object)
        end,
    }
}