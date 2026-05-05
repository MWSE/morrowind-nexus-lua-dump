local core = require('openmw.core')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local omwself = require('openmw.self')
local async = require('openmw.async')
local storage = require('openmw.storage')
local input = require('openmw.input')

local templates = require('scripts.StatsWindow.ui.templates.stats')

local constants = require('scripts.StatsWindow.util.constants')
local helpers = require('scripts.StatsWindow.util.helpers')

local configPlayer = require('scripts.StatsWindow.config.player')

local staticUiMode = 'Jail'
local lastStaticMode = false

local storedScrollPos = {}

local function canShow()
    return not not I.UI.getWindowsForMode('Interface')['Stats']
end

local function isControllerMenus()
    return I.GamepadControls.isControllerMenusEnabled and I.GamepadControls.isControllerMenusEnabled()
end

local statsWindow = {}

statsWindow.stats = {
    rep = 0,
    sign = nil,
    factions = nil,
}

statsWindow.panes = {}

statsWindow.element = nil

statsWindow.needsRedraw = false

statsWindow.staticMode = false

statsWindow.isVisible = function()
    return templates.active and statsWindow.element and statsWindow.element.layout.props.visible ~= false
end

statsWindow.isPinned = function()
    return not isControllerMenus() and not statsWindow.staticMode and statsWindow.element and statsWindow.element.layout.userData.pinnable and statsWindow.element.layout.userData.pinned
end

statsWindow.destroy = function()
    templates.active = false
    if statsWindow.element then
        auxUi.deepDestroy(statsWindow.element)
        statsWindow.element = nil
    end
    if templates.activeTooltip then
        templates.activeTooltip:destroy()
        templates.activeTooltip = nil
    end
end

statsWindow.create = function()
    statsWindow.destroy()
    templates.active = true
    statsWindow.element = ui.create{}
    statsWindow.init()
end

statsWindow.update = function()
    if not statsWindow.element then
        return
    end
    local _, visChanged = templates.updateStatsWindow(statsWindow.element.layout)
    if visChanged then
        statsWindow.needsRedraw = true
    end
    auxUi.deepUpdate(statsWindow.element)
end

local function saveWindowState()
    if statsWindow.staticMode or not statsWindow.element or not statsWindow.element.layout then
        return
    end
    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
    storage.playerSection('Settings/StatsWindow/2_WindowOptions'):set('d_StatsDimensions', {
        x = helpers.roundToPlaces(statsWindow.element.layout.props.position.x / layerSize.x, 6),
        y = helpers.roundToPlaces(statsWindow.element.layout.props.position.y / layerSize.y, 6),
        w = helpers.roundToPlaces(statsWindow.element.layout.props.size.x / layerSize.x, 6),
        h = helpers.roundToPlaces(statsWindow.element.layout.props.size.y / layerSize.y, 6),
    })
    if statsWindow.element.layout.userData.pinnable then
        storage.playerSection('Settings/StatsWindow/2_WindowOptions'):set('b_StatsPinned', statsWindow.element.layout.userData.pinned or false)
    end
end

local setSize = function()
    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
    
    if not statsWindow.staticMode then
        local dims = storage.playerSection('Settings/StatsWindow/2_WindowOptions'):get('d_StatsDimensions')
        local windowPos = util.vector2(dims.x * layerSize.x, dims.y * layerSize.y)
        local windowSize = util.vector2(dims.w * layerSize.x, dims.h * layerSize.y)
        statsWindow.element.layout.props.position = windowPos
        statsWindow.element.layout.props.size = windowSize
    else
        statsWindow.element.layout.props.anchor = util.vector2(0.5, 0.5)
        statsWindow.element.layout.props.relativePosition = util.vector2(0.5, 0.5)
        statsWindow.element.layout.props.size = util.vector2(600, layerSize.y-96)
        statsWindow.element.layout.props.position = util.vector2(0, 0)
    end
end

statsWindow.init = function()
    if not statsWindow.element then
        return
    end

    statsWindow.element = templates.statsWindow(statsWindow.panes, statsWindow.staticMode, storedScrollPos)

    setSize()

    statsWindow.update()
end

statsWindow.show = function(staticMode)
    if not canShow() then return end

    local wasVisible = statsWindow.isVisible()

    statsWindow.staticMode = isControllerMenus() or staticMode
    if statsWindow.staticMode then
        I.UI.setMode(staticUiMode, {windows = {}}) -- stand-in mode to show cursor
    end

    templates.active = true
    statsWindow.updateTrackedStats()
    if not statsWindow.element or lastStaticMode ~= statsWindow.staticMode then
        lastStaticMode = statsWindow.staticMode
        statsWindow.create()
    end

    setSize()
    statsWindow.element.layout.props.visible = true
    statsWindow.update()

    statsWindow.element.layout.userData.setPinnable(not staticMode)

    if not wasVisible then
        omwself:sendEvent(constants.Events.WINDOW_SHOWN)
    end
end

statsWindow.hide = function(force)
    if not statsWindow.isVisible() then return end

    statsWindow.staticMode = statsWindow.staticMode or isControllerMenus()

    if not statsWindow.isPinned() or force then
        templates.active = false
        if statsWindow.element then
            statsWindow.element.layout.props.visible = false
            statsWindow.element:update()
        end
        omwself:sendEvent(constants.Events.WINDOW_HIDDEN)
    end
    if templates.activeTooltip then
        templates.activeTooltip:destroy()
        templates.activeTooltip = nil
    end
    saveWindowState()
    if statsWindow.staticMode then
        I.UI.removeMode(staticUiMode)
    end
    statsWindow.staticMode = false
end

statsWindow.toggle = function(staticMode)
    if statsWindow.isVisible() and not statsWindow.isPinned() then
        statsWindow.hide(true)
    elseif I.UI.getMode() == nil then
        statsWindow.show(staticMode)
    end
end

statsWindow.onUiModeChanged = function(oldMode, newMode)
    if statsWindow.element then
        statsWindow.element.layout.userData.setPinned(configPlayer.window.b_StatsPinned)
    end
    local statsWindowMode = statsWindow.staticMode and staticUiMode or 'Interface'
    if statsWindow.isPinned() and not statsWindow.staticMode then
        if newMode == nil or newMode == 'Interface' then
            statsWindow.show()
        else
            statsWindow.hide(true)
        end
    elseif newMode ~= statsWindowMode then
        statsWindow.hide(true)
    end
end

statsWindow.onMouseWheel = function(v, h)
    if statsWindow.element and statsWindow.element.layout and templates.focusedScrollable and templates.focusedScrollable.layout then
        local layout = templates.focusedScrollable.layout
        local pos = layout.content[1].props.position
        layout.content[1].props.position = util.vector2(
            pos.x,
            util.clamp(pos.y + v * layout.userData.scrollStep, -layout.userData.scrollLimit, 0)
        )
        layout.userData.onScroll()
    end
end

local updateInt = 0.5
local updateTimer = 0

local trackedStats = {}
local lastTrackedStats = {}

statsWindow.trackStat = function(statId, getter)
    trackedStats[statId] = getter
end

statsWindow.untrackStat = function(statId)
    trackedStats[statId] = nil
end

statsWindow.updateTrackedStats = function()
    local changedStats = {}
    local anyChanged = false

    for statId, getter in pairs(trackedStats) do
        local newValue = getter(omwself)
        if not helpers.tableEquals(newValue, lastTrackedStats[statId]) then
            statsWindow.stats[statId] = newValue
            lastTrackedStats[statId] = helpers.deepCopy(newValue)
            changedStats[statId] = true
            anyChanged = true
        end
    end

    if anyChanged then
        local sectionsToUpdate = {}

        local function collectSections(sections)
            for _, section in pairs(sections or {}) do
                local update = false
                if section.trackedStats and section.builder then
                    for statId, _ in pairs(changedStats) do
                        if section.trackedStats[statId] then
                            update = true
                            break
                        end
                    end
                end

                if update then
                    table.insert(sectionsToUpdate, section)
                elseif section.sections then
                    collectSections(section.sections)
                end
            end
        end

        for _, pane in pairs(statsWindow.panes) do
            for _, box in pairs(pane) do
                collectSections(box.sections)
            end
        end

        for _, section in ipairs(sectionsToUpdate) do
            section.lines = {}
            section.sections = {}
        end

        for _, section in ipairs(sectionsToUpdate) do
            section.builder()
        end

        statsWindow.needsRedraw = true
    end
end

statsWindow.onFrame = function()
    for _, el in ipairs(templates.updateQueue) do
        el:update()
    end
    templates.updateQueue = {}

    local dt = core.getRealFrameDuration()

    if templates.active then
        if not canShow() then
            statsWindow.hide(true)
            return
        end

        if templates.focusedScrollable and templates.focusedScrollable.layout then
            local rightStick = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
            if math.abs(rightStick) > 0.2 then
                local layout = templates.focusedScrollable.layout
                local pos = layout.content[1].props.position
                layout.content[1].props.position = util.vector2(
                    pos.x,
                    util.clamp(pos.y - rightStick * layout.userData.scrollStep / 4 * dt * 60, -layout.userData.scrollLimit, 0)
                )
                layout.userData.onScroll()
            end

            storedScrollPos[templates.focusedScrollable.layout.name] = templates.focusedScrollable.layout.content[1].props.position.y
        end

        statsWindow.updateTrackedStats()

        if statsWindow.needsRedraw then
            statsWindow.create()
            statsWindow.update()
            statsWindow.needsRedraw = false
        else
            if updateTimer >= updateInt then
                local valChanged, visChanged = templates.updateStatsWindow(statsWindow.element.layout)
                if visChanged then
                    statsWindow.needsRedraw = true
                end
                if valChanged then
                    auxUi.deepUpdate(statsWindow.element)
                end
                updateTimer = 0
            else
                updateTimer = updateTimer + dt
            end
        end
    end
end

-- Section management functions

function statsWindow.getPane(paneId)
    return statsWindow.panes[paneId]
end

function statsWindow.getBox(boxId)
    for paneId, pane in pairs(statsWindow.panes) do
        for _, box in ipairs(pane) do
            if box.id == boxId then
                return box, paneId
            end
        end
    end
end

function statsWindow.getSection(sectionId)
    local function getSubsection(section, id)
        if section.sections then
            for _, subSection in ipairs(section.sections) do
                if subSection.id == id then
                    return subSection
                end
                local found = getSubsection(subSection, id)
                if found then
                    return found
                end
            end
        end
    end

    for paneId, pane in pairs(statsWindow.panes) do
        for _, box in ipairs(pane) do
            local found = getSubsection(box, sectionId)
            if found then
                return found, box, paneId
            end
        end
    end
end

function statsWindow.getLine(lineId)
    local function findLineInSections(sections, id)
        if not sections then return nil end
        for _, section in ipairs(sections) do
            if section.lines then
                for _, line in ipairs(section.lines) do
                    if line.id == id then
                        return line, section
                    end
                end
            end
            local found, foundSection = findLineInSections(section.sections, id)
            if found then
                return found, foundSection
            end
        end
    end

    for paneId, pane in pairs(statsWindow.panes) do
        for _, box in ipairs(pane) do
            local found, section = findLineInSections(box.sections, lineId)
            if found then
                return found, section, box, paneId
            end
        end
    end
end

function statsWindow.addBoxToPane(boxId, paneId, params)
    if not boxId or not paneId then return false end
    local existingBox, existingPaneId = statsWindow.getBox(boxId)
    if existingBox then
        print('Box', boxId, 'already exists in pane', existingPaneId)
        return false
    end

    params.id = boxId

    statsWindow.panes[paneId] = statsWindow.panes[paneId] or {}
    table.insert(statsWindow.panes[paneId], params)
    statsWindow.needsRedraw = true
    return true
end

function statsWindow.addSectionToBox(sectionId, boxId, params)
    if not sectionId or not boxId then return false end
    local existingSection, existingBox, existingPaneId = statsWindow.getSection(sectionId)
    if existingSection then
        print('Section', sectionId, 'already exists in box', existingBox.id, 'in pane', existingPaneId)
        return false
    end

    params.id = sectionId

    local box = statsWindow.getBox(boxId)
    if not box then
        print('Box', boxId, 'not found for new section', sectionId)
        return false
    end

    box.sections = box.sections or {}
    table.insert(box.sections, params)
    statsWindow.needsRedraw = true
    return true
end

function statsWindow.addSectionToSection(sectionId, parentSectionId, params)
    if not sectionId or not parentSectionId then return false end
    local existingSection, existingBox, existingPaneId = statsWindow.getSection(sectionId)
    if existingSection then
        print('Section', sectionId, 'already exists in box', existingBox.id, 'in pane', existingPaneId)
        return false
    end

    params.id = sectionId

    local parentSection = statsWindow.getSection(parentSectionId)
    if not parentSection then
        print('Parent section', parentSectionId, 'not found for new section', sectionId)
        return false
    end
        
    parentSection.sections = parentSection.sections or {}
    table.insert(parentSection.sections, params)
    statsWindow.needsRedraw = true
    return true
end

function statsWindow.addLineToSection(lineId, sectionId, params)
    if not lineId or not sectionId then return false end
    local existingLine, existingSection, existingBox, existingPaneId = statsWindow.getLine(lineId)
    if existingLine then
        print('Line', lineId, 'already exists in section', existingSection.id, 'in box', existingBox.id, 'in pane', existingPaneId)
        return false
    end

    params.id = lineId

    local section = statsWindow.getSection(sectionId)
    if not section then
        print('Section', sectionId, 'not found for new line', lineId)
        return false
    end

    section.lines = section.lines or {}
    table.insert(section.lines, params)
    statsWindow.needsRedraw = true
    return true
end

local function mergeParams(original, new)
    for k, v in pairs(new) do
        if v == constants.NIL then
            original[k] = nil
        else
            original[k] = v
        end
    end
end

function statsWindow.moveSectionToBox(sectionId, boxId)
    if not sectionId or not boxId then return false end
    local section, existingBox = statsWindow.getSection(sectionId)
    if not section then
        print('Section', sectionId, 'not found for moving to box', boxId)
        return false
    end

    local box = statsWindow.getBox(boxId)
    if not box then
        print('Target box', boxId, 'not found for moving section', sectionId)
        return false
    end

    -- Remove from existing location
    if existingBox then
        local function removeSection(sections, id)
            if sections then
                for i, section in ipairs(sections) do
                    if section.id == id then
                        table.remove(sections, i)
                        return true
                    elseif section.sections then
                        local removed = removeSection(section.sections, id)
                        if removed then
                            return true
                        end
                    end
                end
            end
        end

        removeSection(existingBox.sections, sectionId)
    end

    -- Add to new box
    box.sections = box.sections or {}
    table.insert(box.sections, section)
    statsWindow.needsRedraw = true
    return true
end

function statsWindow.modifyBox(boxId, params)
    local box = statsWindow.getBox(boxId)
    if not box then
        print('Box', boxId, 'not found for modification')
        return false
    end
    mergeParams(box, params)
    statsWindow.needsRedraw = true
    return true
end

function statsWindow.modifySection(sectionId, params)
    local section = statsWindow.getSection(sectionId)
    if not section then
        print('Section', sectionId, 'not found for modification')
        return false
    end
    mergeParams(section, params)
    statsWindow.needsRedraw = true
    return true
end

function statsWindow.modifyLine(lineId, params)
    local line = statsWindow.getLine(lineId)
    if not line then
        print('Line', lineId, 'not found for modification')
        return false
    end
    mergeParams(line, params)
    statsWindow.needsRedraw = true
    return true
end

return statsWindow