-- modules/spell_manager.lua
-- Spell cost computation from effects, synergy detection, modifier handling, and per-spell cost cache.
--
-- Storage format for motte_spell_storage[spell_id]:
--   { cost, skill_table, cost_mod, chance_mod }
--   skill_table uses +1 packed indices (school + 1 = index):
--   [1]=Alteration [2]=Conjuration [3]=Destruction [4]=Illusion [5]=Mysticism [6]=Restoration
--
-- WIP — modifier system design notes:
--   Goal: compute cost_mod and chance_mod from "modifier effects" in a spell,
--   then apply them in cast_events and ui without re-running the base cost formula.
--   Steps:
--     1. Skip modifier effects when counting effects for the multi-effect formula.
--     2. For each modifier effect, look up its entry in a modifier table to get a cost/chance weight.
--     3. Sum weights → cost_mod, chance_mod. Store alongside spell cost.
--     4. In cast_events: spell_cost = spell_cost * cost_mod.
--     5. Modifier effect IDs currently: { 3401 } (see modifier_effect_ids below).
local this = {}
local log = mwse.Logger.new { moduleName = "Spell storage" }

local config = require("Magicka of the Third Era.config")
local spell_table = require("Magicka of the Third Era.data.spell_table")
local synergy_table = require("Magicka of the Third Era.data.synergy_table")
local Modifier_Logic = require("Magicka of the Third Era.modules.modifier_logic")

-- Modifier effects
local modifier_effect_ids = { 3401 }

-- Tables for offensive values of skills/attributes for effects
local att_table_offense = { [0] = 1, [1] = 0.4, [2] = 0.75, [3] = 0.65, [4] = 0.75, [5] = 0.9, [6] = 0.35, [7] = 0.35 }
local skill_table_offense = {
	[0] = 1,
	[1] = 0.4,
	[2] = 0.7,
	[3] = 0.7,
	[4] = 1,
	[5] = 1,
	[6] = 1,
	[7] = 1,
	[8] = 0.8,
	[9] = 0.4,
	[10] = 1,
	[11] = 0.6,
	[12] = 0.6,
	[13] = 0.6,
	[14] = 1,
	[15] = 1,
	[16] = 0.4,
	[17] = 0.7,
	[18] = 0.4,
	[19] = 0.5,
	[20] = 0.4,
	[21] = 0.7,
	[22] = 1,
	[23] = 1,
	[24] = 0.4,
	[25] = 0.4,
	[26] = 1,
}

-- Fallback parameters for effects not in the spell table (e.g. from mods).
-- Uses the +1 packed index: school + 1 = index.
-- [1]=Alteration, [2]=Conjuration, [3]=Destruction, [4]=Illusion, [5]=Mysticism, [6]=Restoration.
local school_defaults = {
	[1] = { coef = 0.40, mag_pow = 0.70, dur_pow = -0.25, area_pow = 0.10 }, -- Alteration: utility
	[2] = { coef = 0.50, mag_pow = 0.75, dur_pow = -0.20, area_pow = 0.10 }, -- Conjuration: summoning
	[3] = { coef = 0.60, mag_pow = 0.71, dur_pow = -0.20, area_pow = 0.10 }, -- Destruction: damage
	[4] = { coef = 0.35, mag_pow = 0.70, dur_pow = -0.25, area_pow = 0.10 }, -- Illusion: crowd control
	[5] = { coef = 0.45, mag_pow = 0.72, dur_pow = -0.20, area_pow = 0.10 }, -- Mysticism: utility/hybrid
	[6] = { coef = 0.40, mag_pow = 0.70, dur_pow = -0.30, area_pow = 0.10 }, -- Restoration: healing/buffs
}

local function detect_synergies(effect_db, effect_costs, synergy_array)
	-- preparation
	-- MODIFIERS: unsure if I have to do anything here. maybe skip modifier effects? but if they're not a part of a synergy then it's fine?
	local synergy_bonuses = { synergy_ids = {}, cost_discount = 0 }
	local total_effect_cost = 0
	for i = 1, #effect_costs do
		total_effect_cost = total_effect_cost + effect_costs[i]
	end

	-- go through every synergy to see if it fits. It's not optimized atm, but seems to work well. Maybe lua is effective enough.
	for i, synergy in ipairs(synergy_array) do

		-- local effect_check_array = {}
		-- for j=1, required_effect_amount do
		--  effect_check_array[effects_required[j]] = -1
		-- end

		local synergy_rules = synergy.rules
		local synergy_fulfilment_array = {}
		for a = 1, #synergy_rules do
			synergy_fulfilment_array[a] = -1
		end

		-- iterate through each rule (pick each for one synergy)
		for j, rule in ipairs(synergy_rules) do
			-- iterate through each effect
			for v, effect in ipairs(effect_db) do
				-- print(string.format("Effect ID: %d. Mag: %d-%d. ", effect.id, effect.min, effect.max))
				local is_legit_effect = true
				local rule_fulfilment_array = {}
				for b = 1, #rule do
					rule_fulfilment_array[b] = -1
				end
				-- iterate through each part of rule, for each effect
				for k, item in ipairs(rule) do
					-- print(string.format("Rule part requirement: %s is %s %d", item.field, item.sign, item.value))
					local field_value = effect[item.field]
					-- convert the sign into condition
					if item.sign == "equal" then
						if field_value == item.value then
							-- print("Rule part satisfied!")
						else
							-- print("Rule part not satisfied!")
							is_legit_effect = false
						end
					elseif item.sign == "greater" then
						if field_value > item.value then
							-- print("Rule part satisfied!")
						else
							-- print("Rule part not satisfied!")
							is_legit_effect = false
						end
					elseif item.sign == "greater or equal" then
						if field_value >= item.value then
							-- print("Rule part satisfied!")
						else
							-- print("Rule part not satisfied!")
							is_legit_effect = false
						end
					elseif item.sign == "less" then
						if field_value < item.value then
							-- print("Rule part satisfied!")
						else
							-- print("Rule part not satisfied!")
							is_legit_effect = false
						end
					elseif item.sign == "less or equal" then
						if field_value <= item.value then
							-- print("Rule part satisfied!")
						else
							-- print("Rule part not satisfied!")
							is_legit_effect = false
						end
					elseif item.sign == "not equal" then
						if field_value ~= item.value then
							-- print("Rule part satisfied!")
						else
							-- print("Rule part not satisfied!")
							is_legit_effect = false
						end
					end
					-- if satisfies this part, for this part's id, set it's value in array to effect number
					if is_legit_effect then
						-- print(string.format("Effect number %d satisfies rule %d of the synergy rule array for rule no. %d", v, j, i))
						rule_fulfilment_array[k] = v
					end
				end
				-- now that our effect passed through every part of rule, check the fulfilment array. if at least one is wrong, the effect is not legit for the rule.
				for c = 1, #rule_fulfilment_array do
					if rule_fulfilment_array[c] == -1 then
						is_legit_effect = false
					end
				end
				-- if effect satisfies all conditions described in this rule, we write it down
				if is_legit_effect then
					synergy_fulfilment_array[j] = v
				end
			end
		end

		-- check the synergy array whether all the rules are satisfied
		local synergy_works = true
		for d = 1, #synergy_fulfilment_array do
			if synergy_fulfilment_array[d] == -1 then
				synergy_works = false
			end
			-- print(string.format("Rule number %d. Satisfied by effect number: %d.", d, synergy_fulfilment_array[d]))
		end

		if synergy_works then
			log:trace(string.format("Synergy %s works for this spell!", synergy.name, synergy.benefit.type))
			table.insert(synergy_bonuses.synergy_ids, i)
			local effect_weight = 0
			-- weight is equal to the lowest relevant / total cost
			for d = 1, #synergy_fulfilment_array do
				if effect_weight == 0 then
					effect_weight = effect_costs[synergy_fulfilment_array[d]]
				else
					effect_weight = math.min(effect_weight, effect_costs[synergy_fulfilment_array[d]])
				end
			end
			effect_weight = effect_weight / total_effect_cost
			log:trace(string.format("Weight for this synergy: %.2f", effect_weight))
			-- for now only cost discount is supported
			if synergy.benefit.type == "cost_discount" then
				synergy_bonuses.cost_discount = synergy_bonuses.cost_discount + effect_weight * synergy.benefit.value
			end
		end

	end

	return synergy_bonuses
end

local function detect_all_modifier_effects(effect_array)
	local modifiers = {}
	local seen = {}
	for j, effect in ipairs(effect_array) do
		for k, effect_id in ipairs(modifier_effect_ids) do
			if effect.id == effect_id and not seen[effect_id] then
				log:trace(string.format("Found a modifier effect: %s", effect.id))
				table.insert(modifiers, effect.id)
				seen[effect_id] = true
			end
		end
	end
	return modifiers
end

local function weighed_average(var_array, weight_array, method)
	local avg = 0
	local sum = 0
	if method == "arithmetic" then
		for i, x in ipairs(var_array) do
			avg = avg + x * weight_array[i]
		end
		for i, x in ipairs(weight_array) do
			sum = sum + x
		end
		avg = avg / sum
	elseif method == "geometric" then
		for i, x in ipairs(var_array) do
			avg = avg + math.log(x) * weight_array[i]
		end
		for i, x in ipairs(weight_array) do
			sum = sum + x
		end
		avg = math.exp(avg / sum)
	end
	return avg
end

-- Effect cost calculation, grabs all the info from the spell table and uses a generalized alg in most cases.
this.effect_cost_advanced = function(effect)
	-- MODIFIERS: may need to add a check for modifier effect
	local t = {}
	local effect_cost = 0
	local effect_mag = 0
	local effect_strength = 0
	local effect_id = effect.id
	-- parameters to grab, default values if not in the db
	local mag_pow = 1
	local coef = 1
	local duration_pow = 0
	local duration_min = 1
	local area_pow = 0.1
	local constant_offset = 0
	local mag_offset = 0
	local duration_offset = 0
	local effect_strength_min = 0
	-- lua is stupid and starts arrays from 1, we have to remap the id=0 to something else if we want an iterable table
	-- Why do we want an iterable table, again?
	if effect_id == 0 then
		effect_id = 3434
	end
	t = spell_table[effect_id]
	if not t then
		local school = effect.object and effect.object.school or 0
		t = school_defaults[school + 1] or school_defaults[1]
		log:warn(string.format("Effect ID %d (%s) not in spell table, using school %d defaults.",
			effect.id, effect.object and effect.object.name or "unknown", school))
	end
	if t then
		-- get everything from the table, if possible
		if t.mag_pow then
			mag_pow = t.mag_pow
		end
		if t.coef then
			coef = t.coef
		end
		if t.dur_pow then
			duration_pow = t.dur_pow
		end
		if t.dur_min then
			duration_min = t.dur_min
		end
		if t.area_pow then
			area_pow = t.area_pow
		end
		-- offsets
		if t.const_offset then
			constant_offset = t.const_offset
		end
		if t.mag_offset then
			mag_offset = t.mag_offset
		end
		if t.dur_offset then
			duration_offset = t.dur_offset
		end
		-- range mods
		if effect.rangeType == 1 then
			if t.range1_coef_mod then
				coef = coef * t.range1_coef_mod
			end
			if t.range1_dur then
				duration_pow = t.range1_dur
			end
		elseif effect.rangeType == 2 then
			if t.range2_coef_mod then
				coef = coef * t.range2_coef_mod
			end
			if t.range2_dur then
				duration_pow = t.range2_dur
			end
		end
		-- modify coef for attribute/skill
		if effect_id == 17 or effect_id == 22 then
			coef = coef * att_table_offense[effect.attribute]
		end
		if effect_id == 21 or effect_id == 26 then
			coef = coef * skill_table_offense[effect.skill]
		end

		-- minimal strength
		if t.strength_min then
			effect_strength_min = t.strength_min
		end
		-- Calculate effect strength
		if t.ignore_magmin then
			effect_mag = math.max(2 * (math.max(effect.max, 1) + mag_offset), effect_strength_min)
		else
			effect_mag = math.max((math.max(effect.min, 1) + math.max(effect.max, 1) + 2 * mag_offset), effect_strength_min)
		end
		effect_strength = effect_mag * math.max((effect.duration + duration_offset), duration_min)
		-- Check for overrides
		if t.range0_const_cost and effect.rangeType == 0 then
			effect_cost = t.range0_const_cost
		else
			if t.const_cost then
				effect_cost = t.const_cost
			else
				effect_cost = (effect_strength ^ mag_pow) * coef *
				              (math.max((effect.duration + duration_offset), duration_min) ^ duration_pow) *
				              ((effect.radius + 1) ^ area_pow) + constant_offset
			end
		end
		-- Special snowflake - targeted levitation with low magnitude
		-- Boring linear formula for now (10s = 10, 20s = 17)
		if effect_id == 10 and effect.rangeType ~= 0 and effect.min < 30 then
			log:trace(string.format("Found targeted levitation with effect min of %d", effect.min))
			if effect.rangeType == 1 then
				effect_cost = 0.65 * effect.duration * ((effect.radius + 1) ^ 0.1) + 2
			else
				effect_cost = 0.72 * effect.duration * ((effect.radius + 1) ^ 0.1) + 2
			end
		end
		log:trace(string.format("Effect ID %d calculated successfully. Costs: %.2f.", effect_id, effect_cost))
	end
	return effect_cost
end

-- High effort formula for multi effect spells to make them cost correctly with non-linear scaling
-- Spell with 2 effects "frost damage 30" and "frost damage 20" will cost exactly the same as the spell with 1 effect "frost damage 50", although these effects, when added up, cost more.
this.spell_cost_advanced = function(effect_array, cost_array)

	local spell_cost = 0
	local strength_array = {}
	local mag_pow_array = {}
	local coef_array = {}
	local duration_array = {}
	local duration_pow_array = {}
	local radius_array = {}
	local area_pow_array = {}
	local const_offset_array = {}

	local has_const_offset = false
	local weighed_mag_pow = 1
	local weighed_coef = 1
	local weighed_duration = 1
	local weighed_duration_pow = 1
	local weighed_radius = 1
	local weighed_area_pow = 1
	local weighed_const_offset = 0
	local total_strength = 0
	local sum_of_costs = 0

	-- Synergies!
	local synergy_bonuses = detect_synergies(effect_array, cost_array, synergy_table)

	-- remove modifiers from further procession
	local non_modifier_effect_array = {}
	local non_modifier_cost_array = {}
	-- numberer (maybe redundant?)
	local n = 1
	for i, effect in ipairs(effect_array) do
		local modifier = false
		-- modifier check for the effect #i
		for k, effect_id in ipairs(modifier_effect_ids) do
			if effect.id == effect_id then
				modifier = true
				log:trace(string.format("Found a modifier effect: %s", effect.id))
			end
		end
		if not (modifier) then
			table.insert(non_modifier_effect_array, effect)
			table.insert(non_modifier_cost_array, cost_array[n])
		end
		n = n + 1
	end

	-- we process non-modifiers ONLY!
	for i = 1, #non_modifier_effect_array do
		local t = {}
		-- parameters for the effects
		local mag_pow = 1
		local coef = 1
		local duration_pow = 0
		local duration_min = 1
		local area_pow = 0.2
		local constant_offset = 0
		local mag_offset = 0
		local duration_offset = 0
		local effect_strength_min = 0

		local effect_mag = 0
		-- we might fail to find water breathing, so I've added both 0 and 3434 as indices.
		t = spell_table[non_modifier_effect_array[i].id]
		if not t then
			local school = non_modifier_effect_array[i].object and non_modifier_effect_array[i].object.school or 0
			t = school_defaults[school + 1] or school_defaults[1]
			log:warn(string.format("Effect ID %d (%s) not in spell table, using school %d defaults.",
				non_modifier_effect_array[i].id,
				non_modifier_effect_array[i].object and non_modifier_effect_array[i].object.name or "unknown",
				school))
		end
		if t then
			-- basic
			if t.mag_pow then
				mag_pow = t.mag_pow
			end
			if t.coef then
				coef = t.coef
			end
			if t.dur_pow then
				duration_pow = t.dur_pow
			end
			if t.dur_min then
				duration_min = t.dur_min
			end
			if t.area_pow then
				area_pow = t.area_pow
			end
			-- offsets
			if t.const_offset then
				constant_offset = t.const_offset
			end
			if t.mag_offset then
				mag_offset = t.mag_offset
			end
			if t.dur_offset then
				duration_offset = t.dur_offset
			end
			-- range mods
			if non_modifier_effect_array[i].rangeType == 1 then
				if t.range1_coef_mod then
					coef = coef * t.range1_coef_mod
				end
				if t.range1_dur then
					duration_pow = t.range1_dur
				end
			elseif non_modifier_effect_array[i].rangeType == 2 then
				if t.range2_coef_mod then
					coef = coef * t.range2_coef_mod
				end
				if t.range2_dur then
					duration_pow = t.range2_dur
				end
			end
			-- modify coef for attribute/skill
			if non_modifier_effect_array[i].id == 17 or non_modifier_effect_array[i].id == 22 then
				coef = coef * att_table_offense[non_modifier_effect_array[i].attribute]
			end
			if non_modifier_effect_array[i].id == 21 or non_modifier_effect_array[i].id == 26 then
				coef = coef * skill_table_offense[non_modifier_effect_array[i].skill]
			end
			-- minimal strength
			if t.strength_min then
				effect_strength_min = t.strength_min
			end
			-- Skip if it has overrides (abusable / non-mergeable skill). Returns 0 and therefore we use sum of effect costs for the price instead.
			-- for const_cost, have a 'modifier effect check!!!'
			if (t.range0_const_cost and non_modifier_effect_array[i].rangeType == 0) or t.const_cost or
			(non_modifier_effect_array[i].id == 10 and non_modifier_effect_array[i].rangeType ~= 0) then
				log:trace(
				"This spell is not valid for the advanced formula (constant cost, targeted levitation, and such). Aborting calculations, using sum of effects instead.")
				return { cost = 0, synergies = synergy_bonuses }
			end
			-- Calculate strength and put it in array.
			if t.ignore_magmin then
				effect_mag = math.max(2 * (math.max(non_modifier_effect_array[i].max, 1) + mag_offset), effect_strength_min)
			else
				effect_mag = math.max(
				             math.max(non_modifier_effect_array[i].min, 1) + math.max(non_modifier_effect_array[i].max, 1) + 2 *
				             mag_offset, effect_strength_min)
			end
			strength_array[i] = effect_mag * math.max((non_modifier_effect_array[i].duration + duration_offset), duration_min)
			-- Add stuff to separate arrays to use them for more readable weighed average calculation.
			if constant_offset > 0 then
				has_const_offset = true
			end
			mag_pow_array[i] = mag_pow
			coef_array[i] = coef
			duration_array[i] = math.max((non_modifier_effect_array[i].duration + duration_offset), duration_min)
			duration_pow_array[i] = duration_pow
			radius_array[i] = non_modifier_effect_array[i].radius + 1
			area_pow_array[i] = area_pow
			const_offset_array[i] = constant_offset
		end
	end

	-- weighing everything
	weighed_mag_pow = weighed_average(mag_pow_array, non_modifier_cost_array, "geometric")
	weighed_coef = weighed_average(coef_array, non_modifier_cost_array, "geometric")
	weighed_duration = weighed_average(duration_array, non_modifier_cost_array, "geometric")
	weighed_duration_pow = weighed_average(duration_pow_array, non_modifier_cost_array, "arithmetic")
	weighed_radius = weighed_average(radius_array, non_modifier_cost_array, "geometric")
	weighed_area_pow = weighed_average(area_pow_array, non_modifier_cost_array, "arithmetic")
	-- This might be still non-ideal, need to think.
	-- Const offsets, effectively, do not stack additively, which is generally good (otherwise it would make spells with several const offsets unusable), but might lead to some weird cases.
	if has_const_offset then
		weighed_const_offset = weighed_average(const_offset_array, non_modifier_cost_array, "arithmetic")
	end

	for i, str in ipairs(strength_array) do
		total_strength = total_strength + str
	end

	for i, cost in ipairs(non_modifier_cost_array) do
		sum_of_costs = sum_of_costs + cost
	end

	-- Here it comes
	spell_cost = (total_strength ^ weighed_mag_pow) * weighed_coef * (weighed_duration ^ weighed_duration_pow) *
	             (weighed_radius ^ weighed_area_pow) + weighed_const_offset

	if config.log_level == "TRACE" then
		for i = 1, #non_modifier_effect_array do
			log:trace(string.format(
			          "Effect no %d. Strength: %d, Mag pow: %.2f, Coef: %.2f, Duration: %d, Duration pow: %.2f, Radius: %d, Area pow: %.2f, Const offset: %d",
			          i, strength_array[i], mag_pow_array[i], coef_array[i], duration_array[i], duration_pow_array[i],
			          radius_array[i], area_pow_array[i], const_offset_array[i]))
		end
		log:trace(string.format(
		          "Weighed mag_pow: %.3f\nweighed coef: %.3f\nweighed duration: %.3f\nweighed duration pow: %.3f\nweighed radius: %.3f\nweighed area pow: %.3f\nweighed const offset: %.3f",
		          weighed_mag_pow, weighed_coef, weighed_duration, weighed_duration_pow, weighed_radius, weighed_area_pow,
		          weighed_const_offset))
		log:trace(string.format("Old cost (sum of effect costs): %.2f\nNew cost: %.2f.\nLowest one will be used.",
		                        sum_of_costs, spell_cost))
	end

	if sum_of_costs < spell_cost and #non_modifier_effect_array > 1 then
		log:trace(
		"Found unsynergetic effects in the spell (sum of effect costs is lower than calculated cost). Sum of effects cost will be used instead. Above are the spell details.")
	end

	-- In some cases it might be worse than sum of effect costs. For these cases, we use sum of costs instead. If this function returns 0, same logic will apply (but synergies won't be applied so it's bad).
	spell_cost = math.min(spell_cost, sum_of_costs)

	-- Apply modifiers.
	local modifier_list = detect_all_modifier_effects(effect_array)
	if #modifier_list > 0 then
		log:trace("Modifiers have been found. Processing the modifier effects.")
		local modifier_changes = { difficulty = 1, cost = 1 }
		modifier_changes = Modifier_Logic.process_modifiers(effect_array, cost_array, modifier_list)
		spell_cost = spell_cost * modifier_changes.difficulty
	end

	-- Apply synergies. Treats the 'better' cost. Still won't apply synergies to spells with abusable effects.
	if synergy_bonuses.cost_discount > 0 then
		spell_cost = spell_cost * (1 - synergy_bonuses.cost_discount)
		log:trace(string.format("Synergies found! Discount is %.2f * spell cost!", synergy_bonuses.cost_discount))
	end

	return { cost = spell_cost, synergies = synergy_bonuses }
end

-- Compute the player's effective skill for a spell from the stored skill_table.
-- skill_table uses the +1 packed format: index = school + 1.
-- [1]=Alteration, [2]=Conjuration, [3]=Destruction, [4]=Illusion, [5]=Mysticism, [6]=Restoration.
function this.compute_skill(skill_table, mobile)
	for i = 1, 6 do
		if skill_table[i] == nil then
			log:error(string.format(
				"compute_skill: skill_table[%d] is nil. Full table: [1]=%s [2]=%s [3]=%s [4]=%s [5]=%s [6]=%s",
				i,
				tostring(skill_table[1]), tostring(skill_table[2]), tostring(skill_table[3]),
				tostring(skill_table[4]), tostring(skill_table[5]), tostring(skill_table[6])
			))
			return 0
		end
	end
	return
		skill_table[1] * (mobile.alteration  and mobile.alteration.current  or mobile.magic.current or 0)
		+ skill_table[2] * (mobile.conjuration and mobile.conjuration.current or mobile.magic.current or 0)
		+ skill_table[3] * (mobile.destruction and mobile.destruction.current or mobile.magic.current or 0)
		+ skill_table[4] * (mobile.illusion    and mobile.illusion.current    or mobile.magic.current or 0)
		+ skill_table[5] * (mobile.mysticism   and mobile.mysticism.current   or mobile.magic.current or 0)
		+ skill_table[6] * (mobile.restoration and mobile.restoration.current or mobile.magic.current or 0)
end

-- Normalize a working skill_table (index 0=Alteration) by total_effect_cost and
-- return a packed table (school + 1 = index) suitable for persistent storage.
local function pack_skill_table(working_table, total_effect_cost)
	local packed = {}
	for k = 0, 5 do
		working_table[k] = working_table[k] / total_effect_cost
		log:trace(string.format("Coeficient for skill %d: %.2f", k, working_table[k]))
		packed[k + 1] = working_table[k]
	end
	return packed
end

-- Get spell cost and skill data from the cache, or calculate and cache it fresh.
--
-- Parameters:
--   spell               tes3spell object
--   config              mod config table
--   premade_spells      table of unique spell cost overrides
--   save_always_succeeds  bool: true for UI menus (saves weakest-school entry),
--                                false for cast event (just uses vanilla cost)
--   mobile              the relevant mobile for skill lookup (usually tes3.mobilePlayer)
--
-- Returns a table { cost, skill_for_spell, skill_table } on success, or nil if the
-- spell has zero total effect cost (i.e. an empty or fully-invalid spell).
function this.get_or_calculate(spell, premade_spells, save_always_succeeds, mobile)
	local spell_id = spell.id

	-- Cache hit: return stored values directly (evict if skill_table is corrupt)
	if tes3.player.data.motte_spell_storage[spell_id] then
		local spell_data = tes3.player.data.motte_spell_storage[spell_id]
		local skill_table = spell_data.skill_table
		local valid = skill_table
		if valid then
			for i = 1, 6 do
				if skill_table[i] == nil then valid = false; break end
			end
		end
		if not valid then
			log:warn(string.format("Spell %s has corrupt skill_table in storage, evicting for recalculation.", spell_id))
			tes3.player.data.motte_spell_storage[spell_id] = nil
		else
			local spell_cost = spell_data.cost
			log:trace(string.format("Spell %s found in storage. Cost: %.2f.", spell, spell_cost))
			local skill_for_spell = mobile and this.compute_skill(skill_table, mobile) or 0
			return { cost = spell_cost, skill_for_spell = skill_for_spell, skill_table = skill_table }
		end
	end

	-- Unique spell overrides
	local unique_spell_data = premade_spells[spell_id] or {}
	local old_cost = spell.magickaCost

	if config.override_costs_alwaystosucceed or not spell.alwaysSucceeds then
		-- Full cost calculation path (normal spells, or always-succeed with cost override)
		local working_table = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }
		local effect_db = {}
		local cost_db = {}
		local total_effect_cost = 0

		for j, effect in ipairs(spell.effects) do
			if effect.object then
				local eff_cost = this.effect_cost_advanced(effect)
				cost_db[j] = eff_cost
				effect_db[j] = effect
				total_effect_cost = total_effect_cost + eff_cost
				if effect.object.school >= 0 and effect.object.school <= 5 then
					working_table[effect.object.school] = working_table[effect.object.school] + eff_cost
				else
					working_table[0] = working_table[0] + eff_cost
				end
			end
		end

		if total_effect_cost == 0 then
			return nil
		end

		local packed_table = pack_skill_table(working_table, total_effect_cost)

		-- Single vs multi-effect cost formula
		local spell_cost
		if #effect_db == 1 then
			log:trace("One-effect spell found! Using basic formula.")
			spell_cost = total_effect_cost
		else
			log:trace("Multi-effect spell found! Trying advanced formula.")
			local adv_calc = this.spell_cost_advanced(effect_db, cost_db)
			spell_cost = adv_calc.cost
			if spell_cost == 0 then
				log:trace("Non-legit spell for advanced formula! Going for plan B.")
				spell_cost = total_effect_cost
			end
		end

		-- Apply unique spell overrides
		if unique_spell_data.use_premade_cost then
			spell_cost = old_cost
			log:trace("Found unique spell rule. Spell will use old costs.")
		end
		if unique_spell_data.fixed_cost then
			spell_cost = unique_spell_data.fixed_cost
			log:trace("Found unique spell rule. Spell will use pre-written costs.")
		end
		if unique_spell_data.flat_mult then
			spell_cost = spell_cost * unique_spell_data.flat_mult
			log:trace("Found unique spell rule. Spell will have it's cost multiplied by a value.")
		end
		if unique_spell_data.skill_table then
			-- premade_spells uses 0-based school indices; convert to +1 packed format
			local st = unique_spell_data.skill_table
			packed_table = { st[0], st[1], st[2], st[3], st[4], st[5] }
			log:trace("Found unique spell rule. Spell will use custom skill table.")
		end

		-- Cache result
		tes3.player.data.motte_spell_storage[spell_id] = {
			cost = spell_cost,
			skill_table = packed_table,
			cost_mod = 1,
			chance_mod = 1,
		}

		local skill_for_spell = mobile and this.compute_skill(packed_table, mobile) or 0
		return { cost = spell_cost, skill_for_spell = skill_for_spell, skill_table = packed_table }

	else
		-- Always-succeed spell: use vanilla cost
		local spell_cost = spell.magickaCost
		local skill_for_spell = 0
		local saved_table = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 }

		if save_always_succeeds and mobile then
			local do_not_save_this = false
			local weakest_school = spell:getLeastProficientSchool(mobile)
			local relevant_skill

			if weakest_school == 0 then
				relevant_skill = mobile.alteration and mobile.alteration.current or mobile.magic.current
			elseif weakest_school == 1 then
				relevant_skill = mobile.conjuration and mobile.conjuration.current or mobile.magic.current
			elseif weakest_school == 2 then
				relevant_skill = mobile.destruction and mobile.destruction.current or mobile.magic.current
			elseif weakest_school == 3 then
				relevant_skill = mobile.illusion and mobile.illusion.current or mobile.magic.current
			elseif weakest_school == 4 then
				relevant_skill = mobile.mysticism and mobile.mysticism.current or mobile.magic.current
			elseif weakest_school == 5 then
				relevant_skill = mobile.restoration and mobile.restoration.current or mobile.magic.current
			else
				relevant_skill = 100
				do_not_save_this = true
				log:debug("Either no school or custom school - setting skill to 100. Not saving this skill in the DB.")
			end

			log:trace(string.format(
			          "Found a pre-made spell %s, that's intended to always succeed, so it's cost will stay. Relevant skill: %d",
			          spell.id, relevant_skill))
			skill_for_spell = relevant_skill

			if not do_not_save_this then
				saved_table[weakest_school + 1] = 1
				tes3.player.data.motte_spell_storage[spell_id] = {
					cost = spell_cost,
					skill_table = saved_table,
					cost_mod = 1,
					chance_mod = 1,
				}
			end
		else
			log:trace(string.format("Pre-made spell %s is being cast, it's cost will stay.", spell.id))
		end

		return { cost = spell_cost, skill_for_spell = skill_for_spell, skill_table = saved_table }
	end
end

-- If the +1 skill_table format hasn't been confirmed for this save, clear storage so all
-- spells are recalculated fresh. Guarded by motte_skill_table_version so it only resets once.
-- Version history: 1 = failed remap attempt (data may be corrupt), 2 = clean reset to +1 format.
function this.migrate_skill_tables()
	if tes3.player.data.motte_skill_table_version == 2 then return end
	tes3.player.data.motte_spell_storage = {}
	tes3.player.data.motte_skill_table_version = 2
	log:info("Spell storage cleared for +1 skill_table format migration (v2).")
end

return this
