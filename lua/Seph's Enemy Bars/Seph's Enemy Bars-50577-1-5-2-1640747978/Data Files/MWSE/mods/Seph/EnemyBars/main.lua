local mod = "Seph's Enemy Bars"
local version = "1.5.2"

local function logMessage(message)
	mwse.log("[" .. mod .. " " .. version .. "] " .. message)
end

local defaultConfig = {
	showMagickaFatigueBars = true,
	indicateHostility = true,
	showForHostileActorsOnly = false,
	hideBarFrames = false,
	showHealthValues = false,
	showMagickaValues = false,
	showFatigueValues = false,
	style = 0,
	frameColor = 0,
	healthColor = 1,
	friendlyHealthColor = 4,
	magickaColor = 3,
	fatigueColor = 2,
	length = 100,
	thickness = 100,
	alignPositionX = 50,
	alignPositionY = 3
}

local config = mwse.loadConfig(mod, defaultConfig)

local frameColors = {
	[0] = {1.00, 1.00, 1.00},
	[1] = {0.65, 0.45, 0.25}
}

local barColors = {
	[0] = {0.700000, 0.700000, 0.700000},
	[1] = {0.784314, 0.235294, 0.117647},
	[2] = {0.000000, 0.588235, 0.235294},
	[3] = {0.207843, 0.270588, 0.623529},
	[4] = {0.800000, 0.600000, 0.000000}
}

local idEnemyBarMenu = nil
local idHealthBarLabel = nil
local idHealthBarFill = nil
local idMagickaBarLabel = nil
local idMagickaBarFill = nil
local idFatigueBarLabel = nil
local idFatigueBarFill = nil
local idPickpocketMenu = nil
local idHelpMenu = nil
local idHelpMenuName = nil
local idMenuSwimFillBar = nil
local currentTarget = nil
local rayCastTimer = nil
local hiddenTimer = nil
local cachedBarMenu = nil
local cachedHealthBarLabel = nil
local cachedHealthBarFill = nil
local cachedMagickaBarLabel = nil
local cachedMagickaBarFill = nil
local cachedFatigueBarLabel = nil
local cachedFatigueBarFill = nil

local function isValidTarget(reference)
	if reference and reference.object and (reference.object.objectType == tes3.objectType.creature or reference.object.objectType == tes3.objectType.npc) then
		if reference.mobile and reference.mobile.health.current ~= nil and not reference.mobile.isDead then
			return true
		end
	end
	return false
end

local function isHostile(mobile)
	if mobile and tes3.mobilePlayer then
		for _, hostileActor in pairs(mobile.hostileActors) do
			if tes3.mobilePlayer == hostileActor then
				return true
			end
		end
	end
	return false
end

local function createBarMenu()
	local healthBarWidth = 400 * (config.length / 100)
	local healthBarHeight = 30 * (config.thickness / 100)
	
	-- Bar menu
	local enemyBarMenu = tes3ui.createHelpLayerMenu{ id = idEnemyBarMenu, fixedFrame = true }
	enemyBarMenu:destroyChildren()
    enemyBarMenu.disabled = true
    enemyBarMenu.absolutePosAlignX = config.alignPositionX / 100.0
    enemyBarMenu.absolutePosAlignY = config.alignPositionY / 100.0
    enemyBarMenu.color = {0, 0, 0}
    enemyBarMenu.alpha = 0.0
	enemyBarMenu.autoWidth = false
	enemyBarMenu.autoHeight = false
	enemyBarMenu.flowDirection = "top_to_bottom"
	enemyBarMenu.childAlignX = 0.5
	if config.hideBarFrames then
		enemyBarMenu.width = healthBarWidth * 0.74
	else
		enemyBarMenu.width = healthBarWidth
	end
	if config.style == 0 then
		enemyBarMenu.height = healthBarHeight * 2
	else
		if not config.hideBarFrames then
			enemyBarMenu.flowDirection = ""
		end
		enemyBarMenu.height = healthBarHeight * 3
	end
	enemyBarMenu.visible = false
	enemyBarMenu.disabled = true
	cachedBarMenu = enemyBarMenu
	
	-- Health
	local healthBarFrame = nil
	if config.hideBarFrames then
		healthBarFrame = enemyBarMenu:createRect{ color = {0, 0, 0} }
		healthBarFrame.width = healthBarWidth * 0.74
		healthBarFrame.height = healthBarHeight * 0.6
	else
		healthBarFrame = enemyBarMenu:createImage({ path = "Textures/Seph/EnemyBars/Frame.dds" })
		healthBarFrame.color = frameColors[config.frameColor]
		healthBarFrame.imageScaleX = config.length / 100
		healthBarFrame.imageScaleY = config.thickness / 100
		if config.style ~= 0 then
			healthBarFrame.absolutePosAlignX = 0.5
			healthBarFrame.absolutePosAlignY = 0.0
		end
	end
	
	local healthBarFill = healthBarFrame:createFillBar({ id = idHealthBarFill, current = 100, max = 100})
	healthBarFill.autoWidth = false
	healthBarFill.autoHeight = false
	healthBarFill.widget.showText = false
	if config.hideBarFrames then
		healthBarFill.width = healthBarFrame.width
		healthBarFill.height = healthBarFrame.height
		healthBarFill.absolutePosAlignX = 0.5
		healthBarFill.absolutePosAlignY = 0.5
	else
		healthBarFill.width = healthBarWidth * 0.74
		healthBarFill.height = healthBarHeight * 0.6
		healthBarFill.absolutePosAlignX = 0.5
		healthBarFill.absolutePosAlignY = 0.75
	end
	cachedHealthBarFill = healthBarFill
	
	local healthBarLabel = healthBarFill:createLabel({ id = idHealthBarLabel})
	healthBarLabel.autoWidth = true
	healthBarLabel.autoHeight = true
	healthBarLabel.maxWidth = healthBarWidth * 0.74
	healthBarLabel.color = tes3ui.getPalette("header_color")
	healthBarLabel.absolutePosAlignX = 0.5
	healthBarLabel.absolutePosAlignY = 0.45
	cachedHealthBarLabel = healthBarLabel
	
	local subBarBlock = enemyBarMenu:createBlock()
	subBarBlock.flowDirection = "left_to_right"
	subBarBlock.childAlignX = 0.5
	subBarBlock.autoWidth = true
	subBarBlock.autoHeight = true
	
	-- Magicka
	local magickaBarFrame = nil
	if config.hideBarFrames then
		if config.style == 0 then
			magickaBarFrame = subBarBlock:createRect{ color = {0, 0, 0} }
			magickaBarFrame.width = healthBarFrame.width / 2
		else
			magickaBarFrame = enemyBarMenu:createRect{ color = {0, 0, 0} }
			magickaBarFrame.width = healthBarFrame.width
		end
		magickaBarFrame.height = healthBarFrame.height
	else
		if config.style == 0 then
			magickaBarFrame = subBarBlock:createImage({ path = "Textures/Seph/EnemyBars/FrameLeft.dds" })
		else
			magickaBarFrame = enemyBarMenu:createImage({ path = "Textures/Seph/EnemyBars/Frame.dds" })
			magickaBarFrame.absolutePosAlignX = 0.5
			magickaBarFrame.absolutePosAlignY = 0.4
		end
		magickaBarFrame.color = frameColors[config.frameColor]
		magickaBarFrame.imageScaleX = config.length / 100
		magickaBarFrame.imageScaleY = config.thickness / 100
	end
	magickaBarFrame.visible = config.showMagickaFatigueBars
	
	local magickaBarFill = magickaBarFrame:createFillBar({ id = idMagickaBarFill, current = 100, max = 100})
	magickaBarFill.autoWidth = false
	magickaBarFill.autoHeight = false
	magickaBarFill.widget.showText = false
	magickaBarFill.widget.fillColor = tes3ui.getPalette("magic_color")
	if config.hideBarFrames then
		magickaBarFill.width = magickaBarFrame.width
		magickaBarFill.height = magickaBarFrame.height
		magickaBarFill.absolutePosAlignX = 1.0
		magickaBarFill.absolutePosAlignY = 0.1
	else
		if config.style == 0 then
			magickaBarFill.width = healthBarWidth * 0.3575
			magickaBarFill.height = healthBarHeight * 0.48
			magickaBarFill.absolutePosAlignX = 0.975
			magickaBarFill.absolutePosAlignY = 0.125
		else
			magickaBarFill.width = healthBarWidth * 0.74
			magickaBarFill.height = healthBarHeight * 0.6
			magickaBarFill.absolutePosAlignX = 0.5
			magickaBarFill.absolutePosAlignY = 0.75
		end
	end
	cachedMagickaBarFill = magickaBarFill
	
	local magickaBarLabel = magickaBarFill:createLabel({ id = idMagickaBarLabel})
	magickaBarLabel.autoWidth = true
	magickaBarLabel.autoHeight = true
	magickaBarLabel.maxWidth = healthBarWidth * 0.74
	magickaBarLabel.color = tes3ui.getPalette("header_color")
	magickaBarLabel.absolutePosAlignX = 0.5
	magickaBarLabel.absolutePosAlignY = 0.5
	cachedMagickaBarLabel = magickaBarLabel
	
	-- Fatigue
	local fatigueBarFrame = nil
	if config.hideBarFrames then
		if config.style == 0 then
			fatigueBarFrame = subBarBlock:createRect{ color = {0, 0, 0} }
			fatigueBarFrame.width = healthBarFrame.width / 2
		else
			fatigueBarFrame = enemyBarMenu:createRect{ color = {0, 0, 0} }
			fatigueBarFrame.width = healthBarFrame.width
		end
		fatigueBarFrame.height = healthBarFrame.height
	else
		if config.style == 0 then
			fatigueBarFrame = subBarBlock:createImage({ path = "Textures/Seph/EnemyBars/FrameRight.dds" })
		else
			fatigueBarFrame = enemyBarMenu:createImage({ path = "Textures/Seph/EnemyBars/Frame.dds" })
			fatigueBarFrame.absolutePosAlignX = 0.5
			fatigueBarFrame.absolutePosAlignY = 0.8
		end
		fatigueBarFrame.color = frameColors[config.frameColor]
		fatigueBarFrame.imageScaleX = config.length / 100
		fatigueBarFrame.imageScaleY = config.thickness / 100
	end
	fatigueBarFrame.visible = config.showMagickaFatigueBars
	
	local fatigueBarFill = fatigueBarFrame:createFillBar({ id = idFatigueBarFill, current = 100, max = 100})
	fatigueBarFill.autoWidth = false
	fatigueBarFill.autoHeight = false
	fatigueBarFill.widget.showText = false
	fatigueBarFill.widget.fillColor = tes3ui.getPalette("fatigue_color")
	if config.hideBarFrames then
		fatigueBarFill.width = fatigueBarFrame.width
		fatigueBarFill.height = fatigueBarFrame.height
		fatigueBarFill.absolutePosAlignX = 0.0
		fatigueBarFill.absolutePosAlignY = 0.1
	else
		if config.style == 0 then
			fatigueBarFill.width = healthBarWidth * 0.3575
			fatigueBarFill.height = healthBarHeight * 0.48
			fatigueBarFill.absolutePosAlignX = 0.025
			fatigueBarFill.absolutePosAlignY = 0.125
		else
			fatigueBarFill.width = healthBarWidth * 0.74
			fatigueBarFill.height = healthBarHeight * 0.6
			fatigueBarFill.absolutePosAlignX = 0.5
			fatigueBarFill.absolutePosAlignY = 0.75
		end
	end
	cachedFatigueBarFill = fatigueBarFill
	
	local fatigueBarLabel = fatigueBarFill:createLabel({ id = idFatigueBarLabel})
	fatigueBarLabel.autoWidth = true
	fatigueBarLabel.autoHeight = true
	fatigueBarLabel.maxWidth = healthBarWidth * 0.74
	fatigueBarLabel.color = tes3ui.getPalette("header_color")
	fatigueBarLabel.absolutePosAlignX = 0.5
	fatigueBarLabel.absolutePosAlignY = 0.5
	cachedFatigueBarLabel = fatigueBarLabel
	
	enemyBarMenu:updateLayout()
end

local function getBarMenu()
	return tes3ui.findHelpLayerMenu(idEnemyBarMenu)
end

local function repositionBreathMenu()
	local menuSwimFillBar = tes3ui.findHelpLayerMenu(tes3ui.registerID("MenuSwimFillBar"))
	if menuSwimFillBar then
		if config.alignPositionY < 12 and cachedBarMenu and cachedBarMenu.visible then
			menuSwimFillBar.absolutePosAlignY = config.alignPositionY / 100.0 + 0.07
		else
			menuSwimFillBar.absolutePosAlignY = 0.05
		end
	end
end

local function updateBars()
	if isValidTarget(currentTarget) then
		if cachedBarMenu then
			-- Name
			cachedHealthBarLabel.text = currentTarget.object.name
			
			-- Positioning
			repositionBreathMenu()
			cachedBarMenu.absolutePosAlignX = config.alignPositionX / 100.0
			cachedBarMenu.absolutePosAlignY = config.alignPositionY / 100.0
			
			-- Numbers
			cachedMagickaBarLabel.visible = config.showMagickaValues
			cachedFatigueBarLabel.visible = config.showFatigueValues
			if config.showHealthValues then
				cachedHealthBarLabel.text = cachedHealthBarLabel.text .. string.format(" (%d/%d)", currentTarget.mobile.health.current, currentTarget.mobile.health.base)
			end
			if config.showMagickaValues then
				cachedMagickaBarLabel.text = string.format("%d/%d", currentTarget.mobile.magicka.current, currentTarget.mobile.magicka.base)
			end
			if config.showFatigueValues then
				cachedFatigueBarLabel.text = string.format("%d/%d", currentTarget.mobile.fatigue.current, currentTarget.mobile.fatigue.base)
			end
			
			-- Colors
			if config.indicateHostility then
				if isHostile(currentTarget.mobile) then
					cachedHealthBarFill.widget.fillColor = barColors[config.healthColor]
				else
					cachedHealthBarFill.widget.fillColor = barColors[config.friendlyHealthColor]
				end
			else
				cachedHealthBarFill.widget.fillColor = barColors[config.healthColor]
			end
			cachedMagickaBarFill.widget.fillColor = barColors[config.magickaColor]
			cachedFatigueBarFill.widget.fillColor = barColors[config.fatigueColor]
			
			-- Update values
			cachedHealthBarFill.widget.max = currentTarget.mobile.health.base
			cachedHealthBarFill.widget.current = currentTarget.mobile.health.current
			cachedMagickaBarFill.parent.visible = config.showMagickaFatigueBars
			cachedMagickaBarFill.widget.max = currentTarget.mobile.magicka.base
			cachedMagickaBarFill.widget.current = currentTarget.mobile.magicka.current
			cachedFatigueBarFill.parent.visible = config.showMagickaFatigueBars
			cachedFatigueBarFill.widget.max = currentTarget.mobile.fatigue.base
			cachedFatigueBarFill.widget.current = currentTarget.mobile.fatigue.current
			
			cachedBarMenu:updateLayout()
		end
	end
end

local function hideHelpMenuIfNeeded()
	if config.showForHostileActorsOnly then
		local helpMenu = tes3ui.findHelpLayerMenu(idHelpMenu)
		if helpMenu and helpMenu.visible then
			local nameLabel = helpMenu:findChild(idHelpMenuName)
			if nameLabel and currentTarget and nameLabel.text == currentTarget.object.name then
				helpMenu.maxWidth = 0
				helpMenu.maxHeight = 0
			end
		end
	end
end

local function showBarMenu()
	if not hiddenTimer then
		if not cachedBarMenu then
			return
		end
		
		if not cachedBarMenu.visible then
			cachedBarMenu.disabled = false
			cachedBarMenu.visible = true
			cachedBarMenu:updateLayout()
			hideHelpMenuIfNeeded()
			repositionBreathMenu()
		end
	end
end

local function hideBarMenu()
	if not cachedBarMenu then
		return
	end
	
	if cachedBarMenu.visible then
		cachedBarMenu:updateLayout()
		cachedBarMenu.visible = false
		cachedBarMenu.disabled = true
		repositionBreathMenu()
		
		if hiddenTimer then
			hiddenTimer:cancel()
		end
		hiddenTimer	= timer.start({
			duration = 0.07, 
			type = timer.real, 
			callback = function(e) hiddenTimer = nil end
		})
	end
end

local function destroyBarMenu()
	local barMenu = getBarMenu()
	if not barMenu then
		return
	end
	
	barMenu:destroy()
	cachedBarMenu = nil
	cachedHealthBarLabel = nil
	cachedHealthBarFill = nil
	cachedMagickaBarLabel = nil
	cachedMagickaBarFill = nil
	cachedFatigueBarLabel = nil
	cachedFatigueBarFill = nil
	currentTarget = nil
end

local function updateTarget()
	if tes3.player and tes3.mobilePlayer then
		local hitResult = tes3.rayTest({ 
			position = tes3.getPlayerEyePosition(),
			direction = tes3.getPlayerEyeVector(),
			ignore = { tes3.player },
			maxDistance = tes3.findGMST(tes3.gmst.iMaxActivateDist).value
		})
		currentTarget = hitResult and hitResult.reference
		
		local pickPocketMenu = tes3ui.findMenu(idPickpocketMenu)
		if tes3ui.menuMode() or not isValidTarget(currentTarget) or (pickPocketMenu and pickPocketMenu.visible)	or tes3.mobilePlayer.isDead or (config.showForHostileActorsOnly and not isHostile(currentTarget.mobile)) then
			hideBarMenu()
			repositionBreathMenu()
		else
			updateBars()
			showBarMenu()
		end
	end
end

local function stopTimers()
	currentTarget = nil
	if rayCastTimer then
		rayCastTimer:cancel()
		rayCastTimer = nil
	end
	if hiddenTimer then
		hiddenTimer:cancel()
		hiddenTimer = nil
	end
end

local function onUiActivated(e)
	if not getBarMenu() then
		createBarMenu()
	end
	
	local menuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	if menuMulti then
		local npcHealthBar = menuMulti:findChild(tes3ui.registerID("MenuMulti_npc_health_bar"))
		if npcHealthBar then
			-- Just yeet that yellow bar somewhere so it never shows its ugly face again.
			npcHealthBar.absolutePosAlignX = 10.0
			npcHealthBar.absolutePosAlignY = 10.0
			npcHealthBar.visible = false
			npcHealthBar.disabled = true
		end
	end
end

local function onUiObjectTooltip(e)
	if e.tooltip and isValidTarget(e.reference) then
		if not config.showForHostileActorsOnly or isHostile(e.reference.mobile) then
			e.tooltip.maxWidth = 0
			e.tooltip.maxHeight = 0
		end
	end
end

local function onRayCastTimer(e)
	updateTarget()
	rayCastTimer = timer.start({duration = 0.06, type = timer.real, callback = onRayCastTimer})
end

local function onActivationTargetChanged(e)
	updateTarget()
end

local function onEnterFrame(e)
	if not rayCastTimer then
		onRayCastTimer()
	end
end

local function onMenuEnter(e)
	hideBarMenu()
end

local function onCellChanged(e)
	updateTarget()
end

local function onLoad(e)
	stopTimers()
	hideBarMenu()
	destroyBarMenu()
end

local function onLoaded()
	stopTimers()
	destroyBarMenu()
	createBarMenu()
	onRayCastTimer()
end

local function onInitialized(e)
	idEnemyBarMenu = tes3ui.registerID("SephsEnemyBars:BarMenu")
	idHealthBarLabel = tes3ui.registerID("SephsEnemyBars:HealthBarLabel")
	idHealthBarFill = tes3ui.registerID("SephsEnemyBars:HealthBarFill")
	idMagickaBarLabel = tes3ui.registerID("SephsEnemyBars:MagickaBarLabel")
	idMagickaBarFill = tes3ui.registerID("SephsEnemyBars:MagickaBarFill")
	idFatigueBarLabel = tes3ui.registerID("SephsEnemyBars:FatigueBarLabel")
	idFatigueBarFill = tes3ui.registerID("SephsEnemyBars:FatigueBarFill")
	idPickpocketMenu = tes3ui.registerID("Pickpocket:Menu")
	idHelpMenu = tes3ui.registerID("HelpMenu")
	idHelpMenuName = tes3ui.registerID("HelpMenu_name")
	idMenuSwimFillBar = tes3ui.registerID("MenuSwimFillBar")
	event.register("load", onLoad)
	event.register("loaded", onLoaded)
	event.register("cellChanged", onCellChanged)
	event.register("menuEnter", onMenuEnter)
	event.register("enterFrame", onEnterFrame)
	event.register("activationTargetChanged", onActivationTargetChanged)
	event.register("uiActivated", onUiActivated, { filter = "MenuMulti" })
	event.register("uiObjectTooltip", onUiObjectTooltip)
    logMessage("Initialized")
end
event.register("initialized", onInitialized)

local function onModConfigReady(e)
    local template = mwse.mcm.createTemplate{ name = mod }
    template:saveOnClose(mod, config)
    template:register()

    local page = template:createSideBarPage()
    page.description = mod .. " " .. version .. "\n\nThis mod adds more detailed health, magicka and fatigue bars to any npc or creature you look at."

	local generalCategory = page:createCategory("General")

    generalCategory:createYesNoButton{
        label = "Show magicka and fatigue Bars?",
        description = "Default: Yes",
        variable = mwse.mcm.createTableVariable{id = "showMagickaFatigueBars", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Change color based on hostility?",
        description = "Default: Yes",
        variable = mwse.mcm.createTableVariable{id = "indicateHostility", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Show bars for hostile actors only?",
        description = "Default: No",
        variable = mwse.mcm.createTableVariable{id = "showForHostileActorsOnly", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Hide bar decorations?",
        description = "Default: No",
        variable = mwse.mcm.createTableVariable{id = "hideBarFrames", table = config, restartRequired = true}
    }
	
	generalCategory:createDropdown{
		label = "Style",
		description = "Default: Compact",
		options = {
			{label = "Compact", value = 0},
			{label = "Normal", value = 1}
		},
		variable = mwse.mcm:createTableVariable{id = "style", table = config, restartRequired = true}
	}
	
	local valueCategory = page:createCategory("Values")
	
	valueCategory:createYesNoButton{
        label = "Show health values?",
        description = "Default: No",
        variable = mwse.mcm.createTableVariable{id = "showHealthValues", table = config, restartRequired = false}
    }
	
	valueCategory:createYesNoButton{
        label = "Show magicka values?",
        description = "Default: No",
        variable = mwse.mcm.createTableVariable{id = "showMagickaValues", table = config, restartRequired = false}
    }
	
	valueCategory:createYesNoButton{
        label = "Show fatigue values?",
        description = "Default: No",
        variable = mwse.mcm.createTableVariable{id = "showFatigueValues", table = config, restartRequired = false}
    }
	
	local colorCategory = page:createCategory("Colors")

	colorCategory:createDropdown{
		label = "Decoration",
		description = "Default: Silver",
		options = {
			{label = "Silver", value = 0},
			{label = "Brown", value = 1}
		},
		variable = mwse.mcm:createTableVariable{id = "frameColor", table = config, restartRequired = true}
	}
	
	colorCategory:createDropdown{
		label = "Friendly",
		description = "Default: Yellow",
		options = {
			{label = "Gray", value = 0},
			{label = "Red", value = 1},
			{label = "Green", value = 2},
			{label = "Blue", value = 3},
			{label = "Yellow", value = 4}
		},
		variable = mwse.mcm:createTableVariable{id = "friendlyHealthColor", table = config, restartRequired = false}
	}
	
	colorCategory:createDropdown{
		label = "Health",
		description = "Default: Red",
		options = {
			{label = "Gray", value = 0},
			{label = "Red", value = 1},
			{label = "Green", value = 2},
			{label = "Blue", value = 3},
			{label = "Yellow", value = 4}
		},
		variable = mwse.mcm:createTableVariable{id = "healthColor", table = config, restartRequired = false}
	}
	
	colorCategory:createDropdown{
		label = "Magicka",
		description = "Default: Blue",
		options = {
			{label = "Gray", value = 0},
			{label = "Red", value = 1},
			{label = "Green", value = 2},
			{label = "Blue", value = 3},
			{label = "Yellow", value = 4}
		},
		variable = mwse.mcm:createTableVariable{id = "magickaColor", table = config, restartRequired = false}
	}
	
	colorCategory:createDropdown{
		label = "Fatigue",
		description = "Default: Green",
		options = {
			{label = "Gray", value = 0},
			{label = "Red", value = 1},
			{label = "Green", value = 2},
			{label = "Blue", value = 3},
			{label = "Yellow", value = 4}
		},
		variable = mwse.mcm:createTableVariable{id = "fatigueColor", table = config, restartRequired = false}
	}
	
	local sizeCategory = page:createCategory("Size")
	
	sizeCategory:createSlider{
		label = "Length",
		description = "Default: 100",
		min = 50,
		max = 200,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "length",
			table = config,
			restartRequired = true
		}
	}
	
	sizeCategory:createSlider{
		label = "Thickness",
		description = "Default: 100",
		min = 50,
		max = 200,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "thickness",
			table = config,
			restartRequired = true
		}
	}
	
	local positionCategory = page:createCategory("Position")
	
	positionCategory:createSlider{
		label = "X Alignment",
		description = "Default: 50",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "alignPositionX",
			table = config,
			restartRequired = false
		}
	}
	
	positionCategory:createSlider{
		label = "Y Alignment",
		description = "Default: 3",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "alignPositionY",
			table = config,
			restartRequired = false
		}
	}
end
event.register("modConfigReady", onModConfigReady)