local OMWUtil = require("openmw.util")
local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local Core = require("openmw.core")
local Ambient = require("openmw.ambient")

local Utils = require("scripts/WayfarersAtlas/Utils")
local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")
local TooltipController = require("scripts/WayfarersAtlas/UI/Controllers/TooltipController")
local NotePrompt = require("scripts/WayfarersAtlas/UI/NotePrompt")
local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Dictionary = Immutable.Dictionary

local v2 = OMWUtil.vector2
local l10n = Core.l10n("WayfarersAtlas")

local UNSCALED_SIZE = v2(32, 32)
local MIN_V2 = v2(0, 0)
local MAX_V2 = v2(1, 1)

---@class WAY.NotesLayer: WAY.UIObject
local NotesLayer = UIObject:extend("NotesLayer")

---@class WAY.NotesLayer.Props
---@field notes {[string]: WAY.NoteRecord} Is not read-only.
---@field parentUnscaledSize unknown
---@field newNote fun(relativePosition): WAY.NoteRecord
---@field getSize fun(): unknown
---@field onDraggingNote fun(dragging: boolean)
---@field onPrompting fun(prompting: boolean)

---@param props WAY.NotesLayer.Props
function NotesLayer.new(props)
	---@class WAY.NotesLayer
	local self = NotesLayer.bind(UI.create({
		props = { relativeSize = v2(1, 1) },
	}))

	self._props = props
	self._noteUIObjectsById = {}

	local lastMouseOffset = v2(0, 0)
	self:registerEvent("mouseMove", function(e)
		lastMouseOffset = e.offset
		return true
	end)

	self:registerEvent("mouseDoubleClick", function()
		self:_onNewNote(lastMouseOffset)
		return true
	end)

	for _, record in pairs(props.notes) do
		self:_createNoteUI(record)
	end

	table.sort(self:getContent(), function(a, b)
		return a.userData.noteRecord.id < b.userData.noteRecord.id
	end)

	self:queueUpdate()

	return self
end

local function playWritingSound()
	local writeFileIndex = math.random(3)
	Ambient.playSoundFile(("sound/WayfarersAtlas/write%d.wav"):format(writeFileIndex), {
		volume = 0.5,
		pitch = math.random(85, 115) / 100,
	})
end

function NotesLayer:_prompt(record, mode, startPos, onConfirm)
	if self._promptWindow then
		return
	end

	Ambient.playSound("menu click")

	local uiObject = self._noteUIObjectsById[record.id]
	local lastRelativePosition = record.relativePosition

	local function merge(newRecord)
		return Dictionary.merge(newRecord, {
			relativePosition = lastRelativePosition,
		})
	end

	local disconnect = SharedUI.scrollableXY({
		uiObject = uiObject,
		startClickPos = startPos,
		onScroll = function(offset)
			local relOffset = Utils.v2div(offset, self._props.getSize())
			local nextRelativePos = Utils.v2clamp(lastRelativePosition + relOffset, MIN_V2, MAX_V2)

			self:_updateNoteUI(Dictionary.merge(self:_assertGetNoteFromId(record.id), {
				relativePosition = nextRelativePos,
			}))

			self._props.onDraggingNote(true)
		end,
		onScrollFinished = function()
			lastRelativePosition = self:_assertGetNoteFromId(record.id).relativePosition
			self._props.onDraggingNote(false)
		end,
	})

	-- Update so that the scroll event listeners are registered.
	self:queueUpdate()

	self._promptWindow = NotePrompt.new({
		mode = mode,
		record = record,
		onConfirmed = function(newRecord)
			if mode == "new" or not Dictionary.equalsDeep(merge(newRecord), record) then
				playWritingSound()
			end

			onConfirm(merge(newRecord))
		end,
		onChanged = function(newRecord)
			self:_updateNoteUI(merge(newRecord))
		end,
		onCanceled = function()
			if mode == "new" then
				self:_onRemoveNote(record.id)
			elseif mode == "edit" then
				self:_updateNoteUI(record)
			end
		end,
		onRemoved = function()
			if mode == "edit" then
				playWritingSound()
			end

			self:_onRemoveNote(record.id)
		end,
	})

	self._promptWindow:registerEvent("custom_destroyed", function()
		self._promptWindow = nil
		self._props.onPrompting(false)
		disconnect()
		self:queueUpdate()
	end)

	self._props.onPrompting(true)
end

local function populateNoteTooltip(content, uiObject)
	---@type WAY.NoteRecord
	local record = uiObject:getLayout().userData.noteRecord
	local noteDefaultName = l10n("DefaultNoteName", { id = record.id })
	local text = noteDefaultName .. "\n" .. record.name

	if record.description ~= "" then
		text = text .. "\n\n" .. record.description
	end

	content:add({
		template = I.MWUI.templates.textNormal,
		props = {
			multiline = true,
			text = Utils.wordWrap(text, 30),
		},
	})
end

function NotesLayer:_onNewNote(mouseOffset)
	if self._promptWindow then
		return
	end

	local relPos = Utils.v2div(mouseOffset, self._props.getSize())
	local record, confirm = self._props.newNote(relPos)

	self:_createNoteUI(record)
	self:queueUpdate()

	local notes = self._props.notes
	self:_prompt(record, "new", nil, function(newRecord)
		self:_updateNoteUI(newRecord)
		confirm(newRecord)
		notes[record.id] = newRecord
	end)
end

function NotesLayer:_onRemoveNote(id)
	Utils.remove(self:getContent(), tostring(id))
	self._noteUIObjectsById[id] = nil
	self._props.notes[id] = nil

	self:queueUpdate()
end

function NotesLayer:destroy()
	if self._promptWindow then
		self._promptWindow:destroy()
	end
end

function NotesLayer:_makeProps(record)
	return {
		relativeSize = (not record.pinned) and Utils.v2div(UNSCALED_SIZE, self._props.parentUnscaledSize) or v2(0, 0),
		size = record.pinned and UNSCALED_SIZE or v2(0, 0),
		anchor = v2(0.5, 0.5),
		relativePosition = record.relativePosition,
		resource = UI.texture({ path = record.iconPath }),
		color = record.color,
	}
end

---@param new WAY.NoteRecord
---@param old WAY.NoteRecord
local function shouldUpdateProps(new, old)
	return new.color ~= old.color
		or new.iconPath ~= old.iconPath
		or new.pinned ~= old.pinned
		or new.relativePosition ~= old.relativePosition
end

function NotesLayer:_updateNoteUI(record)
	local object = self._noteUIObjectsById[record.id]
	local layout = object:getLayout()

	if shouldUpdateProps(record, layout.userData.noteRecord) then
		for name, value in pairs(self:_makeProps(record)) do
			layout.props[name] = value
		end

		self:queueUpdate()
	end

	layout.userData.noteRecord = record
end

---@return WAY.NoteRecord
function NotesLayer:_assertGetNoteFromId(id)
	local uiObject = self._noteUIObjectsById[id]
	local noteRecord
	if uiObject then
		noteRecord = uiObject:getLayout().userData.noteRecord
	end

	if not noteRecord then
		noteRecord = self._props.notes[id]
	end

	if not noteRecord then
		error("Could not find note record for ID " .. tostring(id))
	end

	return noteRecord
end

---@param record WAY.NoteRecord
function NotesLayer:_createNoteUI(record)
	local uiObject = UIObject.bind({
		name = tostring(record.id),
		type = UI.TYPE.Image,
		props = self:_makeProps(record),
		userData = { noteRecord = record },
	})

	self._noteUIObjectsById[record.id] = uiObject

	uiObject:registerEvent("mousePress", function(e)
		self:_prompt(self._props.notes[record.id], "edit", e.position, function(newRecord)
			self._props.notes[newRecord.id] = newRecord
			self:_updateNoteUI(newRecord)
		end)
	end)

	TooltipController:register(uiObject, populateNoteTooltip)

	self:addChild(uiObject)
end

function NotesLayer:onVisibleChanged(visible)
	if self._promptWindow then
		self._promptWindow:setVisible(visible)
	end
end

return NotesLayer
