-- scripts/steelfist/mirror.lua
-- GLOBAL: (1) receives MENU settings and writes them to global runtime storage
--         (2) casts the glove enchant (Self/Touch), drains charge, spawns VFX/SFX
--         (3) applies durability wear on the used glove
--         (4) NEW: strips out any Bound weapon/armor effects before casting or draining

local core    = require('openmw.core')
local types   = require('openmw.types')
local storage = require('openmw.storage')

local RUNTIME_KEY  = 'IronFistRuntime'
local EVENT_APPLY  = 'IronFistApplySettings'
local EVENT_ENCH   = 'SteelFist_ApplyEnchantOnHit' -- player.lua sends this

local function log(fmt, ...) print(('[IronFist][global] ' .. fmt):format(...)) end

-- 1) SETTINGS MIRROR
local function applySettings(values)
  if not values then return end
  local S = storage.globalSection(RUNTIME_KEY) -- GLOBAL can write
  for _, k in ipairs({
    'enabled','base','skillWeight','strWeight','condFloor',
    'heavyMult','mediumMult','lightMult','clothingMult',
    'armorBaseFactor',
    'detEnabled','detChance','detScale',
    'castEnchantOnHit','consumeEnchantCharge','debug',
  }) do
    local v = values[k]
    if v ~= nil then S:set(k, v) end
  end
  log('Settings applied (base=%.2f, baseArmor=%.2f, cast=%s, drain=%s)',
      values.base or -1, values.armorBaseFactor or -1,
      tostring(values.castEnchantOnHit), tostring(values.consumeEnchantCharge))
end

-- Helpers
local function getEnchantFromItem(item)
  if not (item and item:isValid()) then return nil end
  local rec
  if types.Armor.objectIsInstance(item) then
    rec = types.Armor.record(item)
  elseif types.Clothing.objectIsInstance(item) then
    rec = types.Clothing.record(item)
  end
  if rec and rec.enchant then
    return core.magic.enchantments.records[rec.enchant]
  end
  return nil
end

local function applyEnchEffects(who, item, idxList, caster)
  if not who or not who:isValid() then return end
  if not item or not item:isValid() then return end
  if not (idxList and #idxList > 0) then return end
  types.Actor.activeSpells(who):add({
    id        = item.recordId,
    effects   = idxList,   -- 0-based indices into the enchantment's effects
    caster    = caster,
    item      = item,
    stackable = false,
  })
end

local function tryDrainCharge(item, enchant)
  local idata = types.Item.itemData(item)
  if not idata then return false end
  local cost = (enchant and enchant.cost) or 0
  if cost <= 0 then return true end
  local cur = idata.enchantmentCharge or 0
  if cur < cost then return false end
  idata.enchantmentCharge = cur - cost
  return true
end

-- Block list for bound effects (see core.magic.EFFECT_TYPE)
local EFFECT = core.magic and core.magic.EFFECT_TYPE or {}
local BLOCKED_BOUND = {
  [EFFECT.BoundBattleAxe] = true,
  [EFFECT.BoundBoots]     = true,
  [EFFECT.BoundCuirass]   = true,
  [EFFECT.BoundDagger]    = true,
  [EFFECT.BoundGloves]    = true,
  [EFFECT.BoundHelm]      = true,
  [EFFECT.BoundLongbow]   = true,
  [EFFECT.BoundLongsword] = true,
  [EFFECT.BoundMace]      = true,
  [EFFECT.BoundShield]    = true,
  [EFFECT.BoundSpear]     = true,
}

-- Remove any indexes whose effect is a bound item spell
local function filterOutBound(enchant, idxList)
  if not (enchant and enchant.effects and idxList) then return {} end
  local out = {}
  for _, idx0 in ipairs(idxList) do
    local p = enchant.effects[idx0 + 1]
    if p and p.id and not BLOCKED_BOUND[p.id] then
      out[#out+1] = idx0
    end
  end
  return out
end

local function doTouchFxAndSfx(target, enchant, touchIdx)
  if not (target and target:isValid() and enchant and enchant.effects) then return end
  for _, idx0 in ipairs(touchIdx or {}) do
    local p = enchant.effects[idx0 + 1]
    if p and p.id then
      local mrec = core.magic.effects.records[p.id]
      if mrec then
        if mrec.hitStatic then
          local srec = types.Static.record(mrec.hitStatic)
          if srec and srec.model and srec.model ~= '' then
            target:sendEvent('AddVfx', { model = srec.model })
          end
        end
        if mrec.hitSound and mrec.hitSound ~= '' then
          core.sound.playSound3d(mrec.hitSound, target, { volume = 1.0 })
        end
      end
    end
  end
end

-- 2) ENCHANT + WEAR entry point from player.lua
local function onApplyEnchantOnHit(data)
  if not data or not (data.glove and data.glove:isValid()) then return end

  local glove   = data.glove
  local caster  = data.caster
  local target  = data.target
  local selfIdx = data.selfIdx or {}
  local touchIdx= data.touchIdx or {}
  local consume = data.consume
  local wearAmt = tonumber(data.wearAmt) or 0

  -- Wear regardless of charge / casting
  if wearAmt > 0 then
    local idata = types.Item.itemData(glove)
    if idata and idata.condition then
      idata.condition = math.max(0, idata.condition - wearAmt)
    end
  end

  local enchant = getEnchantFromItem(glove)
  if not enchant or enchant.type == (core.magic and core.magic.ENCHANTMENT_TYPE.ConstantEffect) then
    return
  end

  -- Extra safety: remove any bound effects (even if player.lua filtered already)
  selfIdx  = filterOutBound(enchant, selfIdx)
  touchIdx = filterOutBound(enchant, touchIdx)

  -- If nothing remains to cast, do not drain charge or spawn FX/SFX
  if (#selfIdx == 0) and (#touchIdx == 0) then
    return
  end

  if consume and not tryDrainCharge(glove, enchant) then
    return -- out of charge
  end

  if #selfIdx > 0 and caster and caster:isValid() then
    applyEnchEffects(caster, glove, selfIdx, caster)
  end
  if #touchIdx > 0 and target and target:isValid() then
    applyEnchEffects(target, glove, touchIdx, caster)
    doTouchFxAndSfx(target, enchant, touchIdx)
  end
end

return {
  eventHandlers = {
    [EVENT_APPLY] = applySettings,
    [EVENT_ENCH]  = onApplyEnchantOnHit,
  },
  engineHandlers = {
    onInit = function() log('Global ready (runtime=%s, apply=%s).', RUNTIME_KEY, EVENT_APPLY) end,
  },
}
