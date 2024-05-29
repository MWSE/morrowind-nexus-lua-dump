--[[
    RestUp Mod for OpenMW
    Developed collaboratively by Lex (GPT-4o) and Clemmerson

    This mod is free to use and modify, as long as proper credit is given.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

-- scripts/restup/player_rest_check.lua
local core = require('openmw.core')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local async = require('openmw.async')
local rng = require('scripts.restup.rng')
local time_tracker = require('scripts.restup.time_tracker')
local earlyMorningMessages = require('scripts.restup.messages.earlymorning_messages')
local midMorningMessages = require('scripts.restup.messages.midmorning_messages')
local afternoonMessages = require('scripts.restup.messages.afternoon_messages')
local midAfternoonMessages = require('scripts.restup.messages.midafternoon_messages')
local eveningMessages = require('scripts.restup.messages.evening_messages')
local nightMessages = require('scripts.restup.messages.night_messages')

local settingsGroup = storage.playerSection('Settings_RestUp')

local enabled = settingsGroup:get('enabled', true)
local enableEarlyMorning = settingsGroup:get('enableEarlyMorning', true)
local enableMidMorning = settingsGroup:get('enableMidMorning', true)
local enableAfternoon = settingsGroup:get('enableAfternoon', true)
local enableMidAfternoon = settingsGroup:get('enableMidAfternoon', true)
local enableEvening = settingsGroup:get('enableEvening', true)
local enableNight = settingsGroup:get('enableNight', true)

local lastGameTime = core.getGameTime()
local isResting = false

local function checkPlayerResting()
    local currentGameTime = core.getGameTime()
    local timeDifference = currentGameTime - lastGameTime
    lastGameTime = currentGameTime

    time_tracker.setTimePeriod(currentGameTime)
    local timePeriod = time_tracker.getTimePeriod()
    local flags = time_tracker.getFlags()

    if timeDifference > 1 then
        if timeDifference > 3500 and enabled then
            if flags.ForBirds then
                ui.showMessage("This is for the birds.")
            elseif flags.EarlyMorning and enableEarlyMorning then
                local messageIndex = math.floor(rng.customRandomRange(1, #earlyMorningMessages + 1))
                ui.showMessage(earlyMorningMessages[messageIndex])
            elseif flags.MidMorning and enableMidMorning then
                local messageIndex = math.floor(rng.customRandomRange(1, #midMorningMessages + 1))
                ui.showMessage(midMorningMessages[messageIndex])
            elseif flags.Afternoon and enableAfternoon then
                local messageIndex = math.floor(rng.customRandomRange(1, #afternoonMessages + 1))
                ui.showMessage(afternoonMessages[messageIndex])
            elseif flags.MidAfternoon and enableMidAfternoon then
                local messageIndex = math.floor(rng.customRandomRange(1, #midAfternoonMessages + 1))
                ui.showMessage(midAfternoonMessages[messageIndex])
            elseif flags.Evening and enableEvening then
                local messageIndex = math.floor(rng.customRandomRange(1, #eveningMessages + 1))
                ui.showMessage(eveningMessages[messageIndex])
            elseif flags.Night and enableNight then
                local messageIndex = math.floor(rng.customRandomRange(1, #nightMessages + 1))
                ui.showMessage(nightMessages[messageIndex])
            end
        end
        isResting = false
    else
        isResting = true
    end
end

local function onLoad(data)
    if data then
        lastGameTime = data.lastGameTime or core.getGameTime()
        isResting = data.isResting or false
        enabled = data.enabled or settingsGroup:get('enabled', true)
        enableEarlyMorning = data.enableEarlyMorning or settingsGroup:get('enableEarlyMorning', true)
        enableMidMorning = data.enableMidMorning or settingsGroup:get('enableMidMorning', true)
        enableAfternoon = data.enableAfternoon or settingsGroup:get('enableAfternoon', true)
        enableMidAfternoon = data.enableMidAfternoon or settingsGroup:get('enableMidAfternoon', true)
        enableEvening = data.enableEvening or settingsGroup:get('enableEvening', true)
        enableNight = data.enableNight or settingsGroup:get('enableNight', true)
    else
        lastGameTime = core.getGameTime()
        isResting = false
        enabled = settingsGroup:get('enabled', true)
        enableEarlyMorning = settingsGroup:get('enableEarlyMorning', true)
        enableMidMorning = settingsGroup:get('enableMidMorning', true)
        enableAfternoon = settingsGroup:get('enableAfternoon', true)
        enableMidAfternoon = settingsGroup:get('enableMidAfternoon', true)
        enableEvening = settingsGroup:get('enableEvening', true)
        enableNight = settingsGroup:get('enableNight', true)
    end
end

local function onSave()
    return {
        lastGameTime = lastGameTime,
        isResting = isResting,
        enabled = enabled,
        enableEarlyMorning = enableEarlyMorning,
        enableMidMorning = enableMidMorning,
        enableAfternoon = enableAfternoon,
        enableMidAfternoon = enableMidAfternoon,
        enableEvening = enableEvening,
        enableNight = enableNight
    }
end

local function updateSettings()
    enabled = settingsGroup:get('enabled', true)
    enableEarlyMorning = settingsGroup:get('enableEarlyMorning', true)
    enableMidMorning = settingsGroup:get('enableMidMorning', true)
    enableAfternoon = settingsGroup:get('enableAfternoon', true)
    enableMidAfternoon = settingsGroup:get('enableMidAfternoon', true)
    enableEvening = settingsGroup:get('enableEvening', true)
    enableNight = settingsGroup:get('enableNight', true)
end

settingsGroup:subscribe(async:callback(updateSettings))

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = function(dt)
            checkPlayerResting()
        end
    }
}