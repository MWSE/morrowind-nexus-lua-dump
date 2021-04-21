local config = require("OperatorJack.SecurityEnhanced.config")

local this = {}
this.debug = function (message)
    if (config.debugMode) then
        local prepend = '[Security Enhanced: DEBUG] '
        mwse.log(prepend .. message)
        tes3.messageBox(prepend .. message)
    end
end

-- Store currently equipped weapon for re-equip.
this.lastWeapon = nil
this.saveCurrentEquipment = function ()
    this.lastWeapon = nil

    -- Store the currently equipped weapon, if any.
    local weaponStack = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    })
    if (weaponStack) then
        this.debug('Saving Weapon ID: ' .. weaponStack.object.id)
        this.lastWeapon = weaponStack.object
    end
end

this.reequipEquipment = function ()
    -- If we had a weapon equipped before, re-equip it.
    if (this.lastWeapon) then
        mwscript.equip{ reference = tes3.player, item = this.lastWeapon }
    end
end

this.getSortedInventoryByObjectType = function (objectType)
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

this.getBestObjectByObjectType = function (objectType)
    local objects = this.getSortedInventoryByObjectType(objectType)
    local object = objects[#objects]

    this.debug("Found Best Object: Selected Object:" .. object.id)
    return object
end

this.getNextBestObjectByObjectType = function (objectType, currentObject)
    local objects = this.getSortedInventoryByObjectType(objectType)
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

    this.debug("Found Next Best Object: Selected Object:" .. object.id)
    return object
end


this.getWorstObjectByObjectType = function (objectType)
    local objects = this.getSortedInventoryByObjectType(objectType)
    local object = objects[1]

    this.debug("Found Worst Object: Selected Object:" .. object.id)
    return object
end

return this