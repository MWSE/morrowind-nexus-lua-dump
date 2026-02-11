local UI = require("openmw.ui")
local Async = require("openmw.async")

local UIUpdater = require("scripts/WayfarersAtlas/UI/UIUpdater")
local Utils = require("scripts/WayfarersAtlas/Utils")
local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Dictionary = Immutable.Dictionary

---@class WAY.UIObject DOM element-like wrapper for layouts and elements.
local UIObject = {}
UIObject.className = "UIObject"
UIObject.__index = UIObject

function UIObject:__tostring()
	return "UIObject_" .. self.className
end

function UIObject.bind(elementOrLayout)
	local layout, element = Utils.getElementPair(elementOrLayout)

	-- Layout can only be bound to one object.
	assert(not layout.userData or not layout.userData.__object, "Layout is already bound")

	---@class WAY.UIObject
	local self = setmetatable({
		__layout = layout,
		__element = element,
		__callbacksByEventName = {},
	}, UIObject)

	self.__layout.props = self.__layout.props or {}
	self.__layout.content = self.__layout.content or UI.content({})
	self.__layout.events = self.__layout.events or {}
	self.__layout.userData = self.__layout.userData or {}
	self.__layout.userData.__object = self

	return self
end

---@return WAY.UIObject
function UIObject:extend(className)
	local newClass = Dictionary.copy(UIObject)
	newClass.__index = newClass
	newClass.className = className
	newClass.bind = function(...)
		return setmetatable(self.bind(...), newClass)
	end

	return newClass
end

function UIObject:getLayout()
	return self.__layout
end

function UIObject:getProps()
	return self.__layout.props
end

function UIObject:getElement()
	return self.__element
end

function UIObject:getBound()
	return self.__element or self.__layout
end

function UIObject:getContent()
	return self.__layout.content
end

-- The parent element should always updated when connecting or disconnecting.
function UIObject:connectEvent(eventName, callback)
	self:registerEvent(eventName, callback)

	local disconnected = false
	return function()
		if disconnected then
			return
		end

		disconnected = true

		local item = self.__callbacksByEventName[eventName]
		local last = nil

		while item do
			if item.callback == callback then
				if last then
					last.next = item.next
				else
					self.__callbacksByEventName[eventName] = item.next
				end

				break
			end

			last = item
			item = item.next
		end

		if not self.__callbacksByEventName[eventName] then
			self.__layout.events[eventName] = nil
		end
	end
end

-- The parent element should always updated when registering.
function UIObject:registerEvent(eventName, callback)
	local head = self.__callbacksByEventName[eventName]

	self.__callbacksByEventName[eventName] = { callback = callback, next = head }

	if not head then
		self.__layout.events[eventName] = Async:callback(function(...)
			local propagate = self:triggerEvent(eventName, ...)
			return propagate
		end)
	end

	return self
end

function UIObject:triggerEvent(eventName, ...)
	local propagate = nil
	local node = self.__callbacksByEventName[eventName]

	while node do
		local _propagate = node.callback(...)

		if _propagate ~= nil then
			propagate = _propagate
		end

		node = node.next
	end

	return propagate
end

---@return any
function UIObject:findFirst(childName)
	local child = Utils.findFirst(self:getContent(), childName)

	if child then
		return Utils.getObject(child) or child
	else
		return nil
	end
end

-- Appends the array of children to the object's bound content.
---@param content table[]
function UIObject:addContent(content)
	for i = 1, #content do
		local child = content[i]
		self:addChild(child)
	end

	return self
end

local function maybeUnwrapBinding(node)
	if node.getBound then
		return node:getBound()
	else
		return node
	end
end

-- Adds children. A child's key becomes the child's name.
-- Order insensitive.
---@param children {[string]: unknown}
function UIObject:addChildren(children)
	for childName, child in pairs(children) do
		Utils.uiName(maybeUnwrapBinding(child), childName)
		self:addChild(child)
	end

	return self
end

---@generic T
---@param child T
---@return T
function UIObject:addChild(child)
	---@diagnostic disable
	local node = maybeUnwrapBinding(child)

	self.__layout.content:add(node)

	---@diagnostic enable
	return child
end

---@generic T
---@param child T
---@return T
---@param name string
function UIObject:addChildName(name, child)
	Utils.uiName(maybeUnwrapBinding(child), name)
	self:addChild(child)
	return child
end

function UIObject:update()
	self:onUpdate()

	if self.__element then
		self.__element:update()
	end

	-- If :onUpdate() triggered another queued update, this will cancel the queue.
	-- If :update() is called manually and while being queued, this will cancel the queue.
	UIUpdater:cancel(self)
end

function UIObject:queueUpdate()
	if self.__element or self.onUpdate ~= UIObject.onUpdate then
		UIUpdater:queue(self, self.update)
	end
end

function UIObject:isVisible()
	return self:getProps().visible ~= false
end

-- Sets visibility and calls onVisibleChanged.
-- Used for setting visibility of elements that aren't part of the same UI tree.
---@param visible boolean
function UIObject:setVisible(visible)
	if self:isVisible() == visible then
		return
	end

	self:getProps().visible = visible
	self:queueUpdate()

	self:onVisibleChanged(visible)
end

function UIObject:isDestroyed()
	return self.__destroyed == true
end

function UIObject:destroy()
	if self.__destroyed then
		return
	end

	self.__destroyed = true

	Utils.topDown(self:getBound(), Utils.destroy)

	self:onDestroyed()
	self:triggerEvent("custom_destroyed")
end

---@param visible boolean
function UIObject:onVisibleChanged(visible) end

function UIObject:onDestroyed() end

function UIObject:onUpdate() end

return UIObject
