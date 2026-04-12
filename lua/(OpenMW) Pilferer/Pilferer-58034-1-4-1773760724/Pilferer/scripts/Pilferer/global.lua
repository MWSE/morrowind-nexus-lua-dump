local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local MODNAME = "Pilferer"
local ACTOR_SCRIPT = "scripts/Pilferer/actor.lua"

local saveData = {}
local delayedUpdateJobs = {} --{ticks remaining, func}

local function onUpdate(dt)
	if dt == 0 then return end
	for id, infos in pairs(delayedUpdateJobs) do
		infos[1] = infos[1] - 1
		if infos[1] <= 0 then
			infos[2]()
			delayedUpdateJobs[id] = nil
		end
	end
end


local function onLoad(data)
    saveData = data or {}
    saveData.playerState = saveData.playerState or {}
    saveData.helloBoostCells = saveData.helloBoostCells or {}
    
    -- Migrate old global boolean to per-cell
    if saveData.helloBoostActive then
        saveData.helloBoostActive = nil
        local player = world.players[1]
        if player and player:isValid() and player.cell then
            saveData.helloBoostCells[player.cell.id] = true
        end
    end
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

local function allPlayersDetectedInCell(cellId)
    for _, player in ipairs(world.players) do
        if player:isValid() and player.cell and player.cell.id == cellId then
            local state = getPlayerState(player)
            if not state.isDetected then
                return false
            end
        end
    end
    return true
end

local function deactivateCellBoostIfReady(cellId)
    if not cellId or not saveData.helloBoostCells[cellId] then return end
    if not allPlayersDetectedInCell(cellId) then return end
    
    saveData.helloBoostCells[cellId] = nil
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(ACTOR_SCRIPT) and actor.cell and actor.cell.id == cellId then
            actor:sendEvent("Pilferer_resetHello")
        end
    end
end

local function onActorActive(actor)
    if types.NPC.objectIsInstance(actor) and not types.Player.objectIsInstance(actor) then
        if not actor:hasScript(ACTOR_SCRIPT) then
            actor:addScript(ACTOR_SCRIPT)
        end
        if actor.cell and saveData.helloBoostCells[actor.cell.id] then
            actor:sendEvent("Pilferer_boostHello")
        end
    end
end

local function onCellChanged(player)
    if not player or not player:isValid() then
        print(string.format("[%s] Cell changed but invalid player reference", MODNAME))
        return
    end
    
    local cellId = player.cell and player.cell.id
    if not cellId then return end
    
    saveData.helloBoostCells[cellId] = true
    
    -- Reset detection state on cell change
    local state = getPlayerState(player)
    if state.isDetected then
        removeDetectedDebuff(player)
        state.isDetected = false
    end
    state.hasStolenItem = false
    state.stolenValue = 0
    
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(ACTOR_SCRIPT) and actor.cell and actor.cell.id == cellId then
            actor:sendEvent("Pilferer_boostHello")
        end
    end
    print(string.format("[%s] Player entered new cell - preparing NPC greetings", MODNAME))
end

local function onGreetingDetected(data)
    local greeterName = data and data.name or "unknown"
    local player = data and data.player
    if not player or not player:isValid() then return end
    
    local cellId = player.cell and player.cell.id
    if not cellId or not saveData.helloBoostCells[cellId] then return end
    
    print(string.format("[%s] Greeting detected from %s - player is detected!", MODNAME, greeterName))
    
    local state = getPlayerState(player)
    if not state.isDetected then
        state.isDetected = true
        applyDetectedDebuff(player)
        checkAndCommitTheft(player)
    end
    player:sendEvent("Pilferer_greetingReceived", {name = greeterName})
    
    deactivateCellBoostIfReady(cellId)
end

local function onSneakDetected(data)
    local detectorName = data and data.name or "unknown"
    local player = data and data.player
    if not player or not player:isValid() then return end
    
    print(string.format("[%s] Sneak detection by %s - player is detected!", MODNAME, detectorName))
    
    local state = getPlayerState(player)
    if not state.isDetected then
        state.isDetected = true
        applyDetectedDebuff(player)
        checkAndCommitTheft(player)
    end
    player:sendEvent("Pilferer_greetingReceived", {name = detectorName})
    
    local cellId = player.cell and player.cell.id
    deactivateCellBoostIfReady(cellId)
end

function isTheft(item, player)
	if item.owner.recordId then
		return true
	elseif item.owner.factionId and types.NPC.getFactionRank(player, item.owner.factionId) == 0 then
		return true
	elseif item.owner.factionId and types.NPC.getFactionRank(player, item.owner.factionId) < (item.owner.factionRank or 0) then
		return true
	end
	return false
end

-- Activation handler for items
local function onItemActivation(object, actor)
    if not types.Player.objectIsInstance(actor) then
        return  -- Only care about player taking items
    end
    
    local owner = object.owner
    if not owner then return end
    
    -- Check if item is owned by someone other than player
    local isOwned = isTheft(object, actor)
    if not isOwned then return end
    
	local previous = types.Player.inventory(actor):find(object.recordId)
	local previousCount = previous and previous.count or 0
	table.insert(delayedUpdateJobs, {2, function()
		-- idk check if the player's count of this item increased
		local new = types.Player.inventory(actor):find(object.recordId)
		local newCount = new and new.count or 0
		if newCount <= previousCount then return end
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
	end})
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

local itemTypes = {
    types.Weapon, types.Armor, types.Clothing, types.Potion,
    types.Book, types.Ingredient, types.Apparatus, types.Lockpick,
    types.Probe, types.Repair, types.Miscellaneous, types.Light,
}

for _, itemType in ipairs(itemTypes) do
    I.Activation.addHandlerForType(itemType, onItemActivation)
end


return {
    engineHandlers = {
        onActorActive = onActorActive,
        onPlayerAdded = onPlayerAdded,
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
		onUpdate = onUpdate,
    },
    eventHandlers = {
        Pilferer_cellChanged = onCellChanged,
        Pilferer_greetingDetected = onGreetingDetected,
        Pilferer_sneakDetected = onSneakDetected,
        Pilferer_unhookActor = function(actor)
            if actor:isValid() and actor:hasScript(ACTOR_SCRIPT) then
                actor:removeScript(ACTOR_SCRIPT)
            end
        end,
    },
}