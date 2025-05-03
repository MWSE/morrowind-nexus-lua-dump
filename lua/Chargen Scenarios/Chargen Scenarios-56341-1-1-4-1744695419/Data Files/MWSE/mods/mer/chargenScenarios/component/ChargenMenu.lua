local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("ChargenMenu")

---@class ChargenScenarios.ChargenMenu.config
---@field id string The id of the menu
---@field name string The name of the menu, displayed in MCM
---@field priority number
---@field buttonLabel string
---@field getButtonValue fun(self: ChargenScenarios.ChargenMenu):string
---@field createMenu fun(self: ChargenScenarios.ChargenMenu) Make sure to call self:okCallback() when clicking ok
---@field validate? fun(self: ChargenScenarios.ChargenMenu):boolean Return false if the menu needs to be opened again after other things have changed
---@field isActive? fun(self: ChargenScenarios.ChargenMenu):boolean Return false if the menu should not be shown
---@field getTooltip nil|fun(self: ChargenScenarios.ChargenMenu):nil|{ header: string, description: string} Return a tooltip for the menu
---@field onStart? fun(self: ChargenScenarios.ChargenMenu) Callback triggered when chargen finishes

---Defines a menu that is added to the chargen sequence
---@class ChargenScenarios.ChargenMenu : ChargenScenarios.ChargenMenu.config
---@field registeredMenus table<string, ChargenScenarios.ChargenMenu> The menus that have been registered
---@field orderedMenus ChargenScenarios.ChargenMenu[] The menus in the order they should be added
---@field data fun(self: ChargenScenarios.ChargenMenu):table<string, boolean> Get the data table for the player
---@field getCompleted fun(self: ChargenScenarios.ChargenMenu):boolean Check if the menu has been completed
---@field setCompleted fun(self: ChargenScenarios.ChargenMenu) Set the menu as completed
---@field new fun(data:ChargenScenarios.ChargenMenu.config):ChargenScenarios.ChargenMenu Create a new ChargenMenu
---@field register fun(data:ChargenScenarios.ChargenMenu.config):ChargenScenarios.ChargenMenu Register a new ChargenMenu
---@field createMenu fun(self: ChargenScenarios.ChargenMenu) Create the menu
---@field okCallback fun(self: ChargenScenarios.ChargenMenu) Callback to call when the ok button is clicked
---@field isActive fun(self: ChargenScenarios.ChargenMenu):boolean Check if the menu is active
---@field validate fun(self: ChargenScenarios.ChargenMenu):boolean Check if the menu is valid
---@field onStart fun(self: ChargenScenarios.ChargenMenu) Callback triggered when chargen finishes
local ChargenMenu = {
    registeredMenus = {},
    orderedMenus = {}
}

---Register a menu that can be used in the chargen sequence
---@param data ChargenScenarios.ChargenMenu.config
---@return ChargenScenarios.ChargenMenu
function ChargenMenu.register(data)
    local menu = ChargenMenu.new(data)
    ChargenMenu.registeredMenus[menu.id] = menu

    --insert into ordered list, where higher priority is first
    table.insert(ChargenMenu.orderedMenus, 1, menu)
    table.sort(ChargenMenu.orderedMenus, function(a, b) return a.priority > b.priority end)

    if common.config.mcm[menu:getMcmId()] == nil then
        common.config.mcm[menu:getMcmId()] = true
    end

    return menu
end

function ChargenMenu.new(data)
    logger:assert(data.id ~= nil, "ChargenMenu must have an id")
    logger:assert(data.priority ~= nil, "ChargenMenu must have a priority")
    logger:assert(data.buttonLabel ~= nil, "ChargenMenu must have a buttonLabel")
    logger:assert(data.getButtonValue ~= nil, "ChargenMenu must have a getButtonValue")
    logger:assert(data.createMenu ~= nil, "ChargenMenu must have a createMenu")

    local menu = table.copy(data)
    menu.validate = menu.validate or function() return true end
    menu.isActive = menu.isActive or function() return true end
    menu.onStart = menu.onStart or function() end
    setmetatable(menu, { __index = ChargenMenu })
    return menu
end


function ChargenMenu:okCallback()
    logger:debug("Pressed ok in %s menu, moving to next menu", self.id)
    self:setCompleted()
    ---@type ChargenScenarios.ChargenMenu | nil
    local nextMenu
    local foundThisMenu = false
    for i, menu in ipairs(ChargenMenu.orderedMenus) do
        logger:debug("Checking menu %s", menu.id)
        if menu == self then foundThisMenu = true end
        if foundThisMenu and #ChargenMenu.orderedMenus > i then
            local thisMenu = ChargenMenu.orderedMenus[i + 1]
            if thisMenu:isActive() and thisMenu:isEnabled() and not thisMenu:getCompleted() then
                nextMenu = thisMenu
                logger:debug("Next menu is %s", nextMenu.id)
                break
            end
        end
    end
    if nextMenu then
        logger:debug("Creating next menu")
        nextMenu:createMenu()
    else
        logger:debug("No next menu, returning to stat menu")
        tes3.runLegacyScript{ command = "EnableStatReviewMenu"} ---@diagnostic disable-line
    end
end

---Get the ID used for storing MCM config
function ChargenMenu:getMcmId()
    return "chargenScenariosMenu_" .. self.id
end

---Check if the menu is enabled in the MCM
function ChargenMenu:isEnabled()
    return common.config.mcm[self:getMcmId()]
end

function ChargenMenu:data()
    tes3.player.tempData.chargenScenariosMenus = tes3.player.tempData.chargenScenariosMenus or {}
    return tes3.player.tempData.chargenScenariosMenus
end


function ChargenMenu:getCompleted()
    return self:data()[self.id]
end

function ChargenMenu:setCompleted()
    self:data()[self.id] = true
end

return ChargenMenu