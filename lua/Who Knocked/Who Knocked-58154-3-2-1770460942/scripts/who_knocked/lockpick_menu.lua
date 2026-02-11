-- Lockpick Menu for Door Interactions
-- Provides choice between force lock, pick lock, magic unlock, and exit
-- Part of the Universal Activator Framework

local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local auxUi = require("openmw_aux.ui")
local core = require("openmw.core")

local lockpickMenu = {}

-- UI mode change detection to prevent menu conflicts
local currentMenuRoot = nil
local lastUiMode = nil

-- Check if UI mode changed and close menu if needed
local function checkUiModeChange()
    local currentMode = I.UI.getMode()
    if currentMode ~= lastUiMode then
        -- UI mode changed, check if we should close our menu
        if currentMenuRoot and currentMode ~= "Interface" then
            lockpickMenu.closeMenu(currentMenuRoot)
            currentMenuRoot = nil
        end
        lastUiMode = currentMode
    end
end

-- Show the lockpick choice menu
function lockpickMenu.showLockpickMenu(door, actor)
    -- Close any existing menu first
    if currentMenuRoot then
        lockpickMenu.closeMenu(currentMenuRoot)
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
    
    -- The lockpick menu should only be called when the system is confirmed to be enabled
    -- The query/response check happens in the door choice menu before calling this function
    
    -- Create menu choices
    local choices = {}
    
    -- Force lock option
    table.insert(choices, {
        text = "[Force] Break the lock",
        description = "Use brute force to break the lock (may damage the door)",
        action = function()
            lockpickMenu.closeMenu(root)
            -- Send force lock event back to player script
            actor:sendEvent("UA_ExecuteForceLock", {door = door})
        end
    })
    
    -- Pick lock option
    table.insert(choices, {
        text = "[Pick] Use lockpicks",
        description = "Attempt to pick the lock with your skills",
        action = function()
            lockpickMenu.closeMenu(root)
            -- Send pick lock event back to player script
            actor:sendEvent("UA_ExecutePickLock", {door = door})
        end
    })
    
    -- Magic unlock option
    table.insert(choices, {
        text = "[Magic] Use spells",
        description = "Use magical means to unlock the door",
        action = function()
            lockpickMenu.closeMenu(root)
            -- Send magic unlock event back to player script
            actor:sendEvent("UA_ExecuteMagicUnlock", {door = door})
        end
    })
    
    -- Master attempt option
    table.insert(choices, {
        text = "[Master] Combined approach",
        description = "Use all your skills together for the best chance",
        action = function()
            lockpickMenu.closeMenu(root)
            -- Send master attempt event back to player script
            actor:sendEvent("UA_ExecuteMasterAttempt", {door = door})
        end
    })
    
    -- Exit option
    table.insert(choices, {
        text = "[Exit] Never mind",
        description = "Cancel and return to previous menu",
        action = function()
            lockpickMenu.closeMenu(root)
            -- Send back to main door menu
            actor:sendEvent("UA_ShowKnockKnock", {door = door})
        end
    })
    
    -- Build UI content
    local content = lockpickMenu.buildMenuContent(door, choices)
    
    -- Create the menu window
    root = ui.create {
        layer = "Windows",
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxSolid,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            relativeSize = util.vector2(0.6, 0.5),  -- Same size as main menu
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
function lockpickMenu.buildMenuContent(door, choices)
    local content = {}
    
    -- Title
    table.insert(content, {
        type = ui.TYPE.Text,
        props = {
            text = "Lockpick Options",
            textSize = 24,
            textColor = util.color.rgb(0.9, 0.8, 0.6),
            textAlign = ui.ALIGNMENT.Center,
            paddingBottom = 16,
        }
    })
    
    -- Door info
    local doorType = "Unknown"
    if door.recordId then
        if door.recordId:find("shack") or door.recordId:find("house") then
            doorType = "Residence"
        elseif door.recordId:find("shop") or door.recordId:find("store") then
            doorType = "Shop"
        elseif door.recordId:find("guild") then
            doorType = "Guild Hall"
        elseif door.recordId:find("temple") then
            doorType = "Temple"
        elseif door.recordId:find("tavern") or door.recordId:find("inn") then
            doorType = "Tavern"
        end
    end
    
    table.insert(content, {
        type = ui.TYPE.Text,
        props = {
            text = "Door Type: " .. doorType,
            textSize = 16,
            textColor = util.color.rgb(0.7, 0.7, 0.7),
            textAlign = ui.ALIGNMENT.Center,
            paddingBottom = 24,
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
                                textColor = util.color.rgb(0.9, 0.9, 0.9),
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
function lockpickMenu.closeMenu(root)
    if root then
        auxUi.deepDestroy(root)
        root = nil
    end
    -- Clear tracking
    currentMenuRoot = nil
    I.UI.setMode(nil)
end

return lockpickMenu
