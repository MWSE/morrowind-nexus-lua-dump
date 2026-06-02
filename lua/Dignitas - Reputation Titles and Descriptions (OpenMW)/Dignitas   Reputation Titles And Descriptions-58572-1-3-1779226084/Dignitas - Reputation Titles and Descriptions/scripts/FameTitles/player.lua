-- Dignitas - Reputation Titles and Descriptions
-- Player script. Extends the Stats Window reputation line with a
-- fame title, quest titles, and faction rank breakdown in the tooltip.

local core     = require('openmw.core')
local async    = require('openmw.async')
local input    = require('openmw.input')
local ui       = require('openmw.ui')
local self     = require('openmw.self')
local types    = require('openmw.types')
local storage  = require('openmw.storage')
local I        = require('openmw.interfaces')

local MODNAME    = 'Dignitas'
local L          = core.l10n(MODNAME)
local TOOLTIP_WIDTH = 360

local TRIGGER_CYCLE_TITLE = 'Dignitas_CycleDisplayedTitle'
local TITLE_CHECK_INTERVAL = 2.0
-- Titles that already exist when a save is loaded are treated as baseline
-- state, not newly earned titles. This avoids repeated unlock messages
-- when loading an older save that has not yet persisted Dignitas state.
local TITLE_LOAD_BASELINE_SECONDS = 8.0
local TITLE_LOAD_BASELINE_REFRESH = 0.5


-- ============================================================
-- FAME TITLE THRESHOLDS
--
-- Titles are intentionally dense at low reputation, then become
-- wider thresholds as reputation gains accelerate. Reputation 50
-- is the final fame threshold.
-- ============================================================

local FAME_TITLE_THRESHOLDS = {
    { rep = 0,  key = "title_0"  },
    { rep = 1,  key = "title_1"  },
    { rep = 2,  key = "title_2"  },
    { rep = 3,  key = "title_3"  },
    { rep = 4,  key = "title_4"  },
    { rep = 5,  key = "title_5"  },
    { rep = 6,  key = "title_6"  },
    { rep = 7,  key = "title_7"  },
    { rep = 8,  key = "title_8"  },
    { rep = 9,  key = "title_9"  },
    { rep = 10, key = "title_10" },
    { rep = 12, key = "title_11" },
    { rep = 14, key = "title_12" },
    { rep = 16, key = "title_13" },
    { rep = 18, key = "title_14" },
    { rep = 20, key = "title_15" },
    { rep = 22, key = "title_16" },
    { rep = 24, key = "title_17" },
    { rep = 26, key = "title_18" },
    { rep = 28, key = "title_19" },
    { rep = 30, key = "title_20" },
    { rep = 32, key = "title_21" },
    { rep = 34, key = "title_22" },
    { rep = 36, key = "title_23" },
    { rep = 38, key = "title_24" },
    { rep = 40, key = "title_25" },
    { rep = 42, key = "title_26" },
    { rep = 44, key = "title_27" },
    { rep = 46, key = "title_28" },
    { rep = 48, key = "title_29" },
    { rep = 50, key = "title_30" },
}

local function fameKeyForRep(rep)
    rep = tonumber(rep) or 0
    local key = FAME_TITLE_THRESHOLDS[1].key
    for _, threshold in ipairs(FAME_TITLE_THRESHOLDS) do
        if rep < threshold.rep then break end
        key = threshold.key
    end
    return key
end

-- ============================================================
-- QUEST-BASED TITLES
--
-- Each entry: { questId, minStage, stages, keys = {...} }
-- When the quest exists and matches the configured stage rule,
-- its keys are added to the player's list of titles. `keys` lets
-- one quest grant multiple titles if desired.
--
-- Use `stages` for exact-stage checks where later quest stages
-- can explicitly remove or deny a title.
-- ============================================================

local QUEST_TITLES = {
    {
        questId  = "b8_meetvivec",
        minStage = 50,
        keys     = { "title_nerevarine", "title_hortator" },
    },
    {
        questId = "MS_ClutterCollector",
        stages  = { [50] = true },
        keys    = { "title_champion_of_clutter" },
    },
    {
        questId = "BM_SkaalAttack",
        stages  = { [100] = true, [110] = true },
        keys    = { "title_blodskaal" },
    },
    {
        questId = "BM_MeadHall",
        stages  = { [100] = true },
        keys    = { "title_chieftain_of_thirsk" },
    },
    {
        questId  = "HH_Stronghold",
        minStage = 300,
        keys     = { "title_lord_rethan_manor" },
    },
    {
        questId  = "HR_Stronghold",
        minStage = 300,
        keys     = { "title_lord_indarys_manor" },
    },
    {
        questId  = "HT_Stronghold",
        minStage = 300,
        keys     = { "title_lord_tel_uvirith" },
    },
}

-- ============================================================
-- SETTINGS
-- ============================================================

local SETTINGS_KEY = 'Settings_' .. MODNAME

I.Settings.registerPage {
    key         = MODNAME,
    l10n        = MODNAME,
    name        = "settings_page_name",
    description = "settings_page_desc",
}

I.Settings.registerGroup {
    key               = SETTINGS_KEY,
    page              = MODNAME,
    l10n              = MODNAME,
    name              = "settings_group_display",
    permanentStorage  = true,
    settings = {
        {
            key         = "showFameTitle",
            name        = "setting_showFameTitle",
            description = "setting_showFameTitle_desc",
            renderer    = "checkbox",
            default     = true,
        },
        {
            key         = "showQuestTitles",
            name        = "setting_showQuestTitles",
            description = "setting_showQuestTitles_desc",
            renderer    = "checkbox",
            default     = true,
        },
        {
            key         = "showFactionRanks",
            name        = "setting_showFactionRanks",
            description = "setting_showFactionRanks_desc",
            renderer    = "checkbox",
            default     = true,
        },
        {
            key         = "titleDisplayMode",
            name        = "setting_titleDisplayMode",
            description = "setting_titleDisplayMode_desc",
            renderer    = "select",
            default     = "titleDisplay_auto",
            argument    = {
                l10n  = MODNAME,
                items = {
                    "titleDisplay_auto",
                    "titleDisplay_selected",
                    "titleDisplay_selected_fame",
                    "titleDisplay_fame",
                    "titleDisplay_none",
                },
            },
        },
        {
            key         = "showTitleUnlockNotifications",
            name        = "setting_showTitleUnlockNotifications",
            description = "setting_showTitleUnlockNotifications_desc",
            renderer    = "checkbox",
            default     = false,
        },
        {
            key         = "cycleDisplayedTitleHotkey",
            name        = "setting_cycleDisplayedTitleHotkey",
            description = "setting_cycleDisplayedTitleHotkey_desc",
            renderer    = "inputBinding",
            default     = "",
            argument    = {
                key  = TRIGGER_CYCLE_TITLE,
                type = "trigger",
            },
        },
        {
            key         = "factionRanksInline",
            name        = "setting_factionRanksInline",
            description = "setting_factionRanksInline_desc",
            renderer    = "select",
            default     = "factionRanksInline_none",
            argument    = {
                l10n  = MODNAME,
                items = { "factionRanksInline_all", "factionRanksInline_none" },
            },
        },
    },
}

local settingsSection = storage.playerSection(SETTINGS_KEY)
local stateSection = storage.playerSection('State_' .. MODNAME)

local SETTING_DEFAULTS = {
    showFameTitle                 = true,
    showQuestTitles               = true,
    showFactionRanks              = true,
    titleDisplayMode              = "titleDisplay_auto",
    showTitleUnlockNotifications  = false,
    factionRanksInline            = "factionRanksInline_none",
}

local function getSetting(key)
    local val = settingsSection:get(key)
    if val == nil then return SETTING_DEFAULTS[key] end
    return val
end

-- ============================================================
-- TITLE RESOLUTION
-- ============================================================

local function makeTitleEntry(id, name, desc, category, sortOrder)
    return {
        id        = tostring(id or name or ""),
        name      = tostring(name or ""),
        desc      = tostring(desc or ""),
        category  = tostring(category or ""),
        sortOrder = tonumber(sortOrder) or 0,
    }
end

local function getFameTitle(rep)
    return L(fameKeyForRep(rep))
end

local function getFameDesc(rep)
    return L(fameKeyForRep(rep) .. "_desc")
end

local function getFameTitleEntry(rep)
    local key = fameKeyForRep(rep)
    return makeTitleEntry("fame:" .. key, L(key), L(key .. "_desc"), "fame", 900)
end

local function getQuestTitles()
    local titles = {}
    local ok, quests = pcall(types.Player.quests, self)
    if not ok or not quests then return titles end

    for _, qt in ipairs(QUEST_TITLES) do
        local qOk, q = pcall(function() return quests[qt.questId] end)
        local stage = qOk and q and q.stage or nil
        local matched = false

        if stage then
            if qt.stages then
                matched = qt.stages[stage] == true
            elseif qt.minStage then
                matched = stage >= qt.minStage
            end
        end

        if matched then
            for _, key in ipairs(qt.keys) do
                titles[#titles + 1] = makeTitleEntry(
                    "quest:" .. key,
                    L(key),
                    L(key .. "_desc"),
                    "quest",
                    700 + #titles
                )
            end
        end
    end
    return titles
end

local function getFactionRankTitles()
    local entries = {}
    local ok, factions = pcall(types.NPC.getFactions, self)
    if not ok or not factions then return entries end

    for _, factionId in ipairs(factions) do
        local fOk, factionRecord = pcall(function()
            return core.factions.records[factionId]
        end)
        if fOk and factionRecord and not factionRecord.hidden then
            local rOk, rank = pcall(types.NPC.getFactionRank, self, factionId)
            if rOk and rank and rank > 0 then
                local rankRecord = factionRecord.ranks[rank]
                local rankName = rankRecord and rankRecord.name or nil
                if rankName then
                    entries[#entries + 1] = {
                        id        = "faction:" .. tostring(factionId) .. ":" .. tostring(rank),
                        rank      = rank,
                        name      = rankName,
                        desc      = tostring(factionRecord.name or ""),
                        faction   = factionRecord.name,
                        category  = "faction",
                        sortOrder = 500 + rank,
                    }
                end
            end
        end
    end
    table.sort(entries, function(a, b) return a.rank > b.rank end)
    return entries
end



local function rewardSpellKnown(spellId)
    if not spellId then return false end
    local wanted = tostring(spellId):lower()
    local ok, spells = pcall(function() return types.Player.spells(self) end)
    if not ok or not spells then return false end
    for _, spell in pairs(spells) do
        if spell and spell.id and tostring(spell.id):lower() == wanted then return true end
    end
    return false
end

local function getOppTitlesFallback()
    local ok, cfg = pcall(require, 'scripts.cmc.config')
    if not ok or not cfg or not cfg.rewardDefs then return {} end

    local bestByPath = {}
    for _, reward in ipairs(cfg.rewardDefs) do
        local known = false
        for _, spellId in ipairs(reward.spells or {}) do
            if rewardSpellKnown(spellId) then known = true break end
        end
        if known then
            local old = bestByPath[reward.path]
            if not old or (tonumber(reward.threshold) or 0) > (tonumber(old.threshold) or 0) then
                bestByPath[reward.path] = reward
            end
        end
    end

    local descByPath = {
        mercy = 'Earned by cleansing diseased and blighted beasts.',
        disease = 'Earned by spreading common disease among beasts.',
        blight = 'Earned by spreading blight among beasts.',
    }
    local titles = {}
    for _, path in ipairs({ 'mercy', 'disease', 'blight' }) do
        local reward = bestByPath[path]
        if reward and reward.title then
            titles[#titles + 1] = makeTitleEntry(
                "external:opp:" .. path .. ":" .. tostring(reward.threshold or 0),
                reward.title,
                descByPath[path] or L("tooltip_mod_title_desc_generic"),
                "external",
                650 + #titles
            )
        end
    end
    return titles
end

local function getExternalTitles()
    local titles = {}

    local opp = I.OfPestilenceAndPurification
    if opp and type(opp.getDignitasTitles) == 'function' then
        local ok, oppTitles = pcall(opp.getDignitasTitles)
        if ok and type(oppTitles) == 'table' then
            for _, title in ipairs(oppTitles) do
                if title and title.name then
                    titles[#titles + 1] = makeTitleEntry(
                        "external:" .. tostring(title.name),
                        tostring(title.name),
                        title.desc and tostring(title.desc) or '',
                        "external",
                        650 + #titles
                    )
                end
            end
            return titles
        end
    end

    return getOppTitlesFallback()
end

-- ============================================================
-- TOOLTIP CONSTRUCTION
-- ============================================================

local function getPlayerName()
    local ok, record = pcall(types.NPC.record, self)
    if ok and record and record.name then
        return record.name
    end

    -- Fallback for older or unusual API surfaces. Keep this defensive so
    -- a missing recordId or records table cannot break the Stats Window.
    local fallbackOk, fallbackName = pcall(function()
        local records = types.NPC.records
        local recordId = self.recordId
        local fallbackRecord = records and recordId and records[recordId] or nil
        return fallbackRecord and fallbackRecord.name or ""
    end)
    if fallbackOk and fallbackName then
        return fallbackName
    end

    return ""
end

local function getStoredSelectedTitleId()
    local id = stateSection:get("selectedTitleId")
    if id == nil or id == "" then return nil end
    return tostring(id)
end

local function setStoredSelectedTitleId(id)
    if id == nil or id == "" then
        stateSection:set("selectedTitleId", "")
    else
        stateSection:set("selectedTitleId", tostring(id))
    end
end

local function getAvailableTitleEntries(rep)
    local entries = {}

    if getSetting("showFameTitle") then
        entries[#entries + 1] = getFameTitleEntry(rep)
    end

    if getSetting("showQuestTitles") then
        for _, qt in ipairs(getQuestTitles()) do entries[#entries + 1] = qt end
        for _, mt in ipairs(getExternalTitles()) do entries[#entries + 1] = mt end
    end

    if getSetting("showFactionRanks") then
        for _, entry in ipairs(getFactionRankTitles()) do entries[#entries + 1] = entry end
    end

    table.sort(entries, function(a, b)
        if a.sortOrder ~= b.sortOrder then return a.sortOrder > b.sortOrder end
        return tostring(a.name) < tostring(b.name)
    end)
    return entries
end

local function getTitleEntryById(rep, titleId)
    if not titleId then return nil end
    for _, entry in ipairs(getAvailableTitleEntries(rep)) do
        if entry.id == titleId then return entry end
    end
    return nil
end

local function getSelectedTitleEntry(rep)
    return getTitleEntryById(rep, getStoredSelectedTitleId())
end

local function buildAutomaticTitleParts(rep, includeFactionInlineSetting)
    local parts = {}

    if getSetting("showQuestTitles") then
        for _, qt in ipairs(getQuestTitles()) do
            parts[#parts + 1] = qt.name
        end
        for _, mt in ipairs(getExternalTitles()) do
            parts[#parts + 1] = mt.name
        end
    end

    if getSetting("showFactionRanks") then
        if includeFactionInlineSetting ~= true
           or getSetting("factionRanksInline") == "factionRanksInline_all" then
            for _, entry in ipairs(getFactionRankTitles()) do
                parts[#parts + 1] = entry.name
            end
        end
    end

    if getSetting("showFameTitle") then
        parts[#parts + 1] = getFameTitle(rep)
    end

    return parts
end

local function buildDisplayedTitleParts(rep)
    local mode = getSetting("titleDisplayMode")
    if mode == "titleDisplay_none" then return {} end

    if mode == "titleDisplay_fame" then
        if getSetting("showFameTitle") then return { getFameTitle(rep) } end
        return {}
    end

    if mode == "titleDisplay_selected" or mode == "titleDisplay_selected_fame" then
        local parts = {}
        local selected = getSelectedTitleEntry(rep)
        if selected then parts[#parts + 1] = selected.name end
        if mode == "titleDisplay_selected_fame" and getSetting("showFameTitle") then
            local fame = getFameTitle(rep)
            if fame ~= "" and (not selected or fame ~= selected.name) then
                parts[#parts + 1] = fame
            end
        end
        return parts
    end

    return buildAutomaticTitleParts(rep, true)
end

local function buildTooltipTitleParts(rep)
    local mode = getSetting("titleDisplayMode")
    if mode == "titleDisplay_auto" then
        return buildAutomaticTitleParts(rep, false)
    end
    return buildDisplayedTitleParts(rep)
end

--- Returns the comma-joined title line used as the tooltip header.
local function buildFullTitleLine(rep)
    local parts = {}
    parts[#parts + 1] = getPlayerName()
    for _, title in ipairs(buildTooltipTitleParts(rep)) do
        parts[#parts + 1] = title
    end
    return table.concat(parts, ", ")
end

--- Returns the string appended to the reputation number in the
--- Stats Window inline value, e.g. ", Conjurer, Sera" — leading
--- comma included iff non-empty. Governed by settings:
---   showFameTitle     : appends the fame title (always at end).
---   showQuestTitles   : appends any earned quest titles.
---   factionRanksInline: if "all", appends faction rank names;
---                       if "none", ranks are tooltip-only.
local function buildInlineValueSuffix(rep)
    local parts = buildDisplayedTitleParts(rep)
    if #parts == 0 then return "" end
    return ", " .. table.concat(parts, ", ")
end

--- Returns the multi-line tooltip body.
local function buildTooltipText(rep)
    local lines = {}

    -- Header: full composite title line (always shows everything enabled)
    lines[#lines + 1] = buildFullTitleLine(rep)
    lines[#lines + 1] = ""

    -- Fame description
    if getSetting("showFameTitle") then
        local desc = getFameDesc(rep)
        if desc and desc ~= "" then
            lines[#lines + 1] = desc
        end
    end

    -- Quest titles section
    if getSetting("showQuestTitles") then
        local questTitles = getQuestTitles()
        if #questTitles > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = L("tooltip_quest_header") .. ":"
            for _, qt in ipairs(questTitles) do
                if qt.desc and qt.desc ~= "" then
                    lines[#lines + 1] = "  " .. qt.name .. " — " .. qt.desc
                else
                    lines[#lines + 1] = "  " .. qt.name
                end
            end
        end
    end

    -- External mod titles section
    if getSetting("showQuestTitles") then
        local externalTitles = getExternalTitles()
        if #externalTitles > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = L("tooltip_mod_title_header") .. ":"
            for _, mt in ipairs(externalTitles) do
                if mt.desc and mt.desc ~= "" then
                    lines[#lines + 1] = "  " .. mt.name .. " — " .. mt.desc
                else
                    lines[#lines + 1] = "  " .. mt.name
                end
            end
        end
    end

    -- Faction standings section
    if getSetting("showFactionRanks") then
        local factionTitles = getFactionRankTitles()
        if #factionTitles > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = L("tooltip_faction_header") .. ":"
            for _, entry in ipairs(factionTitles) do
                lines[#lines + 1] = "  " .. entry.faction .. ": " .. entry.name
            end
        end
    end

    return table.concat(lines, "\n")
end

local getCurrentRep

-- ============================================================
-- DISPLAYED TITLE SELECTION AND UNLOCK NOTIFICATIONS
-- ============================================================

local function titleIdSetFromEntries(entries)
    local set = {}
    for _, entry in ipairs(entries or {}) do
        if entry.id and entry.id ~= "" then
            set[entry.id] = entry.name or entry.id
        end
    end
    return set
end

local function encodeTitleIdSet(set)
    local ids = {}
    for id in pairs(set or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    return table.concat(ids, "\n")
end

local function decodeTitleIdSet(encoded)
    local set = {}
    encoded = tostring(encoded or "")
    for id in encoded:gmatch("[^\n]+") do
        set[id] = true
    end
    return set
end

local function rememberKnownTitles(rep)
    stateSection:set("knownTitleIds", encodeTitleIdSet(titleIdSetFromEntries(getAvailableTitleEntries(rep))))
end

local function notifyNewTitles(rep)
    local entries = getAvailableTitleEntries(rep)
    local current = titleIdSetFromEntries(entries)
    local rawKnown = stateSection:get("knownTitleIds")
    local known = decodeTitleIdSet(rawKnown)

    if not getSetting("showTitleUnlockNotifications") then
        stateSection:set("knownTitleIds", encodeTitleIdSet(current))
        return
    end

    -- Old saves and first installs do not have a known-title baseline yet.
    -- Seed it silently so already-earned titles are not announced as new
    -- every time that older save is loaded.
    if rawKnown == nil or rawKnown == "" then
        stateSection:set("knownTitleIds", encodeTitleIdSet(current))
        return
    end

    for _, entry in ipairs(entries) do
        if entry.id and not known[entry.id] then
            ui.showMessage(L("msg_title_unlocked", { title = entry.name }))
        end
    end

    stateSection:set("knownTitleIds", encodeTitleIdSet(current))
end

local nextTitleCheck = 0
local loadBaselineRemaining = TITLE_LOAD_BASELINE_SECONDS
local loadBaselineRefresh = 0

local function resetTitleLoadBaseline()
    loadBaselineRemaining = TITLE_LOAD_BASELINE_SECONDS
    loadBaselineRefresh = 0
    rememberKnownTitles(getCurrentRep())
end

local function checkTitleUnlocks(dt)
    dt = tonumber(dt) or 0

    if loadBaselineRemaining > 0 then
        loadBaselineRemaining = loadBaselineRemaining - dt
        loadBaselineRefresh = loadBaselineRefresh - dt
        if loadBaselineRefresh <= 0 then
            rememberKnownTitles(getCurrentRep())
            loadBaselineRefresh = TITLE_LOAD_BASELINE_REFRESH
        end
        return
    end

    nextTitleCheck = nextTitleCheck - dt
    if nextTitleCheck > 0 then return end
    nextTitleCheck = TITLE_CHECK_INTERVAL
    notifyNewTitles(getCurrentRep())
end

local cycleTriggerRegistered = false
local function cycleDisplayedTitle()
    local rep = getCurrentRep()
    local entries = getAvailableTitleEntries(rep)
    if #entries == 0 then
        setStoredSelectedTitleId(nil)
        settingsSection:set("titleDisplayMode", "titleDisplay_none")
        ui.showMessage(L("msg_title_selection_none_available"))
        return
    end

    local currentMode = getSetting("titleDisplayMode")
    local currentId = (currentMode == "titleDisplay_selected" or currentMode == "titleDisplay_selected_fame") and getStoredSelectedTitleId() or nil
    local index = 0
    if currentId then
        for i, entry in ipairs(entries) do
            if entry.id == currentId then index = i break end
        end
    end

    local nextIndex = index + 1
    if nextIndex > #entries then
        setStoredSelectedTitleId(nil)
        settingsSection:set("titleDisplayMode", "titleDisplay_none")
        ui.showMessage(L("msg_title_selection_cleared"))
        return
    end

    local selected = entries[nextIndex]
    setStoredSelectedTitleId(selected.id)
    settingsSection:set("titleDisplayMode", "titleDisplay_selected")
    ui.showMessage(L("msg_title_selection_set", { title = selected.name }))
end

local function registerCycleTitleTrigger()
    if cycleTriggerRegistered then return end
    cycleTriggerRegistered = true
    input.registerTrigger {
        key = TRIGGER_CYCLE_TITLE,
        l10n = MODNAME,
        name = "trigger_cycle_title_name",
        description = "trigger_cycle_title_desc",
    }
    input.registerTriggerHandler(TRIGGER_CYCLE_TITLE, async:callback(cycleDisplayedTitle))
end

-- ============================================================
-- STATS WINDOW INTEGRATION
--
-- We attach to the Stats Window Extended (SWE) API.
--
-- Case A: Tamriel Rebuilt Reputation mod is active. The
--         reputation section has a builder; we wrap it so after
--         its lines are drawn we modify the Morrowind line
--         (ID "SW_PCRep") to append our fame title + tooltip.
--
-- Case B: Vanilla SWE only. We modify the default reputation
--         line directly (ID comes from DefaultLines.REPUTATION).
-- ============================================================

function getCurrentRep()
    if I.StatsWindow and I.StatsWindow.Constants and I.StatsWindow.getStat then
        return I.StatsWindow.getStat(I.StatsWindow.Constants.TrackedStats.REPUTATION) or 0
    end
    return 0
end

local statsWindowInitialized = false
local fallbackFameLineAdded = false
local wrappedLines = setmetatable({}, { __mode = "k" })

local function lineAlreadyWrapped(line)
    if wrappedLines[line] then return true end

    local markerOk, marker = pcall(function() return line.__dignitasWrapped end)
    return markerOk and marker == true
end

local function markLineWrapped(line)
    wrappedLines[line] = true
    pcall(function() line.__dignitasWrapped = true end)
end

local function withLeadingSpacer(text)
    text = tostring(text or "")
    if text == "" or text:match("^%s") then
        return text
    end
    return " " .. text
end

local function wrapLineValue(line)
    if not line or lineAlreadyWrapped(line) or type(line.value) ~= "function" then return end

    local originalValue = line.value
    line.value = function()
        local base = originalValue()
        if type(base) ~= "table" then
            base = { string = tostring(base or "") }
        end
        base.string = withLeadingSpacer(tostring(base.string or "")) .. buildInlineValueSuffix(getCurrentRep())
        return base
    end
    line.tooltip = function()
        return I.StatsWindow.TooltipBuilders.TEXT({
            text  = buildTooltipText(getCurrentRep()),
            width = TOOLTIP_WIDTH,
        })
    end

    markLineWrapped(line)
end

local function addFallbackFameLine()
    if fallbackFameLineAdded then return end
    fallbackFameLineAdded = true

    local API = I.StatsWindow
    local C   = API.Constants
    API.addLineToSection("Dignitas_FameLine", C.DefaultSections.REPUTATION, {
        label      = L("label_morrowind"),
        labelColor = C.Colors.DEFAULT,
        value = function()
            local rep = getCurrentRep()
            return { string = withLeadingSpacer(tostring(rep) .. buildInlineValueSuffix(rep)) }
        end,
        tooltip = function()
            return API.TooltipBuilders.TEXT({
                text  = buildTooltipText(getCurrentRep()),
                width = TOOLTIP_WIDTH,
            })
        end,
    })
end

local function initStatsWindow()
    -- Defensive: Stats Window Extended (or a compatible mod providing
    -- I.StatsWindow) may not be loaded. Bail silently in that case
    -- rather than throwing on every frame.
    if not I.StatsWindow
       or not I.StatsWindow.Constants
       or not I.StatsWindow.getSection then
        return
    end

    local API = I.StatsWindow
    local C   = API.Constants

    local repSection = API.getSection(C.DefaultSections.REPUTATION)
    if not repSection then return end

    if statsWindowInitialized then return end
    statsWindowInitialized = true

    if repSection.builder then
        -- Case A: wrap the existing TR/TD-rep builder.
        local originalBuilder = repSection.builder
        API.modifySection(C.DefaultSections.REPUTATION, {
            builder = function()
                originalBuilder()
                local morrowindLine = API.getLine("SW_PCRep")
                if morrowindLine then
                    wrapLineValue(morrowindLine)
                elseif getSetting("showFameTitle") then
                    addFallbackFameLine()
                end
            end,
        })
    else
        -- Case B: vanilla SWE, no builder.
        local line = API.getLine(C.DefaultLines.REPUTATION)
        if line then
            API.modifyLine(C.DefaultLines.REPUTATION, {
                value = function()
                    local rep = getCurrentRep()
                    return { string = withLeadingSpacer(tostring(rep) .. buildInlineValueSuffix(rep)) }
                end,
                tooltip = function()
                    return API.TooltipBuilders.TEXT({
                        text  = buildTooltipText(getCurrentRep()),
                        width = TOOLTIP_WIDTH,
                    })
                end,
            })
        end
    end
end

-- ============================================================
-- ENGINE HANDLERS
-- ============================================================

local function initDignitas()
    registerCycleTitleTrigger()
    initStatsWindow()
    resetTitleLoadBaseline()
end

return {
    engineHandlers = {
        onInit = initDignitas,
        onLoad = initDignitas,
        onUpdate = checkTitleUnlocks,
    },
}
