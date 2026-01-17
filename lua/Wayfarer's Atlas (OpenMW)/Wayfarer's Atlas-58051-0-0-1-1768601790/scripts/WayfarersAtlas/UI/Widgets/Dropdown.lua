local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local OMWUtil = require("openmw.util")
local Async = require("openmw.async")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local Scrollable = require("scripts/WayfarersAtlas/UI/Widgets/Scrollable")
local Utils = require("scripts/WayfarersAtlas/Utils")
local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Dictionary = Immutable.Dictionary

local v2 = OMWUtil.vector2

local TEXT_NORMAL_TEXT_SIZE = I.MWUI.templates.textNormal.props.textSize
local PADDING = 4

---@class WAY.Dropdown: WAY.UIObject
local Dropdown = UIObject:extend("Dropdown")

---@class WAY.Dropdown.Props
---@field items string[]

function Dropdown.new(props)
	local itemLayouts = {}
	local self
	local listLayout = Utils.ListLayout.new({ padding = PADDING })

	for index, item in ipairs(props.items) do
		table.insert(
			itemLayouts,
			listLayout:append({
				type = UI.TYPE.Image,
				props = {
					size = v2(200, TEXT_NORMAL_TEXT_SIZE),
					alpha = 0.0,
				},
				events = {
					mouseClick = Async:callback(function()
						self:setSelectedIndex(index)
					end),
				},
				content = UI.content({
					{
						type = UI.TYPE.Text,
						template = I.MWUI.templates.textNormal,
						props = {
							text = item,
							inheritAlpha = false,
						},
					},
				}),
			})
		)
	end

	---@class WAY.Dropdown
	self = Dropdown.bind(UI.create({
		type = UI.TYPE.Image,
		props = {
			size = v2(200, TEXT_NORMAL_TEXT_SIZE + PADDING),
			resource = UI.texture({ path = "black" }),
			alpha = UI._getMenuTransparency(),
		},
	}))

	self._isFocused = false
	self._isFolded = true
	self._props = props
	self._listContent = UI.content(itemLayouts)

	self._scrollbarContainer = self:addChild(UIObject.bind({
		props = { relativeSize = v2(1, 1), visible = false },
	}))

	self._scrollbar = self._scrollbarContainer:addChild(Scrollable.new({
		size = v2(200, 80),
		flexSize = v2(200, listLayout.size + PADDING),
		onFocusGain = function()
			self._isFocused = true
		end,
		onFocusLoss = function()
			self._isFocused = false
		end,
		content = UI.content({
			{
				props = { relativeSize = v2(1, 1) },
				content = self._listContent,
			},
		}),
	}))

	self._foldedContainer = self:addChildName(
		"foldedContainer",
		UIObject.bind({
			type = UI.TYPE.Image,
			props = {
				relativeSize = v2(1, 1),
				alpha = 0.0,
				visible = true,
			},
		})
	)
		:registerEvent("mouseClick", function()
			if self._isFolded then
				self:setFolded(false)
			end
		end)
		:registerEvent("custom_globalMouseClick", function()
			if not self._isFolded and not self._isFocused then
				self:setFolded(true)
			end
		end)

	self:setSelectedIndex(1)

	return self
end

function Dropdown:onDestroyed()
	self._scrollbar:destroy()
	self._foldedContainer:destroy()
end

function Dropdown:onUpdate()
	self._scrollbar:update()
end

---@param index integer
function Dropdown:setSelectedIndex(index)
	if self._index == index then
		self:setFolded(true)
		return
	end

	if index <= 0 then
		error("index <= 0")
	end

	if index > #self._props.items then
		error("index out of bounds (" .. tostring(#self._props.items) .. ")")
	end

	if self._index then
		table.insert(self._listContent, self._index + 1, self._listContent[1])
		table.remove(self._listContent, 1)
	end

	local selectedLayout = table.remove(self._listContent, index)
	table.insert(self._listContent, 1, selectedLayout)

	local listLayout = Utils.ListLayout.new({ padding = PADDING })
	for _, layout in ipairs(self._listContent) do
		listLayout:append(layout)
	end

	Utils.removeAll(self._foldedContainer:getContent())
	self._foldedContainer:addChild(Dictionary.merge(selectedLayout, { events = Immutable.None }))

	self._index = index

	self:setFolded(true)

	self:queueUpdate()

	self:triggerEvent("custom_onSelected", index)
end

function Dropdown:setFolded(folded)
	if self._isFolded == folded then
		return
	end

	self._isFolded = folded

	local props = self:getProps()

	if self._isFolded then
		self._foldedContainer:setVisible(true)
		self._scrollbarContainer:setVisible(false)
		props.size = v2(200, TEXT_NORMAL_TEXT_SIZE + PADDING)
	else
		self._foldedContainer:setVisible(false)
		self._scrollbarContainer:setVisible(true)
		props.size = v2(200, 80)
	end

	self:queueUpdate()
end

return Dropdown
