MAXINT = 2 ^ 53

UnrestrictiveFactions = {
    -- vanilla
    ["temple"]             = true,
    ["imperial cult"]      = true,
    ["talos cult"]         = true,
    -- TD
    ["t_mw_temple"]        = true,
    ["t_mw_imperialCult"]  = true,
    ["t_cyr_imperialCult"] = true,
    ["t_sky_imperialCult"] = true,
}

Spellbooks = {
    -- have to be in lowercase!!!

    -- vanilla
    bk_secretsdwemeranimunculi      = true,
    -- tamriel data
    t_bk_aboveitalltr               = true,
    t_bk_adventuresendtr            = true,
    t_sc_battlecrytr                = true,
    t_note_bloodbeattr              = true,
    t_sc_bonesongtr                 = true,
    t_bk_bonewalkerritualstr        = true,
    t_bk_bonewalkerritualsotr       = true,
    t_note_bralegelsnotetr          = true,
    t_bk_breakouttr                 = true,
    t_sc_callofthebeaststr          = true,
    t_bk_cavesoficetr               = true,
    t_note_chaoticallyscrawledtr    = true,
    t_bk_cowardiceoftheenemytr      = true,
    t_bk_dalgorjournaltr            = true,
    t_bk_fablevalenwoodtr           = true,
    t_bk_thefaithfultr              = true,
    t_bk_follyofsteeltr             = true,
    t_sc_foundationsofprotectiontr  = true,
    t_bk_handinhandtr               = true,
    t_bk_handsofftr                 = true,
    t_bk_breakinsetofarmortr        = true,
    t_bk_interrogatingdunmertr      = true,
    t_bk_justpunishmenttr           = true,
    t_bk_laidlowtr                  = true,
    t_bk_likeinthedealtr            = true,
    t_bk_lockedcellartr             = true,
    t_bk_masonsongtr                = true,
    t_bk_mostcrueltradetr           = true,
    t_bk_mothersdiarytr             = true,
    t_bk_mysteriesofthewormtr       = true,
    t_sc_newfoundhealthgalodustr    = true,
    t_bk_olgolgromuksprivatenotestr = true,
    t_bk_elementaldaedratr          = true,
    t_bk_onthemovetr                = true,
    t_bk_theperyitonvol1closetr     = true,
    t_bk_theperyitonvol1opentr      = true,
    t_bk_theperyitonvol2closetr     = true,
    t_bk_theperyitonvol2opentr      = true,
    t_bk_theperyitonvol3closetr     = true,
    t_bk_theperyitonvol3opentr      = true,
    t_bk_theperyitonvol4closetr     = true,
    t_bk_theperyitonvol4opentr      = true,
    t_bk_theperyitonvol5closetr     = true,
    t_bk_theperyitonvol5opentr      = true,
    t_sc_prayertoazuratr            = true,
    t_sc_prideunboundtr             = true,
    t_sc_ralenrothadasmemoirtr      = true,
    t_sc_reunrefinedtr              = true,
    t_sc_reverencetr                = true,
    t_bk_ruhnaniaalmsivitr          = true,
    t_bk_seconddoortr               = true,
    t_bk_seekinghometr              = true,
    t_bk_sevenpennantstr            = true,
    t_bk_smallkindnesstr            = true,
    t_bk_spectrumstudytr            = true,
    t_sc_steadfasttr                = true,
    t_sc_stillimagetr               = true,
    t_bk_tasteofsugartr             = true,
    t_sc_threesonetstr              = true,
    t_sc_entangledreamtr            = true,
    t_bk_thetormentklauseintr_v1    = true,
    t_bk_thetormentklauseintr_v2    = true,
    t_bk_truejusticetr              = true,
    -- t_bk_weightofguilttr            = true, -- excluded due to being a tg quest item
}

-- +----------------------------------+
-- | Consts for buyable book messages |
-- +----------------------------------+

CitiesWithOrdinators = {
    "vivec",
    "mournhold",
    "necrom",
}
MANY_VENDORS_THRESHOLD = 3
LOW_DISPOSITION = 30

-- +------------------------------------+
-- | Consts for NPC owned book messages |
-- +------------------------------------+

MagicClasses = {
    -- criteria for adding is:
    -- Specialization: Magic
    -- And at least 3/5 major skills need to be magic (may have exceptions)

    -- vanilla playable
    battlemage      = true,
    healer          = true,
    mage            = true,
    nightblade      = true,
    sorcerer        = true,
    spellsword      = true,
    witchhunter     = true,
    -- vanilla NPC
    alchemist       = true,
    enchanter       = true,
    ["guild guide"] = true,
    mabrigash       = true,
    necromancer     = true,
    priest          = true,
    warlock         = true,
    ["wise woman"]  = true,
    witch           = true,
    -- bloodmoon NPC
    shaman          = true,
    -- TD
    astrologer      = true,
    naturalist      = true,
    ["clever-man"]  = true,
}
LOW_INT = 30
HIGH_ENCH = 75

-- +----------------------------------------+
-- | Consts for faction owned book messages |
-- +----------------------------------------+

FactionArchetypes = {
    -- it's all over the place, I know...
    mage = {
        -- vanilla
        ["mages guild"]      = true,
        telvanni             = true,
        -- TD
        ["t_cyr_magesguild"] = true,
        ["t_ham_magesguild"] = true,
        ["t_sky_magesguild"] = true,
    },
    warrior = {
        -- vanilla
        ["fighters guild"]       = true,
        ["imperial legion"]      = true,
        redoran                  = true,
        blades                   = true,
        -- TD
        ["t_cyr_imperiallegion"] = true,
        ["t_cyr_blades"]         = true,
        ["t_sky_fightersguild"]  = true,
    },
    rogue = {
        -- vanilla
        ["thieves guild"]      = true,
        ["morag tong"]         = true,
        hlaalu                 = true,
        -- TD
        ["t_cyr_thievesguild"] = true,
        ["t_sky_thievesguild"] = true,
    }
}
