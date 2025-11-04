local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local calendar = require('openmw_aux.calendar')
local activeLights = {}
local iterateLights = nil

local offModels = {
	["meshes/l/light_ashl_lantern_01.nif"] =	"meshes/light_ashl_lantern_01_off99.nif",
	["meshes/l/light_ashl_lantern_02.nif"] =	"meshes/light_ashl_lantern_02_off99.nif",
	["meshes/l/light_ashl_lantern_03.nif"] =	"meshes/light_ashl_lantern_03_off99.nif",
	["meshes/l/light_ashl_lantern_04.nif"] =	"meshes/light_ashl_lantern_04_off99.nif",
	["meshes/l/light_ashl_lantern_05.nif"] =	"meshes/light_ashl_lantern_05_off99.nif",
	["meshes/l/light_ashl_lantern_06.nif"] =	"meshes/light_ashl_lantern_06_off99.nif",
	["meshes/l/light_ashl_lantern_07.nif"] =	"meshes/light_ashl_lantern_07_off99.nif",
	["meshes/l/light_de_lantern_01.nif"] =	  "meshes/light_de_lantern_01_off99.nif",
	["meshes/l/light_de_lantern_03.nif"] =	  "meshes/light_de_lantern_03_off99.nif",
	["meshes/l/light_de_lantern_04.nif"] =	  "meshes/light_de_lantern_04_off99.nif",
	["meshes/l/light_de_lantern_05.nif"] =	  "meshes/light_de_lantern_05_off99.nif",
	["meshes/l/light_de_lantern_07.nif"] =	  "meshes/light_de_lantern_07_off99.nif",
	["meshes/l/light_de_lantern_08.nif"] =	  "meshes/light_de_lantern_08_off99.nif",
	["meshes/l/light_de_lantern_09.nif"] =	  "meshes/light_de_lantern_09_off99.nif",
	["meshes/l/light_de_lantern_10.nif"] =	  "meshes/light_de_lantern_10_off99.nif",
	["meshes/l/light_de_lantern_11.nif"] =	  "meshes/light_de_lantern_11_off99.nif",
	["meshes/l/light_de_lantern_12.nif"] =	  "meshes/light_de_lantern_12_off99.nif",
	["meshes/l/light_de_lantern_13.nif"] =	  "meshes/light_de_lantern_13_off99.nif",
	["meshes/l/light_de_lantern_14.nif"] =	  "meshes/light_de_lantern_14_off99.nif",
	["meshes/l/light_de_streetlight_01.nif"] =  "meshes/light_de_streetlight_01_off99.nif",
	["meshes/l/light_paper_lantern_01.nif"] =   "meshes/light_paper_lantern_01_off99.nif",
	["meshes/l/light_paper_lantern_02.nif"] =   "meshes/light_paper_lantern_02_off99.nif",
	["meshes/l/light_paper_lantern_off.nif"] =  "meshes/light_paper_lantern_off_off99.nif",
	
}

local whitelistPatterns = {
	"streetlight",
	"lantern",
	"torch",
	"lamp",
	--"candle",
}

local blacklist = {
	["chargen_lantern_03_sway"] = true,
}

--local blacklistPatterns = {
--	"campfire",
--	"pitfire",
--	"firepit",
--	"lava",
--	"blue water ref",
--	"blue coast ref",
--	"light_fire",
--	"logpile",
--	"flame light",
--	"blue ice",
--	"brazier",
--	
--}
--local blacklist = {
--	["t_mw_light_aanthirinmushroom"] = true,
--	["t_mw_light_bloatspore_128"] = true,
--	["t_mw_light_bloatspore_512"] = true,
--	["t_mw_light_bulbshroom_256"] = true,
--	["t_mw_light_bulbshroom_1024"] = true,
--	["t_mw_light_glowshrooms_128"] = true,
--	["t_mw_light_glowshrooms_256"] = true,
--	["t_mw_light_glowshrooms_512"] = true,
--	["t_glb_light_plant_128"] = true,
--	["t_glb_light_plant_256"] = true,
--	["t_glb_light_plant_512"] = true,
--	["t_glb_light_plant_64"] = true,
--	["t_glb_light_sheggoshelf_128"] = true,
--	["t_glb_light_sheggoshelf_256"] = true,
--	["t_glb_light_sheggoshelf_512"] = true,
--	["t_glb_light_sheggoshelf_77"] = true,
--	["t_glb_light_shroom1_128"] = true,
--	["t_glb_light_shroom2_128"] = true,
--	["t_glb_light_shroom3_128"] = true,
--	["t_glb_light_shroom4_128"] = true,
--	["t_glb_light_wispstalk_64"] = true,
--	["bc mushroom 64"] = true,
--	["bc mushroom 128"] = true,
--	["bc mushroom 177"] = true,
--	["bc mushroom 256"] = true,
--	["orange_128_01_d"] = true,
--	["orange_256_ci_02"] = true,
--	--["blue coast ref 1024"] = true,
--	--["blue water ref 128"] = true,
--	["red_64"] = true,
--	["dark_128"] = true,
--	["green light_128"] = true,
--	["dark_512_01"] = true,
--	["dark_256_d_01"] = true,
--	["dark_256"] = true,
--	["orange_768_01"] = true,
--	["green light_400"] = true,
--	["tr_fm_lighthousefire"] = true,
--	["tr_m1_fw_lighthouse_fire"] = true,
--	["ab_light_telexballlamp01_256"] = true,
--	["llcs_slave_lamp"] = true,
--	["uvi_crystal_bulb_blue"] = true,
--	["uvi_crystal_bulb_warm"] = true,
--	--["light_fire"] = true,
--	--["light_fire"] = true,
--	--["blue water ref 512"] = true,
--	--["lava_light_700"] = true,
--}


local function onUpdate(dt)
	if dt == 0 then return end
	iterateLights, light = next(activeLights, iterateLights)
	if light then
		if not light:isValid() or light.count == 0 then
			table.remove(activeLights, iterateLights)
		else
			--processLight
			local clockHour = tonumber(calendar.formatGameTime("%H", calendar.gameTime()))
			local isNight = false
			if clockHour < 7 or clockHour > 19 then
				isNight = true
			end
			if isNight and saveData.reverseRecordLookup[light.recordId] then
				local pos = light.position
				local cell = light.cell
				local rotation = light.rotation
				local scale = light.scale
				local count = light.count
				light:remove()
				local newObject = world.createObject(saveData.reverseRecordLookup[light.recordId], count)
				newObject:teleport(cell, pos, {rotation = rotation})
			elseif not isNight and not saveData.reverseRecordLookup[light.recordId] then
				if not saveData.generatedRecords[light.recordId] then
					local original = types.Light.record(light)
					local draft = {template =original, isOffByDefault = true}
					if offModels[original.model] then
						draft.model = offModels[original.model]
					end
					draft = types.Light.createRecordDraft(draft)
					local newRecord = world.createRecord(draft)
					saveData.generatedRecords[light.recordId] = newRecord.id
					saveData.reverseRecordLookup[newRecord.id] = light.recordId
				end
				local pos = light.position
				local cell = light.cell
				local rotation = light.rotation
				local scale = light.scale
				local count = light.count
				light:remove()
				local newObject = world.createObject(saveData.generatedRecords[light.recordId], count)
				newObject:teleport(cell, pos, {rotation = rotation})
			end
		end
	end
end

local function onObjectActive(object)
	if types.Light.objectIsInstance(object) then
		--if blacklist[object.recordId] then
		--	return
		--end
		local validRecord = false
		for _, searchPattern in pairs(whitelistPatterns) do
			if object.recordId:find(searchPattern) then
				validRecord = true
			end
		end
		if blacklist[object.recordId] or not saveData.reverseRecordLookup[object.recordId] and not validRecord then
			--print(object.recordId)
			return
		end
		if object.cell.isExterior or object.cell.isQuasiExterior then
			--print(object.recordId, saveData.reverseRecordLookup[object.recordId])
			table.insert(activeLights,object)
		end
	end
end

local function onLoad(data)
	saveData = data or {
		generatedRecords = {}, 
		reverseRecordLookup = {}
	}
end

local function onSave()
	return saveData
end

return{
	engineHandlers = { 
		onUpdate = onUpdate,
		onObjectActive = onObjectActive,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
	},
}