local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')
local animation = require('openmw.animation')

--modID for easy settings registering
local modID = 'LightweightLeveling'

--get the list of attributes and skills
local attributeTable = core.stats.Attribute.records
local skillTable = core.stats.Skill.records

--register the whole page
I.Settings.registerPage {
  key = modID,
  l10n = modID,
  name = 'Lightweight Leveling Options',
  description = 'Alter the rate at which you gain attribute points, as well as the maxmimum value attributes can reach this way.'
}

--register the section for the two settings
I.Settings.registerGroup {
  order = 0,
  key = 'Settings' .. modID,
  page = modID,
  l10n = modID,
  name = 'General',
  description = '',
  permanentStorage = true,
  settings = {
    {
    key = 'MagicNumber',
    renderer = 'number',
    argument = { min = 1, max = 10 },
    name = 'Magic Number',
    description = 'The number of skill increases required to increase an attribute.\n(Default: 5, Minimum: 1, Maximum: 10)',
    default = 5
    },
    {
    key = 'AttributeCap',
    renderer = 'number',
    argument = { min = 100, max = 999 },
    name = 'Attribute Cap',
    description = 'The maximum value your attributes can be increased to.\n(Default: 100, Minimum: 100, Maximum: 999)',
    default = 100
    }
  }
}

--define the settings for later use
local settings = storage.playerSection('Settings' .. modID)

--get the magic number (required skill increases)
local function getMagicNumber()
  return settings:get('MagicNumber')
end

--get the attribute cap
local function getAttributeCap()
  return settings:get('AttributeCap')
end

--keep track of the skill increases by governing attribute
local counter = {
  ['Strength'] = 0,
  ['Intelligence'] = 0,
  ['Willpower'] = 0,
  ['Agility'] = 0,
  ['Speed'] = 0,
  ['Endurance'] = 0,
  ['Personality'] = 0
}

--function for the audio/visual effect of attribute increasing
local function attributeIncreaseEffect()

  --params for the sound
  local params = {
    timeOffset=0.1,
    volume=0.5,
    scale=false,
    pitch=1.0,
    loop=false
  }
  
  --the effect is the fortify attribute effect, very fitting
  local mgef = core.magic.effects.records[79]
  
  --options for the visual effect
  local options = {
    vfxId = mgef.id,
    loop=false
  }
  
  --play the visual effect
  animation.addVfx(self,types.Static.record(mgef.hitStatic).model,options)
  --play the sound
  ambient.playSound('restoration hit', params)

end

--increase the attribute depending on the name of the attribute sent. Increments by 1 only
local function incrementAttribute(attribute)

  --for some reason, i can't do math on the values directly, so create increment as a stopgap variable
  increment = 0
  
  --allow the player some setting control
  cap = getAttributeCap()

  --won't go through this whole thing, but will go through one section, they're all the same
  --if statement to get the right attribute to increase
  if (attribute == 'Strength') then
    --if their attribute is less than the cap (defined in settings) then proceed
    if types.Actor.stats.attributes.strength(self).base < cap then
      --establish increment as stopgap variable
      increment = types.Actor.stats.attributes.strength(self).base
      --increment
      increment = increment + 1
      --set the actual attribute to the now increased value
      types.Actor.stats.attributes.strength(self).base = increment
      --send an event to the player to make sure they know what happened
      self:sendEvent('ShowMessage', {message = 'Your Strength has increased!'})
      --do the audio/visual effect to let the player know
      attributeIncreaseEffect()
    --if attribute is equal to or greater than cap, then stop it from increasing
    else
      --send message to Lua log, not to player
      print('Your Strength is already at max.')
    end
  elseif (attribute == 'Intelligence') then
    if types.Actor.stats.attributes.intelligence(self).base < cap then
      increment = types.Actor.stats.attributes.intelligence(self).base
      increment = increment + 1
      types.Actor.stats.attributes.intelligence(self).base = increment
      self:sendEvent('ShowMessage', {message = 'Your Intelligence has increased!'})
      attributeIncreaseEffect()
    else
      print('Your Intelligence is already at max.')
    end
  elseif (attribute == 'Willpower') then
    if types.Actor.stats.attributes.willpower(self).base < cap then
      increment = types.Actor.stats.attributes.willpower(self).base
      increment = increment + 1
      types.Actor.stats.attributes.willpower(self).base = increment
      self:sendEvent('ShowMessage', {message = 'Your Willpower has increased!'})
      attributeIncreaseEffect()
    else
      print('Your Willpower is already at max.')
    end
  elseif (attribute == 'Agility') then
    if types.Actor.stats.attributes.agility(self).base < cap then
      increment = types.Actor.stats.attributes.agility(self).base
      increment = increment + 1
      types.Actor.stats.attributes.agility(self).base = increment
      self:sendEvent('ShowMessage', {message = 'Your Agility has increased!'})
      attributeIncreaseEffect()
    else
      print('Your Agility is already at max.')
    end
  elseif (attribute == 'Speed') then
    if types.Actor.stats.attributes.speed(self).base < cap then
      increment = types.Actor.stats.attributes.speed(self).base
      increment = increment + 1
      types.Actor.stats.attributes.speed(self).base = increment
      self:sendEvent('ShowMessage', {message = 'Your Speed has increased!'})
      attributeIncreaseEffect()
    else
      print('Your Speed is already at max.')
    end
  elseif (attribute == 'Endurance') then
    if types.Actor.stats.attributes.endurance(self).base < cap then
      increment = types.Actor.stats.attributes.endurance(self).base
      increment = increment + 1
      types.Actor.stats.attributes.endurance(self).base = increment
      self:sendEvent('ShowMessage', {message = 'Your Endurance has increased!'})
      attributeIncreaseEffect()
    else
      print('Your Endurance is already at max.')
    end
  elseif (attribute == 'Personality') then
    if types.Actor.stats.attributes.personality(self).base < cap then
      increment = types.Actor.stats.attributes.personality(self).base
      increment = increment + 1
      types.Actor.stats.attributes.personality(self).base = increment
      self:sendEvent('ShowMessage', {message = 'Your Personality has increased!'})
      attributeIncreaseEffect()
    else
      print('Your Personality is already at max.')
    end
  end

end

--establish the levelup handler
I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
  
  --get the value for the required skill increases from settings
  magicNumber = getMagicNumber()
  --get the name of the skill that just leveled
  skill = skillTable[skillid].name
  --get the governing attribute of that skill
  attribute = attributeTable[skillTable[skillid].attribute].name
    
  --increase the counter to keep track of skill increases
  counter[attribute] = counter[attribute] + 1
    
  --if the counter is divisible by the magic number, then increase the associated attribute
  if (counter[attribute] % magicNumber == 0) then
    incrementAttribute(attribute)
  end
    
end)

return {
  engineHandlers = {
    
    --set the counters to the right values on load
    onLoad = function(data)
      if data and data.counter then
        counter = data.counter
      end
    end,
    
    --save the counter values for later loading
    onSave = function() return {counter = counter} end
  }
}
