local tempbuff = {
  "p_fire resistance_s",
  "p_fire_shield_s",
  "p_fortify_agility_s",
  "p_fortify_endurance_s",
  "p_fortify_intelligence_s",
  "p_fortify_luck_s",
  "p_fortify_magicka_s",
  "p_fortify_speed_s",
  "p_fortify_strength_s",
  "p_fortify_willpower_s",
  "p_frost_resistance_s",
  "p_frost_shield_s",
  "p_lightning shield_s",
  "p_magicka_resistance_s",
  "p_poison_resistance_s",
  "p_reflection_s",
  "p_shock_resistance_s",
  "p_spell_absorption_s",
  }

local function onCombatStart(e)
  if e.actor == tes3.mobilePlayer then
    return
  end
  if e.target ~= tes3.mobilePlayer then
    return
  end

  local doOnce = mwscript.getSpellEffects({reference = e.actor, spell = "0s_buffed"})
  if doOnce then
    return
  end

  mwscript.addSpell({reference = e.actor, spell = "0s_buffed"})

  if e.actor.object.objectType == tes3.objectType.creature then
    return
  end

  local tempboost = table.choice(tempbuff)
  mwscript.addItem({reference = e.actor, item = tempboost})
  mwscript.equip({reference = e.actor, item = tempboost})
end

local function initialized()
  if tes3.isModActive("HarderBattle.ESP") then
    event.register("combatStart", onCombatStart)
  else
    mwse.log("HarderBattle.ESP not active")
  end
end
event.register("initialized", initialized)