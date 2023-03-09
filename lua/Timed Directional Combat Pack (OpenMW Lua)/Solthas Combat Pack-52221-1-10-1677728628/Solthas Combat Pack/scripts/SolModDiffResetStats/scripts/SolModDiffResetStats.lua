local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')

-- settings functions
local function boolSetting(sKey, sDef)
    return {
        key = sKey,
        renderer = 'checkbox',
        name = sKey..'_name',
        description = sKey..'_desc',
        default = sDef,
    }
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
    return {
        key = sKey,
        renderer = 'number',
        name = sKey..'_name',
        description = sKey..'_desc',
        default = sDef,
    argument = {
      integer = sInt,
      min = sMin,
      max = sMax,
    },
    }
end
-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
I.Settings.registerPage({
   key = 'SolModDiffResetStats',
   l10n = 'SolModDiffResetStats',
   name = 'name',
   description = 'description',
})
-- default values!
local doRun = false
local raiseDifficulty = false
local lowerDifficulty = false
local difficultyMod = 0.2
local damage = false
local modifier = false
I.Settings.registerGroup({
   key = 'Settings_SolModDiffResetStats',
   page = 'SolModDiffResetStats',
   l10n = 'SolModDiffResetStats',
   name = 'group_name',
   permanentStorage = true,
   settings = {
		boolSetting('doRun',doRun),
		boolSetting('raiseDifficulty',raiseDifficulty),
		boolSetting('lowerDifficulty',lowerDifficulty),
		numbSetting('difficultyMod',difficultyMod, false,0,1),
		boolSetting('damage',damage),
		boolSetting('modifier',modifier),
	},
})

local settingsGroup = storage.playerSection('Settings_SolModDiffResetStats')

-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills

-- init to defaults
baseMult = 1
-- update
local function updateSettings()
  raiseDifficulty = settingsGroup:get('raiseDifficulty')
  lowerDifficulty = settingsGroup:get('lowerDifficulty')
  difficultyMod = settingsGroup:get('difficultyMod')
  damage = settingsGroup:get('damage')
  modifier = settingsGroup:get('modifier')
  -- force run update
  doRun = settingsGroup:get('doRun')
end
local function init()
  updateSettings()
  
  -- change base stat modifier
  baseMult = 1
  if raiseDifficulty then
  baseMult = baseMult / (1 + difficultyMod)
  end
  if lowerDifficulty then
  baseMult = baseMult * (1 + difficultyMod)
  end
  if raiseDifficulty or lowerDifficulty then
    -- update settings
    raiseDifficulty = false
    settingsGroup:set('raiseDifficulty',false)
    lowerDifficulty = false
    settingsGroup:set('lowerDifficulty',false)
    -- update attributes
    attributes.strength(self).base = math.floor(math.max(0,baseMult*attributes.strength(self).base))
    attributes.intelligence(self).base = math.floor(math.max(0,baseMult*attributes.intelligence(self).base))
    attributes.willpower(self).base = math.floor(math.max(0,baseMult*attributes.willpower(self).base))
    attributes.agility(self).base = math.floor(math.max(0,baseMult*attributes.agility(self).base))
    attributes.speed(self).base = math.floor(math.max(0,baseMult*attributes.speed(self).base))
    attributes.endurance(self).base = math.floor(math.max(0,baseMult*attributes.endurance(self).base))
    attributes.personality(self).base = math.floor(math.max(0,baseMult*attributes.personality(self).base))
    attributes.luck(self).base = math.floor(math.max(0,baseMult*attributes.luck(self).base))
    -- update skills
    --combat
    skills.armorer(self).base = math.floor(math.max(0,baseMult*skills.armorer(self).base))
    skills.athletics(self).base = math.floor(math.max(0,baseMult*skills.athletics(self).base))
    skills.axe(self).base = math.floor(math.max(0,baseMult*skills.axe(self).base))
    skills.block(self).base = math.floor(math.max(0,baseMult*skills.block(self).base))
    skills.bluntweapon(self).base = math.floor(math.max(0,baseMult*skills.bluntweapon(self).base))
    skills.heavyarmor(self).base = math.floor(math.max(0,baseMult*skills.heavyarmor(self).base))
    skills.longblade(self).base = math.floor(math.max(0,baseMult*skills.longblade(self).base))
    skills.mediumarmor(self).base = math.floor(math.max(0,baseMult*skills.mediumarmor(self).base))
    skills.spear(self).base = math.floor(math.max(0,baseMult*skills.spear(self).base))
    --magic
    skills.alchemy(self).base = math.floor(math.max(0,baseMult*skills.alchemy(self).base))
    skills.alteration(self).base = math.floor(math.max(0,baseMult*skills.alteration(self).base))
    skills.conjuration(self).base = math.floor(math.max(0,baseMult*skills.conjuration(self).base))
    skills.destruction(self).base = math.floor(math.max(0,baseMult*skills.destruction(self).base))
    skills.enchant(self).base = math.floor(math.max(0,baseMult*skills.enchant(self).base))
    skills.illusion(self).base = math.floor(math.max(0,baseMult*skills.illusion(self).base))
    skills.mysticism(self).base = math.floor(math.max(0,baseMult*skills.mysticism(self).base))
    skills.restoration(self).base = math.floor(math.max(0,baseMult*skills.restoration(self).base))
    skills.unarmored(self).base = math.floor(math.max(0,baseMult*skills.unarmored(self).base))
    --stealth
    skills.acrobatics(self).base = math.floor(math.max(0,baseMult*skills.acrobatics(self).base))
    skills.handtohand(self).base = math.floor(math.max(0,baseMult*skills.handtohand(self).base))
    skills.lightarmor(self).base = math.floor(math.max(0,baseMult*skills.lightarmor(self).base))
    skills.marksman(self).base = math.floor(math.max(0,baseMult*skills.marksman(self).base))
    skills.mercantile(self).base = math.floor(math.max(0,baseMult*skills.mercantile(self).base))
    skills.security(self).base = math.floor(math.max(0,baseMult*skills.security(self).base))
    skills.shortblade(self).base = math.floor(math.max(0,baseMult*skills.shortblade(self).base))
    skills.sneak(self).base = math.floor(math.max(0,baseMult*skills.sneak(self).base))
    skills.speechcraft(self).base = math.floor(math.max(0,baseMult*skills.speechcraft(self).base))
  end
  
  -- debug case... resetting all relevant modifiers
  if damage then
    -- update settings
    damage = false
    settingsGroup:set('damage',false)
    -- update attributes
    attributes.strength(self).damage = 0
    attributes.intelligence(self).damage = 0
    attributes.willpower(self).damage = 0
    attributes.agility(self).damage = 0
    attributes.speed(self).damage = 0
    attributes.endurance(self).damage = 0
    attributes.personality(self).damage = 0
    attributes.luck(self).damage = 0
    -- update skills
    --combat
    skills.armorer(self).damage = 0
    skills.athletics(self).damage = 0
    skills.axe(self).damage = 0
    skills.block(self).damage = 0
    skills.bluntweapon(self).damage = 0
    skills.heavyarmor(self).damage = 0
    skills.longblade(self).damage = 0
    skills.mediumarmor(self).damage = 0
    skills.spear(self).damage = 0
    --magic
    skills.alchemy(self).damage = 0
    skills.alteration(self).damage = 0
    skills.conjuration(self).damage = 0
    skills.destruction(self).damage = 0
    skills.enchant(self).damage = 0
    skills.illusion(self).damage = 0
    skills.mysticism(self).damage = 0
    skills.restoration(self).damage = 0
    skills.unarmored(self).damage = 0
    --stealth
    skills.acrobatics(self).damage = 0
    skills.handtohand(self).damage = 0
    skills.lightarmor(self).damage = 0
    skills.marksman(self).damage = 0
    skills.mercantile(self).damage = 0
    skills.security(self).damage = 0
    skills.shortblade(self).damage = 0
    skills.sneak(self).damage = 0
    skills.speechcraft(self).damage = 0
  end

  if modifier then
    -- update settings
    modifier = false
    settingsGroup:set('modifier',false)
    -- update attributes
    attributes.strength(self).modifier = 0
    attributes.intelligence(self).modifier = 0
    attributes.willpower(self).modifier = 0
    attributes.agility(self).modifier = 0
    attributes.speed(self).modifier = 0
    attributes.endurance(self).modifier = 0
    attributes.personality(self).modifier = 0
    attributes.luck(self).modifier = 0
    -- update skills
    --combat
    skills.armorer(self).modifier = 0
    skills.athletics(self).modifier = 0
    skills.axe(self).modifier = 0
    skills.block(self).modifier = 0
    skills.bluntweapon(self).modifier = 0
    skills.heavyarmor(self).modifier = 0
    skills.longblade(self).modifier = 0
    skills.mediumarmor(self).modifier = 0
    skills.spear(self).modifier = 0
    --magic
    skills.alchemy(self).modifier = 0
    skills.alteration(self).modifier = 0
    skills.conjuration(self).modifier = 0
    skills.destruction(self).modifier = 0
    skills.enchant(self).modifier = 0
    skills.illusion(self).modifier = 0
    skills.mysticism(self).modifier = 0
    skills.restoration(self).modifier = 0
    skills.unarmored(self).modifier = 0
    --stealth
    skills.acrobatics(self).modifier = 0
    skills.handtohand(self).modifier = 0
    skills.lightarmor(self).modifier = 0
    skills.marksman(self).modifier = 0
    skills.mercantile(self).modifier = 0
    skills.security(self).modifier = 0
    skills.shortblade(self).modifier = 0
    skills.sneak(self).modifier = 0
    skills.speechcraft(self).modifier = 0
  end
  
end
settingsGroup:subscribe(async:callback(updateSettings))

return { 
  engineHandlers = { 
    onActive = init,
    onInputAction = function(id)
      if doRun then
        if id == input.ACTION.GameMenu or id == input.ACTION.Use then
          doRun = false
          settingsGroup:set('doRun',false) -- turn off here to prevent recursion with init()
          init()
        end
      end
    end
  }
}