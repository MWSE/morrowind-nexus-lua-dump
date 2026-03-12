local I = require("openmw.interfaces")
local types = require("openmw.types")
local self = require("openmw.self")
local storage = require("openmw.storage")
local async = require("openmw.async")

local E = require("scripts.AmmoCountHUD.uiElements")
local C = require("scripts.AmmoCountHUD.utils.consts")

local settingsBehavior = storage.playerSection("SettingsAmmoCountHUD_behavior")
local settingsLooks = storage.playerSection("SettingsAmmoCountHUD_looks")
local updateTime = 0

local function getEquippedAmmoCount(weapon, ammoType)
    if ammoType == types.Weapon.TYPE.MarksmanThrown then
        return weapon.count
    else
        local ammo = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Ammunition)
        if not ammo then return 0 end

        local ammoRecord = ammo.type.records[ammo.recordId]
        return ammoRecord.type == ammoType and ammo.count or 0
    end
end

local function getTotalAmmoCount(weapon, ammoType)
    local inv = self.type.inventory(self)
    local allAmmo = inv:getAll(types.Weapon)
    local ammoCounter = 0
    for _, item in ipairs(allAmmo) do
        if item.type.records[item.recordId].type == ammoType then
            ammoCounter = ammoCounter + item.count
        end
    end
    return ammoCounter
end

local hudMode = {
    ["Equipped"] = getEquippedAmmoCount,
    ["Total"] = getTotalAmmoCount,
    ["Eqipped/Total"] = function(weapon, ammoType)
        local equipped = getEquippedAmmoCount(weapon, ammoType)
        local total = getTotalAmmoCount(weapon, ammoType)
        return tostring(equipped) .. "/" .. tostring(total)
    end
}

local function setHUDAmmmoCount(count)
    E.ammo.layout.props.text = tostring(count or "")
end

local function getAmmoCount()
    local equipment = self.type.getEquipment(self)
    local weapon = equipment[self.type.EQUIPMENT_SLOT.CarriedRight]

    -- no weapon equipped
    if not weapon then
        return nil
    end

    local weaponType = weapon.type.records[weapon.recordId].type
    local ammoType = C.weaponTypeToAmmoType[weaponType]

    -- equipped weapon is not marksman
    if not ammoType then
        return nil
    end

    local ammoCountGetter = hudMode[settingsBehavior:get("hudMode")]
    return ammoCountGetter(weapon, ammoType)
end

local function onFrame(dt)
    E.ammo.layout.props.visible = settingsLooks:get("enabled") and I.UI.isHudVisible()

    updateTime = updateTime + dt
    local checkEvery = settingsBehavior:get('cooldown')

    if updateTime < checkEvery then
        E.ammo:update()
        return
    end

    if checkEvery == 0 then
        updateTime = 0
    else
        while updateTime > checkEvery do
            updateTime = updateTime - checkEvery
        end
    end

    setHUDAmmmoCount(getAmmoCount())
    E.ammo:update()
end

settingsBehavior:subscribe(async:callback(function()
    onFrame(settingsBehavior:get("cooldown"))
end))

return {
    engineHandlers = {
        onFrame = onFrame,
    }
}
