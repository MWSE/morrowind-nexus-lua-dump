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
   key = 'SolSwimBoostDrain',
   l10n = 'SolSwimBoostDrain',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local verbose = true
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
      {
         key = 'enabled',
         default = enabled,
         renderer = 'checkbox',
         name = 'enabled_name',
      },
      {
         key = 'verbose',
         default = verbose,
         renderer = 'checkbox',
         name = 'verbose_name',
      },
      {
         key = 'buffSpeed',
         default = buffSpeed,
         renderer = 'number',
         name = 'buffSpeed_name',
         description = 'buffSpeed_description',
         argument = {
            integer = true,
            min = 1,
            max = 1000,
         },
      },
      {
         key = 'statBreakeven',
         default = statBreakeven,
         renderer = 'number',
         name = 'statBreakeven_name',
         description = 'statBreakeven_description',
         argument = {
            integer = true,
            min = 0,
            max = 100,
         },
      },
      {
         key = 'fatigueCost',
         default = fatigueCost,
         renderer = 'number',
         name = 'fatigueCost_name',
         description = 'fatigueCost_description',
         argument = {
            min = 0,
            max = 100,
         },
      },
      {
         key = 'buffDuration',
         default = buffDuration,
         renderer = 'number',
         name = 'buffDuration_name',
         description = 'buffDuration_description',
         argument = {
            min = 0.1,
            max = 5,
         },
      },
      {
         key = 'doHurt',
         default = doHurt,
         renderer = 'checkbox',
         name = 'doHurt_name',
      },
      {
         key = 'hurtVal',
         default = hurtVal,
         renderer = 'number',
         name = 'hurtVal_name',
         description = 'hurtVal_description',
         argument = {
            integer = true,
            min = 1,
            max = 100,
         },
      },
      {
         key = 'hurtWait',
         default = hurtWait,
         renderer = 'number',
         name = 'hurtWait_name',
         description = 'hurtWait_description',
         argument = {
            integer = true,
            min = 1,
            max = 5,
         },
      },
   },
})
local settingsGroup = storage.playerSection('Settings_SolSwimBoostDrain')

-- initialize
local scaleBuff = buffSpeed*statBreakeven/100
local flatBuff = buffSpeed - scaleBuff
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  buffSpeed = settingsGroup:get('buffSpeed')
  statBreakeven = settingsGroup:get('statBreakeven')
    scaleBuff = buffSpeed*statBreakeven/100
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
local function spdMod(modVal)
  attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
  -- damage check
  if attributes.speed(self).modifier == attributes.speed(self).damage then
    attributes.speed(self).modifier = 0
    attributes.speed(self).damage = 0
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local buffTotal = 0
-- save state to be removed on load
local function onSave()
    return{
      buffTotal = buffTotal
    }
end
local function onLoad(data)
  if data then
    buffTotal = data.buffTotal
    spdMod(-buffTotal)
    buffTotal = 0
  end
end

local buffVal = 0
local hurtTime = 0
local lastHurt = 0
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
                dynamic.fatigue(self).current = math.max(0,cfat - fatigueCost)
                -- apply buff
                buffVal = flatBuff + scaleBuff*(skills.athletics(self).modified)/50
                spdMod(buffVal)
                buffTotal = buffTotal + buffVal
          
                if verbose then
                  ui.showMessage('BOOST!')
                end
      
                -- start release timer
                async:newUnsavableSimulationTimer(
                buffDuration,
                function()
                  spdMod(-buffTotal)
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
      if enabled and doHurt then -- if running this calc
        if types.Actor.isSwimming(self) then -- if in water
          local mf = self.controls.movement
          local ms = self.controls.sideMovement
          if mf ~= 0 or ms ~= 0 then -- if moving
            if dynamic.fatigue(self).current == 0 then -- if out of fatigue
              hurtTime = core.getSimulationTime() - lastHurt
              if hurtTime > hurtWait then -- if enough time has passed


               ui.showMessage('Swimming while out of fatigue!')

                dynamic.health(self).current = math.max(0,dynamic.health(self).current - hurtVal) -- don't set to below 0
                lastHurt = core.getSimulationTime() -- get timer value
              end
            end
          end
        end
      end
    end,
  } 
}