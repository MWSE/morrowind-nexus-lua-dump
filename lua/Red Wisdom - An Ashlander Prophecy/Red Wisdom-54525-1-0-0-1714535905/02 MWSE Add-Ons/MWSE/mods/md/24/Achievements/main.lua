local sb_achievements = require("sb_achievements.interop")

local function init()
    local iconPath = "Icons\\md24\\q\\"

    local cats = {
        main = sb_achievements.registerCategory("Main Quest"),
        side = sb_achievements.registerCategory("Side"),
        misc = sb_achievements.registerCategory("Miscellaneous")
    }

    sb_achievements.registerAchievement {
        id = "md24_elements",
        category = cats.side,
        condition = function()
            return (tes3.getItemCount({ reference = "player", item = "md24_c_AshbaneGirdle" }) +
            tes3.getItemCount({ reference = "player", item = "md24_c_StoneOfGrounding" }) +
            tes3.getItemCount({ reference = "player", item = "md24_c_TheTwelfthTalisman" }) +
            tes3.getItemCount({ reference = "player", item = "md24_c_TheWhirlingband" })) > 3
        end,
        icon = iconPath .. "achievement_elements.tga",
        colour = sb_achievements.colours.red,
        title = "Tribal Elements", desc = "Collect all four of the elemental Ashlander trinkets."
    }

end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
