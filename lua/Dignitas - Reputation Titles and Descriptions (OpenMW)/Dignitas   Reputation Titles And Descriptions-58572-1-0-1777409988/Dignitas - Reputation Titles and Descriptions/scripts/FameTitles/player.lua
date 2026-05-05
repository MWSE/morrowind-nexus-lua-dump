-- Dignitas - Reputation Titles and Descriptions
-- Player script. Extends the Stats Window reputation line with a
-- fame title, quest titles, and faction rank breakdown in the tooltip.

local core     = require('openmw.core')
local self     = require('openmw.self')
local types    = require('openmw.types')
local storage  = require('openmw.storage')
local I        = require('openmw.interfaces')

local MODNAME    = 'Dignitas'
local L          = core.l10n(MODNAME)
local TOOLTIP_WIDTH = 360

-- ============================================================
-- FAME TITLE THRESHOLDS
-- ============================================================

local FAME_TITLE_COUNT = 31  -- titles 0..30 inclusive

local function fameKeyForRep(rep)
    if rep < 0 then rep = 0 end
    if rep > FAME_TITLE_COUNT - 1 then rep = FAME_TITLE_COUNT - 1 end
    return "title_" .. rep
end

-- ============================================================
-- QUEST-BASED TITLES
--
-- Each entry: { questId, minStage, keys = {...} }
-- When the quest exists and is at/past minStage, its keys are
-- added to the player's list of titles. `keys` lets one quest
-- grant multiple titles if desired.
-- ============================================================

local QUEST_TITLES = {
    {
        questId  = "b8_meetvivec",
        minStage = 50,
        keys     = { "title_nerevarine", "title_hortator" },
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

local SETTING_DEFAULTS = {
    showFameTitle      = true,
    showQuestTitles    = true,
    showFactionRanks   = true,
    factionRanksInline = "factionRanksInline_none",
}

local function getSetting(key)
    local val = settingsSection:get(key)
    if val == nil then return SETTING_DEFAULTS[key] end
    return val
end

-- ============================================================
-- TITLE RESOLUTION
-- ============================================================

local function getFameTitle(rep)
    return L(fameKeyForRep(rep))
end

local function getFameDesc(rep)
    return L(fameKeyForRep(rep) .. "_desc")
end

local function getQuestTitles()
    local titles = {}
    local ok, quests = pcall(types.Player.quests, self)
    if not ok or not quests then return titles end

    for _, qt in ipairs(QUEST_TITLES) do
        local qOk, q = pcall(function() return quests[qt.questId] end)
        if qOk and q and q.stage and q.stage >= qt.minStage then
            for _, key in ipairs(qt.keys) do
                titles[#titles + 1] = {
                    name = L(key),
                    desc = L(key .. "_desc"),
                }
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
                        rank    = rank,
                        name    = rankName,
                        faction = factionRecord.name,
                    }
                end
            end
        end
    end
    table.sort(entries, function(a, b) return a.rank > b.rank end)
    return entries
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

--- Returns the full comma-joined title line:
---   "PlayerName, [faction ranks...], [quest titles...], [fame title]"
--- Used at the top of the tooltip as a header. For the inline
--- stats-window value, see buildInlineValueSuffix.
local function buildFullTitleLine(rep)
    local parts = {}
    parts[#parts + 1] = getPlayerName()

    if getSetting("showQuestTitles") then
        for _, qt in ipairs(getQuestTitles()) do
            parts[#parts + 1] = qt.name
        end
    end

    if getSetting("showFactionRanks") then
        for _, entry in ipairs(getFactionRankTitles()) do
            parts[#parts + 1] = entry.name
        end
    end

    if getSetting("showFameTitle") then
        parts[#parts + 1] = getFameTitle(rep)
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
    local parts = {}

    if getSetting("showQuestTitles") then
        for _, qt in ipairs(getQuestTitles()) do
            parts[#parts + 1] = qt.name
        end
    end

    if getSetting("showFactionRanks")
       and getSetting("factionRanksInline") == "factionRanksInline_all" then
        for _, entry in ipairs(getFactionRankTitles()) do
            parts[#parts + 1] = entry.name
        end
    end

    if getSetting("showFameTitle") then
        parts[#parts + 1] = getFameTitle(rep)
    end

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

local function getCurrentRep()
    return I.StatsWindow.getStat(I.StatsWindow.Constants.TrackedStats.REPUTATION) or 0
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

return {
    engineHandlers = {
        onInit = initStatsWindow,
        onLoad = initStatsWindow,
    },
}
