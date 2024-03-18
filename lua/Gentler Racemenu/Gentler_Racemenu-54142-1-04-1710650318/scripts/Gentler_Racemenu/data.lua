
-- TOOLS
-----------------------------------------------------------------------------------------------------------

function DEBUG(...)
	if Mui.getSetting('GRM_DEBUG') then print(...) end
end

local function array_concat(array, ...)
  for _, t in ipairs({...}) do
    for _, v in ipairs(t) do table.insert(array, v) end
  end
  return array
end

-- COMPATIBILITY DATA
-----------------------------------------------------------------------------------------------------------

local Compat = {
  swapping_mods = false,
  MODULES = {},
  enabled = {},
  modules = {
    default = {
			content_files = {},
			dependencies = {},
			apply = function() end
		},
    new  = function(self, t)  end,
    edit = function(self, t)  end,
  },
	scripts = {}, -- array of scriptid
	spells = {}, -- array of spellid
	globals = {}, -- table of GLOBid -> val
}

-- COMPATIBILITY MODULES
-----------------------------------------------------------------------------------------------------------

--[] Set defaults for Compat.modules and setup metatable inheritance

Compat.modules.mt = {__index = Compat.modules.default}
setmetatable(Compat.modules, Compat.modules.mt)

function Compat.modules:new(t)
  if (t.name) then self[t.name] = {} else error('You can\'t create a nameless module!') end
  table.insert(Compat.MODULES, t.name)
  if t['dependencies']  then self[t.name]['dependencies']  = t['dependencies']  end
  if t['apply']         then self[t.name]['apply']         = t['apply']         end
  if t['content_files'] then self[t.name]['content_files'] = t['content_files']
    for _i, _filename in ipairs(t['content_files']) do
      self[t.name]['content_files'][_i] = string.lower(_filename)
    end
  end  -- set inheritance
  self[t.name].mt = {__index = self.default}
  setmetatable(self[t.name], self[t.name].mt)
end

-- COMPATIBILITY MODULE DEFINITIONS
-----------------------------------------------------------------------------------------------------------
Compat.modules:new{ name ='sensiblebirthsigns',
  content_files = {'SensibleBirthsigns.esp'},
  apply = function()
    array_concat(Compat.spells, {'_shadowKin'})
		array_concat(Compat.scripts, {'grm_compat_KI_birthsign_start'})
  end
}

Compat.modules:new{ name ='sensibleraces',
  content_files = {'SensibleRaces.esp'},
  apply = function()
    array_concat(Compat.spells, {'_racialArgonian_01', '_racialBosmer_01', '_racialImperial_01', '_racialKhajiit_01'})
		array_concat(Compat.scripts, {'grm_compat_KI_racialToggle_start'})
	end
}

Compat.modules:new{ name ='reincarnate',
  content_files = {'Reincarnate - Races of Morrowind.ESP'},
  apply = function()
    array_concat(Compat.spells, {'racial_argonian_ability_2_perk', 'racial_khajiit_ability_1_perk', 'racial_khajiit_ability_2_perk'})
		array_concat(Compat.scripts, {'grm_compat_racial_startup'})
	end
}

-- MOD DATA
-----------------------------------------------------------------------------------------------------------

local Dt = {
-- Player Data
  pc_attributes = {},
  pc_skills = {},
	pc_dynamic = {},
  pc_level = 0,
  pc_spells = {},
	pc_factions = {
		-- faction_id = {rank = 0, reputation = 0, expelled = bool}
	},
-- Compatibility and Engine Data
  RACES = {},
	PCRACE = {
		['argonian'] = 1,
		['breton'  ] = 2,
		['dark elf'] = 3,
		['high elf'] = 4,
		['imperial'] = 5,
		['khajiit' ] = 6,
		['nord'    ] = 7,
		['orc'     ] = 8,
		['redguard'] = 9,
		['wood elf'] = 10,
	},
  BIRTHSIGNS = {},
  ATTRIBUTES = {'strength', 'intelligence', 'willpower', 'agility', 'speed', 'endurance', 'personality', 'luck'},
  SKILLS = {
    'acrobatics' , 'alchemy'  , 'alteration' , 'armorer'   , 'athletics' , 'axe'       , 'block'    , 'bluntweapon', 'conjuration',
    'destruction', 'enchant'  , 'handtohand' , 'heavyarmor', 'illusion'  , 'lightarmor', 'longblade', 'marksman'   , 'mediumarmor',
    'mercantile' , 'mysticism', 'restoration', 'security'  , 'shortblade', 'sneak'     , 'spear'    , 'speechcraft', 'unarmored'
  },
  specialization = {
    COMBAT  = {'athletics' ,'block'   ,'longblade'  ,'bluntweapon','axe'       ,'spear'   ,'mediumarmor','heavyarmor' ,'armorer'},
    MAGIC   = {'alchemy'   ,'enchant' ,'conjuration','destruction','mysticism' ,'illusion','unarmored'  ,'alteration' ,'restoration'},
    STEALTH = {'lightarmor','marksman','sneak'      ,'handtohand' ,'shortblade','security','mercantile' ,'speechcraft','acrobatics'},
  },
  races = {
    default = {
      skills = {},
      attributes_male = {},
      attributes_female = {},
      spells = {},
      PCRace = 0
    },
    new  = function(self, t)  end,
    edit   = function(self, t)  end,
    delete = function(self, name) end,
  },
  birthsigns = { -- Created records follow the following pattern -> birthsigns = {name = {spells, spells2, ..etc}, name2 = {...}, ..etc}
    default = {},
    new  = function(self, t)  end,
  },
	known_spells = {
    -- VANILLA
    'resist disease_75', 'immune to poison', 'argonian breathing',
    'magicka mult bonus_5', 'resist magicka_50', 'dragon skin',
    'ancestor guardian', 'resist fire_75',
    'magicka mult bonus_15', 'weakness magicka_50', 'weakness fire_50', 'weakness frost_25', 'weakness shock_25', 'resist disease_75',
    'star of the west', 'voice of the emperor',
    'eye of night', 'eye of fear',
    'immune to frost', 'resist shock_50', 'woad', 'thunder fist',
    'resist magicka_25', 'orc_beserk',
    'resist disease_75', 'resist poison_75', 'adrenaline rush',
    'resist disease_75', 'beast tongue',
    -- REINCARNATE - RACES OF MORROWIND
    'racial_altmer_ability_1' ,'racial_altmer_ability_2' ,'racial_altmer_power',
    'racial_argonian_ability_1' ,'racial_argonian_ability_2_spell' ,'racial_argonian_power' ,'racial_argonian_ability_2_perk',
    'racial_bosmer_ability_1' ,'racial_bosmer_ability_2' ,'racial_bosmer_power',
    'racial_breton_ability_1' ,'racial_breton_ability_2' ,'racial_breton_power',
    'racial_dunmer_ability_1' ,'racial_dunmer_ability_2' ,'racial_dunmer_power',
    'racial_imperial_ability_1' ,'racial_imperial_ability_2' ,'racial_imperial_power',
    'racial_khajiit_ability_1_spell' ,'racial_khajiit_ability_2_spell' ,'racial_khajiit_ability_3', 'racial_khajiit_power', 'racial_khajiit_ability_1_perk', 'racial_khajiit_ability_2_perk',
    'racial_nord_ability_1' ,'racial_nord_ability_2' ,'racial_nord_power',
    'racial_orc_ability_1' ,'racial_orc_ability_2' ,'racial_orc_power',
    'racial_redguard_ability_1' ,'racial_redguard_ability_2' ,'racial_redguard_power',
    -- a'Ђьi"0pla, Ђьi || macro: append clipboard as list item
    -- o'Ђьi"0pla, Ђьi || macro: append clipboard as list item, in new line
  },
  EDITMODES = {
    'ChargenName',
    'ChargenClass',
    'ChargenClassGenerate',
    'ChargenClassPick',
    'ChargenClassCreate',
    'ChargenClassReview',
    'ChargenBirth',
    'ChargenRace',
  },
-- Internal Script Data
  last3uimodes = {},
  exit_check = false,
  exit_timer = 0,
}

-- RACE MANIPULATION
-----------------------------------------------------------------------------------------------------------

function Dt.races:new(t)
  if (t.name) then self[t.name] = {} else error('You can\'t create a nameless race!') end
  table.insert(Dt.RACES, t.name)
  if t.spells then self[t.name].spells = t.spells end
  vars = {'skills','attributes_male', 'attributes_female'}
  for _, _var in ipairs(vars) do
    self[t.name][_var] = t[_var]
  end
  table.insert(Dt.RACES, t.name)
end

function Dt.races:edit(t)
  if not t.name then error('You must create a race before editing it!') end
    if t.spells then self[t.name].spells = t.spells end
  vars = {'skills','attributes_male', 'attributes_female'}
  for _, _var in ipairs(vars) do
    if t[_var] then
      for _stat, _value in pairs(t[_var]) do
        if t[_var][_stat] then self[t.name][_var][_stat] = t[_var][_stat] end
      end
    end
  end
end

-- BIRTHSIGN MANIPULATION
-----------------------------------------------------------------------------------------------------------

function Dt.birthsigns:new(t)
  if (t.id) then
			self[t.id] = {}
		else
			error('You can\'t create a nameless birthsign!')
		end
  if t.spells then self[t.id] = t.spells end
  table.insert(Dt.BIRTHSIGNS, t.id)
end

-- RETURN || NEED THIS SO FILE DO THING
return {Dt = Dt, Compat = Compat}
