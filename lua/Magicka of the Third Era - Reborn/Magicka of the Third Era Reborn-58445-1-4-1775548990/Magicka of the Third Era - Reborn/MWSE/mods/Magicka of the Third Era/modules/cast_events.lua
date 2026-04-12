-- modules/cast_events.lua
-- Event handlers for spell casting: chance manipulation, cost manipulation, and experience gain.

local config  = require("Magicka of the Third Era.config")
local SM      = require("Magicka of the Third Era.modules.spell_manager")
local Formulas = require("Magicka of the Third Era.modules.formulas")

local premade_spells           = require("Magicka of the Third Era.data.premade_spells")
local determinist_effect_table = require("Magicka of the Third Era.data.determinist_effects")

local log = mwse.Logger.new{ modName = "Magicka of the Third Era", logLevel = config.log_level }

-------------------------------------------------------------------------------

local function is_birthsign_spell(spell)
  if not config.skip_birthsign_spells then return false end
  local birthsign = tes3.mobilePlayer and tes3.mobilePlayer.birthsign
  if not birthsign then return false end
  for bs_spell in tes3.iterate(birthsign.spells.iterator) do
    if bs_spell.id == spell.id then return true end
  end
  return false
end

-------------------------------------------------------------------------------

---@param e spellCastEventData
local function spell_chance_manipulation(e)
  local caster = e.caster.object.mobile
  local spell_cost = 0
  local spell_chance = 0
  local skill_for_spell = 0
  local spell_id = e.source.id
  local magic_skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}

  local determinist_spell = false
  -- disable for non-spells
  if e.source.castType ~= tes3.spellType.spell then
    return
  end
  if is_birthsign_spell(e.source) then
    log:trace(string.format("Spell %s is a birthsign spell. Skipping chance recalculation.", e.source.id))
    return
  end
  -- check for semi-determinism (mode 1): mark if spell has any abusable effects
  if config.determinism_mode == 1 then
    for _, effect in ipairs(e.source.effects) do
      if effect.object then
        for _, effect_id in ipairs(determinist_effect_table) do
          if effect.id == effect_id then
            determinist_spell = true
            log:trace(string.format("Found a determinist effect: %s", effect.id))
          end
        end
      end
    end
  end

  -- check if the spell is in storage. I've updated this in 1.3 to remove redundancy, error message is in case something goes wrong
  if tes3.player.data.motte_spell_storage[spell_id] then
    local spell_data = tes3.player.data.motte_spell_storage[spell_id]
    magic_skill_table = spell_data.skill_table
    spell_cost = spell_data.cost
    log:trace(string.format("Spell %s found in storage. Preparing for cast chance calculations", spell_id))
    if caster.alteration and caster.conjuration and caster.destruction and caster.illusion and caster.mysticism and caster.restoration then
      skill_for_spell = SM.compute_skill(magic_skill_table, caster)
    else
      skill_for_spell = 9999 -- creature casters
    end
    spell_chance = Formulas.calculate_cast_chance(spell_cost, caster.willpower.current, caster.luck.current, skill_for_spell)
    log:trace(string.format("Resulting cost (for chances): %.2f. Skill for spell: %d. Therefore, chance to cast: %d. Chance calculations stage is finished.", spell_cost, skill_for_spell, spell_chance))
    e.castChance = spell_chance
  else
    log:error(string.format("Spell %s should have been calculated but wasn't. This is an error, let me know the scenario how this did happen.", spell_id))
  end

  -- Respect "Always to succeed spells" if setting to overwrite chances is set to false (default: false)
  if e.source.alwaysSucceeds and (not(config.override_chances_alwaystosucceed)) then
    log:trace("Skipping this spell due to premade spell rules. Setting chance to 100 percent.")
    e.castChance = 100
  end

  -- Bandaid/diagnostic tool: if there are some absurdly strong spells that don't have "always succeeds", NPCs will suck at casting them.
  if e.castChance <= 60 and e.caster.object.mobile ~= tes3.mobilePlayer then
    log:debug(string.format("Low chance for spell for NPC: %s, spell: %s", e.caster.id, e.source.id))
    if config.npc_assist then
      e.castChance = 61
      log:trace("Increased spell chance to 61!")
    end
  end

  -- Friendship ended with dice rolls, determinism is my best friend now.
  if config.determinism_mode == 2 or determinist_spell then
    if e.castChance > 60 then
      e.castChance = 100
      log:trace("Determinism: overriding spell chances - spell is guaranteed to succeed.")
    else
      e.castChance = 0
      log:trace("Determinism: overriding spell chances - spell is guaranteed to fail.")
    end
  else
    -- Apply flat bonus only in modes 0 and 1; mode 3 uses the hybrid formula instead.
    if config.determinism_mode ~= 3 and e.castChance > 0 then
      e.castChance = math.min(e.castChance + config.flat_chance_bonus, 100)
    end
  end

  -- Hybrid mode: probabilistic shoulder for a less abrupt transition.
  if config.determinism_mode == 3 then
    -- Self-correct invalid slider configurations to avoid division by zero.
    if config.sa_cut_in_value >= config.sa_fulcrum_value then
      config.sa_cut_in_value = 50
      config.sa_fulcrum_value = 60
      tes3.messageBox("[Magicka of the Third Era] Cut-in value must be lower than the fulcrum. Reverted to defaults.")
    end
    if config.sa_fulcrum_value >= config.sa_cut_off_value then
      config.sa_fulcrum_value = 60
      config.sa_cut_off_value = 65
      tes3.messageBox("[Magicka of the Third Era] Fulcrum value must be lower than the cut-off. Reverted to defaults.")
    end
    e.castChance = Formulas.apply_hybrid_mode(e.castChance)
    log:trace(string.format("Hybrid: effective cast chance after shoulder transform: %d.", e.castChance))
  end
end

---@param e spellMagickaUseEventData
local function spell_cost_manipulation(e)
  local spell_cost = 0
  local fatigue_normalized = 0
  local sound_factor = 0

  -- disable for non-spells
  if e.spell.castType ~= tes3.spellType.spell then
    return
  end
  if is_birthsign_spell(e.spell) then
    log:trace(string.format("Spell %s is a birthsign spell. Skipping cost recalculation.", e.spell.id))
    return
  end

  local storage_result = SM.get_or_calculate(e.spell, premade_spells, false, e.caster.object.mobile)
  if storage_result then
    spell_cost = storage_result.cost
  end
  -- MODIFIERS: apply cost edits here (multiply by cost_mod if present)
  -- blood magic (proof of concept)
  --local blood_magic = New_Effects.check_blood_magic(e.spell)
  --if blood_magic > 0 then
  --  spell_cost = spell_cost * (100 - blood_magic) / 100
  --  log:trace(blood_magic)
  --end

  -- Fatigue increases costs up to 50% more (by default, configurable), these costs do not affect the cast chance.
  fatigue_normalized = math.min(1, e.caster.object.mobile.fatigue.normalized)
  -- Sound increases costs by 5% per magnitude. Also does not affect cast chance.
  if e.caster.object.mobile.sound < 0 then
    sound_factor = e.caster.object.mobile.sound * -0.05
    log:trace(string.format("Caster affected by sound, magnitude of %d. Increasing spell costs...", e.caster.object.mobile.sound))
  end
  -- Armor increases costs up to 100% more (by default, configurable). Also does not affect cast chance. Skip creature casters.
  local armor_factor = 0
  if e.caster.object.objectType == tes3.objectType.npc then
    local armor_table = Formulas.get_armor_coefs(e.caster.object.mobile)
    if config.armor_penalty_perc_max > 0 then
      armor_factor = armor_table.light * math.max(config.armor_penalty_cap_light - e.caster.object.mobile.lightArmor.current, 0) / config.armor_penalty_cap_light +
      armor_table.medium * math.max(config.armor_penalty_cap_medium - e.caster.object.mobile.mediumArmor.current, 0) / config.armor_penalty_cap_medium +
      armor_table.heavy * math.max(config.armor_penalty_cap_heavy - e.caster.object.mobile.heavyArmor.current, 0) / config.armor_penalty_cap_heavy
      armor_factor = armor_factor * (config.armor_penalty_perc_max / 100)
      if armor_factor > 0 then
        log:trace(string.format("Spell costs are increased by armor. Factor: %.2f.", armor_factor))
      end
    end
  end
  spell_cost = spell_cost * (1 + (config.fatigue_penalty_mult / 100) * (1 - fatigue_normalized) + sound_factor + armor_factor)
  if e.caster.object.mobile == tes3.mobilePlayer and e.caster.object.mobile.magicka.current > 100 then
    spell_cost = spell_cost * (1 + (e.caster.object.mobile.magicka.current - 100) * config.overflowing_magicka_rate / 10000)
  end
  -- We need to help dumb NPC AI to handle new costs. I think they fail to cast at low magicka: they cast the spell thinking it costs the old cost (cheaper). They repeat this process, constantly failing at this stage.
  -- The alternative is to rewrite the entire AI so deal with it
  if e.caster.object.mobile ~= tes3.mobilePlayer and e.caster.object.mobile.magicka.current < spell_cost then
    log:info(string.format("NPC casting this spell has magicka of %.2f. However, spell costs %.2f. Spell discounted to magicka - 0.5 to help the AI handle this.", e.caster.object.mobile.magicka.current, spell_cost))
    spell_cost = math.max(e.caster.object.mobile.magicka.current - 0.5, 0)
    -- This should allow this spell to be cast one last time before NPC will have almost no magicka and switch to something else. Seems to work after testing
  end
  e.cost = math.round(spell_cost)

  log:trace(string.format("Resulting cost for spell: %.2f. Cost calculation stage is finished.", e.cost))
end

---@param e spellCastedEventData
local function exp_gain(e)
  if (not tes3.player) or (e.caster ~= tes3.player) then return end

  local caster = e.caster.mobile
  if not(config.experience_gain) or e.source.castType ~= tes3.spellType.spell then
    return
  end
  ---@cast caster tes3mobilePlayer

  local spell_id = e.source.id
  local school = tes3.magicSchoolSkill[e.expGainSchool]
  local magic_skill_table = {}
  local spell_cost = 0
  -- Base divider for costs
  local base_const = 7.5
  -- Disable vanilla exp gain
  e.expGainSchool = tes3.magicSchool.none
  if tes3.player.data.motte_spell_storage[spell_id] then
    -- if spell is in the DB, where it should be.
    local spell_data = tes3.player.data.motte_spell_storage[spell_id]
    magic_skill_table = spell_data.skill_table
    spell_cost = spell_data.cost
    -- level only if base skill < 100
    if caster.alteration.base < 100 or config.leveling_uncapped then
      caster:exerciseSkill(11, spell_cost * magic_skill_table[1] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_alteration / 100)
    end
    if caster.conjuration.base < 100 or config.leveling_uncapped then
      caster:exerciseSkill(13, spell_cost * magic_skill_table[2] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_conjuration / 100)
    end
    if caster.destruction.base < 100 or config.leveling_uncapped then
      caster:exerciseSkill(10, spell_cost * magic_skill_table[3] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_destruction / 100)
    end
    if caster.illusion.base < 100 or config.leveling_uncapped then
      caster:exerciseSkill(12, spell_cost * magic_skill_table[4] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_illusion / 100)
    end
    if caster.mysticism.base < 100 or config.leveling_uncapped then
      caster:exerciseSkill(14, spell_cost * magic_skill_table[5] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_mysticism / 100)
    end
    if caster.restoration.base < 100 or config.leveling_uncapped then
      caster:exerciseSkill(15, spell_cost * magic_skill_table[6] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_restoration / 100)
    end
  else
    -- If spell is not in the DB for some reason.
    spell_cost = e.source.magickaCost
    log:warn(string.format("Spell %s not found in database! Using simplified approach.", spell_id))
    caster:exerciseSkill(school, spell_cost / base_const * config.leveling_rate_global / 100)
  end
end

-------------------------------------------------------------------------------

local M = {}

function M.register()
  event.register("spellCast",       spell_chance_manipulation)
  event.register("spellMagickaUse", spell_cost_manipulation)
  event.register("spellCasted",     exp_gain)
end

return M
