local util = require('openmw.util')

local VERSION = "1.1.1"

local INSTRUMENT_ITEMS = {
    Lute = {
        misc_de_lute_01 = true, -- Vanilla
        misc_de_lute_01_phat = true,
        t_imp_lute_01 = true,   -- Tamriel Data
        t_com_lute_01 = true,
        t_de_uni_renaldlute = true,
        t_imp_uni_goldenlute = true,
        t_de_music_adun = true,
        t_de_music_shiratar = true,
        ab_mus_delutethin = true, -- OOAB Data
    },
    Drum = {
        misc_de_drum_01 = true, -- Vanilla
        misc_de_drum_02 = true,
        t_imp_drum_01 = true,   -- Tamriel Data
        t_imp_drum_02 = true,
        t_imp_drum_03 = true,
        t_imp_drum_04 = true,
    },
    Fiddle = {
        r_bc_fiddle = true, -- Bardcraft
    },
    Ocarina = {
        r_bc_ocarina = true, -- Bardcraft
    },
    BassFlute = {
        r_bc_bassflute = true, -- Bardcraft
    },
    PanFlute = {
        t_de_music_panflute_01 = true,
        ab_misc_6thflute = true,
        ab_misc_ashlflute = true,
        ab_mus_6thflute = true,
        ab_mus_ashlflute = true,
    },
    Harp = {
        t_de_music_sudahk = true,
        ab_mus_deharp = true,
    },
    Lyre = {
        t_de_music_lyre_01 = true,
        t_de_music_takuratum = true,
        ab_mus_delyre = true,
        ab_mus_ashllyre = true,
    },
}

local SHEATHABLE_INSTRUMENTS = { -- Instruments that can be displayed on the back
    Lute = true,
    Drum = true,
    Fiddle = true,
    BassFlute = true,
}

local VENUES = {
    tavern = {
        -- Base Game
        ["ald-ruhn, ald skar inn"] = "boderi farano",
        ["ald-ruhn, council club"] = "darvam hlaren",
        ["ald-ruhn, the rat in the pot"] = "lirielle stoine",
        ["balmora, council club"] = "banor seran",
        ["balmora, eight plates"] = "dulnea ralaal",
        ["balmora, lucky lockup"] = "benunius agrudilius",
        ["balmora, south wall cornerclub"] = "bacola closcius",
        ["caldera, shenk's shovel"] = "shenk",
        ["dagon fel, the end of the world"] = "fryfnhild",
        ["ebonheart, six fishes"] = "agning",
        ["ghostgate, tower of dusk"] = "galore salvi",
        ["gnisis, madach tradehouse"] = "fenas madach",
        ["maar gan, andus tradehouse"] = "manse andus",
        ["molag mar, the pilgrim's rest"] = "selkirnemus",
        ["pelagiad, halfway tavern"] = "drelasa ramothran",
        ["sadrith mora, fara's hole in the wall"] = "fara",
        ["sadrith mora, gateway inn"] = "ery",
        ["sadrith mora, dirty muriel's cornerclub"] = "muriel sette",
        ["seyda neen, arrille's tradehouse"] = "elone",
        ["suran, desele's house of earthly delights"] = "helviane desele",
        ["suran, suran tradehouse"] = "ashumanu eraishah",
        ["tel aruhn, plot and plaster"] = "drarayne girith",
        ["tel branora, sethan's tradehouse"] = "llorayna sethan",
        ["tel mora, the covenant"] = "thaeril",
        ["vivec, black shalk cornerclub"] = "raril giral",
        ["vivec, elven nations cornerclub"] = "gadela andus",
        ["vivec, no name club"] = "brathus dals",
        ["vivec, the flowers of gold"] = "sorosi radobar",
        ["vivec, the lizard's head"] = "manara othan",
        ["vos, varo tradehouse"] = "burcanius varo",
        -- Tamriel Rebuilt (incomplete)
        ["the grey lodge"] = "tr_m4_kraki the grey",
        ["hunted hound inn"] = "tr_m3_ryamon sevenas",
        ["the inn between"] = "tr_m2_audania ranius",
        ["aimrah, the sailors' inn"] = "tr_m3_dilvene gilmanil",
        ["akamora, the laughing goblin"] = "tr_m2_liuba onamas",
        ["akamora, underground bazaar"] = "tr_m2_llania darvani",
        ["almas thirr, hostel of the crossing"] = "tr_m3_doryn naves",
        ["almas thirr, limping scrib"] = "tr_m3_hlireni hleran",
        ["almas thirr, the pious pirate"] = "tr_m3_rothis thalur",
        ["almas thirr, thirsty saint cornerclub"] = "tr_m3_yammu hainnadon",
        ["bal foyen, cat-catchers' cornerclub"] = "tr_m4_llaynu_maanil",
        ["andothren, council club"] = "tr_m4_darayne_llarem"
    },
    street = {
        metropolises = {
            -- Base Game
            "Vivec",
            -- Tamriel Rebuilt
            "Old Ebonheart",
            "Narsis",
            -- Cyrodiil
            "Anvil",
            -- Skyrim
            "Karthwasten"
        },
        cities = {
            -- Base Game
            "Ald-ruhn",
            "Balmora",
            "Sadrith Mora",
            -- Tamriel Rebuilt
            "Almas Thirr",
            "Andothren",
            "Bal Foyen",
            "Firewatch",
            "Necrom",
            "Akamora",
            "Hlan Oek",
            "Hlerynhul",
            "Port Telvannis",
            -- Skyrim
            "Dragonstar"
        },
        towns = {
            -- Base Game
            "Caldera",
            "Ebonheart",
            "Gnisis",
            "Maar Gan",
            "Molag Mar",
            "Pelagiad",
            "Suran",
            "Tel Aruhn",
            "Tel Branora",
            "Tel Mora",
            -- Tamriel Rebuilt
            "Darvonis",
            "Dondril",
            "Helnim",
            "Llothanis",
            "Omaynis",
            "Othmura",
            "Ranyon-ruhn",
            "Roa Dyr",
            "Sailen",
            "Shipal-Sharai",
            "Vhul",
            -- Cyrodiil
            "Brina Cross",
            "Charach",
            -- Skyrim
            "Karthgad"
        }
    }
}

local PUBLICAN_CLASSES = {
    publican = true,
    t_sky_publican = true,
    t_cyr_publican = true,
    t_glb_publican = true,
}

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
                },
                position = util.vector3(-712, -788, -1791),
                rotation = util.transform.rotateZ(math.pi / 2),
            }
        },
        startingLevel = 30,
        sheathedInstrument = "misc_de_lute_01",
    }
}

local QUEST_REWARDS = {
    b2_ahemmusasafe = {
        stage = 50,
        msg = "UI_Msg_QuestReward_Ahemmusa",
        item = "r_bc_songscroll_ahemmusa",
    },
    da_sheogorath = {
        stage = 70,
        msg = "UI_Msg_QuestReward_Sheogorath",
        item = "r_bc_musbox_sheo",
    }
}

local SONG_IDS = {
    -- Starting:        0x00000 - 0x0FFFF
    [0x00000] = "scales.mid",
    [0x00001] = "start-altmer.mid",
    [0x00002] = "start-argonian.mid",
    [0x00003] = "start-bosmer.mid",
    [0x00004] = "start-breton.mid",
    [0x00005] = "start-dunmer.mid",
    [0x00006] = "start-imperial.mid",
    [0x00007] = "start-khajiit.mid",
    [0x00008] = "start-nord.mid",
    [0x00009] = "start-orc.mid",
    [0x0000A] = "start-redguard.mid",
    -- Beginner:        0x10000 - 0x1FFFF
    [0x10000] = "beg1.mid",
    [0x10001] = "beg2.mid",
    [0x10002] = "beg3.mid",
    [0x10003] = "theroadbehindus.mid",
    [0x10100] = "bwv997.mid",
    -- Intermediate:    0x20000 - 0x2FFFF
    [0x20000] = "int1.mid",
    [0x20001] = "int2.mid",
    [0x20002] = "int3.mid",
    [0x20003] = "int4.mid",
    [0x20004] = "beneathtwomoons.mid",
    [0x20005] = "cliffstrider.mid",
    [0x20100] = "greensleeves.mid",
    [0x20101] = "imp1.mid",
    [0x20102] = "reddiamond.mid",
    -- Advanced:        0x30000 - 0x3FFFF
    [0x30000] = "adv1.mid",
    [0x30100] = "bwv997-adv.mid",
    -- Misc:            0xE0000 - 0xFFFFF
    [0xE0000] = "ahemmusa.mid",
    [0xE0001] = "molagberan.mid",
    [0xE0002] = "rollbretonnia.mid",
    [0xE0003] = "wondrouslove.mid",
    [0xE0004] = "redmountain.mid",
    [0xE0005] = "shrinktodust.mid",
    [0xE0006] = "brooding.mid",
    [0xE0007] = "lessrude.mid",
    [0xE0008] = "jornibret.mid",
    [0xE0009] = "moonsong.mid",
    ---- Drum Cadences:     0xE1000 - 0xE1FFF
    [0xE1000] = "cadence1.mid",
}

local SONG_POOLS = {
    beginner = {
        0x10000, -- beg1.mid
        0x10001, -- beg2.mid
        0x10002, -- beg3.mid
        0x10003, -- theroadbehindus.mid
        0x10100, -- bwv997.mid
    },
    intermediate = {
        0x20000, -- int1.mid
        0x20001, -- int2.mid
        0x20002, -- int3.mid
        0x20003, -- int4.mid
        0x20004, -- beneathtwomoons.mid
        0x20005, -- cliffstrider.mid
        0x20100, -- greensleeves.mid
        0x20101, -- imp1.mid
        0x20102, -- reddiamond.mid
    },
    advanced = {
        --0x30000, -- adv1.mid
        0x30100, -- bwv997-adv.mid
    },
}

local SONG_BOOKS = {
    r_bc_songbook_beg = {
        pools = {
            "beginner",
        },
    },
    r_bc_songbook_int = {
        pools = {
            "intermediate",
        },
    },
    r_bc_songbook_adv = {
        pools = {
            "advanced",
        },
    },
    r_bc_songscroll_ahemmusa = {
        songs = {
            0xE0000, -- ahemmusa.mid
        }
    },
    -- bk_battle_molag_beran = { -- Entertainers plug-in book
    --     songs = {
    --         0xE0001,          -- molagberan.mid
    --     }
    -- },
    -- bk_balladeers_fakebook = { -- Entertainers plug-in book
    --     songs = {
    --         0xE0002,           -- rollbretonnia.mid
    --     }
    -- },
    bk_ashland_hymns = { -- Vanilla book
        songs = {
            0xE0003,     -- wondrouslove.mid
        }
    },
    -- bk_five_far_stars = { -- Vanilla book
    --     songs = {
    --         0xE0004,      -- redmountain.mid
    --     }
    -- },
    -- bk_words_of_the_wind = { -- Vanilla book
    --     songs = {
    --         0xE0005,         -- shrinktodust.mid
    --     }
    -- },
    -- bk_cantatasofvivec = { -- Vanilla book
    --     songs = {
    --         0xE0006,       -- brooding.mid
    --     }
    -- },
    -- bk_istunondescosmology = { -- Vanilla book
    --     songs = {
    --         0xE0007,           -- lessrude.mid
    --     }
    -- },
    -- ["bookskill_light armor3"] = { -- Vanilla book
    --     songs = {
    --         0xE0008,               -- jornibret.mid
    --     }
    -- }
}

local MUSIC_BOXES = {
    r_bc_musbox_beg_a = {
        pools = {
            "beginner",
        },
        spawnChance = 0.5,
    },
    r_bc_musbox_int_a = {
        pools = {
            "intermediate",
        },
        spawnChance = 0.3,
    },
    r_bc_musbox_adv_a = {
        pools = {
            "advanced",
        },
        spawnChance = 0.7,
    },
    r_bc_musbox_sheo_a = { -- Sheogorath's Music Box; picks a random song from all music box pools
        pools = {
            "beginner",
            "intermediate",
            "advanced",
        },
        spawnChance = 0.5,
    }
}

local STARTING_SONGS = {
    ["scales.mid"] = "any",
    ["start-dunmer.mid"] = "any",
    -- ["start-altmer.mid"] = "high elf",
    -- ["start-argonian.mid"] = "argonian",
    -- ["start-bosmer.mid"] = "wood elf",
    -- ["start-breton.mid"] = "breton",
    -- ["start-dunmer.mid"] = "dark elf",
    -- ["start-imperial.mid"] = "imperial",
    -- ["start-khajiit.mid"] = "khajiit",
    -- ["start-nord.mid"] = "nord",
    -- ["start-orc.mid"] = "orc",
    -- ["start-redguard.mid"] = "redguard",
}

return {
    Version = VERSION,
    InstrumentItems = INSTRUMENT_ITEMS,
    SheathableInstruments = SHEATHABLE_INSTRUMENTS,
    Venues = VENUES,
    PublicanClasses = PUBLICAN_CLASSES,
    BardNpcs = BARD_NPCS,
    QuestRewards = QUEST_REWARDS,
    SongBooks = SONG_BOOKS,
    MusicBoxes = MUSIC_BOXES,
    SongIds = SONG_IDS,
    SongPools = SONG_POOLS,
    StartingSongs = STARTING_SONGS,
}
