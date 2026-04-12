-- modules/ui.lua
-- UI event callbacks: spellmaker, spell merchant, and magic menu updates.

local config        = require("Magicka of the Third Era.config")
local SM            = require("Magicka of the Third Era.modules.spell_manager")
local Known_Effects = require("Magicka of the Third Era.modules.known_effects")
local Formulas      = require("Magicka of the Third Era.modules.formulas")

local premade_spells           = require("Magicka of the Third Era.data.premade_spells")
local custom_price_spells      = require("Magicka of the Third Era.data.custom_price_spells")
local determinist_effect_table = require("Magicka of the Third Era.data.determinist_effects")

local log = mwse.Logger.new{ modName = "Magicka of the Third Era", logLevel = config.log_level }

local effect_cost_advanced    = SM.effect_cost_advanced
local spell_cost_advanced     = SM.spell_cost_advanced
local calculate_cast_chance   = Formulas.calculate_cast_chance
local get_armor_coefs         = Formulas.get_armor_coefs

local spellmaker_cost  = 0
local self_spellmaking = false

-------------------------------------------------------------------------------

---@param e calcSpellmakingSpellPointCostEventData
local function spellmaker_update(e)
  -- This function updates the spell cost/chance in spellmaker. Also shows the synergies and recalculates the price based on cost.
  log:trace("Spellmaking menu is being updated!")
  local menu = tes3ui.findMenu("MenuSpellmaking")
  if menu then
    -- Find effects in the UI
    local ms_sel = menu:findChild("MenuSpellmaking_SpellEffectsLayout")
    if not ms_sel then return end
    local psp_p = ms_sel:findChild("PartScrollPane_pane")
    if not psp_p then return end
    local effect_database = psp_p.children
    -- Calculation variables
    local total_effect_cost = 0
    local spell_cost = 0
    local spell_chance = 0
    local skill_for_spell = 0
    local effect_db = {}
    local cost_db = {}
    local magic_skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
    local discount = 0
    -- Disposition matters, but by default only a little, because you only need 1 NPC with max disposition
    local disp_factor = 1
    local service_actor_sm = tes3ui.getServiceActor()
    if service_actor_sm then
      local disp = service_actor_sm.object.disposition
      if disp then
        disp_factor = 1 + (100 - disp) * config.economy_spellmaker_diff / 10000
      end
    end
    -- Calculations for effects
    for i=1, #effect_database do
      local elem = effect_database[i]
      local effect_obj = elem:getPropertyObject("MenuSpellmaking_Effect")
      local effect_id = effect_obj.id
      local effect_school = effect_obj.school
      local duration = elem:getPropertyInt("MenuSpellmaking_Duration")
      -- Some stupid bug when default duration is 0, ruins the calculations and is factually incorrect (you can never have a duration of 0 in a spell, without MCP at least)
      if duration == 0 then duration = 1 end
      local mag_min = elem:getPropertyInt("MenuSpellmaking_MagLow")
      local mag_max = elem:getPropertyInt("MenuSpellmaking_MagHigh")
      local radius = elem:getPropertyInt("MenuSpellmaking_Area")
      -- Why can't you just be normal
      local range_text = elem.text
      local range = (range_text == "Target") and 2 or (range_text == "Touch") and 1 or 0
      local e_attribute = elem:getPropertyInt("MenuSpellmaking_Attribute")
      local e_skill = elem:getPropertyInt("MenuSpellmaking_Skill")

      local effect_data = {id = effect_id, min = mag_min, max = mag_max, duration = duration, radius = radius, rangeType = range, attribute = e_attribute, skill = e_skill}
      local effect_cost = effect_cost_advanced(effect_data)
      effect_db[i] = effect_data
      cost_db[i] = effect_cost

      total_effect_cost = total_effect_cost + effect_cost

      if effect_school >= 0 and effect_school <= 5 then
        magic_skill_table[effect_school] = magic_skill_table[effect_school] + effect_cost
      else
        -- case of custom schools or crap like this
        magic_skill_table[0] = magic_skill_table[0] + effect_cost
      end
    end
    -- MODLABEL 1
    -- If spell is legit, re-calculate the cost
    if total_effect_cost > 0 then
      if #effect_db == 1 then
        log:trace("One-effect spell in the spellmaker found! Using basic formula.")
        spell_cost = total_effect_cost
      else
        -- skip all mod effects for adv formula!!
        log:trace("Multi-effect spell in the spellmaker found! Trying advanced formula.")
        local adv_calc = spell_cost_advanced(effect_db, cost_db)
        spell_cost = adv_calc.cost
        discount = adv_calc.synergies.cost_discount
        if spell_cost == 0 then
          log:debug("Non-legit spell for advanced formula in spellmaking menu! Going for plan B.")
          spell_cost = total_effect_cost
        end
      end

      -- weighing magic skills
      for k=0, 5 do
        magic_skill_table[k] = magic_skill_table[k] / total_effect_cost
        log:trace(string.format("Coeficient for skill %d: %.2f", k, magic_skill_table[k]))
      end

      skill_for_spell = magic_skill_table[0] * tes3.mobilePlayer.alteration.current + magic_skill_table[1] * tes3.mobilePlayer.conjuration.current + magic_skill_table[2] * tes3.mobilePlayer.destruction.current +
      magic_skill_table[3] * tes3.mobilePlayer.illusion.current + magic_skill_table[4] * tes3.mobilePlayer.mysticism.current + magic_skill_table[5] * tes3.mobilePlayer.restoration.current

      spell_chance = calculate_cast_chance(spell_cost, tes3.mobilePlayer.willpower.current, tes3.mobilePlayer.luck.current, skill_for_spell)
      log:trace(string.format("Spell info updated. Skill for spell: %d, Cost: %.2f, Chance: %.2f", skill_for_spell, spell_cost, spell_chance))

      -- display discount
      local cost_text = tostring (math.round(spell_cost))
      if discount > 0 then
        cost_text = cost_text .. " (-" .. tostring(math.floor(discount*100)) .. "%)"
      end

      -- forward data for mods that use this value
      e.spellPointCost = math.round(spell_cost)

      --Needs a small delay since vanilla gets calculated right after this event, and we need to overwrite vanilla
      timer.start{type = timer.real, duration = 0.07, callback = function()
        menu:findChild("MenuSpellmaking_SpellPointCost").text = cost_text
        menu:findChild("MenuSpellmaking_SpellChance").text = tostring (math.round(spell_chance))
        menu:findChild("MenuSpellmaking_PriceValueLabel").text = tostring (math.floor(spell_cost * config.economy_spellmaker_mult * disp_factor))
        end}

      -- save for cost checker, use disp_factor here
      spellmaker_cost = math.round(spell_cost * disp_factor)

    end
  end
end

-- attempt to fit with spellmaker mod

-- block spellmaking if you don't have enough gold, thanks to SpellMaker mod for this
---@param _ uiActivatedEventData
local function spellmaking_block(_)
  local menu = tes3ui.findMenu("MenuSpellmaking")
  if menu then
    local buyButton = menu:findChild("MenuSpellmaking_Buybutton")
    local gold_amount = tes3.getPlayerGold()
    self_spellmaking = (tes3ui.getServiceActor() == nil)
    if self_spellmaking then
      return
    end
    if not buyButton then return end
    buyButton:registerBefore(tes3.uiEvent.mouseClick,
        function(mouseClickEventData)
          if gold_amount < math.floor(spellmaker_cost * config.economy_spellmaker_mult) then
            tes3.messageBox("You don't have enough gold to create this spell")
            return false -- this will prevent the regular mouseclick event from being run
          end
        end
      )
  end
end

---@param _ spellCreatedEventData
local function spellmaking_payment(_)
  if not self_spellmaking and tes3.player then
    tes3.removeItem({reference = tes3.player, item = "gold_001", count = math.floor(spellmaker_cost * config.economy_spellmaker_mult)})
  end
end

-- Update the spell merchant UI
-- Does not work with this part of UI Expansion, unfortunately (UI Expansion uses different elements and bugs out sometimes), so I've made an even better UI (based on UI expansion)

---@param e uiActivatedEventData
local function spellmerchant_update(e)
  if not e.newlyCreated then return end
  -- Very similar to MenuMagic
  --e.element:registerAfter("preUpdate", function()
  local gold_amount = tes3.getPlayerGold()
  local service_actor = tes3ui.getServiceActor()
  if not service_actor then return end
  local disp = service_actor.object.disposition
  local disp_factor = 1
  if disp then
    disp_factor = 1 + (100 - disp) * config.economy_spellmerchant_diff / 10000
  end

  -- UI Expansion integration
  local menu = e.element
  local MenuServiceSpells_ServiceList = menu:findChild("MenuServiceSpells_ServiceList")
  if not MenuServiceSpells_ServiceList then return end
  local MenuServiceSpells_ServiceList_PartScrollPane_pane = MenuServiceSpells_ServiceList:findChild("PartScrollPane_pane")
  if not MenuServiceSpells_ServiceList_PartScrollPane_pane then return end
  local MenuServiceSpells_Spell = tes3ui.registerProperty("MenuServiceSpells_Spell")
  local serviceSpells = {} --- @type tes3spell[]
  for _, child in ipairs(MenuServiceSpells_ServiceList_PartScrollPane_pane.children) do
    table.insert(serviceSpells, child:getPropertyObject(MenuServiceSpells_Spell))
  end

  local knownEffects = Known_Effects.getKnownEffectsTable(tes3.mobilePlayer)

  -- my stuff
  local all_spells = e.element:findChild("MenuServiceSpells_ServiceList")
  if not all_spells then return end
  local names_pane = all_spells:findChild("PartScrollPane_pane")
  if not names_pane then return end
  local names = names_pane.children
  local service_text = {base_texts = {}, gold_texts = {}, cost_texts = {}, chance_texts = {}}
  local service_chances = {}
  local gold_costs = {}
  local service_school = {}

  -- process spells
  for i=1, #serviceSpells do
    local spell = serviceSpells[i]
    local spell_id = spell.id

    local spell_cost = 0
    local spell_chance = 0
    local skill_for_spell = 0
    local determinist_spell = false

    if (config.override_costs_alwaystosucceed or not (spell.alwaysSucceeds)) and config.determinism_mode == 1 then
      for j, effect in ipairs(spell.effects) do
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

    local storage_result = SM.get_or_calculate(spell, premade_spells, true, tes3.mobilePlayer)
    if storage_result then
      spell_cost = storage_result.cost
      skill_for_spell = storage_result.skill_for_spell
    end

    if spell_cost > 0 then
      log:trace(string.format("Spell processed. ID: %s. Your skill for this spell: %d", spell.id, skill_for_spell))
      spell_chance = calculate_cast_chance(spell_cost, tes3.mobilePlayer.willpower.current, tes3.mobilePlayer.luck.current, skill_for_spell)

      local cost_text = tostring (math.floor(spell_cost))
      gold_costs[spell] = math.floor(spell_cost * config.economy_spellmerchant_mult * disp_factor)
      local gold_text = tostring (gold_costs[spell])
      if custom_price_spells[spell_id] then
        gold_costs[spell] = math.floor(custom_price_spells[spell_id].cost * disp_factor)
        gold_text = tostring (gold_costs[spell])
      end
      local chance_text = ""
      if spell.alwaysSucceeds and not (config.override_chances_alwaystosucceed) then
        spell_chance = 100
        log:trace(string.format("Spell %s has 100 percent success rate.", spell.id))
      end
      if config.determinism_mode == 2 or determinist_spell then
        chance_text = tostring(math.min(math.floor(spell_chance * 100 / 60), 100))
      elseif config.determinism_mode == 3 then
        spell_chance = Formulas.apply_hybrid_mode(spell_chance)
        chance_text = tostring(spell_chance)
      else
        if spell_chance > 0 then
          spell_chance = math.min(spell_chance + config.flat_chance_bonus, 100)
        end
        chance_text = tostring(math.floor(spell_chance))
      end

      local chance_label = (config.determinism_mode == 2 or determinist_spell) and "Mastery" or "Cast Chance"
      names[i].text = tostring(spell.name) .. " | " .. gold_text .. " Gold | " .. cost_text .. " Base Cost | " .. chance_text .. " " .. chance_label
      if not (config.ui_extended_spell_merchant) then
        service_text.base_texts[spell] = names[i].text
      else
        service_text.base_texts[spell] = tostring(spell.name)
      end

      service_chances[spell] = spell_chance

      local max_school = {value = 0, school = 0}
      local stored_spell = tes3.player.data.motte_spell_storage[spell_id]
      if stored_spell then
        for k=1, 6 do
          if max_school.value < stored_spell.skill_table[k] then
            max_school.value = stored_spell.skill_table[k]
            max_school.school = k - 1  -- convert +1 packed index back to raw school index (0-5)
          end
        end
      end

      service_school[spell] = max_school.school
      service_text.gold_texts[spell] = gold_text .. " Gold"
      service_text.cost_texts[spell] = cost_text .. " Base Cost"
      if config.determinism_mode == 2 or determinist_spell then
        service_text.chance_texts[spell] = chance_text .. " Mastery"
      else
        service_text.chance_texts[spell] = chance_text .. " Cast Chance"
      end

    end
  end

  menu.width = 750

  -- Only sort spells that were processed (have a gold cost entry).
  -- Spells with zero calculated cost have no entry in any lookup table and are excluded.
  local sortable = {}
  for _, spell in ipairs(serviceSpells) do
    if gold_costs[spell] then
      table.insert(sortable, spell)
    end
  end

  if config.ui_spell_merchant_sort == 1 then
    table.sort(sortable, function(a, b) return a.name < b.name end)
  elseif config.ui_spell_merchant_sort == 2 then
    table.sort(sortable, function(a, b) return gold_costs[a] < gold_costs[b] end)
  elseif config.ui_spell_merchant_sort == 3 then
    table.sort(sortable, function(a, b) return service_chances[a] > service_chances[b] end)
  elseif config.ui_spell_merchant_sort == 4 then
    table.sort(sortable, function(a, b)
      local sa, sb = service_school[a], service_school[b]
      return sa < sb or (sa == sb and a.name < b.name)
    end)
  elseif config.ui_spell_merchant_sort == 5 then
    table.sort(sortable, function(a, b)
      local sa, sb = service_school[a], service_school[b]
      return sa < sb or (sa == sb and gold_costs[a] < gold_costs[b])
    end)
  end
  serviceSpells = sortable

  -- UI Expansion strikes again

  MenuServiceSpells_ServiceList_PartScrollPane_pane:destroyChildren()
  MenuServiceSpells_ServiceList_PartScrollPane_pane.flowDirection = "left_to_right"
  local MenuServiceSpells_Icons = MenuServiceSpells_ServiceList_PartScrollPane_pane:createBlock({ id = "MenuServiceSpells_Icons" })
  MenuServiceSpells_Icons.flowDirection = "top_to_bottom"
  MenuServiceSpells_Icons.autoWidth = true
  MenuServiceSpells_Icons.autoHeight = true
  MenuServiceSpells_Icons.paddingRight = 4
  MenuServiceSpells_Icons.paddingLeft = 2
  local MenuServiceSpells_Spells = MenuServiceSpells_ServiceList_PartScrollPane_pane:createBlock({ id = "MenuServiceSpells_Spells" })
  MenuServiceSpells_Spells.flowDirection = "top_to_bottom"
  if config.ui_extended_spell_merchant then
    MenuServiceSpells_Spells.width = 300
  else
    MenuServiceSpells_Spells.autoWidth = true
  end
  MenuServiceSpells_Spells.autoHeight = true

  local MenuServiceSpells_Gold
  local MenuServiceSpells_Cost
  local MenuServiceSpells_Chance

  if config.ui_extended_spell_merchant then
    MenuServiceSpells_Gold = MenuServiceSpells_ServiceList_PartScrollPane_pane:createBlock({ id = "MenuServiceSpells_Gold" })
    MenuServiceSpells_Gold.flowDirection = "top_to_bottom"
    MenuServiceSpells_Gold.width = 90
    MenuServiceSpells_Gold.autoHeight = true
    MenuServiceSpells_Cost = MenuServiceSpells_ServiceList_PartScrollPane_pane:createBlock({ id = "MenuServiceSpells_Cost" })
    MenuServiceSpells_Cost.flowDirection = "top_to_bottom"
    MenuServiceSpells_Cost.width = 120
    MenuServiceSpells_Cost.autoHeight = true
    MenuServiceSpells_Chance = MenuServiceSpells_ServiceList_PartScrollPane_pane:createBlock({ id = "MenuServiceSpells_Chance" })
    MenuServiceSpells_Chance.flowDirection = "top_to_bottom"
    MenuServiceSpells_Chance.autoHeight = true
    MenuServiceSpells_Chance.autoWidth = true
  end

  local GUI_ID_MenuServiceSpells_Icon = tes3ui.registerID("MenuServiceSpells_Icon")
  local GUI_ID_MenuServiceSpells_Spell = tes3ui.registerID("MenuServiceSpells_Spell")

  local GUI_ID_MenuServiceSpells_Gold
  local GUI_ID_MenuServiceSpells_Cost
  local GUI_ID_MenuServiceSpells_Chance

  if config.ui_extended_spell_merchant then
    GUI_ID_MenuServiceSpells_Gold = tes3ui.registerID("MenuServiceSpells_Gold")
    GUI_ID_MenuServiceSpells_Cost = tes3ui.registerID("MenuServiceSpells_Cost")
    GUI_ID_MenuServiceSpells_Chance = tes3ui.registerID("MenuServiceSpells_Chance")
  end

  local MenuServiceSpells_Spell_Click = 0x616690
  local MenuServiceSpells_Spell_Help = 0x616810

  -- colors
  local new_effect_color = tes3ui.getPalette("link_color")
  local uncastable_color = {1, 0.2, 0.2}

  -- Fill out the service list.
  for _, spell in ipairs(serviceSpells) do
    -- Create an icon for usability/prettiness.
    local icon = MenuServiceSpells_Icons:createImage({ id = GUI_ID_MenuServiceSpells_Icon, path = string.format("icons\\%s", spell.effects[1].object.icon) })
    icon.borderTop = 2
    icon:setPropertyObject("MenuServiceSpells_Spell", spell)
    icon:register("mouseClick", MenuServiceSpells_Spell_Click)
    icon:register("help", MenuServiceSpells_Spell_Help)


    -- Reimplement text
    local label = MenuServiceSpells_Spells:createTextSelect({ id = GUI_ID_MenuServiceSpells_Spell, text = service_text.base_texts[spell] })
    label:setPropertyObject("MenuServiceSpells_Spell", spell)
    label:register("mouseClick", MenuServiceSpells_Spell_Click)
    label:register("help", MenuServiceSpells_Spell_Help)

    if gold_costs[spell] > gold_amount then
      label.disabled = true
      label.widget.state = 2
    elseif service_chances[spell] < 60 then
      label.widget.state = 4
      label.widget.idleActive = uncastable_color
    elseif (not Known_Effects.getKnowsAllSpellEffects(knownEffects, spell)) then
      -- Known effect? Make it blue.
      label.widget.state = 4
      label.widget.idleActive = new_effect_color
    end

    -- moar text
    if config.ui_extended_spell_merchant then
      label = MenuServiceSpells_Gold:createTextSelect({ id = GUI_ID_MenuServiceSpells_Gold, text = service_text.gold_texts[spell] })
      label:setPropertyObject("MenuServiceSpells_Spell", spell)

      label = MenuServiceSpells_Cost:createTextSelect({ id = GUI_ID_MenuServiceSpells_Cost, text = service_text.cost_texts[spell] })
      label:setPropertyObject("MenuServiceSpells_Spell", spell)

      label = MenuServiceSpells_Chance:createTextSelect({ id = GUI_ID_MenuServiceSpells_Chance, text = service_text.chance_texts[spell] })
      label:setPropertyObject("MenuServiceSpells_Spell", spell)
    end

  end
  menu:updateLayout()

  -- block if you don't have the gold
  -- note that only names and icons are clickable

  local upd_names = menu:findChild("MenuServiceSpells_Spells").children
  local upd_icons = menu:findChild("MenuServiceSpells_Icons").children
  for _, item in ipairs(upd_icons) do
    table.insert(upd_names, item)
  end

  for i=1, #upd_names do
    upd_names[i]:registerBefore(tes3.uiEvent.mouseClick,
        function(_)
          local spell = upd_names[i]:getPropertyObject("MenuServiceSpells_Spell")
          local spell_id = spell.id
          local gold_cost = 0
          if tes3.player.data.motte_spell_storage[spell_id] then
            if custom_price_spells[spell_id] then
              gold_cost = custom_price_spells[spell_id].cost * disp_factor
            else
              gold_cost = tes3.player.data.motte_spell_storage[spell_id].cost * config.economy_spellmerchant_mult * disp_factor
            end
          else
            log:error(string.format("Spell %s, which you attempt to purchase, had not been found in the storage. This should not happen.", spell.id))
          end
          if gold_amount < math.floor(gold_cost) then
            tes3.messageBox("You don't have enough gold to purchase this spell.")
            return false -- this will prevent the regular mouseclick event from being run
          else
            tes3.removeItem({reference = tes3.player, item = "gold_001", count = math.floor(gold_cost)})
            tes3.addItem({reference = service_actor, item = "gold_001", count = math.floor(gold_cost)})
            service_actor.barterGold = service_actor.barterGold + math.floor(gold_cost)
          end
        end
      )
  end

  --end)
end

-- Update the spell selection UI. Spell costs in UI will be calculated once per spell. They'll be also used whenever player casts these spells.
---@param e uiActivatedEventData
local function magic_menu_update(e)
    if not e.newlyCreated then return end

    e.element:registerAfter("preUpdate", function()
        local names = e.element:findChild("MagicMenu_spell_names").children
        local costs = e.element:findChild("MagicMenu_spell_costs").children
        local chances = e.element:findChild("MagicMenu_spell_percents").children
        local cost_title = e.element:findChild("MagicMenu_spell_cost_title")
        if cost_title then
          cost_title.text = (config.determinism_mode == 2) and "Cost/Mastery" or "Cost/Chance"
        end
        for i=1, #names do
            local spell = names[i]:getPropertyObject("MagicMenu_Spell")
            local spell_cost = 0
            local spell_chance = 0
            local skill_for_spell = 0
            local fatigue_normalized = 0
            local sound_factor = 0
            local determinist_spell = false

            -- Check for the semi determinism mode
            if (config.override_costs_alwaystosucceed or not (spell.alwaysSucceeds)) and config.determinism_mode == 1 then
              for _, effect in ipairs(spell.effects) do
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

            local storage_result = SM.get_or_calculate(spell, premade_spells, true, tes3.mobilePlayer)
            if storage_result then
              spell_cost = storage_result.cost
              skill_for_spell = storage_result.skill_for_spell
            end

            -- If the spell has been at least partially processed, edit it's UI entry
            if spell_cost > 0 then
              log:trace(string.format("Spell processed. ID: %s. Your skill for this spell: %d", spell.id, skill_for_spell))
              spell_chance = calculate_cast_chance(spell_cost, tes3.mobilePlayer.willpower.current, tes3.mobilePlayer.luck.current, skill_for_spell)
              -- Fatigue increases costs up to 50% more, these costs do not affect the cast chance
              fatigue_normalized = math.min(1, tes3.mobilePlayer.fatigue.normalized)
              if tes3.mobilePlayer.sound < 0 then
                sound_factor = tes3.mobilePlayer.sound * -0.05
                log:trace(string.format("Player affected by sound. Increasing spell costs by a factor of %.2f...", sound_factor))
              end
              local armor_table = get_armor_coefs(tes3.mobilePlayer)
              local armor_factor = 0
              if config.armor_penalty_perc_max > 0 then
                armor_factor = armor_table.light * math.max(config.armor_penalty_cap_light - tes3.mobilePlayer.lightArmor.current, 0) / config.armor_penalty_cap_light +
                armor_table.medium * math.max(config.armor_penalty_cap_medium - tes3.mobilePlayer.mediumArmor.current, 0) / config.armor_penalty_cap_medium +
                armor_table.heavy * math.max(config.armor_penalty_cap_heavy - tes3.mobilePlayer.heavyArmor.current, 0) / config.armor_penalty_cap_heavy
                armor_factor = armor_factor * (config.armor_penalty_perc_max / 100)
                if armor_factor > 0 then
                  log:trace(string.format("Player's costs are increased by armor. Factor: %.2f.", armor_factor))
                end
              end
              spell_cost = spell_cost * (1 + (config.fatigue_penalty_mult / 100) * (1 - fatigue_normalized) + sound_factor + armor_factor)
              if tes3.mobilePlayer.magicka.current > 100 then
                spell_cost = spell_cost * (1 + (tes3.mobilePlayer.magicka.current - 100) * config.overflowing_magicka_rate / 10000)
              end
              costs[i].text = tostring (math.floor(spell_cost))
              if spell.alwaysSucceeds and not (config.override_chances_alwaystosucceed) then
                spell_chance = 100
                log:trace(string.format("Spell %s has 100 percent success rate.", spell.id))
              end
              if config.determinism_mode == 2 or determinist_spell then
                chances[i].text = "/" .. tostring(math.min(math.floor(spell_chance * 100 / 60), 100))
              elseif config.determinism_mode == 3 then
                spell_chance = Formulas.apply_hybrid_mode(spell_chance)
                chances[i].text = "/" .. tostring(spell_chance)
              else
                if spell_chance > 0 then
                  spell_chance = math.min(spell_chance + config.flat_chance_bonus, 100)
                end
                chances[i].text = "/" .. tostring(math.floor(spell_chance))
              end

            end
        end
    end)
end

-------------------------------------------------------------------------------

local M = {}

function M.register()
  event.register("uiActivated", magic_menu_update,    { filter = "MenuMagic" })
  event.register("uiActivated", spellmaking_block,    { filter = "MenuSpellmaking" })
  event.register("uiActivated", spellmerchant_update, { filter = "MenuServiceSpells" })
  event.register("spellCreated", spellmaking_payment)
  event.register(tes3.event.calcSpellmakingSpellPointCost, spellmaker_update)
end

return M
