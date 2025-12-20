local core = require("openmw.core")
local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')
local settings = require("scripts.voshondsquickselect.qs_settings")
local Debug = require("scripts.voshondsquickselect.qs_debug")

-- Constants
local MODNAME = "VoshondsQuickSelect"
local playerSettings = storage.playerSection('SettingsPlayer' .. MODNAME)
local HOTBAR_UPDATE_INTERVAL = 5.0 -- Update hotbar at most once per 5 seconds

-- State variables
local selectedPage = 0
local hotbarContainer = nil
local lastHotbarUpdateTime = 0   -- Timestamp of last hotbar update
local initialHotbarDrawn = false -- Flag to ensure we only draw the hotbar once at startup

-- Debug logging with timestamps
local function log(message, level)
    local timestamp = os.date("%H:%M:%S")
    local prefix = string.format("[%s] [QuickSelect] ", timestamp)

    if level == "error" then
        Debug.error("QuickSelect_p", prefix .. message)
    elseif level == "warning" then
        Debug.warning("QuickSelect_p", prefix .. message)
    else
        -- Regular debug messages go through the Debug.quickSelect function
        -- which already checks the enableDebugLogging setting
        Debug.quickSelect(prefix .. message)
    end
end

-- Simple function to draw the hotbar (will be replaced by the actual implementation in qs_hotbar.lua)
local function drawHotbar()
    log("Drawing hotbar from QuickSelect_P", "info")

    -- This is just a placeholder. The actual drawHotbar will be handled by QuickSelect_Hotbar
    if I.QuickSelect_Hotbar and I.QuickSelect_Hotbar.drawHotbar then
        I.QuickSelect_Hotbar.drawHotbar()
    else
        log("QuickSelect_Hotbar interface not available yet", "info")
    end
end

-- Should we update the hotbar? (prevents excessive redrawing)
local function shouldUpdateHotbar(forceUpdate)
    if forceUpdate then return true end

    local currentTime = os.time()
    if currentTime - lastHotbarUpdateTime >= HOTBAR_UPDATE_INTERVAL then
        lastHotbarUpdateTime = currentTime
        return true
    end

    return false
end

-- Input handling
local function onInputAction(action)
    if action >= input.ACTION.QuickKey1 and action <= input.ACTION.QuickKey10 then
        local slot = action - input.ACTION.QuickKey1 + 1

        -- Debug: Check all modifier states
        local shiftPressed = input.isShiftPressed()
        local ctrlPressed = input.isCtrlPressed()
        local mouse4Pressed = input.isMouseButtonPressed(4)
        local mouse5Pressed = input.isMouseButtonPressed(5)
        
        log("Input debug - Shift: " .. tostring(shiftPressed) .. ", Ctrl: " .. tostring(ctrlPressed) .. 
            ", Mouse4: " .. tostring(mouse4Pressed) .. ", Mouse5: " .. tostring(mouse5Pressed), "info")

        -- Direct hotbar selection:
        -- Default: Keys 1-0 select slots from the first hotbar (page 0)
        -- Shift OR Mouse4: Shift+1-0 or Mouse4+1-0 select slots from the second hotbar (page 1)
        -- Ctrl OR Mouse5: Ctrl+1-0 or Mouse5+1-0 select slots from the third hotbar (page 2)
        local targetPage = 0
        if shiftPressed or mouse4Pressed then
            targetPage = 1
            log("Target page set to 1 (Shift: " .. tostring(shiftPressed) .. ", Mouse4: " .. tostring(mouse4Pressed) .. ")", "info")
        elseif ctrlPressed or mouse5Pressed then
            targetPage = 2
            log("Target page set to 2 (Ctrl: " .. tostring(ctrlPressed) .. ", Mouse5: " .. tostring(mouse5Pressed) .. ")", "info")
        else
            log("Target page set to 0 (default)", "info")
        end

        -- If we're on a different page than the target, switch to it
        if selectedPage ~= targetPage then
            selectedPage = targetPage
            log("Switched to page " .. targetPage, "info")
        end

        -- Calculate the actual slot number based on the page
        local actualSlot = slot + (targetPage * 10)
        log("Activated slot " .. actualSlot .. " (slot " .. slot .. " on page " .. targetPage .. ")", "info")

        -- Now that interfaces might be available, try to use them
        if I.QuickSelect_Storage then
            log("QuickSelect_Storage interface is available", "info")

            local itemData = I.QuickSelect_Storage.getFavoriteItemData(actualSlot)

            if I.QuickSelect_Hotbar then
                log("QuickSelect_Hotbar interface is available, resetting fade", "info")
                I.QuickSelect_Hotbar.resetFade()
                -- Force update the hotbar when a slot is activated
                lastHotbarUpdateTime = os.time()
                I.QuickSelect_Hotbar.drawHotbar()
            end

            -- Process item data if available
            if itemData then
                log("Item data found for slot " .. actualSlot, "info")

                -- Handle spells
                if itemData.spell and not itemData.enchantId then
                    log("Processing spell in slot " .. actualSlot, "info")

                    local selectedSpell = types.Actor.getSelectedSpell(self)
                    if selectedSpell and selectedSpell.id == itemData.spell then
                        -- Toggle spell stance if the same spell is already selected
                        local currentStance = types.Actor.getStance(self)
                        if currentStance == types.Actor.STANCE.Spell then
                            types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                        else
                            types.Actor.setStance(self, types.Actor.STANCE.Spell)
                        end

                        -- Update the hotbar UI to reflect the spell change
                        if I.QuickSelect_Hotbar then
                            lastHotbarUpdateTime = os.time()
                            I.QuickSelect_Hotbar.drawHotbar()
                        end
                    else
                        -- If a different spell is selected, handle spell stance
                        local currentStance = types.Actor.getStance(self)
                        local wasSpellStance = (currentStance == types.Actor.STANCE.Spell)
                        local hadSpellSelected = (selectedSpell ~= nil)

                        -- Change to the new spell
                        types.Actor.setSelectedSpell(self, itemData.spell)

                        -- Always set stance to Spell when selecting a new spell
                        types.Actor.setStance(self, types.Actor.STANCE.Spell)

                        -- Update UI after a small delay
                        async:newUnsavableSimulationTimer(0.05, function()
                            if I.QuickSelect_Hotbar then
                                lastHotbarUpdateTime = os.time()
                                I.QuickSelect_Hotbar.drawHotbar()
                            end
                        end)
                    end
                else
                    -- Handle enchanted items
                    if itemData.enchantId then
                        log("Processing enchanted item in slot " .. actualSlot, "info")
                        local enchantedItem = types.Actor.getSelectedEnchantedItem(self)
                        local realItem = types.Actor.inventory(self):find(itemData.itemId)

                        -- Only proceed if the item exists in inventory
                        if realItem then
                            -- Check if the same enchanted item is already selected
                            if enchantedItem and enchantedItem.recordId == realItem.recordId then
                                -- Toggle enchanted item stance if already selected
                                local currentStance = types.Actor.getStance(self)
                                if currentStance == types.Actor.STANCE.Spell then
                                    types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                                else
                                    types.Actor.setStance(self, types.Actor.STANCE.Spell)
                                end
                            else
                                -- If a different enchanted item or no item is selected
                                local currentStance = types.Actor.getStance(self)
                                local wasSpellStance = (currentStance == types.Actor.STANCE.Spell)
                                local hadEnchantedItemSelected = (enchantedItem ~= nil)

                                -- Set the new enchanted item
                                types.Actor.setSelectedEnchantedItem(self, realItem)

                                -- Always set stance to Spell when selecting a new enchanted item
                                types.Actor.setStance(self, types.Actor.STANCE.Spell)
                            end

                            -- Update UI after selection
                            async:newUnsavableSimulationTimer(0.05, function()
                                if I.QuickSelect_Hotbar then
                                    lastHotbarUpdateTime = os.time()
                                    I.QuickSelect_Hotbar.drawHotbar()
                                end
                            end)
                        else
                            log("Enchanted item not found in inventory: " .. tostring(itemData.itemId), "warning")
                        end
                    else
                        -- Handle other item types
                        log("Equipping slot " .. actualSlot, "info")
                        I.QuickSelect_Storage.equipSlot(actualSlot)
                    end
                end
            else
                log("No item data for slot " .. actualSlot, "info")
            end
        else
            log("QuickSelect_Storage interface not available", "warning")
        end
    end
end

-- Register our interface immediately
return {
    interfaceName = "QuickSelect",
    interface = {
        drawHotbar = drawHotbar,
        getSelectedPage = function() return selectedPage end,
        setSelectedPage = function(num) selectedPage = num end
    },
    engineHandlers = {
        onInputAction = onInputAction,
        onLoad = function()
            log("Initializing QuickSelect system", "info")

            -- Initialize with page 0 selected
            selectedPage = 0
            lastHotbarUpdateTime = os.time()
            initialHotbarDrawn = false

            -- Draw the hotbar when interfaces are ready (no waiting/checking needed)
            async:newUnsavableSimulationTimer(1.0, function()
                log("Delayed initialization complete", "info")
                if I.QuickSelect_Hotbar and not initialHotbarDrawn then
                    log("Drawing initial hotbar", "info")
                    lastHotbarUpdateTime = os.time()
                    initialHotbarDrawn = true
                    I.QuickSelect_Hotbar.drawHotbar()
                else
                    log("QuickSelect_Hotbar not available for initial draw", "warning")
                end
            end)
        end,
        onUpdate = function(dt)
            -- COMPLETELY DISABLE automatic updates
            -- Only draw hotbar on user action or other explicit triggers
            
            -- Debug: Test mouse button detection (remove this after testing)
            local mouse4 = input.isMouseButtonPressed(5)
            local mouse5 = input.isMouseButtonPressed(4)
            if mouse4 or mouse5 then
                log("Mouse button test - Mouse4: " .. tostring(mouse4) .. ", Mouse5: " .. tostring(mouse5), "info")
            end
        end,
        onSave = function()
            log("Saving QuickSelect state", "info")
            return {
                selectedPage = selectedPage,
                initialHotbarDrawn = initialHotbarDrawn
            }
        end,
        onLoad = function(data)
            log("Loading QuickSelect state", "info")
            if data then
                selectedPage = data.selectedPage or 0
                initialHotbarDrawn = data.initialHotbarDrawn or false
            end
        end
    },
    eventHandlers = {
        -- Respond to settings changes
        settingsChanged = function(data)
            log("Settings changed: " .. tostring(data.key), "info")

            -- If text appearance settings changed, refresh styles and redraw UI
            if (data.page == "SettingsVoshondsQuickSelect" and
                    data.group == "SettingsVoshondsQuickSelectText") or
                (data.key == "slotTextColor" or
                    data.key == "slotTextAlpha" or
                    data.key == "slotTextShadowColor" or
                    data.key == "slotTextShadowAlpha" or
                    data.key == "enableTextShadow" or
                    data.key == "showSlotNumbers" or
                    data.key == "showItemCounts") then
                -- Refresh text styles in the icon controller
                if I.Controller_Icon_QS and I.Controller_Icon_QS.refreshTextStyles then
                    log("Refreshing text styles", "info")
                    I.Controller_Icon_QS.refreshTextStyles()
                end

                -- Force redraw the hotbar to apply changes
                if I.QuickSelect_Hotbar then
                    log("Redrawing hotbar to apply text style changes", "info")
                    lastHotbarUpdateTime = os.time()
                    I.QuickSelect_Hotbar.drawHotbar()
                end
            end
        end
    }
}
