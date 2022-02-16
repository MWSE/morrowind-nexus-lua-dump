local seph = require("seph")

local mcm = seph.Mcm()

mcm.showEnabledButton = false

function mcm:onCreate()
    local config = self.mod.config
	local viewportWidth, viewportHeight = tes3ui.getViewportSize()

	local function highlight(elementName)
		local hud = self.mod.modules.hud
		if hud.elements[elementName] then
			self.mod.modules.highlighter:setHighlight(hud.elements[elementName])
		else
			self.mod.modules.highlighter:removeHighlight()
		end
		local menuMulti = tes3ui.findMenu(hud.uuids.menuMulti)
		if menuMulti then
			menuMulti:updateLayout()
		end
	end

	local function onCallback(component)
		self.mod.modules.hud:update()
		if component and component.elementName then
			highlight(component.elementName)
		end
	end

	local function onMouseOver(component)
		if component and component.elementName then
			highlight(component.elementName)
		end
	end

	local function booleanToReadableString(boolean)
		if boolean then
			return "Yes"
		else
			return "No"
		end
	end

	local function flowDirectionToReadableString(flowDirection)
		if flowDirection:lower() == "left_to_right" then
			return "Horizontal"
		elseif flowDirection:lower() == "top_to_bottom" then
			return "Vertical"
		else
			return "None"
		end
	end

	local function updatePositionValueLabel(component)
		local value = ""
		if component.elements.slider then
			value = (component.elements.slider.widget.current + component.min) / 10.0
		end
        local text = ""
		if string.find(component.label, "%s", 1, true) then
			text = string.format(component.label, value)
		else
			text = component.label .. ": " .. value
		end
		component.elements.label.text = text
	end

	local function createSideBarPage(label)
		return self.template:createSideBarPage{
			label = label,
			description = "Hover over a setting for more information.",
			postCreate =
				function()
					self.mod.modules.highlighter:removeHighlight()
				end
		}
	end

	local function createVisibleButton(parent, elementName)
		return parent:createYesNoButton{
			label = "Visible?",
			description = string.format("This determines if this element should be visible or not.\n\nDefault: %s", booleanToReadableString(config.default[elementName].visible)),
			variable = mwse.mcm.createTableVariable{id = "visible", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createHorizontalPositionSlider(parent, elementName)
		return parent:createSlider{
			label = "Horizontal position: %s%%",
			description = string.format("This sets the relative horizontal position of this element. At 100%% it will be aligned to the rightmost edge of the screen.\n\nDefault: %.1f", config.default[elementName].position.x / 10.0),
			min = 0, max = 1000, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "x", table = config.current[elementName].position, restartRequired = false},
			callback = onCallback,
			updateValueLabel = updatePositionValueLabel,
			elementName = elementName
		}
	end

	local function createVerticalPositionSlider(parent, elementName)
		return parent:createSlider{
			label = "Vertical position: %s%%",
			description = string.format("This sets the relative vertical position of this element. At 100%% it will be aligned to the bottommost edge of the screen.\n\nDefault: %.1f", config.default[elementName].position.y / 10.0),
			min = 0, max = 1000, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "y", table = config.current[elementName].position, restartRequired = false},
			callback = onCallback,
			updateValueLabel = updatePositionValueLabel,
			elementName = elementName
		}
	end

	local function createWidthSlider(parent, elementName)
		return parent:createSlider{
			label = "Width",
			description = string.format("This sets the absolute width of this element.\n\nDefault: %d", config.default[elementName].width),
			min = 0, max = viewportWidth, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "width", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createHeightSlider(parent, elementName)
		return parent:createSlider{
			label = "Height",
			description = string.format("This sets the absolute height of this element.\n\nDefault: %d", config.default[elementName].height),
			min = 0, max = viewportHeight, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "height", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createLayoutDropdown(parent, elementName)
		return parent:createDropdown{
			label = "Layout",
			description = string.format("This sets the layout of this element. The magic effect icons will align themselves either horizontally or vertically.\n\nDefault: %s", flowDirectionToReadableString(config.default[elementName].layout)),
			options = {
				{label = "Horizontal", value = "left_to_right"},
				{label = "Vertical", value = "top_to_bottom"}
			},
			variable = mwse.mcm:createTableVariable{id = "layout", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createAlphaSlider(parent, elementName)
		return parent:createSlider{
			label = "Alpha: %s%%",
			description = string.format("This sets the opacity of this element. At 100%% this element will be fully opaque.\n\nDefault: %d", config.default[elementName].alpha),
			min = 1, max = 100, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "alpha", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createColorSliders(parent, elementName)
        return{
            parent:createSlider{
                label = "Red: %s%%",
                description = string.format("This sets the red content of the color of this element.\n\nDefault: %d", config.default[elementName].color.r),
                min = 0, max = 100, step = 1, jump = 10,
                variable = mwse.mcm.createTableVariable{id = "r", table = config.current[elementName].color, restartRequired = false},
                callback = onCallback,
				elementName = elementName
            },
            parent:createSlider{
                label = "Green: %s%%",
                description = string.format("This sets the green content of the color of this element.\n\nDefault: %d", config.default[elementName].color.g),
                min = 0, max = 100, step = 1, jump = 10,
                variable = mwse.mcm.createTableVariable{id = "g", table = config.current[elementName].color, restartRequired = false},
                callback = onCallback,
				elementName = elementName
            },
            parent:createSlider{
                label = "Blue: %s%%",
                description = string.format("This sets the blue content of the color of this element.\n\nDefault: %d", config.default[elementName].color.b),
                min = 0, max = 100, step = 1, jump = 10,
                variable = mwse.mcm.createTableVariable{id = "b", table = config.current[elementName].color, restartRequired = false},
                callback = onCallback,
				elementName = elementName
            }
        }
	end

	local function createModCategories(parent)
		for modElementName, modElementConfig in pairs(config.current.mods) do
			local modCategory = parent:createCategory(modElementConfig.name)
			if modElementConfig.options.visibility then
				modCategory:createYesNoButton{
					label = "Visible?",
					description = string.format("This determines if this element should be visible or not.\n\nDefault: %s", booleanToReadableString(config.current.mods[modElementName].defaults.visible)),
					variable = mwse.mcm.createTableVariable{id = "visible", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					elementName = modElementName
				}
			end
			if modElementConfig.options.position then
				modCategory:createSlider{
					label = "Horizontal position: %s%%",
					description = string.format("This sets the relative horizontal position of this element. At 100%% it will be aligned to the rightmost edge of the screen.\n\nDefault: %.1f", config.current.mods[modElementName].defaults.positionX / 10.0),
					min = 0, max = 1000, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "positionX", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					updateValueLabel = updatePositionValueLabel,
					elementName = modElementName
				}
				modCategory:createSlider{
					label = "Vertical position: %s%%",
					description = string.format("This sets the relative vertical position of this element. At 100%% it will be aligned to the bottommost edge of the screen.\n\nDefault: %.1f", config.current.mods[modElementName].defaults.positionY / 10.0),
					min = 0, max = 1000, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "positionY", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					updateValueLabel = updatePositionValueLabel,
					elementName = modElementName
				}
			end
			if modElementConfig.options.size then
				modCategory:createSlider{
					label = "Width",
					description = string.format("This sets the absolute width of this element.\n\nDefault: %d", config.current.mods[modElementName].defaults.width),
					min = 0, max = viewportWidth, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "width", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					elementName = modElementName
				}
				modCategory:createSlider{
					label = "Height",
					description = string.format("This sets the absolute height of this element.\n\nDefault: %d", config.current.mods[modElementName].defaults.height),
					min = 0, max = viewportHeight, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "height", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					elementName = modElementName
				}
			end
			self.logger:debug(string.format("Created mod category '%s'", modElementConfig.name))
		end
	end

	event.register("MCM:MouseOver", onMouseOver)

    local generalPage = createSideBarPage("General")
	generalPage:createSlider{
		label = "Deadzone",
		description = string.format("This defines a deadzone that prevents HUD elements from getting too close to the edges of the screen.\n\nDefault: %d", config.default.deadzone),
		min = 0, max = 100, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "deadzone", table = config.current, restartRequired = false},
		callback = onCallback
	}

	local highlightCategory = generalPage:createCategory("Highlight")
	highlightCategory.description = "This is an overlay that highlights the element you are currently editing. It will only be visible inside the configuration menu when you hover over various settings."
	createVisibleButton(highlightCategory, "highlight")
	createColorSliders(highlightCategory, "highlight")
	createAlphaSlider(highlightCategory, "highlight")

	local barPage = createSideBarPage("Bars")

	local healthBarCategory = barPage:createCategory("Health bar")
	healthBarCategory.description = "This is the player's health bar."
	createVisibleButton(healthBarCategory, "healthBar")
	healthBarCategory:createYesNoButton{
		label = "Show values?",
		description = string.format("This determines if current and maximum numbers of your health will be shown inside the health bar.\n\nDefault: %s", booleanToReadableString(config.default.healthBar.showValues)),
		variable = mwse.mcm.createTableVariable{id = "showValues", table = config.current.healthBar, restartRequired = false},
		callback = onCallback,
		elementName = "healthBar"
	}
	createWidthSlider(healthBarCategory, "healthBar")
	createHeightSlider(healthBarCategory, "healthBar")
	createHorizontalPositionSlider(healthBarCategory, "healthBar")
	createVerticalPositionSlider(healthBarCategory, "healthBar")
	createColorSliders(healthBarCategory, "healthBar")
	-- createAlphaSlider(healthBarCategory, "healthBar")

	local magicBarCategory = barPage:createCategory("Magicka bar")
	magicBarCategory.description = "This is the player's magicka bar."
	createVisibleButton(magicBarCategory, "magicBar")
	magicBarCategory:createYesNoButton{
		label = "Show values?",
		description = string.format("This determines if current and maximum numbers of your magicka will be shown inside the magicka bar.\n\nDefault: %s", booleanToReadableString(config.default.magicBar.showValues)),
		variable = mwse.mcm.createTableVariable{id = "showValues", table = config.current.magicBar, restartRequired = false},
		callback = onCallback,
		elementName = "magicBar"
	}
	createWidthSlider(magicBarCategory, "magicBar")
	createHeightSlider(magicBarCategory, "magicBar")
	createHorizontalPositionSlider(magicBarCategory, "magicBar")
	createVerticalPositionSlider(magicBarCategory, "magicBar")
	createColorSliders(magicBarCategory, "magicBar")
	-- createAlphaSlider(magicBarCategory, "magicBar")

	local fatigueBarCategory = barPage:createCategory("Fatigue bar")
	fatigueBarCategory.description = "This is the player's fatigue bar."
	createVisibleButton(fatigueBarCategory, "fatigueBar")
	fatigueBarCategory:createYesNoButton{
		label = "Show values?",
		description = string.format("This determines if current and maximum numbers of your fatigue will be shown inside the fatigue bar.\n\nDefault: %s", booleanToReadableString(config.default.fatigueBar.showValues)),
		variable = mwse.mcm.createTableVariable{id = "showValues", table = config.current.fatigueBar, restartRequired = false},
		callback = onCallback,
		elementName = "fatigueBar"
	}
	createWidthSlider(fatigueBarCategory, "fatigueBar")
	createHeightSlider(fatigueBarCategory, "fatigueBar")
	createHorizontalPositionSlider(fatigueBarCategory, "fatigueBar")
	createVerticalPositionSlider(fatigueBarCategory, "fatigueBar")
	createColorSliders(fatigueBarCategory, "fatigueBar")
	-- createAlphaSlider(fatigueBarCategory, "fatigueBar")

	local npcHealthBarCategory = barPage:createCategory("NPC health bar")
	npcHealthBarCategory.description = "This is the enemy NPC's health bar that appears when you damage the NPC."
	createVisibleButton(npcHealthBarCategory, "npcHealthBar")
	createWidthSlider(npcHealthBarCategory, "npcHealthBar")
	createHeightSlider(npcHealthBarCategory, "npcHealthBar")
	createHorizontalPositionSlider(npcHealthBarCategory, "npcHealthBar")
	createVerticalPositionSlider(npcHealthBarCategory, "npcHealthBar")

	local equippedPage = createSideBarPage("Equipped")

	local equippedWeaponCategory = equippedPage:createCategory("Weapon")
	equippedWeaponCategory.description = "This is the icon for your currently equipped weapon."
	createVisibleButton(equippedWeaponCategory, "equippedWeapon")
	createHorizontalPositionSlider(equippedWeaponCategory, "equippedWeapon")
	createVerticalPositionSlider(equippedWeaponCategory, "equippedWeapon")
	-- createAlphaSlider(equippedWeaponCategory, "equippedWeapon")

	local equippedMagicCategory = equippedPage:createCategory("Magic")
	equippedMagicCategory.description = "This is the icon for your currently equipped magic."
	createVisibleButton(equippedMagicCategory, "equippedMagic")
	createHorizontalPositionSlider(equippedMagicCategory, "equippedMagic")
	createVerticalPositionSlider(equippedMagicCategory, "equippedMagic")
	-- createAlphaSlider(equippedMagicCategory, "equippedMagic")

	local equippedNotificationCategory = equippedPage:createCategory("Notification")
	equippedNotificationCategory.description = "This is the text notification that appears when you change your equipped weapon or magic."
	createVisibleButton(equippedNotificationCategory, "equippedNotification")
	createHorizontalPositionSlider(equippedNotificationCategory, "equippedNotification")
	createVerticalPositionSlider(equippedNotificationCategory, "equippedNotification")

	local mapPage = createSideBarPage("Map")

	local mapCategory = mapPage:createCategory("Map")
	mapCategory.description = "This is the minimap."
	createVisibleButton(mapCategory, "map")
	createWidthSlider(mapCategory, "map")
	createHeightSlider(mapCategory, "map")
	createHorizontalPositionSlider(mapCategory, "map")
	createVerticalPositionSlider(mapCategory, "map")
	-- createAlphaSlider(mapCategory, "map")

	local mapNotificationCategory = mapPage:createCategory("Notification")
	mapNotificationCategory.description = "This is the text notification that appears when you enter a new area/cell."
	createVisibleButton(mapNotificationCategory, "mapNotification")
	createHorizontalPositionSlider(mapNotificationCategory, "mapNotification")
	createVerticalPositionSlider(mapNotificationCategory, "mapNotification")

	local otherPage = createSideBarPage("Other")

	local activeMagicEffectsCategory = otherPage:createCategory("Active magic effects")
	activeMagicEffectsCategory.description = "These are the magic effects that are currently affecting you. This includes permanent and temporary effects."
	createVisibleButton(activeMagicEffectsCategory, "activeMagicEffects")
	createLayoutDropdown(activeMagicEffectsCategory, "activeMagicEffects")
	createHorizontalPositionSlider(activeMagicEffectsCategory, "activeMagicEffects")
	createVerticalPositionSlider(activeMagicEffectsCategory, "activeMagicEffects")

	local sneakIndicatorCategory = otherPage:createCategory("Sneak indicator")
	sneakIndicatorCategory.description = "This is the indicator that appears when you are sneaking and hidden."
	createVisibleButton(sneakIndicatorCategory, "sneakIndicator")
	createHorizontalPositionSlider(sneakIndicatorCategory, "sneakIndicator")
	createVerticalPositionSlider(sneakIndicatorCategory, "sneakIndicator")
	-- createAlphaSlider(sneakIndicatorCategory, "sneakIndicator")

	local menuNotifyCategory = otherPage:createCategory("Messages")
	menuNotifyCategory.description = "These are the messages that appear for various reasons, like raising skill levels, committing crimes, killing essential NPCs and so on."
	createVisibleButton(menuNotifyCategory, "menuNotify")
	menuNotifyCategory:createYesNoButton{
		label = "Flip?",
		description = string.format("This determines if the messages should be flipped. If set to true this will make messages flow from top to bottom and appear at the top of the screen instead. This also modifies the behaviour of the 'Vertical offset' setting.\n\nDefault: %s", booleanToReadableString(config.default.menuNotify.flipped)),
		variable = mwse.mcm.createTableVariable{id = "flipped", table = config.current.menuNotify, restartRequired = false}
	}
	createHorizontalPositionSlider(menuNotifyCategory, "menuNotify")
	menuNotifyCategory:createSlider{
		label = "Vertical offset",
		description = string.format("This sets the absolute vertical offset for this element. The higher this value, the further up the messages will appear. If flipped, increasing this value will make the messages appear further down instead.\n\nDefault: %d", config.default.menuNotify.position.y),
		min = -viewportHeight, max = viewportHeight, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "y", table = config.current.menuNotify.position, restartRequired = false},
		callback = onCallback,
		elementName = "menuNotify"
	}

	local menuSwimFillBarCategory = otherPage:createCategory("Breath meter")
	menuSwimFillBarCategory.description = "This is the breath meter that appears when you are underwater."
	createVisibleButton(menuSwimFillBarCategory, "menuSwimFillBar")
	createHorizontalPositionSlider(menuSwimFillBarCategory, "menuSwimFillBar")
	createVerticalPositionSlider(menuSwimFillBarCategory, "menuSwimFillBar")

	local modsPage = createSideBarPage("Mods")
	modsPage:createYesNoButton{
		label = "Automatically delete inactive mod configurations?",
		description = string.format("This determines if HUD Customizer configurations of other mods will stay in your configuration file indefinetely or not. The removal of other mods won't lead to their HUD Customizer config being deleted if this is set to 'No'.\n\nDefault: %s", booleanToReadableString(config.default.deleteInvalidModConfigs)),
		variable = mwse.mcm.createTableVariable{id = "deleteInvalidModConfigs", table = config.current, restartRequired = false}
	}
    modsPage.postCreate =
        function(component)
            component.postCreate = nil
			self.mod.config:cleanMods()
            createModCategories(modsPage)
            self.template:clickTab(component)
        end
end

function mcm:onClose()
	self.mod.modules.hud:update()
	self.mod.modules.highlighter:removeHighlight()
end

function mcm:onResetButtonClicked()
	self.mod.modules.hud:update()
end

return mcm