--[[
	Mod Initialization: Companion Health Bars
	Author: mesafoo
	Credits: NullCascade, and all the other MWSE devs for all the work they've done on MWSE. NullCascade again for the companion detection, blacklist, and MCM menu code I've used, and the very generous MIT license his mods are under.
	
	Adds health bars for your companions to the in-game HUD.

]]--

local companionHealthBarsTable = {}

local function logMessage(messageIn, debugLevel)
	debugLevel = debugLevel or 1
	if(debugLevel > 0) then
		mwse.log(messageIn)
		if(debugLevel > 1) then
			tes3.messageBox({message = messageIn})
		end
	end
end

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20190401) then
	logMessage("[Companion Health Bars] MWSE build date of" .. mwse.buildDate .. "does not meet minimum build date of 20190401.")
	return
end

local config = mwse.loadConfig("Companion Health Bars")
if (config == nil) then
	config = {blackList = {"chargen boat guard 2"}, pollRate = 1,}
end

-- Package to send to the mod config.
local modConfig = require("Companion Health Bars.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Companion Health Bars", modConfig)
end
event.register("modConfigReady", registerModConfig)

local function inBlackList(actor)
	local reference = actor.reference

	-- Get the ID. If we're looking at an instance, check against the base object instead.
	local id = reference.id
	if (reference.object.isInstance) then
		id = reference.object.baseObject.id
	end
	
	--Added check to make sure there is a blacklist before using table.find on it, else we'll get errors in the MWSE log.
	return (config.blackList and table.find(config.blackList, id) ~= nil)
end

local function validCompanionCheck(mobileActor)
	-- The player shouldn't count as his own companion.
	if (mobileActor == tes3.mobilePlayer) then
		return false
	end
	--Make sure the friendly actor is currently following player.
	if (tes3.getCurrentAIPackageId(mobileActor) ~= tes3.aiPackage.follow) then
		return false
	end
	-- Respect the blacklist.
	if (inBlackList(mobileActor)) then
		return false
	end
	-- Make sure we don't get dead actors.
	local animState = mobileActor.actionData.animationAttackState
	if (mobileActor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end

	return true
end

local function clearTable(tableToClear)
	for i = #tableToClear, 1, -1 do
		tableToClear[i] = nil
	end
end

local function refreshHealthBars()
	--Refresh health bars with updated health value.
	for i, healthBar in ipairs(companionHealthBarsTable) do
		healthBar.barMenu.widget.max = healthBar.companionReference.mobile.health.base
		healthBar.barMenu.widget.current = healthBar.companionReference.mobile.health.current
		if(i == #companionHealthBarsTable) then
			healthBar.parentMenu:updateLayout()
		end
	end
end

local function createHealthBar(gameHUD, parentMenu, parentMenuID, companion)
	--Create a label with the companion's name for the health bar.
	local labelMenuID = tes3ui.registerID("CompanionHealthBars:" .. companion.id .. ".label")
	local labelMenu = parentMenu:createLabel{id = labelMenuID, text = companion.object.name}
	--Add a bit of space between the health bars. A good value here is going to depend on personal taste I suppose.
	labelMenu.borderTop = 2
	--Create a bar with the companion's current/max health.
	local barMenuID = tes3ui.registerID("CompanionHealthBars:" .. companion.id ..".bar")
	local barMenu = parentMenu:createFillBar{id = barMenuID, current = companion.mobile.health.current, max = companion.mobile.health.base}
	--Make the bar red.
	barMenu.widget.fillColor = {0.906, 0.302, 0.235}
	--Add all our health bar info to the table.
	companionHealthBarsTable[#companionHealthBarsTable+1] = {companionReference = companion, parentMenuID = parentMenuID, parentMenu = parentMenu, labelMenuID = labelMenuID, labelMenu = labelMenu, barMenuID = barMenuID, barMenu = barMenu,}
end

local function checkHealthBars(companionTable, gameHUDID, gameHUD)
	--Traverse the table of health bars that are currently being shown.
	for i = #companionHealthBarsTable, 1, -1 do
		local isCompanion = false
		--Traverse the table of current companions.
		for j = #companionTable, 1, -1 do
			if(companionHealthBarsTable[i].companionReference == companionTable[j]) then
				--Companion already has a health bar, removing from table so they don't get another.
				isCompanion = true
				table.remove(companionTable, j)
				break
			end
		end
		--Remove health bar if actor is not a companion.
		if(isCompanion == false) then
			local menuLabel = gameHUD:findChild(companionHealthBarsTable[i].labelMenuID)
			local menuBar = gameHUD:findChild(companionHealthBarsTable[i].barMenuID)
			if(menuLabel ~= nil and menuBar ~= nil) then
				menuLabel:destroy()
				menuBar:destroy()
				table.remove(companionHealthBarsTable, i)
			else
				logMessage("[CompanionHealthBars] Error: Failed to destroy " .. healthBar.companionReference.id .. "'s Menus")
				return
			end
		end
	end
	--Check if health bars parent menu exists.
	local parentMenuID = tes3ui.registerID("CompanionHealthBars:Menu")
	local parentMenu
	if(parentMenuID ~= nil) then
		parentMenu = gameHUD:findChild(parentMenuID)
		if(parentMenu == nil) then
			--Create a parent menu it and fill out any needed properties.
			parentMenu = gameHUD:createRect{id = parentMenuID, {1.0, 1.0, 1.0}}
			parentMenu.autoHeight = true
			parentMenu.autoWidth = true
			parentMenu.absolutePosAlignX = ((gameHUD.width * 0.98) / gameHUD.width)
			parentMenu.absolutePosAlignY = (1.0 - ((gameHUD.height * 0.9) / gameHUD.height))
			parentMenu.flowDirection = "top_to_bottom"
			parentMenu.alpha = 0.6
			parentMenu.paddingAllSides = 4
		end
		--Create health bars for everyone remaining in companionTable.
		for i = #companionTable, 1, -1 do
			createHealthBar(gameHUD, parentMenu, parentMenuID, companionTable[i])
		end
	end
	--Refresh health bars if table is not empty.
	if(#companionHealthBarsTable ~= 0) then
		refreshHealthBars()
	end
end

local function companionCheck(e)
	--Check if in menu mode. Not sure if this is necessary.
	if (tes3.getWorldController().flagMenuMode == true) then
		return
	end
	--Create a table of all current companions.
	local companionTable = {}
	for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if (validCompanionCheck(mobileActor, tes3.mobilePlayer)) then
			companionTable[#companionTable+1] = mobileActor.reference
		end
	end
	--Get the games main hud menu element.
	local gameHUDID = tes3ui.registerID("MenuMulti")
	if(gameHUDID ~= nil) then
		local gameHUD = tes3ui.findMenu(gameHUDID)
		if(gameHUD ~= nil) then
			--If we have at least one companion, update the health bars.
			if(#companionTable ~= 0) then
				checkHealthBars(companionTable, gameHUDID, gameHUD)
			else
				--Else we have no companions, so we can destroy the health bars parent menu, which should also destroy any child health bars there may be remaining.
				if(#companionHealthBarsTable ~= 0) then
					local parentMenu = gameHUD:findChild(companionHealthBarsTable[#companionHealthBarsTable].parentMenuID)
					if(parentMenu ~= nil) then
						parentMenu:destroy()
						gameHUD:updateLayout()
						clearTable(companionHealthBarsTable)
					end
				end
			end
		end
	end
	
end

if(config ~= nil) then
	mwse.log("[Companion Health Bars] Loaded config:\n%s", json.encode(config, { indent = true }))
	event.register("loaded", (function(e) timer.start(config.pollRate, companionCheck, 0) end))
	event.register("load", (function(e) clearTable(companionHealthBarsTable) end))
else
	logMessage("[Companion Health Bars] ERROR: Could not load config file! Was installation done right?")
end