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
   key = 'SolWeightyChargeAttacks',
   l10n = 'SolWeightyChargeAttacks',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local verbose = true
local integrateParry = true
local buffControl = 0 -- 0 both, 1 str only, 2 acc only
local buffBase = 2
local tradeOffBase = 5
local doAgi = true
local maxCharge = 2
local buffDuration = 1
I.Settings.registerGroup({
   key = 'Settings_SolWeightyChargeAttacks',
   page = 'SolWeightyChargeAttacks',
   l10n = 'SolWeightyChargeAttacks',
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
         key = 'integrateParry',
         default = integrateParry,
         renderer = 'checkbox',
         name = 'integrateParry_name',
         description = 'integrateParry_description',
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
         key = 'doAgi',
         default = doAgi,
         renderer = 'checkbox',
         name = 'doAgi_name',
         description = 'doAgi_description'
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

local settingsGroup = storage.playerSection('Settings_SolWeightyChargeAttacks')

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
  integrateParry = settingsGroup:get('integrateParry')
  buffControl = settingsGroup:get('buffControl')
  buffBase = settingsGroup:get('buffBase')
  tradeOffBase = settingsGroup:get('tradeOffBase')
  doAgi = settingsGroup:get('doAgi')
  maxCharge = settingsGroup:get('maxCharge')
  buffDuration = settingsGroup:get('buffDuration')
  -- calculate new buff vals
  if doAgi then
    stanceBuff = {-tradeOffBase,buffBase}
  else
    stanceBuff = {-2*tradeOffBase,buffBase}
  end
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- debug case... resetting all relevant modifiers
if modType == -1 then
  -- damage -- this really shouldn't be needed
  attributes.agility(self).damage = 0
  attributes.endurance(self).damage = 0
  attributes.speed(self).damage = 0
  attributes.strength(self).damage = 0
  skills.axe(self).damage = 0
  skills.bluntweapon(self).damage = 0
  skills.handtohand(self).damage = 0
  skills.longblade(self).damage = 0
  skills.marksman(self).damage = 0
  skills.shortblade(self).damage = 0
  skills.spear(self).damage = 0
  -- modifiers
  attributes.agility(self).modifier = 0
  attributes.endurance(self).modifier = 0
  attributes.speed(self).modifier = 0
  attributes.strength(self).modifier = 0
  skills.axe(self).modifier = 0
  skills.bluntweapon(self).modifier = 0
  skills.handtohand(self).modifier = 0
  skills.longblade(self).modifier = 0
  skills.marksman(self).modifier = 0
  skills.shortblade(self).modifier = 0
  skills.spear(self).modifier = 0
end

-- stance effects 
local function chargeMod(modVal)
    attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
    if doAgi then
      attributes.agility(self).modifier = attributes.agility(self).modifier + modVal
    end
end
local function releaseMod(modVal,buffType)
  if buffType == 1 then
    attributes.endurance(self).modifier = attributes.endurance(self).modifier + modVal
    attributes.strength(self).modifier = attributes.strength(self).modifier + modVal
  else
    skills.axe(self).modifier = skills.axe(self).modifier + modVal
    skills.bluntweapon(self).modifier = skills.bluntweapon(self).modifier + modVal
    skills.handtohand(self).modifier = skills.handtohand(self).modifier + modVal
    skills.longblade(self).modifier = skills.longblade(self).modifier + modVal
    skills.marksman(self).modifier = skills.marksman(self).modifier + modVal
    skills.shortblade(self).modifier = skills.shortblade(self).modifier + modVal
    skills.spear(self).modifier = skills.spear(self).modifier + modVal
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
      if  not types.Lockpick.objectIsInstance(usedWeapon) and not types.Probe.objectIsInstance(usedWeapon) then
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
            if verbose and not integrateParry then
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
            -- check if applying buff
            doBuff = true
            if integrateParry then
              local ig = types.Actor.isOnGround(self)
              local mf = self.controls.movement
              local ms = self.controls.sideMovement
              if ig and mf == -1 then -- backwards component
                doBuff = false -- def
              elseif ig and mf == 0 and ms ~= 0 then -- sideways only
                doBuff = false
              end
            end
      
            if doBuff then
              -- get release buff
              local buffNext = hybridVal(stanceBuff[2],getReleaseMod(chargeTime),1)
              local buffType = 0
              -- buff accuracy or strength depending on isGrounded and config val
              if buffControl == 0 then
                if types.Actor.isOnGround(self) then
                buffType = 2
                else
                buffType = 1
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
                ui.showMessage('JUMP ATTACK ' .. tostring(chargeBuffTotal[2]))
                else
                ui.showMessage('GROUND ATTACK ' .. tostring(chargeBuffTotal[2]))
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