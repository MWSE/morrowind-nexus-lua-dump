local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local iui = require('openmw.interfaces').UI -- to disable extra hurt if resting

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
  key = 'SolLoseMoreHealth',
  l10n = 'SolLoseMoreHealth',
  name = 'name',
  description = 'description',
})
-- default values!
local enabled = true
local verbose = false
local hurtOnGain = true
local hurtPercent = 50
local pctThreshold = 0.05
local allowHurtWhileRest = false
I.Settings.registerGroup({
  key = 'Settings_SolLoseMoreHealth',
  page = 'SolLoseMoreHealth',
  l10n = 'SolLoseMoreHealth',
  name = 'group_name',
  permanentStorage = true,
  settings = {
		boolSetting('enabled',enabled),
		boolSetting('verbose',verbose),
		boolSetting('hurtOnGain',hurtOnGain),
		numbSetting('hurtPercent',hurtPercent,true,0,1000),
		numbSetting('pctThreshold',pctThreshold,false,0.0,1.0),
		boolSetting('allowHurtWhileRest',allowHurtWhileRest),
  },
})
local settingsGroup = storage.playerSection('Settings_SolLoseMoreHealth')

local hurtMult = { 1, 1 } -- on hurt, on heal
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  hurtOnGain = settingsGroup:get('hurtOnGain')
  hurtPercent = settingsGroup:get('hurtPercent')
  hurtMult[1] = 0.01 * hurtPercent
  hurtMult[2] = 1 - 1 / (1 + 0.01 * hurtPercent)
  pctThreshold = settingsGroup:get('pctThreshold')
  allowHurtWhileRest = settingsGroup:get('allowHurtWhileRest')
end
local function init()
  updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- shorthand for convenience
local dynamic = types.Actor.stats.dynamic

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local remainder = 0
-- save state to be removed on load
local function onSave()
  return {
    remainder = remainder
  }
end
local function onLoad(data)
  if data then
    remainder = data.remainder
  end
end

local hurtOrder = 5

local curHeal = 0
local oldHeal = 0
local oldMax = 0
local curMax = 0
local doHurt = false
local delHeal = 0
local hurtVal = 0
local hurtApply = 0
local hurtIdx = 1
local isResting = false
return {
  engineHandlers = {
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,

    onUpdate = function(dt)
      if enabled then
        curHeal = math.ceil(dynamic.health(self).current)

        if isResting then -- if you were resting, which will only be true if you aren't supposed to take damage while resting...
          oldHeal = curHeal
        end

        if not doHurt then
          if curHeal ~= oldHeal then   -- if health changed check if max changed
            --              ui.printToConsole(tostring(curHeal) ..' '..tostring(oldHeal) ..' '..tostring(hurtVal),ui.CONSOLE_COLOR.Default)
            if oldHeal == 0 then       -- on very first frame get it proper
              oldHeal = curHeal
            end
            curMax = math.ceil(dynamic.health(self).base)
            if curMax ~= oldMax then
              if oldMax == 0 then   -- on very first frame get it proper
                oldMax = curMax
              end
              -- if current and old health rations are too similar, do nothing
              if math.abs(1 - (curHeal / curMax * oldMax / oldHeal)) < pctThreshold then -- make threshold a setting
                doHurt = false
              else
                doHurt = true
              end
            else
              if curHeal < oldHeal then
                doHurt = true   -- definitely hurt is lost health
                hurtIdx = 1
                --  ui.showMessage('hurt')
              else
                doHurt = hurtOnGain   -- make this a setting, to hurt if gained health?
                hurtIdx = 2
                --  ui.showMessage('heal- ' .. tostring(hurtOnGain))
              end
              -- update oldval for next frame
              oldMax = curMax
            end

            -- get updates prior to hurting or not
            delHeal = math.abs(curHeal - oldHeal)
            delHeal = (delHeal - math.abs(hurtVal))
            --     ui.printToConsole(tostring(delHeal) .. ' ' .. tostring(hurtVal),ui.CONSOLE_COLOR.Default)

            if doHurt then
              if remainder ~= remainder or not remainder then   -- if nan or nil
                remainder = 0
              end

              -- include remainder from last hurt for total hurt val
              hurtVal = hurtMult[hurtIdx] * delHeal

              -- debug on hurt val accumulation
              --    ui.printToConsole(tostring(hurtVal) .. ' ' .. tostring(delHeal),ui.CONSOLE_COLOR.Default)

              hurtVal = hurtVal + remainder
              if hurtVal >= hurtOrder then
                --    if hurtVal ~= 0 then -- this requires I use more logic to ceil if negative
                hurtApply = math.floor(hurtVal)

                -- debug on damage take
                if verbose then
                  ui.printToConsole(
                  tostring(oldHeal) .. ' -> ' .. tostring(curHeal) .. ' -> ' .. tostring(curHeal - hurtApply),
                    ui.CONSOLE_COLOR.Default)
                end

                -- now apply the hurt
                curHeal = math.max(0, curHeal - hurtApply)   -- dead vs not dead
                dynamic.health(self).current = curHeal
              else
                hurtApply = 0
              end
              --    ui.printToConsole(tostring(remainder) ..' = '.. tostring(hurtVal) ..' - '.. tostring(hurtApply),ui.CONSOLE_COLOR.Default)
              remainder = hurtVal - hurtApply
              hurtVal = 0
              doHurt = false
            end
            -- update oldval for next frame
            oldHeal = curHeal
          end
          isResting = false -- now that it's definitely not paused, turn off resting thing
        end
      end
    end,

    onFrame = function(dt)
      if enabled and hurtOnGain and (not allowHurtWhileRest) then
        if iui.getMode()=="Rest" then
          isResting = true -- this should disable its ability to hurt you... somehow
        end
      end
    end,
  }
}
