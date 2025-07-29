---@type CellMatchPatterns
local AnvilPatterns = {
    allowed = {
        "anvil",
        "marav",
        "hal sadek",
        "archad",
        "brina cross",
        "goldstone",
        "charach"
    },

    disallowed = {
        'sewer',
        'underworks',
        'crypt',
    },
}

---@type IDPresenceMap
local AyleidStatics = {
    ['t_ayl_dngruin_i_3wayse_02'] = true,
    ['t_ayl_dngruin_i_block_01'] = true,
    ['t_ayl_dngruin_i_block_02'] = true,
    ['t_ayl_dngruin_i_block_03'] = true,
    ['t_ayl_dngruin_i_block_04'] = true,
    ['t_ayl_dngruin_i_block_05'] = true,
    ['t_ayl_dngruin_i_block_06'] = true,
    ['t_ayl_dngruin_i_ceilingspike_01'] = true,
    ['t_ayl_dngruin_i_divider_01'] = true,
    ['t_ayl_dngruin_i_divider_02'] = true,
    ['t_ayl_dngruin_i_doorframe_01'] = true,
    ['t_ayl_dngruin_i_doorframe_02'] = true,
    ['t_ayl_dngruin_i_doorframe_03'] = true,
    ['t_ayl_dngruin_i_entrance_01'] = true,
    ['t_ayl_dngruin_i_entrance_02'] = true,
    ['t_ayl_dngruin_i_entrancesprl_01'] = true,
    ['t_ayl_dngruin_i_entrsprltwr_01'] = true,
    ['t_ayl_dngruin_i_floor_01'] = true,
    ['t_ayl_dngruin_i_floor_02'] = true,
    ['t_ayl_dngruin_i_flrrais3way_01'] = true,
    ['t_ayl_dngruin_i_flrrais4way_01'] = true,
    ['t_ayl_dngruin_i_flrraiscen_01'] = true,
    ['t_ayl_dngruin_i_flrraiscen_02'] = true,
    ['t_ayl_dngruin_i_flrraiscorn_01'] = true,
    ['t_ayl_dngruin_i_flrraisend_01'] = true,
    ['t_ayl_dngruin_i_flrraismid_01'] = true,
    ['t_ayl_dngruin_i_hall_01'] = true,
    ['t_ayl_dngruin_i_hall_02'] = true,
    ['t_ayl_dngruin_i_hall3way_01'] = true,
    ['t_ayl_dngruin_i_hall3way_02'] = true,
    ['t_ayl_dngruin_i_hall4way_01'] = true,
    ['t_ayl_dngruin_i_hall4way_02'] = true,
    ['t_ayl_dngruin_i_hallcaveic_01'] = true,
    ['t_ayl_dngruin_i_hallcavesh_01'] = true,
    ['t_ayl_dngruin_i_hallend_01'] = true,
    ['t_ayl_dngruin_i_hallend_02'] = true,
    ['t_ayl_dngruin_i_hallfitting_01'] = true,
    ['t_ayl_dngruin_i_hallramp_01'] = true,
    ['t_ayl_dngruin_i_hallramp_02'] = true,
    ['t_ayl_dngruin_i_hallstair_01'] = true,
    ['t_ayl_dngruin_i_hallstair_02'] = true,
    ['t_ayl_dngruin_i_hallturn_01'] = true,
    ['t_ayl_dngruin_i_hallturn_02'] = true,
    ['t_ayl_dngruin_i_hallturn_03'] = true,
    ['t_ayl_dngruin_i_lightfix_01'] = true,
    ['t_ayl_dngruin_i_lightfix_02'] = true,
    ['t_ayl_dngruin_i_lightfix_03'] = true,
    ['t_ayl_dngruin_i_pedestal_01'] = true,
    ['t_ayl_dngruin_i_pedestal_02'] = true,
    ['t_ayl_dngruin_i_pedestal_03'] = true,
    ['t_ayl_dngruin_i_pitbridge_01'] = true,
    ['t_ayl_dngruin_i_pitbridge3w_01'] = true,
    ['t_ayl_dngruin_i_pitbridge4w_01'] = true,
    ['t_ayl_dngruin_i_pitbridgearc_01'] = true,
    ['t_ayl_dngruin_i_pitbridgearc_02'] = true,
    ['t_ayl_dngruin_i_pitbridgebr_01'] = true,
    ['t_ayl_dngruin_i_pitbridgecap_01'] = true,
    ['t_ayl_dngruin_i_pitbridge_crn_0'] = true,
    ['t_ayl_dngruin_i_pitbridgeend_01'] = true,
    ['t_ayl_dngruin_i_pitbridgeplbr_0'] = true,
    ['t_ayl_dngruin_i_pitbridges_01'] = true,
    ['t_ayl_dngruin_i_pitbridges_02'] = true,
    ['t_ayl_dngruin_i_pitceiling_01'] = true,
    ['t_ayl_dngruin_i_pitceiling_02'] = true,
    ['t_ayl_dngruin_i_pitcolumn_01'] = true,
    ['t_ayl_dngruin_i_pitcolumncrn_01'] = true,
    ['t_ayl_dngruin_i_pitcolumnw_01'] = true,
    ['t_ayl_dngruin_i_pitcornert_01'] = true,
    ['t_ayl_dngruin_i_pitdivider_01'] = true,
    ['t_ayl_dngruin_i_pitdivider_02'] = true,
    ['t_ayl_dngruin_i_pitdivider_03'] = true,
    ['t_ayl_dngruin_i_pitfloor_01'] = true,
    ['t_ayl_dngruin_i_pitfloor_02'] = true,
    ['t_ayl_dngruin_i_pitflooredcr_01'] = true,
    ['t_ayl_dngruin_i_pitflooredst_01'] = true,
    ['t_ayl_dngruin_i_pitstairs_01'] = true,
    ['t_ayl_dngruin_i_pitwall_01'] = true,
    ['t_ayl_dngruin_i_pitwallbr_01'] = true,
    ['t_ayl_dngruin_i_pitwallc_01_'] = true,
    ['t_ayl_dngruin_i_pitwalle_01'] = true,
    ['t_ayl_dngruin_i_pitwallt_01'] = true,
    ['t_ayl_dngruin_i_pitwallt_02'] = true,
    ['t_ayl_dngruin_i_pitwalltentr_01'] = true,
    ['t_ayl_dngruin_i_pitwallttrsl_01'] = true,
    ['t_ayl_dngruin_i_pitwallttrsr_01'] = true,
    ['t_ayl_dngruin_i_ridge_01'] = true,
    ['t_ayl_dngruin_i_ridgeext_01'] = true,
    ['t_ayl_dngruin_i_ridgeext_02'] = true,
    ['t_ayl_dngruin_i_ridgeext_03'] = true,
    ['t_ayl_dngruin_i_ridgegrend_01'] = true,
    ['t_ayl_dngruin_i_ridgegrext_01'] = true,
    ['t_ayl_dngruin_i_ridgelend_01'] = true,
    ['t_ayl_dngruin_i_ridgelext_01'] = true,
    ['t_ayl_dngruin_i_roomceiling_01'] = true,
    ['t_ayl_dngruin_i_roomceiling_02'] = true,
    ['t_ayl_dngruin_i_roomceiling_03'] = true,
    ['t_ayl_dngruin_i_roomceiling_04'] = true,
    ['t_ayl_dngruin_i_roomcol_01'] = true,
    ['t_ayl_dngruin_i_roomcol_02'] = true,
    ['t_ayl_dngruin_i_roomcol_03'] = true,
    ['t_ayl_dngruin_i_roomcol_04'] = true,
    ['t_ayl_dngruin_i_roomcolbase_01'] = true,
    ['t_ayl_dngruin_i_roomcolbrk_01'] = true,
    ['t_ayl_dngruin_i_roomcolbrk_02'] = true,
    ['t_ayl_dngruin_i_roomcolbrk_03'] = true,
    ['t_ayl_dngruin_i_roomcolfloor_01'] = true,
    ['t_ayl_dngruin_i_roomcolsml_01'] = true,
    ['t_ayl_dngruin_i_roomcolsml_02'] = true,
    ['t_ayl_dngruin_i_roomcolsmlbrk_0'] = true,
    ['t_ayl_dngruin_i_roomcrn_01'] = true,
    ['t_ayl_dngruin_i_roomcrn2_01'] = true,
    ['t_ayl_dngruin_i_roomcrn3_01'] = true,
    ['t_ayl_dngruin_i_roomcrnc_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextb_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextl_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextlc_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextr_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextrc_01'] = true,
    ['t_ayl_dngruin_i_roomcrno_01'] = true,
    ['t_ayl_dngruin_i_roomcrno_02'] = true,
    ['t_ayl_dngruin_i_roomcrnsecrb_01'] = true,
    ['t_ayl_dngruin_i_roomcrnsecrl_01'] = true,
    ['t_ayl_dngruin_i_roomcrnsecrr_01'] = true,
    ['t_ayl_dngruin_i_roomflr_01'] = true,
    ['t_ayl_dngruin_i_roomflredcrn_01'] = true,
    ['t_ayl_dngruin_i_roomflredstr_01'] = true,
    ['t_ayl_dngruin_i_roomwall_01'] = true,
    ['t_ayl_dngruin_i_roomwallext_01'] = true,
    ['t_ayl_dngruin_i_roomwallextw_01'] = true,
    ['t_ayl_dngruin_i_roomwallextw_02'] = true,
    ['t_ayl_dngruin_i_roomwallextw_03'] = true,
    ['t_ayl_dngruin_i_roomwallextw_04'] = true,
    ['t_ayl_dngruin_i_roomwallsecr_01'] = true,
    ['t_ayl_dngruin_i_roomwallshl_01'] = true,
    ['t_ayl_dngruin_i_rubble_01'] = true,
    ['t_ayl_dngruin_i_rubblepile_01'] = true,
    ['t_ayl_dngruin_i_rubblepile_02'] = true,
    ['t_ayl_dngruin_i_secrettohall_01'] = true,
    ['t_ayl_dngruin_i_secrtunnl_01'] = true,
    ['t_ayl_dngruin_i_secrtunnl3w_01'] = true,
    ['t_ayl_dngruin_i_secrtunnl4w_01'] = true,
    ['t_ayl_dngruin_i_secrtunnlcrn_01'] = true,
    ['t_ayl_dngruin_i_secrtunnlend_01'] = true,
    ['t_ayl_dngruin_i_secrtunnlrmp_01'] = true,
    ['t_ayl_dngruin_i_secrwall_01'] = true,
    ['t_ayl_dngruin_i_smlroom_cent_01'] = true,
    ['t_ayl_dngruin_i_smlroom_corn_01'] = true,
    ['t_ayl_dngruin_i_smlroom_corn_02'] = true,
    ['t_ayl_dngruin_i_smlroom_corn_03'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_01'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_02'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_03'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_04'] = true,
    ['t_ayl_dngruin_i_smlroom_wall_01'] = true,
    ['t_ayl_dngruin_i_squarecolumn_01'] = true,
    ['t_ayl_dngruin_i_squarecolumn_02'] = true,
    ['t_ayl_dngruin_i_squarecolumn_03'] = true,
    ['t_ayl_dngruin_i_tower_capl_01'] = true,
    ['t_ayl_dngruin_i_tower_capr_01'] = true,
    ['t_ayl_dngruin_i_tower_ceil_01'] = true,
    ['t_ayl_dngruin_i_tower_ceilmd_01'] = true,
    ['t_ayl_dngruin_i_tower_ent_01'] = true,
    ['t_ayl_dngruin_i_tower_floor_01'] = true,
    ['t_ayl_dngruin_i_tower_flrmid_01'] = true,
    ['t_ayl_dngruin_i_tower_stairsl_0'] = true,
    ['t_ayl_dngruin_i_tower_stairsr_0'] = true,
    ['t_ayl_dngruin_i_tower_wall_01'] = true,
    ['t_ayl_dngruin_i_tower_wall_02'] = true,
    ['t_ayl_dngruin_i_tower_wall_03'] = true,
    ['t_ayl_dngruin_i_welkyndchndl_01'] = true,
    ['t_ayl_dngruin_i_welkyndclst_01'] = true,
    ['t_ayl_dngruin_i_welkyndclstg_01'] = true,
    ['t_ayl_dngruin_i_welkyndclstw_01'] = true,
    ['t_ayl_dngruin_i_welkyndholdr_01'] = true,
    ['t_ayl_dngruin_i_welkyndlump_01'] = true,
    ['t_ayl_dngruin_i_welkyndplnt_01'] = true,
    ['t_ayl_dngruin_i_welkyndplntw_01'] = true,
    ['t_ayl_dngruin_i_welkyndstn_01'] = true,
    ['t_ayl_dngruin_i_welkyndstn_02'] = true,
    ['t_ayl_dngruin_i_welkyndstn_03'] = true,
    ['t_ayl_dngruin_i_welkyndstnw_01'] = true,
    ['t_ayl_dngruin_i_welkyndstnw_02'] = true,
    ['t_ayl_dngruin_i_welkyndstnw_03'] = true,
    ['t_ayl_dngruin_i_wideh_01'] = true,
    ['t_ayl_dngruin_i_wideh3way_01'] = true,
    ['t_ayl_dngruin_i_wideh3wayse_01'] = true,
    ['t_ayl_dngruin_i_wideh3wayse_02'] = true,
    ['t_ayl_dngruin_i_wideh4crn_01'] = true,
    ['t_ayl_dngruin_i_wideh4way_01'] = true,
    ['t_ayl_dngruin_i_widehbr_01'] = true,
    ['t_ayl_dngruin_i_widehcat_01'] = true,
    ['t_ayl_dngruin_i_widehcrnse_01'] = true,
    ['t_ayl_dngruin_i_widehend_01'] = true,
    ['t_ayl_dngruin_i_widehgatef_01'] = true,
    ['t_ayl_dngruin_i_widehsecret_01'] = true,
    ['t_ayl_dngruin_i_widehstair_01'] = true,
    ['t_ayl_dngruin_i_widehstairbr_01'] = true,
    ['t_ayl_dngruin_i_widehtrans_01'] = true,
    ['t_ayl_dngruin_i_wideh_trans3_01'] = true,
    ['t_ayl_dngruin_i_wideh_trans4_01'] = true,
    ['t_ayl_dngruin_i_wideh_trans4_02'] = true,
    ['t_ayl_dngruin_i_windowleft_01'] = true,
    ['t_ayl_dngruin_i_windowmiddle_01'] = true,
    ['t_ayl_dngruin_i_windowright_01'] = true,
    ['t_ayl_dngruin_i_windowsectnl_01'] = true,
    ['t_ayl_dngruin_i_windowsectnl_02'] = true,
}

---@type IDPresenceMap
local BarrowsStatics = {
    ['t_imp_dngcolbarrow_i_block_01'] = true,
    ['t_imp_dngcolbarrow_i_block_02'] = true,
    ['t_imp_dngcolbarrow_i_ceil_01'] = true,
    ['t_imp_dngcolbarrow_i_ceil_02'] = true,
    ['t_imp_dngcolbarrow_i_ceil_03'] = true,
    ['t_imp_dngcolbarrow_i_ceil_04'] = true,
    ['t_imp_dngcolbarrow_i_ceil_05'] = true,
    ['t_imp_dngcolbarrow_i_ceil_06'] = true,
    ['t_imp_dngcolbarrow_i_column_01'] = true,
    ['t_imp_dngcolbarrow_i_column_02'] = true,
    ['t_imp_dngcolbarrow_i_column_03'] = true,
    ['t_imp_dngcolbarrow_i_column_04'] = true,
    ['t_imp_dngcolbarrow_i_column_05'] = true,
    ['t_imp_dngcolbarrow_i_column_06'] = true,
    ['t_imp_dngcolbarrow_i_corner_01'] = true,
    ['t_imp_dngcolbarrow_i_corner_02'] = true,
    ['t_imp_dngcolbarrow_i_corner_03'] = true,
    ['t_imp_dngcolbarrow_i_cover_01'] = true,
    ['t_imp_dngcolbarrow_i_dirt_01'] = true,
    ['t_imp_dngcolbarrow_i_dirt_02'] = true,
    ['t_imp_dngcolbarrow_i_dirt_03'] = true,
    ['t_imp_dngcolbarrow_i_dirt_04'] = true,
    ['t_imp_dngcolbarrow_i_exit_01'] = true,
    ['t_imp_dngcolbarrow_i_floor_01'] = true,
    ['t_imp_dngcolbarrow_i_floor_02'] = true,
    ['t_imp_dngcolbarrow_i_floor_03'] = true,
    ['t_imp_dngcolbarrow_i_floor_04'] = true,
    ['t_imp_dngcolbarrow_i_inscr_01'] = true,
    ['t_imp_dngcolbarrow_i_inscr_02'] = true,
    ['t_imp_dngcolbarrow_i_passge_01'] = true,
    ['t_imp_dngcolbarrow_i_passge_02'] = true,
    ['t_imp_dngcolbarrow_i_passge_03'] = true,
    ['t_imp_dngcolbarrow_i_passge_04'] = true,
    ['t_imp_dngcolbarrow_i_passtairs'] = true,
    ['t_imp_dngcolbarrow_i_pillar_01'] = true,
    ['t_imp_dngcolbarrow_i_pillar_02'] = true,
    ['t_imp_dngcolbarrow_i_rubble_01'] = true,
    ['t_imp_dngcolbarrow_i_stair_01'] = true,
    ['t_imp_dngcolbarrow_i_wall_01'] = true,
    ['t_imp_dngcolbarrow_i_wall_02'] = true,
    ['t_imp_dngcolbarrow_i_wall_03'] = true,
    ['t_imp_dngcolbarrow_i_wall_04'] = true,
    ['t_imp_dngcolbarrow_i_wall_05'] = true,
    ['t_imp_dngcolbarrow_i_wall_06'] = true,
    ['t_imp_dngcolbarrow_i_wall_07'] = true,
    ['t_imp_dngcolbarrow_i_wall_08'] = true,
    ['t_imp_dngcolbarrow_i_wall_09'] = true,
    ['t_imp_dngcolbarrow_i_wall_10'] = true,
    ['t_imp_dngcolbarrow_i_wall_11'] = true,
}

---@type IDPresenceMap
local CaveStaticIds = require 'doc.caveStaticIds'

---@type IDPresenceMap
local CryptStatics = {
    ['t_imp_dngcrypt_i_center_01'] = true,
    ['t_imp_dngcrypt_i_column_01'] = true,
    ['t_imp_dngcrypt_i_column_02'] = true,
    ['t_imp_dngcrypt_i_corner_01'] = true,
    ['t_imp_dngcrypt_i_doorjam_01'] = true,
    ['t_imp_dngcrypt_i_end_01'] = true,
    ['t_imp_dngcrypt_i_floor_01'] = true,
    ['t_imp_dngcrypt_i_hall_01'] = true,
    ['t_imp_dngcrypt_i_r_ceiling_01'] = true,
    ['t_imp_dngcrypt_i_r_center_01'] = true,
    ['t_imp_dngcrypt_i_r_corner_01'] = true,
    ['t_imp_dngcrypt_i_r_corner_02'] = true,
    ['t_imp_dngcrypt_i_r_side_01'] = true,
    ['t_imp_dngcrypt_i_side_01'] = true,
    ['t_imp_dngcrypt_i_stairs_01'] = true,
    ['t_imp_dngcrypt_i_wall_01'] = true,
    ['t_imp_dngcrypt_i_wall_02'] = true,
    ['t_imp_dngcrypt_i_wall_03'] = true,
    ['t_imp_dngcrypt_i_wall_04'] = true,
}

---@type IDPresenceMap
local StirkRegions = {
    ['stirk isle region'] = true,
    ['dasek marsh region'] = true,
}

---@type CellMatchPatterns
local SutchPatterns = {
    allowed = {
        "sutch",
        "thyra",
        "isvorhal",
        "seppaki",
        "salthearth"
    },

    disallowed = {
        'sewer',
        'underworks',
        'crypt',
    }
}

---@type CellMatchPatterns
local TemplePatterns = {
    allowed = {
        "anvil, chapel",
        "anvil, temple",
        "brina cross, chapel",
        "charach, chapel",
        "fort heath, chapel",
        "goldstone, chapel",
        "thresvy, chapel"
    },

    disallowed = {},
}

---@type IDPresenceMap
local CyrContentFiles = {
    ['cyr_main.esm'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        -- 'Project Cyrodiil - Abecean Shores/Imperial Crypts',
        id = 'ms/interior/cyrodiil tombs imperial',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(CyrContentFiles)
                and playback.rules.staticExact(CryptStatics)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Brennan Bluffs',
        id = 'ms/region/cyrodiil brennan bluffs',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'gilded hills region'
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Divine Temples',
        id = 'ms/cell/nine divine temples',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior and playback.rules.cellNameMatch(TemplePatterns)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Colovian Barrows',
        id = 'ms/interior/cyrodiil tombs colovian',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(CyrContentFiles)
                and playback.rules.staticExact(BarrowsStatics)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Caves',
        id = 'ms/interior/cyrodiil caves',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(CyrContentFiles)
                and playback.rules.staticExact(CaveStaticIds)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Ayleid',
        id = 'ms/interior/cyrodiil ayleid',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(CyrContentFiles)
                and playback.rules.staticExact(AyleidStatics)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Kingdom of Sutch',
        id = 'ms/cell/cyrodiil sutch',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(SutchPatterns)
        end
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Kingdom of Anvil',
        id = 'ms/cell/cyrodiil anvil',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(AnvilPatterns)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Strident Coast',
        id = 'ms/region/cyrodiil strident coast',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'gold coast region'
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Stirk Isle',
        id = 'ms/region/cyrodiil stirk isle',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return playback.rules.region(StirkRegions)
        end,
    }
}
