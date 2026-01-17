--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Debug Widget								  		   │
│  Handy Dandy									 					   │
╰──────────────────────────────────────────────────────────────────────╯
]]

-- scripts/debug_widget.lua

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local v2 = util.vector2

local function makeDebugWidget(name)
	local title = name
	local name = name or ""
	local widget = nil
	local contentFlex = nil
	local settingsSection = nil
	local prints = {}

	storageName = name or ""
	
	defaultPosition = defaultPosition or v2(100, 300)
	
	-- Setup storage
	settingsSection = storage.playerSection("ownlysDebugWidgets")
	
	-- Load position from storage or use default
	local function clampPosition(pos)
		local layerId = ui.layers.indexOf("HUD")
		
		-- Clamp with some margin (at least 50px visible)
		local minSize = 50
		return v2(
			math.max(0, math.min(pos.x, G_hudLayerSize.x - minSize)),
			math.max(0, math.min(pos.y, G_hudLayerSize.y - minSize))
		)
	end
	local savedX = settingsSection:get("WIDGET_"..name.."_X_POS")
	local savedY = settingsSection:get("WIDGET_"..name.."_Y_POS")
	local position = savedX and savedY and v2(savedX, savedY) or defaultPosition
	position = clampPosition(position)
	
	local fontSize = settingsSection:get("WIDGET_"..name.."_FONT_SIZE") or 16
	local textTemplate = {
		props = {
			textColor = util.color.rgb(0.9, 0.9, 0.9),
			textShadow = true,
			textSize = fontSize,
		}
	}
	
	local template = {
		content = ui.content{
			{
				type = ui.TYPE.Image,
				props = {
					resource = ui.texture { path = 'black' },
					relativeSize = v2(1,1),
					alpha = 0.5
				}
			}
		}
	}
	
	widget = ui.create({
		type = ui.TYPE.Container,
		layer = 'Modal',
		template = template,
		props = {
			position = position,
			autoSize = true,
		},
		userData = { windowStartPosition = position },
		content = ui.content{}
	})
	
	widget.layout.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				elem.userData.isDragging = true
				elem.userData.dragStartPosition = data.position
				elem.userData.windowStartPosition = widget.layout.props.position
			end
			widget:update()
		end),
		
		mouseRelease = async:callback(function(data, elem)
			if elem.userData.isDragging then
				elem.userData.isDragging = false
				-- Save position when drag ends
				local pos = clampPosition(widget.layout.props.position)
				settingsSection:set("WIDGET_"..name.."_X_POS", math.floor(pos.x))
				settingsSection:set("WIDGET_"..name.."_Y_POS", math.floor(pos.y))
				widget.layout.props.position = pos
			end
			widget:update()
		end),
		
		mouseMove = async:callback(function(data, elem)
			if elem.userData.isDragging then
				local delta = data.position - elem.userData.dragStartPosition
				local newPos = elem.userData.windowStartPosition + delta
				widget.layout.props.position = clampPosition(newPos)
				widget:update()
			end
		end),
	}
	
	contentFlex = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			autoSize = true,
			arrange = ui.ALIGNMENT.Start
		},
		content = ui.content{
			title and {
				type = ui.TYPE.Text,
				template = textTemplate,
				props = {
					text = title,
					textColor = util.color.rgb(1, 1, 0.5),
				}
			} or {}
		}
	}
	widget.layout.content:add(contentFlex)
	widget:update()
	if G_mousewheelJobs then
		table.insert(G_mousewheelJobs, function(dir)
			if widget and widget.layout then
				if widget.layout.userData.isDragging then
					fontSize = math.max(1,fontSize + dir)
					settingsSection:set("WIDGET_"..name.."_FONT_SIZE", fontSize)
					textTemplate.props.textSize = fontSize
					widget:update()
				end
			end
		end)
	end

	local function formatValue(value)
		if type(value) == "number" then
			return string.format("%.2f", value)
		elseif type(value) == "boolean" then
			return value and "YES" or "NO"
		elseif type(value) == "table" then
			if value.x and value.y and value.z then
				return string.format("(%.2f, %.2f, %.2f)", value.x, value.y, value.z)
			elseif value.name then
				return value.name
			else
				return "[table]"
			end
		end
		return tostring(value)
	end
	
	local function clear()
		prints = {}
	end
	
	local function print(...)
		local n = select("#", ...) -- includes nil arguments
		local first = select(1, ...)
	
		-- If a single table is passed, print its contents (sorted)
		if n == 1 and type(first) == "table" then
			local t = first
			local sortedKeys = {}
	
			for key in pairs(t) do
				table.insert(sortedKeys, key)
			end
	
			table.sort(sortedKeys, function(a, b)
				return tostring(a):lower() < tostring(b):lower()
			end)
	
			for _, key in ipairs(sortedKeys) do
				table.insert(prints, key .. ": " .. formatValue(t[key]))
			end
	
		else
			-- Otherwise, concatenate all arguments (including nils)
			local str = ""
			for i = 1, n do
				local line = select(i, ...)
				if str ~= "" then
					str = str .. " "
				end
				str = str .. tostring(line) -- tostring(nil) = "nil"
			end
			table.insert(prints, str)
		end
		
		while #contentFlex.content > 1 do
			table.remove(contentFlex.content)
		end
		
		for _, line in ipairs(prints) do
			contentFlex.content:add({
				type = ui.TYPE.Text,
				template = textTemplate,
				props = {
					text = tostring(line),
				}
			})
		end
		widget:update()
	end
	
	local function display(...)
		if not contentFlex then return end
	
		local n = select("#", ...) -- includes nils
		local first = select(1, ...)
	
		-- Keep title, clear rest
		while #contentFlex.content > 1 do
			table.remove(contentFlex.content)
		end
	
		-- If single argument is a table, show key-value pairs
		if n == 1 and type(first) == "table" then
			local t = first
			local sortedKeys = {}
	
			for key in pairs(t) do
				table.insert(sortedKeys, key)
			end
	
			table.sort(sortedKeys, function(a, b)
				return tostring(a):lower() < tostring(b):lower()
			end)
	
			for _, key in ipairs(sortedKeys) do
				contentFlex.content:add({
					type = ui.TYPE.Text,
					template = textTemplate,
					props = {
						text = key .. ": " .. formatValue(t[key]),
					}
				})
			end
		else
			-- Each argument is a separate line (handle nil safely)
			for i = 1, n do
				local line = select(i, ...)
				contentFlex.content:add({
					type = ui.TYPE.Text,
					template = textTemplate,
					props = {
						text = tostring(line), -- tostring(nil) = "nil"
					}
				})
			end
		end
	
		widget:update()
	end
	local function dest()
		widget:destroy()
	end
	
	return {
		display = display,
		p = print,
		clear = clear,
		destroy = dest,
	}
end

return makeDebugWidget