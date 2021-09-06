local GUI_ID_ScrollPane = tes3ui.registerID("PartScrollPane_pane")

local GUI_ID_StatMenu = tes3ui.registerID("MenuStat")
local GUI_ID_StatBirthBlock = tes3ui.registerID("MenuStat_birth_layout")

local GUI_ID_DialogMenu = tes3ui.registerID("MenuDialog")
local GUI_ID_DialogTopics = tes3ui.registerID("MenuDialog_topics_pane")
local GUI_ID_DialogDivider = tes3ui.registerID("MenuDialog_divider")

local GUI_ID_DebtsLayout = tes3ui.registerID("MenuStat_debts_layout")
local GUI_ID_DebtsBlock = tes3ui.registerID("MenuStat_debts_block")
local GUI_ID_DebtsOuterBlock = tes3ui.registerID("MenuStat_debts_OuterBlock")
local GUI_ID_DebtsList = tes3ui.registerID("MenuStat_debts_list")
local GUI_ID_DebtsHeader = tes3ui.registerID("MenuStat_debts_header")

local GUI_ID_LoanButton = tes3ui.registerID("MenuDialog_service_loan")
local GUI_ID_LoanMenu = tes3ui.registerID("MenuLoan")
local GUI_ID_LoanValueSlider = tes3ui.registerID("MenuLoan_value_slider")
local GUI_ID_LoanValueNumber = tes3ui.registerID("MenuLoan_value_number")
local GUI_ID_LoanTimeSlider = tes3ui.registerID("MenuLoan_time_slider")
local GUI_ID_LoanTimeNumber = tes3ui.registerID("MenuLoan_time_number")
local GUI_ID_LoanSum = tes3ui.registerID("MenuLoan_Sum")

local interest = 0.14
local loanTimeMax = 14
local currentDay = 0

-- Debt list in stats menu functions

local function onMenuStatDebtsTooltip(e)
	local debtData = tes3.player.data.debtList[e.source:getPropertyObject("DebtNPC").id]
	local tooltip = tes3ui.createTooltipMenu({})
	tooltip.minWidth = 50

	local tooltip = tooltip:createBlock({})
	tooltip.autoWidth = true
	tooltip.autoHeight = true
	tooltip.childAlignX = 0
	tooltip.flowDirection  = "top_to_bottom"

	block = tooltip:createBlock({})
	block.autoWidth = true
	block.autoHeight = true
	block.flowDirection  = "top_to_bottom"
	block.borderAllSides = 6
	local label = block:createLabel({text = "Lender"})
	label.color = {0.875, 0.788, 0.624}
	block:createLabel({text = debtData["Name"]})

	block = tooltip:createBlock({})
	block.autoWidth = true
	block.autoHeight = true
	block.flowDirection  = "top_to_bottom"
	block.borderAllSides = 6
	label = block:createLabel({text = "Location"})
	label.color = {0.875, 0.788, 0.624}
	block:createLabel({text = debtData["Location"]})

	block = tooltip:createBlock({})
	block.autoWidth = true
	block.autoHeight = true
	block.flowDirection  = "top_to_bottom"
	block.borderAllSides = 6
	label = block:createLabel({text = "Value"})
	label.color = {0.875, 0.788, 0.624}
	block:createLabel({text = string.format("%d", debtData["Value"])})

	block = tooltip:createBlock({})
	block.autoWidth = true
	block.autoHeight = true
	block.flowDirection  = "top_to_bottom"
	block.borderAllSides = 6
	label = block:createLabel({text = "Time left"})
	label.color = {0.875, 0.788, 0.624}
	block:createLabel({text = string.format("%d days", debtData["Period"])})
end

local function createDebtList()
	local menu = tes3ui.findMenu(GUI_ID_StatMenu)
	local statPane = menu:findChild(GUI_ID_ScrollPane)
	local birthBlock = menu:findChild(GUI_ID_StatBirthBlock)
	if table.size(tes3.player.data.debtList) > 0 then
		outerDebtsBlock = statPane:createBlock({ id = GUI_ID_DebtsOuterBlock })
		outerDebtsBlock.autoHeight = true
		outerDebtsBlock.layoutWidthFraction = 1.0
		outerDebtsBlock.flowDirection = "top_to_bottom"

		local headingBlock = outerDebtsBlock:createBlock({id = GUI_ID_DebtsHeader})
		headingBlock.layoutWidthFraction = 1.0
		headingBlock.autoHeight = true

		local heading = headingBlock:createLabel({id = GUI_ID_DebtsLayout , text = "Debts"})
		heading.color = tes3ui.getPalette("header_color")
		debtsListBlock = outerDebtsBlock:createBlock({id = GUI_ID_DebtsList })
		debtsListBlock.flowDirection = "top_to_bottom"
		debtsListBlock.layoutWidthFraction = 1.0
		debtsListBlock.autoHeight = true

		for i, debtData in pairs(tes3.player.data.debtList) do
			outerDebtsBlock.autoHeight = true
			local debtsLayout = debtsListBlock:createBlock({id = GUI_ID_DebtsLayout})
			debtsLayout.widthProportional = 1.0
			debtsLayout.autoHeight = true
			debtsLayout.borderRight = 4
			debtsLayout.childAlignX = -1
			debtsLayout.flowDirection  = "left_to_right"
			local debtLabel = debtsLayout:createLabel({text = debtData["Name"]})
			debtLabel.borderLeft = 10
			debtsLayout:createLabel({text = string.format("%d", debtData["Value"])})
			debtsLayout:setPropertyObject("DebtNPC", tes3.getObject(i))
			debtsLayout:register("help", onMenuStatDebtsTooltip)
		end
	outerDebtsBlock:createDivider({id = GUI_ID_DebtsLayout})
	statPane:reorderChildren(birthBlock, outerDebtsBlock, -1)
	end
	menu:updateLayout()
end

local function destroyDebtList()
	local menu = tes3ui.findMenu(GUI_ID_StatMenu)
	local debtsBlock = menu:findChild(GUI_ID_DebtsOuterBlock)
	if debtsBlock then
		debtsBlock:destroy()
	end
end

local function updateDebtList()
	destroyDebtList()
	createDebtList()
end

local function destroyLoanMenu()
	local menu = tes3ui.findMenu(GUI_ID_LoanMenu)
	menu:destroy()
end

-- Loan functions

local function rateLoan(npc)
	local maxLoan = npc.barterGold
	local k1 = tes3.mobilePlayer.mercantile.current + tes3.mobilePlayer.speechcraft.current/5 + tes3.mobilePlayer.personality.current/5 + tes3.mobilePlayer.luck.current/10
	local k2 = npc:getSkillValue(24) + npc:getSkillValue(25)/5 + npc.personality.current/5 + npc.luck.current/10 + 150 - npc.object.disposition
	local koef = 1 - k1/200 + k2/200
	if koef < 0.5 then koef = 0.5 end
	maxLoan = maxLoan / koef
	return maxLoan
end

local function calcLoanSum(loanValue, loanTime)
	local loanNPC = tes3ui.findMenu(GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
	return math.round(loanValue + ((interest / loanTimeMax) * loanValue ) * loanTime, 0)
end

local function createLoan()
	local menu = tes3ui.findMenu(GUI_ID_LoanMenu)
	local loanNPC = tes3ui.findMenu(GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
	local loanValue = menu:findChild(GUI_ID_LoanValueSlider).widget.current
	local loanTime = menu:findChild(GUI_ID_LoanTimeSlider).widget.current
	local loanSum = calcLoanSum(loanValue, loanTime)
	if loanSum ~= 0 then
		local debtData = {}
		debtData["Name"] = loanNPC.reference.object.name
		debtData["Location"] = loanNPC.reference.cell.name
		debtData["Value"] = loanSum
		debtData["Period"] = loanTime
		tes3.player.data.debtList[loanNPC.reference.object.id] = debtData
	end
	tes3.addItem({reference = tes3.getPlayerRef(), item = "Gold_001", count = loanValue})
	loanNPC.barterGold = loanNPC.barterGold - loanValue
	destroyLoanMenu()
	updateDebtList()
end

local function destroyLoan(id)
	tes3.player.data.debtList[id] = nil
	destroyLoanMenu()
	updateDebtList()
end

local function updateLoans()
	for id, debtData in pairs(tes3.player.data.debtList) do
		debtData["Period"] = debtData["Period"] - 1
		if debtData["Period"] < 0 then
			tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + debtData["Value"] * 2
			tes3.player.data.debtCrime = true
			tes3.messageBox(tes3.findGMST("sCrimeMessage").value)
			destroyLoan(id)
		end
	end
	updateDebtList()
end

-- Loan menu functions

local function updateLoanSum()
	local menu = tes3ui.findMenu(GUI_ID_LoanMenu)
	local loanValue = menu:findChild(GUI_ID_LoanValueSlider).widget.current
	local loanTime = menu:findChild(GUI_ID_LoanTimeSlider).widget.current
	local label = menu:findChild(GUI_ID_LoanSum)
	local loanSum = calcLoanSum(loanValue, loanTime)
	label.text = ("TOTAL DEBT: "..loanSum)
end

local function onLoanValueChanged(e)
	tes3ui.findMenu(GUI_ID_LoanMenu):findChild(GUI_ID_LoanValueNumber).text = ("Value: "..e.source.widget.current)
	updateLoanSum()
end

local function onLoanTimeChanged(e)
	tes3ui.findMenu(GUI_ID_LoanMenu):findChild(GUI_ID_LoanTimeNumber).text = ("Period: "..e.source.widget.current.." days")
	updateLoanSum()
end

local function payDebt()
	local menu = tes3ui.findMenu(GUI_ID_LoanMenu)
	local loanNPC = tes3ui.findMenu(GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
	local debtData = tes3.player.data.debtList[loanNPC.reference.object.id]
	local loanSum = debtData["Value"]
	loanNPC.barterGold = loanNPC.barterGold + loanSum
	tes3.removeItem({reference = tes3.getPlayerRef(), item = "Gold_001", count = loanSum})
	destroyLoan(loanNPC.reference.object.id)
end

local function createLoanMenu(e)
	local menu = tes3ui.createMenu({id = GUI_ID_LoanMenu, dragFrame = false, fixedFrame = true})
	local npc = tes3ui.findMenu(GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"

	local label = menu:createLabel({text = "Take a loan"})
	label.color = {0.875, 0.788, 0.624}
	label.justifyText = "center"
	label.wrapText = true
	label.autoWidth = true

	local block = menu:createBlock()
	block.autoWidth = true
	block.autoHeight = true
	block.flowDirection = "left_to_right"
	block.borderTop = 10
	block.borderBottom = 10

	local block1 = block:createBlock()
	block1.width = 120
	block1.autoHeight = true
	label = block1:createLabel({id = GUI_ID_LoanValueNumber, text = "Value: 0"})
	label.borderRight = 5

	local slider = block:createSlider({id = GUI_ID_LoanValueSlider, current = 0, max = rateLoan(npc), jump = 10, step = 100})
	slider.width = 400
	slider:register("PartScrollBar_changed", onLoanValueChanged)

	block = menu:createBlock()
	block.autoWidth = true
	block.autoHeight = true
	block.flowDirection = "left_to_right"
	block.borderTop = 10
	block.borderBottom = 10

	block1 = block:createBlock()
	block1.width = 120
	block1.autoHeight = true
	label = block1:createLabel({id = GUI_ID_LoanTimeNumber, text = "Period: 0 days"})
	label.borderRight = 5

	slider = block:createSlider({id = GUI_ID_LoanTimeSlider, current = 0, max = loanTimeMax, jump = 1, step = 1})
	slider.width = 400
	slider:register("PartScrollBar_changed", onLoanTimeChanged)

	block = menu:createBlock()
	block.autoHeight = true
	block.widthProportional = 1
	block.childAlignX = -1
	block:createLabel({id = GUI_ID_LoanSum, text = "TOTAL DEBT: 0"})

	block1 = block:createBlock()
	block1.autoWidth = true
	block1.autoHeight = true
	block1.flowDirection  = "left_to_right"

	local button = block1:createButton({text = "Take"})
	button:register("mouseClick", createLoan)

	button = block1:createButton({text = "Cancel"})
	button:register("mouseClick", destroyLoanMenu)
end

local function createLoanMenuDebt()
	local menu = tes3ui.createMenu({id = GUI_ID_LoanMenu, dragFrame = false, fixedFrame = true})
	local debtData = tes3.player.data.debtList[tes3ui.findMenu(GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor").reference.object.id]
	menu.borderAllSides = 20
	menu.flowDirection = "top_to_bottom"

	local label = menu:createLabel({text = "Pay Debt"})
	label.color = {0.875, 0.788, 0.624}
	label.justifyText = "center"
	label.wrapText = true
	label.autoWidth = true
	label.borderBottom = 10

	local block = menu:createBlock()
	block.autoHeight = true
	block.autoWidth = true
	block.childAlignX = -1
	block:createLabel({id = GUI_ID_LoanSum, text = ("YOUR DEBT: "..string.format("%d", debtData["Value"]))})

	block1 = block:createBlock()
	block1.autoWidth = true
	block1.autoHeight = true
	block1.flowDirection  = "left_to_right"

	local button = block1:createButton({text = "Pay Debt"})
	button.borderLeft = 10

	if tes3.getPlayerGold() < debtData["Value"] then
		button.widget.state = 2
	else
		button:register("mouseClick", payDebt)
	end

	button = block1:createButton({text = "Cancel"})
	button:register("mouseClick", destroyLoanMenu)
end

local function onLoanButtonClick()
	if tes3.player.data.debtList[tes3ui.findMenu(GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor").reference.object.id] ~= nil then
		createLoanMenuDebt()
	else
		createLoanMenu()
	end
end

local function createLoanButton(parent,enabled)
	local loanButton
	if enabled then
		loanButton = parent:createTextSelect({id = GUI_ID_LoanButton, text = "Loan"})
		loanButton:register("mouseClick", onLoanButtonClick)
		loanButton.visible = true
	else
		loanButton = parent:createLabel({id = GUI_ID_LoanButton, text = "Loan"})
		loanButton.color = tes3ui.getPalette("journal_finished_quest_color")
		loanButton.visible = true
	end
	return loanButton
end

local function updateLoanButton()
	local menu = tes3ui.findMenu(GUI_ID_DialogMenu)
	if not menu then return end
	local actor = menu:getPropertyObject("PartHyperText_actor")
	local topics = menu:findChild(GUI_ID_DialogTopics):findChild(GUI_ID_ScrollPane)
	local dialogDivider = menu:findChild(GUI_ID_DialogDivider)
	local loanButton = menu:findChild(GUI_ID_LoanButton)
	local loanAvaliable = ((actor.barterGold > 0) or (tes3.player.data.debtList[actor.reference.object.id])) and not tes3.player.data.debtCrime
	if actor.reference.object.class.id == "Pawnbroker" then
		if loanButton then
			if not loanButton.visible then
				loanButton.visible = true
			end
			local loanButtonEnabled = not (loanButton.color == tes3ui.getPalette("journal_finished_quest_color"))
			if loanButtonEnabled and not loanAvaliable then
				loanButton:destroy()
				loanButton = createLoanButton(topics, false)
				topics:reorderChildren(dialogDivider, loanButton, 1)
				menu:updateLayout()
			elseif (not loanButtonEnabled) and loanAvaliable then
				loanButton:destroy()
				loanButton = createLoanButton(topics, true)
				topics:reorderChildren(dialogDivider, loanButton, 1)
				menu:updateLayout()
			end
		else
			if loanAvaliable then
				loanButton = createLoanButton(topics, true)
				topics:reorderChildren(dialogDivider, loanButton, 1)
				menu:updateLayout()
			else
				loanButton = createLoanButton(topics, false)
				topics:reorderChildren(dialogDivider, loanButton, 1)
				menu:updateLayout()
			end
		end
	end
end

--events

local function onEnterFrame()
	updateLoanButton()
	if currentDay ~= tes3.getGlobal("Day") then
		currentDay = tes3.getGlobal("Day")
		updateLoans()
	end
	if tes3.player.data.debtCrime == true and tes3.mobilePlayer.bounty == 0 then
		tes3.player.data.debtCrime = false
	end
end

local function onLoad(e)
	event.register("menuEnter ", updateDebtList)
	event.register("enterFrame", onEnterFrame)
	if tes3.player.data.debtList == nil then tes3.player.data.debtList = {} end
	if tes3.player.data.debtCrime == nil then tes3.player.data.debtCrime = false end
end

event.register("loaded", onLoad)
