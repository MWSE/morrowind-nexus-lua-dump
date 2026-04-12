local mp = 'scripts/MaxYari/animated_lanterns/'
DebugLevel = 0

local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local markup = require('openmw.markup')
local vfs = require('openmw.vfs')

local gutils = require(mp .. 'utils/gutils')
local DEFS = require(mp .. 'utils/defs')
local s = require(mp .. 'settings_global')

local PLAYER_EVENT_RAYCAST_REQUEST = "LanternRaycastRequest"
local PLAYER_EVENT_RAYCAST_RESULT = "LanternRaycastResult"
local PLAYER_EVENT_CAMERA_DIRECTION = "LanternCameraDirection"

-- Interface
local interface = {
    version = 1.15    
}

local currentCell = nil
local cameraLookDirection = util.vector3(0, 1, 0)
local currentCellsGroup = nil
local player = world.players[1]

local activeLanternDistance = 100*69
-- Animation framerate limiting parameters
local minAnimFPS = 120      -- Closest possible: 60 FPS
local maxAnimFPS = 25      -- Furthest possible: 10 FPS
local minAnimDist = 10*69      -- Distance at which minAnimFPS applies
local maxAnimDist = activeLanternDistance   -- Distance at which maxAnimFPS applies

local lanterns = {} -- Now a table indexed by object.id
-- Deferred lantern search state (flat list of objects)
local pendingLanternObjects = nil -- flat list of objects to process
local pendingLanternIdx = 1
local PENDING_LANTERN_BATCH = 12
local PENDING_LANTERN_RAYCASTS = 3

local ZUnitVector = util.vector3(0,0,1)
local angleLimit = (math.pi / 2) - 0.001

local gravity = 9.8
local angularDamping = 0.99
local windDirection = util.vector3(1, -1, 0):normalize()
local baseYawRotationSpeed = 0.02
local yawRotationSpeed = baseYawRotationSpeed
local yawRotationAmplitude = 0.5

local windPowerMin = 0
local windPowerMax = 0
local extWindPowerMin = 0.5
local extWindPowerMax = 1.5
local stormWindPowerMin = 10
local stormWindPowerMax = 15
local intWindPowerMin = 0
local intWindPowerMax = 0.5
local windBurstProbability = 0.5
local windPowerChangeInterval = 1

-- Weather check cache (updates once per second)
local weatherCheckTimer = 0
local weatherCheckInterval = 1.0
local lastWeatherState = nil

--if true then return end


local function initializeLanternWindData(lantern)
    local positionLength = lantern.position:length()
    local initialTimer = math.abs(math.sin(positionLength / 1000))
    return {
        windForce = 0,
        windPowerTarget = 0,
        windPowerChangeTimer = initialTimer,
        angularVelocity = 0,
        swingAngle = 0
    }
end

local function updateLanternWindForce(lanternData, dt)
    lanternData.windPowerChangeTimer = lanternData.windPowerChangeTimer - dt
    if lanternData.windPowerChangeTimer <= 0 then
        if math.random() < windBurstProbability then
            lanternData.windPowerTarget = math.random() * (windPowerMax - windPowerMin) + windPowerMin
        else
            lanternData.windPowerTarget = 0
        end
        lanternData.windPowerChangeTimer = windPowerChangeInterval / 2 + math.random() * windPowerChangeInterval / 2
    end
    lanternData.windForce = gutils.lerpClamped(lanternData.windForce, lanternData.windPowerTarget, dt * 2)
    if lanternData.windForce < 0 then lanternData.windForce = 0 end
end

local function mergeArray(target, source)
    if source then
        for _, item in ipairs(source) do
            table.insert(target, item)
        end
    end
end

local function loadLanternConfigs()
    local mergedConfig = {
        lantern_configs = {},
        blacklisted_names = {},
        blacklisted_cell_ids = {}
    }

    for filePath in vfs.pathsWithPrefix('scripts/MaxYari/animated_lanterns/configs/') do
        if filePath:match('%.yaml$') then
            gutils.print("Loadin lantern config ".. filePath,0)
            local config = markup.loadYaml(filePath)
            if config then
                mergeArray(mergedConfig.lantern_configs, config.lantern_configs)
                mergeArray(mergedConfig.blacklisted_names, config.blacklisted_names)
                mergeArray(mergedConfig.blacklisted_cell_ids, config.blacklisted_cell_ids)
            end
        end
    end

    -- Lowercase all names and blacklist entries
    for _, config_entry in ipairs(mergedConfig.lantern_configs) do
        config_entry.name = config_entry.name:lower()
    end
    for i, name in ipairs(mergedConfig.blacklisted_names) do
        mergedConfig.blacklisted_names[i] = name:lower()
    end
    for i, id in ipairs(mergedConfig.blacklisted_cell_ids) do
        mergedConfig.blacklisted_cell_ids[i] = id:lower()
    end

    -- Create map for quick lookups
    mergedConfig.blacklisted_cell_map = {}
    for _, id in ipairs(mergedConfig.blacklisted_cell_ids) do
        mergedConfig.blacklisted_cell_map[id] = true
    end

    -- Convert offsets and directions to vectors
    for _, config_entry in ipairs(mergedConfig.lantern_configs) do
        config_entry.offset = util.vector3(config_entry.offset[1], config_entry.offset[2], config_entry.offset[3])
        if config_entry.localSwingDirection then
            config_entry.localSwingDirection = util.vector3(config_entry.localSwingDirection[1], config_entry.localSwingDirection[2], config_entry.localSwingDirection[3])
        end
    end

    return mergedConfig
end

local lanternConfig = loadLanternConfigs()
local lanternConfigs = lanternConfig.lantern_configs


local function isBlacklisted(obj)
    local recordId = obj.recordId:lower()
    local model = obj.type.record(obj).model
    if model then model = model:lower() end
    -- Check blacklisted_cell_ids
    if obj.cell and obj.cell.name then
        local cellName = obj.cell.name:lower()
        if lanternConfig.blacklisted_cell_map[cellName] then
            return true
        end
    end
    -- Check blacklisted_names (partial match)
    for _, name in ipairs(lanternConfig.blacklisted_names) do
        if recordId:find(name) or (model and model:find(name)) then
            return true
        end
    end
    return false
end

local function findConfig(obj)
    local recordId = obj.recordId:lower()
    local model = obj.type.record(obj).model
    if model then model = model:lower() end
    for _, config in ipairs(lanternConfigs) do
        if recordId:find(config.name) or (model and model:find(config.name)) then
            return config
        end
    end
    return nil
end





local function getCellsAround(centerCell)
    local ret = {}
    local centerX, centerY = centerCell.gridX, centerCell.gridY
    table.insert(ret, centerCell)

    if centerCell.isExterior then
        -- Iterate over the surrounding cells
        for dx = -1, 1 do
            for dy = -1, 1 do
                if dx == 0 and dy == 0 then goto continue end
                local cellX = centerX + dx
                local cellY = centerY + dy
                local cell = world.getExteriorCell(cellX, cellY)
                table.insert(ret, cell)
                ::continue::
            end
        end
    end

    return ret
end





local function findLanternsDeferredStep()
    if not pendingLanternObjects then return end
    local processed = 0
    local raycastsThisFrame = 0

    while processed < PENDING_LANTERN_BATCH and pendingLanternObjects and raycastsThisFrame < PENDING_LANTERN_RAYCASTS do
        if pendingLanternIdx > #pendingLanternObjects then
            pendingLanternObjects = nil
            pendingLanternIdx = 1
            break
        end

        local obj = pendingLanternObjects[pendingLanternIdx]
        -- Find config
        local foundConfig = findConfig(obj)

        -- Skip blacklisted objects
        if not isBlacklisted(obj) and foundConfig then
            local finishedInitialise = false
            if foundConfig.onlyHangs then
                finishedInitialise = true
            end
            local timerOffset = math.random() / 4

            local initialSwingAxis = nil
            if foundConfig.localSwingDirection then
                initialSwingAxis = obj.rotation:apply(foundConfig.localSwingDirection):normalize():cross(ZUnitVector)
            end

            lanterns[obj.id] = {
                object = obj,
                swingPhaseOffset = math.random() * 2 * math.pi,
                yawPhaseOffset = math.random() * 2 * math.pi,
                initialYawRotation = obj.rotation:getYaw(),
                originOffset = foundConfig.offset,
                localSwingDirection = foundConfig.localSwingDirection,
                initialSwingAxis = initialSwingAxis,
                avoidYawRotation = foundConfig.avoidYawRotation,
                weight = foundConfig.weight or 1,
                windData = initializeLanternWindData(obj),
                animTimer = timerOffset,
                finishedInitialise = finishedInitialise,
                configName = foundConfig.name,
                onlyHangs = foundConfig.onlyHangs,
                positionNeedsReset = false
            }
            if finishedInitialise then
                lanterns[obj.id].positionNeedsReset = true
            end
            -- If not finishedInitialise, send for raycast (up to PENDING_LANTERN_RAYCASTS per frame)
            if not finishedInitialise then
                player:sendEvent(PLAYER_EVENT_RAYCAST_REQUEST, { lantern = obj })
                raycastsThisFrame = raycastsThisFrame + 1
            end
        end

        processed = processed + 1
        pendingLanternIdx = pendingLanternIdx + 1
    end
end

local function prepareLanternSearch()
    pendingLanternObjects = {}
    pendingLanternIdx = 1
    for _, cell in ipairs(currentCellsGroup or {}) do
        for _, obj in ipairs(cell:getAll()) do
            table.insert(pendingLanternObjects, obj)
        end
    end
end

local function processLanterns(objects)
    -- Allows external scripts to enqueue lantern objects for deferred processing.
    -- "objects" should be a list (array) of object instances.
    if type(objects) ~= 'table' or #objects == 0 then
        return
    end

    if not pendingLanternObjects then
        pendingLanternObjects = {}
        pendingLanternIdx = 1
    end

    for _, obj in ipairs(objects) do
        table.insert(pendingLanternObjects, obj)
    end
end
interface.processLanterns = processLanterns

local function replaceLantern(original, new)
    -- Replaces an existing lantern object with a new one, updating the lanterns map.
    -- original: the old lantern object (or object with .id to find)
    -- new: the new lantern object to use in its place    

    -- Find the lantern entry by original object id
    local lanternData = lanterns[original.id]
    if not lanternData then
        return false
    end

    -- Remove old entry and replace with new
    lanterns[original.id] = nil
    lanternData.object = new
    lanterns[new.id] = lanternData

    return true
end
interface.replaceLantern = replaceLantern

interface.isAnimated = function(objectId)
    local data = lanterns[objectId]
    return data and data.lastAnimTime or 0
end

local function cleanUpLanterns()
    if not currentCellsGroup then return end
    
    -- Build O(1) lookup table for current cells
    local validCells = {}
    for _, cell in ipairs(currentCellsGroup) do
        validCells[cell] = true
    end
    
    for id, lanternData in pairs(lanterns) do
        if not lanternData.object:isValid() or not validCells[lanternData.object.cell] then
            lanterns[id] = nil
        end
    end
end

local function getAnimIntervalForDistance(dist)
    if dist <= minAnimDist then return 1 / minAnimFPS end
    if dist >= maxAnimDist then return 1 / maxAnimFPS end
    local t = (dist - minAnimDist) / (maxAnimDist - minAnimDist)
    local fps = minAnimFPS + (maxAnimFPS - minAnimFPS) * t
    return 1 / fps
end

local function onRaycastResult(data)
    -- results: array of { objectId = lantern.object.id, shouldInit = true/false }

    --print("Raycast result for lantern", data.lantern.id, "shouldInit:", data.shouldInit)
    
    local lantern = lanterns[data.lantern.id]
    if lantern then
        if data.shouldInit then
            lantern.finishedInitialise = true
            lantern.positionNeedsReset = true
        else
            -- print("Not initialising lantern", data.lantern.id, "due to raycast hit")
            lanterns[data.lantern.id] = nil
        end
    end
    
end

local function onCameraDirectionUpdate(direction)
    cameraLookDirection = direction
end


local teleportOptsPayload = {}


local function animateLanterns(dt)
    local lookDir = cameraLookDirection
    local playerPos = player.position
    for id, lanternData in pairs(lanterns) do
        if not lanternData.finishedInitialise then goto continue end
        if lanternData.positionNeedsReset then
            -- Reseting position here will result in manually positioned lanters teleporting back to their initial position - very undesirable
            -- Atm im not sure why i even introduced it... were some signs broken without it?
            -- lanternData.object:teleport(lanternData.object.cell, lanternData.object.startingPosition, { rotation = lanternData.object.startingRotation })
            lanternData.positionNeedsReset = false
            goto continue
        end

        local lantern = lanternData.object
        local lanternPos = lantern.position
        local toLantern = lanternPos - playerPos
        local dist = toLantern:length()
        if dist > activeLanternDistance then goto continue end
        if toLantern:dot(lookDir) < 0 then goto continue end

        -- Accounting for animation interval (far away lanterns are animated at lower fps)
        local interval = getAnimIntervalForDistance(dist)
        lanternData.animTimer = (lanternData.animTimer or 0) - dt
        if lanternData.animTimer > 0 then goto continue end
        lanternData.animTimer = interval

        if not lantern or lantern.count <= 0 or not lantern:isValid() or not lantern.enabled then
            lanterns[id] = nil
        else
            local windData = lanternData.windData
            local originOffset = lanternData.originOffset
            local localSwingDirection = lanternData.localSwingDirection
            local avoidYawRotation = lanternData.avoidYawRotation
            local weight = lanternData.weight or 1            

            updateLanternWindForce(windData, dt)

            local swingDirection = windDirection
            local swingAxis = lanternData.initialSwingAxis -- For fixed-axis swinged objects such as guild signs this will have a value and theres no point in recalculating it
            if not swingAxis then
                -- For non-fixed axis swinging objects (lanterns) - we calculate axis every frame
                swingAxis = swingDirection:cross(ZUnitVector):normalize()
            end

            local gravityForce = -gravity * math.sin(windData.swingAngle)
            local windForceEffect = (windData.windForce / weight) * math.cos(windData.swingAngle)
            local netTorque = gravityForce + windForceEffect

            local angularAcceleration = netTorque
            windData.angularVelocity = (windData.angularVelocity + angularAcceleration * dt) * angularDamping
            windData.swingAngle = windData.swingAngle + windData.angularVelocity * dt            

            local swingRotation = util.transform.rotate(windData.swingAngle, swingAxis)

            local combinedRotation
            if avoidYawRotation then
                combinedRotation = swingRotation * util.transform.rotateZ(lanternData.initialYawRotation)
            else
                local yawAngle = math.sin(core.getSimulationTime() * yawRotationSpeed + lanternData.yawPhaseOffset) * yawRotationAmplitude
                local yawRotation = util.transform.rotateZ(yawAngle)
                combinedRotation = swingRotation * yawRotation
            end

            local currOriginOffset = lantern.rotation:apply(originOffset)
            local newOriginOffset = combinedRotation:apply(originOffset)
            local finalOffset = currOriginOffset - newOriginOffset

            teleportOptsPayload.rotation = combinedRotation
            lantern:teleport(lantern.cell, lanternPos + finalOffset, teleportOptsPayload)
            lanternData.lastAnimTime = core.getSimulationTime()
        end

        ::continue::
    end
end


local stormWeathers = { -- these have isStorm = false and report wrong storm directions. Blizzard works fine.
	Blight = true,
	Ashstorm = true,
}

local function getWindParams(isStorm)
	local mult = isStorm and s.settings.StormWindMult or s.settings.CalmWindMult
	local baseMin = isStorm and stormWindPowerMin or extWindPowerMin
	local baseMax = isStorm and stormWindPowerMax or extWindPowerMax
	return baseMin * mult, baseMax * mult, baseYawRotationSpeed * mult
end

local function updateWeatherSettings(cell)
	if not cell.isExterior then
		if lastWeatherState == "interior" then return false end
		lastWeatherState = "interior"
		windDirection = util.vector3(0, 1, 0)
		local mult = s.settings.InteriorWindMult
		windPowerMin = intWindPowerMin * mult
		windPowerMax = intWindPowerMax * mult
		yawRotationSpeed = baseYawRotationSpeed * mult
		return true
	end

	local currentWeather = core.weather.getCurrent(cell)
	local nextWeather = core.weather.getNext(cell)
	local transition = core.weather.getTransition(cell) or 0

	local currentName = currentWeather and currentWeather.name
	local nextName = nextWeather and nextWeather.name
	local currentIsStorm = (currentWeather and currentWeather.isStorm) or stormWeathers[currentName]
	local nextIsStorm = (nextWeather and nextWeather.isStorm) or stormWeathers[nextName]
	
	-- fix up blight and ashstorm's incorrect reported wind directions
	local targetDirection
	if stormWeathers[currentName] then
		targetDirection = util.vector3(0, 1, 0)
	else
		targetDirection = core.weather.getCurrentStormDirection(cell)
	end
	
	-- snap wind direction when stepping outside or blend slowly
	if not lastWeatherState or lastWeatherState == "interior" then
		windDirection = targetDirection
	else
		windDirection = (windDirection * 0.9 + targetDirection * 0.1):normalize()
	end
	
	-- skip recalc if state unchanged and no active transition
	local isStorm = currentIsStorm or nextIsStorm
	local newWeatherState = isStorm and "storm" or "exterior"
	if lastWeatherState == newWeatherState and transition == 0 then
		return false
	end
	lastWeatherState = newWeatherState

	-- lerp between current and next weather
	local curMin, curMax, curYaw = getWindParams(currentIsStorm)
	if nextWeather and transition > 0 then
		local nextMin, nextMax, nextYaw = getWindParams(nextIsStorm)
		local blend = 1 - transition
		windPowerMin = curMin + (nextMin - curMin) * blend
		windPowerMax = curMax + (nextMax - curMax) * blend
		yawRotationSpeed = curYaw + (nextYaw - curYaw) * blend
	else
		windPowerMin = curMin
		windPowerMax = curMax
		yawRotationSpeed = curYaw
	end

	return true
end




local function onCellChange(cell)
    currentCellsGroup = getCellsAround(cell)
    updateWeatherSettings(cell)
    cleanUpLanterns()
    prepareLanternSearch()
end

local function onUpdate(dt)
    if dt <= 0 then return end
    
    local cell = player.cell
    if cell ~= currentCell then
        currentCell = cell
        onCellChange(cell)
    end

    -- Update weather settings periodically (once per second)
    weatherCheckTimer = weatherCheckTimer - dt
    if weatherCheckTimer <= 0 then
        updateWeatherSettings(cell)
        weatherCheckTimer = weatherCheckInterval
    end

    findLanternsDeferredStep()
    animateLanterns(dt)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        CellChange = onCellChange,
        [PLAYER_EVENT_RAYCAST_RESULT] = onRaycastResult,
        [PLAYER_EVENT_CAMERA_DIRECTION] = onCameraDirectionUpdate,
    },
    -- Public API for other scripts/plugins
    interfaceName = DEFS.mod_name,
    interface = interface
}