local I = require('openmw.interfaces')
local self = require('openmw.self')
local inspectors = 0
local currentTime = nil
local active = false
local initialized = false

local function initialize()
	if not initialized then
		initialized = true
		animation = require('openmw.animation')
		lootTime = animation.getTextKeyTime(self, "containeropen: loot")
		stopTime = animation.getTextKeyTime(self, "containeropen: stop") or 0
		closeTime = animation.getTextKeyTime(self, "containerclose: stop") or 0
	end
end

QuickLoot_openAnimation = function()
	initialize()
	if not lootTime then return end
	inspectors = inspectors +1
	if inspectors == 1 then
		local tempTime = closeTime-(currentTime or closeTime) 
		animation.cancel(self, 'containerclose')
		if tempTime + 1/30 > lootTime then
		--print(1,tempTime)
			animation.playBlended(self, 'containeropen',{priority  = 9999,startpoint = math.max(tempTime,0.0001), startkey ="loot", stopkey = "stop"})
		else
			animation.playBlended(self, 'containeropen',{priority  = 9999,startpoint = tempTime, startkey ="start", stopkey = "stop"})
		end
	end
	active = true
end
QuickLoot_closeAnimation = function()
	initialize()
	if not lootTime then return end
	inspectors = math.max(0,inspectors -1)
	if inspectors == 0 then
		animation.cancel(self, 'containeropen')
		animation.playBlended(self, 'containerclose',{priority  = 9999,startpoint = stopTime-(currentTime or stopTime),startkey ="start", stopkey = "stop"})
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
		animation.playBlended(self, 'containeropen',{priority  = 9999,startkey = "loot",startpoint  =0.0001, stopkey = "stop",autodisable =false})
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