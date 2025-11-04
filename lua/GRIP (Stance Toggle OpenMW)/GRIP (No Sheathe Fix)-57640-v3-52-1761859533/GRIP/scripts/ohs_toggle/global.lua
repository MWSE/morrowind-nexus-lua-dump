-- scripts/ohs_toggle/global.lua (OpenMW 0.49/0.50)
-- 1H↔2H toggle (reach preserved), Short Blade→(2H) cheat,
-- Blunt(1H)→(2H) uses LongBladeTwoHand (longsword trick; fixes grip),
-- durability & enchant-charge preservation,
-- Great Feather (encumbrance fix) during swaps,
-- NO bound-weapon conversions or guards.
-- Hardened for non-weapon right-hand items (lockpicks/probes/etc).

local world  = require('openmw.world')
local types  = require('openmw.types')
local core   = require('openmw.core')
local store  = require('openmw.storage')

local EQUIP  = types.Actor.EQUIPMENT_SLOT
local WTYPE  = types.Weapon.TYPE

-- Name tags
local SUFFIX_1H = ' (1H)'
local SUFFIX_2H = ' (2H)'

-- Settings
local SETTINGS_GROUP = 'SettingsOHS_Toggle'
local settings       = store.globalSection(SETTINGS_GROUP)

-- Anti-overencumbrance Feather (temporary while swapping)
local FEATHER_RECORD   = 'great feather'
local FEATHER_TAG_NAME = 'OHS Swap Feather'

-- Persistent record maps
-- NOTE: enchant-aware buckets per base id
local state = { baseTo = {}, varTo = {} }

-- ===== Utils =====
local function lower(s) return type(s) == 'string' and s:lower() or s end
local function endswith(s, suf) return s and suf and s:sub(-#suf) == suf end
local function dbgEnabled() return settings and settings:get('DebugLog') == true end
local function dbg(...) if dbgEnabled() then print('[OHS][GLOBAL]', ...) end end

-- Announce debug flips immediately (quality-of-life)
local _dbgLast
local function pollDebugFlip()
  local cur = dbgEnabled()
  if _dbgLast == nil then _dbgLast = cur; return end
  if cur ~= _dbgLast then
    print('[OHS][GLOBAL]', 'Debug logging ' .. (cur and 'ENABLED' or 'DISABLED'))
    _dbgLast = cur
  end
end

local function actorInv(actor)
  local inv = types.Actor.inventory(actor)
  if inv and not inv:isResolved() then inv:resolve() end
  return inv
end

-- SAFE: returns Weapon record of right-hand item, or nil if not a Weapon (lockpick/probe/etc.)
local function rightHandWeaponRecord(actor)
  local eq = types.Actor.getEquipment(actor)
  local rh = eq and eq[EQUIP.CarriedRight] or nil
  if not (rh and rh:isValid()) then return nil end
  if not types.Weapon.objectIsInstance(rh) then return nil end
  return types.Weapon.record(rh)
end

-- Bound check
local function isBoundLike(rec)
  if not rec then return false end
  local name = (rec.name or '')
  local id   = (rec.id or '')
  return (name:lower():find('bound', 1, true) ~= nil) or (id:lower():find('bound', 1, true) ~= nil)
end

-- ===== Great Feather helpers =====
local function findSwapFeatherId(actor)
  for k, sp in pairs(types.Actor.activeSpells(actor)) do
    if sp and sp.name == FEATHER_TAG_NAME and sp.id == FEATHER_RECORD then
      return sp.activeSpellId or k
    end
  end
  return nil
end
local function addSwapFeather(actor)
  if not (actor and actor:isValid()) then return end
  if findSwapFeatherId(actor) ~= nil then return end
  types.Actor.activeSpells(actor):add{ id = FEATHER_RECORD, effects = { 0 }, name = FEATHER_TAG_NAME, caster = actor }
  dbg('Added swap Feather for', actor.recordId)
end
local function removeSwapFeather(actor)
  if not (actor and actor:isValid()) then return end
  local actives = types.Actor.activeSpells(actor)
  for k, sp in pairs(actives) do
    if sp and sp.name == FEATHER_TAG_NAME and sp.id == FEATHER_RECORD then
      actives:remove(sp.activeSpellId or k)
    end
  end
end

-- ===== Durability/charge transfer =====
local function preserveDurabilityAndCharge(oldObj, newObj)
  if not (oldObj and oldObj:isValid()) then return end
  if not (newObj and newObj:isValid()) then return end
  local oldRec, newRec = types.Weapon.record(oldObj), types.Weapon.record(newObj)
  if not (oldRec and newRec) then return end
  local oldData, newData = types.Item.itemData(oldObj), types.Item.itemData(newObj)
  if not (oldData and newData) then return end

  -- Preserve % condition
  local oldMaxHealth, newMaxHealth = oldRec.health or 0, newRec.health or 0
  if oldMaxHealth > 0 and newMaxHealth > 0 then
    local pct = (oldData.condition or oldMaxHealth) / oldMaxHealth
    local cond = math.floor(pct * newMaxHealth + 0.5)
    if cond < 1 and (oldData.condition or 0) > 0 then cond = 1 end
    newData.condition = cond
  end

  -- Preserve enchantment charge (capacity read from Enchantment record)
  if oldRec.enchant and newRec.enchant then
    local oldEnc = core.magic.enchantments.records[oldRec.enchant]
    local newEnc = core.magic.enchantments.records[newRec.enchant]
    local oldMax = (oldEnc and oldEnc.charge) or 0
    local newMax = (newEnc and newEnc.charge) or 0
    if newMax > 0 then
      local oldCharge = oldData.enchantmentCharge
      local src = (oldCharge == nil) and oldMax or oldCharge
      if src > newMax then src = newMax end
      if src < 0 then src = 0 end
      newData.enchantmentCharge = math.floor(src + 0.5)
    end
  end
end

-- Create instance in inventory
local function getOrCreateObject(actor, recordId)
  local inv = actorInv(actor)
  local obj = inv:find(recordId)
  if obj then return obj end
  local newObj = world.createObject(recordId, 1)
  newObj:moveInto(inv)
  return newObj
end

local function requestEquip(actor, newObj, oldObj, note)
  if not (newObj and newObj:isValid()) then return end
  pcall(preserveDurabilityAndCharge, oldObj, newObj)
  addSwapFeather(actor)
  actor:sendEvent('OHS_LocalEquip', { object = newObj, old = oldObj, note = note })
end

local function roundNonNeg(n) n = n or 0; n = math.floor(n + 0.5); if n < 0 then n = 0 end; return n end

-- ========= enchant-aware helpers & record reuse =========
local function _lowerIdOrNone(id)
  if id == nil or id == '' then return '_none' end
  return string.lower(id)
end

-- Require name+type+(optional health)+enchant to match
local function preferExistingByNameAndType(name, typeId, wantHealth, wantEnchantId)
  local wantEnc = _lowerIdOrNone(wantEnchantId)
  for _, r in ipairs(types.Weapon.records) do
    if r.name == name and r.type == typeId then
      if wantHealth == nil or (r.health or 0) == (wantHealth or 0) then
        local rEnc = _lowerIdOrNone(r.enchant)
        if rEnc == wantEnc then
          return r.id
        end
      end
    end
  end
  return nil
end

-- Per-(base,enchant) buckets on state.baseTo[baseLower]
local function _getEnchantCache(baseLower)
  state.baseTo[baseLower] = state.baseTo[baseLower] or {}
  local bucket = state.baseTo[baseLower]
  bucket.longByEnchant   = bucket.longByEnchant   or {}
  bucket.twoByEnchant    = bucket.twoByEnchant    or {}
  -- sheathByEnchant left in place for compatibility (we no longer write to it)
  bucket.sheathByEnchant = bucket.sheathByEnchant or {}
  return bucket
end

-- Robust resolver from a variant record back to its base record
local function resolveBaseRecordFromVariant(variantRec)
  if not variantRec then return nil end
  local ridLower = lower(variantRec.id)

  -- map back-pointer
  local var = state.varTo[ridLower]
  if var and var.base then
    local rec = types.Weapon.record(var.base)
    if rec then return rec end
  end

  -- search caches
  for baseLower, bucket in pairs(state.baseTo) do
    if bucket then
      for _, vid in pairs(bucket.longByEnchant or {}) do
        if lower(vid) == ridLower then
          local rec = types.Weapon.record(baseLower)
          if rec then return rec end
        end
      end
      for _, vid in pairs(bucket.twoByEnchant or {}) do
        if lower(vid) == ridLower then
          local rec = types.Weapon.record(baseLower)
          if rec then return rec end
        end
      end
      -- sheath cache check left for save-compat only (we no longer create sheath records)
      for _, vid in pairs(bucket.sheathByEnchant or {}) do
        if lower(vid) == ridLower then
          local rec = types.Weapon.record(baseLower)
          if rec then return rec end
        end
      end
    end
  end

  -- name fallback (prefer same enchant)
  local name = variantRec.name or variantRec.id or ''
  local baseName = name
  if endswith(name, SUFFIX_1H) then baseName = name:sub(1, #name - #SUFFIX_1H)
  elseif endswith(name, SUFFIX_2H) then baseName = name:sub(1, #name - #SUFFIX_2H)
  end
  local encKey = _lowerIdOrNone(variantRec.enchant)
  local fallback
  for _, r in ipairs(types.Weapon.records) do
    if r.name == baseName and not endswith(r.name, SUFFIX_1H) and not endswith(r.name, SUFFIX_2H) then
      if _lowerIdOrNone(r.enchant) == encKey then
        return r
      end
      if not fallback then fallback = r end
    end
  end
  return fallback
end

-- ========= type mapping =========
local function mapTargetType(baseRec, style) -- '1H' | '2H'
  local t = baseRec.type
  if style == '1H' then
    if t == WTYPE.SpearTwoWide          then return WTYPE.LongBladeOneHand end
    if t == WTYPE.LongBladeTwoHand      then return WTYPE.LongBladeOneHand end
    if t == WTYPE.AxeTwoHand            then return WTYPE.AxeOneHand end
    if t == WTYPE.BluntTwoClose or t == WTYPE.BluntTwoWide then return WTYPE.BluntOneHand end
    return nil
  else
    if t == WTYPE.LongBladeOneHand      then return WTYPE.LongBladeTwoHand end
    if t == WTYPE.AxeOneHand            then return WTYPE.AxeTwoHand end
    if t == WTYPE.BluntOneHand          then return WTYPE.LongBladeTwoHand end -- longsword trick
    if t == WTYPE.ShortBladeOneHand     then return WTYPE.LongBladeTwoHand end -- cheat
    return nil
  end
end

-- ========= 1H variant (enchant-aware) =========
local function ensureLongVariant(baseRec)
  local baseLower  = lower(baseRec.id)
  local baseHealth = baseRec.health or 0
  local encKey     = _lowerIdOrNone(baseRec.enchant)

  local targetType = mapTargetType(baseRec, '1H') or WTYPE.LongBladeOneHand
  local bucket     = _getEnchantCache(baseLower)

  local cachedId = bucket.longByEnchant[encKey]
  if cachedId then
    local rec = types.Weapon.record(cachedId)
    if rec and (rec.health or 0) == baseHealth and rec.type == targetType and _lowerIdOrNone(rec.enchant) == encKey then
      return cachedId
    else
      bucket.longByEnchant[encKey] = nil
    end
  end

  local targetName  = ((baseRec.name and #baseRec.name>0) and baseRec.name or baseRec.id) .. SUFFIX_1H
  local tryExisting = preferExistingByNameAndType(targetName, targetType, baseHealth, baseRec.enchant)

  local id
  if tryExisting then
    id = tryExisting
  else
    local mult = tonumber(settings:get('OneHandDamageMult')) or 0.85
    local function dm(n) return roundNonNeg((n or 0) * mult) end
    local draft = types.Weapon.createRecordDraft({
      template = baseRec, name = targetName, type = targetType,
      thrustMinDamage  = dm(baseRec.thrustMinDamage), thrustMaxDamage = dm(baseRec.thrustMaxDamage),
      slashMinDamage   = dm(baseRec.slashMinDamage),  slashMaxDamage  = dm(baseRec.slashMaxDamage),
      chopMinDamage    = dm(baseRec.chopMinDamage),   chopMaxDamage   = dm(baseRec.chopMaxDamage),
      enchant          = baseRec.enchant, enchantCapacity = baseRec.enchantCapacity or 0,
      weight           = baseRec.weight, value = baseRec.value, health = baseRec.health,
      reach            = baseRec.reach, speed = baseRec.speed,
    })
    id = world.createRecord(draft).id
    dbg('Created (1H)', baseRec.id, '->', id, 'mult=', tostring(mult))
  end

  local ridLower  = lower(id)
  bucket.longByEnchant[encKey] = id
  state.varTo[ridLower] = { base = baseLower, role = 'long', needsSheatheFix = false } -- sheath flag hard-disabled
  return id
end

-- ========= 2H variant (enchant-aware) =========
local function ensureTwoHandVariant(baseRec)
  local baseLower  = lower(baseRec.id)
  local baseHealth = baseRec.health or 0
  local encKey     = _lowerIdOrNone(baseRec.enchant)

  local targetType = mapTargetType(baseRec, '2H')
  if not targetType then return nil end

  local bucket  = _getEnchantCache(baseLower)
  local cachedId = bucket.twoByEnchant[encKey]
  if cachedId then
    local rec = types.Weapon.record(cachedId)
    if rec and (rec.health or 0) == baseHealth and rec.type == targetType and _lowerIdOrNone(rec.enchant) == encKey then
      return cachedId
    else
      bucket.twoByEnchant[encKey] = nil
    end
  end

  local targetName  = ((baseRec.name and #baseRec.name>0) and baseRec.name or baseRec.id) .. SUFFIX_2H
  local tryExisting = preferExistingByNameAndType(targetName, targetType, baseHealth, baseRec.enchant)

  local id
  if tryExisting then
    id = tryExisting
  else
    local mult = tonumber(settings:get('TwoHandDamageMult')) or 1.35
    local function dm(n) return roundNonNeg((n or 0) * mult) end
    local draft = types.Weapon.createRecordDraft({
      template = baseRec, name = targetName, type = targetType,
      thrustMinDamage  = dm(baseRec.thrustMinDamage), thrustMaxDamage = dm(baseRec.thrustMaxDamage),
      slashMinDamage   = dm(baseRec.slashMinDamage),  slashMaxDamage  = dm(baseRec.slashMaxDamage),
      chopMinDamage    = dm(baseRec.chopMinDamage),   chopMaxDamage   = dm(baseRec.chopMaxDamage),
      enchant          = baseRec.enchant, enchantCapacity = baseRec.enchantCapacity or 0,
      weight           = baseRec.weight, value = baseRec.value, health = baseRec.health,
      reach            = baseRec.reach, speed = baseRec.speed,
    })
    id = world.createRecord(draft).id
    dbg('Created (2H)', baseRec.id, '->', id, 'mult=', tostring(mult), 'type=', tostring(targetType))
  end

  bucket.twoByEnchant[encKey] = id
  state.varTo[lower(id)] = { base = baseLower, role = 'two', needsSheatheFix = false }
  return id
end

-- ===== Toggle =====
local function toggleNow(actor)
  local rec = rightHandWeaponRecord(actor)
  if not rec then
    actor:sendEvent('OHS_ShowMessage', { text = 'Equip a weapon to use the stance toggle.' })
    return
  end
  dbg('Toggle pressed with', rec.id, 'type', tostring(rec.type))

  if isBoundLike(rec) then
    actor:sendEvent('OHS_ShowMessage', { text = 'Bound weapons cannot be changed.' })
    return
  end

  local name     = rec.name or rec.id or ''
  local ridLower = lower(rec.id)

  -- Our (1H) → Base
  if endswith(name, SUFFIX_1H) then
    local baseRec = resolveBaseRecordFromVariant(rec)
    if baseRec and lower(baseRec.id) ~= ridLower then
      local eq = types.Actor.getEquipment(actor)
      local cur = eq and eq[EQUIP.CarriedRight]
      if cur and cur:isValid() then
        requestEquip(actor, getOrCreateObject(actor, baseRec.id), cur)
      end
    end
    return
  end

  -- Our (2H) → Base
  if endswith(name, SUFFIX_2H) then
    local baseRec = resolveBaseRecordFromVariant(rec)
    if baseRec and lower(baseRec.id) ~= ridLower then
      local eq = types.Actor.getEquipment(actor)
      local cur = eq and eq[EQUIP.CarriedRight]
      if cur and cur:isValid() then
        requestEquip(actor, getOrCreateObject(actor, baseRec.id), cur)
      end
    end
    return
  end

  -- Base 2H → (1H)
  if rec.type == WTYPE.SpearTwoWide
     or rec.type == WTYPE.LongBladeTwoHand
     or rec.type == WTYPE.AxeTwoHand
     or rec.type == WTYPE.BluntTwoClose
     or rec.type == WTYPE.BluntTwoWide then
    local longId = ensureLongVariant(rec)
    if longId and lower(longId) ~= ridLower then
      local eq = types.Actor.getEquipment(actor)
      local cur = eq and eq[EQUIP.CarriedRight]
      if cur and cur:isValid() then
        requestEquip(actor, getOrCreateObject(actor, longId), cur)
      end
    end
    return
  end

  -- Base 1H → (2H)
  if rec.type == WTYPE.LongBladeOneHand
     or rec.type == WTYPE.AxeOneHand
     or rec.type == WTYPE.BluntOneHand
     or rec.type == WTYPE.ShortBladeOneHand then
    local twoId = ensureTwoHandVariant(rec)
    if not twoId then
      actor:sendEvent('OHS_ShowMessage', { text = 'This one-handed weapon cannot be two-handed.' })
      return
    end
    if lower(twoId) ~= ridLower then
      local eq = types.Actor.getEquipment(actor)
      local cur = eq and eq[EQUIP.CarriedRight]
      if cur and cur:isValid() then
        requestEquip(actor, getOrCreateObject(actor, twoId), cur)
      end
    end
    return
  end

  dbg('Toggle: unsupported base type for (2H):', rec.id, rec.type)
  actor:sendEvent('OHS_ShowMessage', { text = 'No two-hand variant for this weapon type.' })
end

-- ===== Engine / Events =====
return {
  engineHandlers = {
    onSave   = function() return state end,
    onLoad   = function(saved) if type(saved) == 'table' then state = saved end end,
    onUpdate = function(_) pollDebugFlip() end,
  },
  eventHandlers = {
    OHS_ToggleNow     = function(data)
      if dbgEnabled() then print('[OHS][GLOBAL]', 'Event: OHS_ToggleNow') end
      local a = data and data.actor; if a and a:isValid() then toggleNow(a) end
    end,
    -- OHS_StanceChanged removed (back-sheath swap disabled)
    OHS_RemoveObject  = function(data) local o = data and data.object; if o and o:isValid() then o:remove(1) end end,
    OHS_SwapComplete  = function(data) local a = data and data.actor; if a and a:isValid() then removeSwapFeather(a) end end,
  },
}
