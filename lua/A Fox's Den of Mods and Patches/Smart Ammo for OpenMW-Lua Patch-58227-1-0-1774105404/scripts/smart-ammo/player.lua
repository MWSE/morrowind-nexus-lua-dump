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

local preferredAmmo = {}
 
local prevWeapon   = nil  -- weapon object last frame
local prevAmmo     = nil  -- ammo object last frame
local prevWpnType  = nil  -- weapon type last frame (nil = unarmed/H2H)

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

local function getWeaponType(weapon)
    if not weapon then return nil end
    if types.Lockpick.objectIsInstance(weapon)
    or types.Probe.objectIsInstance(weapon) then return nil end
    local t = Weapon.record(weapon).type
    return ammoMap[t] and t or nil
end

local function equipMsg(ammoRec, setPref)
    if not playerSettings:get("showMessages") then return end
    local t = ammoRec.type
    if t == Arrow then
        ui.showMessage(string.format(L(setPref and "preferredBow" or "setBow", { name = ammoRec.name })))
    elseif t == Bolt then
        ui.showMessage(string.format(L(setPref and "preferredCrossbow" or "setCrossbow", { name = ammoRec.name })))
    elseif t == Thrown then
        ui.showMessage(string.format(L("setThrown", { name = ammoRec.name })))
    end
end

local function doEquip(eq, slot, item)
    eq[slot] = item
    Player.setEquipment(self, eq)
    equipMsg(Weapon.record(item), false)
end

local function findAmmoForWeapon(wpnType)
    for _, wpn in ipairs(Player.inventory(self):getAll(Weapon)) do
        local t = Weapon.record(wpn).type
        if (wpnType == Bow      and t == Arrow)
        or (wpnType == Crossbow and t == Bolt)
        or (wpnType == Thrown   and t == Thrown) then
            return wpn
        end
    end
end

local function isInInventory(item)
    for _, wpn in ipairs(Player.inventory(self):getAll(Weapon)) do
        if wpn == item then return true end
    end
    return false
end

local function onUpdate()
    local eq      = Player.equipment(self)
    local weapon  = eq[weaponSlot]
    local ammo    = eq[ammoSlot]
    local wpnType = getWeaponType(weapon)
 
    -- Alt+equip: set preferred ammo
    if input.isAltPressed() then
        if prevAmmo == nil and ammo ~= nil then
            local ammoType = Weapon.record(ammo).type
            local kind     = ammoMap[ammoType]
            if kind and preferredAmmo[kind] ~= ammo
            and (kind == Bow or kind == Crossbow) then
                preferredAmmo[kind] = ammo
                equipMsg(Weapon.record(ammo), true)
            end
        end
    end
 
    if weapon == prevWeapon and ammo == prevAmmo then
        prevWeapon  = weapon
        prevAmmo    = ammo
        prevWpnType = wpnType
        return
    end

    if wpnType == nil and prevWpnType == Thrown and prevWeapon ~= nil then
        if not isInInventory(prevWeapon) then
            local toUse = findAmmoForWeapon(Thrown)
            if toUse then doEquip(eq, weaponSlot, toUse) end
        end
        -- If player deliberately unequipped (item still in inventory): do nothing
        prevWeapon  = weapon
        prevAmmo    = ammo
        prevWpnType = wpnType
        return
    end
 
    if weapon ~= nil and (wpnType == Bow or wpnType == Crossbow) then
        local wantAmmo = preferredAmmo[wpnType]
        if wantAmmo ~= nil and ammo ~= wantAmmo then
            doEquip(eq, ammoSlot, wantAmmo)
            preferredAmmo[wpnType] = nil
        elseif ammo == nil then
            local toUse = findAmmoForWeapon(wpnType)
            if toUse then doEquip(eq, ammoSlot, toUse) end
        else
            -- Wrong ammo type in slot (e.g. arrows with crossbow)
            local ammoType = Weapon.record(ammo).type
            local correct  = (wpnType == Bow and ammoType == Arrow)
                          or (wpnType == Crossbow and ammoType == Bolt)
            if not correct then
                local toUse = findAmmoForWeapon(wpnType)
                if toUse then doEquip(eq, ammoSlot, toUse) end
            end
        end
    end
 
    prevWeapon  = weapon
    prevAmmo    = ammo
    prevWpnType = wpnType
end
 
return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad   = function(data)
            if data then preferredAmmo = data.preferredAmmo or {} end
        end,
        onSave   = function()
            return { preferredAmmo = preferredAmmo }
        end,
    },
}
