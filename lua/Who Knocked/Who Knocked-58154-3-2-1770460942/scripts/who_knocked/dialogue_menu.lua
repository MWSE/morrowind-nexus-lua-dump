-- Dialogue Menu for Door Interactions
-- Provides choice between admire, intimidate, bribe, and exit
-- Part of the Universal Activator Framework

local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local auxUi = require("openmw_aux.ui")
local core = require("openmw.core")

local dialogueMenu = {}

-- Show the dialogue choice menu
function dialogueMenu.showDialogueMenu(door, actor)
    local root
    
    -- Check if dialogue system is enabled
    -- Query the global script for current setting
    core.sendGlobalEvent("WhoKnocked_QueryDialogueEnabled", {door = door})
    
    -- For now, assume it's enabled based on our settings
    -- TODO: Implement proper async response handling
    local dialogueEnabled = true -- Based on log showing "ENABLED"
    
    if not dialogueEnabled then
        ui.showMessage("Dialogue system is disabled in settings")
        return
    end
    
    -- Create menu choices
    local choices = {}
    
    -- Admire option
    table.insert(choices, {
        text = "[Admire] Use charm and wit",
        description = "Persuade them with your speechcraft and personality",
        action = function()
            dialogueMenu.closeMenu(root)
            -- Send admire event back to player script
            actor:sendEvent("UA_ExecuteAdmire", {door = door})
        end
    })
    
    -- Intimidate option
    table.insert(choices, {
        text = "[Intimidate] Use threats",
        description = "Force them to open the door through fear",
        action = function()
            dialogueMenu.closeMenu(root)
            -- Send intimidate event back to player script
            actor:sendEvent("UA_ExecuteIntimidate", {door = door})
        end
    })
    
    -- Bribe option
    table.insert(choices, {
        text = "[Bribe] Offer gold",
        description = "Pay them to open the door",
        action = function()
            dialogueMenu.closeMenu(root)
            -- Send bribe event back to player script
            actor:sendEvent("UA_ExecuteBribe", {door = door})
        end
    })
    
    -- Exit option
    table.insert(choices, {
        text = "[Exit] Never mind",
        description = "Cancel and return to previous menu",
        action = function()
            dialogueMenu.closeMenu(root)
            -- Send back to main door menu
            actor:sendEvent("UA_ShowKnockKnock", {door = door})
        end
    })
    
    -- Build UI content
    local content = dialogueMenu.buildMenuContent(door, choices)
    
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
    
    I.UI.setMode("Interface", { windows = {} })
    
    return root
end

-- Build the menu content UI
function dialogueMenu.buildMenuContent(door, choices)
    local content = {}
    
    -- Title
    table.insert(content, {
        type = ui.TYPE.Text,
        props = {
            text = "Dialogue Options",
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
function dialogueMenu.closeMenu(root)
    if root then
        auxUi.deepDestroy(root)
        root = nil
    end
    I.UI.setMode(nil)
end

return dialogueMenu
