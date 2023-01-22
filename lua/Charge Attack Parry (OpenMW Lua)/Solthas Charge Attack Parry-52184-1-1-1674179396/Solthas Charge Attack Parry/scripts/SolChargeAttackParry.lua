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
   key = 'SolChargeAttackParry',
   l10n = 'SolChargeAttackParry',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local verbose = true
local buffControl = 0 -- 0 both, 1 DEF only, 2 AGI only
local buffBase = 2
local tradeOffBase = 5
local maxCharge = 2
local buffDuration = 1
I.Settings.registerGroup({
   key = 'Settings_SolChargeAttackParry',
   page = 'SolChargeAttackParry',
   l10n = 'SolChargeAttackParry',
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
         description = 'verbose_description',
      },
      {
         key = 'buffControl',
         default = buffControl,
         renderer = 'number',
         name = 'buffControl_name',
         description = 'buffControl_description',
         argument = {
            integer = true,
            min = 0,
            max = 2,
         },
      },
      {
         key = 'buffBase',
         default = buffBase,
         renderer = 'number',
         name = 'buffBase_name',
         description = 'buffBase_description',
         argument = {
            min = 0,
            max = 10,
         },
      },
      {
         key = 'tradeOffBase',
         default = tradeOffBase,
         renderer = 'number',
         name = 'tradeOffBase_name',
         description = 'tradeOffBase_description',
         argument = {
            min = 0,
            max = 20,
         },
      },
      {
         key = 'maxCharge',
         default = maxCharge,
         renderer = 'number',
         name = 'maxCharge_name',
         description = 'maxCharge_description',
         argument = {
            min = 1,
            max = 5,
         },
      },
      {
         key = 'buffDuration',
         default = buffDuration,
         renderer = 'number',
         name = 'buffDuration_name',
         description = 'buffDuration_description',
         argument = {
            min = 1,
            max = 5,
         },
      },
   },
})

local settingsGroup = storage.playerSection('Settings_SolChargeAttackParry')

-- shorthand for convenience
local Weapon = types.Weapon
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills

-- reduce effectiveness of hybrid stances
local function hybridVal(base,mult,count)
    return math.ceil(base*math.pow(mult,math.max(count,0)))
end

-- script config
local modType = 1 --1 skill, -1 debug reset all stat modifiers
local incH2H = true -- include handtohand for heavy charged attacks?
  -- if true, must define "weight" and "speed" values for h2h in buff/debuff fncs
local incRanged = true -- include ranged weapons for heavy charged attacks?

-- and store stance idxs for indexing into tables
local stanceIndex = {charge=1, release=2}
local maxStance = 0
for _ in pairs(stanceIndex) do
  maxStance = maxStance + 1
end

-- init to defaults
local stanceBuff = {-tradeOffBase,buffBase}
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  buffControl = settingsGroup:get('buffControl')
  buffBase = settingsGroup:get('buffBase')
  tradeOffBase = settingsGroup:get('tradeOffBase')
  maxCharge = settingsGroup:get('maxCharge')
  buffDuration = settingsGroup:get('buffDuration')
  -- calculate new buff vals
    stanceBuff = {-tradeOffBase,buffBase}
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- debug case... resetting all relevant modifiers
if modType == -1 then
  -- damage -- this really shouldn't be needed
  skills.heavyarmor(self).damage = 0
  skills.lightarmor(self).damage = 0
  skills.mediumarmor(self).damage = 0
  skills.unarmored(self).damage = 0
  -- modifiers
  skills.heavyarmor(self).modifier = 0
  skills.lightarmor(self).modifier = 0
  skills.mediumarmor(self).modifier = 0
  skills.unarmored(self).modifier = 0
end

-- stance effects 
local function chargeMod(modVal)
    attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
    skills.heavyarmor(self).modifier = skills.heavyarmor(self).modifier + modVal
    skills.lightarmor(self).modifier = skills.lightarmor(self).modifier + modVal
    skills.mediumarmor(self).modifier = skills.mediumarmor(self).modifier + modVal
    skills.unarmored(self).modifier = skills.unarmored(self).modifier + modVal
end
local function releaseMod(modVal,buffType)
  if buffType == 1 then
    skills.heavyarmor(self).modifier = skills.heavyarmor(self).modifier + modVal
    skills.lightarmor(self).modifier = skills.lightarmor(self).modifier + modVal
    skills.mediumarmor(self).modifier = skills.mediumarmor(self).modifier + modVal
    skills.unarmored(self).modifier = skills.unarmored(self).modifier + modVal
  else
    attributes.agility(self).modifier = attributes.agility(self).modifier + modVal
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local chargeBuffTotal = {}
for i=1,maxStance,1 do 
  chargeBuffTotal[i] = 0
end

local function weaponCheck()
  local isWeapon = false
  if types.Actor.stance(self) == types.Actor.STANCE.Weapon then
    local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if (not usedWeapon) then -- handtohand
      isWeapon = incH2H
    else
      if not types.Lockpick.objectIsInstance(usedWeapon) and not types.Probe.objectIsInstance(usedWeapon) then
        local weaponType = Weapon.record(usedWeapon).type
        if (weaponType < 9) then -- melee weapon
          isWeapon = true
        elseif (weaponType <= 13) then -- ranged weapon
          isWeapon = incRanged
        elseif (weaponType > 13) then -- unknown weapon
          isWeapon = true
        end
      end
    end 
  end
  return(isWeapon)
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
  local buffMod = (1 + math.sqrt(weapWeight))*(50/strength)
    -- mod up as weapon weight up, with minimum
    -- mod down as strength up
  return(buffMod)
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
  local buffMod = (1 + math.sqrt(weapWeight))*math.min(maxCharge,(chargeTime*weapSpeed))--/weapSpeed
    -- mod up as weapon weight up, with minimum
    -- mod up as charge increases, vs weapon speed
    -- mod up as weapon speed up?
  return(buffMod)
end

-- save state to be removed on load
local function onSave()
    return{
      chargeBuffTotal = chargeBuffTotal
    }
end

local function onLoad(data)
  if data then
    chargeBuffTotal = data.chargeBuffTotal
    chargeMod(-chargeBuffTotal[1])
    releaseMod(-chargeBuffTotal[2])
    for i=1,maxStance,1 do
      chargeBuffTotal[i] = 0
    end
  end
end

local weaponWeight = 0
local chargeTime = 0
local doBuff = false
local isCharge = false -- true if trigger input action
local isWeapon = false
return { 
  engineHandlers = { 
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,
    
    onFrame = function(dt)
      if enabled then
        local isUse = input.isActionPressed(input.ACTION.Use)
        if core.isWorldPaused() then
          isUse = false
        end
        
        if isUse and not isCharge then -- on first frame you hit use        
--        if isUse and not isCharge and not types.Actor.isOnGround(self) then -- on first frame you hit use        
          isCharge = true -- update stance
          isWeapon = weaponCheck()
          -- apply charge debuff
          if isWeapon then
            chargeTime = core.getSimulationTime() -- set timer value
            local buffNext = hybridVal(stanceBuff[1],getChargeMod(),1)
            chargeMod(buffNext)
            chargeBuffTotal[1] = chargeBuffTotal[1] + buffNext
            if verbose then
              ui.showMessage('CHARGE ' .. tostring(chargeBuffTotal[1]))
            end
          end
      
        elseif not isUse and isCharge then -- on first frame you release use
          isCharge = false
          -- remove charge debuff
          chargeMod(-chargeBuffTotal[1])
          chargeBuffTotal[1] = 0
          if isWeapon and chargeBuffTotal[2]==0 then -- only buff if unbuffed
            chargeTime = core.getSimulationTime() - chargeTime -- get timer value
            -- buff DEFENSE or Agility depending on movement and config val
            local mf = self.controls.movement
            local ms = self.controls.sideMovement
            local ig = types.Actor.isOnGround(self)
            local moveType = 0
            if ig and mf == -1 then -- backwards component
              moveType = 1 -- def
            elseif ig and mf == 0 and ms ~= 0 then -- sideways only
              moveType = 2 -- agi
            end
            if moveType > 0 then
              doBuff = true
            else
              doBuff = false
            end
            
            if doBuff then
              -- get release buff
              local buffNext = hybridVal(stanceBuff[2],getReleaseMod(chargeTime),1)
              local buffType = 0
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
              releaseMod(buffNext,buffType)
              chargeBuffTotal[2] = chargeBuffTotal[2] + buffNext
              -- status info
              if verbose then
                if buffType == 1 then
                ui.showMessage('ARMOR UP ' .. tostring(chargeBuffTotal[2]))
                else
                ui.showMessage('AGILITY UP ' .. tostring(chargeBuffTotal[2]))
                end
              end
              -- start release timer
              async:newUnsavableSimulationTimer(
                buffDuration,
                function()
                releaseMod(-chargeBuffTotal[2],buffType)
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