-- Shows weapon requirement info near the crosshair when looking at a weapon the player does NOT meet the requirements for.
-- Uses SharedRay_v1.lua

local selfObj  = require("openmw.self")
local types    = require("openmw.types")
local ui       = require("openmw.ui")
local util     = require("openmw.util")
local storage  = require("openmw.storage")
local async    = require("openmw.async")
local I        = require("openmw.interfaces")
local Actor    = types.Actor
local NPC      = types.NPC
local Weapon   = types.Weapon

local shared        = require("scripts.wreq_shared")
local data          = require("scripts.wreq_data")
local WEAPON_SKILL  = data.WEAPON_SKILL
local WEAPON_ATTR   = data.WEAPON_ATTR
local WEAPON_DMG    = data.WEAPON_DAMAGE_FORMULA
local WEAPON_TGRP   = data.WEAPON_TIER_GROUP
local IGNORED       = data.IGNORED_TYPES
local IGNORED_IDS   = shared.IGNORED_IDS
local SKILL_NAMES   = shared.SKILL_NAMES
local ATTR_NAMES    = shared.ATTR_NAMES
local DEFAULTS      = shared.DEFAULTS

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

local function refreshCache()
    C.MOD_ENABLED     = getFrom(secGeneral, "MOD_ENABLED")
    C.TOOLTIP_ENABLED = getFrom(secGeneral, "TOOLTIP_ENABLED")

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

    C.T1_SKILL = getFrom(secReqs, "T1_SKILL")
    C.T2_SKILL = getFrom(secReqs, "T2_SKILL")
    C.T3_SKILL = getFrom(secReqs, "T3_SKILL")
    C.T4_SKILL = getFrom(secReqs, "T4_SKILL")
    C.T1_ATTR  = getFrom(secReqs, "T1_ATTR")
    C.T2_ATTR  = getFrom(secReqs, "T2_ATTR")
    C.T3_ATTR  = getFrom(secReqs, "T3_ATTR")
    C.T4_ATTR  = getFrom(secReqs, "T4_ATTR")
end

for _, sec in ipairs(ALL_SECTIONS) do
    sec:subscribe(async:callback(refreshCache))
end

local function getAvgDamage(rec, formula)
    if formula == "chop" then
        return (rec.chopMinDamage + rec.chopMaxDamage) / 2
    elseif formula == "slash" then
        return (rec.slashMinDamage + rec.slashMaxDamage) / 2
    elseif formula == "thrust" then
        return (rec.thrustMinDamage + rec.thrustMaxDamage) / 2
    else
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

--- Returns nil if checks pass. Otherwise { lines = { {label,cur,req,met} } }
local function getFailedRequirements(item)
    if not Weapon.objectIsInstance(item) then return end

    local rec        = Weapon.record(item)
    local weaponType = rec.type
    if IGNORED[weaponType] then return end
    if IGNORED_IDS[item.recordId:lower()] then return end

    local skillId = WEAPON_SKILL[weaponType]
    local attrId  = WEAPON_ATTR[weaponType]
    local formula = WEAPON_DMG[weaponType]
    local group   = WEAPON_TGRP[weaponType]
    if not skillId then return end

    local tier     = getTier(getAvgDamage(rec, formula), group)
    local minSkill = C["T" .. tier .. "_SKILL"]
    local minAttr  = C["T" .. tier .. "_ATTR"]

    local skill = NPC.stats.skills[skillId](selfObj.object).modified
    local attr  = Actor.stats.attributes[attrId](selfObj.object).modified

    if skill >= minSkill and attr >= minAttr then return end

    local lines = {}
    lines[#lines + 1] = {
        label = SKILL_NAMES[skillId] or skillId,
        cur   = skill,
        req   = minSkill,
        met   = skill >= minSkill,
    }
    lines[#lines + 1] = {
        label = ATTR_NAMES[attrId] or attrId,
        cur   = attr,
        req   = minAttr,
        met   = attr >= minAttr,
    }
    return { lines = lines }
end

local COLOR_MET  = util.color.rgb(0.65, 0.85, 0.45)
local COLOR_FAIL = util.color.rgb(0.90, 0.25, 0.20)

local FONT_SIZE = 16
local PAD_V     = 6

local element = nil
local lastObjId = nil

local function destroyWidget()
    if element then
        element:destroy()
        element = nil
    end
    lastObjId = nil
end

local function buildWidget(info)
    local rows = {}

    rows[#rows + 1] = { props = { size = util.vector2(0, PAD_V) } }

    for _, line in ipairs(info.lines) do
        local color = line.met and COLOR_MET or COLOR_FAIL
        local mark  = line.met and "" or "  !"
        rows[#rows + 1] = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text       = string.format("  %s  %d / %d%s  ", line.label, line.cur, line.req, mark),
                textSize   = FONT_SIZE,
                textColor  = color,
                textAlignH = ui.ALIGNMENT.Center,
            },
        }
    end

    rows[#rows + 1] = { props = { size = util.vector2(0, PAD_V) } }

    element = ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor           = util.vector2(0.5, 0),
            position         = util.vector2(0, 24),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(rows),
            },
        },
    }
end

local CHECK_INTERVAL = 0.2
local timer = 0

local function onFrame(dt)
    if not C.MOD_ENABLED or not C.TOOLTIP_ENABLED then
        destroyWidget()
        return
    end

    timer = timer + dt
    if timer < CHECK_INTERVAL then return end
    timer = 0

    if not I.SharedRay then
        destroyWidget()
        return
    end

    if I.UI.getMode() ~= nil then
        destroyWidget()
        return
    end

    local ray = I.SharedRay.get()
    local obj = ray and ray.hitObject

    if not obj or not obj:isValid() or not Weapon.objectIsInstance(obj) then
        destroyWidget()
        return
    end

    if obj.id == lastObjId then return end

    destroyWidget()

    local info = getFailedRequirements(obj)
    if not info then return end

    lastObjId = obj.id
    buildWidget(info)
end

return {
    engineHandlers = {
        onInit  = function() refreshCache() end,
        onLoad  = function() refreshCache() end,
        onFrame = onFrame,
    },
}