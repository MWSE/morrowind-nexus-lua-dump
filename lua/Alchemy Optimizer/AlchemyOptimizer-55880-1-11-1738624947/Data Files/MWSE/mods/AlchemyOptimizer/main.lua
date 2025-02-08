--------------------------------------------------------------------------------
-- MAIN MODULE: main.lua
-- Purpose: Provides the main UI for Alchemy Optimizer, including the Blacklist,
--          Effect Priority, and Potion List tabs.
--------------------------------------------------------------------------------

local modName = "Alchemy Optimizer"
local menuId = "alchemyOptimizerMenu"
local activeTab = "Blacklist"

local potionCrafting = require("AlchemyOptimizer.potionCrafting")
local potionData = require("AlchemyOptimizer.potionData") -- Secondary custom UI script
local ingredientEffects = require("AlchemyOptimizer.ingredientEffects")  -- For dynamic path calculation

-- Persistent data initialization
local function initializeData()
    tes3.player.data.alchemyOptimizer = tes3.player.data.alchemyOptimizer or {}
    tes3.player.data.alchemyOptimizer.blacklist = tes3.player.data.alchemyOptimizer.blacklist or {}
    mwse.log("[main.lua] initializeData: Player data initialized.")
end

--------------------------------------------------------------------------------
-- Blacklist Tab
--------------------------------------------------------------------------------
local function createBlacklistTab(parent)
    local inventory = tes3.player.object.inventory
    local blacklist = tes3.player.data.alchemyOptimizer.blacklist

    local scrollPane = parent:createVerticalScrollPane({ id = "BlacklistScrollPane" })
    for _, stack in pairs(inventory) do
        if stack.object.objectType == tes3.objectType.ingredient then
            local ingredientId = stack.object.id
            local ingredientName = stack.object.name

            local block = scrollPane:createBlock({})
            block.flowDirection = "left_to_right"
            block.widthProportional = 1.0
            block.autoHeight = true
            block.borderBottom = 4

            local labelText = string.format("%s (%s)", ingredientName, ingredientId)
            block:createLabel({ text = labelText })

            local isBlacklisted = blacklist[ingredientId]
            local buttonText = isBlacklisted and "Remove" or "Add"

            local toggleButton = block:createButton({ text = buttonText })
            toggleButton:register("mouseClick", function()
                if blacklist[ingredientId] then
                    blacklist[ingredientId] = nil
                    toggleButton.text = "Add"
                    tes3.messageBox("%s removed from blacklist.", ingredientName)
                else
                    blacklist[ingredientId] = true
                    toggleButton.text = "Remove"
                    tes3.messageBox("%s added to blacklist.", ingredientName)
                end
            end)
        end
    end
    mwse.log("[main.lua] createBlacklistTab: Completed.")
end

--------------------------------------------------------------------------------
-- Effect Priority Tab
--------------------------------------------------------------------------------
local function loadEffectPrioritiesForUI()
    local priorities = {}
    -- Build the path dynamically using the script directory.
    local modDir = ingredientEffects.getScriptDirAbsolute()
    local filePath = modDir .. "effectpriorities.csv"
    mwse.log("[main.lua] loadEffectPrioritiesForUI: Reading CSV from: " .. filePath)
    local file = io.open(filePath, "r")
    if file then
        for line in file:lines() do
            table.insert(priorities, line)
        end
        file:close()
        mwse.log("[main.lua] loadEffectPrioritiesForUI: Successfully loaded effect priorities (" .. #priorities .. " lines).")
    else
        tes3.messageBox("Could not find effectpriorities.csv. Ensure it is in the correct directory:\n" .. filePath)
        mwse.log("[main.lua] loadEffectPrioritiesForUI: ERROR - File not found: " .. filePath)
    end
    return priorities
end

local function createEffectPriorityTab(parent)
    local scrollPane = parent:createVerticalScrollPane({ id = "EffectPriorityScrollPane" })
    local lines = loadEffectPrioritiesForUI()

    if not lines or #lines == 0 then
        scrollPane:createLabel({ text = "No effect priorities loaded." })
        mwse.log("[main.lua] createEffectPriorityTab: No effect priorities loaded.")
        return
    end

    for _, line in ipairs(lines) do
        local block = scrollPane:createBlock({})
        block.flowDirection = "left_to_right"
        block.widthProportional = 1.0
        block.autoHeight = true
        block.borderBottom = 4

        block:createLabel({ text = line })
    end
    mwse.log("[main.lua] createEffectPriorityTab: Completed.")
end

--------------------------------------------------------------------------------
-- Potion List Tab
--------------------------------------------------------------------------------
local function createPotionListTab(parent)
    local list = potionCrafting.calculatePotionList()
    if not list or #list == 0 then
        parent:createLabel({ text = "No potions available." })
        mwse.log("[main.lua] createPotionListTab: No potions available.")
        return
    end

    local scroll = parent:createVerticalScrollPane({ id = "PotionListScrollPane" })
    for _, item in ipairs(list) do
        local block = scroll:createBlock({})
        block.flowDirection = "left_to_right"
        block.widthProportional = 1.0
        block.autoHeight = true
        block.borderBottom = 4

        local labelText = string.format("%s (x%d)", item.name, item.count)
        block:createLabel({ text = labelText })

        local brewBtn = block:createButton({ text = "Brew" })
        brewBtn:register("mouseClick", function()
            potionCrafting.brewSynergyLine(item)
        end)
    end
    mwse.log("[main.lua] createPotionListTab: Completed.")
end

--------------------------------------------------------------------------------
-- Main Window
--------------------------------------------------------------------------------
local function createAlchemyMenu()
    local existing = tes3ui.findMenu(menuId)
    if existing then
        existing:destroy()
    end

    local menu = tes3ui.createMenu({ id = menuId, dragFrame = true, fixedFrame = false, modal = false, loadable = true })
    menu.width = 600
    menu.height = 400
    menu.absolutePosAlignX = 0.1
    menu.absolutePosAlignY = 0.5

    -- Title
    local titleBlock = menu:createBlock({})
    titleBlock.widthProportional = 1.0
    titleBlock.autoHeight = true
    titleBlock.childAlignX = 0.5
    titleBlock:createLabel({ text = modName })

    -- Close Button
    local closeBlock = menu:createBlock({})
    closeBlock.widthProportional = 1.0
    closeBlock.autoHeight = true
    closeBlock.childAlignX = 1.0
    local closeButton = closeBlock:createButton({ text = "Close" })
    closeButton:register("mouseClick", function()
        menu:destroy()
    end)

    -- Tabs
    local tabBar = menu:createBlock({})
    tabBar.widthProportional = 1.0
    tabBar.autoHeight = true
    tabBar.flowDirection = "left_to_right"

    local function updateContent(tabName)
        local contentBlock = menu:findChild("contentBlock")
        if contentBlock then
            contentBlock:destroy()
        end

        contentBlock = menu:createBlock({ id = "contentBlock" })
        contentBlock.widthProportional = 1.0
        contentBlock.heightProportional = 1.0
        contentBlock.autoHeight = true
        contentBlock.borderAllSides = 4
        contentBlock.flowDirection = "top_to_bottom"

        if tabName == "Blacklist" then
            createBlacklistTab(contentBlock)
        elseif tabName == "Effect Priority" then
            createEffectPriorityTab(contentBlock)
        elseif tabName == "Potion List" then
            createPotionListTab(contentBlock)
        end

        menu:updateLayout()
    end

    local tabs = { "Blacklist", "Effect Priority", "Potion List" }
    for _, tabName in ipairs(tabs) do
        local tabButton = tabBar:createButton({ text = tabName })
        tabButton:register("mouseClick", function()
            activeTab = tabName
            updateContent(tabName)
        end)
    end

    updateContent(activeTab)
    mwse.log("[main.lua] createAlchemyMenu: Menu created successfully.")
end

--------------------------------------------------------------------------------
-- Key Event
--------------------------------------------------------------------------------
local function onKeyDown(e)
    if e.keyCode == tes3.scanCode.semicolon then
        local existing = tes3ui.findMenu(menuId)
        if existing then
            existing:destroy()
            potionData.close() -- Close the secondary UI
        else
            if tes3ui.menuMode() then
                createAlchemyMenu()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Monitor All Menus for Closure
--------------------------------------------------------------------------------
local function onAnyMenuActivated(e)
    e.element:registerBefore("destroy", function()
        local optimizerMenu = tes3ui.findMenu(menuId)
        if optimizerMenu then
            optimizerMenu:destroy()
        end
    end)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
local function initialized()
    event.register(tes3.event.keyDown, onKeyDown)
    event.register(tes3.event.loaded, initializeData)
    event.register(tes3.event.uiActivated, onAnyMenuActivated)
    mwse.log("[main.lua] initialized: All events registered.")
end

event.register(tes3.event.initialized, initialized)
