local core = require('openmw.core')
if core.API_REVISION <65 then return end

local I = require('openmw.interfaces')
local self = require('openmw.self')
local inspectors = {}
local currentTime = nil
local active = false
local initialized = false

local function table_length(t)
	local i = 0
	for _ in pairs(t) do
		i=i+1
	end
	return i
end

local function initialize()
	if not initialized then
		initialized = true
		animation = require('openmw.animation')
		lootTime = animation.getTextKeyTime(self, "containeropen: loot")
		stopTime = animation.getTextKeyTime(self, "containeropen: stop") or 0
		closeTime = animation.getTextKeyTime(self, "containerclose: stop") or 0
	end
end

QuickLoot_openAnimation = function(player)
	initialize()
	if not lootTime then return end
	if table_length(inspectors) == 0 then
		local tempTime = closeTime-(currentTime or closeTime) 
		animation.cancel(self, 'containerclose')
		if tempTime + 1/30 > lootTime then
			animation.playBlended(self, 'containeropen',{priority  = 9999,startPoint = math.max(tempTime,0.0001), startKey ="loot", stopKey = "stop", autoDisable =false})
		else
			animation.playBlended(self, 'containeropen',{priority  = 9999,startPoint = tempTime, startKey ="start", stopKey = "stop",autoDisable =false})
		end
		currentTime = animation.getCurrentTime(self, "containeropen")
	end
	inspectors[player.id] = true
	active = true
end

QuickLoot_closeAnimation = function(player)
	initialize()
	if not lootTime then return end
	inspectors[player.id] = nil
	if table_length(inspectors) == 0 and currentTime then
		animation.cancel(self, 'containeropen')
		animation.playBlended(self, 'containerclose',{priority  = 9999,startPoint = stopTime-(currentTime or stopTime),startKey ="start", stopKey = "stop"})
		currentTime = stopTime-(currentTime or stopTime)
	end
	active = true
end

onUpdate = function(dt)
	if not active then
		return
	end
	local at = animation.getCurrentTime(self, "containeropen")
	currentTime = at
	if at and at + dt + 1/60 > lootTime and at < lootTime then
		animation.cancel(self, 'containeropen')
		animation.playBlended(self, 'containeropen',{priority  = 9999,startKey = "loot",startPoint  =0.0001, stopKey = "stop",autoDisable =false})
	elseif not at then
		at = animation.getCurrentTime(self, "containerclose")
		currentTime = at				
	end
	if not currentTime then
		active = false
	end
end


return{
	engineHandlers = { 
		onUpdate = onUpdate,
		_onAnimationTextKey = onAnimationTextKey,
		_onPlayAnimation = playBlendedAnimation,
	},
	eventHandlers = { 
		OwnlysQuickLoot_openAnimation = QuickLoot_openAnimation,
		OwnlysQuickLoot_closeAnimation =QuickLoot_closeAnimation,
	}
}