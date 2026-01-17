local sb_achievements = include("sb_achievements.interop")

if sb_achievements == nil then
    return
end

local iconPath = "Icons\\mdww\\v\\"

local cats = {
    whitewave = sb_achievements.registerCategory("The Search for the White Wave")
}

sb_achievements.registerAchievement {
    id = "mdww_raven",
    category = cats.whitewave,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("mdWW_RavenTracker")
    end,
    progressMax = function()
        return 3
    end,
    icon = iconPath .. "achievement_raven.tga",
    colour = sb_achievements.colours.blue,
    title = "Unkind to Ravens", desc = "Scare away 3 ravens."
}

sb_achievements.registerAchievement {
    id = "mdww_cleaver",
    category = cats.whitewave,
    conditionType = sb_achievements.conditionType.instant,
    condition = function()
        return tes3.getGlobal("mdWW_CleaverTracker") == 1
    end,
    icon = iconPath .. "achievement_cleaver.tga",
    colour = sb_achievements.colours.blue,
    title = "What Lies Beneath", desc = "Find the Cleaver of Skarveth.",
    configDesc = sb_achievements.configDesc.hideDesc,
    lockedDesc = sb_achievements.lockedMessage.psHidden
}