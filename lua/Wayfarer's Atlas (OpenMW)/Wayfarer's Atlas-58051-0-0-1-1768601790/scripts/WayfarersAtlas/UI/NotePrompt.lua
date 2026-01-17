local OMWUtil = require("openmw.util")
local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local Async = require("openmw.async")
local Core = require("openmw.core")

local Utils = require("scripts/WayfarersAtlas/Utils")
local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")
local TooltipController = require("scripts/WayfarersAtlas/UI/Controllers/TooltipController")
local Button = require("scripts/WayfarersAtlas/UI/Widgets/Button")
local Checkbox = require("scripts/WayfarersAtlas/UI/Widgets/Checkbox")
local UIContext = require("scripts/WayfarersAtlas/UI/UIContext")
local Window = require("scripts/WayfarersAtlas/UI/Widgets/Window")
local UIUpdater = require("scripts/WayfarersAtlas/UI/UIUpdater")

local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Array = Immutable.Array
local Dictionary = Immutable.Dictionary

local v2 = OMWUtil.vector2
local l10n = Core.l10n("WayfarersAtlas")

---@class WAY.NotePrompt: WAY.UIObject
local NotePrompt = UIObject:extend("NotePrompt")

local WHITE_COLOR = Utils.rgb(255, 255, 255)
local WHITE_RESOURCE = UI.texture({ path = "white" })

local StaticSavedPos = nil
local StaticSavedSize = nil

local function distributeArray(i, squareSize, rowSize, spacing)
	-- stylua: ignore
	return v2(
		(squareSize + spacing) * ((i - 1) % rowSize),
		(squareSize + spacing) * math.floor((i - 1) / rowSize)
	)
end

local function arrayContainer(props)
	local layouts = props.layouts
	local len = #layouts

	local selected = props.index
	local selectionBorder = UIObject.bind({
		template = I.MWUI.templates.bordersThick,
		props = {
			size = v2(props.squareSize + 2, props.squareSize + 2),
		},
	})

	local function selectItem(index, wasClicked)
		local layout = layouts[index]

		selectionBorder:getProps().position = Utils.v2clamp(layout.props.position - v2(1, 1), v2(0, 0), v2(2000, 2000))

		selected = index

		props.onSelected(index, Utils.getObject(layout), wasClicked)
	end

	-- Defer to the next resumption cycle so that we don't invoke our callback
	-- before the caller has had a chance to initialize.
	UIUpdater:defer(function()
		if not selectionBorder:isDestroyed() then
			selectItem(selected, false)
		end
	end)

	for i, layout in pairs(layouts) do
		local object = assert(Utils.getObject(layout))
		object:registerEvent("mousePress", function()
			selectItem(i, true)
		end)
	end

	if props.tooltipFn then
		TooltipController:register(selectionBorder, function(content)
			local object = Utils.getObject(layouts[selected])
			if object then
				props.tooltipFn(content, object)
			end
		end)
	end

	table.insert(layouts, selectionBorder:getLayout())

	return {
		props = {
			size = v2(
				(props.squareSize + props.spacing) * props.rowSize,
				(props.squareSize + props.spacing) * (math.floor((len - 1) / props.rowSize) + 1)
			),
		},
		content = UI.content(layouts),
	}
end

local function colorEquals(c1, c2)
	return c1.r == c2.r and c1.g == c2.g and c1.b == c2.b
end

local function colorPalettes(squareSize, rowSize, spacing, selected, onSelected)
	local layouts = {}

	for i, palette in ipairs(UIContext.noteColors) do
		table.insert(layouts, {
			type = UI.TYPE.Image,
			props = {
				size = v2(squareSize, squareSize),
				position = distributeArray(i, squareSize, rowSize, spacing),
				resource = WHITE_RESOURCE,
				color = palette,
			},
		})

		UIObject.bind(layouts[i])
	end

	return arrayContainer({
		layouts = layouts,
		index = Array.find(UIContext.noteColors, function(color)
			return colorEquals(color, selected)
		end) or 1,
		squareSize = squareSize,
		rowSize = rowSize,
		spacing = spacing,
		onSelected = onSelected,
	})
end

-- Omit parent directories and the file extension.
local function getFileName(path)
	return path:match("([^/\\]+)%.[^%.+]+$")
end

local function extractIconNameFromPath(iconPath)
	-- If it does not have a file extension, return early.
	if not iconPath:find("%.[^%.+]*$") then
		return ""
	end

	return getFileName(iconPath)
		-- Uppercase the first letter.
		:gsub("^[^%w]-(%w)", string.upper)
		-- Uppercase the first letter between words and force a space.
		:gsub("[- ](%w)", function(letter)
			return " " .. letter:upper()
		end)
end

local function getIconNameFromPath(iconPath)
	local fileName = getFileName(iconPath)
	local l10nKey = "Icon_" .. fileName
	local localizedName = l10n(l10nKey)

	if localizedName == l10nKey then
		return extractIconNameFromPath(iconPath)
	else
		return localizedName
	end
end

local function populateIconTooltip(content, uiObject)
	local iconPath = uiObject:getLayout().userData.iconPath
	local text = getIconNameFromPath(iconPath)
	if text == "" then
		return
	end

	content:add({
		template = I.MWUI.templates.textNormal,
		props = {
			multiline = true,
			text = text,
		},
	})
end

local function icons(squareSize, rowSize, spacing, selected, onSelected)
	local layouts = {}

	for i, iconPath in ipairs(UIContext.noteIconPaths) do
		table.insert(layouts, {
			type = UI.TYPE.Image,
			props = {
				size = v2(squareSize, squareSize),
				position = distributeArray(i, squareSize, rowSize, spacing),
				resource = UI.texture({ path = iconPath }),
				color = WHITE_COLOR,
			},
			userData = {
				iconPath = iconPath,
			},
		})

		TooltipController:register(UIObject.bind(layouts[i]), populateIconTooltip)
	end

	return arrayContainer({
		layouts = layouts,
		index = Array.find(UIContext.noteIconPaths, function(icon)
			return icon == selected
		end) or 1,
		squareSize = squareSize,
		rowSize = rowSize,
		spacing = spacing,
		tooltipFn = populateIconTooltip,
		onSelected = onSelected,
	})
end

---@class WAY.NotePrompt.Props
---@field mode "new" | "edit"
---@field record WAY.NoteRecord
---@field onChanged fun(newRecord: WAY.NoteRecord)
---@field onConfirmed fun(newRecord: WAY.NoteRecord)
---@field onCanceled fun()
---@field onRemoved fun()

---@param props WAY.NotePrompt.Props
function NotePrompt.new(props)
	local self

	local listLayout = Utils.ListLayout.new({ padding = 24, start = 8 })
	local record = props.record
	---@type WAY.UIObject
	local selectedIconUIObject = nil
	---@type WAY.UIObject
	local lastSelectedIconUIObject = nil

	local nameIsDesired = props.mode == "edit"

	local function updateIconUIObject()
		if lastSelectedIconUIObject then
			lastSelectedIconUIObject:getProps().color = WHITE_COLOR
		end

		if selectedIconUIObject then
			selectedIconUIObject:getProps().color = record.color
		end

		lastSelectedIconUIObject = selectedIconUIObject
	end

	local function patchRecord(delta)
		record = Dictionary.merge(record, delta)
		props.onChanged(record)
	end

	local nameLayout = {
		template = I.MWUI.templates.textEditLine,
		props = {
			relativeSize = v2(1, 1),
			size = v2(0, 0),
			text = record.name,
		},
		events = {
			textChanged = Async:callback(function(newStr, layout)
				nameIsDesired = newStr ~= ""
				layout.props.text = newStr

				patchRecord({ name = newStr })
			end),
		},
	}

	local content = UI.content({
		listLayout:append({
			template = I.MWUI.templates.textNormal,
			props = {
				size = v2(0, 16),
				relativeSize = v2(1, 0),
				text = l10n("Name"),
				textAlignV = UI.ALIGNMENT.Center,
			},
		}),
		{
			template = I.MWUI.templates.borders,
			props = {
				position = v2(0, listLayout:alignPrev(UI.ALIGNMENT.Center)),
				relativePosition = v2(1, 0),
				anchor = v2(1, 0.5),
				size = v2(0, 24),
				relativeSize = v2(0.6, 0),
			},
			content = UI.content({
				SharedUI.padding(1, nameLayout),
			}),
		},
		listLayout:append({
			template = I.MWUI.templates.textNormal,
			props = {
				size = v2(0, 16),
				relativeSize = v2(1, 0),
				text = l10n("Pinned"),
				textAlignV = UI.ALIGNMENT.Center,
				resource = WHITE_RESOURCE,
			},
		}),
		{
			props = {
				position = v2(0, listLayout:alignPrev(UI.ALIGNMENT.Center)),
				anchor = v2(1, 0.5),
				size = v2(0, 30),
				relativePosition = v2(1, 0),
				relativeSize = v2(0.6, 0),
			},
			content = UI.content({
				Checkbox.new()
					:setEnabled(record.pinned)
					:registerEvent("custom_setEnabled", function(enabled)
						patchRecord({ pinned = enabled })
					end)
					:getBound(),
			}),
		},
		listLayout:append({
			template = I.MWUI.templates.textNormal,
			props = {
				size = v2(0, 16),
				relativeSize = v2(1, 0),
				text = l10n("Color"),
				textAlignV = UI.ALIGNMENT.Center,
			},
		}),
		listLayout:appendPadding(
			4,
			colorPalettes(24, 16, 4, record.color, function(i)
				patchRecord({ color = UIContext.noteColors[i] })
				updateIconUIObject()
				self:queueUpdate()
			end)
		),
		listLayout:append({
			template = I.MWUI.templates.textNormal,
			props = {
				size = v2(0, 16),
				relativeSize = v2(1, 0),
				text = l10n("Icon"),
				textAlignV = UI.ALIGNMENT.Center,
			},
		}),
		listLayout:appendPadding(
			4,
			icons(32, 13, 4, record.iconPath, function(i, uiObject, wasClicked)
				local delta = { iconPath = UIContext.noteIconPaths[i] }
				selectedIconUIObject = uiObject

				if wasClicked and not nameIsDesired then
					local iconPathName = getIconNameFromPath(delta.iconPath)
					if iconPathName ~= "" then
						delta.name = iconPathName
						nameLayout.props.text = delta.name
						nameIsDesired = false
					end
				end

				updateIconUIObject()

				patchRecord(delta)

				self:queueUpdate()
			end)
		),
		listLayout:append({
			template = I.MWUI.templates.textNormal,
			props = {
				size = v2(0, 16),
				relativeSize = v2(1, 0),
				text = l10n("Description"),
				textAlignV = UI.ALIGNMENT.Center,
			},
		}),
		listLayout:appendPadding(4, {
			template = I.MWUI.templates.borders,
			props = {
				size = v2(0, -listLayout.size - 30 - 16),
				relativeSize = v2(1, 1),
			},
			content = UI.content({
				SharedUI.padding(4, {
					template = I.MWUI.templates.textEditBox,
					props = {
						relativeSize = v2(1, 1),
						size = v2(0, 0),
						multiline = true,
						wordWrap = true,
						text = record.description,
					},
					events = {
						textChanged = Async:callback(function(newStr, layout)
							layout.props.text = newStr
							patchRecord({ description = newStr })
						end),
					},
				}),
			}),
		}),
		{
			type = UI.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = false,
				relativePosition = v2(0, 1),
				anchor = v2(0, 1),
				size = v2(0, 30),
				relativeSize = v2(1, 0),
				align = UI.ALIGNMENT.End,
			},
			external = {
				grow = 1,
				stretch = 1,
			},
			content = UI.content({
				Button.new()
					:setText(l10n("Remove"))
					:registerEvent("custom_clicked", function()
						props.onRemoved()
						self:destroy()
					end)
					:getBound(),
				SharedUI.intervalH(8),
				Button.new()
					:setText(l10n("Confirm"))
					:registerEvent("custom_clicked", function()
						props.onConfirmed(record)
						self:destroy()
					end)
					:getBound(),
				SharedUI.intervalH(8),
				Button.new()
					:setText(l10n("Cancel"))
					:registerEvent("custom_clicked", function()
						props.onCanceled()
						self:destroy()
					end)
					:getBound(),
			}),
		},
	})

	local window = Window.new({
		minSize = v2(500, 500),
		layer = "WAY_Popup",
		onDragged = function(offset)
			StaticSavedPos = offset
		end,
		onResized = function(size)
			StaticSavedSize = size
		end,
	})

	window:setTitle(props.mode == "new" and l10n("NewNote") or l10n("EditNote"))

	if StaticSavedPos then
		window:setPosition(StaticSavedPos)
	else
		window:setPosition(UI.screenSize() / 2 - (v2(500, 500) / 2))
	end

	if StaticSavedSize then
		window:setSize(StaticSavedSize)
	end

	window:getWindowContent():add({
		name = "background",
		type = UI.TYPE.Image,
		props = {
			resource = UI.texture({ path = "black" }),
			relativeSize = v2(1, 1),
			alpha = UI._getMenuTransparency(),
		},
	})
	window:getWindowContent():add(SharedUI.padding(8, {
		props = {
			relativeSize = v2(1, 1),
		},
		content = content,
	}))

	---@class WAY.NotePrompt
	self = NotePrompt.bind({})
	self._window = window

	return self
end

function NotePrompt:onVisibleChanged(visible)
	self._window:setVisible(visible)
end

function NotePrompt:onUpdate()
	self._window:update()
end

function NotePrompt:onDestroyed()
	self._window:destroy()
end

return NotePrompt
