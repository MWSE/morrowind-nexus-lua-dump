-- main.lua
------------------------------------------------------------
-- Custom Staff List (frei erweiterbar)
-- IDs bitte in Kleinbuchstaben eintragen!
------------------------------------------------------------
local customStaffs = {
    ["t_dae_uni_wabbajack"]     = true,
    ["t_cr_uni_agenchegel"]     = true,
    ["t_de_uni_staffveloth"]    = true,
    ["t_com_uni_typossophia"]   = true,
    -- ["unique_superstaff_01"] = true,
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function round(v)
    return math.floor(v + 0.5)
end

------------------------------------------------------------
-- Staff detection (unabhängig von Waffengattung)
------------------------------------------------------------
local function isStaff(item)
    if not item or not item.id then return false end
    local id = item.id:lower()

    -- 1) Custom-Liste
    if customStaffs[id] then
        return true
    end

    -- 2) ID-Suche nach Keywords (staff / scepter / sceptre) 
    if id:find("staff") or id:find("scepter") or id:find("stick") or id:find("sceptre") then
        return true
    end

    return false
end

------------------------------------------------------------
-- Multiplier based ONLY on gold value
------------------------------------------------------------
local function staffMultiplier(item)
    if not isStaff(item) then
        return 1, false
    end

    local value = item.value or 0
    local mult = 1

    if     value < 50     then mult = 1.1
    elseif value < 500    then mult = 1.2
    elseif value < 1000   then mult = 1.3
    elseif value < 2500   then mult = 1.3
    elseif value < 5000   then mult = 1.4
    elseif value < 7500   then mult = 1.4
    elseif value < 10000  then mult = 1.5
    elseif value < 25000  then mult = 1.6
    elseif value < 50000  then mult = 1.7
    elseif value < 75000  then mult = 1.8
    elseif value < 100000 then mult = 1.9
    else                     mult = 2
    end

    return mult, true
end

------------------------------------------------------------
-- Actual casting effect (real gameplay) + Debug-Logging
------------------------------------------------------------
local function staffCasting(e)
    if e.caster ~= tes3.player then return end

    local equipped = tes3.getEquippedItem{ actor = tes3.player, objectType = tes3.objectType.weapon }
    if not equipped or not equipped.object then
        -- kein Werkzeug ausgerüstet; nichts tun
        return
    end

    local weapon = equipped.object
    local mult, isStaffWeapon = staffMultiplier(weapon)
    local baseChance = e.castChance or 0

    -- Debugausgabe
    mwse.log("[StaffCasting] Casting spell. Weapon=%s isStaff=%s baseChance=%s mult=%.2f",
        tostring(weapon.id), tostring(isStaffWeapon), tostring(baseChance), mult)

    if isStaffWeapon then
        local newChance = clamp(baseChance * mult, 0, 100)
        mwse.log("[StaffCasting] New cast chance: %s", tostring(newChance))
        e.castChance = newChance
    end
end

------------------------------------------------------------
-- Tooltip (bleibt erhalten)
------------------------------------------------------------
local function staffTooltip(e)
    local mult, isStaffWeapon = staffMultiplier(e.object)
    if not isStaffWeapon then return end

    local text = string.format("Cast Chance Multiplier: x%.2f", mult)
    local block = e.tooltip:createBlock()
    block.paddingAllSides = 6
    block.autoHeight = true
    block.autoWidth = true
    block:createLabel { text = text }
end

------------------------------------------------------------
-- Init (nur Gameplay + Tooltip)
------------------------------------------------------------
event.register("initialized", function()
    event.register("spellCast", staffCasting)
    event.register("uiObjectTooltip", staffTooltip)

    mwse.log("Staff Casting (equipped-based, custom IDs included) : initialized")
end)
