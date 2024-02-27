
local Compat = {
    swapping_mods = false,
    MODULES = {},
    enabled = {},
    modules = {
        default = {content_files = {}, dependencies = {}, apply = function() end},
        new    = function(self, t)    end,
        edit   = function(self, t)    end,
    }
-----------------------------------------------------------------------------------------------------------
}



local Data = {
-- Player Data
    pc_attributes = {},
    pc_skills = {},
    pc_level = 0,
    pc_race = {id = '', spells = {}},
    pc_gender = '',
    pc_birthsign = {id = '', spells = {}},
    pc_spells = {},
-- Compatibility and Engine Data
    RACES = {},
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
        new    = function(self, t)    end,
        edit   = function(self, t)    end,
        delete = function(self, name) end,
    },
    birthsigns = { -- Created records follow the following pattern -> birthsigns = {name = {spells, spells2, ..etc}, name2 = {...}, ..etc}
        default = {},
        new    = function(self, t)    end,
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

--[] Set defaults for Data.races and setup metatable inheritance

Data.races.mt = {__index = Data.races.default}
setmetatable(Data.races, Data.races.mt)
-- Set all skill values to 0, since these are bonuses
for _, _var in ipairs(Data.SKILLS) do
    Data.races.default.skills[_var] = 0
end
-- Set all attribute values to 40, since these are flat and 40 is the baseline amount.
for _, _var in ipairs(Data.ATTRIBUTES) do
    Data.races.default.attributes_female[_var] = 40
    Data.races.default.attributes_male[_var] = 40
end

--[] Race creator: race tables contain only their special values, and inherit all others from race.default

function Data.races:new(t)
    if (t.name) then self[t.name] = {} else error('You can\'t create a nameless race!') end
    -- set racial enum
    table.insert(Data.RACES, t.name)
    -- set non-default racial values, if any
    vars = {'spells', 'PCRace'}
    for _, _var in ipairs(vars) do
        if t[_var] then self[t.name][_var] = t[_var] end
    end
    vars = {'skills','attributes_male', 'attributes_female'}
    for _, _var in ipairs(vars) do
        if t[_var] then
            self[t.name][_var] = t[_var]
            self[t.name][_var].mt = {__index = self.default[_var]}
            setmetatable(self[t.name][_var], self[t.name][_var].mt)
        end
    end
    -- add to RACES enum
    table.insert(Data.RACES, t.name)
    -- set inheritance
    self[t.name].mt = {__index = self.default}
    setmetatable(self[t.name], self[t.name].mt)
end

--[] Race editor: replace the spell list or individual attributes/skills without affecting the rest of the race data.

function Data.races:edit(t)
    if not t.name then error('You must create a race before editing it!') end
    vars = {'spells', 'PCRace'}
    for _, _var in ipairs(vars) do
        -- Note 'spells' is wholly replaced, not merged
        -- In other words, you're providing the entire spells list, like in :new()
        if t[_var] then self[t.name][_var] = t[_var] end
    end
    vars = {'skills','attributes_male', 'attributes_female'}
    for _, _var in ipairs(vars) do
        if t[_var] then -- if we find skills/attributes, we look into that table to for the specific stats:
            for _stat, _value in pairs(t[_var]) do
                -- Note all pre-existing values are kept unless directly changed/deleted.
                -- In other words, you're providing the *differences* between the old stats table and the new one.
                if t[_var][_stat] then self[t.name][_var][_stat] = t[_var][_stat] end
            end
        end
    end
end

--[] Race deleter: about as gentle as it looks.

function Data.races:delete(name)
    self[name] = nil
end

-- BIRTHSIGN MANIPULATION
-----------------------------------------------------------------------------------------------------------

--[] Set defaults for Data.birthsigns and setup metatable inheritance

Data.birthsigns.mt = {__index = Data.birthsigns.default}
setmetatable(Data.birthsigns, Data.birthsigns.mt)

--[] Birthsign creator: birthsigns are indexed by record id and added automagically on load.

function Data.birthsigns:new(t)
    if (t.id) then self[t.id] = {} else error('You can\'t create a nameless birthsign!') end
    -- set non-default birthsign values, if any
    if t.spells then self[t.id] = t.spells end
    -- add to BIRTHSIGNS enum
    table.insert(Data.BIRTHSIGNS, t.id)
    -- set inheritance
    self[t.id].mt = {__index = self.default}
    setmetatable(self[t.id], self[t.id].mt)
end

-- COMPATIBILITY MODULES
-----------------------------------------------------------------------------------------------------------

--[] Set defaults for Compat.modules and setup metatable inheritance

Compat.modules.mt = {__index = Compat.modules.default}
setmetatable(Compat.modules, Compat.modules.mt)

--[] Module creator:

function Compat.modules:new(t)
    if (t.name) then self[t.name] = {} else error('You can\'t create a nameless module!') end
    -- add to ENUM
    table.insert(Compat.MODULES, t.name)
    -- set non-default values, if any
    vars = {'', 'dependencies', 'apply'}
    if t['dependencies']    then self[t.name]['dependencies']    = t['dependencies']    end
    if t['apply']         then self[t.name]['apply']         = t['apply']         end
    if t['content_files'] then self[t.name]['content_files'] = t['content_files']
        for _i, _filename in ipairs(t['content_files']) do
            self[t.name]['content_files'][_i] = string.lower(_filename)
        end
    end    -- set inheritance
    self[t.name].mt = {__index = self.default}
    setmetatable(self[t.name], self[t.name].mt)
end

-- COMPATIBILITY MODULE DEFINITIONS
-----------------------------------------------------------------------------------------------------------

-- "Compatibility" for vanilla races
Compat.modules:new{ name ='vanilla_races',
    content_files = {'morrowind.esm', 'bloodmoon.esm', 'tribunal.esm'},
    apply = function()
        Data.races:new{ name = 'argonian',
            PCRace = 1,
            attributes_male   = {endurance = 30, personality = 30, willpower = 30, agility = 50, speed = 50},
            attributes_female = {endurance = 30, personality = 30, intelligence = 50},
            skills = {alchemy = 5, athletics = 15, illusion = 5, mediumarmor = 5, mysticism = 5, spear = 5, unarmored = 5},
            spells = {'resist disease_75', 'immune to poison', 'argonian breathing'},
        }
        Data.races:new{ name = 'breton',
            PCRace = 2,
            attributes_male   = {intelligence = 50, willpower = 50, agility = 30, endurance = 30, speed = 30},
            attributes_female = {intelligence = 50, willpower = 50, agility = 30, endurance = 30, strength = 30},
            skills = {conjuration = 10, mysticism = 10, restoration = 10, alchemy = 5, alteration = 5, illusion = 5},
            spells = {'magicka mult bonus_5', 'resist magicka_50', 'dragon skin'},
        }
        Data.races:new{ name = 'dark elf',
            PCRace = 3,
            attributes_male   = {willpower = 30, speed = 50, personality = 30},
            attributes_female = {willpower = 30, speed = 50, endurance = 30},
            skills = {longblade = 5, destruction = 10, lightarmor = 5, athletics = 5, mysticism = 5, marksman = 5, shortblade = 10},
            spells = {'ancestor guardian', 'resist fire_75'},
        }
        Data.races:new{ name = 'high elf',
            PCRace = 4,
            attributes_male   = {strength = 30, intelligence = 50, speed = 30},
            attributes_female = {strength = 30, intelligence = 50, endurance = 30},
            skills = {destruction = 10, enchant = 10, alchemy = 10, alteration = 5, conjuration = 5, illusion = 5},
            spells = {'magicka mult bonus_15', 'weakness magicka_50', 'weakness fire_50', 'weakness frost_25', 'weakness shock_25', 'resist disease_75'},
        }
        Data.races:new{ name = 'imperial',
            PCRace = 5,
            attributes_male   = {agility = 30, personality = 50, willpower = 30},
            attributes_female = {agility = 30, personality = 50, speed = 30},
            skills = {speechcraft = 10, mercantile = 10, longblade = 10, bluntweapon = 5, lightarmor = 5, handtohand = 5},
            spells = {'star of the west', 'voice of the emperor'},
        }
        Data.races:new{ name = 'khajiit',
            PCRace = 6,
            attributes_male   = {willpower = 30, agility = 50, endurance = 30},
            attributes_female = {willpower = 30, agility = 50, strength = 30},
            skills = {acrobatics = 15, athletics = 5, handtohand = 5, lightarmor = 5, security = 5, shortblade = 5, sneak = 5},
            spells = {'eye of night', 'eye of fear'},
        }
        Data.races:new{ name = 'nord',
            PCRace = 7,
            attributes_male   = {strength = 50, intelligence = 30, agility = 30, personality = 30, endurance = 50},
            attributes_female = {strength = 50, intelligence = 30, agility = 30, personality = 30, willpower = 50},
            skills = {axe = 10, bluntweapon = 10, mediumarmor = 10, heavyarmor = 5, longblade = 5, spear = 5},
            spells = {'immune to frost', 'resist shock_50', 'woad', 'thunder fist'},
        }
        Data.races:new{ name = 'orc',
            PCRace = 8,
            attributes_male   = {strength = 45, agility = 35, speed = 30, endurance = 50, willpower = 50, personality = 30, intelligence = 30},
            attributes_female = {strength = 45, agility = 35, speed = 30, endurance = 50, willpower = 45, personality = 25},
            skills = {armorer = 10, block = 10, heavyarmor = 10, mediumarmor = 10, axe = 5},
            spells = {'resist magicka_25', 'orc_beserk'},
        }
        Data.races:new{ name = 'redguard',
            PCRace = 9,
            attributes_male   = {intelligence = 30, willpower = 30, endurance = 50, strength = 50, personality = 30},
            attributes_female = {intelligence = 30, willpower = 30, endurance = 50},
            skills = {longblade = 15, athletics = 5, axe = 5, bluntweapon = 5, heavyarmor = 5, mediumarmor = 5, shortblade = 5},
            spells = {'resist disease_75', 'resist poison_75', 'adrenaline rush'},
        }
        Data.races:new{ name = 'wood elf',
            PCRace = 10,
            attributes_male   = {strength = 30, willpower = 30, agility = 50, speed = 50, endurance = 30},
            attributes_female = {strength = 30, willpower = 30, agility = 50, speed = 50, endurance = 30},
            skills = {marksman = 15, sneak = 10, lightarmor = 10, alchemy = 5, acrobatics = 5},
            spells = {'resist disease_75', 'beast tongue'},
        }
    end
}
-- Compatibility module for Reincarnate - Races of Morrowind
Compat.modules:new{ name ='reincarnate',
    content_files = {'Reincarnate - Races of Morrowind.ESP'},
    dependencies = {'vanilla_races'},
    apply = function()
        Data.races:edit{ name = 'high elf',
            skills = {destruction = 15},
            spells = {'racial_altmer_ability_1'       ,'racial_altmer_ability_2'          ,'racial_altmer_power'},
        }
        Data.races:edit{ name = 'argonian',
            skills = {spear = 10},
            spells = {'racial_argonian_ability_1'     ,'racial_argonian_ability_2_spell'  ,'racial_argonian_power' ,'racial_argonian_ability_2_perk'},
        }
        Data.races:edit{ name = 'wood elf',
            skills = {restoration = 5},
            spells = {'racial_bosmer_ability_1'       ,'racial_bosmer_ability_2'          ,'racial_bosmer_power'},
        }
        Data.races:edit{ name = 'breton',
            skills = {conjuration = 15},
            spells = {'racial_breton_ability_1'       ,'racial_breton_ability_2'          ,'racial_breton_power'},
        }
        Data.races:edit{ name = 'dark elf',
            skills = {marksman = 10, mediumarmor = 5, athletics = 0},
            spells = {'racial_dunmer_ability_1'       ,'racial_dunmer_ability_2'          ,'racial_dunmer_power'},
        }
        Data.races:edit{ name = 'imperial',
            skills = {block = 5, heavyarmor = 5, speechcraft = 15},
            spells = {'racial_imperial_ability_1'     ,'racial_imperial_ability_2'        ,'racial_imperial_power'},
        }
        Data.races:edit{ name = 'khajiit',
            skills = {handtohand = 10},
            spells = {'racial_khajiit_ability_1_spell','racial_khajiit_ability_2_spell'   ,'racial_khajiit_ability_3', 'racial_khajiit_power', 'racial_khajiit_ability_1_perk', 'racial_khajiit_ability_2_perk'},
        }
        Data.races:edit{ name = 'nord',
            skills = {axe = 15, lightarmor = 10, mediumarmor = 0},
            spells = {'racial_nord_ability_1'         ,'racial_nord_ability_2'            ,'racial_nord_power'},
        }
        Data.races:edit{ name = 'orc',
            skills = {armorer = 15},
            spells = {'racial_orc_ability_1'          ,'racial_orc_ability_2'             ,'racial_orc_power'},
        }
        Data.races:edit{ name = 'redguard',
            skills = {athletics = 10},
            spells = {'racial_redguard_ability_1'     ,'racial_redguard_ability_2'        ,'racial_redguard_power'},
        }
    end
}

-- Compatibility module for Kart's Special Boy
Compat.modules:new{ name ='kart_special_boy',
    content_files = {'kart_special_boy.esp', 'kart_special_boy.omwaddon'},
    dependencies = {'reincarnate'},
    apply = function()
        Data.races['kart_breton'] = Data.races.breton
    end
}

-- 
Compat.modules:new{ name ='sensiblebirthsigns',
    content_files = {'SensibleBirthsigns.esp'},
    apply = function()
        if Data.birthsigns['Moonshadow Sign'] then
            table.insert(Data.birthsigns['Moonshadow Sign'], '_shadowKin')
        end
    end
}
-- RETURN || NEED THIS SO FILE DO THING
return {Data = Data, Compat = Compat}
