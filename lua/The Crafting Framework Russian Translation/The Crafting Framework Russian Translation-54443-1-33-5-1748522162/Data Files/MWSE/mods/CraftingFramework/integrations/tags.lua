local TagManager = require("CraftingFramework.components.TagManager")

local traders = {
    "arrille",
    "ra'virr",
    "mebestian ence",
    "alveno andules",
    "goldyn belaram",
    "irgola",
    "clagius clanler",
    "fadase selvayn",
    "tiras sadus",
    "heifnir",
    "ancola",
    "ababael timsar-dadisun",
    "shulki ashunbabi",
    "perien aurelie",
    "thongar",
    "vasesius viciulus",
    "baissa",
    "sedam omalen",
    "ferele athram",
    "urfing",
    "dralasa nithryon",
    "galtis guvron",
    "naspis apinia",
    "berwen",
    "Sky_iRe_KW_Tivela",
    "Sky_iRe_VS_Sorri",
    "TR_m3_Hamal",
}

TagManager.addIds{
    tag = "generalTrader",
    ids = traders
}

local innkeepers = {
    "lirielle stoine",
    "darvam hlaren",
    "arrille",
    "helviane desele",
    "ashumanu eraishah",
    "fryfnhild",
    "thongar",
    "brathus dals",
    "drarayne girith",
    "selkirnemus",
    "orns omaren",
    "moroni uvelas",
    "sedam omalen",
}

TagManager.addIds{
    tag = "innkeeper",
    ids = innkeepers
}

TagManager.addIds{
    tag = "bard",
    ids = {
        "bard",
        "t_sky_bard",
        "t_cyr_bard",
        "t_glb_bard",
    }
}

TagManager.addIds{
    tag = "publican",
    ids = {
        "publican",
        "t_sky_publican",
        "t_cyr_publican",
        "t_glb_publican",
    }
}