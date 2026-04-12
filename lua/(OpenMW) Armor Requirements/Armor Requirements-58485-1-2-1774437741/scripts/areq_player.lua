local self    = require("openmw.self")
local types   = require("openmw.types")
local ui      = require("openmw.ui")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local I       = require("openmw.interfaces")
local Actor   = types.Actor
local NPC     = types.NPC

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
local settingsDirty = false

local function refreshCache()
    C.MOD_ENABLED         = getFrom(secGeneral, "MOD_ENABLED")
    C.HEAVY_ENABLED       = getFrom(secGeneral, "HEAVY_ENABLED")
    C.MEDIUM_ENABLED      = getFrom(secGeneral, "MEDIUM_ENABLED")
    C.LIGHT_ENABLED       = getFrom(secGeneral, "LIGHT_ENABLED")
    C.BOUND_CHECK_ENABLED = getFrom(secGeneral, "BOUND_CHECK_ENABLED")

    C.HEAVY_T2_RATING = getFrom(secHeavy, "HEAVY_T2_RATING")
    C.HEAVY_T3_RATING = getFrom(secHeavy, "HEAVY_T3_RATING")
    C.HEAVY_T4_RATING = getFrom(secHeavy, "HEAVY_T4_RATING")
    C.HEAVY_T2_SKILL  = getFrom(secHeavy, "HEAVY_T2_SKILL")
    C.HEAVY_T3_SKILL  = getFrom(secHeavy, "HEAVY_T3_SKILL")
    C.HEAVY_T4_SKILL  = getFrom(secHeavy, "HEAVY_T4_SKILL")
    C.HEAVY_T2_ATTR   = getFrom(secHeavy, "HEAVY_T2_ATTR")
    C.HEAVY_T3_ATTR   = getFrom(secHeavy, "HEAVY_T3_ATTR")
    C.HEAVY_T4_ATTR   = getFrom(secHeavy, "HEAVY_T4_ATTR")

    C.MEDIUM_T2_RATING = getFrom(secMedium, "MEDIUM_T2_RATING")
    C.MEDIUM_T3_RATING = getFrom(secMedium, "MEDIUM_T3_RATING")
    C.MEDIUM_T4_RATING = getFrom(secMedium, "MEDIUM_T4_RATING")
    C.MEDIUM_T2_SKILL  = getFrom(secMedium, "MEDIUM_T2_SKILL")
    C.MEDIUM_T3_SKILL  = getFrom(secMedium, "MEDIUM_T3_SKILL")
    C.MEDIUM_T4_SKILL  = getFrom(secMedium, "MEDIUM_T4_SKILL")
    C.MEDIUM_T2_ATTR   = getFrom(secMedium, "MEDIUM_T2_ATTR")
    C.MEDIUM_T3_ATTR   = getFrom(secMedium, "MEDIUM_T3_ATTR")
    C.MEDIUM_T4_ATTR   = getFrom(secMedium, "MEDIUM_T4_ATTR")

    C.LIGHT_T2_RATING = getFrom(secLight, "LIGHT_T2_RATING")
    C.LIGHT_T3_RATING = getFrom(secLight, "LIGHT_T3_RATING")
    C.LIGHT_T4_RATING = getFrom(secLight, "LIGHT_T4_RATING")
    C.LIGHT_T2_SKILL  = getFrom(secLight, "LIGHT_T2_SKILL")
    C.LIGHT_T3_SKILL  = getFrom(secLight, "LIGHT_T3_SKILL")
    C.LIGHT_T4_SKILL  = getFrom(secLight, "LIGHT_T4_SKILL")
    C.LIGHT_T2_ATTR   = getFrom(secLight, "LIGHT_T2_ATTR")
    C.LIGHT_T3_ATTR   = getFrom(secLight, "LIGHT_T3_ATTR")
    C.LIGHT_T4_ATTR   = getFrom(secLight, "LIGHT_T4_ATTR")
end

local function markDirty() settingsDirty = true end
for _, sec in ipairs(ALL_SECTIONS) do
    sec:subscribe(async:callback(markDirty))
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

local function checkArmor(item)
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
    local skill    = NPC.stats.skills[skillId](self.object).modified
    local attrId   = ARMOR_ATTR[skillId]
    local attr     = Actor.stats.attributes[attrId](self.object).modified
    if skill >= minSkill and attr >= minAttr then return end
    self.object:sendEvent('Unequip', { item = item })
    local parts = {}
    if skill < minSkill then
        parts[#parts + 1] = string.format("%s %d/%d",
            SKILL_NAMES[skillId] or skillId, skill, minSkill)
    end
    if attr < minAttr then
        parts[#parts + 1] = string.format("%s %d/%d",
            ATTR_NAMES[attrId] or attrId, attr, minAttr)
    end
    ui.showMessage(string.format('"%s" requires: %s',
        rec.name or item.recordId, table.concat(parts, ", ")))
end

local ARMOR_SLOTS = {
    Actor.EQUIPMENT_SLOT.Helmet,
    Actor.EQUIPMENT_SLOT.Cuirass,
    Actor.EQUIPMENT_SLOT.Greaves,
    Actor.EQUIPMENT_SLOT.Boots,
    Actor.EQUIPMENT_SLOT.LeftPauldron,
    Actor.EQUIPMENT_SLOT.RightPauldron,
    Actor.EQUIPMENT_SLOT.LeftGauntlet,
    Actor.EQUIPMENT_SLOT.RightGauntlet,
    Actor.EQUIPMENT_SLOT.CarriedLeft,
}

local BOUND_EFFECT_SLOTS = {
    BoundHelm    = { Actor.EQUIPMENT_SLOT.Helmet },
    BoundCuirass = { Actor.EQUIPMENT_SLOT.Cuirass },
    BoundGloves  = { Actor.EQUIPMENT_SLOT.LeftGauntlet, Actor.EQUIPMENT_SLOT.RightGauntlet },
    BoundBoots   = { Actor.EQUIPMENT_SLOT.Boots },
    BoundShield  = { Actor.EQUIPMENT_SLOT.CarriedLeft },
}

local function checkBoundArmor()
    if not C.MOD_ENABLED then return end
    local effects = Actor.activeEffects(self.object)
    local eq = nil
    for effectId, slots in pairs(BOUND_EFFECT_SLOTS) do
        local eff = effects:getEffect(effectId)
        if eff and eff.magnitude and eff.magnitude > 0 then
            if not eq then eq = Actor.getEquipment(self.object) end
            for _, slot in ipairs(slots) do
                local item = eq and eq[slot]
                if item and item:isValid() and types.Armor.objectIsInstance(item) then
                    checkArmor(item)
                end
            end
        end
    end
end

local function checkAllArmor()
    if not C.MOD_ENABLED then return end
    local eq = Actor.getEquipment(self.object)
    if not eq then return end
    for _, slot in ipairs(ARMOR_SLOTS) do
        local item = eq[slot]
        if item and item:isValid() and types.Armor.objectIsInstance(item) then
            checkArmor(item)
        end
    end
end

local HOTKEYS = {
    ['1']=true,['2']=true,['3']=true,['4']=true,['5']=true,
    ['6']=true,['7']=true,['8']=true,['9']=true,
}

local boundCheckTimer = 0
local BOUND_CHECK_INTERVAL = 2.0

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
            if not C.BOUND_CHECK_ENABLED then return end
            boundCheckTimer = boundCheckTimer + dt
            if boundCheckTimer < BOUND_CHECK_INTERVAL then return end
            boundCheckTimer = 0
            checkBoundArmor()
        end,
        onKeyPress = function(key)
            if not C.MOD_ENABLED then return end
            if not HOTKEYS[key.symbol] then return end
            checkAllArmor()
        end,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if not C.MOD_ENABLED then return end
            if data.oldMode == "Interface" and data.newMode == nil then
                checkAllArmor()
            end
        end,
    },
}