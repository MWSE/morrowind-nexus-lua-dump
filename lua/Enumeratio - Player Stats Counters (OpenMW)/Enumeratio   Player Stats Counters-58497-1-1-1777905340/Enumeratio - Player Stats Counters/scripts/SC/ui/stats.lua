local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require("openmw.interfaces")

local mDef = require('scripts.SC.config.definition')
local mS = require('scripts.SC.config.settings')
local derived = require('scripts.SC.util.derived')

local L = core.l10n(mDef.MOD_NAME)

local module = {}

local API
local C

local function get(profileId, key)
    return storage.playerSection(profileId):get(key) or 0
end

local profileIdRef = nil
local statsWindowRegistered = false
local statsWindowDisabled = false
local summaryOnlyLogged = false

local function stat(key)
    if not profileIdRef then return 0 end
    return get(profileIdRef, key)
end

-- Abbreviate large numbers: 47300 → "47k", 1200000 → "1.2m"
local function fmtNum(n)
    if mS.displayStorage:get("abbreviateNumbers") and type(n) == "number" then
        if n >= 1000000 then
            local m = n / 1000000
            if m == math.floor(m) then
                return string.format("%dm", m)
            else
                return string.format("%.1fm", m)
            end
        elseif n >= 10000 then
            local k = math.floor(n / 1000)
            return string.format("%dk", k)
        end
    end
    return tostring(n)
end

local function fmtRate(value, suffix)
    if not value then return "N/A" end
    return string.format("%.1f%s", value, suffix or "")
end

-- ================================================================
-- QUEUE-BASED LINE INSERTION (supports sorting counters)
-- Lines are queued per section, then flushed in the desired order.
-- Sort mode: "default" (insertion order), "alpha" (by label A-Z),
-- "highest" (by counter value descending). Requires reloadlua.
-- ================================================================

local lineQueues = {}  -- sectionId → list of { params, sortLabel, sortValue }

local function queueLine(sectionId, id, params, sortLabel, sortValueFn)
    if not lineQueues[sectionId] then lineQueues[sectionId] = {} end
    table.insert(lineQueues[sectionId], {
        id = id,
        params = params,
        sortLabel = sortLabel or "",
        sortValueFn = sortValueFn,
    })
end

local function flushSection(sectionId)
    local queue = lineQueues[sectionId]
    if not queue then return end

    local sortMode = mS.displayStorage:get("sortCounters") or "sortCounters_default"

    if sortMode == "sortCounters_alpha" then
        table.sort(queue, function(a, b)
            return a.sortLabel < b.sortLabel
        end)
    elseif sortMode == "sortCounters_highest" then
        table.sort(queue, function(a, b)
            local va = a.sortValueFn and a.sortValueFn() or 0
            local vb = b.sortValueFn and b.sortValueFn() or 0
            if va ~= vb then return va > vb end
            return a.sortLabel < b.sortLabel  -- tiebreak alphabetical
        end)
    end
    -- "default" = no sort, insertion order preserved

    for _, entry in ipairs(queue) do
        API.addLineToSection(entry.id, sectionId, entry.params)
    end

    lineQueues[sectionId] = nil
end

-- Convenience wrapper: builds standard line params and queues them.
local function addLine(sectionId, id, labelKey, descKey, valueFn, visibleKey, storageKey)
    local label = L(labelKey)
    local params = {
        label = label,
        labelColor = C.Colors.DEFAULT,
        value = valueFn,
        tooltip = function()
            return API.TooltipBuilders.HEADER(L(labelKey), L(descKey), "")
        end,
        visibleFn = visibleKey and function()
            if not mS.isVisible(visibleKey) then return false end
            if storageKey and mS.displayStorage:get("hideZeroCounters") then
                if (profileIdRef and get(profileIdRef, storageKey) or 0) == 0 then
                    return false
                end
            end
            return true
        end or nil,
    }
    local sortValueFn = storageKey and function()
        return profileIdRef and get(profileIdRef, storageKey) or 0
    end or nil
    queueLine(sectionId, id, params, label, sortValueFn)
end

local missingStatsWindowWarned = false

module.setStatsWindow = function(state)
    if not I.StatsWindow or not I.StatsWindow.Constants then
        if not missingStatsWindowWarned then
            print("[Enumeratio] Stats Window Extender is required; counters UI disabled.")
            missingStatsWindowWarned = true
        end
        return false
    end

    API = I.StatsWindow
    C = API.Constants
    profileIdRef = state.profileId

    if mS.summaryStorage and mS.summaryStorage:get('summaryOnlyPopup') then
        statsWindowDisabled = true
        if not summaryOnlyLogged then
            print("[Enumeratio] Summary-only mode enabled; Stats Window counters hidden.")
            summaryOnlyLogged = true
        end
        return false
    end
    statsWindowDisabled = false

    -- OpenMW starts PLAYER scripts before and during save loading. Register
    -- the Stats Window layout only once, but keep profileIdRef refreshed so
    -- all value callbacks read the currently loaded character's storage.
    if statsWindowRegistered then
        return true
    end

    -- ================================================================
    -- Root sections: right panel (always) and left panel (optional).
    -- The Stats group can be placed in the left panel via a setting
    -- to better use screen space. All other groups stay on the right.
    -- Changing the left-panel setting requires reloadlua to take effect.
    -- ================================================================
    API.addSectionToBox("SC_ROOT", C.DefaultBoxes.RIGHT_SCROLL_BOX, {
        divider = { before = true, after = false },
    })

    local statsOnLeft = mS.displayStorage:get("statsOnLeftPanel")
    local statsParent = "SC_ROOT"

    if statsOnLeft then
        -- Create a new box on the left pane, placed after the attributes box.
        -- Then add our section root into that box.
        local leftOk = pcall(function()
            API.addBoxToPane("SC_LEFT_BOX", C.Panes.LEFT, {
                placement = {
                    type = C.Placement.AFTER,
                    target = C.DefaultBoxes.ATTRIBUTES_BOX,
                },
            })
            API.addSectionToBox("SC_LEFT_ROOT", "SC_LEFT_BOX", {
                divider = { before = false, after = false },
            })
        end)
        if leftOk then
            statsParent = "SC_LEFT_ROOT"
        end
    end

    -- ================================================================
    -- GROUP: Stats
    -- ================================================================
    API.addSectionToSection("SC_STATS", statsParent, {
        header = "Stats",
        indent = true,
    })

    addLine("SC_STATS", "QUEST_COUNT", "statQuestTitle", "statQuestDesc", function()
        return { string = fmtNum(stat("questCount")) }
    end, "showQuestCount", "questCount")

    addLine("SC_STATS", "DAYS_PASSED", "statDaysTitle", "statDaysDesc", function()
        return { string = tostring(derived.displayDaysPassed()) }
    end, "showDaysPassed")

    queueLine("SC_STATS", "DEATHS", {
        label = L("tooltipDeathCountTitle"),
        labelColor = C.Colors.DEFAULT,
        value = function()
            return { string = fmtNum(stat("deathCount")) }
        end,
        tooltip = function()
            return API.TooltipBuilders.HEADER(
                L("tooltipDeathCountTitle"), L("tooltipDeathCountDesc"), "")
        end,
        visibleFn = function()
            if not mS.healthStorage:get("deathCounter") then return false end
            if mS.displayStorage:get("hideZeroCounters") then
                if stat("deathCount") == 0 then return false end
            end
            return true
        end,
    }, L("tooltipDeathCountTitle"), function()
        return stat("deathCount")
    end)

    addLine("SC_STATS", "MOST_GOLD", "statMostGoldTitle", "statMostGoldDesc", function()
        return { string = fmtNum(stat("mostGold")) }
    end, "showMostGold", "mostGold")

    addLine("SC_STATS", "TOTAL_GOLD_FOUND", "statTotalGoldFoundTitle", "statTotalGoldFoundDesc", function()
        return { string = fmtNum(stat("totalGoldFound")) }
    end, "showTotalGoldFound", "totalGoldFound")

    addLine("SC_STATS", "BOOK_COUNT", "statBookTitle", "statBookDesc", function()
        return { string = fmtNum(stat("bookCount")) }
    end, "showBookCount", "bookCount")

    addLine("SC_STATS", "ARTIFACTS_FOUND", "statArtifactsFoundTitle", "statArtifactsFoundDesc", function()
        return { string = fmtNum(stat("artifactsFound")) }
    end, "showArtifactsFound", "artifactsFound")

    addLine("SC_STATS", "DISEASES_CAUGHT", "statDiseasesCaughtTitle", "statDiseasesCaughtDesc", function()
        return { string = fmtNum(stat("diseaseCaught")) }
    end, "showDiseasesCaught", "diseaseCaught")

    addLine("SC_STATS", "BLIGHTS_CAUGHT", "statBlightsCaughtTitle", "statBlightsCaughtDesc", function()
        return { string = fmtNum(stat("blightCaught")) }
    end, "showBlightsCaught", "blightCaught")

    -- Distance/speed conversion. For gameplay-facing readouts, treat world
    -- units as approximately feet-scale rather than applying the CS-style
    -- 70-units-per-metre mapping directly; that mapping overstates practical
    -- travelled distance in this mod's counters.
    local WORLD_UNITS_PER_FOOT = 73.0
    local FEET_PER_MILE = 5280.0
    local METERS_PER_FOOT = 0.3048

    local function unitsToFeet(units)
        return (units or 0) / WORLD_UNITS_PER_FOOT
    end

    local function unitsToMeters(units)
        return unitsToFeet(units) * METERS_PER_FOOT
    end

    local function fmtDist(units)
        local feet = unitsToFeet(units)
        if mS.displayStorage:get("useImperial") then
            if feet >= FEET_PER_MILE then
                return string.format("%.1f mi", feet / FEET_PER_MILE)
            else
                return string.format("%d ft", math.floor(feet))
            end
        else
            local metres = feet * METERS_PER_FOOT
            if metres >= 1000 then
                return string.format("%.1f km", metres / 1000)
            else
                return string.format("%d m", math.floor(metres))
            end
        end
    end

    addLine("SC_STATS", "DIST_ON_FOOT", "statDistFootTitle", "statDistFootDesc", function()
        return { string = fmtDist(stat("distOnFoot")) }
    end, "showDistOnFoot", "distOnFoot")

    addLine("SC_STATS", "DIST_LEVITATED", "statDistLevTitle", "statDistLevDesc", function()
        return { string = fmtDist(stat("distLevitated")) }
    end, "showDistLevitated", "distLevitated")

    addLine("SC_STATS", "DIST_JUMPED", "statDistJumpedTitle", "statDistJumpedDesc", function()
        return { string = fmtDist(stat("distJumped")) }
    end, "showDistJumped", "distJumped")

    addLine("SC_STATS", "DIST_SWUM", "statDistSwumTitle", "statDistSwumDesc", function()
        return { string = fmtDist(stat("distSwum")) }
    end, "showDistSwum", "distSwum")

    addLine("SC_STATS", "DIST_MOUNTED", "statDistMountedTitle", "statDistMountedDesc", function()
        return { string = fmtDist(stat("distMounted")) }
    end, "showDistMounted", "distMounted")

    -- Per-mount distance breakdown (only shown if the mount has distance > 0)
    local MOUNT_KEYS = {
        { key = "horse",      title = "statDistMountHorseTitle",      desc = "statDistMountHorseDesc" },
        { key = "guar",       title = "statDistMountGuarTitle",       desc = "statDistMountGuarDesc" },
        { key = "donkey",     title = "statDistMountDonkeyTitle",     desc = "statDistMountDonkeyDesc" },
        { key = "strident",   title = "statDistMountStridentTitle",   desc = "statDistMountStridentDesc" },
        { key = "skylamp",    title = "statDistMountSkylampTitle",    desc = "statDistMountSkylampDesc" },
        { key = "skyrender",  title = "statDistMountSkyrenderTitle",  desc = "statDistMountSkyrenderDesc" },
        { key = "nix",        title = "statDistMountNixTitle",        desc = "statDistMountNixDesc" },
        { key = "cliffracer", title = "statDistMountCliffracerTitle", desc = "statDistMountCliffracerDesc" },
        { key = "boar",       title = "statDistMountBoarTitle",       desc = "statDistMountBoarDesc" },
    }
    for _, mount in ipairs(MOUNT_KEYS) do
        local storageKey = "distMount_" .. mount.key
        local mountTitle = mount.title
        local mountDesc = mount.desc
        local mountId = "DIST_MOUNT_" .. mount.key:upper()
        queueLine("SC_STATS", mountId, {
            label = L(mountTitle),
            labelColor = C.Colors.DEFAULT,
            value = function()
                return { string = "  " .. fmtDist(stat(storageKey)) }
            end,
            tooltip = function()
                return API.TooltipBuilders.HEADER(L(mountTitle), L(mountDesc), "")
            end,
            visibleFn = function()
                if not mS.isVisible("showDistMountBreakdown") then return false end
                -- Always hide per-mount lines when that mount has no distance
                if (stat(storageKey) or 0) == 0 then return false end
                return true
            end,
        }, L(mountTitle), function()
            return stat(storageKey) or 0
        end)
    end

    -- Personal Records — fmtHeight is same as fmtDist
    local fmtHeight = fmtDist

    local function fmtSpeed(unitsPerSec)
        local feetPerSec = unitsToFeet(tonumber(unitsPerSec) or 0)
        if mS.displayStorage:get("useImperial") then
            local mph = feetPerSec * 0.681818
            return string.format("%.0f mph", mph)
        else
            local metresPerSec = feetPerSec * METERS_PER_FOOT
            local kmh = metresPerSec * 3.6
            return string.format("%.0f km/h", kmh)
        end
    end

    addLine("SC_STATS", "HIGHEST_POINT", "statHighestPointTitle", "statHighestPointDesc", function()
        return { string = fmtHeight(stat("highestPoint")) }
    end, "showHighestPoint", "highestPoint")

    addLine("SC_STATS", "DEEPEST_DIVE", "statDeepestDiveTitle", "statDeepestDiveDesc", function()
        local raw = stat("deepestDive")
        if raw == 0 then
            return { string = mS.displayStorage:get("useImperial") and "0 ft" or "0 m" }
        end
        return { string = fmtHeight(math.abs(raw)) }
    end, "showDeepestDive", "deepestDive")

    addLine("SC_STATS", "LONGEST_FALL", "statLongestFallTitle", "statLongestFallDesc", function()
        return { string = fmtHeight(stat("longestFallSurvived")) }
    end, "showLongestFall", "longestFallSurvived")

    addLine("SC_STATS", "FASTEST_SPEED", "statFastestSpeedTitle", "statFastestSpeedDesc", function()
        return { string = fmtSpeed(stat("fastestSpeed")) }
    end, "showFastestSpeed", "fastestSpeed")

    addLine("SC_STATS", "FURTHEST_FROM_START", "statFurthestFromStartTitle", "statFurthestFromStartDesc", function()
        return { string = fmtDist(stat("furthestFromStart")) }
    end, "showFurthestFromStart", "furthestFromStart")

    flushSection("SC_STATS")

    -- ================================================================
    -- GROUP: Primary Needs
    -- ================================================================
    API.addSectionToSection("SC_NEEDS", "SC_ROOT", {
        header = "Primary Needs",
        indent = true,
    })

    addLine("SC_NEEDS", "SD_COOK_COUNT", "statSdCookTitle", "statSdCookDesc", function()
        return { string = fmtNum(stat("sdCookCount")) }
    end, "showSdCookCount", "sdCookCount")

    addLine("SC_NEEDS", "SD_MEAL_COUNT", "statSdMealTitle", "statSdMealDesc", function()
        return { string = fmtNum(stat("sdMealCount")) }
    end, "showSdMealCount", "sdMealCount")

    addLine("SC_NEEDS", "SD_DRINK_COUNT", "statSdDrinkTitle", "statSdDrinkDesc", function()
        return { string = fmtNum(stat("sdDrinkCount")) }
    end, "showSdDrinkCount", "sdDrinkCount")

    addLine("SC_NEEDS", "SD_BATH_COUNT", "statSdBathTitle", "statSdBathDesc", function()
        return { string = fmtNum(stat("sdBathCount")) }
    end, "showSdBathCount", "sdBathCount")

    addLine("SC_NEEDS", "SLEEP_DAYS", "statSleepTitle", "statSleepDesc", function()
        local h = stat("sleepHours")
        return { string = tostring(math.floor(h / 24)) }
    end, "showSleepHours", "sleepHours")

    flushSection("SC_NEEDS")

    -- ================================================================
    -- GROUP: Interactions
    -- ================================================================
    API.addSectionToSection("SC_INTERACT", "SC_ROOT", {
        header = "Interactions",
        indent = true,
    })

    addLine("SC_INTERACT", "TRAVEL_COUNT", "statTravelTitle", "statTravelDesc", function()
        return { string = fmtNum(stat("travelCount")) }
    end, "showTravelCount", "travelCount")

    addLine("SC_INTERACT", "TRAIN_COUNT", "statTrainTitle", "statTrainDesc", function()
        return { string = fmtNum(stat("trainCount")) }
    end, "showTrainCount", "trainCount")

    addLine("SC_INTERACT", "UNLOCKS_COUNT", "statUnlocksTitle", "statUnlocksDesc", function()
        return { string = fmtNum(stat("unlockCount")) }
    end, "showUnlocksCount", "unlockCount")

    addLine("SC_INTERACT", "DISARMS_COUNT", "statDisarmsTitle", "statDisarmsDesc", function()
        return { string = fmtNum(stat("disarmCount")) }
    end, "showDisarmsCount", "disarmCount")

    addLine("SC_INTERACT", "LOCKPICKS_BROKEN", "statLockpickTitle", "statLockpickDesc", function()
        return { string = fmtNum(stat("lockpicksBroken")) }
    end, "showLockpicksBroken", "lockpicksBroken")

    addLine("SC_INTERACT", "PROBES_BROKEN", "statProbeTitle", "statProbeDesc", function()
        return { string = fmtNum(stat("probesBroken")) }
    end, "showProbesBroken", "probesBroken")

    addLine("SC_INTERACT", "BRUTE_FORCE_COUNT", "statBruteForceTitle", "statBruteForceDesc", function()
        return { string = fmtNum(stat("bruteForceCount")) }
    end, "showBruteForceCount", "bruteForceCount")

    addLine("SC_INTERACT", "PLANTS_FORAGED", "statPlantsForagedTitle", "statPlantsForagedDesc", function()
        return { string = fmtNum(stat("plantsForaged")) }
    end, "showPlantsForaged", "plantsForaged")

    addLine("SC_INTERACT", "INGREDIENTS_EATEN", "statIngredientsEatenTitle", "statIngredientsEatenDesc", function()
        return { string = fmtNum(stat("ingredientsEaten")) }
    end, "showIngredientsEaten", "ingredientsEaten")

    addLine("SC_INTERACT", "PEOPLE_MET", "statPeopleMetTitle", "statPeopleMetDesc", function()
        return { string = fmtNum(stat("peopleMet")) }
    end, "showPeopleMet", "peopleMet")

    addLine("SC_INTERACT", "SLAVES_FREED", "statSlavesTitle", "statSlavesDesc", function()
        return { string = fmtNum(stat("slavesFreed")) }
    end, "showSlavesFreed", "slavesFreed")

    addLine("SC_INTERACT", "REPAIR_COUNT", "statRepairCountTitle", "statRepairCountDesc", function()
        return { string = fmtNum(stat("repairCount")) }
    end, "showRepairCount", "repairCount")

    flushSection("SC_INTERACT")

    -- ================================================================
    -- GROUP: Combat
    -- ================================================================
    API.addSectionToSection("SC_COMBAT", "SC_ROOT", {
        header = "Combat",
        indent = true,
    })

    addLine("SC_COMBAT", "NPC_KILL_COUNT", "statNpcKillTitle", "statNpcKillDesc", function()
        return { string = fmtNum(stat("npcKillCount")) }
    end, "showNpcKillCount", "npcKillCount")

    addLine("SC_COMBAT", "GODS_KILLED", "statGodsKilledTitle", "statGodsKilledDesc", function()
        return { string = fmtNum(stat("godsKilled")) }
    end, "showGodsKilled", "godsKilled")

    addLine("SC_COMBAT", "REGICIDES", "statRegicidesTitle", "statRegicidesDesc", function()
        return { string = fmtNum(stat("regicides")) }
    end, "showRegicides", "regicides")

    addLine("SC_COMBAT", "WITCHES_HUNTED", "statWitchesHuntedTitle", "statWitchesHuntedDesc", function()
        return { string = fmtNum(stat("witchesHunted")) }
    end, "showWitchesHunted", "witchesHunted")

    addLine("SC_COMBAT", "NECROMANCERS_SLAIN", "statNecromancersSlainTitle", "statNecromancersSlainDesc", function()
        return { string = fmtNum(stat("necromancersSlain")) }
    end, "showNecromancersSlain", "necromancersSlain")

    addLine("SC_COMBAT", "WARLOCKS_SLAIN", "statWarlocksSlainTitle", "statWarlocksSlainDesc", function()
        return { string = fmtNum(stat("warlocksSlain")) }
    end, "showWarlocksSlain", "warlocksSlain")

    addLine("SC_COMBAT", "WORSHIPPERS_SLAIN", "statWorshippersSlainTitle", "statWorshippersSlainDesc", function()
        return { string = fmtNum(stat("worshippersSlain")) }
    end, "showWorshippersSlain", "worshippersSlain")

    addLine("SC_COMBAT", "CREATURE_KILL_COUNT", "statCreatureKillTitle", "statCreatureKillDesc", function()
        return { string = fmtNum(stat("creatureKillCount")) }
    end, "showCreatureKillCount", "creatureKillCount")

    addLine("SC_COMBAT", "UNDEAD_KILL_COUNT", "statUndeadKillTitle", "statUndeadKillDesc", function()
        return { string = fmtNum(stat("undeadKillCount")) }
    end, "showUndeadKillCount", "undeadKillCount")

    addLine("SC_COMBAT", "DAEDRA_KILL_COUNT", "statDaedraKillTitle", "statDaedraKillDesc", function()
        return { string = fmtNum(stat("daedraKillCount")) }
    end, "showDaedraKillCount", "daedraKillCount")

    addLine("SC_COMBAT", "HUMANOID_KILL_COUNT", "statHumanoidKillTitle", "statHumanoidKillDesc", function()
        return { string = fmtNum(stat("humanoidKillCount")) }
    end, "showHumanoidKillCount", "humanoidKillCount")

    addLine("SC_COMBAT", "KILL_COUNT", "statKillTitle", "statKillDesc", function()
        return { string = fmtNum(stat("killCount")) }
    end, "showKillCount", "killCount")

    addLine("SC_COMBAT", "DAMAGE_TAKEN", "statDamageTakenTitle", "statDamageTakenDesc", function()
        return { string = fmtNum(stat("damageTaken")) }
    end, "showDamageTaken", "damageTaken")

    addLine("SC_COMBAT", "COMBAT_DAMAGE_TAKEN", "statCombatDmgTitle", "statCombatDmgDesc", function()
        return { string = fmtNum(stat("combatDamageTaken")) }
    end, "showCombatDamageTaken", "combatDamageTaken")

    addLine("SC_COMBAT", "COMBAT_ACCURACY", "statAccuracyTitle", "statAccuracyDesc", function()
        local swings = stat("swingCount")
        local hits   = stat("hitCount")
        if swings == 0 then return { string = "N/A" } end
        local pct = math.floor((hits / swings) * 100)
        return { string = string.format("%d%%", pct) }
    end, "showCombatAccuracy", "swingCount")

    addLine("SC_COMBAT", "MISS_COUNT", "statMissTitle", "statMissDesc", function()
        local swings = stat("swingCount")
        local hits   = stat("hitCount")
        return { string = fmtNum(swings - hits) }
    end, "showMissCount", "swingCount")

    addLine("SC_COMBAT", "KNOCKDOWN_COUNT", "statKnockdownTitle", "statKnockdownDesc", function()
        return { string = fmtNum(stat("knockdownCount")) }
    end, "showKnockdownCount", "knockdownCount")

    addLine("SC_COMBAT", "SNEAK_ATTACK_COUNT", "statSneakAttackTitle", "statSneakAttackDesc", function()
        return { string = fmtNum(stat("sneakAttackCount")) }
    end, "showSneakAttackCount", "sneakAttackCount")

    addLine("SC_COMBAT", "HEADSHOT_COUNT", "statHeadshotTitle", "statHeadshotDesc", function()
        return { string = fmtNum(stat("headshotCount")) }
    end, "showHeadshotCount", "headshotCount")

    queueLine("SC_COMBAT", "KD_RATIO", {
        label = L("statKDRatioTitle"),
        labelColor = C.Colors.DEFAULT,
        value = function()
            local ratio = derived.kdRatio(profileIdRef)
            if not ratio then return { string = "N/A" } end
            if ratio == math.huge then return { string = "∞" } end
            return { string = string.format("%.2f", ratio) }
        end,
        tooltip = function()
            return API.TooltipBuilders.HEADER(L("statKDRatioTitle"), L("statKDRatioDesc"), "")
        end,
        visibleFn = function()
            return mS.isVisible("showKDRatio")
        end,
    }, L("statKDRatioTitle"), function()
        return stat("killCount")
    end)

    -- Weapons Used — shows total unique weapons used for kills.
    -- Tooltip displays top 20 weapons by kill count.
    queueLine("SC_COMBAT", "WEAPONS_USED", {
        label = L("statWeaponsUsedTitle"),
        labelColor = C.Colors.DEFAULT,
        value = function()
            if not state.getTopWeapons then return { string = "—" } end
            local top = state.getTopWeapons(999)
            return { string = tostring(#top) }
        end,
        tooltip = function()
            if not state.getTopWeapons then
                return API.TooltipBuilders.HEADER(L("statWeaponsUsedTitle"), "No data", "")
            end
            local top = state.getTopWeapons(20)
            local lines = {}
            for _, entry in ipairs(top) do
                lines[#lines + 1] = entry.name .. ": " .. tostring(entry.count)
            end
            return API.TooltipBuilders.HEADER(
                L("statWeaponsUsedTooltip"),
                #lines > 0 and table.concat(lines, "\n") or "No kills recorded yet.",
                ""
            )
        end,
        visibleFn = function()
            if not mS.isVisible("showWeaponsUsed") then return false end
            if mS.displayStorage:get("hideZeroCounters") then
                if not state.getTopWeapons then return false end
                if #state.getTopWeapons(999) == 0 then return false end
            end
            return true
        end,
    }, L("statWeaponsUsedTitle"), function()
        if not state.getTopWeapons then return 0 end
        return #state.getTopWeapons(999)
    end)

    flushSection("SC_COMBAT")

    -- ================================================================
    -- GROUP: Magic
    -- ================================================================
    API.addSectionToSection("SC_MAGIC", "SC_ROOT", {
        header = "Magic",
        indent = true,
    })

    addLine("SC_MAGIC", "INTERVENTION_COUNT", "statInterventionTitle", "statInterventionDesc", function()
        return { string = fmtNum(stat("interventionCount")) }
    end, "showInterventionCount", "interventionCount")

    addLine("SC_MAGIC", "RECALL_COUNT", "statRecallTitle", "statRecallDesc", function()
        return { string = fmtNum(stat("recallCount")) }
    end, "showRecallCount", "recallCount")

    addLine("SC_MAGIC", "ALCHEMY_COUNT", "statAlchemyTitle", "statAlchemyDesc", function()
        return { string = fmtNum(stat("alchemyCount")) }
    end, "showAlchemyCount", "alchemyCount")

    addLine("SC_MAGIC", "POTION_COUNT", "statPotionTitle", "statPotionDesc", function()
        return { string = fmtNum(stat("potionCount")) }
    end, "showPotionCount", "potionCount")

    addLine("SC_MAGIC", "SPELLS_MADE", "statSpellsMadeTitle", "statSpellsMadeDesc", function()
        return { string = fmtNum(stat("spellsMade")) }
    end, "showSpellsMade", "spellsMade")

    addLine("SC_MAGIC", "ITEMS_ENCHANTED", "statItemsEnchantedTitle", "statItemsEnchantedDesc", function()
        return { string = fmtNum(stat("itemsEnchanted")) }
    end, "showItemsEnchanted", "itemsEnchanted")

    addLine("SC_MAGIC", "Trapped_COUNT", "statTrappedTitle", "statTrappedDesc", function()
        return { string = fmtNum(stat("trapCount")) }
    end, "showTrappedCount", "trapCount")

    addLine("SC_MAGIC", "BLACK_SOULS_TRAPPED", "statBlackSoulsTitle", "statBlackSoulsDesc", function()
        return { string = fmtNum(stat("blackSoulsTrapped")) }
    end, "showBlackSoulsTrapped", "blackSoulsTrapped")

    addLine("SC_MAGIC", "SPELL_EFFECTS_LEARNED", "statSpellEffectsTitle", "statSpellEffectsDesc", function()
        return { string = fmtNum(stat("spellEffectsLearned")) }
    end, "showSpellEffectsLearned", "spellEffectsLearned")

    -- Spells Cast — shows total unique spells/powers used.
    -- Tooltip displays top 20 spells by cast count.
    queueLine("SC_MAGIC", "SPELLS_CAST", {
        label = L("statSpellsCastTitle"),
        labelColor = C.Colors.DEFAULT,
        value = function()
            if not state.getTopSpells then return { string = "—" } end
            local top = state.getTopSpells(999)
            return { string = tostring(#top) }
        end,
        tooltip = function()
            if not state.getTopSpells then
                return API.TooltipBuilders.HEADER(L("statSpellsCastTitle"), "No data", "")
            end
            local top = state.getTopSpells(20)
            local lines = {}
            for _, entry in ipairs(top) do
                lines[#lines + 1] = entry.name .. ": " .. tostring(entry.count)
            end
            return API.TooltipBuilders.HEADER(
                L("statSpellsCastTooltip"),
                #lines > 0 and table.concat(lines, "\n") or "No spells cast yet.",
                ""
            )
        end,
        visibleFn = function()
            if not mS.isVisible("showSpellsCast") then return false end
            if mS.displayStorage:get("hideZeroCounters") then
                if not state.getTopSpells then return false end
                if #state.getTopSpells(999) == 0 then return false end
            end
            return true
        end,
    }, L("statSpellsCastTitle"), function()
        if not state.getTopSpells then return 0 end
        return #state.getTopSpells(999)
    end)

    flushSection("SC_MAGIC")

    -- ================================================================
    -- GROUP: Crime
    -- ================================================================
    API.addSectionToSection("SC_CRIME", "SC_ROOT", {
        header = "Crime",
        indent = true,
    })

    addLine("SC_CRIME", "HIGHEST_BOUNTY", "statHighBountyTitle", "statHighBountyDesc", function()
        return { string = fmtNum(stat("highestBounty")) }
    end, "showHighestBounty", "highestBounty")

    addLine("SC_CRIME", "MURDER_COUNT", "statMurderTitle", "statMurderDesc", function()
        return { string = fmtNum(stat("murderCount")) }
    end, "showMurderCount", "murderCount")

    addLine("SC_CRIME", "ASSAULT_COUNT", "statAssaultTitle", "statAssaultDesc", function()
        return { string = fmtNum(stat("assaultCount")) }
    end, "showAssaultCount", "assaultCount")

    addLine("SC_CRIME", "JAIL_COUNT", "statJailTitle", "statJailDesc", function()
        return { string = fmtNum(stat("jailCount")) }
    end, "showJailCount", "jailCount")

    addLine("SC_CRIME", "BOUNTIES_PAID", "statBountiesPaidTitle", "statBountiesPaidDesc", function()
        return { string = fmtNum(stat("bountiesPaid")) }
    end, "showBountiesPaid", "bountiesPaid")

    addLine("SC_CRIME", "STOLEN_ITEM_COUNT", "statStolenItemTitle", "statStolenItemDesc", function()
        return { string = fmtNum(stat("stolenItemCount")) }
    end, "showStolenItemCount", "stolenItemCount")

    addLine("SC_CRIME", "STOLEN_ITEM_VALUE", "statStolenValueTitle", "statStolenValueDesc", function()
        return { string = fmtNum(stat("stolenItemValue")) }
    end, "showStolenItemValue", "stolenItemValue")

    flushSection("SC_CRIME")

    -- ================================================================
    -- GROUP: Misc
    -- ================================================================
    API.addSectionToSection("SC_MISC", "SC_ROOT", {
        header = "Misc",
        indent = true,
    })

    addLine("SC_MISC", "SCRIB_COUNT", "statScribTitle", "statScribDesc", function()
        return { string = fmtNum(stat("scribCount")) }
    end, "showScribCount", "scribCount")

    local qlLabelKey = mS.miscStorage and mS.miscStorage:get("quickloadAsSaveScum")
        and "statSaveScumTitle" or "statQuickloadTitle"
    local qlDescKey = mS.miscStorage and mS.miscStorage:get("quickloadAsSaveScum")
        and "statSaveScumDesc" or "statQuickloadDesc"
    addLine("SC_MISC", "QUICKLOAD_COUNT", qlLabelKey, qlDescKey, function()
        return { string = fmtNum(stat("quickloadCount")) }
    end, "showQuickloadCount", "quickloadCount")

    addLine("SC_MISC", "WORLDS_DOOMED", "statWorldsDoomedTitle", "statWorldsDoomedDesc", function()
        return { string = fmtNum(stat("worldsDoomed")) }
    end, "showWorldsDoomed", "worldsDoomed")

    addLine("SC_MISC", "SKOOMA_COUNT", "statSkoomaCountTitle", "statSkoomaCountDesc", function()
        return { string = fmtNum(stat("skoomaCount")) }
    end, "showSkoomaCount", "skoomaCount")

    flushSection("SC_MISC")

    -- ================================================================
    -- GROUP: Insults (requires OpenMW 0.51+ for DialogueResponse event)
    -- ================================================================
    API.addSectionToSection("SC_INSULTS", "SC_ROOT", {
        header = "Insults",
        indent = true,
    })

    addLine("SC_INSULTS", "SWIT_COUNT", "statSwitTitle", "statSwitDesc", function()
        return { string = fmtNum(stat("switCount")) }
    end, "showSwitCount", "switCount")

    addLine("SC_INSULTS", "FETCHER_COUNT", "statFetcherTitle", "statFetcherDesc", function()
        return { string = fmtNum(stat("fetcherCount")) }
    end, "showFetcherCount", "fetcherCount")

    addLine("SC_INSULTS", "NWAH_COUNT", "statNwahTitle", "statNwahDesc", function()
        return { string = fmtNum(stat("nwahCount")) }
    end, "showNwahCount", "nwahCount")

    addLine("SC_INSULTS", "SCUM_COUNT", "statScumTitle", "statScumDesc", function()
        return { string = fmtNum(stat("scumCount")) }
    end, "showScumCount", "scumCount")

    flushSection("SC_INSULTS")

    -- ================================================================
    -- ALPHABETICAL SKILL SORTING (optional, toggleable)
    -- Overrides the SWE skill section builders to sort skills A-Z
    -- within each category (Major, Minor, Misc). Requires reloadlua.
    -- ================================================================
    if mS.displayStorage:get("sortSkillsAlpha") then
        local self = require('openmw.self')
        local T = require('openmw.types')

        local function sortedSkillBuilder(sectionId, getSkillIds)
            API.modifySection(sectionId, {
                trackedStats = { [C.TrackedStats.CLASS] = true },
                builder = function()
                    local ids = getSkillIds()
                    -- Sort by display name
                    table.sort(ids, function(a, b)
                        local nameA = core.stats.Skill.record(a).name
                        local nameB = core.stats.Skill.record(b).name
                        return nameA < nameB
                    end)
                    for _, skillId in ipairs(ids) do
                        API.addLineToSection(skillId, sectionId, API.LineBuilders.SKILL(skillId))
                    end
                end,
            })
        end

        sortedSkillBuilder(C.DefaultSections.MAJOR_SKILLS, function()
            local classRecord = T.NPC.classes.records[API.getStat(C.TrackedStats.CLASS)]
            local ids = {}
            for _, id in ipairs(classRecord.majorSkills) do ids[#ids + 1] = id end
            return ids
        end)

        sortedSkillBuilder(C.DefaultSections.MINOR_SKILLS, function()
            local classRecord = T.NPC.classes.records[API.getStat(C.TrackedStats.CLASS)]
            local ids = {}
            for _, id in ipairs(classRecord.minorSkills) do ids[#ids + 1] = id end
            return ids
        end)

        sortedSkillBuilder(C.DefaultSections.MISC_SKILLS, function()
            local classRecord = T.NPC.classes.records[API.getStat(C.TrackedStats.CLASS)]
            local majorMinor = {}
            for _, id in ipairs(classRecord.majorSkills) do majorMinor[id] = true end
            for _, id in ipairs(classRecord.minorSkills) do majorMinor[id] = true end
            local ids = {}
            for _, rec in ipairs(core.stats.Skill.records) do
                if not majorMinor[rec.id] then ids[#ids + 1] = rec.id end
            end
            return ids
        end)
    end

    statsWindowRegistered = true
    print("[Enumeratio] Stats Window counters registered")
    return true
end

module.isStatsWindowRegistered = function()
    return statsWindowRegistered
end

module.canRetryStatsWindow = function()
    return (not statsWindowRegistered) and (not statsWindowDisabled)
end

return module
