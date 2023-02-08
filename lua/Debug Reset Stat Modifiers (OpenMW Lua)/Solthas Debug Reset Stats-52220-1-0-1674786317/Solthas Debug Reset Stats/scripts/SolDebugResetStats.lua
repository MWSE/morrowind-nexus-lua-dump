local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')

-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'SolDebugResetStats',
   l10n = 'SolDebugResetStats',
   name = 'name',
   description = 'description',
})

-- default values!
local damage = false
local modifier = false
I.Settings.registerGroup({
   key = 'Settings_SolDebugResetStats',
   page = 'SolDebugResetStats',
   l10n = 'SolDebugResetStats',
   name = 'group_name',
   permanentStorage = true,
   settings = {
      {
         key = 'damage',
         default = damage,
         renderer = 'checkbox',
         name = 'damage_name',
      },
      {
         key = 'modifier',
         default = modifier,
         renderer = 'checkbox',
         name = 'modifier_name',
      },
   },
})

local settingsGroup = storage.playerSection('Settings_SolDebugResetStats')

-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills

-- reduce effectiveness of hybrid stances
local function hybridVal(base,mult,count)
    return math.ceil(base*math.pow(mult,math.max(count,0)))
end

-- init to defaults
-- update
local function updateSettings()
  damage = settingsGroup:get('damage')
  modifier = settingsGroup:get('modifier')
end
local function init()
    updateSettings()
--    ui.printToConsole('speed damage ' .. tostring(attributes.speed(self).damage),ui.CONSOLE_COLOR.Default)
--    ui.printToConsole('speed modifier ' .. tostring(attributes.speed(self).modifier),ui.CONSOLE_COLOR.Default)
--    ui.printToConsole('endurance damage ' .. tostring(attributes.endurance(self).damage),ui.CONSOLE_COLOR.Default)
--    ui.printToConsole('endurance modifier ' .. tostring(attributes.endurance(self).modifier),ui.CONSOLE_COLOR.Default)
  
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
  }
}