local world = require("openmw.world")

local pool = {
            "misc_de_lute_01",
            "misc_de_lute_01_phat",
            "t_imp_lute_01",
            "t_com_lute_01",
            "t_de_uni_renaldlute", 
            "t_imp_uni_goldenlute",
            "t_de_music_adun",
            "t_de_music_shiratar",
            "ab_mus_delutethin",
            "misc_de_drum_01",
            "misc_de_drum_02",
            "t_imp_drum_01",
            "t_imp_drum_02",
            "t_imp_drum_03",
            "t_imp_drum_04",
            "r_bc_fiddle",
            "r_bc_ocarina",
            "r_bc_bassflute",
            --"t_de_music_panflute_01", these are unplayable even though they are listed as "instrument_items" in the common.lua of the bardcraft's scripts/data directory
            --"ab_misc_6thflute",
            --"ab_misc_ashlflute",
            -- "ab_mus_6thflute",
            -- "ab_mus_ashlflute",
            --"t_de_music_sudahk",
            --"ab_mus_deharp",
            --"t_de_music_lyre_01",
            --"t_de_music_takuratum",
            -- "ab_mus_delyre",
            -- "ab_mus_ashllyre",
        }
local instrument = pool[math.random(#pool)]
local function selectedBardBackground(player)
    tostring(instrument)
    local item1 = world.createObject(instrument, 1)
    item1:moveInto(player)
    local item2 = world.createObject("r_bc_songbook_beg", 1)
    item2:moveInto(player)
end

return {
        eventHandlers = {
            CharacterTraits_selectedBardBackground = selectedBardBackground,
        }
}