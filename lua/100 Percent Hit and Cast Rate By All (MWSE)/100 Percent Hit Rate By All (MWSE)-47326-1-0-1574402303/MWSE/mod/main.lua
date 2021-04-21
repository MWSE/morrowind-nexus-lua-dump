local function oneHitWonder(e)
	e.hitChance = 100
end

local function initialized(e)
	event.register("calcHitChance", oneHitWonder)
end

event.register("initialized", initialized)