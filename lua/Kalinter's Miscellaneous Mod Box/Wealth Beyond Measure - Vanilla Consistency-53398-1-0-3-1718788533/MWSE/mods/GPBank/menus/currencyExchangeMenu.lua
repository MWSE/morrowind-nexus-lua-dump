local common = require("GPBank.common.common")
local config = require("GPBank.config")

local currencyExchangeMenu = {}

function currencyExchangeMenu.decreaseCurrencyExchange(e)
    local name = e.source.name
    local name = string.gsub(name, "-", "")
    name = string.gsub(name, "^(%d+)", "")
    local menu = tes3ui.findMenu(common.GUI_ID_CurrencyExchangeMenu):findChild("GPExchangeInput" .. name)
    local text = tonumber(common.getTextAmount(menu))
    local increasedNumber = text - 1
    menu.text = tostring(increasedNumber)
end

function currencyExchangeMenu.increaseCurrencyExchange(e)
    local name = e.source.name
    local name = string.gsub(name, "-", "")
    name = string.gsub(name, "^(%d+)", "")
    local menu = tes3ui.findMenu(common.GUI_ID_CurrencyExchangeMenu):findChild("GPExchangeInput" .. name)
    local text = tonumber(common.getTextAmount(menu))
    local increasedNumber = text + 1
    menu.text = tostring(increasedNumber)
end

function currencyExchangeMenu.confirmCurrencyExchangeChange()
    local actualCopper = common.getActualCopper(common.totalCopper)
    for _, bill in pairs(common.currency) do
        local count = 0
        for _, currency in pairs(common.counts) do
            if (currency.id == bill.id) then
                count = currency.count
            end
        end
        local id = bill.id
        local name = bill.name
        local price = bill.value
        local weight = bill.weight
        local menu = tes3ui.findMenu(common.GUI_ID_CurrencyExchangeMenu):findChild("GPExchangeInput" .. id)
        local text = tonumber(common.getTextAmount(menu))
        -- Giving bills
        if (text < 0) then
            local diff = count + text
            if (diff < 0) then
                tes3.messageBox({message = "You don't have " .. math.abs(text) .. " " .. name .. ".", showInDialog = false})
            else
                common.counts[id].count = common.counts[id].count - math.abs(text)
                tes3.messageBox({message = "You exchanged " .. math.abs(text) .. " " .. name .. " for " .. math.abs(price * text) .. " gold Septims.", showInDialog = false})
                actualCopper = actualCopper + math.abs(price * text)
                common.fixCounts()
            end
        -- Getting bills
        elseif (text ~= 0) then
            if (actualCopper >=  text * price) then
                common.counts[id].count = common.counts[id].count + math.abs(text)
                tes3.messageBox({message = "You exchanged " .. math.abs(price * text) .. " gold Septims for " .. text .. " " .. name .. ".", showInDialog = false})
                actualCopper = actualCopper - math.abs(price * text)
                common.fixCounts()
            elseif (text * price > actualCopper and common.GPBankData.accountBalance < text * price) then
                tes3.messageBox({message = "You don't have " .. text * price .. " gold.", showInDialog = false})
            end
        end
        local menu = tes3ui.findMenu(common.GUI_ID_CurrencyExchangeMenu):findChild("GPExchangeInput" .. id)
        menu.text = 0
        menu = tes3ui.findMenu(common.GUI_ID_CurrencyExchangeMenu):findChild("GPBankBill" .. id)
        menu.text = ("\n Value: " .. price .. "\n Owned: " .. common.counts[id].count)
    end
    local menu = tes3ui.findMenu(common.GUI_ID_CurrencyExchangeMenu):findChild(common.GUI_ID_CurrencyExchangeMenuDescription)
    menu.text = ("Here you can exchange your gold Septims for Letters of Credit, higher denomination Septims, native Triune currency, or vice versa. Banned currencies (Drams and Dumacs) may be turned-in to the Imperial Bank for a fair exchange rate. \n \n Gold Septims: " .. actualCopper)
end

function currencyExchangeMenu.destroycurrencyExchangeMenu()
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    bankMenu.visible = true
	local menu = tes3ui.findMenu(common.GUI_ID_CurrencyExchangeMenu)
	menu:destroy()
end

function currencyExchangeMenu.createcurrencyExchangeMenu(e)
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    local npc = tes3ui.findMenu(common.GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
    bankMenu.visible = false
    local actualCopper = common.getActualCopper(common.totalCopper)
	local menu = tes3ui.createMenu({id = common.GUI_ID_CurrencyExchangeMenu, dragFrame = false, fixedFrame = true})
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"

	local label = menu:createLabel({text = "Imperial Bank of Cyrodiil \n"})
	label.color = {0.870, 0.659, 0.0783}
	label.widthProportional = 1
    label.wrapText = true
    label.justifyText = "center"

    local description = menu:createLabel({id = common.GUI_ID_CurrencyExchangeMenuDescription, text = "Here you can exchange your gold Septims for Letters of Credit, higher denomination Septims, native Triune currency, or vice versa. Banned currencies (Drams and Dumacs) may be turned-in to the Imperial Bank for a fair exchange rate. \n \n Gold Septims: " .. actualCopper})
    description.color = {0.875, 0.788, 0.624}
    description.widthProportional = 1
    description.wrapText = 1
    description.justifyText = "center"
    description.borderAllSides = 10

	local currenciesBlock = menu:createBlock()
	currenciesBlock.autoHeight = true
    currenciesBlock.autoWidth = true
    currenciesBlock.wrapText = true
    currenciesBlock.childAlignX = 0.5
    currenciesBlock.justifyText = "center"
    currenciesBlock.flowDirection = "left_to_right"
	currenciesBlock.borderAllSides = 10

    local currenciesBlock1 = currenciesBlock:createBlock()
    currenciesBlock1.autoWidth = true
    currenciesBlock1.autoHeight = true
    currenciesBlock1.flowDirection = "top_to_bottom"
    currenciesBlock1.wrapText = true
    currenciesBlock1.childAlignX = 0.5
    currenciesBlock1.justifyText = "center"
    currenciesBlock1.borderAllSides = 10

    for _, bill in pairs(common.currencies1) do
        local count = 0
        for _, currency in pairs(common.counts) do
            if (currency.id == bill.id) then
                count = currency.count
            end
        end
        local billLabel = currenciesBlock1:createLabel({text = "\n" .. bill.name})
        billLabel.wrapText = true
        billLabel.autoWidth = true
        billLabel.autoHeight = true
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.870, 0.659, 0.0783}

        billLabel = currenciesBlock1:createLabel({id = "GPBankBill" .. bill.id, text = "\n Value: " .. bill.value .. "\n Owned: " .. count})
        billLabel.justifyText = "center"
        billLabel.wrapText = true
        billLabel.autoWidth = true
        billLabel.widthProportional = 1
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.875, 0.788, 0.624}

        local currenciesTradeBlock = currenciesBlock1:createBlock()
        currenciesTradeBlock.autoWidth = true
        currenciesTradeBlock.autoHeight = true
        currenciesTradeBlock.flowDirection = "left_to_right"
        currenciesTradeBlock.wrapText = true
        currenciesTradeBlock.childAlignX = 0.5
        currenciesTradeBlock.justifyText = "center"
        currenciesTradeBlock.borderAllSides = 1

        local minusButton = currenciesTradeBlock:createButton({id = common.GUI_ID_CurrencyExchangeMenuDecreaseButton .. bill.id, text = "-"})
        minusButton:register("mouseClick", currencyExchangeMenu.decreaseCurrencyExchange)

        local currenciesTextInput = currenciesTradeBlock:createTextInput({id = "GPExchangeInput" .. bill.id, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        currenciesTextInput.autoHeight = true
        currenciesTextInput.autoWidth = true
        currenciesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = currenciesTradeBlock:createButton({id = common.GUI_ID_CurrencyExchangeMenuIncreaseButton .. bill.id, text = "+"})
        plusButton:register("mouseClick", currencyExchangeMenu.increaseCurrencyExchange)
    end

    local currenciesBlock2 = currenciesBlock:createBlock()
    currenciesBlock2.autoWidth = true
    currenciesBlock2.autoHeight = true
    currenciesBlock2.flowDirection = "top_to_bottom"
    currenciesBlock2.wrapText = true
    currenciesBlock2.childAlignX = 0.5
    currenciesBlock2.justifyText = "center"
    currenciesBlock2.borderAllSides = 10

    for _, bill in pairs(common.currencies2) do
        local count = 0
        for _, currency in pairs(common.counts) do
            if (currency.id == bill.id) then
                count = currency.count
            end
        end
        local billLabel = currenciesBlock2:createLabel({text = "\n" .. bill.name})
        billLabel.wrapText = true
        billLabel.autoWidth = true
        billLabel.autoHeight = true
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.870, 0.659, 0.0783}

        billLabel = currenciesBlock2:createLabel({id = "GPBankBill" .. bill.id, text = "\n Value: " .. bill.value .. "\n Owned: " .. count})
        billLabel.justifyText = "center"
        billLabel.wrapText = true
        billLabel.widthProportional = 1
        billLabel.autoHeight = true
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.875, 0.788, 0.624}

        local currenciesTradeBlock = currenciesBlock2:createBlock()
        currenciesTradeBlock.autoWidth = true
        currenciesTradeBlock.autoHeight = true
        currenciesTradeBlock.flowDirection = "left_to_right"
        currenciesTradeBlock.wrapText = true
        currenciesTradeBlock.childAlignX = 0.5
        currenciesTradeBlock.justifyText = "center"
        currenciesTradeBlock.borderAllSides = 1

        local minusButton = currenciesTradeBlock:createButton({id = common.GUI_ID_CurrencyExchangeMenuDecreaseButton .. bill.id, text = "-"})
        minusButton:register("mouseClick", currencyExchangeMenu.decreaseCurrencyExchange)

        local currenciesTextInput = currenciesTradeBlock:createTextInput({id = "GPExchangeInput" .. bill.id, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        currenciesTextInput.autoHeight = true
        currenciesTextInput.autoWidth = true
        currenciesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = currenciesTradeBlock:createButton({id = common.GUI_ID_CurrencyExchangeMenuIncreaseButton .. bill.id, text = "+"})
        plusButton:register("mouseClick", currencyExchangeMenu.increaseCurrencyExchange)
    end

    local currenciesBlock3 = currenciesBlock:createBlock()
    currenciesBlock3.autoWidth = true
    currenciesBlock3.autoHeight = true
    currenciesBlock3.flowDirection = "top_to_bottom"
    currenciesBlock3.wrapText = true
    currenciesBlock3.childAlignX = 0.5
    currenciesBlock3.justifyText = "center"
    currenciesBlock3.borderAllSides = 10

    for _, bill in pairs(common.currencies3) do
        local count = 0
        for _, currency in pairs(common.counts) do
            if (currency.id == bill.id) then
                count = currency.count
            end
        end
        local billLabel = currenciesBlock3:createLabel({text = "\n" .. bill.name})
        billLabel.wrapText = true
        billLabel.autoWidth = true
        billLabel.autoHeight = true
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.870, 0.659, 0.0783}

        billLabel = currenciesBlock3:createLabel({id = "GPBankBill" .. bill.id, text = "\n Value: " .. bill.value .. "\n Owned: " .. count})
        billLabel.justifyText = "center"
        billLabel.wrapText = true
        billLabel.autoWidth = true
        billLabel.widthProportional = 1
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.875, 0.788, 0.624}

        local currenciesTradeBlock = currenciesBlock3:createBlock()
        currenciesTradeBlock.autoWidth = true
        currenciesTradeBlock.autoHeight = true
        currenciesTradeBlock.flowDirection = "left_to_right"
        currenciesTradeBlock.wrapText = true
        currenciesTradeBlock.childAlignX = 0.5
        currenciesTradeBlock.justifyText = "center"
        currenciesTradeBlock.borderAllSides = 1

        local minusButton = currenciesTradeBlock:createButton({id = common.GUI_ID_CurrencyExchangeMenuDecreaseButton .. bill.id, text = "-"})
        minusButton:register("mouseClick", currencyExchangeMenu.decreaseCurrencyExchange)

        local currenciesTextInput = currenciesTradeBlock:createTextInput({id = "GPExchangeInput" .. bill.id, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        currenciesTextInput.autoHeight = true
        currenciesTextInput.autoWidth = true
        currenciesTextInput.color = {0.875, 0.788, 0.624}

        local plusButton = currenciesTradeBlock:createButton({id = common.GUI_ID_CurrencyExchangeMenuIncreaseButton .. bill.id, text = "+"})
        plusButton:register("mouseClick", currencyExchangeMenu.increaseCurrencyExchange)
    end

    local currenciesBlock4 = currenciesBlock:createBlock()
    currenciesBlock4.autoWidth = true
    currenciesBlock4.autoHeight = true
    currenciesBlock4.flowDirection = "top_to_bottom"
    currenciesBlock4.wrapText = true
    currenciesBlock4.childAlignX = 0.5
    currenciesBlock4.justifyText = "center"
    currenciesBlock4.borderAllSides = 10

    for _, bill in pairs(common.currencies4) do
        local count = 0
        for _, currency in pairs(common.counts) do
            if (currency.id == bill.id) then
                count = currency.count
            end
        end
        local billLabel = currenciesBlock4:createLabel({text = "\n" .. bill.name})
        billLabel.wrapText = true
        billLabel.autoWidth = true
        billLabel.autoHeight = true
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.870, 0.659, 0.0783}

        billLabel = currenciesBlock4:createLabel({id = "GPBankBill" .. bill.id, text = "\n Value: " .. bill.value .. "\n Owned: " .. count})
        billLabel.justifyText = "center"
        billLabel.wrapText = true
        billLabel.widthProportional = 1
        billLabel.autoHeight = true
        billLabel.borderLeft = 5
        billLabel.borderRight = 3
        billLabel.color = {0.875, 0.788, 0.624}

        local currenciesTradeBlock = currenciesBlock4:createBlock()
        currenciesTradeBlock.autoWidth = true
        currenciesTradeBlock.autoHeight = true
        currenciesTradeBlock.flowDirection = "left_to_right"
        currenciesTradeBlock.wrapText = true
        currenciesTradeBlock.childAlignX = 0.5
        currenciesTradeBlock.justifyText = "center"
        currenciesTradeBlock.borderAllSides = 1

        local minusButton = currenciesTradeBlock:createButton({id = common.GUI_ID_CurrencyExchangeMenuDecreaseButton .. bill.id, text = "-"})
        minusButton:register("mouseClick", currencyExchangeMenu.decreaseCurrencyExchange)

        local currenciesTextInput = currenciesTradeBlock:createTextInput({id = "GPExchangeInput" .. bill.id, text = 0, placeholderText = 0, numeric = true, autoFocus = false})
        currenciesTextInput.autoHeight = true
        currenciesTextInput.autoWidth = true
        currenciesTextInput.color = {0.875, 0.788, 0.624}

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
	button:register("mouseClick", currencyExchangeMenu.confirmCurrencyExchangeChange)

	local cancelButton = block:createButton({text = "Cancel"})
	cancelButton:register("mouseClick", currencyExchangeMenu.destroycurrencyExchangeMenu)
end

return currencyExchangeMenu