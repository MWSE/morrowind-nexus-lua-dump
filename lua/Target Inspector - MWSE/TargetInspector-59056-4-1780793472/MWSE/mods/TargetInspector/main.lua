local modName = "Target Inspector"

local configModule = require("TargetInspector.config")
local config = configModule.current

require("TargetInspector.mcm")

local inspectorKeyHeld = false
local currentTarget    = nil

local UI_ID_InspectorMenu = tes3ui.registerID("TargetInspector:Menu")

local inspectorWidth  = 620
local inspectorHeight = 720
local leftColWidth    = 330
local rightColWidth   = 270

local currentLineWidth = leftColWidth - 16

local CREATURE_TYPE_NAMES = {
    [0] = "Creature",
    [1] = "Daedra",
    [2] = "Undead",
    [3] = "Humanoid",
}

local COLOR_HEADER = { 1.0, 0.85, 0.35 }
local COLOR_VALUE  = { 0.9, 0.9,  0.9  }
local COLOR_DIM    = { 0.6, 0.6,  0.6  }

--==================
-- HELPERS
--==================

local function debugLog(message)
    if not config.debug then return end
    mwse.log("[Target Inspector] %s", tostring(message))
end

local function safeGet(object, key)
    if not object then return nil end
    local ok, value = pcall(function() return object[key] end)
    if ok then return value end
    return nil
end

local function getStatisticCurrent(stat)
    if not stat then return 0 end
    return safeGet(stat, "current") or safeGet(stat, "value") or safeGet(stat, "base") or 0
end

local function getStatisticBase(stat)
    if not stat then return 0 end
    return safeGet(stat, "base") or safeGet(stat, "current") or safeGet(stat, "value") or 0
end

local function getReference(e)
    if e and e.reference then return e.reference end
    return tes3.getPlayerTarget()
end

local function getMobile(reference)
    if not reference then return nil end
    if reference == tes3.player then return tes3.mobilePlayer end
    return reference.mobile
end

local function getObjectTypeName(reference)
    if not reference or not reference.object then return "Unknown" end
    local objectType = reference.object.objectType
    if objectType == tes3.objectType.npc then
        return "NPC"
    end
    if objectType == tes3.objectType.creature then
        local creatureType = safeGet(reference.object, "type")
        local typeName = CREATURE_TYPE_NAMES[creatureType] or tostring(creatureType or "Unknown")
        return "Creature: " .. typeName
    end
    return tostring(objectType)
end

local function getDisposition(reference, mobile, objectType)
    if objectType ~= tes3.objectType.npc then return nil end
    local d = safeGet(mobile, "disposition")
    if d ~= nil then return d end
    return safeGet(reference.object, "baseDisposition")
end

--==================
-- UI HELPERS
--==================

local function destroyInspector()
    local menu = tes3ui.findMenu(UI_ID_InspectorMenu)
    if menu then menu:destroy() end
    currentTarget = nil
end

local function addLine(parent, text, color)
    local label = parent:createLabel({ text = text })
    label.wrapText = true
    label.width = currentLineWidth
    if color then label.color = color end
    return label
end

local function addHeader(parent, text)
    local spacer = parent:createLabel({ text = "" })
    spacer.height = 5
    return addLine(parent, text, COLOR_HEADER)
end

local function addValue(parent, text)
    return addLine(parent, text, COLOR_VALUE)
end

local function addCenteredLabel(menu, text, color)
    local block = menu:createBlock({})
    block.width        = inspectorWidth - 28
    block.autoHeight   = true
    block.childAlignX  = 0.5
    block.flowDirection = tes3.flowDirection.leftToRight

    local label = block:createLabel({ text = text })
    label.autoWidth = true
    if color then label.color = color end
    return label
end

--==================
-- SECTIONS
--==================

local function addVitals(parent, reference, mobile)
    local object = reference.object
    local objectType = object.objectType

    addHeader(parent, "Info")
    addValue(parent, getObjectTypeName(reference))

    if objectType == tes3.objectType.npc then
        local race = safeGet(object, "race")
        if race then
            addValue(parent, "Race: " .. (safeGet(race, "name") or safeGet(race, "id") or "Unknown"))
        end
        local isFemale = safeGet(object, "female")
        if isFemale ~= nil then
            addValue(parent, "Gender: " .. (isFemale and "Female" or "Male"))
        end
    end

    if object.class then
        addValue(parent, "Class: " .. (object.class.name or object.class.id or "Unknown"))
    end
    if object.level then
        addValue(parent, "Level: " .. tostring(object.level))
    end

    addHeader(parent, "Vitals")
    if mobile.health then
        addValue(parent, string.format("Health:  %.0f / %.0f",
            getStatisticCurrent(mobile.health), getStatisticBase(mobile.health)))
    end
    if mobile.magicka then
        addValue(parent, string.format("Magicka: %.0f / %.0f",
            getStatisticCurrent(mobile.magicka), getStatisticBase(mobile.magicka)))
    end
    if mobile.fatigue then
        addValue(parent, string.format("Fatigue: %.0f / %.0f",
            getStatisticCurrent(mobile.fatigue), getStatisticBase(mobile.fatigue)))
    end
end

local function addDisposition(parent, reference, mobile, objectType)
    local disp = getDisposition(reference, mobile, objectType)
    if disp ~= nil then
        addHeader(parent, "Social")
        addValue(parent, "Disposition: " .. tostring(disp))
    end
end

local function addFaction(parent, object)
    local faction = safeGet(object, "faction")
    if not faction then return end
    addHeader(parent, "Faction")
    addValue(parent, safeGet(faction, "name") or safeGet(faction, "id") or "Unknown")
    local rankIndex = safeGet(object, "factionRank")
    if rankIndex ~= nil then
        local ok, rankName = pcall(function() return faction:getRankName(rankIndex) end)
        if ok and rankName and rankName ~= "" then
            addValue(parent, "Rank: " .. rankName)
        end
    end
end

local function addCombatStats(parent, mobile)
    local armorRating = safeGet(mobile, "armorRating")
    local attackBonus = safeGet(mobile, "attackBonus")
    if armorRating == nil and attackBonus == nil then return end
    addHeader(parent, "Combat")
    if armorRating ~= nil then
        addValue(parent, string.format("Armor Rating: %.0f", armorRating))
    end
    if attackBonus ~= nil then
        addValue(parent, string.format("Attack Bonus: %.0f", attackBonus))
    end
end

local function addAttributes(parent, mobile)
    addHeader(parent, "Attributes")
    local attributes = {
        {"STR","strength"}, {"INT","intelligence"},
        {"WIL","willpower"},{"AGI","agility"},
        {"SPD","speed"},    {"END","endurance"},
        {"PER","personality"},{"LUC","luck"},
    }
    for _, pair in ipairs(attributes) do
        addValue(parent, string.format("%s: %.0f", pair[1], getStatisticCurrent(mobile[pair[2]])))
    end
end

--==================
-- MAGIC EFFECTS
--==================

-- Reverse lookup: tes3.effect enum ID -> readable name.
-- "fortifyAttribStrength" -> "Fortify Strength"
-- "fortifySkillBlock"     -> "Fortify Block"
local EFFECT_NAMES = {}
pcall(function()
    if not tes3.effect then return end
    for k, v in pairs(tes3.effect) do
        if type(v) == "number" and type(k) == "string" then
            local name = k
                :gsub("Attrib(%u)", "%1")
                :gsub("Skill(%u)",  "%1")
                :gsub("(%u)", " %1")
                :gsub("^%s+", "")
                :gsub("%s+", " ")
                :gsub("^%l", string.upper)
            EFFECT_NAMES[v] = name
        end
    end
end)

-- Resolves which attribute/skill an effect targets.
-- Uses the Nth slot in source.effects where N = effectIndex,
-- since effectIds on source effect slots are nil in MWSE.
local function resolveEffectSubType(effect, effectIndex)
    local attribute = safeGet(effect, "attribute")
    local skill     = safeGet(effect, "skill")
    if attribute == -1 then attribute = nil end
    if skill     == -1 then skill     = nil end
    if attribute ~= nil or skill ~= nil then return attribute, skill end

    local instance = safeGet(effect, "instance")
    if not instance then return nil, nil end

    local source = safeGet(instance, "source")
    if not source then return nil, nil end

    local spellEffects = safeGet(source, "effects")
    if not spellEffects then return nil, nil end

    pcall(function()
        local se = spellEffects[effectIndex or 1]
        if se then
            local a = safeGet(se, "attribute")
            local s = safeGet(se, "skill")
            if a ~= nil and a >= 0 then attribute = a end
            if s ~= nil and s >= 0 then skill     = s end
        end
    end)

    return attribute, skill
end

local function getMagicEffectName(effectId, effect, effectIndex)
    if effectId == nil then return "Unknown" end

    local name = EFFECT_NAMES[effectId] or tostring(effectId)

    local attribute, skill = resolveEffectSubType(effect, effectIndex or 1)

    if attribute ~= nil and attribute >= 0 then
        local attrName = (tes3.attributeName and tes3.attributeName[attribute]) or tostring(attribute)
        attrName = attrName:gsub("^%l", string.upper)
        name = name .. " " .. attrName
    end

    if skill ~= nil and skill >= 0 then
        local skillName = (tes3.skillName and tes3.skillName[skill]) or tostring(skill)
        skillName = skillName:gsub("^%l", string.upper)
        name = name .. " " .. skillName
    end

    return name
end

local function addActiveMagicEffects(parent, mobile)
    addHeader(parent, "Active Effects")

    local effectList = safeGet(mobile, "activeMagicEffectList")

    if not effectList then
        addValue(parent, "None")
        return
    end

    local lines = {}
    local sourceEffectCount = {}

    pcall(function()
        for _, effect in pairs(effectList) do
            local effectId  = safeGet(effect, "effectId")
            local magnitude = safeGet(effect, "magnitude")

            if effectId ~= nil then
                local instance  = safeGet(effect, "instance")
                local source    = instance and safeGet(instance, "source")
                local sourceKey = source and tostring(source) or "__unknown__"

                sourceEffectCount[sourceKey] = (sourceEffectCount[sourceKey] or 0) + 1
                local effectIndex = sourceEffectCount[sourceKey]

                local name = getMagicEffectName(effectId, effect, effectIndex)

                table.insert(lines, (magnitude and magnitude ~= 0)
                    and string.format("%s (%.0f)", name, magnitude)
                    or name)
            end
        end
    end)

    if #lines == 0 then
        addValue(parent, "None")
    else
        for _, line in ipairs(lines) do
            addValue(parent, line)
        end
    end
end

local function addSkills(parent, mobile)
    if not mobile.skills then return end
    addHeader(parent, "Skills")
    for skillId = 0, 26 do
        local skillData = mobile.skills[skillId + 1]
        if skillData then
            addValue(parent, string.format("%s: %.0f",
                tes3.skillName[skillId] or tostring(skillId),
                getStatisticCurrent(skillData)))
        end
    end
end

local function addCreatureSkills(parent, mobile)
    local combat  = safeGet(mobile, "combat")
    local magic   = safeGet(mobile, "magic")
    local stealth = safeGet(mobile, "stealth")

    if not combat and not magic and not stealth then return end

    addHeader(parent, "Combat Ratings")
    if combat  then addValue(parent, string.format("Combat:  %.0f", getStatisticCurrent(combat))) end
    if magic   then addValue(parent, string.format("Magic:   %.0f", getStatisticCurrent(magic))) end
    if stealth then addValue(parent, string.format("Stealth: %.0f", getStatisticCurrent(stealth))) end
end

--==================
-- DEBUG DUMP
--==================

local function logDebugInfo(reference, mobile)
    local object = reference.object
    local objectType = object.objectType

    debugLog("=== Target Inspector Debug ===")
    debugLog("Name:         " .. tostring(object.name or object.id))
    debugLog("Type:         " .. getObjectTypeName(reference))

    if objectType == tes3.objectType.npc then
        local race = safeGet(object, "race")
        debugLog("Race:         " .. tostring(race and (race.name or race.id) or "nil"))
        debugLog("Gender:       " .. (safeGet(object, "female") and "Female" or "Male"))
        debugLog("Class:        " .. tostring(object.class and (object.class.name or object.class.id) or "nil"))
        local disp = getDisposition(reference, mobile, objectType)
        debugLog("Disposition:  " .. tostring(disp))
        local faction = safeGet(object, "faction")
        if faction then
            debugLog("Faction:      " .. tostring(safeGet(faction, "name") or safeGet(faction, "id")))
            local rankIndex = safeGet(object, "factionRank")
            local ok, rankName = pcall(function() return faction:getRankName(rankIndex) end)
            debugLog("Rank:         " .. tostring(ok and rankName or rankIndex))
        else
            debugLog("Faction:      None")
        end
    end

    debugLog("Level:        " .. tostring(object.level))
    debugLog("Health:       " .. string.format("%.0f / %.0f", getStatisticCurrent(mobile.health), getStatisticBase(mobile.health)))
    debugLog("Magicka:      " .. string.format("%.0f / %.0f", getStatisticCurrent(mobile.magicka), getStatisticBase(mobile.magicka)))
    debugLog("Fatigue:      " .. string.format("%.0f / %.0f", getStatisticCurrent(mobile.fatigue), getStatisticBase(mobile.fatigue)))
    debugLog("Armor Rating: " .. string.format("%.1f", safeGet(mobile, "armorRating") or 0))
    debugLog("Attack Bonus: " .. tostring(safeGet(mobile, "attackBonus")))

    local attributes = {
        {"STR","strength"},{"INT","intelligence"},{"WIL","willpower"},
        {"AGI","agility"}, {"SPD","speed"},       {"END","endurance"},
        {"PER","personality"},{"LUC","luck"},
    }
    for _, pair in ipairs(attributes) do
        debugLog(pair[1] .. ": " .. tostring(getStatisticCurrent(mobile[pair[2]])))
    end

    if objectType == tes3.objectType.npc and mobile.skills then
        for skillId = 0, 26 do
            local skillData = mobile.skills[skillId + 1]
            if skillData then
                debugLog((tes3.skillName[skillId] or tostring(skillId)) .. ": "
                    .. tostring(getStatisticCurrent(skillData)))
            end
        end
    elseif objectType == tes3.objectType.creature then
        debugLog("Combat:  " .. tostring(getStatisticCurrent(safeGet(mobile, "combat"))))
        debugLog("Magic:   " .. tostring(getStatisticCurrent(safeGet(mobile, "magic"))))
        debugLog("Stealth: " .. tostring(getStatisticCurrent(safeGet(mobile, "stealth"))))
    end

    local effectList = safeGet(mobile, "activeMagicEffectList")
    if effectList then
        debugLog("effectList length: " .. tostring(#effectList))

        local sourceEffectCount = {}

        for i = 1, #effectList do
            local effect = effectList[i]
            if not effect then
                debugLog("Effect[" .. i .. "]: nil entry")
            else
                local effectId  = safeGet(effect, "effectId")
                local magnitude = safeGet(effect, "magnitude")

                local instance  = safeGet(effect, "instance")
                local source    = instance and safeGet(instance, "source")
                local sourceKey = source and tostring(source) or "__unknown__"

                sourceEffectCount[sourceKey] = (sourceEffectCount[sourceKey] or 0) + 1
                local effectIndex = sourceEffectCount[sourceKey]

                local nameResult
                local nameOk, nameErr = pcall(function()
                    nameResult = getMagicEffectName(effectId, effect, effectIndex)
                end)
                if not nameOk then
                    nameResult = "ERROR:" .. tostring(nameErr)
                end

                debugLog("Effect[" .. i .. "]: " .. tostring(nameResult)
                    .. " (id=" .. tostring(effectId)
                    .. " mag=" .. tostring(magnitude)
                    .. " source=" .. sourceKey .. ")")
            end
        end
    else
        debugLog("activeMagicEffectList: nil")
    end

    debugLog("=== End Debug ===")
end

--==================
-- INSPECTOR
--==================

local function showInspector(reference)
    if not reference or not reference.object then
        destroyInspector()
        return
    end

    local objectType = reference.object.objectType

    if objectType ~= tes3.objectType.npc and objectType ~= tes3.objectType.creature then
        destroyInspector()
        return
    end

    local mobile = getMobile(reference)
    if not mobile then
        destroyInspector()
        return
    end

    if currentTarget == reference and tes3ui.findMenu(UI_ID_InspectorMenu) then
        return
    end

    destroyInspector()
    currentTarget = reference

    if config.debug then
        logDebugInfo(reference, mobile)
    end

    local menu = tes3ui.createMenu({
        id = UI_ID_InspectorMenu,
        fixedFrame = true,
    })

    menu.width         = inspectorWidth
    menu.height        = inspectorHeight
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.paddingTop    = 12
    menu.paddingBottom = 12
    menu.paddingLeft   = 14
    menu.paddingRight  = 14
    menu.positionX     = 760
    menu.positionY     = 220

    addCenteredLabel(menu, "Target Inspector", COLOR_DIM)

    local g1 = menu:createLabel({ text = "" })
    g1.height = 8
    local g2 = menu:createLabel({ text = "" })
    g2.height = 8

    addCenteredLabel(menu, reference.object.name or reference.object.id or "Unknown", COLOR_HEADER)

    local gap = menu:createLabel({ text = "" })
    gap.height = 10

    local columnsBlock = menu:createBlock({})
    columnsBlock.flowDirection = tes3.flowDirection.leftToRight
    columnsBlock.autoHeight    = true
    columnsBlock.width         = leftColWidth + rightColWidth

    local leftCol = columnsBlock:createBlock({})
    leftCol.flowDirection = tes3.flowDirection.topToBottom
    leftCol.autoHeight    = true
    leftCol.width         = leftColWidth

    local rightCol = columnsBlock:createBlock({})
    rightCol.flowDirection = tes3.flowDirection.topToBottom
    rightCol.autoHeight    = true
    rightCol.width         = rightColWidth

    currentLineWidth = leftColWidth - 16

    if config.showVitals then
        addVitals(leftCol, reference, mobile)
    end
    if config.showDisposition then
        addDisposition(leftCol, reference, mobile, objectType)
    end
    if config.showFaction and objectType == tes3.objectType.npc then
        addFaction(leftCol, reference.object)
    end
    if config.showCombatStats then
        addCombatStats(leftCol, mobile)
    end
    if config.showAttributes then
        addAttributes(leftCol, mobile)
    end
    if config.showActiveMagicEffects then
        addActiveMagicEffects(leftCol, mobile)
    end

    currentLineWidth = rightColWidth - 16

    if config.showSkills then
        if objectType == tes3.objectType.npc then
            addSkills(rightCol, mobile)
        else
            addCreatureSkills(rightCol, mobile)
        end
    end

    menu:updateLayout()
end

--==================
-- EVENTS
--==================

local function onObjectTooltip(e)
    if not config.enabled or not inspectorKeyHeld then return end
    showInspector(getReference(e))
end

event.register(tes3.event.uiObjectTooltip, onObjectTooltip)

event.register(tes3.event.simulate, function()
    if not config.enabled or not inspectorKeyHeld then return end
    local target = tes3.getPlayerTarget()
    if target then showInspector(target) else destroyInspector() end
end)

event.register(tes3.event.keyDown, function(e)
    if tes3.isKeyEqual({ expected = config.inspectKey, actual = e }) then
        inspectorKeyHeld = true
    end
end)

event.register(tes3.event.keyUp, function(e)
    if tes3.isKeyEqual({ expected = config.inspectKey, actual = e }) then
        inspectorKeyHeld = false
        destroyInspector()
    end
end)

mwse.log("[%s] Initialized.", modName)
