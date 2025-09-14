local interfaces = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local common = require('scripts.VanillaRetroactiveHealth.common')

local settings = require('scripts.VanillaRetroactiveHealth.settings')

local state = {
    isInitialized = false,
    enduranceIncreases = {}
}

--- Returns the number rounded to the number of decimal places.
--- @param num number
--- @param decimalPlaces number
--- @return number
local function round(num, decimalPlaces)
    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

--- Returns the sum of the values in the list.
--- @param list table
--- @return number
local function sum(list)
    local total = 0

    for _, v in ipairs(list) do
        total = total + v
    end

    return total
end

--- Returns the player's current endurance.
--- @return integer
local function getEndurance()
    return types.Actor.stats.attributes.endurance(self).base
end

--- Returns the player's current base health.
--- @return number
local function getBaseHealth()
    return round(types.Actor.stats.dynamic.health(self).base, 1)
end

--- Returns the player's current health.
--- @return number
local function getCurrentHealth()
    return round(types.Actor.stats.dynamic.health(self).current, 1)
end

--- Returns a list of endurance increases for maximized health.
--- For example, 6 increases becomes {5, 1, 0}.
--- @param totalIncreases number
--- @param length number
--- @return table
local function maximizeEnduranceIncreases(totalIncreases, length)
    local result = {}

    for i = 1, length do
        local take = math.min(5, totalIncreases)
        result[i] = take
        totalIncreases = totalIncreases - take
    end

    return result
end

--- Returns a list of endurance increases for minimized health.
--- For example, 6 increases becomes {0, 1, 5}.
--- @param totalIncreases number
--- @param length number
--- @return table
local function minimizeEnduranceIncreases(totalIncreases, length)
    local result = {}

    for i = length, 1, -1 do
        local take = math.min(5, totalIncreases)
        result[i] = take
        totalIncreases = totalIncreases - take
    end

    return result
end

--- Returns a list of endurance increases for balanced health.
--- For example, 6 increases becomes {2, 2, 2}.
--- @param totalIncreases number
--- @param length number
--- @return table
local function balanceEnduranceIncreases(totalIncreases, length)
    local result = {}
    local base = math.floor(totalIncreases / length)
    local remainder = totalIncreases % length

    for i = 1, length do
        result[i] = base
    end

    local mid = math.floor((length + 1) / 2)
    local offset = 0

    while remainder > 0 do
        local left = mid - offset
        local right = mid + offset

        if left >= 1 then
            result[left] = result[left] + 1
            remainder = remainder - 1

            if remainder == 0 then
                break
            end
        end

        if right <= length and right ~= left then
            result[right] = result[right] + 1
            remainder = remainder - 1
        end

        offset = offset + 1
    end

    return result
end

--- Returns a list of endurance increases redistributed according to the mode.
--- @param list table
--- @param mode string
--- @return table
local function redistributeEnduranceIncreases(list, mode)
    local totalIncreases = sum(list)
    local length = #list

    if mode == "Maximized" then
        return maximizeEnduranceIncreases(totalIncreases, length)
    elseif mode == "Minimized" then
        return minimizeEnduranceIncreases(totalIncreases, length)
    elseif mode == "Balanced" then
        return balanceEnduranceIncreases(totalIncreases, length)
    else
        return list
    end
end

--- Recalculates and sets the player's health according to the mode in the settings. Current health is also updated
--- based on the original ratio of current to base health.
local function recalculateHealth()
    local mode = settings.getRetroactiveHealthMode()
    local enduranceIncreases = redistributeEnduranceIncreases(state.enduranceIncreases, mode)
    local endurance = state.startingEndurance
    local health = state.startingHealth

    for _, increase in ipairs(enduranceIncreases) do
        endurance = endurance + increase
        health = round(health + 0.1 * endurance, 1)
    end

    local ratio = round(getCurrentHealth() / getBaseHealth(), 0)
    types.Actor.stats.dynamic.health(self).base = round(health, 1)
    types.Actor.stats.dynamic.health(self).current = math.max(1, math.floor(health * ratio))
end

--- Recalculates health when the setting changes.
local function onRetroactiveHealthModeChanged()
    if state.isInitialized then
        recalculateHealth()
    end
end

--- Initializes starting health and endurance after character creation finishes.
--- On level up, updates the list of endurance increases and recalculates the player's health.
--- @param data table
local function onUiModeChanged(data)
    if not state.isInitialized and data.oldMode == "ChargenClassReview" then
        state.startingHealth = getBaseHealth()
        state.startingEndurance = getEndurance()
        state.isInitialized = true
    elseif state.isInitialized and data.newMode == "LevelUp" then
        state.oldEndurance = getEndurance()
    elseif state.isInitialized and data.oldMode == "LevelUp" then
        local increase = getEndurance() - state.oldEndurance
        table.insert(state.enduranceIncreases, increase)
        recalculateHealth()
    end
end

local function onLoad(data)
    if data then
        state = data
    end
end

local function onSave()
    return state
end

interfaces.Settings.registerPage(settings.page)

for _, group in ipairs(settings.groups) do
    interfaces.Settings.registerGroup(group)
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        [common.events.RetroactiveHealthModeChanged] = onRetroactiveHealthModeChanged,
        UiModeChanged = onUiModeChanged
    },
}
