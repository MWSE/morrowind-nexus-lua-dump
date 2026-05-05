local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')

local l10n = core.l10n('StatsWindow')

local configPlayer = require('scripts.StatsWindow.config.player')

if configPlayer.modIntegration.b_EnableTDFactions then
    local provinceTable = {
        {
            id = "t_cyr",
            name = l10n("TDRep_Cyrodiil")
        },
        {
            id = "t_ham",
            name = l10n("TDRep_Hammerfell")
        },
        {
            id = "t_hr",
            name = l10n("TDRep_HighRock")
        },
        {
            id = "t_mw",
            name = l10n("TDRep_Morrowind")
        },
        {
            id = "t_pi",
            name = l10n("TDRep_PadomaicIsles")
        },
        {
            id = "t_sky",
            name = l10n("TDRep_Skyrim")
        }
    }

    local function getFactionsByProvince(factions)
        local factionsByProvince = {}
        for _, factionId in ipairs(factions) do
            local factionRecord = core.factions.records[factionId]
            if not factionRecord.hidden then
                local provinceFound = false
                for _, province in ipairs(provinceTable) do
                    if factionId:find(province.id) then
                        factionsByProvince[province.name] = factionsByProvince[province.name] or {}
                        table.insert(factionsByProvince[province.name], factionId)
                        provinceFound = true
                        break
                    end
                end
                if not provinceFound then
                    factionsByProvince[l10n("TDRep_Morrowind")] = factionsByProvince[l10n("TDRep_Morrowind")] or {}
                    table.insert(factionsByProvince[l10n("TDRep_Morrowind")], factionId)
                end
            end
        end
        return factionsByProvince
    end

    local C = I.StatsWindow.Constants

    I.StatsWindow.modifySection(C.DefaultSections.FACTION, {
        header = l10n("TDFactions_Title"),
        builder = function()
            local factions = I.StatsWindow.getStat(C.TrackedStats.FACTIONS)
            local factionsByProvince = getFactionsByProvince(factions)

            -- Check if we only have factions in Morrowind
            local hasNonMorrowindProvince = false
            for _, province in ipairs(provinceTable) do
                if province.name ~= l10n("TDRep_Morrowind") and factionsByProvince[province.name] and #factionsByProvince[province.name] > 0 then
                    hasNonMorrowindProvince = true
                    break
                end
            end

            if not hasNonMorrowindProvince then
                -- Only Morrowind factions, add directly to the main section
                local morrowindFactions = factionsByProvince[l10n("TDRep_Morrowind")]
                if morrowindFactions then
                    for _, factionId in ipairs(morrowindFactions) do
                        local line = I.StatsWindow.LineBuilders.FACTION(factionId)
                        I.StatsWindow.addLineToSection(factionId, C.DefaultSections.FACTION, line)
                    end
                end
            else
                -- Create subsections for each province
                for _, province in ipairs(provinceTable) do
                    local provinceFactions = factionsByProvince[province.name]
                    if provinceFactions and #provinceFactions > 0 then
                        I.StatsWindow.addSectionToSection('TDFactions_' .. province.id, C.DefaultSections.FACTION, {
                            header = province.name,
                            indent = true,
                        })
                        for _, factionId in ipairs(provinceFactions) do
                            local line = I.StatsWindow.LineBuilders.FACTION(factionId)
                            line.label = line.label:gsub(province.name, "")
                            line.label = line.label:gsub("^%s+", "")
                            line.label = line.label:gsub("%s+$", "")
                            I.StatsWindow.addLineToSection(factionId, 'TDFactions_' .. province.id, line)
                        end
                    end
                end
            end
        end
    })
end