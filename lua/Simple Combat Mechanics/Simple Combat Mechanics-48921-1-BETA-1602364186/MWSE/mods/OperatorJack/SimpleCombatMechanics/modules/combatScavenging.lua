local common = require("OperatorJack.SimpleCombatMechanics.common")
local config = require("OperatorJack.SimpleCombatMechanics.config")

local function loadTypes(types)
    if (config.enableCombatScavengingWeapons == true) then
        types[tes3.objectType.weapon] = true
    end
    if (config.enableCombatScavengingArmor == true) then
        types[tes3.objectType.armor] = true
    end
    if (config.enableCombatScavengingClothing == true) then
        types[tes3.objectType.clothing] = true
    end
    if (config.enableCombatScavengingPotions == true) then
        types[tes3.objectType.alchemy] = true
    end
end

local function getWeaponRating(weaponObject)
    local chop = (weaponObject.chopMin + weaponObject.chopMax) / 2
    local slash = (weaponObject.slashMin + weaponObject.slashMax) / 2
    local thrust = (weaponObject.thrustMin + weaponObject.thrustMax) / 2
    return (chop + slash + thrust) / 3.0 * weaponObject.speed * weaponObject.reach
end

local function getBetterWeapon(weapon1Object, weapon2Object)
    local weapon1Rating, weapon2Rating
    weapon1Rating = getWeaponRating(weapon1Object)
    weapon2Rating = getWeaponRating(weapon2Object)

    if (weapon1Rating > weapon2Rating) then
        return weapon1Object, weapon1Rating - weapon2Rating
    end
    return weapon2Object, weapon1Rating - weapon2Rating
end

local function getPriorityItem(list)
    local priorityItems = {}
    local currentPriority = 0
    for _, obj in ipairs(list) do
        if (obj.priority == currentPriority) then
            table.insert(priorityItems, obj.item)
        elseif (obj.priority > currentPriority) then
            currentPriority = obj.priority
            priorityItems = {}
            table.insert(priorityItems, obj.item)
        end
    end

    if (#priorityItems > 1) then
        return priorityItems[math.random(#priorityItems)]
    elseif (#priorityItems == 1) then
        return priorityItems[1]
    else
        return nil
    end
end

local function addPriorityItem(list, item, priority)
    table.insert(list, {
        item = item,
        priority = priority
    })
end

local function evaluateWeapon(list, mobile, item)
    -- Do we have a weapon already?
    if (mobile.readiedWeapon ~= nil) then
        --Is the weapon better than our current weapon? Chosen based on skill level and weapon stats.
        local weaponSkill = mobile[common.skillMappings[item.object.type]].current
        local currentSkill = mobile[common.skillMappings[mobile.readiedWeapon.object.type]].current

        -- If we are more skilled with the weapon, we might want to take it. Weapons are prioritized over all else.
        local skillDiff = weaponSkill - currentSkill
        if (skillDiff > 5) then
            -- If we have a higher skill, and the weapon is better, take it.
            local betterObject, ratingDiff = getBetterWeapon(mobile.readiedWeapon.object, item.object)
            if (betterObject == item.object) then
                addPriorityItem(list, item, 100)
                return
            elseif (ratingDiff < -10) then
                -- Otherwise, we may still want to take it, but consider other options.
                addPriorityItem(list, item, 70)
                return
            end
        elseif (skillDiff > -15) then
            -- If we have a higher skill, and the weapon is better, take it.
            local betterObject, ratingDiff = getBetterWeapon(mobile.readiedWeapon.object, item.object)
            if (betterObject == item.object) then
                addPriorityItem(list, item, 70)
                return
            elseif (ratingDiff < -10) then
                -- Otherwise, we may still want to take it, but consider other options.
                addPriorityItem(list, item, 50)
                return
            end
        end

        -- Otherwise, ignore the weapon.
    else
    -- If not, is the weapon better than not having a weapon? Chosen based on skill level.
        local weaponSkill = mobile[common.skillMappings[item.object.type]].current
        local handToHandSkill = mobile.handToHand.current

        -- If we are more skilled with the weapon, we might want to take it. Weapons are prioritized over all else.
        local skillDiff = weaponSkill - handToHandSkill
        if (skillDiff > 20) then
            addPriorityItem(list, item, 100)
            return
        elseif (skillDiff > -15) then
            -- If we are less skilled with it, maybe we consider other options too.
            addPriorityItem(list, item, 75)
            return
        end
    end
end

local function evaluateArmor(list, mobile, item)
    local equippedItem
	for _, stack in pairs(mobile.reference.object.equipment) do
		if (stack.object.slot == item.object.slot) then
			equippedItem = stack
		end
    end

    if (equippedItem) then
        -- If armor rating is better with the item on the ground, should take the item. otherwise, ignore it.
        if (item.object:calculateArmorRating(mobile) > equippedItem.object:calculateArmorRating(mobile)) then
            addPriorityItem(list, item, 75)
            return
        end
    else
        -- Not currently wearing armor in that slot. Should take the item.
        addPriorityItem(list, item, 75)
        return
    end
end

local function evaluateAlchemy(list, mobile, item)
    if (item.value > 800) then
        addPriorityItem(list, item, 80)
        return
    else
        local priority = math.floor(item.value / 10)
        addPriorityItem(list, item, priority)
        return
    end
end

local function evaluateClothing(list, mobile, item)
    -- If it doesn't have an enchantment, we don't care. Not useful in combat.
    if (item.object.enchantment == nil) then
        return
    end

    -- If it does have an enchantment, weight the enchantment, based on max charge and type.
    local enchantment = item.object.enchantment
    if (enchantment.castType == tes3.enchantmentType.constant) then
        addPriorityItem(list, item, 80)
        return
    end

    if (item.object.value > 80000) then
        addPriorityItem(list, item, 80)
        return
    else
        local priority = math.floor(item.object.value / 1000)
        addPriorityItem(list, item, priority)
        return
    end
end

local function chooseItem(mobile, items)
    local reasonableItems = {}
    for _, item in ipairs(items) do
        if (item.object.objectType == tes3.objectType.weapon) then
            evaluateWeapon(reasonableItems, mobile, item)
        elseif (item.object.objectType == tes3.objectType.armor) then
            evaluateArmor(reasonableItems, mobile, item)
        elseif (item.object.objectType == tes3.objectType.alchemy) then
            evaluateAlchemy(reasonableItems, mobile, item)
        elseif (item.object.objectType == tes3.objectType.clothing) then
            evaluateClothing(reasonableItems, mobile, item)
        end
    end

    return getPriorityItem(reasonableItems)
end

local function onAction(e)
    if (config.enableCombatScavenging == false) then
        return
    end

    local session = e.session
    local mobile = session.mobile
    local reference = mobile.reference

    if (mobile.actorType ~= tes3.actorType.npc) then
        return
    end

    if (mobile.hasFreeAction == false) then
        return
    end

    local items = {}
    -- Iterate through the references in the cell.
    local types = {}
    loadTypes(types)
    
    for _, cellReference in pairs(common.getReferencesNearPoint(reference.position, config.combatScavengingSearchDistance)) do
        -- Check for possible items by type and distance.
        if (types[cellReference.object.objectType] and 
            tes3.hasOwnershipAccess({reference = reference, target = cellReference}) == true) then
            table.insert(items, cellReference)
        end
    end

    -- Activate reference. Let AI handle the rest.
    local item = chooseItem(mobile, items)
    if (item) then
        local object = item.object
        reference:activate(item)
        timer.delayOneFrame(function()
            reference:updateEquipment()

            if (config.combatScavengingForceEquip == true) then
                mobile:equip(object)
            end
        end)
    end
end
event.register("determineAction", onAction)