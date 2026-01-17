local core = require('openmw.core')
local self = require('openmw.self')
local util = require('openmw.util')
local ui = require('openmw.ui')

local helpers = require('scripts.StatsWindow.util.helpers')
local constants = require('scripts.StatsWindow.util.constants')

local statsWindow = require('scripts.StatsWindow.ui.statsWindow')

local receivedGlobals = {}

local API = {}

API.VERSION = 1

API.Constants = constants

API.Templates = {
    BASE = require('scripts.StatsWindow.ui.templates.base'),
    STATS = require('scripts.StatsWindow.ui.templates.stats'),
}

API.TooltipBuilders = {
    TEXT = function(params)
        return API.Templates.STATS.tooltip(4, ui.content {
            {
                template = API.Templates.BASE.textParagraph,
                props = {
                    size = util.vector2(params.width or 300, 0),
                    text = params.text or '',
                    autoSize = true,
                }
            }
        })
    end,
    HEADER = function(title, description, subDescription)
        return API.Templates.STATS.headerTooltip(title, description, subDescription, title)
    end,
    ICON = function(params)
        return API.Templates.STATS.iconTooltip(params)
    end,
    SKILL = function(params)
        return API.Templates.STATS.skillTooltip(params)
    end,
    LEVEL = function()
        return API.Templates.STATS.levelTooltip()
    end,
    FACTION = function(record)
        return API.Templates.STATS.factionTooltip(record)
    end,
    BIRTHSIGN = function(record)
        return API.Templates.STATS.birthsignTooltip(record)
    end,
}

API.LineBuilders = {
    FACTION = function(factionId)
        local factionRecord = core.factions.record(factionId)
        return {
            label = factionRecord.name,
            tooltip = function()
                return API.TooltipBuilders.FACTION(factionRecord)
            end,
        }
    end,
    SKILL = function(skillId)
        local skillRecord = core.stats.Skill.records[skillId]
        return {
            label = skillRecord.name,
            labelColor = API.Constants.Colors.DEFAULT,
            value = function()
                local skillStat = self.type.stats.skills[skillId](self)
                local color
                if skillStat.modified > skillStat.base then
                    color = API.Constants.Colors.POSITIVE
                elseif skillStat.modified < skillStat.base then
                    color = API.Constants.Colors.DAMAGED
                end
                return { string = tostring(math.floor(skillStat.modified)), color = color }
            end,
            tooltip = function()
                local skillStat = self.type.stats.skills[skillId](self)
                return API.TooltipBuilders.SKILL({
                    icon = {
                        bgr = skillRecord.icon,
                    },
                    title = skillRecord.name,
                    subtitle = API.Constants.Strings.GOVERNING_ATTRIBUTE .. ': ' .. core.stats.Attribute.records[skillRecord.attribute].name,
                    description = skillRecord.description,
                    currentValue = skillStat.base,
                    progress = skillStat.progress,
                    maxValue = 100,
                })
            end,
        }
    end,
}

function API.show(staticMode)
    statsWindow.show(staticMode)
end

function API.hide(force)
    statsWindow.hide(force)
end

function API.toggle(staticMode)
    statsWindow.toggle(staticMode)
end

function API.isVisible()
    return statsWindow.isVisible()
end

function API.isPinned()
    return statsWindow.isPinned()
end

function API.onFrame()
    statsWindow.onFrame()
end

function API.onMouseWheel(v, h)
    statsWindow.onMouseWheel(v, h)
end

function API.update()
    statsWindow.update()
end

function API.trackStat(statId, getter)
    statsWindow.trackStat(statId, getter)
end

function API.untrackStat(statId)
    statsWindow.untrackStat(statId)
end

function API.trackGlobalVariable(varName)
    core.sendGlobalEvent('SW_TrackGlobal', { var = varName, player = self})
    API.trackStat(varName, function()
        return receivedGlobals[varName]
    end)
end

function API.untrackGlobalVariable(varName)
    core.sendGlobalEvent('SW_UntrackGlobal', { var = varName, player = self})
    API.untrackStat(varName)
end

function API.setStat(statId, value)
    if not helpers.tableEquals(value, statsWindow.stats[statId]) then
        statsWindow.needsRedraw = true
    end
    statsWindow.stats[statId] = value
end

function API.getStat(statId)
    return statsWindow.stats[statId]
end

function API.addBoxToPane(boxId, paneId, params)
    statsWindow.addBoxToPane(boxId, paneId, params)
end

function API.addSectionToBox(sectionId, boxId, params)
    statsWindow.addSectionToBox(sectionId, boxId, params)
end

function API.addSectionToSection(sectionId, parentSectionId, params)
    statsWindow.addSectionToSection(sectionId, parentSectionId, params)
end

function API.addLineToSection(lineId, sectionId, params)
    statsWindow.addLineToSection(lineId, sectionId, params)
end

function API.moveSectionToBox(sectionId, boxId)
    statsWindow.moveSectionToBox(sectionId, boxId)
end

function API.modifyBox(boxId, params)
    statsWindow.modifyBox(boxId, params)
end

function API.modifySection(sectionId, params)
    statsWindow.modifySection(sectionId, params)
end

function API.modifyLine(lineId, params)
    statsWindow.modifyLine(lineId, params)
end

function API.overrideLineBuilder(type, newDef)
    API.LineBuilders[type] = newDef
end

function API.overrideTooltipBuilder(type, newDef)
    API.TooltipBuilders[type] = newDef
end

function API.setDirty()
    statsWindow.needsRedraw = true
end

function API.getPanes()
    return statsWindow.panes
end

function API.getPane(paneId)
    return statsWindow.getPane(paneId)
end

function API.getBox(boxId)
    local box, parentPaneId = statsWindow.getBox(boxId)
    return box, parentPaneId
end

function API.getSection(sectionId)
    local section, parentBox, parentPaneId = statsWindow.getSection(sectionId)
    return section, parentBox, parentPaneId
end

function API.getLine(lineId)
    local line, parentSection, parentBox, parentPaneId = statsWindow.getLine(lineId)
    return line, parentSection, parentBox, parentPaneId
end

function API.getWindowElement()
    return statsWindow.element
end

return {
    interfaceName = 'StatsWindow',
    interface = API,
    eventHandlers = {
        UiModeChanged = function(data)
            statsWindow.onUiModeChanged(data.oldMode, data.newMode)
        end,
        SW_GlobalChanged = function(data)
            receivedGlobals[data.var] = data.newValue
        end,
    },
}