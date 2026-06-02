local mod = require("InventoryDateTime.config")
local config = mod.config

require("InventoryDateTime.mcm")

-- ============================================================
-- Mod Info
-- ============================================================

local modName = "Inventory Date Time"

-- ============================================================
-- Calendar Data
-- ============================================================

local months = {
	"Morning Star",
	"Sun's Dawn",
	"First Seed",
	"Rain's Hand",
	"Second Seed",
	"Mid Year",
	"Sun's Height",
	"Last Seed",
	"Heartfire",
	"Frost Fall",
	"Sun's Dusk",
	"Evening Star",
}

local weekdays = {
	"Morndas",
	"Tirdas",
	"Middas",
	"Turdas",
	"Fredas",
	"Loredas",
	"Sundas",
}

-- ============================================================
-- UI IDs
-- ============================================================

local labelId = tes3ui.registerID("InventoryDateTime_Label")

-- ============================================================
-- Date / Time Formatting
-- ============================================================

local function getTimeText(hourFloat)
	local hour = math.floor(hourFloat)
	local minute = math.floor((hourFloat - hour) * 60)

	if minute >= 60 then
		minute = 0
		hour = hour + 1
	end

	hour = hour % 24

	return string.format("%02d:%02d", hour, minute)
end

local function applyDateTimeFormat(formatText, values)
	local result = formatText or "%W, %D %M %T (Day %N)"

	local replacements = {
		["%%W"] = values.weekdayName,
		["%%M"] = values.monthName,
		["%%D"] = tostring(values.day),
		["%%Y"] = tostring(values.year),
		["%%T"] = values.timeText,
		["%%N"] = tostring(values.dayNumber),
	}

	for token, value in pairs(replacements) do
		result = result:gsub(token, value)
	end

	return result
end

local function getSafeFormatText()
	local formatText = config.dateTimeFormat

	if type(formatText) ~= "string" or formatText == "" then
		return mod.defaultConfig.dateTimeFormat
	end

	-- Prevent giant strings from breaking the UI.
	formatText = formatText:sub(1, 120)

	-- Keep it one line.
	formatText = formatText:gsub("[\r\n]", " ")

	return formatText
end

local function getDateTimeText()
	local wc = tes3.worldController
	if not wc then
		return ""
	end

	local day = math.floor(wc.day.value)
	local monthIndex = math.floor(wc.month.value) + 1
	local monthName = months[monthIndex] or "Unknown"
	local year = math.floor(wc.year.value)

	local dayNumber = math.floor(wc.daysPassed.value)

	local weekdayIndex = ((dayNumber + 2) % 7) + 1
	local weekdayName = weekdays[weekdayIndex] or "Unknown"

	local timeText = getTimeText(wc.hour.value)

	return applyDateTimeFormat(getSafeFormatText(), {
		weekdayName = weekdayName,
		monthName = monthName,
		day = day,
		year = year,
		timeText = timeText,
		dayNumber = dayNumber,
	})
end



-- ============================================================
-- Inventory Date/Time Label
-- ============================================================

local function addDateTimeToInventory()
	if not config.enableInventory then
		return
	end

	local menu = tes3ui.findMenu("MenuInventory")
	if not menu then
		return
	end

	-- Remove the previous label so duplicates do not stack.
	local oldLabel = menu:findChild(labelId)
	if oldLabel then
		oldLabel:destroy()
	end

	local dateTimeText = getDateTimeText()

	local label = menu:createLabel({
		id = labelId,
		text = dateTimeText,
	})

	label.color = tes3ui.getPalette(tes3.palette.normalColor)

	-- Positioning inside the inventory menu.
	-- Increase borderTop to move it lower.
	-- Increase borderRight to move it left.
	label.borderTop = 40
	label.borderRight = 64
	label.borderBottom = 8
	label.borderLeft = 8

	menu:updateLayout()
end

-- ============================================================
-- Pinned Inventory Live Update
-- ============================================================

local liveUpdateTimer = 0
local lastInventoryDateTimeText = nil

local function onSimulateLiveInventory(e)
	if not config.enableInventory then
		return
	end

	liveUpdateTimer = liveUpdateTimer + e.delta
	if liveUpdateTimer < 1 then
		return
	end

	liveUpdateTimer = 0

	local menu = tes3ui.findMenu("MenuInventory")
	if not menu then
		lastInventoryDateTimeText = nil
		return
	end

	local currentText = getDateTimeText()
	if currentText == lastInventoryDateTimeText then
		return
	end

	lastInventoryDateTimeText = currentText
	addDateTimeToInventory()
end

-- ============================================================
-- Rest/Wait Message
-- ============================================================

local shouldShowDateTimeAfterRestWait = false
local restWaitStartHour = nil
local restWaitStartDayNumber = nil
local onSimulate

local function onRestWaitMenuEnter()
	local wc = tes3.worldController
	if wc then
		restWaitStartHour = wc.hour.value
		restWaitStartDayNumber = math.floor(wc.daysPassed.value)
	end

	shouldShowDateTimeAfterRestWait = true

	-- Only tick briefly after Rest/Wait opens.
	-- This avoids keeping simulate registered forever.
	event.register(tes3.event.simulate, onSimulate)
end

onSimulate = function()
	if not shouldShowDateTimeAfterRestWait then
		event.unregister(tes3.event.simulate, onSimulate)
		return
	end

	shouldShowDateTimeAfterRestWait = false
	event.unregister(tes3.event.simulate, onSimulate)

	local wc = tes3.worldController
	if not wc then
		return
	end

	local currentHour = wc.hour.value
	local currentDayNumber = math.floor(wc.daysPassed.value)

	local timePassed =
		currentDayNumber ~= restWaitStartDayNumber
		or math.floor(currentHour * 60) ~= math.floor(restWaitStartHour * 60)

	if not timePassed then
		return
	end

	if config.enableRestWaitMessage then
		tes3.messageBox(getDateTimeText())
	end

	addDateTimeToInventory()
end

-- ============================================================
-- Menu Refresh Handling
-- ============================================================

local function onAnyMenuEnter()
	timer.start({
		duration = 0.01,
		type = timer.real,
		callback = function()
			-- Do not refresh inventory while Rest/Wait is open.
			if tes3ui.findMenu("MenuRestWait") then
				return
			end

			-- MenuInventory can exist even when its filtered menuEnter
			-- does not fire, so we check for it manually.
			if tes3ui.findMenu("MenuInventory") then
				addDateTimeToInventory()
			end
		end
	})
end

-- ============================================================
-- Loaded
-- ============================================================

local function onLoaded()
	mwse.log("[%s] Loaded.", modName)
end

-- ============================================================
-- Events
-- ============================================================

event.register(tes3.event.loaded, onLoaded)

event.register(tes3.event.menuEnter, onAnyMenuEnter)

event.register(tes3.event.menuEnter, onRestWaitMenuEnter, {
	filter = "MenuRestWait"
})

event.register(tes3.event.simulate, onSimulateLiveInventory)