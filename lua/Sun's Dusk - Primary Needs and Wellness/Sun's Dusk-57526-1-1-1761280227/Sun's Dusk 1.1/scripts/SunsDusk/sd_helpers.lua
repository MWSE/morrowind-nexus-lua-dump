--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk -.-.- Helpers                                            │
│  Little spells for UI, color, math, and tooltips                     │
╰──────────────────────────────────────────────────────────────────────╯

]]


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
	--r, g, b, a = r / 255, g / 255, b / 255, a / 255
	local maxc, minc = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then s = 0 else s = d / max end

	if max == min then
		h = 0 -- achromatic
	else
    if max == r then
		h = (g - b) / d
    if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
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
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  v       The value
 * @return  Array           The RGB representation
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
	return util.color.rgb(color.r * mult, color.g * mult, color.b * mult)
end

function tableContains(t,entry)
	for a,b in pairs(t) do
		if b == entry then return entry end
	end
	return false
end


-- ╭──────────────────────────╮
-- │  game helpers            │
-- ╰──────────────────────────╯
-- funny text here

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

-- ╭──────────────────────────╮
-- │  Borders and tooltips    │
-- ╰──────────────────────────╯
-- Borders from thin to thicc, calories optional
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

-- Mouse tooltip: small, polite, follows cursor like a kagouti on a snacc run
local function makeMouseTooltip(position, text)
	local layerId = ui.layers.indexOf("Notification")
	local hudLayerSize = ui.layers[layerId].size
	
	-- Determine anchor and offset based on mouse position
	local anchorX, offsetX
	local anchorY, offsetY
	
	-- Horizontal positioning
	if position.x < hudLayerSize.x / 2 then
		-- Left side: anchor left, offset right
		anchorX = 0
		offsetX = 4
	else
		-- Right side: anchor right, offset left
		anchorX = 1
		offsetX = -4
	end
	
	-- Vertical positioning
	if position.y < hudLayerSize.y / 2 then
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
