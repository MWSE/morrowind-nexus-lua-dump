local config = require("Rain Sheltering.config")
local npcData = require("Rain Sheltering.npc_data")
local paths = require("Rain Sheltering.paths")

local M = {}

---@param position tes3vector3
---@param point table
local function getDistanceFromPositionToPoint(position, point)
	local targetVector = tes3vector3.new(point.x, point.y, point.z)
	return position:distance(targetVector)
end

M.isNpcNearPoint = function(npc, point)
    return getDistanceFromPositionToPoint(npc.position, point) <= config.arriveDistance
end

---@param npc tes3reference
---@param point {x: number, y: number, z: number}
M.sendNpcToPoint = function(npc, point)
    tes3.setAITravel({
        reference = npc.mobile,
        destination = tes3vector3.new(point.x, point.y, point.z) -- у point может быть name, и это таблица
    })
end

local function cancelTravelPackage(npc)
    if tes3.getCurrentAIPackageId({ reference = npc }) ~= tes3.aiPackage.travel then
        return
    end

    local data = npcData.getNpcData(npc)
    if not data then return end

    tes3.setAIWander({ -- range 0, reset true
        reference = npc.mobile,
        idles = data.originIdles
    })
end

---@param npc tes3reference
---@param callback function|nil
M.cancelTravelAndRotateSmooth = function(npc, targetAngle, callback)
    -- 1. Отменяем пакет движения к точке (назначением wander range 0)
    cancelTravelPackage(npc)

    -- 2. Поворачиваем
    local duration = 0.4 -- время поворота в секундах
    local steps = 16
    local currentStep = 0

    local currentAngle = npc.facing
    local delta = (targetAngle - currentAngle)
    delta = (delta + math.pi) % (2 * math.pi) - math.pi
    local angleStep = delta / steps

    timer.start({
        duration = duration / steps,
        iterations = steps,
        callback = function()
            currentStep = currentStep + 1
            npc.facing = npc.facing + angleStep
            -- 3. Вызываем калбэк
            if currentStep == steps and callback then
                callback()
            end
        end
    })
end

M.resetPathAndTurnBack = function(npc, data)
    -- Разворачиваем NPC на 180 (смотреть на дождь)
    M.cancelTravelAndRotateSmooth(npc, npc.facing + math.pi)

    -- Обнуляем маршрут
    data.nextPoint = 1  -- чтобы при получении маршрута обратно двигался по нему
    data.keyPoints = { data.shelterPoint } -- чтобы при откате в "toShelter" (от вступления в бой) мог вернуться
end

M.sendNpcToNextPoint = function(npc, data)
    cancelTravelPackage(npc)
    data.nextPoint = data.nextPoint + 1
    M.sendNpcToPoint(npc, data.keyPoints[data.nextPoint])
end

---@return {x: number, y: number, z: number}[]|nil - 1/2 точки входа/выхода на мост, если это необходимо
local function buildRouteAcrossRiver(origin, cellKey, shelterPoint)
    if not paths.hasBridge(cellKey) then return end

    local keyPoints
    -- Поиск пути через реку
    local originSide = paths.onWhichSideOfRiver(cellKey, origin.x, origin.y)
    local shelterSide = paths.onWhichSideOfRiver(cellKey, shelterPoint.x, shelterPoint.y)
    if originSide ~= shelterSide then
        local onBridge = (originSide == "on bridge")
        -- 1. Определяем, на каком берегу искать ближайший мост
        -- Если origin на мосту - ищем вход на стороне укрытия
        local searchBank = onBridge and paths[shelterSide .. "Bridges"][cellKey]
                           or paths[originSide .. "Bridges"][cellKey] -- иначе - на стороне origin

        -- 2. Находим индекс ближайшего моста
        local bridgeIdx = 1
        local minDist = getDistanceFromPositionToPoint(origin, searchBank[1])
        for i = 2, #searchBank do
            local dist = getDistanceFromPositionToPoint(origin, searchBank[i])
            if dist < minDist then
                minDist = dist
                bridgeIdx = i
            end
        end
        -- 3. Формируем маршрут
        if onBridge then
            -- Если origin на мосту, нужна только точка выхода на берег с укрытием
            keyPoints = { paths[shelterSide .. "Bridges"][cellKey][bridgeIdx] }
        else -- Если на берегу, нужны две точки: вход и выход
            keyPoints = {
                paths[originSide .. "Bridges"][cellKey][bridgeIdx],
                paths[shelterSide .. "Bridges"][cellKey][bridgeIdx]
            }
        end

        return keyPoints
    end
end

local function checkForMiddlePoints(origin, cellKey, shelterPoint)
    local middlePoints = buildRouteAcrossRiver(origin, cellKey, shelterPoint)

    return middlePoints
end

---@param origin tes3vector3
---@param shelterPoint {name: string, x: number, y: number, z: number}
---@return {x: number, y: number, z: number}[]
local function buildRouteKeyPointsForShelter(origin, cellKey, shelterPoint)
    local originZonePoints = paths.getOriginZonePath(origin)
    local middleZonePoints = checkForMiddlePoints(origin, cellKey, shelterPoint)
    local shelterZonePoints = paths.getShelterZonePath(origin, shelterPoint.name)

    local keyPoints = {}

    local function appendPoints(points)
        if not points then return end
        for i = 1, #points do
            table.insert(keyPoints, points[i])
        end
    end

    appendPoints(originZonePoints)
    appendPoints(middleZonePoints)
    appendPoints(shelterZonePoints)
    table.insert(keyPoints, shelterPoint)

    return keyPoints
end

---@param startPoint tes3vector3
---@param keyPoints {x: number, y: number, z: number}[]
---@param maxDistance number
---@return number
local function calcRouteDistance(startPoint, keyPoints, maxDistance)
    local totalDistance = 0
    local currentPoint = startPoint

    for i = 1, #keyPoints do
        local nextPoint = keyPoints[i]
        totalDistance = totalDistance + getDistanceFromPositionToPoint(currentPoint, nextPoint)
        -- Если общее расстояние на текущем шаге уже больше максимального - не досчитываем
        if totalDistance > maxDistance then
            return totalDistance
        end

        currentPoint = tes3vector3.new(nextPoint.x, nextPoint.y, nextPoint.z)
    end

    return totalDistance
end

---@param origin tes3vector3
---@param cellKey string cell.id
---@param shelterPoint {name: string, x: number, y: number, z: number}
---@param maxDistance number|nil
---@return number
M.getEstimatedDistanceToShelter = function(origin, cellKey, shelterPoint, maxDistance)
    local keyPoints = buildRouteKeyPointsForShelter(origin, cellKey, shelterPoint)
    return calcRouteDistance(origin, keyPoints, maxDistance)
end

-- Строит маршрут из origin в shelterPoint, или наоборот
M.buildRoute = function(npc, cellKey, endPoint)
    local data = npcData.getNpcData(npc)
    if not data then return end

    -- 1. Если существуют промежуточные проложенные маршруты - получаем их
    local originZonePoints = paths.getOriginZonePath(data.origin)
    local middleZonePoints = checkForMiddlePoints(data.origin, cellKey, data.shelterPoint)
    local shelterZonePoints = paths.getShelterZonePath(data.origin, data.shelterPoint.name)

    -- ранний выход
    if not originZonePoints
        and not middleZonePoints
        and not shelterZonePoints then
        data.keyPoints = { endPoint }
        return
    end

    -- 2. Определяем направление
    local isGoingBack = false
    if endPoint == data.origin then
        isGoingBack = true
    end

    -- 3. Объединяем промежуточные маршруты, в порядке направления
    -- Если погода изменилась по пути к endPoint, и нужно перестроить существующий маршрут
    -- обнуляем keyPoints перед вставкой в него нового маршрута
    data.keyPoints = {}

    local function appendPoints(points)
        if not points then return end
        if isGoingBack then -- Инвертируем массив точек
            for i = #points, 1, -1 do
                table.insert(data.keyPoints, points[i])
            end
        else -- Копируем массив точек
            for i = 1, #points do
                table.insert(data.keyPoints, points[i])
            end
        end
    end

    if isGoingBack then -- От укрытия: Сначала точки укрытия, потом исходной зоны
        appendPoints(shelterZonePoints)
        appendPoints(middleZonePoints)
        appendPoints(originZonePoints)
    else -- К укрытию: Сначала точки выхода из зоны, потом точки по пути к укрытию
        appendPoints(originZonePoints)
        appendPoints(middleZonePoints)
        appendPoints(shelterZonePoints)
    end

    -- 4. Добавляем точку назначения
    table.insert(data.keyPoints, endPoint)
end

return M