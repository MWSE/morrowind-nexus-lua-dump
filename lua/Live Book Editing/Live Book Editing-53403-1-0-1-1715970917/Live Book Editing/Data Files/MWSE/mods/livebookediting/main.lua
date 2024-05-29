local logger = require("logging.logger")
local config = require("livebookediting.config").config

local log = logger.new({
	name = "livebookediting",
	-- outputFile = "livebookediting.log",
	logLevel = config.logLevel,
})

local util = require("livebookediting.util")
dofile("livebookediting.mcm")


local i18n = mwse.loadTranslations("livebookediting")
local id = util.id
local paths = {
	[id.book] = tes3.installDirectory .. "\\data files\\booktext.txt",
	[id.scroll] = tes3.installDirectory .. "\\data files\\scrolltext.txt",
}

--- Checks if there is missing \<br> statement at the end.
--- Will show a messageBox if it is missing.
---@param text string
local function checkMissingLineBreak(text)
	local ending = text:trim():sub(-4, -1):lower()
	if ending ~= "<br>" then
		tes3.messageBox(i18n("missingLineBreakText"))
	end
end

--- Reads the contents of a text file and returns it as a string.
--- Also returns true if the text is missing <br> at the end.
---@param path string
---@return string
local function loadFile(path)
	if not lfs.fileexists(path) then
		local msg = string.format("File doesn't exist: \"%s\". Loading default text.", path)
		tes3.messageBox(msg)
		log:error(msg)
		return i18n("defaultText")
	end
	local file = io.open(path, "r")
	if not file then
		local msg = string.format("Couldn't open file at: \"%s\". Loading default text.", path)
		tes3.messageBox(msg)
		log:error(msg)
		return i18n("defaultText")
	end
	local buffer = tostring(file:read("*a"))
	file:close()
	log:debug("Read from %s:\n%s", path, buffer)

	checkMissingLineBreak(buffer)
	return buffer
end

---@alias livebookeditingBookType
---| "book"
---| "scroll"

--- Opens the book or scroll with text from text file. Performs checks if
--- there is missing \<br> statement at the end.
---@param bookType livebookeditingBookType
local function showText(bookType)
	local text = loadFile(paths[id[bookType]])

	if bookType == "book" then
		tes3ui.showBookMenu(text)
	elseif bookType == "scroll" then
		tes3ui.showScrollMenu(text)
	end
end

---@param actual keyDownEventData
---@param expected mwseKeyCombo
---@return boolean
local function canOpenBook(actual, expected)
	if tes3.onMainMenu() then
		tes3.messageBox(i18n("loadBefore"))
		return false
	end

	if not tes3.isKeyEqual({ actual = actual, expected = expected }) then
		return false
	end

	return true
end

---@param e keyDownEventData
local function openBook(e)
	if not canOpenBook(e, config.bookKey) then return end
	showText("book")
end
event.register(tes3.event.keyDown, openBook, { filter = config.bookKey.keyCode })

---@param e keyDownEventData
local function openScrool(e)
	if not canOpenBook(e, config.scrollKey) then return end
	showText("scroll")
end
event.register(tes3.event.keyDown, openScrool, { filter = config.scrollKey.keyCode })


---@param e bookGetTextEventData
local function onGetText(e)
	local bookid = e.book.id
	local path = paths[bookid]
	if not path then return end

	local text = loadFile(path)
	e.text = text
end
event.register(tes3.event.bookGetText, onGetText)

---@param e loadedEventData|nil
local function addItems(e)
	-- Wait until chargen is finished.
	if e and e.newGame then return end

	if config.addBook then
		util.addItem("book")
	end
	if config.addScroll then
		util.addItem("scroll")
	end
end
event.register(tes3.event.charGenFinished, addItems)
event.register(tes3.event.loaded, addItems)
