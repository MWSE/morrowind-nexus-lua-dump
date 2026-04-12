
-- main.lua
-- Bootstrap: registers events, manages spell storage and Magicka Expanded distribution.
--
-- Module map:
--   modules/cast_events.lua      spellCast / spellMagickaUse / spellCasted handlers
--   modules/ui.lua               spellmaker, spell merchant, and magic menu UI
--   modules/formulas.lua         pure math: cast chance, armor coefficient breakdown
--   modules/spell_manager.lua    spell cost computation, synergy detection, spell storage cache
--   modules/known_effects.lua    tracks which spell effects the player has seen (UI highlight)
--   modules/mcm.lua              Mod Configuration Menu
--
-- Data (static, read-only):
--   data/premade_spells.lua      vanilla/DLC spell IDs (skips re-calculation)
--   data/custom_price_spells.lua gold price overrides for spells with no meaningful base cost
--   data/determinist_effects.lua effect IDs forced deterministic under semi-determinism mode (1)
--   data/force_allow_effects.lua effects explicitly unlocked for spellmaking
--   data/spell_table.lua         base cost table per effect
--   data/synergy_table.lua       synergy discount rules for multi-effect spells
--   data/me_distribution.lua     Magicka Expanded spell-to-merchant distribution map

local config = require("Magicka of the Third Era.config")
local log = mwse.Logger.new{
    modName = "Magicka of the Third Era",
    logLevel = config.log_level,
}
local UI           = require("Magicka of the Third Era.modules.ui")
local CastEvents   = require("Magicka of the Third Era.modules.cast_events")
local SpellManager = require("Magicka of the Third Era.modules.spell_manager")

--[[ (WIP, not yet active)
local Effect_Mechanics = require("Magicka of the Third Era.effect_mechanics")
local New_Effects      = require("Magicka of the Third Era.modules.new_effects")
]]


local version = "2.0"

-- a list of effects to force allow into spellmaking
local force_allow_effects = require("Magicka of the Third Era.data.force_allow_effects")

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Spell storage.
---@param e loadedEventData
local function load_storage(e)
  if not tes3.player.data.motte_spell_storage then
    tes3.player.data.motte_spell_storage = {}
  else
    log:trace("Game loaded. Found spell storage.")
  end
  SpellManager.migrate_skill_tables()
  -- check version, record one if none present, reset storage if using earlier version
  if not tes3.player.data.motte_version then
    tes3.player.data.motte_version = version
  else
    if tes3.player.data.motte_version ~= version then
      log:info(string.format("Detected savegame with a different version of a mod: %s. Current mod version: %s, resetting the storage for an auto-update.", tes3.player.data.motte_version, version))
      tes3.player.data.motte_spell_storage = {}
      tes3.player.data.motte_version = version
    end
  end
end

-- ME Stuff

local me_known_packs = {"lore_friendly", "summoning", "teleportation", "tr", "weather", "cortex"}

local me_packs = {lore_friendly = false, summoning = false, teleportation = false, tr = false, weather = false, cortex = false}

local me_distribution = require("Magicka of the Third Era.data.me_distribution")
---@param e loadedEventData
local function magicka_expanded_spells(e)

  if not config.distribute_magicka_expanded_spells then return end

  log:trace("Looking for Magicka Expanded Spell Packs...")
  -- I don't know if it's a good way to make sure ME creates spells before this check applies
  timer.start{type = timer.real, duration = 3, callback = function()
    
    if tes3.getObject('OJ_ME_BanishDaedraSpell') then
      log:trace("ME Packs: Found Lore-Friendly Pack!")
      me_packs.lore_friendly = true
    end
    if tes3.getObject('OJ_ME_SummWarDurzogSpell') then
      log:trace("ME Packs: Found Summoning Pack!")
      me_packs.summoning = true
    end
    if tes3.getObject('OJ_ME_TeleportToAldRuhn') then
      log:trace("ME Packs: Found Teleportation Pack!")
      me_packs.teleportation = true
    end
    if tes3.getObject('OJ_ME_TeleportToAkamora') then
      log:trace("ME Packs: Found TR Pack!")
      me_packs.tr = true
    end
    if tes3.getObject('OJ_ME_WeatherBlizzard') then
      log:trace("ME Packs: Found Weather Pack!")
      me_packs.weather = true
    end
    if tes3.getObject('OJ_ME_BlinkSpell') then
      log:trace("ME Packs: Found Cortex Pack!")
      me_packs.cortex = true
    end
    
    -- distribute spells to merchants, using same logic as Enhanced Detection (thanks for the code!)
    for _, pack_name in ipairs(me_known_packs) do
      if me_packs[pack_name] then
        log:trace(string.format("Distributing spells from the %s pack...", pack_name))

        for npc_id, dist_spell_id in pairs(me_distribution[pack_name]) do
          local npc = tes3.getObject(npc_id)
          ---@cast npc tes3npc
          if (npc) then
            if (type(dist_spell_id) ~= "table") then
              local spell = tes3.getObject(dist_spell_id)
              ---@cast spell tes3spell
              if (spell) then
                tes3.addSpell({ actor = npc, spell = spell })
              end
            else
              for _, spell_id in pairs(dist_spell_id) do
                local spell = tes3.getObject(spell_id)
                ---@cast spell tes3spell
                if (spell) then
                  tes3.addSpell({ actor = npc, spell = spell })
                end
              end
            end
          end
        end
      end
    end


  end}
end

local function initialized()
  UI.register()
  CastEvents.register()

  event.register(tes3.event.loaded, load_storage)
  event.register(tes3.event.loaded, magicka_expanded_spells)
  -- Disable vanilla spellmaking value and spellprice mechanics, if mods enable it again via script, it won't be pretty.
  tes3.findGMST("fSpellMakingValueMult").value = 0
  tes3.findGMST("fSpellValueMult").value = 0
  -- Enable effects for spellmaking
  local force_effects = {}
  for i, effect_name in ipairs(force_allow_effects) do
    --log:trace(string.format("Allowing effect: %s", effect_name))
    force_effects[i] = tes3.getMagicEffect(tes3.effect[effect_name])
    force_effects[i].allowSpellmaking = true
  end


  --if is_mod_installed("ui expansion") then
  --  local ui_cfg = mwse.loadConfig("ui expansion", {components={serviceSpells=false}})
  --  ui_cfg.components.serviceSpells = false
  --  log:trace(ui_cfg.components.serviceSpells)
  --  mwse.saveConfig("UI Expansion", ui_cfg)
  --  log:trace("Disabling spell services menu component from UI Expansion.")
  --end
  print(string.format("[Vengyre] Magicka of the Third Era initialized. Version: %s.", version))
end

local function override_uiexpansion()
  local ui_common = include("ui expansion.common")
  if ui_common then
    if ui_common.config.components.serviceSpells == true then
      log:trace("Disabling spell services menu component from UI Expansion.")
      ui_common.config.components.serviceSpells = false
    end
  end
end

event.register("initialized", override_uiexpansion, { priority = 99 })
event.register("initialized", initialized)

-- Update the HUD spell fillbar to reflect cast chance in determinism modes 2 and 3.
--   Mode 2: mastery = min(floor(chance * 100 / 60), 100)  — full at the 60 threshold
--   Mode 3: effective chance after hybrid shoulder transform (0-100)
local SpellManager_hud = require("Magicka of the Third Era.modules.spell_manager")
local Formulas_hud     = require("Magicka of the Third Era.modules.formulas")
local premade_hud      = require("Magicka of the Third Era.data.premade_spells")
event.register("uiActivated", function(e)
  e.element:registerAfter("preUpdate", function()
    if config.determinism_mode ~= 2 and config.determinism_mode ~= 3 then return end
    local fill = e.element:findChild("MenuMulti_magic_fill")
    if not fill then return end
    local mobile = tes3.mobilePlayer
    if not mobile then return end
    local spell = mobile.currentSpell
    if not spell or spell.castType ~= tes3.spellType.spell then return end
    local result = SpellManager_hud.get_or_calculate(spell, premade_hud, false, mobile)
    if not result then return end
    local spell_chance = Formulas_hud.calculate_cast_chance(result.cost, mobile.willpower.current, mobile.luck.current, result.skill_for_spell)
    local display
    if config.determinism_mode == 2 then
      display = math.min(math.floor(spell_chance * 100 / 60), 100)
    else
      display = Formulas_hud.apply_hybrid_mode(spell_chance)
    end
    fill.widget.current = display
    fill.widget.max     = 100
    fill:updateLayout()
  end)
end, { filter = "MenuMulti" })


-- MCM --

local function modConfigReady()
	require("Magicka of the Third Era.modules.mcm")
end
event.register('modConfigReady', modConfigReady)