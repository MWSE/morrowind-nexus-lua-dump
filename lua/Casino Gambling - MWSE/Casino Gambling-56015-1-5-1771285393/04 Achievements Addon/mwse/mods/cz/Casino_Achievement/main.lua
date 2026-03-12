---@diagnostic disable: assign-type-mismatch
local sb_achievements = require("sb_achievements.interop")

local function init()
    local iconPath = "Icons\\cz\\csn\\"
    local cats = {
        main = sb_achievements.registerCategory("Main Quest"),
        side = sb_achievements.registerCategory("Side Quest"),
        faction = sb_achievements.registerCategory("Faction"),
        misc = sb_achievements.registerCategory("Miscellaneous")
    }
    sb_achievements.registerAchievement {
        id        = "CSNRouletteWins",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_roulette_wins")
        end,
        progressMax = function ()
            return 10
        end,
        icon      = iconPath .. "ic_v_rlt.dds",
        colour    = sb_achievements.colours.bronze,
        title     = "Wheel Of Fortune", desc = "Win 10 games of Daedra's Turn.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNBlackjackWins",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_blackjack_wins")
        end,
        progressMax = function ()
            return 10
        end,
        icon      = iconPath .. "ic_v_bj.dds",
        colour    = sb_achievements.colours.bronze,
        title     = "Know When To Hold 'Em", desc = "Win 10 games of Iron Crown.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNSolitaireWins",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_solitaire_wins")
        end,
        progressMax = function ()
            return 10
        end,
        icon      = iconPath .. "ic_v_hort.dds",
        colour    = sb_achievements.colours.bronze,
        title     = "Solitaire", desc = "Win 10 games of Hortator.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNGreedWins",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_greed_wins")
        end,
        progressMax = function ()
            return 10
        end,
        icon      = iconPath .. "ic_v_grd.dds",
        colour    = sb_achievements.colours.bronze,
        title     = "Greed Is Good", desc = "Win 10 games of Greed.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNLebronWins",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_lebron_wins")
        end,
        progressMax = function ()
            return 10
        end,
        icon      = iconPath .. "ic_v_dice.dds",
        colour    = sb_achievements.colours.bronze,
        title     = "Vivec's Gambit", desc = "Win 10 games of Thirty-Six.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNLebronWinsChallenge",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_lebron_wins")
        end,
        progressMax = function ()
            return 36
        end,
        icon      = iconPath .. "ic_v_dice_ch.dds",
        colour    = sb_achievements.colours.gold,
        title     = "36 Tosses Of Vivec", desc = "Win 36 games of Thirty-Six.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNMahjongWins",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_mahjong_wins")
        end,
        progressMax = function ()
            return 10
        end,
        icon      = iconPath .. "ic_v_mahj.dds",
        colour    = sb_achievements.colours.bronze,
        title     = "Card Architect", desc = "Win 10 games of Mazte.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNBannedChallenge",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress = function ()
            return tes3.getGlobal("csn_casino_bans")
        end,
        progressMax = function ()
            local isTRLoaded = tes3.getFileExists("TR_Mainland.esm")
            local isPCLoaded = tes3.getFileExists("Cyr_Main.esm")
            local maxCasinos = 3
            if isTRLoaded then maxCasinos = maxCasinos + 2 end
            if isPCLoaded then maxCasinos = maxCasinos + 2 end
            return maxCasinos
        end,
        icon      = iconPath .. "ic_v_ban.dds",
        colour    = sb_achievements.colours.bronze,
        title     = "The One Who Broke The Bank", desc = "Get banned from every gambling hall.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })