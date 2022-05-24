local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local storage = require('openmw.storage')
local types = require("openmw.types")
local ui = require("openmw.ui")
local I = require('openmw.interfaces')

local MOD_NAME = "SmartAmmo"
local playerSettings = storage.playerSection("SettingsPlayer" .. MOD_NAME)

local L = core.l10n(MOD_NAME)
local Player = types.Player
local Weapon = types.Weapon

local Arrow = Weapon.TYPE.Arrow
local Bolt = Weapon.TYPE.Bolt
local Bow = Weapon.TYPE.MarksmanBow
local Crossbow = Weapon.TYPE.MarksmanCrossbow
local Thrown = Weapon.TYPE.MarksmanThrown

local ammoSlot = Player.EQUIPMENT_SLOT.Ammunition
local weaponSlot = Player.EQUIPMENT_SLOT.CarriedRight

local currentWpnType
local currentEquipped
local lastAmmo
local currentAmmo
local preferredAmmo = {}

local ammoMap = {
    [Arrow] = Bow,
    [Bow] = Arrow,
    [Bolt] = Crossbow,
    [Crossbow] = Bolt,
    [Thrown] = Thrown
}

I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "Smart Ammo",
    description = "Ammo autoequip while bow/crossbow/thrown weapon readied."
}

I.Settings.registerGroup {
    key = "SettingsPlayer" .. MOD_NAME,
    l10n = MOD_NAME,
    name = "Smart Ammo",
    page = MOD_NAME,
    description = "Mod options",
    permanentStorage = false,
    settings = {
        {
            key = "showMessages",
            name = "Show Messages",
            default = true,
            renderer = "checkbox"
        }
    }
}

local function equippedType()
    local weapon = Player.equipment(self, weaponSlot)
    if not weapon then return end
    if weapon.type == Weapon then
        local record = Weapon.record(weapon)
        if ammoMap[record.type] then
            return record.type
        end
    end
end

local function equipMsg(ammoRec, setPref)
    if not playerSettings:get("showMessages") then return end

    if ammoRec.type == Arrow then
        if setPref then
            ui.showMessage(string.format(L("preferredBow", {name = ammoRec.name})))
        else
            ui.showMessage(string.format(L("setBow", {name = ammoRec.name})))
        end
    elseif ammoRec.type == Bolt then
        if setPref then
            ui.showMessage(string.format(L("preferredCrossbow", {name = ammoRec.name})))
        else
            ui.showMessage(string.format(L("setCrossbow", {name = ammoRec.name})))
        end
    elseif ammoRec.type == Thrown then
        ui.showMessage(string.format(L("setThrown", {name = ammoRec.name})))
    end
end

local function setPreferred(ammo)
    local ammoType = Weapon.record(ammo).type
    local kind = ammoMap[ammoType]

    if preferredAmmo[kind] == ammo then return end

    if kind == Bow and ammoType == Arrow
        or kind == Crossbow and ammoType == Bolt then
        preferredAmmo[kind] = ammo
        local rec = Weapon.record(ammo)
        equipMsg(rec, true)
    end
end

local function equip(slot, thing)
    local equipped = Player.equipment(self)
    equipped[slot] = thing
    Player.setEquipment(self, equipped)
    equipMsg(Weapon.record(thing))
end

local function getAmmoForWeapon(kind)
    for _, wpn in ipairs(Player.inventory(self):getAll(Weapon)) do
        local wpnType = Weapon.record(wpn).type
        if kind == Bow and wpnType == Arrow then
            return wpn
        elseif kind == Crossbow and wpnType == Bolt then
            return wpn
        elseif kind == Thrown and wpnType == Thrown then
            return wpn
        end
    end
end

local function checkAmmo(wpn, ammo)
    local wpnType = Weapon.record(wpn).type
    local ammoType = Weapon.record(ammo).type
    if wpnType == Bow and ammoType == Arrow then
        return true
    elseif wpnType == Crossbow and ammoType == Bolt then
        return true
    end
    return false
end

local function onFrame()
    lastAmmo = currentAmmo
    currentAmmo =  Player.equipment(self, ammoSlot)
    if input.isAltPressed() then
        if lastAmmo == nil and currentAmmo ~= nil then
            setPreferred(currentAmmo)
        end
    end
end

local function onLoad(data)
    preferredAmmo = data.preferredAmmo
end

local function onSave()
    return {
        preferredAmmo = preferredAmmo
    }
end

local function onUpdate()
    local ammo =  Player.equipment(self, ammoSlot)
    local lastType = currentWpnType
    currentEquipped = Player.equipment(self, weaponSlot)
    currentWpnType = equippedType()

    if currentEquipped ~= nil then
        if currentWpnType == Thrown then return end

        local wantAmmo = preferredAmmo[currentWpnType]
        if wantAmmo ~= nil and ammo ~= wantAmmo then
            equip(ammoSlot, wantAmmo)
            preferredAmmo[currentWpnType] = nil
            return
        elseif ammo == nil then
            local toUse = getAmmoForWeapon(currentWpnType)
            if toUse ~= nil then
                equip(ammoSlot, toUse)
            end
            return
        elseif ammo ~= nil then
            if checkAmmo(currentEquipped, ammo) == false then
                local toUse = getAmmoForWeapon(currentWpnType)
                if toUse ~= nil then
                    equip(ammoSlot, toUse)
                end
            end
        end
    end

    if currentEquipped == nil and lastType == Thrown then
        local toUse = getAmmoForWeapon(Thrown)
        if toUse ~= nil then
            equip(weaponSlot, toUse)
        end
    end
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    }
}
