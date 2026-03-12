--[[
╭──────────────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Tea Module                                                     │
│  Teapots for brewing heather and stoneflower tea                             │
│  F = Brew Tea (opens selection menu)                                         │
╰──────────────────────────────────────────────────────────────────────────────╯
]]

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
-- │ Teacup Mesh Lookup (built once from G_teacupIds at load)                     │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local teacupMeshes = {}

local function buildTeacupMeshLookup()
	for id in pairs(G_teacupIds) do
		local ok, rec = pcall(types.Miscellaneous.record, id)
		if ok and rec and rec.model then
			teacupMeshes[rec.model:lower()] = true
		end
	end
end

local function isTeacupMesh(item)
	local rec = item.type.record(item)
	if not rec or not rec.model then return false end
	return teacupMeshes[rec.model:lower()] or false
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Combined Inventory Scan                                                      │
-- ╰──────────────────────────────────────────────────────────────────────────────╯
-- Single pass. Returns:
--   emptyTeacups    : { item, ... }         Misc teacups (by G_teacupIds)
--   waterTeacups    : { {item, ml}, ... }   Potions: water + teacup mesh
--   waterContainers : { {item, ml}, ... }   Potions: water + non-cup mesh
--   totalWaterMl    : number

local function scanTeaInventory()

	local emptyTeacups    = {}
	local waterTeacups    = {}
	local waterContainers = {}
	local totalWaterMl    = 0

	-- Misc items: empty teacups by recordId
	for _, item in ipairs(typesActorInventorySelf:getAll(types.Miscellaneous)) do
		if item:isValid() and item.count > 0 and G_teacupIds[item.recordId] then
			table.insert(emptyTeacups, item)
		end
	end

	-- Potions: detect water by name pattern "l water)", sort by mesh
	for _, item in ipairs(typesActorInventorySelf:getAll(types.Potion)) do
		if item:isValid() and item.count > 0 then
			local rec = types.Potion.record(item)
			local name = (rec.name or "")
			if name:lower():sub(-8) == "l water)" then
				local currentAmount = name:match("%(([^/]+)/")
				if currentAmount then
					local ml = parse_amount(currentAmount)
					if ml and ml > 0 then
						local isCup = isTeacupMesh(item)
						local dest = isCup and waterTeacups or waterContainers
						table.insert(dest, { item = item, ml = ml, count = item.count })
						totalWaterMl = totalWaterMl + (ml * item.count)
					end
				end
			end
		end
	end

	return emptyTeacups, waterTeacups, waterContainers, totalWaterMl
end

local lastScan = {}

local function refreshTeaScan()
	local empty, wCups, wBottles, totalMl = scanTeaInventory()
	lastScan.emptyTeacups    = empty
	lastScan.waterTeacups    = wCups
	lastScan.waterContainers = wBottles
	lastScan.totalWaterMl    = totalMl
	-- Fillable cups = empty cups + water cups (water gets replaced by tea)
	local fillable = 0
	for _, item in ipairs(empty) do fillable = fillable + item.count end
	for _, e in ipairs(wCups) do fillable = fillable + e.count end
	lastScan.fillableCups = fillable
	return lastScan
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Helper Functions                                                             │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function hasIngredient(ingredientId)
	return typesActorInventorySelf:find(ingredientId)
end

local function hasAnyTeaIngredient()
	for _, ingredientId in pairs(G_teaIngredients) do
		if hasIngredient(ingredientId) then
			return true
		end
	end
	return false
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Brew Request (player → global with object refs)                              │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function requestBrew(teaType, teapotObject)
	local scan = refreshTeaScan()

	local cupsToBrew    = math.min(scan.fillableCups, G_CUPS_PER_BREW)
	local fromWaterCups = 0
	for _, e in ipairs(scan.waterTeacups) do fromWaterCups = fromWaterCups + e.count end
	fromWaterCups       = math.min(cupsToBrew, fromWaterCups)
	local fromEmptyCups = cupsToBrew - fromWaterCups
	local externalWaterNeeded = fromEmptyCups * G_WATER_PER_CUP

	-- Bottle water available
	local bottleMl = 0
	for _, e in ipairs(scan.waterContainers) do bottleMl = bottleMl + e.ml * e.count end

	if cupsToBrew == 0 then
		messageBox(2, "No teacups to fill")
		return
	end
	if bottleMl < externalWaterNeeded then
		messageBox(2, "Not enough water")
		return
	end

	-- Build ref lists, trimmed to what we'll actually use
	local waterCupRefs = {}
	local remaining = fromWaterCups
	for _, e in ipairs(scan.waterTeacups) do
		if remaining <= 0 then break end
		table.insert(waterCupRefs, e.item)
		remaining = remaining - e.count
	end

	local emptyCupRefs = {}
	remaining = fromEmptyCups
	for _, item in ipairs(scan.emptyTeacups) do
		if remaining <= 0 then break end
		table.insert(emptyCupRefs, item)
		remaining = remaining - item.count
	end

	core.sendGlobalEvent("SunsDusk_Tea_brewTea", {
		self,                                      -- [1] player
		teaType,                                   -- [2] tea type
		teapotObject and teapotObject.id or nil,   -- [3] teapot objectId
		waterCupRefs,                              -- [4] teacup potions holding water
		emptyCupRefs,                              -- [5] empty teacup misc items
		externalWaterNeeded,                       -- [6] ml to draw from bottles
	})
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
		requestBrew(teaType, teaMenuCurrentTeapot)
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
	local scan = refreshTeaScan()
	local hasTeacupItem = scan.fillableCups >= 2
	local totalWater = scan.totalWaterMl
	local waterNeeded = G_CUPS_PER_BREW * G_WATER_PER_CUP
	local hasWater = totalWater >= waterNeeded
	
	-- Heather Tea option
	local hasHeather = hasIngredient(G_teaIngredients.tea_H)
	local heatherDisabled = not hasHeather or not hasTeacupItem or not hasWater
	local heatherName = localizedLiquidNames and localizedLiquidNames["tea_H"] or "Heather Tea"
	local heatherText = heatherName
	if not hasHeather then
		heatherText = heatherText .. " (need heather)"
	elseif not hasTeacupItem then
		heatherText = heatherText .. " (need teacup)"
	elseif not hasWater then
		heatherText = heatherText .. " (need water)"
	end
	optionsContent[#optionsContent + 1] = makeTeaMenuOption(idx, heatherText, "heather", heatherDisabled)
	idx = idx + 1
	
	-- Stoneflower Tea option
	local hasStoneflower = hasIngredient(G_teaIngredients.tea_SF)
	local stoneflowerDisabled = not hasStoneflower or not hasTeacupItem or not hasWater
	local stoneflowerName = localizedLiquidNames and localizedLiquidNames["tea_SF"] or "Stoneflower Tea"
	local stoneflowerText = stoneflowerName
	if not hasStoneflower then
		stoneflowerText = stoneflowerText .. " (need stoneflower)"
	elseif not hasTeacupItem then
		stoneflowerText = stoneflowerText .. " (need teacup)"
	elseif not hasWater then
		stoneflowerText = stoneflowerText .. " (need water)"
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
-- │ World Interaction Registration                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

G_worldInteractions.tea = {
	canInteract = function(object, objectType)
		if not NEEDS_TEA then return false end
		if objectType ~= "Miscellaneous" and objectType ~= "Static" and objectType ~= "Activator" then
			return false
		end
		return teapotIds[object.recordId] or false
	end,
	getActions = function(object, objectType)
		local scan = refreshTeaScan()
		local waterNeeded = G_CUPS_PER_BREW * G_WATER_PER_CUP
		local hasWater = scan.totalWaterMl >= waterNeeded
		local hasTeacups = scan.fillableCups >= 2
		local hasIngredients = hasAnyTeaIngredient()
		local canBrew = hasWater and hasTeacups and hasIngredients
		
		return {{
			label = "Brew Tea",
			preferred = "ToggleWeapon",
			disabled = not canBrew,
			handler = function(obj)
				teaMenuCurrentTeapot = obj
				createTeaMenu()
			end,
			failedHandler = function(obj)
				local missing = {}
				if not hasWater then
					missing[#missing+1] = "water (" .. waterNeeded .. " ml)"
				end
				if not hasTeacups then
					missing[#missing+1] = "teacups"
				end
				if not hasIngredients then
					missing[#missing+1] = "tea ingredients"
				end
				
				local msg = "Cannot brew tea. Missing: " .. table.concat(missing, ", ")
				messageBox(2, msg)
			end
		}}
	end
}

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

local function teaBrewingFailed(data)
	local reason = data.reason or "Unknown error"
	messageBox(2, "Brewing failed: " .. reason)
end

G_eventHandlers.SunsDusk_Tea_brewingFailed = teaBrewingFailed

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
	buildTeacupMeshLookup()
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