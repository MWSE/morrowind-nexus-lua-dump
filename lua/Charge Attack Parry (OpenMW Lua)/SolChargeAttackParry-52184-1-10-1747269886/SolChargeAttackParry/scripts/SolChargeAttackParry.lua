local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local ambient = require('openmw.ambient') -- 0.49 req

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
  key = 'SolChargeAttackParry',
  l10n = 'SolChargeAttackParry',
  name = 'name',
  description = 'description',
})
-- default values!
local enabled = true
local verbose = 0
local sfxVolume = 0.0
local hideChargePopup = true
local incRanged = true -- include ranged weapons ?
local buffControl = 0  -- 0 both, 1 DEF only, 2 AGI only
local buffBase = 2.0
local fatigueMult = 0.5
local tradeOffBase = 5.0
local doSpeedRelease = true
local maxCharge = 2.0
local buffDuration = 0.5
I.Settings.registerGroup({
  key = 'Settings_SolChargeAttackParry',
  page = 'SolChargeAttackParry',
  l10n = 'SolChargeAttackParry',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled', enabled),
    numbSetting('verbose', verbose, true, 0, 2),
    numbSetting('sfxVolume', sfxVolume, false, 0.0, 2.0),
    boolSetting('hideChargePopup', hideChargePopup),
    boolSetting('incRanged', incRanged),
    numbSetting('buffControl', buffControl, true, 0, 2),
    numbSetting('buffBase', buffBase, false, 0, 10),
    numbSetting('fatigueMult', fatigueMult, false, 0, 2),
    numbSetting('tradeOffBase', tradeOffBase, false, 0, 20),
    boolSetting('doSpeedRelease', doSpeedRelease),
    numbSetting('maxCharge', maxCharge, false, 1, 5),
    numbSetting('buffDuration', buffDuration, false, 0.25, 5),
  },
})

local settingsGroup = storage.playerSection('Settings_SolChargeAttackParry')

-- shorthand for convenience
local Weapon = types.Weapon
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- reduce effectiveness of hybrid stances
local function hybridVal(base, mult, count)
  return math.ceil(base * math.pow(mult, math.max(count, 0)))
end

-- script config
local modType = 1   --1 skill, -1 debug reset all stat modifiers
local incH2H = true -- include handtohand for heavy charged attacks?
-- if true, must define "weight" and "speed" values for h2h in buff/debuff fncs

-- and store stance idxs for indexing into tables
local stanceIndex = { charge = 1, release = 2 }
local maxStance = 0
for _ in pairs(stanceIndex) do
  maxStance = maxStance + 1
end

-- init to defaults
local stanceBuff = { -tradeOffBase, buffBase }
local stanceNames = { '', '' }
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  hideChargePopup = settingsGroup:get('hideChargePopup')
  verbose = settingsGroup:get('verbose')
  -- update verbose
  if verbose == 1 then
    stanceNames = { 'DEFENSE UP', 'AGILITY UP', 'CHARGE' }
  elseif verbose == 2 then
    stanceNames = { 'DEF+', 'AGI+', 'SPD ETC' }
  end
  sfxVolume = settingsGroup:get('sfxVolume')
  incRanged = settingsGroup:get('incRanged')
  buffControl = settingsGroup:get('buffControl')
  buffBase = settingsGroup:get('buffBase')
  fatigueMult = settingsGroup:get('fatigueMult')
  tradeOffBase = settingsGroup:get('tradeOffBase')
  -- calculate new buff vals
  stanceBuff = { -tradeOffBase, buffBase }
  doSpeedRelease = settingsGroup:get('doSpeedRelease')
  maxCharge = settingsGroup:get('maxCharge')
  buffDuration = settingsGroup:get('buffDuration')
end
local function init()
  updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- stance effects
local function chargeMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.speed(self).modifier = math.max(0, attributes.speed(self).modifier + modSign * math.ceil(0.5 * modVal))
    -- do athletics and acrobatics with speed, but give them each half impact
    skills.athletics(self).modifier = math.max(0, skills.athletics(self).modifier + modSign * math.ceil(0.5 * modVal))
    skills.acrobatics(self).modifier = math.max(0, skills.acrobatics(self).modifier + modSign * math.ceil(0.5 * modVal))
    skills.heavyarmor(self).modifier = math.max(0, skills.heavyarmor(self).modifier + modSign * modVal)
    skills.lightarmor(self).modifier = math.max(0, skills.lightarmor(self).modifier + modSign * modVal)
    skills.mediumarmor(self).modifier = math.max(0, skills.mediumarmor(self).modifier + modSign * modVal)
    skills.unarmored(self).modifier = math.max(0, skills.unarmored(self).modifier + modSign * modVal)
  else
    modVal = math.abs(modVal)
    attributes.speed(self).damage = math.max(0, attributes.speed(self).damage + modSign * math.ceil(0.5 * modVal))
    -- do athletics and acrobatics with speed, but give them each half impact
    skills.athletics(self).damage = math.max(0, skills.athletics(self).damage + modSign * math.ceil(0.5 * modVal))
    skills.acrobatics(self).damage = math.max(0, skills.acrobatics(self).damage + modSign * math.ceil(0.5 * modVal))
    skills.heavyarmor(self).damage = math.max(0, skills.heavyarmor(self).damage + modSign * modVal)
    skills.lightarmor(self).damage = math.max(0, skills.lightarmor(self).damage + modSign * modVal)
    skills.mediumarmor(self).damage = math.max(0, skills.mediumarmor(self).damage + modSign * modVal)
    skills.unarmored(self).damage = math.max(0, skills.unarmored(self).damage + modSign * modVal)
  end
end

local function releaseMod(modSign, modVal, buffType)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    if doSpeedRelease then
      -- if debuff speed on release
      attributes.speed(self).damage = math.max(0, attributes.speed(self).damage + tradeOffBase * modSign * modVal)
      -- do athletics and acrobatics with speed, but give them each half impact
      skills.athletics(self).damage = math.max(0, skills.athletics(self).damage + tradeOffBase * modSign * modVal)
      skills.acrobatics(self).damage = math.max(0, skills.acrobatics(self).damage + tradeOffBase * modSign * modVal)
    end
    --normal
    if buffType == 1 then
      skills.heavyarmor(self).modifier = math.max(0, skills.heavyarmor(self).modifier + modSign * modVal)
      skills.lightarmor(self).modifier = math.max(0, skills.lightarmor(self).modifier + modSign * modVal)
      skills.mediumarmor(self).modifier = math.max(0, skills.mediumarmor(self).modifier + modSign * modVal)
      skills.unarmored(self).modifier = math.max(0, skills.unarmored(self).modifier + modSign * modVal)
    else
      attributes.agility(self).modifier = math.max(0, attributes.agility(self).modifier + modSign * modVal)
      -- offset agility by willpower to keep max fatigue constant
      attributes.willpower(self).damage = math.max(0, attributes.willpower(self).damage + modSign * modVal)
    end
  else -- if negative effect, then damage
    modVal = math.abs(modVal)
    if doSpeedRelease then
      -- if debuff speed on release
      attributes.speed(self).modifier = math.max(0, attributes.speed(self).modifier + tradeOffBase * modSign * modVal)
      -- do athletics and acrobatics with speed, but give them each half impact
      skills.athletics(self).modifier = math.max(0, skills.athletics(self).modifier + tradeOffBase * modSign * modVal)
      skills.acrobatics(self).modifier = math.max(0, skills.acrobatics(self).modifier + tradeOffBase * modSign * modVal)
    end
    --normal
    if buffType == 1 then
      skills.heavyarmor(self).damage = math.max(0, skills.heavyarmor(self).damage + modSign * modVal)
      skills.lightarmor(self).damage = math.max(0, skills.lightarmor(self).damage + modSign * modVal)
      skills.mediumarmor(self).damage = math.max(0, skills.mediumarmor(self).damage + modSign * modVal)
      skills.unarmored(self).damage = math.max(0, skills.unarmored(self).damage + modSign * modVal)
    else
      attributes.agility(self).damage = math.max(0, attributes.agility(self).damage + modSign * modVal)
      -- offset agility by willpower to keep max fatigue constant
      attributes.willpower(self).modifier = math.max(0, attributes.willpower(self).modifier + modSign * modVal)
    end
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local chargeBuffTotal = {}
for i = 1, maxStance, 1 do
  chargeBuffTotal[i] = 0
end
local buffType = 0

local function weaponCheck()
  local isWeapon = false
  if types.Actor.stance(self) == types.Actor.STANCE.Weapon then
    local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if (not usedWeapon) then -- handtohand
      isWeapon = incH2H
    else
      if not types.Lockpick.objectIsInstance(usedWeapon) and not types.Probe.objectIsInstance(usedWeapon) then
        local weaponType = Weapon.record(usedWeapon).type
        if (weaponType < 9) then       -- melee weapon
          isWeapon = true
        elseif (weaponType <= 13) then -- ranged weapon
          isWeapon = incRanged
        elseif (weaponType > 13) then  -- unknown weapon
          isWeapon = true
        end
      end
    end
  end
  return (isWeapon)
end

local function getChargeMod()
  -- get relevant stats
  local strength = attributes.strength(self).modified
  local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  local weapWeight = 1
  if not (not usedWeapon) then -- NOT handtohand
    weapWeight = Weapon.record(usedWeapon).weight
  end
  -- setup mod
  --local buffMod = (1 + math.sqrt(weapWeight))*(50/strength)
  --local buffMod = (1 + math.sqrt(weapWeight))*math.max(0,(2.5-(strength/50)))
  local buffMod = (1 + math.sqrt(weapWeight)) * (100 / (strength + 50))
  -- mod up as weapon weight up, with minimum
  -- mod down as strength up
  return (buffMod)
end

local function getReleaseMod(chargeTime)
  -- get relevant stats
  local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  local weapSpeed = 1
  local weapWeight = 1
  if not (not usedWeapon) then -- NOT handtohand
    weapSpeed = Weapon.record(usedWeapon).speed
    weapWeight = Weapon.record(usedWeapon).weight
  end
  -- setup mod
  local buffMod = (1 + math.sqrt(weapWeight)) * math.min(maxCharge, (chargeTime * weapSpeed)) --/weapSpeed
  -- mod up as weapon weight up, with minimum
  -- mod up as charge increases, vs weapon speed
  -- mod up as weapon speed up?
  return (buffMod)
end

local function getMaxTime()
  local weapSpeed = 1
  local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  if not (not usedWeapon) then -- NOT handtohand
    weapSpeed = Weapon.record(usedWeapon).speed
  end
  -- setup mod
  local maxTime = maxCharge / weapSpeed
  return (maxTime)
end

-- save state to be removed on load
local function onSave()
  return {
    chargeBuffTotal = chargeBuffTotal,
    buffType = buffType
  }
end
local function onLoad(data)
  if data then
    chargeBuffTotal = data.chargeBuffTotal
    buffType = data.buffType
    chargeMod(-1, chargeBuffTotal[1])
    releaseMod(-1, chargeBuffTotal[2], buffType)
    for i = 1, maxStance, 1 do
      chargeBuffTotal[i] = 0
    end
  end
end

local chargeTime = 0
local doBuff = false
local isCharge = false -- true if trigger input action
local isWeapon = false
local maxTime = 0.0
local doPlaySound = false
return {
  engineHandlers = {
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,

    onUpdate = function(dt)
      if enabled then
        local isUse = input.isActionPressed(input.ACTION.Use)

        if isUse and not isCharge then -- on first frame you hit use
          --        if isUse and not isCharge and not types.Actor.isOnGround(self) then -- on first frame you hit use
          isCharge = true              -- update stance
          isWeapon = weaponCheck()
          -- apply charge debuff
          if isWeapon then
            chargeTime = core.getSimulationTime() -- set timer value
            local buffNext = hybridVal(stanceBuff[1], getChargeMod(), 1)
            chargeMod(1, buffNext)
            chargeBuffTotal[1] = chargeBuffTotal[1] + buffNext
            if verbose > 0 and not hideChargePopup then
              ui.showMessage(stanceNames[3] .. ' ' .. tostring(chargeBuffTotal[1]))
            end

            -- extra calculation to figure out max allowed charge time for sound effect only
            if ambient and (sfxVolume > 0.0) then
              maxTime = getMaxTime() - 0.4
              doPlaySound = true
            end
          end
        elseif isUse and isCharge then -- while charging  
          if ambient and doPlaySound and (sfxVolume > 0.0) then
            if (core.getSimulationTime() - chargeTime) >= maxTime then
              doPlaySound = false
              --ambient.playSoundFile("sound/fx/envrn/heart.wav", { timeOffset = 4.0, volume = (1.5 * sfxVolume), pitch = (1.5 + 0.1 * math.random()) })
              ambient.playSoundFile("sound/SolWeightyChargeAttacks/solHeart.wav", { volume = (0.7 * sfxVolume), pitch = (1.5 + 0.1 * math.random()) })
            end
          end
        elseif not isUse and isCharge then -- on first frame you release use
          isCharge = false
          -- remove charge debuff
          chargeMod(-1, chargeBuffTotal[1])
          chargeBuffTotal[1] = 0
          if isWeapon and chargeBuffTotal[2] == 0 then         -- only buff if unbuffed
            chargeTime = core.getSimulationTime() - chargeTime -- get timer value
            -- buff DEFENSE or Agility depending on movement and config val
            local mf = self.controls.movement
            local ms = self.controls.sideMovement
            local ig = types.Actor.isOnGround(self)
            local is = types.Actor.isSwimming(self)
            local moveType = 0
            if (ig or is) and mf == -1 then                -- backwards component
              moveType = 1                                 -- def
            elseif (ig or is) and mf == 0 and ms ~= 0 then -- sideways only
              moveType = 2                                 -- agi
            end
            if moveType > 0 then
              doBuff = true
            else
              doBuff = false
            end

            if doBuff then
              -- get release buff
              local buffNext = hybridVal(stanceBuff[2], getReleaseMod(chargeTime), 1)
              -- fatigue cost
              local cfat = dynamic.fatigue(self).current
              local strength = attributes.strength(self).modified
              local fatigueCost = math.ceil(fatigueMult * buffNext * 100 / (strength + 50))
              dynamic.fatigue(self).current = math.max(0, cfat - fatigueCost)
              -- determine what you're buffing
              if buffControl == 0 then
                if moveType == 1 then
                  buffType = 1 -- def
                elseif moveType == 2 then
                  buffType = 2 -- agi
                end
              else
                buffType = buffControl
              end
              -- apply buff
              releaseMod(1, buffNext, buffType)
              chargeBuffTotal[2] = chargeBuffTotal[2] + buffNext
              -- status info
              if verbose > 0 then
                local buffMax = hybridVal(stanceBuff[2], getReleaseMod(maxCharge), 1)
                if buffType == 1 then
                  ui.showMessage(stanceNames[1] .. ' ' .. tostring(chargeBuffTotal[2]) .. ' / ' .. tostring(buffMax))
                else
                  ui.showMessage(stanceNames[2] .. ' ' .. tostring(chargeBuffTotal[2]) .. ' / ' .. tostring(buffMax))
                end
              end
              -- start release timer
              async:newUnsavableSimulationTimer(
                buffDuration,
                function()
                  releaseMod(-1, chargeBuffTotal[2], buffType)
                  chargeBuffTotal[2] = 0
                end
              )
            end
          end
        end
      end
    end
  }
}
