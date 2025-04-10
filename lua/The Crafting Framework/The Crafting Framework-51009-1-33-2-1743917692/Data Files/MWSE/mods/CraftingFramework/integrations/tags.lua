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