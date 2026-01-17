--[[
╭──────────────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Tea Module                                                     │
│  Teapots as refill sources for heather and stoneflower tea                   │
│  R = brew heather tea, F = brew stoneflower tea                              │
╰──────────────────────────────────────────────────────────────────────────────╯
]]

local teaTooltip = nil

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Teapot Configuration                                                         │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

-- Teapot IDs (any teapot can brew either tea type)
local teapotIds = {
	["t_com_copperkettle_01"] 		= true,
	["t_com_coppetteapot_01"] 		= true,
	["ab_misc_kettleceremonial"] 	= true,
	["ab_misc_debugteapot"] 		= true,
	["ab_misc_ceramicteapot01"] 	= true,
	["ab_misc_ceramicteapot01hang"] = true,
	["ab_misc_comcopperkettle01"]	= true,
	["sd_teapot_red"]				= true,
}

-- Ingredient IDs required to make each tea type
local teaIngredients = {
	tea_H 	= "ingred_heather_01",
	tea_SF 	= "ingred_stoneflower_petals_01",
}

-- Teacup IDs that can be filled with tea (from sd_g.lua vesselLiquids)
local teacupIds = {
	["misc_com_redware_cup"]		= true,
	["misc_de_pot_redware_03"]		= true,
	["ab_misc_deceramiccup_01"] 	= true,
	["ab_misc_deceramiccup_02"] 	= true,
	["ab_misc_deceramicflask_01"] 	= true,
}

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Helper Functions                                                             │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function isTeapot(object)
	if not object or not object.recordId then return false end
	-- Teapots are Miscellaneous items placed in the world
	if G_raycastResultType ~= "Miscellaneous" and G_raycastResultType ~= "Static" and G_raycastResultType ~= "Activator" then
		return false
	end
	local id = object.recordId:lower()
	return teapotIds[id] or false
end

-- Check if player has the required ingredient
local function hasIngredient(ingredientId)
	local inv = types.Actor.inventory(self)
	for _, item in ipairs(inv:getAll(types.Ingredient)) do
		if item:isValid() and item.count > 0 then
			local rec = types.Ingredient.record(item)
			if rec.id:lower() == ingredientId:lower() then
				return true
			end
		end
	end
	return false
end

-- Check if player has any teacups that can be filled
local function hasTeacup()
	local inv = types.Actor.inventory(self)
	local Misc = types.Miscellaneous
	local Potion = types.Potion
	
	-- Check empty teacups (Miscellaneous)
	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec = Misc.record(item)
			if teacupIds[rec.id:lower()] then
				return true
			end
		end
	end
	
	-- Check partially filled teacups (Potions with tea)
	for _, item in ipairs(inv:getAll(Potion)) do
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse and saveData.reverse[item.recordId:lower()]
			if rev and teacupIds[rev.orig:lower()] then
				return true
			end
		end
	end
	
	return false
end

-- Brew tea of specified type
local function brewTea(teaType)
	local ingredientId = teaIngredients[teaType]
	local liquidName = localizedLiquidNames[teaType] or "tea"
	
	-- Check if player has the required ingredient
	if not hasIngredient(ingredientId) then
		local ingredRec = types.Ingredient.record(ingredientId)
		local ingredientName = ingredRec and ingredRec.name or ingredientId
		messageBox(2, "You need " .. ingredientName .. " to brew " .. liquidName)
		return
	end
	
	-- Check if player has a teacup to fill
	if not hasTeacup() then
		messageBox(2, "You need a teacup to fill with " .. liquidName)
		return
	end
	
	-- Remove 1 ingredient from inventory
	core.sendGlobalEvent("SunsDusk_Tea_consumeIngredient", {self, ingredientId})
	
	-- Refill teacups with the appropriate tea
	core.sendGlobalEvent("SunsDusk_Tea_refillTeacups", {self, teaType})
	
	log(3, "[Tea] Brewing " .. teaType .. " using " .. ingredientId)
end

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Tooltip Positioning (same as cooking/well tooltips)                          │
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
	if not NEEDS_TEA then return end
	
	local lookingAtTeapot = G_raycastResult and G_raycastResult.hitObject and isTeapot(G_raycastResult.hitObject)
	
	if lookingAtTeapot and I.UI.isHudVisible() and not saveData.playerInfo.isInWerewolfForm then
		if teaTooltip then
			teaTooltip:destroy()
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
		
		-- Check eligibility for each tea type
		local hasHeather = hasIngredient(teaIngredients.tea_H)
		local hasStoneflower = hasIngredient(teaIngredients.tea_SF)
		local hasTeacupItem = hasTeacup()
		
		local heatherEligible = hasHeather and hasTeacupItem
		local stoneflowerEligible = hasStoneflower and hasTeacupItem
		
		local heatherIconColor = heatherEligible and validIconRgb or invalidIconRgb
		local heatherTextColor = heatherEligible and WORLD_TOOLTIP_FONT_COLOR or invalidIconRgb
		local stoneflowerIconColor = stoneflowerEligible and validIconRgb or invalidIconRgb
		local stoneflowerTextColor = stoneflowerEligible and WORLD_TOOLTIP_FONT_COLOR or invalidIconRgb
		
		local heatherName = localizedLiquidNames["tea_H"] or "heather tea"
		local stoneflowerName = localizedLiquidNames["tea_SF"] or "stoneflower tea"
		
		-- Create the tooltip UI
		teaTooltip = ui.create({
			layer = 'Scene',
			name = "teaTooltip",
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
		
		-- Line 1: F key for stoneflower tea
		local line1 = {
			layer = 'Scene',
			name = "teaTooltipLine1",
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = true,
				arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
			},
			content = ui.content{}
		}
		teaTooltip.layout.content:add(line1)
		
		line1.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/f.dds"),
				tileH = false,
				tileV = false,
				size  = v2(WORLD_TOOLTIP_ICON_SIZE, WORLD_TOOLTIP_ICON_SIZE),
				alpha = 0.6,
				color = stoneflowerIconColor,
			}
		}
		line1.content:add{
			type = ui.TYPE.Text,
			props = {
				text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "").."Brew " .. stoneflowerName,
				textColor = stoneflowerTextColor,
				textShadow = true,
				textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
				alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
			}
		}
		
		-- Line 2: R key for heather tea
		local line2 = {
			layer = 'Scene',
			name = "teaTooltipLine2",
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = true,
				arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
			},
			content = ui.content{}
		}
		teaTooltip.layout.content:add(line2)
		
		line2.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/r.dds"),
				tileH = false,
				tileV = false,
				size  = v2(WORLD_TOOLTIP_ICON_SIZE, WORLD_TOOLTIP_ICON_SIZE),
				alpha = 0.6,
				color = heatherIconColor,
			}
		}
		line2.content:add{
			type = ui.TYPE.Text,
			props = {
				text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "").."Brew " .. heatherName,
				textColor = heatherTextColor,
				textShadow = true,
				textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
				alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
			}
		}
		
	elseif teaTooltip then
		teaTooltip:destroy()
		teaTooltip = nil
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
	if teaTooltip then
		teaTooltip:destroy()
		teaTooltip = nil
	end
	raycastChanged()
end

table.insert(G_refreshTooltipJobs, refreshTooltip)

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Input Handlers                                                               │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

-- R key (ToggleSpell) - Brew heather tea
input.registerTriggerHandler("ToggleSpell", async:callback(function(dt, use, sneak, run)
	if not NEEDS_TEA then return end
	
	if teaTooltip and G_raycastResult and G_raycastResult.hitObject and isTeapot(G_raycastResult.hitObject) then
		brewTea("tea_H")
	end
end))

-- F key (ToggleWeapon) - Brew stoneflower tea
input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
	if not NEEDS_TEA then return end
	
	if teaTooltip and G_raycastResult and G_raycastResult.hitObject and isTeapot(G_raycastResult.hitObject) then
		brewTea("tea_SF")
	end
end))

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Event Handler for Refill Completion                                          │
-- ╰──────────────────────────────────────────────────────────────────────────────╯

local function teacupsRefilled(data)
	local replaced = data.replaced or 0
	local teaType = data.teaType
	local liquidName = localizedLiquidNames[teaType] or "tea"
	
	if replaced > 0 then
		ambient.playSound("item potion up")
		messageBox(3, "Brewed " .. tostring(replaced) .. " teacup" .. (replaced > 1 and "s" or "") .. " of " .. liquidName)
	else
		messageBox(2, "No teacups could be filled")
	end
end

G_eventHandlers.SunsDusk_Tea_teacupsRefilled = teacupsRefilled