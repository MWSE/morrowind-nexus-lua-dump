local ui    = require('openmw.ui')
local util  = require('openmw.util')
local core  = require('openmw.core')
local types = require('openmw.types')
local self  = require('openmw.self')
local input = require('openmw.input')
local I     = require('openmw.interfaces')
local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')

local currencies = require('scripts.MakeAProfit.currencies')
local gamepad    = require('scripts.MakeAProfit.gamepad')

local baseTemplates, specialTemplates
if I.InventoryExtender then
	baseTemplates    = require('scripts.InventoryExtender.ui.templates.base')
	specialTemplates = require('scripts.InventoryExtender.ui.templates.magic')
end

local v2 = util.vector2

local Investment = {}

local function isInvestTarget(obj)
	if not obj then return false end
	if types.NPC.objectIsInstance(obj) then return true end
	if types.Creature.objectIsInstance(obj) and S_INVEST_CREATURES then return true end
	return false
end

local function isCreature(obj)
	return obj and types.Creature.objectIsInstance(obj)
end

local function getRecord(obj)
	if types.NPC.objectIsInstance(obj) then return types.NPC.record(obj) end
	if types.Creature.objectIsInstance(obj) then return types.Creature.record(obj) end
end

local ARROW_STEP      = 25
local MAX_DISP_GAIN   = 25
local DISP_PER_GOLD   = 100

local saveData        = nil
local dialogWindow    = nil
local currentAmount   = 0
local currentText     = '0'
local cachedMerchant  = nil
local gamepadHandler  = nil

local function getPlayerGold()
	return currencies.getPlayerCount()
end

local function getNpcId(merchant)
	return merchant.recordId
end

local function getInvested(merchant)
	if not saveData or not saveData.investments then return 0 end
	return saveData.investments[getNpcId(merchant)] or 0
end

local function calcDisposition(amount)
	return math.min(MAX_DISP_GAIN, math.floor(amount / DISP_PER_GOLD))
end

-- scale by S_INVEST_EFFICIENCY
local function effectiveInvest(amount)
	if amount <= 0 then return 0 end
	local pct = (S_INVEST_EFFICIENCY or 100) / 100
	if pct >= 1 then return amount end
	return math.max(1, math.floor(amount * pct))
end

-- cap for investment: 100 at level 0, ~1000 at 50, ~10000 at 100
local function getMaxInvestment()
	local level = self.type.stats.skills.mercantile(self).modified
	return math.floor(100 * 10 ^ (level / 50))
end

local function clampAmount()
	local cap = math.min(getPlayerGold(), getMaxInvestment() - getInvested(cachedMerchant))
	currentAmount = math.max(0, math.min(currentAmount, cap))
	currentText = tostring(currentAmount)
end

local function destroyDialog()
	if gamepadHandler then
		gamepad.unregister(gamepadHandler)
		gamepadHandler = nil
	end
	if dialogWindow then
		auxUi.deepDestroy(dialogWindow)
		dialogWindow = nil
	end
	cachedMerchant = nil
	currentAmount = 0
	currentText = '0'
end

local function doInvest()
	if not cachedMerchant or currentAmount <= 0 then return end
	local amount = currentAmount
	local playerGold = getPlayerGold()
	if amount > playerGold then amount = playerGold end
	if amount <= 0 then return end
	
	local effective = effectiveInvest(amount)
	local disp = isCreature(cachedMerchant) and 0 or calcDisposition(amount)

	-- save raw invested amount; merchant only receives the effective portion
	saveData.investments = saveData.investments or {}
	local id = getNpcId(cachedMerchant)
	local prev = saveData.investments[id] or 0
	saveData.investments[id] = prev + amount
	saveData.lastApplied[id] = core.getGameTime()
	
	local rec = getRecord(cachedMerchant)
	local who = (rec and rec.name) or id
	--print('Invested ' .. amount .. ' gold in ' .. who)
	--print('Total invested: ' .. prev .. ' > ' .. saveData.investments[id])
	if isCreature(cachedMerchant) then
	--	print('Creature merchant, disposition skipped')
	elseif disp > 0 then
	--	print('Disposition bonus: +' .. disp)
	end
	--print('Mercantile XP awarded')

	-- global event: remove player gold, add merchant gold, disposition
	core.sendGlobalEvent('MAP_DoInvest', {
		player    = self,
		merchant  = cachedMerchant,
		amount    = amount,
		effective = effective,
		disp      = disp,
	})

	I.SkillProgression.skillUsed('mercantile', { useType = I.SkillProgression.SKILL_USE_TYPES.Mercantile_Success, })

	local msg = 'Invested ' .. amount .. ' gold.'
	if effective < amount then
		msg = msg .. ' Merchant gained ' .. effective .. '.'
	end
	if disp > 0 then
		msg = msg .. ' Disposition +' .. disp .. '.'
	end
	ui.showMessage(msg)
	destroyDialog()
	-- the global doInvest handler sends MAP_RefreshInfoBars back to the player
end

function Investment.showDialog(merchant)
	if dialogWindow then destroyDialog() end
	if not merchant then return end
	
	cachedMerchant = merchant
	currentAmount = 0
	currentText = '0'
	
	local tw = I.InventoryExtender.getWindow('Trade')
	local ctx = tw and tw.ctx
	
	local record = getRecord(merchant)
	local npcName = (record and record.name) or 'Merchant'
	local forcedGold = (saveData.forcedTradeGold and saveData.forcedTradeGold[getNpcId(merchant)]) or 0
	local baseGold = ((record and record.baseGold) or 0) + forcedGold
	local invested = getInvested(merchant)
	local playerGold = getPlayerGold()
	local maxCap = getMaxInvestment()
	
	local tag = isCreature(merchant) and 'creature' or 'NPC'
	
	local infoStr = 'Merchant gold: ' .. baseGold
	if invested > 0 then
		local effInv = effectiveInvest(invested)
		if effInv < invested then
			infoStr = infoStr .. '  (+' .. effInv .. ' from ' .. invested .. ' invested)'
		else
			infoStr = infoStr .. '  (+' .. invested .. ' invested)'
		end
	end
	
	local dispText = {
		template = baseTemplates.textNormal,
		props = { text = '' },
	}
	
	local isCrtr = isCreature(merchant)
	
	local function refreshDisp()
		local parts = {}
		-- show effective gain when efficiency < 100
		if currentAmount > 0 then
			local eff = effectiveInvest(currentAmount)
			if eff < currentAmount then
				table.insert(parts, 'Merchant gains: ' .. eff)
			end
		end
		if not isCrtr then
			local disp = calcDisposition(currentAmount)
			if currentAmount > 0 and disp > 0 then
				table.insert(parts, 'Disposition +' .. disp)
			end
		end
		dispText.props.text = table.concat(parts, '   ')
	end
	
	local sliderMax = math.min(getMaxInvestment() - invested, playerGold)
	local sliderStep = math.max(1, math.floor(sliderMax / 25))
	
	local layout = {
		type = ui.TYPE.Flex,
		props = {
			arrange = ui.ALIGNMENT.Center,
			align = ui.ALIGNMENT.Center,
		},
		content = ui.content {},
	}
	
	layout.content:add({
		template = baseTemplates.textHeader,
		props = { text = 'Invest in ' .. npcName },
	})
	layout.content:add(baseTemplates.intervalV(8))
	
	layout.content:add({
		template = baseTemplates.textNormal,
		props = { text = infoStr },
	})
	
	layout.content:add({
		template = baseTemplates.textNormal,
		props = { text = 'Your gold: ' .. playerGold },
	})
	layout.content:add(baseTemplates.intervalV(8))
	
	local slider
	local valueText = {
		template = baseTemplates.textEditLine,
		props = {
			text = currentText,
			size = v2(60, 0),
		},
	}
	valueText.events = {
		textChanged = async:callback(function(newText, elem)
			local digits = newText:gsub('[^%d]', '')
			currentText = digits
			currentAmount = tonumber(digits) or 0
			clampAmount()
			elem.props.text = currentText
			refreshDisp()
			if dialogWindow then dialogWindow:update() end
		end),
		focusLoss = async:callback(function()
			clampAmount()
			valueText.props.text = currentText
			if slider then slider.layout.userData.triggerChange(currentAmount) end
			refreshDisp()
			if dialogWindow then dialogWindow:update() end
		end),
		keyPress = async:callback(function(data, elem)
			if data.code == input.KEY.Enter
				or data.code == input.KEY.NP_Enter then
				doInvest()
			elseif data.code == input.KEY.Escape then
				destroyDialog()
			end
		end),
	}
	
	-- slider
	slider = baseTemplates.slider(0, sliderMax, 0, sliderStep, 240, function(newValue)
		currentAmount = math.floor(newValue)
		currentText = tostring(currentAmount)
		valueText.props.text = currentText
		refreshDisp()
		if dialogWindow then dialogWindow:update() end
	end)

	--[[
	local inputRow = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {},
	}
	inputRow.content:add(specialTemplates.interactive({
		onClick = function()
			currentAmount = currentAmount - ARROW_STEP
			clampAmount()
			refreshDisp()
			if dialogWindow then dialogWindow:update() end
		end,
	}, baseTemplates.button('<'), ctx))
	inputRow.content:add(baseTemplates.intervalH(4))
	inputRow.content:add({
		template = I.MWUI.templates.box,
		content = ui.content {
			{
				template = I.MWUI.templates.padding,
				content = ui.content { textEdit },
			},
		},
	})
	inputRow.content:add(baseTemplates.intervalH(4))
	inputRow.content:add(specialTemplates.interactive({
		onClick = function()
			currentAmount = currentAmount + ARROW_STEP
			clampAmount()
			refreshDisp()
			if dialogWindow then dialogWindow:update() end
		end,
	}, baseTemplates.button('>'), ctx))
	layout.content:add(inputRow)
	--]]
	
	layout.content:add(slider)
	layout.content:add(baseTemplates.intervalV(4))
	
	local valueRow = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			-- amount box
			{
				template = I.MWUI.templates.box,
				content = ui.content {
					{
						template = I.MWUI.templates.padding,
						content = ui.content { valueText },
					},
				},
			},
			baseTemplates.intervalH(8),
			{
				template = baseTemplates.textNormal,
				props = { text = '/ ' .. sliderMax },
			},
		},
	}
	layout.content:add(valueRow)
	layout.content:add(baseTemplates.intervalV(4))
	layout.content:add(dispText)
	layout.content:add(baseTemplates.intervalV(8))
	
	local btnRow = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {},
	}
	
	-- invest button (label tweaked when gamepad recently active)
	local investBtn  = baseTemplates.button('Invest')
	local investText = investBtn.layout.content[1].content[2]
	local function refreshInvestLabel()
		if gamepad.wasRecentlyActive(60) then
			investText.props.text = 'Invest [Y]'
		else
			investText.props.text = 'Invest'
		end
		investBtn:update()
	end
	refreshInvestLabel()
	btnRow.content:add(specialTemplates.interactive({
		onClick = function() doInvest() end,
	}, investBtn, ctx))

	btnRow.content:add(baseTemplates.intervalH(8))

	btnRow.content:add(specialTemplates.interactive({
		onClick = function() destroyDialog() end,
	}, baseTemplates.button('Cancel'), ctx))

	-- gamepad: dpad moves slider (repeats while held), Y confirms
	gamepadHandler = function(id, isRepeat)
		if not dialogWindow then return end
		local step = slider.layout.userData.step
		if id == input.CONTROLLER_BUTTON.DPadLeft then
			slider.layout.userData.triggerChange(slider.layout.userData.value - step)
		elseif id == input.CONTROLLER_BUTTON.DPadRight then
			slider.layout.userData.triggerChange(slider.layout.userData.value + step)
		elseif id == input.CONTROLLER_BUTTON.Y and not isRepeat then
			doInvest()
			return
		end
		refreshInvestLabel()
	end
	gamepad.register(gamepadHandler)

	layout.content:add(btnRow)
	
	dialogWindow = ui.create(specialTemplates.modal({
		{
			template = baseTemplates.padding(8),
			content = ui.content { layout },
		},
	}))
end

-- ----------------------------------------------------
-- vanilla MWUI invest dialog (no IE)
-- ----------------------------------------------------

-- manually built horizontal slider with left/right step buttons
-- returns wrapper layout and setHandlePos(val) for external updates
local function buildVanillaSlider(maxValue, step, onChange)
	local TRACK_W = 240
	local TRACK_H = 16
	local BTN_SIZE = 16
	local handleW = math.max(20, math.min(TRACK_W / 3, TRACK_W / math.max(1, maxValue)))

	local function valueToPos(val)
		if maxValue <= 0 then return 0 end
		return util.clamp(val, 0, maxValue) / maxValue * (TRACK_W - handleW)
	end
	local function posToValue(pos)
		local available = TRACK_W - handleW
		if available <= 0 then return 0 end
		return math.floor(util.clamp(pos, 0, available) / available * maxValue + 0.5)
	end

	-- internal value tracking (kept in sync via setHandlePos)
	local sliderState = {
		value = 0,
	}

	-- handle (records click offset, propagates events to track)
	local handle = {
		name = 'handle',
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = 'textures/omw_menu_scroll_center_h.dds' },
			size = v2(handleW, TRACK_H - 4),
			tileH = true,
			position = v2(0, 0),
			propagateEvents = true,
		},
		userData = {
			dragOffset = nil,
		},
		events = {
			mousePress = async:callback(function(e, layout)
				if e.button ~= 1 then return false end
				layout.userData.dragOffset = e.offset.x
				return false
			end),
			mouseRelease = async:callback(function(e, layout)
				layout.userData.dragOffset = nil
				return false
			end),
		},
	}

	-- track (handles jump-on-click and drag-tracking via mouseMove)
	local track = {
		name = 'sliderTrack',
		template = I.MWUI.templates.borders,
		props = {
			size = v2(TRACK_W, TRACK_H),
		},
		content = ui.content { handle },
		events = {
			mousePress = async:callback(function(e, layout)
				if e.button ~= 1 then return end
				ambient.playSound('menu click')
				local v = posToValue(e.offset.x - handleW / 2)
				layout.content[1].userData.dragOffset = handleW / 2
				onChange(v)
			end),
			mouseMove = async:callback(function(e, layout)
				if e.button == 1 and layout.content[1].userData.dragOffset then
					local newX = e.offset.x - layout.content[1].userData.dragOffset
					onChange(posToValue(newX))
				end
				return true
			end),
			mouseRelease = async:callback(function(e, layout)
				if e.button == 1 then
					layout.content[1].userData.dragOffset = nil
				end
			end),
		},
	}

	-- left step button
	local leftBtn = {
		template = I.MWUI.templates.borders,
		props = {
			size = v2(BTN_SIZE, BTN_SIZE),
		},
		content = ui.content {
			{
				type = ui.TYPE.Image,
				props = {
					resource = ui.texture { path = 'textures/omw_menu_scroll_left.dds' },
					size = v2(BTN_SIZE - 4, BTN_SIZE - 4),
					position = v2(2, 2),
				},
			},
		},
		events = {
			mousePress = async:callback(function(e)
				if e.button ~= 1 then return end
				ambient.playSound('menu click')
				onChange(sliderState.value - step)
			end),
		},
	}

	-- right step button
	local rightBtn = {
		template = I.MWUI.templates.borders,
		props = {
			size = v2(BTN_SIZE, BTN_SIZE),
		},
		content = ui.content {
			{
				type = ui.TYPE.Image,
				props = {
					resource = ui.texture { path = 'textures/omw_menu_scroll_right.dds' },
					size = v2(BTN_SIZE - 4, BTN_SIZE - 4),
					position = v2(2, 2),
				},
			},
		},
		events = {
			mousePress = async:callback(function(e)
				if e.button ~= 1 then return end
				ambient.playSound('menu click')
				onChange(sliderState.value + step)
			end),
		},
	}

	-- horizontal wrapper: [left] [track] [right]
	local wrapper = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			leftBtn,
			{ props = { size = v2(2, 0) } },
			track,
			{ props = { size = v2(2, 0) } },
			rightBtn,
		},
	}

	-- pushes the handle to the position matching val and updates internal state
	local function setHandlePos(val)
		sliderState.value = util.clamp(val, 0, maxValue)
		handle.props.position = v2(valueToPos(sliderState.value), 0)
	end

	return wrapper, setHandlePos
end

-- vanilla bordered button with hover tint; returns (layout, setText)
local function buildVanillaButton(text, onClick, getRefreshHost)
	local label = {
		template = I.MWUI.templates.textNormal,
		props = {
			text = text,
		},
	}
	local layout = {
		template = I.MWUI.templates.box,
		content = ui.content {
			{
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
				},
				content = ui.content {
					{ props = { size = v2(8, 0) } },
					label,
					{ props = { size = v2(8, 0) } },
				},
			},
		},
		events = {
			focusGain = async:callback(function(_, l)
				l.content[1].content[2].props.textColor = util.color.commaString(core.getGMST('FontColor_color_normal_over'))
				local host = getRefreshHost and getRefreshHost()
				if host then host:update() end
				return true
			end),
			focusLoss = async:callback(function(_, l)
				l.content[1].content[2].props.textColor = util.color.commaString(core.getGMST('FontColor_color_normal'))
				local host = getRefreshHost and getRefreshHost()
				if host then host:update() end
				return true
			end),
			mousePress = async:callback(function(e)
				if e.button ~= 1 then return end
				ambient.playSound('menu click')
			end),
			mouseRelease = async:callback(function(e)
				if e.button ~= 1 then return end
				if onClick then onClick() end
			end),
		},
	}
	local function setText(newText)
		label.props.text = newText
	end
	return layout, setText
end

function Investment.showDialogVanilla(merchant)
	if dialogWindow then destroyDialog() end
	if not merchant then return end
	if not isInvestTarget(merchant) then return end

	cachedMerchant = merchant
	currentAmount = 0
	currentText = '0'

	local record = getRecord(merchant)
	local npcName = (record and record.name) or 'Merchant'
	local forcedGold = (saveData.forcedTradeGold and saveData.forcedTradeGold[getNpcId(merchant)]) or 0
	local baseGold = ((record and record.baseGold) or 0) + forcedGold
	local invested = getInvested(merchant)
	local playerGold = getPlayerGold()
	local maxCap = getMaxInvestment()
	local sliderMax = math.min(maxCap - invested, playerGold)

	if sliderMax <= 0 then
		ui.showMessage(playerGold <= 0 and 'You have no gold to invest.' or 'You have already invested the maximum.')
		cachedMerchant = nil
		return
	end

	local isCrtr = isCreature(merchant)

	-- info string with effective-investment hint
	local infoStr = 'Merchant gold: ' .. baseGold
	if invested > 0 then
		local effInv = effectiveInvest(invested)
		if effInv < invested then
			infoStr = infoStr .. '  (+' .. effInv .. ' from ' .. invested .. ' invested)'
		else
			infoStr = infoStr .. '  (+' .. invested .. ' invested)'
		end
	end

	-- forward declarations for closure access
	local sliderLayout
	local setHandlePos
	local valueText
	local dispText

	local function refreshHandlePos()
		if setHandlePos then
			setHandlePos(currentAmount)
		end
	end

	local function refreshDisp()
		local parts = {}
		if currentAmount > 0 then
			local eff = effectiveInvest(currentAmount)
			if eff < currentAmount then
				table.insert(parts, 'Merchant gains: ' .. eff)
			end
		end
		if not isCrtr then
			local disp = calcDisposition(currentAmount)
			if currentAmount > 0 and disp > 0 then
				table.insert(parts, 'Disposition +' .. disp)
			end
		end
		dispText.props.text = table.concat(parts, '   ')
	end

	local function setAmount(newVal)
		currentAmount = util.clamp(math.floor(newVal + 0.5), 0, sliderMax)
		currentText = tostring(currentAmount)
		valueText.props.text = currentText
		refreshHandlePos()
		refreshDisp()
		if dialogWindow then dialogWindow:update() end
	end

	-- value text edit (digits only)
	valueText = {
		template = I.MWUI.templates.textEditLine,
		props = {
			text = currentText,
			size = v2(60, 0),
		},
	}
	valueText.events = {
		textChanged = async:callback(function(newText, elem)
			local digits = newText:gsub('[^%d]', '')
			local v = tonumber(digits) or 0
			currentAmount = util.clamp(v, 0, sliderMax)
			currentText = tostring(currentAmount)
			elem.props.text = currentText
			refreshHandlePos()
			refreshDisp()
			if dialogWindow then dialogWindow:update() end
		end),
		focusLoss = async:callback(function()
			valueText.props.text = currentText
			if dialogWindow then dialogWindow:update() end
		end),
		keyPress = async:callback(function(data)
			if data.code == input.KEY.Enter or data.code == input.KEY.NP_Enter then
				doInvest()
			elseif data.code == input.KEY.Escape then
				destroyDialog()
			end
		end),
	}

	-- disposition / efficiency hint line
	dispText = {
		template = I.MWUI.templates.textNormal,
		props = {
			text = '',
		},
	}

	-- slider (1% step minimum)
	local sliderStep = math.max(1, math.floor(sliderMax / 25))
	sliderLayout, setHandlePos = buildVanillaSlider(sliderMax, sliderStep, function(v)
		setAmount(v)
	end)

	-- header
	local header = {
		template = I.MWUI.templates.textHeader,
		props = {
			text = 'Invest in ' .. npcName,
		},
	}

	-- merchant gold info line
	local merchantInfo = {
		template = I.MWUI.templates.textNormal,
		props = {
			text = infoStr,
		},
	}

	-- player gold info line
	local playerInfo = {
		template = I.MWUI.templates.textNormal,
		props = {
			text = 'Your gold: ' .. playerGold,
		},
	}

	-- amount display row: [value box]   / sliderMax
	local valueRow = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			-- amount box
			{
				template = I.MWUI.templates.box,
				content = ui.content {
					{
						template = I.MWUI.templates.padding,
						content = ui.content { valueText },
					},
				},
			},
			{ props = { size = v2(8, 0) } },
			-- max indicator
			{
				template = I.MWUI.templates.textNormal,
				props = {
					text = '/ ' .. sliderMax,
				},
			},
		},
	}

	-- button row: [Invest] [Cancel]
	local function host() return dialogWindow end
	local investBtn, setInvestText = buildVanillaButton('Invest', function() doInvest() end, host)
	local cancelBtn = buildVanillaButton('Cancel', function() destroyDialog() end, host)
	local btnRow = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			investBtn,
			{ props = { size = v2(8, 0) } },
			cancelBtn,
		},
	}

	-- swap label to "Invest [Y]" when gamepad has been recently active
	local function refreshInvestLabel()
		setInvestText(gamepad.wasRecentlyActive(60) and 'Invest [Y]' or 'Invest')
		if dialogWindow then dialogWindow:update() end
	end

	-- main vertical stack
	local layout = {
		type = ui.TYPE.Flex,
		props = {
			arrange = ui.ALIGNMENT.Center,
			align = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			header,
			{ props = { size = v2(0, 8) } },
			merchantInfo,
			playerInfo,
			{ props = { size = v2(0, 8) } },
			sliderLayout,
			{ props = { size = v2(0, 4) } },
			valueRow,
			{ props = { size = v2(0, 4) } },
			dispText,
			{ props = { size = v2(0, 8) } },
			btnRow,
		},
	}

	-- gamepad: dpad nudges value, Y confirms
	gamepadHandler = function(id, isRepeat)
		if not dialogWindow then return end
		if id == input.CONTROLLER_BUTTON.DPadLeft then
			setAmount(currentAmount - sliderStep)
		elseif id == input.CONTROLLER_BUTTON.DPadRight then
			setAmount(currentAmount + sliderStep)
		elseif id == input.CONTROLLER_BUTTON.Y and not isRepeat then
			doInvest()
			return
		end
		refreshInvestLabel()
	end
	gamepad.register(gamepadHandler)

	-- modal window (centered, thick borders, solid bg)
	dialogWindow = ui.create {
		layer = 'Windows',
		name = 'mapInvestVanilla',
		template = I.MWUI.templates.boxSolidThick,
		props = {
			anchor = v2(0.5, 0.5),
			relativePosition = v2(0.5, 0.5),
		},
		content = ui.content {
			{
				template = I.MWUI.templates.padding,
				content = ui.content {
					{
						type = ui.TYPE.Flex,
						props = {
							arrange = ui.ALIGNMENT.Center,
							align = ui.ALIGNMENT.Center,
						},
						content = ui.content {
							{ props = { size = v2(0, 6) } },
							{
								type = ui.TYPE.Flex,
								props = {
									horizontal = true,
								},
								content = ui.content {
									{ props = { size = v2(8, 0) } },
									layout,
									{ props = { size = v2(8, 0) } },
								},
							},
							{ props = { size = v2(0, 6) } },
						},
					},
				},
			},
		},
	}

	-- show [Y] label on button
	refreshInvestLabel()
end

function Investment.closeDialog()
	destroyDialog()
end

function Investment.isDialogOpen()
	return dialogWindow ~= nil
end

-- barter window button
function Investment.hookBarterButton(barterControls, tradeWindow)
	if not barterControls or not barterControls.content then return end
	if barterControls.userData and barterControls.userData._mapInvestAdded then return end
	
	if not Investment.canInvest(tradeWindow and tradeWindow.target) then 
		barterControls.userData = barterControls.userData or {}
		barterControls.userData._mapInvestAdded = true
		return 
	end
	
	local ctx = tradeWindow and tradeWindow.ctx
	
	--local tw = I.InventoryExtender.getWindow('Trade')
	--local m = tw and tw.target
	--if m and isInvestTarget(m) then
	--	local invested = getInvested(tw.target)
	--	local playerGold = getPlayerGold()
	--	local maxCap = getMaxInvestment()
	--	if playerGold <= 0 then
	--		return -- You don't have any gold
	--	elseif invested >= maxCap then
	--		return -- Can't invest any more gold
	--	end
	--else
	--	barterControls.userData = barterControls.userData or {}
	--	barterControls.userData._mapInvestAdded = true
	--	return
	--end
	
	barterControls.userData = barterControls.userData or {}
	barterControls.userData._mapInvestAdded = true
	
	barterControls.content:add(baseTemplates.intervalH(4))
	-- invest button
	barterControls.content:add(specialTemplates.interactive({
		onClick = function()
			local tw = I.InventoryExtender.getWindow('Trade')
			local m = tw and tw.target
			if m and isInvestTarget(m) then
				local invested = getInvested(tw.target)
				local playerGold = getPlayerGold()
				local maxCap = getMaxInvestment()
				if playerGold <= 0 then
					ui.showMessage("You don't have any gold")
				elseif invested >= maxCap then
					ui.showMessage("Can't invest any more gold")
				else
					Investment.showDialog(m)
				end
			end
		end,
	}, baseTemplates.button('Invest'), ctx))
end

function Investment.init(sd)
	saveData = sd
	saveData.investments     = saveData.investments     or {}
	saveData.forcedTradeGold = saveData.forcedTradeGold or {}
	saveData.lastApplied     = saveData.lastApplied     or {}
end

function Investment.canInvest(merchant)
	if not S_ENABLE_INVESTMENT then return false end
	if merchant and isCreature(merchant) and not S_INVEST_CREATURES then
		return false
	end
	local threshold = S_INVESTMENT_THRESHOLD or 75
	if threshold <= 0 then return true end
	return self.type.stats.skills.mercantile(self).modified >= threshold
end

-- when entering barter mode, increase barter gold by past investment sand forced bonus
function Investment.onEnterBarter(merchant)
    if not merchant then return end
    if not isInvestTarget(merchant) then return end
	
    local id = getNpcId(merchant)
    local invested   = getInvested(merchant)
    local forcedGold = (saveData.forcedTradeGold and saveData.forcedTradeGold[id]) or 0
    -- forced trade gold is unaffected; only the invested portion is scaled
    local totalBonus = effectiveInvest(invested) + forcedGold
    if totalBonus <= 0 then return end
	
    local now = core.getGameTime()
    local delay = (core.getGMST('fBarterGoldResetDelay') or 24) * 3600
    local lastApplied = saveData.lastApplied[id]
    if lastApplied and (now - lastApplied) < delay then return end
	
    saveData.lastApplied[id] = now
	
    core.sendGlobalEvent('MAP_ApplyInvestment', {
        merchant   = merchant,
        investment = totalBonus,
    })
	
	local framesPassed = 0
    G_onFrameJobs['investRefresh'] = function()
		framesPassed = framesPassed + 1
		if framesPassed > 11 then
			local IE = I.InventoryExtender
			if IE then
				local tw = IE.getWindow('Trade')
				if tw and tw.infoBar then tw.infoBar.layout.userData.updateAll() end
				local iw = IE.getWindow('Inventory')
				if iw and iw.infoBar then iw.infoBar.layout.userData.updateAll() end
			end
			G_onFrameJobs['investRefresh'] = nil
		end
	end
end

function Investment.onLeaveBarter()
	if dialogWindow then destroyDialog() end
end

return Investment

-- perk ideas:
-- ** Merchant Mastery - Sell items for 10/20% more

-- Bribery - Can bribe guards to lower your bounty (ignore crimes)
-- ** merchants no longer refuse to trade if you have contraband in your inventory
-- ** can sell contraband to shady characters (camonna tong, thieve's guild, creature merchants, nonhostile)
-- Fence - Can barter stolen goods with any merchant.

-- ** Kinship - Buy items for 15% less when trading with the same race / faction
-- Business Relation - Create a bond with the next merchant you speak with. Buy items for 30% less from that specific merchant.

-- ** Salesman - Can sell any type of item to any kind of merchant. allow for trading any item with any merchant (bonuses and regional and whatnot still apply)

-- ** Trade Prince - Every merchant in the world gains 1000 gold for bartering. everyone gets +500 gold when trading with you
-- ** can trade with anyone