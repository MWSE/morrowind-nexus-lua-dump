local types          = require('openmw.types')
local ui             = require('openmw.ui')
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
local selectEqWindow = require('scripts.Loadouts.contents.selectEq')
local auxUi          = require('openmw_aux.ui')
local scrollableList = require('scripts.Loadouts.myLib.scrollableList')
local MOD_ID         = require("scripts.Loadouts.settingsData").MOD_ID
local core           = require('openmw.core')
local myTemplates    = require('scripts.Loadouts.myLib.myTemplates')
local l10n           = core.l10n(MOD_ID)

local UI_MODE        = I.UI.MODE.Journal


local mySection = storage.playerSection(SECTION_KEY)
local function getSettings(keyForSection, key)
        o.showCondition.value                        = mySection:get(o.showCondition.key)
        o.highlightColor.value                       = mySection:get(o.highlightColor.key)
        myTemplates.highlight.content[1].props.color = o.highlightColor.value
        o.bgAlpha.value                              = mySection:get(o.bgAlpha.key)
        o.bgAlpha_eqSelect.value                     = mySection:get(o.bgAlpha_eqSelect.key)
        o.bgAlpha_tooltip.value                      = mySection:get(o.bgAlpha_tooltip.key)
        o.toolTipDelay.value                         = mySection:get(o.toolTipDelay.key)
        o.toolTipPosX.value                          = mySection:get(o.toolTipPosX.key)
        o.toolTipPosY.value                          = mySection:get(o.toolTipPosY.key)
        o.toolTipAnchorX.value                       = mySection:get(o.toolTipAnchorX.key)
        o.toolTipAnchorY.value                       = mySection:get(o.toolTipAnchorY.key)
end
mySection:subscribe(async:callback(getSettings))
getSettings()


---@param max? boolean
local function showWindows(max)
        g.controls.resetKeys()
        ---@diagnostic disable-next-line: undefined-field
        g.myVars.res = ui.layers[ui.layers.indexOf('Windows')].size

        if I.SunsDusk then
                g.myVars.backPack.recordId = I.SunsDusk.getSaveData().backpackId
        end

        g.myVars.mainWindow = myWindow:new(l10n('Loadouts'), 0, 0, {
                {
                        name = l10n('Browse'),
                        key = 'Browse',
                        getContent = function()
                                return browsLoadouts.getSavedLoadoutsLO()
                        end,
                },
                {
                        name = core.getGMST('sCreate'),
                        key = 'Create',
                        getContent = function()
                                return createLoadout.getCreateLoadoutLO()
                        end,
                },
        }, max, o.bgAlpha.value)


        if g.myVars.mainWindow.tabManager then
                g.myVars.mainWindow.tabManager.selectTab(1)
        end
end

local function hideWindows()
        if g.myVars.mainWindow.element.layout then
                auxUi.deepDestroy(g.myVars.mainWindow.element)
                -- g.myVars.mainWindow.element:destroy()
        end

        if selectEqWindow.element.layout then
                auxUi.deepDestroy(selectEqWindow.element)
                -- selectEqWindow.element:destroy()
        end

        for _, v in pairs(scrollableList.all) do
                if v.element and v.element.layout then
                        auxUi.deepDestroy(v.element)
                end
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

                I.UI.setMode(UI_MODE, { windows = activeWindows })

                return true
        else
                if selectEqWindow.element.layout then
                        selectEqWindow.element:destroy()
                else
                        hideWindows()
                        I.UI.removeMode(UI_MODE)
                end
        end
end

input.registerTriggerHandler(o.showLoadoutsWindowRes.argument.key, async:callback(showLoadoutsWindow))

input.registerTriggerHandler(o.showLoadoutsWindow.argument.key, async:callback(function()
        showLoadoutsWindow(true)
end))
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

local function onMouseWheel(vertical)
        if not g.myVars.mainWindow.element.layout then return end


        for _, v in pairs(scrollableList.all) do
                -- v:scroll(-vertical)
                if v.element and v.element.layout then
                        v:scroll(-vertical)
                end
        end
        toolTip.closed = true
        toolTip.currentId = nil
end


local function keyActions()
        local window = g.myVars.mainWindow
        if not window.element.layout then return end
        if not window.tabManager or not window.tabManager.activeTab then return end
        if createLoadout.nav.inputFocused == true then return end

        if window.tabManager.activeTab.key == 'Create' then
                if selectEqWindow.element.layout then
                        if selectEqWindow.view == 'list' then
                                g.controls.checkKey('up', function()
                                        selectEqWindow:listPrev()
                                end, true)
                                g.controls.checkKey('down', function()
                                        selectEqWindow:listNext()
                                end, true)
                        else
                                g.controls.checkKey('up', function()
                                        selectEqWindow:prev(selectEqWindow.ROW_LEN)
                                end, true)
                                g.controls.checkKey('down', function()
                                        selectEqWindow:next(selectEqWindow.ROW_LEN)
                                end, true)
                                g.controls.checkKey('left', function()
                                        selectEqWindow:prev(1)
                                end, true)
                                g.controls.checkKey('right', function()
                                        selectEqWindow:next(1)
                                end, true)
                        end

                        g.controls.checkKey('select', function()
                                selectEqWindow.itemsLayouts[selectEqWindow.index].events
                                    .mousePress()
                        end, false)
                else
                        g.controls.checkKey('up', function()
                                createLoadout.nav:prev()
                        end, true)
                        g.controls.checkKey('down', function()
                                createLoadout.nav:next()
                        end, true)
                        g.controls.checkKey('select', function()
                                createLoadout.nav.items[createLoadout.nav.index].events
                                    .mousePress()
                        end, false)
                end
        else
                g.controls.checkKey('up', function()
                        browsLoadouts.prevLoadout()
                end, true)
                g.controls.checkKey('down', function()
                        browsLoadouts.nextLoadout()
                end, true)
                g.controls.checkKey('select', function()
                        browsLoadouts.equipThisLoadout(false)
                end, false)
        end



        if not selectEqWindow.element.layout then
                g.controls.checkKey('right', function()
                        window.tabManager.nextTab()
                end, false)

                g.controls.checkKey('left', function()
                        window.tabManager.prevTab()
                end, false)
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

                        for i = #g.myVars.doLater, 1, -1 do
                                local entry = g.myVars.doLater[i]
                                if entry.skip < 1 then
                                        table.remove(g.myVars.doLater, i).action()
                                        -- if entry.action then entry.action() end
                                else
                                        entry.skip = entry.skip - 1
                                end
                        end

                        for _ = 1, #g.myVars.myDelayedActions do
                                table.remove(g.myVars.myDelayedActions):update()
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
                        g.controls.handlePress(id, true)
                end,

                onControllerButtonRelease = function(id)
                        g.controls.handlePress(id, nil)
                end,

                onKeyPress = function(e)
                        toolTip.closed = true
                        toolTip.currentId = nil
                        g.controls.handlePress(e.code, true)
                end,

                onKeyRelease = function(e)
                        g.controls.handlePress(e.code, nil)
                end,
                onMouseButtonPress = function(button)
                        toolTip.closed = true
                        toolTip.currentId = nil

                        if button == 3 then
                                if selectEqWindow.element.layout then
                                        selectEqWindow.element:destroy()
                                else
                                        hideWindows()
                                        I.UI.setMode(nil)
                                end
                        end
                end
        },

        eventHandlers = {
                UiModeChanged = function(data)
                        if not data.newMode then
                                if selectEqWindow.element.layout then
                                        selectEqWindow.element:destroy()
                                        local activeWindows = {}
                                        I.UI.setMode(UI_MODE, { windows = activeWindows })
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
                        if not g.myVars.instrument then
                                g.myVars.instrument = {
                                        recordId = nil,
                                        keepPrev = false,
                                }
                        end


                        if g.myVars.instrument.recordId == data.recordId then
                                g.myVars.instrument.recordId = nil
                        else
                                g.myVars.instrument.recordId = data.recordId
                        end
                end,
                BC_PerformerInfo = function(data)
                        if data.actor ~= self.object then return end

                        if data.stats then
                                g.myVars.performerInfo = data.stats

                                if not g.myVars.instrument then
                                        g.myVars.instrument = {
                                                recordId = nil,
                                                keepPrev = false,
                                        }
                                end

                                if data.stats.sheathedInstrument then
                                        g.myVars.instrument.recordId = data.stats.sheathedInstrument
                                else
                                        g.myVars.instrument.recordId = nil
                                end
                        end
                end,
        }
}
