local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')

-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

-- script config
local modType = 1 --1 skill, -1 debug reset all stat modifiers

I.Settings.registerPage({
   key = 'SolSneakJumpDodge48',
   l10n = 'SolSneakJumpDodge48',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local verbose = true -- 0 none, 1 stance name, 2 stance stats, 3 consoleDebugInfo
local buffArmor = 10000
local buffSpeed = 500
local fatigueCost = 50
local buffDuration = 0.5
I.Settings.registerGroup({
   key = 'Settings_SolSneakJumpDodge48',
   page = 'SolSneakJumpDodge48',
   l10n = 'SolSneakJumpDodge48',
   name = 'group_name',
   permanentStorage = false,
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
         key = 'buffArmor',
         default = buffArmor,
         renderer = 'number',
         name = 'buffArmor_name',
         description = 'buffArmor_description',
         argument = {
            integer = true,
            min = 1,
            max = 100000,
         },
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
   },
})
local settingsGroup = storage.playerSection('Settings_SolSneakJumpDodge48')

-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  buffArmor = settingsGroup:get('buffArmor')
  buffSpeed = settingsGroup:get('buffSpeed')
  fatigueCost = settingsGroup:get('fatigueCost')
  buffDuration = settingsGroup:get('buffDuration')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- debug case... resetting all relevant modifiers
if modType == -1 then
  -- damage -- this really shouldn't be needed
  attributes.speed(self).damage = 0
  skills.heavyarmor(self).damage = 0
  skills.lightarmor(self).damage = 0
  skills.mediumarmor(self).damage = 0
  skills.unarmored(self).damage = 0
  -- modifiers
  attributes.speed(self).modifier = 0
  skills.heavyarmor(self).modifier = 0
  skills.lightarmor(self).modifier = 0
  skills.mediumarmor(self).modifier = 0
  skills.unarmored(self).modifier = 0
end

-- stance effects 
local function phyMod(modVal)
  skills.heavyarmor(self).modifier = skills.heavyarmor(self).modifier + modVal
  skills.lightarmor(self).modifier = skills.lightarmor(self).modifier + modVal
  skills.mediumarmor(self).modifier = skills.mediumarmor(self).modifier + modVal
  skills.unarmored(self).modifier = skills.unarmored(self).modifier + modVal
end
local function spdMod(modVal)
  attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local buffTotal = {0,0}
-- save state to be removed on load
local function onSave()
    return{
      buffTotal = buffTotal
    }
end
local function onLoad(data)
  if data then
    buffTotal = data.buffTotal
    phyMod(-buffTotal[1])
    spdMod(-buffTotal[2])
    buffTotal = {0,0}
  end
end

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
          if input.isActionPressed(input.ACTION.Sneak) then
            if doBuff then
              -- apply fatigue cost
              local cfat = dynamic.fatigue(self).current
              if cfat >= fatigueCost then -- only do buff if enough fatigue for it
                doBuff = false
                dynamic.fatigue(self).current = cfat - fatigueCost
                -- apply buff
                phyMod(buffArmor)
                spdMod(buffSpeed)
                buffTotal[1] = buffTotal[1] + buffArmor
                buffTotal[2] = buffTotal[2] + buffSpeed
          
				if verbose then
					ui.showMessage('DODGE!')
				end
		  
                -- start release timer
                async:newUnsavableSimulationTimer(
                buffDuration,
                function()
					phyMod(-buffTotal[1])
					spdMod(-buffTotal[2])
                  buffTotal = {0,0}
                  doBuff = true
                end
                )
              end
            end
          end
        end
      end
    end
  } 
}