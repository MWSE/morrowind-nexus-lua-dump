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
  key = 'SolSneakJumpDodge',
  l10n = 'SolSneakJumpDodge',
  name = 'name',
  description = 'description',
})
-- default values!
local enabled = true
local verbose = false
local sfxVolume = 1.0
local allowInAir = false
local buffArmor = 1000
local buffSpeed = 500
local fatigueCost = 50
local buffDuration = 0.35
local jumpBuff = true
local soundNotif = true
I.Settings.registerGroup({
  key = 'Settings_SolSneakJumpDodge',
  page = 'SolSneakJumpDodge',
  l10n = 'SolSneakJumpDodge',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled', enabled),
    boolSetting('verbose', verbose),
    numbSetting('sfxVolume', sfxVolume, false, 0.0, 2.0),
    boolSetting('allowInAir', allowInAir),
    numbSetting('buffArmor', buffArmor, true, 1, 10000),
    numbSetting('buffSpeed', buffSpeed, true, 1, 1000),
    numbSetting('fatigueCost', fatigueCost, true, 0, 100),
    numbSetting('buffDuration', buffDuration, false, 0.1, 5),
    boolSetting('jumpBuff', jumpBuff),
    boolSetting('soundNotif', soundNotif),
  },
})
local settingsGroup = storage.playerSection('Settings_SolSneakJumpDodge')

-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  sfxVolume = settingsGroup:get('sfxVolume')
  allowInAir = settingsGroup:get('allowInAir')
  buffArmor = settingsGroup:get('buffArmor')
  buffSpeed = settingsGroup:get('buffSpeed')
  fatigueCost = settingsGroup:get('fatigueCost')
  buffDuration = settingsGroup:get('buffDuration')
  jumpBuff = settingsGroup:get('jumpBuff')
  soundNotif = settingsGroup:get('soundNotif')
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
    if jumpTotal then
      jmpMod(-1, jumpTotal)
    end
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
      if enabled then
        isSneak = self.controls.sneak                       -- 0.49 sneak check
        if isSneak == nil then
          isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check
        end
        if not doBuff then                                  -- if stop sneaking when currently buffed, debuff
          if not isSneak then
            phyMod(-1, buffTotal[1])
            spdMod(-1, buffTotal[2])
            buffTotal = { 0, 0 }
            doBuff = true
          end
        end

        if jumpBuff then                                 -- if doing jumpbuff then keep track of timers
          if isSneak and types.Actor.isOnGround(self) then -- must be on ground to charge buff... should you also need to stop moving?
            if not doJumpBuff then                       -- only check sneak timer if not already ready for jump buff
              sneakTimer = sneakTimer + dt
              if sneakTimer > 1.0 then                   -- if sneak long enough, ready jump buff
                doJumpBuff = true
                if ambient and (sfxVolume > 0.0) and soundNotif then
                  ambient.playSoundFile("sound/fx/foot/land_md.wav",{volume=(0.7*sfxVolume), pitch=(1.2 + 0.1*math.random())})
                end
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
                1.5*buffDuration,
                function()
                  jmpMod(-1, jumpTotal)
                  jumpTotal = 0
                end
              )
            end
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
                if not debug.isGodMode() then
                  dynamic.fatigue(self).current = cfat - fatigueCost
                end
                -- apply buff
                phyMod(1, buffArmor)
                spdMod(1, buffSpeed)
                buffTotal[1] = buffTotal[1] + buffArmor
                buffTotal[2] = buffTotal[2] + buffSpeed

                if ambient and (sfxVolume > 0.0) then
                  ambient.playSound("torch out",{volume=(1.0*sfxVolume), pitch=(0.7 + 0.1*math.random())})
                end
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
