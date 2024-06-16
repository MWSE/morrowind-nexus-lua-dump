local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')

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
I.Settings.registerPage({
   key = 'SolSneakAttackBuff',
   l10n = 'SolSneakAttackBuff',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local verbose = false
local buffBase = 1
local fatigueMult = 1
local doSpeedRelease = true
local maxCharge = 2.5
local buffDuration = 2.0
I.Settings.registerGroup({
  key = 'Settings_SolSneakAttackBuff',   page = 'SolSneakAttackBuff',
  l10n = 'SolSneakAttackBuff',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled',enabled),
    boolSetting('verbose',verbose),
    numbSetting('buffBase',buffBase, false,0,2),
    numbSetting('fatigueMult',fatigueMult, false,0,2),
    boolSetting('doSpeedRelease',doSpeedRelease),
    numbSetting('maxCharge',maxCharge, false,1,5),
    numbSetting('buffDuration',buffDuration, false,0.25,5),
   },
})

local settingsGroup = storage.playerSection('Settings_SolSneakAttackBuff')

-- shorthand for convenience
local Weapon = types.Weapon
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- reduce effectiveness of hybrid stances
local function hybridVal(base,mult,count)
    return math.ceil(base*math.pow(mult,math.max(count,0)))
end

-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  buffBase = settingsGroup:get('buffBase')
  fatigueMult = settingsGroup:get('fatigueMult')
  doSpeedRelease = settingsGroup:get('doSpeedRelease')
  maxCharge = settingsGroup:get('maxCharge')
  buffDuration = settingsGroup:get('buffDuration')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- stance effects 
local function releaseMod(modSign,modVal)
  if doSpeedRelease then
    if modSign > 0 then -- expect positive modsign on application of effect
      input.setControlSwitch(input.CONTROL_SWITCH.Controls,false) -- if buffing, stop movement
    elseif modSign <= 0 then
      input.setControlSwitch(input.CONTROL_SWITCH.Controls,true) -- if unbuffing, release movement
    end
  end
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.strength(self).modifier = math.max(0,attributes.strength(self).modifier + modSign*modVal)
  else
    modVal = math.abs(modVal)
    attributes.strength(self).damage = math.max(0,attributes.strength(self).damage + modSign*modVal)
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local chargeBuffTotal = 0
local function weaponCheck()
  local weaponMult = 0 -- modifier to buff
  if types.Actor.stance(self) == types.Actor.STANCE.Weapon then
    local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if (not usedWeapon) then -- handtohand
      weaponMult = 2
    else
      if  not types.Lockpick.objectIsInstance(usedWeapon) and not types.Probe.objectIsInstance(usedWeapon) then
        local weaponType = Weapon.record(usedWeapon).type
        if (weaponType == 0) then -- short blade
          weaponMult = 1.75
        elseif (weaponType <= 8) then -- other melee weapon
          weaponMult = 1
        elseif (weaponType == 9) then -- ranged weapon-bow
          weaponMult = 1.75
        elseif (weaponType == 10) then -- ranged weapon-crossbow
          weaponMult = 1.5
        elseif (weaponType == 11) then -- ranged weapon-throwing
          weaponMult = 2
        elseif (weaponType > 13) then -- unknown weapon
          weaponMult = 1
        end
      end
    end 
  end
  return(weaponMult)
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
    releaseMod(-1,chargeBuffTotal)
  end
end

local chargeTime = 0
local doBuff = false
local isCharge = false -- true if trigger input action
local weaponMult = false
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
        
        local isSneak = self.controls.sneak -- 0.49 sneak check
        if isSneak == nil then
            isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check
        end
    
        if isUse and not isCharge then -- on first frame you hit use        
          isCharge = true -- update stance
          weaponMult = weaponCheck()
          -- apply charge debuff
          if weaponMult > 0 then
            chargeTime = 0 -- set timer value
          end
          
        -- do I really need to check every frame it's charging just to let you know when you can release?
        elseif isUse and isCharge and isSneak and not doBuff then -- if currently charging
          if weaponMult>0 then
            chargeTime = chargeTime + dt -- increment timer only if sneaking
            if chargeTime >= maxCharge then 
              doBuff = true
              ui.showMessage('Sneak attack buff ready!')
            end
          end
          
        elseif not isUse and isCharge and isSneak then -- on first frame you release use
          isCharge = false
          if weaponMult>0 and chargeBuffTotal==0 then -- only buff if unbuffed
            if doBuff then
              -- get release buff
              local buffNext = hybridVal(skills.sneak(self).modified,(weaponMult*buffBase),1) -- modify strength by your sneak skill x your weapon multiplier
              -- apply buff
              releaseMod(1,buffNext)
              chargeBuffTotal = chargeBuffTotal + buffNext
			  -- fatigue cost
			  local cfat = dynamic.fatigue(self).current
			  local fatigueCost = math.ceil(fatigueMult*math.sqrt(buffNext))
			  -- don't set fatigue here, because buffing strength will mess it up anyway
              -- status info
              if verbose then
                  ui.showMessage('Sneak Attack x' .. tostring(weaponMult) .. ': STR + ' .. tostring(chargeBuffTotal))
              end
              -- start release timer
              async:newUnsavableSimulationTimer(
                buffDuration,
                function()
                  releaseMod(-1,chargeBuffTotal)
                  chargeBuffTotal = 0
                  doBuff = false --reset buff counter
                  dynamic.fatigue(self).current = math.max(0,cfat - fatigueCost)
                end
              )
            end
          end
        end
      end
    end
  }
}