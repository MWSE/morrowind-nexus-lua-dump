return {
  ["mod.name"] = "Dubaua Critical",

  ["tooltip.crit.chance"] = "chance to deal",
  ["tooltip.crit.damage"] = "critical damage",

  ["mcm.settings.label"] = "Settings",
  ["mcm.info"] = "This mod adds tier-based critical hits inspired by Oblivion.\n\n" ..
      "For the player and NPCs, critical hits depend on weapon skill, Luck, and weapon type. " ..
      "The game's original (vanilla) critical hits are not disabled by this mod and remain fully active.\n\n" ..
      "Weapon skills are divided into four tiers.\n" ..
      "At novice level (skill 1-24), critical hits are completely disabled. There are no crits at all.\n" ..
      "At apprentice level (skill 25-49), critical chance ranges from 5% to 12%.\n" ..
      "At journeyman level (skill 50-74), critical chance ranges from 10% to 21%.\n" ..
      "At expert level (skill 75+), critical chance ranges from 15% to 30%.\n\n" ..
      "Luck affects critical chance linearly inside each tier. Luck is clamped between 40 and 100. " ..
      "Within this range, Luck linearly interpolates between the minimum and maximum critical chance " ..
      "of the current tier. Luck below 40 does not reduce critical chance further, and Luck above 100 " ..
      "does not increase it. Creatures do not use skill tiers; their rules are described separately below.\n\n" ..
      "Critical damage depends on weapon type and skill tier. Fast and precise weapons such as short blades, " ..
      "bows, and thrown weapons scale to higher critical multipliers, while heavier weapons scale more " ..
      "conservatively. Critical chance and critical damage are calculated independently. Arrows and bolts " ..
      "do not apply their own critical multipliers; all critical logic is resolved at the weapon level. " ..
      "Critical damage is also affected by the internal weapon speed value. For example, a glass dagger has a " ..
      "higher effective multiplier than a heavier daedric tanto, even though both are short blades.\n\n" ..
      "When a hit is detected as potentially affected by a vanilla critical multiplier, the mod attempts to " ..
      "predict this and applies a correction to prevent excessive stacking. If both a vanilla critical hit " ..
      "and a mod critical hit occur on the same attack, the final damage is chosen as the higher value " ..
      "between the original game damage and the modded critical result.\n\n" ..
      "Creatures use a separate system, since they do not rely on weapon skills. Their critical chance scales " ..
      "linearly with level, from 5-10% at level 1 to 15-30% at level 20. Luck is applied afterward using the " ..
      "same linear interpolation model. Creature critical damage increases every 5 levels, scaling from 150% " ..
      "up to a maximum of 400% total damage.\n\n" ..
      "The mod displays critical chance and critical damage multiplier directly in the weapon tooltip. The " ..
      "tooltip is only shown if the relevant weapon skill is 25 or higher.\n\n" ..
      "I intentionally did not expose fine-grained balance settings in the UI. The mod is designed to be " ..
      "playable out of the box with fixed, author-defined balance. If you want to change anything, open " ..
      "main.lua and edit the values directly. All important sections are commented.\n\n" ..
      "This mod is inspired by Reizeron's Lucky Strike and introduces " ..
      "proper scaling based on the actor's own weapon skill (player or NPC) or creature level. " ..
      "It also avoids giga-crits when two crit sources stack at high Luck.\n\n" ..
      "Questions and feedback:\n" .. "dubaua@gmail.com",
  ["mcm.playerCanCrit.label"] = "Enable Player Crits",
  ["mcm.enemyCanCrit.label"] = "Enable Enemy Crits",
}
