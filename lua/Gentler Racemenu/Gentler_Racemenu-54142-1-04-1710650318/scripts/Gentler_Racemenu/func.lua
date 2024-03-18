local core  = require('openmw.core')
local self  = require('openmw.self')
local types = require('openmw.types')

local Dt     = require('scripts.gentler_racemenu.data').Dt
local Compat = require('scripts.gentler_racemenu.data').Compat
local Mui    = require('scripts.gentler_racemenu.modui')

-- TOOLS
local eps = 0.001
function equal(a,b) return (math.abs(b - a) < eps) end
local function get_val(not_table_or_func) return not_table_or_func end
local function table_find(table, thing)
  if type(thing) == 'number' then
    for k, v in pairs(table) do
      if equal(v, thing) then return thing end
    end
  else
    for k, v in pairs(table) do
      if v == thing then return thing end
    end
  end
end

function DEBUG(...)
	if Mui.getSetting('GRM_DEBUG') then print(...) end
end
function FILL(n, str) return string.rep(' ', math.max(0, n - #str)) end
function STAT_Accounted(increase, fromrace, fromability)
	local message = ''
	local show = {}
	if fromrace    ~= 0 then table.insert(show, tostring(fromrace)..' from race stats') end
	if fromability ~= 0 then table.insert(show, tostring(fromability)..' from magic abilities') end
	if #show > 0 then
		if increase == '+' then message = 'Restored ' else message = 'Removed ' end
		message = message..table.concat(show, ', and ')..'.'
	end
	return message
end
function DEBUG_TOTALSTATS()
	local attr = 0
	local skill = 0
	for _, id in ipairs(Dt.ATTRIBUTES) do
		attr = attr + types.NPC.stats.attributes[id](self).base
	end
	for _, id in ipairs(Dt.SKILLS) do
		skill = skill + types.NPC.stats.skills[id](self).base
	end
	DEBUG('Total Attribute points: '..tostring(attr)..' | Total Skill Points: '..tostring(skill))
end

function toTable(userdata)
	t = {}
	for k, v in pairs(userdata) do
		t[k] = v
	end
	return t
end

-- DEFINITIONS --
-----------------------------------------------------------------------------------------------------------
local Fn = {
  get_birthsigns     = function() end, -- Dynamically populate Dt.birthsigns with all loaded birthsigns and their corresponding spell lists.

  is_entering      = function(oldmode, newmode) end, -- return editmode if entering, nil otherwise
  is_exiting       = function(oldmode, newmode) end, -- return editmode if exiting , nil otherwise

  get_abilitymodifiers = function(kind, stat) end, -- return ability_fortify_points for kind.stat, 0 if none.

  set_data_stats     = function() end,-- set all internal stats using the current gamestate
  set_openmw_stats   = function() end,-- set the player's stats using internal data
}
-----------------------------------------------------------------------------------------------------------

--[] Module Enabler: finds all compatible mods in load order and builds Compat.enabled accordingly
Fn.enable_compat_modules = function()
  local to_enable = {}
  -- Loop over all available compatibility modules, see if they need enabling and add them to the list if their dependencies are met
  for _, _module in ipairs(Compat.MODULES) do
    local loaded = {}
    -- Loop over all of the module's content files, if we find any then mark module as loaded and break
    for _, _content_file in ipairs (Compat.modules[_module].content_files) do
      if core.contentFiles.has(_content_file) then table.insert(loaded, _module) break end
    end
    -- loop over all loaded modules (since they were indexed by load order this also follows said order) and make sure all their dependencies are fulfilled.
    for _index, _ in ipairs(loaded) do
      dependencies_fulfilled = true
      for _, _dependency in ipairs(Compat.modules[_module].dependencies) do
        if not table_find(to_enable, _dependency) then dependencies_fulfilled = false print('GRM - Missing module dependency.. '.._module) break end
      end
      if dependencies_fulfilled then table.insert(to_enable, _module) end
    end
  end
  -- Enable all modules that need enabling, and add them to the enabled list for further use.
  for _, _module in ipairs(to_enable) do
    Compat.modules[_module].apply()
    Compat.enabled[_module] = true
		DEBUG('Compatibility Module Enabled:', _module)
  end
end

Fn.applyMWBolt = function(mwbolt)
  local equipment = types.Actor.getEquipment(self)
  local pcammo = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.Ammunition)
  equipment[types.Actor.EQUIPMENT_SLOT.Ammunition] = mwbolt
  types.Actor.setEquipment(self, equipment)
  equipment[types.Actor.EQUIPMENT_SLOT.Ammunition] = pcammo
  types.Actor.setEquipment(self, equipment)
  DEBUG('MWBolt applied.')
  core.sendGlobalEvent('grm_removeItem', {source = self, item = mwbolt, count = 1})
end

Fn.get_birthsigns = function()
  for _, _birthsign in ipairs(types.Player.birthSigns.records) do
    Dt.birthsigns:new{
      id = _birthsign.id,
      spells = _birthsign.spells
    }
		DEBUG('Birthsign loaded:', _birthsign.name)
  end
end
Fn.get_races = function()
  for _, race in ipairs(types.NPC.races.records) do
  	if not race.isPlayable then return end
  	local attr_male = {}
  	local attr_female = {}
  	for id, _ in pairs(race.attributes) do
  		attr_male[id]   = race.attributes[id].male
  	  attr_female[id] = race.attributes[id].female
  	end
		local skills_with_0s = race.skills
		for _, id in ipairs(Dt.SKILLS) do
			if not skills_with_0s[id] then skills_with_0s[id] = 0 end
    end
	  Dt.races:new{
  		name   = race.id,
      spells = race.spells,
  		skills = skills_with_0s,
      attributes_male   = attr_male,
  		attributes_female = attr_female,
  	}
		do local spells = {}
			for _, id in ipairs(race.spells) do table.insert(spells, core.magic.spells[id].name) end
			DEBUG('Race Loaded: '..race.name..FILL(8, race.name)..' | Spells: ['..table.concat(spells, ', ')..']')
		end
  end
end

Fn.is_editmode = function(mode)
  for _,_editmode in ipairs(Dt.EDITMODES) do
    if _editmode == mode then return true end
  end
  return false
end
Fn.is_switching = function()
  if Fn.is_editmode(Dt.last3uimodes[3]) then return true end
end

Fn.is_entering = function(newmode)
  if Fn.is_switching() then return false end
  if Fn.is_editmode(newmode) then return get_val(newmode) end
end

Fn.is_exiting = function(oldmode, newmode)
  if newmode and newmode ~= 'Interface' then return false end
  if Fn.is_editmode(oldmode) then return true end
end

Fn.get_abilitymodifiers = function(kind, stat)
    local API_Spelltype_Ability = get_val(core.magic.SPELL_TYPE.Ability)
    local fortify = 0
    local getmodifier = function() end
    -- Create the appropriate 'getmodifier' check for the kind and stat being updated:
    if   kind == 'skills'   then
      getmodifier = function(_effect) if _effect.affectedSkill   == stat then fortify = fortify + _effect.magnitudeThisFrame end end
    elseif kind == 'attributes' then
      getmodifier = function(_effect) if _effect.affectedAttribute == stat then fortify = fortify + _effect.magnitudeThisFrame end end
    end
    for _id, _params in pairs(types.Actor.activeSpells(self)) do
      if core.magic.spells[_params.id] then -- we only wanna check SPELL types, since abilities never come from enchantments
        local spell_type = get_val(core.magic.spells[_params.id].type)
        if equal(spell_type, API_Spelltype_Ability) then -- if it's not an ability, then we don't care about it
          for _, _effect in pairs(_params.effects) do
            getmodifier(_effect) -- Check if the effect affects [kind.stat] and if it does then add it's magnitude to fortify
          end
        end
      end
    end
    return fortify
end

Fn.set_data_stats = function(mode)

  local gender = 'female'
  if types.NPC.record(self).isMale then gender = 'male' end

  local race = types.NPC.record(self).race
	DEBUG('Race:', types.NPC.races.record(race).name, '| Spells:', Dt.races[race].spells)

  Dt.pc_level = get_val(types.Player.stats.level(self).current)
	DEBUG('Saved Level:', level)

	for _, factionid in ipairs(types.NPC.getFactions(self)) do
		Dt.pc_factions[factionid] = {
		  rank = types.NPC.getFactionRank(self, factionid),
		  reputation = types.NPC.getFactionReputation(self, factionid),
			expelled = types.NPC.isExpelled(self, factionid),
		}
	  DEBUG('Saved Faction Status:', factionid, '| Rank:', Dt.pc_factions[factionid].rank, '| Reputation:', Dt.pc_factions[factionid].reputation, '| Expelled?', Dt.pc_factions[factionid].expelled)
	end

	if not Mui.getSetting('Keep_Stats_Unchanged') then
    DEBUG('Saving ATTRIBUTES...')
	  for _, _name in ipairs(Dt.ATTRIBUTES) do
	  	local base    = types.Player.stats.attributes[_name](self).base
	  	local race    = Dt.races[race]['attributes_'..gender][_name]
	  	local ability = Fn.get_abilitymodifiers('attributes',_name)
      Dt.pc_attributes[_name] = base - race - ability
	  	DEBUG(_name..FILL(12, _name)..': '..base - race - ability..' || '..STAT_Accounted('-', race, ability))
    end
    DEBUG('Saving SKILLS...')
    for _, _name in ipairs(Dt.SKILLS) do
      local base    = types.Player.stats.skills[_name](self).base
      local race    = Dt.races[race].skills[_name]
      local ability = Fn.get_abilitymodifiers('skills',_name)
      Dt.pc_skills[_name] = base - race - ability
	  	DEBUG(_name..FILL(12, _name)..': '..base - race - ability..' || '..STAT_Accounted('-', race, ability))
    end
    DEBUG('Removing Class Bonuses...')
    local API_class = types.Player.classes.record(types.Player.record(self).class)
    Dt.pc_attributes[API_class.attributes[1]] = Dt.pc_attributes[API_class.attributes[1]] - 10
    Dt.pc_attributes[API_class.attributes[2]] = Dt.pc_attributes[API_class.attributes[2]] - 10
    DEBUG('Favoured Attributes reduced by 10: ['..API_class.attributes[1]..', '..API_class.attributes[2]..']')
    for _i, _skill in ipairs(API_class.majorSkills) do
      Dt.pc_skills[_skill] = Dt.pc_skills[_skill] - 25
    end
	  DEBUG('Major skills reduced by 25: ['..table.concat(toTable(API_class.majorSkills), ', ')..']')
    for _, _skill in ipairs(API_class.minorSkills) do
      Dt.pc_skills[_skill] = Dt.pc_skills[_skill] - 10
    end
	  DEBUG('Minor skills reduced by 10: ['..table.concat(toTable(API_class.minorSkills), ', ')..']')
    for _, _skill in ipairs(Dt.specialization[string.upper(API_class.specialization)]) do
      Dt.pc_skills[_skill] = Dt.pc_skills[_skill] - 5
    end
	  DEBUG(string.upper(API_class.specialization)..' skills reduced by 5: ['..table.concat(Dt.specialization[string.upper(API_class.specialization)], ', ')..']')
	else
    DEBUG('Saving ATTRIBUTES...')
	  for _, _name in ipairs(Dt.ATTRIBUTES) do
	  	local base    = types.Player.stats.attributes[_name](self).base
	  	local ability = Fn.get_abilitymodifiers('attributes',_name)
      Dt.pc_attributes[_name] = base - ability
	  	DEBUG(_name..FILL(12, _name)..': '..base - ability..' || '..STAT_Accounted('-', 0, ability))
    end
    DEBUG('Saving SKILLS...')
    for _, _name in ipairs(Dt.SKILLS) do
      local base    = types.Player.stats.skills[_name](self).base
      local ability = Fn.get_abilitymodifiers('skills',_name)
      Dt.pc_skills[_name] = base - ability
	  	DEBUG(_name..FILL(12, _name)..': '..base - ability..' || '..STAT_Accounted('-', 0, ability))
    end

	end

	local str_factor = types.NPC.stats.attributes.strength(self).base * 0.5
	local end_factor = types.NPC.stats.attributes.endurance(self).base * 0.5
	Dt.pc_dynamic.health = types.Actor.stats.dynamic.health(self).base - end_factor - str_factor - Fn.get_abilitymodifiers('fortifyhealth')
	DEBUG('Storing HP: '..string.format("%.1f", tostring(Dt.pc_dynamic.health))..' | Removed '..tostring(str_factor)..' from STR and '..tostring(end_factor)..' from END')
  if Mui.getSetting('Force_Dynamic_Stats') then
	  DEBUG('Saving Dynamic Stats...')
    local xint = types.Actor.stats.attributes.intelligence(self).modified * Fn.get_abilitymodifiers('fortifymaximummagicka')
		Dt.pc_dynamic.magicka = - xint
		for _, stat in ipairs{'health', 'magicka', 'fatigue'} do
			Dt.pc_dynamic[stat] = types.Actor.stats.dynamic[stat](self).base - Fn.get_abilitymodifiers('fortify'..stat)
		end
	  DEBUG('Storing HP: '..string.format("%.1f", tostring(Dt.pc_dynamic.health)))
	  DEBUG('Storing MP: '..string.format("%.1f", tostring(Dt.pc_dynamic.magicka)))
		DEBUG('Storing FP: '..string.format("%.1f", tostring(Dt.pc_dynamic.fatigue)))
	end

  Dt.pc_spells = {}
  for _, _spell in ipairs(types.Player.spells(self)) do -- Add all player spells
    Dt.pc_spells[_spell.id] = _spell.id
  end
  local birthsign = types.Player.birthSigns.record(types.Player.getBirthSign(self))
	if birthsign then
    for _, _id in ipairs(Dt.birthsigns[birthsign.id]) do
      Dt.pc_spells[_id] = nil
    end
  	do local spells = {}
  	  for _, id in ipairs(Dt.birthsigns[birthsign.id]) do table.insert(spells, core.magic.spells[id].name) end
    	DEBUG('Removing Birthsign Spells: '..birthsign.name..' | Spells: ['..table.concat(spells, ', ')..']')
    end
	end
  for _, _id in ipairs(Dt.races[race].spells) do
    Dt.pc_spells[_id] = nil
  end
	do local spells = {}
	  for _, id in ipairs(Dt.races[race].spells) do table.insert(spells, core.magic.spells[id].name) end
  	DEBUG('Removing Racial Spells: '..types.NPC.races.record(race).name..' | Spells: ['..table.concat(spells, ', ')..']')
  end
  for _, _id in ipairs(Compat.spells) do
    Dt.pc_spells[_id] = nil
  end
	do local spells = {}
	  for _, id in ipairs(Compat.spells) do table.insert(spells, core.magic.spells[id].name) end
  	DEBUG('Removing Scripted Race/Birthsign Spells: ['..table.concat(spells, ', ')..']')
  end
	if Mui.getSetting('Purge_Spells') then
		for _, spellid in ipairs(Dt.known_spells) do
			Dt.pc_spells[spellid] = nil
		end
		DEBUG('Purging all known race and birthsign spells from player list...')
	end
	do local spells = {}
	  for _, id in pairs(Dt.pc_spells) do table.insert(spells, core.magic.spells[id].name) end
  	DEBUG('Saved Player Spells: ['..table.concat(spells, ', ')..']')
  end

  for _, _spell in ipairs(types.Player.spells(self)) do
    types.Player.spells(self):remove(_spell.id)
  end
	DEBUG('Clearing Player Spells... done.')

end

Fn.set_openmw_stats = function()
  local gender = 'female'
  if types.Player.record(self).isMale then gender = 'male' end
  local race = types.NPC.record(self).race
  local newattributes = {}
  local newskills = {}
	for factionid, faction in pairs(Dt.pc_factions) do
		types.NPC.setFactionRank(self, factionid, faction.rank)
		types.NPC.setFactionReputation(self, factionid, faction.reputation)
	  DEBUG('Restored Faction Status:', factionid, '| Rank:', faction.rank, '| Reputation:', faction.reputation, '| Expelled?', faction.expelled)
	end
	if not Mui.getSetting('Keep_Stats_Unchanged') then
		DEBUG('Restoring ATTRIBUTES...')
    for _name, _attribute in pairs(Dt.pc_attributes) do
	  	local base    = Dt.pc_attributes[_name]
			local race    = Dt.races[race]['attributes_'..gender][_name]
			local ability = Fn.get_abilitymodifiers('attributes',_name)
      newattributes[_name] = base + race + ability
	  	DEBUG(_name..FILL(12, _name)..': '..base + race + ability..' || '..STAT_Accounted('+', race, ability))
    end
		DEBUG('Restoring SKILLS...')
    for _name, _skill in pairs(Dt.pc_skills) do
	  	local base    = Dt.pc_skills[_name]
			local race    = Dt.races[race].skills[_name]
			local ability = Fn.get_abilitymodifiers('skills',_name)
      newskills[_name] = base + race + ability
	  	DEBUG(_name..FILL(12, _name)..': '..base + race + ability..' || '..STAT_Accounted('+', race, ability))
		end
		DEBUG('Restoring Class Bonuses...')
    local API_class = types.Player.classes.record(types.Player.record(self).class)
    newattributes[API_class.attributes[1]] = newattributes[API_class.attributes[1]] + 10
    newattributes[API_class.attributes[2]] = newattributes[API_class.attributes[2]] + 10
    DEBUG('Favoured Attributes increased by 10: ['..API_class.attributes[1]..', '..API_class.attributes[2]..']')
    for _, _skill in ipairs(API_class.majorSkills) do
      newskills[_skill] = newskills[_skill] + 25
    end
	  DEBUG('Major skills increased by 25: ['..table.concat(toTable(API_class.majorSkills), ', ')..']')
    for _, _skill in ipairs(API_class.minorSkills) do
      newskills[_skill] = newskills[_skill] + 10
    end
	  DEBUG('Minor skills increased by 10: ['..table.concat(toTable(API_class.minorSkills), ', ')..']')
    for _, _skill in ipairs(Dt.specialization[string.upper(API_class.specialization)]) do
      newskills[_skill] = newskills[_skill] + 5
    end
	  DEBUG(string.upper(API_class.specialization)..' skills increased by 5: ['..table.concat(Dt.specialization[string.upper(API_class.specialization)], ', ')..']')
	else
		DEBUG('Restoring ATTRIBUTES...')
    for _name, _val in pairs(Dt.pc_attributes) do
			local ability = Fn.get_abilitymodifiers('attributes',_name)
      newattributes[_name] = _val + ability
	  	DEBUG(_name..FILL(12, _name)..': '..tostring(_val)..' || '..STAT_Accounted('+', 0, ability))
    end
		DEBUG('Restoring SKILLS...')
    for _name, _val in pairs(Dt.pc_skills) do
			local ability = Fn.get_abilitymodifiers('skills',_name)
      newskills[_name] = _val + ability
	  	DEBUG(_name..FILL(12, _name)..': '..tostring(_val)..' || '..STAT_Accounted('+', 0, ability))
    end
	end

	DEBUG('Applying ATTRIBUTES... done.')
  for _, _name in ipairs(Dt.ATTRIBUTES) do
    types.Player.stats.attributes[_name](self).base = get_val(newattributes[_name])
  end
	DEBUG('Applying SKILLS... done.')
  for _, _name in ipairs(Dt.SKILLS) do
    types.Player.stats.skills[_name](self).base = get_val(newskills[_name])
  end

	local str_factor = types.NPC.stats.attributes.strength(self).base * 0.5
	local end_factor = types.NPC.stats.attributes.endurance(self).base * 0.5
	types.Player.stats.dynamic.health(self).base = Dt.pc_dynamic.health + end_factor + str_factor + Fn.get_abilitymodifiers('fortifyhealth')
  types.Player.stats.dynamic.health(self).current = types.Player.stats.dynamic.health(self).base
	DEBUG('Setting HP: '..string.format("%.1f", tostring(Dt.pc_dynamic.health))..' | Restored '..tostring(str_factor)..' from STR and '..tostring(end_factor)..' from END')
  if Mui.getSetting('Force_Dynamic_Stats') then
	  DEBUG('Restoring Dynamic Stats...')
		for _, stat in ipairs{'health', 'magicka', 'fatigue'} do
      types.Player.stats.dynamic[stat](self).base = get_val(Dt.pc_dynamic[stat])
      types.Player.stats.dynamic[stat](self).current = get_val(Dt.pc_dynamic[stat])
		end
	  DEBUG('Setting HP: '..string.format("%.1f", tostring(Dt.pc_dynamic.health)))
	  DEBUG('Setting MP: '..string.format("%.1f", tostring(Dt.pc_dynamic.magicka)))
		DEBUG('Setting FP: '..string.format("%.1f", tostring(Dt.pc_dynamic.fatigue)))
	end


	do local spells = {}
	  for _, id in pairs(Dt.pc_spells) do table.insert(spells, core.magic.spells[id].name) end
  	DEBUG('Saved Player Spells: ['..table.concat(spells, ', ')..']')
  end

  for _, _id in ipairs(types.NPC.races.record(race).spells) do
    Dt.pc_spells[_id] = _id
  end
	do local spells = {}
	  for _, id in ipairs(types.NPC.races.record(race).spells) do table.insert(spells, core.magic.spells[id].name) end
  	DEBUG('New Race: '..types.NPC.races.record(race).name..' | Spells: ['..table.concat(spells, ', ')..']')
  end
  local birthsign = types.Player.birthSigns.record(types.Player.getBirthSign(self))
	if birthsign then
    for _, _id in ipairs(birthsign.spells) do
      Dt.pc_spells[_id] = _id
    end
    do local spells = {}
      for _, id in ipairs(Dt.birthsigns[birthsign.id]) do table.insert(spells, core.magic.spells[id].name) end
    	DEBUG('New Birthsign: '..birthsign.name..' | Spells: ['..table.concat(spells, ', ')..']')
    end
  end
  for _spellid, _spell in pairs(Dt.pc_spells) do
    types.Player.spells(self):add(_spellid)
  end
	DEBUG('Applying Player Spells... done.')
	
  types.Player.stats.level(self).current = get_val(Dt.pc_level)
	DEBUG('Restoring level:', Dt.pc_level)

	if Dt.PCRACE[race] then
    core.sendGlobalEvent('grm_setGlobals', {name = 'PCRace', value = Dt.PCRACE[race]})
	  DEBUG('Race-based dialogue set to [ '..race..' ]')
	end

	if Compat.scripts ~= {} then
  	for _, scriptid in ipairs(Compat.scripts) do
  	  core.sendGlobalEvent('grm_setGlobals', {name = scriptid, value = 1})
  		DEBUG('Starting MWScript: '..scriptid)
  	end
  	core.sendGlobalEvent('grm_addItem', {id = 'grm_mwbolt', source = self.object, count = 1})
	end

	if Mui.getSetting('Respect_Caps') then
		local lost_attributes = 0
		local lost_skills = 0
	  for _, _name in ipairs(Dt.ATTRIBUTES) do
			if types.Player.stats.attributes[_name](self).base > 100 then
        lost_attributes = lost_attributes + types.Player.stats.attributes[_name](self).base - 100
        types.Player.stats.attributes[_name](self).base = 100
			end
		end
    for _, _name in ipairs(Dt.SKILLS) do
			if types.Player.stats.skills[_name](self).base > 100 then
        lost_skills = lost_skills + types.Player.stats.skills[_name](self).base - 100
        types.Player.stats.skills[_name](self).base = 100
			end
		end
		DEBUG('STAT CAP - LOST ATTRIBUTES: '..tostring(lost_attributes))
		DEBUG('STAT CAP - LOST SKILLS: '..tostring(lost_skills))
	end
	
  DEBUG_TOTALSTATS()

	if Mui.getSetting('Migration_Mode') then
	 	Mui.setSetting('Migration_Mode', false)
	  Mui.savePreset('current')
	end
end

-- RETURN || NEED THIS SO FILE DO THING
return Fn
