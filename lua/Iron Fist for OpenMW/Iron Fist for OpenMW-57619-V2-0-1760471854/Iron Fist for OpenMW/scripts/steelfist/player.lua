-- scripts/steelfist/player.lua
-- Local defender-side combat hook. Attach to NPC, CREATURE, and PLAYER.
-- On successful unarmed melee by the Player:
--   - add damage from ONLY ONE hand (alternating per defender)
--   - legacy STR/H2H/cond + weight-class multipliers
--   - baseArmor term only
--   - compute durability wear
--   - ask GLOBAL to cast enchant, drain charge, play FX/SFX, and apply wear
--   - NEW: filter out all Bound weapon/armor effects so they are never cast

local self    = require('openmw.self')
local I       = require('openmw.interfaces')
local core    = require('openmw.core')
local types   = require('openmw.types')
local storage = require('openmw.storage')

local RUNTIME_KEY = 'IronFistRuntime'
local EVENT_APPLY_ENCHANT = 'SteelFist_ApplyEnchantOnHit'

local nextHand = 'right' -- alternates per defender

-- Settings (locals read-only)
local function CFG()
  local S = storage.globalSection(RUNTIME_KEY) -- locals may READ global; only GLOBAL writes
  return {
    enabled               = S:get('enabled') ~= false,
    base                  = S:get('base') or 1.0,
    skillWeight           = S:get('skillWeight') or 1.0,
    strWeight             = S:get('strWeight') or 1.0,
    condFloor             = S:get('condFloor') or 0.10,

    heavyMult             = S:get('heavyMult') or 1.50,
    mediumMult            = S:get('mediumMult') or 1.00,
    lightMult             = S:get('lightMult') or 0.50,
    clothingMult          = S:get('clothingMult') or 0.35,

    armorBaseFactor       = S:get('armorBaseFactor') or 0.00,

    detEnabled            = S:get('detEnabled') or true,
    detChance             = S:get('detChance') or 20,
    detScale              = S:get('detScale') or 1.0,

    castEnchantOnHit      = S:get('castEnchantOnHit') ~= false,
    consumeEnchantCharge  = S:get('consumeEnchantCharge') ~= false,

    debug                 = S:get('debug') or false,
  }
end

local function isArmorHand(t)
  return t == types.Armor.TYPE.LGauntlet
      or t == types.Armor.TYPE.RGauntlet
      or t == types.Armor.TYPE.LBracer
      or t == types.Armor.TYPE.RBracer
end
local function isClothingHand(t)
  return t == types.Clothing.TYPE.LGlove
      or t == types.Clothing.TYPE.RGlove
end
local function chooseHand()
  local h = nextHand
  nextHand = (h == 'right') and 'left' or 'right'
  return h
end

local function getHandItem(attacker, hand)
  local eq = types.Actor.getEquipment(attacker)
  if not eq then return nil, nil end
  local armorItem, clothingItem
  for _, item in pairs(eq) do
    if types.Armor.objectIsInstance(item) then
      local rec = types.Armor.record(item)
      if rec and isArmorHand(rec.type) then
        local isLeft = (rec.type == types.Armor.TYPE.LGauntlet or rec.type == types.Armor.TYPE.LBracer)
        if (hand == 'left' and isLeft) or (hand == 'right' and not isLeft) then armorItem = item end
      end
    elseif types.Clothing.objectIsInstance(item) then
      local rec = types.Clothing.record(item)
      if rec and isClothingHand(rec.type) then
        local isLeft = (rec.type == types.Clothing.TYPE.LGlove)
        if (hand == 'left' and isLeft) or (hand == 'right' and not isLeft) then clothingItem = item end
      end
    end
  end
  if armorItem then return armorItem, 'armor' end
  if clothingItem then return clothingItem, 'clothing' end
  return nil, nil
end

local function getSTR(att)
  local attrs = types.Actor.stats and types.Actor.stats.attributes
  if attrs and attrs.strength then local s = attrs.strength(att); return (s and s.modified) or 0 end
  return 0
end
local function getH2H(att)
  if types.NPC and types.NPC.stats and types.NPC.stats.skills and types.NPC.stats.skills.handtohand then
    local s = types.NPC.stats.skills.handtohand(att); if s and s.modified then return s.modified end
  end
  if types.SkillStats and types.SkillStats.handtohand then
    local s = types.SkillStats.handtohand(att); if s and s.modified then return s.modified end
  end
  return 0
end

local function condScaled(item, floor)
  if not types.Armor.objectIsInstance(item) then return 1.0 end
  local rec  = types.Armor.record(item)
  local data = types.Item.itemData(item)
  local cur  = (data and data.condition) or rec.health
  local maxH = (rec.health and rec.health > 0) and rec.health or 1
  return math.max(floor or 0, cur / maxH)
end

local function classMult(item, cfg)
  if types.Armor.objectIsInstance(item) then
    local skillId = I.Combat.getArmorSkill(item) -- "heavyarmor","mediumarmor","lightarmor","unarmored"
    if skillId == 'heavyarmor' then return cfg.heavyMult
    elseif skillId == 'mediumarmor' then return cfg.mediumMult
    elseif skillId == 'lightarmor' then return cfg.lightMult
    else return 0.0 end
  elseif types.Clothing.objectIsInstance(item) then
    return cfg.clothingMult
  end
  return 0.0
end

-- IDs of Bound effects to block entirely (see openmw.core MagicEffectId list)
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

local RANGE = core.magic and core.magic.RANGE or { Self=0, Touch=1, Target=2 }
local function splitEffectsByRange(enchant)
  local toSelf, toVictim = {}, {}
  if not enchant or not enchant.effects then return toSelf, toVictim end
  for i1, eff in ipairs(enchant.effects) do
    if eff and eff.id and not BLOCKED_BOUND[eff.id] then
      local i0 = i1 - 1
      if eff.range == RANGE.Self then
        toSelf[#toSelf+1] = i0
      else
        toVictim[#toVictim+1] = i0 -- Touch/Target counted as victim
      end
    end
  end
  return toSelf, toVictim
end

local registered, printedCfg = false, false

local function register()
  if registered then return end

  I.Combat.addOnHitHandler(function(attack)
    -- Only successful, unarmed melee from the Player
    if not attack or not attack.successful then return end
    if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end
    if attack.weapon ~= nil then return end
    if not (attack.attacker and types.Player.objectIsInstance(attack.attacker)) then return end

    local cfg = CFG()
    if not cfg.enabled then return end

    if not printedCfg and cfg.debug then
      printedCfg = true
      print(('[IronFist] ready (base=%.2f, baseArmorF=%.2f, det=%s@%d%% x%.2f, cast=%s, drain=%s)')
        :format(cfg.base, cfg.armorBaseFactor, tostring(cfg.detEnabled),
          cfg.detChance or -1, cfg.detScale or -1,
          tostring(cfg.castEnchantOnHit), tostring(cfg.consumeEnchantCharge)))
    end

    -- ONE hand only
    local hand = chooseHand()
    local glove, kind = getHandItem(attack.attacker, hand)
    if not glove then return end

    -- Terms
    local STR = getSTR(attack.attacker)
    local H2H = getH2H(attack.attacker)
    local strTerm   = 1.0 + (STR / 100.0) * cfg.strWeight
    local skillTerm = 1.0 + (H2H / 100.0) * cfg.skillWeight
    local swing     = attack.strength or 1.0
    local mult      = classMult(glove, cfg)
    local cond      = condScaled(glove, cfg.condFloor)

    -- (1) Legacy term
    local legacy = (mult > 0) and (cfg.base * mult * cond * skillTerm * strTerm * swing) or 0

    -- (2) Base armor contribution only
    local baseArmor = 0
    if types.Armor.objectIsInstance(glove) then
      local rec = types.Armor.record(glove)
      baseArmor = (rec.baseArmor or 0) * cond
    end
    local baseArmorAdd = (baseArmor > 0 and cfg.armorBaseFactor > 0)
      and (baseArmor * cfg.armorBaseFactor * skillTerm * strTerm * swing) or 0

    local bonus = legacy + baseArmorAdd
    if bonus > 0 then
      attack.damage = attack.damage or {}
      attack.damage.health = (attack.damage.health or 0) + bonus
    end

    -- Wear (decide here; apply in GLOBAL)
    local wearAmt = nil
    if cfg.detEnabled and kind == 'armor' and (cfg.detChance or 0) > 0 and (cfg.detScale or 0) > 0 then
      if math.random(1,100) <= (cfg.detChance or 0) then
        wearAmt = bonus * cfg.detScale
      end
    end

    -- Enchant cast/drain/VFX
    if cfg.castEnchantOnHit or wearAmt then
      local enchant = nil
      if types.Armor.objectIsInstance(glove) then
        local r = types.Armor.record(glove); if r and r.enchant then enchant = core.magic.enchantments.records[r.enchant] end
      elseif types.Clothing.objectIsInstance(glove) then
        local r = types.Clothing.record(glove); if r and r.enchant then enchant = core.magic.enchantments.records[r.enchant] end
      end

      local toSelf, toVictim = {}, {}
      if cfg.castEnchantOnHit and enchant and enchant.type ~= (core.magic and core.magic.ENCHANTMENT_TYPE.ConstantEffect) then
        toSelf, toVictim = splitEffectsByRange(enchant)  -- already filters out bound effects
      end

      core.sendGlobalEvent(EVENT_APPLY_ENCHANT, {
        caster   = attack.attacker,
        target   = self,
        glove    = glove,
        consume  = cfg.consumeEnchantCharge,
        selfIdx  = toSelf,     -- 0-based, filtered
        touchIdx = toVictim,   -- 0-based, filtered
        wearAmt  = wearAmt,
      })
    end

    if cfg.debug then
      print(string.format('[IronFist] %s +%.2f (swing=%.2f, STR=%.1f, H2H=%.1f)', hand, bonus, attack.strength or 1, STR, H2H))
    end
  end)

  registered = true
end

return {
  engineHandlers = {
    onInit = register,
    onLoad = function() registered = false; register() end,
  },
}
