--[[
╭──────────────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Shower Module                                                  │
│  Showers as heating stations for player cells                                │
│  R = fill shower with water (up to 2 fills), F = use water to heat cell      │
╰──────────────────────────────────────────────────────────────────────────────╯
]]

local showerTooltip = nil

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Shower Configuration                                                         │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

-- Shower IDs (any shower can be filled and used for heating)
local showerIds = {
	["s3_t_nor_furn_saunapit_01"] = true
	-- Add more shower IDs here as needed
}

-- Track water fill state per shower (keyed by object.id)
-- Stored in saveData.m_shower.showerWater[objectId] = {fills = 0-2}

local WATER_PER_FILL_ML = 500 -- 500ml per fill
local MAX_FILLS = 2
local HEAT_PER_USE = 10 -- Temperature increase per use

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Helper Functions                                                             │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function isShower(object)
	if not object or not object.recordId then return false end
	if G_raycastResultType ~= "Static" and G_raycastResultType ~= "Activator" then
		return false
	end
	local id = object.recordId:lower()
	return showerIds[id] or false
end

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



local function getTotalWaterMl()
	local inv = types.Actor.inventory(self)
	local totalWater = 0
	
	for _, item in ipairs(inv:getAll(types.Potion)) do
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse and saveData.reverse[item.recordId:lower()]
			if rev and (rev.liquid == "water" or rev.liquid == "susWater" or rev.liquid == "saltWater") then
				totalWater = totalWater + (rev.q * 250 * item.count)
			end
		end
	end
	
	return totalWater
end

-- Fill shower with water from inventory
local function fillShower(objectId)
	local showerData = getShowerData(objectId)
	
	if showerData.fills >= MAX_FILLS then
		messageBox(2, "The sauna is already full")
		return
	end
	
	if checkWaterInventory() < WATER_PER_FILL_ML then
		messageBox(2, "You need at least " .. WATER_PER_FILL_ML .. "ml of water")
		return
	end
	
	-- Consume water from inventory via global event
	core.sendGlobalEvent("SunsDusk_Shower_consumeWater", {self, WATER_PER_FILL_ML, objectId})
	
	log(3, "[Sauna] Filling sauna " .. objectId .. " with " .. WATER_PER_FILL_ML .. "ml water")
end

-- Use shower to heat the cell
local function useShower(objectId)
	local showerData = getShowerData(objectId)
	
	if showerData.fills <= 0 then
		messageBox(2, "The sauna has no water")
		return
	end
	
	-- Reduce fill level
	showerData.fills = showerData.fills - 1
	
	-- Heat the player's cell via temperature system
	if saveData.m_temp then

		local oldTemp = saveData.m_temp.currentTemp or 20
		saveData.m_temp.currentTemp = math.min(35, oldTemp + HEAT_PER_USE)
		
		-- sauna functionality
		saveData.m_temp.cellTempModCellId = self.cell.id
		saveData.m_temp.cellTempMod = math.min(35/3, (saveData.m_temp.cellTempMod or 0) + HEAT_PER_USE/2)
		
		
		-- Also increase wetness slightly since it's a shower
		if saveData.m_temp.water then
			saveData.m_temp.water.wetness = math.min(1, (saveData.m_temp.water.wetness or 0) + 0.3)
		end
		
		ambient.playSoundFile("sound/Fx/FOOT/steam.wav")
		messageBox(3, "The warm water heats you up (" .. showerData.fills .. " fills remaining)")
		log(3, "[Sauna] Used sauna, heated from " .. f1(oldTemp) .. " to " .. f1(saveData.m_temp.currentTemp))
	else
		messageBox(2, "Temperature system not active")
	end
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Tooltip Positioning (same as cooking/well/tea tooltips)                      │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function alignAxis(value)
	local center = 0.5
	local threshold = 0.01
	local dist = math.abs(value - center)
	local t = math.min(dist / threshold, 1)
	if value > center then
		return 0.5 - (t * 0.5)
	else
		return 0.5 + (t * 0.5)
	end
end

local function alignAnchor(pos)
	local alignedX = alignAxis(pos.x)
	local alignedY = alignAxis(pos.y)
	return v2(alignedX, alignedY)
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Raycast Changed - Display Tooltip                                            │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function raycastChanged()
	if not NEEDS_TEMP then return end
	
	local lookingAtShower = G_raycastResult and G_raycastResult.hitObject and isShower(G_raycastResult.hitObject)
	
	if lookingAtShower and I.UI.isHudVisible() and not saveData.playerInfo.isInWerewolfForm then
		if showerTooltip then
			showerTooltip:destroy()
		end
		
		-- Disable combat/magic controls while showing tooltip
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
		
		local anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100))
		
		-- Calculate colors for valid/invalid states
		local validIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
		validIconHsv[2] = validIconHsv[2]*0.6
		validIconHsv[3] = math.min(1, validIconHsv[3]*1.8)
		local validIconRgb = util.color.rgb(hsvToRgb(validIconHsv[1], validIconHsv[2], validIconHsv[3]))
		
		local invalidIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
		invalidIconHsv[2] = invalidIconHsv[2]*0.3
		invalidIconHsv[3] = math.min(1, invalidIconHsv[3]*0.4)
		local invalidIconRgb = util.color.rgb(hsvToRgb(invalidIconHsv[1], invalidIconHsv[2], invalidIconHsv[3]))
		
		-- Get shower state
		local objectId = G_raycastResult.hitObject.id
		local showerData = getShowerData(objectId)
		local currentFills = showerData.fills
		local hasEnoughWater =checkWaterInventory() >= WATER_PER_FILL_ML
		
		-- Check eligibility for each action
		local canFill = currentFills < MAX_FILLS and hasEnoughWater
		local canUse = currentFills > 0
		
		local fillIconColor = canFill and validIconRgb or invalidIconRgb
		local fillTextColor = canFill and WORLD_TOOLTIP_FONT_COLOR or invalidIconRgb
		local useIconColor = canUse and validIconRgb or invalidIconRgb
		local useTextColor = canUse and WORLD_TOOLTIP_FONT_COLOR or invalidIconRgb
		
		-- Build fill text with status
		local fillText = "Fill sauna (" .. currentFills .. "/" .. MAX_FILLS .. ")"
		if currentFills >= MAX_FILLS then
			fillText = "Sauna full"
		elseif not hasEnoughWater then
			fillText = "Fill shower (need " .. WATER_PER_FILL_ML .. "ml)"
		end
		
		local useText = "Use sauna to warm up"
		if currentFills <= 0 then
			useText = "Sauna empty"
		end
		
		-- Create the tooltip UI
		showerTooltip = ui.create({
			layer = 'Scene',
			name = "showerTooltip",
			type = ui.TYPE.Flex,
			props = {
				relativePosition = v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100),
				anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100)),
				horizontal = false,
				autoSize = true,
				arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
			},
			content = ui.content{}
		})
		
		-- Line 1: F key for using shower
		local line1 = {
			layer = 'Scene',
			name = "showerTooltipLine1",
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = true,
				arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
			},
			content = ui.content{}
		}
		showerTooltip.layout.content:add(line1)
		
		line1.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/f.dds"),
				tileH = false,
				tileV = false,
				size  = v2(WORLD_TOOLTIP_ICON_SIZE, WORLD_TOOLTIP_ICON_SIZE),
				alpha = 0.6,
				color = useIconColor,
			}
		}
		line1.content:add{
			type = ui.TYPE.Text,
			props = {
				text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "")..useText,
				textColor = useTextColor,
				textShadow = true,
				textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
				alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
			}
		}
		
		-- Line 2: R key for filling shower
		local line2 = {
			layer = 'Scene',
			name = "showerTooltipLine2",
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = true,
				arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
			},
			content = ui.content{}
		}
		showerTooltip.layout.content:add(line2)
		
		line2.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/r.dds"),
				tileH = false,
				tileV = false,
				size  = v2(WORLD_TOOLTIP_ICON_SIZE, WORLD_TOOLTIP_ICON_SIZE),
				alpha = 0.6,
				color = fillIconColor,
			}
		}
		line2.content:add{
			type = ui.TYPE.Text,
			props = {
				text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "")..fillText,
				textColor = fillTextColor,
				textShadow = true,
				textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
				alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
			}
		}
		
	elseif showerTooltip then
		showerTooltip:destroy()
		showerTooltip = nil
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
	end
end

table.insert(G_raycastChangedJobs, raycastChanged)
table.insert(G_refreshWidgetJobs, raycastChanged)

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Refresh Tooltip                                                              │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function refreshTooltip()
	if showerTooltip then
		showerTooltip:destroy()
		showerTooltip = nil
	end
	raycastChanged()
end

table.insert(G_refreshTooltipJobs, refreshTooltip)

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Input Handlers                                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

-- R key (ToggleSpell) - Fill shower with water
input.registerTriggerHandler("ToggleSpell", async:callback(function(dt, use, sneak, run)
	if not NEEDS_TEMP then return end
	
	if showerTooltip and G_raycastResult and G_raycastResult.hitObject and isShower(G_raycastResult.hitObject) then
		fillShower(G_raycastResult.hitObject.id)
	end
end))

-- F key (ToggleWeapon) - Use shower to heat up
input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
	if not NEEDS_TEMP then return end
	
	if showerTooltip and G_raycastResult and G_raycastResult.hitObject and isShower(G_raycastResult.hitObject) then
		useShower(G_raycastResult.hitObject.id)
	end
end))

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
		
		-- Refresh tooltip to show updated state
		refreshTooltip()
	else
		messageBox(2, "Not enough water consumed")
	end
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
