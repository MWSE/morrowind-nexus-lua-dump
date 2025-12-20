-- scripts/ohs_toggle/global.lua (OpenMW 0.49)
-- 1H↔2H toggle (reach preserved), spear/staff sheath fix, Short Blade→(2H) cheat,
-- Blunt(1H)→(2H) uses LongBladeTwoHand (longsword trick; fixes grip),
-- durability & enchant-charge preservation,
-- Great Feather (encumbrance fix) during swaps,
-- NO bound-weapon conversions or guards.
-- Hardened for non-weapon right-hand items (lockpicks/probes/etc).

local core                                                          = require('openmw.core')
local store                                                         = require('openmw.storage')
local types                                                         = require('openmw.types')
local util                                                          = require 'openmw.util'
local world                                                         = require('openmw.world')

local EQUIP                                                         = types.Actor.EQUIPMENT_SLOT
local WTYPE                                                         = types.Weapon.TYPE
local STANCE                                                        = types.Actor.STANCE

-- Name tags
local SUFFIX_1H                                                     = ' (1H)'
local SUFFIX_2H                                                     = ' (2H)'

local OneHandedTypes, TwoHandedTypes, SheathFixTypes, WeaponTypeMap = {
  [WTYPE.LongBladeOneHand] = true,
  [WTYPE.AxeOneHand] = true,
  [WTYPE.BluntOneHand] = true,
  [WTYPE.ShortBladeOneHand] = true,
}, {
  [WTYPE.SpearTwoWide] = true,
  [WTYPE.LongBladeTwoHand] = true,
  [WTYPE.AxeTwoHand] = true,
  [WTYPE.BluntTwoClose] = true,
  [WTYPE.BluntTwoWide] = true,
}, {
  [WTYPE.SpearTwoWide] = true,
  [WTYPE.BluntTwoClose] = true,
  [WTYPE.BluntTwoWide] = true,
}, {
  ['1H'] = {
    [WTYPE.SpearTwoWide] = WTYPE.LongBladeOneHand,
    [WTYPE.LongBladeTwoHand] = WTYPE.LongBladeOneHand,
    [WTYPE.AxeTwoHand] = WTYPE.AxeOneHand,
    [WTYPE.BluntTwoClose] = WTYPE.BluntOneHand,
    [WTYPE.BluntTwoWide] = WTYPE.BluntOneHand,
  },
  ['2H'] = {
    [WTYPE.LongBladeOneHand] = WTYPE.LongBladeTwoHand,
    [WTYPE.AxeOneHand] = WTYPE.AxeTwoHand,
    [WTYPE.BluntOneHand] = WTYPE.LongBladeTwoHand,
    [WTYPE.ShortBladeOneHand] = WTYPE.LongBladeTwoHand,
  },
}

local DebugEnabled, OneHandDamageMult, TwoHandDamageMult            = false, nil, nil

local RecordMapStorage                                              = store.globalSection('GRIPRecords')
RecordMapStorage:setLifeTime(store.LIFE_TIME.Temporary)

local OldToNewRecords, NewToOldRecords = {}, {}
local NormalToSheath, SheathToNormal   = {}, {}

local EnchantRecords                   = core.magic.enchantments.records
local WeaponRecords, CreateWeaponDraft = types.Weapon.records, types.Weapon.createRecordDraft

local function dbg(...)
  if not DebugEnabled then return end
  print('[OHS][GLOBAL]', ...)
end

local function record(object)
  return object.type.records[object.recordId]
end

-- Simple bound check: if name or id contains "bound" (case-insensitive)
local function isBoundLike(rec)
  if not rec then return false end
  local name = (rec.name or '')
  local id   = (rec.id or '')
  return (name:lower():find('bound', 1, true) ~= nil)
      or (id:lower():find('bound', 1, true) ~= nil)
end

local function isStaffLikeTwoHand(rec)
  assert(rec)

  return (rec.name:lower() or rec.id):lower():find('staff', 1, true) ~= nil
end

local function needsSheatheFix(baseRec)
  local originalRecordId = NewToOldRecords[baseRec.id]
  if originalRecordId then
    baseRec = WeaponRecords[originalRecordId]
  end

  if not SheathFixTypes[baseRec.type] then return end

  if baseRec.type == WTYPE.SpearTwoWide then return true end

  return isStaffLikeTwoHand(baseRec)
end

local function itemData(item)
  assert(types.Item.objectIsInstance(item))
  return item.type.itemData(item)
end

local function updateRecordMaps(oldId, newId)
  OldToNewRecords[oldId] = newId
  RecordMapStorage:set('OldToNewRecords', OldToNewRecords)

  NewToOldRecords[newId] = oldId
  RecordMapStorage:set('NewToOldRecords', NewToOldRecords)
end

local function getId(thing)
  local idType, recordId = type(thing)

  if idType == 'string' then
    recordId = thing
  else
    local dataType = thing.__type.name

    if dataType == 'ESM::Weapon' then
      recordId = thing.id
    elseif dataType == 'MWLua::GObject' then
      recordId = thing.recordId
    else
      error('Wtf is this: ' .. thing.__type.name)
    end
  end

  return recordId
end

local function getReplacementRecord(id)
  local replacementId = OldToNewRecords[id]
  if not replacementId then return end
  return types.Weapon.records[replacementId]
end

local function getOriginalRecord(id)
  local originalId = NewToOldRecords[id]
  if not originalId then return end
  return types.Weapon.records[originalId]
end

-- ===== Durability/charge transfer (ENCHANTMENT max charge) =====
local function preserveDurabilityAndCharge(oldObj, newObj)
  local oldRec, newRec = record(oldObj), record(newObj)
  local oldData, newData = itemData(oldObj), itemData(newObj)

  assert(oldRec and newRec and oldData and newData)

  -- Preserve % condition
  local oldMaxHealth, newMaxHealth = oldRec.health or 0, newRec.health or 0
  if oldMaxHealth > 0 and newMaxHealth > 0 then
    local pct = (oldData.condition or oldMaxHealth) / oldMaxHealth
    local cond = math.floor(pct * newMaxHealth + 0.5)
    if cond < 1 and (oldData.condition or 0) > 0 then cond = 1 end
    newData.condition = cond
  end

  -- Preserve enchantment charge using ENCHANTMENT record charge (not item capacity).
  if not oldRec.enchant or not newRec.enchant then return end

  local oldEnc, newEnc = EnchantRecords[oldRec.enchant], EnchantRecords[newRec.enchant]

  local oldMax, newMax = oldEnc and oldEnc.charge or 0, newEnc and newEnc.charge or 0

  if newMax <= 0 then
    return
  end

  local oldCharge = oldData.enchantmentCharge
  local src = oldCharge and oldCharge or oldMax

  if src > newMax then
    src = newMax
  elseif src < 0 then
    src = 0
  end

  newData.enchantmentCharge = util.round(src)
end

local featherEffect = core.magic.EFFECT_TYPE.Feather
local function getOrCreateObject(actor, recordOrId)
  local inv = actor.type.inventory(actor)
  local recordId = getId(recordOrId)
  local obj = inv:find(recordId)
  if obj then return obj end

  local newObj = world.createObject(recordId, 1)
  newObj:moveInto(inv)

  return newObj
end

local function requestEquip(actor, newObj, oldObj, note)
  assert(newObj and newObj:isValid())

  preserveDurabilityAndCharge(oldObj, newObj)

  local weight = record(newObj).weight
  actor.type.activeEffects(actor):modify(weight, featherEffect)

  actor:sendEvent('OHS_LocalEquip',
    {
      object = newObj,
      old = oldObj,
      negateFeather = true,
    }
  )
end

local function roundNonNeg(n)
  return util.clamp(util.round(n or 0), 0, math.huge)
end

local function mapTargetType(baseRec, style)
  local styleMap = WeaponTypeMap[style]
  assert(styleMap)

  return styleMap[baseRec.type]
end

local function dm(n, multiplier)
  multiplier = multiplier or OneHandDamageMult
  return roundNonNeg((n or 0) * multiplier)
end

local function ensureWeaponVariant(baseRec, is2H)
  local existingReplacement = getReplacementRecord(baseRec.id)
  if existingReplacement then
    return existingReplacement
  end

  assert(baseRec.name)

  local currentSheathId = SheathToNormal[baseRec.id]
  local originalId, targetName = NewToOldRecords[baseRec.id], nil
  --- This is a replacement record, but not a sheath
  if originalId then
    targetName = WeaponRecords[originalId].name
    --- This is a sheath, but it could be a sheath for a replacement, or one for an original item
  elseif currentSheathId then
    local newReplacedBySheath = NewToOldRecords[currentSheathId]

    if newReplacedBySheath then
      targetName = WeaponRecords[newReplacedBySheath].name
    else
      targetName = WeaponRecords[currentSheathId].name
    end
  else
    --- Neither sheath, nor replacement, no name fuckery
    targetName = baseRec.name
  end

  targetName = targetName .. (is2H and SUFFIX_2H or SUFFIX_1H)

  local targetType = mapTargetType(baseRec, is2H and '2H' or '1H')
  assert(targetType)

  local mult = is2H and TwoHandDamageMult or OneHandDamageMult
  local draft = {
    template = baseRec,
    name = targetName,
    type = targetType,
  }

  for _, name in ipairs {
    'thrustMinDamage',
    'thrustMaxDamage',
    'slashMinDamage',
    'slashMaxDamage',
    'chopMinDamage',
    'chopMaxDamage'
  } do
    draft[name] = dm(baseRec[name], mult)
  end

  draft = CreateWeaponDraft(draft)

  local id = world.createRecord(draft).id

  updateRecordMaps(baseRec.id, id)

  dbg('Created (1H)', baseRec.id, '->', id, 'mult=', tostring(OneHandDamageMult))

  return id
end

local function ensureSheathVariant(baseRec)
  local oldId          = baseRec.id

  local existingSheath = NormalToSheath[baseRec.id]
  if existingSheath then
    return existingSheath
  end

  assert(baseRec.name and baseRec.name ~= '')
  local originalRecord  = getOriginalRecord(oldId)

  local newId           = world.createRecord(CreateWeaponDraft {
    template = baseRec,
    type = (originalRecord or {}).type
  }).id

  SheathToNormal[newId] = oldId
  RecordMapStorage:set('SheathToNormal', SheathToNormal)

  NormalToSheath[oldId] = newId
  RecordMapStorage:set('NormalToSheath', NormalToSheath)

  dbg('Created sheath marker', newId, 'for base', baseRec.id)
  return newId
end

-- ===== Toggle & stance =====
local function toggleNow(data)
  local actor, weapon = data.actor, data.weapon

  local unsheathed, weaponRecord = SheathToNormal[weapon.recordId], nil
  if unsheathed then
    weaponRecord = WeaponRecords[unsheathed]
  else
    weaponRecord = record(weapon)
  end

  dbg('Toggle pressed with', weaponRecord.id, 'type', tostring(weaponRecord.type))

  if isBoundLike(weaponRecord) then
    return actor:sendEvent('OHS_ShowMessage', { text = 'Bound weapons cannot be changed.' })
  end

  local currentId, newId   = weaponRecord.id, nil
  local oldToNew, newToOld = OldToNewRecords[currentId], NewToOldRecords[currentId]
  if oldToNew then
    newId = oldToNew
  elseif newToOld then
    newId = newToOld
  elseif TwoHandedTypes[weaponRecord.type] then
    newId = ensureWeaponVariant(weaponRecord, false)
  elseif OneHandedTypes[weaponRecord.type] then
    newId = ensureWeaponVariant(weaponRecord, true)
  else
    dbg('Toggle: unsupported base type for (2H):', weaponRecord.id, weaponRecord.type)
    return actor:sendEvent('OHS_ShowMessage', { text = 'No two-hand variant for this weapon type.' })
  end

  if not newId or newId == currentId then return end

  local originalId = NewToOldRecords[newId]

  --- If we're not currently drawing a weapon,
  --- and the current weapon is a replacement, and it's NOT a sheath,
  --- switch the ID out for a sheath-friendly alternative
  if
      actor.type.getStance(actor) == actor.type.STANCE.Nothing
      and originalId
      and not SheathToNormal[weapon.recordId]
  then
    local originalRecord = WeaponRecords[originalId]

    if needsSheatheFix(originalRecord) then
      local variant = ensureSheathVariant(WeaponRecords[newId])

      if type(variant) == 'string' then
        newId = variant
      elseif variant then
        newId = variant.id
      end
    end
  end

  local currentWeapon = types.Actor.getEquipment(actor, EQUIP.CarriedRight)
  if not currentWeapon then return end

  requestEquip(actor, getOrCreateObject(actor, newId), currentWeapon)
end

local function onStanceChanged(data)
  local actor, newStance, weapon = data.actor, data.new, data.weapon

  local weaponRecord = record(weapon)
  if isBoundLike(weaponRecord) then return end

  local newId
  if newStance == STANCE.Nothing then
    if not OneHandedTypes[weaponRecord.type] or not needsSheatheFix(weaponRecord) then return end

    newId = ensureSheathVariant(weaponRecord)
  elseif newStance == STANCE.Weapon then
    newId = SheathToNormal[weapon.recordId]
  end

  if not newId then return end

  requestEquip(actor, getOrCreateObject(actor, newId), weapon)
end

return {
  engineHandlers = {
    onSave = function()
      return {
        OldToNewRecords = OldToNewRecords,
        NewToOldRecords = NewToOldRecords,
        NormalToSheath = NormalToSheath,
        SheathToNormal = SheathToNormal,
      }
    end,
    onLoad = function(saved)
      saved = saved or {}

      local newToOld = saved.NewToOldRecords or {}
      RecordMapStorage:set('NewToOldRecords', newToOld)
      NewToOldRecords = newToOld

      local oldToNew = saved.OldToNewRecords or {}
      RecordMapStorage:set('OldToNewRecords', oldToNew)
      OldToNewRecords = oldToNew

      local normalToSheath = saved.NormalToSheath or {}
      RecordMapStorage:set('NormalToSheath', normalToSheath)
      NormalToSheath = normalToSheath

      local sheathToNormal = saved.SheathToNormal or {}
      RecordMapStorage:set('SheathToNormal', sheathToNormal)
      SheathToNormal = sheathToNormal

      for _, player in ipairs(world.players) do
        player.type.sendMenuEvent(player, 'OHS_RequestGlobalData')
      end
    end,
  },
  eventHandlers = {
    OHS_ToggleNow        = toggleNow,
    OHS_StanceChanged    = onStanceChanged,
    OHS_RemoveObject     = function(object)
      assert(object and object:isValid())
      object:remove(1)
    end,
    OHS_UpdateGlobalData = function(data)
      dbg(
        ('Updating damage multipliers: One Hand: %.2f, Two Hand: %.2f')
        :format(
          data.OneHandDamageMult,
          data.TwoHandDamageMult
        )
      )
      DebugEnabled = data.DebugLog
      OneHandDamageMult = data.OneHandDamageMult
      TwoHandDamageMult = data.TwoHandDamageMult
    end,
  },
}
