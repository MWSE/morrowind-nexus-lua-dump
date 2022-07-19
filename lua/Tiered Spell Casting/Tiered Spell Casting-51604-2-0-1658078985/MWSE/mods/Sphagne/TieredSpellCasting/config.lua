local config = mwse.loadConfig("Tired Spell Casting")

if (config == nil or config.uncapped == nil) then
	config = {
		uncapped = false,	-- Uncapped game settings
		penChance = false,	-- Spell chance penalty, instead of spell cost
	}
end

return config