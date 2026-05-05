local core = require('openmw.core')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local omwself = require('openmw.self')
local async = require('openmw.async')
local storage = require('openmw.storage')
local input = require('openmw.input')

local templates = require('scripts.MagicWindowExtender.ui.templates.magic')

local constants = require('scripts.MagicWindowExtender.util.constants')
local helpers = require('scripts.MagicWindowExtender.util.helpers')

local configPlayer = require('scripts.MagicWindowExtender.config.player')

local staticUiMode = 'Jail'
local lastStaticMode = false

local storedScrollPos = {}

local function canShow()
    return not not I.UI.getWindowsForMode('Interface')['Magic']
end

local function isControllerMenus()
    return I.GamepadControls.isControllerMenusEnabled and I.GamepadControls.isControllerMenusEnabled()
end

local magicWindow = {}

magicWindow.stats = {}

magicWindow.panes = {}

magicWindow.element = nil

magicWindow.needsRedraw = false
magicWindow.needsRedrawDelayed = false

magicWindow.staticMode = false

magicWindow.isVisible = function()
    return templates.active and magicWindow.element and magicWindow.element.layout.props.visible ~= false
end

magicWindow.isPinned = function()
    return not isControllerMenus() and not magicWindow.staticMode and magicWindow.element and magicWindow.element.layout.userData.pinnable and magicWindow.element.layout.userData.pinned
end

magicWindow.destroy = function()
    templates.active = false
    if magicWindow.element then
        auxUi.deepDestroy(magicWindow.element)
        magicWindow.element = nil
    end
    if templates.activeTooltip then
        auxUi.deepDestroy(templates.activeTooltip)
        templates.activeTooltip = nil
    end
end

magicWindow.create = function()
    magicWindow.destroy()
    templates.active = true
    magicWindow.element = ui.create{}
    magicWindow.init()
end

magicWindow.update = function(updateValues)
    if not magicWindow.element then
        return
    end
    magicWindow.updateTrackedStats()
    local _, visChanged = templates.updateMagicWindow(magicWindow.element.layout, updateValues)
    if visChanged then
        magicWindow.needsRedraw = true
    end
    magicWindow.element:update()
    --auxUi.deepUpdate(magicWindow.element)
end

local function saveWindowState()
    if magicWindow.staticMode or not magicWindow.element or not magicWindow.element.layout then
        return
    end
    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
    storage.playerSection('Settings/MagicWindowExtender/2_WindowOptions'):set('d_MagicWindowDimensions', {
        x = helpers.roundToPlaces(magicWindow.element.layout.props.position.x / layerSize.x, 6),
        y = helpers.roundToPlaces(magicWindow.element.layout.props.position.y / layerSize.y, 6),
        w = helpers.roundToPlaces(magicWindow.element.layout.props.size.x / layerSize.x, 6),
        h = helpers.roundToPlaces(magicWindow.element.layout.props.size.y / layerSize.y, 6),
    })
    if magicWindow.element.layout.userData.pinnable then
        storage.playerSection('Settings/MagicWindowExtender/2_WindowOptions'):set('b_MagicWindowPinned', magicWindow.element.layout.userData.pinned or false)
    end
end

local setSize = function()
    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size

    if not magicWindow.staticMode then
        local dims = storage.playerSection('Settings/MagicWindowExtender/2_WindowOptions'):get('d_MagicWindowDimensions')
        if dims then
            local windowPos = util.vector2(dims.x * layerSize.x, dims.y * layerSize.y)
            local windowSize = util.vector2(dims.w * layerSize.x, dims.h * layerSize.y)
            magicWindow.element.layout.props.position = windowPos
            magicWindow.element.layout.props.size = windowSize
        end
    else
        magicWindow.element.layout.props.anchor = util.vector2(0.5, 0.5)
        magicWindow.element.layout.props.relativePosition = util.vector2(0.5, 0.5)
        magicWindow.element.layout.props.size = util.vector2(600, layerSize.y-96)
        magicWindow.element.layout.props.position = util.vector2(0, 0)
    end
end

magicWindow.init = function()
    if not magicWindow.element then
        return
    end

    magicWindow.element = templates.magicWindow(magicWindow.panes, magicWindow.staticMode, storedScrollPos)

    setSize()

    magicWindow.update()
end

magicWindow.show = function(staticMode)
    if not canShow() then return end

    local wasVisible = magicWindow.isVisible()

    magicWindow.staticMode = isControllerMenus() or staticMode
    if magicWindow.staticMode then
        I.UI.setMode(staticUiMode, {windows = {}}) -- stand-in mode to show cursor
    end

    templates.active = true
    magicWindow.updateTrackedStats()
    if not magicWindow.element or lastStaticMode ~= magicWindow.staticMode then
        lastStaticMode = magicWindow.staticMode
        magicWindow.create()
    end

    setSize()
    magicWindow.element.layout.props.visible = true
    magicWindow.element:update()

    magicWindow.element.layout.userData.setPinnable(not staticMode)

    if not wasVisible then
        omwself:sendEvent(constants.Events.WINDOW_SHOWN)
    end
end

magicWindow.hide = function(force)
    if not magicWindow.isVisible() then return end

    magicWindow.staticMode = magicWindow.staticMode or isControllerMenus()

    if not magicWindow.isPinned() or force then
        templates.active = false
        if magicWindow.element then
            magicWindow.element.layout.props.visible = false
            magicWindow.element:update()
        end
        omwself:sendEvent(constants.Events.WINDOW_HIDDEN)
    end
    if templates.activeTooltip then
        auxUi.deepDestroy(templates.activeTooltip)
        templates.activeTooltip = nil
    end
    saveWindowState()
    if magicWindow.staticMode then
        I.UI.removeMode(staticUiMode)
    end
    magicWindow.staticMode = false
end

magicWindow.toggle = function(staticMode)
    if magicWindow.isVisible() and not magicWindow.isPinned() then
        magicWindow.hide(true)
    elseif I.UI.getMode() == nil then
        magicWindow.show(staticMode)
    end
end

magicWindow.onUiModeChanged = function(oldMode, newMode)
    if magicWindow.element then
        magicWindow.element.layout.userData.setPinned(configPlayer.window.b_MagicWindowPinned)
    end
    local magicWindowMode = magicWindow.staticMode and staticUiMode or 'Interface'
    if magicWindow.isPinned() and not magicWindow.staticMode then
        if newMode == nil or newMode == 'Interface' then
            magicWindow.show()
        else
            magicWindow.hide(true)
        end
    elseif newMode ~= magicWindowMode then
        magicWindow.hide(true)
    end
    if templates.modalElement then
        auxUi.deepDestroy(templates.modalElement)
        templates.modalElement = nil
    end
end

magicWindow.onMouseWheel = function(v, h)
    if magicWindow.element and magicWindow.element.layout and templates.focusedScrollable and templates.focusedScrollable.layout then
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

magicWindow.trackStat = function(statId, getter)
    trackedStats[statId] = getter
    magicWindow.updateTrackedStats()
end

magicWindow.untrackStat = function(statId)
    trackedStats[statId] = nil
end

magicWindow.changedStats = {}
magicWindow.boxesToRedraw = {}

magicWindow.updateTrackedSections = function()
    local sectionsToUpdate = {}

    local function collectSections(sections, boxId)
        for _, section in pairs(sections or {}) do
            local update = false
            if section.trackedStats and section.builder then
                for statId, _ in pairs(magicWindow.changedStats) do
                    if section.trackedStats[statId] then
                        update = true
                        break
                    end
                end
            end

            if update then
                magicWindow.boxesToRedraw[boxId] = true
                table.insert(sectionsToUpdate, section)
            elseif section.sections then
                collectSections(section.sections)
            end
        end
    end

    for _, pane in pairs(magicWindow.panes) do
        for _, box in pairs(pane) do
            collectSections(box.sections, box.id)
        end
    end

    for _, section in ipairs(sectionsToUpdate) do
        section.lines = {}
        section.sections = {}
    end

    for _, section in ipairs(sectionsToUpdate) do
        section.builder()
    end

    if next(magicWindow.boxesToRedraw) ~= nil then
        if magicWindow.element then
            for boxId, _ in pairs(magicWindow.boxesToRedraw) do
                magicWindow.boxesToRedraw[boxId] = magicWindow.getBox(boxId)
            end
            templates.remakeBoxes(magicWindow.element.layout, magicWindow.boxesToRedraw)
            templates.updateMagicWindow(magicWindow.element.layout)
            if templates.activeTooltip then
                auxUi.deepDestroy(templates.activeTooltip)
                templates.activeTooltip = nil
            end
            magicWindow.boxesToRedraw = {}
        end
    end
    
    magicWindow.changedStats = {}
end

magicWindow.updateTrackedStats = function()
    local anyChanged = next(magicWindow.changedStats) ~= nil or next(magicWindow.boxesToRedraw) ~= nil

    for statId, getter in pairs(trackedStats) do
        local newValue = getter(omwself)
        if not helpers.tableEquals(newValue, lastTrackedStats[statId]) then
            magicWindow.stats[statId] = newValue
            lastTrackedStats[statId] = helpers.deepCopy(newValue)
            magicWindow.changedStats[statId] = true
            anyChanged = true
        end
    end

    if anyChanged then
        magicWindow.updateTrackedSections()
    end
end

magicWindow.onFrame = function()
    for _, el in ipairs(templates.updateQueue) do
        el:update()
    end
    templates.updateQueue = {}

    local dt = core.getRealFrameDuration()

    if templates.active then
        if not canShow() then
            magicWindow.hide(true)
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

        if magicWindow.needsRedraw then
            magicWindow.create()
            magicWindow.needsRedraw = false
        elseif updateTimer >= updateInt then
            magicWindow.updateTrackedStats()
            local valChanged, visChanged = templates.updateMagicWindow(magicWindow.element.layout)
            if valChanged then
                magicWindow.element:update()
            end
            if visChanged then
                magicWindow.needsRedraw = true
            end
            updateTimer = 0
        else
            updateTimer = updateTimer + dt
        end

        if magicWindow.needsRedrawDelayed then
            magicWindow.needsRedrawDelayed = false
            magicWindow.needsRedraw = true
        end
    end
end

-- Section management functions

function magicWindow.getPane(paneId)
    return magicWindow.panes[paneId]
end

function magicWindow.getBox(boxId)
    for paneId, pane in pairs(magicWindow.panes) do
        for _, box in ipairs(pane) do
            if box.id == boxId then
                return box, paneId
            end
        end
    end
end

function magicWindow.getSection(sectionId)
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

    for paneId, pane in pairs(magicWindow.panes) do
        for _, box in ipairs(pane) do
            local found = getSubsection(box, sectionId)
            if found then
                return found, box, paneId
            end
        end
    end
end

function magicWindow.getLine(lineId)
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

    for paneId, pane in pairs(magicWindow.panes) do
        for _, box in ipairs(pane) do
            local found, section = findLineInSections(box.sections, lineId)
            if found then
                return found, section, box, paneId
            end
        end
    end
end

function magicWindow.addBoxToPane(boxId, paneId, params)
    if not boxId or not paneId then return false end
    local existingBox, existingPaneId = magicWindow.getBox(boxId)
    if existingBox then
        print('Box', boxId, 'already exists in pane', existingPaneId)
        return false
    end

    params.id = boxId

    magicWindow.panes[paneId] = magicWindow.panes[paneId] or {}
    table.insert(magicWindow.panes[paneId], params)
    magicWindow.needsRedraw = true
    return true
end

function magicWindow.addSectionToBox(sectionId, boxId, params)
    if not sectionId or not boxId then return false end
    local existingSection, existingBox, existingPaneId = magicWindow.getSection(sectionId)
    if existingSection then
        print('Section', sectionId, 'already exists in box', existingBox.id, 'in pane', existingPaneId)
        return false
    end

    params.id = sectionId

    local box = magicWindow.getBox(boxId)
    if not box then
        print('Box', boxId, 'not found for new section', sectionId)
        return false
    end

    box.sections = box.sections or {}
    table.insert(box.sections, params)
    magicWindow.needsRedraw = true
    return true
end

function magicWindow.addSectionToSection(sectionId, parentSectionId, params)
    if not sectionId or not parentSectionId then return false end
    local existingSection, existingBox, existingPaneId = magicWindow.getSection(sectionId)
    if existingSection then
        print('Section', sectionId, 'already exists in box', existingBox.id, 'in pane', existingPaneId)
        return false
    end

    params.id = sectionId

    local parentSection = magicWindow.getSection(parentSectionId)
    if not parentSection then
        print('Parent section', parentSectionId, 'not found for new section', sectionId)
        return false
    end
        
    parentSection.sections = parentSection.sections or {}
    table.insert(parentSection.sections, params)
    magicWindow.needsRedraw = true
    return true
end

function magicWindow.addLineToSection(lineId, sectionId, params)
    if not lineId or not sectionId then return false end
    local existingLine, existingSection, existingBox, existingPaneId = magicWindow.getLine(lineId)
    if existingLine then
        print('Line', lineId, 'already exists in section', existingSection.id, 'in box', existingBox.id, 'in pane', existingPaneId)
        return false
    end

    params.id = lineId

    local section, box = magicWindow.getSection(sectionId)
    if not section then
        print('Section', sectionId, 'not found for new line', lineId)
        return false
    end

    section.lines = section.lines or {}
    table.insert(section.lines, params)
    magicWindow.boxesToRedraw[box.id] = true
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

function magicWindow.moveSectionToBox(sectionId, boxId)
    if not sectionId or not boxId then return false end
    local section, existingBox = magicWindow.getSection(sectionId)
    if not section then
        print('Section', sectionId, 'not found for moving to box', boxId)
        return false
    end

    local box = magicWindow.getBox(boxId)
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
    magicWindow.needsRedraw = true
    return true
end

function magicWindow.modifyBox(boxId, params)
    local box = magicWindow.getBox(boxId)
    if not box then
        print('Box', boxId, 'not found for modification')
        return false
    end
    mergeParams(box, params)
    magicWindow.needsRedraw = true
    return true
end

function magicWindow.modifySection(sectionId, params)
    local section = magicWindow.getSection(sectionId)
    if not section then
        print('Section', sectionId, 'not found for modification')
        return false
    end
    mergeParams(section, params)
    magicWindow.needsRedraw = true
    return true
end

function magicWindow.modifyLine(lineId, params)
    local line = magicWindow.getLine(lineId)
    if not line then
        print('Line', lineId, 'not found for modification')
        return false
    end
    mergeParams(line, params)
    magicWindow.needsRedraw = true
    return true
end

return magicWindow