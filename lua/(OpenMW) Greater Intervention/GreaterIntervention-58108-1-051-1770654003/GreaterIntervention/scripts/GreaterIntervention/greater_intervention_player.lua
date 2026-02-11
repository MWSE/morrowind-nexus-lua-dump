local ui        = require('openmw.ui')
local core      = require('openmw.core')
local self      = require('openmw.self')
local types     = require('openmw.types')
local async     = require('openmw.async')
local util      = require('openmw.util')
local input     = require('openmw.input')
local I         = require('openmw.interfaces')
local nearby    = require('openmw.nearby')
local MWE_API   = require('openmw.interfaces').MagicWindow

-- Max number of buttons per column
local MAX_PER_COLUMN = 16

-- Enable experimental standard Intervention destination display based on discovered markers.
local ENABLE_STANDARD_INTERVENTION_ENHANCE = true

-- If Magic Window Extender is present, this functionality is handled in greater_intervention_MWE_custom_spell.lua instead.
if MWE_API then ENABLE_STANDARD_INTERVENTION_ENHANCE = false end

-- Map Greater Intervention Spell IDs to the specific Marker IDs they filter for.
local SPELL_MAP = {
    ["almsivi intervention greater"] = "templemarker",
    ["divine intervention greater"] = "divinemarker"
}

-- Map standard Intervention Spell IDs to the specific Marker IDs they filter for.
local STANDARD_SPELL_MAP = {
    ["almsivi intervention"] = "templemarker",
    ["divine intervention"] = "divinemarker"
}

-- Track selected standard Intervention spell to prevent constant updating
local selectedStandardIntherventionSpell = {
    AlmsiviIntervention = "almsivi intervention",
    DivineIntervention = "divine intervention",
    Unknown = "unknown"
}

local recentStandardInterventionSpell = selectedStandardIntherventionSpell.Unknown

local currentMenu = nil
local focusedIndex = 1
local menuItems = {} -- Stores the onClick functions for navigation
local currentMarkerList = {} -- Store this globally to allow redraws
local buttonsPerCol = 1

local function closeMenu()
    if currentMenu then
        currentMenu:destroy()
        currentMenu = nil
    end
    I.UI.setMode(nil) -- Unpause game and hide cursor
end

-- Show message of newly discovered destination.
local function createDiscoveryMessage(displayName)
    if displayName then
        ui.showMessage("Added " .. displayName .. " to Greater Intervention list.")
    end
end

local function createInterventionMenu(markerList)
    currentMarkerList = markerList -- Save for redraw
    if #markerList == 0 then
        ui.showMessage("No destinations discovered for this spell yet.")
        return
    end

    if currentMenu then currentMenu:destroy() end

    local buttonContent = {}
    menuItems = {}

    -- 1. Button Factory with Focus Logic
    local function makeButton(index, label, color, onClick)
        menuItems[index] = onClick
        local isFocused = (index == focusedIndex)

        return {
            type = ui.TYPE.Container,
            template = isFocused and I.MWUI.templates.boxActive or I.MWUI.templates.box,
            props = { mouseTransparent = false },
            events = { mouseRelease = async:callback(onClick) },
            content = ui.content {
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = label,
                        textColor = isFocused and util.color.rgb(1, 1, 1) or color,
                        textAlignH = ui.ALIGNMENT.Center,
                        textAlignV = ui.ALIGNMENT.Center,
                        mouseTransparent = true,
                        textSize = 20,
                        autoSize = false,
                        size = util.vector2(300, 40),
                    }
                }
            }
        }
    end

    -- 2. Assemble Buttons
    for i, marker in ipairs(markerList) do
        table.insert(buttonContent, makeButton(i, marker.label, util.color.rgb(223/255, 201/255, 156/255), function()
            core.sendGlobalEvent('executeTeleport', marker)
            closeMenu()
        end))
    end
    -- Add Cancel Button
    local cancelIdx = #buttonContent + 1
    table.insert(buttonContent, makeButton(cancelIdx, "Cancel", util.color.rgb(1, 0.4, 0.4), function()
        closeMenu()
    end))

    -- 3. Calculate grid dimensions
    local totalButtons = #buttonContent
    local numColumns = math.ceil(totalButtons / MAX_PER_COLUMN)
    buttonsPerCol = math.ceil(totalButtons / numColumns)

    -- 4. Column Distribution
    local colWidgets = {}
    local currentColumnItems = {}
    for i, button in ipairs(buttonContent) do
        table.insert(currentColumnItems, button)
        if #currentColumnItems >= buttonsPerCol or i == #buttonContent then
            table.insert(colWidgets, {
                type = ui.TYPE.Flex,
                props = {
                    column = true,
                    arrange = ui.ALIGNMENT.Start,
                    margin = 10,
                },
                content = ui.content(currentColumnItems)
            })
            currentColumnItems = {}
        end
    end

    -- 5. Create UI
    currentMenu = ui.create {
        layer = 'Modal',
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(colWidgets)
            }
        }
    }

    -- Pause game and hide the vanilla interface
    I.UI.setMode('Interface', { windows = {} })
end

-- Chebyshev Distance Helper
local function getChebyshevDistance(playerPos, markerX, markerY)
    return math.max(math.abs(playerPos.x - markerX), math.abs(playerPos.y - markerY))
end

-- Get player's position in the exterior world
local function getExteriorPlayerPos(playerPos)
    local cell = self.cell

    -- If in exterior cell, just return player's position
    if cell.isExterior then return self.position end

    -- Player is in interior cell. Attempt to find closest exit to exterior cell
    for _, door in ipairs(nearby.doors) do
        if types.Door.isTeleport(door) then
            local destCell = types.Door.destCell(door)

            -- Check if door teleports to an exterior cell
            if destCell.isExterior then
                return types.Door.destPosition(door) -- This is the exterior world position
            end
        end
    end
    return nil
end

-- Find closest Marker to player
local function findClosest(markerList)
    if not markerList or #markerList == 0 then return nil end

    local playerPos = getExteriorPlayerPos(self.position)
    if not playerPos then return nil end

    local closest = nil
    local minDistance = math.huge

    for _, marker in ipairs(markerList) do
        local dist = getChebyshevDistance(playerPos, marker.x, marker.y)
        if dist < minDistance then
            minDistance = dist
            closest = marker
        end
    end
    return closest
end

-- Show possible destination of standard Intervention spell
local function showStandardInterventionDestination(data)
    local closest = findClosest(data.markerList)
    local interventionType
    if data.markerType == "templemarker" then
        interventionType = "Almsivi"
    elseif data.markerType == "divinemarker" then
        interventionType = "Divine"
    else return end

    local closestLabel = "Unknown"
    if closest then closestLabel = closest.label end
    ui.showMessage("Closest discovered " .. interventionType .. " Intervention destination: " .. closestLabel)
end

return {
    eventHandlers = {
        -- Receive Teleport data from Global script and create menu.
        receiveTeleportData = createInterventionMenu,
        -- Receive new marker discovery from Global script and show message.
        receiveNewDiscovery = createDiscoveryMessage,
        -- Receive Marker data from Global script for standard Intervention spell processing.
        receiveMarkerData = showStandardInterventionDestination
    },
    engineHandlers = {
        -- Runs on every frame to check whether player has cast a Greater Intervention spell,
        -- or selected a standard Intervention spell.
        onUpdate = function(dt)

            -- If no menu has been created
            if currentMenu == nil then
                -- Check whether player has cast a Greater Intervention spell.
                local active = types.Actor.activeSpells(self)
                for spellId, markerType in pairs(SPELL_MAP) do
                    if active:isSpellActive(spellId) then
                        -- Request Teleport data for corresponding marker type from Global script.
                        -- This will also build the menu.
                        core.sendGlobalEvent('requestTeleportData', { type = markerType })
                        -- Remove the active Greater Intervention spell from the player.
                        for id, activeSpell in pairs(active) do
                            if activeSpell.id == spellId then
                                active:remove(activeSpell.activeSpellId)
                                break
                            end
                        end
                        break
                    end
                end
            end

            -- Standard Intervention enhancement
            if ENABLE_STANDARD_INTERVENTION_ENHANCE then
                -- Get currently selected spell.
                local selectedSpell = types.Player.getSelectedSpell(self)
                local sId = selectedSpell.id:lower()
                local noMatch = true;

                -- Check if the currently selected spell is a standard Intervention one
                for spellId, markerType in pairs(STANDARD_SPELL_MAP) do
                    if sId == spellId then
                        -- Match found
                        noMatch = false
                        -- Only show message if not already done so for this selected spell.
                        if sId ~= recentStandardInterventionSpell then
                            recentStandardInterventionSpell = sId
                            -- Request Marker data for corresponding marker type from Global script.
                            core.sendGlobalEvent('requestMarkerData', { type = markerType })
                        end
                    end
                end
                -- If no standard Intervention spell is selected, reset recent selected spell tracker
                if noMatch then recentStandardInterventionSpell = selectedStandardIntherventionSpell.Unknown end
            end
        end,
        -- Controller support
        onControllerButtonPress = function(id)
            if not currentMenu then return end

            local newIndex = focusedIndex
            local totalButtons = #menuItems

            if id == input.CONTROLLER_BUTTON.DPadDown then
                newIndex = focusedIndex + 1
            elseif id == input.CONTROLLER_BUTTON.DPadUp then
                newIndex = focusedIndex - 1
            elseif id == input.CONTROLLER_BUTTON.DPadRight then
                newIndex = focusedIndex + buttonsPerCol
            elseif id == input.CONTROLLER_BUTTON.DPadLeft then
                newIndex = focusedIndex - buttonsPerCol
            elseif id == input.CONTROLLER_BUTTON.A then
                if menuItems[focusedIndex] then menuItems[focusedIndex]() end
                return
            elseif id == input.CONTROLLER_BUTTON.B then
                closeMenu()
                return
            end

            -- For horizontal (column) navigation, if moving to a column that has less than MAX_PER_COLUMN,
            -- and the index is set out of bounds, set it to the last button index.
            if newIndex > totalButtons then newIndex = totalButtons end

            -- Clamp the index within valid bounds
            if newIndex ~= focusedIndex and newIndex >= 1 and newIndex <= totalButtons then
                focusedIndex = newIndex
                createInterventionMenu(currentMarkerList) -- Refresh menu
            end
        end,
        -- Keyboard support
        onKeyPress = function(e)
            if not currentMenu then return end

            local newIndex = focusedIndex
            local totalButtons = #menuItems

            if e.code == input.KEY.DownArrow then
                newIndex = focusedIndex + 1
            elseif e.code == input.KEY.UpArrow then
                newIndex = focusedIndex - 1
            elseif e.code == input.KEY.RightArrow then
                newIndex = focusedIndex + buttonsPerCol
            elseif e.code == input.KEY.LeftArrow then
                newIndex = focusedIndex - buttonsPerCol
            elseif e.code == input.KEY.Enter or e.code == input.KEY.Space then
                if menuItems[focusedIndex] then menuItems[focusedIndex]() end
                return
            elseif e.code == input.KEY.Escape then
                closeMenu()
                return
            end

            if newIndex > totalButtons then newIndex = totalButtons end

            if newIndex ~= focusedIndex and newIndex >= 1 and newIndex <= totalButtons then
                focusedIndex = newIndex
                createInterventionMenu(currentMarkerList)
            end
        end
    }
}
