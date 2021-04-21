--[[
	Morrowind Mouse Control
	@author		cpassuel
	@version	V1.3.3
	@changelog	1.0   Initial version
				1.1   Added Draw weapon with left click
				1.2   Added Not Ready mode spell/weapon cycling
				1.2.1 Added Quick Loot compatibility
				1.2.2 Added Pickpocket compatibility
				1.3   Added light support and modifier keys + mouse wheel
				1.3.1 Added ability to disable mouse wheel cycling in third person view
				1.3.2 Small fix : now can switch mode with QuickLoot/Pickpocket mod activated
				1.3.3 Small fix : activate mod after character creation (to avoid punching Jiub)
]]--

-- Cycle through Weapon ready / no weapon no spell / Spell ready
-- no weapon => equip hand to hand
-- no spell => no cycle to spell ready


--[[
	Variables
]]

-- https://unendli.ch/posts/2016-07-22-enumerations-in-lua.html
-- playerStates = {WeaponReady = 1, SpellReady = 2, NotReady = 3,}
modActions = { none = 0, CycleSpell = 1, CycleWeapon = 2, CycleLight = 3,}

local modName = "Morrowind Mouse Control"
local modVersion = "V1.3.3"
local modConfig = "MorrowindMouseControl"
local modAuthor= "cpassuel"

-- scancode for Prev/Next Spell/Weapon
local controlTypeNextWeapon = 13
local controlTypePrevWeapon = 14
local controlTypeNextSpell = 15
local controlTypePrevSpell = 16
local keyBindingArray = {}	-- array for keycode associated to control types

-- options list for modifier keys actions
local modifierKeyOptions = {
	{ label = "NONE", value = 0 },
	{ label = "Cycle Spells", value = 1 },
	{ label = "Cycle Weapons", value = 2 },
	-- { label = "Swap Light On and Off", value = 3 },
	-- { label = "Same as without modifier key", value = 4 },
}

-- action for extra mouse button
-- local extraMouseButtonOptions = {
	-- { label = "NONE", value = 0 },
	-- { label = "Prev Spell", value = 1 },
	-- { label = "Next Spell", value = 2 },
	-- { label = "Prev Weapon", value = 3 },
	-- { label = "Next Weapon", value = 4 },
-- }

-- action for Not Ready mode
local mouseWheelNotReadyOptions = {
	{ label = "NONE", value = 0 },
	{ label = "Cycle Spells", value = 1 },
	{ label = "Cycle Weapons", value = 2 },
	{ label = "Swap Light On and Off", value = 3 },
}

-- flag true if all Prev/Next Spell/Weapon commands are mapped to keyboard
local isKeyboardOnly
local activatemod = false	-- to prevent switching modes before character creation

--[[
	Compatibility check
	
	-- Mods using mouse wheel
	Pickpocket https://www.nexusmods.com/morrowind/mods/47581 ADDED
	QuickLoot https://www.nexusmods.com/morrowind/mods/46283 ADDED
	
	-- Mods not using custom menu
	inom - Inventory mouse wheel https://www.nexusmods.com/morrowind/mods/46847 NO NEED
	
	-- Mods to check
	Alchemy Helper Menu - MWSE Lua https://www.nexusmods.com/morrowind/mods/48141
	UI Expansion https://www.nexusmods.com/morrowind/mods/46071 ?
	Misc Mates https://www.nexusmods.com/morrowind/mods/48122
]]
local ignoredUIs = {
	["QuickLoot:Menu"] = true,
	["Pickpocket:Menu"] = true
}


--[[
	mod config
]]

-- Define mod config package
local modDefaultConfig = {
	modEnabled = true,
	-- Not Ready mode setting
	leftClickDrawWeapon = false,
	NotReadyWheelAction = 0,
	-- unequipLightOnWeapon = false,
	-- MouseWheel enable/disable
	spellReadyMouseWheel = true,
	weaponReadyMouseWheel = true,
	disableMouseWheel3rdPerson = true,
	-- mouse wheel modifier keys actions (default none)
	disableModifierKeyMenu = false,
	mwCtrlAction = 0,
	mwWindowsAction = 0,
	mwAltAction = 0,
	-- Extra mouse buttons
	mouseButton4Action = 0,
	mouseButton5Action = 0,
	-- mouse wheel threshold 
	mwThreshold = 1,
}

-- Load config file, and fill in default values for missing elements.
local config = mwse.loadConfig(modConfig)
if (config == nil) then
	config = modDefaultConfig
else
	for k, v in pairs(modDefaultConfig) do
		if (config[k] == nil) then
			config[k] = v
		end
	end
end


--[[
	helper functions
]]


-- get key binding for Prev/NextWeapon and Prev/NextSpell
local function getKeyBinding()
	-- https://mwse.readthedocs.io/en/latest/lua/guide/scancodes.html
	-- https://mwse.readthedocs.io/en/latest/mwscript/references.html#control-types
	local isAllKeyboardMapped = true
	
	local inputMaps = tes3.worldController.inputController.inputMaps
	for i = controlTypeNextWeapon, controlTypePrevSpell do
		-- offset +1 between control type and inputMaps array
		local mapping = inputMaps[i+1]
		if (mapping.device == 0) then
			keyBindingArray[i] = mapping.code
		else
			-- not mapped to keyboard
			keyBindingArray[i] = -1
			isAllKeyboardMapped = false
		end
	end
	
	return isAllKeyboardMapped
end


-- when no spell equiped, equip the first one or first power
function equipFirstSpell()
	if tes3.mobilePlayer.currentSpell == nil then
		-- send controlTypeNextSpell or controlTypePrevSpell after checking if keyboard mapped
		if keyBindingArray[controlTypeNextSpell] >= 0 then
			tes3.tapKey(keyBindingArray[controlTypeNextSpell])
		elseif keyBindingArray[controlTypePrevSpell] >= 0 then
			tes3.tapKey(keyBindingArray[controlTypePrevSpell])
		end
	end
end


-- Cycie spells according to the direction
-- dir = direction 
local function CycleSpell(dir)
	if (dir >= config.mwThreshold) then
		if keyBindingArray[controlTypeNextSpell] >= 0 then
			tes3.tapKey(keyBindingArray[controlTypeNextSpell])
		end
	elseif (dir <= -config.mwThreshold) then
		if keyBindingArray[controlTypePrevSpell] >= 0 then
			tes3.tapKey(keyBindingArray[controlTypePrevSpell])
		end
	end
end


-- Cycie weapons according to the direction
-- dir = direction 
local function CycleWeapon(dir)
	if (dir >= config.mwThreshold) then
		if keyBindingArray[controlTypeNextWeapon] >= 0 then
			tes3.tapKey(keyBindingArray[controlTypeNextWeapon])
		end
	elseif (dir <= -config.mwThreshold) then
		if keyBindingArray[controlTypePrevWeapon] >= 0 then
			tes3.tapKey(keyBindingArray[controlTypePrevWeapon])
		end
	end
end


--
local function extraMouseButtonAction(action)
end

--[[
	light support
	based on Torch Hotkey https://www.nexusmods.com/morrowind/mods/45747
	by Remiros, Greatness7 and NullCascade
]]

local lastShield
local lastWeapon
local lastRanged

-- unequip torch / lamp
local function unequipLight()
	tes3.mobilePlayer:unequip{ type = tes3.objectType.light }
end

-- retrieve the first torch / lamp
local function getFirstLight()
    for stack in tes3.iterate(tes3.player.object.inventory.iterator) do
        if stack.object.canCarry then
            return stack.object
        end
    end
end


local function swapForLight()
    -- Look to see if we have a light equipped. If we have one, unequip it.
    local lightStack = tes3.getEquippedItem{ actor = tes3.player, objectType = tes3.objectType.light }
    if (lightStack) then
        unequipLight()

        -- If we had a shield equipped before, re-equip it.
        if (lastShield) then
            mwscript.equip{ reference = tes3.player, item = lastShield }
        end

        -- If we had a 2H weapon equipped before, re-equip it.
        if (lastWeapon) then
            mwscript.equip{ reference = tes3.player, item = lastWeapon }
        end
    
        -- If we had a ranged weapon equipped before, re-equip it.
        if (lastRanged) then
            mwscript.equip{ reference = tes3.player, item = lastRanged }
        end

        return
    end

    -- If we don't have a light equipped, try to equip one.
    local light = getFirstLight()
    if light then
    	lastShield = nil
		lastWeapon = nil
		lastRanged = nil
    
        -- Store the currently equipped shield, if any.
        local shieldStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield })
        if (shieldStack) then
            lastShield = shieldStack.object
        end
    
        -- Store the currently equipped 2H weapon, if any.
        local weaponStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon})
        if (weaponStack and weaponStack.object.isTwoHanded) then
            lastWeapon = weaponStack.object
        end
    
        -- Store the currently equipped ranged weapon, if any.
        local rangedStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon})
        if (rangedStack and rangedStack.object.isRanged) then
            lastRanged = rangedStack.object
        end

        -- Equip the light we found.
        mwscript.equip{ reference = tes3.player, item = light}
    	return
  	end

    --tes3.messageBox("You have no lights")
end


--[[
	event handlers 
]]

-- Cycle through spells or weapons
-- https://mwse.readthedocs.io/en/latest/lua/event/mouseWheel.html
local function onMouseWheel(e)
	local action = -1	-- no modifier key pressed
	
	-- prevent mode switching before character creation
	if not activatemod then	
		return
	end
	
	-- 
	if not config.modEnabled or not isKeyboardOnly then
		return
	end

	-- only in game, and filter custom menus
	if tes3.menuMode() or ignoredUIs[tostring(tes3ui.getMenuOnTop())] then
		return
	end

	-- cycling unendli in third peron view ?
	if tes3.is3rdPerson() and config.disableMouseWheel3rdPerson then
		return
	end
	
	-- get action from config if modifier key pressed - priority (CTRL, Windows, Alt)
	if e.isControlDown then
		action = config.mwCtrlAction
	elseif e.isSuperDown then
		action = config.mwWindowsAction
	elseif e.isAltDown then
		action = config.mwAltAction
	end
	
	-- determine action to make depending on player mode and config
	if action == -1 or action == 4 then
		-- no modifier key or same action as without modifier => depending on player status
		if (tes3.mobilePlayer.weaponDrawn) then
			action = modActions.CycleWeapon
		elseif (tes3.mobilePlayer.spellReadied) then
			action = modActions.CycleSpell
		else
			-- not ready => get the not ready action from config
			--tes3.mobilePlayer.attackDisabled = true ?
			action = config.NotReadyWheelAction
		end
	end

	-- apply action
	if action == modActions.CycleWeapon then
		CycleWeapon(e.delta)
	elseif action == modActions.CycleSpell then
		CycleSpell(e.delta)
	elseif action == modActions.CycleLight then
		swapForLight()
	end
end


-- cycle spell / weapon on mouse button 2
local function onMouseButtonDown(e)

	-- prevent mode switching before character creation
	if not activatemod then	
		return
	end

	if not config.modEnabled then
		return
	end

	-- only in game, and allows custom menus
	if tes3.menuMode() then
		return
	end	

	if (e.button == 2) then
		-- mouse wheel button
		
		-- equip spell/power if none equiped
		equipFirstSpell()
		-- beware if no spell/scroll => cycle to nothing ready
		
		-- Cycle through Weapon ready / no weapon no spell / Spell ready
		-- https://mwse.readthedocs.io/en/latest/lua/type/tes3mobilePlayer/weaponReady.html
		-- https://mwse.readthedocs.io/en/latest/lua/type/tes3mobilePlayer/castReady.html
		if tes3.mobilePlayer.weaponDrawn then
			-- weapon ready to no weapon
			tes3.mobilePlayer.weaponReady = false
			return
		end
		
		if tes3.mobilePlayer.spellReadied then
			-- Spell ready to weapon ready
			tes3.mobilePlayer.weaponReady = true
			return
		end
		
		-- no spell no weapon to spell ready
		tes3.mobilePlayer.castReady = true
	elseif (e.button == 0) and config.leftClickDrawWeapon then
		-- left mouse button
		if not tes3.mobilePlayer.weaponDrawn and not tes3.mobilePlayer.spellReadied then
			tes3.mobilePlayer.weaponReady = true
		end
	elseif (e.button == 3) then
		extraMouseButtonAction(config.mouseButton4Action)
	elseif (e.button == 4) then
		extraMouseButtonAction(config.mouseButton5Action)
	end
end


-- refresh keybinding when leaving menu and set isKeyboardOnly flag 
local function onMenuExit()
	isKeyboardOnly = getKeyBinding()
end


-- https://mwse.readthedocs.io/en/latest/lua/event/journal.html
local function onJournal(e)
	activatemod = true
	event.unregister("journal", onJournal)
end


-- https://mwse.readthedocs.io/en/latest/lua/event/loaded.html
local function onLoaded(e)
	if e.newGame then
		activatemod = false
		event.register("journal", onJournal)
	else
		activatemod = true
	end
end


--[[
	constructor
]]

local function initialize()
	isKeyboardOnly = getKeyBinding()
	event.register("mouseWheel", onMouseWheel)
	event.register("mouseButtonDown", onMouseButtonDown)
	event.register("menuExit", onMenuExit)
	event.register("loaded", onLoaded)
	mwse.log(modName .. " initialized")
	if not isKeyboardOnly then
		tes3.messageBox(modName .. " - some prev/next spell/weapon controls not mapped to keyboard. It will affect the mod behaviour")
	end
end
event.register("initialized", initialize)


--[[
	mod config menu
]]

local function createtableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}  
end


--[[
	Menu structure

	Main Setting
	  Enable
	Mod Settings
		No Ready mode Setting
			Cycle Action
			Skyrim mode
		Mouse Wheel Setting
			Spell Ready
			Weapon Ready
		Modifier keys settings
			Ctrl Cycle Action
			Alt Cycle Action
			Windows Cycle Action
			disable modifier key on menu
		Extra mouse buttons settings
]]


local function registerModConfig()
    local template = mwse.mcm.createTemplate(modName)
	template:saveOnClose(modConfig, config)
	
    local page = template:createSideBarPage{
		label = "Sidebar Page",
		description = modName .. " " .. modVersion .. 
		"\n\nThis mod allows you to replace all keyboard commands for Weapon Ready/Spell Ready with mouse click and to select Weapons/Spells/Light with mouse wheel." ..
		"\n\nYou can switch between Weapon Ready / Not Ready / Spell Ready modes with the Middle mouse button. In Weapon Ready mode you will cycle weapons with the mouse wheel and in Spell Ready mode you will cycle spells/powers." ..
		"\n\nIn Not Ready mode you can choose if you want to cycle spells or weapons or turn light On and Off" ..
		"\n\nModifier keys (Ctrl, Alt, Windows) + mouse wheel are now supported so you can define a specific action when using mouse wheel while holding down a modifier key"
	}
	
    local catMain = page:createCategory(modName)
	catMain:createYesNoButton {
		label = "Enable " .. modName,
		description = "Allows you to Enable or Disable the mod",
		variable = createtableVar("modEnabled"),
		defaultSetting = true,
	}

	local catSettings = page:createCategory("Mod Settings")
    local catNotReady = catSettings:createCategory("Not Ready mode settings")
	catNotReady:createYesNoButton {
		label = "Draw weapon with left mouse click in Not Ready mode (i.e. Skyrim mode)",
		description = "Allows to draw equiped weapon with Left mouse click in Not Ready mode like in Skyrim",
		variable = createtableVar("leftClickDrawWeapon"),
		defaultSetting = false,
	}

	catNotReady:createDropdown {
		label = "Action for mouse wheel in Not Ready mode",
		description = "Select the wanted action when using mouse wheel from None to Cycle Spells, Cycle Weapons or Turn light On or Off",
		options = mouseWheelNotReadyOptions,	  
		variable = createtableVar("NotReadyWheelAction"),
		defaultSetting = 0,
	}

	local catMouseWheel = catSettings:createCategory("Mouse Wheel settings")
	catMouseWheel:createYesNoButton {
		label = "Disable Weapon/Spell/Torch cycling in third person view",
		description = "Disable Weapon/Spell/Torch cycling in third person view for people using mouse wheel to zoom in/out",
		variable = createtableVar("disableMouseWheel3rdPerson"),
		defaultSetting = false,
	}
	
	--
	local catModifiers = catSettings:createCategory("Modifier keys + Mouse Wheel settings")
	catModifiers:createDropdown {
		label = "Action for CTRL + MouseWheel",
		description = "Select the wanted action when using mouse wheel while holding CTRL key down",
		options = modifierKeyOptions,	  
		variable = createtableVar("mwCtrlAction"),
		defaultSetting = 0,
	}

	catModifiers:createDropdown {
		label = "Action for ALT + MouseWheel",
		description = "Select the wanted action when using mouse wheel while holding ALT key down",
		options = modifierKeyOptions,	  
		variable = createtableVar("mwAltAction"),
		defaultSetting = 0,
	}
	
	catModifiers:createDropdown {
		label = "Action for Windows + MouseWheel",
		description = "Select the wanted action when using mouse wheel while holding Windows key down",
		options = modifierKeyOptions,	  
		variable = createtableVar("mwWindowsAction"),
		defaultSetting = 0,
	}
	
	--
	-- local catExtraButtons = catSettings:createCategory("Extra Mouse Buttons (Experimental)")
	-- catExtraButtons:createDropdown {
		-- label = "Action for Mouse Button 4",
		-- description = "Select action for Mouse Button #4",
		-- options = extraMouseButtonOptions,	  
		-- variable = createtableVar("mouseButton4Action"),
		-- defaultSetting = 0,
	-- }
	
	-- catExtraButtons:createDropdown {
		-- label = "Action for Mouse Button 5",
		-- description = "Select action for Mouse Button #5",
		-- options = extraMouseButtonOptions,	  
		-- variable = createtableVar("mouseButton5Action"),
		-- defaultSetting = 0,
	-- }
	
	--
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
