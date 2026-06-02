local config = require("Ben-MagicRebalance.config")
local util = require("Ben-MagicRebalance.util")
local gameConfig = config.getGameConfig()

local this = {}

--------------------------------------------------
-- LOGGING HELPERS
--------------------------------------------------

local function getModNameAndVersion()
    return string.format("%s v%.1f", config.getModName(), config.getVersion())
end

local function log(...)

    if not config.getLoggingEnabled() then return end

    local message = ""
    local arg1, arg2 = ...

    if arg1 == nil
    or arg2 == nil
    then message = tostring(arg1)
    else message = string.format(...) end

    mwse.log("[%s] %s", getModNameAndVersion(), message)

end

this.log = log

local function logValueChange(message, valueFormat, oldValue, newValue, valueWasTouched)

    if not config.getLoggingEnabled() then return end

    message = message .. valueFormat

    if newValue ~= nil and valueWasTouched ~= false then
        message = message .. " -> " .. valueFormat
    end

    return log(message, oldValue, newValue)

end

this.logValueChange = logValueChange

local function toast(...)

    if not config.getLoggingEnabled() then return end

    local message = ""
    local arg1, arg2 = ...

    if arg1 == nil
    or arg2 == nil
    then message = tostring(arg1)
    else message = string.format(...) end

    tes3.messageBox("[%s]\n%s", getModNameAndVersion(), message)

end

this.toast = toast

--------------------------------------------------
-- OBJECT HELPERS
--------------------------------------------------

local function sortedIterateObjects(filter)

    if not config.getLoggingEnabled() then
        return tes3.iterateObjects(filter)
    end

    local objects = {}
    local sortedTable = {}

    for object in tes3.iterateObjects(filter) do

        objects[object.id] = object
        table.insert(sortedTable, object.id)

    end

    table.sort(sortedTable, util.sortFunction_ByStringKey)

    local i = 0 -- iterator variable
    local iteratorFunction = function ()

        i = i + 1
        if sortedTable[i] == nil then return nil
        else return objects[sortedTable[i]] end

    end

    return iteratorFunction

end

this.sortedIterateObjects = sortedIterateObjects

--------------------------------------------------
-- SEARCH HELPERS
--------------------------------------------------

local function logSearchTable(searchTable, valueIsNumber)

    if not config.getLoggingEnabled() then return end

    local message = "  %s %s"
    if valueIsNumber then message = "  %d %s" end

    for searchTerm, value in util.sortedPairs(searchTable, util.getSortFunction_ByKeyLengthDescThenKeyThenValue(searchTable)) do
        log(message, value, searchTerm)
    end

end

local function getSearchPattern(searchTerm)

    local firstCharacter = string.sub(searchTerm, 1, 1)
    local searchPattern = nil

    if firstCharacter == "*"
    then searchPattern = string.sub(searchTerm, 2)
    else searchPattern = util.getCaseInsensitivePattern(searchTerm) end

    if string.len(searchPattern) == 0 then return nil end
    return searchPattern

end

local function parseSearchTerms_MultiLine(searchTermsString, setOfValidValues, valueLabel, valueIsNumber, transformValueFunction)

    local searchTermsTable = {}

    for line in string.gmatch(searchTermsString, "[^\n]+") do

        local startIndex, endIndex = string.find(line, ":")

        if startIndex ~= nil then

            local value = string.sub(line, 1, startIndex - 1) ---@type (string | number | nil)
            local searchTerm = string.sub(line, endIndex + 1)

            if string.len(searchTerm) > 0 then

                if valueIsNumber then
                    value = tonumber(value)
                end

                if transformValueFunction ~= nil then
                    value = transformValueFunction(value)
                end

                if setOfValidValues[value] ~= nil then
                    searchTermsTable[searchTerm] = value
                end

            end

        end

    end

    log("%s Search Terms:", valueLabel)
    logSearchTable(searchTermsTable, valueIsNumber)
    return searchTermsTable

end

local function getSearchPatterns_MultiLine(searchTermsString, setOfValidValues, valueLabel, valueIsNumber, transformValueFunction)

    local searchTermsTable = parseSearchTerms_MultiLine(searchTermsString, setOfValidValues, valueLabel, valueIsNumber, transformValueFunction)
    local searchPatterns = {}

    for searchTerm, value in pairs(searchTermsTable) do

        local searchPattern = getSearchPattern(searchTerm)

        if searchPattern ~= nil then
            searchPatterns[searchPattern] = value
        end

    end

    log("%s Search Patterns:", valueLabel)
    logSearchTable(searchPatterns, valueIsNumber)
    return searchPatterns

end

this.getSearchPatterns_MultiLine = getSearchPatterns_MultiLine

local function parseSearchTerms_SingleLine(searchTermsString, value, valueLabel, valueIsNumber)

    local searchTermsTable = {}

    for searchTerm in string.gmatch(searchTermsString, "[^/]+") do
        searchTermsTable[searchTerm] = value
    end

    log("%s Search Terms:", valueLabel)
    logSearchTable(searchTermsTable, valueIsNumber)
    return searchTermsTable

end

local function getSearchPatterns_SingleLine(searchTermsString, value, valueLabel, valueIsNumber)

    local searchTermsTable = parseSearchTerms_SingleLine(searchTermsString, value, valueLabel, valueIsNumber)
    local searchPatterns = {}

    for searchTerm, value in pairs(searchTermsTable) do

        local searchPattern = getSearchPattern(searchTerm)

        if searchPattern ~= nil then
            searchPatterns[searchPattern] = value
        end

    end

    log("%s Search Patterns:", valueLabel)
    logSearchTable(searchPatterns)
    return searchPatterns

end

this.getSearchPatterns_SingleLine = getSearchPatterns_SingleLine

local function getValueBySearchPattern(item, searchPatterns, valueLabel, valueFormat)

    local matchLabel = nil

    -- search for longest patterns first (e.g. search "Nordic Silver" before "Nordic" or "Silver")
    for searchPattern, value in util.sortedPairs(searchPatterns, util.getSortFunction_ByKeyLengthDescThenKeyThenValue(searchPatterns)) do

        local matchValue = nil

        if string.find(item.name, searchPattern) ~= nil then
            matchValue = item.name
            matchLabel = "Name"

        -- elseif string.find(item.mesh, searchPattern) ~= nil then
        --     matchValue = item.mesh
        --     matchLabel = "Mesh"

        -- elseif string.find(item.icon, searchPattern) ~= nil then
        --     matchValue = item.icon
        --     matchLabel = "Icon"

        elseif string.find(item.id, searchPattern) ~= nil then
            matchValue = item.id
            matchLabel = "ID"
        end

        if matchLabel ~= nil then

            if valueLabel ~= nil
            and valueFormat ~= nil then

                local message =
                    "  %s: " .. valueFormat ..
                    " | Detect %s by %s: %s"..
                    " | Pattern: %s"

                log(message,
                    valueLabel, value,
                    valueLabel, matchLabel, matchValue,
                    searchPattern)

            end

            return value

        end

    end

    return nil

end

this.getValueBySearchPattern = getValueBySearchPattern

local function getValueByStat(stat, maxStats, valueLabel, statLabel, valueFormat, statFormat, statUiMax)

    for value, maxStat in util.sortedPairs(maxStats, util.getSortFunction_ByValueThenKey(maxStats)) do

        -- if UI slider is set to max, treat maxStat as infinity
        if stat <= maxStat or maxStat >= statUiMax then

            if valueLabel ~= nil
            and statLabel ~= nil
            and valueFormat ~= nil
            and statFormat ~= nil then

                local message =
                    "  %s: " .. valueFormat ..
                    " | Detect %s by %s: " .. statFormat ..
                    " | Max %s: " .. statFormat

                log(message,
                    valueLabel, value,
                    valueLabel, statLabel, stat,
                    statLabel, maxStat)

            end

            return value

        end

    end

    return nil

end

this.getValueByStat = getValueByStat

--------------------------------------------------
-- EFFECT HELPERS
--------------------------------------------------

local function getEffectConfig(effectId)

    local costs = gameConfig.magicEffect.effectCosts[effectId] or {}
    local limits = gameConfig.limit.effectLimits[effectId] or {}

    local effectConfig = {
        baseMagickaCost = costs.baseMagickaCost,

        minDuration = util.zeroAsNil(limits.minDuration),
        maxDuration = util.zeroAsNil(limits.maxDuration),
        minMagnitude = util.zeroAsNil(limits.minMagnitude),
        maxMagnitude = util.zeroAsNil(limits.maxMagnitude),

        recMinDuration = util.zeroAsNil(limits.recMinDuration) or util.zeroAsNil(limits.minDuration),
        recMinMagnitude = util.zeroAsNil(limits.recMinMagnitude) or util.zeroAsNil(limits.minMagnitude),
        recMaxMagnitude = util.zeroAsNil(limits.recMaxMagnitude) or util.zeroAsNil(limits.maxMagnitude),
    }

    return effectConfig

end

this.getEffectConfig = getEffectConfig

-- https://mwse.github.io/MWSE/references/magic-effects-modded/
-- this list was last updated 2026-05-28
local effectId_SourceMod = {
    [220] = "Magicka Expanded",
    [223] = "Magicka Expanded",
    [224] = "Magicka Expanded",
    [225] = "Magicka Expanded",
    [226] = "Magicka Expanded",
    [227] = "Magicka Expanded",
    [228] = "Magicka Expanded",
    [229] = "Magicka Expanded",
    [230] = "Magicka Expanded",
    [231] = "Magicka Expanded",
    [232] = "Magicka Expanded",
    [233] = "Magicka Expanded",
    [234] = "Magicka Expanded",
    [235] = "Magicka Expanded",
    [236] = "Magicka Expanded",
    [237] = "Magicka Expanded",
    [238] = "Magicka Expanded",
    [239] = "Magicka Expanded",
    [240] = "Magicka Expanded",
    [241] = "Magicka Expanded",
    [242] = "Magicka Expanded",
    [243] = "Magicka Expanded",
    [244] = "Magicka Expanded",
    [245] = "Magicka Expanded",
    [246] = "Magicka Expanded",
    [247] = "Magicka Expanded",
    [248] = "Magicka Expanded",
    [249] = "Magicka Expanded",
    [250] = "Magicka Expanded",
    [251] = "Magicka Expanded",
    [252] = "Magicka Expanded",
    [253] = "Magicka Expanded",
    [254] = "Magicka Expanded",
    [255] = "Magicka Expanded",
    [256] = "Magicka Expanded",
    [257] = "Magicka Expanded",
    [258] = "Magicka Expanded",
    [259] = "Magicka Expanded",
    [260] = "Magicka Expanded",
    [261] = "Magicka Expanded",
    [262] = "Magicka Expanded",
    [263] = "Magicka Expanded",
    [264] = "Magicka Expanded",
    [265] = "The Astral Pocket",
    [266] = "Chrysopoeia",
    [267] = "Magicka Expanded",
    [268] = "Magicka Expanded",
    [269] = "Magicka Expanded",
    [270] = "Magicka Expanded",
    [271] = "Magicka Expanded",
    [272] = "Magicka Expanded",
    [273] = "Magicka Expanded",
    [274] = "Magicka Expanded",
    [275] = "Magicka Expanded",
    [276] = "Magicka Expanded",
    [277] = "Magicka Expanded",
    [278] = "Magicka Expanded",
    [279] = "Magicka Expanded",
    [280] = "Magicka Expanded",
    [281] = "Magicka Expanded",
    [282] = "Magicka Expanded",
    [283] = "Magicka Expanded",
    [284] = "Magicka Expanded",
    [285] = "Magicka Expanded",
    [286] = "Magicka Expanded",
    [287] = "Magicka Expanded",
    [288] = "Magicka Expanded",
    [289] = "Magicka Expanded",
    [290] = "Magicka Expanded",
    [291] = "Magicka Expanded",
    [292] = "Magicka Expanded",
    [293] = "Magicka Expanded",
    [294] = "Magicka Expanded",
    [295] = "Magicka Expanded",
    [296] = "Magicka Expanded",
    [297] = "Magicka Expanded",
    [298] = "Magicka Expanded",
    [299] = "Magicka Expanded",
    [300] = "Magicka Expanded",
    [301] = "Magicka Expanded",
    [302] = "Magicka Expanded",
    [303] = "Magicka Expanded",
    [304] = "Magicka Expanded",
    [305] = "Magicka Expanded",
    [306] = "Magicka Expanded",
    [307] = "Magicka Expanded",
    [308] = "Magicka Expanded",
    [309] = "Magicka Expanded",
    [310] = "Magicka Expanded",
    [312] = "Magicka Expanded",
    [313] = "Magicka Expanded",
    [314] = "Magicka Expanded",
    [315] = "Magicka Expanded",
    [316] = "Magicka Expanded",
    [317] = "Magicka Expanded",
    [318] = "Magicka Expanded",
    [319] = "Magicka Expanded",
    [320] = "Magicka Expanded",
    [321] = "Magicka Expanded",
    [323] = "Magicka Expanded",
    [324] = "Magicka Expanded",
    [325] = "Magicka Expanded",
    [326] = "Magicka Expanded",
    [327] = "Magicka Expanded",
    [328] = "Magicka Expanded",
    [329] = "Magicka Expanded",
    [330] = "Magicka Expanded",
    [331] = "Magicka Expanded",
    [332] = "Magicka Expanded",
    [333] = "Magicka Expanded",
    [334] = "Magicka Expanded",
    [335] = "Magicka Expanded",
    [336] = "Enhanced Detection",
    [337] = "Enhanced Detection",
    [338] = "Enhanced Detection",
    [339] = "Enhanced Detection",
    [340] = "Enhanced Detection",
    [341] = "Enhanced Detection",
    [342] = "Enhanced Detection",
    [343] = "Hircine's Maze",
    [344] = "MM - Enhanced Light",
    [345] = "Enhanced Detection",
    [346] = "Enhanced Detection",
    [400] = "Deeper Dagoth Ur",
    [401] = "Deeper Dagoth Ur",
    [402] = "Fortified Molag Mar",
    [403] = "Fortified Molag Mar",
    [404] = "Fortified Molag Mar",
    [405] = "Fortified Molag Mar",
    [420] = "Summon Creeper",
    --[424] = "3E 427 A Space Odyssey",
    --[424] = "Fargoth Intervention",
    [425] = "Daedric Intervention Spell",
    [426] = "Call Incarnate",
    [427] = "OAAB Integrations",
    [429] = "Bound Leggings for Beasts",
    [430] = "Power Fantasy",
    [431] = "Power Fantasy",
    [500] = "4NM_Magic",
    [501] = "4NM_Magic",
    [502] = "4NM_Magic",
    [504] = "4NM_Magic",
    [506] = "4NM_Magic",
    [508] = "4NM_Magic",
    [510] = "4NM_Magic",
    [511] = "4NM_Magic",
    [513] = "4NM_Magic",
    [515] = "4NM_Magic",
    [516] = "4NM_Magic",
    [518] = "4NM_Magic",
    [520] = "4NM_Magic",
    [521] = "4NM_Magic",
    [523] = "4NM_Magic",
    [525] = "4NM_Magic",
    [526] = "4NM_Magic",
    [528] = "4NM_Magic",
    [530] = "4NM_Magic",
    [531] = "4NM_Magic",
    [533] = "4NM_Magic",
    [535] = "4NM_Magic",
    [536] = "4NM_Magic",
    [538] = "4NM_Magic",
    [540] = "4NM_Magic",
    [541] = "4NM_Magic",
    [543] = "4NM_Magic",
    [545] = "4NM_Magic",
    [546] = "4NM_Magic",
    [548] = "4NM_Magic",
    [550] = "4NM_Magic",
    [551] = "4NM_Magic",
    [553] = "4NM_Magic",
    [555] = "4NM_Magic",
    [556] = "4NM_Magic",
    [558] = "4NM_Magic",
    [560] = "4NM_Magic",
    [561] = "4NM_Magic",
    [563] = "4NM_Magic",
    [565] = "4NM_Magic",
    [600] = "4NM_Magic",
    [601] = "Customizable MWSE Multi Mark and Harder Recall",
    --[602] = "4NM_Magic",
    --[602] = "Customizable MWSE Multi Mark and Harder Recall",
    [610] = "Throw It",
    --[701] = "4NM - Total Gameplay Overhaul",
    --[701] = "Extradimensional Pockets",
    [702] = "4NM - Total Gameplay Overhaul",
    [704] = "Bound Ammo",
    [705] = "Bound Ammo (JosephMcKean Edit)",
    [706] = "Bound Ammo (JosephMcKean Edit)",
    [711] = "Animate Weapon Spell",
    [786] = "Enchant Drain",
    [787] = "Obedient Summons",
    [790] = "Class Starting Spells",
    [791] = "Class Starting Spells",
    [793] = "Class Starting Spells",
    [796] = "Class Starting Spells",
    [900] = "Leech Effects",
    [901] = "Leech Effects",
    [902] = "Leech Effects",
    [1201] = "Vaermina's Quest - Dreams of the Escaped",
    [1202] = "Vaermina's Quest - Dreams of the Escaped",
    [1203] = "Vaermina's Quest - Dreams of the Escaped",
    [1812] = "STRONGER - A Simple MWSE Encumbrance Overhaul",
    [1813] = "STRONGER - A Simple MWSE Encumbrance Overhaul",
    [2090] = "Tamriel_Data",
    [2091] = "Tamriel_Data",
    [2092] = "Tamriel_Data",
    [2093] = "Tamriel_Data",
    [2094] = "Tamriel_Data",
    [2095] = "Tamriel_Data",
    [2096] = "Tamriel_Data",
    [2097] = "Tamriel_Data",
    [2098] = "Tamriel_Data",
    [2099] = "Tamriel_Data",
    [2100] = "Tamriel_Data",
    [2101] = "Tamriel_Data",
    [2102] = "Tamriel_Data",
    [2103] = "Tamriel_Data",
    [2104] = "Tamriel_Data",
    [2105] = "Tamriel_Data",
    [2106] = "Tamriel_Data",
    [2107] = "Tamriel_Data",
    [2108] = "Tamriel_Data",
    [2109] = "Tamriel_Data",
    [2110] = "Tamriel_Data",
    [2111] = "Tamriel_Data",
    [2112] = "Tamriel_Data",
    [2113] = "Tamriel_Data",
    [2114] = "Tamriel_Data",
    [2115] = "Tamriel_Data",
    [2116] = "Tamriel_Data",
    [2117] = "Tamriel_Data",
    [2119] = "Tamriel_Data",
    [2120] = "Tamriel_Data",
    [2121] = "Tamriel_Data",
    [2122] = "Tamriel_Data",
    [2123] = "Tamriel_Data",
    [2124] = "Tamriel_Data",
    [2125] = "Tamriel_Data",
    [2126] = "Tamriel_Data",
    [2127] = "Tamriel_Data",
    [2128] = "Tamriel_Data",
    [2129] = "Tamriel_Data",
    [2130] = "Tamriel_Data",
    [2131] = "Tamriel_Data",
    [2132] = "Tamriel_Data",
    [2133] = "Tamriel_Data",
    [2134] = "Tamriel_Data",
    [2135] = "Tamriel_Data",
    [2136] = "Tamriel_Data",
    [2137] = "Tamriel_Data",
    [2138] = "Tamriel_Data",
    [2139] = "Tamriel_Data",
    [2140] = "Tamriel_Data",
    [2141] = "Tamriel_Data",
    [2142] = "Tamriel_Data",
    [2143] = "Tamriel_Data",
    [2145] = "Tamriel_Data",
    [2146] = "Tamriel_Data",
    [2147] = "Tamriel Rebuilt",
    [2148] = "Tamriel Rebuilt",
    [2149] = "Tamriel Rebuilt",
    [2150] = "Tamriel Rebuilt",
    [3300] = "Summon Souls",
    [3301] = "Summon Souls",
    [3302] = "Summon Souls",
    [3303] = "Summon Souls",
    [3304] = "Summon Souls",
    [3305] = "Summon Souls",
    [3306] = "Summon Souls",
    [3307] = "Summon Souls",
    [3308] = "Summon Souls",
    [7700] = "Atronach Expansion",
    [7701] = "Atronach Expansion",
    [7702] = "Atronach Expansion",
    [7703] = "Atronach Expansion",
    [7704] = "Atronach Expansion",
    [7705] = "Atronach Expansion",
    [7706] = "Atronach Expansion",
    [7770] = "The Sanguine Rose",
    [7800] = "OOAB Grazelands",
    [8113] = "Pimp My Shrine - The Daedric Legend of Vernaccus",
    [8114] = "Pimp My Shrine - The Daedric Legend of Vernaccus",
    [8500] = "DRIP - Dynamic Randomised Item Properties",
    [9599] = "Unidentified Items (JosephMcKean Edit)",
    [10000] = "Seph's NPC Soul Trapping",
    [23235] = "Fortify Magicka Regeneration",
    [23236] = "Fortify Magicka Regeneration",
    [23331] = "Magical Repairing",
    [23332] = "Magical Repairing",
    [23333] = "Magical Repairing",
}

local function getEffectIdSourceMod(effectId)
    return effectId_SourceMod[effectId]
end

this.getEffectIdSourceMod = getEffectIdSourceMod

local effectRange_DisplayName = {
    [tes3.effectRange.self] = "Self",
    [tes3.effectRange.touch] = "Touch",
    [tes3.effectRange.target] = "Target",
}

local function getEffectRangeDisplayName(effectRange)
    return effectRange_DisplayName[effectRange]
end

local function getEffectName(effect)

    local name = effect.object.name

    if effect.attribute >= 0 then name = name:gsub("Attribute", tes3.getAttributeName(effect.attribute))  end
    if effect.skill >= 0 then name = name:gsub("Skill", tes3.getSkillName(effect.skill)) end

    return name

end

this.getEffectName = getEffectName

local function logEffect(effect, descriptor)

    local effectName = getEffectName(effect)
    local rangeName = getEffectRangeDisplayName(effect.rangeType)

    local format = "  %sEffect: %s" -- " %d to %d for %d in %d on %s"
    local values = {}

    if effect.max > 1 then format = format .. " %d" table.insert(values, effect.min) end
    if effect.min ~= effect.max then format = format .. " to %d" table.insert(values, effect.max) end
    if effect.duration > 1 then format = format .. " for %d secs" table.insert(values, effect.duration) end
    if effect.radius > 0 then format = format .. " in %d ft" table.insert(values, effect.radius) end

    format = format .. " on %s"
    table.insert(values, rangeName)

    log(format, descriptor, effectName, table.unpack(values))

end

--------------------------------------------------
-- MAGIC SOURCE HELPERS
--------------------------------------------------

-- magicSource = spell, alchemy, or enchantment

local function logEffects(magicSource, descriptor)

    if not config.getLoggingEnabled() then return end

    descriptor = descriptor or ""

    for _, effect in ipairs(magicSource.effects) do
        if effect.object ~= nil then logEffect(effect, descriptor) end
    end

end

this.logEffects = logEffects

local function getFirstEffect(magicSource)

    for _, effect in ipairs(magicSource.effects) do
        if effect.object ~= nil then return effect end
    end

end

this.getFirstEffect = getFirstEffect

local function getHasModdedEffect(magicSource)

    for _, effect in ipairs(magicSource.effects) do
        if effect.id > 142 then return true end
    end

    return false

end

this.getHasModdedEffect = getHasModdedEffect

--------------------------------------------------
-- MAGIC EFFECT HELPERS
--------------------------------------------------

local unmodifiedMagicEffects = {}

local function cacheMagicEffect(magicEffect)

    if unmodifiedMagicEffects[magicEffect.id] ~= nil then return end

    unmodifiedMagicEffects[magicEffect.id] = {
        baseMagickaCost = magicEffect.baseMagickaCost,
    }

end

local function cacheMagicEffects()

    for _, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        cacheMagicEffect(magicEffect)
    end

end

this.cacheMagicEffects = cacheMagicEffects

local function getUnmodifiedMagicEffect(effectId)
    return unmodifiedMagicEffects[effectId]
end

this.getUnmodifiedMagicEffect = getUnmodifiedMagicEffect

local magicSchool_DisplayName = {
    [tes3.magicSchool.alteration] = "Alteration",
    [tes3.magicSchool.conjuration] = "Conjuration",
    [tes3.magicSchool.destruction] = "Destruction",
    [tes3.magicSchool.illusion] = "Illusion",
    [tes3.magicSchool.mysticism] = "Mysticism",
    [tes3.magicSchool.restoration] = "Restoration",
    [tes3.magicSchool.none] = "None",
}

local function getMagicSchoolDisplayName(magicSchool)
    return magicSchool_DisplayName[magicSchool]
end

this.getMagicSchoolDisplayName = getMagicSchoolDisplayName

local magicSchool_SortOrder = {
    [tes3.magicSchool.restoration] = 1,
    [tes3.magicSchool.destruction] = 2,
    [tes3.magicSchool.mysticism] = 3,
    [tes3.magicSchool.illusion] = 4,
    [tes3.magicSchool.alteration] = 5,
    [tes3.magicSchool.conjuration] = 6,
    [tes3.magicSchool.none] = 7,
}

local function sortFunction_ByMagicSchool(keyA, keyB)

    local valueA = magicSchool_SortOrder[keyA]
    local valueB = magicSchool_SortOrder[keyB]

    return valueA < valueB

end

this.sortFunction_ByMagicSchool = sortFunction_ByMagicSchool

--------------------------------------------------
-- GMST HELPERS
--------------------------------------------------

local gmst_DisplayName = {
    [tes3.gmst.fEnchantmentMult] = "fEnchantmentMult",
    [tes3.gmst.fElementalShieldMult] = "fElementalShieldMult",
}

local function setGmst(gmstId, newValue)

    local gmst = tes3.findGMST(gmstId)
    local oldValue = gmst.value

    tes3.findGMST(gmstId).value = newValue
    if not config.getLoggingEnabled() then return end

    local displayName = gmst_DisplayName[gmstId]
    local valueFormat = nil

    if gmst.type == "i" then
        valueFormat = "%d"
    elseif gmst.type == "f" then
        valueFormat = "%.4f"
    elseif gmst.type == "s" then
        valueFormat = "%s"
    end

    local message = "GMST %s: " .. valueFormat .. " -> " .. valueFormat
    log(message, displayName, oldValue, newValue)

end

this.setGmst = setGmst

local function setGmsts(gmstTable)

    for gmstId, value in util.sortedPairs(gmstTable) do
        setGmst(gmstId, value)
    end

end

this.setGmsts = setGmsts

return this
