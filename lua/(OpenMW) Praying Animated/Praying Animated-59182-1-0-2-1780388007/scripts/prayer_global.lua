local types  = require('openmw.types')
local I       = require('openmw.interfaces')
local shared = require('scripts.prayer_shared')

local shrineEnabled  = shared.DEFAULTS.SHRINE_ACTIVATOR
local allowImperial  = shared.DEFAULTS.ALLOW_IMPERIAL
local allowDaedra    = shared.DEFAULTS.ALLOW_DAEDRA

local SHRINE_KEYWORDS = {}
for _, kw in ipairs(shared.SHRINE_KEYWORDS or {'shrine'}) do
    SHRINE_KEYWORDS[#SHRINE_KEYWORDS + 1] = kw:lower()
end

-- lowercase the Imperial keyword substrings
local IMPERIAL_KEYWORDS = {}
for _, kw in ipairs(shared.IMPERIAL_KEYWORDS or {}) do
    IMPERIAL_KEYWORDS[#IMPERIAL_KEYWORDS + 1] = kw:lower()
end

-- exact-name lookup sets (lowercased)
local IMPERIAL_NAMES = {}
for _, name in ipairs(shared.IMPERIAL_NAMES or {}) do
    IMPERIAL_NAMES[name:lower()] = true
end

local DAEDRA_NAMES = {}
for _, name in ipairs(shared.DAEDRA_NAMES or {}) do
    DAEDRA_NAMES[name:lower()] = true
end

-- true if `lower` belongs to the Imperial group (keyword substring or name)
local function isImperial(lower)
    if IMPERIAL_NAMES[lower] then return true end
    for _, kw in ipairs(IMPERIAL_KEYWORDS) do
        if string.find(lower, kw, 1, true) then return true end
    end
    return false
end

-- true if `lower` belongs to the Daedra group (exact name)
local function isDaedra(lower)
    return DAEDRA_NAMES[lower] == true
end

local function onActivateActivator(object, actor)
    if not shrineEnabled then return end
    if actor == nil or actor.type ~= types.Player then return end
    if object == nil then return end

    local record = types.Activator.record(object)
    local script = record and record.mwscript
    if script == nil or script == '' then return end

    local lower = script:lower()

    -- group exclusions: only allowed if the corresponding toggle is enabled
    if isImperial(lower) and not allowImperial then return end
    if isDaedra(lower)   and not allowDaedra   then return end

    local isStandardShrine = false
    for _, kw in ipairs(SHRINE_KEYWORDS) do
        if string.find(lower, kw, 1, true) then 
            isStandardShrine = true
            break 
        end
    end

    if isStandardShrine or IMPERIAL_NAMES[lower] or DAEDRA_NAMES[lower] then
        actor:sendEvent('Prayer_StartPrayer', {})
    end
end

I.Activation.addHandlerForType(types.Activator, onActivateActivator)

local function onSettingsUpdated(data)
    if data == nil then return end
    if data.SHRINE_ACTIVATOR ~= nil then shrineEnabled = data.SHRINE_ACTIVATOR end
    if data.ALLOW_IMPERIAL   ~= nil then allowImperial = data.ALLOW_IMPERIAL end
    if data.ALLOW_DAEDRA     ~= nil then allowDaedra   = data.ALLOW_DAEDRA end
end

return {
    eventHandlers = {
        Prayer_SettingsUpdated = onSettingsUpdated,
    },
}