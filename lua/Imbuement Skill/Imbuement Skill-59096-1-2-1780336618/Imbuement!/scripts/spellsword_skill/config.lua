--[[
    Spellsword! Skill — Config

    Central tuning file. All numerical values, thresholds, and lists live here.
    Built on the same architecture as Toxicology! — every value is exposed in
    the settings menu so the player can tune without touching this file.

    This mod overlays a "spellsword" SKILL on top of the existing Spellsword
    (Imbue Weapon) mod. The skill gates how many charges each imbue cast grants,
    how strong the elemental synergy is, how much magicka the Active mode drains
    per hit, and whether spell-stacking on the same imbue is allowed.

    XP is awarded only when the player actually USES the imbue: depleting a
    charge or paying magicka via the Active mode. Detection is strictly limited
    to the three vanilla Spellsword spell records:
        spellsword_fire, spellsword_frost, spellsword_shock
    Spellmaking-crafted "absorb"-based spells are deliberately ignored.
]]

local config = {
    skillId   = 'imbuement',
    startLevel = 5,
    maxLevel   = 100,
    classBonus = 10, -- +10 for Combat-specialisation classes

    -- The three valid imbue spell record ids. These are the only spells that
    -- count for charge override, settings drive, and XP gain. The set is
    -- closed by design — the user explicitly asked for spellmaking and modded
    -- absorb-based spells to be excluded so the progression is bounded.
    validImbueSpellIds = {
        spellsword_fire  = true,
        spellsword_frost = true,
        spellsword_shock = true,
    },

    -- ─── Charges (Charges mode) ──────────────────────────────────────────────
    -- Start at skill 5 with 10 charges (matches base Spellsword behaviour),
    -- gain +5 charges at every milestone (every 20 skill levels).
    --
    --   skill 5  → 10 charges
    --   skill 20 → 15 charges (milestone 1)
    --   skill 40 → 20 charges (milestone 2)
    --   skill 60 → 25 charges (milestone 3)
    --   skill 80 → 30 charges (milestone 4)
    --   skill 100 → 35 charges (milestone 5)
    --
    -- Formula: baseCharges + floor(skill / milestoneInterval) * chargesPerMilestone
    -- Capped at maxCharges to keep the late game predictable.
    charges = {
        baseCharges       = 10,
        chargesPerMilestone = 5,
        milestoneInterval = 20,
        maxCharges        = 35,
    },

    -- ─── Active mode magicka efficiency ──────────────────────────────────────
    -- "Active mode is based on maximum magicka so that can stay untouched" —
    -- the mode itself is preserved as base Spellsword shipped it: each hit
    -- drains the spell's magicka cost, you can keep fighting as long as you
    -- have magicka. What scales with skill is the EFFICIENCY of that drain:
    -- as you master the discipline, you spend less magicka per imbued strike.
    --
    -- Reduction percentage = floor(skill / milestoneInterval) * stepPercent,
    -- capped at maxReductionPercent. At skill 5 the reduction is 0% (you pay
    -- the full spell cost); at skill 100 the reduction is at its maximum.
    --
    --   skill 5   → 0%  reduction (full cost)
    --   skill 20  → 10% reduction
    --   skill 40  → 20% reduction
    --   skill 60  → 30% reduction
    --   skill 80  → 40% reduction
    --   skill 100 → 50% reduction
    activeMagickaEfficiency = {
        stepPercent         = 10,
        maxReductionPercent = 50,
    },

    -- ─── Elemental buff scaling ──────────────────────────────────────────────
    -- Base Spellsword's `ElementalBuffAmount` is a flat multiplier (default 0.15)
    -- applied when an elemental damage type matches an attack type (fire/slash,
    -- shock/chop, ice/thrust). We OWN this setting while our skill is enabled:
    -- we compute it from a configurable base and a per-milestone step, then
    -- write it into Spellsword's SettingsImbuleWeapon storage every tick.
    --
    --   skill 5   → base (default 0.05 = 5%)
    --   skill 20  → base + 1 step (default 0.10)
    --   skill 40  → base + 2 steps (default 0.15)
    --   skill 60  → base + 3 steps (default 0.20)
    --   skill 80  → base + 4 steps (default 0.25)
    --   skill 100 → base + 5 steps (default 0.30)
    elementalBuff = {
        baseBuff          = 0.05,
        stepPerMilestone  = 0.05,
        maxBuff           = 0.30,
    },

    -- ─── Spell stacking gate ─────────────────────────────────────────────────
    -- "Spell stacking is proportional to the level of the spellsword skill" —
    -- treated as a milestone unlock. Below the unlock threshold we force
    -- Spellsword's `SpellStacking` setting OFF. At or above the threshold,
    -- stacking is allowed (subject to the user's stacking toggle in our mod).
    spellStacking = {
        unlockLevel = 50,
    },

    -- ─── Perks ───────────────────────────────────────────────────────────────
    -- Four milestone unlocks at 25 / 50 / 75 / 100 that add utility on top of
    -- the four scaling tracks above. All values configurable in the settings.
    --
    -- Design constraints honoured:
    --   * Every perk is gated by a strict valid-imbue check (only the three
    --     vanilla spellsword spells trigger them).
    --   * No perk modifies the target's stats or hooks the hit script — they
    --     all work through the events the base Spellsword mod already exposes
    --     (IW_SpellCast / IW_DecrementSpellCharge / IW_RemoveMagicka) and
    --     through magicka adjustments on the player.
    --   * Each perk is balanced for utility, not raw damage. The scaling
    --     tracks already provide power growth; perks provide choice and flow.
    perks = {
        -- Perk 25: Lingering Imbue — when you cast a fresh valid imbue while
        -- another valid imbue (any element) is active with charges remaining,
        -- the leftover charges carry over to the new cast. Effectively lets
        -- you switch elements without throwing away your remaining hits.
        lingeringImbueLevel = 25,

        -- Perk 50: Arcane Flow — every successful imbued hit restores a small
        -- amount of magicka, gated by a short cooldown. Built so combat feeds
        -- magic — NOT to enable unlimited casting. The cooldown ensures rapid
        -- weapon swings can't compound the restore into infinite sustain.
        --
        -- Defaults: 2 magicka per proc, 0.5 second cooldown → at most
        -- 4 magicka/sec sustain. With Active-mode hits costing 9 magicka raw
        -- (or 4.5 at 50% efficiency), the floor still requires a magicka pool.
        arcaneFlowLevel        = 50,
        arcaneFlowMagickaPerHit = 2,    -- magicka per successful imbued hit
        arcaneFlowCooldownSec  = 0.5,   -- seconds between procs

        -- Perk 75: Perfect Conduit — switching imbue elements mid-combat
        -- grants temporary stat bonuses, but only along the elemental cycle.
        -- Going the "wrong way" gives no bonus. This is the combo-routing
        -- mechanic.
        --
        -- Cycle: Fire → Shock → Frost → Fire
        --   Fire → Shock: Fortify Speed (attack speed)
        --   Shock → Frost: Fortify Agility (stagger resistance — in Morrowind,
        --                  staggering on hit is gated by Agility)
        --   Frost → Fire: Fortify Strength (weapon damage scales with Strength)
        --
        -- Buffs do not stack with themselves — re-triggering the same
        -- transition refreshes the timer. Different transitions can run
        -- simultaneously (they buff different stats).
        perfectConduitLevel    = 75,
        perfectConduitMagnitude = 20,    -- Fortify amount applied to the stat
        perfectConduitDurationSec = 8,   -- seconds the buff lasts

        -- Perk 100: Arcane Overdrive — capstone "ultimate state" triggered via
        -- the `spellsword overdrive` console command. During the window:
        --   • Charge consumption in Charges mode is fully refunded
        --   • Magicka consumption in Active mode is fully refunded
        --   • Any fresh imbue cast carries over previous charges, regardless
        --     of element (combines with Lingering Imbue logic)
        --
        -- Once the window expires, a cooldown begins. The cooldown is the
        -- balancing knob — long enough to feel like "once per combat" without
        -- requiring engine-level combat-state detection.
        arcaneOverdriveLevel       = 100,
        arcaneOverdriveDurationSec = 12,   -- 10-15 sec target, 12 = middle
        arcaneOverdriveCooldownSec = 90,   -- approximates "once per combat"
    },

    -- ─── XP gain ─────────────────────────────────────────────────────────────
    -- The mod uses Skill Framework's per-level scaling internally. These are
    -- the raw per-event weights — the actual XP is `weight * skillFramework's
    -- normal scaling * user xpMultiplier setting`.
    --
    --   apply       : every successful imbue cast (one-shot, gives a small bump)
    --   chargeSpend : every charge consumed via Charges-mode hit
    --   magickaSpend: every Active-mode hit that pays magicka
    --   firstUseFree: first hit in Active mode (free) — small XP token by default
    xp = {
        apply         = 0.40,
        chargeSpend   = 1.00,
        magickaSpend  = 1.10,
        firstUseFree  = 0.25,
    },

    -- ─── Skill books ─────────────────────────────────────────────────────────
    -- Picked to fit the lore theme: combat-magic primers that overlap with
    -- spellsword identity. These are widely available in the base game, so
    -- the player can actually find them in the wild.
    skillBooks = {
        'bk_legendaryscourge',       -- Legendary Scourge
        'bk_2920_eveningstar',       -- 2920, Evening Star (v12) — Spell-Weaving / dueling theme
    },

    -- ─── Race modifiers ──────────────────────────────────────────────────────
    -- Spellsword is iconically Breton (magic-resistant warriors) and Dunmer
    -- (versatile combat-mages). Tamriel Data races mirrored from Toxicology
    -- so multi-region playthroughs feel consistent.
    raceBonuses = {
        { id = 'breton',         amount = 10 },
        { id = 'dark elf',       amount = 10 },
        { id = 'high elf',       amount = 5  },
        { id = 'redguard',       amount = 5  },
        { id = 'imperial',       amount = 5  },
        -- Tamriel Data mirrors (literal record ids)
        { id = 'T_Bm_Naga',      amount = 5  },
        { id = 'T_Yne_Ynesai',   amount = 5  },
        { id = 'T_Sky_Reachman', amount = 10 },
        { id = 'T_Pya_SeaElf',   amount = 5  },
    },

    -- ─── UI / tooltip ────────────────────────────────────────────────────────
    ui = {
        -- Cost used to estimate "Active uses" in the tooltip. The three valid
        -- imbue spells all cost 9 (see ImbuleWeapon_load.lua). We expose this
        -- as config so future Spellsword updates don't break the tooltip math.
        imbueSpellCost      = 9,
        tooltipDecimalPlaces = 1, -- for buff display
    },

    -- ─── Debug ───────────────────────────────────────────────────────────────
    debug = {
        defaultDebug = false,
    },
}

return config
