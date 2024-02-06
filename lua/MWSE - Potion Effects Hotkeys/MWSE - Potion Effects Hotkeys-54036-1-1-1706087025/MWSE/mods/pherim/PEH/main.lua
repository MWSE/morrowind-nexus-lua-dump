--[[
    Potion Effects Hotkeys
--]]

local configPath = "Potion Effects Hotkeys"

-- The config table
local config = mwse.loadConfig(configPath, {
	iEffectsSearched = 1,
	iMaxPotionEffects = 2,
    bRHealthEnabled = true,
	keyHealth = {keyCode = tes3.scanCode.g},
	bRMagickaEnabled = true,
	keyMagicka = {keyCode = tes3.scanCode.b},
	bRFatigueEnabled = true,
	keyFatigue = {keyCode = tes3.scanCode.v},
	bMiscEnabled = true,
	keyMisc = {keyCode = tes3.scanCode.h},
	miscEffect = 0,
	miscAttribute = 0,
})

local function checkCC()	
	-- Check if Controlled Consumption Cooldown is active
	local menuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	if menuMulti then
		local icons = menuMulti:findChild(tes3ui.registerID("MenuMulti_weapon_layout")).parent.children
		for i=1, #icons do
			if icons[i].children and icons[i].children[1] then
				if icons[i].children[1].contentPath and icons[i].children[1].contentPath == "icons\\nc\\potions_blocked.tga" then
					if icons[i].visible == true then
						return true
					else
						return false
					end
				end
			end
		end
	end	
end

local function getEffect()

	local mEffect

	local inputController = tes3.worldController.inputController
	if config.bRHealthEnabled == true and inputController:isKeyDown(currentKeyHealth) then
		mEffect = 75
	elseif config.bRMagickaEnabled == true and inputController:isKeyDown(currentKeyMagicka) then
		mEffect = 76
	elseif config.bRFatigueEnabled == true and inputController:isKeyDown(currentKeyFatigue) then
		mEffect = 77
	elseif config.bMiscEnabled == true and inputController:isKeyDown(currentKeyMisc) then
		mEffect = currentMiscEffect
	else 
		mEffect = -1
	end
	return mEffect;
end

local function getPotion(ref)
	local iSearchEffects
	
	if config.iEffectsSearched > config.iMaxPotionEffects then
		iSearchEffects = config.iMaxPotionEffects
	else
		iSearchEffects = config.iEffectsSearched
	end

	for stack in tes3.iterate(ref.object.inventory.iterator) do

		if stack.object.objectType == tes3.objectType.alchemy and stack.object:getActiveEffectCount() <= config.iMaxPotionEffects then
			for i = 1, iSearchEffects do				
				if stack.object.effects[i].id == getEffect() then
					-- check if the effect is Restore/Fortify Attribute
					if stack.object.effects[i].id == 74 or stack.object.effects[i].id == 79 then
						if stack.object.effects[i].attribute == currentMiscAttribute then
							return stack.object
						end
					else
						return stack.object
					end
				end
			end	
		end
	end
end

local function drinkPotion(e)
	if tes3.menuMode() then
		return
	end
	
	if (checkCC() == true) then
		tes3.messageBox("You cannot drink another potion right now.")
		return
	end
	
	if getEffect() == -1 then
		return
	end	
	
	local potion = getPotion(tes3.mobilePlayer)
	if potion then		
		local eventData = { item = potion, reference = tes3.player }
		event.trigger("equip", eventData, { filter = tes3.player })
		tes3.mobilePlayer:equip{ item = potion }
	else
		-- check if the effect is Restore/Fortify Attribute
		if tes3.getMagicEffect(getEffect()).id == 74 then
			tes3.messageBox("You don't have any Restore %s potions", tes3.getAttributeName(currentMiscAttribute))
		elseif tes3.getMagicEffect(getEffect()).id == 79 then
			tes3.messageBox("You don't have any Fortify %s potions", tes3.getAttributeName(currentMiscAttribute))
		else
			tes3.messageBox("You don't have any %s potions", tes3.getMagicEffect(getEffect()).name)
		end	
	end
end

local function mcmUpdated()
    -- unregister old event (if applicable)
    if event.isRegistered("keyDown", drinkPotion, { filter = currentKeyHealth }) then
        event.unregister("keyDown", drinkPotion, { filter = currentKeyHealth })
    end
    -- update key to current config setting
    currentKeyHealth = config.keyHealth.keyCode
    -- register new event (taking the new keybinding into account)
    event.register("keyDown", drinkPotion, { filter = currentKeyHealth })
    
	if event.isRegistered("keyDown", drinkPotion, { filter = currentKeyMagicka }) then
        event.unregister("keyDown", drinkPotion, { filter = currentKeyMagicka })
    end
    -- update key to current config setting
    currentKeyMagicka = config.keyMagicka.keyCode
    -- register new event (taking the new keybinding into account)
    event.register("keyDown", drinkPotion, { filter = currentKeyMagicka })
	
	if event.isRegistered("keyDown", drinkPotion, { filter = currentKeyFatigue }) then
        event.unregister("keyDown", drinkPotion, { filter = currentKeyFatigue })
    end
    -- update key to current config setting
    currentKeyFatigue = config.keyFatigue.keyCode
    -- register new event (taking the new keybinding into account)
    event.register("keyDown", drinkPotion, { filter = currentKeyFatigue })
	
	if event.isRegistered("keyDown", drinkPotion, { filter = currentKeyMisc }) then
        event.unregister("keyDown", drinkPotion, { filter = currentKeyMisc })
    end
    -- update key to current config setting
    currentKeyMisc = config.keyMisc.keyCode
    -- register new event (taking the new keybinding into account)
    event.register("keyDown", drinkPotion, { filter = currentKeyMisc })
	
	currentMiscEffect = config.miscEffect
	currentMiscAttribute = config.miscAttribute
end

local function initialized()
	mcmUpdated()
	print("Initialized Potion Effects Hotkeys")
end

event.register("initialized", initialized)

-- When the mod config menu is ready to start accepting registrations,
-- register this mod.
local function registerModConfig()
    -- Create the top level component Template
    -- The name will be displayed in the mod list on the lefthand pane
    local template = mwse.mcm.createTemplate({ name = "Potion Effects Hotkeys" })
	
	template.onClose = function (modConfigContainer)
        -- Save config options when the mod config menu is closed
        -- NOTE: you cant use `saveOnClose` with `onClose`, which is why 
        -- i'm putting `saveConfig` here
        mwse.saveConfig(configPath, config)
        mcmUpdated()
    end

    -- Create a simple container Page under Template
    local settings = template:createPage({ label = "Settings" })
	
	settings:createSlider{ label = "Ignore Potions with more than X effects",
		variable = mwse.mcm:createTableVariable({ id = "iMaxPotionEffects", table = config }),min = 1, max = 8, jump = 1, defaultSetting = 2}
	
	settings:createSlider{ label = "Search first X effects per potion",
		variable = mwse.mcm:createTableVariable({ id = "iEffectsSearched", table = config }),min = 1, max = 8, jump = 1, defaultSetting = 1}	

	local catHealth = settings:createCategory("Restore Health Potions")
	
    catHealth:createYesNoButton({
        label = "Enable Restore Health Potions Hotkey",
        variable = mwse.mcm:createTableVariable({ id = "bRHealthEnabled", table = config }),
    })
	
	catHealth:createKeyBinder({
    label = "Assign Hotkey",
    description = "Assign a new Hotkey for Restore Health Potions.",
    variable = mwse.mcm.createTableVariable{ id = "keyHealth", table = config },
    allowCombinations = false,
	})
	
	local catMagicka = settings:createCategory("Restore Magicka Potions")
	
	catMagicka:createYesNoButton({
        label = "Enable Restore Magicka Potions Hotkey",
        variable = mwse.mcm:createTableVariable({ id = "bRMagickaEnabled", table = config }),
    })
	
	catMagicka:createKeyBinder({
    label = "Assign Hotkey",
    description = "Assign a new Hotkey for Restore Magicka Potions.",
    variable = mwse.mcm.createTableVariable{ id = "keyMagicka", table = config },
    allowCombinations = false,
	})
	
	local catFatigue = settings:createCategory("Restore Fatigue Potions")
	
	catFatigue:createYesNoButton({
        label = "Enable Restore Fatigue Potions Hotkey",
        variable = mwse.mcm:createTableVariable({ id = "bRFatigueEnabled", table = config }),
    })
	
	catFatigue:createKeyBinder({
    label = "Assign Hotkey",
    description = "Assign a new Hotkey for Restore Fatigue Potions.",
    variable = mwse.mcm.createTableVariable{ id = "keyFatigue", table = config },
    allowCombinations = false,
	})
	
	local catMisc = settings:createCategory("Misc Potions")
	
	catMisc:createYesNoButton({
        label = "Enable Misc Hotkey",
        variable = mwse.mcm:createTableVariable({ id = "bMiscEnabled", table = config }),
    })
	
	catMisc:createKeyBinder({
    label = "Assign Hotkey",
    description = "Assign a new Hotkey for misc potions.",
    variable = mwse.mcm.createTableVariable{ id = "keyMisc", table = config },
    allowCombinations = false,
	})
	
	catMisc:createDropdown{
		label = "Effect:",
		options = {
			{ label = tes3.getMagicEffect(0).name, value = 0 }, -- Water Breathing
			{ label = tes3.getMagicEffect(1).name, value = 1 }, -- Swift Swim
			{ label = tes3.getMagicEffect(2).name, value = 2 }, -- Water Walking
			{ label = tes3.getMagicEffect(3).name, value = 3 }, -- Shield
			{ label = tes3.getMagicEffect(4).name, value = 4 }, -- Fire Shield
			{ label = tes3.getMagicEffect(5).name, value = 5 }, -- Lightning Shield
			{ label = tes3.getMagicEffect(6).name, value = 6 }, -- Frost Shield
			{ label = tes3.getMagicEffect(8).name, value = 8 }, -- Feather
			{ label = tes3.getMagicEffect(9).name, value = 9 }, -- Jump
			{ label = tes3.getMagicEffect(10).name, value = 10 }, -- Levitate
			{ label = tes3.getMagicEffect(11).name, value = 11 }, -- Slow Fall
			{ label = tes3.getMagicEffect(39).name, value = 39 }, -- Invisibility
			{ label = tes3.getMagicEffect(40).name, value = 40 }, -- Chameleon
			{ label = tes3.getMagicEffect(41).name, value = 41 }, -- Light
			{ label = tes3.getMagicEffect(42).name, value = 42 }, -- Sanctuary
			{ label = tes3.getMagicEffect(43).name, value = 43 }, -- Night Eye
			{ label = tes3.getMagicEffect(57).name, value = 57 }, -- Dispel
			{ label = tes3.getMagicEffect(59).name, value = 59 }, -- Telekinesis
			{ label = tes3.getMagicEffect(60).name, value = 60 }, -- Mark
			{ label = tes3.getMagicEffect(61).name, value = 61 }, -- Recall
			{ label = tes3.getMagicEffect(63).name, value = 63 }, -- Almsivi Intervention
			{ label = tes3.getMagicEffect(64).name, value = 64 }, -- Detect Animal
			{ label = tes3.getMagicEffect(65).name, value = 65 }, -- Detect Enchantment
			{ label = tes3.getMagicEffect(66).name, value = 66 }, -- Detect Key
			{ label = tes3.getMagicEffect(67).name, value = 67 }, -- Spell Absorption
			{ label = tes3.getMagicEffect(68).name, value = 68 }, -- Reflect
			{ label = tes3.getMagicEffect(69).name, value = 69 }, -- Cure Common Disease
			{ label = tes3.getMagicEffect(70).name, value = 70 }, -- Cure Blight Disease
			{ label = tes3.getMagicEffect(72).name, value = 72 }, -- Cure Poison
			{ label = tes3.getMagicEffect(73).name, value = 73 }, -- Cure Paralyzation
			{ label = tes3.getMagicEffect(74).name, value = 74 }, -- Restore Attribute**
			{ label = tes3.getMagicEffect(79).name, value = 79 }, -- Fortify Attribute**
			{ label = tes3.getMagicEffect(80).name, value = 80 }, -- Fortify Health
			{ label = tes3.getMagicEffect(81).name, value = 81 }, -- Fortify Magicka
			{ label = tes3.getMagicEffect(82).name, value = 82 }, -- Fortify Fatigue
			{ label = tes3.getMagicEffect(117).name, value = 117 }, -- Fortify Attack
			{ label = tes3.getMagicEffect(90).name, value = 90 }, -- Resist Fire
			{ label = tes3.getMagicEffect(91).name, value = 91 }, -- Resist Frost
			{ label = tes3.getMagicEffect(92).name, value = 92 }, -- Resist Shock
			{ label = tes3.getMagicEffect(93).name, value = 93 }, -- Resist Magicka
			{ label = tes3.getMagicEffect(94).name, value = 94 }, -- Resist Common Disease
			{ label = tes3.getMagicEffect(95).name, value = 95 }, -- Resist Blight Disease*
			{ label = tes3.getMagicEffect(97).name, value = 97 }, -- Resist Poison
			{ label = tes3.getMagicEffect(98).name, value = 98 }, -- Resist Normal Weapons*
			{ label = tes3.getMagicEffect(99).name, value = 99 }, -- Resist Paralysis
		}, -- * = Effect does not exist in vanilla potions or ingredients | ** = Uses separate setting for specified attribute
		variable = mwse.mcm.createTableVariable({ id = "miscEffect", table = config }),
		description = [[Potions with this effect are used with the misc potions hotkey]]
	}
	
	catMisc:createDropdown{
		label = "Attribute for Restore/Fortify Attribute Potions:",
		options = {
			{ label = tes3.getAttributeName(0), value = 0 }, -- Strength
			{ label = tes3.getAttributeName(1), value = 1 }, -- Intelligence
			{ label = tes3.getAttributeName(2), value = 2 }, -- Willpower
			{ label = tes3.getAttributeName(3), value = 3 }, -- Agility
			{ label = tes3.getAttributeName(4), value = 4 }, -- Speed
			{ label = tes3.getAttributeName(5), value = 5 }, -- Endurance
			{ label = tes3.getAttributeName(6), value = 6 }, -- Personality
			{ label = tes3.getAttributeName(7), value = 7 }, -- Luck
		},
		variable = mwse.mcm.createTableVariable({ id = "miscAttribute", table = config }),
		description = [[Restore/Fortify Attribute will use this attribute]]
	}

    -- Finish up.
    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)