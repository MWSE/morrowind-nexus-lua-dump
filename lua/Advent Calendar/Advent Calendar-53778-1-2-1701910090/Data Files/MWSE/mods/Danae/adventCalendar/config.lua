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
        message = "You'll be needing this.",
        gifts = {
            aa_xmas_Christmas_Tree_small = 2,
        },
    },
    aa_xmas_02 = {
        minimumDate = {
            day = 2,
            month = 12,
        },
        message = "Let's get you started in... blue?",
        gifts = {
            aa_xmas_candle01 = 2,
            aa_xmas_plate02 = 2,
            aa_xmas_stocking_snow_misc = 1,
        },
    },
    aa_xmas_03 = {
        minimumDate = {
            day = 3,
            month = 12,
        },
        message = "And blue for your tree.",
        gifts = {
            aa_xmas_Christmas_Orn_SilverGl = 2,
            aa_xmas_Christmas_Orn_Silver = 2,
            aa_xmas_Christmas_Orn_SnowsM = 4
        },
    },
    aa_xmas_04 = {
        minimumDate = {
            day = 4,
            month = 12,
        },
        message = "Red's your colour?",
        gifts = {
            aa_xmas_candle02 = 2,
            aa_xmas_cloth01 = 1,
            aa_xmas_plate01 = 2,
            aa_xmas_stocking_red_misc = 1
        },
    },
    aa_xmas_05 = {
        minimumDate = {
            day = 5,
            month = 12,
        },
        message = "Yes, yes, also for your tree.",
        gifts = {
            aa_xmas_Christmas_Orn_GoldGl = 2,
            aa_xmas_Christmas_Orn_Gold = 2,
            aa_xmas_Christmas_Orn_RedGl = 2,
            aa_xmas_Christmas_Orn_Red = 2,
        },
    },
    aa_xmas_06 = {
        minimumDate = {
            day = 6,
            month = 12,
        },
        message = "Decorating got you thirsty?",
        gifts = {
            ["GW22_dri_Glühwein"] = 4,
        },
    },
    aa_xmas_07 = {
        minimumDate = {
            day = 7,
            month = 12,
        },
        message = "And hungry?",
        gifts = {
            GW22_Cookie_01 = 2,
            GW22_Cookie_02 = 2,
            GW22_Cookie_03 = 2,
            GW22_Cookie_04 = 2,
        },
    },
    aa_xmas_08 = {
        minimumDate = {
            day = 8,
            month = 12,
        },
        message = "Ready for something a little fancier?",
        gifts = {
            aa_xmas_Christmas_saucer_CH = 2,
            aa_xmas_Christmas_teacup = 2
        },
    },
    aa_xmas_09 = {
        minimumDate = {
            day = 9,
            month = 12,
        },
        message = "I have a message for you, your eyes only.",
        gifts = {
            aa_xmas_Christmas_Card_2 = 1,
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
        message = "And because evil does not rest, something for your protection.",
        gifts = {
            GW22_a_WreathShield = 1,
        },
    },
    aa_xmas_12 = {
        minimumDate = {
            day = 12,
            month = 12,
        },
        message = "Let's add to that fancy set.",
        gifts = {
            aa_xmas_Christmas_candle = 2,
            aa_xmas_Teapot_CH = 1
        },
    },
    aa_xmas_13 = {
        minimumDate = {
            day = 13,
            month = 12,
        },
        message = "Time to make friends.",
        gifts = {
            aa_xmas_Candy_Cane_LE = 10,
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
        message = "Something to play with your other 'friends'.",
        gifts = {
            aa_xmas_w_Snowball_deadly = 20,
        },
    },
    aa_xmas_16 = {
        minimumDate = {
            day = 16,
            month = 12,
        },
        message = "Let's get your living room ready.",
        gifts = {
            aa_xmas_plant = 4,
        },
    },
    aa_xmas_17 = {
        minimumDate = {
            day = 17,
            month = 12,
        },
        message = "Oh, we never completed that fancy set!",
        gifts = {
            aa_xmas_Christmas_plate_CH = 4,
            aa_xmas_Christmas_sugar = 1
        },
    },
    aa_xmas_18 = {
        minimumDate = {
            day = 18,
            month = 12,
        },
        message = "The final touch for your tree",
        gifts = {
            aa_xmas_gold_Glass_ornament = 1,
            aa_xmas_silver_Glass_ornament = 1
        },
    },
    aa_xmas_19 = {
        minimumDate = {
            day = 19,
            month = 12,
        },
        message = "I know these tend to break a lot. I got you some spare.",
        gifts = {
            aa_xmas_Christmas_Orn_GoldGl = 2,
            aa_xmas_Christmas_Orn_Gold = 2,
            aa_xmas_Christmas_Orn_RedGl = 2,
            aa_xmas_Christmas_Orn_Red = 2,
            aa_xmas_Christmas_Orn_SilverGl = 2,
            aa_xmas_Christmas_Orn_Silver = 2,
            aa_xmas_Christmas_Orn_SnowsM = 4,
        },
    },
    aa_xmas_20 = {
        minimumDate = {
            day = 20,
            month = 12,
        },
        message = "No celebration without some proper lights.",
        gifts = {
            aa_xmas_Christmas_Lights_Misc = 5,
        },
    },
    aa_xmas_21 = {
        minimumDate = {
            day = 21,
            month = 12,
        },
        message = "Something for your friends.",
        gifts = {
            aa_xmas_gift01 = 3,
            aa_xmas_gift02 = 3
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
            aa_xmas_mug_tea_CH = 4
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