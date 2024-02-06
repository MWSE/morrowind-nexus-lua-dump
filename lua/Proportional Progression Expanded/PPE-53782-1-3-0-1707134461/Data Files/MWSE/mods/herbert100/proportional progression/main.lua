
--[[
	Proportional Progression Expanded

	Original mod by NullCascade

	Tweaked and updated by herbert100

	This module allows configuring the rate at which skills level.
]]--

local log = require("herbert100.logger").new("PPE") ---@type herbert.Logger

-- copied from NullCascade's other mods. this will check if "Proportional Progression" was installed and then delete it.
-- this is necessary because the mods config is marked as part of the mod, so it won't be imported otherwise.
-- Ensure we don't have an old version installed.
if lfs.attributes("Data Files/MWSE/lua/nc/xpscale/mod_init.lua") then
	if lfs.rmdir("Data Files/MWSE/lua/nc/xpscale/", true) then
		log("Old install found and deleted.")
		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		log("Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/xpscale' and restart Morrowind.")
		tes3.messageBox("[PPE: Error] Original Proportional Progression mod could not be deleted. Please delete it. Path: \"Data Files\"\\MWSE\\lua\\nc\\xpscale\\mod_init.lua")
		return
	end
end



local config = require("herbert100.proportional progression.config") ---@type PPE.config
local utils = require("herbert100.proportional progression.config.utils")
local interop = require("herbert100.proportional progression.interop")

function interop.change_profile(profile_name)
	return utils.change_profile(config, profile_name)
end






-- =============================================================================
-- INITIALIZE CONFIG AND IMPORT OLD CONFIG IF IT EXISTS
-- =============================================================================


require("herbert100.proportional progression.mcm") -- you probably do not want to open this file, it will bring nothing but agony and pain. this your only warning


local block_next = interop.block_next
local priority = config.priority

--[[ store computation variables here, why not.]]
local global_scale_factor, lvl_delta, max_lvl, specialization_modifier

local interpolate ---@type boolean

local upd_reg = require("herbert100").update_registration

local skill_type_modifiers = {} ---@type table<tes3.skillType, number>

local skill_cfg = config.skill.modifiers

local custom_skill_cfg = config.custom_skill.modifiers

local lvl_cfg = config.level.modifiers

local skill_lvl_cfg = config.skill_level.modifiers

local skill_enabled, custom_skill_enabled, lvl_enabled, skill_lvl_enabled ---@type boolean, boolean, boolean, boolean

local function logmsg_calc_xp(e, modifier)
	local id, name
	if skill_cfg[e.skill] == nil then
		name, id = e.skill.name, string.format("%q", e.skill.id)
	else
		name, id = tes3.getSkillName(e.skill), e.skill
	end

	return "calculating xp for %q (id=%s)\n\t\z
		original xp: %s\n\t\z
		total xp: %s",
		name, id, e.progress, e.progress * modifier
end
---@param skill_or_id tes3.skill|SkillsModule.Skill
local function logmsg_calc_xp_mod(skill_or_id, lvl_mult, skill_lvl_mult, skill_mult, spec_mult, type_mult)
	local skill, player_skill, type_str, id
	-- if it's a custom skill
	if skill_cfg[skill_or_id] == nil then
		id = string.format("%q", skill_or_id.id)
		skill = skill_or_id
		player_skill = skill
		type_str = "other"
	else
		id = skill_or_id
		skill, player_skill = tes3.getSkill(id), tes3.mobilePlayer.skills[1+id]
		type_str = table.find(tes3.skillType, player_skill.type)
	end
	
	local po = tes3.player.object
	local player_lvl = po.level
	local spec_mult_str = skill.specialization == po.class.specialization and spec_mult or "N/A"

	return "Calculated modifiers for %q (id=%s):\n\t\z
		global_mult: 	 	  %.2f\n\t\z
		skill_mult: 		  %-8s (skill name:   %s)\n\t\z
		level_mult: 		  %-8s (player level: %i)\n\t\z
		skill_level_mult:     %-8s (skill level:  %i)\n\t\z
		skill_type_modifier:  %-8s (%q skill)\n\t\z
		specialization_mult:  %s\n\t\z
		------------------------------\n\t\z
		total multiplier:	  %f",
		skill.name, id,
		global_scale_factor,
		skill_mult, 		skill.name,
		lvl_mult, 		player_lvl,
		skill_lvl_mult, player_skill.base,
		type_mult,		type_str,
		spec_mult_str,

		global_scale_factor * lvl_mult * skill_lvl_mult * skill_mult * spec_mult * type_mult
end


---@param id tes3.skill
function interop.calc_xp_modifier(id)
	local lvl_mult, skill_lvl_mult, skill_mult, spec_mult, type_mult = 1, 1, 1, 1, 1

	-- We start with the global scale.
	local po = tes3.player.object
	local player_lvl = po.level

	local player_skill = tes3.mobilePlayer.skills[id+1] ---@type tes3statisticSkill

	if skill_enabled then
		skill_mult = skill_cfg[id] 
	end

	if specialization_modifier ~= 1 and po.class.specialization == tes3.getSkill(id).specialization then
		spec_mult = specialization_modifier
	end

	type_mult = skill_type_modifiers[player_skill.type]

	if skill_lvl_enabled then
		local skill_base = player_skill.base
		if skill_base >= max_lvl then
			skill_lvl_mult = skill_lvl_cfg[max_lvl]
		else
			local prev_lvl = skill_base - skill_base % lvl_delta
			if interpolate then
				skill_lvl_mult = math.lerp(
					skill_lvl_cfg[prev_lvl], 				-- a
					skill_lvl_cfg[prev_lvl + lvl_delta], 	-- b
					(skill_base - prev_lvl) / lvl_delta		-- t
				)
			else
				skill_lvl_mult = skill_lvl_cfg[prev_lvl]
			end
		end
	end
	if lvl_enabled then
		if player_lvl >= max_lvl then
			lvl_mult = lvl_cfg[max_lvl]
		else
			local prev_lvl = player_lvl - player_lvl % lvl_delta
			if interpolate then
				lvl_mult = math.lerp(
					lvl_cfg[prev_lvl],
					lvl_cfg[prev_lvl + lvl_delta],
					(player_lvl - prev_lvl) / lvl_delta
				)
			else
				lvl_mult = lvl_cfg[prev_lvl]
			end
		end
	end

	if log.level > 3 then
		if id == tes3.skill.athletics then
			log:trace(logmsg_calc_xp_mod, id, lvl_mult, skill_lvl_mult, skill_mult, spec_mult, type_mult)
		else
			log(logmsg_calc_xp_mod, id, lvl_mult, skill_lvl_mult, skill_mult, spec_mult, type_mult)
		end
	end

	return global_scale_factor * lvl_mult * skill_lvl_mult * skill_mult * spec_mult * type_mult
end

local calc_xp_modifier = interop.calc_xp_modifier

---@param skill SkillsModule.Skill
function interop.calc_skills_module_xp_modifier(skill)
	local lvl_mult, skill_lvl_mult, skill_mult, spec_mult, type_mult = 1, 1, 1, 1, 1

	-- We start with the global scale.
	local po = tes3.player.object
	local player_lvl = po.level


	if skill_enabled then
		skill_mult = custom_skill_cfg[skill.id] 
	end

	if po.class.specialization == skill.specialization then
		spec_mult = specialization_modifier
	end

	if skill_lvl_enabled then
		local skill_base = skill.base
		if skill_base >= max_lvl then
			skill_lvl_mult = skill_lvl_cfg[max_lvl]
		else
			local prev_lvl = skill_base - skill_base % lvl_delta
			if interpolate then
				skill_lvl_mult = math.lerp(
					skill_lvl_cfg[prev_lvl], 				-- a
					skill_lvl_cfg[prev_lvl + lvl_delta], 	-- b
					(skill_base - prev_lvl) / lvl_delta		-- t
				)
			else
				skill_lvl_mult = skill_lvl_cfg[prev_lvl]
			end
		end
	end
	if lvl_enabled then
		if player_lvl >= max_lvl then
			lvl_mult = lvl_cfg[max_lvl]
		else
			local prev_lvl = player_lvl - player_lvl % lvl_delta
			if interpolate then
				lvl_mult = math.lerp(
					lvl_cfg[prev_lvl],
					lvl_cfg[prev_lvl + lvl_delta],
					(player_lvl - prev_lvl) / lvl_delta
				)
			else
				lvl_mult = lvl_cfg[prev_lvl]
			end
		end
	end

	if log.level > 3 then
		log(logmsg_calc_xp_mod, skill, lvl_mult, skill_lvl_mult, skill_mult, spec_mult, type_mult)
	end

	return global_scale_factor * lvl_mult * skill_lvl_mult * skill_mult * spec_mult * type_mult
end






-- =============================================================================
-- COMPUTATIONS
-- =============================================================================

--[[this function is the only thing that "actually does anything the player cares about".
	the rest is just feature bloat, pointless "optimization", and adding customization options
	through the MCM. well, maybe they care about the MCM options.
]]
--- @param e exerciseSkillEventData
local function update_xp(e)
	if block_next[e.skill] then 
		block_next[e.skill] = nil
		log("didn't modify xp for %s because another mod asked us not to.", tes3.getSkillName, e.skill)
		return
	end
	local modifier = calc_xp_modifier(e.skill)
	if log.level > 3 then
		if e.skill == tes3.skill.athletics then
			log:trace(logmsg_calc_xp, e, modifier)
		else
			log(logmsg_calc_xp, e, modifier)
		end
	end
	e.progress = e.progress * modifier
end

---@param e SkillsModule.exerciseSkillEventData
local function update_custom_skill_xp(e)
	if block_next[e.skill.id] then
		block_next[e.skill.id] = nil
		log("didn't modify xp for %s because another mod asked us not to.", e.skill.name)
		return
	end
	local modifier = interop.calc_skills_module_xp_modifier(e.skill)
	log(logmsg_calc_xp, e, modifier)
	e.progress = e.progress * modifier
end



-- =============================================================================
-- UPDATE COMPUTATION VALUES AND REGISTER IF APPROPRIATE
-- =============================================================================

--[[ this is called whenever the MCM page is closed, and also when the mod is first initialized

	*) it updates the calculation variables to those in the config file.
	*) because of how MCM is made, all the values in the JSON file need to be divided by 100.
	*) we do it once whenever the config is updated in order to cut down on division cycles in the actual code.
	*) it also cuts down on table accesses. not sure if any of this actually makes a difference though.
	*) i'm only bothering with this because otherwise, we would be doing all this stuff several times per second (sometimes every frame.)
		*) so it's probably better to just do it once, and then again as needed.
]]



local function update_variables()
	global_scale_factor = config.scale 
	specialization_modifier = config.specialization_modifier 

	skill_type_modifiers = {
		[tes3.skillType.major] = config.major_skill_modifier,
		[tes3.skillType.minor] = config.minor_skill_modifier,
		[tes3.skillType.misc] = config.misc_skill_modifier,
	}
	lvl_delta = config.lvl_delta
	max_lvl = config.max_lvl
	-- update_class_skill_list()

	-- -------------------------------------------------------------------------
	-- UPDATE SKILL MODIFIERS
	-- -------------------------------------------------------------------------
	lvl_enabled = config.level.enable
	skill_enabled = config.skill.enable
	skill_lvl_enabled = config.skill_level.enable
	custom_skill_enabled = config.custom_skill.enable
	-- skills need to be treated specially, everything else is copied as is.

	-- -------------------------------------------------------------------------
	-- UPDATE LEVEL AND SKILL_LEVEL MODIFIERS
	-- -------------------------------------------------------------------------
	log:trace("config: %s", require("inspect").inspect, config)
	-- level = config.level.enable and {}
	-- skill_level = config.skill_level.enable and {}
	interpolate = config.interpolate_level_modifiers

	local should_register = lvl_enabled or skill_lvl_enabled
	for k,v in pairs(config) do
		if should_register then break end
		if type(v) == "number" and k:endswith("_modifier") then
			should_register = v ~= 1 or should_register
		end
	end

	log("should_register = %s", should_register)
	
	upd_reg{callback = update_xp,
		event = tes3.event.exerciseSkill, 
		priority = config.priority, 
		old_priority = priority,
		register = skill_enabled or should_register 
	}
	upd_reg{callback = update_custom_skill_xp,
		event = "SkillsModule:exerciseSkill", 
		priority = config.priority, 
		old_priority = priority,
		register = custom_skill_enabled or should_register 
	}
	priority = config.priority
end

---@param e herbert.events.MCM_closed.data
event.register("herbert:MCM_closed", function (e)
	if e.mod_name == "Proportional Progression Expanded" then
		log("detected that the MCM was closed. updating variables...")
		utils.save(config, true)
		update_variables()
	end
end)



local function initialize()
	update_variables()
	log:info("Initialized.")
	log:debug("using config: %s", json.encode, config)
	-- we're doing this on game load so the player reference is available
end


event.register(tes3.event.initialized, initialize)
