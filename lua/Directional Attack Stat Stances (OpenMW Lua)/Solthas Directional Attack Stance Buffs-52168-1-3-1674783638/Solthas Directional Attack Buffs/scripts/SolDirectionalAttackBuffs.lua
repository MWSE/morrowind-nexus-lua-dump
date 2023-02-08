local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')

-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'SolDirectionalAttackBuffs',
   l10n = 'SolDirectionalAttackBuffs',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local verbose = 1 -- 0 none, 1 stance name, 2 stance stats, 3 consoleDebugInfo
local buffBase = 20
local tradeoffMult = 0.4
local hybridMult = 0.7 -- diminishing returns for each stage of combo
local buffDuration = 3
I.Settings.registerGroup({
   key = 'Settings_sda_DirectionalAttacks',
   page = 'SolDirectionalAttackBuffs',
   l10n = 'SolDirectionalAttackBuffs',
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
            max = 3,
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
            min = 1,
            max = 100,
         },
      },
      {
         key = 'tradeOffMult',
         default = tradeoffMult,
         renderer = 'number',
         name = 'tradeOffMult_name',
         description = 'tradeOffMult_description',
         argument = {
            min = 0,
            max = 2,
         },
      },
      {
         key = 'hybridMult',
         default = hybridMult,
         renderer = 'number',
         name = 'hybridMult_name',
         description = 'hybridMult_description',
         argument = {
            min = 0,
            max = 2,
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


local settingsGroup = storage.playerSection('Settings_sda_DirectionalAttacks')

-- shorthand for convenience
local Weapon = types.Weapon
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills

-- reduce effectiveness of hybrid stances
local function hybridVal(base,mult,count)
    return math.ceil(base*math.pow(mult,math.max(count,0)))
  --    return (base*math.pow(mult,math.max(count,0)))
end

-- script config
local modType = 1 -- 0 att, 1 skill
local incH2H = true -- include handtohand for dir attacks? (it actually has dir attacks so ... yes let's include it)
-- time and value vars
local tradeoffDelay = 0 -- delay tradeoff's hybrid diminishing returns, such that it has a heavier initial impact?
-- combine buffs and extend timer?
local comboTimer = true -- if true, on hybrid stance input, combine its buff with the previous and give an extended timer
local comboMult = 0.5 -- fraction of base duration to extend each stage
-- and store stance idxs for indexing into tables
local stanceIndex = {lunge=1, slash=2, chop=3}
local maxStance = 0
for _ in pairs(stanceIndex) do
  maxStance = maxStance + 1
end

-- init to defaults
--local buffDown = hybridVal(buffBase,-tradeoffMult,1)
local buffDown = 0
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  buffBase = settingsGroup:get('buffBase')
  tradeoffMult = settingsGroup:get('tradeOffMult')
  buffDown = hybridVal(buffBase,-tradeoffMult,1)
  hybridMult = settingsGroup:get('hybridMult')
  buffDuration = settingsGroup:get('buffDuration')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- init modifier values
local stanceBuffNext = {}
-- preallocate stancePrimary
local stanceNext = 0 -- determines which case to move into for state engine
local stancePrimary = 0 -- CASE: 0 none, 1 lunge, 2 slash, 3 chop
local stanceSecondary = 0 -- case, secondarily selected for hybrid state
local stanceActive = {} -- use this to determine if the current stance is active or not, to avoid repeat triggers
-- logic for stages
local stanceStage = 0 -- increments stance count to determine hybridVal multiplier 
-- if showing stat changes, then calculate them now
-- stance names for verbose
local stanceName = {'1','1','1'} ----- do I need these 1s?
if verbose == 1 then
--  stanceName = {'LUNGE','SLASH','CHOP'}
  stanceName = {'AGI','DEF','ATK'}
elseif verbose == 2 or verbose==3 then
  stanceName = {'AGI','DEF','ATK'}
end
-- use a queue to store stance and stage numbers
local circStance = {} -- store which stance was triggered
local circStage = {} -- store the stage of the stance trigger
local circCombo = {} -- if combining timers then include this queue

-- stance effects 
local function lungeMod(modVal)
  if modType == 0 then
    attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
  elseif modType == 1 then
    attributes.agility(self).modifier = attributes.agility(self).modifier + modVal
    attributes.endurance(self).modifier = attributes.endurance(self).modifier - modVal
    skills.acrobatics(self).modifier = skills.acrobatics(self).modifier + modVal
  end
  -- damage check
  if attributes.speed(self).modifier == attributes.speed(self).damage then
    attributes.speed(self).modifier = 0
    attributes.speed(self).damage = 0
  end
  if attributes.agility(self).modifier == attributes.agility(self).damage then
    attributes.agility(self).modifier = 0
    attributes.agility(self).damage = 0
  end
  if attributes.endurance(self).modifier == attributes.endurance(self).damage then
    attributes.endurance(self).modifier = 0
    attributes.endurance(self).damage = 0
  end
  if skills.acrobatics(self).modifier == skills.acrobatics(self).damage then
    skills.acrobatics(self).modifier = 0
    skills.acrobatics(self).damage = 0
  end
end
local function slashMod(modVal)
  if modType == 0 then
    attributes.agility(self).modifier = attributes.agility(self).modifier + modVal
    attributes.endurance(self).modifier = attributes.endurance(self).modifier - modVal
  elseif modType == 1 then
    skills.block(self).modifier = skills.block(self).modifier + modVal -- block???
    skills.heavyarmor(self).modifier = skills.heavyarmor(self).modifier + modVal
    skills.lightarmor(self).modifier = skills.lightarmor(self).modifier + modVal
    skills.mediumarmor(self).modifier = skills.mediumarmor(self).modifier + modVal
    skills.unarmored(self).modifier = skills.unarmored(self).modifier + modVal
  end
  -- damage check
  if attributes.agility(self).modifier == attributes.agility(self).damage then
    attributes.agility(self).modifier = 0
    attributes.agility(self).damage = 0
  end
  if attributes.endurance(self).modifier == attributes.endurance(self).damage then
    attributes.endurance(self).modifier = 0
    attributes.endurance(self).damage = 0
  end
  if skills.block(self).modifier == skills.block(self).damage then
    skills.block(self).modifier = 0
    skills.block(self).damage = 0
  end
  if skills.heavyarmor(self).modifier == skills.heavyarmor(self).damage then
    skills.heavyarmor(self).modifier = 0
    skills.heavyarmor(self).damage = 0
  end
  if skills.lightarmor(self).modifier == skills.lightarmor(self).damage then
    skills.lightarmor(self).modifier = 0
    skills.lightarmor(self).damage = 0
  end
  if skills.mediumarmor(self).modifier == skills.mediumarmor(self).damage then
    skills.mediumarmor(self).modifier = 0
    skills.mediumarmor(self).damage = 0
  end
  if skills.unarmored(self).modifier == skills.unarmored(self).damage then
    skills.unarmored(self).modifier = 0
    skills.unarmored(self).damage = 0
  end
end
local function chopMod(modVal)
  if modType == 0 then
    attributes.strength(self).modifier = attributes.strength(self).modifier + modVal
    -- for balance would need to burden or feather depending on if increased or decreased
    attributes.endurance(self).modifier = attributes.endurance(self).modifier - modVal -- offset by endurance to keep max fatigue constant
  elseif modType == 1 then
    skills.axe(self).modifier = skills.axe(self).modifier + modVal
    skills.bluntweapon(self).modifier = skills.bluntweapon(self).modifier + modVal
    skills.handtohand(self).modifier = skills.handtohand(self).modifier + modVal
    skills.longblade(self).modifier = skills.longblade(self).modifier + modVal
    skills.shortblade(self).modifier = skills.shortblade(self).modifier + modVal
    skills.spear(self).modifier = skills.spear(self).modifier + modVal
  end
  -- damage check
  if attributes.strength(self).modifier == attributes.strength(self).damage then
    attributes.strength(self).modifier = 0
    attributes.strength(self).damage = 0
  end
  if attributes.endurance(self).modifier == attributes.endurance(self).damage then
    attributes.endurance(self).modifier = 0
    attributes.endurance(self).damage = 0
  end
  if skills.axe(self).modifier == skills.axe(self).damage then
    skills.axe(self).modifier = 0
    skills.axe(self).damage = 0
  end
  if skills.bluntweapon(self).modifier == skills.bluntweapon(self).damage then
    skills.bluntweapon(self).modifier = 0
    skills.bluntweapon(self).damage = 0
  end
  if skills.handtohand(self).modifier == skills.handtohand(self).damage then
    skills.handtohand(self).modifier = 0
    skills.handtohand(self).damage = 0
  end
  if skills.longblade(self).modifier == skills.longblade(self).damage then
    skills.longblade(self).modifier = 0
    skills.longblade(self).damage = 0
  end
  if skills.shortblade(self).modifier == skills.shortblade(self).damage then
    skills.shortblade(self).modifier = 0
    skills.shortblade(self).damage = 0
  end
  if skills.spear(self).modifier == skills.spear(self).damage then
    skills.spear(self).modifier = 0
    skills.spear(self).damage = 0
  end
end

-- init stance total tracking
-- this is used for verbose outputs, and for onSave/onLoad tracking
local stanceBuffTotal = {}
for i=1,maxStance,1 do 
  stanceBuffTotal[i] = 0
end
local buffDurationMod = buffDuration -- set to default

function initStance(stanceNext) -- newState 1 lunge, 2 slash, 3 chop
  stanceStage = stanceStage + 1 -- increment stance stage
  local isBuff = true
  if stancePrimary == 0 then -- if no current stance, set this to primary
    stancePrimary = stanceNext
    -- set upcoming buff values
    for i=1,maxStance,1 do 
      stanceBuffNext[i] = buffDown
    end
    stanceBuffNext[stanceNext] = buffBase
  else
    if stanceSecondary == 0 then
      stanceSecondary = stanceNext
    end
    local buffDownHybrid = hybridVal(buffDown,hybridMult,stanceStage-(1+tradeoffDelay)) -- if not primary, then heavier tradeoff
    for i=1,maxStance,1 do 
      stanceBuffNext[i] = buffDownHybrid
    end
    stanceBuffNext[stanceNext] = hybridVal(buffBase,hybridMult,stanceStage-1)
  end

  if isBuff then    
    -- update stance totals
    for i=1,maxStance,1 do 
      stanceBuffTotal[i] = stanceBuffTotal[i] + stanceBuffNext[i]
    end
    -- send stance info message
    if verbose == 1 then   
      if stancePrimary == stanceNext then
        ui.showMessage('STANCE- ' .. stanceName[stanceNext])
      elseif stanceSecondary == stanceNext then
        ui.showMessage('STANCE- ' .. stanceName[stancePrimary] .. ' / ' .. stanceName[stanceNext])
      else
        ui.showMessage('STANCE- ' .. stanceName[stancePrimary] .. ' / ' .. stanceName[stanceSecondary] .. ' / ' .. stanceName[stanceNext])        
      end
    elseif verbose==2 or verbose==3  then
       -- build string iteratively for concatenated verbose output
      local buildString = ''
      for i=1,maxStance,1 do
        buildString = buildString .. tostring(stanceName[i]) .. ' ' .. tostring(stanceBuffTotal[i])
        if i<maxStance then
          buildString = buildString .. ', '
        end
      end
      if verbose == 2 then
        ui.showMessage(buildString)
      else
        ui.printToConsole(buildString,ui.CONSOLE_COLOR.Default)
      end
    end

    -- mod stat
    stanceActive[stanceNext] = true
    lungeMod(stanceBuffNext[1])
    slashMod(stanceBuffNext[2])
    chopMod(stanceBuffNext[3])
    -- update queue for timer to call
    table.insert(circStance,stanceNext)
    table.insert(circStage,stanceStage)
    
    -- modify stuff for combo timer extension
    if comboTimer then -- if in a combo
      if stanceStage>1 then
        for i,_ in ipairs(circCombo) do
          circCombo[i] = false -- set prior entries to not retrigger on their own
        end
        -- update combo duration
        buffDurationMod = buffDurationMod + buffDuration*(math.pow(comboMult,math.max(stanceStage-1,0)))
--        buffDurationMod = buffDurationMod + hybridVal(buffDuration,comboMult,stanceStage-1)
      end
      table.insert(circCombo,true)
    end
        
    -- start timer for current stance effect
    async:newUnsavableSimulationTimer(
      buffDurationMod,
      function()
        stanceStage = stanceStage - 1
        currentStance = table.remove(circStance,1)
        currentStage = table.remove(circStage,1)
                
        -- if doing combo timers, then check if actuall de-buffing with this timer call 
        local runDebuff = true
        if comboTimer then
          runDebuff = table.remove(circCombo,1)
        end
        
        if runDebuff then
          -- debug info
          if verbose == 3 then
            ui.printToConsole('stance ' .. tostring(currentStance)
               .. ', primary ' .. tostring(stancePrimary) .. ', secondary ' .. tostring(stanceSecondary)
               .. ', stage ' .. tostring(stanceStage),ui.CONSOLE_COLOR.Default)
          end
  
          -- unmod stat
          local stanceDebuff = {0,0,0}
          if not comboTimer then -- if no combo, then calculate stats to debuff
            if stancePrimary == currentStance then
              stancePrimary = 0 -- stance logic
              for i=1,maxStance,1 do 
                stanceDebuff[i] = buffDown
              end
              stanceDebuff[currentStance] = buffBase
            else
              if stanceSecondary == currentStance then 
                stanceSecondary = 0
              end
              local debuffHybrid = hybridVal(buffDown,hybridMult,currentStage-(1+tradeoffDelay))
              for i=1,maxStance,1 do 
                stanceDebuff[i] = debuffHybrid
              end
              stanceDebuff[currentStance] = hybridVal(buffBase,hybridMult,currentStage-1)
            end
          else -- if combo timer, then just remove all totals
            for i=1,maxStance,1 do 
              stanceDebuff[i] = stanceBuffTotal[i]
            end
            stancePrimary = 0
            stanceSecondary = 0
          end
          
          -- debug info
          if verbose == 3 then
            ui.printToConsole('lunge ' .. tostring(stanceDebuff[1])
               .. ', slash ' .. tostring(stanceDebuff[2])
               .. ', chop ' .. tostring(stanceDebuff[3]),ui.CONSOLE_COLOR.Default)
          end
          
          -- update stats
          lungeMod(-stanceDebuff[1])
          slashMod(-stanceDebuff[2])
          chopMod(-stanceDebuff[3])
          if not comboTimer then
            stanceActive[currentStance] = false
          else
            for i=1,maxStance,1 do
              stanceActive[i] = false
            end
          end
          
          -- update totals for tracking
          for i=1,maxStance,1 do
            stanceBuffTotal[i] = stanceBuffTotal[i] - stanceDebuff[i]
          end
          buffDurationMod = buffDuration -- reset to default
          
          if verbose == 1 then   
            ui.showMessage('STANCE- RESET')
          elseif verbose==2 or verbose==3  then
             -- build string iteratively for concatenated verbose output
            local buildString = ''
            for i=1,maxStance,1 do
              buildString = buildString .. tostring(stanceName[i]) .. ' ' .. tostring(stanceBuffTotal[i])
              if i<maxStance then
                buildString = buildString .. ', '
              end
            end
            if verbose == 2 then
              ui.showMessage(buildString)
            else
              ui.printToConsole(buildString,ui.CONSOLE_COLOR.Default)
            end
          end
        end
      end
    )
  end
end

-- save state to be removed on load
local function onSave()
    return{
      stanceBuffTotal = stanceBuffTotal
    }
end

local function onLoad(data)
  if data then
    stanceBuffTotal = data.stanceBuffTotal
    lungeMod(-stanceBuffTotal[1])
    slashMod(-stanceBuffTotal[2])
    chopMod(-stanceBuffTotal[3])
    for i=1,maxStance,1 do
      stanceBuffTotal[i] = 0
    end
  end
end

return { 
  engineHandlers = { 
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,
    -- DEFINE ATTACK TYPE
    onInputAction = function(id)
      if enabled and id == input.ACTION.Use and types.Actor.stance(self) == types.Actor.STANCE.Weapon then
--      if id == input.ACTION.Use and types.Actor.stance(self) == types.Actor.STANCE.Weapon then
        -- check your weapon type to see if directional attacks are relevant
        local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        isMelee = false
        if (not usedWeapon) then -- handtohand
          isMelee = incH2H
        else
          if  not types.Lockpick.objectIsInstance(usedWeapon) and not types.Probe.objectIsInstance(usedWeapon) then
            local weaponType = Weapon.record(usedWeapon).type
            if (weaponType < 9) or (weaponType > 13) then
              isMelee = true
            end
          end
        end 
    
        if isMelee then -- 0-8 is melee, 9-11 is ranged, 12-13 is ammunition, usedWeapon nil if handtohand
          -- check movement to determine attack dir
          local mf = self.controls.movement
          local ms = self.controls.sideMovement
          
          stanceNext = 0
          if mf ~= 0 and ms == 0 then -- lunge
            if not stanceActive[1] then -- do not repeat
              stanceNext = 1
            end
          elseif mf == 0 and ms ~= 0 then -- slash
            if not stanceActive[2] then -- do not repeat
              stanceNext = 2
            end
          elseif (mf == 0 and ms == 0) or (mf ~= 0 and ms ~= 0) then -- chop
            if not stanceActive[3] then -- do not repeat
              stanceNext = 3
            end
          else 
            stanceNext = -1 -- this should be unreachable
          end
          
          if stanceNext ~= 0 then
            initStance(stanceNext)
          end
          
        end
      end
    end
  } 
}