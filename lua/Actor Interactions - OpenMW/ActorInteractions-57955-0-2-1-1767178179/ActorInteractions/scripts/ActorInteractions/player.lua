local types          = require('openmw.types')
local ambient        = require('openmw.ambient')
local camera         = require('openmw.camera')
local util           = require('openmw.util')
local nearby         = require('openmw.nearby')
local ui             = require('openmw.ui')
local core           = require('openmw.core')
local storage        = require('openmw.storage')
local async          = require('openmw.async')
local I              = require('openmw.interfaces')
local input          = require('openmw.input')
local self           = require('openmw.self')
local myWindow       = require('scripts.ActorInteractions.myLib.window')
local g              = require('scripts.ActorInteractions.myLib')
local createLoadout  = require('scripts.ActorInteractions.contents.createLoadout')
local o              = require("scripts.ActorInteractions.settingsData").o
local events         = require("scripts.ActorInteractions.events")
local toolTip        = require('scripts.ActorInteractions.myLib.toolTip')
local scrollableGrid = require('scripts.ActorInteractions.myLib.scrollableGrid')

local scrollableList = require('scripts.ActorInteractions.myLib.scrollableList')
local giveawayView   = require('scripts.ActorInteractions.contents.giveStuff')
local actorStats     = require('scripts.ActorInteractions.contents.actorStats')
local selectEqWindow = require('scripts.ActorInteractions.contents.loadoutGraph').selectEqWindow

local SECTION_KEY    = require('scripts.ActorInteractions.settingsData').SECTION_KEY
local mySection      = storage.playerSection(SECTION_KEY)


local VALID_TARGETS = {
        [types.NPC] = true,
        [types.Creature] = true,
}

local function spawnVFX(pos)
        local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.FireDamage]
        local model = types.Static.records[effect.areaStatic].model
        core.sendGlobalEvent('SpawnVfx', { model = model, position = pos })
end

local function castTestRay()
        local angle = self.rotation:getYaw()
        local pitch = self.rotation:getPitch()
        local magnitude = 1500
        local tx = math.cos(angle) * math.cos(pitch)
        local ty = math.sin(angle) * math.cos(pitch)
        local tz = math.sin(-pitch)

        local camPos = camera.getPosition()

        local target = camPos + util.vector3(ty, tx, tz) * magnitude

        ---@type RayCastingResult
        local res = nearby.castRay(camPos, target, {
                ignore = { self }
        })


        -- if res.hit then
        --         spawnVFX(res.hitPos)
        -- end

        -- for i, v in pairs(types.Potion.records) do
        --         print(i, v)
        -- end
        -- print(#types.Potion.records)

        -- for i = 2, #nearby.actors do
        --         -- print(i, nearby.actors[i])
        --         nearby.actors[i]:sendEvent(events.getAIPackage, { actor = self })
        -- end



        if res.hitObject and VALID_TARGETS[res.hitObject.type] then
                ---@type NPC
                local npc = res.hitObject



                ---@type Vector2
                local dis = self.position - npc.position

                if dis:length() > 180 then
                        ui.showMessage("Actor too far")
                        return
                end


                if types.Actor.isDead(npc) == true then
                        ui.showMessage("Actor is dead")
                        return
                end


                -- npc:sendEvent(events.getAIPackage, { actor = self })
                -- print('checkIfFollower sent')
                npc:sendEvent(events.checkIfFollower, { actor = self })


                -- if types.Actor.canMove(npc) == false then
                --         ui.showMessage("Actor is immobilized")
                --         return
                -- end

                -- if npc.type == types.NPC and types.NPC.getStance(npc) ~= types.NPC.STANCE.Nothing then
                --         ui.showMessage("Actor is in combat")
                --         return
                -- end


                -- return npc
        end

        -- ui.showMessage("No valid Actor")
end


---@param npc NPC
---@param max? boolean
---@param isFollower boolean|nil
local function showWindows(npc, max, isFollower)
        local activeWindows = {}
        for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                        table.insert(activeWindows, window)
                end
        end

        I.UI.setMode('Interface', { windows = activeWindows })

        local screenSize = ui.screenSize()
        g.myVars.scale = screenSize.x / ui.layers[1].size.x
        g.myVars.res = screenSize / g.myVars.scale

        g.myVars.mainWindow = myWindow:new('Actor Interactions', 0, 0, {
                {
                        name = g.tabName.actorStats,
                        getContent = function()
                                return actorStats.getItemsLO(npc)
                        end
                },
                {
                        name = g.tabName.giveaway,
                        getContent = function()
                                return giveawayView.getItemsLO(npc, isFollower)
                        end,
                },
        }, max, npc.type.record(npc).name .. string.format('%s', isFollower and ' (Following)' or ''))


        if g.myVars.mainWindow.tabManager then
                g.myVars.mainWindow.tabManager.selectTab(1)
        end
end

---@return ui.Element|nil
local function getExtraOpenedWindow()
        g.myVars.currentScrollable = nil

        if selectEqWindow.element.layout then
                return selectEqWindow.element
        end

        if giveawayView.giveItemsWindow.layout then
                return giveawayView.giveItemsWindow
        end
end

local function hideWindows()
        if g.myVars.mainWindow.element.layout then
                g.myVars.mainWindow.element:destroy()
        end

        if selectEqWindow.element.layout then
                selectEqWindow.element:destroy()
        end

        if giveawayView.giveItemsWindow.layout then
                selectEqWindow.element:destroy()
        end

        g.myVars.currentScrollable = nil
        toolTip.closed = true
        toolTip.currentId = nil
end

---@param max boolean
local showGiveawayWindow = function(max)
        if not types.Player.isCharGenFinished(self) then return end

        if not g.myVars.mainWindow.element.layout then
                castTestRay()
                -- local npc = castTestRay()
                -- if not npc then return end

                -- showWindows(npc, max)

                -- local activeWindows = {}
                -- for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                --         if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                --                 table.insert(activeWindows, window)
                --         end
                -- end

                -- I.UI.setMode('Interface', { windows = activeWindows })
        else
                local extraWindow = getExtraOpenedWindow()
                if extraWindow then
                        extraWindow:destroy()
                else
                        hideWindows()
                        I.UI.removeMode('Interface')
                end
        end

        return true
end

-- ---@param max boolean
-- local showGiveawayWindow = function(max)
--         if not types.Player.isCharGenFinished(self) then return end

--         if not g.myVars.mainWindow.element.layout then
--                 local npc = castTestRay()
--                 if not npc then return end

--                 showWindows(npc, max)

--                 local activeWindows = {}
--                 for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
--                         if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
--                                 table.insert(activeWindows, window)
--                         end
--                 end

--                 I.UI.setMode('Interface', { windows = activeWindows })
--         else
--                 local extraWindow = getExtraOpenedWindow()
--                 if extraWindow then
--                         extraWindow:destroy()
--                 else
--                         hideWindows()
--                         I.UI.removeMode('Interface')
--                 end
--         end

--         return true
-- end

input.registerTriggerHandler(o.openGivawayWindow.argument.key, async:callback(showGiveawayWindow))
input.registerTriggerHandler(o.GP_openGivawayWindow.argument.key, async:callback(function()
        showGiveawayWindow(true)
end))



local function keyActions()
        --- TODO : Pass a key checker function along side any window that gets created and check
        --- keys for the top most window.

        if not g.myVars.mainWindow.element.layout then return end
        if g.myVars.mainWindow.tabManager then
                if createLoadout.nav.inputFocused == true then return end
                local tabName = g.myVars.mainWindow.tabManager.activeTab.name

                if g.myVars.dressUpWindow.element.layout then
                        if selectEqWindow.element.layout then
                                if selectEqWindow.selectEqList.isGrid then
                                        g.controls.checkKey("up", function()
                                                selectEqWindow.selectEqList:listNext(-selectEqWindow.selectEqList
                                                        .ROW_LEN)
                                        end, true)

                                        g.controls.checkKey("down", function()
                                                selectEqWindow.selectEqList:listNext(selectEqWindow.selectEqList.ROW_LEN)
                                        end, true)

                                        g.controls.checkKey("left", function()
                                                selectEqWindow.selectEqList:listNext(-1)
                                        end, true)

                                        g.controls.checkKey("right", function()
                                                selectEqWindow.selectEqList:listNext(1)
                                        end, true)
                                else
                                        g.controls.checkKey("up", function()
                                                selectEqWindow.selectEqList:listNext(-1)
                                        end, true)

                                        g.controls.checkKey("down", function()
                                                selectEqWindow.selectEqList:listNext(1)
                                        end, true)
                                end

                                g.controls.checkKey("select", function()
                                        selectEqWindow.selectEqList:selectCurrent()
                                end, false)
                        else
                                g.controls.checkKey("up", function()
                                        createLoadout.nav:prev()
                                end, true)
                                g.controls.checkKey("down", function()
                                        createLoadout.nav:next()
                                end, true)
                                g.controls.checkKey("select", function()
                                        if not createLoadout.nav.items or #createLoadout.nav.items < 1 then return end
                                        createLoadout.nav.items[createLoadout.nav.index].events
                                            .mousePress()
                                end, false)
                        end
                elseif tabName == g.tabName.giveaway then
                        if giveawayView.giveItemsWindow.layout then
                                if giveawayView.itemsList.isGrid then
                                        g.controls.checkKey("up", function()
                                                giveawayView.itemsList:listNext(-giveawayView.itemsList
                                                        .ROW_LEN)
                                        end, true)

                                        g.controls.checkKey("down", function()
                                                giveawayView.itemsList:listNext(giveawayView.itemsList.ROW_LEN)
                                        end, true)

                                        g.controls.checkKey("left", function()
                                                giveawayView.itemsList:listNext(-1)
                                        end, true)

                                        g.controls.checkKey("right", function()
                                                giveawayView.itemsList:listNext(1)
                                        end, true)
                                else
                                        g.controls.checkKey("up", function()
                                                giveawayView.itemsList:listNext(-1)
                                        end, true)

                                        g.controls.checkKey("down", function()
                                                giveawayView.itemsList:listNext(1)
                                        end, true)
                                end
                                g.controls.checkKey("select", function()
                                        giveawayView.itemsList:selectCurrent()
                                end, false)
                        else
                                g.controls.checkKey("up", function()
                                        giveawayView.actionsList:listNext(-1)
                                end, true)
                                g.controls.checkKey("down", function()
                                        giveawayView.actionsList:listNext(1)
                                end, true)
                                g.controls.checkKey("select", function()
                                        giveawayView.actionsList:selectCurrent()
                                end, false)
                        end
                end

                if not selectEqWindow.element.layout and not giveawayView.giveItemsWindow.layout and not g.myVars.dressUpWindow.element.layout then
                        g.controls.checkKey("right", function()
                                g.myVars.mainWindow.tabManager.nextTab()
                        end, false)

                        g.controls.checkKey("left", function()
                                g.myVars.mainWindow.tabManager.prevTab()
                        end, false)
                end
        end
end


local function reOpenInterface()
        toolTip.currentId = nil
        local activeWindows = {}
        for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                        table.insert(activeWindows, window)
                end
        end
        I.UI.setMode('Interface', { windows = activeWindows })
end

return {
        interfaceName = "ActorInteractionsOpenMWMod",
        interface = {
                version = 1,
                oneKeyActionsListData = {
                        {
                                getName = function()
                                        return 'Open Actor Interactions Window'
                                end,
                                action = function()
                                        return showGiveawayWindow(true)
                                end,
                        },
                },
        },

        engineHandlers = {
                onMouseWheel = function(vertical)
                        if not g.myVars.mainWindow.element.layout then return end
                        toolTip.closed = true
                        toolTip.currentId = nil
                        if g.myVars.currentScrollable then
                                g.myVars.currentScrollable:scroll(-vertical)
                        end
                end,
                onLoad = function(data)
                        if not data then return end
                        if data.windowsProps then
                                myWindow.windowsProps = data.windowsProps
                        end

                        if data.trainTokens then
                                giveawayView.trainTokens = data.trainTokens
                        end
                end,
                onSave = function()
                        return {
                                windowsProps = myWindow.windowsProps,
                                trainTokens = giveawayView.trainTokens or 0,
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

                        toolTip.update()
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
                onMouseButtonPress = function()
                        toolTip.closed = true
                        toolTip.currentId = nil
                end
        },

        eventHandlers = {
                UiModeChanged = function(data)
                        if not data.newMode then
                                local closedAWindow
                                if selectEqWindow.element.layout then
                                        selectEqWindow.element:destroy()
                                        reOpenInterface()
                                        closedAWindow = true
                                elseif g.myVars.dressUpWindow.element.layout then
                                        g.myVars.dressUpWindow.element:destroy()
                                        reOpenInterface()
                                        closedAWindow = true
                                end

                                if giveawayView.giveItemsWindow.layout then
                                        giveawayView.giveItemsWindow:destroy()
                                        reOpenInterface()
                                        closedAWindow = true
                                end


                                if not closedAWindow then
                                        hideWindows()
                                end
                        end
                end,

                [events.itemMoved] = function(data)
                        giveawayView.itemsList:updateItems()
                end,

                [events.tokensRefilled] = function(data)
                        g.myVars.mainWindow.tabManager.selectTab(2)
                end,
                [events.spellDeleted] = function(data)
                        giveawayView.itemsList:updateItems()
                end,
                [events.npcTrained] = function(data)
                        giveawayView.itemsList:updateItems()
                        ui.showMessage('npc was trained')
                end,

                ---@param data {spellId: string, target: NPC}
                [events.spellTaught] = function(data)
                        ui.showMessage(string.format('You taught %s how to %s',
                                data.target.type.record(data.target).name,
                                core.magic.spells.records[data.spellId].name
                        ))
                end,

                -- -@param data {package: string, actor: NPC}
                -- [events.aIPackgeGot] = function(data)
                ---@param data {actor: NPC, isFollower: boolean}
                [events.isFollower] = function(data)
                        -- print('isFollower received ', data.isFollower)

                        -- print('data.package = ', data.package)
                        local npc = data.actor

                        if data.isFollower == true then
                                showWindows(npc, true, true)
                        else
                                if types.Actor.canMove(npc) == false then
                                        local text = string.format('%s is immobilized', npc.type.record(npc).name)
                                        ui.showMessage(text)
                                        return
                                end

                                -- if npc.type == types.NPC and types.NPC.getStance(npc) ~= types.NPC.STANCE.Nothing then
                                if types.NPC.getStance(npc) ~= types.NPC.STANCE.Nothing then
                                        local text = string.format('%s is in combat', npc.type.record(npc).name)
                                        ui.showMessage(text)
                                        return
                                end

                                showWindows(npc, true)
                        end
                end
        }
}
