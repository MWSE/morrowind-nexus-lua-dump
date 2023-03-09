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
   key = 'SolTimedDirAttacks',
   l10n = 'SolTimedDirAttacks',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local verbose = 1
local incRanged = false -- include ranged weapons ?
local buffBase = 10
local tradeOffBase = 50
local fatigueLoss = 15
local paceMult = 1.5
I.Settings.registerGroup({
   key = 'Settings_SolTimedDirAttacks',
   page = 'SolTimedDirAttacks',
   l10n = 'SolTimedDirAttacks',
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
         renderer = 'number',
         name = 'verbose_name',
         description = 'verbose_description',
         argument = {
            integer = true,
            min = 0,
            max = 2,
         },
      },
      {
         key = 'incRanged',
         default = incRanged,
         renderer = 'checkbox',
         name = 'incRanged_name',
      },
      {
         key = 'buffBase',
         default = buffBase,
         renderer = 'number',
         name = 'buffBase_name',
         description = 'buffBase_description',
         argument = {
        integer = true,
            min = 0,
            max = 100,
         },
      },
      {
         key = 'tradeOffBase',
         default = tradeOffBase,
         renderer = 'number',
         name = 'tradeOffBase_name',
         description = 'tradeOffBase_description',
         argument = {
        integer = true,
            min = 0,
            max = 100,
         },
      },
      {
         key = 'fatigueLoss',
         default = fatigueLoss,
         renderer = 'number',
         name = 'fatigueLoss_name',
         description = 'fatigueLoss_description',
         argument = {
        integer = true,
            min = 0,
            max = 100,
         },
      },
      {
         key = 'paceMult',
         default = paceMult,
         renderer = 'number',
         name = 'paceMult_name',
         description = 'paceMult_description',
         argument = {
            min = 0.5,
            max = 3.0,
         },
      },
   },
})
local settingsGroup = storage.playerSection('Settings_SolTimedDirAttacks')

-- shorthand for convenience
local Weapon = types.Weapon
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- reduce effectiveness of hybrid stances
local function hybridVal(base,mult,count)
    return math.ceil(base*math.pow(mult,math.max(count,0)))
end

-- script config
local incH2H = true -- include handtohand?
  -- if true, must define "speed" value for h2h in buff/debuff fncs

-- init to defaults
local buffDuration = 1
local stateNames = {}
local stanceNames = {'','','',''}
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  incRanged = settingsGroup:get('incRanged')
  buffBase = settingsGroup:get('buffBase')
  tradeOffBase = settingsGroup:get('tradeOffBase')
  paceMult = settingsGroup:get('paceMult')
  -- update pace timer multiplier
  buffDuration = 6/paceMult -- 3 states, so divide by 3
    -- actually let's do 6 just to be safe
  -- update verbose
  if verbose == 1 then
    stateNames = {'EARLY', 'GOOD', 'PERFECT'}
    stanceNames = {'CHOP','SLASH','THRUST','FUMBLE'}
  elseif verbose == 2 then
    stateNames  = {'', '', ''}
    stanceNames = {'ACC','DEF','AGI','FTG, SPD'}
  end
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- stance effects 
local function chopMod(modSign,modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    skills.axe(self).modifier = math.max(0,skills.axe(self).modifier + modSign*modVal)
    skills.bluntweapon(self).modifier = math.max(0,skills.bluntweapon(self).modifier + modSign*modVal)
    skills.handtohand(self).modifier = math.max(0,skills.handtohand(self).modifier + modSign*modVal)
    skills.longblade(self).modifier = math.max(0,skills.longblade(self).modifier + modSign*modVal)
    skills.marksman(self).modifier = math.max(0,skills.marksman(self).modifier + modSign*modVal) -- marksman?
    skills.shortblade(self).modifier = math.max(0,skills.shortblade(self).modifier + modSign*modVal)
    skills.spear(self).modifier = math.max(0,skills.spear(self).modifier + modSign*modVal)
  else
    modVal = math.abs(modVal)
    skills.axe(self).damage = math.max(0,skills.axe(self).damage + modVal)
    skills.bluntweapon(self).damage = math.max(0,skills.bluntweapon(self).damage + modSign*modVal)
    skills.handtohand(self).damage = math.max(0,skills.handtohand(self).damage + modSign*modVal)
    skills.longblade(self).damage = math.max(0,skills.longblade(self).damage + modSign*modVal)
    skills.marksman(self).damage = math.max(0,skills.marksman(self).damage + modSign*modVal) -- marksman?
    skills.shortblade(self).damage = math.max(0,skills.shortblade(self).damage + modSign*modVal)
    skills.spear(self).damage = math.max(0,skills.spear(self).damage + modSign*modVal)
  end
end
local function slashMod(modSign,modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    skills.block(self).modifier = math.max(0,skills.block(self).modifier + modSign*modVal) -- block?
    skills.heavyarmor(self).modifier = math.max(0,skills.heavyarmor(self).modifier + modSign*modVal)
    skills.lightarmor(self).modifier = math.max(0,skills.lightarmor(self).modifier + modSign*modVal)
    skills.mediumarmor(self).modifier = math.max(0,skills.mediumarmor(self).modifier + modSign*modVal)
    skills.unarmored(self).modifier = math.max(0,skills.unarmored(self).modifier + modSign*modVal)
  else
    modVal = math.abs(modVal)
    skills.block(self).damage = math.max(0,skills.block(self).damage + modSign*modVal) -- block?
    skills.heavyarmor(self).damage = math.max(0,skills.heavyarmor(self).damage + modSign*modVal)
    skills.lightarmor(self).damage = math.max(0,skills.lightarmor(self).damage + modSign*modVal)
    skills.mediumarmor(self).damage = math.max(0,skills.mediumarmor(self).damage + modSign*modVal)
    skills.unarmored(self).damage = math.max(0,skills.unarmored(self).damage + modSign*modVal)
  end
end
local function lungeMod(modSign,modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.agility(self).modifier = math.max(0,attributes.agility(self).modifier + modSign*modVal)
       -- offset agility by willpower to keep max fatigue constant
    attributes.willpower(self).damage = math.max(0,attributes.willpower(self).damage + modSign*modVal)
    skills.acrobatics(self).modifier = math.max(0,skills.acrobatics(self).modifier + modSign*modVal)
  else
    modVal = math.abs(modVal)
    attributes.agility(self).damage = math.max(0,attributes.agility(self).damage + modSign*modVal)
       -- offset agility by willpower to keep max fatigue constant
    attributes.willpower(self).modifier = math.max(0,attributes.willpower(self).modifier + modSign*modVal)
    skills.acrobatics(self).damage = math.max(0,skills.acrobatics(self).damage + modSign*modVal)
  end
end
local function debuffMod(modSign,modVal) -- debuff speed on fumble
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.speed(self).modifier = math.max(0,attributes.speed(self).modifier + modSign*math.ceil(0.5*modVal))
	-- do athletics and acrobatics with speed, but give them each half impact
    skills.athletics(self).modifier = math.max(0,skills.athletics(self).modifier + modSign*math.ceil(0.5*modVal))
    skills.acrobatics(self).modifier = math.max(0,skills.acrobatics(self).modifier + modSign*math.ceil(0.5*modVal))
  else
    modVal = math.abs(modVal)
    attributes.speed(self).damage = math.max(0,attributes.speed(self).damage + modSign*math.ceil(0.5*modVal))
	-- do athletics and acrobatics with speed, but give them each half impact
    skills.athletics(self).damage = math.max(0,skills.athletics(self).damage + modSign*math.ceil(0.5*modVal))
    skills.acrobatics(self).damage = math.max(0,skills.acrobatics(self).damage + modSign*math.ceil(0.5*modVal))
  end
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

local function getPace()
  -- get relevant stats
  local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  local weapSpeed = 1
  if (usedWeapon) then -- NOT handtohand
    weapSpeed = Weapon.record(usedWeapon).speed
  end
  -- setup mod
  local paceTime = 1/weapSpeed
  return(paceTime)
end


local buffTotal = {0,0,0,0}
-- save state to be removed on load
local function onSave()
    return{
      buffTotal = buffTotal
    }
end
local function onLoad(data)
  if data then
    buffTotal = data.buffTotal
    chopMod(-1,buffTotal[1])
    slashMod(-1,buffTotal[2])
    lungeMod(-1,buffTotal[3])
    debuffMod(-1,buffTotal[4])    
    buffTotal = {0,0,0,0}
  end
end

-- use a queue to store stance and stage numbers
local circStance = {} -- store which stance was triggered
local circCombo = {} -- store whether stance was eaten by a new input
local weaponWeight = 0
local chargeTime = 0
local doBuff = true
local isCharge = false -- true if trigger input action
local isWeapon = false
local stanceNext = 0
local isBuffed = false
local buffMult = 0
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
          isCharge = true -- update stance
          isWeapon = weaponCheck()
          -- get dir attack type
          if isWeapon then -- 0-8 is melee, 9-11 is ranged, 12-13 is ammunition, usedWeapon nil if handtohand
            -- check movement to determine attack dir
            local mf = self.controls.movement
            local ms = self.controls.sideMovement
            if mf ~= 0 and ms == 0 then -- lunge
              stanceNext = 3
            elseif mf == 0 and ms ~= 0 then -- slash
              stanceNext = 2
            elseif (mf == 0 and ms == 0) or (mf ~= 0 and ms ~= 0) then -- chop
              stanceNext = 1
            end
            
            if doBuff then
              doBuff = false
              chargeTime = core.getSimulationTime() - chargeTime -- get timer value
              local paceTime = getPace()
              local chargeState = math.floor(paceMult*chargeTime/paceTime)    
        
              if chargeState == 0 then -- drain fatigue
                isBuffed = true
                local cfat = dynamic.fatigue(self).current
        --        dynamic.fatigue(self).current = math.max(0, dynamic.fatigue(self).current - fatigueLoss)
                dynamic.fatigue(self).current = math.max(0, cfat - fatigueLoss)
        -- there's a conflict between this fatigue loss and the loss of agility. It can subtract from your true max fatigue ignoring the loss from agility
        -- which, once agility returns to normal, can cause your fatigue to go above maximum
        --        dynamic.fatigue(self).current = math.min(dynamic.fatigue(self).base, dynamic.fatigue(self).current)       
              elseif chargeState == 1 then -- 1x buff
                isBuffed = true
                buffMult = 1
              elseif chargeState == 2 then -- 2x buff
                isBuffed = true
                buffMult = 2
              else -- nothing
                isBuffed = false
              end
              
              if isBuffed then
                -- remove existing buffs
                chopMod(-1,buffTotal[1])
                slashMod(-1,buffTotal[2])
                lungeMod(-1,buffTotal[3])
                debuffMod(-1,buffTotal[4])
                buffTotal = {0,0,0,0}

                -- apply new buff
                if chargeState == 0 then
                  debuffMod(1,-tradeOffBase)
                  buffTotal[4] = buffTotal[4] - tradeOffBase
                  stanceNext = 4
                else
                  if stanceNext == 1 then
                    chopMod(1,buffBase*buffMult)
                    buffTotal[1] = buffTotal[1] + buffBase*buffMult
                  elseif stanceNext == 2 then
                    slashMod(1,buffBase*buffMult)
                    buffTotal[2] = buffTotal[2] + buffBase*buffMult
                  elseif stanceNext == 3 then
                    lungeMod(1,buffBase*buffMult)
                    buffTotal[3] = buffTotal[3] + buffBase*buffMult
                  end
                end
                -- update queue for timer to call
                for i,_ in ipairs(circCombo) do
                  circCombo[i] = false -- set prior entries to not retrigger on their own
                end
                table.insert(circCombo,true)
        
                if verbose == 1 then
                  if chargeState == 0 then
                    ui.showMessage(stateNames[chargeState+1].. ' ' .. stanceNames[4])
                  else
                    ui.showMessage(stateNames[chargeState+1].. ' ' .. stanceNames[stanceNext])                  
                  end
                elseif verbose == 2 then
                  if chargeState == 0 then
                    ui.showMessage(tostring(-fatigueLoss) ..' '.. stanceNames[4] .. ' -' .. tostring(tradeOffBase) .. ' (' .. tostring(math.floor(chargeTime*10)/10) .. ' / ' .. tostring(math.floor(paceTime/paceMult*10)/10)..')')
                  else
                    ui.showMessage(stanceNames[stanceNext] .. ' +' .. tostring(buffBase*buffMult) .. ' (' .. tostring(math.floor(chargeTime*10)/10) .. ' / ' .. tostring(math.floor(paceTime/paceMult*10)/10)..')')                
                  end
                end
                
                -- start end buff timer
                async:newUnsavableSimulationTimer(
                  buffDuration*paceTime,
                  function()
                    local runDebuff = table.remove(circCombo,1)
                    if runDebuff then
                      chopMod(-1,buffTotal[1])
                      slashMod(-1,buffTotal[2])
                      lungeMod(-1,buffTotal[3])
                      debuffMod(-1,buffTotal[4])
                      buffTotal = {0,0,0,0}
                    end
                  end
                )
              end
            end
          end
          
        elseif not isUse and isCharge then -- on first frame you release use
          isCharge = false
          if isWeapon then -- only buff if unbuffed
            doBuff = true
            chargeTime = core.getSimulationTime() -- start timer
          end
        end
      end
    end
  }
}