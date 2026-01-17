local types = require('openmw.types')
local debug = require('openmw.debug')
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local openDebug = require('openmw.debug')
local util = require('openmw.util')
local camera = require('openmw.camera')
local ui = require('openmw.ui')
local g = require('scripts.oneKeyActionsList.myLib')
local window = require('scripts.oneKeyActionsList.myLib.window')

local SECTION_KEY = require('scripts.oneKeyActionsList.settingsData').SECTION_KEY
local MOD_NAME = require('scripts.oneKeyActionsList.settingsData').MOD_NAME
local o = require('scripts.oneKeyActionsList.settingsData').o

local simpleList = require('scripts.oneKeyActionsList.myLib.simpleList')

local mySection = storage.playerSection(SECTION_KEY)
local function getSettings(section, key)
end
mySection:subscribe(async:callback(getSettings))
getSettings()

---@type Window|{}
local mainWindow = {
        ---@type ui.Element|{}
        element = {}
}

local TEXT_SIZE = 16

---@class OneKeyActionsListData
---@field getName fun(): string
---@field action fun(): boolean|nil
-- -@field removeContent function

---@type OneKeyActionsListData
local currentWindowData

local function showWindows()
        local screenSize = ui.screenSize()
        g.myVars.scale = screenSize.x / ui.layers[1].size.x
        g.myVars.res = screenSize / g.myVars.scale

        -- if currentWindowData then
        --         currentWindowData.removeContent()
        -- end

        if mainWindow.element and mainWindow.element.layout then
                mainWindow.element:destroy()
        end

        ---@type SimpleListData[]
        local simpleListData = {}

        ---@param interfaceName string
        ---@param obj {oneKeyActionsListData : OneKeyActionsListData}
        for interfaceName, obj in pairs(I) do
                local dataList = obj.oneKeyActionsListData
                if not dataList then
                        goto continue
                end
                ---@param data OneKeyActionsListData
                for _, data in pairs(dataList) do
                        local listObj = {
                                text = data.getName(),
                                action = function()
                                        return data.action() == true
                                end,
                        }
                        table.insert(simpleListData, listObj)
                end
                ::continue::
        end

        table.sort(simpleListData, function(a, b)
                return a.text < b.text
        end)


        ---@type SimpleListData[]
        local gameActionsListData = {
                -- {
                --         text = 'Open Interface',
                --         action = function()
                --                 I.UI.setMode('Interface')
                --                 return true
                --         end
                -- },
                {
                        text = 'Open Journal',
                        action = function()
                                I.UI.setMode('Journal')
                                return true
                        end
                },
                {
                        text = 'Rest',
                        action = function()
                                I.UI.setMode('Rest')
                                return true
                        end
                },
                {
                        text = 'Ready Spell' .. (types.Actor.getStance(self) == types.Actor.STANCE.Spell
                                and ' (Active)' or ''),
                        action = function()
                                types.Actor.setStance(self, types.Actor.STANCE.Spell)
                        end
                },
                {
                        text = 'Ready Weapon' .. (types.Actor.getStance(self) == types.Actor.STANCE.Weapon
                                and ' (Active)' or ''),
                        action = function()
                                types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                        end
                },
                {
                        text = 'No Spell/Weapon' .. (types.Actor.getStance(self) == types.Actor.STANCE.Nothing
                                and ' (Active)' or ''),
                        action = function()
                                types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                        end
                },
        }

        ---@type SimpleListData[]
        local cameraActionsListData = {
                {
                        text = 'First Person',
                        action = function()
                                camera.setMode(camera.MODE.FirstPerson, false)
                        end
                },
                {
                        text = 'Preview',
                        action = function()
                                camera.setMode(camera.MODE.Preview, false)
                        end
                },
                {
                        text = 'Static',
                        action = function()
                                camera.setMode(camera.MODE.Static, false)
                        end
                },
                {
                        text = 'Third Person',
                        action = function()
                                camera.setMode(camera.MODE.ThirdPerson, false)
                        end
                },
                {
                        text = 'show/hide HUD',
                        action = function()
                                I.UI.setHudVisibility(not I.UI.isHudVisible())
                        end
                },
        }


        ---@type SimpleListData[]
        local debugActionsListData = {
                {
                        text = 'toggle ActorsPaths',
                        action = function()
                                debug.toggleRenderMode(openDebug.RENDER_MODE.ActorsPaths)
                        end,
                },
                {
                        text = 'toggle CollisionDebug',
                        action = function()
                                debug.toggleRenderMode(openDebug.RENDER_MODE.CollisionDebug)
                        end,
                },
                {
                        text = 'toggle NavMesh',
                        action = function()
                                debug.toggleRenderMode(openDebug.RENDER_MODE.NavMesh)
                        end,
                },
                {
                        text = 'toggle Pathgrid',
                        action = function()
                                debug.toggleRenderMode(openDebug.RENDER_MODE.Pathgrid)
                        end,
                },
                {
                        text = 'toggle RecastMesh',
                        action = function()
                                debug.toggleRenderMode(openDebug.RENDER_MODE.RecastMesh)
                        end,
                },
                -- {
                --         text = 'toggle Scene',
                --         action = function()
                --                 debug.toggleRenderMode(openDebug.RENDER_MODE.Scene)
                --         end,
                -- },
                -- {
                --         text = 'toggle Water',
                --         action = function()
                --                 debug.toggleRenderMode(openDebug.RENDER_MODE.Water)
                --         end,
                -- },
                {
                        text = 'toggle Wireframe',
                        action = function()
                                debug.toggleRenderMode(openDebug.RENDER_MODE.Wireframe)
                        end,
                },
        }

        mainWindow = window:new(MOD_NAME, {
                {
                        name = 'Mod Actions',
                        getContent = function()
                                g.myVars.currentList = simpleList:new(simpleListData)
                                g.myVars.currentList.parentElement = g.myVars.currentList.layout
                                g.myVars.currentList:highlight()
                                return g.myVars.currentList.layout
                        end
                },
                {
                        name = 'Game Actions',
                        getContent = function()
                                g.myVars.currentList = simpleList:new(gameActionsListData)
                                g.myVars.currentList.parentElement = g.myVars.currentList.layout
                                g.myVars.currentList:highlight()
                                return g.myVars.currentList.layout
                        end
                },
                {
                        name = 'Camera',
                        getContent = function()
                                g.myVars.currentList = simpleList:new(cameraActionsListData)
                                g.myVars.currentList.parentElement = g.myVars.currentList.layout
                                g.myVars.currentList:highlight()
                                return g.myVars.currentList.layout
                        end
                },
                {
                        name = 'Debug',
                        getContent = function()
                                g.myVars.currentList = simpleList:new(debugActionsListData)
                                g.myVars.currentList.parentElement = g.myVars.currentList.layout
                                g.myVars.currentList:highlight()
                                return g.myVars.currentList.layout
                        end
                },
        }, mySection:get(o.windowAlpha.key))

        g.myVars.mainWindow = mainWindow

        mainWindow.tabManager.selectTab(1)
end

local function showWindowTriggerCallback()
        if mainWindow.element.layout then
                mainWindow.element:destroy()
                I.UI.setMode(nil)
        elseif not I.UI.getMode() then
                g.controls.reset()
                showWindows()
                I.UI.setMode('Interface', { windows = {} })
        end

        -- if I.UI.getMode() ~= nil then
        --         -- if mainWindow.element.layout then
        --         --         mainWindow.element:destroy()
        --         --         I.UI.setMode(nil)
        --         -- elseif currentWindowData then
        --         --         currentWindowData.removeContent()
        --         -- end
        -- else
        --         showWindows()
        --         I.UI.setMode('Interface', { windows = {} })
        -- end
end

input.registerTriggerHandler(o.showoneOneKeyActionsListWindow.argument.key, async:callback(showWindowTriggerCallback))
input.registerTriggerHandler(o.GP_showoneOneKeyActionsListWindow.argument.key, async:callback(showWindowTriggerCallback))

return {
        engineHandlers = {

                onFrame = function()
                        if mainWindow.element.layout then
                                g.controls.checkKey("up", function()
                                        g.myVars.currentList:listNext(-1)
                                end, true)

                                g.controls.checkKey("down", function()
                                        g.myVars.currentList:listNext(1)
                                end, true)
                                g.controls.checkKey("left", function()
                                        g.myVars.mainWindow.tabManager.prevTab()
                                end, true)
                                g.controls.checkKey("right", function()
                                        g.myVars.mainWindow.tabManager.nextTab()
                                end, true)
                                g.controls.checkKey("select", function()
                                        g.myVars.currentList:selectCurrent()
                                end, false)
                        end
                end,

                onUpdate = function()
                        for _ = 1, #g.myVars.myDelayedActions do
                                table.remove(g.myVars.myDelayedActions):update()
                        end
                end,

                onControllerButtonPress = function(id)
                        g.controls.handlePress(id, true)
                end,
                onControllerButtonRelease = function(id)
                        g.controls.handlePress(id, nil)
                end,
                onKeyPress = function(e)
                        g.controls.handlePress(e.code, true)
                end,
                onKeyRelease = function(e)
                        g.controls.handlePress(e.code, nil)
                end

        },
        eventHandlers = {
                UiModeChanged = function(data)
                        if not data.newMode then
                                if mainWindow.element.layout then
                                        mainWindow.element:destroy()
                                end
                        end
                end,
        }
}
