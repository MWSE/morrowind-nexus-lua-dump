local I = require('openmw.interfaces')
local self = require('openmw.self')
local core = require('openmw.core')
local input = require('openmw.input')
local async = require('openmw.async')
local storage = require('openmw.storage')
local ui = require('openmw.ui')

local util = require('openmw.util')
local v2 = util.vector2

local API = I.StatsWindow

local configPlayer = require('scripts.StatsWindow.config.player')

local function init()
    if not I.GamepadControls.isControllerMenusEnabled or not I.GamepadControls.isControllerMenusEnabled() then
        if configPlayer.window.b_ReplaceVanillaWindow then
            I.UI.registerWindow('Stats', API.show, API.hide)
        end
    elseif configPlayer.misc.b_ShowControllerWarning then
        storage.playerSection('Settings/StatsWindow/5_Misc'):set('b_ShowControllerWarning', false)
        local msg = 'NOTICE:\nStats Window Extender\'s window replacer is not compatible with controller menus. You will need to bind a button in the script settings to toggle the extended window manually.\nThis message will only appear once.'
        if I.UI.showInteractiveMessage then -- OpenMW 0.50+
            I.UI.showInteractiveMessage(msg, {})
        else
            ui.showMessage(msg)
        end
    end
    local actionCallback = async:callback(function(e)
        if e then
            I.StatsWindow.toggle(true)
        end
    end)
    input.registerActionHandler('SW_ToggleStatsWindow1', actionCallback)
    input.registerActionHandler('SW_ToggleStatsWindow2', actionCallback)
end

local C = API.Constants

-- Default boxes
API.addBoxToPane(C.DefaultBoxes.HEALTH_BOX, C.Panes.LEFT, {
    placement = {
        type = C.Placement.TOP,
        -- priority = 100 unless specified
    },
})

API.addBoxToPane(C.DefaultBoxes.LEVEL_BOX, C.Panes.LEFT, {
    placement = {
        type = C.Placement.AFTER,
        target = C.DefaultBoxes.HEALTH_BOX,
    },
})

API.addBoxToPane(C.DefaultBoxes.ATTRIBUTES_BOX, C.Panes.LEFT, {
    placement = {
        type = C.Placement.AFTER,
        target = C.DefaultBoxes.LEVEL_BOX,
    },
})

API.addBoxToPane(C.DefaultBoxes.RIGHT_SCROLL_BOX, C.Panes.RIGHT, {
    placement = {
        type = C.Placement.TOP,
    },
})

-- Default sections

API.addSectionToBox(C.DefaultSections.HEALTH_STATS, C.DefaultBoxes.HEALTH_BOX, {
})

API.addSectionToBox(C.DefaultSections.LEVEL_STATS, C.DefaultBoxes.LEVEL_BOX, {
})

API.addSectionToBox(C.DefaultSections.ATTRIBUTES, C.DefaultBoxes.ATTRIBUTES_BOX, {
})

API.addSectionToBox(C.DefaultSections.MAJOR_SKILLS, C.DefaultBoxes.RIGHT_SCROLL_BOX, {
    header = C.Strings.MAJOR_SKILLS,
    indent = true,
})

API.addSectionToBox(C.DefaultSections.MINOR_SKILLS, C.DefaultBoxes.RIGHT_SCROLL_BOX, {
    header = C.Strings.MINOR_SKILLS,
    indent = true,
})

API.addSectionToBox(C.DefaultSections.MISC_SKILLS, C.DefaultBoxes.RIGHT_SCROLL_BOX, {
    header = C.Strings.MISC_SKILLS,
    indent = true,
})

API.addSectionToBox(C.DefaultSections.FACTION, C.DefaultBoxes.RIGHT_SCROLL_BOX, {
    header = C.Strings.FACTION,
    indent = true,
})

API.addSectionToBox(C.DefaultSections.BIRTHSIGN, C.DefaultBoxes.RIGHT_SCROLL_BOX, {
    header = C.Strings.BIRTH_SIGN,
    indent = true,
})

API.addSectionToBox(C.DefaultSections.REPUTATION, C.DefaultBoxes.RIGHT_SCROLL_BOX, {
    indent = true,
    divider = {
        before = true,
        after = false,
    },
})

API.addSectionToBox(C.DefaultSections.BOUNTY, C.DefaultBoxes.RIGHT_SCROLL_BOX, {
    indent = true,
})

-- Default lines
local healthStats = {
    { id = C.DefaultLines.HEALTH, icon = 'icons/k/health.dds', color = C.Colors.BAR_HEALTH },
    { id = C.DefaultLines.MAGICKA, icon = 'icons/k/magicka.dds', color = C.Colors.BAR_MAGIC },
    { id = C.DefaultLines.FATIGUE, icon = 'icons/k/fatigue.dds', color = C.Colors.BAR_FATIGUE },
}

for _, stat in ipairs(healthStats) do
    API.addLineToSection(stat.id, C.DefaultSections.HEALTH_STATS, {
        type = C.LineType.PROGRESS_BAR,
        label = C.Strings[stat.id:upper()],
        labelColor = C.Colors.DEFAULT_LIGHT,
        value = function()
            local dynamicStat = self.type.stats.dynamic[stat.id](self)
            return {
                value = math.floor(dynamicStat.current),
                maxValue = math.floor(dynamicStat.base),
                color = stat.color,
                size = v2(130, API.Templates.STATS.LINE_HEIGHT),
            }
        end,
        tooltip = function()
            return API.TooltipBuilders.ICON({
                icon = {
                    bgr = stat.icon,
                },
                title = C.Strings[stat.id:upper()],
                description = C.Strings[stat.id:upper() .. '_DESC'],
            })
        end,
    })
end

API.addLineToSection(C.DefaultLines.LEVEL, C.DefaultSections.LEVEL_STATS, {
    label = C.Strings.LEVEL,
    labelColor = C.Colors.DEFAULT_LIGHT,
    value = function()
        return { string = tostring(self.type.stats.level(self).current) }
    end,
    tooltip = API.TooltipBuilders.LEVEL,
})

API.addLineToSection(C.DefaultLines.RACE, C.DefaultSections.LEVEL_STATS, {
    label = C.Strings.RACE,
    labelColor = C.Colors.DEFAULT_LIGHT,
    value = function()
        return { string = self.type.races.records[self.type.records[self.recordId].race].name }
    end,
    tooltip = function()
        local raceRecord = self.type.races.records[self.type.records[self.recordId].race]
        return API.TooltipBuilders.HEADER(raceRecord.name, raceRecord.description)
    end,
})

API.addLineToSection(C.DefaultLines.CLASS, C.DefaultSections.LEVEL_STATS, {
    label = C.Strings.CLASS,
    labelColor = C.Colors.DEFAULT_LIGHT,
    value = function()
        return { string = self.type.classes.records[API.getStat(C.TrackedStats.CLASS)].name }
    end,
    tooltip = function()
        local classRecord = self.type.classes.records[API.getStat(C.TrackedStats.CLASS)]
        local specString = C.Strings.SPEC .. ': ' .. C.Strings['SPEC_' .. classRecord.specialization:upper()]
        return API.TooltipBuilders.HEADER(classRecord.name, classRecord.description, specString)
    end,
})

for _, attr in ipairs(core.stats.Attribute.records) do
    API.addLineToSection(attr.id, C.DefaultSections.ATTRIBUTES, {
        label = attr.name,
        value = function()
            local attrStat = self.type.stats.attributes[attr.id](self)
            local color
            if attrStat.modified > attrStat.base then
                color = C.Colors.POSITIVE
            elseif attrStat.modified < attrStat.base then
                color = C.Colors.DAMAGED
            end
            return {
                string = tostring(math.floor(attrStat.modified)),
                color = color,
            }
        end,
        tooltip = function()
            return API.TooltipBuilders.ICON({
                icon = {
                    bgr = attr.icon,
                },
                title = attr.name,
                description = attr.description,
            })
        end,
    })
end

API.modifySection(C.DefaultSections.MAJOR_SKILLS, {
    trackedStats = { [C.TrackedStats.CLASS] = true },
    builder = function() -- When the tracked stat changes, the section's contents are cleared and builder is called
        local classRecord = self.type.classes.records[API.getStat(C.TrackedStats.CLASS)]
        for _, skillId in ipairs(classRecord.majorSkills) do
            API.addLineToSection(skillId, C.DefaultSections.MAJOR_SKILLS, API.LineBuilders.SKILL(skillId))
        end
    end,
})

API.modifySection(C.DefaultSections.MINOR_SKILLS, {
    trackedStats = { [C.TrackedStats.CLASS] = true },
    builder = function()
        local classRecord = self.type.classes.records[API.getStat(C.TrackedStats.CLASS)]
        for _, skillId in ipairs(classRecord.minorSkills) do
            API.addLineToSection(skillId, C.DefaultSections.MINOR_SKILLS, API.LineBuilders.SKILL(skillId))
        end
    end,
})

API.modifySection(C.DefaultSections.MISC_SKILLS, {
    trackedStats = { [C.TrackedStats.CLASS] = true },
    builder = function()
        local classRecord = self.type.classes.records[API.getStat(C.TrackedStats.CLASS)]
        local majorMinorSkills = {}
        for _, skillId in ipairs(classRecord.majorSkills) do
            majorMinorSkills[skillId] = true
        end
        for _, skillId in ipairs(classRecord.minorSkills) do
            majorMinorSkills[skillId] = true
        end
        for _, skillRecord in ipairs(core.stats.Skill.records) do
            if not majorMinorSkills[skillRecord.id] then
                API.addLineToSection(skillRecord.id, C.DefaultSections.MISC_SKILLS, API.LineBuilders.SKILL(skillRecord.id))
            end
        end
    end,
})

API.modifySection(C.DefaultSections.FACTION, {
    trackedStats = { [C.TrackedStats.FACTIONS] = true },
    builder = function()
        local factions = API.getStat(C.TrackedStats.FACTIONS)
        for _, factionId in ipairs(factions) do
            local factionRecord = core.factions.records[factionId]
            if not factionRecord.hidden then
                API.addLineToSection(factionRecord.id, C.DefaultSections.FACTION, API.LineBuilders.FACTION(factionRecord.id))
            end
        end
    end,
})

API.modifySection(C.DefaultSections.BIRTHSIGN, {
    trackedStats = { [C.TrackedStats.BIRTHSIGN] = true },
    builder = function()
        local signRecord = self.type.birthSigns.records[API.getStat(C.TrackedStats.BIRTHSIGN)]
        if signRecord then
            API.addLineToSection(signRecord.id, C.DefaultSections.BIRTHSIGN, {
                label = signRecord.name,
                tooltip = function()
                    return API.TooltipBuilders.BIRTHSIGN(signRecord)
                end,
            })
        end
    end,
})

API.addLineToSection(C.DefaultLines.REPUTATION, C.DefaultSections.REPUTATION, {
    label = C.Strings.REPUTATION,
    value = function()
        local rep = API.getStat(C.TrackedStats.REPUTATION) or 0
        return { string = tostring(rep) }
    end,
    tooltip = function()
        return API.TooltipBuilders.TEXT({ text = C.Strings.REPUTATION_DESC })
    end,
})

API.addLineToSection(C.DefaultLines.BOUNTY, C.DefaultSections.BOUNTY, {
    label = C.Strings.BOUNTY,
    value = function()
        local bounty = self.type.getCrimeLevel(self)
        return { string = tostring(bounty) }
    end,
    tooltip = function()
        return API.TooltipBuilders.TEXT({ text = C.Strings.BOUNTY_DESC })
    end,
})

API.trackStat(C.TrackedStats.BIRTHSIGN, function() return self.type.getBirthSign(self) end)
API.trackStat(C.TrackedStats.FACTIONS, self.type.getFactions)
API.trackStat(C.TrackedStats.CLASS, function() return self.type.records[self.recordId].class end)
API.trackGlobalVariable('SW_PCRep')

if configPlayer.tweaks.b_FactionAndRepOnLeft then
    API.addBoxToPane(C.DefaultBoxes.LEFT_FACTION_BOX, C.Panes.LEFT, {
        placement = {
            type = C.Placement.AFTER,
            target = C.DefaultBoxes.ATTRIBUTES_BOX,
        },
        maxHeightLines = configPlayer.tweaks.i_MaxFactionRepLines,
    })

    API.moveSectionToBox(C.DefaultSections.REPUTATION, C.DefaultBoxes.LEFT_FACTION_BOX)
    API.moveSectionToBox(C.DefaultSections.BOUNTY, C.DefaultBoxes.LEFT_FACTION_BOX)
    API.moveSectionToBox(C.DefaultSections.FACTION, C.DefaultBoxes.LEFT_FACTION_BOX)
end

if configPlayer.tweaks.b_RestyleBountyAndRep then
    API.modifySection(C.DefaultSections.REPUTATION, { indent = false, })
    API.modifySection(C.DefaultSections.BOUNTY, { indent = false, })
    API.modifyLine(C.DefaultLines.REPUTATION, { labelColor = C.Colors.DEFAULT_LIGHT, })
    API.modifyLine(C.DefaultLines.BOUNTY, { labelColor = C.Colors.DEFAULT_LIGHT, })
end

if configPlayer.tweaks.b_HideZeroBounty then
    API.modifyLine(C.DefaultLines.BOUNTY, {
        visibleFn = function()
            local bounty = self.type.getCrimeLevel(self)
            return bounty > 0
        end,
    })
end

if configPlayer.tweaks.b_BirthsignOnLeft then
    API.modifySection(C.DefaultSections.BIRTHSIGN, {
        visibleFn = function() return false end,
    })

    API.addLineToSection(C.DefaultSections.BIRTHSIGN, C.DefaultSections.LEVEL_STATS, {
        label = C.Strings.BIRTH_SIGN,
        labelColor = C.Colors.DEFAULT_LIGHT,
        value = function()
            local signRecord = self.type.birthSigns.records[API.getStat(C.TrackedStats.BIRTHSIGN)]
            return { string = signRecord and signRecord.name or '' }
        end,
        tooltip = function()
            local signRecord = self.type.birthSigns.records[API.getStat(C.TrackedStats.BIRTHSIGN)]
            if signRecord then
                return API.TooltipBuilders.BIRTHSIGN(signRecord)
            end
        end,
        visibleFn = function()
            local signRecord = self.type.birthSigns.records[API.getStat(C.TrackedStats.BIRTHSIGN)]
            return not not signRecord
        end,
    })
end

if configPlayer.tweaks.s_HouseNameDisplay ~= 'HouseNameDisplay_Full' or configPlayer.tweaks.b_ShowFactionRankInList ~= 'ShowFactionRankInList_Off' then
    local baseFn = API.LineBuilders.FACTION
    API.overrideLineBuilder('FACTION', function(factionId)
        local base = baseFn(factionId)
        local factionRecord = core.factions.record(factionId)
        if configPlayer.tweaks.s_HouseNameDisplay == 'HouseNameDisplay_Partial' then
            base.label = base.label:gsub('^Great House ', 'House ')
        elseif configPlayer.tweaks.s_HouseNameDisplay == 'HouseNameDisplay_Minimal' then
            base.label = base.label:gsub('^Great House ', ''):gsub('^House ', '')
        end
        if configPlayer.tweaks.b_ShowFactionRankInList ~= 'ShowFactionRankInList_Off' then
            local title = configPlayer.tweaks.b_ShowFactionRankInList == 'ShowFactionRankInList_Title'
            base.value = function()
                if self.type.isExpelled(self, factionId) then
                    return { string = title and API.Constants.Strings.EXPELLED or 'X', color = API.Constants.Colors.DAMAGED }
                else
                    local rank = self.type.getFactionRank(self, factionId)
                    return { string = title and (factionRecord.ranks[rank] and factionRecord.ranks[rank].name or '') or tostring(rank) }
                end
            end
        end
        return base
    end)
end

return {
    engineHandlers = {
        onInit = init,
        onLoad = init,
        onFrame = function()
            API.onFrame()
        end,
        onMouseWheel = function(v, h)
            API.onMouseWheel(v, h)
        end,
    },
}