require("RankUp_AdvancementNotifications.main")
require("RankUp_AdvancementNotifications.factionAndIconList")

function AddRankUpFaction(factionName, displayedFactionName, yourIconPath, yourIconPathSSQN)
    table.insert(GetFactionNames, factionName) -- The in-game name of the faction to be fetched via tes3.getFaction() e. g. "Fighters Guild"
    table.insert(FactionTableNames, displayedFactionName) -- The displayed faction name in the notification message (add a dot at the end) e. g. "Great House Telvanni."

    if tes3.isLuaModActive("SSQN") then -- Adds different icon depending on if SSQN is installed or not, so the styles and more importantly imagesizes align.
        table.insert(IconPaths, yourIconPathSSQN) -- The path to the faction icon (SSQN Style & Imagesize), just choose a SSQN default one if you don't want to make one yourself
                                                  -- or scale your own icon to the same size as a SSQN one (64x64).
    else
        table.insert(IconPaths, yourIconPath) -- The path to the faction icon (Rank Up! Style & Imagesize), just choose a Rank Up! default one if you don't want to make one yourself
                                              -- or scale your own icon to the same size as a Rank Up! one (512x512).
    end
end

return AddRankUpFaction