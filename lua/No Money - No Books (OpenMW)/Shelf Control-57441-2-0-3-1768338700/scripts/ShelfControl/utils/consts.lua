MAXINT = 2 ^ 53

UnrestrictiveFactions = {
    -- vanilla
    ["temple"] = true,
    ["imperial cult"] = true,
    ["talos cult"] = true,
    -- TD
    ["t_mw_temple"] = true,
    ["t_mw_imperialCult"] = true,
    ["t_cyr_imperialCult"] = true,
    ["t_sky_imperialCult"] = true,
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
    battlemage = true,
    healer = true,
    mage = true,
    nightblade = true,
    sorcerer = true,
    spellsword = true,
    witchhunter = true,
    -- vanilla NPC
    alchemist = true,
    enchanter = true,
    ["guild guide"] = true,
    mabrigash = true,
    necromancer = true,
    priest = true,
    warlock = true,
    ["wise woman"] = true,
    witch = true,
    -- bloodmoon NPC
    shaman = true,
    -- TD
    astrologer = true,
    naturalist = true,
    ["clever-man"] = true,
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
        ["mages guild"] = true,
        telvanni = true,
        -- TD
        ["t_cyr_magesguild"] = true,
        ["t_ham_magesguild"] = true,
        ["t_sky_magesguild"] = true,
    },
    warrior = {
        -- vanilla
        ["fighters guild"] = true,
        ["imperial legion"] = true,
        redoran = true,
        blades = true,
        -- TD
        ["t_cyr_imperiallegion"] = true,
        ["t_cyr_blades"] = true,
        ["t_sky_fightersguild"] = true,
    },
    rogue = {
        -- vanilla
        ["thieves guild"] = true,
        ["morag tong"] = true,
        hlaalu = true,
        -- TD
        ["t_cyr_thievesguild"] = true,
        ["t_sky_thievesguild"] = true,
    }
}