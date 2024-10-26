local self = require('openmw.self')
local Core = require('openmw.core')
local Ui = require('openmw.ui')
local Input = require('openmw.input')
local Types = require('openmw.types')
local Async = require('openmw.async')
local Interface = require("openmw.interfaces")
local Ambient = require('openmw.ambient')
local Storage = require('openmw.storage')

Interface.Settings.registerPage({
   key = 'ChargeTimeWeaponBuff',
   l10n = 'ChargeTimeWeaponBuff',
   name = "Maxar's Charge Time Weapon Buff",
   description = 'Settings for weapon skill buff based on charge time',
})

local isFeatureEnabled = true
local isMessageEnabled = true
local isSoundEnabled = true
local messageDuration = 1.0 -- How long to show the message, in seconds
local baseBuffIncreaseInterval = 0.05 -- Base time to increase the buff (in seconds)
local statSpeedPower = 0.02
local statBaseSpeedPower = 0.0
local buffIncrementValue = 1 -- How much to increase the buff each tick
local gracePeriod = 0.05 -- 5% grace period for
local includeHandToHand = true -- Include hand-to-hand in weapon check
local includeRangedWeapons = true -- Include ranged weapons in weapon check

local usePreset = false
local selectedPreset = 'smooth'

Interface.Settings.registerGroup({
  key = 'Settings_ChargeTimeWeaponBuff',
  page = 'ChargeTimeWeaponBuff',
  l10n = 'ChargeTimeWeaponBuff',
  name = 'Settings',
  permanentStorage = true,
  settings = {
     {
        key = 'isFeatureEnabled',
        default = isFeatureEnabled,
        renderer = 'checkbox',
        name = 'Enable Charge Time Weapon Buff',
        description = 'Toggles the weapon skill buff feature based on charge time',
     },
     {
       key = 'isSoundEnabled',
       default = isSoundEnabled,
       renderer = 'checkbox',
       name = 'Enable Sound Effects',
       description = 'Toggles sound effects associated with the charge time feature',
     },
     {
       key = 'isMessageEnabled',
       default = isMessageEnabled,
       renderer = 'checkbox',
       name = 'Enable Messages',
       description = 'Toggles display of performance messages after charging',
     },
     {
       key = 'messageDuration',
       default = messageDuration,
       renderer = 'number',
       name = 'Message Display Duration',
       description = 'Sets how long performance messages are displayed (in seconds)',
       argument = {
          min = 0.5,
          max = 10.0,
       },
     },
     {
       key = 'includeHandToHand',
       default = includeHandToHand,
       renderer = 'checkbox',
       name = 'Include Hand-to-Hand',
       description = 'Applies the charge time buff to hand-to-hand combat',
     },
     {
       key = 'includeRangedWeapons',
       default = includeRangedWeapons,
       renderer = 'checkbox',
       name = 'Include Ranged Weapons',
       description = 'Applies the charge time buff to ranged weapons',
     },
     {
        key = 'baseBuffIncreaseInterval',
        default = baseBuffIncreaseInterval,
        renderer = 'number',
        name = 'Buff Increase Interval',
        description = 'Sets the base time interval for increasing the buff (in seconds).',
        argument = {
           min = 0.01,
           max = 5.0,
        },
     },
     {
        key = 'buffIncrementValue',
        default = buffIncrementValue,
        renderer = 'number',
        name = 'Buff Increment Amount',
        description = 'Sets the amount to increase the buff by each interval',
        argument = {
          integer = true,
          min = 1.0,
          max = 5.0,
        },
     },
     {
        key = 'gracePeriod',
        default = gracePeriod,
        renderer = 'number',
        name = 'Grace Period',
        description = 'Sets the grace period for the optimal charge time (in seconds)',
        argument = {
           min = 0.0,
           max = 1.0,
        },
     },
     {
      key = 'statSpeedPower',
      default = statSpeedPower,
      renderer = 'number',
      name = 'Stat Speed Power',
      description = 'Bigger - faster buff increase, smaller - slower buff increase (0.001 - 0.1)',
      argument = {
         min = 0.001,
         max = 0.1,
      },
      },
      {
        key = 'statBaseSpeedPower',
        default = statBaseSpeedPower,
        renderer = 'number',
        name = 'Stat Base Speed Power',
        description = 'Its for balancing stat speed power influence, increase it and decrease statSpeedPower (0.0 - 2.0)',
        argument = {
           min = 0.0,
           max = 2.0,
        },
      },
     {
      key = 'usePreset',
      default = true,
      renderer = 'checkbox',
      name = 'Apply preset.',
      description = 'Press "yes" to apply preset configuration',
    },
    {
      key = 'selectedPreset',
      default = 'smooth',
      renderer = 'select',
      name = 'Preset',
      description = 'Select preset configuration',
      argument = {
        l10n = 'BuffApplicationStyle',
        items = {'smooth', 'stepped'}
      }
    }
  },
})
local settingsGroup = Storage.playerSection('Settings_ChargeTimeWeaponBuff')

local function updateSettingsFromStorage()
  isFeatureEnabled = settingsGroup:get('isFeatureEnabled')
  isMessageEnabled = settingsGroup:get('isMessageEnabled')
  messageDuration = settingsGroup:get('messageDuration')
  baseBuffIncreaseInterval = settingsGroup:get('baseBuffIncreaseInterval')
  buffIncrementValue = settingsGroup:get('buffIncrementValue')
  includeHandToHand = settingsGroup:get('includeHandToHand')
  includeRangedWeapons = settingsGroup:get('includeRangedWeapons')
  isSoundEnabled = settingsGroup:get('isSoundEnabled')
  gracePeriod = settingsGroup:get('gracePeriod')
  statSpeedPower = settingsGroup:get('statSpeedPower')
  statBaseSpeedPower = settingsGroup:get('statBaseSpeedPower')

  usePreset = settingsGroup:get('usePreset')
  selectedPreset = settingsGroup:get('selectedPreset')
end

local function checkButton(delta)
  if Interface.UI.getMode() == nil then return end

  if not usePreset then
    if selectedPreset == 'smooth' then
      settingsGroup:set('baseBuffIncreaseInterval', 0.07)
      settingsGroup:set('buffIncrementValue', 1)
      settingsGroup:set('gracePeriod', 0.05)
      settingsGroup:set('statSpeedPower', 0.02)
      settingsGroup:set('statBaseSpeedPower', 0.0)
    elseif selectedPreset == 'stepped' then
      settingsGroup:set('baseBuffIncreaseInterval', 0.25)
      settingsGroup:set('buffIncrementValue', 3)
      settingsGroup:set('gracePeriod', 0.0)
      settingsGroup:set('statSpeedPower', 0.02)
      settingsGroup:set('statBaseSpeedPower', 0.0)
    end
    settingsGroup:set('usePreset', true)
    updateSettingsFromStorage()
  end
end

local function initializeSettings()
    updateSettingsFromStorage()
end
settingsGroup:subscribe(Async:callback(updateSettingsFromStorage))

local function isWeaponEquipped()
  local isWeaponInHand = false
  if Types.Actor.stance(self) == Types.Actor.STANCE.Weapon then
    local equippedWeapon = Types.Actor.equipment(self, Types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if (not equippedWeapon) then -- hand-to-hand
      isWeaponInHand = includeHandToHand
    else
      if not Types.Lockpick.objectIsInstance(equippedWeapon) and not Types.Probe.objectIsInstance(equippedWeapon) then
        local weaponType = Types.Weapon.record(equippedWeapon).type
        if (weaponType < 9) then -- melee weapon
          isWeaponInHand = true
        elseif (weaponType <= 13) then -- ranged weapon
          isWeaponInHand = includeRangedWeapons
        elseif (weaponType > 13) then -- unknown weapon
          isWeaponInHand = true
        end
      end
    end 
  end
  return(isWeaponInHand)
end

local function getPlayerWepaonSpeed()
  local equippedWeapon = Types.Actor.equipment(self, Types.Actor.EQUIPMENT_SLOT.CarriedRight)
  if equippedWeapon then
    return Types.Weapon.record(equippedWeapon).speed
  else
    return 1.0
  end
end

local function getEquippedWeaponType()
  local equippedWeapon = Types.Actor.equipment(self, Types.Actor.EQUIPMENT_SLOT.CarriedRight)
  if equippedWeapon then
    return Types.Weapon.record(equippedWeapon).type
  else
    return nil -- Hand-to-hand
  end
end

local function getRelevantWeaponSkill(weaponType)
  if weaponType == nil then
    return Types.NPC.stats.skills.handtohand
  elseif weaponType == Types.Weapon.TYPE.ShortBladeOneHand then
    return Types.NPC.stats.skills.shortblade
  elseif weaponType == Types.Weapon.TYPE.LongBladeOneHand or weaponType == Types.Weapon.TYPE.LongBladeTwoHand then
    return Types.NPC.stats.skills.longblade
  elseif weaponType == Types.Weapon.TYPE.BluntOneHand or weaponType == Types.Weapon.TYPE.BluntTwoClose or weaponType == Types.Weapon.TYPE.BluntTwoWide then
    return Types.NPC.stats.skills.bluntweapon
  elseif weaponType == Types.Weapon.TYPE.AxeOneHand or weaponType == Types.Weapon.TYPE.AxeTwoHand then
    return Types.NPC.stats.skills.axe
  elseif weaponType == Types.Weapon.TYPE.SpearTwoWide then
    return Types.NPC.stats.skills.spear
  elseif weaponType == Types.Weapon.TYPE.MarksmanBow or weaponType == Types.Weapon.TYPE.MarksmanCrossbow or weaponType == Types.Weapon.TYPE.MarksmanThrown then
    return Types.NPC.stats.skills.marksman
  else
    return nil
  end
end


local isWeaponCharging = false
local chargeStartTime = 0
local currentBuffValue = 0
local activeWeaponSkill = nil
local lastBuffApplicationTime = 0

local weaponSkills = {
  Types.NPC.stats.skills.shortblade,
  Types.NPC.stats.skills.longblade,
  Types.NPC.stats.skills.axe,
  Types.NPC.stats.skills.bluntweapon,
  Types.NPC.stats.skills.spear,
  Types.NPC.stats.skills.marksman,
  Types.NPC.stats.skills.handtohand
}
local function calculateMaximalBuffValue()
  local maximumBuffValue = 0
  for _, weaponSkill in pairs(weaponSkills) do
    maximumBuffValue = maximumBuffValue + weaponSkill(self).base / 5
  end

  return math.floor(maximumBuffValue + 0.5)
end

local function calculateSpeedMultiplier()
  local playerAgility = Types.Actor.stats.attributes.agility(self).modified
  local multiplier = (playerAgility * getPlayerWepaonSpeed() * statSpeedPower) + statBaseSpeedPower
  return math.max(0.5, math.min(10, multiplier)) -- Clamp between 0.5 and 2
end

local function applyWeaponSkillBuff(buffAmount)
  if activeWeaponSkill then
    activeWeaponSkill(self).modifier = activeWeaponSkill(self).modifier + buffAmount
    currentBuffValue = currentBuffValue + buffAmount
  end
end

local function removeWeaponSkillBuff()
  if activeWeaponSkill and currentBuffValue > 0 then
    activeWeaponSkill(self).modifier = activeWeaponSkill(self).modifier - currentBuffValue
    currentBuffValue = 0
  end
end

local function startCharging(currentSimulationTime)
  if currentBuffValue > 0 then
    removeWeaponSkillBuff()
  end

  isWeaponCharging = true
  chargeStartTime = currentSimulationTime
  lastBuffApplicationTime = currentSimulationTime
  local weaponType = getEquippedWeaponType()
  activeWeaponSkill = getRelevantWeaponSkill(weaponType)
  currentBuffValue = 0
end

local function calculateOptimalChargeTime(multiplier, maxBuffValue)
  local adjustedBuffIncreaseInterval = baseBuffIncreaseInterval / multiplier
  local ticksToMaxBuff = maxBuffValue / buffIncrementValue
  return ticksToMaxBuff * adjustedBuffIncreaseInterval
end

local function isTickTime(currentTime, lastTime, interval)
  return currentTime - lastTime >= interval
end

local function updateChargingBuff(currentSimulationTime, deltaTime)
  local chargeTime = currentSimulationTime - chargeStartTime
  local speedMultiplier = math.max(0.5, math.min(2, calculateSpeedMultiplier()))
  local maximumBuffValue = calculateMaximalBuffValue()
  local optimalChargeTime = calculateOptimalChargeTime(speedMultiplier, maximumBuffValue) * (1 + gracePeriod)  -- grace period

  if chargeTime <= optimalChargeTime then
      if isTickTime(currentSimulationTime, lastBuffApplicationTime, baseBuffIncreaseInterval / speedMultiplier) then
          local buffToApply = math.min(buffIncrementValue, maximumBuffValue - currentBuffValue)
          applyWeaponSkillBuff(buffToApply)
          lastBuffApplicationTime = currentSimulationTime
      end
  else
      if isTickTime(currentSimulationTime, lastBuffApplicationTime, baseBuffIncreaseInterval * speedMultiplier) then
          local newBuffValue = math.max(0, currentBuffValue - buffIncrementValue)
          local buffChange = newBuffValue - currentBuffValue
          applyWeaponSkillBuff(buffChange)
          lastBuffApplicationTime = currentSimulationTime
      end
  end
end

local perfect_params = {
  timeOffset=0,
  volume=1.0,
  scale=false,
  pitch=1.0,
  loop=false
};

local great_params = {
  timeOffset=0.1,
  volume=1.0,
  scale=false,
  pitch=1.0,
  loop=false
};

local good_params = {
  timeOffset=0.2,
  volume=1.0,
  scale=false,
  pitch=1.0,
  loop=false
};

local function finishCharging(currentSimulationTime)
  isWeaponCharging = false
  --print("Weapon speed: " .. getPlayerWepaonSpeed())
  --print("Optimal charge time: " .. calculateOptimalChargeTime(calculateSpeedMultiplier(), calculateMaximalBuffValue()))
  if activeWeaponSkill then
    local procent = currentBuffValue / calculateMaximalBuffValue()
    if procent > 0.9 then
      if isMessageEnabled then
        Ui.showMessage("Perfect.", messageDuration)
      end

      if isSoundEnabled then
        Ambient.playSoundFile("sound\\Perfect.mp3", perfect_params)
      end

    elseif procent > 0.7 then
      if isMessageEnabled then
        Ui.showMessage("Great.", messageDuration)
      end

      if isSoundEnabled then
        Ambient.playSoundFile("sound\\Perfect.mp3", great_params)
      end

    elseif procent > 0.5 then
      if isMessageEnabled then
        Ui.showMessage("Good.", messageDuration)
      end

      if isSoundEnabled then
        Ambient.playSoundFile("sound\\Perfect.mp3", good_params)
      end
      
    elseif procent > 0.25 then
      if isMessageEnabled then
        Ui.showMessage("Decent.", messageDuration)
      end
    end
    Async:newUnsavableSimulationTimer(0.2, removeWeaponSkillBuff)
  end
end

local function cancelCharging()
  isWeaponCharging = false
  removeWeaponSkillBuff()
end

return {
  engineHandlers = {
    onFrame = checkButton,
    onActive = initializeSettings,
    
    onUpdate = function(deltaTime)
      if Core.API_REVISION > 60 and Interface.UI.getMode() ~= nil then return end
      if not isFeatureEnabled then return end

      local isUseActionPressed = Input.isActionPressed(Input.ACTION.Use)
      local currentSimulationTime = Core.getSimulationTime()

      if isWeaponEquipped() then
        if isUseActionPressed and not isWeaponCharging then
          startCharging(currentSimulationTime)
        elseif isUseActionPressed and isWeaponCharging then
          updateChargingBuff(currentSimulationTime, deltaTime)
        elseif not isUseActionPressed and isWeaponCharging then
          finishCharging(currentSimulationTime)
        end
      elseif not isWeaponEquipped() and isWeaponCharging then
        cancelCharging()
      end
    end
  }
}