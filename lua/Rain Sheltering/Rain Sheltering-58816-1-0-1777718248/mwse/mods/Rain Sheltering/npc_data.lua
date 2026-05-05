local getCurrentTime = require("Rain Sheltering.getCurrentTime")

local M = {}

M.getNpcData = function(npc)
    return npc.data.rainShelter
end

M.clear = function(npc)
	npc.data.rainShelter = nil
end

M.saveNpcShelterState = function(npc, cellKey, shelterPoint)
	-- Запоминаем исходное положение NPC
	local origin = npc.position:copy()

	local originAiPackage = npc.mobile.aiPlanner:getActivePackage()
	local originIdles = {}
	if originAiPackage and originAiPackage.idles then
		for i = 1, #originAiPackage.idles do
			originIdles[i] = originAiPackage.idles[i].chance
		end
	end

	-- Записываем в NPC данные о выбранном укрытии и исходное положение
	npc.data.rainShelter = {
		phase = "toShelter",
		cellKey = cellKey,
		shelterName = shelterPoint.name,
		shelterPoint = shelterPoint,
		origin = origin,
		originIdles = originIdles,
		range = originAiPackage.distance,
		duration = originAiPackage.duration,
		time = originAiPackage.startGameHour,
		keyPoints = {},
		nextPoint = 1,
		lastSeenTime = getCurrentTime(),
		originFacing = npc.facing,
		inCombat = npc.mobile.inCombat,
	}
end

-- Воскрешение после сериализации JSON
M.restoreNpcData = function(data)
    if data then
        data.origin = tes3vector3.new(data.origin.x, data.origin.y, data.origin.z)
    end
end

M.restoreAllNpcsData = function()
    for _, cell in ipairs(tes3.getActiveCells()) do
        for npc in cell:iterateReferences(tes3.objectType.npc) do
            local data = M.getNpcData(npc)
            M.restoreNpcData(data)
        end
    end
end

return M