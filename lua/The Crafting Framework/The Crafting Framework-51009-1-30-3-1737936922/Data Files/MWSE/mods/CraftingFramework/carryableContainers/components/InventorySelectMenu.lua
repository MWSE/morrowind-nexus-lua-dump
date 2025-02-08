local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("InventorySelect")
local CarryableContainer = require("CraftingFramework.carryableContainers.components.CarryableContainer")

local SIDEBAR_MENU_ID = "CraftingFramework:InventorySelectMenu"

---@class CraftingFramework.InventorySelectMenu
local InventorySelectMenu = {}

---@alias inventorySelectFilter
---| "'alembic'"
---| "'calcinator'"
---| "'enchanted'"
---| "'ingredients'"
---| "'mortar'"
---| "'quickUse'"
---| "'retort'"
---| "'soulGemFilled'"

---@alias inventorySelectFilterFunction fun(e:{item:tes3item, itemData?:tes3itemData}):boolean

---@type table<inventorySelectFilter, inventorySelectFilterFunction>
local filterMapping = {
    alembic = function(e)
        return e.item.objectType ~= tes3.objectType.apparatus
        and e.item.type --[[@as tes3apparatus]] == tes3.apparatusType.alembic
    end,
    calcinator = function(e)
        return e.item.objectType ~= tes3.objectType.apparatus
        and e.item.type --[[@as tes3apparatus]] == tes3.apparatusType.calcinator
    end,
    enchanted = function(e) --filters for NON-enchanted
        return e.item.enchantment --[[@as tes3misc]] == nil
    end,
    ingredients = function(e)
        return e.item.objectType == tes3.objectType.ingredient
    end,
    mortar = function(e)
        return e.item.objectType ~= tes3.objectType.apparatus
        and e.item.type --[[@as tes3apparatus]] == tes3.apparatusType.mortarPestle
    end,
    quickUse = function(e)
        local filterEventData = {
            claim = false,
            filter = nil,
            item = e.item,
            itemData = e.itemData,
            type = "quick"
        }
        local result = event.trigger("filterInventorySelect", filterEventData)
        return result.filter == true
    end,
    retort = function(e)
        return e.item.objectType ~= tes3.objectType.apparatus
        and e.item.type --[[@as tes3apparatus]] == tes3.apparatusType.retort
    end,
}

---@param reference tes3reference
---@param filter inventorySelectFilterFunction
local function checkItemsAgainstFilter(reference, filter)
    ---@param stack tes3itemStack
    for _, stack in pairs(reference.object.inventory) do
        local numVariables = stack.variables and #stack.variables or 0

        --If there are any items in the stack without itemData, run the filter with just the object
        if numVariables < stack.count then
            if filter{ item = stack.object } then
                return true
            end
        end

        --If there are any items in the stack with itemData, run the filter with the itemData
        if numVariables > 0 then
            for _, itemData in ipairs(stack.variables) do
                if filter{ item = stack.object, itemData = itemData } then
                    return true
                end
            end
        end
    end
end

---@param filter inventorySelectFilter|inventorySelectFilterFunction
local function referenceHasItems(filter, reference)
    if type(filter) == "string" then
        filter = filterMapping[filter]
    end
    return checkItemsAgainstFilter(reference, filter)
end

---@class CraftingFramework.InventorySelectMenu.containerInfo
---@field reference tes3reference The actor or container reference
---@field icon? string The icon to display on the button. If not provided, will be replaced with name of reference object

function InventorySelectMenu.closeSideMenu()
    local menu = tes3ui.findMenu(SIDEBAR_MENU_ID)
    if menu then
        logger:debug("Destroying inventory select menu sidebar")
        menu:destroy()
        tes3ui.leaveMenuMode()
    else
        logger:error("No inventory select menu sidebar to destroy")
    end
end

local function createButtonClickCallback(e, sidebarMenu, containerInfoList, activeIndex, currentIndex, containerInfo)
    return function()
        logger:debug("on sidebar button click, closing menu")
        local selectMenu = tes3ui.findMenu("MenuInventorySelect") --[[@as tes3uiElement]]
        if selectMenu then
            selectMenu:destroy()
        end
        sidebarMenu:destroy()
        e.reference = containerInfo.reference
        activeIndex = currentIndex
        tes3.worldController.menuClickSound:play()
        InventorySelectMenu.doOpenMenu(e, containerInfoList, activeIndex)
    end
end

---@param e tes3ui.showInventorySelectMenu.params
---@param sidebarMenu tes3uiElement
---@param containerInfoList CraftingFramework.InventorySelectMenu.containerInfo[]
---@param activeIndex number index of the currently selected container
function InventorySelectMenu.addButtons(e, sidebarMenu, containerInfoList, activeIndex)
    for index, containerInfo in ipairs(containerInfoList) do
        local iconBorder = sidebarMenu:createThinBorder{ id = "thinborder_container_" .. containerInfo.reference.object.id }
        iconBorder.autoHeight = true
        iconBorder.widthProportional = 1.0
        iconBorder.paddingAllSides = 10
        iconBorder.flowDirection = "left_to_right"
        iconBorder.childAlignY = 0.5
        iconBorder:register("mouseClick", createButtonClickCallback(e, sidebarMenu, containerInfoList, activeIndex, index, containerInfo))


        local icon
        if containerInfo.icon then
            icon = iconBorder:createImage{
                id = "container_" .. containerInfo.reference.object.id,
                path = containerInfo.icon,
            }
            icon.width = 32
            icon.height = 32
            icon.scaleMode = true
        else
            icon = iconBorder:createBlock{
                id = "container_" .. containerInfo.reference.object.id,
            }
            icon.width = 32
            icon.height = 32
        end

        icon.borderRight = 4
        icon:register("mouseClick", createButtonClickCallback(e, sidebarMenu, containerInfoList, activeIndex, index, containerInfo))


        local name = containerInfo.icon and containerInfo.reference.object.name or "Inventory"
        local button = iconBorder:createTextSelect{
            id = "container_" .. containerInfo.reference.object.id,
            text = name
        }
        button.autoHeight = true

        -- if activeIndex ~= index then
        --     button.widget.state = tes3.uiState.disabled
        -- end

        if activeIndex == index then
            button.text = "- " .. button.text
        end

        if referenceHasItems(e.filter, containerInfo.reference) then
            button:register("mouseClick", createButtonClickCallback(e, sidebarMenu, containerInfoList, activeIndex, index, containerInfo))
        else
            button.widget.state = tes3.uiState.disabled
            button.color = tes3ui.getPalette("disabled_color")
        end
    end
end

---@param e tes3ui.showInventorySelectMenu.params
---@param containerInfoList CraftingFramework.InventorySelectMenu.containerInfo[]
---@param activeIndex number index of the currently selected container
function InventorySelectMenu.createSideMenu(e, containerInfoList, activeIndex)
    ---@type tes3uiElement
    local sidebarMenu = tes3ui.createMenu{
        id = SIDEBAR_MENU_ID,
        modal = true,
        fixedFrame = true
    }
    sidebarMenu.minWidth = 300
    sidebarMenu.absolutePosAlignX = 0.25
    sidebarMenu.absolutePosAlignY = 0.5
    sidebarMenu.flowDirection = "top_to_bottom"

    local header = sidebarMenu:createLabel{ id = "header", text = "Containers" }
    header.borderBottom = 6

    InventorySelectMenu.addButtons(e, sidebarMenu, containerInfoList, activeIndex)
    sidebarMenu:updateLayout()
    sidebarMenu:registerBefore("unfocus", function(e) return true end)
    tes3ui.enterMenuMode(SIDEBAR_MENU_ID)
end

---@param e tes3ui.showInventorySelectMenu.params
---@param containerInfoList CraftingFramework.InventorySelectMenu.containerInfo[]
---@param activeIndex number index of the currently selected container
function InventorySelectMenu.doOpenMenu(e, containerInfoList, activeIndex)
    local activeContainer = containerInfoList[activeIndex]
    e.reference = activeContainer.reference
    logger:debug("Opening inventory select menu for %s", e.reference.object.name)

    ---@type CraftingFramework.showInventorySelectMenu.params
    local params = table.copy(e)
    params.callback = function(callbackParams)
        callbackParams = callbackParams or {}
        callbackParams.reference = activeContainer.reference
        if e.callback then e.callback(callbackParams) end
        logger:debug("callback - closing menu")
        InventorySelectMenu.closeSideMenu()
    end
    params.noResultsCallback = function(callbackParams)
        callbackParams = callbackParams or {}
        callbackParams.reference = activeContainer.reference
        if e.noResultsCallback then e.noResultsCallback(callbackParams) end
        logger:debug("noResultsCallback - closing menu")
        InventorySelectMenu.closeSideMenu()
    end

    tes3ui.showInventorySelectMenu(params)
    local selectMenu = tes3ui.findMenu("MenuInventorySelect") --[[@as tes3uiElement]]
    if not selectMenu then
        logger:debug("no selectMenu, probably means nothing passed filter")
        return
    end
    selectMenu:registerBefore("unfocus", function(e) return true end)

    --don't show if the only container is the player
    if #containerInfoList == 1 and containerInfoList[1].icon == nil then
        --don't show container list
    else
        InventorySelectMenu.createSideMenu(e, containerInfoList, activeIndex)
    end

    timer.delayOneFrame(function()
        local selectMenu = tes3ui.findMenu("MenuInventorySelect") --[[@as tes3uiElement]]
        if selectMenu then
            selectMenu:destroy()
        end
        local sidebarMenu = tes3ui.findMenu(SIDEBAR_MENU_ID) --[[@as tes3uiElement]]
        if sidebarMenu then
            sidebarMenu:destroy()
        end
    end)
end

---@class CraftingFramework.showInventorySelectMenu.callbackParams : tes3ui.showInventorySelectMenu.callbackParams
---@field reference tes3reference The reference of the container or actor that was selected


---@class CraftingFramework.showInventorySelectMenu.params : tes3ui.showInventorySelectMenu.params
---@field callback?  fun(e:CraftingFramework.showInventorySelectMenu.callbackParams)
---@field noResultsCallback? fun(e:{item:tes3item|tes3misc, itemData:tes3itemData, reference:tes3reference})
---@field additionalContainers CarryableContainer[]?

---Open an inventory select menu with a sidebar of containers
---@param e CraftingFramework.showInventorySelectMenu.params
function InventorySelectMenu.open(e)
    e.reference = e.reference or tes3.player

    ---@type CraftingFramework.InventorySelectMenu.containerInfo[]
    local containerInfoList = {}

    if referenceHasItems(e.filter, e.reference) then
        table.insert(containerInfoList, {
            reference = e.reference,
        })
    end

    local containers = CarryableContainer.getCarryableContainersInInventory(e.reference)
    if e.additionalContainers and #e.additionalContainers > 0 then
        for _, container in ipairs(e.additionalContainers) do
            table.insert(containers, container)
        end
    end
    if containers and #containers > 0 then
        for _, container in ipairs(containers) do
            local containerRef = container:getContainerRef()
            if containerRef and referenceHasItems(e.filter, containerRef) then
                table.insert(containerInfoList, {
                    reference = containerRef,
                    icon = "icons\\"..container.item.icon
                })
            end
        end
    end

    if #containerInfoList == 0 then
        tes3.messageBox(e.noResultsText)
        if e.noResultsCallback then
            e.noResultsCallback(e)
        end
        return
    end
    InventorySelectMenu.doOpenMenu(e, containerInfoList, 1)
end

return InventorySelectMenu