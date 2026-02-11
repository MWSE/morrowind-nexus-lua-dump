local types                  = require('openmw.types')
local async                  = require('openmw.async')
local ui                     = require('openmw.ui')
local I                      = require('openmw.interfaces')
local self                   = require('openmw.self')
local util                   = require('openmw.util')
local myTypes                = require("scripts.Loadouts.myLib.myTypes")
local g                      = require('scripts.Loadouts.myLib')
local getLoadoutGraph        = require('scripts.Loadouts.contents.loadoutGraph').getLoadoutGraph
local selectEquipmentWindow  = require('scripts.Loadouts.contents.loadoutGraph').selectEquipmentWindow
local selectInstrumentWindow = require('scripts.Loadouts.contents.loadoutGraph').selectInstrumentWindow
local selectBackpackWindow   = require('scripts.Loadouts.contents.loadoutGraph').selectBackpackWindow
local browseLoadouts         = require('scripts.Loadouts.contents.browsLoadouts')
local o                      = require("scripts.Loadouts.settingsData").o
local MOD_ID                 = require("scripts.Loadouts.settingsData").MOD_ID
local core                   = require('openmw.core')
local l10n                   = core.l10n(MOD_ID)

local loadoutName            = ''
local saveAsName             = ''
local currentEqEls           = {}
local SLOT_NAME_GAP          = 100
local BAR_LEN                = 80

---@type ui.Layout
local currentGraph

local nav                    = {}
nav.index                    = 1
---@type ui.Layout[]
nav.items                    = {}
nav.inputFocused             = false

---@type ui.Element|{}
nav.saveLO                   = {}
function nav:next()
        self:deHighlight()
        self.index = self.index + 1
        if self.index > #self.items then
                self.index = #self.items
        end
        self:highlight()
end

function nav:prev()
        self:deHighlight()
        self.index = self.index - 1
        if self.index < 1 then
                self.index = 1
        end
        self:highlight()
end

function nav:highlight(index)
        self.index = index or self.index
        local entryLayout = self.items[self.index]
        entryLayout.template = g.templates.highlight

        ---@type ui.Layout
        local graphSlotLayout = entryLayout.userData.graphSlotLayout

        ---@diagnostic disable-next-line: undefined-field
        graphSlotLayout.content.overlay.template = g.templates.highlight_white

        ---@diagnostic disable-next-line: undefined-field
        currentGraph.content.currEqName.props.text = entryLayout.userData.l10nName

        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end

function nav:deHighlight()
        local entryLayout = self.items[self.index]
        entryLayout.template = nil

        ---@type ui.Layout
        local graphSlotLayout = entryLayout.userData.graphSlotLayout

        ---@diagnostic disable-next-line: undefined-field
        graphSlotLayout.content.overlay.template = nil
end

function nav:selectSlot()
        if (self.index - 1) > myTypes.SLOTS.Ammunition then
                selectInstrumentWindow()
        else
                selectEquipmentWindow(self.index - 1)
        end
end

local function addInstrumentEntry()
        local instNameEl

        if g.myVars.instrument.recordId then
                local record = types.Miscellaneous.records[g.myVars.instrument.recordId]
                instNameEl = {
                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                        },
                        userData = {
                                empty = nil,
                        },
                        content = ui.content {
                                {
                                        type  = ui.TYPE.Image,
                                        props = {
                                                resource = ui.texture { path = record.icon },
                                                size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE)
                                        }
                                },
                                g.gui.makeGap(4, 0),
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props    = {
                                                text = record.name,
                                                textSize = g.sizes.TEXT_SIZE,
                                                textShadow = true,
                                        }
                                }
                        }
                }
        else
                instNameEl = {
                        template = I.MWUI.templates.textNormal,
                        props = {
                                text = string.format('- %s -', l10n('Empty')),
                                textSize = g.sizes.TEXT_SIZE,
                                textShadow = true,
                        },
                        userData = {
                                empty = true,
                        },
                }
        end

        local layout = {
                type = ui.TYPE.Flex,
                userData = {
                        graphSlotLayout = currentGraph.userData.instrumentLO,
                        l10nName = l10n(myTypes.slotIndexToName[20])
                },
                props = {
                        relativeSize = util.vector2(1, 0),
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        size = util.vector2(SLOT_NAME_GAP, g.sizes.TEXT_SIZE),
                                        align = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = l10n('Instrument'),
                                                        textSize = g.sizes.TEXT_SIZE,
                                                        textColor = not instNameEl.userData.empty and g.colors.normal or g.colors.disabled,
                                                        textShadow = true,
                                                }
                                        },

                                }
                        },
                        instNameEl
                },
                events = {
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                selectInstrumentWindow()
                        end),
                        focusGain = async:callback(function()
                                nav:deHighlight()
                                nav:highlight(nav.instrumentIndex)
                        end),
                }
        }

        return layout
end


local function addBackPackEntry()
        local backpackId
        local savedData = I.SunsDusk.getSaveData()
        if savedData then
                backpackId = savedData.backpackId
        end

        local bpNameEl

        if backpackId then
                local record = types.Miscellaneous.records[backpackId]
                bpNameEl = {
                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                        },
                        userData = {
                                empty = nil,
                        },
                        content = ui.content {
                                {
                                        type  = ui.TYPE.Image,
                                        props = {
                                                resource = ui.texture { path = record.icon },
                                                size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE)
                                        }
                                },
                                g.gui.makeGap(4, 0),
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props    = {
                                                text = record.name,
                                                textSize = g.sizes.TEXT_SIZE,
                                                textShadow = true,
                                        }
                                }
                        }
                }
        else
                bpNameEl = {
                        template = I.MWUI.templates.textNormal,
                        props = {
                                text = string.format('- %s -', l10n('Empty')),
                                textSize = g.sizes.TEXT_SIZE,
                                textShadow = true,
                        },
                        userData = {
                                empty = true,
                        },
                }
        end

        local layout = {
                type = ui.TYPE.Flex,
                userData = {
                        graphSlotLayout = currentGraph.userData.backPackLO,
                        l10nName = l10n(myTypes.slotIndexToName[21])
                },
                props = {
                        relativeSize = util.vector2(1, 0),
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        size = util.vector2(SLOT_NAME_GAP, g.sizes.TEXT_SIZE),
                                        align = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = l10n('Backpack'),
                                                        textSize = g.sizes.TEXT_SIZE,
                                                        textColor = not bpNameEl.userData.empty and g.colors.normal or g.colors.disabled,
                                                        textShadow = true,
                                                }
                                        },

                                }
                        },
                        bpNameEl
                },
                events = {
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                selectBackpackWindow()
                        end),
                        focusGain = async:callback(function()
                                nav:deHighlight()
                                nav:highlight(nav.backPackIndex)
                        end),
                }
        }

        return layout
end

---@return ui.Layout
local function getCurrentEquipment()
        currentEqEls = {}
        nav.items = {}

        local eq = types.Actor.getEquipment(self)
        ---@cast eq EquipmentTable

        for i = 1, #myTypes.ARRANGED_SLOTS do
                local slotKey = myTypes.ARRANGED_SLOTS[i]
                local index = myTypes.SLOTS[slotKey] + 1
                local slotName = myTypes.slotIndexToName[index]

                ---@type ui.Layout
                local nameElement

                if not g.myVars.keepPrev[index - 1] then
                        g.myVars.keepPrev[index - 1] = false
                end

                local item
                local record
                local bar
                local chargeBar

                if eq and eq[index - 1] then
                        item = eq[index - 1]
                        ---@type Record
                        record = item.type.record(item)
                elseif slotName == 'Carried L' and core.contentFiles.has('dualwielding.omwscripts') == true and g.myVars.secondWeapon then
                        item = g.myVars.secondWeapon
                        ---@type Record
                        record = item.type.record(item)
                end

                if record then
                        if o.showCondition.value then
                                ---@type ItemData
                                local data = item.type.itemData(item)
                                if data.condition then
                                        local value = data.condition
                                        local max = record.maxCondition or record.health or record.duration
                                        bar = g.gui.makeGUIBar_2(value, max, BAR_LEN, g.sizes.TEXT_SIZE,
                                                g.colors.redTintHex,
                                                14)
                                end

                                if record.enchant then
                                        ---@type Enchantment
                                        local enchantment = core.magic.enchantments.records[record.enchant]

                                        if enchantment.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
                                                local value = data.enchantmentCharge or 0
                                                local max = enchantment.charge
                                                chargeBar = g.gui.makeGUIBar_2(value, max, BAR_LEN, g.sizes.TEXT_SIZE,
                                                        g.colors.blueTintHex, 14)
                                        end
                                end
                        end

                        nameElement = {
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders, --- ###########
                                external = { grow = 1, stretch = 1 },
                                props = {
                                        horizontal = true,
                                        size = util.vector2(0, g.sizes.TEXT_SIZE),
                                        relativeSize = util.vector2(1, 0),
                                },
                                userData = {
                                        empty = nil,
                                },
                                content = ui.content {
                                        {
                                                type = ui.TYPE.Widget,
                                                props = {
                                                        size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE),
                                                },
                                                content = ui.content {
                                                        record.enchant and {
                                                                type = ui.TYPE.Image,
                                                                props = {
                                                                        resource = g.textures.magicIcon,
                                                                        size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE),
                                                                },
                                                        } or {},
                                                        {
                                                                type = ui.TYPE.Image,
                                                                props = {
                                                                        resource = ui.texture {
                                                                                path = record.icon,
                                                                        },
                                                                        size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE),
                                                                },
                                                        }
                                                },
                                        },
                                        g.gui.makeGap(4, 0),
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props    = {
                                                        -- position = util.vector2(20, 0),
                                                        text = record.name,
                                                        textSize = g.sizes.TEXT_SIZE,
                                                        textShadow = true,
                                                }
                                        },
                                        g.gui.makeGap(4, 0),
                                        g.gui.makeInt(0, 0, 1, 0),
                                        bar or g.gui.makeGap(BAR_LEN, 0),
                                        g.gui.makeGap(4, 0),
                                        chargeBar or g.gui.makeGap(BAR_LEN, 0),
                                },
                        }
                else
                        nameElement = {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = g.myVars.keepPrev[index - 1] == false
                                            and string.format('- %s -', l10n('Empty'))
                                            or string.format('- %s -', l10n('Keep_Previous')),
                                        textSize = g.sizes.TEXT_SIZE,
                                        textShadow = true,
                                },
                                userData = {
                                        empty = g.myVars.keepPrev[index - 1] == false,
                                },
                        }
                end


                local graphIndex = myTypes.SLOTS[myTypes.ARRANGED_SLOTS[i]]

                local layout = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders, --- #############
                        userData = {
                                graphSlotLayout = currentGraph.userData.slotsLOs[graphIndex],
                                l10nName = l10n(myTypes.slotIndexToName[graphIndex + 1])
                        },
                        props = {
                                size = util.vector2(0, g.sizes.TEXT_SIZE),
                                relativeSize = util.vector2(1, 0),
                                horizontal = true,
                        },
                        content = ui.content {
                                {
                                        props = {
                                                size = util.vector2(100, g.sizes.TEXT_SIZE),
                                        },
                                        content = ui.content {
                                                {
                                                        template = I.MWUI.templates.textNormal,
                                                        props = {
                                                                text = l10n(slotName),
                                                                textSize = g.sizes.TEXT_SIZE,
                                                                textColor = nameElement.userData.empty == nil and g.colors.normal or g.colors.disabled,
                                                                textShadow = true,
                                                        }
                                                },
                                        }
                                },
                                nameElement,
                        },
                        events = {
                                mousePress = async:callback(function(e)
                                        if e and e.button ~= 1 then return end
                                        selectEquipmentWindow(index - 1)
                                end),
                                focusGain = async:callback(function()
                                        nav:deHighlight()
                                        nav:highlight(i)
                                end),
                        }
                }

                table.insert(currentEqEls, layout)
        end

        if g.myVars.performerInfo then
                nav.instrumentIndex = #currentEqEls + 1
                table.insert(currentEqEls, addInstrumentEntry())
        end

        if I.SunsDusk then
                nav.backPackIndex = #currentEqEls + 1
                table.insert(currentEqEls, addBackPackEntry())
        end


        nav.items = currentEqEls

        local layout = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ##########
                props = {
                        align = ui.ALIGNMENT.Center,
                },
                content = ui.content(currentEqEls)
        }


        layout.content:insert(3, g.gui.makeGap(0, 10))
        layout.content:insert(9, g.gui.makeGap(0, 10))
        layout.content:insert(15, g.gui.makeGap(0, 10))
        layout.content:insert(23, g.gui.makeGap(0, 10))
        -- layout.content:insert(#layout.content, g.gui.makeGap(0, 10))


        return layout
end


local function saveLoadout()
        if not loadoutName or loadoutName == '' then
                ui.showMessage(l10n('enterAName'))
                return
        end

        for i = 1, #g.myVars.savedLoadouts do
                if g.myVars.savedLoadouts[i].name == loadoutName then
                        ui.showMessage(l10n('alreadyExists', { name = loadoutName }))
                        return
                end
        end

        local eq = types.Actor.getEquipment(self)
        ---@cast eq EquipmentTable

        local myEq = {}
        for _, v in pairs(myTypes.SLOTS) do
                local item = eq[v]
                local recordId
                local icon

                if item then
                        recordId = item.recordId
                        local record = item.type.record(item)
                        icon = record.icon
                end
                myEq[v] = {
                        recordId = recordId,
                        icon = icon,
                        keepPrev = g.myVars.keepPrev[v],
                }
        end

        table.insert(g.myVars.savedLoadouts, {
                name = loadoutName,
                myEq = myEq,
                secondWeapon = g.myVars.secondWeapon,
                instrument = {
                        recordId = g.myVars.instrument.recordId,
                        keepPrev = g.myVars.instrument.keepPrev
                },
                backPack = {
                        recordId = g.myVars.backPack.recordId,
                        keepPrev = g.myVars.backPack.keepPrev
                }
        })

        table.sort(g.myVars.savedLoadouts, function(a, b)
                return a.name:lower() < b.name:lower()
        end)

        ui.showMessage(l10n('loadoutCreated', { name = loadoutName }))
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end


local function overwriteLoadout()
        local original = browseLoadouts.getCurrentLoadout()

        local eq = types.Actor.getEquipment(self)
        ---@cast eq EquipmentTable

        local myEq = {}
        for _, v in pairs(myTypes.SLOTS) do
                local item = eq[v]
                local recordId
                local icon

                if item then
                        recordId = item.recordId
                        local record = item.type.record(item)
                        icon = record.icon
                end
                myEq[v] = {
                        recordId = recordId,
                        icon = icon,
                        keepPrev = g.myVars.keepPrev[v],
                }
        end

        original.myEq = myEq
        original.secondWeapon = g.myVars.secondWeapon

        original.instrument = {
                recordId = g.myVars.instrument.recordId,
                keepPrev = g.myVars.instrument.keepPrev
        }

        original.backPack = {
                recordId = g.myVars.backPack.recordId,
                keepPrev = g.myVars.backPack.keepPrev
        }

        ui.showMessage(l10n('loadoutOverwritten', { name = loadoutName }))

        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end

local function quickSave()
        loadoutName = saveAsName
        saveLoadout()
end


---@return ui.Element
local function getSaveLO()
        local currentHighlightedLoadout = browseLoadouts.getCurrentLoadout()

        if nav.saveLO.layout then
                nav.saveLO:destroy()
        end
        nav.saveLO = ui.create {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                -- external = {grow =1 , stretch = 1},

                props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center
                },
                content = ui.content {

                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = core.getGMST('sName') .. ":",
                                        textSize = g.sizes.TEXT_SIZE,
                                        textShadow = true,



                                },

                        },
                        g.gui.makeGap(4, 0),
                        {
                                type = ui.TYPE.Flex,
                                template = g.templates.getTemplate('thin', { 0, 0, 0, 2 }),
                                props = {
                                        size = util.vector2(1, g.sizes.BOX_SIZE),
                                        align = ui.ALIGNMENT.Center
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textEditLine,
                                                props = {
                                                        text = '',
                                                        textSize = g.sizes.TEXT_SIZE,
                                                        size = util.vector2(160, 1),
                                                        textShadow = true,

                                                },
                                                events = {
                                                        textChanged = async:callback(function(
                                                            a, l)
                                                                if string.len(a) < 24 then
                                                                        l.props.text =
                                                                            a
                                                                        loadoutName = a
                                                                end
                                                                if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                                        table.insert(
                                                                                g.myVars.myDelayedActions,
                                                                                g.myVars.mainWindow.tabManager
                                                                                .contentContainer)
                                                                end
                                                        end),
                                                        focusGain = async:callback(function()
                                                                nav.inputFocused = true
                                                        end),
                                                        focusLoss = async:callback(function()
                                                                nav.inputFocused = false
                                                        end)
                                                }
                                        },
                                }
                        },
                }
        }

        nav.saveLO.layout.content:add(g.gui.makeGap(4, 0))
        nav.saveLO.layout.content:add(g.gui.makeButton(l10n('Save'), saveLoadout, nav.saveLO))
        nav.saveLO.layout.content:add(g.gui.makeGap(4, 0))
        nav.saveLO.layout.content:add(g.gui.makeButton(l10n('SaveAs') .. ' ' .. saveAsName, quickSave, nav.saveLO))
        nav.saveLO.layout.content:add(g.gui.makeGap(4, 0))
        if currentHighlightedLoadout then
                nav.saveLO.layout.content:add(g.gui.makeButton(
                        l10n('Overwrite') .. ' ' .. currentHighlightedLoadout.name, overwriteLoadout, nav
                        .saveLO))
        end

        return nav.saveLO
end


---@return ui.Layout
local function getCreateLoadoutLO()
        nav.inputFocused = false
        loadoutName = ''

        local count = 1
        saveAsName = 'Loadout-' .. count


        ::retry::
        for i, v in pairs(g.myVars.savedLoadouts) do
                if v.name == saveAsName then
                        count = count + 1
                        saveAsName = 'Loadout-' .. count
                        goto retry
                end
        end




        local eq = types.Actor.getEquipment(self)
        ---@cast eq EquipmentTable
        local myEq = {}
        for _, v in pairs(myTypes.SLOTS) do
                local item = eq[v]
                local recordId
                local icon

                if item then
                        recordId = item.recordId
                        local record = item.type.record(item)
                        icon = record.icon
                end
                myEq[v] = {
                        recordId = recordId,
                        icon = icon,
                        keepPrev = g.myVars.keepPrev[v],
                }
        end


        ---@type OneSavedLoadOut
        local currLoadout = {
                myEq = myEq,
                secondWeapon = g.myVars.secondWeapon,
                instrument = {
                        recordId = g.myVars.instrument.recordId,
                        keepPrev = g.myVars.instrument.keepPrev,
                },
                backPack = {
                        recordId = g.myVars.backPack.recordId,
                        keepPrev = g.myVars.backPack.keepPrev
                }
        }

        currentGraph = getLoadoutGraph(currLoadout, nav)
        local currentEquipment = getCurrentEquipment()

        ---@type ui.Layout
        local element

        element = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ############
                props = {
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        g.gui.makeGap(0, 4),
                        getSaveLO(),
                        g.gui.makeGap(0, 20),

                        {
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders, --- ############
                                props = {
                                        horizontal = true,
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        relativeSize = util.vector2(1, 1),

                                },
                                content = ui.content {
                                        g.gui.makeGap(10, 0),
                                        currentGraph,
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
                                        currentEquipment


                                }
                        }
                }
        }

        nav:highlight()

        return element
end


return {
        getCreateLoadoutLO = getCreateLoadoutLO,
        nav = nav
}
