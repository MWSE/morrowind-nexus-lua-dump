local sb_achievements = require("sb_achievements.interop")
local success, macModule = pcall(require, "MAC.playerData")
local pData
if success then
    pData = macModule
else
    pData = {
        colours = {
            bronze  = { 255 / 255, 140 / 255, 20 / 255 },
            silver  = { 200 / 255, 200 / 255, 255 / 255 },
            gold    = { 203 / 255, 190 / 255, 53 / 255 },
            plat    = { 200 / 255, 240 / 255, 200 / 255 }
        }
    }
end

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
        condition = function()
            return tes3.getGlobal("csn_roulette_wins") >= 10
        end,
        icon      = iconPath .. "ic_v_rlt.dds",
        colour    = pData.colours.bronze,
        title     = "Wheel of Fortune", desc = "Win 10 games of Daedra's Turn.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNBlackjackWins",
        category  = cats.misc,
        condition = function()
            return tes3.getGlobal("csn_blackjack_wins") >= 10
        end,
        icon      = iconPath .. "ic_v_bj.dds",
        colour    = pData.colours.bronze,
        title     = "Know When To Hold 'Em", desc = "Win 10 games of Iron Crown.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNSolitaireWins",
        category  = cats.misc,
        condition = function()
            return tes3.getGlobal("csn_solitaire_wins") >= 10
        end,
        icon      = iconPath .. "ic_v_hort.dds",
        colour    = pData.colours.bronze,
        title     = "Solitaire", desc = "Win 10 games of Hortator.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNGreedWins",
        category  = cats.misc,
        condition = function()
            return tes3.getGlobal("csn_greed_wins") >= 10
        end,
        icon      = iconPath .. "ic_v_grd.dds",
        colour    = pData.colours.bronze,
        title     = "Greed Is Good", desc = "Win 10 games of Greed.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "CSNLebronWins",
        category  = cats.misc,
        condition = function()
            return tes3.getGlobal("csn_lebron_wins") >= 10
        end,
        icon      = iconPath .. "ic_v_dice.dds",
        colour    = pData.colours.bronze,
        title     = "Vivec's Gambit", desc = "Win 10 games of Thirty-Six.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })