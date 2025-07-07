local I = require('openmw.interfaces')

local CREATURES_WHITELIST = {
    -- vanilla undead
    'ancestor_ghost',
    'ancestor_ghost_greater',
    'bonelord',
    'bonewalker',
    'bonewalker_weak',
    'bonewalker_greater',
    'skeleton_weak',
    'skeleton',
    'skeleton entrance',
    'skeleton archer',
    'skeleton champion',
    'skeleton entrance', -- exteriors

    -- TD undead
    't_mw_und_boneldgr_.*',
    't_mw_und_procebonwal_.*',
    't_mw_und_reverbonwal_.*',
    't_mw_und_ancestorwep_.*',
    't_mw_und_mum_.*',
    't_glb_und_skelarise_.*',
    't_mw_und_skelarc_.*',
    't_glb_und_skelwlor_.*',
    't_glb_und_skelcmpgr_.*',
    't_glb_und_skelcmpgls_.*',
    't_mw_und_skelwwiz_.*',

    -- AndranoTombRemastered
    'wretch3_skeleton_weak.*',

    -- OAAB
    'ab_und_glassberserker',

    -- RP Creatures + Antares' Undead Redux
    'skeleton_undead',
    'skeleton_weak_undead',
    'un_ghost_undead',
    'rp_wraith',
    -- TODO: fix skeletons aggroing after arising
    'un_skeleton_arise',
    'un_skeleton_arise2',
}
for i, v in ipairs(CREATURES_WHITELIST)
do
    I.more_peaceful_tombs.add_creature(v)
end

-- only interior cells are supported ATM

local CELL_WHITELIST = {
    -- generic and vanilla
    '.* ancestral tomb.*',
    '.* ancestral vaults.*',
    'ashmelech',
    -- TR
    'mugan crypt',
    'necrom, catacombs.*',
    'narsis, catacombs.*',
    'shaden',
    'sirrilash',
    'dulandos, shrine',
    'dulandos, catacombs',
}
for i, v in ipairs(CELL_WHITELIST)
do
    I.more_peaceful_tombs.add_cell_wl(v)
end

local CELL_BLACKLIST = {
    -- vanilla

    -- TR
    'balvel ancestral tomb', -- https://en.uesp.net/wiki/Tamriel_Rebuilt:Save_a_Prayer
    'darano ancestral tomb.*', -- https://en.uesp.net/wiki/Tamriel_Rebuilt:A_Ruined_Legacy
    'drothril ancestral tomb', -- https://en.uesp.net/wiki/Tamriel_Rebuilt:Warm_to_the_Touch
    'olthan ancestral tomb', -- https://en.uesp.net/wiki/Tamriel_Rebuilt:Tribunal_Thrill-Seeking
}
for i, v in ipairs(CELL_BLACKLIST)
do
    I.more_peaceful_tombs.add_cell_bl(v)
end
