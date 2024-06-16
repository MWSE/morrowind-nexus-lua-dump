local common = require("GPBank.common.common")
local config = require("GPBank.config")

local accountMenu = {}

function accountMenu.destroyAccountMenu()
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    bankMenu.visible = true
	local menu = tes3ui.findMenu(common.GUI_ID_AccountMenu)
	menu:destroy()
end

function accountMenu.createAccountMenu()
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    bankMenu.visible = false
	local menu = tes3ui.createMenu({id = common.GUI_ID_AccountMenu, dragFrame = false, fixedFrame = true})
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"

	local label = menu:createLabel({text = "Imperial Bank of Cyrodiil \n"})
	label.color = {0.870, 0.659, 0.0783}
	label.widthProportional = 1
    label.wrapText = true
    label.justifyText = "center"

    local description = menu:createLabel({id = common.GUI_ID_AccountMenuDescription, text = "Here you can deposit or withdraw septims from your account. \n"})
    description.color = {0.875, 0.788, 0.624}
    description.widthProportional = 1
    description.wrapText = 1
    description.justifyText = "center"
    description.borderAllSides = 10

    description = menu:createLabel({id = common.GUI_ID_AccountMenuDetail, text = "Balance: ".. string.format("%.0f", common.accountBalance) .. "\n Interest Rate: " .. string.format("%.4f", common.getInterestRateBank()) .. "\n Interest Gain: " .. string.format("%.0f", common.getInterestBank(common.accountBalance)) .. "\n"})
    description.color = {0.875, 0.788, 0.624}
    description.widthProportional = 1
    description.wrapText = 1
    description.justifyText = "center"
    description.borderAllSides = 10

	local block = menu:createBlock()
	block.autoHeight = true
    block.widthProportional = 1
    block.wrapText = true
    block.childAlignX = 0.5
    block.flowDirection = "left_to_right"
	block.borderAllSides = 10

    local innerBlockBalance = block:createBlock()
    innerBlockBalance.autoHeight = true
    innerBlockBalance.autoWidth = true
    innerBlockBalance.borderAllSides = 10

	label = innerBlockBalance:createLabel({id = common.GUI_ID_BankAccountBalance, text = "Balance: " .. string.format("%.0f", common.accountBalance)})
	label.autoWidth = true
    label.autoHeight = true
    label.color = {0.875, 0.788, 0.624}

    local innerBlockTransfer = block:createBlock()
    innerBlockTransfer.autoWidth = true
    innerBlockTransfer.autoHeight = true
    innerBlockTransfer.borderAllSides = 10

    local transferLabel = innerBlockTransfer:createLabel({text = "Transfer: "})
    transferLabel.autoWidth = true
    transferLabel.autoHeight = true
    transferLabel.borderRight = 3
    transferLabel.color = {0.875, 0.788, 0.624}

    local accountInput = innerBlockTransfer:createTextInput({id = common.GUI_ID_BankAccountBalanceInput, text = 0, placeholderText = 0, numeric = true, autoFocus = true})
    accountInput.autoHeight = true
    accountInput.autoWidth = true
    accountInput.color = {0.875, 0.788, 0.624}

    local innerBlockSeptims = block:createBlock()
    innerBlockSeptims.autoHeight = true
    innerBlockSeptims.autoWidth = true
    innerBlockSeptims.borderAllSides = 10

    local accountInputLabel = innerBlockSeptims:createLabel({id = common.GUI_ID_BankAccountBalanceLabel, text = "Septims: " .. common.totalCopper .. "\n"})
    accountInputLabel.autoHeight = true
    accountInputLabel.autoWidth = true
    accountInputLabel.color = {0.875, 0.788, 0.624}

    -- BUTTONS

	block = menu:createBlock()
	block.autoHeight = true
    block.widthProportional = 1
    block.wrapText = true
    block.childAlignX = 0.5
    block.flowDirection = "left_to_right"
	block.borderAllSides = 10

	local button = block:createButton({text = "Deposit"})
	button:register("mouseClick", common.depositGold)

    button = block:createButton({id = common.GUI_ID_AccountMenuWithdrawButton, text = "Withdraw"})
    button:register("mouseClick", common.withdrawGold)

	button = block:createButton({text = "Cancel"})
	button:register("mouseClick", accountMenu.destroyAccountMenu)
end

return accountMenu