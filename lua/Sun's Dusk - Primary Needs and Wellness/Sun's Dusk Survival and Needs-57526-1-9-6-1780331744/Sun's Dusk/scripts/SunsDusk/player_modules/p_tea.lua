-- Tea Module
--Teapot Configuration

-- meshes from G_teapotIds/G_coffeePotIds at load -buildBrewingVesselMeshes

local teapotMeshes = {}
local coffeePotMeshes = {}

local function buildBrewingVesselMeshes()
	for id in pairs(G_teapotIds) do
		local ok, rec = pcall(types.Miscellaneous.record, id)
		if ok and rec and rec.model then
			teapotMeshes[rec.model:lower()] = true
		end
	end
	for id in pairs(G_coffeePotIds) do
		local ok, rec = pcall(types.Miscellaneous.record, id)
		if ok and rec and rec.model then
			coffeePotMeshes[rec.model:lower()] = true
		end
	end
end

-- ======================================
-- Tea Menu State
-- ======================================

local teaMenuElement = nil
local teaMenuOptions = {}
local teaMenuSelected = 0
local teaMenuProcessed = false
local teaMenuOptionPressed = false
local teaMenuTime = 0
local teaMenuPosition = nil
local teaMenuAnim = {}
local teaMenuCurrentTeapot = nil

local teaMenuTheme = {
	header = G_morrowindLight or util.color.rgb(0.79, 0.65, 0.38),
	normal = G_morrowindGold or util.color.rgb(0.79, 0.65, 0.38),
	normalPressed = G_morrowindPressed or util.color.rgb(0.93, 0.89, 0.79),
	disabled = util.color.rgb(0.4, 0.35, 0.25),
	baseSize = 16,
	largeSize = 18
}

-- ======================================
-- Helper Functions
-- ======================================

local function hasIngredient(ingredientId)
	return typesActorInventorySelf:find(ingredientId)
end

-- ======================================
-- Tea Menu Functions
-- ======================================

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
	-- specialty: close menu/mode this frame, wait several frames before opening crafting framework
	if data and data.type == "specialty" then
		if I.UI.getMode() == I.UI.MODE.Interface then
			I.UI.removeMode(I.UI.MODE.Interface)
		end
		ambient.playSound("Menu Click")
		-- frame countdown lets the close anim and ui teardown settle before crafting framework opens
		local framesLeft = 2
		local jobId = "teaMenuSpecialty_" .. math.random()
		G_onFrameJobs[jobId] = function()
			framesLeft = framesLeft - 1
			if framesLeft > 0 then return end
			G_onFrameJobs[jobId] = nil
			self:sendEvent("CraftingFramework_openCraftingWindow", "Brew Tea")
		end
		return
	end
	
	if I.UI.getMode() == I.UI.MODE.Interface then
		I.UI.removeMode(I.UI.MODE.Interface)
	end
	if not data or data.type == "cancel" then
		ambient.playSound("Menu Click")
		return
	end
	
	if data.type == "heather" or data.type == "stoneflower" then
		local teaType = data.type == "heather" and "tea_H" or "tea_SF"
		
		-- gather teacups fresh; getActions already guaranteed at least one
		local cups = {}
		for _, item in ipairs(typesActorInventorySelf:getAll(types.Miscellaneous)) do
			if item:isValid() and item.count > 0 and G_teacupIds[item.recordId] then
				table.insert(cups, item)
			end
		end
		
		core.sendGlobalEvent("SunsDusk_Tea_brewSimple", {
			player  = self,
			teapot  = teaMenuCurrentTeapot,
			teaType = teaType,
			cupRefs = cups,
		})
		ambient.playSoundFile("sound/sunsdusk/cooking.ogg", {volume = 1.0})
		G_refreshTooltips()
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
			{ 
				type = ui.TYPE.Image, 
				props = {
					relativeSize = v2(1, 1),
					resource = ui.texture{ path = "white" },
					color = opts.color or util.color.hex("000000"),
					alpha = opts.alpha or 0,
					size = v2(p.left + p.right, p.top + p.bottom)
				}
			},
			{ 
				external = { slot = true }, 
				props = { 
					position = v2(p.left, p.top), 
					relativeSize = v2(1, 1) 
				} 
			}
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
			textAlignH = ui.ALIGNMENT.Center,
			textColor = textColor,
			textSize = teaMenuTheme.largeSize
		}
	}
	if extraData then
		for k, v in pairs(extraData) do opt.userData[k] = v end
	end
	teaMenuOptions[index] = opt
	return { 
		template = I.MWUI.templates.padding, 
		--alignment = ui.ALIGNMENT.Center, 
		content = ui.content{ opt } 
	}
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
	
	-- heather
	if hasIngredient(G_teaIngredients.tea_H) then
		local heatherName = localizedLiquidNames and localizedLiquidNames["tea_H"] or "Heather Tea"
		optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, heatherName, "heather", false)
		idx = idx + 1
	end
	
	-- stoneflower
	if hasIngredient(G_teaIngredients.tea_SF) then
		local stoneflowerName = localizedLiquidNames and localizedLiquidNames["tea_SF"] or "Stoneflower Tea"
		optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, stoneflowerName, "stoneflower", false)
		idx = idx + 1
	end
	
	-- specialty teas via Crafting Framework (always shown when available)
	if I.CraftingFramework and G_CEREMONIAL_TEA_INSTALLED then
		optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, "Ceremonial Tea", "specialty", false)
		idx = idx + 1
	end
	
	-- cancel
	optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, "Cancel", "cancel", false)
	
	local pos = teaMenuPosition or v2(G_hudLayerSize.x * 0.5, G_hudLayerSize.y * 0.5)
	
	teaMenuElement = ui.create{
		layer = "Windows",
		template = makePaddedBox{ alpha = 0.5, padding = 2, color = util.color.hex("000000") },
		props = {
			position = pos,
			anchor = v2(0.5, 0.5),
			alpha = 0.0
		},
		content = ui.content{
			{
				template = makePaddedBox{ alpha = 0.0, padding = { left = 32, right = 32, top = 12, bottom = 12 } },
				content = ui.content{
					{
						type = ui.TYPE.Flex,
						props = { 
							horizontal = false,
							align = ui.ALIGNMENT.Center,
							arrange = ui.ALIGNMENT.Center 
						},
						content = ui.content{
							{
								type = ui.TYPE.Flex,
								props = {
									horizontal = false,
									align = ui.ALIGNMENT.Center,
									arrange = ui.ALIGNMENT.Center
								},
								content = ui.content{
									{
										template = I.MWUI.templates.padding,
										--alignment = ui.ALIGNMENT.Center,
										content = ui.content{
											{
												type = ui.TYPE.Text,
												props = {
													text = "Choose tea to brew:",
													multiline = true,
													textAlignH = ui.ALIGNMENT.Center,
													textColor = teaMenuTheme.header,
													textSize = teaMenuTheme.baseSize
												} 
											}
										}
									}
								}
							},
							{ 
								type = ui.TYPE.Flex, 
								props = { 
									horizontal = false, 
									align = ui.ALIGNMENT.Center, 
									arrange = ui.ALIGNMENT.Start 
								},
								content = ui.content(optionsContent)
							}
						}
					}
				}
			}
		}
	}
	
	-- drag
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
-- │ Brewing Actions                                                              │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

-- read teapot fill via the liquids name pattern; empty misc returns 0, 0
local function teapotFillMl(teapot)
	if not teapot or teapot.type ~= types.Potion then return 0, 0 end
	local rec = types.Potion.record(teapot)
	if not rec or not rec.name then return 0, 0 end
	local name = rec.name
	if name:lower():sub(-8) ~= "l water)" then return 0, 0 end
	local cur, max = name:match("%(([^/]+)/([^%s]+)")
	if not cur or not max then return 0, 0 end
	return parse_amount(cur) or 0, parse_amount(max) or 0
end

-- empty teacup misc items in the player inventory
local function scanInventoryTeacups()
	local cups = {}
	local total = 0
	for _, item in ipairs(typesActorInventorySelf:getAll(types.Miscellaneous)) do
		if item:isValid() and item.count > 0 and G_teacupIds[item.recordId] then
			table.insert(cups, item)
			total = total + item.count
		end
	end
	return cups, total
end

-- consume 250mL water, swap teapot to a filled potion record
local function handleAddWater(teapot)
	core.sendGlobalEvent("SunsDusk_Tea_addWaterToTeapot", {
		player = self,
		teapot = teapot,
		addQ   = 1,
	})
	--ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
	ambient.playSoundFile("sound/SunsDusk/pour.ogg")
	G_refreshTooltips()
end

-- open the tea selection menu; brewing happens on confirm via selectTeaOption
local function handleBrewTea(teapot)
	teaMenuCurrentTeapot = teapot
	createTeaMenu()
end

-- coffee skips the menu (no heather/stoneflower analogues); go straight to crafting framework
local function handleBrewCoffee(coffeepot)
	if not I.CraftingFramework or not G_CEREMONIAL_TEA_INSTALLED then
		messageBox(2, "Ceremonial Tea Brewing is required to brew coffee.")
		return
	end
	ambient.playSound("Menu Click")
	self:sendEvent("CraftingFramework_openCraftingWindow", "Brew Coffee")
end

-- ======================================
-- World Interaction Registration
-- ======================================

G_worldInteractions.tea = {
	canInteract = function(object, objectType)
		if not NEEDS_TEA then return false end
		if objectType ~= "Miscellaneous"
				and objectType ~= "Static"
				and objectType ~= "Activator"
				and objectType ~= "Potion" then
			return false
		end
		local rec = object.type.record(object)
		if not rec or not rec.model then return false end
		return teapotMeshes[rec.model:lower()] or false
	end,
	getActions = function(object, objectType)
		local currentMl, maxMl = teapotFillMl(object)
		local isFilled = currentMl > 0
		local atMax    = maxMl > 0 and currentMl >= maxMl
		local hasWater = checkWaterInventory() >= G_WATER_PER_CUP
		local _, teacupCount = scanInventoryTeacups()
		local actions = {}
		
		-- add water (R)
		table.insert(actions, {
			label = "Add water",
			preferred = "ToggleSpell",
			disabled = atMax or not hasWater,
			handler = handleAddWater,
			failedHandler = function()
				if atMax then
					messageBox(2, "The teapot is already full.")
				else
					messageBox(2, "You do not have any water to add to this teapot.")
				end
			end,
		})
		
		-- brew tea (F) - low priority wins F over the default Consume on filled teapot potions
		table.insert(actions, {
			label = "Brew Tea",
			preferred = "ToggleWeapon",
			priority = -10,
			disabled = not isFilled or teacupCount == 0,
			handler = handleBrewTea,
			failedHandler = function()
				if not isFilled then
					messageBox(2, "You must add water to brew tea.")
				else
					messageBox(2, "You have no tea cups to put tea in.")
				end
			end,
		})
		
		return actions
	end
}

-- coffee pot mirrors the teapot one but routes F to Brew Coffee.
-- CF profession dropdown surfaces Brew Tea too.
G_worldInteractions.coffee = {
	canInteract = function(object, objectType)
		if not NEEDS_TEA then return false end
		if not G_CEREMONIAL_TEA_INSTALLED then return false end
		if objectType ~= "Miscellaneous"
				and objectType ~= "Static"
				and objectType ~= "Activator"
				and objectType ~= "Potion" then
			return false
		end
		local rec = object.type.record(object)
		if not rec or not rec.model then return false end
		return coffeePotMeshes[rec.model:lower()] or false
	end,
	getActions = function(object, objectType)
		local currentMl, maxMl = teapotFillMl(object)
		local isFilled = currentMl > 0
		local atMax    = maxMl > 0 and currentMl >= maxMl
		local hasWater = checkWaterInventory() >= G_WATER_PER_CUP
		local _, teacupCount = scanInventoryTeacups()
		local actions = {}
		
		-- add water (R)
		table.insert(actions, {
			label = "Add water",
			preferred = "ToggleSpell",
			disabled = atMax or not hasWater,
			handler = handleAddWater,
			failedHandler = function()
				if atMax then
					messageBox(2, "The coffee pot is already full.")
				else
					messageBox(2, "You do not have any water to add to this coffee pot.")
				end
			end,
		})
		
		-- brew coffee (F) - low priority wins F over the default Consume on filled coffee pots
		table.insert(actions, {
			label = "Brew Coffee",
			preferred = "ToggleWeapon",
			priority = -10,
			disabled = not isFilled or teacupCount == 0,
			handler = handleBrewCoffee,
			failedHandler = function()
				if not isFilled then
					messageBox(2, "You must add water to brew coffee.")
				else
					messageBox(2, "You have no tea cups to put coffee in.")
				end
			end,
		})
		
		return actions
	end
}

-- ======================================
-- Frame Update
-- ======================================

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

-- ======================================
-- Event Handlers
-- ======================================

local function teaBrewingCompleted(data)
	local replaced = data.replaced or 0
	local teaType = data.teaType
	local liquidName = localizedLiquidNames and localizedLiquidNames[teaType] or "tea"
	
	if replaced > 0 then
		ambient.playSound("item potion up")
		messageBox(3, "Brewed " .. tostring(replaced) .. " teacup" .. (replaced > 1 and "s" or "") .. " of " .. liquidName)
		I.SkillProgression.skillUsed("alchemy", {
			skillGain = 0.5,
			useType = I.SkillProgression.SKILL_USE_TYPES.Alchemy_CreatePotion,
		})
		if I.SkillFramework then
			I.SkillFramework.skillUsed("sunsdusk_cooking", { skillGain = 0.5 })
		end
	else
		messageBox(2, "No teacups could be filled")
	end
end

G_eventHandlers.SunsDusk_Tea_brewingCompleted = teaBrewingCompleted

local function teaBrewingFailed(data)
	local reason = data.reason or "Unknown error"
	messageBox(2, "Brewing failed: " .. reason)
end

G_eventHandlers.SunsDusk_Tea_brewingFailed = teaBrewingFailed

local function teaPlayBrewingSound()
	ambient.playSoundFile("sound/sunsdusk/cooking.ogg", {volume = 1.0})
	messageBox(3, "Brewing tea...")
end

G_eventHandlers.SunsDusk_Tea_playBrewingSound = teaPlayBrewingSound

-- ======================================
-- Init
-- ======================================

local function onLoad()
	if not NEEDS_TEA then return end
	buildBrewingVesselMeshes()
	if not saveData.m_tea then
		saveData.m_tea = {}
	end
end

table.insert(G_onLoadJobs, onLoad)

G_onFrameJobsSluggish.teaMenuUpdate = teaMenuFrameUpdate

-- only happens with tea items currently
G_eventHandlers.SunsDusk_consumedWithTimestamp = function(data)
	local tempData = saveData.m_temp
	if not tempData then return end
	local item = data.item
	local ageInHours = (core.getGameTime() - data.timestamp) / 3600
	
	if ageInHours <= 3 then
		tempData.currentTemp = tempData.currentTemp + math.min(5, math.max(0, 24 - tempData.currentTemp))
		tempData.stewDuration = 120
		tempData.stewMagnitude = 5
	end
end