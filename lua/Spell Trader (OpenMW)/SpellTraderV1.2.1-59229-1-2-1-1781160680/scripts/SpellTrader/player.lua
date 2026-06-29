local I = require('openmw.interfaces')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local core = require('openmw.core')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')

local SpellBuyingWindow = require('scripts.SpellTrader.ui.spellBuyingWindow')

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function gmstColor(key, fallback)
    local value = core.getGMST(key)
    if type(value) == 'string' then
        local parts = {}
        for part in value:gmatch('[^,]+') do
            parts[#parts + 1] = tonumber(part:match('^%s*(.-)%s*$'))
        end
        if #parts >= 3 and parts[1] and parts[2] and parts[3] then
            local alpha = parts[4] or 255
            return util.color.rgba(
                clamp(parts[1], 0, 255) / 255,
                clamp(parts[2], 0, 255) / 255,
                clamp(parts[3], 0, 255) / 255,
                clamp(alpha, 0, 255) / 255)
        end
    end
    return fallback
end

local settingsSection = storage.playerSection('Settings/SpellTrader/1_General')
local stateSection = storage.playerSection('SpellTrader/State')
local defaultUnknownSpellColor = gmstColor('FontColor_color_link', util.color.rgb(0.45, 0.55, 1))
local validSortFields = {
    name = true,
    school = true,
    price = true,
    unknown = true,
    new = true,
}

local ctx = {
    focusedScrollable = nil,
}

local window = SpellBuyingWindow:new(ctx)
local registered = false
local customEnabled = nil
local settingsSignature = nil
local visibleSettingsSignature = nil
local subscribedToSettings = false
local generalResetTouched = {}
local lastResetSeenSpells = nil
local savedSeenSpellIds = {}

local generalSettingDefaults = {
    EnableMod = true,
    ShowIcons = true,
    HighlightUnknownSpells = true,
    MarkNewSpells = false,
    NewSpellSeenDelay = 0.5,
    AllowWindowDrag = true,
    AllowWindowResize = true,
    ShowSortButtons = false,
    ShowSearch = false,
    ConfirmPurchase = false,
}

local generalSettingCount = 11

local function settingEnabled(key)
    return settingsSection:get(key) ~= false
end

local function settingColor(key, fallback)
    local value = settingsSection:get(key)
    if value then
        return value
    end
    return fallback
end

local function settingNumber(key, fallback, min, max)
    local value = settingsSection:get(key)
    if type(value) ~= 'number' then
        value = fallback
    end
    return clamp(value, min, max)
end

local function seenSpellIds()
    local seen = {}
    for spellId, value in pairs(savedSeenSpellIds) do
        if value == true then
            seen[spellId] = true
        end
    end
    return seen
end

local function markNewSpellsEnabled()
    return settingsSection:get('MarkNewSpells') == true
end

local function sortPreference()
    local field = stateSection:get('SortField')
    if not validSortFields[field] or (field == 'new' and not markNewSpellsEnabled()) then
        field = 'name'
    end

    local ascending = stateSection:get('SortAscending')

    return {
        sortField = field,
        sortAscending = ascending ~= false,
    }
end

local function currentSettings()
    local sort = sortPreference()
    local windowPosition = stateSection:get('WindowPosition')
    local windowSize = stateSection:get('WindowSize')
    local windowPositionX = stateSection:get('WindowPositionX')
    local windowPositionY = stateSection:get('WindowPositionY')
    local windowSizeX = stateSection:get('WindowSizeX')
    local windowSizeY = stateSection:get('WindowSizeY')
    return {
        enableMod = settingEnabled('EnableMod'),
        showIcons = settingEnabled('ShowIcons'),
        highlightUnknownSpells = settingEnabled('HighlightUnknownSpells'),
        highlightUnknownSpellColor = settingColor('HighlightUnknownSpellColor', defaultUnknownSpellColor),
        markNewSpells = markNewSpellsEnabled(),
        newSpellSeenDelay = settingNumber('NewSpellSeenDelay', 0.5, 0, 2),
        seenSpellIds = markNewSpellsEnabled() and seenSpellIds() or {},
        allowWindowDrag = settingEnabled('AllowWindowDrag'),
        allowWindowResize = settingEnabled('AllowWindowResize'),
        showSortButtons = settingsSection:get('ShowSortButtons') == true,
        showSearch = settingsSection:get('ShowSearch') == true,
        confirmPurchase = settingsSection:get('ConfirmPurchase') == true,
        sortField = sort.sortField,
        sortAscending = sort.sortAscending,
        windowPosition = type(windowPositionX) == 'number' and type(windowPositionY) == 'number'
            and { x = windowPositionX, y = windowPositionY }
            or (type(windowPosition) == 'table' and windowPosition or nil),
        windowSize = type(windowSizeX) == 'number' and type(windowSizeY) == 'number'
            and { x = windowSizeX, y = windowSizeY }
            or (type(windowSize) == 'table' and windowSize or nil),
    }
end

local function makeVisibleSettingsSignature()
    local highlightColor = settingColor('HighlightUnknownSpellColor', defaultUnknownSpellColor)
    return table.concat({
        settingEnabled('EnableMod') and '1' or '0',
        settingEnabled('ShowIcons') and '1' or '0',
        settingEnabled('HighlightUnknownSpells') and '1' or '0',
        highlightColor:asHex(),
        markNewSpellsEnabled() and '1' or '0',
        tostring(settingNumber('NewSpellSeenDelay', 0.5, 0, 2)),
        settingEnabled('AllowWindowDrag') and '1' or '0',
        settingEnabled('AllowWindowResize') and '1' or '0',
        settingsSection:get('ShowSortButtons') == true and '1' or '0',
        settingsSection:get('ShowSearch') == true and '1' or '0',
        settingsSection:get('ConfirmPurchase') == true and '1' or '0',
    }, ':')
end

local function defaultVisibleSettingsSignature()
    return table.concat({
        '1',
        '1',
        '1',
        defaultUnknownSpellColor:asHex(),
        '0',
        '0.5',
        '1',
        '1',
        '0',
        '0',
        '0',
    }, ':')
end

local function settingMatchesDefault(key)
    if key == 'HighlightUnknownSpellColor' then
        local color = settingsSection:get(key)
        return color ~= nil and color:asHex() == defaultUnknownSpellColor:asHex()
    end
    return settingsSection:get(key) == generalSettingDefaults[key]
end

local function settingsAtExplicitDefaults()
    local color = settingsSection:get('HighlightUnknownSpellColor')
    return settingsSection:get('EnableMod') == true
        and settingsSection:get('ShowIcons') == true
        and settingsSection:get('HighlightUnknownSpells') == true
        and color ~= nil
        and color:asHex() == defaultUnknownSpellColor:asHex()
        and settingsSection:get('MarkNewSpells') == false
        and settingsSection:get('NewSpellSeenDelay') == 0.5
        and settingsSection:get('AllowWindowDrag') == true
        and settingsSection:get('AllowWindowResize') == true
        and settingsSection:get('ShowSortButtons') == false
        and settingsSection:get('ShowSearch') == false
        and settingsSection:get('ConfirmPurchase') == false
end

local function touchedDefaultSettingCount()
    local count = 0
    for key in pairs(generalResetTouched) do
        if settingMatchesDefault(key) then
            count = count + 1
        end
    end
    return count
end

local function clearSavedUiState()
    stateSection:set('SortField', nil)
    stateSection:set('SortAscending', nil)
    stateSection:set('WindowPosition', nil)
    stateSection:set('WindowSize', nil)
    stateSection:set('WindowPositionX', nil)
    stateSection:set('WindowPositionY', nil)
    stateSection:set('WindowSizeX', nil)
    stateSection:set('WindowSizeY', nil)
    window:clearSortOverride()
    window:clearSavedPosition()
end

local function syncSortReset()
    local signature = makeVisibleSettingsSignature()
    local resetBySignature = visibleSettingsSignature
        and visibleSettingsSignature ~= signature
        and signature == defaultVisibleSettingsSignature()
    local resetByButton = settingsAtExplicitDefaults()
        and touchedDefaultSettingCount() >= generalSettingCount
    if resetBySignature or resetByButton then
        clearSavedUiState()
    end
    generalResetTouched = {}
    visibleSettingsSignature = signature
end

local function makeSettingsSignature(settings)
    return table.concat({
        settings.enableMod and '1' or '0',
        settings.showIcons and '1' or '0',
        settings.highlightUnknownSpells and '1' or '0',
        settings.highlightUnknownSpellColor:asHex(),
        settings.markNewSpells and '1' or '0',
        tostring(settings.newSpellSeenDelay),
        settings.allowWindowDrag and '1' or '0',
        settings.allowWindowResize and '1' or '0',
        settings.showSortButtons and '1' or '0',
        settings.showSearch and '1' or '0',
        settings.confirmPurchase and '1' or '0',
        settings.sortField,
        settings.sortAscending and '1' or '0',
    }, ':')
end

ctx.getSettings = currentSettings

ctx.markSpellSeen = function(spellId)
    if not markNewSpellsEnabled() or spellId == nil then
        return
    end
    local spellIdText = tostring(spellId)
    local seen = seenSpellIds()
    if seen[spellIdText] == true then
        return
    end
    savedSeenSpellIds[spellIdText] = true
end

ctx.setSortPreference = function(sortField, sortAscending)
    if not validSortFields[sortField] or (sortField == 'new' and not markNewSpellsEnabled()) then
        sortField = 'name'
    end
    stateSection:set('SortField', sortField)
    stateSection:set('SortAscending', sortAscending ~= false)
end

ctx.setWindowPosition = function(position)
    if position then
        stateSection:set('WindowPositionX', position.x)
        stateSection:set('WindowPositionY', position.y)
    end
end

ctx.setWindowBounds = function(position, size)
    if position then
        stateSection:set('WindowPositionX', position.x)
        stateSection:set('WindowPositionY', position.y)
    end
    if size then
        stateSection:set('WindowSizeX', size.x)
        stateSection:set('WindowSizeY', size.y)
    end
end

local function controllerMenusEnabled()
    return I.GamepadControls
        and I.GamepadControls.isControllerMenusEnabled
        and I.GamepadControls.isControllerMenusEnabled()
end

local function applyNativeWindowState()
    if not registered or not ui._setWindowDisabled then
        return
    end
    ui._setWindowDisabled('SpellBuying', customEnabled == true)
end

local function resetSeenSpells()
    savedSeenSpellIds = {}
    stateSection:set('SeenSpellIds', nil)
    window:clearSeenHoverCandidate()
    if window:isOpen() then
        window:refresh()
    end
end

local function syncSeenSpellsReset()
    local token = settingsSection:get('ResetSeenSpells')
    if type(token) ~= 'number' then
        token = 0
    end
    if lastResetSeenSpells ~= nil and token > lastResetSeenSpells then
        resetSeenSpells()
    end
    lastResetSeenSpells = token
end

local function syncUnavailableSort()
    if not markNewSpellsEnabled() and stateSection:get('SortField') == 'new' then
        stateSection:set('SortField', 'name')
        window:clearSortOverride()
    end
end

local function syncSettings()
    syncSeenSpellsReset()
    syncUnavailableSort()
    syncSortReset()
    local settings = currentSettings()
    local enabled = settings.enableMod
    local signature = makeSettingsSignature(settings)
    local uiSettingsChanged = settingsSignature ~= nil and settingsSignature ~= signature
    settingsSignature = signature

    if customEnabled == enabled then
        if uiSettingsChanged and window:isOpen() then
            window:refresh()
        end
        return
    end

    customEnabled = enabled
    applyNativeWindowState()
    if not customEnabled and window:isOpen() then
        I.UI.removeMode('SpellBuying')
    elseif window:isOpen() then
        window:refresh()
    end
end

local function init()
    if registered or controllerMenusEnabled() then
        return
    end

    if not subscribedToSettings then
        settingsSection:subscribe(async:callback(function(_, key)
            if key and (generalSettingDefaults[key] ~= nil or key == 'HighlightUnknownSpellColor') then
                generalResetTouched[key] = true
            elseif key == 'ResetSeenSpells' then
                syncSeenSpellsReset()
            end
        end))
        subscribedToSettings = true
    end
    syncSettings()
    I.UI.registerWindow('SpellBuying', function(arg)
        syncSettings()
        if not customEnabled then
            return
        end
        window:show(arg)
    end, function()
        window:hide()
    end)
    registered = true
    applyNativeWindowState()
end

local function loadState(data)
    savedSeenSpellIds = {}
    if data and type(data.seenSpellIds) == 'table' then
        for spellId, value in pairs(data.seenSpellIds) do
            if value == true then
                savedSeenSpellIds[tostring(spellId)] = true
            end
        end
    end
    init()
end

local function saveState()
    return {
        version = 1,
        seenSpellIds = seenSpellIds(),
    }
end

return {
    eventHandlers = {
        SpellTrader_PurchaseFinished = function(data)
            window:onPurchaseFinished(data)
        end,
        SpellTrader_ShowMessage = function(data)
            if data and data.message then
                ui.showMessage(data.message)
            end
        end,
        SpellTrader_PlayBoughtSound = function()
            ambient.playSound('Item Gold Up')
        end,
    },
    engineHandlers = {
        onInit = init,
        onLoad = loadState,
        onSave = saveState,
        onFrame = function()
            syncSettings()
            window:onFrame()
        end,
        onMouseWheel = function(vertical)
            window:onMouseWheel(vertical)
        end,
    },
}
