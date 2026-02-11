--[[
╭──────────────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Tea Module                                                     │
│  Teapots for brewing heather and stoneflower tea                             │
│  F = Brew Tea (opens selection menu)                                         │
╰──────────────────────────────────────────────────────────────────────────────╯
]]

local teaTooltip = nil

-- local WATER_USAGE = 500
-- local hasEnoughWater = checkWaterInventory() >= WATER_USAGE

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Teapot Configuration                                                         │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local teapotIds = {
	["t_com_copperkettle_01"] 		= true,
	["ab_misc_comredwareteapot"]	= true,	
	["t_com_coppetteapot_01"] 		= true,
	["ab_misc_kettleceremonial"] 	= true,
	["ab_misc_debugteapot"] 		= true,
	["ab_misc_ceramicteapot01"] 	= true,
	["ab_misc_ceramicteapot01hang"] = true,
	["ab_misc_comcopperkettle01"]	= true,
	["sd_teapot_red"]				= true,
	["t_de_punavitkettle_01"]		= true,
	["t_he_blueceladonteapot_01"]	= true,	
	["t_he_greenceladonteapot_01"]	= true,	
	["t_yne_clayteapot"]		    = true,
	["t_yne_stoneteapot"]		    = true,
	["t_yne_woodenteapot_01"]		= true,
	["t_bre_pewterteapot_01"]		= true,
	["t_bre_stonewareteapot_01"]	= true,	
}

local teaIngredients = {
	tea_H 	= "ingred_heather_01",
	tea_SF 	= "ingred_stoneflower_petals_01",
}

local teacupIds = {
	["misc_com_redware_cup"]		= true,
	["misc_de_pot_redware_03"]		= true,
	["ab_misc_deceramiccup_01"] 	= true,
	["ab_misc_deceramiccup_02"] 	= true,
	["ab_misc_deceramicflask_01"] 	= true,
}

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Tea Menu State                                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local teaMenuElement = nil
local teaMenuOptions = {}
local teaMenuSelected = 0
local teaMenuProcessed = false
local teaMenuOptionPressed = false
local teaMenuTime = 0
local teaMenuPosition = nil
local teaMenuAnim = {}
local teaMenuLookingAtTeapot = false
local teaMenuCurrentTeapot = nil

local teaMenuTheme = {
	header = G_morrowindLight or util.color.rgb(0.79, 0.65, 0.38),
	normal = G_morrowindGold or util.color.rgb(0.79, 0.65, 0.38),
	normalPressed = G_morrowindPressed or util.color.rgb(0.93, 0.89, 0.79),
	disabled = util.color.rgb(0.4, 0.35, 0.25),
	baseSize = 16,
	largeSize = 18
}

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Helper Functions                                                             │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function isTeapot(object)
	if not object or not object.recordId then return false end
	if G_raycastResultType ~= "Miscellaneous" and G_raycastResultType ~= "Static" and G_raycastResultType ~= "Activator" then
		return false
	end
	local id = object.recordId:lower()
	return teapotIds[id] or false
end

local function hasIngredient(ingredientId)
	local inv = types.Actor.inventory(self)
	for _, item in ipairs(inv:getAll(types.Ingredient)) do
		if item:isValid() and item.count > 0 then
			local rec = types.Ingredient.record(item)
			if rec.id:lower() == ingredientId:lower() then
				return true
			end
		end
	end
	return false
end

local function countTeacups()
	local inv = types.Actor.inventory(self)
	local Misc = types.Miscellaneous
	local Potion = types.Potion
	local count = 0
	
	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec = Misc.record(item)
			if teacupIds[rec.id:lower()] then
				count = count + item.count
			end
		end
	end
	
	for _, item in ipairs(inv:getAll(Potion)) do
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse and saveData.reverse[item.recordId:lower()]
			if rev and teacupIds[rev.orig:lower()] then
				count = count + item.count
			end
		end
	end
	
	return count
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Tea Menu Functions                                                           │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function destroyTeaMenu()
	if teaMenuElement then
		teaMenuElement:destroy()
		teaMenuElement = nil
	end
	teaMenuOptions = {}
	teaMenuSelected = 0
	teaMenuOptionPressed = false
end

local function selectTeaOption(data)
	if I.UI.getMode() == I.UI.MODE.Interface then
		I.UI.removeMode(I.UI.MODE.Interface)
	end
	if not data or data.type == "cancel" then
		ambient.playSound("Menu Click")
		return
	end
	
	if data.type == "heather" or data.type == "stoneflower" then
		local teaType = data.type == "heather" and "tea_H" or "tea_SF"
		local objectId = teaMenuCurrentTeapot and teaMenuCurrentTeapot.id
		
		if objectId then
			core.sendGlobalEvent("SunsDusk_Tea_brewTea", {self, teaType, objectId})
		end
	end
	
	ambient.playSound("Menu Click")
end

local function focusTeaOption(_, elem)
	for _, opt in ipairs(teaMenuOptions) do
		if opt.props and opt.userData and not opt.userData.disabled then
			opt.props.textColor = teaMenuTheme.normal
		end
	end
	if elem and elem.props and elem.userData and not elem.userData.disabled then
		elem.props.textColor = teaMenuTheme.normalPressed
	end
	teaMenuSelected = elem and elem.userData and elem.userData.index or 0
	if teaMenuElement then teaMenuElement:update() end
	ambient.playSound("Menu Click")
end

local function unfocusTeaOption(_, elem)
	if elem and elem.props and elem.userData and not elem.userData.disabled then
		elem.props.textColor = teaMenuTheme.normal
	end
	teaMenuSelected = 0
	if teaMenuElement then teaMenuElement:update() end
end

local function handleTeaMenuInput()
	if not teaMenuElement or #teaMenuOptions == 0 then return end
	
	local move = 0
	local elapsed = core.getRealTime() - teaMenuTime
	
	if elapsed > 0.2 then
		move = input.getRangeActionValue("MoveBackward") - input.getRangeActionValue("MoveForward")
		move = move + input.getRangeActionValue("MoveRight") - input.getRangeActionValue("MoveLeft")
		move = move + (input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown) and 1 or 0)
		move = move - (input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp) and 1 or 0)
		move = move - input.getNumberActionValue("Zoom3rdPerson")
	elseif elapsed > 0.1 then
		move = -input.getNumberActionValue("Zoom3rdPerson")
	end
	
	if math.abs(move) > 0.9 then
		local n = #teaMenuOptions
		local newSel = teaMenuSelected < 1 and 1 or ((teaMenuSelected - 1 + (move > 0 and 1 or -1)) % n) + 1
		
		local attempts = 0
		while teaMenuOptions[newSel].userData and teaMenuOptions[newSel].userData.disabled and attempts < n do
			newSel = ((newSel - 1 + (move > 0 and 1 or -1)) % n) + 1
			attempts = attempts + 1
		end
		
		focusTeaOption(nil, teaMenuOptions[newSel])
		teaMenuTime = core.getRealTime()
	end
	
	if teaMenuSelected >= 1 and teaMenuSelected <= #teaMenuOptions then
		local selectedOpt = teaMenuOptions[teaMenuSelected]
		if input.isActionPressed(input.ACTION.Activate) then
			if teaMenuProcessed then return end
			if selectedOpt.userData and selectedOpt.userData.disabled then return end
			teaMenuProcessed = true
			teaMenuAnim = { close = true, time = core.getRealTime(), stop = 0.25 }
			selectTeaOption(selectedOpt.userData)
		end
	end
end

local function updateTeaMenuAnimation()
	if not teaMenuElement then return true end
	local m = teaMenuAnim
	if not m.open and not m.close then return end
	
	local elapsed = core.getRealTime() - m.time
	local alpha

	if elapsed < m.stop + 0.2 then
		alpha = math.min((elapsed / m.stop) ^ 2, 1)
		if m.close then 
			alpha = 1 - alpha 
		end
		teaMenuElement.layout.props.alpha = alpha
		teaMenuElement:update()
	elseif m.close then
		destroyTeaMenu()
		return true
	else
		m.open = nil
	end
end

local function makePaddedBox(opts)
	local p = opts.padding or 0
	if type(p) == "number" then p = { left = p, right = p, top = p, bottom = p } end
	return {
		type = ui.TYPE.Container,
		content = ui.content{
			{ type = ui.TYPE.Image, props = {
				relativeSize = v2(1, 1),
				resource = ui.texture{ path = "white" },
				color = opts.color or util.color.hex("000000"),
				alpha = opts.alpha or 0,
				size = v2(p.left + p.right, p.top + p.bottom)
			}},
			{ external = { slot = true }, props = { position = v2(p.left, p.top), relativeSize = v2(1, 1) } }
		}
	}
end

local function makeTeaMenuOption(index, text, optType, disabled, extraData)
	local textColor = disabled and teaMenuTheme.disabled or teaMenuTheme.normal
	
	local opt = {
		type = ui.TYPE.Text,
		userData = { index = index, type = optType, pressed = false, focussed = false, disabled = disabled },
		events = {
			mousePress = async:callback(function(_, elem)
				if teaMenuProcessed then return end
				if elem.userData.disabled then return end
				elem.userData.pressed = true
				teaMenuOptionPressed = true
				elem.userData.focussed = true
			end),
			mouseRelease = async:callback(function(_, elem)
				if teaMenuProcessed then return end
				if elem.userData.disabled then return end
				if elem.userData.pressed then
					local data = elem.userData
					local clickId = "teaMenuClick_" .. math.random()
					G_onFrameJobs[clickId] = function()
						G_onFrameJobs[clickId] = nil
						if teaMenuProcessed then return end
						if not data.focussed then
							data.pressed = false
							data.focussed = false
							teaMenuOptionPressed = false
							unfocusTeaOption(_, elem)
							return
						end
						teaMenuProcessed = true
						teaMenuAnim = { close = true, time = core.getRealTime(), stop = 0.25 }
						selectTeaOption(data)
						if I.UI.getMode() == I.UI.MODE.Interface then
							I.UI.removeMode(I.UI.MODE.Interface)
						end
					end
				end
				elem.userData.pressed = false
				teaMenuOptionPressed = false
			end),
			focusGain = async:callback(function(_, elem)
				if teaMenuProcessed then return end
				if elem.userData.disabled then return end
				focusTeaOption(_, elem)
				elem.userData.focussed = true
			end),
			focusLoss = async:callback(function(_, elem)
				if teaMenuProcessed then return end
				elem.userData.pressed = false
				elem.userData.focussed = false
				teaMenuOptionPressed = false
				unfocusTeaOption(_, elem)
			end)
		},
		props = {
			text = text,
			textAlign = ui.ALIGNMENT.Center,
			textColor = textColor,
			textSize = teaMenuTheme.largeSize
		}
	}
	if extraData then
		for k, v in pairs(extraData) do opt.userData[k] = v end
	end
	teaMenuOptions[index] = opt
	return { template = I.MWUI.templates.padding, alignment = ui.ALIGNMENT.Center, content = ui.content{ opt } }
end

local function createTeaMenu()
	if teaMenuElement then destroyTeaMenu() end
	
	teaMenuOptions = {}
	teaMenuSelected = 0
	teaMenuTime = core.getRealTime()
	teaMenuAnim = { time = core.getRealTime(), open = true, stop = 0.25 }
	teaMenuProcessed = false
	
	if I.uiTweaks then I.uiTweaks.skipSounds(I.UI.MODE.Interface) end
	I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
	core.sendGlobalEvent("SunsDusk_unPauseUI")
	
	local optionsContent = {{
		type = ui.TYPE.Container,
		content = ui.content{{ type = ui.TYPE.Image, props = { resource = ui.texture{ path = "white" }, alpha = 0, size = v2(12, 12) } }}
	}}
	
	local idx = 1
	local cupCount = countTeacups()
	local hasTeacupItem = cupCount > 0
	
	-- Heather Tea option
	local hasHeather = hasIngredient(teaIngredients.tea_H)
	local heatherDisabled = not hasHeather or not hasTeacupItem
	local heatherName = localizedLiquidNames and localizedLiquidNames["tea_H"] or "Heather Tea"
	local heatherText = heatherName
	if not hasHeather then
		heatherText = heatherText .. " (need heather)"
	elseif not hasTeacupItem then
		heatherText = heatherText .. " (need teacup)"
	end
	optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, heatherText, "heather", heatherDisabled)
	idx = idx + 1
	
	-- Stoneflower Tea option
	local hasStoneflower = hasIngredient(teaIngredients.tea_SF)
	local stoneflowerDisabled = not hasStoneflower or not hasTeacupItem
	local stoneflowerName = localizedLiquidNames and localizedLiquidNames["tea_SF"] or "Stoneflower Tea"
	local stoneflowerText = stoneflowerName
	if not hasStoneflower then
		stoneflowerText = stoneflowerText .. " (need stoneflower)"
	elseif not hasTeacupItem then
		stoneflowerText = stoneflowerText .. " (need teacup)"
	end
	optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, stoneflowerText, "stoneflower", stoneflowerDisabled)
	idx = idx + 1
	
	-- Cancel option
	optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, "Cancel", "cancel", false)
	
	local pos = teaMenuPosition or v2(G_hudLayerSize.x * 0.5, G_hudLayerSize.y * 0.5)
	
	teaMenuElement = ui.create{
		layer = "Windows",
		template = makePaddedBox{ alpha = 0.5, padding = 2, color = util.color.hex("000000") },
		props = { position = pos, anchor = v2(0.5, 0.5), align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center, alpha = 0.0 },
		content = ui.content{{
			template = makePaddedBox{ alpha = 0.0, padding = { left = 32, right = 32, top = 12, bottom = 12 } },
			content = ui.content{{
				type = ui.TYPE.Flex,
				props = { horizontal = false, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
				content = ui.content{
					{ type = ui.TYPE.Flex, props = { horizontal = false, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
						content = ui.content{{ template = I.MWUI.templates.padding, alignment = ui.ALIGNMENT.Center,
							content = ui.content{{ type = ui.TYPE.Text, props = { text = "Choose tea to brew:", multiline = true, textAlignH = ui.ALIGNMENT.Center, textColor = teaMenuTheme.header, textSize = teaMenuTheme.baseSize } }}
						}}
					},
					{ type = ui.TYPE.Flex, props = { horizontal = false, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Start },
						content = ui.content(optionsContent)
					}
				}
			}}
		}}
	}
	
	-- Drag functionality
	teaMenuElement.layout.userData = { isDragging = false, potentialDrag = false }
	teaMenuElement.layout.events = {
		mousePress = async:callback(function(data, elem)
			if not teaMenuOptionPressed then
				elem.userData.potentialDrag = true
				elem.userData.dragStart = data.position
				elem.userData.origPos = teaMenuElement.layout.props.position
			end
		end),
		mouseMove = async:callback(function(data, elem)
			if elem.userData.potentialDrag then
				local delta = data.position - elem.userData.dragStart
				if delta:length() > 5 then
					elem.userData.isDragging = true
				end
			end
			if elem.userData.isDragging then
				local delta = data.position - elem.userData.dragStart
				teaMenuElement.layout.props.position = elem.userData.origPos + delta
				teaMenuElement:update()
			end
		end),
		mouseRelease = async:callback(function(data, elem)
			if elem.userData.isDragging then
				teaMenuPosition = teaMenuElement.layout.props.position
			end
			elem.userData.isDragging = false
			elem.userData.potentialDrag = false
		end)
	}
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Tooltip Functions                                                            │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function alignAxis(value)
	local center = 0.5
	local threshold = 0.01
	local dist = math.abs(value - center)
	local t = math.min(dist / threshold, 1)
	if value > center then
		return 0.5 - (t * 0.5)
	else
		return 0.5 + (t * 0.5)
	end
end

local function alignAnchor(pos)
	local alignedX = alignAxis(pos.x)
	local alignedY = alignAxis(pos.y)
	return v2(alignedX, alignedY)
end

local function destroyTeaTooltip()
	if teaTooltip then
		teaTooltip:destroy()
		teaTooltip = nil
	end
end

local function createTeaTooltip()
	destroyTeaTooltip()
	
	if not I.UI.isHudVisible() then return end
	
	local anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100))
	
	local validIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
	validIconHsv[2] = validIconHsv[2]*0.6
	validIconHsv[3] = math.min(1, validIconHsv[3]*1.8)
	local iconColor = util.color.rgb(hsvToRgb(validIconHsv[1], validIconHsv[2], validIconHsv[3]))
	
	teaTooltip = ui.create({
		layer = 'Scene',
		name = "teaTooltip",
		type = ui.TYPE.Flex,
		props = {
			relativePosition = v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100),
			anchor = anchor,
			horizontal = true,
			autoSize = true,
			arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
		},
		content = ui.content{
			{
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/f.dds"),
					tileH = false,
					tileV = false,
					size  = v2(WORLD_TOOLTIP_ICON_SIZE, WORLD_TOOLTIP_ICON_SIZE),
					alpha = 0.6,
					color = iconColor,
				}
			},
			{
				type = ui.TYPE.Text,
				props = {
					text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "").."Brew Tea",
					textColor = WORLD_TOOLTIP_FONT_COLOR,
					textShadow = true,
					textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
					alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
				}
			}
		}
	})
	
	return teaTooltip
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Raycast Changed                                                              │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function raycastChanged()
	if not NEEDS_TEA then return end
	if teaMenuElement then return end
	
	local hitObject = G_raycastResult and G_raycastResult.hitObject
	local lookingAtTeapot = hitObject and isTeapot(hitObject)
	
	if lookingAtTeapot and I.UI.isHudVisible() and not saveData.playerInfo.isInWerewolfForm then
		if not teaMenuLookingAtTeapot or teaMenuCurrentTeapot ~= hitObject then
			teaMenuLookingAtTeapot = true
			teaMenuCurrentTeapot = hitObject
			
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false)
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
			
			createTeaTooltip()
		end
	elseif teaMenuLookingAtTeapot then
		teaMenuLookingAtTeapot = false
		teaMenuCurrentTeapot = nil
		destroyTeaTooltip()
		
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
	end
end

table.insert(G_raycastChangedJobs, raycastChanged)
table.insert(G_refreshWidgetJobs, raycastChanged)

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Input Handler                                                                │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
	if not NEEDS_TEA then return end
	if teaMenuElement then return end
	
	if teaTooltip and teaMenuCurrentTeapot then
		createTeaMenu()
	end
end))

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Frame Update                                                                 │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function teaMenuFrameUpdate()
	if teaMenuElement then
		handleTeaMenuInput()
	end
	updateTeaMenuAnimation()
end

G_UiModeChangedJobs.teaMenuModeChanged = function(data)
	if teaMenuElement and data.newMode ~= I.UI.MODE.Interface and not (teaMenuAnim and teaMenuAnim.close) then
		destroyTeaMenu()
	end
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Event Handlers                                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function teaBrewingCompleted(data)
	local replaced = data.replaced or 0
	local teaType = data.teaType
	local liquidName = localizedLiquidNames and localizedLiquidNames[teaType] or "tea"
	
	if replaced > 0 then
		ambient.playSound("item potion up")
		messageBox(3, "Brewed " .. tostring(replaced) .. " teacup" .. (replaced > 1 and "s" or "") .. " of " .. liquidName)
	else
		messageBox(2, "No teacups could be filled")
	end
end

G_eventHandlers.SunsDusk_Tea_brewingCompleted = teaBrewingCompleted

local function teaPlayBrewingSound()
	ambient.playSoundFile("sound/Fx/enviro/bubblevnt.wav")
	messageBox(3, "Brewing tea...")
end

G_eventHandlers.SunsDusk_Tea_playBrewingSound = teaPlayBrewingSound

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Initialization                                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function onLoad()
	if not NEEDS_TEA then return end
	if not saveData.m_tea then
		saveData.m_tea = {}
	end
end

table.insert(G_onLoadJobs, onLoad)

G_onFrameJobsSluggish.teaMenuUpdate = teaMenuFrameUpdate

log(3, "[SunsDusk:Tea] Tea module loaded successfully")