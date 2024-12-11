---@class AdventCalendar.BoxConfig
---@field minimumDate { day: number, month: number }
---@field message string
---@field gifts table<string, number>

---@class AdventCalendar.Config
local config = {}

---@class AdventCalendar.ConfigMessages
config.messages = {
    alreadyOpened = "It's empty",
    cantOpen = "You can't open this yet...",
    canOpen = "Time to open!",
    acceptGifts = "Accept gifts",
    receivedGifts = "Gifts added to inventory"
}

---@type table<string, AdventCalendar.BoxConfig>
config.boxes = {
    aa_xmas_01 = {
        minimumDate = {
            day = 1,
            month = 12,
        },
        message = "It starts with a tree.",
        gifts = {
            aa_xmas_Christmas_Tree_small = 1,
        },
    },
    aa_xmas_02 = {
        minimumDate = {
            day = 2,
            month = 12,
        },
        message = "Let's get you stocked on stockings",
        gifts = {
            aa_xmas_stocking_green_misc = 1,
            aa_xmas_stocking_holly_misc = 1,
            aa_xmas_stocking_red_misc = 1,
            aa_xmas_stocking_snow_misc = 1,
        },
    },
    aa_xmas_03 = {
        minimumDate = {
            day = 3,
            month = 12,
        },
        message = "Some blue for your tree...",
        gifts = {
            aa_xmas_Christmas_Orn_SilverGl = 3,
            aa_xmas_Christmas_Orn_Silver = 3,
            aa_xmas_Christmas_Orn_SnowsM = 6
        },
    },
    aa_xmas_04 = {
        minimumDate = {
            day = 4,
            month = 12,
        },
        message = "Some red for your tree...",
        gifts = {
            aa_xmas_Christmas_Orn_GoldGl = 3,
            aa_xmas_Christmas_Orn_RedGl = 3,
            aa_xmas_Christmas_Orn_Red = 3,
        },
    },
    aa_xmas_05 = {
        minimumDate = {
            day = 5,
            month = 12,
        },
        message = "and green for your tree!",
        gifts = {
            aa_xmas_Christmas_Orn_Greens = 3,
            aa_xmas_Christmas_Orn_GreensG = 3,
            aa_xmas_Christmas_Orn_Gold = 6,

        },
    },
    aa_xmas_06 = {
        minimumDate = {
            day = 6,
            month = 12,
        },
        message = "The final touch!",
        gifts = {
            aa_xmas_gold_Glass_ornament = 1,
            aa_xmas_silver_Glass_ornament = 1
        },
    },
    aa_xmas_07 = {
        minimumDate = {
            day = 7,
            month = 12,
        },
        message = "Decorating got your hungry and thirsty?",
        gifts = {
            GW22_Cookie_01 = 2,
            GW22_Cookie_02 = 2,
            GW22_Cookie_03 = 2,
            GW22_Cookie_04 = 2,
            ["GW22_dri_Glühwein"] = 4,
        },
    },
    aa_xmas_08 = {
        minimumDate = {
            day = 8,
            month = 12,
        },
        message = "Time to bring the Solstheim snow to Vvardenfell!",
        gifts = {
            aa_xmas_globe_balm = 1,
        },
    },
    aa_xmas_09 = {
        minimumDate = {
            day = 9,
            month = 12,
        },
        message = "I have a message for you, your eyes only.",
        gifts = {
            aa_xmas_Christmas_Card_3 = 1,
        },
    },
    aa_xmas_10 = {
        minimumDate = {
            day = 10,
            month = 12,
        },
        message = "Something for your door, yes, your door.",
        gifts = {
            aa_xmas_Wreath_Loaded_misc = 1,
        },
    },
    aa_xmas_11 = {
        minimumDate = {
            day = 11,
            month = 12,
        },
        message = "You know what needs more snow? The Ashlands!",
        gifts = {
            aa_xmas_globe_ash = 1,
        },
    },
    aa_xmas_12 = {
        minimumDate = {
            day = 12,
            month = 12,
        },
        message = "It's tea time!.",
        gifts = {
            aa_xmas_Christmas_candle = 2,
            aa_xmas_Teapot_CH = 1,
            aa_xmas_Christmas_saucer_CH = 2,
            aa_xmas_Christmas_teacup = 2,
            aa_xmas_Christmas_sugar = 1,
            GW22_Cookie_01 = 1,
            GW22_Cookie_02 = 1,
            GW22_Cookie_03 = 1,
            GW22_Cookie_04 = 1,
        },
    },
    aa_xmas_13 = {
        minimumDate = {
            day = 13,
            month = 12,
        },
        message = "Something for your friends.",
        gifts = {
            aa_xmas_gift01 = 2,
            aa_xmas_gift02 = 2
        },
    },
    aa_xmas_14 = {
        minimumDate = {
            day = 14,
            month = 12,
        },
        message = "Something to play with your friends.",
        gifts = {
            aa_xmas_w_Snowball = 20,
        },
    },
    aa_xmas_15 = {
        minimumDate = {
            day = 15,
            month = 12,
        },
        message = "Something to make friends",
        gifts = {
            aa_xmas_Candy_Cane_LE = 10,
        },
    },
    aa_xmas_16 = {
        minimumDate = {
            day = 16,
            month = 12,
        },
        message = "Snow, snow, snow.",
        gifts = {
            aa_xmas_globe_ald = 1,
        },
    },
    aa_xmas_17 = {
        minimumDate = {
            day = 17,
            month = 12,
        },
        message = "No celebration without some proper lights.",
        gifts = {
            aa_xmas_Christmas_Lights_Misc = 5,
        },
    },
    aa_xmas_18 = {
        minimumDate = {
            day = 18,
            month = 12,
        },
        message = "Think the Telvanni like snow?",
        gifts = {
            aa_xmas_globe_sadrith = 1,
        },
    },
    aa_xmas_19 = {
        minimumDate = {
            day = 19,
            month = 12,
        },
        message = "I know just the thing to warm up",
        gifts = {
            aa_xmas_mug_tea_CH = 4,
        },
    },
    aa_xmas_20 = {
        minimumDate = {
            day = 20,
            month = 12,
        },
        message = "The Nord have a different drink they like better.",
        gifts = {
            aa_xmas_globe_df = 1,
            potion_nord_mead = 1,
        },
    },
    aa_xmas_21 = {
        minimumDate = {
            day = 21,
            month = 12,
        },
        message = "Looks like more gifts have arrived!",
        gifts = {
            aa_xmas_gift01 = 2,
            aa_xmas_gift02 = 2
        },
    },
    aa_xmas_22 = {
        minimumDate = {
            day = 22,
            month = 12,
        },
        message = "Almost ready...",
        gifts = {
            GW22_a_SantaHat = 2,
        },
    },
    aa_xmas_23 = {
        minimumDate = {
            day = 23,
            month = 12,
        },
        message = "The final touch!",
        gifts = {
            GW22_XmasSweater04 = 2,
        },
    },
    aa_xmas_24 = {
        minimumDate = {
            day = 24,
            month = 12,
        },
        message = "Did you really expect something different from Uncle Sweetshare?",
        gifts = {
            aa_xmas_pipe = 1,
            ingred_moon_sugar_01 = 10
        },
    },
}

return config