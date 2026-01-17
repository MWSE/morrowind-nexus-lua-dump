local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local calendar = require('openmw_aux.calendar')
local vfs = require('openmw.vfs')
local activeLights = {}
local iterateLights = nil
local dlrInstalled = false

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
	["meshes/l/light_ashl_lantern_01.nif"] =	"meshes/light_ashl_lantern_01_off99.nif",
	["meshes/l/light_ashl_lantern_02.nif"] =	"meshes/light_ashl_lantern_02_off99.nif",
	["meshes/l/light_ashl_lantern_03.nif"] =	"meshes/light_ashl_lantern_03_off99.nif",
	["meshes/l/light_ashl_lantern_04.nif"] =	"meshes/light_ashl_lantern_04_off99.nif",
	["meshes/l/light_ashl_lantern_05.nif"] =	"meshes/light_ashl_lantern_05_off99.nif",
	["meshes/l/light_ashl_lantern_06.nif"] =	"meshes/light_ashl_lantern_06_off99.nif",
	["meshes/l/light_ashl_lantern_07.nif"] =	"meshes/light_ashl_lantern_07_off99.nif",
	["meshes/l/light_de_lantern_01.nif"] =	  "meshes/light_de_lantern_01_off99.nif",
	["meshes/l/light_de_lantern_02.nif"] =	  "meshes/light_de_lantern_02_off99.nif",
	["meshes/l/light_de_lantern_03.nif"] =	  "meshes/light_de_lantern_03_off99.nif",
	["meshes/l/light_de_lantern_04.nif"] =	  "meshes/light_de_lantern_04_off99.nif",
	["meshes/l/light_de_lantern_05.nif"] =	  "meshes/light_de_lantern_05_off99.nif",
	["meshes/l/light_de_lantern_06.nif"] =	  "meshes/light_de_lantern_06_off99.nif",
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
	["meshes/oaab/l/delantpaper_01.nif"] =   "meshes/delantpaper_01_off99.nif",
	["meshes/oaab/l/delantpaper_02.nif"] =   "meshes/delantpaper_02_off99.nif",
	["meshes/oaab/l/delantpaper_03.nif"] =   "meshes/delantpaper_03_off99.nif",
	["meshes/oaab/l/delantpaperblu_01.nif"] =   "meshes/delantpaperblu_01_off99.nif",
	["meshes/oaab/l/delantpaperblu_02.nif"] =   "meshes/delantpaperblu_02_off99.nif",
	["meshes/oaab/l/delantpaperblu_03.nif"] =   "meshes/delantpaperblu_03_off99.nif",
	["meshes/oaab/l/delantpapergrn_00.nif"] =   "meshes/delantpapergrn_00_off99.nif",
	["meshes/oaab/l/delantpapergrn_01.nif"] =   "meshes/delantpapergrn_01_off99.nif",
	["meshes/oaab/l/delantpapergrn_02.nif"] =   "meshes/delantpapergrn_02_off99.nif",
	["meshes/oaab/l/delantpapergrn_03.nif"] =   "meshes/delantpapergrn_03_off99.nif",
	["meshes/oaab/l/delantpaperred_00.nif"] =   "meshes/delantpaperred_00_off99.nif",
	["meshes/oaab/l/delantpaperred_01.nif"] =   "meshes/delantpaperred_01_off99.nif",
	["meshes/oaab/l/delantpaperred_02.nif"] =   "meshes/delantpaperred_02_off99.nif",
	["meshes/oaab/l/delantpaperred_03.nif"] =   "meshes/delantpaperred_03_off99.nif",
	["meshes/uvi/uvi_crystal_bulb_blu.nif"] =   "meshes/uvi_crystal_bulb_blu_off99.nif",
	["meshes/uvi/uvi_crystal_bulb_wrm.nif"] =   "meshes/uvi_crystal_bulb_wrm_off99.nif",
}



local replacers = {
	dlr = {
		["meshes/l/light_ashl_lantern_01.nif"] = {100568,  "meshes/dlr/light_ashl_lantern_01_off99.nif"					},
		["meshes/l/light_ashl_lantern_02.nif"] = {100583,  "meshes/dlr/light_ashl_lantern_02_off99.nif"					},
		["meshes/l/light_ashl_lantern_03.nif"] = {100583,  "meshes/dlr/light_ashl_lantern_03_off99.nif"					},
		["meshes/l/light_ashl_lantern_04.nif"] = {100586,  "meshes/dlr/light_ashl_lantern_04_off99.nif"					},
		["meshes/l/light_ashl_lantern_05.nif"] = {100586,  "meshes/dlr/light_ashl_lantern_05_off99.nif"					},
		["meshes/l/light_ashl_lantern_06.nif"] = {100586,  "meshes/dlr/light_ashl_lantern_06_off99.nif"					},
		["meshes/l/light_ashl_lantern_07.nif"] = {100586,  "meshes/dlr/light_ashl_lantern_07_off99.nif"					},
		["meshes/l/light_de_lantern_01.nif"] = {44741,	 "meshes/dlr/light_de_lantern_01_off99.nif"				 },
		["meshes/l/light_de_lantern_02.nif"] = {81787,	"meshes/dlr/light_de_lantern_02_off99.nif"				  },
		["meshes/l/light_de_lantern_03.nif"] = {133776,	"meshes/dlr/light_de_lantern_03_off99.nif"				  },
		["meshes/l/light_de_lantern_04.nif"] = {174661,	"meshes/dlr/light_de_lantern_04_off99.nif"				  },
		["meshes/l/light_de_lantern_05.nif"] = {86566,	"meshes/dlr/light_de_lantern_05_off99.nif"				  },
		["meshes/l/light_de_lantern_06.nif"] = {81787,	"meshes/dlr/light_de_lantern_06_off99.nif"				  },
		["meshes/l/light_de_lantern_07.nif"] = {44741,	 "meshes/dlr/light_de_lantern_07_off99.nif"				 },
		["meshes/l/light_de_lantern_08.nif"] = {133776,	"meshes/dlr/light_de_lantern_08_off99.nif"				  },
		["meshes/l/light_de_lantern_09.nif"] = {174661,	"meshes/dlr/light_de_lantern_09_off99.nif"				  },
		["meshes/l/light_de_lantern_10.nif"] = {86567,	"meshes/dlr/light_de_lantern_10_off99.nif"				  },
		["meshes/l/light_de_lantern_11.nif"] = {44741,	 "meshes/dlr/light_de_lantern_11_off99.nif"				 },
		["meshes/l/light_de_lantern_12.nif"] = {133776,	"meshes/dlr/light_de_lantern_12_off99.nif"				  },
		["meshes/l/light_de_lantern_13.nif"] = {174661,	"meshes/dlr/light_de_lantern_13_off99.nif"				  },
		["meshes/l/light_de_lantern_14.nif"] = {86568,	"meshes/dlr/light_de_lantern_14_off99.nif"				  },
		["meshes/l/light_de_streetlight_01.nif"] = {24426, "meshes/dlr/light_de_streetlight_01_off99.nif"					 },
		["meshes/l/light_paper_lantern_01.nif"] = {57291,  "meshes/dlr/light_paper_lantern_01_off99.nif"					},
		["meshes/l/light_paper_lantern_02.nif"] = {57291,  "meshes/dlr/light_paper_lantern_02_off99.nif"					},
		--["meshes/l/light_paper_lantern_off.nif"] = {57199,					  },
	},
	dlr_glow = {
		["meshes/l/light_ashl_lantern_01.nif"] = {101888, "meshes/dlr/light_ashl_lantern_01_off99.nif"					},
		["meshes/l/light_ashl_lantern_02.nif"] = {101898, "meshes/dlr/light_ashl_lantern_02_off99.nif"					},
		["meshes/l/light_ashl_lantern_03.nif"] = {101902, "meshes/dlr/light_ashl_lantern_03_off99.nif"					},
		["meshes/l/light_ashl_lantern_04.nif"] = {101908, "meshes/dlr/light_ashl_lantern_04_off99.nif"					},
		["meshes/l/light_ashl_lantern_05.nif"] = {101907, "meshes/dlr/light_ashl_lantern_05_off99.nif"					},
		["meshes/l/light_ashl_lantern_06.nif"] = {101911, "meshes/dlr/light_ashl_lantern_06_off99.nif"					},
		["meshes/l/light_ashl_lantern_07.nif"] = {101910, "meshes/dlr/light_ashl_lantern_07_off99.nif"					},
		["meshes/l/light_de_lantern_01.nif"] = {46056, "meshes/dlr/light_de_lantern_01_off99.nif"				 },
		--["meshes/l/light_de_lantern_02.nif"] = {87950,				 },
		["meshes/l/light_de_lantern_03.nif"] = {135091, "meshes/dlr/light_de_lantern_03_off99.nif"				  },
		["meshes/l/light_de_lantern_04.nif"] = {175976, "meshes/dlr/light_de_lantern_04_off99.nif"				  },
		--["meshes/l/light_de_lantern_05.nif"] = {87881,				  },
		--["meshes/l/light_de_lantern_06.nif"] = {87945,				  },
		["meshes/l/light_de_lantern_07.nif"] = {46061, "meshes/dlr/light_de_lantern_07_off99.nif"				 },
		["meshes/l/light_de_lantern_08.nif"] = {135096, "meshes/dlr/light_de_lantern_08_off99.nif"				  },
		["meshes/l/light_de_lantern_09.nif"] = {175981, "meshes/dlr/light_de_lantern_09_off99.nif"				  },
		--["meshes/l/light_de_lantern_10.nif"] = {87887,				  },
		["meshes/l/light_de_lantern_11.nif"] = {46060, "meshes/dlr/light_de_lantern_11_off99.nif"				 },
		["meshes/l/light_de_lantern_12.nif"] = {135095, "meshes/dlr/light_de_lantern_12_off99.nif"				  },
		["meshes/l/light_de_lantern_13.nif"] = {175980, "meshes/dlr/light_de_lantern_13_off99.nif"				  },
		--["meshes/l/light_de_lantern_14.nif"] = {87887,				  },
		["meshes/l/light_de_streetlight_01.nif"] = {25741, "meshes/dlr/light_de_streetlight_01_off99.nif"					 },
		["meshes/l/light_paper_lantern_01.nif"] = {58606, "meshes/dlr/light_paper_lantern_01_off99.nif"					},
		["meshes/l/light_paper_lantern_02.nif"] = {58611, "meshes/dlr/light_paper_lantern_02_off99.nif"					},
		--["meshes/l/light_paper_lantern_off.nif"] = {57199,					  },
	},
	dlr_smoothed = {
		["meshes/l/light_ashl_lantern_01.nif"] = {55207,  "meshes/dlr/light_ashl_lantern_01_off99.nif"					},
		["meshes/l/light_ashl_lantern_02.nif"] = {55207,  "meshes/dlr/light_ashl_lantern_02_off99.nif"					},
		["meshes/l/light_ashl_lantern_03.nif"] = {55207,  "meshes/dlr/light_ashl_lantern_03_off99.nif"					},
		["meshes/l/light_ashl_lantern_04.nif"] = {55207,  "meshes/dlr/light_ashl_lantern_04_off99.nif"					},
		["meshes/l/light_ashl_lantern_05.nif"] = {55207,  "meshes/dlr/light_ashl_lantern_05_off99.nif"					},
		["meshes/l/light_ashl_lantern_06.nif"] = {55207,  "meshes/dlr/light_ashl_lantern_06_off99.nif"					},
		["meshes/l/light_ashl_lantern_07.nif"] = {55207,  "meshes/dlr/light_ashl_lantern_07_off99.nif"					},
	},
	dlr_smoothed_glow = {
		["meshes/l/light_ashl_lantern_01.nif"] = {56527, "meshes/dlr/light_ashl_lantern_01_off99.nif"					},
		["meshes/l/light_ashl_lantern_02.nif"] = {56522, "meshes/dlr/light_ashl_lantern_02_off99.nif"					},
		["meshes/l/light_ashl_lantern_03.nif"] = {56526, "meshes/dlr/light_ashl_lantern_03_off99.nif"					},
		["meshes/l/light_ashl_lantern_04.nif"] = {56529, "meshes/dlr/light_ashl_lantern_04_off99.nif"					},
		["meshes/l/light_ashl_lantern_05.nif"] = {56528, "meshes/dlr/light_ashl_lantern_05_off99.nif"					},
		["meshes/l/light_ashl_lantern_06.nif"] = {56532, "meshes/dlr/light_ashl_lantern_06_off99.nif"					},
		["meshes/l/light_ashl_lantern_07.nif"] = {56531, "meshes/dlr/light_ashl_lantern_07_off99.nif"					},
	},
	rr = {
		["meshes/l/light_com_lantern_01.nif"] = {25591, "meshes/rr/light_com_lantern_01_off99.nif"},
		["meshes/l/light_com_lantern_02.nif"] = {25595, "meshes/rr/light_com_lantern_02_off99.nif"},
	},
	rr_enlightened_flames = {
		["meshes/l/light_com_lantern_01.nif"] = {24530, "meshes/rr/light_com_lantern_01_off99.nif"},
		["meshes/l/light_com_lantern_02.nif"] = {24534, "meshes/rr/light_com_lantern_02_off99.nif"},
	},
	dlr_enlightened_flames = {
		["meshes/l/light_de_lantern_02.nif"] = {80680, "meshes/dlr/light_de_lantern_02_off99.nif"},
		["meshes/l/light_de_lantern_05.nif"] = {85573, "meshes/dlr/light_de_lantern_05_off99.nif"},
		["meshes/l/light_de_lantern_06.nif"] = {80672, "meshes/dlr/light_de_lantern_06_off99.nif"},
		["meshes/l/light_de_lantern_10.nif"] = {85574, "meshes/dlr/light_de_lantern_10_off99.nif"},
		["meshes/l/light_de_lantern_14.nif"] = {85575, "meshes/dlr/light_de_lantern_14_off99.nif"},
	},
	dlr_oaab = {
		["meshes/oaab/l/delantpapergrn_00.nif"] = {57296, "meshes/dlr/delantpapergrn_00_off99.nif"},
		["meshes/oaab/l/delantpaperred_00.nif"] = {57296, "meshes/dlr/delantpaperred_00_off99.nif"},
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



-- not necessary anymore, shifted to a whitelist concept
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
-- not necessary anymore, shifted to a whitelist concept
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

local function onUpdate(dt)
	if dt == 0 then return end
	iterateLights, light = next(activeLights, iterateLights)
	if light then
		if not light:isValid() or light.count == 0 then
			table.remove(activeLights, iterateLights)
		else
			--processLight
			local clockHour = tonumber(calendar.formatGameTime("%H", calendar.gameTime()))
			local isNight = clockHour < 7 or clockHour > 19
			local isOffLight = saveData.reverseRecordLookup[light.recordId]
			local originalRecordId = isOffLight or light.recordId
			local shouldTurnOn = isNight and isOffLight
			local shouldTurnOff = not isNight and not isOffLight
			local needsRegenerate = saveData.regenerateToDo[light.recordId]
			if needsRegenerate then
				shouldTurnOff = true
			end
			if shouldTurnOn then
				local cell = light.cell
				if cell then
					local pos = light.position
					local rotation = light.rotation
					local originalId = light.id
					if saveData.originalRotations[originalId] then
						rotation = saveData.originalRotations[originalId]
					end
					local scale = light.scale
					local count = light.count
					light:remove()
					local newObject = world.createObject(isOffLight, count)
					newObject:teleport(cell, pos, {rotation = rotation})
					if scale ~= 1 then
						newObject:setScale(scale)
					end
					saveData.originalRotations[newObject.id] = rotation
					saveData.originalRotations[originalId] = nil
				end
			elseif shouldTurnOff then
				if not saveData.generatedRecords[originalRecordId] then
					local original = types.Light.record(originalRecordId)
					local draft = {template = original, isOffByDefault = true}
					if offModels[original.model] then
						draft.model = offModels[original.model]
					end
					draft = types.Light.createRecordDraft(draft)
					local newRecord = world.createRecord(draft)
					saveData.generatedRecords[originalRecordId] = newRecord.id
					saveData.reverseRecordLookup[newRecord.id] = originalRecordId
				end
				local cell = light.cell
				if cell then
					local pos = light.position
					local rotation = light.rotation
					local originalId = light.id
					if saveData.originalRotations[originalId] then
						rotation = saveData.originalRotations[originalId]
					end
					local scale = light.scale
					local count = light.count
					light:remove()
					local newObject = world.createObject(saveData.generatedRecords[originalRecordId], count)
					newObject:teleport(cell, pos, {rotation = rotation})
					if scale ~= 1 then
						newObject:setScale(scale)
					end
					saveData.originalRotations[newObject.id] = rotation
					saveData.originalRotations[originalId] = nil
				end
			end
		end
	end
end

local function onObjectActive(object)
	if types.Light.objectIsInstance(object) then
		local validRecord = false
		for _, searchPattern in pairs(whitelistPatterns) do
			if object.recordId:find(searchPattern) then
				validRecord = true
			end
		end
		-- skipping blacklisted records or records that failed the pattern matching and don't happen to be the generated "off" ones from this mod
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
		saveData=data
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

return{
	engineHandlers = { 
		onUpdate = onUpdate,
		onObjectActive = onObjectActive,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
	},
}