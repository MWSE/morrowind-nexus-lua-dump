-- DEBUG: Requires restart if changed
local DEBUG = false
local disableHighlights = true
local highlightList = {}

-- Screen Resolution
local viewportWidth, viewportHeight = tes3.getViewportSize() -- TODO Refactor and hardcode Roulette menu size
if(viewportHeight < 1920) then
    viewportWidth = 1920
    viewportHeight = 1080
end
local minWidth = viewportWidth * 0.75 -- 1440
local minHeight = viewportHeight * 0.75 -- 810

-- Cursor Coords
local cursorX = (minWidth)/2  -- 720: -left +right
local cursorY = (minHeight)/2 -- 405: +up -down

-- Menu IDs
local menus = {
    rouletteMenuID = tes3ui.registerID("RouletteMenu"),
    blackjackMenuID = tes3ui.registerID("BlackjackMenu"),
    solitaireMenuID = tes3ui.registerID("SolitaireMenu"),
    greedMenuID = tes3ui.registerID("GreedMenu"),
    lebronMenuID = tes3ui.registerID("LebronMenu")
}

-- Bet Variables
local betTotal = 0 -- amount bet
local betWins = 0 -- amount won

-- Clears the current menu
local function clearGamblingMenu()
    for _,m in pairs(menus) do
        local menu = tes3ui.findMenu(m)
        if menu then
            menu:destroy()
        end
    end
    betTotal = 0
end

-- UTIL: Checks if table contains element
-- Copied from Tamriel Data common.lua
local function tableContains(table, element)
    for _,v in pairs(table) do
        if v == element then
            return true
        end
    end
    return false
end

-- DEBUG: Force-close the menu
-- mostly for livecoding as it tends to get stuck after a few refreshes
local function panicButton(e)
    if(e.keyCode == tes3.scanCode["l"]) then
        for _,m in pairs(menus) do
            local menu = tes3ui.findMenu(m)
            if menu and menu == tes3ui.getMenuOnTop() then
                clearGamblingMenu()
                tes3ui.leaveMenuMode()
                return
            end
        end
    end
end

-- DEBUG: Print resolution on keybind
local function resolutionButton(e)
    if(e.keyCode == tes3.scanCode["r"]) then
        local menu = tes3ui.findMenu(menus.rouletteMenuID)
        if(menu ~= tes3ui.getMenuOnTop()) then return end
        tes3.messageBox("w %d h %d minW %d minH %d", viewportWidth, viewportHeight, minWidth, minHeight)
    end
end

-- DEBUG: Prints cursor coordinates on keybind
local function coordButton(e)
    if(e.keyCode == tes3.scanCode["k"]) then
        local menu = tes3ui.findMenu(menus.rouletteMenuID)
        if(menu ~= tes3ui.getMenuOnTop()) then return end
        -- Get the current cursor position
        local cursor = tes3.getCursorPosition()
        local mouseX = cursor.x
        local mouseY = cursor.y
        tes3.messageBox("Cursor %f %f", mouseX, mouseY)
    end
end

-- DEBUG: Toggle green area highlights on/off
local function toggleHighlightsButton(e)
    if(e.keyCode == tes3.scanCode["j"]) then
        local menu = tes3ui.findMenu(menus.rouletteMenuID)
        if(menu == nil) then return end
        if(menu ~= tes3ui.getMenuOnTop()) then return end
        for _, child in ipairs(highlightList) do
            if(disableHighlights) then
                child.visible = false
            else
                child.visible = true
            end
        end
        if(disableHighlights) then
            tes3.messageBox("Disabled Highlights")
            disableHighlights = false
        else
            tes3.messageBox("Enabled Highlights")
            disableHighlights = true
        end
    end
end

-- DEBUG: Create a green highlight overlay for each betting area
local function createBetHighlights(parentBlock, betAreas)
    for _, area in ipairs(betAreas) do
        local highlightBlock = parentBlock:createBlock()
        if(DEBUG) then
            highlightBlock = parentBlock:createRect({color = {0, 1, 0, 0.5}})
        end
        highlightBlock.width = area.bounds.width
        highlightBlock.height = area.bounds.height
        highlightBlock.ignoreLayoutX = true
        highlightBlock.ignoreLayoutY = true
        highlightBlock.positionX = area.bounds.x - highlightBlock.width/2
        highlightBlock.positionY = area.bounds.y + highlightBlock.height/2
        table.insert(highlightList, highlightBlock)
    end
end

-- Check if mouse is over a bet area and updates the label
local function updateBetLabel(label, betArea, label2, payoutLabel)
    -- Get the current cursor position
    local cursor = tes3.getCursorPosition()
    local mouseX = cursor.x
    local mouseY = cursor.y

    for _, area in ipairs(betArea) do
        local x, y, w, h = area.bounds.x-cursorX, area.bounds.y+cursorY+2, area.bounds.width, area.bounds.height
        if mouseX >= x - w/2 and mouseX <= x + w/2 and mouseY >= y - h/2 and mouseY <= y + h/2 then -- >= 173 - 75/2 -- -123 - 50/2
            ------------DEBUG-----------
            if(DEBUG) then
                label2.text = "IN AREA"
            end
            ----------------------------
            label.text = "Selected Square: " .. area.name
            payoutLabel.text = "Payout: x" .. tostring(area.payout)
            break
        else
            ------------DEBUG-----------
            if(DEBUG) then
                label2.text = "area"
            end
            ----------------------------
            label.text = "Selected Square: None"
            payoutLabel.text = "Payout: x0"
        end
    end
end

-- Populates bet areas with chip icons
local function createAreaChips(betArea)
    for _, area in ipairs(betArea) do
        area.chip.ignoreLayoutX = true
        area.chip.ignoreLayoutY = true
        area.chip.positionX = area.bounds.x - 16
        area.chip.positionY = area.bounds.y + 16
        area.chip.visible = false
    end
end

-- Updates bet total
local function updateBetTotal(betArea, tokenLabel, betSlider)
    betTotal = 0
    for _, area in ipairs(betArea) do
        betTotal = betTotal + area.bet
    end
    tokenLabel.text = string.format("Bet Amount: %d -- Bet Total: %d", betSlider.widget.current+1, betTotal)
end

-- Skeleton for a generic bet menu with a slider and confirm/cancel buttons
local function createGenericMenu(id, betMax, betJump, globMoney, globBet)
    -- Clear existing menu
    clearGamblingMenu()

    -- Create the menu
    local menu = tes3ui.createMenu({ id = id, fixedFrame = true })
    menu.width = 200
    menu.height = 150
    menu.minWidth = 200
    menu.minHeight = 150
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.5
    menu.flowDirection = "top_to_bottom"

    -- Label for Selected Bet
    local labelBlock = menu:createBlock({})
    labelBlock.widthProportional = 1.0
    labelBlock.autoHeight = true
    labelBlock.childAlignX = 0.5
    local tokenLabel = labelBlock:createLabel({ text = "Bet Amount: 1" })

    -- Slider for Bet Amount
    local sliderBlock = menu:createBlock({})
    sliderBlock.widthProportional = 1.0
    sliderBlock.autoHeight = true
    sliderBlock.childAlignX = 0.5
    local betSlider = sliderBlock:createSlider({ current = 0, max = betMax, step = 1, jump = betJump })
    betSlider.width = menu.width * 0.75

    -- Update Bet Amount
    betSlider:register("PartScrollBar_changed", function()
        betTotal = betSlider.widget.current+1
        tokenLabel.text = string.format("Bet Amount: %d", betTotal)
    end)

    -- Buttons
    local buttonBlock = menu:createBlock({})
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.childAlignX = 0.5
    local confirmButton = buttonBlock:createButton({ text = "Confirm Bet" })
    local cancelButton = buttonBlock:createButton({ text = "Cancel" })

    -- Confirm Button Logic
    confirmButton:register("mouseClick", function()
        if betTotal > 0 then
            local playerGold = tes3.getItemCount({ reference = tes3.player, item = "gold_001" })
            if playerGold >= betTotal then
                tes3.removeItem({ reference = tes3.player, item = "gold_001", count = betTotal })
                tes3.setGlobal(globMoney, betTotal)
                tes3.setGlobal(globBet, 1)

                clearGamblingMenu()
                tes3ui.leaveMenuMode()
            else
                tes3.messageBox("You do not have enough gold to make a bet of %d. You have %d gold.", betTotal, playerGold)
            end
        else
            tes3.messageBox("You have not placed any bets on the table.")
        end
    end)

    -- Cancel Button Logic
    cancelButton:register("mouseClick", function()
        clearGamblingMenu()
        tes3ui.leaveMenuMode()
    end)

    -- Enter menu mode
    tes3ui.enterMenuMode(id)
end

-- Create the Roulette Menu
local function createRouletteMenu()
    -- Clear existing menu
    clearGamblingMenu()

    -- Create the menu
    local menu = tes3ui.createMenu({ id = menus.rouletteMenuID, fixedFrame = true })
    menu.width = viewportWidth
    menu.height = viewportHeight
    menu.minWidth = minWidth
    menu.minHeight = minHeight
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.5

    -- Box with UI elements 
    local menuBox = menu:createBlock({})
    menuBox.width = viewportWidth
    menuBox.height = viewportHeight
    menuBox.minWidth = minWidth
    menuBox.minHeight = minHeight
    menuBox.absolutePosAlignX = 0.5
    menuBox.absolutePosAlignY = 0.5
    menuBox.flowDirection = "top_to_bottom"

    -- Background
    local backgroundBlock = menuBox:createBlock({})
    backgroundBlock.widthProportional = 1.0
    backgroundBlock.heightProportional = 0.7
    backgroundBlock.childAlignX = 0.5 -- absolute align doesn't work??
    backgroundBlock:createImage({ path = "textures/cz/casino/roulette_menu.dds" })

    -- Label for Selected Bet
    local labelBlock = menuBox:createBlock({})
    labelBlock.widthProportional = 1.0
    labelBlock.autoHeight = true
    labelBlock.childAlignX = 0.5
    labelBlock.flowDirection = tes3.flowDirection.topToBottom
    local betLabel = labelBlock:createLabel({ text = "Selected Square: None" })
    local payoutLabel = labelBlock:createLabel({ text = "Payout: x0" })
    local tokenLabel = labelBlock:createLabel({ text = "Bet Amount: 1 -- Bet Total: 0" })
    ------------DEBUG-----------
    local coordLabel
    if(DEBUG) then coordLabel = labelBlock:createLabel({ text = "area" }) end
    ----------------------------

    -- Slider for Bet Amount
    local sliderBlock = menuBox:createBlock({})
    sliderBlock.widthProportional = 1.0
    sliderBlock.autoHeight = true
    sliderBlock.childAlignX = 0.5
    local betSlider = sliderBlock:createSlider({ current = 0, max = 299, step = 1, jump = 10 })
    betSlider.width = minWidth * 0.25

    -- Update Bet Amount
    betSlider:register("PartScrollBar_changed", function()
        tokenLabel.text = string.format("Bet Amount: %d -- Bet Total: %d", betSlider.widget.current+1, betTotal)
    end)

    -- Buttons
    local buttonBlock = menuBox:createBlock({})
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.childAlignX = 0.5
    local confirmButton = buttonBlock:createButton({ text = "Confirm Bet" })
    local cancelButton = buttonBlock:createButton({ text = "Cancel" })

    -- Areas for Bets
    local betAreas = {
        { name =  "0", bounds = { x = cursorX-123+8,  y = -cursorY+173+72, width = 50, height = 75 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 1
        { name = "00", bounds = { x = cursorX-123+8,  y = -cursorY+272+64, width = 50, height = 75 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 2
        { name =  "1", bounds = { x =  cursorX-68,    y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 3
        { name =  "2", bounds = { x =  cursorX-68,    y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 4
        { name =  "3", bounds = { x =  cursorX-68,    y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 5
        { name =  "4", bounds = { x =  cursorX-24,    y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 6
        { name =  "5", bounds = { x =  cursorX-24,    y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 7
        { name =  "6", bounds = { x =  cursorX-24,    y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 8
        { name =  "7", bounds = { x =  cursorX+20,    y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 9
        { name =  "8", bounds = { x =  cursorX+20,    y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 10
        { name =  "9", bounds = { x =  cursorX+20,    y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 11
        { name = "10", bounds = { x =  cursorX+65-2,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 12
        { name = "11", bounds = { x =  cursorX+65-2,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 13
        { name = "12", bounds = { x =  cursorX+65-2,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 14
        { name = "13", bounds = { x = cursorX+110-3,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 15
        { name = "14", bounds = { x = cursorX+110-3,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 16
        { name = "15", bounds = { x = cursorX+110-3,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 17
        { name = "16", bounds = { x = cursorX+155-4,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 18
        { name = "17", bounds = { x = cursorX+155-4,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 19
        { name = "18", bounds = { x = cursorX+155-4,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 20
        { name = "19", bounds = { x = cursorX+200-5,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 21
        { name = "20", bounds = { x = cursorX+200-5,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 22
        { name = "21", bounds = { x = cursorX+200-5,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 23
        { name = "22", bounds = { x = cursorX+245-6,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 24
        { name = "23", bounds = { x = cursorX+245-6,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 25
        { name = "24", bounds = { x = cursorX+245-6,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 26
        { name = "25", bounds = { x = cursorX+290-7,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 27
        { name = "26", bounds = { x = cursorX+290-7,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 28
        { name = "27", bounds = { x = cursorX+290-7,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 29
        { name = "28", bounds = { x = cursorX+335-8,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 30
        { name = "29", bounds = { x = cursorX+335-8,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 31
        { name = "30", bounds = { x = cursorX+335-8,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 32
        { name = "31", bounds = { x = cursorX+380-9,  y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 33
        { name = "32", bounds = { x = cursorX+380-9,  y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 34
        { name = "33", bounds = { x = cursorX+380-9,  y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 35
        { name = "34", bounds = { x = cursorX+425-10, y = -cursorY+155+80, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 36
        { name = "35", bounds = { x = cursorX+425-10, y = -cursorY+215+75, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 37
        { name = "36", bounds = { x = cursorX+425-10, y = -cursorY+274+72, width = 32, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 35 }, -- 38

        { name = "Row 0-00",    bounds = { x = cursorX-123+8, y = -cursorY+205+85, width = 50, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 39
        { name = "Split 1-2",   bounds = { x = cursorX-68,     y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 40
        { name = "Split 2-3",   bounds = { x = cursorX-68,     y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 41
        { name = "Split 4-5",   bounds = { x = cursorX-24,     y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 42
        { name = "Split 5-6",   bounds = { x = cursorX-24,     y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 43
        { name = "Split 7-8",   bounds = { x = cursorX+20,     y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 44
        { name = "Split 8-9",   bounds = { x = cursorX+20,     y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 45
        { name = "Split 10-11", bounds = { x = cursorX+65-2,   y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 46
        { name = "Split 11-12", bounds = { x = cursorX+65-2,   y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 47
        { name = "Split 13-14", bounds = { x = cursorX+110-3,  y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 48
        { name = "Split 14-15", bounds = { x = cursorX+110-3,  y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 49
        { name = "Split 16-17", bounds = { x = cursorX+155-4,  y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 50
        { name = "Split 17-18", bounds = { x = cursorX+155-4,  y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 51
        { name = "Split 19-20", bounds = { x = cursorX+200-5,  y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 52
        { name = "Split 20-21", bounds = { x = cursorX+200-5,  y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 53
        { name = "Split 22-23", bounds = { x = cursorX+245-6,  y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 54
        { name = "Split 23-24", bounds = { x = cursorX+245-6,  y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 55
        { name = "Split 25-26", bounds = { x = cursorX+290-7,  y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 56
        { name = "Split 26-27", bounds = { x = cursorX+290-7,  y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 57
        { name = "Split 28-29", bounds = { x = cursorX+335-8,  y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 58
        { name = "Split 29-30", bounds = { x = cursorX+335-8,  y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 59
        { name = "Split 31-32", bounds = { x = cursorX+380-9,  y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 60
        { name = "Split 32-33", bounds = { x = cursorX+380-9,  y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 61
        { name = "Split 34-35", bounds = { x = cursorX+425-10, y = -cursorY+176+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 62
        { name = "Split 35-36", bounds = { x = cursorX+425-10, y = -cursorY+233+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 63

        { name = "Split 1-4",   bounds = { x = cursorX-46,    y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 65 -- I messed up, from here it's -1 index
        { name = "Split 2-5",   bounds = { x = cursorX-46,    y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 66
        { name = "Split 3-6",   bounds = { x = cursorX-46,    y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 67
        { name = "Split 4-7",   bounds = { x = cursorX-2,     y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 68
        { name = "Split 5-8",   bounds = { x = cursorX-2,     y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 69
        { name = "Split 6-9",   bounds = { x = cursorX-2,     y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 70
        { name = "Split 7-10",  bounds = { x = cursorX+42,    y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 71
        { name = "Split 8-11",  bounds = { x = cursorX+42,    y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 72
        { name = "Split 9-12",  bounds = { x = cursorX+42,    y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 73
        { name = "Split 10-13", bounds = { x = cursorX+86,    y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 74
        { name = "Split 11-14", bounds = { x = cursorX+86,    y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 75
        { name = "Split 12-15", bounds = { x = cursorX+86,    y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 76
        { name = "Split 13-16", bounds = { x = cursorX+131-1, y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 77
        { name = "Split 14-17", bounds = { x = cursorX+131-1, y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 78
        { name = "Split 15-18", bounds = { x = cursorX+131-1, y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 79
        { name = "Split 16-19", bounds = { x = cursorX+175-2, y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 80
        { name = "Split 17-20", bounds = { x = cursorX+175-2, y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 81
        { name = "Split 18-21", bounds = { x = cursorX+175-2, y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 82
        { name = "Split 19-22", bounds = { x = cursorX+219-2, y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 83
        { name = "Split 20-23", bounds = { x = cursorX+219-2, y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 84
        { name = "Split 21-24", bounds = { x = cursorX+219-2, y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 85
        { name = "Split 22-25", bounds = { x = cursorX+263-2, y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 86
        { name = "Split 23-26", bounds = { x = cursorX+263-2, y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 87
        { name = "Split 24-27", bounds = { x = cursorX+263-2, y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 88
        { name = "Split 25-28", bounds = { x = cursorX+307-2, y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 89
        { name = "Split 26-29", bounds = { x = cursorX+307-2, y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 90
        { name = "Split 27-30", bounds = { x = cursorX+307-2, y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 91
        { name = "Split 28-31", bounds = { x = cursorX+351-2, y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 92
        { name = "Split 29-32", bounds = { x = cursorX+351-2, y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 93
        { name = "Split 30-33", bounds = { x = cursorX+351-2, y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 94
        { name = "Split 31-34", bounds = { x = cursorX+396-2, y = -cursorY+155+80, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 95
        { name = "Split 32-35", bounds = { x = cursorX+396-2, y = -cursorY+215+75, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 96
        { name = "Split 33-36", bounds = { x = cursorX+396-2, y = -cursorY+274+72, width = 6, height = 44 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 17 }, -- 97

        { name = "Street 1-2-3",    bounds = { x = cursorX-68,     y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 98
        { name = "Street 4-5-6",    bounds = { x = cursorX-24,     y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 99
        { name = "Street 7-8-9",    bounds = { x = cursorX+20,     y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 100
        { name = "Street 10-11-12", bounds = { x = cursorX+65-2,   y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 101
        { name = "Street 13-14-15", bounds = { x = cursorX+110-3,  y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 102
        { name = "Street 16-17-18", bounds = { x = cursorX+155-4,  y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 103
        { name = "Street 19-20-21", bounds = { x = cursorX+200-5,  y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 104
        { name = "Street 22-23-24", bounds = { x = cursorX+245-6,  y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 105
        { name = "Street 25-26-27", bounds = { x = cursorX+290-7,  y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 106
        { name = "Street 28-29-30", bounds = { x = cursorX+335-8,  y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 107
        { name = "Street 31-32-33", bounds = { x = cursorX+380-9,  y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 108
        { name = "Street 34-35-36", bounds = { x = cursorX+425-10, y = -cursorY+288+87, width = 32, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 109

        { name = "Basket 1-0-2",  bounds = { x = cursorX-89+1, y = -cursorY+176+87, width = 6, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 110
        { name = "Basket 0-2-00", bounds = { x = cursorX-89+1, y = -cursorY+205+85, width = 6, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 111
        { name = "Basket 2-00-3", bounds = { x = cursorX-89+1, y = -cursorY+233+87, width = 6, height = 6 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 11 }, -- 112

        { name = "Corner 1-2-4-5",       bounds = { x = cursorX+ -46, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 113
        { name = "Corner 2-3-5-6",       bounds = { x = cursorX+ -46, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 114
        { name = "Corner 4-5-7-8",        bounds = { x = cursorX+ -2, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 115
        { name = "Corner 5-6-8-9",        bounds = { x = cursorX+ -2, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 116
        { name = "Corner 7-8-10-11",      bounds = { x = cursorX+ 42, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 117
        { name = "Corner 8-9-11-12",      bounds = { x = cursorX+ 42, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 118
        { name = "Corner 10-11-13-14",    bounds = { x = cursorX+ 86, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 119
        { name = "Corner 11-12-14-15",    bounds = { x = cursorX+ 86, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 120
        { name = "Corner 13-14-16-17", bounds = { x = cursorX+ 131-1, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 121
        { name = "Corner 14-15-17-18", bounds = { x = cursorX+ 131-1, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 122
        { name = "Corner 16-17-19-20", bounds = { x = cursorX+ 175-2, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 123
        { name = "Corner 17-18-20-21", bounds = { x = cursorX+ 175-2, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 124
        { name = "Corner 19-20-22-23", bounds = { x = cursorX+ 219-2, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 125
        { name = "Corner 20-21-23-24", bounds = { x = cursorX+ 219-2, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 126
        { name = "Corner 22-23-25-26", bounds = { x = cursorX+ 263-2, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 127
        { name = "Corner 23-24-26-27", bounds = { x = cursorX+ 263-2, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 128
        { name = "Corner 25-26-28-29", bounds = { x = cursorX+ 307-2, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 129
        { name = "Corner 26-27-29-30", bounds = { x = cursorX+ 307-2, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 130
        { name = "Corner 28-29-31-32", bounds = { x = cursorX+ 351-2, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 131
        { name = "Corner 29-30-32-33", bounds = { x = cursorX+ 351-2, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 132
        { name = "Corner 31-32-34-35", bounds = { x = cursorX+ 396-2, y = -cursorY+176+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 133
        { name = "Corner 32-33-35-36", bounds = { x = cursorX+ 396-2, y = -cursorY+233+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 8 }, -- 134

        { name = "Top Line 0-00-1-2-3", bounds = { x = cursorX-89+1, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 6 }, -- 135

        { name = "Six Line 1 to 6",    bounds = { x = cursorX-46, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 136
        { name = "Six Line 4 to 9",     bounds = { x = cursorX-2, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 137
        { name = "Six Line 7 to 12",      bounds = { x = cursorX+42, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 138
        { name = "Six Line 10 to 15",     bounds = { x = cursorX+86, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 139
        { name = "Six Line 13 to 18",  bounds = { x = cursorX+131-1, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 140
        { name = "Six Line 16 to 21",  bounds = { x = cursorX+175-2, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 141
        { name = "Six Line 19 to 24",  bounds = { x = cursorX+219-2, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 142
        { name = "Six Line 22 to 27",  bounds = { x = cursorX+263-2, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 143
        { name = "Six Line 25 to 30",  bounds = { x = cursorX+307-2, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 144
        { name = "Six Line 28 to 33",  bounds = { x = cursorX+351-2, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 145
        { name = "Six Line 31 to 36",  bounds = { x = cursorX+396-2, y = -cursorY+288+87, width = 10, height = 10 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 5 }, -- 146

        { name = "1st Dozen 1 to 12",  bounds = { x = cursorX+466-8, y = -cursorY+155+80, width = 40, height = 50 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 147
        { name = "2nd Dozen 13 to 24", bounds = { x = cursorX+466-8, y = -cursorY+215+75, width = 40, height = 50 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 148
        { name = "3rd Dozen 25 to 36", bounds = { x = cursorX+466-8, y = -cursorY+274+72, width = 40, height = 50 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 149

        { name = "1st Column 1 to 34",     bounds = { x = cursorX-2, y = -cursorY+178, width = 174, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 150
        { name = "2nd Column 2 to 35", bounds = { x = cursorX+175-2, y = -cursorY+178, width = 174, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 151
        { name = "3rd Column 3 to 36", bounds = { x = cursorX+351-2, y = -cursorY+178, width = 174, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 152

        { name = "1st Half 1 to 18",  bounds = { x = cursorX-46,    y = -cursorY+122, width = 86, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 153
        { name = "2nd Half 19 to 36", bounds = { x = cursorX+396-3, y = -cursorY+122, width = 86, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 2 }, -- 154

        { name = "Red",   bounds = { x = cursorX+131-1, y = -cursorY+122, width = 86, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 1 }, -- 155
        { name = "Black", bounds = { x = cursorX+219-2, y = -cursorY+122, width = 86, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 1 }, -- 156
        { name = "Even",  bounds = { x = cursorX+42,    y = -cursorY+122, width = 86, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 1 }, -- 157
        { name = "Odd",   bounds = { x = cursorX+307-2, y = -cursorY+122, width = 86, height = 56 }, bet = 0, chip = menu:createImage({ path = "textures/cz/casino/roulette_chip.dds" }), payout = 1 }, -- 158
    }

    -- Winning areas for each number
    local betAreaWins = {       -- number     -- split      -- spilt       -- split 2     -- split 2     -- street      -- basket      -- basket      -- basket      -- corner      -- corner      -- corner      -- corner      -- 2xline      -- 2xline      -- dozen       -- column      -- half        -- r/b         -- odd/even
        { name =  "0", wins = { betAreas[1],  betAreas[39],                                                             betAreas[109], betAreas[110],                                                                            betAreas[134],                                                                            betAreas[156] } },
        { name = "00", wins = { betAreas[2],  betAreas[39],                                                             betAreas[110], betAreas[111],                                                                            betAreas[134],                                                                            betAreas[156] } },
        { name =  "1", wins = { betAreas[3],  betAreas[40],                betAreas[64],                 betAreas[97],  betAreas[109],                               betAreas[112],                                              betAreas[134], betAreas[135], betAreas[146], betAreas[149], betAreas[152], betAreas[154], betAreas[157] } },
        { name =  "2", wins = { betAreas[4],  betAreas[40],                betAreas[65],                 betAreas[97],  betAreas[109], betAreas[110], betAreas[111], betAreas[112], betAreas[113],                               betAreas[134], betAreas[135], betAreas[146], betAreas[150], betAreas[152], betAreas[155], betAreas[156] } },
        { name =  "3", wins = { betAreas[5],  betAreas[41],                betAreas[66],                 betAreas[97],  betAreas[111],                               betAreas[113],                                              betAreas[134], betAreas[135], betAreas[146], betAreas[151], betAreas[152], betAreas[154], betAreas[157] } },
        { name =  "4", wins = { betAreas[6],  betAreas[42],                betAreas[64],  betAreas[67],  betAreas[98],                                               betAreas[114],                                              betAreas[135], betAreas[136], betAreas[146], betAreas[149], betAreas[152], betAreas[155], betAreas[156] } },
        { name =  "5", wins = { betAreas[7],  betAreas[42], betAreas[43],  betAreas[65],  betAreas[68],  betAreas[98],                                               betAreas[112], betAreas[113], betAreas[114], betAreas[115], betAreas[135], betAreas[136], betAreas[146], betAreas[150], betAreas[152], betAreas[154], betAreas[157] } },
        { name =  "6", wins = { betAreas[8],  betAreas[43],                betAreas[66],  betAreas[69],  betAreas[98],                                               betAreas[113], betAreas[115],                               betAreas[135], betAreas[136], betAreas[146], betAreas[151], betAreas[152], betAreas[155], betAreas[156] } },
        { name =  "7", wins = { betAreas[9],  betAreas[44],                betAreas[67],  betAreas[70],  betAreas[99],                                               betAreas[114], betAreas[116],                               betAreas[136], betAreas[137], betAreas[146], betAreas[149], betAreas[152], betAreas[154], betAreas[157] } },
        { name =  "8", wins = { betAreas[10], betAreas[44], betAreas[45],  betAreas[68],  betAreas[71],  betAreas[99],                                               betAreas[114], betAreas[115], betAreas[116], betAreas[117], betAreas[136], betAreas[137], betAreas[146], betAreas[150], betAreas[152], betAreas[155], betAreas[156] } },
        { name =  "9", wins = { betAreas[11], betAreas[45],                betAreas[69],  betAreas[72],  betAreas[99],                                               betAreas[115], betAreas[117],                               betAreas[136], betAreas[137], betAreas[146], betAreas[151], betAreas[152], betAreas[154], betAreas[157] } },
        { name = "10", wins = { betAreas[12], betAreas[46],                betAreas[70],  betAreas[73],  betAreas[100],                                              betAreas[116], betAreas[118],                               betAreas[137], betAreas[138], betAreas[146], betAreas[149], betAreas[152], betAreas[155], betAreas[156] } },
        { name = "11", wins = { betAreas[13], betAreas[46], betAreas[47],  betAreas[71],  betAreas[74],  betAreas[100],                                              betAreas[116], betAreas[117], betAreas[118], betAreas[119], betAreas[137], betAreas[138], betAreas[146], betAreas[150], betAreas[152], betAreas[155], betAreas[157] } },
        { name = "12", wins = { betAreas[14], betAreas[47],                betAreas[72],  betAreas[75],  betAreas[100],                                              betAreas[117], betAreas[119],                               betAreas[137], betAreas[138], betAreas[146], betAreas[151], betAreas[152], betAreas[154], betAreas[156] } },
        { name = "13", wins = { betAreas[15], betAreas[48],                betAreas[73],  betAreas[76],  betAreas[101],                                              betAreas[118], betAreas[120],                               betAreas[138], betAreas[139], betAreas[147], betAreas[149], betAreas[152], betAreas[155], betAreas[157] } },
        { name = "14", wins = { betAreas[16], betAreas[48], betAreas[49],  betAreas[74],  betAreas[77],  betAreas[101],                                              betAreas[118], betAreas[119], betAreas[120], betAreas[121], betAreas[138], betAreas[139], betAreas[147], betAreas[150], betAreas[152], betAreas[154], betAreas[156] } },
        { name = "15", wins = { betAreas[17], betAreas[49],                betAreas[75],  betAreas[78],  betAreas[101],                                              betAreas[119], betAreas[121],                               betAreas[138], betAreas[139], betAreas[147], betAreas[151], betAreas[152], betAreas[155], betAreas[157] } },
        { name = "16", wins = { betAreas[18], betAreas[50],                betAreas[76],  betAreas[79],  betAreas[102],                                              betAreas[120], betAreas[122],                               betAreas[139], betAreas[140], betAreas[147], betAreas[149], betAreas[152], betAreas[154], betAreas[156] } },
        { name = "17", wins = { betAreas[19], betAreas[50], betAreas[51],  betAreas[77],  betAreas[80],  betAreas[102],                                              betAreas[120], betAreas[121], betAreas[122], betAreas[123], betAreas[139], betAreas[140], betAreas[147], betAreas[150], betAreas[152], betAreas[155], betAreas[157] } },
        { name = "18", wins = { betAreas[20], betAreas[51],                betAreas[78],  betAreas[81],  betAreas[102],                                              betAreas[121], betAreas[123],                               betAreas[139], betAreas[140], betAreas[147], betAreas[151], betAreas[152], betAreas[154], betAreas[156] } },
        { name = "19", wins = { betAreas[21], betAreas[52],                betAreas[79],  betAreas[82],  betAreas[103],                                              betAreas[122], betAreas[124],                               betAreas[140], betAreas[141], betAreas[147], betAreas[149], betAreas[153], betAreas[154], betAreas[157] } },
        { name = "20", wins = { betAreas[22], betAreas[52], betAreas[53],  betAreas[80],  betAreas[83],  betAreas[103],                                              betAreas[122], betAreas[123], betAreas[124], betAreas[125], betAreas[140], betAreas[141], betAreas[147], betAreas[150], betAreas[153], betAreas[155], betAreas[156] } },
        { name = "21", wins = { betAreas[23], betAreas[53],                betAreas[81],  betAreas[84],  betAreas[103],                                              betAreas[123], betAreas[125],                               betAreas[140], betAreas[141], betAreas[147], betAreas[151], betAreas[153], betAreas[154], betAreas[157] } },
        { name = "22", wins = { betAreas[24], betAreas[54],                betAreas[82],  betAreas[85],  betAreas[104],                                              betAreas[124], betAreas[126],                               betAreas[141], betAreas[142], betAreas[147], betAreas[149], betAreas[153], betAreas[155], betAreas[156] } },
        { name = "23", wins = { betAreas[25], betAreas[54], betAreas[55],  betAreas[83],  betAreas[86],  betAreas[104],                                              betAreas[124], betAreas[125], betAreas[126], betAreas[127], betAreas[141], betAreas[142], betAreas[147], betAreas[150], betAreas[153], betAreas[154], betAreas[157] } },
        { name = "24", wins = { betAreas[26], betAreas[55],                betAreas[84],  betAreas[87],  betAreas[104],                                              betAreas[125], betAreas[127],                               betAreas[141], betAreas[142], betAreas[147], betAreas[151], betAreas[153], betAreas[155], betAreas[156] } },
        { name = "25", wins = { betAreas[26], betAreas[56],                betAreas[85],  betAreas[88],  betAreas[105],                                              betAreas[126], betAreas[128],                               betAreas[142], betAreas[143], betAreas[148], betAreas[149], betAreas[153], betAreas[154], betAreas[157] } },
        { name = "26", wins = { betAreas[28], betAreas[56], betAreas[57],  betAreas[86],  betAreas[89],  betAreas[105],                                              betAreas[126], betAreas[127], betAreas[128], betAreas[129], betAreas[142], betAreas[143], betAreas[148], betAreas[150], betAreas[153], betAreas[155], betAreas[156] } },
        { name = "27", wins = { betAreas[29], betAreas[57],                betAreas[87],  betAreas[90],  betAreas[105],                                              betAreas[127], betAreas[129],                               betAreas[142], betAreas[143], betAreas[148], betAreas[151], betAreas[153], betAreas[154], betAreas[157] } },
        { name = "28", wins = { betAreas[30], betAreas[58],                betAreas[88],  betAreas[91],  betAreas[106],                                              betAreas[127], betAreas[130],                               betAreas[143], betAreas[144], betAreas[148], betAreas[149], betAreas[153], betAreas[155], betAreas[156] } },
        { name = "29", wins = { betAreas[31], betAreas[58], betAreas[59],  betAreas[89],  betAreas[92],  betAreas[106],                                              betAreas[128], betAreas[129], betAreas[130], betAreas[131], betAreas[143], betAreas[144], betAreas[148], betAreas[150], betAreas[153], betAreas[155], betAreas[157] } },
        { name = "30", wins = { betAreas[32], betAreas[59],                betAreas[90],  betAreas[93],  betAreas[106],                                              betAreas[129], betAreas[131],                               betAreas[143], betAreas[144], betAreas[148], betAreas[151], betAreas[153], betAreas[154], betAreas[156] } },
        { name = "31", wins = { betAreas[33], betAreas[60],                betAreas[91],  betAreas[94],  betAreas[107],                                              betAreas[130], betAreas[132],                               betAreas[144], betAreas[145], betAreas[148], betAreas[149], betAreas[153], betAreas[155], betAreas[157] } },
        { name = "32", wins = { betAreas[34], betAreas[60], betAreas[61],  betAreas[92],  betAreas[95],  betAreas[107],                                              betAreas[130], betAreas[131], betAreas[132], betAreas[133], betAreas[144], betAreas[145], betAreas[148], betAreas[150], betAreas[153], betAreas[154], betAreas[156] } },
        { name = "33", wins = { betAreas[35], betAreas[61],                betAreas[93],  betAreas[96],  betAreas[107],                                              betAreas[131], betAreas[133],                               betAreas[144], betAreas[145], betAreas[148], betAreas[151], betAreas[153], betAreas[155], betAreas[157] } },
        { name = "34", wins = { betAreas[36], betAreas[62],                betAreas[94],                 betAreas[108],                                              betAreas[132],                                              betAreas[145],                betAreas[148], betAreas[149], betAreas[153], betAreas[154], betAreas[156] } },
        { name = "35", wins = { betAreas[37], betAreas[62], betAreas[63],  betAreas[95],                 betAreas[108],                                              betAreas[132], betAreas[134],                               betAreas[145],                betAreas[148], betAreas[150], betAreas[153], betAreas[155], betAreas[157] } },
        { name = "36", wins = { betAreas[38], betAreas[63],                betAreas[96],                 betAreas[108],                                              betAreas[133],                                              betAreas[145],                betAreas[148], betAreas[151], betAreas[153], betAreas[154], betAreas[156] } },
    }

    createAreaChips(betAreas)
    updateBetTotal(betAreas, tokenLabel, betSlider) -- initialize + cleanup

    -- Placing bet down
    event.register("mouseButtonDown", function(e)
        if e.button ~= 0 then return end -- lmb

        local menuCheck = tes3ui.findMenu(menus.rouletteMenuID)
        if(menuCheck ~= tes3ui.getMenuOnTop()) then return end

        local selectedSquare = betLabel.text:match("Selected Square: (.+)")
        if selectedSquare and selectedSquare ~= "None" then
            for _, area in ipairs(betAreas) do
                if(area.name == selectedSquare) then
                    if(area.bet > 0) then
                        tes3.messageBox({
                            message = string.format("There is already a bet of %d gold placed here. Do you want to remove it?", area.bet),
                            buttons = { "Yes", "No" },
                            callback = function(f)
                                if f.button == 0 then -- Yes
                                    area.bet = 0
                                    area.chip.visible = false
                                    updateBetTotal(betAreas, tokenLabel, betSlider)
                                    tes3.playSound({
                                        sound = "Item Gold Up"
                                    })
                                end
                            end,
                        })
                    else
                        area.bet = betSlider.widget.current+1
                        area.chip.visible = true
                        updateBetTotal(betAreas, tokenLabel, betSlider)
                        tes3.playSound({
                            sound = "Item Gold Down"
                        })
                    end
                    break
                end
            end
        end
    end)

    -- Create bet highlights
    createBetHighlights(menu, betAreas)

    -- Mouse Hover Logic
    menu:register("mouseOver", function()
        updateBetLabel(betLabel, betAreas, coordLabel, payoutLabel)
    end)

    -- Confirm Button Logic
    confirmButton:register("mouseClick", function()
        if betTotal > 0 then
            local playerGold = tes3.getItemCount({ reference = tes3.player, item = "gold_001" })
            if playerGold >= betTotal then
                tes3.removeItem({ reference = tes3.player, item = "gold_001", count = betTotal })
                local randNum = math.random(0, 37) -- 37 is 00
                local luck = tes3.mobilePlayer.luck.current

                for _, area in ipairs(betAreaWins) do
                    local areaToNum = tonumber(area.name)
                    if((area.name == "00" and randNum == 37) or areaToNum == randNum) then
                        ------------DEBUG-----------
                        if(DEBUG) then tes3.messageBox("kill %d", areaToNum) end
                        ----------------------------
                        for _, win in ipairs(area.wins) do
                            betWins = betWins + win.bet + win.bet * win.payout
                        end
                        tes3.setGlobal("csn_roulette_number", randNum)
                        tes3.setGlobal("csn_roulette_result", betWins)
                        tes3.setGlobal("csn_roulette_bet", 1)
                        break
                    end
                end

                if(betWins == 0) then
                    ------------DEBUG-----------
                    if(DEBUG) then tes3.messageBox("No win") end
                    ----------------------------

                    -- No wins: luck check
                    local rng = math.random(1, 500)
                    if(rng <= luck) then
                        local potentialWins = {} -- list of potential winning numbers

                        for _, area in ipairs(betAreaWins) do       -- basically, check every betAreaWins wins list
                            for __, win in ipairs(area.wins) do
                                if(win.bet > 0) then                -- if it contains a win
                                    if(not tableContains(potentialWins, area)) then
                                        table.insert(potentialWins, area)   -- add the number to the list and check the next
                                        goto continue
                                    end
                                end
                            end
                            ::continue::
                        end

                        local winner = potentialWins[math.random(1, table.size(potentialWins))] -- winning number
                        for _, win in ipairs(winner.wins) do
                            betWins = betWins + win.bet + win.bet * win.payout
                        end
                        if(winner.name == "00") then tes3.setGlobal("csn_roulette_number", 37)
                        else tes3.setGlobal("csn_roulette_number", tonumber(winner.name)) end
                        tes3.setGlobal("csn_roulette_bet", 2)   -- display luck message
                        tes3.setGlobal("csn_roulette_result", betWins)
                        betWins = 0 -- cleanup
                    else
                        tes3.setGlobal("csn_roulette_number", randNum)
                        tes3.setGlobal("csn_roulette_result", 0)
                        tes3.setGlobal("csn_roulette_bet", 1)
                    end
                end

                betWins = 0 -- cleanup
                clearGamblingMenu()
                tes3ui.leaveMenuMode()
            else
                tes3.messageBox("You do not have enough gold to make a bet of %d. You have %d gold.", betTotal, playerGold)
            end
        else
            tes3.messageBox("You have not placed any bets on the table.")
        end
    end)

    -- Cancel Button Logic
    cancelButton:register("mouseClick", function()
        tes3.messageBox({
            message = "Are you sure you want to leave the table?",
            buttons = { "Yes", "No" },
            callback = function(e)
                if e.button == 0 then -- Yes
                    clearGamblingMenu()
                    tes3ui.leaveMenuMode()
                end
            end,
        })
    end)

    -- Enter menu mode
    tes3ui.enterMenuMode(menus.rouletteMenuID)
end

-- Create the Blackjack Menu
local function createBlackjackMenu()
    createGenericMenu(menus.blackjackMenuID, 199, 10, "csn_blackjack_money", "csn_blackjack_bet")
end

-- Create the Solitaire Menu
local function createSolitaireMenu()
    createGenericMenu(menus.solitaireMenuID, 299, 100, "csn_solitaire_money", "csn_solitaire_bet")
end

-- Create the Greed Menu
local function createGreedMenu()
    createGenericMenu(menus.greedMenuID, 199, 10, "csn_greed_money", "csn_greed_bet")
end

-- Create the Thirty-Six Menu
local function createLebronMenu()
    createGenericMenu(menus.lebronMenuID, 199, 10, "csn_lebron_money", "csn_lebron_bet")
end

-- Player Activates Gambling Table
--- @param e activateEventData
local function onActivate(e)
    if e.target.object.id:lower():find("csn_roulette_table", 1, true) then
        e.block = true
        if(tes3.getGlobal("csn_roulette_bet") > 0) then tes3.messageBox("There is already a bet placed on a table.")
        elseif(tes3.getGlobal("csn_casino_banned") > 0) then tes3.messageBox("You have been banned from playing games here.")
        else createRouletteMenu() end
    elseif e.target.object.id:lower() == "csn_blackjack_deck" then
        e.block = true
        if(tes3.getGlobal("csn_blackjack_bet") > 0) then tes3.messageBox("There is already an active game of Iron Crown.")
        elseif(tes3.getGlobal("csn_casino_banned") > 0) then tes3.messageBox("You have been banned from playing games here.")
        else createBlackjackMenu() end
    elseif e.target.object.id:lower() == "csn_solitaire_box" then
        e.block = true
        if(tes3.getGlobal("csn_solitaire_bet") > 0) then tes3.messageBox("There is already an active game of Hortator.")
        elseif(tes3.getGlobal("csn_casino_banned") > 0) then tes3.messageBox("You have been banned from playing games here.")
        else createSolitaireMenu() end
    elseif e.target.object.id:lower() == "csn_greed_cup" then
        e.block = true
        if(tes3.getGlobal("csn_greed_bet") > 0) then tes3.messageBox("There is already an active game of Greed.")
        elseif(tes3.getGlobal("csn_casino_banned") > 0) then tes3.messageBox("You have been banned from playing games here.")
        else createGreedMenu() end
    elseif e.target.object.id:lower() == "csn_lebron_dice" then
        e.block = true
        if(tes3.getGlobal("csn_lebron_bet") > 0) then tes3.messageBox("There is already an active game of Thirty-Six.")
        elseif(tes3.getGlobal("csn_casino_banned") > 0) then tes3.messageBox("You have been banned from playing games here.")
        else createLebronMenu() end
    end
end

-- Give Player Money
local function rewardMoney(e)
    if e.target.object.id:lower() == "csn_roulette_reward" then
        e.block = true
        tes3.addItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_roulette_result"), showMessage = true })
        tes3.setGlobal("csn_roulette_wins", (tes3.getGlobal("csn_roulette_wins") + 1))
    elseif e.target.object.id:lower() == "csn_blackjack_reward" then
        e.block = true
        if tes3.getGlobal("csn_blackjack_dd") == 1 then
            tes3.removeItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_blackjack_money"), showMessage = true })
            tes3.setGlobal("csn_blackjack_waiting", 0)
        else
            tes3.addItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_blackjack_result"), showMessage = true })
            tes3.setGlobal("csn_blackjack_wins", (tes3.getGlobal("csn_blackjack_wins") + 1))
        end
    elseif e.target.object.id:lower() == "csn_solitaire_reward" then
        e.block = true
        tes3.addItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_solitaire_result"), showMessage = true })
        tes3.setGlobal("csn_solitaire_wins", (tes3.getGlobal("csn_solitaire_wins") + 1))
    elseif e.target.object.id:lower() == "csn_greed_reward" then
        e.block = true
        if tes3.getGlobal("csn_greed_turn") == 0 then
            tes3.removeItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_greed_money"), showMessage = true })
            tes3.setGlobal("csn_greed_money", tes3.getGlobal("csn_greed_money") * 2)
        else
            tes3.addItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_greed_result"), showMessage = true })
            tes3.setGlobal("csn_greed_wins", (tes3.getGlobal("csn_greed_wins") + 1))
        end
    elseif e.target.object.id:lower() == "csn_lebron_reward" then
        e.block = true
        if tes3.getGlobal("csn_lebron_turn") == 0 then
            tes3.removeItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_lebron_money"), showMessage = true })
        else
            tes3.addItem({ reference = tes3.player, item = "gold_001", count = tes3.getGlobal("csn_lebron_result"), showMessage = true })
            tes3.setGlobal("csn_lebron_wins", (tes3.getGlobal("csn_lebron_wins") + 1))
        end
    end
end

-- Initialization
local function onInitialized()
    event.register("activate", onActivate)
    event.register("activate", rewardMoney)
    event.register("load", clearGamblingMenu)
    if(DEBUG) then
        event.register("keyDown", panicButton)
        event.register("keyDown", resolutionButton)
        event.register("keyDown", coordButton)
        event.register("keyDown", toggleHighlightsButton)
    end

    mwse.log("[Casino Gambling] initialized")
end
event.register("initialized", onInitialized)