--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk Helpers                                                  │
╰──────────────────────────────────────────────────────────────────────╯
]]

-- cache textures
textureCache = {}
function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

-- ╭──────────────────────────╮
-- │  UI utilities            │
-- ╰──────────────────────────╯

function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

-- ╭──────────────────────────╮
-- │  Format Numbers          │
-- ╰──────────────────────────╯

function f1dot(number)
	return string.format("%.1f",number+0.05)
end

function f1(number)
	local formatted = string.format("%.1f", number)
	if formatted:sub(#formatted, #formatted) == "0" then
		return tonumber(string.format("%.0f", number))
	end
	return formatted
end

-- two decimal floor, no surprises or fluff.
function f2(num)
	return math.floor(num * 100) / 100
end

-- ╭──────────────────────────╮
-- │  Bounding Box validation │
-- ╰──────────────────────────╯

function isValidBBox(bbox)
	local hs = bbox.halfSize
	local bc = bbox.center
	if hs.x ~= hs.x or hs.y ~= hs.y or hs.z ~= hs.z
		or bc.x ~= bc.x or bc.y ~= bc.y or bc.z ~= bc.z
		or hs.x < 0.001 or hs.y < 0.001 or hs.z < 0.001
		or hs.x > 1e6 or hs.y > 1e6 or hs.z > 1e6 then
		return false
	end
	return true
end

-- ╭──────────────────────────╮
-- │  Bitmask helpers         │
-- ╰──────────────────────────╯

function setBit(n, h)
	local b = 2^(h-1)
	if math.floor(n / b) % 2 == 0 then return n + b end
	return n
end

function clearBit(n, h)
	local b = 2^(h-1)
	if math.floor(n / b) % 2 == 1 then return n - b end
	return n
end

function countBits(n)
	local c = 0
	while n > 0 do
		c = c + n % 2
		n = math.floor(n / 2)
	end
	return c
end

-- ╭──────────────────────────╮
-- │  Color helpers           │
-- ╰──────────────────────────╯

function getColorFromGameSettings(gmst)
	local result = core.getGMST(gmst)
	if not result then
		return util.color.rgb(1,1,1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("Uunexpected color triplet size = " .. #rgb .. " ; using white")
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

function rgbToHsv(r, g, b, a)
	if type(r) == "table" or type(r) == "userdata" then
		g = r.g or r[2]
		b = r.b or r[3]
		a = r.a or r[4]
		r = r.r or r[1]
	end
	--r, g, b, a = r / 255, g / 255, b / 255, a / 255
	local maxc, minc = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = maxc

	local d = maxc - minc
	if maxc == 0 then s = 0 else s = d / maxc end

	if maxc == minc then
		h = 0 -- achromatic
	else
	if maxc == r then
		h = (g - b) / d
	if g < b then h = h + 6 end
	elseif maxc == g then h = (b - r) / d + 2
	elseif maxc == b then h = (r - g) / d + 4
	end
	h = h / 6
	end
	return h, s, v, a
end

-- ╭──────────────────────────╮
-- │  HSV to RGB              │
-- ╰──────────────────────────╯

function hsvToRgb(h, s, v, a)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	local r, g, b
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	else               r, g, b = v, p, q
	end
	return r, g, b, a
	-- If you need 0–255: return r*255, g*255, b*255, a
end

function mixColors(color1, color2, mult)
	local mult = mult or 0.5
	return util.color.rgb(
		color1.r * mult + color2.r * (1 - mult),
		color1.g * mult + color2.g * (1 - mult),
		color1.b * mult + color2.b * (1 - mult)
	)
end

function darkenColor(color, mult)
	return util.color.rgb(math.min(1,color.r * mult), math.min(1,color.g * mult), math.min(1,color.b * mult))
end

function tableContains(t,entry)
	for a,b in pairs(t) do
		if b == entry then return entry end
	end
	return false
end

-- ╭──────────────────────────╮
-- │  Equipment helpers       │
-- ╰──────────────────────────╯

function getEquipmentSlot(item)
	if (item == nil) then
		return
	end
	
	if item.type == types.Armor then
		local armorRecord = types.Armor.records[item.recordId]
		if (armorRecord.type == types.Armor.TYPE.RGauntlet) then
			return types.Actor.EQUIPMENT_SLOT.RightGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.LGauntlet) then
			return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.Boots) then
			return types.Actor.EQUIPMENT_SLOT.Boots
		elseif (armorRecord.type == types.Armor.TYPE.Cuirass) then
			return types.Actor.EQUIPMENT_SLOT.Cuirass
		elseif (armorRecord.type == types.Armor.TYPE.Greaves) then
			return types.Actor.EQUIPMENT_SLOT.Greaves
		elseif (armorRecord.type == types.Armor.TYPE.LBracer) then
			return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.RBracer) then
			return types.Actor.EQUIPMENT_SLOT.RightGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.RPauldron) then
			return types.Actor.EQUIPMENT_SLOT.RightPauldron
		elseif (armorRecord.type == types.Armor.TYPE.LPauldron) then
			return types.Actor.EQUIPMENT_SLOT.LeftPauldron
		elseif (armorRecord.type == types.Armor.TYPE.RPauldron) then
			return types.Actor.EQUIPMENT_SLOT.RightPauldron
		elseif (armorRecord.type == types.Armor.TYPE.Helmet) then
			return types.Actor.EQUIPMENT_SLOT.Helmet
		elseif (armorRecord.type == types.Armor.TYPE.Shield) then
			return types.Actor.EQUIPMENT_SLOT.CarriedLeft
		end
	elseif item.type == types.Clothing then
		local clothingRecord = types.Clothing.records[item.recordId]
		if (clothingRecord.type == types.Clothing.TYPE.Amulet) then
			return types.Actor.EQUIPMENT_SLOT.Amulet
		elseif (clothingRecord.type == types.Clothing.TYPE.Belt) then
			return types.Actor.EQUIPMENT_SLOT.Belt
		elseif (clothingRecord.type == types.Clothing.TYPE.LGlove) then
			return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
		elseif (clothingRecord.type == types.Clothing.TYPE.RGlove) then
			return types.Actor.EQUIPMENT_SLOT.RightGauntlet
		elseif (clothingRecord.type == types.Clothing.TYPE.Ring) then
			return types.Actor.EQUIPMENT_SLOT.RightRing
		elseif (clothingRecord.type == types.Clothing.TYPE.Skirt) then
			return types.Actor.EQUIPMENT_SLOT.Skirt
		elseif (clothingRecord.type == types.Clothing.TYPE.Shirt) then
			return types.Actor.EQUIPMENT_SLOT.Shirt
		elseif (clothingRecord.type == types.Clothing.TYPE.Shoes) then
			return types.Actor.EQUIPMENT_SLOT.Boots
		elseif (clothingRecord.type == types.Clothing.TYPE.Robe) then
			return types.Actor.EQUIPMENT_SLOT.Robe
		elseif (clothingRecord.type == types.Clothing.TYPE.Pants) then
			return types.Actor.EQUIPMENT_SLOT.Pants
		end
	elseif item.type == types.Weapon then
		local weaponRecord = item.type.records[item.recordId]
		if (weaponRecord.type == types.Weapon.TYPE.Arrow or weaponRecord.type == types.Weapon.TYPE.Bolt) then
			return types.Actor.EQUIPMENT_SLOT.Ammunition
		end
		return types.Actor.EQUIPMENT_SLOT.CarriedRight
	elseif item.type == types.Lockpick then
		return types.Actor.EQUIPMENT_SLOT.CarriedRight
	elseif item.type == types.Probe then
		return types.Actor.EQUIPMENT_SLOT.CarriedRight
	elseif item.type == types.Light then
		return types.Actor.EQUIPMENT_SLOT.CarriedLeft
	end
	-- --print("Couldn't find slot for " .. item.recordId)
	return nil
end

function getArmorWeight(record)
	
	-- Apply quality multiplier to base armor
	local baseArmor = record.baseArmor

	--local durabilityCurrent = record.health
	--local durabilityMax = record.health
	local referenceWeight = 0
	local recordType = record.type
	if recordType == types.Armor.TYPE.Boots then
		referenceWeight = core.getGMST("iBootsWeight")
	elseif recordType == types.Armor.TYPE.Cuirass then
		referenceWeight = core.getGMST("iCuirassWeight")
	elseif recordType == types.Armor.TYPE.Greaves then
		referenceWeight = core.getGMST("iGreavesWeight")
	elseif recordType == types.Armor.TYPE.Helmet then
		referenceWeight = core.getGMST("iHelmWeight")
	elseif recordType == types.Armor.TYPE.LBracer then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.RBracer then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.LPauldron then
		referenceWeight = core.getGMST("iPauldronWeight")
	elseif recordType == types.Armor.TYPE.RPauldron then
		referenceWeight = core.getGMST("iPauldronWeight")
	elseif recordType == types.Armor.TYPE.LGauntlet then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.RGauntlet then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.Shield then
		referenceWeight = core.getGMST("iShieldWeight")
	end
	local epsilon = 5e-4
	local class = "???"
	--local skill = 0
	if record.weight == 0 then
		class = "unarmored"
		--skill = types.Player.stats.skills.unarmored(self).modified
	elseif record.weight <= referenceWeight * core.getGMST("fLightMaxMod") + epsilon then
		class = "light"
		--skill = types.Player.stats.skills.lightarmor(self).modified
	elseif record.weight <= referenceWeight * core.getGMST("fMedMaxMod") + epsilon then
		class = "medium"
		--skill = types.Player.stats.skills.mediumarmor(self).modified
	else
		class = "heavy"
		--skill = types.Player.stats.skills.heavyarmor(self).modified
	end
	--local playerArmor = baseArmor * skill / core.getGMST("iBaseArmorSkill")
	return class
end

-- ╭──────────────────────────╮
-- │  CharGen                 │
-- ╰──────────────────────────╯

function chargenFinished()
	if saveData.chargenFinished then
		return true
	end
	if types.Player.getBirthSign(self) ~= "" then
		saveData.chargenFinished = true
		return true
	end
	if types.Player.isCharGenFinished(self) then
		saveData.chargenFinished = true
		return true
	end
	if typesActorInventorySelf:find("chargen statssheet") then
		saveData.chargenFinished = true
		return true
	end
	return false
end

-- ╭──────────────────────────╮
-- │  Borders and tooltips    │
-- ╰──────────────────────────╯
if ui then
	local makeBorder = require("scripts.SunsDusk.ui_makeborder")
	local BORDER_STYLE = "thin" --"none", "thin", "normal", "thick", "verythick"
	local background  = ui.texture { path = 'black' }
	local borderOffset = BORDER_STYLE == "verythick" and 4 or BORDER_STYLE == "thick" and 3 or BORDER_STYLE == "normal" and 2 or (BORDER_STYLE == "thin" or BORDER_STYLE == "max performance") and 1 or 0
	local borderFile = "thin"
	if BORDER_STYLE == "verythick" or BORDER_STYLE == "thick" then
		borderFile = "thick"
	end
	local OPACITY = 0.8
	
	local borderTemplate = makeBorder(borderFile, borderColor or nil, borderOffset, {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			relativeSize = v2(1, 1),
			alpha = OPACITY,
		}
	}).borders
	
	-- mouse tooltip
	local function makeMouseTooltip(position, text)
		local layerId = ui.layers.indexOf("Notification")
		local G_hudLayerSize = ui.layers[layerId].size
		
		-- Determine anchor and offset based on mouse position
		local anchorX, offsetX
		local anchorY, offsetY
		
		-- Horizontal positioning
		if HUD_X_POS < G_hudLayerSize.x / 3 then
			-- Left side: anchor left, offset right
			anchorX = 0
			offsetX = 20
		else
			-- Right side: anchor right, offset left
			anchorX = 1
			offsetX = -4
		end
		
		-- Vertical positioning
		if position.y < G_hudLayerSize.y / 2 then
			-- Top side: anchor top, offset down
			anchorY = 0
			offsetY = 5
		else
			-- Bottom side: anchor bottom, offset up
			anchorY = 1
			offsetY = -4
		end
		
		local elem = ui.create{
			type = ui.TYPE.Flex,
			layer = 'Notification',
			name = uiElementName,
			template = borderTemplate,
			props = {
				autoSize = true,
				anchor = v2(anchorX, anchorY),
				position = v2(position.x + offsetX, position.y + offsetY),
			},
			content = ui.content {
				{ props = { size = v2(1, 1) * 2 } },
				{
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
					},
					content = ui.content {
						{ props = { size = v2(1, 1) * 4 } },
						{
							type = ui.TYPE.Text,
							props = {
								text = text,
								textSize = WIDGET_TOOLTIP_FONT_SIZE,
								textColor = WIDGET_TOOLTIP_FONT_COLOR,
								multiline = true,
							},
						},
						{ props = { size = v2(1, 1) * 5 } },
					},
				},
				{ props = { size = v2(1, 1) * 5 } },
			},
			userData = {
				offset = v2(offsetX, offsetY),
			}
		}
		return elem
	end
	
	function addTooltip(elem, text)
		if ENABLE_TOOLTIPS then
			elem.events = {
				mouseRelease = async:callback(function(data, elem)
					SDHUD_mouseRelease(data, elem)
				end),
				mousePress = async:callback(function(data, elem)
					SDHUD_mousePress(data, elem)
				end),
				focusGain = async:callback(function(data, elem)
					if data and not mouseTooltip then
						local pos = data and data.position or v2(50,50)
						mouseTooltip = makeMouseTooltip(data.position, text)
					end
				end),
				focusLoss = async:callback(function(_, elem)
					if mouseTooltip then
						mouseTooltip:destroy()
						mouseTooltip = nil
					end
				end),
				mouseMove = async:callback(function(data, elem)
					if not mouseTooltip then
						mouseTooltip = makeMouseTooltip(data.position, text)
					end
					if mouseTooltip then
						mouseTooltip.layout.props.position = v2(data.position.x+mouseTooltip.layout.userData.offset.x,data.position.y+mouseTooltip.layout.userData.offset.y)
						mouseTooltip:update()
					end
					SDHUD_mouseMove(data, elem)
				end),
			}
		end
	end
end

-- ╭──────────────────────────╮
-- │  Text Formatting         │
-- ╰──────────────────────────╯

function formatTimeLeft(minutes)
	local hours = math.floor(minutes / 60)
	local mins = minutes % 60
	
	if hours > 0 then
		if mins > 0 then
			return string.format("%d:%02d hours", hours, mins)
		else
			return string.format("%d hour%s", hours, hours > 1 and "s" or "")
		end
	else
		return string.format("%d min%s", minutes, minutes ~= 1 and "s" or "")
	end
end

-- Function to extract ml from formatted string (handles both "XL" and "X ml")
function parse_amount(str)
	local liters = str:match("([%d%.]+)L")
	if liters then
		return tonumber(liters) * 1000
	end
	local ml = str:match("(%d+)%s*ml")
	if ml then
		return tonumber(ml)
	end
	return nil
end

-- ╭──────────────────────────╮
-- │  Water in Inventory      │
-- ╰──────────────────────────╯

function checkWaterInventory()
	local actor = self
	local inventory = types.Actor.inventory(actor)
	
	local totalWater = 0
	local waterItems = {}
	
	for _, item in ipairs(inventory:getAll()) do
		local record = item.recordId
		local name = item.type.record(item).name or ""
		-- Check if this is a water item - format: "Name (X/Y Water)"
		if name:lower():sub(-8,-1) == "l water)" then
			-- Extract the current amount from the name
			-- Updated pattern: captures "250 ml" or "1L" before the "/"
			local currentAmount = name:match("%(([^/]+)/")
			
			if currentAmount then
				local ml = parse_amount(currentAmount)
				if ml then
					totalWater = totalWater + (ml * item.count)
					table.insert(waterItems, {
						name = name,
						count = item.count,
						mlPerItem = ml
					})
				end
			end
		end
	end
	
	return totalWater, waterItems
end

function checkHasDirtyWater()
	local actor = self
	local inventory = types.Actor.inventory(actor)
	
	local totalWater = 0
	local waterItems = {}
	
	-- Patterns using [Ll] to match either case
	local dirtyWaterPatterns = {
		"[Ll] Saltwater%)$",
		"[Ll] Suspicious Water%)$",
	}
	
	for _, item in ipairs(inventory:getAll()) do
		local record = item.recordId
		local name = item.type.record(item).name or ""
		
		-- Check if this is a dirty water item
		local isDirtyWater = false
		for _, pattern in ipairs(dirtyWaterPatterns) do
			if name:match(pattern) then
				isDirtyWater = true
				break
			end
		end
		
		if isDirtyWater then
			-- Extract the current amount from the name
			local currentAmount = name:match("%(([^/]+)/")
			
			if currentAmount then
				local ml = parse_amount(currentAmount)
				if ml then
					totalWater = totalWater + (ml * item.count)
					table.insert(waterItems, {
						name = name,
						count = item.count,
						mlPerItem = ml
					})
				end
			end
		end
	end
	return totalWater > 0, totalWater, waterItems
end

-- local totalMl, items = checkWaterInventory()

-- ╭──────────────────────────╮
-- │  Smooth Alpha            │
-- ╰──────────────────────────╯

-- alpha calculation
-- stages = number of alpha plateaus across [0,1] (default 6)
local function alphaFromValue(x, stages)
	stages = stages or 6
	local last = stages - 1
	local step = math.floor(x * stages)
	local t = x * stages - step -- progress in [0,1] within the step
	local base = math.min(step / last, 1)
	local nextStep = math.min((step + 1) / last, 1)
	if HUD_ALPHA == "Smooth" then
		-- blend exp-in and trig easing, then perceptual gamma
		local a = (math.exp(6 * t) - 1) / (math.exp(6) - 1)
		local b = (math.sin((math.pi / 2) * t))^4
		local e = (0.5 * a + 0.5 * b)^1.7
		return math.min(base + (nextStep - base) * e, 1)
	elseif HUD_ALPHA == "Gradual + better visible" then
		return math.min(1, base^0.5 + 0.3)
	else
		return base
	end
end

-- getWidgetAlpha(val [, stages [, minVisible]])
-- stages: alpha plateaus (default 6). minVisible: floor for the lowest stage (default 0)
function getWidgetAlpha(val, stages, minVisible)
	val = math.max(0, math.min(1, val))
	minVisible = minVisible or 0
	local a = alphaFromValue(val, stages)
	return math.floor((minVisible + (1 - minVisible) * a) * 100) / 100
end

function tableLength(t)
	local i = 0
	for _ in pairs(t) do
		i = i+1
	end
	return i
end


function pad_string(str, length, pad_char)
	local padding_needed = length - #str
	if padding_needed <= 0 then
		return str
	end
	local padded_str = str .. string.rep(pad_char, padding_needed)
	return padded_str
end

function formatTemperature(deg)
	if TEMP_CELSIUS_FAHRENHEIT == "°C" then
		return string.format("%.1f", deg)..(TEMP_FONT_FIX and "" or "°").."C"
	else
		return string.format("%.1f", deg * 9/5 + 32)..(TEMP_FONT_FIX and "" or "°").."F"
	end
end

function formatTemperatureShort(deg)
	if TEMP_CELSIUS_FAHRENHEIT == "°C" then
		return string.format("%i", deg)..(TEMP_FONT_FIX and "" or "°")
	else
		return string.format("%i", deg * 9/5 + 32)..(TEMP_FONT_FIX and "" or "°")
	end
end

function formatTemperatureModifier(deg)
	if TEMP_CELSIUS_FAHRENHEIT == "°C" then
		return (math.floor(deg*10)/10 >= 0 and "+" or "")..math.floor(deg*10)/10 ..(TEMP_FONT_FIX and "" or "°").."C"
	else
		return (math.floor(deg * 9/5*10)/10 >= 0 and "+" or "")..math.floor(deg * 9/5*10)/10 ..(TEMP_FONT_FIX and "" or "°").."F"
	end
end

function getCameraVector()
	local yaw = camera.getYaw()
	local pitch = camera.getPitch()
	local cosPitch = math.cos(pitch)
	local sinPitch = math.sin(pitch)
	local cosYaw = math.cos(yaw)
	local sinYaw = math.sin(yaw)
	
	return v3(
		sinYaw * cosPitch,
		cosYaw * cosPitch,
		-sinPitch
	):normalize()
end

function isStew(item)
	local dbEntry = saveData.registeredConsumables[item.recordId]
	if not dbEntry then return false end
	if not dbEntry.timestamp then return false end
	return dbEntry
end

function isTheft(item)
	if item.owner.recordId then
		return true
	elseif item.owner.factionId and types.NPC.getFactionRank(self, item.owner.factionId) == 0 then
		return true
	elseif item.owner.factionId and types.NPC.getFactionRank(self, item.owner.factionId) < (item.owner.factionRank or 0) then
		return true
	end
	return false
end

function getId(object)
	if not object.contentFile then return object.id end -- Generated records
	return object.contentFile..object.id:sub(-6) -- Morrowind.esm000123
end

local FATIGUE_BASE = core.getGMST('fFatigueBase') --1.25
local FATIGUE_MULT = core.getGMST('fFatigueMult') --0.5

getFatigueTerm = function(actor)
	local normalizedFatigue
	if typesPlayerStatsSelf.fatigue.base == 0 then
		normalizedFatigue = 1
	else
		normalizedFatigue = math.max(0, typesPlayerStatsSelf.fatigue.current / typesPlayerStatsSelf.fatigue.base)
	end
	
	return FATIGUE_BASE - FATIGUE_MULT * (1 - normalizedFatigue)
end