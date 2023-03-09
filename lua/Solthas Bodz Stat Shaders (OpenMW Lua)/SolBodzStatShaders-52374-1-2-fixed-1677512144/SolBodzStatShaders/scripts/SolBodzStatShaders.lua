local self = require('openmw.self')
local types = require('openmw.types')
local dynamic = types.Actor.stats.dynamic

-- shader
local postprocessing = require('openmw.postprocessing')
local shader = postprocessing.load('HealthFatigueEffect')

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
local async = require('openmw.async')
I.Settings.registerPage({
   key = 'SolBodzStatShaders',
   l10n = 'SolBodzStatShaders',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local healthIntensity = 1.0
local magicIntensity = 1.0
local fatigueIntensity = 1.0
local updateInteveral = 0.1
I.Settings.registerGroup({
  key = 'Settings_SolBodzStatShaders',
  page = 'SolBodzStatShaders',
  l10n = 'SolBodzStatShaders',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled',enabled),
    numbSetting('healthIntensity',healthIntensity, false,0.0,2.0),
    numbSetting('magicIntensity',magicIntensity, false,0.0,2.0),
    numbSetting('fatigueIntensity',fatigueIntensity, false,0.0,2.0),
    numbSetting('updateInteveral',updateInteveral, false,0.01,1.0),
  },
})
local settingsGroup = storage.playerSection('Settings_SolBodzStatShaders')
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
    if enabled then
      shader:enable()
	else
      shader:disable() -- force disable just in case
    end
  healthIntensity = settingsGroup:get('healthIntensity')
    if healthIntensity == 0.0 then
      shader:setFloat("uHealthFactor",0.0)
    end
  magicIntensity = settingsGroup:get('magicIntensity')
    if magicIntensity == 0.0 then
      shader:setFloat("uMagickaFactor",0.0)
    end
  fatigueIntensity = settingsGroup:get('fatigueIntensity')
    if fatigueIntensity == 0.0 then
      shader:setFloat("uFatigueFactor",0.0)
    end
  updateInteveral = settingsGroup:get('updateInteveral')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

local maxStat = 0
local pctStat = 0
local updateTime = 0
return {
  engineHandlers = { 
    -- init settings
    onActive = init,

    onUpdate = function(dt)
    if enabled then
      updateTime = updateTime + dt
      if updateTime >= updateInteveral then
        updateTime = 0.0
        if healthIntensity > 0.0 then
          local maxStat = dynamic.health(self).base
		  if maxStat == 0 then
		    maxStat = 1
		  end
          pctStat = math.sqrt(1.0 - math.min(1.0,(2.0*dynamic.health(self).current/maxStat)))
          shader:setFloat("uHealthFactor",healthIntensity*pctStat)
        end
        if magicIntensity > 0.0 then
          local maxStat = dynamic.magicka(self).base
		  if maxStat == 0 then
		    maxStat = 1
		  end
          pctStat = math.sqrt(1.0 - math.min(1.0,(2.0*dynamic.magicka(self).current/maxStat)))
          shader:setFloat("uMagickaFactor",magicIntensity*pctStat)
        end
        if fatigueIntensity > 0.0 then
          local maxStat = dynamic.fatigue(self).base
		  if maxStat == 0 then
		    maxStat = 1
		  end
          pctStat = math.sqrt(1.0 - math.min(1.0,(2.0*dynamic.fatigue(self).current/maxStat)))
          shader:setFloat("uFatigueFactor",fatigueIntensity*pctStat)
        end
      end
    end
  end
  }
}

