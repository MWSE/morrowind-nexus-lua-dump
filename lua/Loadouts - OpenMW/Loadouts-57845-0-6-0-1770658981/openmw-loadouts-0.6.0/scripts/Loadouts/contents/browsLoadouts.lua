local types           = require('openmw.types')
local storage         = require('openmw.storage')
local input           = require('openmw.input')
local async           = require('openmw.async')
local ui              = require('openmw.ui')
local I               = require('openmw.interfaces')
local self            = require('openmw.self')
local util            = require('openmw.util')
local g               = require('scripts.Loadouts.myLib')
local o               = require("scripts.Loadouts.settingsData").o
local SECTION_KEY     = require("scripts.Loadouts.settingsData").SECTION_KEY
local mySection       = storage.playerSection(SECTION_KEY)
local getLoadoutGraph = require('scripts.Loadouts.contents.loadoutGraph').getLoadoutGraph
local myTypes         = require("scripts.Loadouts.myLib.myTypes")
local MOD_ID          = require("scripts.Loadouts.settingsData").MOD_ID
local core            = require('openmw.core')
local l10n            = core.l10n(MOD_ID)


---@type ui.Layout
local visEqEl

local selectedLoadoutIndex = 1


local function updateParentLater(skip)
        table.insert(g.myVars.doLater, {
                action = function()
                        local window = g.myVars.currentWindow
                        if window and window.element then
                                window.tabManager.selectTab()
                        end
                end,
                skip = skip,
        })
end

local function getCurrentLoadout()
        ---@type OneSavedLoadOut
        local loadoutData = g.myVars.savedLoadouts[selectedLoadoutIndex]
        return loadoutData
end

---@type ui.Element|{}
local switchPopup = {}

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
        local loadoutData = g.myVars.savedLoadouts[selectedLoadoutIndex]

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

        if not loadoutData.instrument then
                loadoutData.instrument = {
                        recordId = nil,
                        keepPrev = false
                }
        end
        if loadoutData.instrument.recordId then
                if g.myVars.instrument.recordId ~= loadoutData.instrument.recordId then
                        self:sendEvent('BC_SheatheInstrument',
                                { actor = self, recordId = loadoutData.instrument.recordId })
                end
        elseif not loadoutData.instrument.keepPrev then
                self:sendEvent('BC_SheatheInstrument', { actor = self, recordId = nil })
                g.myVars.instrument.recordId = nil
                g.myVars.instrument.keepPrev = nil
        else
                g.myVars.instrument.keepPrev = true
        end

        if not loadoutData.backPack then
                loadoutData.backPack = {
                        recordId = nil,
                        keepPrev = false
                }
        end

        local currentBagId = myTypes.backPackRecordId[g.myVars.backPack.recordId]
        local savedBagId = myTypes.backPackRecordId[loadoutData.backPack.recordId]

        if savedBagId then
                if savedBagId ~= currentBagId then
                        g.myVars.backPack.keepPrev = nil
                        g.myVars.backPack.recordId = savedBagId
                        local backPack = types.Actor.inventory(self):find(savedBagId)
                        if backPack then
                                core.sendGlobalEvent('UseItem', { object = backPack, actor = self })
                        end
                end
        elseif not loadoutData.backPack.keepPrev then
                if currentBagId then
                        local backPack = types.Actor.inventory(self):find(myTypes.backPackRecordIdEquipped[currentBagId])
                        if backPack then
                                core.sendGlobalEvent('UseItem', { object = backPack, actor = self })
                                self:sendEvent('SunsDusk_backpackEquipped', {})
                        end
                end

                g.myVars.backPack.recordId = nil
                g.myVars.backPack.keepPrev = nil
        else
                g.myVars.backPack.keepPrev = true
        end

        types.Actor.setEquipment(self, newEq)


        if quick == false then
                -- ui.showMessage(string.format('Equipping: %s', loadoutData.name))
                ui.showMessage(l10n('Equipping') .. ' ' .. loadoutData.name)
        else
                updateParentLater(2)

                if switchPopup.layout then
                        switchPopup:destroy()
                end

                switchPopup = ui.create {
                        layer = "Notification",
                        type = ui.TYPE.Flex,
                        template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, g.textures.black, nil, nil, o.bgAlpha.value),
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
                                                textShadow = true,
                                        },

                                },
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = g.myVars.savedLoadouts[selectedLoadoutIndex].name,
                                                textShadow = true,
                                        }
                                },
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = g.myVars.savedLoadouts[selectedLoadoutIndex + 1] and g.myVars.savedLoadouts[selectedLoadoutIndex + 1].name or '',
                                                alpha = 0.5,
                                                textShadow = true,
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


---@return ui.Layout
local function getSavedLoadoutsLO()
        if #g.myVars.savedLoadouts == 0 then
                return g.gui.centerflex {

                        {
                                template = I.MWUI.templates.textHeader,
                                props = {
                                        text = l10n('noSavedLoadouts'),
                                        textSize = 20,
                                        textShadow = true,

                                }
                        }

                }
        end


        local allEls = {}



        for i = 1, #g.myVars.savedLoadouts do
                local loadoutData = g.myVars.savedLoadouts[i]

                local layout = {
                        type = ui.TYPE.Flex,
                        props = {
                                relativeSize = util.vector2(1, 0),
                                arrange = ui.ALIGNMENT.Center,
                                horizontal = true,
                        },
                        content = ui.content {
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = loadoutData.name,
                                                textSize = g.sizes.TEXT_SIZE,
                                                textColor = selectedLoadoutIndex == i and g.colors.selected or g.colors.normal,
                                                textShadow = true,

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
                        getLoadoutGraph(g.myVars.savedLoadouts[selectedLoadoutIndex])
                }
        }

        local flexLayout = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ########################
                props = {
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        g.gui.makeGap(0, 4),
                        {
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders, --- ########################
                                props = {
                                        horizontal = true,
                                        arrange = ui.ALIGNMENT.Center,

                                },
                                content = ui.content {
                                        g.gui.makeButton(core.getGMST('sEquip'), function()
                                                equipThisLoadout(false)
                                        end, g.myVars.mainWindow.tabManager.contentContainer),
                                        g.gui.makeGap(4, 0),
                                        g.gui.makeButton(core.getGMST('sDelete'), function()
                                                table.remove(g.myVars.savedLoadouts, selectedLoadoutIndex)
                                                prevLoadout()
                                        end, g.myVars.mainWindow.tabManager.contentContainer),

                                }
                        },
                        g.gui.makeGap(0, 10),
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
                                        g.gui.makeGap(10, 0),
                                        visEqEl,
                                        g.gui.makeGap(10, 0),
                                        {
                                                template = I.MWUI.templates.verticalLine,
                                                external = { grow = 0, stretch = 0 },
                                                props = {
                                                        relativeSize = util.vector2(0, 0.7),
                                                        size = util.vector2(1, 0),
                                                }
                                        },
                                        g.gui.makeGap(10, 0),
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.templates.borders, --- ############
                                                external = { grow = 0, stretch = 1 },
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

                                                }

                                        },


                                }

                        }
                }

        }

        return flexLayout
end



return {
        getSavedLoadoutsLO = getSavedLoadoutsLO,
        nextLoadout = nextLoadout,
        prevLoadout = prevLoadout,
        equipThisLoadout = equipThisLoadout,
        switchNext = switchNext,
        switchPrev = switchPrev,
        getCurrentLoadout = getCurrentLoadout,
}
