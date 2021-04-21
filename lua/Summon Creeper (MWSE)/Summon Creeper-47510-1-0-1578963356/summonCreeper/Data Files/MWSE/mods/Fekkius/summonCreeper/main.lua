local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("Fekkius.summonCreeper.effects.basicSummonEffects")

local function initialized () -- 1
	print("[ME: Summon Scamp] Initialized") -- 2
end

-- Check Magicka Expanded framework.
if (framework == nil) then
	local function warning()
	 tes3.messageBox(
		"[SUMMON CREEPER-MOD ERROR] Magicka Expanded framework is not installed!"
		.. "You will need to install it to use this mod."
	 )
	end
	event.register("initialized", warning)
	event.register("loaded, warning")
	return
end

event.register("initialized", initialized) -- 3

local spellIds = {
	creeper = "FJ_ME_SummonCreeperSpell"
}

local function getDescription(creatureName)
    return "This effect summons forth the ".. creatureName ..", a Daedric"..
    " merchant from the planes of Oblivion."
end

local function registerSpells()
	framework.spells.createBasicSpell({
		id = "FJ_ME_SummonCreeperSpell",
		name = "Summon Creeper",
		effect = tes3.effect.summonCreeper,
		range = tes3.effectRange.self,
		duration = 10
	})
end

event.register("MagickaExpanded:Register", registerSpells)