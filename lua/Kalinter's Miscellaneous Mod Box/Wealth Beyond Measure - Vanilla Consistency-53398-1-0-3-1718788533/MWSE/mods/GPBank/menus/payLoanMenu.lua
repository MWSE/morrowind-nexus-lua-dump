local common = require("GPBank.common.common")
local config = require("GPBank.config")

local payLoanMenu = {}

function payLoanMenu.destroyPayLoanMenu()
    local bankMenu = tes3ui.findMenu(common.GUI_ID_LoanMenu)
    bankMenu.visible = true
	local menu = tes3ui.findMenu(common.GUI_ID_LoanMenuPay)
	menu:destroy()
end

function payLoanMenu.createPayLoanMenu()
    local bankMenu = tes3ui.findMenu(common.GUI_ID_LoanMenu)
    local npc = tes3ui.findMenu(common.GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
    bankMenu.visible = false
	local menu = tes3ui.createMenu({id = common.GUI_ID_LoanMenuPay, dragFrame = false, fixedFrame = true})
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"
    --menu.widthProportional = 1

	local label = menu:createLabel({text = "Imperial Bank of Cyrodiil \n"})
	label.color = {0.870, 0.659, 0.0783}
	label.widthProportional = 1
    label.wrapText = true
    label.justifyText = "center"

    local description = menu:createLabel({id = common.GUI_ID_LoanMenuPayDescription, text = "Here you can pay off your loan to a lender. \n Balance: " .. common.getLoanFromNPC(npc).balance})
    if (common.getLoanFromNPC(npc).period < 5) then
        description.color = {0.610, 0.0122, 0.0122}
    else
        description.color = {0.875, 0.788, 0.624}
    end
    description.widthProportional = 1
    description.wrapText = 1
    description.justifyText = "center"
    description.borderAllSides = 10

	local block = menu:createBlock()
	block.autoHeight = true
    block.autoWidth = true
    --block.widthProportional = 1
    block.wrapText = true
    block.childAlignX = 0.5
    block.flowDirection = "left_to_right"
	block.borderAllSides = 10

    local innerBlockTransfer = block:createBlock()
    innerBlockTransfer.autoWidth = true
    innerBlockTransfer.autoHeight = true
    innerBlockTransfer.borderAllSides = 10

    local loanLabel = innerBlockTransfer:createLabel({text = "Amount: "})
    loanLabel.autoWidth = true
    loanLabel.autoHeight = true
    loanLabel.borderRight = 3
    loanLabel.color = {0.875, 0.788, 0.624}

    local loanInput = innerBlockTransfer:createTextInput({id = common.GUI_ID_LoanMenuPayTotalLoanInput, text = 0, placeholderText = 0, numeric = true, autoFocus = true})
    loanInput.autoHeight = true
    loanInput.autoWidth = true
    loanInput.color = {0.875, 0.788, 0.624}

    local innerBlockSeptims = block:createBlock()
    innerBlockSeptims.autoHeight = true
    innerBlockSeptims.autoWidth = true
    innerBlockSeptims.borderAllSides = 10

    local accountInputLabel = innerBlockSeptims:createLabel({id = common.GUI_ID_LoanMenuPayTotalSeptimsLabel, text = "Septims: " .. common.totalCopper .. "\n"})
    accountInputLabel.autoHeight = true
    accountInputLabel.autoWidth = true
    accountInputLabel.color = {0.875, 0.788, 0.624}

    local innerBlockRate = block:createBlock()
    innerBlockRate.autoHeight = true
    innerBlockRate.autoWidth = true
    innerBlockRate.borderAllSides = 10

    local rateLabel = innerBlockRate:createLabel({id = common.GUI_ID_LoanMenuPayRateLabel, text = "Rate: " .. string.format("%.4f", common.getInterestRateLoan()) .. "\n"})
    rateLabel.autoHeight = true
    rateLabel.autoWidth = true
    rateLabel.color = {0.875, 0.788, 0.624}

    -- BUTTONS

	block = menu:createBlock()
	block.autoHeight = true
    block.widthProportional = 1
    block.wrapText = true
    block.childAlignX = 0.5
    block.flowDirection = "left_to_right"
	block.borderAllSides = 10

	local button = block:createButton({text = "Pay Loan"})
	button:register("mouseClick", common.payOffLoan)

	button = block:createButton({text = "Cancel"})
	button:register("mouseClick", payLoanMenu.destroyPayLoanMenu)
end

return payLoanMenu