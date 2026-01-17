local tes3 = tes3
local event = event

-- === TIERS ===
local TIERS = {
	{ label = "Bargain",   mag = 5,  dur = 8,   weight = 1.5,  value = 5   },
	{ label = "Cheap",     mag = 8,  dur = 15,  weight = 1.0,  value = 15  },
	{ label = "Standard",  mag = 10, dur = 30,  weight = 0.75, value = 35  },
	{ label = "Quality",   mag = 15, dur = 45,  weight = 0.5,  value = 80  },
	{ label = "Exclusive", mag = 20, dur = 60,  weight = 0.25, value = 175 },
	{ label = "Legendary", mag = 40, dur = 120, weight = 0.1,  value = 300 },
}

-- === OVERRIDES ===
local OVERRIDE_EFFECTS = {
	[tes3.effect.restoreHealth]   = { mag = { 5,10,20,30,40,100 }, dur = { 4,4,4,4,4,4 } },
	[tes3.effect.restoreFatigue]  = { mag = { 15,25,50,100,250,500 }, dur = { 4,4,4,4,4,4 } },
	[tes3.effect.restoreMagicka]  = { mag = { 1,2,3,4,5,10 }, dur = { 4,4,4,4,4,4 } },
	[tes3.effect.light]           = { mag = { 20,50,75,100,150,200 }, dur = { 300,300,300,300,300,300 } },
	[tes3.effect.nightEye]        = { mag = { 20,50,75,100,150,200 }, dur = { 300,300,300,300,300,300 } },
	[tes3.effect.waterBreathing]  = { mag = { 1,1,1,1,1,1 }, dur = { 15,30,60,120,300,300 } },
	[tes3.effect.waterWalking]    = { mag = { 1,1,1,1,1,1 }, dur = { 15,30,60,120,300,300 } },
	[tes3.effect.invisibility]    = { mag = { 1,1,1,1,1,1 }, dur = { 5,10,15,20,30,45 } },
	[tes3.effect.paralyze]        = { mag = { 1,1,1,1,1,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.damageHealth]    = { mag = { 25,20,15,10,5,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.damageFatigue]   = { mag = { 25,20,15,10,5,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.damageMagicka]   = { mag = { 25,20,15,10,5,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.damageAttribute] = { mag = { 20,15,10,5,2,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.damageSkill]     = { mag = { 20,15,10,5,2,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.poison]          = { mag = { 1,1,1,1,1,1 }, dur = { 600,300,25,10,5,1 } },
	[tes3.effect.burden]          = { mag = { 100,75,50,30,15,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.sound]           = { mag = { 75,50,40,30,20,10 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.blind]           = { mag = { 100,80,60,40,20,10 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.drainHealth]     = { mag = { 25,20,15,10,5,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.drainFatigue]    = { mag = { 25,20,15,10,5,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.drainMagicka]    = { mag = { 25,20,15,10,5,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.drainAttribute]  = { mag = { 20,15,10,5,2,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.drainSkill]      = { mag = { 20,15,10,5,2,1 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.weaknesstoFire]           = { mag = { 50,40,30,20,10,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.weaknesstoFrost]          = { mag = { 50,40,30,20,10,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.weaknesstoShock]          = { mag = { 50,40,30,20,10,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.weaknesstoMagicka]        = { mag = { 50,40,30,20,10,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.weaknesstoCommonDisease]  = { mag = { 50,40,30,20,10,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.weaknesstoBlightDisease]  = { mag = { 50,40,30,20,10,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.weaknesstoPoison]         = { mag = { 50,40,30,20,10,5 }, dur = { 60,30,15,10,5,1 } },
	[tes3.effect.dispel]              = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.cureCommonDisease]   = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.cureBlightDisease]   = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.curePoison]          = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.cureParalyzation]    = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.mark]                = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.recall]              = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.divineIntervention]  = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
	[tes3.effect.almsiviIntervention] = { mag = { 1,1,1,1,1,1 }, dur = { 1,1,1,1,1,1 } },
}

-- === Tier selection ===
local function pickTierId(e)
	local mp = tes3.mobilePlayer
	local sVal = (mp and mp:getSkillValue(tes3.skill.alchemy)) or 0
	local function qPoints(q)
		return (q >= 2.0 and 3) or (q >= 1.5 and 2) or (q >= 1.0 and 1) or 0
	end
	local p = e.picker or e
	local tScore = 0
	if p.mortar then tScore = tScore + 1 end
	if p.alembic then tScore = tScore + qPoints(p.alembic.quality or 0) end
	if p.retort then tScore = tScore + qPoints(p.retort.quality or 0) end
	if p.calcinator then tScore = tScore + qPoints(p.calcinator.quality or 0) end

	if not math.clamp then
		function math.clamp(x, minV, maxV)
			if x < minV then return minV end
			if x > maxV then return maxV end
			return x
		end
	end

	local sF = math.clamp(sVal * 0.01, 0, 1)
	local tF = math.clamp(tScore * 0.1, 0, 1)
	local eff = sF * 0.65 + tF * 0.35
	return math.clamp(math.ceil(eff * 6), 1, 6)
end

-- === Potion Brewing Event ===
event.register(tes3.event.potionBrewed, function(e)
	local tierId = pickTierId(e)
	local tier = TIERS[tierId]
	local effects = {}
	local k = 0

	for i = 1, 8 do
		local eff = e.object.effects[i]
		if eff and eff.id ~= -1 then
			local override = OVERRIDE_EFFECTS[eff.id]
			local mag = tier.mag
			local dur = tier.dur
			if override then
				mag = override.mag[tierId] or mag
				dur = override.dur[tierId] or dur
			end
			k = k + 1
			effects[k] = {
				id = eff.id,
				rangeType = tes3.effectRange.self,
				min = mag,
				max = mag,
				duration = dur,
				attribute = eff.attribute,
				skill = eff.skill
			}
		end
	end

	if k == 0 then return end

	local newPotion = tes3alchemy.create{
		name = string.format("%s %s", tier.label, e.object.name or "Potion"),
		mesh = e.object.mesh,
		icon = e.object.icon,
		weight = tier.weight,
		value = tier.value * k,
		effects = effects
	}

	tes3.removeItem{ reference = tes3.player, item = e.object, count = 1, playSound = false }
	tes3.addItem{ reference = tes3.player, item = newPotion, count = 1, playSound = false }
end)

event.register("initialized", function()
end)
