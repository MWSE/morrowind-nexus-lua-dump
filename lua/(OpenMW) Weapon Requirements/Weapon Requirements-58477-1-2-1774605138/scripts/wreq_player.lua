local self    = require("openmw.self")
local types   = require("openmw.types")
local ui      = require("openmw.ui")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local core    = require("openmw.core")
local Actor   = types.Actor
local NPC     = types.NPC
local Weapon  = types.Weapon

local shared        = require("scripts.wreq_shared")
local data          = require("scripts.wreq_data")
local WEAPON_SKILL  = data.WEAPON_SKILL
local WEAPON_ATTR   = data.WEAPON_ATTR
local WEAPON_DMG    = data.WEAPON_DAMAGE_FORMULA
local WEAPON_TGRP   = data.WEAPON_TIER_GROUP
local IGNORED       = data.IGNORED_TYPES
local ATTR_NAMES    = shared.ATTR_NAMES
local SKILL_NAMES   = shared.SKILL_NAMES
local DEFAULTS      = shared.DEFAULTS
local IGNORED_IDS   = shared.IGNORED_IDS

local slotCheckTimer      = 0
local SLOT_CHECK_INTERVAL = 0.5

local secGeneral = storage.playerSection("SettingsWReq")
local secReqs    = storage.playerSection("SettingsWReqReqs")
local secAxe1h   = storage.playerSection("SettingsWReqAxe1h")
local secAxe2h   = storage.playerSection("SettingsWReqAxe2h")
local secMace    = storage.playerSection("SettingsWReqMace")
local secHammer  = storage.playerSection("SettingsWReqHammer")
local secStaff   = storage.playerSection("SettingsWReqStaff")
local secBlade1h = storage.playerSection("SettingsWReqBlade1h")
local secBlade2h = storage.playerSection("SettingsWReqBlade2h")
local secShort   = storage.playerSection("SettingsWReqShort")
local secSpear   = storage.playerSection("SettingsWReqSpear")
local secBow     = storage.playerSection("SettingsWReqBow")
local secXbow    = storage.playerSection("SettingsWReqXbow")
local secThrown  = storage.playerSection("SettingsWReqThrown")

local ALL_SECTIONS = {
    secGeneral, secReqs, secAxe1h, secAxe2h, secMace, secHammer, secStaff,
    secBlade1h, secBlade2h, secShort, secSpear, secBow, secXbow, secThrown,
}

local function getFrom(sec, key)
    local val = sec:get(key)
    if val ~= nil then return val end
    return DEFAULTS[key]
end

local C = {}
local settingsDirty = false

local function refreshCache()
    C.MOD_ENABLED = getFrom(secGeneral, "MOD_ENABLED")

    C.AXE1H_T2  = getFrom(secAxe1h,   "AXE1H_T2_DMG")
    C.AXE1H_T3  = getFrom(secAxe1h,   "AXE1H_T3_DMG")
    C.AXE1H_T4  = getFrom(secAxe1h,   "AXE1H_T4_DMG")
    C.AXE2H_T2  = getFrom(secAxe2h,   "AXE2H_T2_DMG")
    C.AXE2H_T3  = getFrom(secAxe2h,   "AXE2H_T3_DMG")
    C.AXE2H_T4  = getFrom(secAxe2h,   "AXE2H_T4_DMG")
    C.MACE_T2   = getFrom(secMace,    "MACE_T2_DMG")
    C.MACE_T3   = getFrom(secMace,    "MACE_T3_DMG")
    C.MACE_T4   = 999
    C.HAMMER_T2 = getFrom(secHammer,  "HAMMER_T2_DMG")
    C.HAMMER_T3 = getFrom(secHammer,  "HAMMER_T3_DMG")
    C.HAMMER_T4 = 999
    C.STAFF_T2  = getFrom(secStaff,   "STAFF_T2_DMG")
    C.STAFF_T3  = getFrom(secStaff,   "STAFF_T3_DMG")
    C.STAFF_T4  = 999
    C.B1H_T2    = getFrom(secBlade1h, "BLADE1H_T2_DMG")
    C.B1H_T3    = getFrom(secBlade1h, "BLADE1H_T3_DMG")
    C.B1H_T4    = 999
    C.B2H_T2    = getFrom(secBlade2h, "BLADE2H_T2_DMG")
    C.B2H_T3    = getFrom(secBlade2h, "BLADE2H_T3_DMG")
    C.B2H_T4    = getFrom(secBlade2h, "BLADE2H_T4_DMG")
    C.SHORT_T2  = getFrom(secShort,   "SHORT_T2_DMG")
    C.SHORT_T3  = getFrom(secShort,   "SHORT_T3_DMG")
    C.SHORT_T4  = 999
    C.SPEAR_T2  = getFrom(secSpear,   "SPEAR_T2_DMG")
    C.SPEAR_T3  = getFrom(secSpear,   "SPEAR_T3_DMG")
    C.SPEAR_T4  = 999
    C.BOW_T2    = getFrom(secBow,     "BOW_T2_DMG")
    C.BOW_T3    = getFrom(secBow,     "BOW_T3_DMG")
    C.BOW_T4    = getFrom(secBow,     "BOW_T4_DMG")
    C.XBOW_T2   = getFrom(secXbow,    "XBOW_T2_DMG")
    C.XBOW_T3   = getFrom(secXbow,    "XBOW_T3_DMG")
    C.XBOW_T4   = getFrom(secXbow,    "XBOW_T4_DMG")
    C.THROWN_T2 = getFrom(secThrown,  "THROWN_T2_DMG")
    C.THROWN_T3 = getFrom(secThrown,  "THROWN_T3_DMG")
    C.THROWN_T4 = 999

    C.T1_SKILL  = getFrom(secReqs, "T1_SKILL")
    C.T2_SKILL  = getFrom(secReqs, "T2_SKILL")
    C.T3_SKILL  = getFrom(secReqs, "T3_SKILL")
    C.T4_SKILL  = getFrom(secReqs, "T4_SKILL")
    C.T1_ATTR   = getFrom(secReqs, "T1_ATTR")
    C.T2_ATTR   = getFrom(secReqs, "T2_ATTR")
    C.T3_ATTR   = getFrom(secReqs, "T3_ATTR")
    C.T4_ATTR   = getFrom(secReqs, "T4_ATTR")
end

local function markDirty() settingsDirty = true end
for _, sec in ipairs(ALL_SECTIONS) do
    sec:subscribe(async:callback(markDirty))
end

local function getAvgDamage(rec, formula)
    if formula == "chop" then
        return (rec.chopMinDamage + rec.chopMaxDamage) / 2
    elseif formula == "slash" then
        return (rec.slashMinDamage + rec.slashMaxDamage) / 2
    elseif formula == "thrust" then
        return (rec.thrustMinDamage + rec.thrustMaxDamage) / 2
    else -- "max"
        local c = (rec.chopMinDamage   + rec.chopMaxDamage)   / 2
        local s = (rec.slashMinDamage  + rec.slashMaxDamage)  / 2
        local t = (rec.thrustMinDamage + rec.thrustMaxDamage) / 2
        return math.max(c, s, t)
    end
end

local function getTier(dmg, group)
    local t2, t3, t4
    if group == "axe1h"       then t2,t3,t4 = C.AXE1H_T2, C.AXE1H_T3, C.AXE1H_T4
    elseif group == "axe2h"   then t2,t3,t4 = C.AXE2H_T2, C.AXE2H_T3, C.AXE2H_T4
    elseif group == "mace"    then t2,t3,t4 = C.MACE_T2,   C.MACE_T3,  C.MACE_T4
    elseif group == "hammer"  then t2,t3,t4 = C.HAMMER_T2, C.HAMMER_T3,C.HAMMER_T4
    elseif group == "staff"   then t2,t3,t4 = C.STAFF_T2,  C.STAFF_T3, C.STAFF_T4
    elseif group == "blade1h" then t2,t3,t4 = C.B1H_T2,    C.B1H_T3,   C.B1H_T4
    elseif group == "blade2h" then t2,t3,t4 = C.B2H_T2,    C.B2H_T3,   C.B2H_T4
    elseif group == "shortblade" then t2,t3,t4 = C.SHORT_T2,C.SHORT_T3,C.SHORT_T4
    elseif group == "spear"   then t2,t3,t4 = C.SPEAR_T2,  C.SPEAR_T3, C.SPEAR_T4
    elseif group == "bow"     then t2,t3,t4 = C.BOW_T2,    C.BOW_T3,   C.BOW_T4
    elseif group == "crossbow"then t2,t3,t4 = C.XBOW_T2,   C.XBOW_T3,  C.XBOW_T4
    elseif group == "thrown"  then t2,t3,t4 = C.THROWN_T2, C.THROWN_T3,C.THROWN_T4
    else return 1
    end
    if dmg >= t4 then return 4 end
    if dmg >= t3 then return 3 end
    if dmg >= t2 then return 2 end
    return 1
end

local function checkEquippedWeapon()
    if not C.MOD_ENABLED then return end

    local eq = Actor.getEquipment(self.object)
    if not eq then return end
    local weapon = eq[Actor.EQUIPMENT_SLOT.CarriedRight]
    if not weapon or not weapon:isValid() then return end
    if not Weapon.objectIsInstance(weapon) then return end

    local rec        = Weapon.record(weapon)
    local weaponType = rec.type
    if IGNORED[weaponType] then return end
    if IGNORED_IDS[weapon.recordId:lower()] then return end

    local skillId = WEAPON_SKILL[weaponType]
    local attrId  = WEAPON_ATTR[weaponType]
    local formula = WEAPON_DMG[weaponType]
    local group   = WEAPON_TGRP[weaponType]
    if not skillId then return end

    local tier     = getTier(getAvgDamage(rec, formula), group)
    local minSkill = C["T" .. tier .. "_SKILL"]
    local minAttr  = C["T" .. tier .. "_ATTR"]

    local playerSkill = NPC.stats.skills[skillId](self.object).modified
    local playerAttr  = Actor.stats.attributes[attrId](self.object).modified

    local skillOk = playerSkill >= minSkill
    local attrOk  = playerAttr  >= minAttr
    if skillOk and attrOk then return end

    if core.API_REVISION > 76 then
        self.object:sendEvent('Unequip', { item = weapon })
    else
        local eq = Actor.getEquipment(self.object)
        eq[Actor.EQUIPMENT_SLOT.CarriedRight] = nil
        Actor.setEquipment(self, eq)
    end

    local reasons = {}
    if not skillOk then
        reasons[#reasons + 1] = string.format("%s %d/%d",
            SKILL_NAMES[skillId] or skillId, playerSkill, minSkill)
    end
    if not attrOk then
        reasons[#reasons + 1] = string.format("%s %d/%d",
            ATTR_NAMES[attrId] or attrId, playerAttr, minAttr)
    end
    ui.showMessage(string.format('"%s" requires: %s',
        rec.name or weapon.recordId, table.concat(reasons, ", ")))
end

local lastWeaponId = nil

return {
    engineHandlers = {
        onInit  = function() refreshCache() end,
        onLoad  = function() refreshCache() end,
        onFrame = function(dt)
            if settingsDirty then
                settingsDirty = false
                refreshCache()
            end
            if not C.MOD_ENABLED then return end
            slotCheckTimer = slotCheckTimer + dt
            if slotCheckTimer < SLOT_CHECK_INTERVAL then return end
            slotCheckTimer = 0
            local eq = Actor.getEquipment(self.object)
            if not eq then return end
            local weapon = eq[Actor.EQUIPMENT_SLOT.CarriedRight]
            local weaponId = weapon and weapon:isValid() and weapon.id or nil
            if weaponId == lastWeaponId then return end
            lastWeaponId = weaponId
            if not weapon or not weapon:isValid() then return end
            if not Weapon.objectIsInstance(weapon) then return end
            checkEquippedWeapon()
        end,
    },
}