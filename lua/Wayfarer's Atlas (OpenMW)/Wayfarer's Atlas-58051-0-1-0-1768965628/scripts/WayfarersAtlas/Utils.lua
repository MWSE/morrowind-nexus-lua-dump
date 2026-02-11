local UIUpdater = require("scripts/WayfarersAtlas/UI/UIUpdater")

local OMWUtil = require("openmw.util")
local UI = require("openmw.ui")
local Core = require("openmw.core")

local Utils = {}

---@return table, unknown?
function Utils.getElementPair(elementOrLayout)
	if elementOrLayout.layout then
		return elementOrLayout.layout, elementOrLayout
	else
		return elementOrLayout, nil
	end
end

---@return WAY.UIObject?
function Utils.getObject(elementOrLayout)
	local layout = Utils.getElementPair(elementOrLayout)
	if layout.userData then
		return layout.userData.__object
	else
		return nil
	end
end

function Utils.deepCallEvent(elementOrLayout, eventName, ...)
	local args = { ... }
	Utils.topDown(elementOrLayout, function(childElementOrLayout)
		local object = Utils.getObject(childElementOrLayout)
		if object then
			object:triggerEvent(eventName, table.unpack(args))
		end
	end)
end

local function queueUpdate(elementOrLayout)
	local object = Utils.getObject(elementOrLayout)
	if object then
		UIUpdater:queue(object, object.update)
	end
end

function Utils.deepQueueUpdate(elementOrLayout)
	Utils.topDown(elementOrLayout, queueUpdate)
end

function Utils.topDown(elementOrLayout, callback)
	local layout = Utils.getElementPair(elementOrLayout)
	callback(elementOrLayout)

	if layout.content then
		for _, child in ipairs(layout.content) do
			Utils.topDown(child, callback)
		end
	end
end

function Utils.uiName(elementOrLayout, name)
	local layout = Utils.getElementPair(elementOrLayout)
	layout.name = name
	return layout
end

function Utils.uiAdd(content, elementOrLayout)
	content:add(elementOrLayout)
	return elementOrLayout
end

function Utils.remove(content, name)
	return Utils.removeFilter(content, function(layout)
		return layout.name == name
	end)
end

function Utils.removeAll(content)
	return Utils.removeFilter(content, function()
		return true
	end)
end

function Utils.removeFilter(content, filter)
	for i = #content, 1, -1 do
		local child = content[i]
		local layout = Utils.getElementPair(child)
		if filter(layout) then
			-- https://discord.com/channels/260439894298460160/854806553310920714/1234217836948361236
			table.remove(content, i)

			Utils.destroy(child)
		end
	end
end

function Utils.destroy(elementOrLayout)
	local object = Utils.getObject(elementOrLayout)
	if object then
		object:destroy()
	end

	local _layout, element = Utils.getElementPair(elementOrLayout)
	if element then
		element:destroy()
	end
end

function Utils.findFirst(content, name)
	for _, child in ipairs(content) do
		local childLayout, childElement = Utils.getElementPair(child)
		if childLayout.name == name then
			return childElement or childLayout
		end
	end

	return nil
end

function Utils.clamp(x, min, max)
	return math.max(math.min(x, max), min)
end

function Utils.v2clamp(v2, v2min, v2max)
	return OMWUtil.vector2(Utils.clamp(v2.x, v2min.x, v2max.x), Utils.clamp(v2.y, v2min.y, v2max.y))
end

function Utils.v2mul(a, b)
	return OMWUtil.vector2(a.x * b.x, a.y * b.y)
end

function Utils.v2div(a, b)
	return OMWUtil.vector2(a.x / b.x, a.y / b.y)
end

function Utils.inspectTable(tbl, indentation)
	indentation = indentation or 0

	local str = "{\n"
	for k, v in pairs(tbl) do
		str = str .. string.format("%s%q: ", (" "):rep((indentation + 1) * 3), tostring(k))

		if type(v) == "table" then
			str = str .. Utils.inspectTable(v, indentation + 1)
		else
			str = str .. tostring(v)
		end

		str = str .. ",\n"
	end

	str = str .. (" "):rep(indentation * 3) .. "}"

	return str
end

function Utils.printToConsole(str, color)
	UI.printToConsole(str, color or OMWUtil.color.rgb(255, 255, 255))
end

function Utils.rgb(r, g, b)
	return OMWUtil.color.rgb(r / 255, g / 255, b / 255)
end

function Utils.colorFromGMST(gmst)
	local colorString = Core.getGMST(gmst)
	local numberTable = {}

	for numberString in colorString:gmatch("([^,]+)") do
		if #numberTable == 3 then
			break
		end

		local number = tonumber(numberString:match("^%s*(.-)%s*$"))
		if number then
			table.insert(numberTable, number)
		end
	end

	assert(#numberTable == 3, "Invalid color GMST name: " .. gmst)

	return Utils.rgb(table.unpack(numberTable))
end

local ListLayout = {}
ListLayout.__index = ListLayout
Utils.ListLayout = ListLayout

local v2 = OMWUtil.vector2

function ListLayout.new(options)
	return setmetatable({
		size = options.start or 0,
		padding = options.padding,
		lastLayoutSize = 0,
		firstElement = true,
	}, ListLayout)
end

function ListLayout:appendPadding(padding, layout)
	local size = self.size

	-- Don't pad the first element.
	if self.firstElement then
		layout.props.position = v2(0, size)
		self.size = size + layout.props.size.y
	else
		layout.props.position = v2(0, size + padding)
		self.size = size + padding + layout.props.size.y
	end

	self.firstElement = false
	self.lastLayoutSize = layout.props.size.y

	return layout
end

function ListLayout:append(layout)
	local size = self.size

	-- Don't pad the first element.
	if self.firstElement then
		layout.props.position = v2(0, size)
		self.size = size + layout.props.size.y
	else
		layout.props.position = v2(0, size + self.padding)
		self.size = size + self.padding + layout.props.size.y
	end

	self.firstElement = false
	self.lastLayoutSize = layout.props.size.y

	return layout
end

function ListLayout:alignPrev(alignment)
	if alignment == UI.ALIGNMENT.Start then
		return self.size - self.lastLayoutSize
	elseif alignment == UI.ALIGNMENT.Center then
		return self.size - self.lastLayoutSize / 2
	elseif alignment == UI.ALIGNMENT.End then
		return self.size
	else
		error("Invalid enum: " .. tostring(alignment))
	end
end

function ListLayout:spaceFromBottom(containerSizeY)
	local diff = containerSizeY - self.size
	return diff
end

function Utils.doThis(fn)
	return fn()
end

function Utils.wordWrap(text, maxCharCount)
	local charCount = 0

	return text:gsub("([^%s]+)(%s)", function(snippet, whitespace)
		local combined = snippet .. whitespace

		if whitespace == "\n" then
			charCount = 0
			return combined
		end

		charCount = charCount + #snippet

		if charCount > maxCharCount then
			charCount = 0
			return combined .. "\n"
		end

		return combined
	end)
end

return Utils
