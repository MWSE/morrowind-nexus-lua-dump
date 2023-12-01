local self = require("openmw.self")
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local ui = require("openmw.ui")
local async = require("openmw.async")


local modInfo        = require("scripts.auto_ammo_equip_omw.modInfo")
local constants      = require("scripts.auto_ammo_equip_omw.constants")
local playerSettings = require("openmw.storage").playerSection("Settings_AAEOMW_Options_Key_KINDI")


local lastEquippedWeapon = nil -- handles thrown weapons

local getRecord = types.Weapon.record
local getInventory = types.Actor.inventory

local defCompOrder = constants.defCompOrder
local comp = constants.comp
local ammoType = constants.ammoType
local sort = constants.sort --prefer stable sort

local function updatePriority()
    local order = playerSettings:get("Equip Priority") or "1,2,3"
    local pos = 1
    local priority = {}
    for index in string.gmatch(order, "(-?%d+),?") do
        local i = tonumber(index)
        if type(i) == "number" then
            table.insert(priority, i)
        else
            return
        end
    end
    for k, index in ipairs(priority) do
        comp[pos] = defCompOrder[math.abs(index)]
        comp[#defCompOrder + pos] = true
        if index < 0 then
            comp[#defCompOrder + pos] = false
        end
        pos = pos + 1
    end
end

local function ammoSorter(ammunitions)
    sort(ammunitions, function(a, b)
        return comp[3](a, b, comp[6])
    end)
    sort(ammunitions, function(a, b)
        return comp[2](a, b, comp[5])
    end)
    sort(ammunitions, function(a, b)
        return comp[1](a, b, comp[4])
    end)
end

local function getAmmo(ammoTypeToEquip)
    local ammunitions = getInventory(self):getAll(types.Weapon)

    ammunitions = aux_util.mapFilter(ammunitions,
        function(ammo) return getRecord(ammo).type == ammoTypeToEquip end)

    if next(ammunitions) then
        ammoSorter(ammunitions)
        return ammunitions[1]
    end
end

local function autoEquip(ammoTypeToEquip)
    if not playerSettings:get("Mod Status") then
        return
    end

    if types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon and playerSettings:get("Attack Stance") then
        return
    end

    local newAmmo = getAmmo(ammoTypeToEquip)
    if newAmmo then
        core.sendGlobalEvent("UseItem", { object = newAmmo, actor = self, force = true })

        if playerSettings:get("Notification") then
            --due to delayed action (useItem), showMessage can trigger many times here, anyone know a workaround?
            ui.showMessage(string.format(core.getGMST("sLoadingMessage15") .. " %ss..", newAmmo.count, getRecord(newAmmo).name))
            ui.showMessage("")
            ui.showMessage("")
        end
    end
end

local function alreadyEquipped(ammoTypeToEquip)
    local equipment = types.Actor.getEquipment(self)
    local equippedAmmo = equipment[types.Actor.EQUIPMENT_SLOT.Ammunition]
    if equippedAmmo and getRecord(equippedAmmo).type == ammoTypeToEquip then
        return true --if the same type of ammo is already equipped, do nothing
    end
end

playerSettings:subscribe(async:callback(function(sectionName, changedKey)
    if sectionName == "Settings_AAEOMW_Options_Key_KINDI" then
        if changedKey == "Equip Priority" or changedKey == nil then
            pcall(updatePriority)
        end
    end
end))

--onFrame bug, variables dont get updated inside onFrame handler until next simulation
return {
    engineHandlers = {
        onFrame = function(dt) --using onFrame so this works during inventory mode (menumode)
            local equipment = types.Actor.getEquipment(self)
            local equippedWeapon = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            lastEquippedWeapon = equippedWeapon or lastEquippedWeapon

            if equippedWeapon then
                local ammoTypeToEquip = ammoType[getRecord(equippedWeapon).type]
                if ammoTypeToEquip then
                    if not alreadyEquipped(ammoTypeToEquip) then
                        autoEquip(ammoTypeToEquip)
                    end
                end
            elseif lastEquippedWeapon then --if no weapon is currently equipped, determine if the last weapon was a thrown weapon
                if getRecord(lastEquippedWeapon).type == types.Weapon.TYPE.MarksmanThrown then
                    if not getInventory(self):find(lastEquippedWeapon.recordId) then
                        autoEquip(types.Weapon.TYPE.MarksmanThrown)
                    end
                end
            end
        end,
        onActive = function()
            assert(core.API_REVISION >= modInfo.MIN_API,
                string.format("[%s] requires OpenMW version 0.49 or newer!", modInfo.MOD_NAME))
        end
    },
    eventHandlers = {
        AAE_MarksmanWeaponEquipped_eqnx = function(data)
            if not alreadyEquipped(data.ammoType) then
                autoEquip(data.ammoType)
            end
        end,
    }
}
