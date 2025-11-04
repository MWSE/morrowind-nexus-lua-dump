-- Enchant Transfer — Global script (OpenMW 0.49/0.50)
-- Keeps the donor's current model/icon (from your mods), clears enchant on the donor,
-- resets the donor's value to a base-like value, and ADDS the donor enchant's value delta to the target.

local world = require('openmw.world')
local types = require('openmw.types')
local core  = require('openmw.core')

-- --------------------------- helpers ----------------------------------------

local function familyOf(obj)
  if types.Weapon.objectIsInstance(obj)   then return types.Weapon end
  if types.Armor.objectIsInstance(obj)    then return types.Armor  end
  if types.Clothing.objectIsInstance(obj) then return types.Clothing end
  return nil
end

local function isEmptyId(x) return x == nil or x == '' end

local function appendDisenchantedSuffix(name)
  name = name or ''
  if name:sub(-15) == ' (Disenchanted)' then return name end
  return name .. ' (Disenchanted)'  -- [fix] Lua concatenation is `..`
end

local function normPath(p)
  if not p or p == '' then return '' end
  return p:gsub('\\', '/'):lower()
end

-- produce a set of candidate model names by stripping common "unique" suffixes
local function modelCandidates(modelPath)
  local out = {}
  local p = normPath(modelPath)
  if p == '' then return out end
  out[#out+1] = p
  local stripped = p:gsub('_(uni%w*)%.nif$', '.nif'); if stripped ~= p then out[#out+1] = stripped end
  stripped = p:gsub('_(unique)%.nif$', '.nif');       if stripped ~= p then out[#out+1] = stripped end
  local chopped = p:gsub('_[^/_]+%.nif$', '.nif');    if chopped  ~= p then out[#out+1] = chopped  end
  return out
end

-- "core stat" equality (used as a last-resort base match)
local function eq(a,b) return a == b end
local function armorCoreEqual(a,b)
  return eq(a.type,b.type) and eq(a.baseArmor,b.baseArmor) and eq(a.health,b.health)
     and eq(a.weight,b.weight) and eq(a.enchantCapacity,b.enchantCapacity)
end
local function clothingCoreEqual(a,b)
  return eq(a.type,b.type) and eq(a.weight,b.weight) and eq(a.enchantCapacity,b.enchantCapacity)
end
local function weaponCoreEqual(a,b)
  return eq(a.type,b.type)
     and eq(a.chopMinDamage,b.chopMinDamage) and eq(a.chopMaxDamage,b.chopMaxDamage)
     and eq(a.slashMinDamage,b.slashMinDamage) and eq(a.slashMaxDamage,b.slashMaxDamage)
     and eq(a.thrustMinDamage,b.thrustMinDamage) and eq(a.thrustMaxDamage,b.thrustMaxDamage)
     and eq(a.speed,b.speed) and eq(a.reach,b.reach) and eq(a.weight,b.weight) and eq(a.health,b.health)
end
local function coreEqual(T,a,b)
  if T == types.Armor then return armorCoreEqual(a,b)
  elseif T == types.Clothing then return clothingCoreEqual(a,b)
  else return weaponCoreEqual(a,b) end
end

-- lowest value among unenchanted records of same family + slot (type)
local function minValueForFamilySlot(T, donorRec)
  local minV
  local records = T.records
  for i = 1, #records do
    local r = records[i]
    if isEmptyId(r.enchant) and r.type == donorRec.type then
      local v = r.value or 0
      if not minV or v < minV then minV = v end
    end
  end
  return minV or (donorRec.value or 0)
end

-- find the *base* by (1) model variants, (2) icon, (3) core stats; choose the lowest value match
local function findBaseRecordSmart(T, donorRec)
  local recs = T.records
  local donorModel   = normPath(donorRec.model)
  local donorIcon    = normPath(donorRec.icon)
  local modelKeys    = modelCandidates(donorModel)
  local bestModel, bestModelValue
  local bestIcon,  bestIconValue
  local bestCore,  bestCoreValue

  for i = 1, #recs do
    local r = recs[i]
    if isEmptyId(r.enchant) and r.type == donorRec.type then
      local v = r.value or 0
      local rModel = normPath(r.model)
      local rIcon  = normPath(r.icon)

      for _, key in ipairs(modelKeys) do
        if key ~= '' and rModel == key then
          if not bestModel or v < bestModelValue then bestModel, bestModelValue = r, v end
          break
        end
      end
      if donorIcon ~= '' and rIcon ~= '' and rIcon == donorIcon then
        if not bestIcon or v < bestIconValue then bestIcon, bestIconValue = r, v end
      end
      if coreEqual(T, r, donorRec) then
        if not bestCore or v < bestCoreValue then bestCore, bestCoreValue = r, v end
      end
    end
  end

  return bestModel or bestIcon or bestCore
end

-- Build a record from a template, overriding name/enchant and optionally value.
-- Setting enchant="" explicitly clears an inherited enchant when templating from an enchanted record.
local function buildFromTemplate(T, templateRec, overrides)
  overrides = overrides or {}
  local clearEnchant    = overrides.clearEnchant or false
  local nameOverride    = overrides.name
  local enchantOverride = overrides.enchant -- may be nil
  local valueOverride   = overrides.value   -- may be nil

  if T == types.Armor then
    local draft = types.Armor.createRecordDraft({
      template = templateRec,
      name     = nameOverride or templateRec.name,
      enchant  = clearEnchant and "" or enchantOverride,
      value    = valueOverride,
    })
    return world.createRecord(draft)
  elseif T == types.Clothing then
    local draft = types.Clothing.createRecordDraft({
      template = templateRec,
      name     = nameOverride or templateRec.name,
      enchant  = clearEnchant and "" or enchantOverride,
      value    = valueOverride,
    })
    return world.createRecord(draft)
  else -- Weapon
    local draft = types.Weapon.createRecordDraft({
      template = templateRec,
      name     = nameOverride or templateRec.name,
      enchant  = clearEnchant and "" or enchantOverride,
      value    = valueOverride,
    })
    return world.createRecord(draft)
  end
end

-- Replace one instance; preserve condition and charge if asked (clamp condition to max health)
local function replaceOne(oldObj, newRecordId, opts)
  local container = oldObj.parentContainer
  if not container then return nil end

  local newObj = world.createObject(newRecordId, 1)
  newObj:moveInto(container)

  local src = types.Item.itemData(oldObj)
  local dst = types.Item.itemData(newObj)

  if opts and opts.copyCondition and src.condition ~= nil then
    local maxHealth
    if types.Weapon.objectIsInstance(newObj) then
      maxHealth = types.Weapon.record(newObj).health
    elseif types.Armor.objectIsInstance(newObj) then
      maxHealth = types.Armor.record(newObj).health
    end
    if maxHealth then
      dst.condition = math.min(src.condition, maxHealth)
    else
      dst.condition = src.condition
    end
  end

  if opts and opts.copyChargeFrom then
    local donorData = types.Item.itemData(opts.copyChargeFrom)
    dst.enchantmentCharge = donorData.enchantmentCharge
  end
  if opts and opts.resetCharge then
    dst.enchantmentCharge = nil
  end

  oldObj:remove(1)
  return newObj
end

local function sendToPlayer(event, payload)
  local p = world.players and world.players[1]
  if p and p.isValid and p:isValid() then
    p:sendEvent(event, payload)
  else
    core.sendGlobalEvent(event, payload)
  end
end

-- --------------------- enchantment compatibility -----------------------------

local ENCH = core.magic.ENCHANTMENT_TYPE

local function isArmorOrClothing(T)
  return (T == types.Armor) or (T == types.Clothing)
end

-- Only used for Armor/Clothing, but kept generic for clarity
local function isEnchantmentAllowedFor(Ttarget, enchType)
  if Ttarget == types.Weapon then
    -- keep weapons weapon-only behavior (we don't cross to/from them in this mod)
    return (enchType == ENCH.CastOnStrike) or (enchType == ENCH.CastOnUse) or (enchType == ENCH.CastOnce)
  else
    -- Armor & Clothing can sensibly use CastOnUse and ConstantEffect
    return (enchType == ENCH.CastOnUse) or (enchType == ENCH.ConstantEffect)
  end
end

-- Compute the donor enchantment's price delta (how much its enchant raised price over a base-like unenchanted record)
local function computeDonorPriceDelta(Tdonor, donorRec)
  local baseRec = findBaseRecordSmart(Tdonor, donorRec)
  local baseLikeValue = baseRec and baseRec.value or minValueForFamilySlot(Tdonor, donorRec)
  local donorV = donorRec.value or 0
  local baseV  = baseLikeValue or 0
  local delta  = math.max(0, donorV - baseV)
  return delta, baseLikeValue
end

-- ------------------------- event handlers -----------------------------------

local eventHandlers = {}

eventHandlers.ET_DoTransfer = function(data)
  if not data or not data.donor or not data.target then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Missing donor or target.' })
    return
  end

  local donor, target = data.donor, data.target
  if not donor:isValid() or not target:isValid() then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Item(s) are not valid.' })
    return
  end

  local Tdonor, Ttarget = familyOf(donor), familyOf(target)
  if not Tdonor or not Ttarget then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Unsupported item type(s).' })
    return
  end

  -- allow Armor<->Clothing cross-family; keep weapons isolated
  local sameFamily = (Tdonor == Ttarget)
  local armorClothMix = isArmorOrClothing(Tdonor) and isArmorOrClothing(Ttarget)
  if not (sameFamily or armorClothMix) then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Weapons can only transfer to weapons; armor/clothing can transfer between each other.' })
    return
  end

  if donor.parentContainer ~= target.parentContainer then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Items must be in the same container.' })
    return
  end

  local donorRec  = Tdonor.record(donor)
  local targetRec = Ttarget.record(target)
  if isEmptyId(donorRec.enchant) then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Donor must be enchanted.' })
    return
  end
  if not isEmptyId(targetRec.enchant) then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Target must be unenchanted.' })
    return
  end

  -- enforce enchantment-type compatibility for the target family
  local ench = core.magic.enchantments.records[donorRec.enchant]
  if not ench then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Donor enchantment record not found.' })
    return
  end
  if not isEnchantmentAllowedFor(Ttarget, ench.type) then
    local msg = '[Enchant Transfer] This enchantment type is not valid for the target item.'
    sendToPlayer('ET_Result', { ok = false, message = msg })
    return
  end

  -- Price delta from donor's enchant
  local delta, baseLikeValue = computeDonorPriceDelta(Tdonor, donorRec)

  -- Names
  local newNameForTarget     = (data.newName and data.newName ~= '' and data.newName) or targetRec.name
  local donorReplacementName = appendDisenchantedSuffix(donorRec.name)

  -- 1) Create target record = target + donor's enchant (target visuals preserved)
  --    Add the donor's enchantment price delta to the target's base value.
  local newTargetValue = (targetRec.value or 0) + delta
  local newTargetRecord = buildFromTemplate(Ttarget, targetRec, {
    enchant = donorRec.enchant,
    name    = newNameForTarget,
    value   = newTargetValue,
  })
  if not newTargetRecord then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Failed to create target record.' })
    return
  end

  -- 2) Donor replacement:
  --    * KEEP donor's visuals by templating from the DONOR (so we use the currently installed model/icon/biped).
  --    * CLEAR enchant.
  --    * OVERRIDE value to the base value (from smart base match or a base-like minimum).
  local donorReplacementRecord = buildFromTemplate(Tdonor, donorRec, {
    name         = donorReplacementName,
    clearEnchant = true,         -- forces enchant to be removed even if template had one
    value        = baseLikeValue -- resets gold value to something sane
  })
  if not donorReplacementRecord then
    sendToPlayer('ET_Result', { ok = false, message = '[Enchant Transfer] Failed to create donor replacement record.' })
    return
  end

  -- 3) Swap instances
  replaceOne(target, newTargetRecord.id, { copyCondition = true, copyChargeFrom = donor })
  replaceOne(donor,  donorReplacementRecord.id, { copyCondition = true, resetCharge = true })

  local msg = ('[Enchant Transfer] Success! Enchantment moved to target; donor kept its visuals but lost enchant. Target value set to %d.'):format(newTargetValue)
  sendToPlayer('ET_Result', { ok = true, message = msg })
end

return { eventHandlers = eventHandlers }
