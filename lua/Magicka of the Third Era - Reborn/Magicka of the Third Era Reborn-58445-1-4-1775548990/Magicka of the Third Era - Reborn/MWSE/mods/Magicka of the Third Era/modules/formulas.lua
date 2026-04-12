-- modules/formulas.lua
-- Pure stateless computation: cast chance formula and armor coefficient breakdown.

local config = require("Magicka of the Third Era.config")

-- Thanks to nimble armor mod for this, using its values for now
local armorParts = {
	[0] = 0.1,	-- helmet
	[1] = 0.25,	-- cuirass
	[2] = 0.05, -- left pauldron
	[3] = 0.05, -- right pauldron
	[4] = 0.15, -- greaves
	[5] = 0.15, -- boots
	[6] = 0.05, -- left gauntlet
	[7] = 0.05, -- right gauntlet
	[8] = 0.15,	-- shield
--	[9] = 0.05, -- left bracer uses the same value as left gauntlet
--	[10] = 0.05 -- right bracer uses the same value as right gauntlet
}

local function get_armor_coefs(armored_actor)
  local armor = {light = 0, medium = 0, heavy = 0}
	if armored_actor == nil then -- check for disabled actors
		return armor
	end
	for i, value in pairs(armorParts) do
		local stack = tes3.getEquippedItem{actor = armored_actor, objectType = tes3.objectType.armor, slot = i}
		if i == tes3.armorSlot.leftGauntlet or i == tes3.armorSlot.rightGauntlet then	-- if no gloves - check for bracers
			if not stack then stack = tes3.getEquippedItem{actor = armored_actor, objectType = tes3.objectType.armor, slot = i+3} end
		end
		if stack then
			local item = stack.object
			if item.weightClass == 0 then
				armor.light = armor.light + value
			elseif item.weightClass == 1 then
				armor.medium = armor.medium + value
			elseif item.weightClass == 2 then
				armor.heavy = armor.heavy + value
			end
		end
	end
  return armor
end

local function calculate_cast_chance(spell_cost, willpower, luck, magic_skill)
  -- Fatigue affects spell costs instead (after chance is calculated, so it does not affect chance).
  --
  -- Two formulas remain from an earlier three-formula set (the middle "Exp v1.2" was removed):
  --
  -- Formula 2 — "Almost Flat" (originally v1.0):
  --   flat_increase=40, skill_coef=0.83, cost_exp=1.21, willpower_coef=0.2
  --   Higher base chance, lower skill scaling, less punishing cost exponent.
  --   Compresses the range between low-skill and high-skill builds.
  --
  -- Formula 3 — "Complex" / Baseline (originally described as "Exp v1.2 with skill-curve tweaks"):
  --   flat_increase=22, skill_coef=1.65, cost_exp=1.4, willpower_coef=0.4
  --   Steeper skill scaling, more differentiation between builds. Recommended.
  --
  -- Any value other than 2 falls through to the baseline (3) coefficients.

  local cast_chance = 0
  local willpower_coeficient = 0.4
  local luck_coeficient = 0.25
  local spell_cost_coeficient_exp = 1.4
  local magic_skill_coeficient = 1.65
  local flat_increase = 22
  if config.chance_formula == 2 then
    willpower_coeficient = 0.2
    luck_coeficient = 0.12
    spell_cost_coeficient_exp = 1.21
    magic_skill_coeficient = 0.83
    flat_increase = 40
  end
  -- fixing the skill values for better progression
  -- so we smooth the mid-levels 30-50 for early game balance
  -- 30 behaves as 30, but 50 behaves as 40
  if magic_skill >= 30 and magic_skill <= 50 then
    magic_skill = (magic_skill + 30) / 2
  elseif magic_skill > 50 and magic_skill <= 65 then
    -- then we get faster growth in 50-65 range, so while 50 behaves as 40, 65 behaves as 65 again
    magic_skill = (magic_skill - 50) * 5/3 + 40
  end
  -- willpower softcap, since it can get absurd, willpower_softcap = 0 - no cap, willpower_softcap = 100 - hard cap
  if willpower > 100 then
    willpower = 100 + (willpower - 100) ^ ((100 - config.willpower_softcap) / 100)
  end
  cast_chance = flat_increase + willpower_coeficient * willpower + luck_coeficient * luck - (spell_cost ^ spell_cost_coeficient_exp) +
      magic_skill_coeficient * magic_skill
  -- Clamping might actually be not the best approach if you want to visualise just how terrible your chances of casting are (-186 chance aka you'll never cast that)
  cast_chance = math.clamp(math.round(cast_chance), 0, 100)
  return cast_chance
end

--- Applies hybrid mode shoulder transform to a raw cast chance.
--- Caller is responsible for ensuring sa_cut_in < sa_fulcrum < sa_cut_off.
--- @param chance number  Raw cast chance (0–100) from calculate_cast_chance.
--- @return number        Effective chance after piecewise linear remapping and quantisation.
local function apply_hybrid_mode(chance)
  local sa_ci = config.sa_cut_in_value
  local sa_fv = config.sa_fulcrum_value
  local sa_co = config.sa_cut_off_value
  local sa_bp = config.sa_base_probability
  local sa_cs = config.sa_chance_step

  if chance >= sa_co then
    return 100
  elseif chance >= sa_fv then
    -- Upper arm: linear from sa_bp (at fulcrum) to ~100 (at cut-off), quantised.
    return math.floor((sa_bp + (chance - sa_fv) * (100 - sa_bp) / (sa_co - sa_fv)) / sa_cs) * sa_cs
  elseif chance >= sa_ci then
    -- Lower arm: linear from 0 (at cut-in) to sa_bp (at fulcrum), quantised.
    return math.floor(((chance - sa_ci) * sa_bp / (sa_fv - sa_ci)) / sa_cs) * sa_cs
  else
    return 0
  end
end

return {
  calculate_cast_chance = calculate_cast_chance,
  get_armor_coefs       = get_armor_coefs,
  apply_hybrid_mode     = apply_hybrid_mode,
}
