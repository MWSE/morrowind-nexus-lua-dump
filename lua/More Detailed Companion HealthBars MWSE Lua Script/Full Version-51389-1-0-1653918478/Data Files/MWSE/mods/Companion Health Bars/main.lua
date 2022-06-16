--[[
	Mod Name: Companion Health Bars
	Author: mesafoo
	Nexus URL: https://www.nexusmods.com/morrowind/mods/46136
	Description: Adds health bars for your companions to the in-game HUD.
	Credits: NullCascade, Hrnchamd, and all the others that have worked on MWSE, MGE and the MCP over the years. Hrnchamd's UI Inspector which was a big help in making this happen.
	NullCascade again for the companion detection, blacklist, and MCM menu code I used. And the very generous MIT license his mods are released under.
	And a big thanks to all the friendly and helpful people on the Morrowind Modding Community discord.
]]

--The table that will hold most of our information
local companionHealthBars = {}
--Text to prefix our log messages with
local logPrefix = "[Companion Health Bars] "

--Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20190401) then
	mwse.log("%sMWSE build date of %q does not meet minimum build date of 20190401.", logPrefix, mwse.buildDate)
	return
end

--Try to load existing config
local config = mwse.loadConfig("Companion Health Bars")
if (config == nil) then
	--Set to default values if saved config couldn't be loaded
	config = { blackList = {}, pollRate = 1, enableEvents = 1 , fatigka = 0}
else
	--Verify our saved options are expected types, and within expected limits
	if type(config.blackList) ~= "table" then
		config.blackList = {}
	end
	if type(config.enableEvents) == "number" then
		config.enableEvents = math.clamp(config.enableEvents, 0, 1)
	else
		config.enableEvents = 1
	end
	if type(config.fatigka) == "number" then
		config.fatigka = math.clamp(config.enableEvents, 0, 1)
	else
		config.fatigka = 0
	end
	if type(config.pollRate) == "number" then
		config.pollRate = math.clamp(config.pollRate, 1, 5)
	else
		config.pollRate = 1
	end
end

--Package to send to the mod config.
local modConfig = require("Companion Health Bars.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Companion Health Bars", modConfig)
end
event.register("modConfigReady", registerModConfig)

local function inBlackList(actor)
	local reference = actor.reference

	--Get the ID. If we're looking at an instance, check against the base object instead.
	local id = reference.id
	if (reference.object.isInstance) then
		id = reference.object.baseObject.id
	end
	--Check blacklist for actor's id and return result
	return table.find(config.blackList, id)
end

local function validCompanionCheck(mobileActor)
	--The player shouldn't count as his own companion.
	if (mobileActor == tes3.mobilePlayer) then
		return false
	end
	--Make sure the friendly actor is currently following player.
	if (tes3.getCurrentAIPackageId(mobileActor) ~= tes3.aiPackage.follow) then
		return false
	end
	--Respect the blacklist.
	if (inBlackList(mobileActor)) then
		return false
	end
	--Make sure we don't get dead actors.
	local animState = mobileActor.actionData.animationAttackState
	if (mobileActor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end

	return true
end

local function updateAllHealthBarValues()
	--Iterate over and refresh bars with updated values
	for companionRefID, companionBar in pairs(companionHealthBars.healthBars) do
		local companionRef = companionBar.companionRef
		local barWidget = companionBar.barMenu.widget
		local bar2Widget = companionBar.barMenu2.widget
		local bar3Widget = companionBar.barMenu3.widget
		local image = companionBar.image
		if not companionRef and not companionRef.mobile then return end
		local npcHealth = companionRef and companionRef.mobile and companionRef.mobile.health
		local npcMagicka = companionRef and companionRef.mobile and companionRef.mobile.magicka
		local npcFatigue = companionRef and companionRef.mobile and companionRef.mobile.fatigue
		companionBar.barMenu2.visible = config.fatigka ~= 0
		companionBar.barMenu3.visible = config.fatigka ~= 0
		if not barWidget then return end
		barWidget.max = npcHealth.base
		barWidget.current = npcHealth.current
		bar2Widget.max = npcMagicka.base
		bar2Widget.current = npcMagicka.current
		bar3Widget.max = npcFatigue.base
		bar3Widget.current = npcFatigue.current
		image:destroyChildren()
		image.alpha = tes3.worldController.menuAlpha
		local weapon = companionRef.mobile.readiedWeapon
		if weapon and weapon.object then
			local image1 = image:createImage({path = "Icons\\"..weapon.object.icon})
			image1.scaleMode = true
			image1.width = 32
			image1.height = 32
		else
			image:createImage({path = "Icons\\k\\Stealth_HandToHand.tga"})
		end
		local magic1 = companionRef.mobile.currentEnchantedItem
		local magic2 = companionRef.mobile.currentSpell
		if magic1 and magic1.object then
			local image1 = image:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
        	image1.scaleMode = true
        	image1.width = 32
        	image1.height = 32
			local image2 = image1:createImage({path = "Icons\\"..magic1.object.icon})
			image2.scaleMode = true
			image2.width = 32
			image2.height = 32
		elseif magic2 then
			local image2 = image:createImage({path = "Icons\\"..magic2.effects[1].object.bigIcon})
			image2.scaleMode = true
			image2.width = 32
			image2.height = 32
		else
			local image2 = image:createThinBorder()
			image2.width = 32
			image2.height = 32
		end
	end
end

local function createNewHealthBars(companions)
	--Iterate through the list of companions that don't currently have a health bar
	for i = #companions, 1, -1 do
		local companionRef = companions[i]
		--Create a label with the companion's name to go above the health bar
		local labelMenuID = tes3ui.registerID("CompanionHealthBars:"..companionRef.id..".label")
		local labelMenu = companionHealthBars.mainHealthBarMenu.menu:createBlock({id = labelMenuID})
		labelMenu.minWidth = 200
		labelMenu.autoWidth = true
		labelMenu.autoHeight = true
		labelMenu.flowDirection = "left_to_right"
		local text = labelMenu:createLabel{
			text = companionRef.object.name
		}
		--Add a top border to create some space between individual bars
		text.borderTop = 2
		local image = labelMenu:createRect({id = "CHB_SpaFork_images", color = {0,0,0}})
		image.alpha = tes3.worldController.menuAlpha
		image.autoHeight = true
		image.autoWidth = true
		image.flowDirection = "left_to_right"
		image.absolutePosAlignX = 1
		local weapon = companionRef.mobile.readiedWeapon
		if weapon and weapon.object then
			local image1 = image:createImage({path = "Icons\\"..weapon.object.icon})
			image1.scaleMode = true
			image1.width = 32
			image1.height = 32
		else
			image:createImage({path = "Icons\\k\\Stealth_HandToHand.tga"})
		end
		local magic1 = companionRef.mobile.currentEnchantedItem
		local magic2 = companionRef.mobile.currentSpell
		if magic1 and magic1.object then
			local image1 = image:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
        	image1.scaleMode = true
        	image1.width = 32
        	image1.height = 32
			local image2 = image1:createImage({path = "Icons\\"..magic1.object.icon})
			image2.scaleMode = true
			image2.width = 32
			image2.height = 32
		elseif magic2 then
			local image2 = image:createImage({path = "Icons\\"..magic2.effects[1].object.bigIcon})
			image2.scaleMode = true
			image2.width = 32
			image2.height = 32
		else
			local image2 = image:createThinBorder()
			image2.width = 32
			image2.height = 32
		end
		--Create a bar with the companion's current/max health
		local healthBarMenuID = tes3ui.registerID("CompanionHealthBars:"..companionRef.id..".bar")
		local healthBarMenu = companionHealthBars.mainHealthBarMenu.menu:createFillBar{
			id = healthBarMenuID,
			current = companionRef.mobile.health.current,
			max = companionRef.mobile.health.base
		}
		local magickaBarMenu = companionHealthBars.mainHealthBarMenu.menu:createFillBar{
			id = healthBarMenuID.."m",
			current = companionRef.mobile.magicka.current,
			max = companionRef.mobile.magicka.base
		}
		local fatigueBarMenu = companionHealthBars.mainHealthBarMenu.menu:createFillBar{
			id = healthBarMenuID.."f",
			current = companionRef.mobile.fatigue.current,
			max = companionRef.mobile.fatigue.base
		}
		fatigueBarMenu.widget.fillColor = tes3ui.getPalette("fatigue_color")
		magickaBarMenu.widget.fillColor = tes3ui.getPalette("magic_color")
		fatigueBarMenu.visible = config.fatigka ~= 0
		magickaBarMenu.visible = config.fatigka ~= 0
		--Make the bar reddish
		healthBarMenu.widget.fillColor = { 0.906, 0.302, 0.235 }
		--Add the health bar info to the table using the companion's reference as the key name
		companionHealthBars.healthBars[companionRef] = {
			companionRef = companionRef,
			labelMenuID = labelMenuID,
			labelMenu = labelMenu,
			barMenuID = healthBarMenuID,
			barMenu = healthBarMenu,
			barMenu2 = magickaBarMenu,
			barMenu3 = fatigueBarMenu,
			image = image,
		}
	end
end

local function removeExpiredHealthBars(companionTable)
	--Iterate over all the current health bars we have
	for companionRefID, companionBar in pairs(companionHealthBars.healthBars) do
		local stillValid = false
		for i = #companionTable, 1, -1 do
			--Remove valid companions that already have a bar from the list
			if companionTable[i] == companionBar.companionRef then
				stillValid = true
				table.remove(companionTable, i)
				break
			end
		end
		--Destroy any bars that exist for references that are no longer valid companions
		if stillValid == false then
			local labelMenu = companionHealthBars.mainHUD.menu:findChild(companionBar.labelMenuID)
			local barMenu = companionHealthBars.mainHUD.menu:findChild(companionBar.barMenuID)
			local barMenu2 = companionHealthBars.mainHUD.menu:findChild(companionBar.barMenuID.."m")
			local barMenu3 = companionHealthBars.mainHUD.menu:findChild(companionBar.barMenuID.."f")
			if labelMenu ~= nil and barMenu ~= nil then
				labelMenu:destroy()
				barMenu:destroy()
				barMenu2:destroy()
				barMenu3:destroy()
				companionHealthBars.healthBars[companionBar.companionRef] = nil
				--labelMenu = nil
				--barMenu = nil

			else
				mwse.log("%sFailed to find and destroy health bar for %q", logPrefix, companionRefID)
			end
		end
	end
end

local function createParentMenu()
	--Create the menu that holds the individual health bars and set some initial settings for it
	local menuID = tes3ui.registerID("CompanionHealthBars:Menu")
	if menuID ~= nil then
		local mainHUDMenu = companionHealthBars.mainHUD.menu
		local menuElement = mainHUDMenu:createRect{ id = menuID, { 1.0, 1.0, 1.0 } }
		if menuElement ~= nil then
			--Auto adjust dimensions to fit the health bars
			menuElement.autoHeight = true
			menuElement.autoWidth = true
			--Set the position to be top right of the screen and try to keep it in the same spot at various game resolutions
			menuElement.absolutePosAlignX = config.absolutePosAlignX or ((mainHUDMenu.width * 0.98) / mainHUDMenu.width)
			menuElement.absolutePosAlignY = config.absolutePosAlignY or (1.0 - ((mainHUDMenu.height * 0.9) / mainHUDMenu.height))
			--Propagate downwards as we add bars
			menuElement.flowDirection = "top_to_bottom"
			--Make it a bit transparent
			menuElement.alpha = 0.6
			--Add some padding so it overlaps the bars a bit
			menuElement.paddingAllSides = 4

			--Register for the events needed to allow repositioning the menu
			--Enable mouse capture in case cursor moves off menu while dragging
			menuElement:registerAfter("mouseDown", function()
				tes3ui.captureMouseDrag(true)
			end)
			--Set menu position to current mouse position while still dragging
			menuElement:registerAfter("mouseStillPressed", function(e)
				--Clamping position to account for the ~10px frame at the edges of the screen
				menuElement.absolutePosAlignX = math.clamp(((mainHUDMenu.width * 0.5) + e.data0), 10, mainHUDMenu.width - 10) / mainHUDMenu.width
				menuElement.absolutePosAlignY = 1.0 - math.clamp(((mainHUDMenu.height * 0.5) + e.data1), 10, mainHUDMenu.height - 10) / mainHUDMenu.height
				mainHUDMenu:updateLayout()
			end)
			--Release mouse capture after we're done with it and save the new position
			menuElement:registerAfter("mouseRelease", function()
				tes3ui.captureMouseDrag(false)
				config.absolutePosAlignX = menuElement.absolutePosAlignX
				config.absolutePosAlignY = menuElement.absolutePosAlignY
				mwse.saveConfig("Companion Health Bars", config)
			end)

			--Cache the info in our main table so we don't need to recreate this menu more than needed
			companionHealthBars.mainHealthBarMenu = { id = menuID, menu = menuElement }
		end
	end
	return (companionHealthBars.mainHealthBarMenu ~= nil and companionHealthBars.mainHealthBarMenu.menu ~= nil)
end

local function updateHealthBarMenu(companions)
	--Create our main menu if we don't have one yet
	if companionHealthBars.mainHealthBarMenu ~= nil or createParentMenu() == true then
		--Initialize subtable if it hasn't been already
		companionHealthBars.healthBars = companionHealthBars.healthBars or {}
		--Remove old health bars for invalid companions and cull companions list of companions already with bars
		removeExpiredHealthBars(companions)
		--Create bars for anyone remaining in companion list
		createNewHealthBars(companions)
		--Call updateLayout on the main health bar menu to update for any added/removed bars
		companionHealthBars.mainHealthBarMenu.menu:updateLayout()
		--Update the health values
		updateAllHealthBarValues()
	end
end

local function getMainHUD()
	--Try to get the menu for the game's main HUD that we'll be embedding our menu in
	local hudMenuID = tes3ui.registerID("MenuMulti")
	if hudMenuID ~= nil then
		local hudMenuElement = tes3ui.findMenu(hudMenuID)
		if hudMenuElement ~= nil then
			--Cache it in the main table for later use
			companionHealthBars.mainHUD = { id = hudMenuID, menu = hudMenuElement }
		end
	end
	return (companionHealthBars.mainHUD ~= nil and companionHealthBars.mainHUD.menu ~= nil)
end

local companionTable = {}
local function companionCheck()
	--Only update if not in menu mode.
	if tes3ui.menuMode() == false then
		if companionHealthBars.mainHUD ~= nil or getMainHUD() == true then
			--Create a list of player's current valid companions
			for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
				if (validCompanionCheck(mobileActor)) then
					companionTable[#companionTable + 1] = mobileActor.reference
				end
			end
			--Only update things if we found at least one valid companion
			if #companionTable ~= 0 then
				updateHealthBarMenu(companionTable)
				table.clear(companionTable)
			--Otherwise destroy the main health bar menu container and any of its child menus
			elseif companionHealthBars.mainHealthBarMenu ~= nil then
				companionHealthBars.mainHealthBarMenu.menu:destroy()
				companionHealthBars.mainHealthBarMenu = nil
				--Ensure the healthBar table is empty since the validCompanionCheck is occasionally wrong during cell changes
				table.clear(companionHealthBars.healthBars)
				--Update the main HUD
				companionHealthBars.mainHUD.menu:updateLayout()
			end
		else
			mwse.log("%sError getting mainHUD.", logPrefix)
		end
	end
end

--If the actor passed in has a health bar, update the values on it
local function updateHealthBarValues(npcReference)
	local healthBars = companionHealthBars.healthBars
	if healthBars then
		local npcBar = healthBars[npcReference]
		if npcBar then
			local barWidget = npcBar.barMenu.widget
			local npcHealth = npcReference.mobile.health
			barWidget.max = npcHealth.base
			barWidget.current = npcHealth.current
		end
	end
end

--Update health bar values on damage being taken
local function damagedCallback(e)
	updateHealthBarValues(e.reference)
end

--Update health bar values on restore health spelltick
local function spellTickCallback(e)
	if e.effectId == tes3.effect.restoreHealth then
		updateHealthBarValues(e.target)
	end
end

local companionCheckTimer
local eventsRegistered = false
--Function for reinitializing our timer and events. Called on initial game loaded event and after our mcm menu is closed to reflect any potential option changes
function modConfig.updateOptions()
	if companionCheckTimer ~= nil then
		companionCheckTimer:cancel()
	end
	companionCheckTimer = timer.start({ duration = config.pollRate, callback = companionCheck, iterations = -1 })

	if config.enableEvents == 0 and eventsRegistered == true then
		event.unregister("damaged", damagedCallback)
		event.unregister("spellTick", spellTickCallback)
		eventsRegistered = false
	elseif config.enableEvents == 1 and eventsRegistered == false then
		event.register("damaged", damagedCallback)
		event.register("spellTick", spellTickCallback)
		eventsRegistered = true
	end
end

if (config ~= nil) then
	--Register for the events we'll be using
	event.register("loaded", modConfig.updateOptions)
	event.register("load", (function() table.clear(companionHealthBars) end))
	mwse.log("%sInitialized: Loaded config:\n%s", logPrefix, json.encode(config, { indent = true }))
else
	mwse.log("%sERROR: Could not load config file!", logPrefix)
end

event.register("initialized", function()
	local seph = include("seph.hudCustomizer.interop")
	if seph then
---@diagnostic disable-next-line: need-check-nil
		seph:registerElement("CompanionHealthBars:Menu", "Companion HealthBars", {positionX = config.absolutePosAlignX, positionY = config.absolutePosAlignY, visible = true}, {position = true, visibility = true})
	end
end)