local types = require('openmw.types')
local core = require('openmw.core')
local storage = require('openmw.storage')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local util = require('openmw.util')
local g = require('scripts.Loadouts.myLib')
local o = require("scripts.Loadouts.settingsData").o
local SECTION_KEY = require("scripts.Loadouts.settingsData").SECTION_KEY
local mySection = storage.playerSection(SECTION_KEY)
local getLoadoutGraph = require('scripts.Loadouts.contents.loadoutGraph')
local myTypes = require("scripts.Loadouts.myLib.myTypes")

---@type ui.Layout
local visEqEl

local selectedLoadoutIndex = 1

---@type ui.Element|{}
local swtichPopup = {}

---@param loadoutData OneSavedLoadOut
local function equipSecondWeapon(loadoutData)
        local carriedL = loadoutData.myEq[myTypes.SLOTS.CarriedLeft]

        if not carriedL.recordId then
                if loadoutData.secondWeapon and loadoutData.secondWeapon:isValid() then
                        self:sendEvent("EquipSecondWeapon", { Weapon = loadoutData.secondWeapon })
                elseif carriedL.keepPrev and g.myVars.secondWeapon and g.myVars.secondWeapon:isValid() then
                        self:sendEvent("EquipSecondWeapon", { Weapon = g.myVars.secondWeapon })
                else
                        self:sendEvent("RemoveSecondWeaponUI")
                end
        else
                self:sendEvent("RemoveSecondWeaponUI")
        end
end



---@param quick boolean
local function equipThisLoadout(quick)
        if not selectedLoadoutIndex then return end

        -- if saved then
        --         g.myVars.savedLoadouts = saved
        -- end

        if #g.myVars.savedLoadouts == 0 then return end

        local newEq = {}

        ---@type OneSavedLoadOut
        local loadoutData =
            g.myVars.savedLoadouts[selectedLoadoutIndex]

        for slot, data in pairs(loadoutData.myEq) do
                if data.recordId then
                        newEq[slot] = data.recordId
                elseif data.keepPrev then
                        newEq[slot] = types.Actor.getEquipment(self, slot)
                end
        end

        equipSecondWeapon(loadoutData)

        if loadoutData.instrument then
                if g.myVars.instrument ~= loadoutData.instrument then
                        self:sendEvent('BC_SheatheInstrument', { actor = self, recordId = loadoutData.instrument })
                end
        else
                -- TODO : Keep previous instrument ???
                self:sendEvent('BC_SheatheInstrument', { actor = self, recordId = g.myVars.instrument })
        end


        types.Actor.setEquipment(self, newEq)

        if quick == false then
                ui.showMessage(string.format('Equipping: %s', loadoutData.name))
        else
                if g.myVars.mainWindow and g.myVars.mainWindow.tabManager then
                        table.insert(g.myVars.doLater, {
                                action = function()
                                        g.myVars.mainWindow.tabManager.contentContainer.layout.content = ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                        g.myVars.mainWindow.tabManager.contentContainer:update()
                                end,
                                skip = 2
                        })
                end

                if swtichPopup.layout then
                        swtichPopup:destroy()
                end

                swtichPopup = ui.create {
                        layer = "Notification",
                        type = ui.TYPE.Flex,
                        template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                        -- template = I.MWUI.templates.borders,
                        external = { grow = 1, stretch = 1, },
                        props = {
                                relativePosition = util.vector2(0.5, 0.1),
                                anchor = util.vector2(0.5, 0),
                                size = util.vector2(300, 100),
                                horizontal = false,
                                align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = g.myVars.savedLoadouts[selectedLoadoutIndex - 1]
                                                    and g.myVars.savedLoadouts[selectedLoadoutIndex - 1].name or '',
                                                alpha = 0.5,
                                        },

                                },
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = { text = g.myVars.savedLoadouts[selectedLoadoutIndex].name }
                                },
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = g.myVars.savedLoadouts[selectedLoadoutIndex + 1] and g.myVars.savedLoadouts[selectedLoadoutIndex + 1].name or '',
                                                alpha = 0.5,
                                        },

                                }
                        }
                }

                g.util.debounce('switchPopup', 0.8, function()
                        if swtichPopup.layout then
                                swtichPopup:destroy()
                        end
                end)
        end
end

local function prevLoadout()
        selectedLoadoutIndex = selectedLoadoutIndex - 1
        if selectedLoadoutIndex < 1 then
                selectedLoadoutIndex = 1
        end

        g.myVars.mainWindow.tabManager.contentContainer.layout.content = ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end

local function nextLoadout()
        selectedLoadoutIndex = selectedLoadoutIndex + 1
        if selectedLoadoutIndex > #g.myVars.savedLoadouts then
                selectedLoadoutIndex = #g.myVars.savedLoadouts
        end

        g.myVars.mainWindow.tabManager.contentContainer.layout.content = ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end


local function switchPrev(saved)
        selectedLoadoutIndex = selectedLoadoutIndex - 1
        if selectedLoadoutIndex < 1 then
                selectedLoadoutIndex = 1
        end

        equipThisLoadout(true)
end
local function switchNext(saved)
        selectedLoadoutIndex = selectedLoadoutIndex + 1
        if selectedLoadoutIndex > #saved then
                selectedLoadoutIndex = #saved
        end

        equipThisLoadout(true)
end



local focusGainCall = async:callback(function(_, l)
        l.props.textColor = g.colors.hover
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end)


local focusLossCall = async:callback(function(_, l)
        l.props.textColor = g.colors.normal
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end)


---@return ui.Layout
local function getSavedLoadoutsLO()
        if #g.myVars.savedLoadouts == 0 then
                return g.gui.centerflex {

                        {
                                template = I.MWUI.templates.textHeader,
                                props = {
                                        text = 'No saved loadouts',
                                        textSize = 20,
                                }
                        }

                }
        end


        local allEls = {}



        for i = 1, #g.myVars.savedLoadouts do
                local loadoutData = g.myVars.savedLoadouts[i]

                local layout      = {
                        type = ui.TYPE.Flex,
                        template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                        props = {
                                relativeSize = util.vector2(0.5, 0),
                                size = util.vector2(160, g.sizes.TEXT_SIZE + 0),
                                arrange = ui.ALIGNMENT.Center,
                                horizontal = true,
                        },
                        content = ui.content {
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = string.format('%s  ', loadoutData.name),
                                                textSize = g.sizes.TEXT_SIZE,
                                                textColor = selectedLoadoutIndex == i and g.colors.selected or g.colors.normal

                                        },
                                        events = {

                                                mouseClick = async:callback(function()
                                                        selectedLoadoutIndex                                           = i
                                                        g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                            ui
                                                            .content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                        table.insert(g.myVars.myDelayedActions,
                                                                g.myVars.mainWindow.tabManager.contentContainer)
                                                end)
                                        }
                                },

                        },
                }

                table.insert(allEls, layout)
        end

        visEqEl = {
                type = ui.TYPE.Flex,
                -- template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, false),
                props = {
                        -- size = util.vector2(300, 300),

                },
                content = ui.content {
                        getLoadoutGraph(g.myVars.savedLoadouts[selectedLoadoutIndex].myEq, g.myVars.savedLoadouts[selectedLoadoutIndex].secondWeapon, g.myVars.savedLoadouts[selectedLoadoutIndex].instrument)
                }
        }

        local flexLayout = g.gui.flexV {
                g.gui.makeInt(0, 10),
                g.gui.flexH {
                        g.gui.makeInt(10, 0),
                        visEqEl,
                        g.gui.makeInt(10, 0),
                        g.gui.flexV {
                                {
                                        type = ui.TYPE.Flex,
                                        template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                                        content = ui.content(allEls)
                                },
                                g.gui.makeInt(0, 10),

                                {
                                        type = ui.TYPE.Flex,
                                        -- template = I.MWUI.templates.borders,
                                        props = {
                                                horizontal = true,
                                                -- size = util.vector2(100, g.sizes.TEXT_SIZE),
                                        },
                                        content = ui.content {
                                                --- Equip Button
                                                {
                                                        name = 'equipButton',
                                                        template = I.MWUI.templates.textNormal,

                                                        props = {
                                                                text = string.format('Equip [ %s ]',
                                                                        o.equipLoadoutKey.actualValue
                                                                ),
                                                                textSize = g.sizes.TEXT_SIZE,
                                                                textColor = g.colors.normal
                                                        },
                                                        events = {
                                                                mouseClick = async:callback(function()
                                                                        equipThisLoadout(false)
                                                                end),
                                                                focusGain = focusGainCall,
                                                                focusLoss = focusLossCall,

                                                        }
                                                },
                                                g.gui.makeInt(30, 0),
                                                --- Delete Button
                                                {
                                                        name = 'deleteButton',
                                                        template = I.MWUI.templates.textNormal,

                                                        props = {
                                                                text = 'Delete',
                                                                textSize = g.sizes.TEXT_SIZE,
                                                                textColor = g.colors.normal
                                                        },
                                                        events = {
                                                                mouseClick = async:callback(function()
                                                                        table.remove(g.myVars.savedLoadouts,
                                                                                selectedLoadoutIndex)
                                                                        prevLoadout()
                                                                end),
                                                                focusGain = focusGainCall,
                                                                focusLoss = focusLossCall,
                                                        }
                                                },


                                        }
                                },

                        }

                }

        }

        return flexLayout
end



return {
        -- init = init,
        getSavedLoadoutsLO = getSavedLoadoutsLO,
        nextLoadout = nextLoadout,
        prevLoadout = prevLoadout,
        equipThisLoadout = equipThisLoadout,
        switchNext = switchNext,
        switchPrev = switchPrev
}
