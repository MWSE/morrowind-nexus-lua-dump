local sb_achievements = include("sb_achievements.interop")

local function init()
    local iconPath = "Icons\\Narangren\\"

    local cat = sb_achievements.registerCategory("Offerings")

    sb_achievements.registerAchievement {
        id = "Nar_Ithelia",
        category = cat,
        condition = function()
           	  return tes3.getJournalIndex { id = "Nar_ItheliaBless" } >= 1
        end,
        icon = iconPath .. "altar.tga",
        title = "Blessed by the Lost", desc = "Accept the blessing of a long-lost Daedric Prince.",
        configDesc = sb_achievements.configDesc.hideDesc,
        lockedDesc = sb_achievements.lockedMessage.psHidden
    }
end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })