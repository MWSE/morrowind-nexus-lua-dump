local util = require("openmw.util")

local BARD_NPCS = {
    r_bc_n_camilla = { -- Camilla of Cheydinhal
        home = {
            cell = "Pelagiad, Halfway Tavern",
            position = util.vector3(851, 501, 0),
            rotation = util.transform.rotateZ(-math.pi / 2),
        },
        startingLevel = 50,
        sheathedInstrument = "misc_de_lute_01",
    },
    r_bc_n_elara = { -- Elara Endre
        home = {
            cell = 'Ald-ruhn, Guild of Mages',
            position = util.vector3(1992, 620, -640),
            rotation = util.transform.rotateZ(math.pi),
        },
        startingLevel = 30,
    },
    r_bc_n_lucian = { -- Lucian Caro
        home = {
            cell = "Ebonheart, Six Fishes",
            position = util.vector3(230, 593, 0),
            rotation = util.transform.rotateZ(math.pi),
        },
        startingLevel = 60,
        sheathedInstrument = "r_bc_fiddle",
    },
    r_bc_n_rajira = { -- Ra'jira "Quick-Paws"
        home = {
            cell = "Vivec, Black Shalk Cornerclub",
            position = util.vector3(31, 311, -64),
            rotation = util.transform.rotateZ(math.pi),
        },
        compat = {
            {
                files = {
                    "beautiful cities of morrowind",
                },
                position = util.vector3(253, -365, -64),
                rotation = util.transform.rotateZ(math.pi / 2),
            }
        },
        startingLevel = 20,
        sheathedInstrument = "misc_de_drum_02",
        knownSongs = {
            {
                song = "cadence1.mid",
                confidences = {
                    [5] = {
                        [1] = 0.7,
                        [2] = 1.0,
                        [3] = 0.8,
                    }
                }
            }
        }
    },
    r_bc_n_reeds = { -- Sees-Silent-Reeds
        home = {
            cell = "Seyda Neen, Arrille's Tradehouse",
            position = util.vector3(-586, -381, 385),
            rotation = util.transform.rotateZ(math.pi / 2),
        },
        startingLevel = 15,
    },
    r_bc_n_rels = { -- Rels Llervu
        home = {
            cell = "Maar Gan, Andus Tradehouse",
            position = util.vector3(-284, 545, 0),
            rotation = util.transform.rotateZ(5 * math.pi / 6),
        },
        startingLevel = 40,
        sheathedInstrument = "misc_de_drum_01",
    },
    r_bc_n_sargon = { -- Sargon Assinabi
        home = {
            cell = "Vos, Varo Tradehouse",
            position = util.vector3(-104, 221, 130),
            rotation = util.transform.rotateZ(math.pi),
        },
        startingLevel = 25,
        sheathedInstrument = "r_bc_bassflute",
    },
    r_bc_n_strumak = { -- Strumak gro-Bol
        home = {
            cell = "Gnisis, Madach Tradehouse",
            position = util.vector3(-396, 524, -129),
            rotation = util.transform.rotateZ(math.pi / 2),
        },
        compat = {
            {
                files = {
                    "hotv - gnisis",
                    "concept art gnisis",
                    "beautiful cities of morrowind",
                },
                position = util.vector3(-712, -788, -1791),
                rotation = util.transform.rotateZ(math.pi / 2),
            }
        },
        startingLevel = 30,
        sheathedInstrument = "misc_de_lute_01",
    }
}

return BARD_NPCS