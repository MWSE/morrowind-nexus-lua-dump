local firewatch = {}
local util = require("openmw.util")
firewatch.extCells = { { x = 17, y = 15 } }
firewatch.intCells = { "Firewatch, Census and Excise Office" }
firewatch.ExtobjectsToDisable = {

}
firewatch.intObjectsToDisable = {
    { "0xa663e", "tr_mainland.esm" },
    { "0xa6635", "tr_mainland.esm" },
    { "0xa6636", "tr_mainland.esm" },
    { "0xa6579", "tr_mainland.esm" },
    { "0xa6578", "tr_mainland.esm" },
    { "0xa6639", "tr_mainland.esm" },
    { "0xa6576", "tr_mainland.esm" },
    { "0xa6646", "tr_mainland.esm" },
    { "0xa664a", "tr_mainland.esm" },
    { "0x8c3d",  "tr_mainland.esm" },
    { "0x8c35",  "tr_mainland.esm" },
    { "0xd75c3", "tr_mainland.esm" },

    { "0xa6649", "tr_mainland.esm" },
    { "0xa6645", "tr_mainland.esm" },
    { "0xa6651", "tr_mainland.esm" },
    { "0xa6644", "tr_mainland.esm" },
    { "0xa6653", "tr_mainland.esm" },
    { "0xa6849", "tr_mainland.esm" },
    { "0xa6658", "tr_mainland.esm" },

    { "0xa6655", "tr_mainland.esm" },

    { "0xa6652", "tr_mainland.esm" },
    { "0xa6657", "tr_mainland.esm" },
    { "0xa6643", "tr_mainland.esm" },
    { "0xa6648", "tr_mainland.esm" },
    { "0xa6647", "tr_mainland.esm" },
    { "0x8d9b",  "tr_mainland.esm" },
    { "0x8d9a",  "tr_mainland.esm" },
    { "0x8c34",  "tr_mainland.esm" },
    { "0x8f16",  "tr_mainland.esm" },
    { "0x8f1a",  "tr_mainland.esm" },
    { "0x8f15",  "tr_mainland.esm" },
    { "0x8f19",  "tr_mainland.esm" },
    { "0x8c7a",  "tr_mainland.esm" },
    { "0x8c3c",  "tr_mainland.esm" },
    { "0x8c2c",  "tr_mainland.esm" },

}
firewatch.repositions = {
    ["chargen_ship_trapdoor"] = {
        id = "chargen_ship_trapdoor",
        position = util.vector3(140390.375, 126134.734375, 163.2237396240234375),
        rotation = 5.6548667764616,
    }
}
firewatch.intObjectsToLock = {
    { "0xa657f", "tr_mainland.esm" },
    { "0xa65be", "tr_mainland.esm" },
    { "0xa657c", "tr_mainland.esm" },
    { "0xa65bd", "tr_mainland.esm" },
    { "0xa657e", "tr_mainland.esm" },
    { "0xa6580", "tr_mainland.esm" },
    { "0xa657d", "tr_mainland.esm" },
    { "0xa65bf", "tr_mainland.esm" },
    { "0xa65c1", "tr_mainland.esm" },


}
firewatch.hallwayDoorUnlock = { { "0xa65be", "tr_mainland.esm" },

}

firewatch.exitDoorUnlock = { { "0xa657f", "tr_mainland.esm" } }
firewatch.shipExitId = "chargen_shipdoor_firewatch"
firewatch.extNPCPositions = {
    ["chargen boat guard 1"] = {
        position = util.vector3(140217, 126527, 112),
        rotation = math.rad(143)
    },

    ["chargen dock guard"] = {
        position = util.vector3(140946, 125814, 178),
        rotation = math.rad(0),
    }
}
firewatch.placeObjects = { {
    id = "chargen statssheet",
    cell = "Firewatch, Census and Excise Office",
    position = util.vector3(3909, 3191, 14374),
    rotation = math.rad(80)
}, {
    id = "tr_m1_imp_guard_navy_s",
    cell = "Firewatch, Census and Excise Office",
    position = util.vector3(3752, 3368, 14320),
    rotation = math.rad(130),
    script = "scripts/immersiveChargen/npcScripts/chargendoorguard.lua"
}, {
    id = "chargen captain",
    cell = "Firewatch, Census and Excise Office",
    position = util.vector3(4384, 3200, 14817.9189453125),
    rotation = math.rad(21),
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 67,
    id = "chest_small_02_rndgold",
    translation = { 3888.173, 3067.6409, 14381.57 },
    rotation = { 0.0, -0.0, 2.4853988 },
    scale = 1.23,
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 68,
    id = "misc_lw_platter",
    translation = { 3882.2134, 3113.1685, 14376.289 },
    rotation = { 0.0, 0.0, 0.0 },
    scale = 0.61,
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 69,
    id = "chargen dagger",
    owner = "a shady smuggler",
    translation = { 3668.7876, 3655.43, 14387.595 },
    rotation = { 1.5707965, 4.783187, 6.0981803 }
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 70,
    id = "misc_imp_silverware_cup",
    translation = { 3658.314, 3616.8496, 14375.834 },
    rotation = { 0.0, -0.0, 1.300001 },
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 71,
    id = "misc_imp_silverware_plate_01",
    translation = { 3668.3816, 3594.5483, 14371.531 },
    rotation = { 0.0, -0.0, 1.4000002 },
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 72,
    id = "Misc_Imp_Silverware_Bowl",
    translation = { 3651.4246, 3576.3333, 14373.461 },
    rotation = { 0.0, -0.0, 1.385399 },
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 73,
    id = "misc_com_silverware_fork",
    translation = { 3673.3953, 3579.3423, 14371.029 },
    rotation = { 0.0, -0.0, 2.8999996 },
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 74,
    id = "misc_com_silverware_knife",
    translation = { 3673.5398, 3616.6367, 14370.892 },
    rotation = { 0.0, -0.0, 3.3000002 },
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 75,
    id = "misc_imp_silverware_pitcher",
    translation = { 3668.00830078125, 3640.912109375, 14386.1533203125 },
    rotation = { 0.0, -0.0, 5.1168184 },
    scale = 0.88000005,
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 76,
    id = "sc_paper plain",
    translation = { 4085.3179, 3587.1208, 14371.815 },
    rotation = { 0.0, -0.0, 3.500148 },
    scale = 1.5200001,
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 77,
    id = "ingred_bread_01",
    translation = { 4085.2114, 3588.6775, 14376.746 },
    rotation = { 0.0, -0.0, 3.1853983 },
    scale = 1.2600001,
    owner = "a shady smuggler",
    health_left = 0
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 78,
    id = "Potion_Cyro_Whiskey_01",
    owner = "a shady smuggler",
    translation = { 3645.88, 3599.8606, 14378.622 },
    rotation = { 0.0, -0.0, 1.5000001 }
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 79,
    id = "ingred_crab_meat_01",
    owner = "a shady smuggler",
    translation = { 3668.3633, 3594.114, 14371.422 },
    rotation = { 0.0, -0.0, 1.5000001 }
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 80,
    id = "pick_apprentice_01",
    owner = "a shady smuggler",
    translation = { 3666.7644, 3558.0308, 14370.508 },
    rotation = { 0.0, -0.0, 2.3999999 }
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 81,
    id = "light_com_candle_10_128",
    owner = "a shady smuggler",
    translation = { 3657.8364, 3547.5723, 14380.309 },
    rotation = { 0.0, -0.0, 0.20000313 }
}, {
    cell = "Firewatch, Census and Excise Office",
    refr_index = 82,
    id = "misc_lw_flask",
    owner = "a shady smuggler",
    translation = { 3883.7654, 3113.7095, 14387.414 },
    rotation = { 0.0, 0.0, 0.0 }
} }

firewatch.placeObjectsExt = { {
    refr_index = 1,
    id = "zhac_walltoplace",
    position = util.vector3(140756.97, 126847.07, 320.0),
    rotation = (4.0707974)
}, {
    refr_index = 2,
    id = "zhac_walltoplace",
    position = util.vector3(141097.27, 124797.35, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 3,
    id = "zhac_walltoplace",
    position = util.vector3(141097.27, 125053.35, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 4,
    id = "zhac_walltoplace",
    position = util.vector3(141097.27, 125309.35, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 5,
    id = "zhac_walltoplace",
    position = util.vector3(141096.77, 125548.41, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 6,
    id = "zhac_walltoplace",
    position = util.vector3(141106.7, 125792.78, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 7,
    id = "zhac_walltoplace",
    position = util.vector3(141117.0, 126043.64, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 8,
    id = "zhac_walltoplace",
    position = util.vector3(140872.14, 126684.7, 320.0),
    rotation = (1.0707964)
}, {
    refr_index = 9,
    id = "zhac_walltoplace",
    position = util.vector3(140751.03, 126270.41, 320.0),
    rotation = (1.0707964)
}, {
    refr_index = 10,
    id = "zhac_walltoplace",
    position = util.vector3(140495.27, 126305.47, 239.96704),
    rotation = (1.1539851)
}, {
    refr_index = 11,
    id = "zhac_walltoplace",
    position = util.vector3(140483.78, 126767.19, 320.0),
    rotation = (1.0707964)
}, {
    refr_index = 12,
    id = "zhac_walltoplace",
    position = util.vector3(140575.64, 126904.96, 320.0),
    rotation = (2.5707965)
}, {
    refr_index = 13,
    id = "zhac_walltoplace",
    position = util.vector3(140811.5, 126037.81, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 14,
    id = "zhac_walltoplace",
    position = util.vector3(140819.73, 125790.29, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 15,
    id = "zhac_walltoplace",
    position = util.vector3(143227.39, 124325.89, 336.2677),
    rotation = (0.4707986)
}, {
    refr_index = 16,
    id = "zhac_walltoplace",
    position = util.vector3(143440.7, 124206.17, 388.40002),
    rotation = (0.4707986)
}, {
    refr_index = 17,
    id = "zhac_walltoplace",
    position = util.vector3(143653.97, 124098.22, 425.71484),
    rotation = (0.4707986)
}, {
    refr_index = 18,
    id = "zhac_walltoplace",
    position = util.vector3(143882.11, 123982.08, 425.71484),
    rotation = (0.4707986)
}, {
    refr_index = 19,
    id = "zhac_walltoplace",
    position = util.vector3(144110.27, 123865.97, 425.71484),
    rotation = (0.4707986)
}, {
    refr_index = 20,
    id = "zhac_walltoplace",
    position = util.vector3(141055.98, 126285.65, 320.0),
    rotation = (1.2707964)
}, {
    refr_index = 21,
    id = "zhac_walltoplace",
    position = util.vector3(140957.98, 126525.9, 320.0),
    rotation = (1.0707964)
}, {
    refr_index = 22,
    id = "zhac_walltoplace",
    position = util.vector3(140668.69, 126435.805, 320.0),
    rotation = (1.0707964)
}, {
    refr_index = 23,
    id = "zhac_walltoplace",
    position = util.vector3(140522.25, 126481.36, 255.47949),
    rotation = (2.5707963)
}, {
    refr_index = 24,
    id = "zhac_walltoplace",
    position = util.vector3(140424.25, 126605.195, 239.96704),
    rotation = (2.5707963)
}, {
    refr_index = 25,
    id = "zhac_walltoplace",
    position = util.vector3(140241.66, 126662.94, 239.96704),
    rotation = (0.870796)
}, {
    refr_index = 26,
    id = "zhac_walltoplace",
    position = util.vector3(140120.14, 126858.87, 239.96704),
    rotation = (0.870796)
}, {
    refr_index = 27,
    id = "zhac_walltoplace",
    position = util.vector3(139990.69, 127019.75, 239.96704),
    rotation = (0.870796)
}, {
    refr_index = 28,
    id = "zhac_walltoplace",
    position = util.vector3(139951.12, 126839.086, 239.96704),
    rotation = (2.3707964)
}, {
    refr_index = 29,
    id = "zhac_walltoplace",
    position = util.vector3(139824.06, 126695.82, 239.96704),
    rotation = (2.3707964)
}, {
    refr_index = 30,
    id = "zhac_walltoplace",
    position = util.vector3(139829.0, 126501.36, 239.96704),
    rotation = (4.153984)
}, {
    refr_index = 31,
    id = "zhac_walltoplace",
    position = util.vector3(139962.78, 126288.53, 239.96704),
    rotation = (3.9539843)
}, {
    refr_index = 32,
    id = "zhac_walltoplace",
    position = util.vector3(140162.73, 126098.516, 239.96704),
    rotation = (3.9539843)
}, {
    refr_index = 33,
    id = "zhac_walltoplace",
    position = util.vector3(140340.48, 125909.99, 239.96704),
    rotation = (3.9539843)
}, {
    refr_index = 34,
    id = "zhac_walltoplace",
    position = util.vector3(140551.33, 125777.24, 239.96704),
    rotation = (3.4539847)
}, {
    refr_index = 35,
    id = "zhac_walltoplace",
    position = util.vector3(140661.25, 125876.46, 239.96704),
    rotation = (1.4539852)
}, {
    refr_index = 36,
    id = "zhac_walltoplace",
    position = util.vector3(140591.86, 126096.68, 239.96704),
    rotation = (1.1539851)
}, {
    refr_index = 37,
    id = "zhac_walltoplace",
    position = util.vector3(140800.0, 124544.0, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 38,
    id = "zhac_walltoplace",
    position = util.vector3(140800.0, 124800.0, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 39,
    id = "zhac_walltoplace",
    position = util.vector3(140800.0, 125056.0, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 40,
    id = "zhac_walltoplace",
    position = util.vector3(140799.5, 125295.055, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 41,
    id = "zhac_walltoplace",
    position = util.vector3(140809.44, 125539.43, 320.0),
    rotation = (1.5707964)
}, {
    refr_index = 42,
    id = "zhac_walltoplace",
    position = util.vector3(141892.9, 124341.08, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 43,
    id = "zhac_walltoplace",
    position = util.vector3(141637.55, 124359.17, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 44,
    id = "zhac_walltoplace",
    position = util.vector3(141382.17, 124377.29, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 45,
    id = "zhac_walltoplace",
    position = util.vector3(141143.7, 124393.69, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 46,
    id = "zhac_walltoplace",
    position = util.vector3(140900.61, 124420.9, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 47,
    id = "zhac_walltoplace",
    position = util.vector3(143015.12, 124367.51, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 48,
    id = "zhac_walltoplace",
    position = util.vector3(142759.23, 124360.016, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 49,
    id = "zhac_walltoplace",
    position = util.vector3(142503.33, 124352.55, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 50,
    id = "zhac_walltoplace",
    position = util.vector3(142264.42, 124345.055, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 51,
    id = "zhac_walltoplace",
    position = util.vector3(142019.83, 124347.86, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 52,
    id = "zhac_walltoplace",
    position = util.vector3(142220.55, 124707.49, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 53,
    id = "zhac_walltoplace",
    position = util.vector3(141964.66, 124700.0, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 54,
    id = "zhac_walltoplace",
    position = util.vector3(141708.75, 124692.53, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 55,
    id = "zhac_walltoplace",
    position = util.vector3(141469.84, 124685.04, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 56,
    id = "zhac_walltoplace",
    position = util.vector3(141225.25, 124687.84, 320.0),
    rotation = (6.253984)
}, {
    refr_index = 57,
    id = "zhac_walltoplace",
    position = util.vector3(143383.75, 124642.49, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 58,
    id = "zhac_walltoplace",
    position = util.vector3(143128.39, 124660.586, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 59,
    id = "zhac_walltoplace",
    position = util.vector3(142873.02, 124678.7, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 60,
    id = "zhac_walltoplace",
    position = util.vector3(142634.55, 124695.1, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 61,
    id = "zhac_walltoplace",
    position = util.vector3(142391.45, 124722.305, 320.0),
    rotation = (0.070798665)
}, {
    refr_index = 62,
    id = "zhac_walltoplace",
    position = util.vector3(144595.05, 124206.79, 417.41284),
    rotation = (0.37079862)
}, {
    refr_index = 63,
    id = "zhac_walltoplace",
    position = util.vector3(144356.44, 124299.54, 417.41284),
    rotation = (0.37079862)
}, {
    refr_index = 64,
    id = "zhac_walltoplace",
    position = util.vector3(144117.84, 124392.32, 417.41284),
    rotation = (0.37079862)
}, {
    id = "zhac_walltoplace",
    position = util.vector3(143894.86, 124478.445, 417.41284),
    rotation = (0.37079862)
}, {
    refr_index = 66,
    id = "zhac_walltoplace",
    position = util.vector3(143670.66, 124576.27, 417.41284),
    rotation = (0.37079862)
} }

return firewatch
