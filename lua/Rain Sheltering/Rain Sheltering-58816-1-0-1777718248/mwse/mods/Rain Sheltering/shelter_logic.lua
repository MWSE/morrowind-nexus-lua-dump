local state = require("Rain Sheltering.state")
local config = require("Rain Sheltering.config")
local sheltersByCellKey = require("Rain Sheltering.shelter_locations")
local isValidNpc = require("Rain Sheltering.isValidNpc")
local navigation = require("Rain Sheltering.navigation")
local npcData = require("Rain Sheltering.npc_data")
local getCurrentTime = require("Rain Sheltering.getCurrentTime")
require("Rain Sheltering.time_skip")
--- Логика укрытий от дождя: поиск точек, занятость, travel, поворот на месте, возврат.

local function getPlayerData()
	local data = tes3.player.data
	data.rainShelter = data.rainShelter or {}
	local playerData = data.rainShelter
	playerData.occupiedShelters = playerData.occupiedShelters or {}

	return playerData
end

-- Возвращает таблицу занятых убежищ в ячейке
local function getOrCreateCellOccupancy(cellKey)
	local playerData = getPlayerData()

	playerData.occupiedShelters[cellKey] = playerData.occupiedShelters[cellKey] or {}
	return playerData.occupiedShelters[cellKey]
end

---@return boolean
local function isShelterOccupiedByAnother(cellKey, shelterName, npcId)
	local occupancy = getOrCreateCellOccupancy(cellKey)
	local occupiedBy = occupancy[shelterName]
	return occupiedBy and occupiedBy ~= npcId
end

-- Возвращает ближайшее не занятое укрытие (запись из shelter_locations.lua) в пределах досягаемости
local function findNearestFreeShelter(reference, shelters, cellKey)
	local nearest = nil
	local nearestDistance = config.maxShelterDistance
	for _, point in ipairs(shelters) do
		if not isShelterOccupiedByAnother(cellKey, point.name, reference.id) then
			-- Замер маршрута значительно увеличивает нагрузку в момент начала дождя, но она все еще ничтожна.
			local d = navigation.getEstimatedDistanceToShelter(reference.position, cellKey, point, nearestDistance)
			if d <= nearestDistance then
				nearest = point
				nearestDistance = d
			end
		end
	end

	return nearest
end

-- Записывает укрытие за NPC
local function occupyShelter(cellKey, shelterName, npcId)
	local occupancy = getOrCreateCellOccupancy(cellKey)
	occupancy[shelterName] = npcId
end

-- Записывает npcData, занимает и отправляет NPC в укрытие
local function sendNpcToShelter(npc, shelterPoint, cellKey)
	-- Записываем в NPC данные о выбранном укрытии и исходное положение
	npcData.saveNpcShelterState(npc, cellKey, shelterPoint)
	occupyShelter(cellKey, shelterPoint.name, npc.id)
	-- Строим маршрут к укрытию
	navigation.buildRoute(npc, cellKey, shelterPoint)
	navigation.sendNpcToPoint(npc, npcData.getNpcData(npc).keyPoints[1])
end

-- Если при нахождении в укрытии начался бой (поставился "toShelter") - по окончанию возвращаем в укрытие
local function checkIfInCombat(npc, data)
	if data.inCombat then
		if npc.mobile.inCombat then return end
		-- Потом снова отправляем в последнюю точку (или укрытие)
		--[[ Можно построить маршрут сложнее, не перезаписывая origin:
			В то же убежище, или освободить и занять (за)новое.
			Но в любом из этих случаев, если маршрут изменится на пол пути - 
			построится маршрут в origin/shelter, возможно, с другим количеством ключевых точек
			Что приведет к неправильному пересчету nextPoint.

			Так что пусть идет в укрытие, даже если на пути препятствие, и нужно вечно идти в стену.
			Пока не телепортируется по отсутсвию персонажа.
    		В оригинале NPC корректно возвращаются после агра.
		]]--
		data.inCombat = false
		navigation.sendNpcToPoint(npc, data.keyPoints[data.nextPoint])
	end
end

-- Останавливаем, разворачиваем на 180, меняем фазу
local function onArriveAtShelter(npc, data)
	navigation.resetPathAndTurnBack(npc, data)
	data.phase = "atShelter"
end

-- Нужно возвращать NPC, если он убежит (в бой)
local function stayAtShelter(npc, data)
	-- Если начался бой, пока NPC в укрытии - переводим в "toShelter", чтобы потом вернулся
	if npc.mobile.inCombat then
		data.inCombat = true
		data.phase = "toShelter"
	end
end

local function restoreOriginBehavior(npc, data)
	tes3.setAIWander({
		reference = npc.mobile,
		idles = data.originIdles,
		range = data.range,
		duration = data.duration,
		time = data.time,
		reset = true
	})
end

-- Выписываем NPC из укрытия
local function releaseShelter(cellKey, shelterName, npcId)
	local playerData = getPlayerData()
	if not playerData.occupiedShelters[cellKey] then return end

	if playerData.occupiedShelters[cellKey][shelterName] == npcId then
		playerData.occupiedShelters[cellKey][shelterName] = nil
	end
end

-- Выписывает NPC из укрытия и очищает data
local function clearNpcShelterState(npc)
	local data = npcData.getNpcData(npc)
	if not data then return end

	releaseShelter(data.cellKey, data.shelterName, npc.id)
	npcData.clear(npc)
end

-- Поворачиваем в исходную сторону, восстанавливаем исходное поведение, обнуляем данные, выписываем из укрытия
local function onReturningOrigin(npc, data)
	-- Поворачиваем в исходную сторону
	navigation.cancelTravelAndRotateSmooth(npc, data.originFacing, function()
		restoreOriginBehavior(npc, data) -- восстанавливаем исходный AIWander
	end)
	-- обнуляем записанные в NPC данные, и выписываем его из укрытия
	clearNpcShelterState(npc)
end

local function updateShelteringNpc(npc, data)
	data.lastSeenTime = getCurrentTime()
	-- Если NPC движется к укрытию
	if data.phase == "toShelter" then
		checkIfInCombat(npc, data)

		-- И уже дошел до укрытия
		if navigation.isNpcNearPoint(npc, data.shelterPoint) then
			onArriveAtShelter(npc, data)
		-- Если еще в пути
		elseif navigation.isNpcNearPoint(npc, data.keyPoints[data.nextPoint]) then
			-- Если пришел на промежуточную точку - назначаем следующую
			navigation.sendNpcToNextPoint(npc, data)
		end
	elseif data.phase == "atShelter" then
		-- Здесь нужно проверять на бой, т.к AIWander 0 не вернет потом в укрытие
		stayAtShelter(npc, data)
	-- Если NPC возвращается из укрытия
	elseif data.phase == "returning" then
		-- Если уже вернулся на исходную позицию - возвращается к своим делаем:
		if navigation.isNpcNearPoint(npc, data.origin) then
			onReturningOrigin(npc, data)
		-- Если еще в пути
		elseif navigation.isNpcNearPoint(npc, data.keyPoints[data.nextPoint]) then
			-- Если пришел на промежуточную точку - назначаем следующую
			navigation.sendNpcToNextPoint(npc, data)
		end
	end
end

-- Выписывает NPC из укрытия, направляет в исходную точку, ставит фазу "returning"
local function beginNpcReturn(npc, data)
	navigation.buildRoute(npc, data.cellKey, data.origin)

	if data.phase == "atShelter" then
		navigation.sendNpcToPoint(npc, data.keyPoints[1])
	else --"toShelter" Если дождь закончился пока NPC шел в укрытие
		-- нужно обновить nextPoint для новопостроенного маршрута
		data.nextPoint = #data.keyPoints - data.nextPoint
		navigation.sendNpcToNextPoint(npc, data)
	end
	data.phase = "returning"
end

-- Возвращает таблицу shelterPoint-ов в ячейке
local function collectShelters(cellKey)
	return sheltersByCellKey[cellKey] or {}
end

-- Найти ближайшее свободное укрытие и отправить туда NPC
local function seekShelter(npc, shelters, cellKey)
	-- ищем ближайшее не занятое укрытие в пределах досягаемости
	local nearest = findNearestFreeShelter(npc, shelters, cellKey)
	if nearest then -- И отправляем туда NPC. Записываем укрытие за ним
		sendNpcToShelter(npc, nearest, cellKey)
	end
end

-- Возвращает NPC обратно в укрытие (если по пути в origin начался дождь)
local function backToShelter(npc, cellKey, data)
	-- Перестраиваем маршрут (в обратном порядке)
	navigation.buildRoute(npc, cellKey, data.shelterPoint)
	-- нужно обновить nextPoint для новопостроенного маршрута
	data.nextPoint = #data.keyPoints - data.nextPoint
	navigation.sendNpcToNextPoint(npc, data)
	data.phase = "toShelter"
end

local function processNpcSheltering(npc, shelters, cellKey)
	-- Состояние NPC, при котором его нужно выписать из укрытия
	if not isValidNpc(npc) then
		clearNpcShelterState(npc)
		return
	end

	local package = tes3.getCurrentAIPackageId({ reference = npc })
	if package == tes3.aiPackage.none then -- у мертвых тоже none, но их надо выписывать
		return
	end

	local data = npcData.getNpcData(npc)
	-- Если укрытия нет, и начался дождь
	if data == nil then -- пытаемся найти укрытие для NPC, и отправем его в него
		-- Я не отправляю во время travel, но, если бы это произошло, в idles записался бы nil
		-- и нельзя было восстановить origin поведение. Т.к NPC обычно в wander, а travel назначается скриптами
		if package == tes3.aiPackage.travel then return end
		seekShelter(npc, shelters, cellKey)
	-- Если NPC уже выбрал себе укрытие
	elseif data.phase == "toShelter" or data.phase == "atShelter" then
		-- Выполняем действия, соответствующие текущей фазе взаимодействия с укрытием
		updateShelteringNpc(npc, data)
	else -- Дождь снова началася во время "returning" в origin
		backToShelter(npc, cellKey, data)
	end
end

local function getCellKey(cell)
    if not cell or not cell.id then
        return nil
    end
    return cell.id
end

local function isExteriorCell(cell)
    return cell and cell.isOrBehavesAsExterior == true
end

-- Если дождь есть - каждые config.checkInverval вызывается эта функция
local function processSheltering()
	-- Обрабатываем поведение NPC в каждой из подходящих ячеек
	for cell, _ in pairs(state.cellsToSheltering) do
		local cellKey = getCellKey(cell) -- id
		if not isExteriorCell(cell) then return end
		-- Получаем таблицу укрытий в ячейке
		---------- Если стражник в бою выбежал из ячейки с укрытиями - он выпадает из циклов.
		local shelters = collectShelters(cellKey)
		if #shelters == 0 then return end

		-- Обрабатываем каждого NPC в ячейке
       	for npc in cell:iterateReferences(tes3.objectType.npc) do
           	processNpcSheltering(npc, shelters, cellKey)
       	end
	end
end

local function releaseNpcFromShelter(npc)
	local data = npcData.getNpcData(npc)
	if not data then return end

	if not isValidNpc(npc) then
		clearNpcShelterState(npc)
		return
	end

	local package = tes3.getCurrentAIPackageId({ reference = npc })
	if package == tes3.aiPackage.none then return end

	if data.phase ~= "returning" then
		-- Выписываем NPC из укрытия, направляем в исходную точку, ставим фазу "returning"
		beginNpcReturn(npc, data)
	else -- Возврат к исходной точке и занятию
		updateShelteringNpc(npc, data)
	end
end

-- Если дождя нет - каждые config.checkInverval вызывается эта функция
local function releaseAllShelters()
	for cell, _ in pairs(state.cellsToSheltering) do
		if not isExteriorCell(cell) then return end
		-- Выпускаем всех NPC в ячейке из укрытий
       	for npc in cell:iterateReferences(tes3.objectType.npc) do
           	releaseNpcFromShelter(npc)
       	end
	end
end

--- Time sync logic

local function teleportNpcToOrigin(npc, data)
	npc.position = data.origin
	npc.facing = data.originFacing
end

local function resetNpc(npc, data)
	teleportNpcToOrigin(npc, data)
	restoreOriginBehavior(npc, data)
	clearNpcShelterState(npc)
end

local function hasCellShelters(cell)
	return sheltersByCellKey[cell.id] ~= nil
end

local function canCellBeSheltered(cell)
	return isExteriorCell(cell) and hasCellShelters(cell)
end

-- time_skip.lua. Телепортируем всех NPC в активных ячейках после ожидания/отдыха
local function onTimeSkip(e)
	if e.elapsedTime < config.unloadedNpcTeleportDelay then return end

    for _, cell in ipairs(tes3.getActiveCells()) do
        if canCellBeSheltered(cell) then
            for npc in cell:iterateReferences(tes3.objectType.npc) do
                local data = npcData.getNpcData(npc)
                if data then
                    resetNpc(npc, data)
                end
            end
        end
    end
end
event.register("RainShelter:TimeSkip", onTimeSkip)

-- Телепортируем NPC из этой ячейки в их origin, если мы их долго не видели (отсутствовали)
local function resetNpcIfLongAbsence(npc, data, currentTime)
	--[[ Пытался добавить зависимость от текущей погоды.
	Чтобы NPC не телепортировались всегда после долго отсутствия, а
	если здесь дождь - продолжали идти в укрытие с последней точки (в идеале вообще телепортировались).

	Но проблема в том, как брать текущее состояние дождя:
	1) tes3.getCurrentWeather() и tes3.worldController.weatherController.currentWeather - 
	еще не обновились в onCellActivated
	Это период от полноценного начала дождя, и до полноценного наступления следующей погоды.
	2) tes3cell.region.weather включает в себя период, когда тучи еще только потихоньку сходятся для дождя.
	И не включают период, когда они расходятся для следующей погоды, и уже ничего не капает.

	К тому же, тогда способ взятия дождя и state.isRaining должны браться одинаково, иначе
	если после возврата в ячейку дождь заканчивается - region показывает false - NPC телепортируются,
	в следующем onSimulate worldController показывает true - они идут к укрытию.
	Тучи рассеиваются - идут обрато.
	Либо, если везде region - NPC уходят по-сухому, а возвращаются когда еще идет дождь.
	]]--
	-- Если был дождь в последний раз, когда мы видели NPC
	if data and data.lastSeenTime then
		local timeDiff = currentTime - data.lastSeenTime
		-- Если игрока не было больше unloadedNpcTeleportDelay часов
		if timeDiff > config.unloadedNpcTeleportDelay then
			resetNpc(npc, data)
		end
	else -- Если дождя не было, мы вернулись, и он есть - можно тпшить их сразу в укрытия.
		-- Но это дублирование частей разных функций, + вопрос в фейсинге. Пока не хочу.
		-- Пусть просто идут пешком вместе с нами.
	end
end

local function prepareNpcsInCell(cell)
	local currentTime = getCurrentTime()

	for npc in cell:iterateReferences(tes3.objectType.npc) do
		local data = npcData.getNpcData(npc)
		npcData.restoreNpcData(data)

		------------потенциальная проблема, если NPC проходит в укрытие по ячейке, в которой укрытий нет
		resetNpcIfLongAbsence(npc, data, currentTime)
	end
end

local function onCellActivated(e)
	local cell = e.cell
	if not canCellBeSheltered(cell) then return end
	-- Добавляем ячейку в массив ячеек, которые нужно обрабатывать каждые checkInterval
	state.cellsToSheltering[cell] = true
	-- Восстановить данные после загрузки, и телепортировать NPC в origin, если нас здесь долго не было
	prepareNpcsInCell(cell)
end
event.register("cellActivated", onCellActivated)

local function onCellDeactivated(e)
	state.cellsToSheltering[e.cell] = nil
end
event.register("cellDeactivated", onCellDeactivated)

local function resetActiveCells()
	-- Очищаем таблицу полностью, так как cellActivated уже мог сработать
	table.clear(state.cellsToSheltering)
	-- И заполняем массив активными ячейками вручную
	for _, cell in ipairs(tes3.getActiveCells()) do
		if canCellBeSheltered(cell) then
			state.cellsToSheltering[cell] = true
		end
	end
end

return {
	processSheltering = processSheltering,
	releaseAllShelters = releaseAllShelters,
	resetActiveCells = resetActiveCells,
	restoreAllNpcsData = npcData.restoreAllNpcsData,
}