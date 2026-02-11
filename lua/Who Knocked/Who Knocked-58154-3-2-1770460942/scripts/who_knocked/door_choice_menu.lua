-- Door Choice Menu for Knock-Knock Interactions
-- Provides choice between knock, lockpick, and cancel
-- Part of the Universal Activator Framework

local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local auxUi = require("openmw_aux.ui")
local core = require("openmw.core")

local doorChoiceMenu = {}

-- UI mode change detection to prevent menu conflicts
local currentMenuRoot = nil
local lastUiMode = nil

-- Check if UI mode changed and close menu if needed
local function checkUiModeChange()
    local currentMode = I.UI.getMode()
    if currentMode ~= lastUiMode then
        -- UI mode changed, check if we should close our menu
        if currentMenuRoot and currentMode ~= "Interface" then
            doorChoiceMenu.closeMenu(currentMenuRoot)
            currentMenuRoot = nil
        end
        lastUiMode = currentMode
    end
end

-- Helper function to check if lockpick system is enabled
local function isLockpickEnabled()
    -- Query global script for lockpick setting
    -- The global script will respond with WhoKnocked_QueryLockpickEnabled event
    -- For now, we'll default to true and let the action functions handle the check
    return true -- Will be checked again in action function
end

-- Helper function to check if dialogue system is enabled
local function isDialogueEnabled()
    -- Query global script for dialogue setting
    -- The global script will respond with WhoKnocked_QueryDialogueEnabled event
    -- For now, we'll default to true and let the action functions handle the check
    return true -- Will be checked again in action function
end

-- Show the door interaction choice menu
function doorChoiceMenu.showDoorChoice(door, actor)
    -- Close any existing menu first
    if currentMenuRoot then
        doorChoiceMenu.closeMenu(currentMenuRoot)
    end
    
    local root
    
    -- Store current UI mode
    lastUiMode = I.UI.getMode()
    
    -- Start UI mode change monitoring
    local function startMonitoring()
        local monitorTimer = async:newUnsavableGameTimer(0.1, function()
            checkUiModeChange()
            -- Continue monitoring if menu is still open
            if currentMenuRoot then
                async:newUnsavableGameTimer(0.1, startMonitoring)
            end
        end)
    end
    
    -- Default to enabled (will be updated by responses)
    local lockpickEnabled = true
    local dialogueEnabled = true
    
    -- Send query events for current settings
    core.sendGlobalEvent("WhoKnocked_QueryLockpickEnabled", {door = door})
    core.sendGlobalEvent("WhoKnocked_QueryDialogueEnabled", {door = door})
    
    -- Create menu choices
    local choices = {}
    
    -- Lockpick option (check actual setting)
    table.insert(choices, {
        text = "[Lockpick]",
        color = util.color.rgb(0.7, 0.85, 1.0),  -- Light blue
        description = "Try to pick the lock with your skills",
        action = function()
            doorChoiceMenu.closeMenu(root)
            -- Send query to global script with actor reference for response
            core.sendGlobalEvent("WhoKnocked_QueryLockpickEnabled", {door = door, actor = actor})
        end
    })
    
    -- Dialogue option (check actual setting)
    table.insert(choices, {
        text = "[Persuade]",
        color = util.color.rgb(0.85, 0.7, 1.0),  -- Light purple
        description = "Try to persuade them to open the door",
        action = function()
            doorChoiceMenu.closeMenu(root)
            -- Send query to global script with actor reference for response
            core.sendGlobalEvent("WhoKnocked_QueryDialogueEnabled", {door = door, actor = actor})
        end
    })
    
    -- Cancel option
    table.insert(choices, {
        text = "[Cancel]",
        color = util.color.rgb(0.7, 0.7, 0.7),  -- Light gray
        description = "Cancel interaction and walk away",
        action = function()
            doorChoiceMenu.closeMenu(root)
            -- Do nothing, just close the menu
        end
    })
    
    -- Build UI content
    local content = doorChoiceMenu.buildMenuContent(door, choices)
    
    -- Create the menu window
    root = ui.create {
        layer = "Windows",
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxSolid,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            relativeSize = util.vector2(0.6, 0.4),  -- Smaller for door menu
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    relativeSize = util.vector2(1, 1),
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    padding = 24,
                    backgroundColor = util.color.rgba(0.0, 0.0, 0.0, 1.0),
                },
                content = ui.content(content)
            }
        }
    }
    
    -- Track this menu instance and start monitoring
    currentMenuRoot = root
    startMonitoring()
    
    I.UI.setMode("Interface", { windows = {} })
    
    return root
end

-- Build the menu content UI
function doorChoiceMenu.buildMenuContent(door, choices)
    local content = {}
    
    -- Title
    table.insert(content, {
        type = ui.TYPE.Text,
        props = {
            text = "knock knock",
            textSize = 24,
            textColor = util.color.rgb(0.9, 0.8, 0.6),
            textAlign = ui.ALIGNMENT.Center,
            paddingBottom = 16,
        }
    })
    
    -- Choices
    for i, choice in ipairs(choices) do
        -- Choice button
        table.insert(content, {
            type = ui.TYPE.Container,
            props = {
                paddingTop = 8,
                paddingBottom = 8,
            },
            content = ui.content({
                {
                    type = ui.TYPE.Container,
                    template = I.MWUI.templates.pane,
                    props = {
                        relativeSize = util.vector2(1, 1),
                        padding = 16,
                    },
                    events = {
                        mouseClick = async:callback(choice.action)
                    },
                    content = ui.content({
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = choice.text,
                                textSize = 18,
                                textColor = choice.color or util.color.rgb(0.9, 0.9, 0.9),
                                textAlign = ui.ALIGNMENT.Center,
                            }
                        }
                    })
                }
            })
        })
        
        -- Spacer between choices
        if i < #choices then
            table.insert(content, {
                type = ui.TYPE.Container,
                props = { paddingTop = 12 },
                content = ui.content({})
            })
        end
    end
    
    return content
end

-- Close the menu
function doorChoiceMenu.closeMenu(root)
    if root then
        auxUi.deepDestroy(root)
        root = nil
    end
    -- Clear tracking
    currentMenuRoot = nil
    I.UI.setMode(nil)
end

return doorChoiceMenu
