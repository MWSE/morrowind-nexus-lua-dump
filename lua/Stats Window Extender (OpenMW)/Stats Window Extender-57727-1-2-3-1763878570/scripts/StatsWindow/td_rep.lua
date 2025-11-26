local core = require('openmw.core')
local I = require('openmw.interfaces')

local l10n = core.l10n('StatsWindow')

local configPlayer = require('scripts.StatsWindow.config.player')

if configPlayer.modIntegration.b_EnableTDReputation then
    local projectTable = {
        {
            province = "Cyrodiil",
            name = l10n("TDRep_Cyrodiil"),
            installVar = "T_Glob_Installed_PC",
            repVar = "T_Glob_Rep_Cyr"
        },
        {
            province = "Hammerfell",
            name = l10n("TDRep_Hammerfell"),
            installVar = "T_Glob_Installed_Ham",
            repVar = "T_Glob_Rep_Ham"
        },
        {
            province = "High Rock",
            name = l10n("TDRep_HighRock"),
            installVar = "T_Glob_Installed_HR427",
            repVar = "T_Glob_Rep_Hr"
        },
        {
            province = "Morrowind",
            name = l10n("TDRep_Morrowind"),
            installVar = "",
            repVar = "SW_PCRep"
        },
        {
            province = "Padomaic Isles",
            name = l10n("TDRep_PadomaicIsles"),
            installVar = "T_Glob_Installed_PI",
            repVar = "T_Glob_Rep_PI"
        },
        {
            province = "Skyrim",
            name = l10n("TDRep_Skyrim"),
            installVar = "T_Glob_Installed_SHotN",
            repVar = "T_Glob_Rep_Sky"
        }
    }

    local trackedStats = {}

    for _, project in ipairs(projectTable) do
        if project.installVar ~= "" then
            I.StatsWindow.trackGlobalVariable(project.installVar)
            trackedStats[project.installVar] = true
        end
        if project.repVar ~= "" then
            I.StatsWindow.trackGlobalVariable(project.repVar)
            trackedStats[project.repVar] = true
        end
    end

    local C = I.StatsWindow.Constants

    I.StatsWindow.modifySection(C.DefaultSections.REPUTATION, {
        trackedStats = trackedStats,
        builder = function()
            for _, project in ipairs(projectTable) do
                if project.province == "Morrowind" or (I.StatsWindow.getStat(project.installVar) and I.StatsWindow.getStat(project.installVar) > 0) then
                    if I.StatsWindow.getStat(project.repVar) and I.StatsWindow.getStat(project.repVar) ~= 0 then
                        I.StatsWindow.addLineToSection(project.repVar, C.DefaultSections.REPUTATION, {
                            label = project.name,
                            value = function()
                                local repValue = I.StatsWindow.getStat(project.repVar) or 0
                                return { string = tostring(repValue) }
                            end,
                            tooltip = function()
                                return I.StatsWindow.TooltipBuilders.TEXT({ text = string.format(l10n("TDRep_Tooltip"), project.name) })
                            end,
                        })
                    end
                end
            end
        end,
        header = l10n("TDRep_Title"),
        indent = true,
        divider = {
            before = true,
            after = true,
        }
    })
end