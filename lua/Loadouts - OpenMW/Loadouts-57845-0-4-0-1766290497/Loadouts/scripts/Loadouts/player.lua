local types          = require('openmw.types')
local ui             = require('openmw.ui')
local core           = require('openmw.core')
local storage        = require('openmw.storage')
local async          = require('openmw.async')
local I              = require('openmw.interfaces')
local input          = require('openmw.input')
local self           = require('openmw.self')
local myWindow       = require('scripts.Loadouts.myLib.window')
local g              = require('scripts.Loadouts.myLib')
local browsLoadouts  = require('scripts.Loadouts.contents.browsLoadouts')
local createLoadout  = require('scripts.Loadouts.contents.createLoadout')
local o              = require("scripts.Loadouts.settingsData").o
local SECTION_KEY    = require("scripts.Loadouts.settingsData").SECTION_KEY
local toolTip        = require("scripts.Loadouts.myLib.toolTip")
local mySection      = storage.playerSection(SECTION_KEY)
local selectEqWindow = require('scripts.Loadouts.contents.selectEq')

local scrollableList = require('scripts.Loadouts.myLib.scrollableList')


local tFunc = {
        keyPresses = {}
}

local keyMaps = {
        [input.KEY.W]                       = 'up',
        [input.KEY.UpArrow]                 = 'up',
        [input.CONTROLLER_BUTTON.DPadUp]    = 'up',

        [input.KEY.S]                       = 'down',
        [input.KEY.DownArrow]               = 'down',
        [input.CONTROLLER_BUTTON.DPadDown]  = 'down',

        [input.KEY.A]                       = 'left',
        [input.KEY.LeftArrow]               = 'left',
        [input.CONTROLLER_BUTTON.DPadLeft]  = 'left',

        [input.KEY.D]                       = 'right',
        [input.KEY.RightArrow]              = 'right',
        [input.CONTROLLER_BUTTON.DPadRight] = 'right',

        [input.KEY.Enter]                   = 'select',
        [input.KEY.E]                       = 'select',
        [input.CONTROLLER_BUTTON.A]         = 'select',
}
local myActions = {
        up     = 'up',
        down   = 'down',
        left   = 'left',
        right  = 'right',
        -- nextTab = 'nextTab',
        -- prevTab = 'prevTab',
        select = 'select',
}
local keys = {}
local alreadyPressed = {}
local keyPressTime = {}
local FAST_DELAY = 0.02
local NORM_DELAY = 0.48
local nextRound = false
local holdDelay = 0.23

local function checkKey(actionKey, action, hold)
        if keys[actionKey] == true then
                if hold == true then
                        if not alreadyPressed[actionKey] then
                                alreadyPressed[actionKey] = true
                                action()
                        elseif keyPressTime[actionKey] and core.getRealTime() - keyPressTime[actionKey] > holdDelay then
                                g.util.throt(tFunc.keyPresses, FAST_DELAY, action)
                        end
                elseif not alreadyPressed[actionKey] then
                        alreadyPressed[actionKey] = true
                        action()
                end
        end
end

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


---@param max? boolean
local function showWindows(max)
        local screenSize = ui.screenSize()
        g.myVars.scale = screenSize.x / ui.layers[1].size.x
        g.myVars.res = screenSize / g.myVars.scale

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
        }, max)


        if g.myVars.mainWindow.tabManager then
                g.myVars.mainWindow.tabManager.selectTab(1)
        end
end

local function hideWindows()
        if g.myVars.mainWindow.element.layout then
                g.myVars.mainWindow.element:destroy()
        end

        if selectEqWindow.element.layout then
                selectEqWindow.element:destroy()
        end

        toolTip.closed = true
        toolTip.currentId = nil
end


---@param max boolean
local showLoadoutsWindow = function(max)
        if not types.Player.isCharGenFinished(self) then return end

        if not g.myVars.mainWindow.element.layout then
                showWindows(max)

                local activeWindows = {}
                for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                        if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                                table.insert(activeWindows, window)
                        end
                end

                I.UI.setMode('Interface', { windows = activeWindows })

                return true
        else
                if selectEqWindow.element.layout then
                        selectEqWindow.element:destroy()
                else
                        hideWindows()
                        I.UI.removeMode('Interface')
                end
        end
end

input.registerTriggerHandler(o.showLoadoutsWindow.argument.key, async:callback(showLoadoutsWindow))
input.registerTriggerHandler(o.GP_showLoadoutsWindow.argument.key, async:callback(function()
        showLoadoutsWindow(true)
end))

input.registerTriggerHandler(o.switchToNextLoadout.argument.key, async:callback(function()
        browsLoadouts.switchNext(g.myVars.savedLoadouts)
end))
input.registerTriggerHandler(o.GP_switchToNextLoadout.argument.key, async:callback(function()
        browsLoadouts.switchNext(g.myVars.savedLoadouts)
end))

input.registerTriggerHandler(o.switchToPrevLoadout.argument.key, async:callback(function()
        browsLoadouts.switchPrev(g.myVars.savedLoadouts)
end))
input.registerTriggerHandler(o.GP_switchToPrevLoadout.argument.key, async:callback(function()
        browsLoadouts.switchPrev(g.myVars.savedLoadouts)
end))

---@param code number
---@param pressed true|nil
local function handlePress(code, pressed)
        if not g.myVars.mainWindow.element.layout then return end
        local key = keyMaps[code]
        if key then
                keys[key] = pressed

                if pressed then
                        keyPressTime[key] = core.getRealTime()
                else
                        alreadyPressed[key] = nil
                        keyPressTime[key] = nil
                end
        end
end

local function onMouseWheel(vertical)
        if not g.myVars.mainWindow.element.layout then return end

        for _, v in pairs(scrollableList.all) do
                v:scroll(-vertical)
                -- if v.focus then
                --         v:scroll(vertical)
                -- end
        end
        toolTip.closed = true
        toolTip.currentId = nil
end


local function keyActions()
        if not g.myVars.mainWindow.element.layout then return end
        if g.myVars.mainWindow.tabManager then
                if createLoadout.nav.inputFocused == true then return end
                if g.myVars.mainWindow.tabManager.activeTab.name == 'Create' then
                        if selectEqWindow.element.layout then
                                if selectEqWindow.view == 'list' then
                                        checkKey(myActions.up, function()
                                                selectEqWindow:listPrev()
                                        end, true)
                                        checkKey(myActions.down, function()
                                                selectEqWindow:listNext()
                                        end, true)
                                else
                                        checkKey(myActions.up, function()
                                                selectEqWindow:prev(selectEqWindow.ROW_LEN)
                                        end, true)
                                        checkKey(myActions.down, function()
                                                selectEqWindow:next(selectEqWindow.ROW_LEN)
                                        end, true)
                                        checkKey(myActions.left, function()
                                                selectEqWindow:prev(1)
                                        end, true)
                                        checkKey(myActions.right, function()
                                                selectEqWindow:next(1)
                                        end, true)
                                end

                                checkKey(myActions.select, function()
                                        selectEqWindow.itemsLayouts[selectEqWindow.index].events
                                            .mousePress()
                                end, false)
                        else
                                checkKey(myActions.up, function()
                                        createLoadout.nav:prev()
                                end, true)
                                checkKey(myActions.down, function()
                                        createLoadout.nav:next()
                                end, true)
                                checkKey(myActions.select, function()
                                        createLoadout.nav.items[createLoadout.nav.index].events
                                            .mousePress()
                                end, false)
                        end
                else
                        checkKey(myActions.up, function()
                                browsLoadouts.prevLoadout()
                        end, true)
                        checkKey(myActions.down, function()
                                browsLoadouts.nextLoadout()
                        end, true)
                        checkKey(myActions.select, function()
                                browsLoadouts.equipThisLoadout(false)
                        end, false)
                end



                if not selectEqWindow.element.layout then
                        checkKey(myActions.right, function()
                                g.myVars.mainWindow.tabManager.nextTab()
                        end, false)

                        checkKey(myActions.left, function()
                                g.myVars.mainWindow.tabManager.prevTab()
                        end, false)
                end
        end
end

return {
        interfaceName = "LoadoutsOpenwMWMod",
        interface = {
                version = 1,
                oneKeyActionsListData = {
                        {
                                getName = function()
                                        return 'Open Loadouts Window'
                                end,
                                action = function()
                                        if not g.myVars.mainWindow.element.layout then
                                                keys = {}
                                                return showLoadoutsWindow(true)
                                        end
                                end,
                        }
                },
        },



        engineHandlers = {
                onMouseWheel = onMouseWheel,
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
                        keyActions()

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
                        g.toolTip.update()
                end,
                onUpdate = function()
                        for key, v in pairs(g.util.currentDebounces) do
                                if core.getRealTime() > v[1] then
                                        v[2]()
                                        g.util.currentDebounces[key] = nil
                                end
                        end
                end,

                onControllerButtonPress = function(id)
                        toolTip.closed = true
                        toolTip.currentId = nil
                        handlePress(id, true)
                end,

                onControllerButtonRelease = function(id)
                        handlePress(id, nil)
                end,

                onKeyPress = function(e)
                        toolTip.closed = true
                        toolTip.currentId = nil
                        handlePress(e.code, true)
                end,

                onKeyRelease = function(e)
                        handlePress(e.code, nil)
                end,
                onMouseButtonPress = function()
                        toolTip.closed = true
                        toolTip.currentId = nil
                end
        },

        eventHandlers = {
                UiModeChanged = function(data)
                        if not data.newMode then
                                if selectEqWindow.element.layout then
                                        selectEqWindow.element:destroy()
                                        local activeWindows = {}
                                        for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                                                if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                                                        table.insert(activeWindows, window)
                                                end
                                        end
                                        I.UI.setMode('Interface', { windows = activeWindows })
                                else
                                        hideWindows()
                                end
                        end
                        createLoadout.nav.inputFocused = false
                end,

                -- Dual Wielding ############
                EquipSecondWeapon = function(data)
                        g.myVars.secondWeapon = data.Weapon
                end,
                RemoveSecondWeaponUI = function()
                        g.myVars.secondWeapon = nil
                end,
                -- ##########################

                -- Bardcraft ################
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
        }
}
