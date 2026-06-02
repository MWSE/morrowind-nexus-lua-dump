local world = require('openmw.world')
local core  = require('openmw.core')
local util  = require('openmw.util')   

local progressActive = false
local progressStart  = 0
local progressTotal  = 1

local BOTTLE_CFG = {
    recordId = 'POTION_LOCAL_BREW_01',
}

local CAMPFIRE_CFG = {
    recordId = 'light_pitfire00',
}

local LIGHT_RECORDS = {
    "lantern_0",  "lantern_carved_00",  "lantern_or_0",
    "lantern_com_0", "lantern_com_1",
    "candle_white_uniq", "wax_candle00", "wax_candle01",
    "candle_green00",    "candle_blue00",    'Light_Ashl_Lantern_01',
   'Light_Ashl_Lantern_02',
   'Light_Ashl_Lantern_03',
   'Light_Ashl_Lantern_04',
   'Light_Ashl_Lantern_05',
   'Light_Ashl_Lantern_06',
   'Light_Ashl_Lantern_07',
   'Light_Com_Lantern_01',
   'Light_Com_Lantern_02',
   'Light_De_Lantern_01',
   'Light_De_Lantern_02',
   'Light_De_Lantern_03',
   'Light_De_Lantern_04',
   'Light_De_Lantern_05',
   'Light_De_Lantern_06',
   'Light_De_Lantern_07',
   'Light_De_Lantern_08',
   'Light_De_Lantern_09',
   'Light_De_Lantern_10',
   'Light_De_Lantern_11',
   'Light_De_Lantern_12',
   'Light_De_Lantern_13',
   'Light_De_Lantern_14',
   'Light_MH_Rope_Lantern',
   'Light_paper_lantern_01',
   'Light_paper_lantern_02',
   'Light_paper_lantern_off'
}
local LIGHT_RECORD_SET = {}
for _, id in ipairs(LIGHT_RECORDS) do LIGHT_RECORD_SET[id:lower()] = true end

local spawnedLight = nil

local spawnedBottles = {}
local spawnedEquipment = {}

local function getPlayer()
    return world.players[1]
end

local function findLightInInventory(actor)
    local inv = actor.inventory
    if not inv then return nil end
    for _, item in ipairs(inv:getAll()) do
        local rid = (item.recordId or ""):lower()
        if LIGHT_RECORD_SET[rid] then
            return rid
        end
    end
    return nil
end

return {
    interfaceName = "GameMenu",
    interface = {
        version = 1,
        openWaitDialog = function()
            local p = getPlayer()
            if p then p:sendEvent('DWR_ShowWaitUI', { isRest = false }) end
        end,
        openRestDialog = function()
            local p = getPlayer()
            if p then p:sendEvent('DWR_ShowWaitUI', { isRest = true }) end
        end,
    },

    engineHandlers = {
        onUpdate = function()
            if not progressActive then return end
            local p = getPlayer()
            if not p then return end
            local ratio = math.min(1.0,
                (core.getRealTime() - progressStart) / progressTotal)
            p:sendEvent('DWR_ProgressTick', { ratio = ratio })
        end,

        onSave = function()
            return {
                bottles   = spawnedBottles,
                equipment = spawnedEquipment,
                light     = spawnedLight,
            }
        end,

        onLoad = function(data)
            spawnedBottles   = (data and data.bottles)   or {}
            spawnedEquipment = (data and data.equipment) or {}
            spawnedLight     = (data and data.light)

            for _, obj in ipairs(spawnedBottles) do
                if obj and obj.enabled then obj:remove() end
            end
            spawnedBottles = {}

            for _, obj in ipairs(spawnedEquipment) do
                if obj and obj.enabled then obj:remove() end
            end
            spawnedEquipment = {}

            if spawnedLight and spawnedLight.enabled then
                spawnedLight:remove()
            end
            spawnedLight = nil

            local p = world.players[1]
            if p then
                p:sendEvent('DWR_StopWaiting', {})
            end
        end,
    },

    eventHandlers = {
--        DWR_Pause = function()
--           world.pause('DWR')
--        end,

--        DWR_Unpause = function()
--            world.unpause('DWR')
--        end,

        DWR_AdvanceOneHour = function()
            world.advanceTime(1.0)
        end,

        DWR_RequestWait = function(data)
            local p = getPlayer()
            if p then
                p:sendEvent('DWR_ShowWaitUI', {
                    isRest = data and data.isRest or false,
                })
            end
        end,

        DWR_StartProgress = function(data)
            progressActive = true
            progressStart  = data.startReal
            progressTotal  = data.totalSec
        end,

        DWR_StopProgress = function()
            progressActive = false
        end,

        DWR_SpawnBottles = function(data)
			for _, obj in ipairs(spawnedBottles) do
				if obj.enabled then obj:remove() end
			end
			spawnedBottles = {}

			local p = getPlayer()
			if not p then return end

			local cell = p.cell

			local ok, obj = pcall(world.createObject, BOTTLE_CFG.recordId, 1)
			if ok and obj then
				obj:teleport(cell, data.bottlePos, util.transform.identity)
				table.insert(spawnedBottles, obj)
			else
				print("[DWR] no bottle: " .. tostring(obj))
			end
			
			local lightRecordId = data.lightRecordId
			if spawnedLight and spawnedLight.enabled then
				spawnedLight:remove()
				spawnedLight = nil
			end
			if lightRecordId then
				local ok3, obj3 = pcall(world.createObject, lightRecordId, 1)
				if ok3 and obj3 then
					local pFwd = data.playerFwd or util.vector3(0, 1, 0)
					local pRight   = util.vector3(pFwd.y, -pFwd.x, 0)
					local isCandle = lightRecordId:lower():find("candle") ~= nil
					local lightZ   = isCandle and -4 or 15
					local lightPos = data.bottlePos
								   + pFwd  * 50   
								   + pRight * -60  
								   + util.vector3(0, 0, lightZ)  
					obj3:teleport(cell, lightPos, util.transform.identity)
					spawnedLight = obj3
				else
					print("[DWR] no light object: " .. tostring(obj3))
				end
			end
			
			if data.isRest then
				local cellName   = (cell.name or ""):lower()
				local isCave     = cellName:find("cave") or cellName:find("cavern")
								or cellName:find("grotto") or cellName:find("barrow")
								or cellName:find("tomb")   or cellName:find("mine")
								or cellName:find("dungeon") or cellName:find("addamasartus")
				local allowFire  = cell.isExterior or isCave
				if allowFire then
					local ok2, obj2 = pcall(world.createObject, CAMPFIRE_CFG.recordId, 1)
					if ok2 and obj2 then
						obj2:teleport(cell, data.campfirePos, util.transform.identity)
						table.insert(spawnedBottles, obj2)
					else
						print("[DWR] no fireplace: " .. tostring(obj2))
					end
				end
			end
		end,

		DWR_RemoveBottles = function()
			for _, bottle in ipairs(spawnedBottles) do
				if bottle.enabled then bottle:remove() end
			end
			spawnedBottles = {}
			if spawnedLight and spawnedLight.enabled then
				spawnedLight:remove()
			end
			spawnedLight = nil
		end,

		DWR_SpawnEquipment = function(data)
			for _, obj in ipairs(spawnedEquipment) do
				if obj.enabled then obj:remove() end
			end
			spawnedEquipment = {}
			local p = getPlayer()
			if not p then return end
			local cell = p.cell
			for _, item in ipairs(data.items) do
				local ok, obj = pcall(world.createObject, item.recordId, 1)
				if ok and obj then
					local rot = item.rot ~= nil
								and util.transform.rotateZ(item.rot)
								or  util.transform.identity
					obj:teleport(cell, item.pos, rot)
					table.insert(spawnedEquipment, obj)
				end
			end
		end,

		DWR_RemoveEquipment = function()
			for _, obj in ipairs(spawnedEquipment) do
				if obj and obj.enabled then obj:remove() end
			end
			spawnedEquipment = {}
		end,
    },
}
