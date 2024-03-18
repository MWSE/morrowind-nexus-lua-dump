local types = require('openmw.types')
local time  = require('openmw_aux.time')
local core  = require('openmw.core')
local util  = require('openmw.util')


-- TOOLS
local function makecounter(val)
  local count = val
  return function(mod)
    count = count + mod
    return count
  end
end

local function setpreviousval(key, val)
  local oldval = val
  return function(self, newval)
    self[key] = oldval
    oldval = newval
  end
end

local function get(var) -- var must be serializable, recursions WILL stack overflow :D
  if type(var)  ~= 'table' then return var
  else
    local deepcopy = {}
    for _key, _value in pairs(var) do deepcopy[_key] = get(_value) end
    return deepcopy
  end
end

local Dt = {}
-- Player Data
Dt.pc = {
  spell       = 'spellid',
  armor_condition = {set_prevframe = setpreviousval('prevframe', {}) },
  attack      = {speed = 0, damage = 0, step = 0, minkey = '', group = '', draw = 0}, -- weapon = _obj
  probepick     = nil, -- _obj
  security_target = nil, -- _obj
  grounded    = nil,
  position    = util.vector3(0,0,0),
}
-- Engine Data
Dt.ATTACK_ANIMATION_GROUPS = {
  'handtohand',
  'crossbow',
  'weapononehand',
  'weapontwohand',
  'weapontwowide',
  'bowandarrow',
  'throwweapon',
  'weapontwoclose',
  'blunttwohand',
  'bluntonehand',
  'shortbladeonehand'
}
Dt.ATTACK_ANIMATION_KEYS = {
  MIN = {
    ['chop min attack'  ] = 'chop',
    ['slash min attack' ] = 'slash',
    ['thrust min attack'] = 'thrust',
    ['shoot min attack' ] = 'shoot',
  },
  MAX = {
    ['chop max attack'  ] = true,
    ['slash max attack' ] = true,
    ['thrust max attack'] = true,
    ['shoot max attack' ] = true,
  },
  HIT_RELEASE = {
    ['chop hit'         ] = 'chop',
    ['slash hit'        ] = 'slash',
    ['thrust hit'       ] = 'thrust',
    ['shoot release'    ] = 'chop',
  },
}
Dt.SPELL_ANIMATION_KEYS = {
	['target start'] = true,
	['touch start' ] = true,
	['self start'  ] = true,
}
Dt.WEAPON_TYPES = {
  MELEE = {
    [types.Weapon.TYPE.AxeOneHand       ] = 'axe'        ,
    [types.Weapon.TYPE.AxeTwoHand       ] = 'axe'        ,
    [types.Weapon.TYPE.BluntOneHand     ] = 'bluntweapon',
    [types.Weapon.TYPE.BluntTwoClose    ] = 'bluntweapon',
    [types.Weapon.TYPE.BluntTwoWide     ] = 'bluntweapon',
    [types.Weapon.TYPE.LongBladeOneHand ] = 'longblade'  ,
    [types.Weapon.TYPE.LongBladeTwoHand ] = 'longblade'  ,
    [types.Weapon.TYPE.ShortBladeOneHand] = 'shortblade' ,
    [types.Weapon.TYPE.SpearTwoWide     ] = 'spear'      ,
  },
  BOW = {
    [types.Weapon.TYPE.MarksmanBow      ] = 'marksman'   ,
    [types.Weapon.TYPE.MarksmanCrossbow ] = 'marksman'   ,
  },
  AMMO = {
    [types.Weapon.TYPE.Bolt             ] = 'marksman'   ,
    [types.Weapon.TYPE.Arrow            ] = 'marksman'   ,
  },
  THROWN = {
    [types.Weapon.TYPE.MarksmanThrown   ] = 'marksman'   ,
  },
}
-- CHECK TYPE WHEN USING THESE, THEY CAN HAVE THINGS OF OTHER TYPES
Dt.SLOTS = {
  WEAPON   = get(types.Actor.EQUIPMENT_SLOT.CarriedRight),
  MELEE    = get(types.Actor.EQUIPMENT_SLOT.CarriedRight),
  BOW      = get(types.Actor.EQUIPMENT_SLOT.CarriedRight),
  THROWN   = get(types.Actor.EQUIPMENT_SLOT.CarriedRight),
  AMMO     = get(types.Actor.EQUIPMENT_SLOT.Ammunition  ),
  SHIELD   = get(types.Actor.EQUIPMENT_SLOT.CarriedLeft ),
  ARMOR  = { 
    get(types.Actor.EQUIPMENT_SLOT.Boots        ),
    get(types.Actor.EQUIPMENT_SLOT.CarriedLeft  ),
    get(types.Actor.EQUIPMENT_SLOT.Cuirass      ),
    get(types.Actor.EQUIPMENT_SLOT.Greaves      ),
    get(types.Actor.EQUIPMENT_SLOT.Helmet       ),
    get(types.Actor.EQUIPMENT_SLOT.LeftGauntlet ),
    get(types.Actor.EQUIPMENT_SLOT.LeftPauldron ),
    get(types.Actor.EQUIPMENT_SLOT.RightGauntlet),
    get(types.Actor.EQUIPMENT_SLOT.RightPauldron),
  },
}
Dt.ARMOR_TYPES = {
  [types.Armor.TYPE.Boots    ] = core.getGMST('iBootsWeight'   ),
  [types.Armor.TYPE.Cuirass  ] = core.getGMST('iCuirassWeight' ),
  [types.Armor.TYPE.Greaves  ] = core.getGMST('iGreavesWeight' ),
  [types.Armor.TYPE.Helmet   ] = core.getGMST('iHelmWeight'    ),
  [types.Armor.TYPE.LGauntlet] = core.getGMST('iGauntletWeight'),
  [types.Armor.TYPE.LPauldron] = core.getGMST('iPauldronWeight'),
  [types.Armor.TYPE.LBracer  ] = core.getGMST('iGauntletWeight'),
  [types.Armor.TYPE.RBracer  ] = core.getGMST('iGauntletWeight'),
  [types.Armor.TYPE.RGauntlet] = core.getGMST('iGauntletWeight'),
  [types.Armor.TYPE.RPauldron] = core.getGMST('iPauldronWeight'),
  [types.Armor.TYPE.Shield   ] = core.getGMST('iShieldWeight'  ),
}
Dt.ARMOR_RATING_WEIGHTS= {
  [types.Armor.TYPE.Cuirass  ] = 0.3 ,
  [types.Armor.TYPE.Shield   ] = 0.1 ,
  [types.Armor.TYPE.Helmet   ] = 0.1 ,
  [types.Armor.TYPE.Greaves  ] = 0.1 ,
  [types.Armor.TYPE.Boots    ] = 0.1 ,
  [types.Armor.TYPE.LPauldron] = 0.1 ,
  [types.Armor.TYPE.RPauldron] = 0.1 ,
  [types.Armor.TYPE.LGauntlet] = 0.05,
  [types.Armor.TYPE.RGauntlet] = 0.05,
  [types.Armor.TYPE.LBracer  ] = 0.05,
  [types.Armor.TYPE.RBracer  ] = 0.05,
}
Dt.GMST = {
  iBaseArmorSkill      = core.getGMST('iBaseArmorSkill'     ),
  fWeaponDamageMult    = core.getGMST('fWeaponDamageMult'   ),
  fDamageStrengthMult  = core.getGMST('fDamageStrengthMult' ),
  fDamageStrengthBase  = core.getGMST('fDamageStrengthBase' ),
  fLightMaxMod         = core.getGMST('fLightMaxMod'        ),
  fMedMaxMod           = core.getGMST('fMedMaxMod'          ),
  fUnarmoredBase1      = core.getGMST('fUnarmoredBase1'     ),
  fUnarmoredBase2      = core.getGMST('fUnarmoredBase2'     ),
  iBlockMaxChance      = core.getGMST('iBlockMaxChance'     ),
  iBlockMinChance      = core.getGMST('iBlockMinChance'     ),
  fMaxHandToHandMult   = core.getGMST('fMaxHandToHandMult'  ),
  fMinHandToHandMult   = core.getGMST('fMinHandToHandMult'  ),
  fHandtoHandHealthPer = core.getGMST('fHandtoHandHealthPer'),
  fMinWalkSpeed        = core.getGMST('fMinWalkSpeed'       ), -- Currently unused, could be made to affect athletics formula but it seemed too convoluted.
  fMaxWalkSpeed        = core.getGMST('fMaxWalkSpeed'       ), -- Same as previous, I aired on using a flat speed multiplier instead.
  fEncumbranceStrMult  = core.getGMST('fEncumbranceStrMult' ),
  iMaxActivateDist     = core.getGMST('iMaxActivateDist'    ),
}
Dt.GLOB = {} -- Global variables go here. Unused at the moment.
Dt.ATTRIBUTES = {'strength', 'intelligence', 'willpower', 'agility', 'speed', 'endurance', 'personality', 'luck'}
Dt.SKILLS = {
  'acrobatics' , 'alchemy'  , 'alteration' , 'armorer'   , 'athletics' , 'axe'       , 'block'    , 'bluntweapon', 'conjuration',
  'destruction', 'enchant'  , 'handtohand' , 'heavyarmor', 'illusion'  , 'lightarmor', 'longblade', 'marksman'   , 'mediumarmor',
  'mercantile' , 'mysticism', 'restoration', 'security'  , 'shortblade', 'sneak'     , 'spear'    , 'speechcraft', 'unarmored'
}
Dt.scaler_groups = {
  SPELL  = {'alteration', 'conjuration', 'destruction', 'illusion', 'mysticism', 'restoration'},
  WEAPON = {'axe', 'bluntweapon', 'longblade', 'shortblade', 'spear', 'marksman'},
  ARMOR  = {'heavyarmor', 'lightarmor', 'mediumarmor'}, -- !! Armor health gets reduced by the amount of incoming damage it *blocked*.
}
Dt.STANCE = {
  WEAPON  = {[types.Actor.STANCE.Weapon ] = true},
  SPELL   = {[types.Actor.STANCE.Spell  ] = true},
  NOTHING = {[types.Actor.STANCE.Nothing] = true},
}
Dt.scalers = {
  default = {func = function(useType, xp) return xp end},
  new     = function(self, t) end
}
-- SCRIPT LOGIC VARIABLES
Dt.counters = {
  frame           = makecounter(0),
  weapon          = makecounter(0),
  unarmored       = makecounter(0),
  acrobatics      = makecounter(0),
  athletics       = makecounter(0),
  athletics_debug = makecounter(0),
  security        = makecounter(0),
  }
Dt.securiting = false

--[] Scaler creator: Scalers are simple functions that become the body of skp.addSkillUsedHandler(func) through a Dt.scalers[skillid]() call.

function Dt.scalers:new(t)
  if (t.name) then self[t.name] = {} else error('You can\'t create a nameless scaler!') end
  self[t.name].func = t.func
end

-- RETURN || NEED THIS SO FILE DO THING
return Dt
