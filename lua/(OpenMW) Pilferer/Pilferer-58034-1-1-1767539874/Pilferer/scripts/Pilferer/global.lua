local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local MODNAME = "Pilferer"
local ACTOR_SCRIPT = "scripts/Pilferer/actor.lua"

local saveData = {}

local function onLoad(data)
    saveData = data or {}
    saveData.playerState = saveData.playerState or {}
    saveData.helloBoostActive = saveData.helloBoostActive or false
end

local function onSave()
    return saveData
end

local function getPlayerState(player)
    if not saveData.playerState[player.id] then
        saveData.playerState[player.id] = {
            isDetected = false,
            hasStolenItem = false,
            stolenValue = 0,
        }
    end
    return saveData.playerState[player.id]
end

local DETECTED_ABILITY = "pilferer_detected"

local function applyDetectedDebuff(player)
    local spells = types.Actor.spells(player)
    spells:add(DETECTED_ABILITY)
    print(string.format("[%s] Applied %s to player", MODNAME, DETECTED_ABILITY))
end

local function removeDetectedDebuff(player)
    local spells = types.Actor.spells(player)
    spells:remove(DETECTED_ABILITY)
    print(string.format("[%s] Removed %s from player", MODNAME, DETECTED_ABILITY))
end

local function addBountyAndNotify(player, stolenValue)
    -- Add bounty directly to player
    local currentBounty = types.Player.getCrimeLevel(player)
    types.Player.setCrimeLevel(player, currentBounty + stolenValue)
    
    -- Send event to player to show message
    player:sendEvent("Pilferer_theftWitnessed", {stolenValue = stolenValue})
    
    print(string.format("[%s] Theft witnessed! Added %d to bounty (total: %d)", 
        MODNAME, stolenValue, currentBounty + stolenValue))
end

local function checkAndCommitTheft(player)
    local state = getPlayerState(player)
    
    if state.isDetected and state.hasStolenItem and state.stolenValue > 0 then
        addBountyAndNotify(player, state.stolenValue)
        
        -- Reset theft tracking after bounty is added
        state.hasStolenItem = false
        state.stolenValue = 0
    end
end

local function onActorActive(actor)
    if types.NPC.objectIsInstance(actor) and not types.Player.objectIsInstance(actor) then
        if not actor:hasScript(ACTOR_SCRIPT) then
            actor:addScript(ACTOR_SCRIPT)
        end
        if saveData.helloBoostActive then
            actor:sendEvent("Pilferer_boostHello")
        end
    end
end

local function onCellChanged(player)
    if not player or not player:isValid() then
        print(string.format("[%s] Cell changed but invalid player reference", MODNAME))
        return
    end
    
    saveData.helloBoostActive = true
    
    -- Reset detection state on cell change
    local state = getPlayerState(player)
    if state.isDetected then
        removeDetectedDebuff(player)
        state.isDetected = false
    end
    state.hasStolenItem = false
    state.stolenValue = 0
    
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(ACTOR_SCRIPT) then
            actor:sendEvent("Pilferer_boostHello")
        end
    end
    print(string.format("[%s] Player entered new cell - preparing NPC greetings", MODNAME))
end

local function onGreetingDetected(data)
    if not saveData.helloBoostActive then return end
    
    saveData.helloBoostActive = false
    local greeterName = data and data.name or "unknown"
    print(string.format("[%s] Greeting detected from %s - player is detected!", MODNAME, greeterName))
    
    -- Apply detected debuff to all players
    for _, player in ipairs(world.players) do
        local state = getPlayerState(player)
        if not state.isDetected then
            state.isDetected = true
            applyDetectedDebuff(player)
            checkAndCommitTheft(player)
        end
        player:sendEvent("Pilferer_greetingReceived", {name = greeterName})
    end
    
    -- Reset hello on all actors
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(ACTOR_SCRIPT) then
            actor:sendEvent("Pilferer_resetHello")
        end
    end
end

-- Activation handler for items
local function onItemActivation(object, actor)
    if not types.Player.objectIsInstance(actor) then
        return  -- Only care about player taking items
    end
    
    local owner = object.owner
    if not owner then return end
    
    -- Check if item is owned by someone other than player
    local isOwned = owner.recordId or owner.factionId
    if not isOwned then return end
    
    local state = getPlayerState(actor)
    
    -- Get item value - try to access record through the object's type
    local itemValue = 1
    local itemName = object.recordId
    
    if object.type and object.type.record then
        local record = object.type.record(object)
        if record then
            itemValue = record.value or 1
            itemName = record.name or object.recordId
        end
    end
    
    state.hasStolenItem = true
    -- Double the item value for bounty calculation
    local bountyValue = (itemValue * object.count) * 2
    state.stolenValue = state.stolenValue + bountyValue
    
    print(string.format("[%s] Player took owned item: %s (value: %d, bounty: %d)", 
        MODNAME, itemName, itemValue * object.count, bountyValue))
    
    checkAndCommitTheft(actor)
end

local function onPlayerAdded(player)
    getPlayerState(player)  -- Initialize state
    
    -- Reapply debuff if player was detected (for save loads)
    local state = getPlayerState(player)
    if state.isDetected then
        applyDetectedDebuff(player)
    end
end

-- Register activation handlers for all item types
local function registerActivationHandlers()
    local itemTypes = {
        types.Weapon, types.Armor, types.Clothing, types.Potion,
        types.Book, types.Ingredient, types.Apparatus, types.Lockpick,
        types.Probe, types.Repair, types.Miscellaneous, types.Light,
    }
    
    for _, itemType in ipairs(itemTypes) do
        I.Activation.addHandlerForType(itemType, onItemActivation)
    end
    print(string.format("[%s] Registered activation handlers for item types", MODNAME))
end

registerActivationHandlers()

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onPlayerAdded = onPlayerAdded,
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        Pilferer_cellChanged = onCellChanged,
        Pilferer_greetingDetected = onGreetingDetected,
        Pilferer_unhookActor = function(actor)
            if actor:isValid() and actor:hasScript(ACTOR_SCRIPT) then
                actor:removeScript(ACTOR_SCRIPT)
            end
        end,
    },
}