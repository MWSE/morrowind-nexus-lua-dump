-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20220111) then
    local function warning()
        tes3.messageBox(
            "[Security Enhanced ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

local config = require("OperatorJack.SecurityEnhanced.config")
local options = require("OperatorJack.SecurityEnhanced.options")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("OperatorJack.SecurityEnhanced.mcm")
end)


local function debug(message)
    if (config.debugMode) then
        local prepend = '[Security Enhanced: DEBUG] '
        mwse.log(prepend .. message)
        tes3.messageBox(prepend .. message)
    end
end

-- Store currently equipped weapon for re-equip.
local lastWeaponItem = nil
local lastWeaponItemData = nil
local function saveCurrentEquipment()
    -- Store the currently equipped weapon, if any.
    local weaponStack = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    })
    if (weaponStack) then
        debug('Saving Weapon ID: ' .. weaponStack.object.id)
        lastWeaponItem = weaponStack.object
        lastWeaponItemData = weaponStack.itemData
    end
end

local function reequipEquipment()
    -- If we had a weapon equipped before, re-equip it.
    if (lastWeaponItem) then
        if (not tes3.mobilePlayer:equip({ item = lastWeaponItem, itemData = lastWeaponItemData })) then
            tes3.mobilePlayer:equip({ item = lastWeaponItem, selectBestCondition = true })
        end

        lastWeaponItem = nil
        lastWeaponItemData = nil
    end
end

local function hasKey(reference)
    if not reference.lockNode then return false end
    if not reference.lockNode.key then return false end
    return tes3.getItemCount({
        reference = tes3.player,
        item = reference.lockNode.key
    }) > 0
end

local function getSortedInventoryByObjectType(objectType)
    local objects = {}
    for node in tes3.iterate(tes3.player.object.inventory.iterator) do
        if (node.object.objectType == objectType) then
            table.insert(objects, node.object)
        end
    end
    table.sort(
        objects,
        function(a, b)
            return a.quality < b.quality
        end
    )
    return objects
end

local function getBestObjectByObjectType(objectType)
    local objects = getSortedInventoryByObjectType(objectType)
    local object = objects[#objects]

    debug("Found Best Object: Selected Object:" .. object.id)
    return object
end

local function getNextBestObjectByObjectType(objectType, currentObject)
    local objects = getSortedInventoryByObjectType(objectType)
    local object

    for i = 1,#objects do
        local nodeObject = objects[i]
        if (nodeObject.quality > currentObject.quality) then
            object = nodeObject
            break
        end
    end

    if (object == nil) then
        object = objects[1]
    end

    debug("Found Next Best Object: Selected Object:" .. object.id)
    return object
end


local function getWorstObjectByObjectType(objectType)
    local objects = getSortedInventoryByObjectType(objectType)
    local object = objects[1]

    debug("Found Worst Object: Selected Object:" .. object.id)
    return object
end

local function getToolConfig(type)
    if type == tes3.objectType.lockpick then return config.lockpick end
    if type == tes3.objectType.probe then return config.probe end
end

local function hasTool(type)
    for node in tes3.iterate(tes3.player.object.inventory.iterator) do
        if (node.object.objectType == type) then
            return true
        end
    end
    return false
end

local function isToolEquipped(type)
    return tes3.getEquippedItem{
        actor = tes3.player,
        objectType = type
    }
end

local function unequipTool(type)
    tes3.mobilePlayer:unequip {
        type = type
    }
end

local function equipTool(type, saveEquipment, cycle)
    if saveEquipment then saveCurrentEquipment() end

    local currentToolStack = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = type
    })
    local currentTool = currentToolStack and currentToolStack.object

    local toolConfig = getToolConfig(type)

    local tool

    if cycle then
        tool = getNextBestObjectByObjectType(type,currentTool)
    elseif toolConfig.equipOrder == options.equipOrder.BestFirst then
        debug("Equipping Tool: Best First")
        tool = getBestObjectByObjectType(type)
    elseif toolConfig.equipOrder == options.equipOrder.WorstFirst then
         -- Choose lowest level Tool first.
        debug("Equipping Tool: Worst First")
        tool = getWorstObjectByObjectType(type)
    end

    if (tool == nil) then
        debug("Could not find tool.")
        return;
    end

    debug("Equipping tool.")
    tes3.mobilePlayer:equip{
        item = tool
    }
end

local function cycleTool(type)
    local toolConfig = getToolConfig(type)
    if toolConfig.equipHotKeyCycle == options.equipHotKeyCycle.ReequipWeapon then
        debug("Cycling: Requipping weapon.")
        -- Re-equip Weapon
        unequipTool(type)
        reequipEquipment()
    elseif toolConfig.equipHotKeyCycle == options.equipHotKeyCycle.Next then
        debug("Cycling: Moving to next tool.")
        -- Cycle to Next Tool
        equipTool(type, false, true)
    end
end

local function toggleTool(type, e)
    local toolConfig = getToolConfig(type)
    if tes3.isKeyEqual({expected = toolConfig.hotKey, actual = e}) == false then
        debug("In hotkey event, invalid key pressed. Exiting event.")
        return
    end

    debug("Registered hotkey event.")

    -- Don't do anything in menu mode.
    if tes3.menuMode() then
        return
    end

    -- Check if Tool is available.
    if hasTool(type) then
        -- Check if a Tool is already equipped.
        if isToolEquipped(type) then
            debug("Tool is equipped. Cycling.")
            -- Cycle to next item based on configuration.
            cycleTool(type)
        else
            debug("Tool is not equipped. Equipping.")
            -- Equip Tool based on configuration.
            equipTool(type, true, false)
        end
    end
end

local function toggleLockpick(e)
    toggleTool(tes3.objectType.lockpick, e)
end

local function toggleProbe(e)
    toggleTool(tes3.objectType.probe, e)
end

local equipTimer
local equipReference
local processing
local function autoEquipTool(e)
    if  e.target.object.objectType ~= tes3.objectType.door and
        e.target.object.objectType ~= tes3.objectType.container then
        return
    end

    if e.activator ~= tes3.player then return end

    debug("Registered auto-equip for locked object event.")

    if processing then return end
    processing = true

    local function callback(type)
        if hasTool(type) then
            if isToolEquipped(type) == nil then
                equipTool(type, true, false)

                -- Draw tool
                tes3.mobilePlayer.weaponReady = true

                -- Detect target change and reset to weapon when ready.
                equipReference = e.target
                if equipTimer then equipTimer:cancel() end
                equipTimer = timer.start({
                    duration = .5,
                    iterations = -1,
                    callback = function()
                        local target = tes3.getPlayerTarget()
                        if not target or target ~= equipReference then
                            unequipTool(type)
                            reequipEquipment()
                            equipReference = nil
                            equipTimer:cancel()
                            equipTimer = nil
                            processing = nil
                        end
                        if equipReference and
                            equipTimer and
                            ((type == tes3.objectType.lockpick and tes3.getLocked({reference = equipReference}) == false) or
                            (type == tes3.objectType.probe and not tes3.getTrap({reference = equipReference}))) then
                            equipReference = nil
                            equipTimer:cancel()
                            equipTimer = nil

                            timer.start({
                                duration = .8,
                                callback = function ()
                                    unequipTool(type)
                                    reequipEquipment()
                                    processing = nil
                                end
                            })
                        end
                    end
                })

                return -- Exit event handler.
            end
        end
    end

    -- Check for Probe first.
    if  config.probe.autoEquipOnActivate and
            tes3.getTrap({reference = e.target}) and
            hasKey(e.target) == false then

        debug("Auto-equipping probe.")
        callback(tes3.objectType.probe)

    -- Check for lockpick second.
    elseif config.lockpick.autoEquipOnActivate and
            tes3.getLocked({reference = e.target}) and
            not tes3.getTrap({reference = e.target}) and
            hasKey(e.target) == false then

        debug("Auto-equipping lockpick.")
        callback(tes3.objectType.lockpick)
    else
        processing = nil
    end
end

local function initialized()
    event.register("keyDown", toggleLockpick, { filter = config.lockpick.hotKey.keyCode })
    event.register("keyDown", toggleProbe, { filter = config.probe.hotKey.keyCode })


    if (config.lockpick.autoEquipOnActivate or config.probe.autoEquipOnActivate) then
        event.register("activate", autoEquipTool)
    end

    print("[Security Enhanced: INFO] Security Enhanced Initialized")
end

event.register("initialized", initialized)