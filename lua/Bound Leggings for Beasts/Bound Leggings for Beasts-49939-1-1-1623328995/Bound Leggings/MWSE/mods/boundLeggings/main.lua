-- Check Magicka Expanded framework.
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
	local function warning()
		tes3.messageBox("[Bound Leggings: ERROR] Magicka Expanded framework is not installed! You will need to install it to use this mod.")
	end
	event.register("initialized", warning)
	event.register("loaded", warning)
	return
end
----------------------------  
tes3.claimSpellEffectId("boundLeggings", 429)


local function addSpellsToActors()
	local actorsToAddSpellTo = { "estirdalin", "farena arelas", "felen maryon", "heem_la", "nelso salenim" }
	for _, actorId in ipairs(actorsToAddSpellTo) do
		local actor = tes3.getObject(actorId)
		if (actor) then
			actor.spells:add("GW_bound_leggings")
		end
	end
end


local function initialized(e)

	framework.effects.conjuration.createBasicBoundArmorEffect({
		id = tes3.effect.boundLeggings,
		name = "Bound Leggings",
		description = "The spell effect conjures a lesser Daedra bound in the form of a magical, wondrously light pair of Daedric leggings. The leggings appear automatically equipped on the caster, displacing any currently equipped leg armor to inventory.  When the effect ends, the leggings disappear, and any previously equipped leg armor is automatically re-equipped.",
		baseCost = 2,
		armorId = "_adul_al_legging_bound",
		icon = "s\\tx_s_bd_boots.dds"
	})

	framework.spells.createBasicSpell({
		id = "GW_bound_leggings",
		name = "Bound Leggings",
		effect = tes3.effect.boundLeggings,
		range = tes3.effectRange.self,
		duration = 60
	})

	mwse.log("[Bound Leggings: Enabled]")

end


event.register("initialized", initialized)
event.register("loaded", addSpellsToActors)