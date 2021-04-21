local function oneCastWonder(e)
	e.castChance = 100
end

local function initialized(e)
	event.register("spellCast", oneCastWonder)
end

event.register("initialized", initialized)