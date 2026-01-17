local types                = require('openmw.types')
local core                 = require('openmw.core')
local storage              = require('openmw.storage')
local input                = require('openmw.input')
local async                = require('openmw.async')
local ui                   = require('openmw.ui')
local I                    = require('openmw.interfaces')
local self                 = require('openmw.self')
local util                 = require('openmw.util')
local g                    = require('scripts.Loadouts.myLib')
local o                    = require("scripts.Loadouts.settingsData").o
local SECTION_KEY          = require("scripts.Loadouts.settingsData").SECTION_KEY
local mySection            = storage.playerSection(SECTION_KEY)
local getLoadoutGraph      = require('scripts.Loadouts.contents.loadoutGraph').getLoadoutGraph
local myTypes              = require("scripts.Loadouts.myLib.myTypes")

---@type ui.Layout
local visEqEl

local selectedLoadoutIndex = 1

---@type ui.Element|{}
local switchPopup          = {}

---@param loadoutData OneSavedLoadOut
local function equipSecondWeapon(loadoutData)
        local carriedL = loadoutData.myEq[myTypes.SLOTS.CarriedLeft]

        if not carriedL.recordId then
                if loadoutData.secondWeapon and loadoutData.secondWeapon:isValid() then
                        self:sendEvent("EquipSecondWeapon", { Weapon = loadoutData.secondWeapon })
                elseif carriedL.keepPrev and g.myVars.secondWeapon and g.myVars.secondWeapon:isValid() then
                        local carriedRight = loadoutData.myEq[myTypes.SLOTS.CarriedRight].recordId

                        if not carriedRight or not types.Weapon.records[carriedRight] then return end

                        local carriedRightType = carriedRight and types.Weapon.records[carriedRight].type or ''
                        if myTypes.ONE_HAND_WEAPON[carriedRightType] then
                                self:sendEvent("EquipSecondWeapon", { Weapon = g.myVars.secondWeapon })
                        end
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

        if #g.myVars.savedLoadouts == 0 then return end

        local newEq = {}

        ---@type OneSavedLoadOut
        local loadoutData =
            g.myVars.savedLoadouts[selectedLoadoutIndex]

        g.myVars.keepPrev = {}

        for slot, data in pairs(loadoutData.myEq) do
                if data.recordId then
                        newEq[slot] = data.recordId
                elseif data.keepPrev then
                        newEq[slot] = types.Actor.getEquipment(self, slot)
                        g.myVars.keepPrev[slot] = true
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

                if switchPopup.layout then
                        switchPopup:destroy()
                end

                switchPopup = ui.create {
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
                        if switchPopup.layout then
                                switchPopup:destroy()
                        end
                end)
        end
end

local function prevLoadout()
        local prev = selectedLoadoutIndex - 1
        -- selectedLoadoutIndex = selectedLoadoutIndex - 1
        if prev >= 1 then
                selectedLoadoutIndex = prev
        end

        g.myVars.mainWindow.tabManager.contentContainer.layout.content = ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end

local function nextLoadout()
        local next = selectedLoadoutIndex + 1
        if next <= #g.myVars.savedLoadouts then
                selectedLoadoutIndex = next
        end

        g.myVars.mainWindow.tabManager.contentContainer.layout.content = ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end


local function switchPrev(saved)
        local prev = selectedLoadoutIndex - 1
        if prev >= 1 then
                selectedLoadoutIndex = prev
        else
                selectedLoadoutIndex = #saved
        end

        equipThisLoadout(true)
end
local function switchNext(saved)
        local next = selectedLoadoutIndex + 1
        if next <= #saved then
                selectedLoadoutIndex = next
        else
                selectedLoadoutIndex = 1
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

                local layout = {
                        type = ui.TYPE.Flex,
                        -- template = g.templates.highlight,
                        -- template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                        props = {
                                -- relativeSize = util.vector2(0.5, 0),
                                -- size = util.vector2(160, g.sizes.TEXT_SIZE + 0),
                                relativeSize = util.vector2(1, 0),
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
                                                mousePress = async:callback(function(e)
                                                        if e and e.button ~= 1 then return end
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

        selectedLoadoutIndex = math.min(math.max(1, selectedLoadoutIndex), #g.myVars.savedLoadouts)

        visEqEl = {
                type = ui.TYPE.Flex,
                content = ui.content {
                        getLoadoutGraph(g.myVars.savedLoadouts[selectedLoadoutIndex].myEq,
                                g.myVars.savedLoadouts[selectedLoadoutIndex].secondWeapon,
                                g.myVars.savedLoadouts[selectedLoadoutIndex].instrument)
                }
        }


        local equipButtonLayout = {
                name = 'equipButton',
                template = I.MWUI.templates.textNormal,

                props = {
                        text = 'Equip',
                        textSize = g.sizes.TEXT_SIZE,
                        textColor = g.colors.normal
                },
                events = {
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                equipThisLoadout(false)
                        end),
                        focusGain = focusGainCall,
                        focusLoss = focusLossCall,

                }
        }

        local deleteButtonLayout = {
                name = 'deleteButton',
                template = I.MWUI.templates.textNormal,

                props = {
                        text = 'Delete',
                        textSize = g.sizes.TEXT_SIZE,
                        textColor = g.colors.normal
                },
                events = {
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                table.remove(
                                        g.myVars.savedLoadouts,
                                        selectedLoadoutIndex)
                                prevLoadout()
                        end),
                        focusGain = focusGainCall,
                        focusLoss = focusLossCall,
                }
        }

        local flexLayout = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = {
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {

                        {
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders, --- ###############
                                props = {
                                        horizontal = true,
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        relativeSize = util.vector2(1, 1),
                                },
                                content = ui.content {



                                        g.gui.makeInt(10, 0),
                                        visEqEl,
                                        g.gui.makeInt(10, 0),
                                        {
                                                template = I.MWUI.templates.verticalLine,
                                                external = { grow = 0, stretch = 0 },
                                                props = {
                                                        relativeSize = util.vector2(0, 0.9),
                                                        size = util.vector2(1, 0),
                                                }
                                        },
                                        g.gui.makeInt(10, 0),
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.templates.borders, --- ############
                                                -- external = { grow = 1, stretch = 1 },
                                                props = {
                                                        horizontal = false,
                                                        size = util.vector2(400, 1),
                                                },
                                                content = ui.content {
                                                        {
                                                                type = ui.TYPE.Flex,
                                                                -- template = I.MWUI.templates.borders,
                                                                content = ui.content(allEls)
                                                        },
                                                        g.gui.makeInt(0, 10),
                                                        {
                                                                type = ui.TYPE.Flex,
                                                                -- template = I.MWUI.templates.borders, --- ##########
                                                                props = {
                                                                        horizontal = true,
                                                                },
                                                                content = ui.content {
                                                                        equipButtonLayout,
                                                                        g.gui.makeInt(30, 0),
                                                                        deleteButtonLayout,
                                                                }
                                                        },

                                                }

                                        },


                                }

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
