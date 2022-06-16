local sb_achievements = include("sb_achievements.interop")

local function initializedCallback(e)
    local cat = sb_achievements.registerCategory("Dwemer Cycle")

    sb_achievements.registerAchievement {
        id        = "sb_dwemercycle",
        category  = cat,
        condition = function()
            return tes3.getItemCount { item = "sb_dwemer_helm", reference = tes3.player } > 0
        end,
        icon      = "Icons\\sb_dwemercycle\\icn_achievement.tga",
        colour    = { 0, 1, 1 },
        title     = "The Nerevar's Ballad",
        desc      = "Find the Dwemer Cycle helmet in the valley south of Bthuand."
    }
end

if (sb_achievements) then
    event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
end