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
   key = 'SolStaffSpellBuffs',
   l10n = 'SolStaffSpellBuffs',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local onStaffSwap = true -- if you need to swap off staff
local doTradeOffs = true
local verbose = true -- 0 none, 1 stance name, 2 stance stats, 3 consoleDebugInfo
local buffBase = 10
local doInt = true
local doWis = true
local doAgi = true
local doSpd = true
local tradeoffMult = 1.0
I.Settings.registerGroup({
   key = 'Settings_sol_StaffSpellBuff',
   page = 'SolStaffSpellBuffs',
   l10n = 'SolStaffSpellBuffs',
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
         key = 'onStaffSwap',
         default = onStaffSwap,
         renderer = 'checkbox',
         name = 'onStaffSwap_name',
         description = 'onStaffSwap_descrption',
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
            max = 20,
         },
      },
      {
         key = 'doTradeOffs',
         default = doTradeOffs,
         renderer = 'checkbox',
         name = 'doTradeOffs_name',
         description = 'doTradeOffs_description',
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
         key = 'doInt',
         default = doInt,
         renderer = 'checkbox',
         name = 'doInt_name',
      },
      {
         key = 'doWis',
         default = doWis,
         renderer = 'checkbox',
         name = 'doWis_name',
      },
      {
         key = 'doAgi',
         default = doAgi,
         renderer = 'checkbox',
         name = 'doAgi_name',
      },
      {
         key = 'doSpd',
         default = doSpd,
         renderer = 'checkbox',
         name = 'doSpd_name',
      },
   },
})

local settingsGroup = storage.playerSection('Settings_sol_StaffSpellBuff')

-- shorthand for convenience
local Weapon = types.Weapon
local attributes = types.Actor.stats.attributes

-- reduce effectiveness of hybrid stances
local function hybridVal(base,mult,count)
    return math.ceil(base*math.pow(mult,math.max(count,0)))
end

-- script config
local modType = 1 --1 skill, -1 debug reset all stat modifiers
-- and store stance idxs for indexing into tables
local stanceIndex = {spell=1, staff=2}
local maxStance = 0
for _ in pairs(stanceIndex) do
  maxStance = maxStance + 1
end

-- init to defaults
local buffDown = hybridVal(buffBase,-tradeoffMult,1)
local spellBuff = {buffBase,buffDown}
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  onStaffSwap = settingsGroup:get('onStaffSwap')
  buffBase = settingsGroup:get('buffBase')
  doInt = settingsGroup:get('doInt')
  doWis = settingsGroup:get('doWis')
  doTradeOffs = settingsGroup:get('doTradeOffs')
  tradeoffMult = settingsGroup:get('tradeOffMult')
  doAgi = settingsGroup:get('doAgi')
  doSpd = settingsGroup:get('doSpd')
  -- calculate new buff vals
  buffDown = hybridVal(buffBase,-tradeoffMult,1)
  spellBuff = {buffBase,buffDown}
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- stance names for verbose
local stanceName = {'SPELL','STAFF'}

-- debug case... resetting all relevant modifiers
if modType == -1 then
  -- damage -- this really shouldn't be needed
  attributes.speed(self).damage = 0
  attributes.agility(self).damage = 0
  attributes.intelligence(self).damage = 0
  attributes.willpower(self).damage = 0
  -- modifiers
  attributes.speed(self).modifier = 0
  attributes.agility(self).modifier = 0
  attributes.intelligence(self).modifier = 0
  attributes.willpower(self).modifier = 0
end

-- stance effects 
local function magMod(modVal)
  if modType == 1 then
    if doInt then
      attributes.intelligence(self).modifier = attributes.intelligence(self).modifier + modVal
    end
    if doWis then
      attributes.willpower(self).modifier = attributes.willpower(self).modifier + modVal
    end
  end
end
local function phyMod(modVal)
  if modType == 1 then
    if doAgi then
      attributes.agility(self).modifier = attributes.agility(self).modifier + modVal
    end
    if doSpd then
      attributes.speed(self).modifier = attributes.speed(self).modifier + modVal
    end
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local spellBuffTotal = {}
for i=1,maxStance,1 do 
  spellBuffTotal[i] = 0
end

-- save state to be removed on load
local function onSave()
    return{
      spellBuffTotal = spellBuffTotal
    }
end

local function onLoad(data)
  if data then
    spellBuffTotal = data.spellBuffTotal
    magMod(-spellBuffTotal[1])
    phyMod(-spellBuffTotal[2])
    for i=1,maxStance,1 do
      spellBuffTotal[i] = 0
    end
  end
end

local function staffCheck()
          local bugid = 0
  local staffEnchant = 0
  local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  if usedWeapon then -- not hand to hand
    if  not types.Lockpick.objectIsInstance(usedWeapon) and not types.Probe.objectIsInstance(usedWeapon) then
      local weaponType = Weapon.record(usedWeapon).type
      if weaponType == 5 then
        staffEnchant = Weapon.record(usedWeapon).value
        staffEnchant = math.log10(staffEnchant)
      end
    end
  end
  return(staffEnchant)
end

local function inputCheck(id) -- check if ID corresponds to potentially pulling out a weapon or spell
  if not core.isWorldPaused() then
    if id == input.ACTION.ToggleSpell 
    or id == input.ACTION.CycleSpellLeft 
    or id == input.ACTION.CycleSpellRight 
    or id == input.ACTION.ToggleWeapon 
    or id == input.ACTION.CycleWeaponLeft 
    or id == input.ACTION.CycleWeaponRight 
    or id == input.ACTION.QuickKey1 
    or id == input.ACTION.QuickKey2 
    or id == input.ACTION.QuickKey3 
    or id == input.ACTION.QuickKey4 
    or id == input.ACTION.QuickKey5 
    or id == input.ACTION.QuickKey6 
    or id == input.ACTION.QuickKey7 
    or id == input.ACTION.QuickKey8 
    or id == input.ACTION.QuickKey9 
    or id == input.ACTION.QuickKey10 
    or id == input.ACTION.Inventory then
      return(true)
    else
      return(false)
    end
  end
end

local staffEnchant = 1
local isWeapon = false -- true if in weapon stance 
local doBuff = false
return { 
  engineHandlers = { 
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,
    
    onInputAction = function(id)
      if enabled then
        if inputCheck(id) then
          if types.Actor.stance(self) == types.Actor.STANCE.Weapon then -- weapon ready/unready logic
            isWeapon = true
            if verbose and onStaffSwap and staffCheck()~=0 then
              ui.showMessage(stanceName[2])
            end
          elseif types.Actor.stance(self) ~= types.Actor.STANCE.Spell then -- if not weapon or spell
            isWeapon = false
            if verbose and onStaffSwap and staffCheck()~=0 then
              ui.showMessage('NO ' .. stanceName[2])
            end
          end          
          
          if types.Actor.stance(self) == types.Actor.STANCE.Spell then -- spell ready/unready logic
      if not doBuff then -- only buff if not buffed yet
              doBuff = true
              if onStaffSwap then -- only trigger if had a weapon out when swapped to spell? 
                if isWeapon then
                  doBuff = true
                else
                  doBuff = false
                end
              end
  
              staffEnchant = staffCheck()
              if doBuff and staffEnchant~=0 then -- must have staff equipped to buff
                if verbose then
                  ui.showMessage(stanceName[1])
                end
                local buffNext = hybridVal(spellBuff[1],staffEnchant,1)
                magMod(buffNext)
                spellBuffTotal[1] = spellBuffTotal[1] + buffNext
                if doTradeOffs then
                  buffNext = hybridVal(spellBuff[2],staffEnchant,1)
                  phyMod(buffNext)
                  spellBuffTotal[2] = spellBuffTotal[2] + buffNext
                end
              end
            end
          else -- debuff
            doBuff = false
            magMod(-spellBuffTotal[1])
            phyMod(-spellBuffTotal[2])
            spellBuffTotal = {0,0}     
          end
          
        end
      end
    end
  } 
}