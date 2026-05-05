-- ============================================================
-- ARTIFACT ID LIST
-- Comprehensive list of all artifact item IDs from:
--   Morrowind, Tribunal, Bloodmoon, official plugins,
--   Tamriel Rebuilt, and Tamriel Data
-- IDs are stored lowercase for case-insensitive matching.
-- ============================================================

local artifacts = {}

-- Build a fast lookup set from a flat list
local ids = {
    -- ========================================================
    -- MORROWIND — Weapon Artifacts
    -- ========================================================
    "claymore_chrysamere_unique",       -- Chrysamere
    "katana_goldbrand_unique",          -- Goldbrand
    "katana_bluebrand_unique",          -- Eltonbrand
    "daedric_crescent_unique",          -- Daedric Crescent
    "longsword_umbra_unique",           -- Umbra Sword
    "dagger_fang_unique",              -- Fang of Haynekhtnamet
    "ebony_dagger_mehrunes",           -- Mehrunes' Razor
    "mace_molag_bal_unique",           -- Mace of Molag Bal
    "daedric_scourge_unique",          -- Scourge
    "warhammer_crusher_unique",        -- Skull Crusher
    "sunder",                          -- Sunder
    "keening",                         -- Keening
    "staff_hasedoki_unique",           -- Staff of Hasedoki
    "staff_magnus_unique",             -- Staff of Magnus
    "warhammer_volendrung_unique",     -- Volendrung
    "ebony_bow_auriel",                -- Auriel's Bow
    "longbow_shadows_unique",          -- Bow of Shadows
    "claymore_iceblade_unique",        -- Ice Blade of the Monarch
    "spear_mercy_unique",              -- Spear of Bitter Mercy
    "fork_horripilation_unique",       -- Fork of Horripilation
    "cleaver_felms_unique",            -- Cleaver of St. Felms
    "battleaxe_yourpalsbane_uniq",     -- Wings of the Queen of Bats (unused but in CS)
    "crosier_llothis_unique",          -- Crosier of St. Llothis
    "bonebiter_bow_unique",            -- Bonebiter Bow of Sul-Senipul

    -- ========================================================
    -- MORROWIND — Armor Artifacts
    -- ========================================================
    "cuirass_savior_unique",           -- Cuirass of the Savior's Hide
    "ebon_plate_cuirass_unique",       -- Ebony Mail
    "dragonbone_cuirass_unique",       -- Dragonbone Cuirass
    "lords_cuirass_unique",            -- Lord's Mail
    "spell_breaker_unique",            -- Spell Breaker
    "towershield_eleidon_unique",      -- Eleidon's Ward
    "helm_bearclaw_unique",            -- Helm of Oreyn Bearclaw
    "clavicus_unique",                 -- Masque of Clavicus Vile
    "gauntlet_fists_l_unique",         -- Fists of Randagulf (left)
    "gauntlet_fists_r_unique",         -- Fists of Randagulf (right)
    "boots_apostle_unique",            -- Boots of the Apostle
    "boots_blinding_unique",           -- Boots of Blinding Speed
    "tenpaceboots",                    -- Ten Pace Boots
    "shadow_shield",                   -- Shadow Shield

    -- ========================================================
    -- MORROWIND — Clothing Artifacts
    -- ========================================================
    "ring_denstagmer_unique",          -- Denstagmer's Ring
    "ring_khajiit_unique",             -- Ring of Khajiit
    "ring_mentor_unique",              -- Mentor's Ring
    "ring_phynaster_unique",           -- Ring of Phynaster
    "ring_surrounding_unique",         -- Ring of Surroundings
    "ring_vampiric_unique",            -- Vampiric Ring
    "ring_warlock_unique",             -- Warlock's Ring
    "ring_wind_unique",                -- Ring of the Wind
    "necromancers_amulet_uniq",        -- Necromancer's Amulet
    "amulet_unity_uniq",              -- Amulet of Unity
    "heart_ring",                      -- Heart Ring (Dagoth Ur)
    "moon_and_star",                   -- Moon-and-Star
    "robe_lich_unique",                -- Robe of the Lich (unused vanilla, available in Tribunal)
    "hair_shirt_unique",               -- Hair Shirt of Saint Aralor
    "shoes_strilms_unique",            -- Shoes of St. Rilms
    "bloodworm_helm_unique",           -- Bloodworm Helm
    "ward_akavir_unique",              -- Ward of Akavir
    "veloth_judgement_unique",         -- Veloth's Judgement (if present)

    -- ========================================================
    -- MORROWIND — Misc Artifacts
    -- ========================================================
    "misc_soulgem_azura",              -- Azura's Star
    "artifact_bittercup_01",           -- Bittercup
    "skeleton_key",                    -- Skeleton Key
    "madstone_unique",                 -- Madstone of the Ahemmusa
    "wraithguard",                     -- Wraithguard (right)
    "wraithguard_jury_rig",            -- Wraithguard (left/jury-rigged)

    -- ========================================================
    -- TRIBUNAL — Artifacts
    -- ========================================================
    "nerevarblade_01",                 -- Trueflame (unlit)
    "nerevarblade_01_flame",           -- Trueflame (lit)
    "sword of almalexia",              -- Hopesfire
    "mazed_band_end",                  -- Barilzar's Mazed Band

    -- ========================================================
    -- BLOODMOON — Artifacts
    -- ========================================================
    "bm_ring_hircine",                 -- Hircine's Ring
    "bm_hunterspear_unique",           -- Spear of the Hunter
    "bm_mace_aevar_uni",               -- Mace of Aevar Stone-Singer
    "bm ice longsword_fg_unique",      -- Stalhrim Longsword of Flame
    "bm_amulstr1",                     -- Hunter's Amulet of Strength
    "bm_amulspd1",                     -- Hunter's Amulet of Speed

    -- ========================================================
    -- OFFICIAL PLUGINS
    -- ========================================================
    "ebq_artifact",                    -- Adamantium Helm of Tohan (plugin ESP name is EBQ_Artifact)
    "helm_tohan_unique",               -- Adamantium Helm of Tohan (actual item ID)
    "ring_azura_unique",               -- Ring of Azura (Area Effect Arrows plugin)

    -- ========================================================
    -- TAMRIEL REBUILT / TAMRIEL DATA — Weapon Artifacts
    -- ========================================================
    -- Daggers / Short Blades
    "t_com_uni_bladeofwoe",              -- Blade of Woe
    "t_ayl_uni_chillrend",               -- Chillrend
    "t_imp_uni_nafaalilargurclaw",       -- Claw of Nafaalilargus
    "t_imp_uni_nafaalilargusClaw",       -- (alt casing)
    "t_dae_uni_meridiadagger",           -- Dagger of Meridia
    "t_dae_uni_souldagger",              -- Dagger of the Open Soul
    "t_imp_uni_debaser",                 -- Debaser
    "t_imp_uni_sword_dibella",           -- Heartseeker
    "t_nor_uni_kahvozeins_fang_01",      -- Kahvozein's Fang
    "t_rga_uni_nebstalon",               -- Neb's Talon
    "t_nor_uni_red_eagles_fury_01",      -- Red Eagle's Fury
    "t_bre_uni_shardofvehemence",        -- Shard of Vehemence
    "t_rea_uni_voidknife",               -- Void Knife
    "t_nor_uni_godsbloodseax",           -- Vrigyn

    -- Axes
    "t_nor_uni_askenhost",               -- Askenhost
    "t_dae_uni_boethiahaxe",             -- Axe of Boethiah
    "t_nor_uni_godsbloodaxe",            -- Hrygg
    "tr_m4_orlukhcleaver",               -- Orlukh's Cleaver
    "t_nor_uni_axerhorlaks",             -- Rhorlak's Axe
    "t_dae_uni_ruefulaxe",               -- Rueful Axe
    "t_imp_uni_thoriclesaxe",            -- Thoricles' Bane

    -- Blunt / Maces
    "t_bre_uni_azramace",                -- Azra's Mace
    "t_ned_uni_hornsofhanugalba",        -- Horns of Hanugalba
    "t_dreu_uni_scepterofviolation",     -- Scepter of Violation
    "t_nor_uni_stuhnsforge",             -- Stuhn's Forge
    "t_cr_uni_agenchegel",               -- Agenchegel
    "t_imp_uni_championcudgel",          -- Champion's Cudgel
    "t_dae_uni_cane_madstar",            -- Cane of the Mad Star
    "t_com_uni_chimere_staff",           -- Chimere's Staff
    "t_com_uni_clarentavious_staff",     -- Clarentavious' Staff
    "t_nor_uni_hammerstorig",            -- Hammer of Lord Storig
    "t_com_uni_mosslog",                 -- Mosslog
    "t_dwe_uni_oathrung",                -- Oathrung
    "t_nor_uni_hammerolfor",             -- Olfor's Hammer
    "t_nor_uni_runic_hammer_01",         -- Runic Hammer
    "t_dae_uni_sanguinesrose",           -- Sanguine Rose
    "t_dwe_uni_hammergharen_01",         -- Hammer of Gharen

    -- Staves
    "t_de_uni_stafffouner",              -- Staff of the Founder
    "t_de_uni_stafffouder",              -- (alt spelling)
    "t_de_uni_stafffounder",             -- (alt spelling)
    "t_bre_uni_staff_lich",              -- Staff of the Lich
    "t_de_uni_staffroris",               -- Staff of St. Roris
    "t_de_uni_staffveloth",              -- Staff of St. Veloth
    "t_com_uni_typossophia",             -- Staff of the Typos Sophia
    "t_dae_uni_wabbajack",               -- Wabbajack

    -- Spears
    "t_de_uni_muatra",                   -- Muatra
    "t_imp_uni_nandorspear",             -- Nandor's Spear
    "t_nor_uni_shorspear",               -- Spear of Shor's Blood
    "t_arg_uni_spearulaqth",             -- Spear of Warchief Ulaqth
    "t_nor_uni_godsbloodspear",          -- Ulfgyir
    "t_rga_uni_utanogo_01",              -- Utanogo
    "t_yne_uni_wyrm_spear",              -- Wyrm's Fang Spear

    -- Bows
    "t_dae_uni_bowofheavenshail_01",     -- Bow of Heaven's Hail
    "t_dae_uni_bowofheavenshail",        -- (alt ID)
    "t_dwe_uni_neldracsreach",           -- Neldrac's Reach
    "t_rga_uni_snakebow",                -- Sep's Bow
    "t_com_uni_sunkindler",              -- Sunkindler

    -- Long Blades
    "t_dreu_uni_abysmalblade",           -- Abysmal Blade
    "t_de_uni_akrash",                   -- Akrash
    "t_dae_uni_corruptbreaker",          -- Corrupted Dawnbreaker
    "t_imp_uni_cutlassarchon",           -- Cutlass of Lilmoth
    "t_dae_uni_dawnbreaker",             -- Dawnbreaker
    "t_rga_uni_duptro_01",               -- Duptro
    "t_dae_uni_ebonyblade",              -- Ebony Blade
    "t_he_uni_keenblood",                -- Keenblood Blade
    "t_dae_uni_nebcrescen",              -- Neb-Crescen
    "t_nor_uni_red_eagles_bane_01",      -- Red Eagle's Bane
    "t_imp_uni_umbranoxsabre",           -- Saber of King Fasil
    "t_com_uni_spider_impaler",          -- Spider Impaler
    "t_imp_uni_swiftcutsaber",           -- Swiftcut Saber
    "t_dae_uni_moonreiver",              -- Sword of the Moon Reiver
    "t_de_uni_swordnotheld",             -- Sword Not Held
    "t_imp_uni_taldeussword",            -- Sword of Taldeus
    "t_imp_uni_sybaris",                 -- Sybaris
    "t_rga_uni_tangra_01",               -- Tangra
    "t_imp_uni_bladeofkenes",            -- Blade of Kenes
    "t_rga_uni_gatkhel_01",              -- Gatkhel
    "t_dae_uni_gwailo",                  -- Goujian
    "t_yne_uni_kurahk",                  -- Kurahk
    "t_yne_uni_ kurahk",                 -- (alt with space)
    "t_imp_uni_raphalaskatana",          -- Raphalas' Sword
    "t_ayl_uni_sinweaver",               -- Sinweaver
    "t_imp_uni_scepteroftheseas",        -- Scepter of the Seas

    -- ========================================================
    -- TAMRIEL REBUILT / TAMRIEL DATA — Armor Artifacts
    -- ========================================================
    -- Boots
    "t_dae_uni_bootssaviorshide",        -- Boots of the Savior's Hide
    "t_dae_uni_bootsofattronach",        -- Boots of the Atronach
    "t_dae_uni_bootsofpeace_01",         -- Boots of Peace
    "t_de_uni_pasoroth_boots",           -- War Boots of Pasoroth

    -- Cuirass
    "t_de_uni_pasoroth_cuirass",         -- War Cuirass of Pasoroth
    "t_imp_uni_nafaalilargusscales",     -- Scales of Nafaalilargus
    "t_imp_uni_shadowweave",             -- Shadowweave
    "t_de_uni_wraithmail_01",            -- Wraithmail

    -- Gauntlets
    "t_dae_uni_gauntletofpoor_l",        -- Gauntlets of the Poor (left)
    "t_dae_uni_gauntletofpoor_r",        -- Gauntlets of the Poor (right)
    "t_dae_uni_lgauntsaviorshide",       -- Gauntlets of the Savior's Hide (left)
    "t_dae_uni_rgauntsaviorshide",       -- Gauntlets of the Savior's Hide (right)
    "t_de_uni_pasoroth_gaunt_l",         -- War Gauntlets of Pasoroth (left)
    "t_de_uni_pasoroth_gaunt_r",         -- War Gauntlets of Pasoroth (right)

    -- Greaves
    "t_dae_uni_greavessaviorshide",      -- Greaves of the Savior's Hide
    "t_de_uni_pasoroth_greaves",         -- War Greaves of Pasoroth

    -- Helms
    "t_imp_uni_benduolohelm",            -- Helm of Bendu Olo
    "t_imp_uni_masquedcaptain",          -- Masque of the Captain
    "t_dae_uni_helmlightwithin_01",      -- Helm of Light Within
    "t_dae_uni_helmsaviorshide",         -- Helm of the Savior's Hide
    "t_de_uni_kingofrats_01",            -- King of Rats
    "t_de_almarula_helm_uni",            -- Mask of the Alma Rula
    "t_nor_uni_dcultmask_01",            -- Mask of the Precentor
    "t_de_uni_preyseekerhlem",           -- Preyseeker
    "t_de_uni_preyseekerhelm",           -- Preyseeker (alt)
    "t_de_uni_pasoroth_helm",            -- War Helm of Pasoroth
    "t_imp_uni_dragoneye",               -- Dragoneye Helm
    "tr_m4_ando_mg_polyhedrascope",      -- Polyhedrascope
    "tr_m4_ushudimmucrown_01",           -- Crown of Ushu-Dimmu (variant 1)
    "tr_m4_ushudimmucrown_02",           -- Crown of Ushu-Dimmu (variant 2)
    "t_imp_uni_katariahsdeathmask",      -- Death Mask of Katariah
    "t_imp_uni_katariahsdeathmask_x",    -- Death Mask of Katariah (alt)

    -- Pauldrons
    "t_dae_uni_lpauldsaviorshide",       -- Pauldrons of the Savior's Hide (left)
    "t_dae_uni_rpauldsaviorshide",       -- Pauldrons of the Savior's Hide (right)
    "t_dae_uni_lmethatspauldron",        -- Lord Methats' Pauldrons (left)
    "t_dae_uni_rmethatspauldron",        -- Lord Methats' Pauldrons (right)
    "t_de_uni_veloth_pauld_l",           -- Saint Veloth's Pauldrons (left)
    "t_de_uni_veloth_pauld_r",           -- Saint Veloth's Pauldrons (right)
    "t_de_uni_pasoroth_pauld_l",         -- War Pauldrons of Pasoroth (left)
    "t_de_uni_pasoroth_pauld_r",         -- War Pauldrons of Pasoroth (right)

    -- Shields
    "t_de_uni_vivecshield",              -- Bug Shield of Vivec
    "t_dae_uni_fearstruck",              -- Fearstruck
    "t_com_uni_requiem",                 -- Requiem
    "t_de_uni_shield_abernanit",         -- Shield of Abernanit
    "t_imp_uni_urielshield_01",          -- Shield of the Emperor
    "t_bre_uni_lordlyheartershield",     -- Shield of the Lord Commander
    "t_bre_uni_lordlyheartershield",     -- (alt)
    "t_bre_uni_trickstershield",         -- Shield of the Trickster
    "t_nor_uni_targeblooded",            -- Targe of the Blooded
    "t_imp_uni_wardofakavir",            -- Ward of Akavir

    -- ========================================================
    -- TAMRIEL REBUILT / TAMRIEL DATA — Clothing Artifacts
    -- ========================================================
    -- Rings
    "t_com_uni_conjurersring",           -- Conjurer's Ring
    "t_imp_uni_crusaderring",            -- Crusader's Ring
    "t_dae_uni_occultistRing",           -- Ghost Ring
    "t_dae_uni_occultisting",            -- (alt)
    "t_nor_uni_greeneryring",            -- Greenery Ring
    "t_imp_uni_guardianring",            -- Guardian Ring
    "t_com_uni_malkavring",              -- Malkav's Ring
    "t_de_uni_penitentring",             -- Penitent's Ring
    "t_nor_uni_ringbloodlust",           -- Ring of Bloodlust
    "t_dae_uni_eidolonedge",             -- Ring of Eidolon's Edge
    "t_de_uni_championring",             -- Ring of Champions
    "t_de_uni_ringelfborn",              -- Ring of Elfborn
    "t_com_uni_ringfangs",               -- Ring of Fangs
    "t_de_uni_ringflesh",                -- Ring of Flesh
    "t_nor_uni_ringhunt",                -- Ring of the Hunt
    "t_nor_uni_ringinstinct",            -- Ring of Instinct
    "t_com_uni_ringlightingspeed",       -- Ring of Lighting Speed
    "t_nor_uni_ringmoon",                -- Ring of the Moon
    "t_dae_uni_ring_namira_01",          -- Ring of Namira
    "t_de_uni_ringhlaalu",               -- Ring of the Second Family
    "t_imp_uni_ring_respite",            -- Ring of Respite (TD version)
    "tr_m1_fw_ic_ringrespite",           -- Ring of Respite (TR version)
    "t_de_uni_ringseryn",                -- Ring of St. Seryn
    "t_com_uni_ringstars",               -- Ring of Stars
    "t_imp_uni_ringofsunfire",           -- Ring of Sunfire
    "t_ned_uni_ringsunherald",           -- Ring of Sunherald
    "t_nor_uni_ringthunderblows",        -- Ring of Thunderblows
    "t_com_uni_ringofwarding",           -- Ring of Warding
    "t_nor_uni_wolfring",                -- Ring of the Wolf Queen
    "t_de_uni_seafarerring",             -- Seafarer's Ring
    "t_de_uni_apostatering",             -- Shaman's Ring
    "t_com_uni_silver_picks",            -- Silver Picks Ring
    "t_com_uni_spelljewel",              -- Spell Jewel
    "t_imp_uni_vampyrumring_01",         -- Vampyrum Order Ring
    "t_imp_uni_weatherwardcirclet",      -- Weatherward Circlet

    -- Amulets / Belts / Sashes
    "t_vam_uni_amuletbats",              -- Amulet of Bats
    "t_nor_uni_dragontorc",              -- Dragontorc
    "t_nor_uni_hjergelmir",              -- Hjergelmir's Claw
    "t_nor_uni_hornofthewild",           -- Horn of the Wild
    "t_nor_uni_starfrost",               -- Starfrost
    "t_yne_uni_teethofnaskrdhan",        -- Teeth of Naskr'Dhan
    "t_de_uni_totemkushimmu",            -- Totem of the Kushimmu
    "t_de_uni_6th_belt_hearttide",       -- Belt of Hearttide
    "t_de_uni_beltstolms",               -- Belt of St. Olms
    "t_de_uni_fetishishanuran",          -- Fetish of the Ishanuran
    "t_de_uni_sashobainat",              -- Sash of the Obainat

    -- Robes
    "t_dae_uni_robeshroud",              -- Namira's Shroud
    "t_com_uni_regentrobe",              -- Robe of Ebon Regency
    "t_de_uni_robemeris",                -- Robe of St. Meris

    -- ========================================================
    -- TAMRIEL REBUILT / TAMRIEL DATA — Misc Artifacts
    -- ========================================================
    "t_dae_uni_skull_corruption",        -- Skull of Corruption
    "t_dae_uni_flashlillandril",         -- Flask of Lillandril
    "t_dae_uni_flasklillandril",         -- Flask of Lillandril (alt)
    "t_com_uni_kingorgnumcoffer_01",     -- King Orgnum's Coffer
    "t_bkuni_oghmainfinium",             -- Oghma Infinium
    "t_de_uni_pilgrimstone",             -- The Pilgrim Stone
    "t_he_uni_startooth",                -- Star Tooth
    "t_imp_uni_armisticetreaty",         -- Armistice Treaty
    "t_imp_uni_stoneseptimia_01",        -- Stone of Septimia (alt ID)

    -- ========================================================
    -- SKYRIM: HOME OF THE NORDS — Artifacts
    -- ========================================================
    "sky_uni_orichalcumblade",           -- Orichalcum Blade
    "t_nor_uni_tokenicewind",            -- Token of Icewind
    "t_nor_uni_kvisahjaelmur",           -- Kvisahjaelmur
}

for _, id in ipairs(ids) do
    artifacts[id] = true
end

return artifacts
