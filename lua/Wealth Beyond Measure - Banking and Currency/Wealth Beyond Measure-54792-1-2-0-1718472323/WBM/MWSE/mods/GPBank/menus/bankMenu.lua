local common = require("GPBank.common.common")
local config = require("GPBank.config")
local accountMenu = require("GPBank.menus.accountMenu")
local loanMenu = require("GPBank.menus.loanMenu")
local buyInvestmentMenu = require("GPBank.menus.buyInvestmentMenu")
local currencyExchangeMenu = require("GPBank.menus.currencyExchangeMenu")

local bankMenu = {}

function bankMenu.destroyBankMenu()
    common.exitBankMenu()
    local menu = tes3ui.findMenu(common.GUI_ID_BankMenu)
	menu:destroy()
end

function bankMenu.createBankMenu()
    local menu = tes3ui.createMenu({id = common.GUI_ID_BankMenu, dragFrame = false, fixedFrame = true})
	local npc = tes3ui.findMenu(common.GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"

	local label = menu:createLabel({text = "Imperial Bank of Cyrodiil \n"})
	label.color = {0.870, 0.659, 0.0783}
    label.widthProportional = 1
    label.wrapText = true
    label.justifyText = "center"

    local description = menu:createLabel({id = common.GUI_ID_BankMenuDescription, text = "Welcome to the Imperial Bank. We offer various services including accounts with scaling interest, multiple loan options, and investment opportunities. "})
    description.color = {0.875, 0.788, 0.624}
    description.widthProportional = 1
    description.wrapText = 1
    description.justifyText = "center"
    description.borderAllSides = 10
    description.childAlignX = 0.5

    local accountOverview = menu:createLabel({id = common.GUI_ID_BankMenuAccountOverview})
    if (not common.accountCreated) then
        accountOverview.text = ("\n You do not currently have an account. Opening an account requires a one-time fee of " .. common.getAccountFee() .. " septims. \n")
    else
        accountOverview.text = ("\n You currently have an account with a balance of ".. string.format("%.0f", common.accountBalance) .. " septims. \n Your account is earning " .. string.format("%.0f", common.getInterestBank(common.accountBalance)) .. " septims every " .. config.interestPeriodAccount .. " days. \n \n Interest Rate: " .. string.format("%.4f", common.getInterestRateBank()) .. "\n")
    end
    accountOverview.color = {0.875, 0.788, 0.624}
    accountOverview.widthProportional = 1
    accountOverview.wrapText = 1
    accountOverview.justifyText = "center"

    -- BUTTONS

	local block = menu:createBlock()
    block.autoHeight = true
    block.autoWidth = true
    --block.widthProportional = 1
    block.wrapText = true
    block.childAlignX = 0.5
    block.flowDirection = "left_to_right"
	block.borderAllSides = 10

    local button = block:createButton({id = common.GUI_ID_BankMenuAccountButtonCreate, text = "Create Account"})
    if (not common.accountCreated) then
        button.visible = true
    else
        button.visible = false
    end
    button.borderLeft = 5
	button:register("mouseClick", common.createAccount)

    button = block:createButton({id = common.GUI_ID_BankMenuAccountButton, text = "Account"})
    if (common.accountCreated) then
        button.visible = true
    else
        button.visible = false
    end
    button.borderLeft = 5
	button:register("mouseClick", accountMenu.createAccountMenu)

    button = block:createButton({text = "Loans"})
    button:register("mouseClick", loanMenu.createLoanMenu)
    button.borderLeft = 2
    button.borderRight = 2

    button = block:createButton({text = "Investments"})
    button:register("mouseClick", buyInvestmentMenu.createBuyInvestmentMenu)
    button.borderLeft = 2
    button.borderRight = 2

    button = block:createButton({text = "Currency Exchange"})
    button:register("mouseClick", currencyExchangeMenu.createcurrencyExchangeMenu)
    button.borderLeft = 2
    button.borderRight = 2

	button = block:createButton({text = "Cancel"})
	button:register("mouseClick", bankMenu.destroyBankMenu)
end

return bankMenu