local sb_achievements = include("sb_achievements.interop")

local function init()
    local iconPath = "Icons\\Narangren\\"

    local cat = sb_achievements.registerCategory("Offerings")

    sb_achievements.registerAchievement {
        id = "Nar_Mephala",
        category = cat,
        condition = function()
           	  return tes3.getJournalIndex { id = "Nar_MephalaBless" } >= 1
        end,
        icon = iconPath .. "altar.tga",
        title = "Agent of Mephala", desc = "Accept Mephala's blessing in Vivec.",
        configDesc = sb_achievements.configDesc.hideDesc,
        lockedDesc = sb_achievements.lockedMessage.psHidden
    }

    sb_achievements.registerAchievement {
        id = "Nar_Bal",
        category = cat,
        condition = function()
            return tes3.getJournalIndex { id = "Nar_BalBless" } >= 1
        end,
        icon = iconPath .. "altar.tga",
        title = "Servant of Molag Bal", desc = "Accept Molag Bal's blessing in Bal Ur.",
        configDesc = sb_achievements.configDesc.hideDesc,
        lockedDesc = sb_achievements.lockedMessage.psHidden
    }

    sb_achievements.registerAchievement {
        id = "Nar_Mark",
        category = cat,
        condition = function()
            return tes3.getJournalIndex { id = "Nar_DaedraMark" } >= 1
        end,
        icon = iconPath .. "altar.tga",
        title = "Marked by the Daedra", desc = "Accept the Mark of the Daedra beneath Mournhold",
        configDesc = sb_achievements.configDesc.hideDesc,
        lockedDesc = sb_achievements.lockedMessage.psHidden
    }

    sb_achievements.registerAchievement {
        id = "Nar_NoMark",
        category = cat,
        condition = function()
            return tes3.getJournalIndex { id = "Nar_RemoveDaedraMark" } >= 1
        end,
        icon = iconPath .. "altar.tga",
        title = "Can I Have My Soul Back?", desc = "Remove the Mark of the Daedra beneath Mournhold",
        configDesc = sb_achievements.configDesc.hideDesc,
        lockedDesc = sb_achievements.lockedMessage.psHidden
    }
end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })