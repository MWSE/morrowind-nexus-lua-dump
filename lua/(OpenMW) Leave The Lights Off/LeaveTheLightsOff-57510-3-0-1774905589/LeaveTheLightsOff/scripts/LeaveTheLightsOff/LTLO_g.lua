local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local calendar = require('openmw_aux.calendar')
local vfs = require('openmw.vfs')
local core = require('openmw.core')
 
local saveData = {}
local activeLightsList = {}
local activeLightsSet = {}
local whitelistMatchSet = {}
local lightIndex = 1
local wasNight = false
local shouldRun = true
local dlrInstalled = false

-- lights waiting for AL to stop animating them
local pendingReplacements = {}
local pendingSet = {}
-- how stale the lastAnimTime must be before we consider it safe
local ANIM_STALE_THRESHOLD = 0.5
 
 
--mesh path
local modelBlacklist = {
	-- for example:
	--"meshes/l/light_ashl_lantern_01.nif",
}
 
--these are substring of the record id of the light:
local whitelistPatterns = {
	"streetlight",
	"lantern",
	"torch",
	"lamp",
	"pc_m1_anv_light_",
	"delantpaper",
	"uvi_crystal_bulb",
	--"candle",
}
 
-- all models with unique paths:
local offModels = {
	["meshes/l/light_ashl_lantern_01.nif"] = "meshes/light_ashl_lantern_01_off99.nif",
	["meshes/l/light_ashl_lantern_02.nif"] = "meshes/light_ashl_lantern_02_off99.nif",
	["meshes/l/light_ashl_lantern_03.nif"] = "meshes/light_ashl_lantern_03_off99.nif",
	["meshes/l/light_ashl_lantern_04.nif"] = "meshes/light_ashl_lantern_04_off99.nif",
	["meshes/l/light_ashl_lantern_05.nif"] = "meshes/light_ashl_lantern_05_off99.nif",
	["meshes/l/light_ashl_lantern_06.nif"] = "meshes/light_ashl_lantern_06_off99.nif",
	["meshes/l/light_ashl_lantern_07.nif"] = "meshes/light_ashl_lantern_07_off99.nif",
	["meshes/l/light_de_lantern_01.nif"] = "meshes/light_de_lantern_01_off99.nif",
	["meshes/l/light_de_lantern_02.nif"] = "meshes/light_de_lantern_02_off99.nif",
	["meshes/l/light_de_lantern_03.nif"] = "meshes/light_de_lantern_03_off99.nif",
	["meshes/l/light_de_lantern_04.nif"] = "meshes/light_de_lantern_04_off99.nif",
	["meshes/l/light_de_lantern_05.nif"] = "meshes/light_de_lantern_05_off99.nif",
	["meshes/l/light_de_lantern_06.nif"] = "meshes/light_de_lantern_06_off99.nif",
	["meshes/l/light_de_lantern_07.nif"] = "meshes/light_de_lantern_07_off99.nif",
	["meshes/l/light_de_lantern_08.nif"] = "meshes/light_de_lantern_08_off99.nif",
	["meshes/l/light_de_lantern_09.nif"] = "meshes/light_de_lantern_09_off99.nif",
	["meshes/l/light_de_lantern_10.nif"] = "meshes/light_de_lantern_10_off99.nif",
	["meshes/l/light_de_lantern_11.nif"] = "meshes/light_de_lantern_11_off99.nif",
	["meshes/l/light_de_lantern_12.nif"] = "meshes/light_de_lantern_12_off99.nif",
	["meshes/l/light_de_lantern_13.nif"] = "meshes/light_de_lantern_13_off99.nif",
	["meshes/l/light_de_lantern_14.nif"] = "meshes/light_de_lantern_14_off99.nif",
	["meshes/l/light_de_streetlight_01.nif"] = "meshes/light_de_streetlight_01_off99.nif",
	["meshes/l/light_paper_lantern_01.nif"] = "meshes/light_paper_lantern_01_off99.nif",
	["meshes/l/light_paper_lantern_02.nif"] = "meshes/light_paper_lantern_02_off99.nif",
	["meshes/l/light_paper_lantern_off.nif"] = "meshes/light_paper_lantern_off_off99.nif",
	["meshes/oaab/l/delantpaper_01.nif"] = "meshes/delantpaper_01_off99.nif",
	["meshes/oaab/l/delantpaper_02.nif"] = "meshes/delantpaper_02_off99.nif",
	["meshes/oaab/l/delantpaper_03.nif"] = "meshes/delantpaper_03_off99.nif",
	["meshes/oaab/l/delantpaperblu_01.nif"] = "meshes/delantpaperblu_01_off99.nif",
	["meshes/oaab/l/delantpaperblu_02.nif"] = "meshes/delantpaperblu_02_off99.nif",
	["meshes/oaab/l/delantpaperblu_03.nif"] = "meshes/delantpaperblu_03_off99.nif",
	["meshes/oaab/l/delantpapergrn_00.nif"] = "meshes/delantpapergrn_00_off99.nif",
	["meshes/oaab/l/delantpapergrn_01.nif"] = "meshes/delantpapergrn_01_off99.nif",
	["meshes/oaab/l/delantpapergrn_02.nif"] = "meshes/delantpapergrn_02_off99.nif",
	["meshes/oaab/l/delantpapergrn_03.nif"] = "meshes/delantpapergrn_03_off99.nif",
	["meshes/oaab/l/delantpaperred_00.nif"] = "meshes/delantpaperred_00_off99.nif",
	["meshes/oaab/l/delantpaperred_01.nif"] = "meshes/delantpaperred_01_off99.nif",
	["meshes/oaab/l/delantpaperred_02.nif"] = "meshes/delantpaperred_02_off99.nif",
	["meshes/oaab/l/delantpaperred_03.nif"] = "meshes/delantpaperred_03_off99.nif",
	["meshes/uvi/uvi_crystal_bulb_blu.nif"] = "meshes/uvi_crystal_bulb_blu_off99.nif",
	["meshes/uvi/uvi_crystal_bulb_wrm.nif"] = "meshes/uvi_crystal_bulb_wrm_off99.nif",
}
 
local replacers = {
	dlr = {
		["meshes/l/light_ashl_lantern_01.nif"] = { 100568, "meshes/dlr/light_ashl_lantern_01_off99.nif" },
		["meshes/l/light_ashl_lantern_02.nif"] = { 100583, "meshes/dlr/light_ashl_lantern_02_off99.nif" },
		["meshes/l/light_ashl_lantern_03.nif"] = { 100583, "meshes/dlr/light_ashl_lantern_03_off99.nif" },
		["meshes/l/light_ashl_lantern_04.nif"] = { 100586, "meshes/dlr/light_ashl_lantern_04_off99.nif" },
		["meshes/l/light_ashl_lantern_05.nif"] = { 100586, "meshes/dlr/light_ashl_lantern_05_off99.nif" },
		["meshes/l/light_ashl_lantern_06.nif"] = { 100586, "meshes/dlr/light_ashl_lantern_06_off99.nif" },
		["meshes/l/light_ashl_lantern_07.nif"] = { 100586, "meshes/dlr/light_ashl_lantern_07_off99.nif" },
		["meshes/l/light_de_lantern_01.nif"] = { 44741, "meshes/dlr/light_de_lantern_01_off99.nif" },
		["meshes/l/light_de_lantern_02.nif"] = { 81787, "meshes/dlr/light_de_lantern_02_off99.nif" },
		["meshes/l/light_de_lantern_03.nif"] = { 133776, "meshes/dlr/light_de_lantern_03_off99.nif" },
		["meshes/l/light_de_lantern_04.nif"] = { 174661, "meshes/dlr/light_de_lantern_04_off99.nif" },
		["meshes/l/light_de_lantern_05.nif"] = { 86566, "meshes/dlr/light_de_lantern_05_off99.nif" },
		["meshes/l/light_de_lantern_06.nif"] = { 81787, "meshes/dlr/light_de_lantern_06_off99.nif" },
		["meshes/l/light_de_lantern_07.nif"] = { 44741, "meshes/dlr/light_de_lantern_07_off99.nif" },
		["meshes/l/light_de_lantern_08.nif"] = { 133776, "meshes/dlr/light_de_lantern_08_off99.nif" },
		["meshes/l/light_de_lantern_09.nif"] = { 174661, "meshes/dlr/light_de_lantern_09_off99.nif" },
		["meshes/l/light_de_lantern_10.nif"] = { 86567, "meshes/dlr/light_de_lantern_10_off99.nif" },
		["meshes/l/light_de_lantern_11.nif"] = { 44741, "meshes/dlr/light_de_lantern_11_off99.nif" },
		["meshes/l/light_de_lantern_12.nif"] = { 133776, "meshes/dlr/light_de_lantern_12_off99.nif" },
		["meshes/l/light_de_lantern_13.nif"] = { 174661, "meshes/dlr/light_de_lantern_13_off99.nif" },
		["meshes/l/light_de_lantern_14.nif"] = { 86568, "meshes/dlr/light_de_lantern_14_off99.nif" },
		["meshes/l/light_de_streetlight_01.nif"] = { 24426, "meshes/dlr/light_de_streetlight_01_off99.nif" },
		["meshes/l/light_paper_lantern_01.nif"] = { 57291, "meshes/dlr/light_paper_lantern_01_off99.nif" },
		["meshes/l/light_paper_lantern_02.nif"] = { 57291, "meshes/dlr/light_paper_lantern_02_off99.nif" },
		--["meshes/l/light_paper_lantern_off.nif"] = {57199,					  },
	},
	dlr_glow = {
		["meshes/l/light_ashl_lantern_01.nif"] = { 101888, "meshes/dlr/light_ashl_lantern_01_off99.nif" },
		["meshes/l/light_ashl_lantern_02.nif"] = { 101898, "meshes/dlr/light_ashl_lantern_02_off99.nif" },
		["meshes/l/light_ashl_lantern_03.nif"] = { 101902, "meshes/dlr/light_ashl_lantern_03_off99.nif" },
		["meshes/l/light_ashl_lantern_04.nif"] = { 101908, "meshes/dlr/light_ashl_lantern_04_off99.nif" },
		["meshes/l/light_ashl_lantern_05.nif"] = { 101907, "meshes/dlr/light_ashl_lantern_05_off99.nif" },
		["meshes/l/light_ashl_lantern_06.nif"] = { 101911, "meshes/dlr/light_ashl_lantern_06_off99.nif" },
		["meshes/l/light_ashl_lantern_07.nif"] = { 101910, "meshes/dlr/light_ashl_lantern_07_off99.nif" },
		["meshes/l/light_de_lantern_01.nif"] = { 46056, "meshes/dlr/light_de_lantern_01_off99.nif" },
		--["meshes/l/light_de_lantern_02.nif"] = {87950,				 },
		["meshes/l/light_de_lantern_03.nif"] = { 135091, "meshes/dlr/light_de_lantern_03_off99.nif" },
		["meshes/l/light_de_lantern_04.nif"] = { 175976, "meshes/dlr/light_de_lantern_04_off99.nif" },
		--["meshes/l/light_de_lantern_05.nif"] = {87881,				  },
		--["meshes/l/light_de_lantern_06.nif"] = {87945,				  },
		["meshes/l/light_de_lantern_07.nif"] = { 46061, "meshes/dlr/light_de_lantern_07_off99.nif" },
		["meshes/l/light_de_lantern_08.nif"] = { 135096, "meshes/dlr/light_de_lantern_08_off99.nif" },
		["meshes/l/light_de_lantern_09.nif"] = { 175981, "meshes/dlr/light_de_lantern_09_off99.nif" },
		--["meshes/l/light_de_lantern_10.nif"] = {87887,				  },
		["meshes/l/light_de_lantern_11.nif"] = { 46060, "meshes/dlr/light_de_lantern_11_off99.nif" },
		["meshes/l/light_de_lantern_12.nif"] = { 135095, "meshes/dlr/light_de_lantern_12_off99.nif" },
		["meshes/l/light_de_lantern_13.nif"] = { 175980, "meshes/dlr/light_de_lantern_13_off99.nif" },
		--["meshes/l/light_de_lantern_14.nif"] = {87887,				  },
		["meshes/l/light_de_streetlight_01.nif"] = { 25741, "meshes/dlr/light_de_streetlight_01_off99.nif" },
		["meshes/l/light_paper_lantern_01.nif"] = { 58606, "meshes/dlr/light_paper_lantern_01_off99.nif" },
		["meshes/l/light_paper_lantern_02.nif"] = { 58611, "meshes/dlr/light_paper_lantern_02_off99.nif" },
		--["meshes/l/light_paper_lantern_off.nif"] = {57199,					  },
	},
	dlr_smoothed = {
		["meshes/l/light_ashl_lantern_01.nif"] = { 55207, "meshes/dlr/light_ashl_lantern_01_off99.nif" },
		["meshes/l/light_ashl_lantern_02.nif"] = { 55207, "meshes/dlr/light_ashl_lantern_02_off99.nif" },
		["meshes/l/light_ashl_lantern_03.nif"] = { 55207, "meshes/dlr/light_ashl_lantern_03_off99.nif" },
		["meshes/l/light_ashl_lantern_04.nif"] = { 55207, "meshes/dlr/light_ashl_lantern_04_off99.nif" },
		["meshes/l/light_ashl_lantern_05.nif"] = { 55207, "meshes/dlr/light_ashl_lantern_05_off99.nif" },
		["meshes/l/light_ashl_lantern_06.nif"] = { 55207, "meshes/dlr/light_ashl_lantern_06_off99.nif" },
		["meshes/l/light_ashl_lantern_07.nif"] = { 55207, "meshes/dlr/light_ashl_lantern_07_off99.nif" },
	},
	dlr_smoothed_glow = {
		["meshes/l/light_ashl_lantern_01.nif"] = { 56527, "meshes/dlr/light_ashl_lantern_01_off99.nif" },
		["meshes/l/light_ashl_lantern_02.nif"] = { 56522, "meshes/dlr/light_ashl_lantern_02_off99.nif" },
		["meshes/l/light_ashl_lantern_03.nif"] = { 56526, "meshes/dlr/light_ashl_lantern_03_off99.nif" },
		["meshes/l/light_ashl_lantern_04.nif"] = { 56529, "meshes/dlr/light_ashl_lantern_04_off99.nif" },
		["meshes/l/light_ashl_lantern_05.nif"] = { 56528, "meshes/dlr/light_ashl_lantern_05_off99.nif" },
		["meshes/l/light_ashl_lantern_06.nif"] = { 56532, "meshes/dlr/light_ashl_lantern_06_off99.nif" },
		["meshes/l/light_ashl_lantern_07.nif"] = { 56531, "meshes/dlr/light_ashl_lantern_07_off99.nif" },
	},
	rr = {
		["meshes/l/light_com_lantern_01.nif"] = { 25591, "meshes/rr/light_com_lantern_01_off99.nif" },
		["meshes/l/light_com_lantern_02.nif"] = { 25595, "meshes/rr/light_com_lantern_02_off99.nif" },
	},
	rr_enlightened_flames = {
		["meshes/l/light_com_lantern_01.nif"] = { 24530, "meshes/rr/light_com_lantern_01_off99.nif" },
		["meshes/l/light_com_lantern_02.nif"] = { 24534, "meshes/rr/light_com_lantern_02_off99.nif" },
	},
	dlr_enlightened_flames = {
		["meshes/l/light_de_lantern_02.nif"] = { 80680, "meshes/dlr/light_de_lantern_02_off99.nif" },
		["meshes/l/light_de_lantern_05.nif"] = { 85573, "meshes/dlr/light_de_lantern_05_off99.nif" },
		["meshes/l/light_de_lantern_06.nif"] = { 80672, "meshes/dlr/light_de_lantern_06_off99.nif" },
		["meshes/l/light_de_lantern_10.nif"] = { 85574, "meshes/dlr/light_de_lantern_10_off99.nif" },
		["meshes/l/light_de_lantern_14.nif"] = { 85575, "meshes/dlr/light_de_lantern_14_off99.nif" },
	},
	dlr_oaab = {
		["meshes/oaab/l/delantpapergrn_00.nif"] = { 57296, "meshes/dlr/delantpapergrn_00_off99.nif" },
		["meshes/oaab/l/delantpaperred_00.nif"] = { 57296, "meshes/dlr/delantpaperred_00_off99.nif" },
	}
}
 
local blacklist = {
	["chargen_lantern_03_sway"] = true,
}
 
--print("-------------------------------------------------------------------------")
for _, meshPath in pairs(modelBlacklist) do
	for _, record in pairs(types.Light.records) do
		if record.model == meshPath then
			blacklist[meshPath] = true
		end
		--print("blacklisted", record.id, record.model)
	end
end
 
local cachedSizes = {}
local function getFileSize(path)
	if cachedSizes[path] == nil then
		local f = vfs.open(path)
		if f then
			local size = f:seek("end")
			f:close()
			cachedSizes[path] = size
		else
			cachedSizes[path] = false
		end
	end
	return cachedSizes[path]
end
 
for replacerName, replacerData in pairs(replacers) do
	for meshPath, meshData in pairs(replacerData) do
		if getFileSize(meshPath) == meshData[1] and meshData[2] ~= nil then
			if meshData[2] == false then
				for _, record in pairs(types.Light.records) do
					if record.model == meshPath then
						blacklist[meshPath] = true
						--print("blacklisted", record.id, record.model)
					end
				end
			else
				offModels[meshPath] = meshData[2]
			end
			--print(replacerName..": "..meshPath.."("..getFileSize(meshPath)..")")
		end
	end
end
--print("-------------------------------------------------------------------------")
 
 
local function reconstructReverseLookup()
	for _, generatedRecord in pairs(types.Light.records) do
		if generatedRecord.id:find("^Generated:") and generatedRecord.isOffByDefault then
			if not saveData.reverseRecordLookup[generatedRecord.id] then
				for _, originalRecord in pairs(types.Light.records) do
					if not originalRecord.id:find("^Generated:") and not originalRecord.isOffByDefault then
						local expectedOffModel = offModels[originalRecord.model] or originalRecord.model
						if generatedRecord.model == expectedOffModel
							and generatedRecord.color == originalRecord.color
							and generatedRecord.duration == originalRecord.duration
							and generatedRecord.icon == originalRecord.icon
							and generatedRecord.isCarriable == originalRecord.isCarriable
							and generatedRecord.isDynamic == originalRecord.isDynamic
							and generatedRecord.isFire == originalRecord.isFire
							and generatedRecord.isFlicker == originalRecord.isFlicker
							and generatedRecord.isFlickerSlow == originalRecord.isFlickerSlow
							and generatedRecord.isNegative == originalRecord.isNegative
							and generatedRecord.isPulse == originalRecord.isPulse
							and generatedRecord.isPulseSlow == originalRecord.isPulseSlow
							and generatedRecord.mwscript == originalRecord.mwscript
							and generatedRecord.name == originalRecord.name
							and generatedRecord.radius == originalRecord.radius
							and generatedRecord.sound == originalRecord.sound
							and generatedRecord.value == originalRecord.value
							and generatedRecord.weight == originalRecord.weight
						then
							saveData.generatedRecords[originalRecord.id] = generatedRecord.id
							saveData.reverseRecordLookup[generatedRecord.id] = originalRecord.id
							print("LTLO: Reconstructed lookup: " .. originalRecord.id .. " -> " .. generatedRecord.id)
							break
						end
					end
				end
			end
		end
	end
end

local function isAnimatedRecently(objectId)
	if not I.AnimatedLanternsAndSigns or not I.AnimatedLanternsAndSigns.isAnimated then return false end
	local lastTime = I.AnimatedLanternsAndSigns.isAnimated(objectId)
	if lastTime == 0 then return false end
	return (core.getSimulationTime() - lastTime) < ANIM_STALE_THRESHOLD
end

local function replaceLight(oldLight, newRecordId)
	local cell = oldLight.cell
	if not cell then return nil end
 
	local oldId = oldLight.id
	local pos = oldLight.position
	local rotation = oldLight.rotation
	local scale = oldLight.scale
	local count = oldLight.count
	local startingRotation = saveData.originalRotations[oldId] or oldLight.startingRotation
 
	oldLight:remove()
	local newLight = world.createObject(newRecordId, count)
	newLight:teleport(cell, pos, { rotation = rotation })
	if I.AnimatedLanternsAndSigns then
		I.AnimatedLanternsAndSigns.replaceLantern(oldLight, newLight)
	end
	if scale ~= 1 then newLight:setScale(scale) end
 
	saveData.originalRotations[newLight.id] = startingRotation
	saveData.originalRotations[oldId] = nil

	return newLight
end
 
local function getOffRecordId(onRecordId)
	if saveData.generatedRecords[onRecordId] then
		return saveData.generatedRecords[onRecordId]
	end
 
	-- Off version doesn't exist yet, so create it
	local original = types.Light.record(onRecordId)
	local draft = { template = original, isOffByDefault = true }
 
	if offModels[original.model] then
		draft.model = offModels[original.model]
	end
 
	draft = types.Light.createRecordDraft(draft)
	local newRecord = world.createRecord(draft)
 
	saveData.generatedRecords[onRecordId] = newRecord.id
	saveData.reverseRecordLookup[newRecord.id] = onRecordId
 
	return newRecord.id
end

local function processPending()
	for i = #pendingReplacements, 1, -1 do
		local entry = pendingReplacements[i]
		local light = entry.light

		-- discard if gone
		if not light:isValid() or light.count == 0 then
			pendingSet[light.id] = nil
			table.remove(pendingReplacements, i)
			goto continue
		end

		-- still animated, keep waiting
		if isAnimatedRecently(light.id) then
			goto continue
		end

		-- safe to replace now
		local newLight = replaceLight(light, entry.newRecordId)
		if newLight and entry.regenerateKey then
			saveData.regenerateToDo[entry.regenerateKey] = nil
		end

		pendingSet[light.id] = nil
		table.remove(pendingReplacements, i)
		::continue::
	end
end

local darkWeathers = {
	Clear = false,
	Cloudy = false,
	Snow = false,
	Foggy = false,
	Overcast = false,
	Rain = false,
	Thunderstorm = false,
	Ashstorm = true,
	Blight = true,
	Blizzard = true,
}

local weatherUpdater = 0
local darkWeather = false

local function onUpdate(dt)
	if dt == 0 then return end
	
	weatherUpdater = weatherUpdater + 1
	if weatherUpdater >= 30 then
		weatherUpdater = 0
		local cell = world.players[1].cell
		if cell and cell.hasSky then
			local transition = core.weather.getTransition(cell)
			local w
			if transition and transition < 0.5 then
				w = core.weather.getNext(cell) or core.weather.getCurrent(cell)
			else
				w = core.weather.getCurrent(cell)
			end
			darkWeather = w and darkWeathers[w.name] or false
		else
			darkWeather = false --interiors lights never get registered anyway
		end
		return
	end
		
	-- drain pending replacements
	processPending()
	
	local clockHour = (calendar.gameTime() / 3600) % 24
	local isNight = clockHour < 7 or clockHour > 18 or darkWeather
	-- Full rescan only on day/night transition
	if isNight ~= wasNight then
		wasNight = isNight
		shouldRun = true
		lightIndex = 1
	end
 
	-- Swept through everything, pause until new lights or transition (not resetting index to 1)
	local tableLength = #activeLightsList
	if lightIndex > tableLength then
		shouldRun = false
	end
 
	if not shouldRun then return end
 
	local light = activeLightsList[lightIndex]
	-- Clean up invalid lights via swap-remove
	while not light:isValid() or light.count == 0 do
		activeLightsSet[light.id] = nil
		activeLightsList[lightIndex] = activeLightsList[tableLength]
		activeLightsList[tableLength] = nil
 
		tableLength = #activeLightsList
		if lightIndex > tableLength then return end
		light = activeLightsList[lightIndex]
	end
 
	-- Process light
	local currentRecordId = light.recordId
	local isCurrentOn = saveData.reverseRecordLookup[currentRecordId] == nil
	local onRecordId = isCurrentOn and currentRecordId or saveData.reverseRecordLookup[currentRecordId]
	local needsRegenerate = saveData.regenerateToDo[currentRecordId]
 
	if isNight then
		if not isCurrentOn then
			-- Turn on: replace off-light with original
			if isAnimatedRecently(light.id) then
				-- defer until AL stops animating
				if not pendingSet[light.id] then
					pendingSet[light.id] = true
					table.insert(pendingReplacements, {
						light = light,
						newRecordId = onRecordId,
					})
				end
				activeLightsSet[light.id] = nil
				activeLightsList[lightIndex] = activeLightsList[tableLength]
				activeLightsList[tableLength] = nil
				return
			else
				local newLight = replaceLight(light, onRecordId)
				if newLight then
					activeLightsSet[light.id] = nil
					activeLightsList[lightIndex] = activeLightsList[tableLength]
					activeLightsList[tableLength] = nil
					return
				end
			end
		end
	else
		if isCurrentOn or needsRegenerate then
			-- Turn off: replace with generated off-version
			local offRecordId = getOffRecordId(onRecordId)
			if isAnimatedRecently(light.id) then
				-- defer until AL stops animating
				if not pendingSet[light.id] then
					pendingSet[light.id] = true
					table.insert(pendingReplacements, {
						light = light,
						newRecordId = offRecordId,
						regenerateKey = needsRegenerate and currentRecordId or nil,
					})
				end
				activeLightsSet[light.id] = nil
				activeLightsList[lightIndex] = activeLightsList[tableLength]
				activeLightsList[tableLength] = nil
				saveData.regenerateToDo[currentRecordId] = nil
				return
			else
				local newLight = replaceLight(light, offRecordId)
				if newLight then
					activeLightsSet[light.id] = nil
					activeLightsList[lightIndex] = activeLightsList[tableLength]
					activeLightsList[tableLength] = nil
					saveData.regenerateToDo[currentRecordId] = nil
					return
				end
				saveData.regenerateToDo[currentRecordId] = nil
			end
		end
	end
 
	lightIndex = lightIndex + 1
end
 
local function whitelistMatch(str)
	if whitelistMatchSet[str] then return true end
	for _, searchPattern in ipairs(whitelistPatterns) do
		if str:find(searchPattern) then
			whitelistMatchSet[str] = true
			return true
		end
	end
	return false
end
 
local function onObjectActive(object)
	-- Check is a light that is not yet tracked
	if not types.Light.objectIsInstance(object) or activeLightsSet[object.id] then return end
 
	-- Check whitelist and not generated by this mod
	local isGenerated = saveData.reverseRecordLookup[object.recordId] ~= nil
	if not (isGenerated or whitelistMatch(object.recordId)) then return end
 
	-- Check not blacklisted
	if blacklist[object.recordId] then return end
 
	-- Check in exterior or quasi-exterior
	if not (object.cell.isExterior or object.cell.isQuasiExterior) then return end
 
	-- print(object.id, object.recordId, saveData.reverseRecordLookup[object.recordId])
	activeLightsSet[object.id] = true
	table.insert(activeLightsList, object)
	shouldRun = true
end
 
I.Activation.addHandlerForType(types.Light, function(light, actor)
	if light:isValid() and light.count > 0 and saveData.reverseRecordLookup[light.recordId] then
		local newObject = world.createObject(saveData.reverseRecordLookup[light.recordId], light.count)
		newObject:moveInto(types.NPC.inventory(actor))
		saveData.originalRotations[light.id] = nil
		light:remove()
	end
end)
 
local function onLoad(data)
	if not data then
		saveData = {
			generatedRecords = {},
			reverseRecordLookup = {},
			originalRotations = {},
		}
		-- Reconstruct lookup if saveData was wiped but generated records still exist
		reconstructReverseLookup()
	else
		saveData = data
	end
 
 
	saveData.regenerateToDo = saveData.regenerateToDo or {}
	saveData.originalRotations = saveData.originalRotations or {}
 
	-- Clean up stale generated records (user installed/removed/changed a replacer)
	local toRemove = {}
	for originalId, generatedId in pairs(saveData.generatedRecords) do
		local originalRecord = types.Light.record(originalId)
		local generatedRecord = types.Light.record(generatedId)
		if originalRecord and generatedRecord then
			local expectedModel = offModels[originalRecord.model] or originalRecord.model
			if generatedRecord.model ~= expectedModel then
				table.insert(toRemove, originalId)
				saveData.regenerateToDo[generatedId] = true
				print("LTLO: Regenerating record for " .. originalId)
			end
		end
	end
 
	for _, id in ipairs(toRemove) do
		saveData.generatedRecords[id] = nil
	end
end
 
local function onSave()
	return saveData
end
 
return {
	engineHandlers = {
		onUpdate = onUpdate,
		onObjectActive = onObjectActive,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
	},
}