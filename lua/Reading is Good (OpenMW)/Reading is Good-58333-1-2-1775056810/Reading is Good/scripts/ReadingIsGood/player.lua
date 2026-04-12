local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local v2 = util.vector2
local saveData

require("scripts.ReadingIsGood.settings")

-- localizations
local language = "english"
if core.getGMST("sCustomClassName") == "Abenteurer" then
	language = "german"
end

local translations = {
	english = {
		bookDeepens = "%s experience rate increased by %d%%. %d/%d skill books read.",
		bookMaxed = "You've already gained maximum insight into %s from reading. (%d%% XP bonus)",
		tooltipRead = "%s experience increased by %d%%.\n%d/%d skill books read.",
		tooltipUnread = "Unread",
	},
	german = {
		bookDeepens = "%s-Erfahrung um %d%% erhöht. %d/%d Lehrbücher gelesen.",
		bookMaxed = "Du hast bereits maximale Einsicht in %s durch Lesen erlangt. (%d%% EP-Bonus)",
		tooltipRead = "%s-Erfahrung um %d%% erhöht.\n%d/%d Lehrbücher gelesen.",
		tooltipUnread = "Ungelesen",
	},
}

local L = translations[language]

-- debug
local function dbg(...)
	if S_RIG_DEBUG then
		print("[ReadingIsGood]", ...)
	end
end

-- message queue
local pendingMessages = {}
local hasPending = false

local function queueMessage(msg)
	pendingMessages[#pendingMessages + 1] = msg
	hasPending = true
end

-- xp multiplier
local function getBookXPMultiplier(skillId)
	local effectiveBooks = math.min(saveData.skillBooksRead[skillId] or 0, S_BOOK_MAX)
	local externalMod = saveData.externalModifier[skillId] or 0
	return 1 + (effectiveBooks * S_BOOK_BOOST + externalMod), effectiveBooks
end

-- shared book-read logic for vanilla and SkillFramework handlers
local function handleBookRead(skillId, displayName)
	saveData.skillBooksRead[skillId] = (saveData.skillBooksRead[skillId] or 0) + 1
	local booksRead = saveData.skillBooksRead[skillId]

	local effectiveBooks = math.min(booksRead, S_BOOK_MAX)
	local totalBoostPct = effectiveBooks * S_BOOK_BOOST * 100

	if booksRead <= S_BOOK_MAX then
		queueMessage(string.format(L.bookDeepens, displayName, totalBoostPct, booksRead, S_BOOK_MAX))
		dbg(string.format("Book read for %s (%d/%d), multiplier now %.2fx",
			skillId, booksRead, S_BOOK_MAX, 1 + booksRead * S_BOOK_BOOST))
	else
		queueMessage(string.format(L.bookMaxed, displayName, totalBoostPct))
		dbg(string.format("Already at max books for %s (%d/%d)", skillId, booksRead, S_BOOK_MAX))
	end
end

-- Intercept skill book level-ups: undo the vanilla +1 and grant XP boost instead.
I.SkillProgression.addSkillLevelUpHandler(function(skillId, source, options)
	if source ~= I.SkillProgression.SKILL_INCREASE_SOURCES.Book then return true end
	if not S_RIG_TOGGLE then return true end
	-- undo vanilla skill increase and level-up contributions
	if S_NEGATE_SKILLUP then
		types.Actor.stats.level(self).skillIncreasesForAttribute[options.levelUpAttribute] = types.Actor.stats.level(self).skillIncreasesForAttribute[options.levelUpAttribute] - options.levelUpAttributeIncreaseValue
		types.Actor.stats.level(self).progress = types.Actor.stats.level(self).progress - options.levelUpProgress
		types.NPC.stats.skills[skillId](self).base = types.NPC.stats.skills[skillId](self).base - options.skillIncreaseValue
	end

	handleBookRead(skillId, core.stats.Skill.records[skillId].name)
end)

-- Apply XP boost to all skill uses based on how many books have been read.
I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if not S_RIG_TOGGLE then return end

	local mult, effectiveBooks = getBookXPMultiplier(skillId)
	if mult > 1 then
		local oldGain = params.skillGain
		params.skillGain = params.skillGain * mult
		dbg(string.format("XP boost: %s %.4f -> %.4f (x%.2f from %d books)",
			skillId, oldGain, params.skillGain, mult, effectiveBooks))
	end
end)

-- SkillFramework integration
local function initSkillFrameworkHooks()
	if not I.SkillFramework then
		dbg("Skill Framework not detected, skipping integration.")
		return
	end
	if not S_RIG_SKILLFRAMEWORK then
		dbg("Skill Framework integration disabled in settings.")
		return
	end

	dbg("Hooking into Skill Framework for custom skill books.")

	I.SkillFramework.addSkillLevelUpHandler(function(skillId, source, params)
		if not S_RIG_TOGGLE or not S_RIG_SKILLFRAMEWORK then return end

		local srcBook = I.SkillFramework.SKILL_INCREASE_SOURCES
			and I.SkillFramework.SKILL_INCREASE_SOURCES.Book
		if not srcBook or source ~= srcBook then return end

		local skillRecord = I.SkillFramework.getSkillRecord(skillId)
		handleBookRead(skillId, skillRecord and skillRecord.name or skillId)

		if S_NEGATE_SKILLUP then
			params.skillIncreaseValue = 0
		end
	end)

	I.SkillFramework.addSkillUsedHandler(function(skillId, params)
		if not S_RIG_TOGGLE or not S_RIG_SKILLFRAMEWORK then return end

		local mult = getBookXPMultiplier(skillId)
		if mult > 1 then
			local oldGain = params.skillGain
			params.skillGain = params.skillGain * mult
			dbg(string.format("[SF] XP boost: %s %.4f -> %.4f (x%.2f)",
				skillId, oldGain, params.skillGain, mult))
		end
	end)
end
initSkillFrameworkHooks()

-- InventoryExtender tooltip integration
async:newUnsavableSimulationTimer(0.1, function()
	if not I.InventoryExtender then
		dbg("InventoryExtender not found - tooltip integration disabled")
		return
	end

	dbg("Registering skill book tooltip modifier with InventoryExtender.")

	local BASE = I.InventoryExtender.Templates.BASE
	local constants = I.InventoryExtender.Constants
	local COLORS = {
		LABEL = (constants and constants.Colors and constants.Colors.DISABLED)
			or util.color.rgb(0.6, 0.6, 0.6),
		BOOST = util.color.rgb(0.4, 0.7, 1.0),
		MAXED = util.color.rgb(0.5, 0.9, 0.5),
		UNREAD = util.color.rgb(0.8, 0.8, 0.8),
	}

	I.InventoryExtender.registerTooltipModifier("ReadingIsGood_SkillBooks", function(item, layout)
		if not S_RIG_TOGGLE or not S_RIG_INVENTORYX then return layout end

		-- Resolve skill ID and display name
		local skillId, skillName
		local bookRecord = types.Book.records[item.recordId]
		if bookRecord and bookRecord.skill and bookRecord.skill ~= "" then
			-- vanilla skill book
			skillId = bookRecord.skill
			skillName = core.stats.Skill.records[skillId].name
		else
			-- check SkillFramework
			local SF = S_RIG_SKILLFRAMEWORK and I.SkillFramework
			local sfRecord = SF and SF.getSkillBookRecord(item.recordId)
			if not sfRecord then return layout end
			for sId in pairs(sfRecord) do
				skillId = sId
				break
			end
			local skillRecord = SF.getSkillRecord(skillId)
			if not skillRecord then return layout end
			skillName = skillRecord.name
		end

		local ok, content = pcall(function()
			return layout.content[1].content[1].content
		end)
		if not ok or not content then return layout end

		-- separator
		content:add(BASE.intervalV(8))
		content:add({
			template = I.MWUI.templates.horizontalLine,
			props = { size = v2(200, 2) },
		})
		content:add(BASE.intervalV(4))

		if not saveData.readBookIds[item.recordId] then
			-- unread label
			local text = L.tooltipUnread
			if true or S_SHOW_SKILL_UNREAD then
				text = text .. " (" .. skillName .. ")"
			end
			content:add({
				template = BASE.textNormal,
				props = {
					text = text,
					textColor = COLORS.UNREAD,
					textAlignH = ui.ALIGNMENT.Center,
					multiline = true,
				},
			})
		else
			-- read label
			local booksRead = saveData.skillBooksRead[skillId] or 0
			local effectiveBooks = math.min(booksRead, S_BOOK_MAX)
			local totalBoostPct = (getBookXPMultiplier(skillId) - 1) * 100
			content:add({
				template = BASE.textNormal,
				props = {
					text = string.format(L.tooltipRead,
						skillName, totalBoostPct, effectiveBooks, S_BOOK_MAX),
					textColor = booksRead >= S_BOOK_MAX and COLORS.MAXED or COLORS.BOOST,
					textAlignH = ui.ALIGNMENT.Center,
					multiline = true,
				},
			})
		end

		return layout
	end)
end)

-- check what books have already been read, using quickloot's new DB
function fetchQuicklootBooks()
	if not S_FETCH_PREVIOUS then return end
	if not I.QuickLoot or I.QuickLoot.version < 2 then
		dbg("QuickLoot not found - skipping backfill.")
		return
	end

	if saveData.gotQuicklootBooks then return end
	saveData.gotQuicklootBooks = true

	local readBooks = I.QuickLoot.getReadBooks()
	if not readBooks then return end

	local backfilled = 0
	for recordId, _ in pairs(readBooks) do
		if not saveData.readBookIds[recordId] then
			local bookRecord = types.Book.records[recordId]
			if bookRecord and bookRecord.skill and bookRecord.skill ~= "" then
				local skillId = bookRecord.skill
				saveData.skillBooksRead[skillId] = (saveData.skillBooksRead[skillId] or 0) + 1
				saveData.readBookIds[recordId] = true
				backfilled = backfilled + 1
				dbg(string.format("Backfilled: %s -> %s (%d total)",
					recordId, skillId, saveData.skillBooksRead[skillId]))
			end
		end
	end

	if backfilled > 0 then
		dbg(string.format("Backfilled %d skill books from QuickLoot.", backfilled))
	end
end
async:newUnsavableSimulationTimer(0.2, fetchQuicklootBooks)

local function UiModeChanged(data)
	if data.newMode == "Book" or data.newMode == "Scroll" then
		if data.arg then
			saveData.readBookIds[data.arg.recordId] = true
			dbg("Book opened: " .. tostring(data.arg.recordId))
		end
	end
end

local function modExpMult(skillId, mult)
	saveData.externalModifier[skillId] = (saveData.externalModifier[skillId] or 0) + mult
	dbg("got external modifier for " .. tostring(skillId) .. " : " .. tostring(mult))
end

local function onFrame(dt)
	if not hasPending then return end
	if S_NEGATE_SKILLUP then
		ui.showMessage("", { showInDialogue = false })
		ui.showMessage("", { showInDialogue = false })
		ui.showMessage("", { showInDialogue = false })
	end
	for i = 1, #pendingMessages do
		ui.showMessage(pendingMessages[i], { showInDialogue = false })
	end
	pendingMessages = {}
	hasPending = false
end

local function onLoad(data)
	saveData = data or {}
	saveData.skillBooksRead = saveData.skillBooksRead or {}
	saveData.externalModifier = saveData.externalModifier or {}
	saveData.readBookIds = saveData.readBookIds or {}
end

local function onSave()
	return saveData
end

return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onFrame = onFrame,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
	},
	interfaceName = "ReadingIsGood",
	interface = {
		version = 1,
		modExpMult = modExpMult,
	},
}