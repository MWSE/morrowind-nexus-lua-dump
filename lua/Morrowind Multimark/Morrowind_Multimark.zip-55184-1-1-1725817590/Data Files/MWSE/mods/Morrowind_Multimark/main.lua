-- Morrowind Multimark - Allow Multiple Mark spells, and handling of compantions through teleporting
-- Drac and Toccatta, Aug 31, 2024]-- Version 0.8

local this = {}
local playerDests = {} -- markList.marks{} = celDesc, cellname, locX,locY,locZ location, orient (Z), isInterior, gridX, gridY

local action = 0
local menu, UID_menu, UID_label, UID_button, UID_listPane, UID_filterText
local id_menu, id_label, id_nameText, id_listPane, titleLabel
local button_Mark, button_Remove, inputText, inputLabel, cellName, cellDesc, destNum, spellName
local ttl = 0

function init()
	this.id_menu = tes3ui.registerID("Morrowindmultimarkmenu")
	this.id_nameText = tes3ui.registerID("nameText::Input")
	this.id__listPane = tes3ui.registerID("multimark_listPane::List")
	this.UID_inputText = tes3ui.registerID("Morrowindmultimarkmenu::Input")
	mwse.log("[Morrowind Multimark] Initialized")
end

local function momentsDelay(e)
	-- not a lot happening here
end

local function sortcellName(a,b)
	if a.cellDesc < b.cellDesc then
		return true
	elseif a.cellDesc > b.cellDesc then
		return false
	else
		return a.cellDesc < b.cellDesc
	end
end

-- Cancel button
local function onCancel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function onClickSelectedRecall(e)
	local num = e.source:getPropertyInt("Morrowindmultimarkmenu:Index")
	tes3.positionCell({ reference = tes3.player,  cell = playerDests[num].cellName, position = {playerDests[num].locX, playerDests[num].locY, playerDests[num].locZ}, orientation = {0, 0, playerDests[num].orient}, forceCellChange = true })
	local timer = timer.frame.delayOneFrame(momentsDelay)
	--local soundedOff = tes3.playSound({ sound = "mysticism hit"})
	tes3ui.leaveMenuMode()
	menu:destroy()
end

local function onClickRemoveMark(e)
	local num = destNum
	if (num ~= 0) then
		table.remove(playerDests,num)
		tes3.player.data.multimark=playerDests
		destNum = 0
		menu:destroy()
		this.multimarkWindow()
	else
		tes3.messageBox({ message = "Unable to remove; please select the item to remove, first"})
	end
end

local function onClickSelectedItem(e)
	local menu = tes3ui.findMenu(this.id_menu)
	destNum = e.source:getPropertyInt("Morrowindmultimarkmenu:Index")
	menu:destroy()
	action = 2
	this.multimarkWindow()
end

local function onClickMakeMark()
	if (playerDests == nil) then playerDests = {} end
	if (destNum == 0) then destNum = #playerDests+1 end
	if (inputText.text == nil) or (inputText.text == "") or (inputText.text == " ") then cellDesc = tes3.player.cell.name else cellDesc = inputText.text end
	tes3.messageBox({ message = "Location marked as '"..cellDesc.."'"})
	playerDests[destNum] = {["cellDesc"] = cellDesc,
							["cellName"] = tes3.player.cell.name,
							["locX"] = tes3.player.position.x,
							["locY"] = tes3.player.position.y,
							["locZ"] = tes3.player.position.z,
							["orient"] = tes3.player.orientation.z,
							["isInterior"] = tes3.player.cell.isInterior,
							["gridX"] = tes3.player.cell.gridX,
							["gridY"] = tes3.player.cell.gridY}
	table.sort(playerDests,sortcellName)
	tes3.player.data.multimark=playerDests
	destNum = 0
	tes3ui.leaveMenuMode()
	menu:destroy()
end

local function showLocationToolTip(e)
	local tipDesc, tipX, tipY, tipZ, tipAngle
	local tipMenu = tes3ui.createTooltipMenu()
	local tipNum = e.source:getPropertyInt("Morrowindmultimarkmenu:Index")
	tipDesc = playerDests[tipNum].cellName
	if (tipDesc == nil) then tipDesc = "" end
	if (playerDests[tipNum].isInterior == false) then
		tipDesc = tipDesc.." ("..playerDests[tipNum].gridX..", "..playerDests[tipNum].gridY..")"
	end
	local tipLabel = tipMenu:createLabel({ text = tipDesc})
	local tipLabel = tipMenu:createLabel({ text = " " }) --spacer
	tipX = playerDests[tipNum].locX
	tipY = playerDests[tipNum].locY
	tipZ = playerDests[tipNum].locZ
	tipAngle = math.deg(playerDests[tipNum].orient)
	local tipLocation = string.format("(%.0f, %.0f, %.0f) facing %.0f", tipX, tipY, tipZ, tipAngle)
	local tipLabel = tipMenu:createLabel({ text = tipLocation})
end

-- Create window and layout. Called by magicCastedCall for 'recall'
function this.multimarkWindow()
	if (action~=1) and (action~=2) then
		return
	end
	cellName = tes3.player.cell
    --Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
	end
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "MultiMark Recall"
	menu.width = 300
	menu.height = 600
	menu.minWidth = 500
	menu.minHeight = 600
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
	local titleBlock = menu:createBlock({})
	titleBlock.widthProportional = 1.0
	titleBlock.flowDirection = "left_to_right"
	titleBlock.autoHeight = true
	titleBlock.childAlignX = 0.5  -- left content alignment
	titleLabel = titleBlock:createLabel({ text = "#ERROR#"})
	if ( action == 1 ) then -- Is recall spell
		titleLabel.text = spellName --"MultiMark Recall"
	elseif ( action == 2 ) then
		titleLabel.text= spellName --"MultiMark"
	end
	titleLabel.borderRight = 2
	local listBlock = menu:createBlock({})
	listBlock.widthProportional = 1.0
	listBlock.flowDirection = "left_to_right"
	listBlock.childAlignX = 1.0 -- left oriented
	local listPane = menu:createVerticalScrollPane({ id = this.id_listPane})
	local playerRef = tes3.getPlayerRef()
	if (playerDests ~= nil) then 
		playerDests = playerRef.data.multimark -- Fetch any previously saved destinations
	end
	ttl = 0
	if (playerDests ~= nil) then
		for index, x in ipairs(playerDests) do
			local itemBlock = listPane:createBlock({})
			itemBlock.flowDirection = "left_to_right"
			itemBlock.widthProportional = 1.0
			itemBlock.autoHeight = true
			itemBlock.borderAllSides = 3
			itemBlock:setPropertyInt("Morrowindmultimarkmenu:Index", index)
			local label = itemBlock:createLabel({ text = x.cellDesc})
			if (index == destNum) then label.color = tes3ui.getPalette("white_color") else label.color = tes3ui.getPalette("normal_color") end
			label.borderLeft = 10
			if ( action == 1 ) then itemBlock:register("mouseClick", onClickSelectedRecall) end
			if ( action == 2 ) then itemBlock:register("mouseClick", onClickSelectedItem) end
			itemBlock:register("help", showLocationToolTip)
			label.consumeMouseEvents = false
			ttl = ttl + 1
		end
	end

	if (ttl == 0) and ( action == 1 ) then titleLabel.text = "No Destinations Found" end
	
	local inputBlock = menu:createBlock{}
	inputBlock.flowDirection = "left_to_right"
	inputBlock.widthProportional = 1.0
    inputBlock.autoHeight = true
    inputBlock.childAlignX = -1.0
	local inputBorder = inputBlock:createThinBorder{}
	inputBorder.widthProportional = 1.0
	inputBorder.height = 24
	inputBorder.childAlignX = 0.5
	inputBorder.childAlignY = 0.5
	--inputBorder.absolutePosAlignY = 0.5
	inputText = inputBorder:createTextInput({ id = this.UID_inputText })
	inputText.borderLeft = 5
	inputText.borderRight = 5
	inputText.widget.eraseOnFirstKey = false
	inputText.text = cellName
	if (destNum ~= 0) then inputText.text = playerDests[destNum].cellDesc end
	
	local button_block = menu:createBlock{}
	button_block.widthProportional = 1.0  -- width is 100% parent width
	button_block.autoHeight = true
	button_block.childAlignX = 0.5

	button_Mark = button_block:createButton{ id = "multimarkMark", text = "Mark" }
	button_Remove = button_block:createButton{ id = "multimarkRemove", text = "Remove" }
    button_cancel = button_block:createButton{ id = multimarkCancel, text = tes3.findGMST("sCancel").value }
	button_Mark:register("mouseClick", onClickMakeMark)
	button_Remove:register("mouseClick", onClickRemoveMark)
	
	if (action ~= 2) then
		button_Mark.visible = false
		button_Remove.visible = false
		inputText.visible = false
		inputBorder.visible = false
	end

	if (destNum == 0) then button_Remove.visible = false elseif (destNum ~= 0) and (action == 2) then button_Remove.visible = true end

	-- Events
	button_cancel:register("mouseClick", onCancel)
	menu:updateLayout()
	tes3ui.enterMenuMode(this.id_menu)
	tes3ui.acquireTextInput(inputText)
end

local function spellCastCall(e)
	-- Now determine if the spell has a 'mark' or a 'recall' effect. Whichever comes first! And then not execute the spell
	spellName = e.source.name
	for i,x in pairs(e.source.effects) do
		if x.id == tes3.effect.mark then
			action = 2
			e.block = true
			momentsDelay()
			e.sourceInstance.state = tes3.spellState.retired
			destNum = 0
			this.multimarkWindow()
		elseif x.id == tes3.effect.recall then
			action = 1
			e.block = true
			momentsDelay()
			e.sourceInstance.state = tes3.spellState.retired
			destNum = 0
			this.multimarkWindow()
		else
			action = 0
			-- neither mark nor recall - no action
			return
		end
	end
end

event.register("initialized", init)
event.register(tes3.event.spellTick, spellCastCall)