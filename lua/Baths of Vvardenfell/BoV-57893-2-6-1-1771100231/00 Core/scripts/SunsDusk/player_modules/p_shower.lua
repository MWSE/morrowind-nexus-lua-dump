--[[
╭──────────────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Shower Module                                                  │
│  Showers as heating stations for player cells                                │
│  F = use water to heat cell, R = fill shower with water (up to 2 fills)      │
╰──────────────────────────────────────────────────────────────────────────────╯
]]

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Shower Configuration                                                         │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local showerIds = {
	["s3_shower"] = true,
	["s3_t_nor_furn_saunapit_01"] = true,
}

local WATER_PER_FILL_ML = 500
local MAX_FILLS = 2
local HEAT_PER_USE = 10

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ State Helpers                                                                │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function getShowerData(objectId)
	if not saveData.m_shower then
		saveData.m_shower = { showerWater = {} }
	end
	if not saveData.m_shower.showerWater then
		saveData.m_shower.showerWater = {}
	end
	if not saveData.m_shower.showerWater[objectId] then
		saveData.m_shower.showerWater[objectId] = { fills = 0 }
	end
	return saveData.m_shower.showerWater[objectId]
end

--local function getTotalWaterMl()
--	local inv = types.Actor.inventory(self)
--	local totalWater = 0
--
--	for _, item in ipairs(inv:getAll(types.Potion)) do
--		if item:isValid() and item.count > 0 then
--			local rev = saveData.reverse and saveData.reverse[item.recordId:lower()]
--			if rev and (rev.liquid == "water" or rev.liquid == "susWater" or rev.liquid == "saltWater") then
--				totalWater = totalWater + (rev.q * 250 * item.count)
--			end
--		end
--	end
--
--	return totalWater
--end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Actions                                                                      │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function fillShower(object)
	local objectId = object.id
	local showerData = getShowerData(objectId)

	if showerData.fills >= MAX_FILLS then
		messageBox(2, "The sauna is already full")
		return
	end

	if checkWaterInventory() < WATER_PER_FILL_ML then
		messageBox(2, "You need at least " .. WATER_PER_FILL_ML .. "ml of water")
		return
	end

	core.sendGlobalEvent("SunsDusk_Shower_consumeWater", {self, WATER_PER_FILL_ML, objectId})
	log(3, "[Sauna] Filling sauna " .. objectId .. " with " .. WATER_PER_FILL_ML .. "ml water")
end

local function useShower(object)
	local objectId = object.id
	local showerData = getShowerData(objectId)

	if showerData.fills <= 0 then
		messageBox(2, "The sauna has no water")
		return
	end

	showerData.fills = showerData.fills - 1

	if saveData.m_temp then
		local oldTemp = saveData.m_temp.currentTemp or 20
		saveData.m_temp.currentTemp = math.min(35, oldTemp + HEAT_PER_USE)

		saveData.m_temp.cellTempModCellId = self.cell.id
		saveData.m_temp.cellTempMod = math.min(35/3, (saveData.m_temp.cellTempMod or 0) + HEAT_PER_USE/2)

		if saveData.m_temp.water then
			saveData.m_temp.water.wetness = math.min(1, (saveData.m_temp.water.wetness or 0) + 0.3)
		end

		--ambient.playSoundFile("sound/Fx/FOOT/steam.wav") -- doesnt work for me?
		--ambient.playSoundFile("sound/Fx/envrn/steam.wav")
		ambient.playSoundFile("sound/dbs/sauna_hiss.ogg")
		messageBox(3, "The warm water heats you up (" .. showerData.fills .. " fills remaining)")
		log(3, "[Sauna] Used sauna, heated from " .. f1(oldTemp) .. " to " .. f1(saveData.m_temp.currentTemp))
	else
		messageBox(2, "Temperature system not active")
	end
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ World Interaction Registration                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

G_worldInteractions.shower = {
	canInteract = function(object, objectType)
		if not NEEDS_TEMP then return false end
		if objectType ~= "Static" and objectType ~= "Activator" then return false end
		if not object or not object.recordId then return false end
		return showerIds[object.recordId:lower()] or false
	end,

	getActions = function(object, objectType)
		local objectId = object.id
		local showerData = getShowerData(objectId)
		local currentFills = showerData.fills
		local hasEnoughWater = checkWaterInventory() >= WATER_PER_FILL_ML

		local canUse = currentFills > 0
		local useLabel = canUse and "Use sauna to warm up" or "Sauna empty"

		local canFill = currentFills < MAX_FILLS and hasEnoughWater
		local fillLabel
		if currentFills >= MAX_FILLS then
			fillLabel = "Sauna full"
		elseif not hasEnoughWater then
			fillLabel = "Fill shower (need " .. WATER_PER_FILL_ML .. "ml)"
		else
			fillLabel = "Fill sauna (" .. currentFills .. "/" .. MAX_FILLS .. ")"
		end

		return {
			{
				label = useLabel,
				preferred = "ToggleWeapon",
				disabled = not canUse,
				handler = function() useShower(object) G_refreshTooltips() end,
			},
			{
				label = fillLabel,
				preferred = "ToggleSpell",
				disabled = not canFill,
				handler = function() fillShower(object) end,
			},
		}
	end,
}

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Event Handler for Water Consumption Completion                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function showerWaterConsumed(data)
	local consumed = data.consumed or 0
	local objectId = data.objectId

	if consumed >= WATER_PER_FILL_ML then
		local showerData = getShowerData(objectId)
		showerData.fills = math.min(MAX_FILLS, showerData.fills + 1)

		ambient.playSound("item potion up")
		messageBox(3, "Filled sauna (" .. showerData.fills .. "/" .. MAX_FILLS .. ")")
	else
		messageBox(2, "Not enough water consumed")
	end
	G_refreshTooltips()
end

G_eventHandlers.SunsDusk_Shower_waterConsumed = showerWaterConsumed

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Initialization                                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function onLoad()
	if not NEEDS_TEMP then return end
	if not saveData.m_shower then
		saveData.m_shower = { showerWater = {} }
	end
	if not saveData.m_shower.showerWater then
		saveData.m_shower.showerWater = {}
	end
end

table.insert(G_onLoadJobs, onLoad)