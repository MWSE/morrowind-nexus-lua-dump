local common = require("GPBank.common.common")
local config = require("GPBank.config")

local buyInvestmentMenu = {}

function buyInvestmentMenu.decreaseInvestment(e)
    local name = e.source.name
    local strippedName = string.gsub(name, "%d+", "")
    strippedName = string.gsub(strippedName, "-", "")
    local menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy):findChild("GPBankInput" .. strippedName)
    local text = tonumber(common.getTextAmount(menu))
    local decreasedNumber = text - 1
    menu.text = tostring(decreasedNumber)
end

function buyInvestmentMenu.increaseInvestment(e)
    local name = e.source.name
    local strippedName = string.gsub(name, "%d+", "")
    strippedName = string.gsub(strippedName, "-", "")
    local menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy):findChild("GPBankInput" .. strippedName)
    local text = tonumber(common.getTextAmount(menu))
    local increasedNumber = text + 1
    menu.text = tostring(increasedNumber)
end

function buyInvestmentMenu.confirmInvestmentChange()
    local accountCharged = false
    local accountCharge = 0
    for _, commodity in pairs(common.allCommodities) do
        local max = common.getMaxNumInvestments()
        local name = commodity.name
        local price = string.format("%.0f", commodity.currentPrice)
        local owned = commodity.owned
        local menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy):findChild("GPBankInput" .. name)
        local text = tonumber(common.getTextAmount(menu))
        local copperChange = 0
        -- Selling shares
        if (text < 0) then
            local diff = owned + text
            if (diff < 0) then
                tes3.messageBox({message = "You don't have " .. math.abs(text) .. " shares of " .. name .. ".", showInDialog = false})
            else
                copperChange = math.floor(text * price)
                common.totalCopper = common.totalCopper - copperChange
                common.convertDiff(copperChange)
                common.totalCopperBefore = common.totalCopper
                commodity.owned = commodity.owned + text
                commodity.sellPrice = commodity.currentPrice
                if (commodity.sellPrice > commodity.buyPrice) then
                    local increase = commodity.sellPrice - commodity.buyPrice
                    tes3.mobilePlayer:exerciseSkill(24, (increase / (config.mercXPInvest * 100)))
                end
                tes3.messageBox({message = "You sold " .. math.abs(text) .. " shares of " .. name .. " at " .. price .. " Septims each.", showInDialog = false})
                common.fixCounts()
            end
        -- Buying shares
        elseif (text ~= 0) then
            if (common.totalCopper >=  text * price) then
                copperChange = math.floor(text * price)
                tes3.removeItem({reference = tes3.mobilePlayer, item = "Gold_001", count = copperChange, playSound = false})
                common.totalCopper = common.totalCopper - copperChange
                common.convertDiff(copperChange)
                common.totalCopperBefore = common.totalCopper
                tes3.messageBox({message = "You bought " .. text .. " shares of " .. name .. " at " .. price .. " Septims each.", showInDialog = false})
                common.fixCounts()
                commodity.owned = commodity.owned + text
                commodity.buyPrice = commodity.currentPrice
            elseif ((common.GPBankData.accountBalance + common.totalCopper) >= text * price) then
                copperChange = common.totalCopper
                accountCharge = math.floor(text * price) - common.totalCopper
                common.totalCopper = 0
                common.totalCopperBefore = 0
                accountCharged = true
                common.accountBalance = common.accountBalance - accountCharge
                common.GPBankData.accountBalance = common.GPBankData.accountBalance - accountCharge
                tes3.messageBox({message = "You bought " .. text .. " shares of " .. name .. " at " .. price .. " Septims each.", showInDialog = false})
                commodity.owned = commodity.owned + text
                commodity.buyPrice = commodity.currentPrice
            else
                tes3.messageBox({message = "You don't have that much money and your account balance cannot cover this transaction.", showInDialog = false})
            end
        end
        if accountCharged then
            tes3.messageBox({message = "Your account was charged " .. math.floor(accountCharge) .. " Septims.", showInDialog = false})
            accountCharged = false
        end
        local menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy):findChild("GPBankInput" .. name)
        menu.text = 0
        menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy):findChild("GPBankCommodity" .. name)
        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        menu.text = ("Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned)
    end
    common.GPBankData.allCommodities = common.allCommodities
    local menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy):findChild(common.GUI_ID_InvestmentMenuBuyDescription)
    menu.text = ("Here you can invest or sell your investments in various expidentures, such as generic commodities and established companies. \n \n Septims: " .. common.totalCopper .. "\n Total Shares: ".. common.getTotalOwnedShares() .. "\n Total Value: " .. common.getInvestmentValueTotal() .. "\n Max Shares: " .. common.getMaxNumInvestments())
end

function buyInvestmentMenu.checkInvestmentMax()
    local totalOwned = 0
    local max = common.getMaxNumInvestments()
    for _, commodity in pairs(common.allCommodities) do
        local name = commodity.name
        local price = string.format("%.0f", commodity.currentPrice)
        local owned = commodity.owned
        local menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy):findChild("GPBankInput" .. name)
        local text = tonumber(common.getTextAmount(menu))
        totalOwned = totalOwned + owned + text
    end
    if (totalOwned > max) then
        tes3.messageBox({message = "You aren't trusted with that many shares.", showInDialog = false})
    else
        buyInvestmentMenu.confirmInvestmentChange()
    end
end

function buyInvestmentMenu.destroyBuyInvestmentMenu()
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    bankMenu.visible = true
	local menu = tes3ui.findMenu(common.GUI_ID_InvestmentMenuBuy)
	menu:destroy()
end

function buyInvestmentMenu.createBuyInvestmentMenu(e)
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    local npc = tes3ui.findMenu(common.GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
    bankMenu.visible = false
	local menu = tes3ui.createMenu({id = common.GUI_ID_InvestmentMenuBuy, dragFrame = false, fixedFrame = true})
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"

	local label = menu:createLabel({text = "Imperial Bank of Cyrodiil \n"})
	label.color = {0.870, 0.659, 0.0783}
	label.widthProportional = 1
    label.wrapText = true
    label.justifyText = "center"

    local description = menu:createLabel({id = common.GUI_ID_InvestmentMenuBuyDescription, text = "Here you can invest or sell your investments in various expidentures, such as generic commodities and established companies. \n \n Septims: " .. common.totalCopper .. "\n Total Shares: ".. common.getTotalOwnedShares() .. "\n Total Value: " .. common.getInvestmentValueTotal() .. "\n Max Shares: " .. common.getMaxNumInvestments()})
    description.color = {0.875, 0.788, 0.624}
    description.widthProportional = 1
    description.wrapText = 1
    description.justifyText = "center"
    description.borderAllSides = 10

    local investmentChange = common.getTotalInvestmentChange()
    local changeLabel = menu:createLabel({text = "Change: " .. string.format("%.0f", investmentChange)})
    if (investmentChange > 0) then
        changeLabel.color = {0.103, 0.670, 0.0938}
    elseif (investmentChange < 0) then
        changeLabel.color = {0.610, 0.0122, 0.0122}
    else
        changeLabel.color = {0.875, 0.788, 0.624}
    end
    changeLabel.widthProportional = 1
    changeLabel.wrapText = 1
    changeLabel.justifyText = "center"
    changeLabel.borderAllSides = 10

	local commoditiesBlock = menu:createBlock()
	commoditiesBlock.autoHeight = true
    commoditiesBlock.autoWidth = true
    commoditiesBlock.wrapText = true
    commoditiesBlock.childAlignX = 0.5
    commoditiesBlock.justifyText = "center"
    commoditiesBlock.flowDirection = "left_to_right"
	commoditiesBlock.borderAllSides = 10

    local commoditiesBlock1 = commoditiesBlock:createBlock()
    commoditiesBlock1.autoWidth = true
    commoditiesBlock1.autoHeight = true
    commoditiesBlock1.flowDirection = "top_to_bottom"
    commoditiesBlock1.wrapText = true
    commoditiesBlock1.childAlignX = 0.5
    commoditiesBlock1.justifyText = "center"
    commoditiesBlock1.borderAllSides = 10

    common.updateCommodityLists()
    for _, commodity in pairs(common.commodities1) do
        local commodityLabel = commoditiesBlock1:createLabel({text = "\n" .. commodity.name})
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.870, 0.659, 0.0783}

        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        commodityLabel = commoditiesBlock1:createLabel({id = "GPBankCommodity" .. commodity.name, text = "Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned})
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.875, 0.788, 0.624}

        commodityLabel = commoditiesBlock1:createLabel({text = "Change: " .. string.format("%.0f", commodity.change)})
        if (commodity.change > 0) then
            commodityLabel.color = {0.103, 0.670, 0.0938}
        elseif (commodity.change < 0) then
            commodityLabel.color = {0.610, 0.0122, 0.0122}
        else
            commodityLabel.color = {0.875, 0.788, 0.624}
        end
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3

        local commoditiesTradeBlock = commoditiesBlock1:createBlock()
        commoditiesTradeBlock.autoWidth = true
        commoditiesTradeBlock.autoHeight = true
        commoditiesTradeBlock.flowDirection = "left_to_right"
        commoditiesTradeBlock.wrapText = true
        commoditiesTradeBlock.childAlignX = 0.5
        commoditiesTradeBlock.justifyText = "center"
        commoditiesTradeBlock.borderAllSides = 1

        local minusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuDecreaseButton .. commodity.name, text = "-"})
        minusButton:register("mouseClick", buyInvestmentMenu.decreaseInvestment)

        local commoditiesTextInput = commoditiesTradeBlock:createTextInput({id = "GPBankInput" .. commodity.name, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        commoditiesTextInput.autoHeight = true
        commoditiesTextInput.autoWidth = true
        commoditiesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuIncreaseButton .. commodity.name, text = "+"})
        plusButton:register("mouseClick", buyInvestmentMenu.increaseInvestment)
    end

    local commoditiesBlock2 = commoditiesBlock:createBlock()
    commoditiesBlock2.autoWidth = true
    commoditiesBlock2.autoHeight = true
    commoditiesBlock2.flowDirection = "top_to_bottom"
    commoditiesBlock2.wrapText = true
    commoditiesBlock2.childAlignX = 0.5
    commoditiesBlock2.justifyText = "center"
    commoditiesBlock2.borderAllSides = 10

    for _, commodity in pairs(common.commodities2) do
        local change = string.format("%.0f", commodity.change)
        local commodityLabel = commoditiesBlock2:createLabel({text = "\n" .. commodity.name})
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.870, 0.659, 0.0783}

        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        commodityLabel = commoditiesBlock2:createLabel({id = "GPBankCommodity" .. commodity.name, text = "Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned})
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.875, 0.788, 0.624}

        commodityLabel = commoditiesBlock2:createLabel({text = "Change: " .. string.format("%.0f", commodity.change)})
        if (commodity.change > 0) then
            commodityLabel.color = {0.103, 0.670, 0.0938}
        elseif (commodity.change < 0) then
            commodityLabel.color = {0.610, 0.0122, 0.0122}
        else
            commodityLabel.color = {0.875, 0.788, 0.624}
        end
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3

        local commoditiesTradeBlock = commoditiesBlock2:createBlock()
        commoditiesTradeBlock.autoWidth = true
        commoditiesTradeBlock.autoHeight = true
        commoditiesTradeBlock.flowDirection = "left_to_right"
        commoditiesTradeBlock.wrapText = true
        commoditiesTradeBlock.childAlignX = 0.5
        commoditiesTradeBlock.justifyText = "center"
        commoditiesTradeBlock.borderAllSides = 1

        local minusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuDecreaseButton .. commodity.name, text = "-"})
        minusButton:register("mouseClick", buyInvestmentMenu.decreaseInvestment)

        local commoditiesTextInput = commoditiesTradeBlock:createTextInput({id = "GPBankInput" .. commodity.name, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        commoditiesTextInput.autoHeight = true
        commoditiesTextInput.autoWidth = true
        commoditiesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuIncreaseButton .. commodity.name, text = "+"})
        plusButton:register("mouseClick", buyInvestmentMenu.increaseInvestment)
    end

    local commoditiesBlock3 = commoditiesBlock:createBlock()
    commoditiesBlock3.autoWidth = true
    commoditiesBlock3.autoHeight = true
    commoditiesBlock3.flowDirection = "top_to_bottom"
    commoditiesBlock3.wrapText = true
    commoditiesBlock3.childAlignX = 0.5
    commoditiesBlock3.justifyText = "center"
    commoditiesBlock3.borderAllSides = 10

    for _, commodity in pairs(common.commodities3) do
        local change = string.format("%.0f", commodity.currentPrice - commodity.lastPrice)
        local commodityLabel = commoditiesBlock3:createLabel({text = "\n" .. commodity.name})
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.870, 0.659, 0.0783}

        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        commodityLabel = commoditiesBlock3:createLabel({id = "GPBankCommodity" .. commodity.name, text = "Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned})
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.875, 0.788, 0.624}

        commodityLabel = commoditiesBlock3:createLabel({text = "Change: " .. string.format("%.0f", commodity.change)})
        if (commodity.change > 0) then
            commodityLabel.color = {0.103, 0.670, 0.0938}
        elseif (commodity.change < 0) then
            commodityLabel.color = {0.610, 0.0122, 0.0122}
        else
            commodityLabel.color = {0.875, 0.788, 0.624}
        end
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3

        local commoditiesTradeBlock = commoditiesBlock3:createBlock()
        commoditiesTradeBlock.autoWidth = true
        commoditiesTradeBlock.autoHeight = true
        commoditiesTradeBlock.flowDirection = "left_to_right"
        commoditiesTradeBlock.wrapText = true
        commoditiesTradeBlock.childAlignX = 0.5
        commoditiesTradeBlock.justifyText = "center"
        commoditiesTradeBlock.borderAllSides = 1

        local minusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuDecreaseButton .. commodity.name, text = "-"})
        minusButton:register("mouseClick", buyInvestmentMenu.decreaseInvestment)

        local commoditiesTextInput = commoditiesTradeBlock:createTextInput({id = "GPBankInput" .. commodity.name, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        commoditiesTextInput.autoHeight = true
        commoditiesTextInput.autoWidth = true
        commoditiesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuIncreaseButton .. commodity.name, text = "+"})
        plusButton:register("mouseClick", buyInvestmentMenu.increaseInvestment)
    end

    local commoditiesBlock4 = commoditiesBlock:createBlock()
    commoditiesBlock4.autoWidth = true
    commoditiesBlock4.autoHeight = true
    commoditiesBlock4.flowDirection = "top_to_bottom"
    commoditiesBlock4.wrapText = true
    commoditiesBlock4.childAlignX = 0.5
    commoditiesBlock4.justifyText = "center"
    commoditiesBlock4.borderAllSides = 10

    for _, commodity in pairs(common.commodities4) do
        local change = string.format("%.0f", commodity.currentPrice - commodity.lastPrice)
        local commodityLabel = commoditiesBlock4:createLabel({text = "\n" .. commodity.name})
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.870, 0.659, 0.0783}

        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        commodityLabel = commoditiesBlock4:createLabel({id = "GPBankCommodity" .. commodity.name, text = "Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned})
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.875, 0.788, 0.624}

        commodityLabel = commoditiesBlock4:createLabel({text = "Change: " .. string.format("%.0f", commodity.change)})
        if (commodity.change > 0) then
            commodityLabel.color = {0.103, 0.670, 0.0938}
        elseif (commodity.change < 0) then
            commodityLabel.color = {0.610, 0.0122, 0.0122}
        else
            commodityLabel.color = {0.875, 0.788, 0.624}
        end
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3

        local commoditiesTradeBlock = commoditiesBlock4:createBlock()
        commoditiesTradeBlock.autoWidth = true
        commoditiesTradeBlock.autoHeight = true
        commoditiesTradeBlock.flowDirection = "left_to_right"
        commoditiesTradeBlock.wrapText = true
        commoditiesTradeBlock.childAlignX = 0.5
        commoditiesTradeBlock.justifyText = "center"
        commoditiesTradeBlock.borderAllSides = 1

        local minusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuDecreaseButton .. commodity.name, text = "-"})
        minusButton:register("mouseClick", buyInvestmentMenu.decreaseInvestment)

        local commoditiesTextInput = commoditiesTradeBlock:createTextInput({id = "GPBankInput" .. commodity.name, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        commoditiesTextInput.autoHeight = true
        commoditiesTextInput.autoWidth = true
        commoditiesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuIncreaseButton .. commodity.name, text = "+"})
        plusButton:register("mouseClick", buyInvestmentMenu.increaseInvestment)
    end

    local commoditiesBlock5 = commoditiesBlock:createBlock()
    commoditiesBlock5.autoWidth = true
    commoditiesBlock5.autoHeight = true
    commoditiesBlock5.flowDirection = "top_to_bottom"
    commoditiesBlock5.wrapText = true
    commoditiesBlock5.childAlignX = 0.5
    commoditiesBlock5.justifyText = "center"
    commoditiesBlock5.borderAllSides = 10

    for _, commodity in pairs(common.commodities5) do
        local change = string.format("%.0f", commodity.currentPrice - commodity.lastPrice)
        local commodityLabel = commoditiesBlock5:createLabel({text = "\n" .. commodity.name})
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.870, 0.659, 0.0783}

        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        commodityLabel = commoditiesBlock5:createLabel({id = "GPBankCommodity" .. commodity.name, text = "Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned})
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.875, 0.788, 0.624}

        commodityLabel = commoditiesBlock5:createLabel({text = "Change: " .. string.format("%.0f", commodity.change)})
        if (commodity.change > 0) then
            commodityLabel.color = {0.103, 0.670, 0.0938}
        elseif (commodity.change < 0) then
            commodityLabel.color = {0.610, 0.0122, 0.0122}
        else
            commodityLabel.color = {0.875, 0.788, 0.624}
        end
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3

        local commoditiesTradeBlock = commoditiesBlock5:createBlock()
        commoditiesTradeBlock.autoWidth = true
        commoditiesTradeBlock.autoHeight = true
        commoditiesTradeBlock.flowDirection = "left_to_right"
        commoditiesTradeBlock.wrapText = true
        commoditiesTradeBlock.childAlignX = 0.5
        commoditiesTradeBlock.justifyText = "center"
        commoditiesTradeBlock.borderAllSides = 1

        local minusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuDecreaseButton .. commodity.name, text = "-"})
        minusButton:register("mouseClick", buyInvestmentMenu.decreaseInvestment)

        local commoditiesTextInput = commoditiesTradeBlock:createTextInput({id = "GPBankInput" .. commodity.name, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        commoditiesTextInput.autoHeight = true
        commoditiesTextInput.autoWidth = true
        commoditiesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuIncreaseButton .. commodity.name, text = "+"})
        plusButton:register("mouseClick", buyInvestmentMenu.increaseInvestment)
    end

    local commoditiesBlock6 = commoditiesBlock:createBlock()
    commoditiesBlock6.autoWidth = true
    commoditiesBlock6.autoHeight = true
    commoditiesBlock6.flowDirection = "top_to_bottom"
    commoditiesBlock6.wrapText = true
    commoditiesBlock6.childAlignX = 0.5
    commoditiesBlock6.justifyText = "center"
    commoditiesBlock6.borderAllSides = 10

    for _, commodity in pairs(common.commodities6) do
        local change = string.format("%.0f", commodity.currentPrice - commodity.lastPrice)
        local commodityLabel = commoditiesBlock6:createLabel({text = "\n" .. commodity.name})
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.870, 0.659, 0.0783}

        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        commodityLabel = commoditiesBlock6:createLabel({id = "GPBankCommodity" .. commodity.name, text = "Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned})
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.875, 0.788, 0.624}

        commodityLabel = commoditiesBlock6:createLabel({text = "Change: " .. string.format("%.0f", commodity.change)})
        if (commodity.change > 0) then
            commodityLabel.color = {0.103, 0.670, 0.0938}
        elseif (commodity.change < 0) then
            commodityLabel.color = {0.610, 0.0122, 0.0122}
        else
            commodityLabel.color = {0.875, 0.788, 0.624}
        end
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3

        local commoditiesTradeBlock = commoditiesBlock6:createBlock()
        commoditiesTradeBlock.autoWidth = true
        commoditiesTradeBlock.autoHeight = true
        commoditiesTradeBlock.flowDirection = "left_to_right"
        commoditiesTradeBlock.wrapText = true
        commoditiesTradeBlock.childAlignX = 0.5
        commoditiesTradeBlock.justifyText = "center"
        commoditiesTradeBlock.borderAllSides = 1

        local minusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuDecreaseButton .. commodity.name, text = "-"})
        minusButton:register("mouseClick", buyInvestmentMenu.decreaseInvestment)

        local commoditiesTextInput = commoditiesTradeBlock:createTextInput({id = "GPBankInput" .. commodity.name, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        commoditiesTextInput.autoHeight = true
        commoditiesTextInput.autoWidth = true
        commoditiesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuIncreaseButton .. commodity.name, text = "+"})
        plusButton:register("mouseClick", buyInvestmentMenu.increaseInvestment)
    end

    local commoditiesBlock7 = commoditiesBlock:createBlock()
    commoditiesBlock7.autoWidth = true
    commoditiesBlock7.autoHeight = true
    commoditiesBlock7.flowDirection = "top_to_bottom"
    commoditiesBlock7.wrapText = true
    commoditiesBlock7.childAlignX = 0.5
    commoditiesBlock7.justifyText = "center"
    commoditiesBlock7.borderAllSides = 10

    for _, commodity in pairs(common.commodities7) do
        local change = string.format("%.0f", commodity.currentPrice - commodity.lastPrice)
        local commodityLabel = commoditiesBlock7:createLabel({text = "\n" .. commodity.name})
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.870, 0.659, 0.0783}

        local formattedPrice = string.format("%.0f", commodity.currentPrice)
        commodityLabel = commoditiesBlock7:createLabel({id = "GPBankCommodity" .. commodity.name, text = "Volatility: " .. commodity.volatility .. "\n Price: " .. formattedPrice .. "\n Owned: " .. commodity.owned})
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3
        commodityLabel.color = {0.875, 0.788, 0.624}

        commodityLabel = commoditiesBlock7:createLabel({text = "Change: " .. string.format("%.0f", commodity.change)})
        if (commodity.change > 0) then
            commodityLabel.color = {0.103, 0.670, 0.0938}
        elseif (commodity.change < 0) then
            commodityLabel.color = {0.610, 0.0122, 0.0122}
        else
            commodityLabel.color = {0.875, 0.788, 0.624}
        end
        commodityLabel.justifyText = "center"
        commodityLabel.wrapText = true
        commodityLabel.autoWidth = true
        commodityLabel.autoHeight = true
        commodityLabel.borderLeft = 5
        commodityLabel.borderRight = 3

        local commoditiesTradeBlock = commoditiesBlock7:createBlock()
        commoditiesTradeBlock.autoWidth = true
        commoditiesTradeBlock.autoHeight = true
        commoditiesTradeBlock.flowDirection = "left_to_right"
        commoditiesTradeBlock.wrapText = true
        commoditiesTradeBlock.childAlignX = 0.5
        commoditiesTradeBlock.justifyText = "center"
        commoditiesTradeBlock.borderAllSides = 1

        local minusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuDecreaseButton .. commodity.name, text = "-"})
        minusButton:register("mouseClick", buyInvestmentMenu.decreaseInvestment)

        local commoditiesTextInput = commoditiesTradeBlock:createTextInput({id = "GPBankInput" .. commodity.name, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        commoditiesTextInput.autoHeight = true
        commoditiesTextInput.autoWidth = true
        commoditiesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = commoditiesTradeBlock:createButton({id = common.GUI_ID_InvestmentMenuIncreaseButton .. commodity.name, text = "+"})
        plusButton:register("mouseClick", buyInvestmentMenu.increaseInvestment)
    end

    -- BUTTONS

	local block = menu:createBlock()
	block.autoHeight = true
    block.widthProportional = 1
    block.wrapText = true
    block.childAlignX = 0.5
    block.flowDirection = "left_to_right"
	block.borderAllSides = 10

	local button = block:createButton({text = "Confirm"})
	button:register("mouseClick", buyInvestmentMenu.checkInvestmentMax)

	local cancelButton = block:createButton({text = "Cancel"})
	cancelButton:register("mouseClick", buyInvestmentMenu.destroyBuyInvestmentMenu)
end

return buyInvestmentMenu