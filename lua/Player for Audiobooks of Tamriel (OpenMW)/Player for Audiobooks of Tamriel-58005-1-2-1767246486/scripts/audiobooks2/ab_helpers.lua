
-- ────────────────────────────────────────────────────────────  Texture cache ──────────────────────────────────────────────────────────────────────
textureCache = {}							   
function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

-- ╭──────────────────────────╮
-- │  General utilities (UI)  │
-- ╰──────────────────────────╯
-- Deep copy bc tables like to share secrets.
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

-- ──────────────────────────────────────────────────────────── Number formatting ───────────────────────────────────────────────────────────────────
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
-- │  Color helpers		   │
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

--[[
 * Converts an HSV color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
 * Assumes h, s, and v are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h	   The hue
 * @param   Number  s	   The saturation
 * @param   Number  v	   The value
 * @return  Array		   The RGB representation
]]
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
	else			   r, g, b = v, p, q
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
-- │  game helpers			│
-- ╰──────────────────────────╯
-- funny text here

function getEquipmentSlot(item)
	if (item == nil) then
		return
	end
	--Finds a equipment slot for an inventory item, if it has one,
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
		elseif (armorRecord.type == types.Armor.TYPE.Shield) then  -- new
			return types.Actor.EQUIPMENT_SLOT.CarriedLeft          -- new
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
	elseif item.type == types.Lockpick then              -- new
		return types.Actor.EQUIPMENT_SLOT.CarriedRight   -- new
	elseif item.type == types.Probe then                 -- new
		return types.Actor.EQUIPMENT_SLOT.CarriedRight   -- new
	elseif item.type == types.Light then                 -- new
		return types.Actor.EQUIPMENT_SLOT.CarriedLeft   -- new
	end                                                  -- new
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
	playerItems = types.Container.inventory(self):getAll()
	for a,b in pairs(playerItems) do
		if b.recordId == "chargen statssheet" then
			saveData.chargenFinished = true
			return true
		end
	end
	return false
end

-- ╭────────────────────────╮
-- │  Borders and tooltips	│
-- ╰────────────────────────╯
-- Borders from thin to thicc, calories optional
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

-- Mouse tooltip: small, polite, follows cursor like a kagouti on a snacc run
local function makeMouseTooltip(position, text)
	local layerId = ui.layers.indexOf("Notification")
	local G_hudLayerSize = ui.layers[layerId].size
	
	-- Determine anchor and offset based on mouse position
	local anchorX, offsetX
	local anchorY, offsetY
	
	-- Horizontal positioning
	if position.x < G_hudLayerSize.x / 2 then
		-- Left side: anchor left, offset right
		anchorX = 0
		offsetX = 4
	else
		-- Right side: anchor right, offset left
		anchorX = 1
		offsetX = -4
	end
	
	-- Vertical positioning
	if position.y < G_hudLayerSize.y / 2 then
		-- Top side: anchor top, offset down
		anchorY = 0
		offsetY = 4
	else
		-- Bottom side: anchor bottom, offset up
		anchorY = 1
		offsetY = -4
	end
	
	local elem = ui.create{
		type = ui.TYPE.Text,
		layer = 'Notification',
		name = uiElementName,
		template = borderTemplate,
		props = {
			text = text,
			textSize = MOUSE_TOOLTIP_FONT_SIZE,
			textColor = MOUSE_TOOLTIP_FONT_COLOR,
			anchor = v2(anchorX, anchorY),
			multiline = true,
			position = v2(position.x + offsetX, position.y + offsetY),
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
				if not mouseTooltip then
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
local function parse_amount(str)
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

-- Search inventory for water
function checkWaterInventory()
	local actor = self
	local inventory = types.Actor.inventory(actor)
	
	local totalWater = 0
	local waterItems = {}
	
	for _, item in ipairs(inventory:getAll()) do
		local record = item.recordId
		local name = item.type.record(item).name or ""
		-- Check if this is a water item - format: "Name (X/Y Water)"
		if name:match("Water%)") then
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

-- Execute the check
--local totalMl, items = checkWaterInventory()



local function alphaFromValue(x)
	if HUD_ALPHA == "Smooth" then
		-- params
		local k = 6	   -- exponential sharpness
		local p = 4	   -- trig sharpness
		local alpha = 0.5 -- 0..1 (only used for the weighted blend)
		
		-- per-step bookkeeping
		local step = math.floor(x * 6)
		local t = x * 6 - step			   -- progress in [0,1] within the step
		local base = step / 5
		local nextStep = math.min((step + 1) / 5, 1)
		
		-- components
		local a = (math.exp(k * t) - 1) / (math.exp(k) - 1)				 -- exp-in(k)
		local b = (math.sin((math.pi/2) * t))^p							  -- trig(p)
		
		-- weighted average
		local e_lin = (1 - alpha) * a + alpha * b
	
		local y = math.min(base + (nextStep - base) * e_lin, 1)
		
		--perceptualBias
		local a = (math.exp(6 * t) - 1) / (math.exp(6) - 1)		   -- exp-in k=6
		local bTrig = (math.sin((math.pi/2) * t))^4					-- trig p=4
		
		-- choose a blend you liked (linear alpha=0.5 shown here)
		local e = 0.5 * a + 0.5 * bTrig
		
		-- perceptual remap (pick ONE)
		local gamma = 1.7
		e = e ^ gamma					 -- Option A: gamma
		
		-- OR:
		-- e = bias(0.7, e)			   -- Option B: bias
		
		-- finalize
		local y = math.min(base + (nextStep - base) * e, 1)
		return y
	else
		local step = math.floor( x * 6)
		return math.min(step / 5, 1)
	end
end

local function alphaFromValue06666(x)
	if HUD_ALPHA == "Smooth" then
		-- parameters
		local k = 6		-- exponential sharpness
		local p = 4		-- trig sharpness
		local alpha = 0.5  -- blend weight
		local gamma = 1.7  -- perceptual correction
		local xMax = 0.6666  -- full brightness reached here

		-- clamp and rescale so [0, 0.6666] -> [0, 1]
		local scaledX = math.min(x / xMax, 1)

		-- define 4 plateaus (3 steps, final = 1)
		local stepCount = 4
		local step = math.floor(scaledX * stepCount)
		local t = scaledX * stepCount - step
		local base = step / (stepCount - 1)
		local nextStep = math.min((step + 1) / (stepCount - 1), 1)

		-- easing components
		local a = (math.exp(k * t) - 1) / (math.exp(k) - 1)
		local b = (math.sin((math.pi / 2) * t)) ^ p

		-- blend easing
		local e = (1 - alpha) * a + alpha * b
		e = e ^ gamma  -- perceptual tweak

		-- interpolate step levels
		local y = math.min(base + (nextStep - base) * e, 1)

		return y
	else
		local stepCount = 4
		local step = math.floor(x * stepCount)
		return math.min(step / (stepCount - 1), 1)
	end
end

--getWidgetAlpha(sleepData.tiredness)
function getWidgetAlpha(val)
	local val = math.max(0,math.min(1,val))
	--if NEEDS_TIREDNESS_BUFFS then -- this setting prevents tiredness from going above 0.666666
	--	return alphaFromValue06666(val)
	--end
	return math.floor(alphaFromValue(val)*100)/100
--alphaFromValue(math.max(0,math.min(1, NEEDS_TIREDNESS_BUFFS and sleepData.tiredness*1.66 or sleepData.tiredness))) -- instead of times 1.666 call different alphaFromValue functions
end




function pad_string(str, length, pad_char)
    -- If the string is already longer than the desired length, return it as is
    if #str >= length then
        return str
    end

    -- Calculate how many padding characters are needed
    local padding_needed = length - #str
    -- Pad the string with the desired character
    local padded_str = str .. string.rep(pad_char, padding_needed)

    return padded_str
end

function formatTemperature(deg)
	if TEMP_CELSIUS_FAHRENHEIT == "°C" then
		return string.format("%.1f°C", deg)
	else
		return string.format("%.1f°F", deg * 9/5 + 32)
	end
end

function formatTemperatureModifier(deg)
	if TEMP_CELSIUS_FAHRENHEIT == "°C" then
		return math.floor(deg*10)/10 .."°C"
	else
		return math.floor(deg * 9/5*10)/10 .."°F"
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

function getHudLayerSize()
	local layerId = ui.layers.indexOf("Modal")
	return ui.layers[layerId].size
end