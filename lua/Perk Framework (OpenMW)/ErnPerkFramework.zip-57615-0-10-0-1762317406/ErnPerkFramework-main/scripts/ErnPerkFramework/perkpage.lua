--[[
ErnPerkFramework for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local interfaces = require("openmw.interfaces")
local storage = require('openmw.storage')
local pself = require("openmw.self")
local types = require("openmw.types")
local input = require("openmw.input")
local log = require("scripts.ErnPerkFramework.log")
local util = require('openmw.util')
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local settings = require("scripts.ErnPerkFramework.settings")
local ui = require('openmw.ui')
local aux_util = require('openmw_aux.util')
local myui = require('scripts.ErnPerkFramework.pcp.myui')
local list = require('scripts.ErnPerkFramework.list')
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)

-- A content list can contain both Elements and Layouts.
-- Elements are what you get when you call ui.create().
-- Elements are passed by reference, so you can update them without needing to
-- mess with parent layouts that use them.
--
-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/widgets/widget.html#properties
-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/openmw_ui.html##(Template)

local remainingPoints = 0

local menu = nil
local perkList = nil
local perkDetailElement = ui.create {
    name = "detailLayout",
    type = ui.TYPE.Flex,
}

local haveThisPerk = ui.create {
    template = interfaces.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    alignment = ui.ALIGNMENT.Center,
    props = {
        visible = false,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        text = localization("havePerk", {}),
    },
}

local satisfiedCache = {}
local function satisfied(perkID)
    if type(perkID) ~= "string" then
        perkID = perkID:id()
    end
    if satisfiedCache[perkID] ~= nil then
        return satisfiedCache[perkID]
    else
        local ok = interfaces.ErnPerkFramework.getPerks()[perkID]:evaluateRequirements().satisfied
        satisfiedCache[perkID] = ok
        return ok
    end
end

local weightsCache = {}
-- visiblePerks is a map of perkid -> {}, or nil.
local visiblePerks = nil
local function getPerkIDs()
    local sort = function(e)
        local perkObj = interfaces.ErnPerkFramework.getPerks()[e]
        if perkObj:active() then
            return 100
        end
        if not satisfied(e) then
            return 50
        end
        if perkObj:cost() > remainingPoints then
            return 25
        end
        return 0
    end

    local visible = function(id)
        local perkObj = interfaces.ErnPerkFramework.getPerks()[id]
        return perkObj:active() or (not perkObj:hidden())
    end
    if visiblePerks ~= nil then
        visible = function(id)
            return visiblePerks[id] ~= nil
        end
    end

    local out = {}
    for _, e in ipairs(interfaces.ErnPerkFramework.getPerkIDs()) do
        if visible(e) then
            table.insert(out, e)
            if weightsCache[e] == nil then
                weightsCache[e] = sort(e)
            end
        end
    end
    table.sort(out, function(a, b)
        if weightsCache[a] ~= weightsCache[b] then
            return weightsCache[a] < weightsCache[b]
        else
            return interfaces.ErnPerkFramework.getPerks()[a]:name() < interfaces.ErnPerkFramework.getPerks()[b]:name()
        end
    end)
    return out
end

-- index of the selected perk, by the full perk list
local function getSelectedIndex()
    if perkList ~= nil then
        return perkList.selectedIndex
    end
    return 1
end
local function getSelectedPerk()
    local selectedPerkID = getPerkIDs()[getSelectedIndex()]
    return interfaces.ErnPerkFramework.getPerks()[selectedPerkID]
end

local function hasPerk(idx)
    local testID = getPerkIDs()[idx]
    for _, foundID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        if foundID == testID then
            return true
        end
    end
    return false
end

-- perkAvailable returns true if the player does not have the perk, but
-- they could learn it.
local function perkAvailable(perk)
    if perk == nil then
        log(nil, "perkAvailable(nil)")
        return false
    end
    local foundPerk = perk
    if type(perk) == "string" then
        foundPerk = interfaces.ErnPerkFramework.getPerks()[perk]
    end
    return satisfied(foundPerk) and (not foundPerk:active()) and foundPerk:cost() <= remainingPoints
end

local function pickPerk()
    local selectedPerk = getSelectedPerk()
    if selectedPerk ~= nil then
        log(nil, "Picked perk " .. selectedPerk:id())
        if perkAvailable(selectedPerk) then
            log(nil, "Adding perk " .. selectedPerk:id())
            pself:sendEvent(MOD_NAME .. "addPerk",
                { perkID = selectedPerk:id() })
            remainingPoints = remainingPoints - selectedPerk:cost()
            if remainingPoints <= 0 then
                pself:sendEvent(MOD_NAME .. "closePerkUI")
            else
                -- clone visible perks list.
                -- this needs to be converted back into a list.
                local visiblePerksClone = nil
                if visiblePerks ~= nil then
                    visiblePerksClone = {}
                    for k, v in pairs(visiblePerks) do
                        table.insert(visiblePerksClone, k)
                    end
                end
                -- re-open or refresh the current window
                pself:sendEvent(settings.MOD_NAME .. "showPerkUI",
                    { remainingPoints = remainingPoints, visiblePerks = visiblePerksClone })
            end
        end
    end
end

local pickButtonElement = ui.create {}

local function updatePickButtonElement()
    --pickButtonElement:destroy()
    local color = 'normal'
    local cost = 1
    local selectedPerk = getSelectedPerk()
    if selectedPerk ~= nil then
        cost = selectedPerk:cost()
    end
    if not perkAvailable(selectedPerk) then
        color = 'disabled'
    end
    pickButtonElement.layout = myui.createTextButton(
        pickButtonElement,
        localization('pickButton', { cost = cost, available = remainingPoints }),
        color,
        'pickButton',
        {},
        util.vector2(129, 17),
        pickPerk)
    pickButtonElement:update()
end
updatePickButtonElement()

-- viewPerk shows the perk details after a click on a button or redraw
local function viewPerk(perkID, idx)
    if type(idx) ~= "number" then
        error("idx must be a number")
    end
    local foundPerk = perkID
    if type(perkID) == "string" then
        if perkID == "" then
            error("viewPerk() supplied an empty perkID")
            return
        end
        foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
    end
    if foundPerk == nil then
        error("bad perk: " .. tostring(perkID))
        return
    end
    if perkList ~= nil then
        perkList.selectedIndex = idx
    end

    log(nil, "Showing detail for perk " .. foundPerk:name())
    perkDetailElement.layout = foundPerk:detailLayout()
    perkDetailElement:update()
    if perkList ~= nil then
        perkList:setSelectedIndex(idx)
        perkList:update()
    end

    haveThisPerk.layout.props.visible = hasPerk(getSelectedIndex())
    haveThisPerk:update()

    updatePickButtonElement()
end

-- perkNameElement renders a perk button in a list
local function perkNameElement(perkObj, idx)
    --print("making Element for " .. perkObj:id() .. " at idx " .. idx)
    -- this is the perk name as it appears in the selection list.
    local color = 'normal'
    if idx == getSelectedIndex() then
        color = 'active'
    elseif hasPerk(idx) then
        color = 'disabled'
    elseif not satisfied(perkObj) then
        color = 'disabled'
    end

    local selectButton = ui.create {}
    selectButton.layout = myui.createTextButtonBorderless(
        selectButton,
        perkObj:name(),
        color,
        'selectButton_' .. perkObj:id(),
        {},
        util.vector2(129, 17),
        viewPerk,
        { perkObj:id(), idx })
    selectButton:update()
    return selectButton
end

perkList = list.NewList(
    function(idx)
        if type(idx) ~= "number" then
            error("idx must be a number")
        end
        local perkIDs = getPerkIDs()
        return perkNameElement(interfaces.ErnPerkFramework.getPerks()[perkIDs[idx]], idx)
    end
)

local function closeUI()
    if menu ~= nil then
        log(nil, "closing ui")
        menu:destroy()
        menu = nil

        perkList:destroy()

        perkDetailElement = ui.create {
            name = "detailLayout",
            type = ui.TYPE.Flex,
        }
        interfaces.UI.removeMode('Interface')
    end
end

local cancelButtonElement = ui.create {}
cancelButtonElement.layout = myui.createTextButton(
    cancelButtonElement,
    localization('cancelButton'),
    'normal',
    'cancelButton',
    {},
    util.vector2(129, 17),
    closeUI)
cancelButtonElement:update()

local function menuLayout()
    return {
        layer = 'Windows',
        name = 'menuContainer',
        type = ui.TYPE.Container,
        template = interfaces.MWUI.templates.boxTransparentThick,
        props = {
            horizontal = true,
            autoSize = false,

            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5)
            --relativeSize = util.vector2(1, 1) --* settings.uiScale,
        },
        content = ui.content {
            {
                name = 'padding',
                type = ui.TYPE.Container,
                template = myui.padding(8, 8),
                content = ui.content {
                    {
                        name = 'mainFlex',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            autoSize = false,
                            size = util.vector2(600, 480),
                        },
                        content = ui.content {
                            perkList.root,
                            myui.padWidget(8, 0),
                            {
                                -- detail page section
                                type = ui.TYPE.Flex,
                                props = {
                                    arrange = ui.ALIGNMENT.Center,
                                    relativeSize = util.vector2(1, 1),
                                },
                                external = { grow = 1 },
                                content = ui.content {
                                    perkDetailElement,
                                    myui.padWidget(0, 8),
                                    haveThisPerk,
                                    myui.padWidget(0, 8),
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            horizontal = true,
                                        },
                                        content = ui.content {
                                            pickButtonElement,
                                            myui.padWidget(8, 0),
                                            cancelButtonElement
                                        },
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
end

local function drawPerksList()
    local perkIDs = getPerkIDs()
    perkList:setTotal(#perkIDs)
    perkList:update()
end

local function redraw()
    drawPerksList()
    viewPerk(getSelectedPerk(), getSelectedIndex())

    updatePickButtonElement()

    if menu ~= nil then
        menu:update()
    end
end

local function showPerkUI(data)
    weightsCache = {}
    satisfiedCache = {}

    remainingPoints = interfaces.ErnPerkFramework.totalAllowedPoints() -
        interfaces.ErnPerkFramework.currentSpentPoints()

    -- Set the filter, if there is one.
    if data.visiblePerks ~= nil then
        if (type(data.visiblePerks) ~= "table") then
            error("showPerkUI(): expected visiblePerks to be a list, not a " .. type(data.visiblePerks))
        end
        visiblePerks = {}
        local idListString = ""
        for _, v in ipairs(data.visiblePerks) do
            visiblePerks[v] = true
            idListString = idListString .. ", " .. tostring(v)
        end
        log(nil, "Showing explicit subset of perks: " .. idListString)
    else
        visiblePerks = nil
    end

    local allPerkIDs = getPerkIDs()
    if #allPerkIDs == 0 then
        log(nil, "No perks found.")
        return
    end

    -- Quit if this is the normal window and nothing is available.
    if visiblePerks == nil then
        local aPerkIsAvailable = false
        for _, id in ipairs(allPerkIDs) do
            if perkAvailable(id) then
                aPerkIsAvailable = true
                break
            end
        end
        if not aPerkIsAvailable then
            log(nil, "No available perks found.")
            return
        end
    end

    if menu == nil then
        interfaces.UI.setMode('Interface', { windows = {} })
        log(nil, "Showing Perk UI...")

        perkList.selectedIndex = 1
        menu = ui.create(menuLayout())
        redraw()
    else
        redraw()
    end
end


local function onMouseWheel(direction)
    if menu == nil then
        -- If the menu is not up, ignore the mouse wheel.
        return
    end
    if direction < 0 then
        perkList:scroll(-1)
    else
        perkList:scroll(1)
    end
    redraw()
end

local debounce = 0
local keyEnterStatus = false
local keyEscapeStatus = false
local function onFrame(dt)
    if menu == nil then
        return
    end
    myui.processButtonAction(dt)

    if debounce > 0 then
        debounce = debounce - 1
        return
    end

    if input.isKeyPressed(input.KEY.DownArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown) then
        perkList:scroll(1)
        debounce = 5
        redraw()
    end
    if input.isKeyPressed(input.KEY.UpArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp) then
        perkList:scroll(-1)
        debounce = 5
        redraw()
    end

    -- x on playstation is south. trigger on falling edge.
    if input.isKeyPressed(input.KEY.Enter) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.A) then
        keyEnterStatus = true
    elseif keyEnterStatus == true then
        pickPerk()
        keyEnterStatus = false
    end
    -- o on playstation is east. trigger on falling edge.
    if input.isKeyPressed(input.KEY.Escape) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.B) then
        keyEscapeStatus = true
    elseif keyEscapeStatus then
        keyEscapeStatus = false
        closeUI()
    end
end

return {
    eventHandlers = {
        [MOD_NAME .. "showPerkUI"] = showPerkUI,
        [MOD_NAME .. "closePerkUI"] = closeUI,
    },
    engineHandlers = {
        onFrame = onFrame,
        onMouseWheel = onMouseWheel,
    }
}
