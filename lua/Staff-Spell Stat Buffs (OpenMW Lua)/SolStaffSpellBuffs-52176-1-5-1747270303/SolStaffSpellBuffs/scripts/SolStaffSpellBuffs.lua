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
  key = 'SolStaffSpellBuffs',
  l10n = 'SolStaffSpellBuffs',
  name = 'name',
  description = 'description',
})
-- default values!
local enabled = true
local onStaffSwap = true -- if you need to swap off staff
local doTradeOffs = true
local verbose = false
local sfxVolume = 1.0
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
  permanentStorage = true,
  settings = {
    boolSetting('enabled', enabled),
    boolSetting('verbose', verbose),
    numbSetting('sfxVolume', sfxVolume, false, 0.0, 2.0),
    boolSetting('onStaffSwap', onStaffSwap),
    numbSetting('buffBase', buffBase, true, 1, 20),
    boolSetting('doTradeOffs', doTradeOffs),
    numbSetting('tradeoffMult', tradeoffMult, false, 0.0, 2.0),
    boolSetting('doInt', doInt),
    boolSetting('doWis', doWis),
    boolSetting('doAgi', doAgi),
    boolSetting('doSpd', doSpd),
  },
})
local settingsGroup = storage.playerSection('Settings_sol_StaffSpellBuff')

-- shorthand for convenience
local Weapon = types.Weapon
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills

-- reduce effectiveness of hybrid stances
local function hybridVal(base, mult, count)
  return math.ceil(base * mult ^ math.max(count, 0))
end

-- script config
-- and store stance idxs for indexing into tables
local stanceIndex = { spell = 1, staff = 2 }
local maxStance = 0
for _ in pairs(stanceIndex) do
  maxStance = maxStance + 1
end

-- init to defaults
local buffDown = hybridVal(buffBase, -tradeoffMult, 1)
local spellBuff = { buffBase, buffDown }
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  sfxVolume = settingsGroup:get('sfxVolume')
  onStaffSwap = settingsGroup:get('onStaffSwap')
  buffBase = settingsGroup:get('buffBase')
  doInt = settingsGroup:get('doInt')
  doWis = settingsGroup:get('doWis')
  doTradeOffs = settingsGroup:get('doTradeOffs')
  tradeoffMult = settingsGroup:get('tradeoffMult')
  doAgi = settingsGroup:get('doAgi')
  doSpd = settingsGroup:get('doSpd')
  -- calculate new buff vals
  buffDown = hybridVal(buffBase, -tradeoffMult, 1)
  spellBuff = { buffBase, buffDown }
end
local function init()
  updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- stance names for verbose
local stanceName = { 'SPELL', 'STAFF' }

-- stance effects
local function magMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    if doInt then
      attributes.intelligence(self).modifier = math.max(0, attributes.intelligence(self).modifier + modSign * modVal)
    end
    if doWis then
      attributes.willpower(self).modifier = math.max(0, attributes.willpower(self).modifier + modSign * modVal)
      if not doAgi then
        attributes.endurance(self).damage = math.max(0, attributes.endurance(self).damage + modSign * modVal)
      end
    end
  else
    modVal = math.abs(modVal)
    if doInt then
      attributes.intelligence(self).damage = math.max(0, attributes.intelligence(self).damage + modSign * modVal)
    end
    if doWis then
      attributes.willpower(self).damage = math.max(0, attributes.willpower(self).damage + modSign * modVal)
      if not doAgi then
        attributes.endurance(self).modifier = math.max(0, attributes.endurance(self).modifier + modSign * modVal)
      end
    end
  end
end
local function phyMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    if doSpd then
      attributes.speed(self).modifier = math.max(0, attributes.speed(self).modifier + modSign * math.ceil(0.5 * modVal))
      -- do athletics and acrobatics with speed, but give them each half impact
      skills.athletics(self).modifier = math.max(0, skills.athletics(self).modifier + modSign * math.ceil(0.5 * modVal))
      skills.acrobatics(self).modifier = math.max(0, skills.acrobatics(self).modifier + modSign * math.ceil(0.5 * modVal))
    end
    if doAgi then
      attributes.agility(self).modifier = math.max(0, attributes.agility(self).modifier + modSign * modVal)
      if not doWis then
        attributes.endurance(self).damage = math.max(0, attributes.endurance(self).damage + modSign * modVal)
      end
    end
  else
    modVal = math.abs(modVal)
    if doSpd then
      attributes.speed(self).damage = math.max(0, attributes.speed(self).damage + modSign * math.ceil(0.5 * modVal))
      -- do athletics and acrobatics with speed, but give them each half impact
      skills.athletics(self).damage = math.max(0, skills.athletics(self).damage + modSign * math.ceil(0.5 * modVal))
      skills.acrobatics(self).damage = math.max(0, skills.acrobatics(self).damage + modSign * math.ceil(0.5 * modVal))
    end
    if doAgi then
      attributes.agility(self).damage = math.max(0, attributes.agility(self).damage + modSign * modVal)
      if not doWis then
        attributes.endurance(self).modifier = math.max(0, attributes.endurance(self).modifier + modSign * modVal)
      end
    end
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local spellBuffTotal = {}
for i = 1, maxStance, 1 do
  spellBuffTotal[i] = 0
end

-- save state to be removed on load
local function onSave()
  return {
    spellBuffTotal = spellBuffTotal
  }
end

local function onLoad(data)
  if data then
    spellBuffTotal = data.spellBuffTotal
    magMod(-1, spellBuffTotal[1])
    phyMod(-1, spellBuffTotal[2])
    for i = 1, maxStance, 1 do
      spellBuffTotal[i] = 0
    end
  end
end

local function staffCheck()
  local staffEnchant = 0
  local usedWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  if usedWeapon then -- not hand to hand
    if not types.Lockpick.objectIsInstance(usedWeapon) and not types.Probe.objectIsInstance(usedWeapon) then
      local weaponType = Weapon.record(usedWeapon).type
      if weaponType == 5 then
        staffEnchant = Weapon.record(usedWeapon).value
        staffEnchant = math.log(staffEnchant, 10)
      end
    end
  end
  return (staffEnchant)
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
      return (true)
    else
      return (false)
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
            if onStaffSwap and staffCheck() ~= 0 then
              if verbose then
                ui.showMessage(stanceName[2])
              end
              if ambient and (sfxVolume > 0.0) then
                ambient.playSoundFile("sound/fx/magic/shield.wav",
                  { timeOffset = 0.6, volume = (0.7*sfxVolume), pitch = (0.55 + 0.1 * math.random()) })
              end
            end
          elseif types.Actor.stance(self) ~= types.Actor.STANCE.Spell then -- if not weapon or spell
            isWeapon = false
            --    if verbose and onStaffSwap and staffCheck()~=0 then
            --      ui.showMessage('NO ' .. stanceName[2])
            --    end
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
              if doBuff and staffEnchant ~= 0 then -- must have staff equipped to buff
                if verbose then
                  ui.showMessage(stanceName[1])
                end
                if ambient and (sfxVolume > 0.0) then
                  ambient.playSoundFile("sound/fx/magic/shield.wav",
                    { timeOffset = 0.4, volume = (0.9*sfxVolume), pitch = (0.75 + 0.1 * math.random()) })
                end
                local buffNext = hybridVal(spellBuff[1], staffEnchant, 1)
                magMod(1, buffNext)
                spellBuffTotal[1] = spellBuffTotal[1] + buffNext
                if doTradeOffs then
                  buffNext = hybridVal(spellBuff[2], staffEnchant, 1)
                  phyMod(1, buffNext)
                  spellBuffTotal[2] = spellBuffTotal[2] + buffNext
                end
              end
            end
          else -- debuff
            doBuff = false
            magMod(-1, spellBuffTotal[1])
            phyMod(-1, spellBuffTotal[2])
            spellBuffTotal = { 0, 0 }
          end
        end
      end
    end
  }
}
