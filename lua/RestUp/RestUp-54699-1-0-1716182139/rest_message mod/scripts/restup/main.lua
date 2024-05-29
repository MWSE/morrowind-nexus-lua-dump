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


local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')

I.Settings.registerPage({
    key = 'Settings_RestUp',
    l10n = 'RestUp',
    name = 'RestUp',
    description = 'RestUp mod settings',
})

I.Settings.registerGroup({
    key = 'Settings_RestUp',
    page = 'Settings_RestUp',
    l10n = 'RestUp',
    name = 'RestUp Settings',
    permanentStorage = true,
    settings = {
        { key = 'enabled', renderer = 'checkbox', name = 'Enabled', description = 'Enable or disable the RestUp mod', default = true },
        { key = 'enableEarlyMorning', renderer = 'checkbox', name = 'Enable Early Morning', description = 'Enable or disable Early Morning messages', default = true },
        { key = 'enableMidMorning', renderer = 'checkbox', name = 'Enable Mid Morning', description = 'Enable or disable Mid Morning messages', default = true },
        { key = 'enableAfternoon', renderer = 'checkbox', name = 'Enable Afternoon', description = 'Enable or disable Afternoon messages', default = true },
        { key = 'enableMidAfternoon', renderer = 'checkbox', name = 'Enable Mid Afternoon', description = 'Enable or disable Mid Afternoon messages', default = true },
        { key = 'enableEvening', renderer = 'checkbox', name = 'Enable Evening', description = 'Enable or disable Evening messages', default = true },
        { key = 'enableNight', renderer = 'checkbox', name = 'Enable Night', description = 'Enable or disable Night messages', default = true },
    }
})

return {
    engineHandlers = {
        onLoad = function()
            local settingsGroup = storage.playerSection('Settings_RestUp')
            settingsGroup:subscribe(async:callback(function()
                local enabled = settingsGroup:get('enabled', true)
                local enableEarlyMorning = settingsGroup:get('enableEarlyMorning', true)
                local enableMidMorning = settingsGroup:get('enableMidMorning', true)
                local enableAfternoon = settingsGroup:get('enableAfternoon', true)
                local enableMidAfternoon = settingsGroup:get('enableMidAfternoon', true)
                local enableEvening = settingsGroup:get('enableEvening', true)
                local enableNight = settingsGroup:get('enableNight', true)
                
                print("RestUp settings updated:")
                print("Enabled: " .. tostring(enabled))
                print("Enable Early Morning: " .. tostring(enableEarlyMorning))
                print("Enable Mid Morning: " .. tostring(enableMidMorning))
                print("Enable Afternoon: " .. tostring(enableAfternoon))
                print("Enable Mid Afternoon: " .. tostring(enableMidAfternoon))
                print("Enable Evening: " .. tostring(enableEvening))
                print("Enable Night: " .. tostring(enableNight))
            end))
        end,
    }
}