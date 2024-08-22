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
    rugs =templateLayers.rugs,
    paintings = templateLayers.paintings,
    music = {
objects = {
    "spok_dgl_gong_01",
    "spok_dgl_marimba_01",
    "spok_dgl_drum*",
    "misc_mallet_01",
    "spok_dgl_harpsichord_01",
    "spok_dgl_harp_01",
    "misc_music_*",
}
,
name = "Musical Items",
price = 1500
    },
   
    furniture = templateLayers.furniture,
    banners = templateLayers.banners,
    mannequins = templateLayers.mannequins
}