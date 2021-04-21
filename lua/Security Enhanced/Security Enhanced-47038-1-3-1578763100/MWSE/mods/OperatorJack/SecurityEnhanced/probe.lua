local config = require("OperatorJack.SecurityEnhanced.config")
local options = require("OperatorJack.SecurityEnhanced.options")
local common = require("OperatorJack.SecurityEnhanced.common")

local function isAutoEquipOnActivateEnabled()
    if (config.probeAutoEquipOnActivate) then
        return true
    end
    return false
end

local function getHotkeyCycle()
    return config.probeEquipHotKeyCycle
end

local function getEquipOrder()
    return config.probeEquipOrder
end

local function hasProbe()
    for node in tes3.iterate(tes3.player.object.inventory.iterator) do
        if (node.object.objectType == tes3.objectType.probe) then
            return true
        end
    end
    return false
end

local function isProbeEquipped()
    return tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.probe
    }
end

local function unequipProbe()
    tes3.mobilePlayer:unequip {
        type = tes3.objectType.probe
    }
end

local function equipProbe(saveEquipment, cycle)
    if (saveEquipment) then
        -- Store current equipment.
        common.saveCurrentEquipment()
    end

    local currentProbeStack = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = tes3.objectType.probe
    })
    local currentProbe

    if (currentProbeStack ~= nil) then
        currentProbe = currentProbeStack.object
    end

    local probe

    -- Probe isn't equipped. Equip one.
    local equipOrder = getEquipOrder()
    if (equipOrder == options.probe.equipOrder.BestProbeFirst) then
        -- Choose highest level Probe first.
        common.debug("Equipping Probe: Best Probe First")
        if (cycle) then
            probe = common.getNextBestObjectByObjectType(
                tes3.objectType.probe, 
                currentProbe
            )
        else
            probe = common.getBestObjectByObjectType(tes3.objectType.probe)
        end
    elseif (equipOrder == options.probe.equipOrder.WorstProbeFirst) then
        -- Choose lowest level Probe first.
        common.debug("Equipping Probe: Worst Probe First")
        if (cycle) then
            probe = common.getNextBestObjectByObjectType(
                tes3.objectType.probe, 
                currentProbe
            )
        else
            probe = common.getWorstObjectByObjectType(tes3.objectType.probe)
        end
    end

    if (probe == nil) then
        common.debug("Could not find Probe.")
        return;
    end

    common.debug("Equipping Probe.")
    tes3.mobilePlayer:equip{
        item = probe
    }  
end

local function cycleProbe()
    -- Check for cycle option.
    local hotkeyCycle = getHotkeyCycle()
    if (hotkeyCycle == options.probe.equipHotKeyCycle.ReequipWeapon) then
        common.debug("Cycling: Requipping weapon.")
        -- Re-equip Weapon
        unequipProbe()
        common.reequipEquipment()
    elseif (hotkeyCycle == options.probe.equipHotKeyCycle.NextProbe) then
        common.debug("Cycling: Moving to next Probe.")
        -- Cycle to Next Probe
        equipProbe(false, true)
    end
end

local function keybindTest(b, e)
    return (b.keyCode == e.keyCode) and
    (b.isShiftDown == e.isShiftDown) and
    (b.isAltDown == e.isAltDown) and
    (b.isControlDown == e.isControlDown)
end

local function toggleProbe(e)
    if (not keybindTest(config.probeEquipHotKey, e)) then
        common.debug("In hotkey event, invalid key pressed. Exiting event.")
        return
    end

    common.debug("Registered hotkey event.")

    -- Don't do anything in menu mode.
    if tes3.menuMode() then
        return
    end

    -- Check if Probe is available.
    if (hasProbe()) then
        -- Check if a Probe is already equipped.
        if (isProbeEquipped()) then
            common.debug("Probe is equipped. Cycling.")
            -- Cycle to next item based on configuration.
            cycleProbe()
        else
            common.debug("Probe is not equipped. Equipping.")
            -- Equip Probe based on configuration.
            equipProbe(true, false)
        end
    end
end

local function autoEquipProbeOnActivate(e)
    if (e.target.object.objectType ~= tes3.objectType.door and 
        e.target.object.objectType ~= tes3.objectType.container) then
        return
    end

    common.debug("Registered auto-equip for locked object event.")

    if (tes3.getTrap({
        reference = e.target
    })) then
        -- Check if Probe is available.
        if (hasProbe()) then
            -- Check if a Probe is not already equipped.
            if (isProbeEquipped() == nil) then
                -- Equip Probe based on configuration.
                equipProbe(true, false)

                -- Draw probe.
                tes3.mobilePlayer.weaponReady = true

                -- Return false to stop current activation.
                return false
            end
        end
    end
end

local probe = {}

probe.registerEvents = function ()
    event.register("keyDown", toggleProbe, { filter = config.probeEquipHotKey.keyCode })

    if (isAutoEquipOnActivateEnabled()) then
        event.register("activate", autoEquipProbeOnActivate)
    end
end

return probe