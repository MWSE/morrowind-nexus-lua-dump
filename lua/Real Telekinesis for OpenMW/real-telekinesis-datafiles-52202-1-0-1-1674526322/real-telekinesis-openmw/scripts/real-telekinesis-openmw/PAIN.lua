-- IMPORTS
local Types = require('openmw.types')
-- LOCAL SCRIPTS ONLY
local Self = require('openmw.self')

-- MAKE THEM SUFFER
local function damageHandler(data)
	if data.damage then
		local stats = Types.Actor.stats.dynamic.health(Self)
		stats.current = stats.current - data.damage
	end
	if data.fatigueDamage then
		local stats = Types.Actor.stats.dynamic.fatigue(Self)
		stats.current = stats.current - data.fatigueDamage
	end
end

local function toggleAIHandler(data)
	Self.enableAI(data.enabled)
end

local function emptyFatigueHandler(data)
	local stats = Types.Actor.stats.dynamic.fatigue(Self)
	if data.reset then
		-- Note that calling this from the update function screws it up...
		stats.current = stats.base
	else
		-- Knockdown target
		stats.current = -1
	end
end

local function magickaHandler(data)
	if data.amount then
		local stats = Types.Actor.stats.dynamic.magicka(Self)
		stats.current = stats.current - data.amount
	end
end

local function levelStat(stats, data)
	if stats.progress < 1 then
		stats.progress = stats.progress + data.amount
	end
	-- print(stats.progress, stats.base, Self.type)
	if stats.progress >= 1 and stats.base < 100 then
		stats.base = stats.base + 1
		stats.progress = 0
		if data.skillName and Self.type == Types.Player then
			-- Only player script can import ui lol
			local Ui = require('openmw.ui')
			Ui.showMessage("Your " .. data.skillName .. " skill has increased to " .. stats.base .. ".")
		end
	end
end

local function mysticismHandler(data)
	if data.amount then
		local stats = Types.NPC.stats.skills.mysticism(Self)
		levelStat(stats, data)
	end
end

local function destructionHandler(data)
	if data.amount then
		local stats = Types.NPC.stats.skills.destruction(Self)
		levelStat(stats, data)
	end
end

return {
	eventHandlers = {
		TK_Damage = damageHandler, 
		TK_Ai = toggleAIHandler,
		TK_EmptyFatigue = emptyFatigueHandler,
		TK_UseMagicka = magickaHandler,
		TK_LevelMysticism = mysticismHandler,
		TK_LevelDestruction = destructionHandler
	}
}