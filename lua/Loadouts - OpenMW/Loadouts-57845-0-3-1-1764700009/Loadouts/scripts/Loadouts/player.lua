local types = require('openmw.types')
local core = require('openmw.core')
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local self = require('openmw.self')
-- local openDebug = require('openmw.debug')
local myWindow = require('scripts.Loadouts.myLib.window')
local g = require('scripts.Loadouts.myLib')

local browsLoadouts = require('scripts.Loadouts.contents.browsLoadouts')
local createLoadout = require('scripts.Loadouts.contents.createLoadout')

local o = require("scripts.Loadouts.settingsData").o
local SECTION_KEY = require("scripts.Loadouts.settingsData").SECTION_KEY
local mySection = storage.playerSection(SECTION_KEY)

local dataSection = storage.playerSection('SettingsPlayerLoadoutsData')


local bindingSection = storage.playerSection('OMWInputBindings')
local function updateKeyBind(settingsObj, def)
        local newBind = mySection:get(settingsObj.key)
        local bindings = bindingSection:asTable()
        local mybind = bindings[newBind]
        if mybind then
                if type(mybind.button) ~= "number" then
                        bindingSection:set(newBind, def)
                        return
                end
                local newButton = input.getKeyName(mybind.button)
                if settingsObj.value ~= newButton then
                        settingsObj.value = newButton
                else
                        for i, v in pairs(bindings) do
                                if v.key == settingsObj.argument.key then
                                        bindingSection:set(i, def)
                                end
                        end
                        settingsObj.value = newBind
                end
        end
end


local function getSettings(keyForSection, key)
        if key == o.showLoadoutsWindow.key then
                updateKeyBind(o.showLoadoutsWindow, nil)
        end
        if key == o.equipLoadoutKey.key then
                updateKeyBind(o.equipLoadoutKey, {
                        button = input.KEY.E,
                        device = 'keyboard',
                        key = o.equipLoadoutKey.argument.key,
                        type = 'trigger',
                })
        end
        if key == o.switchToNextLoadout.key then
                updateKeyBind(o.switchToNextLoadout, nil)
        end
        if key == o.switchToPrevLoadout.key then
                updateKeyBind(o.switchToPrevLoadout, nil)
        end

        local bind = bindingSection:get(mySection:get(o.equipLoadoutKey.key))
        if bind then
                o.equipLoadoutKey.actualValue = input.getKeyName(bind.button)
        end
end

mySection:subscribe(async:callback(getSettings))

getSettings()

-- ---@type myWindow
-- local mainWindow = {
--         element = {}
-- }

---@class MyEq
local MyEqClass = {
        ---@type string
        recordId = nil,
        ---@type string
        icon = nil,
        ---@type  boolean
        keepPrev = false,
}


---@class OneSavedLoadOut
local OneSavedLoadOut = {
        name = '',
        ---@type table<number, MyEq>
        myEq = {},
        ---@type  Weapon
        secondWeapon = nil,
        ---@type  string
        instrument = nil
}


local function showWindows()
        g.myVars.mainWindow = myWindow:new('Loadouts', 0, 0, {
                {
                        name = 'Browse',
                        getContent = function()
                                return browsLoadouts.getSavedLoadoutsLO()
                        end,
                },
                {
                        name = 'Create',
                        getContent = function()
                                return createLoadout.getCreateLoadoutLO()
                        end,
                },
        })


        if g.myVars.mainWindow.tabManager then
                g.myVars.mainWindow.tabManager.selectTab(1)
        end
end

local function hideWindows()
        if g.myVars.mainWindow.element.layout then
                g.myVars.mainWindow.element:destroy()
        end

        if g.myVars.selectEqWindow.layout then
                g.myVars.selectEqWindow:destroy()
        end
end

local showLoadoutsWindow = function()
        if not types.Player.isCharGenFinished(self) then return end
        if not g.myVars.mainWindow.element.layout then
                showWindows()

                local activeWindows = {}
                for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                        if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                                table.insert(activeWindows, window)
                        end
                end

                I.UI.setMode('Interface', { windows = activeWindows })
        else
                hideWindows()
                I.UI.removeMode('Interface')
        end
end

input.registerTriggerHandler(o.showLoadoutsWindow.argument.key, async:callback(showLoadoutsWindow))

input.registerTriggerHandler(o.switchToNextLoadout.argument.key, async:callback(function()
        browsLoadouts.switchNext(g.myVars.savedLoadouts)
end))

input.registerTriggerHandler(o.switchToPrevLoadout.argument.key, async:callback(function()
        browsLoadouts.switchPrev(g.myVars.savedLoadouts)
end))

return {
        engineHandlers = {
                onLoad = function(data)
                        if data and data.savedLoadouts and #data.savedLoadouts ~= 0 then
                                g.myVars.savedLoadouts = data.savedLoadouts
                        end
                        if data and data.windowsProps then
                                myWindow.windowsProps = data.windowsProps
                        end

                        if data then
                                g.myVars.secondWeapon = data.secondWeapon
                        else
                                g.myVars.secondWeapon = nil
                        end
                end,
                onSave = function()
                        return {
                                savedLoadouts = g.myVars.savedLoadouts,
                                windowsProps = myWindow.windowsProps,
                                secondWeapon = g.myVars.secondWeapon
                        }
                end,
                onFrame = function(dt)
                        for _ = 1, #g.myVars.myDelayedActions do
                                table.remove(g.myVars.myDelayedActions):update()
                        end

                        for i = #g.myVars.doLater, 1, -1 do
                                local entry = g.myVars.doLater[i]
                                if entry.skip <= 0 then
                                        table.remove(g.myVars.doLater, i)
                                        if entry.action then entry.action() end
                                else
                                        entry.skip = entry.skip - 1
                                end
                        end
                end,
                onUpdate = function()
                        for key, v in pairs(g.util.currentDebounces) do
                                if core.getRealTime() > v[1] then
                                        v[2]()
                                        g.util.currentDebounces[key] = nil
                                end
                        end
                end,

                onKeyRelease = function(e)
                        if not g.myVars.mainWindow.element.layout then return end
                        if not g.myVars.mainWindow.tabManager then return end
                        if g.myVars.mainWindow.tabManager.activeTab.name ~= 'Browse' then
                                return
                        end

                        if input.getRangeActionValue('MoveForward') == 1 then
                                browsLoadouts.prevLoadout()
                        elseif input.getRangeActionValue('MoveBackward') == 1 then
                                browsLoadouts.nextLoadout()
                        elseif e.code == input.KEY[o.equipLoadoutKey.actualValue] then
                                browsLoadouts.equipThisLoadout(false)
                        end
                end
        },

        eventHandlers = {
                UiModeChanged = function(data)
                        if not data.newMode then
                                hideWindows()
                        end
                end,

                -- Dual Wielding ############
                EquipSecondWeapon = function(data)
                        g.myVars.secondWeapon = data.Weapon
                end,
                RemoveSecondWeaponUI = function()
                        g.myVars.secondWeapon = nil
                end,
                -- ##########################

                -- Bradcraft ################
                BC_SheatheInstrument = function(data)
                        if g.myVars.instrument == data.recordId then
                                g.myVars.instrument = nil
                        else
                                g.myVars.instrument = data.recordId
                        end
                end,
                BC_PerformerInfo = function(data)
                        if data.actor ~= self.object then return end

                        if data.stats then
                                g.myVars.performerInfo = data.stats

                                if data.stats.sheathedInstrument then
                                        g.myVars.instrument = data.stats.sheathedInstrument
                                else
                                        g.myVars.instrument = nil
                                end
                        end
                end,
                -- ##########################

                -- ZHI_HotkeySelectEvent = function(data)
                --         if data.spell then
                --                 print(data.spell.id)
                --                 local record = core.magic.spells.records[data.spell.id]
                --                 print('record = ', record)
                --                 print('record = ', record.name)
                --                 print('record = ', record.type)
                --         end
                -- end
        }
}
