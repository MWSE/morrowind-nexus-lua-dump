local ambient
local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')

local I = require('openmw.interfaces')

local MOD_NAME = "NCGDMW"

local Player = require('openmw.types').Player
local L = core.l10n(MOD_NAME)
local playerStorage = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local ncgdUI = require("scripts.NCGDMW.ui")

local hasStats = false
local ncgdStatsMenu
local potionId = "ncgd_start_potion"
local interfaceVersion = 3
local scriptVersion = 3
local firstUpdate = true
local baseTotalStats = 0
local forceUpdateHealth = false
local noDecayTime = 0
local noDecayTimeStart = 0

-- Map string values to numbers and back
local fast = 3
local standard = 2
local slow = 1
local none = 0

local rateMap = {
    [L("fast")] = fast,
    [L("standard")] = standard,
    [L("slow")] = slow,
    [L("none")] = none,
    [fast] = L("fast"),
    [standard] = L("standard"),
    [slow] = L("slow"),
    [none] = L("none")
}

-- Map lowercased, concatenated skill names to human-readable form
local skillsMap = {
    ["mediumarmor"] = "Medium Armor",
    ["heavyarmor"] = "Heavy Armor",
    ["bluntweapon"] = "Blunt Weapon",
    ["longblade"] = "Long Blade",
    ["lightarmor"] = "Light Armor",
    ["shortblade"] = "Short Blade",
    ["handtohand"] = "Hand To Hand",
}

-- Key variables
local minSkill = 15

local decayMemory = 0
local lvlProg = 0
local oldDay = 0
local oldHour = 0
local timePassed = 0

local baseSkills = {}
local decaySkills = {}
local maxSkills = {}

local attributeDiffs = {}
local baseAttributes = {}
local healthAttributes = {}
local startAttributes = {}

local vanillaAttributes = {
    strength = "STR",
    intelligence = "INT",
    willpower = "WIL",
    agility = "AGI",
    speed = "SPE",
    endurance = "END",
    personality = "PER",
    luck = "LUK"
}

local affectedAttributes = {
    block = { strength = 2, agility = 1, endurance = 4 },
    armorer = { strength = 1, endurance = 4, personality = 2 },
    mediumarmor = { endurance = 4, speed = 2, willpower = 1 },
    heavyarmor = { strength = 1, endurance = 4, speed = 2 },
    bluntweapon = { strength = 4, endurance = 1, willpower = 2 },
    longblade = { strength = 2, agility = 4, speed = 1 },
    axe = { strength = 4, agility = 2, willpower = 1 },
    spear = { strength = 4, endurance = 2, speed = 1 },
    athletics = { endurance = 2, speed = 4, willpower = 1 },

    enchant = { intelligence = 4, willpower = 2, personality = 1 },
    destruction = { intelligence = 2, willpower = 4, personality = 1 },
    alteration = { speed = 1, intelligence = 2, willpower = 4 },
    illusion = { agility = 1, intelligence = 2, personality = 4 },
    conjuration = { intelligence = 4, willpower = 1, personality = 2 },
    mysticism = { intelligence = 4, willpower = 2, personality = 1 },
    restoration = { endurance = 1, willpower = 4, personality = 2 },
    alchemy = { endurance = 1, intelligence = 4, personality = 2 },
    unarmored = { endurance = 1, speed = 4, willpower = 2 },

    security = { agility = 4, intelligence = 2, personality = 1 },
    sneak = { agility = 4, speed = 1, personality = 2 },
    acrobatics = { strength = 1, agility = 2, speed = 4 },
    lightarmor = { agility = 1, endurance = 2, speed = 4 },
    shortblade = { agility = 4, speed = 2, personality = 1 },
    marksman = { strength = 4, agility = 2, speed = 1 },
    mercantile = { intelligence = 2, willpower = 1, personality = 4 },
    speechcraft = { intelligence = 1, willpower = 2, personality = 4 },
    handtohand = { strength = 4, agility = 2, endurance = 1 }
}

-- If we have ambient, the build is new enough for 0.49 stuff
local is049orNewer = core.API_REVISION >= 51
local hasPlugins

if is049orNewer then
    ambient = require('openmw.ambient')
    hasPlugins = core.contentFiles.has("ncgdmw.omwaddon")
        or core.contentFiles.has("ncgdmw_alt_start.omwaddon")
        or core.contentFiles.has("ncgdmw_starwind.omwaddon")
else
    hasPlugins = core.getGMST("iLevelupMajorMult") == 0
        and core.getGMST("iLevelupMinorMult") == 0
end

if not hasPlugins
    -- or (core.contentFiles.has("ncgdmw.omwaddon")
    --     and core.contentFiles.has("ncgdmw_alt_start.omwaddon"))
    -- or (core.contentFiles.has("ncgdmw.omwaddon")
    --     and core.contentFiles.has("ncgdmw_starwind.omwaddon"))
    -- or (core.contentFiles.has("ncgdmw_alt_start.omwaddon")
    --     and core.contentFiles.has("ncgdmw_starwind.omwaddon"))
then
    ui.create(ncgdUI.missingPluginWarning())
    print(L("noPluginError0"))
    print(L("noPluginError1"))
    print(L("noPluginError2"))
    print(L("noPluginError3"))
    print(L("noPluginError4"))
    print(L("noPluginError5"))
    print(L("noPluginError6"))
    return
end

if is049orNewer then
    if core.contentFiles.has("ncgdmw-vanilla-birthsigns-patch.omwaddon") then
        ui.showMessage(L("dontUseBirthsignsPlugin"))
        print(L("dontUseBirthsignsPlugin"))
    end
end

-- Settings menu
ncgdUI.initSettings()

if is049orNewer then
	if core.contentFiles.has("ncgdmw_starwind.omwaddon") then
        print(L("autoStarwind"))
        playerStorage:set("starwindNames", true)
    end
end

-- Helpers
local function capitalize(s)
    -- THANKS: https://stackoverflow.com/a/2421843
    return s:sub(1, 1):upper() .. s:sub(2)
end

local function totalGameTimeInHours()
    return core.getGameTime() / 60 / 60 - 24
end

local function daysPassed()
    return totalGameTimeInHours() / 24
end

local function gameHour()
    return totalGameTimeInHours() % 24
end

local function randInt(rangeStart, rangeEnd)
    math.randomseed(os.time())
    return math.random(rangeStart, rangeEnd)
end

local function debugPrint(str)
    if playerStorage:get("debugMode") then
        print(str)
    end
end

if is049orNewer then
    debugPrint("OpenMW 0.49.0 detected")
else
    debugPrint("OpenMW 0.48.0 detected")
end

---- Core Logic ----

-- Log how long the player's played without decay so an accurate number can be
-- used in the decay maths below.
if playerStorage:get("decayRate") == "none" then
    noDecayTimeStart = gameHour()
end
local function logDecayTime(_, key)
    if key == "decayRate" then
        if playerStorage:get("decayRate") == "none" then
            noDecayTimeStart = gameHour()
        elseif noDecayTimeStart ~= 0 then
            noDecayTime = noDecayTime + (gameHour() - noDecayTimeStart)
            noDecayTimeStart = 0
        end
    end
end
playerStorage:subscribe(async:callback(logDecayTime))

-- This is used to calculate "decay memory" so we subtract "no decay time" to
-- ensure an accurate value which properly factors if the player disabled
-- decay for any period of time.
local function getDecayTime()
    return gameHour() - noDecayTime
end

local function getDecayRateNum()
    return rateMap[L(playerStorage:get("decayRate"))]
end

local function getGrowthRateNum()
    return rateMap[L(playerStorage:get("growthRate"))]
end

local function recalculateDecayMemory()
    local baseINT = Player.stats.attributes["intelligence"](self).base
    local currentLevel = Player.stats.level(self).current
    local decayRate = getDecayRateNum()

    debugPrint(string.format("Recalculating decay memory for: %s", rateMap[decayRate]))
    debugPrint(string.format("decayMemory is: %s", decayMemory))

    local twoWeeks = 336
    local oneWeek = 168
    local threeDays = 72
    local oneDay = 24
    local halfDay = 12

    decayMemory = currentLevel * currentLevel
    decayMemory = (baseINT * baseINT) / decayMemory

    if decayRate == slow then
        decayMemory = decayMemory * twoWeeks + threeDays
    elseif decayRate == standard then
        decayMemory = decayMemory * oneWeek + oneDay
    elseif decayRate == fast then
        decayMemory = decayMemory * threeDays + halfDay
    end

    debugPrint(string.format("decayMemory modified to: %s", decayMemory))
end

local function getAttributesToRecalculate()
    local decayRate = getDecayRateNum()
    local recalculate = {}

    for id, getter in pairs(Player.stats.skills) do
        local stat = getter(self)
        local actualBase = stat.base
        local storedBase = baseSkills[id]

        if decayRate > none then
            if storedBase then
                if actualBase > storedBase then
                    debugPrint(string.format("Skill increase for %s; halving decay progress", id))
                    debugPrint(string.format("Was: %d", decaySkills[id]))
                    -- Decrease decay rates when skills increase
                    decaySkills[id] = decaySkills[id] / 2
                    debugPrint(string.format("Now: %d", decaySkills[id]))
                end
            end
        end

        if storedBase ~= actualBase then
            baseSkills[id] = actualBase
            local affected = affectedAttributes[id]
            if affected then
                for attribute, _ in pairs(affected) do
                    -- debugPrint(string.format("%s should be recalculated!", attribute))
                    recalculate[attribute] = true
                end
            end
        end

        if actualBase > maxSkills[id] then
            -- debugPrint(string.format("Raising stored value for %s", id))
            maxSkills[id] = actualBase
        end
    end
    return recalculate
end

local function getStat(kind, stat)
    return Player.stats[kind][stat](self).base
end

local function setStat(kind, stat, value)
    local current = Player.stats[kind][stat](self).base
    local changed = current ~= value
    local statName = capitalize(stat)
    local toShow

    if kind == "attributes" then
        if value > current then
            toShow = "attrUp"
        elseif value < current then
            toShow = "attrDown"
        end
        baseAttributes[stat] = value
    elseif kind == "skills" then
        if skillsMap[stat] ~= nil then
            statName = skillsMap[stat]
        end
        if value > current then
            toShow = "skillUp"
        elseif value < current then
            toShow = "skillDown"
        end
        baseSkills[stat] = value
    end

    if changed then
        Player.stats[kind][stat](self).base = value
        ui.showMessage(L(toShow, { stat = statName, value = value }))
    end
    return changed
end

local function handleBirthsigns()
	if not is049orNewer then return end

    local signsMap = {
        ["charioteer ability"] = "ncgdmw_charioteer",
        ["mooncalf ability"] = "ncgdmw_mooncalf",
        ["lady's favor"] = "ncgdmw_ladys_favor",
        ["lady's grace"] = "ncgdmw_ladys_grace"
    }

    for _, spell in pairs(Player.spells(self)) do
        local spellId = string.lower(spell.id)
        local newSpell = signsMap[spellId]
        if newSpell then
            Player.activeSpells(self):remove(spellId)
            Player.spells(self):remove(spellId)
            Player.spells(self):add(newSpell)
        end
    end
end

local function init()
    debugPrint("NCGDMW Lua Edition INIT begins!")
    handleBirthsigns()
    for id, getter in pairs(Player.stats.attributes) do
        local stat = getter(self)
        attributeDiffs[id] = 0
        local newBase = stat.base / 2
        baseAttributes[id] = newBase
        startAttributes[id] = newBase
        stat.base = newBase
        if id == 'endurance' or id == 'strength' or id == 'willpower' then
            healthAttributes[id] = startAttributes[id]
        end
    end
    for id, getter in pairs(Player.stats.skills) do
        local stat = getter(self)
        decaySkills[id] = math.floor(randInt(0, 359) / 30)
        maxSkills[id] = stat.base
    end
    decayMemory = 100
    hasStats = true
    if playerStorage:get("showIntro") then
        -- Wait a few seconds, then flash a message to prompt the user to configure the mod
        async:newSimulationTimer(
            2,
            async:registerTimerCallback(
                "newGameGreeting",
                function()
                    ui.showMessage(L("doSettings"))
                    debugPrint("NCGDMW Lua Edition INIT has ended!")
                end
            )
        )
    end
end

local function attributeDiff(a)
    -- Try to see if something else has modified an attribute and preserve that difference.
    local diff = attributeDiffs[a] + Player.stats.attributes[a](self).base - baseAttributes[a]
    attributeDiffs[a] = diff
    return diff
end

local function doAttributes()
    local decayRate = getDecayRateNum()
    local growthRate = getGrowthRateNum()
    local toRecalculate = getAttributesToRecalculate()
    local checkProgression = false
    local recalculateLuck = false

    for attribute, _ in pairs(toRecalculate) do
        checkProgression = true
        local diff = attributeDiff(attribute)
        if diff > 0 then
            debugPrint(string.format("Adding external change for %s: %d", attribute, diff))
        end
        local total = 0
        for skill, attributes in pairs(affectedAttributes) do
            for attribute2, mult in pairs(attributes) do
                if attribute == attribute2 then
                    total = total + baseSkills[skill] * baseSkills[skill] * mult
                end
            end
        end
        total = math.floor(math.sqrt(total * growthRate / 27) + startAttributes[attribute]) + diff
        local changed, _ = I.NCGDMW.Attribute(attribute, total)
        if changed then recalculateLuck = true end
    end

    if checkProgression then
        local totalStats = 0
        for _, value in pairs(baseSkills) do
            totalStats = totalStats + value * value
        end
        local tot = math.sqrt(totalStats * 2 / 27)

        local current = Player.stats.level(self).current
        if firstUpdate then
            local progress = Player.stats.level(self).progress
            baseTotalStats = tot - current - progress / core.getGMST("iLevelupTotal")
        end
        tot = tot - baseTotalStats

        lvlProg = math.floor(tot % 1 * 100)
        local total = math.floor(tot)

        if total ~= current then
            forceUpdateHealth = true
        end
        if total > 0 then
            if total > current then
                ui.showMessage(L("lvlUp", { level = total }))
            elseif total < current then
                ui.showMessage(L("lvlDown", { level = total }))
            end
            Player.stats.level(self).current = total
        end

        if recalculateLuck then
            local diff = attributeDiff("luck")
            if diff > 0 then
                debugPrint(string.format("Adding external change for Luck: %d", diff))
            end
            total = math.floor(math.sqrt(totalStats * growthRate / 27) + startAttributes.luck) + diff
            I.NCGDMW.Attribute("luck", total)
        end
    end

    if decayRate > none and recalculateLuck then
        recalculateDecayMemory()
    end

    if decayRate > none then
        local GameHour = getDecayTime()
        timePassed = GameHour
        while oldDay < daysPassed() do
            timePassed = timePassed + 24
            oldDay = oldDay + 1
        end
        timePassed = timePassed - oldHour
        oldHour = GameHour

        for skill, _ in pairs(decaySkills) do
            decaySkills[skill] = decaySkills[skill] + timePassed
            if decaySkills[skill] > decayMemory then
                debugPrint(string.format("Decay happening for %s; resetting decay progress for this skill to 0", skill))
                decaySkills[skill] = 0
                local skillBase = Player.stats["skills"][skill](self).base
                if skillBase > maxSkills[skill] / 2 and skillBase > minSkill then
                    local new = skillBase - 1
                    setStat("skills", skill, new)

                    if is049orNewer then
                        ambient.playSound("skillraise", { pitch = 0.79 })
                        ambient.playSound("skillraise", { pitch = 0.76 })
                    end

                    -- Force a recheck of this skill's value
                    baseSkills[skill] = 0
                end
            end
        end
    end
end

local function getHealthFactor(attributes)
    return (attributes.endurance * 4 + attributes.strength * 2 + attributes.willpower) / 7
end

local function doHealth()
    local recalculate = false
    for attribute, value in pairs(healthAttributes) do
        local current
        if playerStorage:get("stateBasedHP") then
            current = Player.stats.attributes[attribute](self).modified
        else
            current = Player.stats.attributes[attribute](self).base
        end
        if current ~= value then
            healthAttributes[attribute] = current
            recalculate = true
        end
    end
    if recalculate or forceUpdateHealth then
        forceUpdateHealth = false
        local currentLevel = Player.stats.level(self).current
        local maxHealth = getHealthFactor(healthAttributes) + (currentLevel - 1) * getHealthFactor(healthAttributes) / 10
        local health = Player.stats.dynamic.health(self)
        local ratio = health.current / health.base
        health.base = maxHealth
        health.current = ratio * maxHealth
    end
end

local function hasOrHadPotion()
    -- Even if the player isn't using the alt start version, if they have stats
    -- then for all intents and purposes they may as well have had the potion.
    if hasStats then return true end
    -- Being in possession of the potion will prevent init()
    -- from running on its own (see "onConsume" below).
    if is049orNewer then
        return #Player.inventory(self):findAll(potionId) > 0
    else
        return Player.inventory(self):countOf(potionId) > 0
    end
end

local function onConsume(item)
    -- No need to do any record checking if the player already has stats.
    if hasStats then return true end
    -- But if we don't have stats, check to see if this
    -- is the right potion and do init() as needed.
    if item.recordId == potionId then
        init()
    end
end

local function onKeyPress(key)
    -- Chargen isn't done enough
    if not hasStats then return end

    -- Prevent the stats menu from rendering over the escape menu
    if key.code == input.KEY.Escape then
        if ncgdStatsMenu ~= nil then
            ncgdStatsMenu:destroy()
            ncgdStatsMenu = nil
        end
        return
    end

    if key.code == playerStorage:get("statsMenuKey") then
        local menu
        local dr = getDecayRateNum()
        if dr > none then
            menu = ncgdUI.decayStatsMenu(decaySkills, decayMemory, playerStorage:get("starwindNames"), rateMap[dr],
                rateMap[getGrowthRateNum()])
        else
            menu = ncgdUI.levelStatsMenu()
        end

        if ncgdStatsMenu == nil then
            ncgdStatsMenu = ui.create(menu)
        else
            ncgdStatsMenu.layout = menu
            ncgdStatsMenu:update()
        end
    end
end

local function onKeyRelease(key)
    if key.code == playerStorage:get("statsMenuKey") then
        if ncgdStatsMenu ~= nil then
            ncgdStatsMenu:destroy()
            ncgdStatsMenu = nil
        end
    end
end

local function onLoad(data)
    if data then
        baseSkills = data.baseSkills
        decayMemory = data.decayMemory
        decaySkills = data.decaySkills
        hasStats = data.hasStats
        healthAttributes = data.healthAttributes
        lvlProg = data.lvlProg
        maxSkills = data.maxSkills
        oldDay = data.oldDay
        oldHour = data.oldHour
        startAttributes = data.startAttributes
        timePassed = data.timePassed
        firstUpdate = data.firstUpdate
        baseTotalStats = data.baseTotalStats
        attributeDiffs = data.attributeDiffs
        baseAttributes = data.baseAttributes
        noDecayTime = data.noDecayTime or 0
        noDecayTimeStart = data.noDecayTimeStart
    end
end

local function onSave()
    return {
        attributeDiffs = attributeDiffs,
        baseAttributes = baseAttributes,
        baseSkills = baseSkills,
        decayMemory = decayMemory,
        decaySkills = decaySkills,
        hasStats = hasStats,
        healthAttributes = healthAttributes,
        lvlProg = lvlProg,
        maxSkills = maxSkills,
        oldDay = oldDay,
        oldHour = oldHour,
        startAttributes = startAttributes,
        timePassed = timePassed,
        version = scriptVersion,
        firstUpdate = firstUpdate,
        baseTotalStats = baseTotalStats,
        noDecayTime = noDecayTime,
        noDecayTimeStart = noDecayTimeStart
    }
end

local function onFrame()
    -- This is a hack to see if we're far enough along in CharGen to have stats
    if not hasOrHadPotion() and (not hasStats and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode)) then
        init()
    elseif hasStats then
        -- Main loop
        doAttributes()
        doHealth()
        firstUpdate = false
    end
end

local jailTime
local function UiModeChanged(data)
    if playerStorage:get("decayRate") ~= "none" then
        if data.newMode == "Jail" and not jailTime then
            jailTime = core.getGameTime()
        elseif not data.newMode and jailTime then
            noDecayTime = noDecayTime + (core.getGameTime() - jailTime) / 60 / 60 - 24
            jailTime = nil
        end
    end
end

-- Public interface
local interface = {
    version = interfaceVersion,
    Attribute = function(name, val)
        local changed
        if name ~= nil then
            if vanillaAttributes[name] == nil then
                print("NCGDMW/Interface/Attribute(): Invalid attribute name given")
                return
            end
            if val ~= nil then
                getStat("attributes", name)
                changed = setStat("attributes", name, val)
            end
            return changed, getStat("attributes", name)
        else
            print("NCGDMW/Interface/Attribute(): No attribute name given")
        end
    end,
    LevelProgress = function(raw)
        if raw then
            return lvlProg
        else
            return tostring(lvlProg) .. "%"
        end
    end,
    ShowNoDecayTime = function() print(noDecayTime) end

}

return {
    engineHandlers = {
        onConsume = onConsume,
        onFrame = onFrame,
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onLoad = onLoad,
        onSave = onSave
    },
    eventHandlers = {UiModeChanged = UiModeChanged},
    interfaceName = MOD_NAME,
    interface = interface
}
