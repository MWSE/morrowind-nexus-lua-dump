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
local verbose = 2
local buffBase = 10
local tradeOffBase = 50
local fatigueLoss = 15
local paceMult = 1.5
I.Settings.registerGroup({
   key = 'Settings_SolTimedDirAttacks',
   page = 'SolTimedDirAttacks',
   l10n = 'SolTimedDirAttacks',
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
local modType = 1 --1 skill, 0 attribute, -1 debug reset all stat modifiers
local incH2H = true -- include handtohand?
  -- if true, must define "weight" and "speed" values for h2h in buff/debuff fncs
local incRanged = true -- include ranged weapons ?

-- init to defaults
local buffDuration = 1
local stateNames = {}
local stanceNames = {'','','',''}
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  buffBase = settingsGroup:get('buffBase')
  tradeOffBase = settingsGroup:get('tradeOffBase')
  paceMult = settingsGroup:get('paceMult')
  -- update pace timer multiplier
  buffDuration = 4/paceMult -- 3 states, so divide by 3
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

-- debug case... resetting all relevant modifiers
if modType == -1 then
  -- damage -- this really shouldn't be needed
  -- modifiers
end

-- stance effects 
local function chopMod(modVal)
  if modType == 0 then
    attributes.strength(self).modifier = attributes.strength(self).modifier + modVal
    -- for balance would need to burden or feather depending on if increased or decreased
  elseif modType == 1 then
    skills.axe(self).modifier = skills.axe(self).modifier + modVal
    skills.bluntweapon(self).modifier = skills.bluntweapon(self).modifier + modVal
    skills.handtohand(self).modifier = skills.handtohand(self).modifier + modVal
    skills.longblade(self).modifier = skills.longblade(self).modifier + modVal
    skills.marksman(self).modifier = skills.marksman(self).modifier + modVal -- marksman?
    skills.shortblade(self).modifier = skills.shortblade(self).modifier + modVal
    skills.spear(self).modifier = skills.spear(self).modifier + modVal
  end
end
local function slashMod(modVal)
  if modType == 0 then
    attributes.agility(self).modifier = attributes.agility(self).modifier + modVal
  elseif modType == 1 then
    skills.block(self).modifier = skills.block(self).modifier + modVal -- block?
    skills.heavyarmor(self).modifier = skills.heavyarmor(self).modifier + modVal
    skills.lightarmor(self).modifier = skills.lightarmor(self).modifier + modVal
    skills.mediumarmor(self).modifier = skills.mediumarmor(self).modifier + modVal
    skills.unarmored(self).modifier = skills.unarmored(self).modifier + modVal
  end
end
local function lungeMod(modVal)
  if modType == 0 then
    attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
    attributes.endurance(self).modifier = attributes.endurance(self).modifier + modVal -- endurance?
  elseif modType == 1 then
    attributes.agility(self).modifier = attributes.agility(self).modifier + modVal
    skills.acrobatics(self).modifier = skills.acrobatics(self).modifier + modVal
  end
end
local function debuffMod(modVal)
  attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
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
    chopMod(-buffTotal[1])
    slashMod(-buffTotal[2])
    lungeMod(-buffTotal[3])
    debuffMod(-buffTotal[4])    
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
    
    onFrame = function(dt)
      if enabled then
        local isUse = input.isActionPressed(input.ACTION.Use)
        if core.isWorldPaused() then
          isUse = false
        end
        
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
                if cfat >= fatigueLoss then -- only do buff if enough fatigue for it
                  dynamic.fatigue(self).current = cfat - fatigueLoss
				else
                  dynamic.fatigue(self).current = 0
                end
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
                chopMod(-buffTotal[1])
                slashMod(-buffTotal[2])
                lungeMod(-buffTotal[3])
                debuffMod(-buffTotal[4])
                buffTotal = {0,0,0,0}

                -- apply new buff
                if chargeState == 0 then
                  debuffMod(-tradeOffBase)
                  buffTotal[4] = buffTotal[4] - tradeOffBase
                  stanceNext = 4
                else
                  if stanceNext == 1 then
                    chopMod(buffBase*buffMult)
                    buffTotal[1] = buffTotal[1] + buffBase*buffMult
                  elseif stanceNext == 2 then
                    slashMod(buffBase*buffMult)
                    buffTotal[2] = buffTotal[2] + buffBase*buffMult
                  elseif stanceNext == 3 then
                    lungeMod(buffBase*buffMult)
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
                      chopMod(-buffTotal[1])
                      slashMod(-buffTotal[2])
                      lungeMod(-buffTotal[3])
                      debuffMod(-buffTotal[4])
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