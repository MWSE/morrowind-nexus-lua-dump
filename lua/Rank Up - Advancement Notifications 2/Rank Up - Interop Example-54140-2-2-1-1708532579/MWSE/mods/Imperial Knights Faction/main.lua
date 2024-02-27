local function init()
    if require("RankUp_AdvancementNotifications.interop") then
        AddRankUpFaction("Imperial Knights", "Imperial Knights.", "Icons\\Rank Up - Advancement Notifications\\Imperial_Legion_Icon.dds", "Icons\\SSQN\\IL.dds")
        -- Explanations on what exact strings to pass to the function are in the interop.lua
        mwse.log("Imperial Knights Rank Up! Interop function successful.")
    else
        mwse.log("Imperial Knights Rank Up! Interop function has failed. The necessary Rank Up! files aren't present.")
    end
end

event.register(tes3.event.initialized, init, {priority = -15}) -- IMPORTANT: Priority needs to be lower than -10, so it gets initialized AFTER Rank Up!.