local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local debug = require('openmw.debug')
local ambient = require('openmw.ambient') -- 0.49 required?

-- settings functions
local function boolSetting(sKey, sDef)
  return {
    key = sKey,
    renderer = 'checkbox',
    name = sKey .. '_name',
    description = sKey .. '_desc',
    default = sDef,
  }
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
  return {
    key = sKey,
    renderer = 'number',
    name = sKey .. '_name',
    description = sKey .. '_desc',
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
  key = 'SolSwimBoostDrain',
  l10n = 'SolSwimBoostDrain',
  name = 'name',
  description = 'description',
})
-- default values!
local enabled = true
local verbose = false
local sfxVolume = 1.0
local buffSpeed = 500
local statBreakeven = 50
local fatigueCost = 30
local buffDuration = 0.5
local doHurt = true
local hurtVal = 5
local hurtWait = 2
I.Settings.registerGroup({
  key = 'Settings_SolSwimBoostDrain',
  page = 'SolSwimBoostDrain',
  l10n = 'SolSwimBoostDrain',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled', enabled),
    boolSetting('verbose', verbose),
    numbSetting('sfxVolume', sfxVolume, false, 0.0, 2.0),
    numbSetting('buffSpeed', buffSpeed, true, 1, 1000),
    numbSetting('statBreakeven', statBreakeven, true, 0, 100),
    numbSetting('fatigueCost', fatigueCost, true, 0, 100),
    numbSetting('buffDuration', buffDuration, false, 0.1, 5),
    boolSetting('doHurt', doHurt),
    numbSetting('hurtVal', hurtVal, true, 1, 100),
    numbSetting('hurtWait', hurtWait, true, 1, 5),
  },
})
local settingsGroup = storage.playerSection('Settings_SolSwimBoostDrain')

-- initialize
local scaleBuff = buffSpeed * statBreakeven / 100
local flatBuff = buffSpeed - scaleBuff
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  sfxVolume = settingsGroup:get('sfxVolume')
  buffSpeed = settingsGroup:get('buffSpeed')
  statBreakeven = settingsGroup:get('statBreakeven')
  scaleBuff = buffSpeed * statBreakeven / 100
  flatBuff = buffSpeed - scaleBuff
  fatigueCost = settingsGroup:get('fatigueCost')
  buffDuration = settingsGroup:get('buffDuration')
  doHurt = settingsGroup:get('doHurt')
  hurtVal = settingsGroup:get('hurtVal')
  hurtWait = settingsGroup:get('hurtWait')
end
local function init()
  updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- stance effects
local function spdMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.speed(self).modifier = math.max(0, attributes.speed(self).modifier + modSign * modVal)
  else
    modVal = math.abs(modVal)
    attributes.speed(self).damage = math.max(0, attributes.speed(self).damage + modSign * modVal)
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local buffTotal = 0
-- save state to be removed on load
local function onSave()
  return {
    buffTotal = buffTotal
  }
end
local function onLoad(data)
  if data then
    buffTotal = data.buffTotal
    spdMod(-1, buffTotal)
    buffTotal = 0
  end
end

local buffVal = 0
local hurtTime = 0
local doBuff = true
return {
  engineHandlers = {
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,

    onInputAction = function(id)
      if enabled then
        if id == input.ACTION.Jump then
          if types.Actor.isSwimming(self) then
            if doBuff then
              -- apply fatigue cost
              local cfat = dynamic.fatigue(self).current
              --if cfat >= fatigueCost then -- only do buff if enough fatigue for it
              if cfat >= 1 then -- Allow to boost to empty, but not to boost on empty
                doBuff = false
                if not debug.isGodMode() then
                  dynamic.fatigue(self).current = math.max(0, cfat - fatigueCost)
                end
                -- apply buff
                buffVal = flatBuff + scaleBuff * (skills.athletics(self).modified) / 50
                spdMod(1, buffVal)
                buffTotal = buffTotal + buffVal

                if ambient and (sfxVolume > 0.0) then
                  --ambient.playSound("defaultlandwater")
                  ambient.playSound("footwaterleft", { volume = (0.5 * sfxVolume), pitch = (0.95 + 0.1 * math.random()) })
                  ambient.playSound("footwaterright", { volume = (0.5 * sfxVolume), pitch = (0.95 + 0.1 * math.random()) })
                end
                if verbose then
                  ui.showMessage('BOOST!')
                end

                -- start release timer
                async:newUnsavableSimulationTimer(
                  buffDuration,
                  function()
                    spdMod(-1, buffTotal)
                    buffTotal = 0
                    doBuff = true
                  end
                )
              end
            end
          end
        end
      end
    end,

    onUpdate = function(dt)
      if enabled and doHurt then             -- if running this calc
        if types.Actor.isSwimming(self) then -- if in water
          local mf = self.controls.movement
          local ms = self.controls.sideMovement
          if mf ~= 0 or ms ~= 0 then                                             -- if moving
            if dynamic.fatigue(self).current == 0 and not debug.isGodMode() then -- if out of fatigue
              hurtTime = hurtTime + dt
              if hurtTime > hurtWait then                                        -- if enough time has passed
                if ambient and (sfxVolume > 0.0) then
                  ambient.playSound("Drown", { volume = (1.0 * sfxVolume) })
                  ambient.playSound("Health Damage", { volume = (0.5 * sfxVolume) })
                else
                  ui.showMessage('Swimming while out of fatigue!')
                end
                dynamic.health(self).current = math.max(0, dynamic.health(self).current - hurtVal) -- don't set to below 0
                hurtTime = 0
              end
            end
          end
        end
      end
    end,
  }
}
