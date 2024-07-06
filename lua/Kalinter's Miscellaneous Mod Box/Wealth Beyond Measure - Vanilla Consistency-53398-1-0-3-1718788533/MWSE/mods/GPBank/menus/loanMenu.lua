local common = require("GPBank.common.common")
local config = require("GPBank.config")
local takeLoanMenu = require("GPBank.menus.takeLoanMenu")
local payLoanMenu = require("GPBank.menus.payLoanMenu")

local loanMenu = {}

function loanMenu.destroyLoanMenu()
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    bankMenu.visible = true
	local menu = tes3ui.findMenu(common.GUI_ID_LoanMenu)
	menu:destroy()
end

function loanMenu.createLoanMenu()
    local npc = tes3ui.findMenu(common.GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
    local loanNpc
    local bankMenu = tes3ui.findMenu(common.GUI_ID_BankMenu)
    bankMenu.visible = false
	local menu = tes3ui.createMenu({id = common.GUI_ID_LoanMenu, dragFrame = false, fixedFrame = true})
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"

	local label = menu:createLabel({text = "Imperial Bank of Cyrodiil \n"})
	label.color = {0.870, 0.659, 0.0783}
	label.widthProportional = 1
    label.wrapText = true
    label.justifyText = "center"

    local description = menu:createLabel({id = common.GUI_ID_LoanMenuDescription, text = "Here you can take out new loans and pay off current loans."})
    description.color = {0.875, 0.788, 0.624}
    description.widthProportional = 1
    description.wrapText = 1
    description.justifyText = "center"
    description.borderAllSides = 10

	local loanOverview = menu:createLabel({id = common.GUI_ID_LoanMenuOverview})
    if (#(common.activeLoans) == 0) then
        loanOverview.text = ("You do not currently have any active loans. \n")
    else
        loanOverview.text = ("You currently have " .. #(common.activeLoans) .. " active loans. \n")
    end
    loanOverview.color = {0.875, 0.788, 0.624}
    loanOverview.widthProportional = 1
    loanOverview.wrapText = 1
    loanOverview.justifyText = "center"

    local loanDetails = menu:createBlock({id = common.GUI_ID_LoanMenuDetail})
    loanDetails.color = {0.875, 0.788, 0.624}
    loanDetails.widthProportional = 1
    loanDetails.autoHeight = true
    loanDetails.childAlignX = 0
    if (#(common.activeLoans) == 0) then
        loanDetails.visible = false
    else
        for _, activeLoan in pairs(common.activeLoans) do
            loanNpc = activeLoan.npc
            local tempID = "GPBankActiveLoan" .. activeLoan.npc
            local activeLoanText = loanDetails:createLabel({id = tempID, text = "Loan from " .. activeLoan.npc .. "\n" .. "Principal - " .. activeLoan.principal .. "\nRate - "  .. string.format("%.4f", activeLoan.rate) .. "\nBalance Remaining - " .. string.format("%.0f", activeLoan.balance) .. "\nTime Remaining - " .. string.format(math.floor(activeLoan.period)) .. " \n"})
            if (activeLoan.period < 5) then
                activeLoanText.color = {0.610, 0.0122, 0.0122}
            else
                activeLoanText.color = {0.875, 0.788, 0.624}
            end
            activeLoanText.visible = true
            activeLoanText.wrapText = 1
            activeLoanText.justifyText = "center"
            activeLoanText.autoHeight = true
            activeLoanText.autoWidth = true
        end
    end

    -- BUTTONS

	local block = menu:createBlock()
    block.autoHeight = true
    block.widthProportional = 1
    block.wrapText = true
    block.childAlignX = 0.5
    block.flowDirection = "left_to_right"
	block.borderAllSides = 10

    local button = block:createButton({id = common.GUI_ID_BankMenuLoanButtonTake, text = "Take Loan"})
    if (#(common.activeLoans) == 0 and common.GPBankData.loanCrime == false) then
        button.visible = true
    elseif (common.GPBankData.loanCrime == true) then
        button.visible = false
    elseif (#(common.activeLoans) <= common.activeLoanMax) then
        local seen = false
        for _, activeLoan in pairs(common.activeLoans) do
            if (activeLoan.npc == npc.reference.object.name) then
                seen = true
            end
        end
        if (not seen) then
            button.visible = true
        else
            button.visible = false
        end
    else
        button.visible = false
    end
    button.borderLeft = 5
	button:register("mouseClick", takeLoanMenu.createTakeLoanMenu)

    button = block:createButton({id = common.GUI_ID_BankMenuLoanButtonPay, text = "Pay Off Loan"})
    if (#(common.activeLoans) ~= 0 and (loanNpc and loanNpc == npc.reference.object.name)) then
        button.visible = true
    else
        button.visible = false
    end
    button.borderLeft = 5
	button:register("mouseClick", payLoanMenu.createPayLoanMenu)

	button = block:createButton({text = "Cancel"})
	button:register("mouseClick", loanMenu.destroyLoanMenu)

end

return loanMenu