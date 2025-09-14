local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI
local core = require('openmw.core')

local saveData = {}
local lastAggroCheck = 0
local currentAggroState = false
local checkInterval = 1.0 -- Check every second
local isDead

-- Check if this actor is aggressive towards any player
local function checkAggroState()
	local isAggressive = false
	local targetPlayer = nil
	
	-- Check AI packages for combat/pursue targeting players
	AI.forEachPackage(function(package)
		if (package.type == "Combat" or package.type == "Pursue") and package.target then
			if types.Player.objectIsInstance(package.target) then
				isAggressive = true
				targetPlayer = package.target
				return isAggressive, targetPlayer
			end
		end
	end)
	
	return isAggressive, targetPlayer
end

-- Send aggro status to nearby players
local function notifyPlayers(isAggressive)
	for _, player in pairs(nearby.players) do
		player:sendEvent("SealedFate_aggroUpdate", {
			actorId = self.id,
			isAggressive = isAggressive,
		})
	end
end

local function onUpdate()
	if not isDead then
		local currentTime = core.getRealTime()
		
		-- Only check periodically to avoid performance issues
		if currentTime >= lastAggroCheck + checkInterval then
			lastAggroCheck = currentTime+math.random()
			isDead = types.Actor.isDead(self)
			if isDead and isAggressive then
				isAggressive = false
				notifyPlayers(isAggressive)
			elseif not isDead then
				local isAggressive, targetPlayer = checkAggroState()
				-- Only notify if aggro state changed
				currentAggroState = isAggressive and not types.Actor.isDead(self)
				notifyPlayers(isAggressive)
			end
		end
	end
end



-- When actor becomes inactive, notify players that aggro is lost
local function onInactive()
	if currentAggroState then
		for _, player in pairs(nearby.players) do
			player:sendEvent("SealedFate_aggroUpdate", {
				actorId = self.id,
				isAggressive = false,
				actorRecordId = self.recordId
			})
		end
		currentAggroState = false
	end
	core.sendGlobalEvent("SealedFate_unhookActor", self)
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
		onInactive = onInactive,
	}
}