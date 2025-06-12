-- player_native.lua: Player script using native Morrowind styling and intelligent jittering
-- Combines native tooltip appearance with smart label placement

local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local self = require('openmw.self')
local async = require('openmw.async')

-- Import utilities
local projection = require('scripts.TwentyTwentyObjects.util.projection')
local logger_module = require('scripts.TwentyTwentyObjects.util.logger')
local storage_module = require('scripts.TwentyTwentyObjects.util.storage')
local spatial = require('scripts.TwentyTwentyObjects.util.spatial')
local occlusion = require('scripts.TwentyTwentyObjects.util.occlusion')
local labelRenderer = require('scripts.TwentyTwentyObjects.util.labelRenderer_native')
local labelLayout = require('scripts.TwentyTwentyObjects.util.labelLayout_jitter')

-- Forward declare
local generalSettings = {}

-- Initialize (defer storage-dependent parts to onLoad)
-- labelRenderer.init() -- If this uses storage, move to onLoad

-- Configuration
local CONFIG = {
    UPDATE_INTERVAL = 0.033,      -- 30fps label updates
    SCAN_INTERVAL = 0.25,         -- Object rescan rate
    MAX_LABELS = 100,             -- Maximum visible labels
    FADE_DURATION = 0.15,         -- Fade in/out time
    LINE_UPDATE_DELAY = 0.05      -- Slight delay for line updates (smoother)
}

-- State
local activeLabels = {}
local currentProfile = nil
local updateAccumulator = 0
local scanAccumulator = 0
local lineUpdateAccumulator = 0

-- Label data structure
local function createLabelData(object, name, screenPos, objectScreenPos, priority)
    return {
        id = tostring(object) .. "_" .. os.time(),
        object = object,
        name = name,
        screenPos = screenPos,
        objectScreenPos = objectScreenPos,
        priority = priority,
        ui = nil,
        line = nil,
        alpha = 0,
        targetAlpha = 1,
        visible = true
    }
end

-- Get object name with Morrowind formatting
local function getObjectName(object)
    local objType = object.type
    local name = ""
    
    -- Get base name
    if objType == types.NPC then
        name = types.NPC.record(object).name
    elseif objType == types.Creature then
        name = types.Creature.record(object).name
    elseif objType == types.Container then
        name = types.Container.record(object).name
    elseif objType == types.Door then
        name = types.Door.record(object).name

        -- Use door destination as name if available
        local destination = types.Door.destCell(object)
        if destination then
            name = destination.name
        end
    elseif objType == types.Weapon then
        name = types.Weapon.record(object).name
    elseif objType == types.Armor then
        name = types.Armor.record(object).name
    elseif objType == types.Clothing then
        name = types.Clothing.record(object).name
    elseif objType == types.Book then
        name = types.Book.record(object).name
    elseif objType == types.Ingredient then
        name = types.Ingredient.record(object).name
    elseif objType == types.Apparatus then
        name = types.Apparatus.record(object).name
    elseif objType == types.Lockpick then
        name = types.Lockpick.record(object).name
    elseif objType == types.Probe then
        name = types.Probe.record(object).name
    elseif objType == types.Repair then
        name = types.Repair.record(object).name
    elseif objType == types.Potion then
        name = types.Potion.record(object).name
    elseif objType == types.Light then
        name = types.Light.record(object).name
    elseif objType == types.Static then
        name = types.Static.record(object).name
    elseif objType == types.Miscellaneous then
        name = types.Miscellaneous.record(object).name
    else
        name = object.recordId or "Unknown"
    end

    -- Add count if available
    if object.count and object.count > 1 then
        name = string.format("%s (%d)", name, object.count)
    end
    
    return name
end

-- Check if object matches filters
local function matchesFilters(object, filters)
    local objType = object.type
    
    if objType == types.NPC and filters.npcs then return true end
    if objType == types.Creature and filters.creatures then return true end
    if objType == types.Container and filters.containers then return true end
    if objType == types.Door and filters.doors then return true end
    if objType == types.Activator and filters.activators then return true end
    if objType == types.Static and filters.activators then return true end  -- Static objects under activators filter
    
    -- Items - check specific subtypes first
    if objType == types.Weapon and filters.weapons then return true end
    if objType == types.Armor and filters.armor then return true end
    if objType == types.Clothing and filters.clothing then return true end
    if objType == types.Book and filters.books then return true end
    if objType == types.Ingredient and filters.ingredients then return true end
    if objType == types.Apparatus and filters.misc then return true end  -- Apparatus items under misc filter
    if objType == types.Lockpick and filters.misc then return true end  -- Lockpick under misc filter
    if objType == types.Probe and filters.misc then return true end  -- Probe under misc filter
    if objType == types.Repair and filters.misc then return true end  -- Repair under misc filter
    if objType == types.Potion and filters.misc then return true end  -- Potions under misc filter
    if objType == types.Light and filters.misc then return true end  -- Lights under misc filter
    if objType == types.Miscellaneous and filters.misc then return true end
    if objType == types.Gold then return true end  -- Always show gold
    
    -- If none of the specific filters matched, check if it's an item and items filter is on
    -- This acts as a catch-all for items without specific filters
    if filters.items then
        -- Only return true for item types that don't have their own filter
        -- or if their specific filter is also enabled
        if objType == types.Weapon or objType == types.Armor or 
           objType == types.Clothing or objType == types.Book or 
           objType == types.Apparatus or objType == types.Lockpick or
           objType == types.Probe or objType == types.Repair or
           objType == types.Potion or objType == types.Light or
           objType == types.Miscellaneous then
            return true
        end
        -- Don't include ingredients unless specifically enabled
    end
    
    return false
end

-- Scan and create labels with jittering
local function scanAndCreateLabels(profile)
    logger_module.info(string.format('Native scan with profile: %s', profile.name))
    
    -- Update and log screen size
    projection.updateScreenSize()
    
    -- Clear existing
    clearAllLabels()
    
    local playerPos = self.position
    local radiusSq = profile.radius * profile.radius
    local candidates = {}
    
    -- Get occlusion method based on performance settings
    local performance = storage_module.get('performance', {occlusion = "medium"})
    
    -- Gather all nearby objects
    local function gatherObjects(objectList, typeFilter)
        for _, obj in ipairs(objectList) do
            if matchesFilters(obj, profile.filters) then
                local distSq = (obj.position - playerPos):length2()
                if distSq <= radiusSq then
                    -- Check if object is in front of camera first
                    local worldPos = projection.getObjectLabelPosition(obj)
                    local screenPos = projection.worldToScreen(worldPos)
                    
                    if screenPos then  -- worldToScreen returns nil if behind camera
                        -- Now check occlusion
                        if occlusion.isVisible(obj, playerPos, performance.occlusion) then
                            local priority = spatial.calculatePriority(obj, playerPos)
                            table.insert(candidates, {
                                object = obj,
                                distance = math.sqrt(distSq),
                                priority = priority,
                                worldPos = worldPos,
                                screenPos = screenPos
                            })
                            if generalSettings.debug then
                                logger_module.debug(string.format('Added candidate: %s at screen pos (%.1f, %.1f)', 
                                    getObjectName(obj), screenPos.x, screenPos.y))
                            end
                        end
                    else
                        if generalSettings.debug then
                            logger_module.debug(string.format('Object %s filtered out - worldToScreen returned nil', 
                                getObjectName(obj)))
                        end
                    end
                end
            end
        end
    end
    
    -- Gather from all sources
    if profile.filters.npcs or profile.filters.creatures then
        gatherObjects(nearby.actors)
    end
    if profile.filters.items or profile.filters.weapons or profile.filters.armor or 
       profile.filters.clothing or profile.filters.books or profile.filters.ingredients or 
       profile.filters.misc then
        gatherObjects(nearby.items)
    end
    if profile.filters.containers then
        gatherObjects(nearby.containers)
    end
    if profile.filters.doors then
        gatherObjects(nearby.doors)
    end
    if profile.filters.activators then
        gatherObjects(nearby.activators)
        -- Also gather statics if activators filter is on
        gatherObjects(nearby.statics)
    end
    
    logger_module.debug(string.format('Found %d candidates before sorting', #candidates))
    
    -- Sort by priority
    table.sort(candidates, function(a, b)
        return a.priority > b.priority
    end)
    
    -- Get max labels from performance settings
    local performanceSettings = storage_module.get('performance', {maxLabels = 100})
    local maxLabels = performanceSettings.maxLabels or CONFIG.MAX_LABELS
    
    -- Limit to max labels
    local toProcess = {}
    for i = 1, math.min(#candidates, maxLabels) do
        toProcess[i] = candidates[i]
    end
    
    logger_module.debug(string.format('Processing %d objects (max: %d)', #toProcess, maxLabels))
    
    -- Calculate screen positions and prepare for jittering
    labelLayout.solver:clear()
    local labelDataList = {}
    
    for _, candidate in ipairs(toProcess) do
        -- We already have worldPos and screenPos from gathering phase
        local screenPos = candidate.screenPos
        local worldPos = candidate.worldPos
        
        -- logger_module.debug(string.format('Object at world pos: %s, screen pos: %s', tostring(worldPos), tostring(screenPos)))
        if generalSettings.debug then
            logger_module.debug(string.format('Object at world pos: %s, screen pos: %s', tostring(worldPos), tostring(screenPos)))
        end
        
        if screenPos and projection.isOnScreen(screenPos, 300) then
            local name = getObjectName(candidate.object)
            
            -- logger_module.debug(string.format('Adding label for: %s', name))
            if generalSettings.debug then
                logger_module.debug(string.format('Adding label for: %s', name))
            end
            
            -- Estimate label size
            local labelWidth = #name * 7  -- Approximate character width
            local labelHeight = 20
            
            -- Add to jitter solver
            labelLayout.solver:addLabel(
                screenPos,
                labelWidth,
                labelHeight,
                candidate.priority,
                {
                    object = candidate.object,
                    name = name,
                    distance = candidate.distance,
                    priority = candidate.priority
                }
            )
        else
            if generalSettings.debug then
                logger_module.debug('Object not on screen or screenPos is nil')
            end
        end
    end
    
    -- Solve positions with jittering
    local solved = labelLayout.solver:solve()
    
    if generalSettings.debug then
        logger_module.debug(string.format('Solver returned %d solutions', #solved))
    end
    
    -- Create labels and lines
    for _, solution in ipairs(solved) do
        local data = solution.data
        
        -- logger_module.debug(string.format('Creating label at pos: %s', tostring(solution.labelPos)))
        if generalSettings.debug then
            logger_module.debug(string.format('Creating label at pos: %s', tostring(solution.labelPos)))
        end
        
        -- Create label at solved position
        local label = labelRenderer.createNativeLabel(data.name, {
            position = solution.labelPos,
            distanceScale = projection.getDistanceScale(data.distance),
            alpha = 1.0  -- Start fully visible for debugging
        })
        
        if not label then
            logger_module.error('Failed to create label!')
        end
        
        -- Create connecting line if needed
        local line = nil
        if solution.showLine then
            if generalSettings.debug then
                logger_module.debug(string.format('Creating line for %s: objectPos=%s, labelPos=%s', 
                    data.name, tostring(solution.objectPos), tostring(solution.labelPos)))
            end
            
            local lineStyle = labelLayout.getLineStyle(
                solution.labelPos,
                solution.objectPos,
                false,  -- Not grouped for now
                data.priority or 50  -- Default priority if missing
            )
            
            if generalSettings.debug then
                logger_module.debug(string.format('Line style: %s', lineStyle))
            end
            
            if lineStyle == "solid" then
                line = labelLayout.createConnectingLine(solution.objectPos, solution.labelPos)
            elseif lineStyle == "dotted" then
                line = labelLayout.createDottedLine(solution.objectPos, solution.labelPos)
            elseif lineStyle == "curved" then
                line = labelLayout.createCurvedLine(solution.objectPos, solution.labelPos, 15)
            end
            
            if generalSettings.debug then
                if line then
                    logger_module.debug('Line created successfully')
                else
                    logger_module.debug('Line creation failed or returned nil')
                end
            end
        else
            if generalSettings.debug then
                logger_module.debug(string.format('No line for %s: distance=%.1f', 
                    data.name, (solution.labelPos - solution.objectPos):length()))
            end
        end
        
        -- Store label data
        table.insert(activeLabels, {
            id = tostring(data.object) .. "_" .. os.time(),
            object = data.object,
            name = data.name,
            label = label,
            line = line,
            labelPos = solution.labelPos,
            objectPos = solution.objectPos,
            alpha = 1.0,  -- Start fully visible
            targetAlpha = 1,
            showLine = solution.showLine
        })
    end
    
    if generalSettings.debug then
        logger_module.debug(string.format('Created %d labels with jittering', #activeLabels))
    end
end

-- Update label positions and lines
local function updateLabels(dt)
    labelLayout.solver:clear()
    local toRemove = {}
    local needsJitter = false
    
    -- First pass: update positions and check for overlaps
    for i, labelData in ipairs(activeLabels) do
        if not labelData.object:isValid() then
            labelData.targetAlpha = 0
            if labelData.alpha <= 0 then
                table.insert(toRemove, i)
            end
        else
            -- Update object screen position
            local worldPos = projection.getObjectLabelPosition(labelData.object)
            local newObjectPos = projection.worldToScreen(worldPos)
            
            if newObjectPos and projection.isOnScreen(newObjectPos, 300) then
                labelData.objectPos = newObjectPos
                labelData.visible = true
                
                -- Add to solver for jittering
                local labelWidth = #labelData.name * 7
                local labelHeight = 20
                
                labelLayout.solver:addLabel(
                    newObjectPos,
                    labelWidth,
                    labelHeight,
                    100 - i,  -- Priority based on order
                    labelData
                )
                
                needsJitter = true
            else
                labelData.visible = false
                labelData.targetAlpha = 0
            end
        end
        
        -- Update alpha
        if labelData.alpha < labelData.targetAlpha then
            labelData.alpha = math.min(labelData.targetAlpha,
                                      labelData.alpha + dt / CONFIG.FADE_DURATION)
        elseif labelData.alpha > labelData.targetAlpha then
            labelData.alpha = math.max(labelData.targetAlpha,
                                      labelData.alpha - dt / CONFIG.FADE_DURATION)
        end
        
        -- Update label UI
        if labelData.label then
            if labelData.label.layout and labelData.label.layout.props then
                labelData.label.layout.props.alpha = labelData.alpha
                labelData.label.layout.props.visible = labelData.visible and labelData.alpha > 0
                labelData.label:update()
            else
                logger_module.error('Label has no layout or props!')
            end
        end
    end
    
    -- Solve new positions if needed
    if needsJitter then
        local solved = labelLayout.solver:solve()
        
        -- Update label positions and lines
        for _, solution in ipairs(solved) do
            local labelData = solution.data
            
            -- Update label position
            if labelData.label then
                labelData.label.layout.props.position = solution.labelPos
                labelData.label:update()
            end
            
            -- Update or create line
            if solution.showLine and labelData.visible then
                if not labelData.line then
                    -- Create new line
                    labelData.line = labelLayout.createConnectingLine(
                        solution.objectPos,
                        solution.labelPos
                    )
                else
                    -- Update existing line
                    -- This would need a more complex line update system
                    if labelData.line.destroy then
                        labelData.line:destroy()
                    end
                    labelData.line = labelLayout.createConnectingLine(
                        solution.objectPos,
                        solution.labelPos
                    )
                end
                
                -- Set line visibility
                if labelData.line then
                    labelData.line.layout.props.alpha = labelData.alpha * 0.6
                    labelData.line:update()
                end
            elseif labelData.line then
                -- Remove line if no longer needed
                if labelData.line.destroy then
                    labelData.line:destroy()
                end
                labelData.line = nil
            end
        end
    end
    
    -- Remove dead labels
    for i = #toRemove, 1, -1 do
        local labelData = activeLabels[toRemove[i]]
        if labelData.label then
            labelData.label:destroy()
        end
        if labelData.line then
            if type(labelData.line) == "table" and labelData.line[1] then
                -- Dotted or curved line (multiple segments)
                for _, segment in ipairs(labelData.line) do
                    segment:destroy()
                end
            elseif labelData.line.destroy then
                labelData.line:destroy()
            end
        end
        table.remove(activeLabels, toRemove[i])
    end
end

-- Clear all labels
function clearAllLabels()
    for _, labelData in ipairs(activeLabels) do
        if labelData.label then
            labelData.label:destroy()
        end
        if labelData.line then
            if type(labelData.line) == "table" and labelData.line[1] then
                for _, segment in ipairs(labelData.line) do
                    segment:destroy()
                end
            elseif labelData.line.destroy then
                labelData.line:destroy()
            end
        end
    end
    activeLabels = {}
end

-- Event handlers
local function onShowHighlights(eventData)
    logger_module.info('onShowHighlights called')
    if not eventData or not eventData.profile then
        logger_module.error('Invalid eventData in onShowHighlights')
        return
    end
    currentProfile = eventData.profile
    occlusion.newFrame()  -- Reset occlusion cache
    scanAndCreateLabels(currentProfile)
end

local function onHideHighlights(eventData)
    logger_module.info('onHideHighlights called')
    -- Clear profile first to stop updates
    currentProfile = nil
    -- Then clear all labels immediately
    clearAllLabels()
end

-- Debug toggle handler
local function onToggleDebug(eventData)
    if eventData and eventData.enabled ~= nil then
        generalSettings.debug = eventData.enabled
        storage_module.set('general', generalSettings)
        logger_module.init(generalSettings.debug)
        logger_module.info(string.format('Debug mode %s', generalSettings.debug and 'enabled' or 'disabled'))
    end
end

-- Update loop
local function onUpdate(dt)
    if not currentProfile then
        -- Clean up any remaining labels when no profile is active
        if #activeLabels > 0 then
            clearAllLabels()
        end
        return
    end
    
    -- Update existing labels
    updateAccumulator = updateAccumulator + dt
    if updateAccumulator >= CONFIG.UPDATE_INTERVAL then
        updateLabels(updateAccumulator)
        updateAccumulator = 0
    end
    
    -- Rescan for new objects
    scanAccumulator = scanAccumulator + dt
    if scanAccumulator >= CONFIG.SCAN_INTERVAL then
        if currentProfile then
            occlusion.newFrame()
            -- Could implement incremental scanning here
        end
        scanAccumulator = 0
    end
end

local function onLoad()
    -- local engine_storage = require('openmw.storage') -- No longer needed here
    -- storage_module.init(engine_storage) -- No longer needed here

    generalSettings = storage_module.get('general', { debug = false })
    logger_module.init(generalSettings.debug)  -- Use settings for debug mode
    
    labelRenderer.init()
    projection.updateScreenSize()
    logger_module.info('Native player script loaded with debug enabled')
end

logger_module.info('Twenty Twenty Objects native player script (player_native.lua) parsed.')

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = onLoad
    },
    eventHandlers = {
        TTO_ShowHighlights = onShowHighlights,
        TTO_HideHighlights = onHideHighlights,
        TTO_ToggleDebug = onToggleDebug
    }
}