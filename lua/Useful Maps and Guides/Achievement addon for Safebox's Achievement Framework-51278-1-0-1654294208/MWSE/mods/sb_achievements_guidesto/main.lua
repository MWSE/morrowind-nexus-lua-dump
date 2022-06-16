local sb_achievements = include("sb_achievements.interop")

local function initializedCallback(e)
    local cat = sb_achievements.registerCategory("Guides To Morrowind")

    sb_achievements.registerAchievement {
        id        = "sb_guidesto",
        category  = cat,
        condition = function()
            return tes3.getItemCount { item = "bk_guide_to_ald_ruhn", reference = tes3.player } > 0 and
                tes3.getItemCount { item = "bk_guide_to_balmora", reference = tes3.player } > 0 and
                tes3.getItemCount { item = "bk_guide_to_sadrithmora", reference = tes3.player } > 0 and
                tes3.getItemCount { item = "bk_guide_to_vivec", reference = tes3.player } > 0 and
                tes3.getItemCount { item = "bk_guide_to_vvardenfell", reference = tes3.player } > 0
        end,
        icon      = "Icons\\sb_guidesto\\icn_GuidesTo.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "Practically Local",
        desc      = "Find a copy of each scroll in the Guide To Morrowind series.",
        hideDesc  = true
    }
end

if (sb_achievements) then
    event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
end
