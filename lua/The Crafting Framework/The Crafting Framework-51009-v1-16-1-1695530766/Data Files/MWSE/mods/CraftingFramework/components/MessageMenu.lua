local Util = require("CraftingFramework.util.Util")
local Indicator = require("CraftingFramework.components.Indicator")
local logger = Util.createLogger("MessageMenu")
local config = require("CraftingFramework.config")

---@class CraftingFramework.MessageMenu.button : tes3ui.showMessageMenu.params.button
---@field position number @The position of this button in the list of buttons, starting at 0 for the first button.


---@class CraftingFramework.MessageMenu.data
---@field id string The unique ID for this Message Menu
---@field message string
---@field buttons CraftingFramework.MessageMenu.button[]
---@field cancels? boolean
---@field priority? number The priority of this registration of the message menu. When multiple menus with this id are registered, the message and configuration options of the highest priority one will be used.

---@class CraftingFramework.MessageMenu : CraftingFramework.MessageMenu.data
local MessageMenu = {
    registeredMenus = {}
}

---@param list1 CraftingFramework.MessageMenu.button[]
---@param list2 CraftingFramework.MessageMenu.button[]
function MessageMenu.mergeButtons(list1, list2)
    local merged = {}
    for _, button in ipairs(list1) do
        local position = button.position or 0
        table.insert(merged, position, button)
    end

end

---@param data CraftingFramework.MessageMenu.data
function MessageMenu.register(data)
    logger:assert(type(data.id) == "string", "id must be a string")
    logger:assert(type(data.message) == "string", "message must be a string")
    logger:assert(type(data.buttons) == "table", "buttons must be a table")

    local messageMenu = {}
    messageMenu.id = data.id
    messageMenu.message = data.message
    messageMenu.buttons = data.buttons
    messageMenu.cancels = not not data.cancels
    messageMenu.priority = data.priority or 0

    local existingMenu = MessageMenu.registeredMenus[messageMenu.id]
    if existingMenu then
        if existingMenu.priority > messageMenu.priority then
            logger:debug("Existing menu has higher priority, using those configs")
            messageMenu.message = existingMenu.message
            messageMenu.cancels = existingMenu.cancels
            messageMenu.priority = existingMenu.priority
        end
        --Merging buttons
        local higherPriorityMenu = existingMenu.priority > messageMenu.priority and existingMenu or messageMenu
        local lowerPriorityMenu = existingMenu.priority > messageMenu.priority and messageMenu or existingMenu
        messageMenu.buttons = MessageMenu.mergeButtons(higherPriorityMenu.buttons, lowerPriorityMenu.buttons)
    end

    MessageMenu.registeredMenus[messageMenu.id] = messageMenu
    logger:debug("Registered %s as MessageMenu", messageMenu.id)

    return messageMenu
end