--[[
    Torch Hotkey
--]]

local function unequipLight()
tes3.mobilePlayer:unequip{ type = tes3.objectType.light }
end

local function getFirstLight(ref)
    for stack in tes3.iterate(ref.object.inventory.iterator) do
        if stack.object.canCarry then
            return stack.object
        end
    end
end

local lastShield
local lastWeapon
local lastRanged

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

        return
    end

    -- If we don't have a light equipped, try to equip one.
    local light = getFirstLight(tes3.player)
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

    tes3.messageBox("У Вас отсутствует источник света")
end

local function initialized(e)
        event.register("keyDown", swapForLight, { filter = 46 })
        print("Initialized TorchHotkey v0.20")
    end

event.register("initialized", initialized)