--[[
    Toxicology! — Config
    Central tuning file. All numerical values, thresholds, and lists live here.
]]

local config = {
    skillId = 'toxicology',
    startLevel = 5,
    maxLevel = 100,
    classBonus = 10, -- +10 for Stealth-specialisation classes

    -- ─── Charges ────────────────────────────────────────────────────────────
    -- Number of hits a single application lasts.
    -- Smooth formula: max(1, floor(skill / 20 + 1)) capped at maxCharges.
    -- 1 charge at 1-19, 2 at 20-39, 3 at 40-59, 4 at 60-79, 5 at 80-100.
    charges = {
        minCharges = 1,
        maxCharges = 5,
        chargesPerTier = 20,
    },

    -- ─── XP gain ────────────────────────────────────────────────────────────
    -- All values multiplied by I.SkillFramework's per-level scaling.
    xp = {
        apply = 0.30,   -- applying a poison to a weapon
        strike = 1.00,  -- successful hit with a poisoned weapon
        kill = 2.00,    -- a poisoned target dies from poison within killWindow
        killWindow = 10.0, -- seconds after last poison hit to count kill
        -- When the player brews a potion with harmful effects, this fraction of
        -- the Alchemy XP grant is mirrored into Toxicology. 0.5 = half.
        brewAlchemyShare = 0.5,
    },

    -- ─── Perks ──────────────────────────────────────────────────────────────
    perks = {
        -- Perk 25: Master Coating — same-poison reapplications reinforce an existing coating.
        masterCoatingLevel = 25,

        -- Perk 50: Compound Blend — unlocks up to three simultaneous coatings.
        compoundBlendLevel = 50,
        compoundBlendMaxLayers = 3,

        -- Perk 75: Efficient Coating — flat chance to preserve every active
        -- coating layer on a poisoned hit. The single proc roll is shared across
        -- all Compound Blend layers so layer charges stay synchronized.
        efficientCoatingLevel = 75,
        efficientCoatingChance = 15, -- fixed 15% chance

        -- Perk 100: Toxic Perfection — chance to apply a 10-second Weakness
        -- to Poison effect before the weapon's poison payload.
        toxicPrecisionLevel = 100,
        toxicPrecisionChance = 35,
        toxicPrecisionMagnitude = 25,
        toxicPrecisionDuration = 10,
    },

    -- ─── Weapon rules ───────────────────────────────────────────────────────
    weapons = {
        -- Which weapon types can be poisoned.
        -- Ranged weapons hold the poison on the BOW, not on ammunition.
        -- Thrown weapons use record-keyed coating state so projectile hits can resolve
        -- after the thrown object leaves the player's inventory. A coating applies to
        -- the next N successful throws of that thrown-weapon record.
        allowedTypes = {
            ShortBladeOneHand = true,
            LongBladeOneHand = true,
            LongBladeTwoHand = true,
            BluntOneHand = true,
            BluntTwoClose = true,
            BluntTwoWide = true, -- staves!
            SpearTwoWide = true,
            AxeOneHand = true,
            AxeTwoHand = true,
            MarksmanBow = true,
            MarksmanCrossbow = true,
            MarksmanThrown = true,
            -- Arrow and Bolt are deliberately excluded — we poison the bow.
        },

        -- Thrown weapons: poison the next N successful throws of this thrown
        -- weapon record. This avoids runtime weapon-record generation.
        thrownMode = 'recordState',
    },

    -- ─── Harm classifier ────────────────────────────────────────────────────
    -- A potion is a "poison candidate" if ANY of its effects are harmful.
    -- Primary source: eff.harmful flag from the engine.
    -- Fallback: explicit allowlist of effect IDs that are *always* treated as
    -- harmful regardless of how the engine reports them (defensive).
    alwaysHarmfulEffects = {
        -- Direct damage
        damagehealth = true,
        damagefatigue = true,
        damagemagicka = true,
        damageattribute = true,
        damageskill = true,
        drainhealth = true,
        drainfatigue = true,
        drainmagicka = true,
        drainattribute = true,
        drainskill = true,
        absorbhealth = true,
        absorbfatigue = true,
        absorbmagicka = true,
        absorbattribute = true,
        absorbskill = true,

        -- Elemental damage
        firedamage = true,
        frostdamage = true,
        shockdamage = true,
        poison = true,

        -- Control / debuff
        paralyze = true,
        silence = true,
        blind = true,
        sound = true,
        burden = true,
        weaknesstofire = true,
        weaknesstofrost = true,
        weaknesstoshock = true,
        weaknesstomagicka = true,
        weaknesstocommondisease = true,
        weaknesstoblightdisease = true,
        weaknesstocorprusdisease = true,
        weaknesstonormalweapons = true,
        weaknesstopoison = true,

        -- Mind effects (hostile when cast on player)
        demoralizecreature = true,
        demoralizehumanoid = true,
        frenzycreature = true,
        frenzyhumanoid = true,
        charm = true,
        commandcreature = true,
        commandhumanoid = true,

        -- Equipment destruction
        disintegratearmor = true,
        disintegrateweapon = true,

        -- Soul trap: not technically harmful but fits poison theme;
        -- leave off the list so player can keep a Soul Trap *potion*.

        -- Corprus: a disease, not a poison effect per se — omit.
    },

    -- ─── Alcohol classifier ─────────────────────────────────────────────────
    -- Records matching this list are ignored when the Ignore Alcohol setting is
    -- enabled. Keep IDs lower-case because callers lower-case record ids before
    -- lookup. The list intentionally covers vanilla, Tribunal/Bloodmoon, and
    -- Tamriel Data beverage/alcohol records whose harmful self-effects should
    -- not make them weapon-poison candidates.
    alcohol = {
        recordIds = {
            -- Vanilla / Tribunal / Bloodmoon
            potion_cyro_brandy_01 = true,
            potion_cyro_whiskey_01 = true,
            potion_comberry_brandy_01 = true,
            potion_comberry_wine_01 = true,
            potion_local_brew_01 = true,
            potion_local_liquor_01 = true,
            potion_ancient_brandy = true,
            p_vintagecomberrybrandy1 = true,
            potion_nord_mead_01 = true,

            -- Tamriel Data common beverage/alcohol records
            t_rea_drink_liquoraeli_01 = true,
            t_rga_drink_aibe_01 = true,
            t_imp_drink_aleakul_01 = true,
            t_imp_drink_cideraliyew_01 = true,
            t_nor_drink_beer_01 = true,
            t_imp_drink_wineblackhill_01 = true,
            t_nor_drink_bodja_01 = true,
            t_imp_drink_winebattle_01 = true,
            t_imp_drink_winefreeestat_01 = true,
            t_nor_drink_fyrg_01 = true,
            t_nor_drink_gjeche_01 = true,
            t_nor_drink_gjulve_01 = true,
            t_rga_drink_winesutchgonogro_01 = true,
            t_de_drink_bourbongoya_01 = true,
            t_we_drink_pigmilkbeerjagga_01 = true,
            t_imp_drink_cherrybrandy_01 = true,
            t_nor_drink_beerlight_01 = true,
            t_de_drink_liquorllotham_01 = true,
            t_de_drink_sweetbarrel_wine_01 = true,
            t_imp_drink_ricebeermori_01 = true,
            t_cnq_ngopta = true,
            t_qyk_ngopta = true,
            t_pi_drink_palmwine = true,
            t_yne_drink_pudjing = true,
            t_de_drink_punavitjug = true,
            t_de_drink_punavitresin_01 = true,
            t_nor_drink_risla_01 = true,
            t_we_drink_meatjuicerotmeth_01 = true,
            t_imp_drink_winerufinoclr_01 = true,
            t_rga_drink_sift = true,
            t_imp_drink_winesour = true,
            t_nor_drink_strmead_01 = true,
            t_imp_drink_winesuriliebr_01 = true,
            t_imp_drink_winesweet = true,
            t_rga_drink_winesutchtalan_01 = true,
            t_imp_drink_winetamikaclr_01 = true,
            t_imp_drink_winetwinmoon_01 = true,
            t_orc_drink_liquorungorth_02 = true,
            t_we_drink_wine_01 = true,
            t_nor_drink_snowberryaleveig_01 = true,
            t_nor_drink_winereach_01 = true,
            t_bre_drink_winewayrest_01 = true,
            t_imp_drink_winewolfsbl_01 = true,
            T_He_Drink_WineAthelin = true,
            T_Bre_Drink_WineBalfiera_01 = true,
            T_Bre_Drink_AperitifBevonche_01 = true,
            T_Rga_Drink_Bogru_01 = true,
            T_Bre_Drink_LiquorBreque_01 = true,
            T_Rga_Drink_CactusWine_01 = true,
            T_Bre_Drink_BrandyChallegoux_01 = true,
            T_QyC_Cimoa = true,
            T_Bre_Drink_DigestifEillevon_01 = true,
            T_De_Drink_GuarMilk_01 = true,
            T_Rea_Drink_TeaGyrrg_01 = true,
            T_He_Drink_BeerHautoma = true,
            T_Bre_Drink_WineHeartplum_01 = true,
            T_Bre_Drink_Jinevere = true,
            T_Bre_Drink_WineMarivon_01 = true,
            T_Imp_Drink_WinePlalloVin_01 = true,
            T_Bre_Drink_CiderPommon_01 = true,
            T_He_Drink_WineRosado = true,
            T_Rga_Drink_Soge_01 = true,
            T_He_Drink_WineSolicichi = true,
            T_Imp_Drink_WineSour = true,

            -- Skyrim: Home of the Nords unique alcohol records
            sky_ire_kw03_vinbrandy = true,
            sky_ire_kw20_vinwine = true,
        },
        terms = {
            'alcohol', 'brandy', 'whiskey', 'whisky', 'wine', 'beer', 'mead',
            'ale', 'liquor', 'bourbon', 'cider', 'grog', 'rum', 'vodka',
            'stout', 'porter', 'lager', 'moonshine', 'sujamma', 'mazte', 'matze',
            'shein', 'greef', 'flin', 'rotmeth', 'battlewine', 'ricebeer',
            'snowberryale', 'strongmead', 'pigmilkbeer', 'local_brew',
            'local_liquor', 'nord_mead', 'vintagecomberrybrandy',
        },
    },


    -- Verified fallback pool for builds/load orders where generic potion-record
    -- enumeration does not surface all eligible harmful potions reliably.
    -- These are only used if the record actually exists in the current load order.
    fallbackExistingPoisonIds = {
        'p_burden_q',
        'p_drain_intelligence_q',
        'p_drain_magicka_q',
        't_com_poison_drainwill_q',
        't_qyk_ngopta',
    },

    -- ─── UI ─────────────────────────────────────────────────────────────────
    ui = {
        tooltipPoisonColor = { 0.55, 0.85, 0.55 },  -- green tint for poison name
        tooltipChargesColor = { 0.85, 0.85, 0.85 }, -- grey for charge counter
        messageDuration = 3.0,
    },

    -- ─── Dev ────────────────────────────────────────────────────────────────
    debug = {
        defaultDebug = false,
    },
}

return config
