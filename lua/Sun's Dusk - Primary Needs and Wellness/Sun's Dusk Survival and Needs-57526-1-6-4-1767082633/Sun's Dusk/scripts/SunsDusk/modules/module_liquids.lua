--local G_cellInfo = {
--	isExterior = false,
--	isIceCave = "water",
--	isCave = "susWater",
--	isDwemer = "susWater",
--	isDaedric = "susWater",
--	isMine = "susWater",
--	isTomb = "susWater",
--	isHouse = "water",
--	isCastle = "water",
--	isMushroom = "water",  -- Telvanni
--	isHlaalu = "water",    -- Hlaalu
--	isRedoran = "water",   -- Redoran
--	isSewer = "susWater",     -- Sewers/Underworks
--	isTemple = "water",    -- Temple interiors
--	isBath = "water",
----  isAshlander = "water",
--}

require('scripts.SunsDusk.lib.temp_water_sources')

-- Vivec freshwater area (for WATER_CLEAN_VIVEC setting)
local VIVEC_POSITION = util.vector3(32467.130859, -90863.234375, 100)
local VIVEC_RADIUS = 20000

local countActivations = 0

-- periodic check
local function getCellWaterType(dt)
	local cell = self.cell
	if not cell then -- gamestart/engine bug
		G_cellInfo.waterType = "water"
	elseif WATER_CLEAN_ALWAYS then -- global override
		G_cellInfo.waterType = "water"
	elseif not cell.isExterior then -- interior
		-- Quasi-exterior (interior in engine but marked as exterior)
		if G_cellInfo.isExterior then
			G_cellInfo.waterType = "water"
			return
		end
		
		-- Regular interior - check in priority order
		local waterType
		
		if G_cellInfo.isSewer then
			waterType = "susWater"
		elseif G_cellInfo.isBath then
			waterType = "water"
		elseif G_cellInfo.isTemple then
			waterType = "water"
		elseif G_cellInfo.isHouse then
			waterType = "water"
		elseif G_cellInfo.isCastle then
			waterType = "water"
		elseif G_cellInfo.isHlaalu then
			waterType = "water"
		elseif G_cellInfo.isRedoran then
			waterType = "water"
		elseif G_cellInfo.isMushroom then
			waterType = "water"
		elseif G_cellInfo.isDaedric and not WATER_CLEAN_DUNGEONS then
			waterType = "susWater"
		elseif G_cellInfo.isDwemer and not WATER_CLEAN_DUNGEONS then
			waterType = "susWater"
		elseif G_cellInfo.isTomb and not WATER_CLEAN_DUNGEONS then
			waterType = "susWater"
		elseif G_cellInfo.isMine and not WATER_CLEAN_DUNGEONS then
			waterType = "susWater"
		elseif G_cellInfo.isIceCave then
			waterType = "water"
		elseif G_cellInfo.isCave and not WATER_CLEAN_DUNGEONS then
			waterType = "susWater"
		else
			waterType = "water"
		end
		
		G_cellInfo.waterType = waterType
	else -- exterior cells
	
		local pos = self.position
		local maxWaterInfluence = 0
		local maxWaterType = nil
		
		for _, source in ipairs(WATER_BODIES) do
			local distance = (pos - source.position):length()
			
			if distance < source.radius then
				local influence = distance/source.radius
				
				if influence > maxWaterInfluence then
					maxWaterInfluence = influence
					maxWaterType = source.waterType or source.blendMode or 1
				end
			end
		end
		
		-- Determine base water type
		local waterType
		if not maxWaterType then
			waterType = "saltWater"
		elseif maxWaterType == 1 then
			waterType = "water"
		elseif maxWaterType == 2 then
			waterType = "saltWater"
		elseif maxWaterType == 3 then
			waterType = "susWater"
		else
			waterType = maxWaterType
		end
		
		-- Apply Vivec freshwater setting
		if waterType == "saltWater" and WATER_CLEAN_VIVEC then
			if (pos - VIVEC_POSITION):length() < VIVEC_RADIUS then
				waterType = "water"
			end
		end
		
		-- Apply river/lake cleaning setting (inverted: makes "water" dirty when OFF)
		if not WATER_CLEAN_BODIES and waterType == "water" then
			waterType = "susWater"
		end
		
		G_cellInfo.waterType = waterType
	end
end

table.insert(G_sluggishScheduler, {getCellWaterType})
G_onFrameJobsSluggish.getCellWaterType = getCellWaterType

-- ----------------------------------------------------------------------------------- Spawning -----------------------------------------------------------------------------------

local function cellChanged(lastCell)
	if self.cell then
		core.sendGlobalEvent("SunsDusk_WaterBottles_convertMiscInCell", {
			player = self,
		})
	end
end

table.insert(G_onLoadJobs, cellChanged)
table.insert(G_cellChangedJobs, cellChanged)

local function onFrame(dt)
    if WATER_SPILL_ON_JUMP and self.controls.jump and G_isInWater < 0.6 then
        core.sendGlobalEvent("SunsDusk_WaterBottles_spillWater", self)
    end
end

table.insert(G_onFrameJobs, onFrame)

-- ----------------------------------------------------------------------------------- Refill -----------------------------------------------------------------------------------

G_wellKeywords = { 
	"well", 		--wellbroken
	"fountain", 	-- T_De_SetInd_X_Fountain ; fountain_water
	"pool", 		--cavemud
	-- "trough", 
	-- "aquaduct", 
	"keg", 
	-- bathing
	"s3_bath_0",
	"washbasin",
--	"white_basin",
	"ab_furn_barrel01water",
	"ab_furn_combucket02water", 
	"t_imp_furnr_basin_02_w", 
	"t_imp_furnr_basin_01", 
	"t_com_var_bucketwater_01", -- can now refill water in OAAB water barells full of water and TD basins with water ; stronghold no longer considered a well
	"ab_furn_lwbowlwater",
	"t_de_furn_basin_01",
	"t_com_furn_basin_01",
	"t_com_var_barrelwater_01",
	"t_com_var_bucketwater_01",
--	"ko_bathtub_wood",
--	"ko_basin",
-- AB_Furn_WashBasin
}

if G_STARWIND_INSTALLED then
	table.insert(G_wellKeywords, "sw_ext_moist")
	table.insert(G_wellKeywords, "sw_bantha")
end

G_wellBlacklist = { 
	"magicka",
	"comkeg", 
	"inkwell", 
	"acid", 
	"lava", 
	"terrmineral", 
	"stairwell", 
	"smdwell", 
	"fountainwall", 
	"blood", 
	"table", 
	"rack",
	"jewel",
}

-- Helper function to determine well water type based on settings
local function getWellWaterType(objectRecordId)
	-- If suspicious water sources are disabled, wells always give clean water
	if WATER_CLEAN_ALWAYS then
		return "water"
	end
	
	-- Check if the static has a specific liquid type defined
	local staticLiquidType = dbStatics[objectRecordId] and dbStatics[objectRecordId].well and dbStatics[objectRecordId].well.liquidType
	if staticLiquidType then
		return staticLiquidType
	end
	
	-- Check Wells setting
	if WATER_CLEAN_WELLS then
		return "water"
	else
		return "susWater"
	end
end

local function isWell(object)
	if G_raycastResultType ~= "Static" and G_raycastResultType ~= "Activator" then 
		return false
	end
	local dbEntry = dbStatics[object.recordId] and dbStatics[object.recordId].well
	if dbEntry ~= nil then
		return dbEntry and true
	end
	local id = object.recordId or ""
	for _, key in ipairs(G_wellKeywords) do
		if id:find(key, 1, true) then
			for _, key in ipairs(G_wellBlacklist) do
				if id:find(key, 1, true) then
					return false
				end
			end
			return true
		end
	end
	return false
end

input.registerTriggerHandler('Activate', async:callback(function()
	if not WATER_REFILL or not NEEDS_THIRST then return end
	if G_raycastResult and G_raycastResult.hitObject and isWell(G_raycastResult.hitObject) then 
		local liquidType = getWellWaterType(G_raycastResult.hitObject.recordId)
		log(3, "activated well ("..G_raycastResult.hitObject.recordId..") refilling with "..( liquidType or "water"))
		if countActivations == 0 then
			core.sendGlobalEvent("SunsDusk_WaterBottles_refillBottlesWell", {self, liquidType})
			if saveData.m_thirst and saveData.m_thirst.thirst > 0.001 and liquidType == "water" then
				ambient.playSound("Drink")
				saveData.m_thirst.thirst = 0
				module_thirst_minute(nil, nil, 0)
			end
		else--if countActivations == 1 then
			core.sendGlobalEvent("SunsDusk_WaterBottles_refillSpillables", {self, liquidType}) --{self, G_cellInfo.waterType or "water"})
		--else
			if saveData.m_temp then --and saveData.m_temp.targetTemp > 20 then
				ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
				--ambient.playSoundFile("sound/sunsdusk/water-splash-05-2-by-jazzy.junggle.net.ogg")
				saveData.m_temp.water.wetness = math.min(1, saveData.m_temp.water.wetness + 0.15)
				if saveData.m_temp.currentTemp > 10 then
					saveData.m_temp.currentTemp = math.max(10, saveData.m_temp.currentTemp - 5)
				end
			end
		end
		countActivations = countActivations + 1
	end
end))

-- calculating anchor based on offcet from center
local function alignAxis(value)
	local center = 0.5
	local threshold = 0.01
	local dist = math.abs(value - center)
	local t = math.min(dist / threshold, 1)
	if value > center then
		return 0.5 - (t * 0.5)  -- Interpolate from 0.5 to 1
	else
		return 0.5 + (t * 0.5)  -- Interpolate from 0.5 to 0
	end
end
local function alignAnchor(pos)
	local alignedX = alignAxis(pos.x)
	local alignedY = alignAxis(pos.y)
	return v2(alignedX, alignedY)
end

local function raycastChanged()
	if not WATER_REFILL then return end
	if G_raycastResultType and isWell(G_raycastResult.hitObject) then
		if wellTooltip then
			wellTooltip:destroy()
		end
		local liquidType = getWellWaterType(G_raycastResult.hitObject.recordId)
		
		wellTooltip = ui.create({
			layer = 'Scene',
			name = "wellTooltip",
			type = ui.TYPE.Text,
			props = {
				text = "refill "..(localizedLiquidNames[liquidType] or "??"),
				relativePosition = v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100),
				anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100)),
				textColor = WORLD_TOOLTIP_FONT_COLOR,
				textShadow = true,
				textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
			}
		})
	elseif wellTooltip then
		wellTooltip:destroy()
		wellTooltip = nil
		countActivations = 0
	end
end
table.insert(G_raycastChangedJobs, raycastChanged)
table.insert(G_refreshWidgetJobs, raycastChanged)

local function waterPurified(liquids)
	local totalMl = 0
	for liquidType, ml in pairs(liquids) do
		totalMl = totalMl + ml
	end
	G_refreshTooltips()
	ambient.playSoundFile("sound/sunsdusk/cooking.ogg", {volume = 1.0})
	messageBox(4, string.format("Purified %i ml water",totalMl))
	if liquids["saltWater"] then
		local quarters = liquids["saltWater"]/250
		local runs = math.max(1,quarters/4)
		local failchance = 0.975^(quarters/4) - 0.3
		for i=1, runs do
			if math.random() > failchance then
				local randomItems = {
					"T_IngCrea_Starfish_01",
					"t_ingmine_salt_01",
					"t_ingmine_salt_01",
					"t_ingmine_salt_01",
					"t_ingmine_salt_01",
					"t_ingmine_salt_01",
				}
				local verifiedItems = {}
				for _, recordId in pairs(randomItems) do
					if types.Ingredient.records[recordId:lower()] then
						table.insert(verifiedItems, recordId:lower())
					end
				end
				local randomItem = verifiedItems[math.random(1,#verifiedItems)]
				local localizedName = types.Ingredient.records[randomItem].name
				messageBox(2, "Received " .. tostring(localizedName) .. " from purifying the Saltwater.")
				core.sendGlobalEvent("SunsDusk_addItem", {self, verifiedItems[math.random(1,#verifiedItems)], 1})
			end
		end
	end
	if liquids["susWater"] then
		local quarters = liquids["susWater"]/250
		local runs = math.max(1,quarters/4)
		local failchance = 0.975^(quarters/4) - 0.15
		for i=1, runs do
			if math.random() > failchance then
				local randomItems = {
					"ingred_heather_01",
					"ingred_muck_01",
					"t_ingcrea_astraljellyfish_01",
					"t_ingFlor_Turnip_01",
					"t_kha_Drink_SugarRum",
					"t_ingFlor_Cabbage_02",
					"ingred_raw_glass_01",
					"ingred_scrap_metal_01",
				}
				local verifiedItems = {}
				for _, recordId in pairs(randomItems) do
					if types.Ingredient.records[recordId:lower()] then
						table.insert(verifiedItems, recordId:lower())
					end
				end
				local randomItem = verifiedItems[math.random(1,#verifiedItems)]
				local localizedName = types.Ingredient.records[randomItem].name
				messageBox(2, "Received " .. tostring(localizedName) .. " from purifying the Suspicious water.")
-- 			local message = "Refilled " .. tostring(replaced) .. " bottles with " .. tostring(localizedLiquidNames[liquidType])	
				core.sendGlobalEvent("SunsDusk_addItem", { self, randomItem, 1 })
			end
		end
	end
end
G_eventHandlers.SunsDusk_WaterBottles_waterPurified = waterPurified

local function refillSwimming(dt)
	if G_isInWater > 0.6 and WATER_REFILL_SWIMMING then
		core.sendGlobalEvent("SunsDusk_WaterBottles_refillSpillables", { self, G_cellInfo.waterType or "saltWater" })
	end
end

--	[("T_Com_CopperKettle_01"):lower()] 	= { "tea_SF", "tea_H" },
--	[("T_Com_CoppetTeapot_01"):lower()] 	= { "tea_SF", "tea_H" },
--	[("AB_Misc_kettleceremonial"):lower()] 	= { "tea_SF", "tea_H" },
--	[("AB_Misc_debugteapot"):lower()] 		= { "tea_SF", "tea_H" },	
-- tea_SF 		= "stoneflower tea",
-- tea_H 		= "heather tea",

--table.insert(G_onFrameJobsSluggish, refillSwimming)
table.insert(G_sluggishScheduler[5], refillSwimming)
G_onFrameJobsSluggish.refillSwimming=refillSwimming

-- after jumping
local function spilledWater(ml)
	if saveData.m_temp then
		if saveData.m_temp.currentTemp > 10 then
			local wetnessMod = 1 - saveData.m_temp.water.wetness
			saveData.m_temp.currentTemp = math.max(10, saveData.m_temp.currentTemp - ml/250 * wetnessMod)
		end
		saveData.m_temp.water.wetness = math.min(1, saveData.m_temp.water.wetness + ml/250*0.1)
		--module_temp_minute(24, 1, 0)
	end	
	messageBox(3, "You accidentally spilled "..ml.." ml from open containers")
	ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
	ambient.playSoundFile("sound/sunsdusk/water-splash-05-2-by-jazzy.junggle.net.ogg")
end

G_eventHandlers.SunsDusk_spilledWater = spilledWater

local function refilledBottlesWell(data)
	local replaced = data.replaced
	local liquidType = data.liquidType -- localizedLiquidNames
	if replaced > 0 then 
		ambient.playSound("item potion up") 
		local message = "Refilled " .. tostring(replaced) .. " bottles with " .. tostring(localizedLiquidNames[liquidType])	
		messageBox(3, message)
	else
		ambient.playSoundFile("sound/sunsdusk/overflow.ogg", {volume = 0.5})
	end
end

G_eventHandlers.SunsDusk_refilledBottlesWell = refilledBottlesWell