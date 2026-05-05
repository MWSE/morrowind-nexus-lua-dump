-- Shows armor requirement info near the crosshair when looking at armor the player does NOT meet the requirements for
-- Uses SharedRay_v1

local selfObj  = require("openmw.self")
local types    = require("openmw.types")
local ui       = require("openmw.ui")
local util     = require("openmw.util")
local storage  = require("openmw.storage")
local async    = require("openmw.async")
local I        = require("openmw.interfaces")
local Actor    = types.Actor
local NPC      = types.NPC

local shared       = require("scripts.areq_shared")
local DEFAULTS     = shared.DEFAULTS
local EXCLUDED_IDS = shared.EXCLUDED_IDS
local SKILL_NAMES  = shared.SKILL_NAMES
local ATTR_NAMES   = shared.ATTR_NAMES
local ARMOR_ATTR   = shared.ARMOR_ATTR


local secGeneral = storage.playerSection("SettingsAReq")
local secHeavy   = storage.playerSection("SettingsAReqHeavy")
local secMedium  = storage.playerSection("SettingsAReqMedium")
local secLight   = storage.playerSection("SettingsAReqLight")
local ALL_SECTIONS = { secGeneral, secHeavy, secMedium, secLight }

local function getFrom(sec, key)
    local val = sec:get(key)
    if val ~= nil then return val end
    return DEFAULTS[key]
end

local C = {}

local function refreshCache()
    C.MOD_ENABLED         = getFrom(secGeneral, "MOD_ENABLED")
    C.TOOLTIP_ENABLED     = getFrom(secGeneral, "TOOLTIP_ENABLED")
    C.HEAVY_ENABLED       = getFrom(secGeneral, "HEAVY_ENABLED")
    C.MEDIUM_ENABLED      = getFrom(secGeneral, "MEDIUM_ENABLED")
    C.LIGHT_ENABLED       = getFrom(secGeneral, "LIGHT_ENABLED")
    C.BOUND_CHECK_ENABLED = getFrom(secGeneral, "BOUND_CHECK_ENABLED")

    for _, prefix in ipairs({"HEAVY", "MEDIUM", "LIGHT"}) do
        local sec = prefix == "HEAVY" and secHeavy
                 or prefix == "MEDIUM" and secMedium
                 or secLight
        for _, t in ipairs({"T2", "T3", "T4"}) do
            C[prefix.."_"..t.."_RATING"] = getFrom(sec, prefix.."_"..t.."_RATING")
            C[prefix.."_"..t.."_SKILL"]  = getFrom(sec, prefix.."_"..t.."_SKILL")
            C[prefix.."_"..t.."_ATTR"]   = getFrom(sec, prefix.."_"..t.."_ATTR")
        end
    end
end

for _, sec in ipairs(ALL_SECTIONS) do
    sec:subscribe(async:callback(refreshCache))
end

local function getClassPrefix(skillId)
    if skillId == "heavyarmor"      then return "HEAVY"
    elseif skillId == "mediumarmor" then return "MEDIUM"
    elseif skillId == "lightarmor"  then return "LIGHT"
    end
end

local function isClassEnabled(skillId)
    if skillId == "heavyarmor"      then return C.HEAVY_ENABLED
    elseif skillId == "mediumarmor" then return C.MEDIUM_ENABLED
    elseif skillId == "lightarmor"  then return C.LIGHT_ENABLED
    end
    return false
end

local function getTier(rating, prefix)
    local t2 = C[prefix .. "_T2_RATING"]
    local t3 = C[prefix .. "_T3_RATING"]
    local t4 = C[prefix .. "_T4_RATING"]
    if not t2 then return 1 end
    if rating >= t4 then return 4 end
    if rating >= t3 then return 3 end
    if rating >= t2 then return 2 end
    return 1
end

local function getFailedRequirements(item)
    if not types.Armor.objectIsInstance(item) then return end
    if EXCLUDED_IDS[item.recordId:lower()] then return end
    if not C.BOUND_CHECK_ENABLED and item.recordId:find("^bound_") then return end

    local skillId = I.Combat.getArmorSkill(item)
    if not skillId or skillId == "unarmored" then return end
    if not isClassEnabled(skillId) then return end

    local prefix = getClassPrefix(skillId)
    if not prefix then return end

    local rec = types.Armor.record(item)
    if not rec then return end

    local tier = getTier(rec.baseArmor or 0, prefix)
    if tier <= 1 then return end

    local minSkill = C[prefix .. "_T" .. tier .. "_SKILL"] or 0
    local minAttr  = C[prefix .. "_T" .. tier .. "_ATTR"]  or 0
    local skill    = NPC.stats.skills[skillId](selfObj.object).modified
    local attrId   = ARMOR_ATTR[skillId]
    local attr     = Actor.stats.attributes[attrId](selfObj.object).modified

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
local PAD_V     = 6   -- vertical padding top/bottom

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

    -- top padding
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

    -- bottom padding
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

    if not obj or not obj:isValid() or not types.Armor.objectIsInstance(obj) then
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