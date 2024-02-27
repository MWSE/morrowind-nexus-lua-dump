local core  = require('openmw.core')
local self  = require('openmw.self')
local types = require('openmw.types')

local Dt = require('scripts.gentler_racemenu.data').Data
local Compat = require('scripts.gentler_racemenu.data').Compat

-- TOOLS
local eps = 0.001
function equal(a,b)                         return (math.abs(b - a) < eps)                                  end
local function get_val(not_table_or_func)   return not_table_or_func                                        end
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
-- DEFINITIONS --
-----------------------------------------------------------------------------------------------------------
local Func = {
    get_birthsigns       = function() end, -- Dynamically populate Dt.birthsigns with all loaded birthsigns and their corresponding spell lists.

    is_entering          = function(oldmode, newmode) end, -- return editmode if entering, nil otherwise
    is_exiting           = function(oldmode, newmode) end, -- return editmode if exiting , nil otherwise

    get_abilitymodifiers = function(kind, stat) end, -- return ability_fortify_points for kind.stat, 0 if none.

    set_data_stats       = function() end,-- set all internal stats using the current gamestate
    set_openmw_stats     = function() end,-- set the player's stats using internal data
}
-----------------------------------------------------------------------------------------------------------

--[] Module Enabler: finds all compatible mods in load order and builds Compat.enabled accordingly
Func.enable_compat_modules = function()
    local to_enable = {}
    -- Loop over all available compatibility modules, see if they need enabling and add them to the list if their dependencies are met
    for _, _module in ipairs(Compat.MODULES) do
        local loaded = {}
        -- Loop over all of the module's content files, if we find any then mark module as loaded (using it's load order index) and break
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
    end
end

Func.get_birthsigns = function()
    local birthsigns = types.Player.birthSigns
    for _, _birthsign in ipairs(birthsigns.records) do
        Dt.birthsigns:new{
            id = _birthsign.id,
            spells = _birthsign.spells
        }
    end
end

Func.is_editmode = function(mode)
    for _,_editmode in ipairs(Dt.EDITMODES) do
        if _editmode == mode then return true end
    end
    return false
end
Func.is_switching = function()
    if Func.is_editmode(Dt.last3uimodes[3]) then return true end
end

Func.is_entering = function(newmode)
    if Func.is_switching() then return false end
    if Func.is_editmode(newmode) then return get_val(newmode) end
end

Func.is_exiting = function(oldmode, newmode)
    if newmode and newmode ~= 'Interface' then return false end
    if Func.is_editmode(oldmode) then return true end
end

Func.get_abilitymodifiers = function(kind, stat)
        local API_Spelltype_Ability = get_val(core.magic.SPELL_TYPE.Ability)
        local fortify = 0
        local getmodifier = function() end
        -- Create the appropriate 'getmodifier' check for the kind and stat being updated:
        if     kind == 'skills'     then
            getmodifier = function(_effect) if _effect.affectedSkill     == stat then fortify = fortify + _effect.magnitudeThisFrame end end
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

Func.set_data_stats = function()
    -- Get & Store current Birthsign, and it's related Spells.
    local birthsign = types.Player.getBirthSign(self)
    Dt.pc_birthsign.id = get_val(birthsign)
    Dt.pc_birthsign.spells = get_val(Dt.birthsigns[birthsign])
    -- Get & Store current Gender
    local gender = 'female'
    if types.Player.record(self).isMale then gender = 'male' end
    Dt.pc_gender = get_val(gender)
    -- Get & Store current Race, and it's related Spells.
    local race = get_val(types.Player.record(self).race)
    Dt.pc_race.id = get_val(race)
    Dt.pc_race.spells = get_val(Dt.races[race].spells)
    -- Store current Level
    Dt.pc_level = get_val(types.Player.stats.level(self).current)
    -- Store current stats, without counting any ability or racial modifiers.
    for _, _name in ipairs(Dt.ATTRIBUTES) do
        Dt.pc_attributes[_name] = get_val(
              types.Player.stats.attributes[_name](self).base
            - Dt.races[race]['attributes_'..gender][_name]
            - Func.get_abilitymodifiers('attributes',_name)
            )
    end
    for _, _name in ipairs(Dt.SKILLS) do
        Dt.pc_skills[_name] = get_val(
              types.Player.stats.skills[_name](self).base
            - Dt.races[race].skills[_name]
            - Func.get_abilitymodifiers('skills',_name)
            )
    end
    -- Take away current class stats
    local API_class = types.Player.classes.record(types.Player.record(self).class)
    Dt.pc_attributes[API_class.attributes[1]] = Dt.pc_attributes[API_class.attributes[1]] - 10
    Dt.pc_attributes[API_class.attributes[2]] = Dt.pc_attributes[API_class.attributes[2]] - 10
    for _, _skill in ipairs(API_class.majorSkills) do
        Dt.pc_skills[_skill] = Dt.pc_skills[_skill] - 25
    end
    for _, _skill in ipairs(API_class.minorSkills) do
        Dt.pc_skills[_skill] = Dt.pc_skills[_skill] - 10
    end
    for _, _skill in ipairs(Dt.specialization[string.upper(API_class.specialization)]) do
        Dt.pc_skills[_skill] = Dt.pc_skills[_skill] - 5
    end
    Dt.pc_spells = {}

    -- Store all player spells, to restore them after they are reset.
    for _, _spell in ipairs(types.Player.spells(self)) do -- Add all player spells
        Dt.pc_spells[_spell.id] = _spell.id
    end

    -- COMPAT for 'reincarnate' || Events for setting globals from Reincarnate toggle abilities, to make sure they're not left on by accident.
    if Compat.enabled['reincarnate'] and (race == 'argonian' or race == 'khajiit') then
        core.sendGlobalEvent('grm_setGlobals', {'toggle_argonian' , 0})
        core.sendGlobalEvent('grm_setGlobals', {'toggle_khajiit_1', 0})
        core.sendGlobalEvent('grm_setGlobals', {'toggle_khajiit_2', 0})
    end
end

Func.set_openmw_stats = function()
    -- Get current Race and Gender
    local gender = 'female'
    if types.Player.record(self).isMale then gender = 'male' end
    local race = get_val(types.Player.record(self).race)
    local newattributes = {}
    local newskills = {}
    -- Add current racial stats, take away old racial stats and add any ability modifiers.
    for _name, _attribute in pairs(Dt.pc_attributes) do
        newattributes[_name] =
              Dt.pc_attributes[_name]
            + Dt.races[race]['attributes_'..gender][_name]
            + Func.get_abilitymodifiers('attributes',_name)
    end
    for _name, _skill in pairs(Dt.pc_skills) do
        newskills[_name] =
              Dt.pc_skills[_name]
            + Dt.races[race].skills[_name]
            + Func.get_abilitymodifiers('skills',_name)
    end
    -- Add back current class stats
    local API_class = types.Player.classes.record(types.Player.record(self).class)
    newattributes[API_class.attributes[1]] = newattributes[API_class.attributes[1]] + 10
    newattributes[API_class.attributes[2]] = newattributes[API_class.attributes[2]] + 10
    for _, _skill in ipairs(API_class.majorSkills) do
        newskills[_skill] = newskills[_skill] + 25
    end
    for _, _skill in ipairs(API_class.minorSkills) do
        newskills[_skill] = newskills[_skill] + 10
    end
    for _, _skill in ipairs(Dt.specialization[string.upper(API_class.specialization)]) do
        newskills[_skill] = newskills[_skill] + 5
    end
    -- Set player Stats
    for _, _name in ipairs(Dt.ATTRIBUTES) do
        types.Player.stats.attributes[_name](self).base = get_val(newattributes[_name])
    end
    for _, _name in ipairs(Dt.SKILLS) do
        types.Player.stats.skills[_name](self).base = get_val(newskills[_name])
    end
    -- If player race changed, then don't add back the previous race's spells
    if race ~= Dt.pc_race.id then
        for _, _id in ipairs(Dt.pc_race.spells) do
            Dt.pc_spells[_id] = nil
        end
    else -- If it hasn't changed, force-add it's spells in case the engine forgot to do it.
        for _, _id in ipairs(Dt.pc_race.spells) do
            Dt.pc_spells[_id] = _id
        end
    end
    -- Get current Birthsign
    local birthsign = types.Player.getBirthSign(self)
    -- If player birthsign changed, then don't add the previous brithsign's spells
    if birthsign ~= Dt.pc_birthsign.id then
        for _, _id in ipairs(Dt.pc_birthsign.spells) do
            Dt.pc_spells[_id] = nil
        end
    else -- If it hasn't changed, force-add it's spells in case the engine forgot to do it.
        for _, _id in ipairs(Dt.pc_birthsign.spells) do
            Dt.pc_spells[_id] = _id
        end
    end
    -- Set player Spells
    for _spellid, _spell in pairs(Dt.pc_spells) do
        types.Player.spells(self):add(_spellid)
    end
    types.Player.stats.level(self).current = get_val(Dt.pc_level)
    -- Send event to set PCRace (to keep the correct dialogue reactivity)
    core.sendGlobalEvent('grm_setGlobals', {'PCRace', Dt.races[race].PCRace})

    -- COMPAT for 'reincarnate' || Slap Reincarnate's startup script awake so it makes racial toggle spells work.
    if Compat.enabled['reincarnate'] and (race == 'argonian' or race == 'khajiit') then
        core.sendGlobalEvent('grm_setGlobals', {'grm_compat_reincarnate_start_RacialStartup', 1})
    elseif Compat.enabled['sensiblebirthsigns'] then
        core.sendGlobalEvent('grm_setGlobals', {'grm_compat_sensibleBirthsigns_start_KI_birthsign_start', 1})
    end
end

-- RETURN || NEED THIS SO FILE DO THING
return Func
