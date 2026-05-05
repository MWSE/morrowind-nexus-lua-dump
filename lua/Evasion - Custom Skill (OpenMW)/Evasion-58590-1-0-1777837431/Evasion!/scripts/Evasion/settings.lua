--[[
    Evasion! — Settings
    Perk toggles, feedback, and tooltip filtering.
]]

local I = require("openmw.interfaces")

local MODNAME = "Evasion"

I.Settings.registerPage {
    key = MODNAME, l10n = "none",
    name = "Evasion!",
    description = "Evasion skill — dodge attacks based on armor loadout, stamina, encumbrance, and movement. Perks at 25, 50, 75, 100.",
}
I.Settings.registerGroup {
    key = "Settings_" .. MODNAME, page = MODNAME, l10n = "none",
    name = "Settings", description = "Configure Evasion!",
    permanentStorage = true,
    settings = {
        { key = "maxSanctuary", name = "Max Sanctuary (Unarmored)", renderer = "number", default = 30,
          description = "Maximum Sanctuary bonus at Evasion 100 with no armor equipped. Cap: 10-60.",
          argument = { integer = true, min = 10, max = 60 } },
        { key = "lightMult", name = "Light Armor Retention %", renderer = "number", default = 60,
          description = "How much Evasion is retained per light armor slot. Cap: 0-100.",
          argument = { integer = true, min = 0, max = 100 } },
        { key = "mediumMult", name = "Medium Armor Retention %", renderer = "number", default = 35,
          description = "How much Evasion is retained per medium armor slot. Cap: 0-100.",
          argument = { integer = true, min = 0, max = 100 } },
        { key = "heavyMult", name = "Heavy Armor Retention %", renderer = "number", default = 15,
          description = "How much Evasion is retained per heavy armor slot. Cap: 0-100.",
          argument = { integer = true, min = 0, max = 100 } },
        { key = "npcMult", name = "NPC Sanctuary Multiplier %", renderer = "number", default = 100,
          description = "Scales the Sanctuary granted to NPCs by Evasion. Cap: 0-200.",
          argument = { integer = true, min = 0, max = 200 } },
        { key = "movementBonus", name = "Movement Bonus %", renderer = "number", default = 5,
          description = "Tiny bonus while actively moving. Cap: 0-25.",
          argument = { integer = true, min = 0, max = 25 } },
        { key = "unarmedBonus", name = "Unarmed Bonus %", renderer = "number", default = 5,
          description = "Tiny bonus while no weapon is readied in the right hand. Cap: 0-25.",
          argument = { integer = true, min = 0, max = 25 } },
        { key = "recentJumpBonus", name = "Recent Jump Bonus %", renderer = "number", default = 3,
          description = "Tiny bonus briefly after jumping. Cap: 0-15.",
          argument = { integer = true, min = 0, max = 15 } },
        { key = "repeatMissWindow", name = "Repeat Miss Window (s)", renderer = "number", default = 4,
          description = "Repeated misses from the same attacker inside this window grant reduced skill progress. Cap: 1-10 seconds.",
          argument = { integer = true, min = 1, max = 10 } },
        { key = "repeatMissMinGain", name = "Repeat Miss Minimum Gain %", renderer = "number", default = 50,
          description = "Minimum skill gain from repeated misses by the same attacker. Cap: 20-100.",
          argument = { integer = true, min = 20, max = 100 } },

        { key = "secondWindEnabled", name = "Perk 25: Second Wind", renderer = "checkbox", default = true,
          description = "Dodging while below 50% fatigue has a 25% chance at unlock scaling to 35% at Evasion 100 to restore 20 fatigue. 10s internal cooldown after a successful proc." },
        { key = "riposteEnabled", name = "Perk 50: Riposte", renderer = "checkbox", default = true,
          description = "On a dodge, a 10% chance at unlock scaling to 20% at Evasion 100 to redirect 35% -> 45% of the attacker's estimated intended damage as health damage." },
        { key = "ashSandEnabled", name = "Perk 75: Pocket Ash", renderer = "checkbox", default = true,
          description = "On a dodge, a 35% chance at unlock scaling to 50% at Evasion 100 to blind the attacker by 50 points for 5 seconds. 8s internal cooldown." },
        { key = "vanishEnabled", name = "Perk 100: Vanish", renderer = "checkbox", default = true,
          description = "On a dodge, become 100% Chameleon for 5 seconds and hit the attacker with a powerful Calm for 5 seconds. 30s internal cooldown." },

        { key = "showFeedback", name = "Visible Feedback", renderer = "checkbox", default = false,
          description = "Show on-screen messages when perks trigger." },
        { key = "detailedFeedback", name = "Detailed Feedback Messages", renderer = "checkbox", default = false,
          description = "When enabled, perk feedback includes numeric effect details. When disabled, messages are concise, e.g. 'Pocket Ash!' instead of 'Pocket Ash! (Blind 50 for 5s).'" },
        { key = "tooltipUnlockedOnly", name = "Tooltip Shows Unlocked Perks Only", renderer = "checkbox", default = false,
          description = "When enabled, the Evasion skill tooltip lists only perks you have already unlocked. If no perks are unlocked yet, it shows the next perk threshold instead." },
        { key = "debugMessages", name = "Debug Messages", renderer = "checkbox", default = false,
          description = "Temporary testing aid. Shows Sanctuary recalculations and Evasion XP gain messages." },
    },
}
