
--[[
	Mod Initialization: Proportional Progression
	Author: NullCascade

	This module allows configuring the rate at which skills level.
]]--


-- =============================================================================
-- INITIALIZE CONFIG AND IMPORT OLD CONFIG IF IT EXISTS
-- =============================================================================

local log = require("herbert100.proportional progression.log") -- basically works as a wrapper for the `getLogger` function from `logging.logger`
local mcm = require("herbert100.proportional progression.mcm") -- you probably do not want to open this file, it will bring nothing but agony and pain. this your only warning
local config = mcm.config ---@type PPE_Config


--[[ store computation variables here, why not.]]
local global_scale_factor, lvl_delta, max_lvl, specialization_modifier, major_skill_modifier, minor_skill_modifier, misc_skill_modifier

local interpolate ---@type boolean

local skill = false				---@type table<tes3skill, number>|false	the modifiers for each skill, or false if not enabled.
local level = false				---@type table<integer, number>|false	the level modifiers, or false if not enabled.
local skill_level = false		---@type table<integer, number>|false	the skill_level modifiers, or false if not enabled.

local major_skills = {} 		---@type table<tes3skill, boolean?> record major skills, so we can check in constant time
local minor_skills = {}			---@type table<tes3skill, boolean?> record major skills, so we can check in constant time

-- =============================================================================
-- COMPUTATIONS
-- =============================================================================

--[[this function is the only thing that "actually does anything the player cares about".
	the rest is just feature bloat, pointless "optimization", and adding customization options
	through the MCM. well, maybe they care about the MCM options.
]]
--- @param e exerciseSkillEventData
local function update_xp(e)
	local skill_id = e.skill

	-- We start with the global scale.
	local modifier = global_scale_factor

	-- If we're using skill modifiers, bring that in.
	if skill ~= false then
		modifier = modifier * skill[skill_id]
	end

	if interpolate == true then
		if level ~= false then
			modifier = modifier * level[math.min(tes3.player.object.level, max_lvl)]
		end
		if skill_level ~= false then
			-- this is an array, so there's an off by 1 error because lua starts indexing at 1. thank you lua very cool
			modifier = modifier * skill_level[math.min(tes3.mobilePlayer.skills[skill_id+1].base, max_lvl)]
		end
	else
		-- If we're using player level modifiers, find the closest level and use it.
		if level ~= false then
			-- take the min so that it doesn't go over the highest index of the array (`max_lvl`)
			-- in this case, taking the min before the modulo operation is fine. the details are left as an exercise to the reader :)
			local player_lvl = math.min(tes3.player.object.level, max_lvl) 

			-- `player_lvl - player_lvl % lvl_delta` is equal to the highest multiple of `lvl_delta` that is `<= player_lvl`
			modifier = modifier * level[player_lvl - player_lvl % lvl_delta]
		end

		-- If we're using skill level modifiers, find the closest and use it.
		if skill_level ~= false then
			-- this is an array, so there's an off by 1 error because lua starts indexing at 1. thank you lua very cool
			local skill_base = math.min(tes3.mobilePlayer.skills[skill_id+1].base, max_lvl)
			modifier = modifier * skill_level[skill_base - skill_base % lvl_delta]
		end
	end
	

	if major_skills[skill_id] then
		modifier = modifier * major_skill_modifier
	elseif minor_skills[skill_id] then 
		modifier = modifier * minor_skill_modifier
	else
		modifier = modifier * misc_skill_modifier
	end

	if specialization_modifier ~= 1 and tes3.player.object.class.specialization == tes3.getSkill(skill_id).specialization then
		modifier = modifier * specialization_modifier
	end

	-- only log stuff if the `log level > 1`. (ie, at least in debug mode.) the `log:debug` function will only print stuff if `log_level > 1`, 
	-- but doing a manual check will stop the strings from being generated when they won't be used.
	if config.log_level > 1 then
		-- only print athletics increases to console if log level is set to trace, to reduce spam when debugging. trust me, it gets really bad.
		if config.log_level == 3 or skill_id ~= tes3.skill.athletics then

			-- redoing all the computation here because this code does not need to be optimized.

			local major_skill_mult = (major_skills[skill_id] and major_skill_modifier) or "N/A"
			local minor_skill_mult = (minor_skills[skill_id] and minor_skill_modifier) or "N/A"
			local misc_skill_mult
			if not major_skills[skill_id] and not minor_skills[skill_id] then
				misc_skill_mult = misc_skill_modifier
			else
				misc_skill_mult =  "N/A"
			end
			local specialization_mult = (tes3.player.object.class.specialization == tes3.getSkill(skill_id).specialization and specialization_modifier) or "N/A"
			local skill_mult = (skill and skill[skill_id]) or "disabled"
			local level_mult, skill_level_mult

			local player_skill_lvl = tes3.mobilePlayer.skills[skill_id+1].base
			local player_lvl = tes3.player.object.level
			if interpolate == true then
				if level ~= false then
					level_mult = level[math.min(player_lvl, max_lvl)]
				end
				if skill_level ~= false then
					skill_level_mult = skill_level[math.min(player_skill_lvl, max_lvl)]
				end
			else
				if level ~= false then
					local _player_lvl = math.min(player_lvl, max_lvl)
					level_mult = level[_player_lvl - _player_lvl % lvl_delta]
				end
				if skill_level ~= false then
					local skill_base = math.min(player_skill_lvl, max_lvl)
					skill_level_mult = skill_level[skill_base - skill_base % lvl_delta]
				end
			end
			level_mult = level_mult or "disabled"
			skill_level_mult = skill_level_mult or "disabled"
			


			local debug_total = global_scale_factor

			for _, f in ipairs({skill_mult, level_mult, skill_level_mult, major_skill_mult, minor_skill_mult, misc_skill_mult, specialization_mult}) do
				if type(f) == "number" then 
					debug_total = debug_total * f
				end
			end
			local skill_name = tes3.getSkillName(skill_id)
			local original_xp_gain = e.progress
			local modified_xp_gain = original_xp_gain * modifier
			log:debug(string.format(
				"Applied multipliers to \"%s\" (id=%i):\n\t\z
					global_mult: 	 	  %.2f\n\t\z
					skill_mult: 		  %-8s (skill name:   %s)\n\t\z
					level_mult: 		  %-8s (player level: %i)\n\t\z
					skill_level_mult:     %-8s (skill level:  %i)\n\t\z
					major_mult:           %s\n\t\z
					minor_mult:           %s\n\t\z
					misc_mult:            %s\n\t\z
					specialization_mult:  %s\n\t\z
					------------------------------\n\t\z
					total multiplier:	  %f\n\t\z
					original XP gain:     %f\n\t\z
					modified XP gain:     %f",
				skill_name, skill_id,
				global_scale_factor,
				tostring(skill_mult), 		skill_name,
				tostring(level_mult), 		player_lvl,
				tostring(skill_level_mult), player_skill_lvl,
				tostring(major_skill_mult),
				tostring(minor_skill_mult),
				tostring(misc_skill_mult),
				tostring(specialization_mult),
				modifier,
				original_xp_gain,
				modified_xp_gain
			))
			if debug_total ~= modifier then 
				log:error(string.format("something is wrong in the debugging code or the original code!!\n\t\z
					the original modifier and the recalculated modifier are different!\n\t\z
						original total:     %f\n\t\t\z
						recalculated total: %f", 
				modifier, debug_total))
			end
		end
	end
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

-- true if we tried to load but couldn't. this is so that we only retry once
local already_failed_to_load = false
-- update the list of major and minor skills
local function update_class_skill_list()
	--[[rudimentary character generation check, done for compatibility with other mods.
		(they may claim the `charGenFinished` event and block us from doing anything, or maybe they don't play nicely with `isCharGenFinished` function).
		*) we call this method again when chargen is finished, just to be extra safe (since it's possible to change your class after picking a birthsign).
	]]
	major_skills, minor_skills = {}, {}
	if tes3.mobilePlayer and tes3.mobilePlayer.birthsign then 
		log:debug("player active and class values exist")
		already_failed_to_load = false
		local class = tes3.player.object.class

		for _,skill_id in pairs(class.majorSkills) do 
			major_skills[skill_id] = true
		end

		for _,skill_id in pairs(class.minorSkills) do 
			minor_skills[skill_id] = true
		end
		if config.log_level > 1 then 
			log:trace("major skills: " .. json.encode(major_skills))
			log:trace("minor skills: " .. json.encode(minor_skills))
		end
	else
		log:debug("player class didn't exist")
		if not already_failed_to_load then -- if this is the first time we failed, try again in one second.
			timer.start{callback=update_class_skill_list, duration=1}
		end
		already_failed_to_load = true
		
	end
end

local function update_variables()
	-- mwse.saveConfig("proportional progression", config)
	global_scale_factor = config.scale 
	specialization_modifier = config.specialization_modifier 
	major_skill_modifier = config.major_skill_modifier 
	minor_skill_modifier = config.minor_skill_modifier 
	misc_skill_modifier = config.misc_skill_modifier

	lvl_delta = config.lvl_delta
	max_lvl = config.max_lvl
	-- update_class_skill_list()

	log:debug("\tglobal_scale_factor: " .. global_scale_factor)
	-- -------------------------------------------------------------------------
	-- UPDATE SKILL MODIFIERS
	-- -------------------------------------------------------------------------
	-- skills need to be treated specially, everything else is copied as is.
	if config.skill.enable == true then 
		log:debug("\tskill component enabled, making modifiers")
		skill = {}

		for skill_name,v in pairs(config.skill.modifiers) do 
			-- names are stored as string, but we need the numeric ID
			local id = tes3.skill[skill_name]
			skill[id] = v
			log:trace(string.format("\t\t%15s (id=%2i): %.2f", skill_name, id, skill[id]))
		end
		if config.log_level == 2 then log:debug("skill component: " .. json.encode(skill)) end

	else
		log:debug("\tskill modifiers are disabled, not making them")
		skill = false
	end
	log:trace("\tSKILL COMPONENT DONE")
	log:trace("\t---------------------------------------")

	-- -------------------------------------------------------------------------
	-- UPDATE LEVEL AND SKILL_LEVEL MODIFIERS
	-- -------------------------------------------------------------------------
	local lvls = mcm.get_lvls()
	log:debug("lvls: " .. json.encode(lvls))
	log:debug("config: " .. json.encode(mcm.config))
	-- level = config.level.enable and {}
	-- skill_level = config.skill_level.enable and {}
	interpolate = config.interpolate_level_modifiers

	if config.interpolate_level_modifiers then
		log:debug("level interpolation is enabled, generating modifiers")
		level = config.level.enable and {[0] = config.level.modifiers[0], [max_lvl] = config.level.modifiers[max_lvl]}
		skill_level = config.skill_level.enable and {[0] = config.skill_level.modifiers[0], [max_lvl] = config.skill_level.modifiers[max_lvl]}
		for lvl=0, max_lvl-1 do
			local a,b,t, lower_lvl, higher_lvl
			lower_lvl = lvl - lvl % lvl_delta
			higher_lvl = lower_lvl + lvl_delta
			t = (lvl - lower_lvl) / lvl_delta
			if level ~= false then
				a,b = config.level.modifiers[lower_lvl], config.level.modifiers[higher_lvl]
				level[lvl] = math.lerp(a,b,t)
			end
			if skill_level ~= false then 
				a,b = config.skill_level.modifiers[lower_lvl], config.skill_level.modifiers[higher_lvl]
				skill_level[lvl] = math.lerp(a,b,t)
			end
		end
	else
		-- if `config.level.enable == true`, set `level` to the table of modifiers, if `config.level.enable == false` then set `level = false`
		level = config.level.enable and config.level.modifiers
		skill_level = config.skill_level.enable and config.skill_level.modifiers
	end
	if config.log_level == 3 then 
		local strings
		local modifier
		if level then
			strings = {"level modifiers done:\n\t0 = " .. level[0]}
			for lvl=0, max_lvl do
				if interpolate then 
					modifier = level[lvl]
				else
					modifier = level[lvl - lvl %lvl_delta]
				end
				strings[#strings+1] = string.format("%i = %s", lvl, tostring(modifier))
			end
			log:trace(table.concat(strings, "\n\t"))
		else
			log:trace("level modifiers are disabled, they weren't generated.")
		end
		log:trace("--------------------------------")
		if skill_level then
			strings = {"skill_level modifiers done:\n\t0 = " .. skill_level[0]}
			for lvl=0, max_lvl do
				if interpolate then
					modifier = skill_level[lvl]
				else
					modifier = skill_level[lvl - lvl %lvl_delta]
				end
				strings[#strings+1] = string.format("%i = %s", lvl, tostring(modifier))
			end
			log:trace(table.concat(strings, "\n\t"))
		else
			log:trace("skill_level modifiers are disabled, they weren't generated.")
		end
	end
	-- if config.interpolate
	-- level = config.level.modifiers
	-- skill_level = config.skill_level.modifiers

	-- only register the event if something is enabled
	if global_scale_factor ~= 1 or skill or level or skill_level 
	or major_skill_modifier ~= 1 or minor_skill_modifier ~= 1 or misc_skill_modifier ~= 1 or specialization_modifier ~= 1 then
		log:debug("something is enabled, making sure the onSkillUse function is registered")
		if not event.isRegistered(tes3.event.exerciseSkill, update_xp) then
			event.register(tes3.event.exerciseSkill, update_xp)
			log:trace("\tevent was not registered. now it is.")
		else
			log:trace("\tevent was registered. it still is.")
		end
	else
		log:debug("nothing is enabled, making sure the exerciseSkill function isn't registered")
		if event.isRegistered(tes3.event.exerciseSkill, update_xp) then
			event.unregister(tes3.event.exerciseSkill, update_xp)
			log:trace("\tevent was registered. now it's not.")
		else
			log:trace("\tevent was not registered. it still isn't.")
		end
	end
end

mcm.update = update_variables



local function initialize()
	update_variables()
	log:info("Initialized.")
	if config.log_level > 1 then log:debug("using config: " .. json.encode(mcm.config)) end
	-- we're doing this on game load so the player reference is available
	event.register(tes3.event.loaded, update_class_skill_list)
	event.register(tes3.event.charGenFinished, update_class_skill_list)
	event.register(tes3.event.calcChargenStats, update_class_skill_list)
end

event.register(tes3.event.initialized, initialize)

event.register(tes3.event.modConfigReady, mcm.register)