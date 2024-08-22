local templateLayers = require("scripts.Hestatur.templateLayers")

return {
    camPos = {
        {
            position = {11.18536090850830078125, 702.06365966796875, 182.1318206787109375},
            pitch = 0.3,
            yaw = 3.12,
            fov = 1.5
        },
        {
            position = {-17.242824554443359375, -385.882965087890625, -42.036441802978515625},
            pitch = 0.27,
            yaw = 0.02,
            fov = 1.5
        },

    },
    paintings = templateLayers.paintings,
    rugs =templateLayers.rugs,
    furniture = {
        objects = {
            "furn_de_r_table_07",
            "spok_chest_5",
            "spok_chest_1",
            "spok_chest_2",
            "active_de_pr_bed_21",
            "misc_uni_pillow_01",
            "furn_de_r_table_07",
            "spok_chest_5",
            "active_de_pr_bed_21",
            "misc_uni_pillow_01",
            "furn_de_r_table_*",
            "furn_com_r_chair_01",
            "light_com_candle_08",
            "AB_o_DeRchDeskEmpty",
            "spok_chest_7",
            "spok_cupboard_1",
            "Furn_De_R_Bookshelf_02",
            "furn_com_r_bookshelf_01",
            "spok_drawers_3",
            "spok_table_1",
            "spok_table_2",
            "furn_de_r_table_03",
            "spok_chest_s2",
            "spok_chest_s1",
            "furn_de_r_bench_01",
            "furn_de_r_wallscreen_02",
            "furn_com_r_chair_01",
            "furn_glassdisplaycase_01",
            "furn_com_rm_barstool",
            "furn_com_rm_shelf_02",
            "light_com_candle_10"
        },
        name = "Furniture",
        price = 500
    },
    banners = templateLayers.banners,
    mannequins = templateLayers.mannequins
}