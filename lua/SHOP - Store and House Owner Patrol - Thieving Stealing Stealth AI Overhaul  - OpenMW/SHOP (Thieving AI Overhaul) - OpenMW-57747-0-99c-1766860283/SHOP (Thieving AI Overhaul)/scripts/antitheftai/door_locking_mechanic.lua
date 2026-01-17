-- Door Locking Mechanic (Player Script)
-- Allows players to lock unlocked doors using keylock items.
-- Success rate is based on Security skill (1% per skill level, up to 100%)
-- keylock-skeleton has 100% success rate

local input = require('openmw.input')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')
local core = require('openmw.core')

-- Keylock item IDs
local KEYLOCK_ITEMS = {
    ['keylock-iron'] = true,
    ['keylock-imperial'] = true,
    ['keylock-dwemer'] = true,
    ['keylock-master'] = true,
    ['keylock-skeleton'] = true
}

-- Check if player is holding a keylock
local function isKeylockEquipped()
    local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon and weapon.recordId then
        return KEYLOCK_ITEMS[weapon.recordId:lower()]
    end
    return false
end

-- Get the equipped keylock item
local function getEquippedKeylock()
    local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon and weapon.recordId and KEYLOCK_ITEMS[weapon.recordId:lower()] then
        return weapon
    end
    return nil
end

-- Get weapon reach/range for distance checking
local function getWeaponReach(weapon)
    if not weapon then return 1.0 end
    local record = types.Lockpick.record(weapon)
    if record and record.reach then
        return record.reach
    end
    -- Default lockpick reach
    return 1.0
end

-- Consume one charge from the keylock
local function consumeCharge(weapon)
    if not weapon then return end
    
    local itemData = types.Item.itemData(weapon)
    if itemData then
        local currentCondition = itemData.condition
        local maxCondition = types.Lockpick.record(weapon).maxCondition or 1
        
        -- Calculate damage per use (divide max condition by number of uses)
        local damagePerUse = maxCondition / (types.Lockpick.record(weapon).uses or 1)
        local newCondition = math.max(0, currentCondition - damagePerUse)
        itemData.condition = newCondition
        
        if newCondition == 0 then
            ui.showMessage("Your keylock has broken!")
        end
    end
end

-- Calculate lock success chance based on Security skill
local function getLockSuccessChance(itemId)
    -- keylock-skeleton always succeeds
    if itemId and itemId:lower() == 'keylock-skeleton' then
        return 100
    end
    
    -- Get player's Security skill
    local securitySkill = types.NPC.stats.skills.security(self).modified
    
    -- 1% per skill level, capped at 100%
    return math.min(100, securitySkill)
end

-- Attempt to lock a door
local function attemptLockDoor(door, keylock)
    print("[DoorLocking] attemptLockDoor called")
    if not door or not keylock then 
        print("[DoorLocking] ERROR: door or keylock is nil")
        return 
    end
    
    print("[DoorLocking] Door ID:", door.id)
    
    -- Check if door is already locked
    local lockLevel = types.Lockable.getLockLevel(door)
    print("[DoorLocking] Door lock level:", lockLevel)
    
    if lockLevel and lockLevel > 0 then
        print("[DoorLocking] Door is already locked - aborting")
        -- Door is already locked, do nothing
        return
    end
    
    -- Only lock doors with lockLevel == 0 (unlocked)
    if lockLevel ~= 0 then
        print("[DoorLocking] Door lock level is not 0 - aborting")
        return
    end
    
    print("[DoorLocking] Door is unlocked - proceeding with lock attempt")
    
    -- Get success chance
    local itemId = keylock.recordId
    local successChance = getLockSuccessChance(itemId)
    print("[DoorLocking] Success chance:", successChance, "%")
    
    -- Roll for success
    local roll = math.random(1, 100)
    local success = roll <= successChance
    print("[DoorLocking] Roll:", roll, "Success:", success)
    
    if success then
        -- Lock the door with a basic lock level (e.g., 50)
        types.Lockable.setLockLevel(door, 50)
        ui.showMessage("You successfully locked the door.")
        print("[DoorLocking] Door locked successfully!")
    else
        ui.showMessage(string.format("You failed to lock the door. (%d%% chance)", successChance))
        print("[DoorLocking] Failed to lock door")
    end
    
    -- Consume charge regardless of success/failure
    consumeCharge(keylock)
    print("[DoorLocking] Charge consumed")
end

-- Raycast to find door in front of player
local function findDoorInRange(maxRange)
    local playerPos = self.position
    local playerRot = self.rotation
    
    -- Get forward direction from player rotation
    local forward = playerRot * util.vector3(0, 1, 0)
    
    -- Raycast from player position forward
    local rayEnd = playerPos + forward * maxRange
    
    local result = nearby.castRay(playerPos, rayEnd)
    
    if result.hit and result.hitObject then
        if result.hitObject.type == types.Door then
            return result.hitObject
        end
    end
    
    return nil
end

-- Main input handler
local function onUseAction()
    -- Only allow if weapon stance is ready
    if types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon then
        return
    end
    print("[DoorLocking] Use action detected!")
    
    -- Check if keylock is equipped
    if not isKeylockEquipped() then
        print("[DoorLocking] No keylock equipped")
        return
    end
    
    print("[DoorLocking] Keylock is equipped!")
    
    local keylock = getEquippedKeylock()
    if not keylock then
        print("[DoorLocking] Failed to get equipped keylock")
        return
    end
    
    print("[DoorLocking] Keylock item:", keylock.recordId)
    
    -- Get weapon range
    local weaponRange = getWeaponReach(keylock)
    print("[DoorLocking] Weapon range:", weaponRange)
    
    -- Find door in range
    local door = findDoorInRange(weaponRange)
    
    if door then
        print("[DoorLocking] Door found! Attempting to lock...")
        attemptLockDoor(door, keylock)
    else
        print("[DoorLocking] No door found in range")
    end
end

return {
    engineHandlers = {
        onActive = function()
            print("[DoorLocking] Door locking mechanic script loaded!")
        end,
        
        onInputAction = function(action)
            print("[DoorLocking] Input action received:", tostring(action))
            if action == input.ACTION.Use then
                print("[DoorLocking] Use action confirmed - calling onUseAction()")
                onUseAction()
            end
        end
    }
}
