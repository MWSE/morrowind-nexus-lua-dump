local seph = require("seph")

local hud = seph.Module()

hud.elements = {}

hud.uuids = {
    menuMulti = tes3ui.registerID("MenuMulti"),
    menuMultiMain = tes3ui.registerID("MenuMulti_main"),
    menuMultiBottomRow = tes3ui.registerID("MenuMulti_bottom_row"),
    menuMultiFillBarsLayout = tes3ui.registerID("MenuMulti_fillbars_layout"),
    menuMultiNpcHealthBar = tes3ui.registerID("MenuMulti_npc_health_bar"),
    menuMultiWeaponLayout = tes3ui.registerID("MenuMulti_weapon_layout"),
	menuMultiMagicLayout = tes3ui.registerID("MenuMulti_magic_layout"),
	menuMultiSneakIcon = tes3ui.registerID("MenuMulti_sneak_icon"),
    menuMultiMagicIconsLayout = tes3ui.registerID("MenuMulti_magic_icons_layout"),
    menuMultiMagicIconsBox = tes3ui.registerID("MenuMulti_magic_icons_box"),
    menuMultiWeaponMagicNotify = tes3ui.registerID("MenuMulti_weapon_magic_notify"),
    menuMultiMapNotify = tes3ui.registerID("MenuMulti_map_notify"),
    menuMapPanel = tes3ui.registerID("MenuMap_panel"),
    menuMapLocalPlayer = tes3ui.registerID("MenuMap_local_player"),
    menuStat = tes3ui.registerID("MenuStat"),
    menuStatHealthFillBar = tes3ui.registerID("MenuStat_health_fillbar"),
    menuStatMagicFillBar = tes3ui.registerID("MenuStat_magic_fillbar"),
    menuStatFatigueFillBar = tes3ui.registerID("MenuStat_fatigue_fillbar"),
	menuStatReview = tes3ui.registerID("MenuStatReview"),
    menuStatHealthFillBarReview = tes3ui.registerID("MenuStatReview_health_fillbar"),
    menuStatMagicFillBarReview = tes3ui.registerID("MenuStatReview_magic_fillbar"),
    menuStatFatigueFillBarReview = tes3ui.registerID("MenuStatReview_fatigue_fillbar"),
	menuSwimFillBar = tes3ui.registerID("MenuSwimFillBar"),
	menuNotify1 = tes3ui.registerID("MenuNotify1"),
	menuNotify2 = tes3ui.registerID("MenuNotify2"),
	menuNotify3 = tes3ui.registerID("MenuNotify3")
}

function hud:expandElementToViewport(element)
	local viewportWidth, viewportHeight = tes3ui.getViewportSize()
	element.autoWidth = false
	element.autoHeight = false
	element.widthProportional = nil
	element.heightProportional = nil
	element.childAlignX = nil
	element.childAlignY = nil
	element.childOffsetX = nil
	element.childOffsetY = nil
	element.flowDirection = nil
	element.width = viewportWidth
	element.height = viewportHeight
	element.absolutePosAlignX = 0.0
	element.absolutePosAlignY = 0.0
end

function hud:disableMouseEvents(element)
	element.consumeMouseEvents = false
	element:registerAfter("update",
		function()
			element.consumeMouseEvents = false
		end
	)
end

function hud:updatePosition(element, position)
	element.absolutePosAlignX = position.x / 1000
	element.absolutePosAlignY = position.y / 1000
	element.paddingTop = 0
	element.paddingBottom = 0
	element.paddingLeft = 0
	element.paddingRight = 0
	element.paddingAllSides = 0
	element.borderTop = 0
	element.borderBottom = 0
	element.borderLeft = 0
	element.borderRight = 0
	element.borderAllSides = self.mod.config.current.deadzone

	event.trigger(
		"seph.hudCustomizer:positionUpdated",
		{
			element = element,
			absolutePosAlignX = element.absolutePosAlignX,
			absolutePosAlignY = element.absolutePosAlignY
		},
		{filter = element.name}
	)
end

function hud:updateSize(element, width, height)
	element.width = width
	element.height = height

	event.trigger(
		"seph.hudCustomizer:sizeUpdated",
		{
			element = element,
			width = width,
			height = height
		},
		{filter = element.name}
	)
end

function hud:updateAlpha(element, alpha)
	local function setElementAlpha(element, alpha)
		element.alpha = alpha
		if element.widget and element.widget.fillColor then
			element.widget.fillAlpha = alpha
		end
	end

	local function updateChildren(element)
		for _, child in pairs(element.children) do
			setElementAlpha(child, alpha)
			updateChildren(child)
		end
	end

	alpha = alpha / 100
	setElementAlpha(element, alpha)
	updateChildren(element)

	event.trigger(
		"seph.hudCustomizer:alphaUpdated",
		{
			element = element,
			alpha = alpha
		},
		{filter = element.name}
	)
end

function hud:updateVisibility(element, visibility)
	if visibility then
		element.maxWidth = nil
		element.maxHeight = nil
	else
		element.maxWidth = 0
		element.maxHeight = 0
	end

	event.trigger(
		"seph.hudCustomizer:visibilityUpdated",
		{
			element = element,
			visibility = visibility
		},
		{filter = element.name}
	)
end

function hud:updatePlayerBars()
	if self.elements.healthBar and self.elements.magicBar and self.elements.fatigueBar then
		local config = self.mod.config

		local function updateFillBarColor(fillBarElement, barConfig)
			fillBarElement.widget.fillColor = {barConfig.color.r / 100, barConfig.color.g / 100, barConfig.color.b / 100}
		end

		local function updateFillBar(fillBarElement, barConfig)
			fillBarElement.parent.borderTop = 0
			fillBarElement.parent.borderBottom = 0
			fillBarElement.parent.borderLeft = 0
			fillBarElement.parent.borderRight = 0
			self:updateVisibility(fillBarElement.parent, barConfig.visible)
			-- self:updateAlpha(fillBarElement.parent, barConfig.alpha)
			self:updateSize(fillBarElement, barConfig.width, barConfig.height)
			self:updatePosition(fillBarElement.parent, barConfig.position)
			updateFillBarColor(fillBarElement, barConfig)
			fillBarElement.widget.showText = barConfig.showValues

			-- Merlord's Ashfall compatibility
			for _, child in pairs(fillBarElement.children) do
				if string.startswith(child.name, "Ashfall") then
					child.height = barConfig.height
				end
			end

			fillBarElement:updateLayout()
		end

		local healthFillBar = self.elements.healthBar:findChild(self.uuids.menuStatHealthFillBar)
		local magicFillBar = self.elements.magicBar:findChild(self.uuids.menuStatMagicFillBar)
		local fatigueFillBar = self.elements.fatigueBar:findChild(self.uuids.menuStatFatigueFillBar)
		updateFillBar(healthFillBar, config.current.healthBar)
		updateFillBar(magicFillBar, config.current.magicBar)
		updateFillBar(fatigueFillBar, config.current.fatigueBar)
		if tes3.mobilePlayer then
			healthFillBar.widget.max = tes3.mobilePlayer.health.base
			healthFillBar.widget.current = tes3.mobilePlayer.health.current
			magicFillBar.widget.max = tes3.mobilePlayer.magicka.base
			magicFillBar.widget.current = tes3.mobilePlayer.magicka.current
			fatigueFillBar.widget.max = tes3.mobilePlayer.fatigue.base
			fatigueFillBar.widget.current = tes3.mobilePlayer.fatigue.current
		end
	end
end

function hud:updateNpcHealthBar()
	if self.elements.npcHealthBar then
		local config = self.mod.config
		self:updateVisibility(self.elements.npcHealthBar.parent, config.current.npcHealthBar.visible)
		self:updateSize(self.elements.npcHealthBar, config.current.npcHealthBar.width, config.current.npcHealthBar.height)
		self:updatePosition(self.elements.npcHealthBar.parent, config.current.npcHealthBar.position)
		self.elements.npcHealthBar:updateLayout()
	end
end

function hud:updateActiveMagicEffects()
	if self.elements.activeMagicEffects then
		local config = self.mod.config
		self.elements.activeMagicEffects.autoWidth = true
		self.elements.activeMagicEffects.autoHeight = true
		self.elements.activeMagicEffects.flowDirection = config.current.activeMagicEffects.layout
		local magicIconsBox = self.elements.activeMagicEffects:findChild(self.uuids.menuMultiMagicIconsBox)
		if magicIconsBox then
			magicIconsBox.alpha = 0.5
			magicIconsBox.flowDirection = config.current.activeMagicEffects.layout
			for _, child in pairs(magicIconsBox.children) do
				child.flowDirection = config.current.activeMagicEffects.layout
				child:updateLayout()
			end
			magicIconsBox:updateLayout()
		end
		self:updateVisibility(self.elements.activeMagicEffects, config.current.activeMagicEffects.visible)
		self:updatePosition(self.elements.activeMagicEffects, config.current.activeMagicEffects.position)
		self.elements.activeMagicEffects:updateLayout()
	end
end

function hud:updateMap()
	if self.elements.map then
		local config = self.mod.config
		local mapPanel = self.elements.map:findChild(self.uuids.menuMapPanel)
		self.elements.map.autoWidth = true
		self.elements.map.autoHeight = true
		self.elements.map.alpha = 1.0
		self:updateVisibility(self.elements.map, config.current.map.visible)
		-- self:updateAlpha(self.elements.map, config.current.map.alpha)
		self:updateSize(mapPanel, config.current.map.width, config.current.map.height)
		self:updatePosition(self.elements.map, config.current.map.position)
		mapPanel:updateLayout()
		self.elements.map:updateLayout()
	end
end

function hud:updateEquippedWeapon()
	if self.elements.equippedWeapon then
		local config = self.mod.config
		self:updateVisibility(self.elements.equippedWeapon, config.current.equippedWeapon.visible)
		-- self:updateAlpha(self.elements.equippedWeapon, config.current.equippedWeapon.alpha)
		self:updatePosition(self.elements.equippedWeapon, config.current.equippedWeapon.position)
	end
end

function hud:updateEquippedMagic()
	if self.elements.equippedMagic then
		local config = self.mod.config
		self:updateVisibility(self.elements.equippedMagic, config.current.equippedMagic.visible)
		-- self:updateAlpha(self.elements.equippedMagic, config.current.equippedMagic.alpha)
		self:updatePosition(self.elements.equippedMagic, config.current.equippedMagic.position)
	end
end

function hud:updateSneakIndicator()
	if self.elements.sneakIndicator then
		local config = self.mod.config
		self.elements.sneakIndicator.width = 36
		self.elements.sneakIndicator.height = 36
		self:updateVisibility(self.elements.sneakIndicator, config.current.sneakIndicator.visible)
		-- self:updateAlpha(self.elements.sneakIndicator, config.current.sneakIndicator.alpha)
		self:updatePosition(self.elements.sneakIndicator, config.current.sneakIndicator.position)
	end
end

function hud:updateEquippedNotification()
	if self.elements.equippedNotification then
		local config = self.mod.config
		self:updatePosition(self.elements.equippedNotification, config.current.equippedNotification.position)
		if not config.current.equippedNotification.visible then
			self.elements.equippedNotification.absolutePosAlignX = 10.0
			self.elements.equippedNotification.absolutePosAlignY = 10.0
			self.elements.equippedNotification.borderAllSides = -100
		end
		self.elements.equippedNotification:updateLayout()
	end
end

function hud:updateMapNotification()
	if self.elements.mapNotification then
		local config = self.mod.config
		self:updatePosition(self.elements.mapNotification, config.current.mapNotification.position)
		if not config.current.mapNotification.visible then
			self.elements.mapNotification.absolutePosAlignX = 10.0
			self.elements.mapNotification.absolutePosAlignY = 10.0
			self.elements.mapNotification.borderAllSides = -100
		end
		self.elements.mapNotification:updateLayout()
	end
end

function hud:updateModElements()
	local updatedElementCount = 0
	local menuMulti = tes3ui.findMenu(self.uuids.menuMulti)
	if menuMulti then
		for modElementName, modElementConfig in pairs(self.mod.config.current.mods) do
			local element = menuMulti:findChild(tes3ui.registerID(modElementName))
			if element then
				self.elements[modElementName] = element
				if modElementConfig.options.visibility then
					self:updateVisibility(element, modElementConfig.visible)
				end
				if modElementConfig.options.position then
					self:updatePosition(element, {x = modElementConfig.positionX, y = modElementConfig.positionY})
				end
				if modElementConfig.options.size then
					self:updateSize(element, modElementConfig.width, modElementConfig.height)
				end
				updatedElementCount = updatedElementCount + 1
				self.logger:trace(string.format("Updated mod element '%s'", modElementConfig.name))
			end
		end
	end
	self.logger:debug(string.format("Updated %d mod elements", updatedElementCount))
end

function hud:updateMenuMulti()
	local menuMulti = tes3ui.findMenu(self.uuids.menuMulti)
	if menuMulti then
		-- Main
		local menuMultiMain = menuMulti:findChild(self.uuids.menuMultiMain)
		if menuMultiMain then
			menuMultiMain.parent.paddingAllSides = 0
			menuMultiMain.widthProportional = nil
			menuMultiMain.heightProportional = nil
			self:expandElementToViewport(menuMultiMain)
			menuMultiMain:updateLayout()
		end

		-- Bottom row
		local bottomRow = menuMulti:findChild(self.uuids.menuMultiBottomRow)
		if bottomRow then
			bottomRow.borderTop = 0
			bottomRow.widthProportional = nil
			self:expandElementToViewport(bottomRow)

			-- Bars, equipped weapon/magic, sneak indicator, equipped notification
			local bottomRowLeft = bottomRow.children[1]
			if bottomRowLeft then
				self:expandElementToViewport(bottomRowLeft)

				-- Player bars
				local fillBarsLayout = bottomRowLeft:findChild(self.uuids.menuMultiFillBarsLayout)
				if fillBarsLayout then
					self:expandElementToViewport(fillBarsLayout.parent)
					self:expandElementToViewport(fillBarsLayout)
					fillBarsLayout.parent.consumeMouseEvents = false
					fillBarsLayout.consumeMouseEvents = false
					self.elements.healthBar = fillBarsLayout:findChild(self.uuids.menuStatHealthFillBar).parent
					self.elements.magicBar = fillBarsLayout:findChild(self.uuids.menuStatMagicFillBar).parent
					self.elements.fatigueBar = fillBarsLayout:findChild(self.uuids.menuStatFatigueFillBar).parent
					self:updatePlayerBars()
					fillBarsLayout.parent:updateLayout()
					fillBarsLayout:updateLayout()
				end

				-- NPC health bar
				self.elements.npcHealthBar = bottomRowLeft:findChild(self.uuids.menuMultiNpcHealthBar)
				self:updateNpcHealthBar()

				-- Equipped weapon
				self.elements.equippedWeapon = bottomRowLeft:findChild(self.uuids.menuMultiWeaponLayout)

				-- Equipped weapon/magic/sneak indicator block
				local equippedBlock = self.elements.equippedWeapon.parent.parent
				self:expandElementToViewport(equippedBlock)
				self:disableMouseEvents(equippedBlock)
				for _, child in pairs(equippedBlock.children) do
					self:expandElementToViewport(child)
					self:disableMouseEvents(child)
				end
				self:updateEquippedWeapon()

				-- Equipped magic
				self.elements.equippedMagic = bottomRowLeft:findChild(self.uuids.menuMultiMagicLayout)
				self:updateEquippedMagic()

				-- Sneak indicator
				self.elements.sneakIndicator = bottomRowLeft:findChild(self.uuids.menuMultiSneakIcon)
				self:updateSneakIndicator()

				-- Equipped notification
				self.elements.equippedNotification = bottomRowLeft:findChild(self.uuids.menuMultiWeaponMagicNotify)
				self:updateEquippedNotification()

				self.elements.equippedWeapon.parent.parent:updateLayout()
				self.elements.equippedWeapon.parent:updateLayout()

				bottomRowLeft:updateLayout()
			end

			-- Active magic effects, map, map notification
			local bottomRowRight = bottomRow.children[2]
			if bottomRowRight then
				self:expandElementToViewport(bottomRowRight)

				-- Active magic effects
				self.elements.activeMagicEffects = bottomRowRight:findChild(self.uuids.menuMultiMagicIconsLayout)
				self:updateActiveMagicEffects()

				-- Map
				self.elements.map = bottomRowRight:findChild(self.uuids.menuMapPanel).parent
				self:updateMap()

				-- Map notification
				self.elements.mapNotification = menuMulti:findChild(self.uuids.menuMultiMapNotify)
				self:updateMapNotification()

				bottomRowRight:updateLayout()
			end
			bottomRow:updateLayout()
		end
		menuMulti:getContentElement():registerAfter("update",
			function(eventData)
				-- This is a hack forcing MenuMulti to update.
				-- The content element has autoWidth set to true, therefore this does nothing besides forcing an update.
				-- For some reason this is only needed on certain resolutions. I'll be damned if I knew what kind of buttfuckery happens here.
				eventData.source.width = 0
			end
		)
		menuMulti:getContentElement():updateLayout()
		menuMulti:updateLayout()
	end
	self:updateModElements()
	self.logger:debug("Updated MenuMulti")
end

function hud:updateMenuStat()
	local menuStat = tes3ui.findMenu(self.uuids.menuStat)
	if menuStat then
		local config = self.mod.config

		local function updateFillBarColor(fillBarElement, configColor)
			fillBarElement.widget.fillColor = {configColor.r / 100, configColor.g / 100, configColor.b / 100}
		end

		updateFillBarColor(menuStat:findChild(self.uuids.menuStatHealthFillBar), config.current.healthBar.color)
		updateFillBarColor(menuStat:findChild(self.uuids.menuStatMagicFillBar), config.current.magicBar.color)
		updateFillBarColor(menuStat:findChild(self.uuids.menuStatFatigueFillBar), config.current.fatigueBar.color)
	end
	self.logger:debug("Updated MenuStat")
end

function hud:updateMenuStatReview()
	local menuStat = tes3ui.findMenu(self.uuids.menuStatReview)
	if menuStat then
		local config = self.mod.config

		local function updateFillBarColor(fillBarElement, configColor)
			fillBarElement.widget.fillColor = {configColor.r / 100, configColor.g / 100, configColor.b / 100}
		end

		updateFillBarColor(menuStat:findChild(self.uuids.menuStatHealthFillBarReview), config.current.healthBar.color)
		updateFillBarColor(menuStat:findChild(self.uuids.menuStatMagicFillBarReview), config.current.magicBar.color)
		updateFillBarColor(menuStat:findChild(self.uuids.menuStatFatigueFillBarReview), config.current.fatigueBar.color)
	end
	self.logger:debug("Updated MenuStatReview")
end

function hud:updateMenuSwimFillBar()
	local menuSwimFillBar = tes3ui.findHelpLayerMenu(self.uuids.menuSwimFillBar)
	if menuSwimFillBar then
		local config = self.mod.config
		self:updateVisibility(menuSwimFillBar, config.current.menuSwimFillBar.visible)
		self:updatePosition(menuSwimFillBar, config.current.menuSwimFillBar.position)
		menuSwimFillBar:updateLayout()
	end
	self.logger:debug("Updated MenuSwimFillBar")
end

function hud:updateMenuNotify()
	local config = self.mod.config

	local function updateNumberedMenuNotify(menuNotify)
		local function applyVerticalOffset()
			if menuNotify then
				menuNotify.positionY = menuNotify.positionY + config.current.menuNotify.position.y
				if config.current.menuNotify.flipped then
					menuNotify.positionY = (menuNotify.positionY * -1) + menuNotify.height
				end
			end
		end

		if menuNotify then
			self:updateVisibility(menuNotify, config.current.menuNotify.visible)
			menuNotify.absolutePosAlignX = config.current.menuNotify.position.x / 1000
			menuNotify:register("preUpdate", applyVerticalOffset)
		end
	end

	-- Todd, why did you do this to me?
	-- The positioning of this menu is cursed.
	updateNumberedMenuNotify(tes3ui.findHelpLayerMenu(self.uuids.menuNotify1))
	updateNumberedMenuNotify(tes3ui.findHelpLayerMenu(self.uuids.menuNotify2))
	updateNumberedMenuNotify(tes3ui.findHelpLayerMenu(self.uuids.menuNotify3))
	self.logger:debug("Updated MenuNotify")
end

function hud:update()
	self:updateMenuMulti()
	self:updateMenuStat()
	self:updateMenuStatReview()
	self.logger:debug("Updated")
end

function hud:onMorrowindInitialized(eventData)
	local priority = -2^16
	event.register("load", function() self.elements = {} end)
	event.register("loaded", function() self:updateMenuMulti() end)
	event.register("cellChanged", function() self:updateMap() end)
	event.register("uiActivated", function() self:updateMenuMulti() end, {filter = "MenuMulti", priority = priority})
	event.register("uiActivated", function() self:updateMenuStat() end, {filter = "MenuStat", priority = priority})
	event.register("uiActivated", function() self:updateMenuStatReview() end, {filter = "MenuStatReview", priority = priority})
	event.register("uiActivated", function() self:updateMenuSwimFillBar() end, {filter = "MenuSwimFillBar", priority = priority})
	event.register("uiActivated", function() self:updateMenuNotify() end, {filter = "MenuNotify1", priority = priority})
	event.register("uiActivated", function() self:updateMenuNotify() end, {filter = "MenuNotify2", priority = priority})
	event.register("uiActivated", function() self:updateMenuNotify() end, {filter = "MenuNotify3", priority = priority})
end

return hud