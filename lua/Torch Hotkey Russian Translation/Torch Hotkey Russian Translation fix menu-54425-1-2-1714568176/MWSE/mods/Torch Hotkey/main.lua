--[[
    Torch Hotkey
--]]
local modName = "Горячая клавиша факела"
local modDescription = "Этот небольшой мод добавляет отдельную горячую клавишу для источников света (по умолчанию \"c\"). При нажатии он активирует первый источник света в вашем инвентаре (отдает приоритет уже использованным). Работает с любым источником света, будь то ванильный или добавленный модом. При повторном нажатии возвращает ранее экипированные щиты, двуручное оружие и оружие дальнего боя."
local configPath = "TorchHotkey"
local defaultConfig = {
		torchKey = {
				keyCode = tes3.scanCode.c,
				isShiftDown = false,
				isAltDown = false,
				isControlDown = false
					}
				}
local config = mwse.loadConfig(configPath, defaultConfig)

local function unequipLight()
tes3.mobilePlayer:unequip{ type = tes3.objectType.light }
end

local function getFirstLight(ref)
	for stack in tes3.iterate(ref.object.inventory.iterator) do
		if stack.object.canCarry and stack.object.time ~= 0 then
			return stack.object
		end
	end
end

local lastShield
local lastWeapon
local lastRanged
local WeaponReady

local function swapForLight(e)
	-- Don't do anything in menu mode.
    if tes3.menuMode() then
        return
    end

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
		
		-- If our weapon was out before then take it out again
		if ( WeaponReady ) then
			tes3.mobilePlayer.weaponReady = true
		end
		
		return
    end

	-- If we don't have a light equipped, try to equip one.
    local light = getFirstLight(tes3.player)
    if light then
		lastShield = nil
		lastWeapon = nil
		lastRanged = nil
		WeaponReady = tes3.mobilePlayer.weaponReady
		
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
		
		-- If we were using a 2H weapon we need to un-ready from combat stance
        if ( lastWeapon or lastRanged ) then
            tes3.mobilePlayer.weaponReady = false
        end
		
		return
	end

	tes3.messageBox("У Вас отсутствует источник света")
end

local function initialized(e)
        event.register("keyDown", swapForLight, { filter = config.torchKey.keyCode })
        print("Initialized TorchHotkey v1.20")
    end

event.register("initialized", initialized)

--Menu Config Mog 
local function registerMCM()
    local template = mwse.mcm.createTemplate(modName)
	--template:saveOnClose(configPath, config)
	template.onClose = function ()
        mwse.saveConfig(configPath, config)
        initialized()
    end
	template:register()
	
	local page = template:createSideBarPage{
        label = "Настройки",
        description = modName.."\n\n"..modDescription
    }

	page:createKeyBinder({
		label = "Горячая клавиша факела",
		description = "Выберите клавишу для экипировки факела.",
		allowCombinations = true,
		variable = mwse.mcm.createTableVariable({
			id = "torchKey",
			table = config,
			defaultSetting = config.torchKey
		})
	})
end
event.register("modConfigReady", registerMCM)