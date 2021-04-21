local config = require("OperatorJack.SecurityEnhanced.config")
local options = require("OperatorJack.SecurityEnhanced.options")
local common = require("OperatorJack.SecurityEnhanced.common")

local function isAutoEquipOnActivateEnabled()
    if (config.lockpickAutoEquipOnActivate) then
        return true
    end
    return false
end

local function getHotkeyCycle()
    return config.lockpickEquipHotKeyCycle
end

local function getEquipOrder()
    return config.lockpickEquipOrder
end

local function hasLockpick()
    for node in tes3.iterate(tes3.player.object.inventory.iterator) do
        if (node.object.objectType == tes3.objectType.lockpick) then
            return true
        end
    end
    return false
end

local function isLockpickEquipped()
    return tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.lockpick
    }
end

local function unequipLockpick()
    tes3.mobilePlayer:unequip {
        type = tes3.objectType.lockpick
    }
end


local function equipLockpick(saveEquipment, cycle)
    if (saveEquipment) then
        -- Store current equipment.
        common.saveCurrentEquipment()
    end

    local currentLockpickStack = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = tes3.objectType.lockpick
    })
    local currentLockpick

    if (currentLockpickStack ~= nil) then
        currentLockpick = currentLockpickStack.object
    end

    local lockpick

    -- Lockpick isn't equipped. Equip one.
    local equipOrder = getEquipOrder()
    if (equipOrder == options.lockpick.equipOrder.BestLockpickFirst) then
        -- Choose highest level lockpick first.
        common.debug("Equipping Lockpick: Best Lockpick First")
        if (cycle) then
            lockpick = common.getNextBestObjectByObjectType(
                tes3.objectType.lockpick, 
                currentLockpick
            )
        else
            lockpick = common.getBestObjectByObjectType(tes3.objectType.lockpick)
        end
    elseif (equipOrder == options.lockpick.equipOrder.WorstLockpicKFirst) then
        -- Choose lowest level lockpick first.
        common.debug("Equipping Lockpick: Worst Lockpick First")
        if (cycle) then
            lockpick = common.getNextBestObjectByObjectType(
                tes3.objectType.lockpick, 
                currentLockpick
            )
        else
            lockpick = common.getWorstObjectByObjectType(tes3.objectType.lockpick)
        end
    end

    if (lockpick == nil) then
        common.debug("Could not find Lockpick.")
        return;
    end

    common.debug("Equipping Lockpick.")
    tes3.mobilePlayer:equip{
        item = lockpick
    }
end

local function cycleLockpick()
    -- Check for cycle option.
    local hotkeyCycle = getHotkeyCycle()
    if (hotkeyCycle == options.lockpick.equipHotKeyCycle.ReequipWeapon) then
        common.debug("Cycling: Requipping weapon.")
        -- Re-equip Weapon
        unequipLockpick()
        common.reequipEquipment()
    elseif (hotkeyCycle == options.lockpick.equipHotKeyCycle.NextLockpick) then
        common.debug("Cycling: Moving to next lockpick.")
        -- Cycle to Next Lockpick
        equipLockpick(false, true)
    end
end

local function keybindTest(b, e)
    return (b.keyCode == e.keyCode) and
    (b.isShiftDown == e.isShiftDown) and
    (b.isAltDown == e.isAltDown) and
    (b.isControlDown == e.isControlDown)
end

local function toggleLockpick(e)
    if (not keybindTest(config.lockpickEquipHotKey, e)) then
        common.debug("In hotkey event, invalid key pressed. Exiting event.")
        return
    end

    common.debug("Registered hotkey event.")

    -- Don't do anything in menu mode.
    if tes3.menuMode() then
        return
    end

    -- Check if lockpick is available.
    if (hasLockpick()) then
        -- Check if a lockpick is already equipped.
        if (isLockpickEquipped()) then
            common.debug("Lockpick is equipped. Cycling.")
            -- Cycle to next item based on configuration.
            cycleLockpick()
        else
            common.debug("Lockpick is not equipped. Equipping.")
            -- Equip lockpick based on configuration.
            equipLockpick(true, false)
        end
    end
end

local function autoEquipLockpick(e)
    if (e.target.object.objectType ~= tes3.objectType.door and 
        e.target.object.objectType ~= tes3.objectType.container
    ) then
        return
    end

    common.debug("Registered auto-equip for locked object event.")

    if (tes3.getLocked({
        reference = e.target
    })) then
        -- Check if lockpick is available.
        if (hasLockpick()) then
            -- Check if a lockpick is not already equipped.
            if (isLockpickEquipped() == nil) then
                -- Equip lockpick based on configuration.
                equipLockpick(true, false)

                -- Draw lockpick
                tes3.mobilePlayer.weaponReady = true
            end
        end
    end
end


local lockpick = {}

lockpick.registerEvents = function ()
    event.register("keyDown", toggleLockpick, { filter = config.lockpickEquipHotKey.keyCode })

    if (isAutoEquipOnActivateEnabled()) then
        event.register("activate", autoEquipLockpick)
    end
end

return lockpick

