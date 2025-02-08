local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')

-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
  key = 'SolSneakJumpDodge',
  l10n = 'SolSneakJumpDodge',
  name = 'name',
  description = 'description',
})

-- default values!
local enabled = true
local verbose = true -- 0 none, 1 stance name, 2 stance stats, 3 consoleDebugInfo
local allowInAir = false
local buffArmor = 10000
local buffSpeed = 500
local fatigueCost = 50
local buffDuration = 0.5
local jumpBuff = true
I.Settings.registerGroup({
  key = 'Settings_SolSneakJumpDodge',
  page = 'SolSneakJumpDodge',
  l10n = 'SolSneakJumpDodge',
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
      key = 'allowInAir',
      default = allowInAir,
      renderer = 'checkbox',
      name = 'allowInAir_name',
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
    {
      key = 'jumpBuff',
      default = jumpBuff,
      renderer = 'checkbox',
      name = 'jumpBuff_name',
      description = 'jumpBuff_description',
    },
  },
})
local settingsGroup = storage.playerSection('Settings_SolSneakJumpDodge')

-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  allowInAir = settingsGroup:get('allowInAir')
  buffArmor = settingsGroup:get('buffArmor')
  buffSpeed = settingsGroup:get('buffSpeed')
  fatigueCost = settingsGroup:get('fatigueCost')
  buffDuration = settingsGroup:get('buffDuration')
  jumpBuff = settingsGroup:get('jumpBuff')
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
local function phyMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    skills.heavyarmor(self).modifier = math.max(0, skills.heavyarmor(self).modifier + modSign * modVal)
    skills.lightarmor(self).modifier = math.max(0, skills.lightarmor(self).modifier + modSign * modVal)
    skills.mediumarmor(self).modifier = math.max(0, skills.mediumarmor(self).modifier + modSign * modVal)
    skills.unarmored(self).modifier = math.max(0, skills.unarmored(self).modifier + modSign * modVal)
  else
    modVal = math.abs(modVal)
    skills.heavyarmor(self).damage = math.max(0, skills.heavyarmor(self).damage + modSign * modVal)
    skills.lightarmor(self).damage = math.max(0, skills.lightarmor(self).damage + modSign * modVal)
    skills.mediumarmor(self).damage = math.max(0, skills.mediumarmor(self).damage + modSign * modVal)
    skills.unarmored(self).damage = math.max(0, skills.unarmored(self).damage + modSign * modVal)
  end
end
local function spdMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.speed(self).modifier = math.max(0, attributes.speed(self).modifier + modSign * modVal)
    attributes.agility(self).modifier = math.max(0, attributes.agility(self).modifier + modSign * modVal)
  else
    modVal = math.abs(modVal)
    attributes.speed(self).damage = math.max(0, attributes.speed(self).damage + modSign * modVal)
    attributes.agility(self).damage = math.max(0, attributes.agility(self).damage + modSign * modVal)
  end
end
local function jmpMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    skills.acrobatics(self).modifier = math.max(0, skills.acrobatics(self).modifier + modSign * modVal)
  else
    modVal = math.abs(modVal)
    skills.acrobatics(self).damage = math.max(0, skills.acrobatics(self).damage + modSign * modVal)
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local buffTotal = { 0, 0 }
local jumpTotal = 0
-- save state to be removed on load
local function onSave()
  return {
    buffTotal = buffTotal,
    jumpTotal = jumpTotal
  }
end
local function onLoad(data)
  if data then
    -- demod dodge state
    buffTotal = data.buffTotal
    phyMod(-1, buffTotal[1])
    spdMod(-1, buffTotal[2])
    buffTotal = { 0, 0 }
    -- demod jump state
    jumpTotal = data.jumpTotal
    jmpMod(-1, jumpTotal)
    jumpTotal = 0
  end
end

local isSneak = true -- init
local sneakTimer = 0.0
local jumpTimer = 0.0
local doJumpBuff = false

local cfat = 0
local doBuff = true
return {
  engineHandlers = {
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,

    onUpdate = function(dt)
      isSneak = self.controls.sneak                         -- 0.49 sneak check
      if isSneak == nil then
        isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check
      end
      if not doBuff then                                    -- if stop sneaking when currently buffed, debuff
        if not isSneak then
          phyMod(-1, buffTotal[1])
          spdMod(-1, buffTotal[2])
          buffTotal = { 0, 0 }
          doBuff = true
        end
      end

      if jumpBuff then -- if doing jumpbuff then keep track of timers
        if isSneak and types.Actor.isOnGround(self) then -- must be on ground to charge buff... should you also need to stop moving?
          if not doJumpBuff then -- only check sneak timer if not already ready for jump buff
            sneakTimer = sneakTimer + dt
            if sneakTimer > 1.0 then -- if sneak long enough, ready jump buff
              doJumpBuff = true
              if verbose then
                ui.showMessage('Jump Buff Ready')
              end
            end
          end
        else
          sneakTimer = 0.0
          if doJumpBuff then
            jumpTotal = skills.acrobatics(self).base
            jmpMod(1, jumpTotal)
            doJumpBuff = false

            -- start release timer
            async:newUnsavableSimulationTimer(
              buffDuration,
              function()
                jmpMod(-1, jumpTotal)
                jumpTotal = 0
              end
            )
          end
        end
      end
    end,

    onInputAction = function(id)
      if enabled then
        if id == input.ACTION.Jump then
          if not allowInAir and not types.Actor.isOnGround(self) then
            isSneak = false
          end

          if isSneak then
            if doBuff then
              -- apply fatigue cost
              cfat = dynamic.fatigue(self).current
              if cfat >= fatigueCost then -- only do buff if enough fatigue for it
                doBuff = false
                dynamic.fatigue(self).current = cfat - fatigueCost
                -- apply buff
                phyMod(1, buffArmor)
                spdMod(1, buffSpeed)
                buffTotal[1] = buffTotal[1] + buffArmor
                buffTotal[2] = buffTotal[2] + buffSpeed

                if verbose then
                  ui.showMessage('DODGE!')
                end

                -- start release timer
                async:newUnsavableSimulationTimer(
                  buffDuration,
                  function()
                    phyMod(-1, buffTotal[1])
                    spdMod(-1, buffTotal[2])
                    buffTotal = { 0, 0 }
                    doBuff = true
                  end
                )
              end
            end
          end
        end
      end
    end,
  }
}
