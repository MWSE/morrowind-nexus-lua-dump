--[[
    Gear Selector Menu

    - Show each gear list as checkboxes
]]

local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("LoadoutsMenu")
local ChargenMenu = require("mer.chargenScenarios.component.ChargenMenu")
local Menu = require("mer.chargenScenarios.util.Menu")
local LoadoutUI = require("mer.chargenScenarios.util.Loadout")
local Loadouts = require("mer.chargenScenarios.component.Loadouts")


---@class ChargenScenarios.LoadoutsMenu
local LoadoutsMenu = {
    MENU_ID = "ChargenScenarios:LoadoutsMenu",
    LOADOUT_LIMIT_LABEL_ID = "ChargenScenarios_LoadoutsMenu_limitLabel",
}

local function getNumActiveLoadouts(loadouts)
    local active = 0
    for _, itemList in ipairs(loadouts) do
        if itemList.active and not itemList.defaultActive then
            active = active + 1
        end
    end
    return active
end

---@type ChargenScenarios.ChargenMenu.config
local menu = {
    id = "loadoutsMenu",
    name = "Loadouts",
    priority = -1500,
    buttonLabel = "Items",
    getButtonValue = function(self)
        return string.format("Loadouts Active: %d", getNumActiveLoadouts(Loadouts.getLoadouts()))
    end,
    getTooltip = function(self)
        local loadouts = Loadouts.getLoadouts()
        local header = "Loadouts"
        local description = ""
        for _, itemList in ipairs(loadouts) do
            local valid = itemList.active
                and not itemList.defaultActive
            if valid then
                description = description .. "- " .. itemList.name .. "\n"
            end
        end

        if description == "" then
            description = "No loadouts selected."
        else
             --remove last newline
            description = description:sub(1, -2)
        end
        return {
            header = header,
            description = description,
        }
    end,
    createMenu = function(self)
        LoadoutsMenu.open{
            okCallback = function()
                self:okCallback()
            end
        }
    end,
    onStart = function(self)
        timer.start{
            duration = 0.5,
            callback = function()
                Loadouts.removeCommonClothing()
                Loadouts.doItems()
                Loadouts.equipBestItemForEachSlot()
                event.trigger("ChargenScenarios:Loadouts_Done")
            end
        }
    end,
}
ChargenMenu.register(menu)



local function updateLimitLabel(loadouts)
    logger:debug("Updating loadout limit label")
    local limit = common.config.mcm.itemPackageLimit
    local activeLoadouts = getNumActiveLoadouts(loadouts)
    local text = string.format("Active Loadouts: %s/%s", activeLoadouts, limit)
    local label = tes3ui.findMenu(LoadoutsMenu.MENU_ID):findChild(LoadoutsMenu.LOADOUT_LIMIT_LABEL_ID)
    label.text = text
end

---@param e { parent: tes3uiElement, loadouts: ChargenScenarios.ItemList[] }
local function createLimitLabel(e)
    local subheading = Menu.createSubheading{
        parent = e.parent,
        id = LoadoutsMenu.LOADOUT_LIMIT_LABEL_ID,
        text = "Active Loadouts: 0/3"
    }
    updateLimitLabel(e.loadouts)
    return subheading
end


---Sorts lists with defaultActive first, then active, then by name
---@param a ChargenScenarios.ItemList
---@param b ChargenScenarios.ItemList
local function sortLoadouts(a, b)
    if a.defaultActive == b.defaultActive then
        if a.active == b.active then
            return a.name < b.name
        end
        return a.active and not b.active
    end
    return a.defaultActive and not b.defaultActive
end


local function createOrUpdateLoadoutsList(e)
    table.sort(e.loadouts, sortLoadouts)
    e.parent:getContentElement():destroyChildren()
    for _, itemList in ipairs(e.loadouts) do
        LoadoutUI.createLoadoutRow{
            parent = e.parent,
            itemList = itemList,
            canClick = e.canClick,
            onClick = e.onClick,
        }
    end
    updateLimitLabel(e.loadouts)
end

---@param loadouts ChargenScenarios.ItemList[]
---@return fun(ChargenScenarios.ItemList):boolean
local getCanClick = function(loadouts)
    return function(itemList)
        local limit = common.config.mcm.itemPackageLimit
        local active = getNumActiveLoadouts(loadouts)
        if itemList.active then return true end
        return active < limit
    end
end

---@param e { parent: tes3uiElement, loadouts: ChargenScenarios.ItemList[] }
---@return tes3uiElement
local function createLoadoutList(e)
    local scrollPane = e.parent:createVerticalScrollPane{
        id = "ChargenScenarios_LoadoutsMenu_scrollPane",
    }
    scrollPane.minHeight = 400
    scrollPane.widthProportional = 1.0
    scrollPane.heightProportional = nil


    local onClick
    onClick = function()
        createOrUpdateLoadoutsList{
            parent = scrollPane,
            loadouts = e.loadouts,
            canClick = getCanClick(e.loadouts),
            onClick = onClick,
        }
    end
    onClick()
    return scrollPane
end


---@param e {scenario: ChargenScenariosScenario, okCallback: function}
function LoadoutsMenu.open(e)
    logger:debug("Opening Loadouts Menu")

    local loadouts = Loadouts.getLoadouts()
    --for each itemList, if defaultActive then set active to true
    for _, itemList in ipairs(loadouts) do
        if itemList.defaultActive then
            itemList.active = true
        end
    end

    local menu = tes3ui.createMenu{ id = LoadoutsMenu.MENU_ID, fixedFrame = true }
    local outerBlock = Menu.createOuterBlock{
        id = "ChargenScenarios_LoadoutsMenu_outerBlock",
        parent = menu
    }
    outerBlock.minWidth = 400
    --heading
    Menu.createHeading{
        parent = outerBlock,
        text = "Starting Equipment"
    }
    --subheading - limits
    createLimitLabel{
        parent = outerBlock,
        loadouts = loadouts
    }

    local scrollPane = createLoadoutList{
        parent = outerBlock,
        loadouts = loadouts
    }

    local buttonsBlock = Menu.createButtonsBlock{
        id = "ChargenScenarios_LoadoutsMenu_buttonsBlock",
        parent = outerBlock,
    }
    buttonsBlock.widthProportional = 1.0


    --Randomise button
    --  - Unselect any non-default loadouts already selected
    --  - Up to the max limit, select random loadouts
    --  - "Select" a loadout by actually clicking the button with button:trigger("mouseClick")
    Menu.createButton{
        id = "ChargenScenarios_LoadoutsMenu_randomiseButton",
        parent = buttonsBlock,
        text = "Random",
        callback = function()
            logger:debug("Randomise button clicked")
            local limit = math.min(common.config.mcm.itemPackageLimit, #loadouts)
            local activeLoadouts = getNumActiveLoadouts(loadouts)
            logger:debug("Active loadouts: %s/%s", activeLoadouts, limit)

            for _, row in ipairs(scrollPane:getContentElement().children) do
                local button = row:findChild("ChargenScenarios_LoadoutsMenu_button")
                local itemList = row:getLuaData("loadout")
                if button and itemList.active and not itemList.defaultActive then
                    logger:debug("Unselecting %s", itemList.name)
                    LoadoutUI.clickRow(row, false)
                end
            end

            local selectedItemLists = {}
            local attempts = 0
            local maxAttempst = 100
            while table.size(selectedItemLists) < limit and attempts < maxAttempst do
                local randomIndex = math.random(1, #loadouts)
                local itemList = loadouts[randomIndex]
                if itemList.defaultActive ~= true and not selectedItemLists[itemList] then
                    selectedItemLists[itemList] = true
                end
                attempts = attempts + 1
            end

            --Trigger the click event for each selected loadout
            for _, row in ipairs(scrollPane:getContentElement().children) do
                local itemList = row:getLuaData("loadout")
                local button = row:findChild("ChargenScenarios_LoadoutsMenu_button")
                if button and selectedItemLists[itemList] then
                    logger:debug("Triggering click for %s", itemList.name)
                    LoadoutUI.clickRow(row, false)
                end
            end

            local onClick
            onClick = function()
                createOrUpdateLoadoutsList{
                    parent = scrollPane,
                    loadouts = loadouts,
                    canClick = getCanClick(loadouts),
                    onClick = onClick,
                }
            end
            onClick()

        end
    }

    --Ok button
    Menu.createButton{
        id = "ChargenScenarios_LoadoutsMenu_okayButton",
        parent = buttonsBlock,
        text = "Ok",
        callback = function()
            tes3ui.findMenu(LoadoutsMenu.MENU_ID):destroy()
            e.okCallback()
        end
    }

    menu:updateLayout()
end

